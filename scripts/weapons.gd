class_name Weapons
extends RefCounted
## 武器定义表：四把枪，参数即弹道。

## E8″ 运行时计数探针：本入口累计消耗的随机数个数（仅供 SMOKE 校验消耗守恒）
static var rng_draws := 0

## 可掉落 / 可上架的武器池（不含起始武器 rifle）
const DROP_POOL := ["shotgun", "railgun", "launcher"]

const DEFS := {
	"rifle": {
		"name": "标准步枪", "desc": "均衡可靠",
		"dmg": 1.0, "interval": 0.30, "count": 1, "spread": 4.0,
		"speed": 250.0, "mag": 8, "reload": 0.9, "pierce": 0,
		"life": 0.0, "explosive": 0.0,
		"tint": Color(1.0, 0.62, 0.25), "icon": "wpn_rifle",
	},
	"shotgun": {
		"name": "爆裂霰弹", "desc": "近距离毁灭",
		"dmg": 0.7, "interval": 0.72, "count": 5, "spread": 22.0,
		"speed": 225.0, "mag": 4, "reload": 1.1, "pierce": 0,
		"life": 0.40, "explosive": 0.0,
		"tint": Color(1.0, 0.82, 0.5), "icon": "wpn_shotgun",
	},
	"railgun": {
		"name": "贯穿磁轨", "desc": "穿透三个目标",
		"dmg": 3.5, "interval": 0.9, "count": 1, "spread": 0.0,
		"speed": 430.0, "mag": 3, "reload": 1.3, "pierce": 3,
		"life": 0.0, "explosive": 0.0,
		"tint": Color(0.5, 0.9, 1.0), "icon": "wpn_railgun",
	},
	"launcher": {
		"name": "爆破榴弹", "desc": "命中范围爆炸",
		"dmg": 1.6, "interval": 0.85, "count": 1, "spread": 2.0,
		"speed": 180.0, "mag": 3, "reload": 1.4, "pierce": 0,
		"life": 0.0, "explosive": 1.0,
		"tint": Color(0.6, 1.0, 0.55), "icon": "wpn_launcher",
	},
	# ---- SPR7：局外解锁内容（增量：未解锁不进池，解锁后进池）----
	"mw_swarm": {
		"name": "蜂群导弹", "desc": "子弹自动追踪最近的敌人",
		"dmg": 0.8, "interval": 0.16, "count": 1, "spread": 0.0,
		"speed": 300.0, "mag": 14, "reload": 1.0, "pierce": 0,
		"life": 1.6, "explosive": 0.0,
		"tint": Color(0.70, 1.0, 0.55), "icon": "wpn_swarm",
		"homing": true, "meta": "u_mw_swarm",
	},
	"mw_arc": {
		"name": "电弧发射器", "desc": "子弹命中时向附近敌人放电，可连锁 3 次",
		"dmg": 0.6, "interval": 0.45, "count": 1, "spread": 0.0,
		"speed": 260.0, "mag": 10, "reload": 1.2, "pierce": 0,
		"life": 0.0, "explosive": 0.0,
		"tint": Color(0.50, 0.80, 1.0), "icon": "wpn_arc",
		"arc": 3, "meta": "u_mw_arc",
	},
	"mw_cluster": {
		"name": "集束榴弹", "desc": "命中爆炸后分裂出 3 枚小弹",
		"dmg": 1.6, "interval": 0.85, "count": 1, "spread": 2.0,
		"speed": 180.0, "mag": 3, "reload": 1.4, "pierce": 0,
		"life": 0.0, "explosive": 1.0,
		"tint": Color(1.0, 0.75, 0.35), "icon": "wpn_launcher",
		"cluster": 3, "meta": "u_mw_cluster",
	},
}


static func icon(id: String) -> Texture2D:
	if not DEFS.has(id):
		Dev.err("weapon", "未知武器 id：%s（回退标准步枪图标）" % id)
		id = "rifle"
	return Assets.g(DEFS[id]["icon"])


## 已解锁的武器 id（按 DEFS 顺序；rifle 永远可用）
static func unlocked_ids() -> Array:
	var out := []
	for id in DEFS:
		if Game.meta_content_unlocked("weapon", {"id": String(id)}):
			out.append(String(id))
	return out


## 随机一把已解锁的武器（掉落 / 商店货架共用这一个入口）
## 一把都没解锁时回退 rifle（起始武器），保证不崩、不出现空 id
static func random_unlocked() -> String:
	var ids := []
	for id in DROP_POOL:
		if Game.meta_content_unlocked("weapon", {"id": id}):
			ids.append(id)
	# 恒消耗 1 次随机数：Godot 4.7 的 randi_range(0, 0) 不消耗随机流，
	# 空池 / 单元素池会少消耗 → 解锁状态改变随机流位置。randi() 恒消耗，% 保证下标合法。
	var r: int = Game.rng.randi() % maxi(ids.size(), 1)
	rng_draws += 1
	if ids.is_empty():
		return "rifle"
	return String(ids[r])
