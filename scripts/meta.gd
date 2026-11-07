extends RefCounted
## 局外 meta 层：解锁树数据 + 经济换算 + 纯规则函数。
##
## 本文件无状态、无副作用：状态与持久化在 Game（game_state.gd），
## 这里只回答三件事：哪些内容被锁、锁了要多少结晶、这一局折算多少结晶。
##
## 解锁关系完全由 UNLOCKS 表推导（kind + target → 节点 id），
## 所以 upgrades / relics / weapons 三个池的数据表不用为解锁机制改动。
##
## 模型（增量）：基础 14 升级 / 10 遗物 / 4 武器**不建节点 → 永远默认可用**；
## 只有新增内容建节点，未解锁不进池、解锁后进池。默认解锁集 = 空集。

const VERSION := 1

## stats 契约键：_run_stats() 产出、payout()/meta_settle_run() 消费；键名只在此登记一份
const STATS_KEYS := ["diamonds", "kills", "max_floor", "time", "score"]
## 结算返回契约键：meta_settle_run() 产出、_settle_meta() 消费
const SETTLE_RETURN_KEYS := ["payout", "crystals"]

## 解锁节点：key 一律 u_ 前缀（与池内容 id 彻底解耦，避免存档里两套口径串味）；
## target 指向对应池里的条目 id（不带前缀）；requires 里放前置**节点 id**。
const UNLOCKS := {
	"u_mx_pierce": {
		"name": "贯穿弹头", "desc": "子弹可穿透 1 个敌人，伤害 +10%",
		"kind": "upgrade", "target": "mx_pierce",
		"cost": 40, "requires": [], "default": false,
		"icon": "pierce", "max": 1,
	},
	"u_mx_critboom": {
		"name": "致命共振", "desc": "暴击时在命中点引爆，爆炸造成 60% 子弹伤害",
		"kind": "upgrade", "target": "mx_critboom",
		"cost": 60, "requires": ["u_mx_pierce"], "default": false,
		"icon": "crit", "max": 1,
	},
	"u_mx_resocore": {
		"name": "源石共鸣核心", "desc": "每拾取 3 颗源石叠 1 层共鸣，满 5 层释放冲击波",
		"kind": "upgrade", "target": "mx_resocore",
		"cost": 100, "requires": ["u_mx_critboom"], "default": false,
		"icon": "diamond", "max": 1,
	},
	"u_mr_resoshield": {
		"name": "谐振护盾", "desc": "源石共鸣爆发时获得 1 层护盾，护盾存在时免疫中毒",
		"kind": "relic", "target": "mr_resoshield",
		"cost": 40, "requires": [], "default": false,
		"icon": "icon_guard", "max": 1,
	},
	"u_mr_kinetic": {
		"name": "动能转换器", "desc": "受击后 2 秒内移速 +40%",
		"kind": "relic", "target": "mr_kinetic",
		"cost": 60, "requires": ["u_mr_resoshield"], "default": false,
		"icon": "relic_drone", "max": 1,
	},
	"u_mw_swarm": {
		"name": "蜂群导弹", "desc": "子弹自动追踪最近的敌人",
		"kind": "weapon", "target": "mw_swarm",
		"cost": 40, "requires": [], "default": false,
		"icon": "wpn_swarm", "max": 1,
	},
	"u_mw_arc": {
		"name": "电弧发射器", "desc": "子弹命中时向附近敌人放电，可连锁 3 次",
		"kind": "weapon", "target": "mw_arc",
		"cost": 60, "requires": ["u_mw_swarm"], "default": false,
		"icon": "wpn_arc", "max": 1,
	},
	"u_mw_cluster": {
		"name": "集束榴弹", "desc": "命中爆炸后分裂出 3 枚小弹",
		"kind": "weapon", "target": "mw_cluster",
		"cost": 100, "requires": ["u_mw_arc"], "default": false,
		"icon": "wpn_launcher", "max": 1,
	},
}

## 局内累计拾取 → 局外结晶的换算与上限（数值可调，不写死在结算函数里）
const ECONOMY := {
	"rate": 0.10,          # 局内累计拾取 → 结晶
	"floor_bonus": 8,      # 每深入 1 层的额外奖励（按层数-1 计）
	"kill_bonus": 0,       # 击杀与源石同源，再计一次=同一件事算两遍
	"run_cap": 60,         # 单局结算上限（防刷）
	"min_floor": 1,        # 不设层数门槛（设 2 会让弱玩家永久卡死）
	"min_seconds": 45.0,   # 短于此不结算
}

## 运行时抽卡下限：过滤后可用条目少于请求数就回退全量池
const MIN_USABLE := {"upgrade": 3, "relic": 2, "weapon": 1}

## 自检阈值（比 MIN_USABLE 严）：某类内容默认可用数退化到只剩一两项时必须报出来
## rifle 计入 weapon —— 「玩家是否被卡住」的真问题
const MIN_DEFAULT_USABLE := {"upgrade": 4, "relic": 3, "weapon": 2}

## 新解锁升级卡的引导加成局数（包含解锁后的第 1 局；递减发生在本局结束时）
const BOOST_RUNS := 3

## "kind:target" → 节点 id 的反查索引（首次使用时构建）
static var _gate := {}
## 初始即解锁的节点 id
static var _defaults := []


static func _ensure_index() -> void:
	if not _gate.is_empty():
		return
	_gate.clear()
	_defaults.clear()
	for id in UNLOCKS:
		var n: Dictionary = UNLOCKS[id]
		var k := String(n.get("kind", ""))
		var t := String(n.get("target", ""))
		if k == "" or t == "":
			continue
		_gate["%s:%s" % [k, t]] = String(id)
		if bool(n.get("default", false)):
			_defaults.append(String(id))


## 全部解锁节点 id（按表内顺序）
static func unlock_ids() -> Array:
	_ensure_index()
	return UNLOCKS.keys()


## 取节点定义
static func node(id: String) -> Dictionary:
	return UNLOCKS.get(id, {})


## 某条内容对应的解锁节点 id；没有则空串（= 默认可用）
static func gate_of(kind: String, content_id: String) -> String:
	_ensure_index()
	return String(_gate.get("%s:%s" % [kind, content_id], ""))


## 某条内容当前是否可用（未被 gate 或已解锁）
static func content_available(kind: String, content_id: String, owned: Array) -> bool:
	var gid := gate_of(kind, content_id)
	if gid == "":
		return true
	return is_unlocked(gid, owned)


## 节点是否已解锁（玩家已拥有，或该节点是初始免费项）
static func is_unlocked(id: String, owned: Array) -> bool:
	if id == "":
		return true
	_ensure_index()
	if owned.has(id):
		return true
	return _defaults.has(id)


## 是否可以解锁：未解锁 + 余额够 + 前置全满足
static func can_unlock(id: String, crystals: int, owned: Array) -> bool:
	if id == "" or not UNLOCKS.has(id):
		return false
	if is_unlocked(id, owned):
		return false
	if crystals < int(UNLOCKS[id].get("cost", 0)):
		return false
	for r in UNLOCKS[id].get("requires", []):
		if not is_unlocked(String(r), owned):
			return false
	return true


## 结算：把本局统计折算成局外结晶
## stats: {diamonds=本局累计拾取, kills, max_floor, time, score}
static func payout(stats: Dictionary) -> int:
	var floor_num := int(stats.get("max_floor", 0))
	var secs := float(stats.get("time", 0.0))
	if floor_num < int(ECONOMY["min_floor"]) or secs < float(ECONOMY["min_seconds"]):
		return 0
	var raw := float(stats.get("diamonds", 0)) * float(ECONOMY["rate"])
	raw += float(maxi(floor_num - 1, 0)) * float(ECONOMY["floor_bonus"])
	raw += float(stats.get("kills", 0)) * float(ECONOMY["kill_bonus"])
	return clampi(int(floor(raw)), 0, int(ECONOMY["run_cap"]))
