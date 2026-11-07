class_name Relics
extends RefCounted
## 遗物（被动道具）：宝箱房/Boss/商店产出，效果直接改玩家字段。

## E8″ 运行时计数探针：本入口累计消耗的随机数个数（仅供 SMOKE 校验消耗守恒）
static var rng_draws := 0

const POOL := [
	{"id": "fang", "name": "吸血獠牙", "desc": "击杀 8% 概率回复 1 生命", "icon": "relic_fang"},
	{"id": "thorn", "name": "荆棘装甲", "desc": "撞你的虫子受到 1 点反伤", "icon": "relic_thorn"},
	{"id": "bounce", "name": "弹射弹壳", "desc": "子弹可弹墙 +1 次", "icon": "relic_bounce"},
	{"id": "frost", "name": "冰霜涂层", "desc": "命中 15% 减速敌人 2 秒", "icon": "relic_frost"},
	{"id": "bigbullet", "name": "巨型弹头", "desc": "子弹更大，伤害 +15%", "icon": "relic_bigbullet"},
	{"id": "mag", "name": "加长弹匣", "desc": "所有武器弹匣 +4", "icon": "relic_mag"},
	{"id": "eye", "name": "猎手印记", "desc": "暴击率 +10%", "icon": "relic_eye"},
	{"id": "radar", "name": "六感警报", "desc": "无敌时间延长，移速 +8%", "icon": "relic_radar"},
	{"id": "drone", "name": "双浮游炮", "desc": "再召唤一座浮游炮", "icon": "relic_drone"},
	{"id": "heart", "name": "黄金心脏", "desc": "生命上限 +1 并回满", "icon": "relic_heart"},
	# ---- SPR7：局外解锁内容（增量：未解锁不进池，解锁后进池）----
	{"id": "mr_resoshield", "name": "谐振护盾", "desc": "源石共鸣爆发时获得 1 层护盾，护盾存在时免疫中毒",
		"icon": "icon_guard", "meta": "u_mr_resoshield"},
	{"id": "mr_kinetic", "name": "动能转换器", "desc": "受击后 2 秒内移速 +40%",
		"icon": "relic_drone", "meta": "u_mr_kinetic"},
]


static func by_id(id: String) -> Dictionary:
	for p in POOL:
		if p["id"] == id:
			return p
	# 未知 id：数据漂移，点名但不崩（回退第一件，图标/名字至少合法）
	Dev.err("relic", "未知遗物 id：%s（回退「%s」）" % [id, POOL[0]["id"]])
	return POOL[0]


## 可用池：只含已解锁的遗物；不足 n 条时回退全量池
## （保证大宝箱的 roll(2) 仍给 2 件，也保证随机数消耗个数与过滤前一致）
static func _usable_pool(n: int) -> Array:
	var pool := []
	for p in POOL:
		if Game.meta_content_unlocked("relic", p):
			pool.append(p.duplicate(true))
	if pool.size() < n:
		Dev.err("meta", "可用遗物不足：需要 %d，实有 %d（已回退全量池）" % [n, pool.size()])
		return POOL.duplicate(true)
	return pool


static func roll(n: int) -> Array:
	var pool := _usable_pool(n)
	var out := []
	for i in n:
		# 恒消耗 1 次：末轮池只剩 1 件时 randi_range(0, 0) 不消耗随机流；
		# 空池也不能 break 跳过消耗，否则解锁状态会改变随机流位置。
		var r: int = Game.rng.randi() % maxi(pool.size(), 1)
		rng_draws += 1
		if pool.is_empty():
			continue
		var pick: Dictionary = pool[r]
		out.append(pick)
		pool.erase(pick)
	return out


## 结算到玩家/主场景
static func apply(id: String, main: Node2D) -> void:
	var player = main.player
	player.relics.append(id)
	match id:
		"fang":
			player.lifesteal_chance += 0.08
		"thorn":
			player.thorns = true
		"bounce":
			player.bounce_count += 1
		"frost":
			player.frost_chance += 0.15
		"bigbullet":
			player.bullet_scale *= 1.4
			player.bullet_dmg_mult *= 1.15
		"mag":
			player.mag_bonus += 4
			player.refresh_mag_cap()
		"eye":
			player.crit_chance = minf(player.crit_chance + 0.10, 0.7)
		"radar":
			player.invuln_bonus += 0.3
			player.speed_base *= 1.08
		"drone":
			main.turret.add_unit()
		"heart":
			player.max_hp += 1
			player.heal(player.max_hp)
		"mr_resoshield":
			# 形态：共鸣爆发时 +1 护盾；修饰：护盾存在时免疫中毒
			player.has_resoshield = true
		"mr_kinetic":
			# 形态：受击后 2 秒内移速 +40%
			player.has_kinetic = true
		_:
			# 防止 POOL 新增 id 却漏写分支：抽到遗物没效果时立刻在日志里点名
			Dev.err("relics", "未知遗物 id（apply 未实现）：%s" % id)
