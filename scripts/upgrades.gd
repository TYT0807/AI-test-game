extends RefCounted
## 三选一升级池：roll 抽卡，apply 结算到玩家/主场景。

const POOL := [
	{"id": "atk", "name": "火力强化", "desc": "子弹伤害 +30%", "icon": "book", "max": 6, "tag": "fire"},
	{"id": "rate", "name": "射速提升", "desc": "射击间隔 -15%", "icon": "clock", "max": 6, "tag": "fire"},
	{"id": "multi", "name": "散射弹", "desc": "每轮多射出 1 发子弹", "icon": "cards", "max": 3, "tag": "fire"},
	{"id": "speed", "name": "疾速靴", "desc": "移动速度 +12%", "icon": "boots", "max": 5, "tag": "surv"},
	{"id": "hp", "name": "生命强化", "desc": "生命上限 +1，并回满", "icon": "face", "max": 4, "tag": "surv"},
	{"id": "bomb", "name": "炸弹补给", "desc": "炸弹上限 +1，并补满", "icon": "bomb", "max": 3, "tag": "elem"},
	{"id": "turret", "name": "浮游炮升级", "desc": "解锁 / 升级浮游炮 Mk", "icon": "drone", "max": 4, "tag": "surv"},
	{"id": "magnet", "name": "磁力吸引", "desc": "拾取范围 +50%", "icon": "diamond", "max": 4, "tag": "surv"},
	{"id": "crit", "name": "弱点洞悉", "desc": "暴击率 +15%（双倍伤害）", "icon": "ears", "max": 3, "tag": ["fire", "elem"]},
	{"id": "velocity", "name": "弹道加速", "desc": "子弹飞行速度 +25%", "icon": "dot", "max": 3, "tag": "fire"},
	# ---- 第二轮新增：带稀有度 ----
	{"id": "chain", "name": "连锁闪电", "desc": "命中 25% 概率弹射到附近敌人", "icon": "chain", "max": 3, "rarity": "rare", "tag": "elem"},
	{"id": "venom", "name": "淬毒弹头", "desc": "命中 30% 概率使敌人中毒", "icon": "venom", "max": 3, "rarity": "rare", "tag": "elem"},
	{"id": "guard", "name": "护盾发生器", "desc": "获得 1 层护盾，可挡一次伤害（上限 3）", "icon": "guard", "max": 3, "rarity": "epic", "tag": "surv"},
	{"id": "dice", "name": "幸运骰", "desc": "暴击 +8%，掉落品质提升", "icon": "dice", "max": 3, "rarity": "common", "tag": "surv"},
	# ---- SPR7：局外解锁内容（增量：未解锁不进池，解锁后进池）----
	{"id": "mx_pierce", "name": "贯穿弹头", "desc": "子弹可穿透 1 个敌人，伤害 +10%",
		"icon": "pierce", "max": 1, "rarity": "rare", "tag": "fire", "meta": "u_mx_pierce"},
	{"id": "mx_critboom", "name": "致命共振", "desc": "暴击时在命中点引爆，爆炸造成 60% 子弹伤害",
		"icon": "crit", "max": 1, "rarity": "rare", "tag": "fire", "meta": "u_mx_critboom"},
	{"id": "mx_resocore", "name": "源石共鸣核心", "desc": "每拾取 3 颗源石叠 1 层共鸣，满 5 层释放冲击波",
		"icon": "diamond", "max": 1, "rarity": "rare", "tag": "surv", "meta": "u_mx_resocore"},
]

## 流派标签与套装：同标签集满 3 件触发质变（以撒「形态 + 修饰」思路）
const TAGS := {
	"fire": {"name": "火力", "need": 3, "color": Color(1.0, 0.55, 0.25)},
	"elem": {"name": "元素", "need": 3, "color": Color(0.55, 0.85, 1.0)},
	"surv": {"name": "生存", "need": 3, "color": Color(0.55, 0.95, 0.6)},
}

const RARITY_WEIGHT := {"common": 10, "rare": 5, "epic": 2}
const RARITY_NAME := {"common": "普通", "rare": "稀有", "epic": "史诗"}
const RARITY_COLOR := {"common": Color(0.75, 0.75, 0.78), "rare": Color(0.35, 0.75, 1.0), "epic": Color(0.85, 0.55, 1.0)}

# 已选次数由 main 记录（重开局自动清零）
static var taken := {}
## E8″ 运行时计数探针：本入口累计消耗的随机数个数（仅供 SMOKE 校验消耗守恒）
static var rng_draws := 0
## 各流派已集齐数量与套装是否已激活
static var tag_counts := {"fire": 0, "elem": 0, "surv": 0}
static var sets_active := {"fire": false, "elem": false, "surv": false}


## 可用池：只含已解锁的升级；不足 n 条时回退全量池
## （保证三选一永远满 3 张，也保证每次 roll 消耗的随机数个数与过滤前一致）
static func _usable_pool(n: int) -> Array:
	var pool := []
	for p in POOL:
		if Game.meta_content_unlocked("upgrade", p):
			pool.append(p.duplicate(true))
	if pool.size() < n:
		Dev.err("meta", "可用升级不足：需要 %d，实有 %d（已回退全量池）" % [n, pool.size()])
		return POOL.duplicate(true)
	return pool


static func roll(n: int) -> Array:
	var out := []
	var pool := _usable_pool(n)
	for i in n:
		var total := 0
		for p in pool:
			total += _weight(p)
		# 恒消耗 1 次：total==1 时 randi_range(1, 1) 不消耗随机流；
		# 空池同样消耗（不 break），消耗个数与池大小 / 门控状态无关。
		var r: int = Game.rng.randi() % maxi(total, 1) + 1
		rng_draws += 1
		if pool.is_empty():
			continue
		var pick: Dictionary = pool[0]
		for p in pool:
			r -= _weight(p)
			if r <= 0:
				pick = p
				break
		out.append(pick)
		pool.erase(pick)
	return out


static func _weight(p: Dictionary) -> int:
	var left := maxi(int(p["max"]) - int(taken.get(p["id"], 0)), 0)
	var w: int = int(RARITY_WEIGHT.get(p.get("rarity", "common"), 10))
	# 解锁可见度补偿：已解锁的新卡 ×1.5（永久，抵消池扩容稀释）；
	# 新解锁后的前 3 局再 ×6（引导），两者乘性 → ×9
	var mult := 1.0
	var node_id := String(p.get("meta", ""))
	if node_id != "" and Game.meta_is_unlocked(node_id):
		mult = 1.5
		if Game.meta_boost_rounds(node_id) > 0:
			mult = 1.5 * 6.0
	return int(left * w * mult)


static func rarity_color(p: Dictionary) -> Color:
	return RARITY_COLOR.get(p.get("rarity", "common"), Color(0.75, 0.75, 0.78))


static func rarity_name(p: Dictionary) -> String:
	return RARITY_NAME.get(p.get("rarity", "common"), "普通")


static func apply(id: String, main: Node2D) -> void:
	var player: Player = main.player
	taken[id] = int(taken.get(id, 0)) + 1
	match id:
		"atk":
			player.bullet_dmg_mult *= 1.3
		"rate":
			player.fire_rate_mult *= 1.18
		"multi":
			player.extra_count += 1
		"speed":
			player.speed_base *= 1.12
		"hp":
			player.max_hp += 1
			player.heal(player.max_hp)
		"bomb":
			player.bomb_cap += 1
			player.add_bomb(player.bomb_cap)
		"turret":
			main.turret.set_tier(main.turret.tier + 1)
		"magnet":
			player.magnet_radius *= 1.5
		"crit":
			player.crit_chance = minf(player.crit_chance + 0.15, 0.6)
		"velocity":
			player.bullet_speed_mult *= 1.25
		"chain":
			player.chain_chance = minf(player.chain_chance + 0.25, 0.75)
		"venom":
			player.poison_chance = minf(player.poison_chance + 0.3, 0.9)
		"guard":
			player.shield_charges = mini(player.shield_charges + 1, 3)
		"dice":
			player.luck += 0.15
			player.crit_chance = minf(player.crit_chance + 0.08, 0.75)
		"mx_pierce":
			# 形态：所有子弹 +1 穿透；修饰：伤害 +10%
			player.pierce_bonus += 1
			player.bullet_dmg_mult *= 1.1
		"mx_critboom":
			# 形态：暴击时在命中点引爆；修饰：爆炸 = 子弹伤害 60%
			player.crit_boom = true
		"mx_resocore":
			# 形态：共鸣计数源改为每拾取 3 颗源石 +1；修饰：冲击波伤害 6→9
			player.has_resocore = true
		_:
			# 防止 POOL 新增 id 却漏写分支：抽到卡没效果时立刻在日志里点名
			Dev.err("upgrades", "未知升级 id（apply 未实现）：%s" % id)
	for key in count_tag(id):
		_apply_set(String(key), player, main)


## 该升级归属的流派标签（crit 是双标签）
static func tags_of(id: String) -> Array:
	for p in POOL:
		if String(p["id"]) != id:
			continue
		var t = p.get("tag", "")
		if t is Array:
			return t
		return [t] if t != "" else []
	return []


## 记一次拾取，返回本次新达成的套装标签
static func count_tag(id: String) -> Array:
	var newly: Array = []
	for t in tags_of(id):
		var key := String(t)
		if not tag_counts.has(key):
			continue
		tag_counts[key] = int(tag_counts[key]) + 1
		if int(tag_counts[key]) >= int(TAGS[key]["need"]) and not bool(sets_active[key]):
			sets_active[key] = true
			newly.append(key)
	return newly


## 重建标签计数（读档后用），返回需要重新应用效果的套装
static func rebuild_tags() -> Array:
	for k in tag_counts.keys():
		tag_counts[k] = 0
	for k in sets_active.keys():
		sets_active[k] = false
	var newly: Array = []
	for id in taken.keys():
		for key in count_tag(String(id)):
			newly.append(key)
	return newly


## 套装质变效果
static func _apply_set(key: String, player, main: Node2D) -> void:
	match key:
		"fire":
			player.fire_rate_mult *= 1.3
			player.set_fire = true
		"elem":
			player.chain_chance = minf(player.chain_chance + 0.15, 0.9)
			player.set_elem = true
		"surv":
			player.set_surv = true
	if main != null and is_instance_valid(main.hud):
		main.hud.banner("套装达成 · %s" % TAGS[key]["name"])
	Game.sfx("powerup", 1.3)
	if main != null and is_instance_valid(main) and main._smoke:
		print("[SMOKE] set activated: %s" % key)


static func reset() -> void:
	taken.clear()
	for k in tag_counts.keys():
		tag_counts[k] = 0
	for k in sets_active.keys():
		sets_active[k] = false
