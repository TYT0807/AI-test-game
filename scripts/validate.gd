extends Node
## 启动自检：把「数据写错、贴图缺失、房间类型没接」这类问题在开局就吼出来。
## 所有检查项都进 Dev 日志，F3 面板可回看。

const KNOWN_AI := ["chase", "spitter", "bomber", "boss", "leap", "summon", "erratic", "turret", "echo"]
const KNOWN_ATLAS := ["slug", "enemy2"]
const KNOWN_ROOM_KINDS := ["start", "combat", "elite", "treasure", "shop", "boss", "secret", "super_secret", "challenge", "cursed", "shrine"]
## HUD 状态图标 key：与 Upgrades 里 guard/chain/venom 对应
const STATUS_ICON_KEYS := ["guard", "chain", "venom"]
## 面板有特殊映射的图标 key（upgrade_panel._icon_for 走专用贴图），不按 generated/图集校验
const ICON_ALIAS_KEYS := ["drone"]
## 合法的 AI 行为参数键（slug.gd 的 AI 函数只读这些）
const AI_PARAM_KEYS := ["ai_range", "ai_cd", "ai_burst", "ai_spread", "ai_bullet_speed",
	"ai_bullet_dmg", "ai_keep", "ai_dash", "ai_dash_time", "ai_n", "ai_sway", "ai_sway_amp"]
## autoload 解析期看不到全局类名，用 preload 取升级池
const UPGRADES := preload("res://scripts/upgrades.gd")
const DungeonClass := preload("res://scripts/dungeon.gd")
## 局外 meta 层（解锁树表 + 最小可用条目数）
const META := preload("res://scripts/meta.gd")
## 掉落/奖励池静态校验用（_check_payload_refs）
const WeaponsScript := preload("res://scripts/weapons.gd")
const RelicsScript := preload("res://scripts/relics.gd")
## 消费端镜像：实读 game_main.gd:_run_stats() / _settle_meta() 得到的独立期望值。
## 故意不与 Meta 共用一份常量 —— 两份独立来源才能交叉校验出坑 42 型漂移。
const CONSUMER_STATS_KEYS := ["diamonds", "kills", "max_floor", "time", "score"]
const CONSUMER_RETURN_KEYS := ["payout", "crystals"]

var problems: Array = []


func run() -> Array:
	problems.clear()
	_check_enemies()
	_check_enemy_refs()
	_check_pools()
	_check_rooms()
	_check_textures()
	_check_icons()
	_check_status_icons()
	_check_affixes()
	_check_modifiers()
	_check_upgrades()
	_check_meta()
	_check_themes()
	_check_ai_params()
	_check_contracts()
	_check_registration()
	_check_apply_ids()
	_check_payload_refs()
	_check_squads()
	_check_active_relics()
	_check_suffixes()
	_check_shrine()
	_check_codex()
	_check_abyss()
	_check_weapon_kinds()
	_check_boss_weapons()
	_check_daily()
	_check_scripts_compile()
	if OS.get_environment("SMOKE_V8") != "":
		_v8_probe()
	if problems.is_empty():
		Dev.info("validate", "自检通过：敌人 %d / 房间 %d / 地图池 %d 层" % [
			Data.ENEMIES.size(), Data.ROOM_META.size(), Data.FLOOR_POOLS.size()])
		Dev.info("validate", "meta：解锁节点 %d · 默认可用 升级%d/遗物%d/武器%d" % [
			META.UNLOCKS.size(),
			_meta_default_usable("upgrade", _meta_ids("upgrade")),
			_meta_default_usable("relic", _meta_ids("relic")),
			_meta_default_usable("weapon", _meta_ids("weapon"))])
	else:
		for p in problems:
			Dev.err("validate", p)
		print("\n========== 启动自检失败（%d 项）==========" % problems.size())
		for p in problems:
			print("  ✗ ", p)
		print("==========================================\n")
	return problems


func _check_enemies() -> void:
	for id in Data.ENEMIES:
		var e: Dictionary = Data.ENEMIES[id]
		if e.has("tex"):
			if String(e["tex"]) == "" or Assets.monster(String(e["tex"])) == null:
				problems.append("敌人 %s 的贴图缺失：%s" % [id, e.get("tex", "")])
		else:
			if not KNOWN_ATLAS.has(e.get("atlas", "")):
				problems.append("敌人 %s 的 atlas 非法：%s" % [id, e.get("atlas", "<空>")])
			if int(e.get("row", -1)) < 0:
				problems.append("敌人 %s 缺 row" % id)
		if not KNOWN_AI.has(e.get("ai", "")):
			problems.append("敌人 %s 的 ai 未实现：%s" % [id, e.get("ai", "<空>")])
		if float(e.get("hp", 0)) <= 0.0:
			problems.append("敌人 %s 血量非正" % id)


## 引用型字段：split / summon 指向的敌人必须存在（启动期就抓，别等玩家打到才报）
func _check_enemy_refs() -> void:
	for id in Data.ENEMIES:
		var e: Dictionary = Data.ENEMIES[id]
		for field in ["split", "summon"]:
			var ref: String = String(e.get(field, ""))
			if ref != "" and not Data.ENEMIES.has(ref):
				problems.append("敌人 %s 的 %s 引用了不存在的敌人：%s" % [id, field, ref])


func _check_pools() -> void:
	_check_pool_dict(Data.FLOOR_POOLS)
	for id in Data.FLOOR_POOL_FALLBACK:
		if not Data.ENEMIES.has(id):
			problems.append("兜底刷怪池引用了不存在的敌人：%s" % id)


## V8 可注入：对任意池字典跑同一套校验（问题写进 problems）
func _check_pool_dict(pools: Dictionary) -> void:
	for f in pools:
		var pool: Dictionary = pools[f]
		if pool.is_empty():
			problems.append("第 %d 层刷怪池为空" % f)
		for id in pool:
			if not Data.ENEMIES.has(id):
				problems.append("第 %d 层刷怪池引用了不存在的敌人：%s" % [f, id])


## V8 显式负向用例：构造空刷怪池，证明 _check_pool_dict 拦截生效
func _v8_probe() -> void:
	var bad := {99: {}}
	var saved := problems.duplicate()
	problems.clear()
	_check_pool_dict(bad)
	var caught := false
	for p in problems:
		if String(p).contains("第 99 层刷怪池为空"):
			caught = true
	problems = saved
	Dev.check(caught, "v8", "空池注入被 _check_pool_dict 拦截：%s" % ("通过" if caught else "未拦截！"))
	if caught:
		Dev.info("v8", "负向用例通过：空池拦截 + 恢复无误报")


## F3 编队模板校验：成员 id/词缀引用、数量、权重、起始层
func _check_squads() -> void:
	for sid in Data.SQUADS:
		var s: Dictionary = Data.SQUADS[sid]
		if int(s.get("weight", 0)) < 1:
			problems.append("编队 %s 权重非法" % sid)
		if int(s.get("min_floor", 0)) < 1:
			problems.append("编队 %s min_floor 非法" % sid)
		for m in s.get("members", []):
			var mid: String = String(m.get("id", ""))
			if not Data.ENEMIES.has(mid):
				problems.append("编队 %s 引用了不存在的敌人：%s" % [sid, mid])
			var aff: String = String(m.get("affix", ""))
			if aff != "" and not Data.AFFIXES.has(aff):
				problems.append("编队 %s 成员 %s 引用了不存在的词缀：%s" % [sid, mid, aff])
			if int(m.get("count", 0)) < 1:
				problems.append("编队 %s 成员 %s 数量非法" % [sid, mid])


## F2 主动遗物校验（T4 契约键 / T6 动作注册 / T9 效果分支覆盖）
func _check_active_relics() -> void:
	for id in Data.ACTIVE_RELICS:
		var r: Dictionary = Data.ACTIVE_RELICS[id]
		if float(r.get("cd", 0)) <= 0.0:
			problems.append("主动遗物 %s 冷却非法" % id)
		var ka := String(r.get("key_action", ""))
		if not Assets.ACTION_DEFS.has(ka):
			problems.append("主动遗物 %s 的按键动作未注册：%s" % [id, ka])
		var kind := String(r.get("effect_kind", ""))
		if not ["shield", "dash", "volley", "toxic"].has(kind):
			problems.append("主动遗物 %s effect_kind 未知：%s" % [id, kind])


## F2/A 反应词缀表校验：trigger 枚举、遗物引用、效果分支
func _check_suffixes() -> void:
	for sid in Data.RELIC_SUFFIXES:
		var s: Dictionary = Data.RELIC_SUFFIXES[sid]
		if not ["ON_SHIELD_BREAK", "ON_DASH_START", "ON_VOLLEY_FIRE", "ON_POISON_TICK"].has(String(s.get("trigger", ""))):
			problems.append("词缀 %s trigger 非法：%s" % [sid, s.get("trigger", "")])
		if not Data.ACTIVE_RELICS.has(String(s.get("relic", ""))):
			problems.append("词缀 %s 引用了不存在的遗物：%s" % [sid, s.get("relic", "")])
		if not ["theme_hazard", "heal", "slow_all", "brief_shield"].has(String(s.get("effect", ""))):
			problems.append("词缀 %s effect 未知：%s" % [sid, s.get("effect", "")])
		if float(s.get("cd", 0)) <= 0.0:
			problems.append("词缀 %s 冷却非法" % sid)


## Sprint 13 A：圣所表自洽（id 唯一 / 代价类型合法 / min_floor 有值 / 房型+里程碑登记）
func _check_shrine() -> void:
	var seen := {}
	var legal_costs := ["", "diamonds", "max_hp", "score"]
	for id in Data.SHRINE_OFFERS:
		if seen.has(id):
			problems.append("SHRINE_OFFERS 重复 id：%s" % id)
		seen[id] = true
		var o: Dictionary = Data.SHRINE_OFFERS[id]
		if not legal_costs.has(String(o.get("cost_kind", ""))):
			problems.append("圣所 %s 代价类型非法：%s" % [id, o.get("cost_kind", "")])
		if int(o.get("cost", 0)) < 0:
			problems.append("圣所 %s 代价为负" % id)
		if int(o.get("min_floor", 0)) < 1:
			problems.append("圣所 %s 缺 min_floor" % id)
	if not Data.ROOM_META.has("shrine"):
		problems.append("shrine 房型缺 ROOM_META 元信息")
	if not Data.MILESTONES.has("first_shrine"):
		problems.append("缺 first_shrine 里程碑文案")
	# 圣所分配确定性抽查：floor>=3 每层恰 1 间 shrine、floor<3 无（Sprint 13 A；
	# 本地 rng 固定种子，不消费 Game.rng——E1 零影响）
	var drng := RandomNumberGenerator.new()
	drng.seed = 20261107
	for fn in [1, 2, 3, 5, 9]:
		var d := DungeonClass.generate(fn, drng, 9)
		var n := 0
		for c in d.rooms:
			if String(d.rooms[c].get("kind", "")) == "shrine":
				n += 1
		if fn < 3 and n != 0:
			problems.append("floor %d 不应有圣所（实得 %d 间）" % [fn, n])
		if fn >= 3 and n != 1:
			problems.append("floor %d 应恰 1 间圣所（实得 %d 间）" % [fn, n])
		# B4【断言性质：前提守卫型恒过】shrine 恒非起点房——_enter_room 早于 _roll_calamity
		# 的时序不对称当前无害依赖此条；生成规则不变则本断言恒过，其价值在「前提被破坏时
		# 当场报错」而非每日回归信号。未来放宽房型/分配规则时在此报错（锁前提，不改时序 → 零 E1 漂移）
		# 【Sprint 17 B 复核】维持「前提守卫型恒过」分类，不需补强；本批只补标注，不改断言逻辑。
		for c in d.rooms:
			if String(d.rooms[c].get("kind", "")) == "shrine" and c == Vector2i.ZERO:
				problems.append("floor %d 的 shrine 落在起点房 Vector2i.ZERO（B4 前提被破坏）" % fn)


## Sprint 13 C：图鉴结构自洽（kinds 分类齐 / last_run 存在 / 校验器与数据表对齐）
func _check_codex() -> void:
	for k in Game.CODEX_KINDS:
		if not Game.codex.has(k):
			problems.append("codex 缺少分类：%s" % k)
	if not Game.codex.has("last_run"):
		problems.append("codex 缺少 last_run")
	if not Game._codex_id_valid("enemies", "goblin"):
		problems.append("codex 校验器误拒合法敌人 id：goblin")
	if Game._codex_id_valid("enemies", "no_such_enemy"):
		problems.append("codex 校验器接受了未知敌人 id")
	if not Game._codex_id_valid("themes", "toxic"):
		problems.append("codex 校验器误拒合法主题 rule：toxic")
	if not Data.RELIC_SUFFIXES.is_empty():
		var some_sid: String = String(Data.RELIC_SUFFIXES.keys()[0])
		if not Game._codex_id_valid("suffixes", some_sid):
			problems.append("codex 校验器误拒合法词缀 id：%s" % some_sid)
	# Sprint 19 A：shrine 第六类白名单正反两向（合法 id = SHRINE_OFFERS 键集）
	if not Game._codex_id_valid("shrine", "blood_relic"):
		problems.append("codex 校验器误拒合法圣所 id：blood_relic")
	if Game._codex_id_valid("shrine", "no_such_offer"):
		problems.append("codex 校验器接受了未知圣所 id")
	# Sprint 20 A：FLAVOR 全六类覆盖门——每个可发现 id 都要有手记，缺一条即「表不齐」
	# （与 icon_codex 同根的防漏门；计数按 "/" 前缀分桶）
	var fcount := {}
	for fk in Data.FLAVOR:
		fcount[String(fk).split("/")[0]] = int(fcount.get(String(fk).split("/")[0], 0)) + 1
	var fexpect := {"enemies": Data.ENEMIES.size(), "relics": Relics.POOL.size(),
		"suffixes": Data.RELIC_SUFFIXES.size(), "themes": Data.FLOOR_THEMES.size(),
		"bosses": Data.codex_bosses_total(), "shrine": Data.SHRINE_OFFERS.size()}
	for fk in fexpect:
		if int(fcount.get(fk, 0)) != int(fexpect[fk]):
			problems.append("FLAVOR %s 覆盖不全：%d/%d" % [fk, int(fcount.get(fk, 0)), int(fexpect[fk])])
	# 图标登记断言：PNG 已生成但 GEN_NAMES 漏登记 = Assets.g() 返回 null → 静默白框（核验 🟡 修复）
	if Assets.g("icon_codex") == null:
		problems.append("icon_codex 已生成但未登记 GEN_NAMES（Assets.g 返回 null → 主菜单图鉴按钮静默白框）")
	# 【Sprint 17 B 断言性质：前提守卫型恒过】当前 CODEX_BOONS 四档 kind 均非 suffixes（data.gd），
	# 本遍历门恒过；价值在「未来扩表误把 suffixes 当阈值」时启动期当场报错，不是每日回归信号。
	# 真防线是本门（判据端切链）；player.gd SMOKE_CODEX_BOON「派生不变」断言同属前提守卫型。
	# Sprint 15 P0 红线（判据端切链）：CODEX_BOONS.kind 不得为 "suffixes"——
	# 否则「送词缀 → mark_codex → 发现度上升 → 更多 boon」正反馈自激。
	# 若产品确需 suffixes 阈值，须改用「不回写图鉴的内部绑定路径」（草案 §3.1 备选）并重做此门
	for bid in Data.CODEX_BOONS:
		if String(Data.CODEX_BOONS[bid].get("kind", "")) == "suffixes":
			problems.append("CODEX_BOONS.%s 以 suffixes 为阈值（boon 自激正反馈——P0 红线）" % bid)
	# Sprint 19 §九-2 P0 防线：CODEX_BOONS.kind 不得为 "shrine"——防「交换 → 加 boon → 更易交换」
	# 正反馈（与上面 suffixes 禁令同型）。shrine 是第六类发现集，不是阈值类别。
	# 【断言性质：前提守卫型恒过】当前四档 kind 均非 shrine，价值在「未来扩表误把 shrine 当阈值」时报错。
	for bid in Data.CODEX_BOONS:
		if String(Data.CODEX_BOONS[bid].get("kind", "")) == "shrine":
			problems.append("CODEX_BOONS.%s 以 shrine 为阈值（交换→boon 正反馈——P0 红线）" % bid)
	# Sprint 16 A：誓约表与印记一一对应（锚点即装备印记）
	if Data.OATH_CONDITIONS.size() != Data.SIGILS.size():
		problems.append("OATH_CONDITIONS 应与 SIGILS 一一对应（%d vs %d）" % [Data.OATH_CONDITIONS.size(), Data.SIGILS.size()])
	for sid in Data.SIGILS:
		if not Data.OATH_CONDITIONS.has(sid):
			problems.append("誓约缺印记对应条目：%s" % sid)
		elif (Data.OATH_CONDITIONS[sid]["watched"] as Array).is_empty():
			problems.append("誓约 %s 无监听事件" % sid)
	# Sprint 16 D：FLAVOR 覆盖三主题 Boss（防「表写了没接上」——文案不入分母/白名单）
	for bid in Data.CODEX_BOSS_NAMES:
		if not Data.FLAVOR.has("bosses/" + bid):
			problems.append("FLAVOR 缺主题 Boss 手记：%s" % bid)


## Sprint 17 C：每日分享码格式/校验位 + DAILY_PATH 读档容错 + 主菜单显示文本（纯只读，不写盘）
## Sprint 21 C：深渊难度档乘子表自洽门（tier 单调 / 乘子>0 / 无 NaN / 尺寸==ABYSS_MAX_TIER）
func _check_abyss() -> void:
	if not (Data.ABYSS_TIERS is Dictionary):
		problems.append("ABYSS_TIERS 必须为 Dictionary")
		return
	if int(Data.ABYSS_MAX_TIER) <= 0:
		problems.append("ABYSS_MAX_TIER 必须为正整数")
	if Data.ABYSS_TIERS.size() != int(Data.ABYSS_MAX_TIER):
		problems.append("ABYSS_TIERS 尺寸 %d 不等于 ABYSS_MAX_TIER %d" % [Data.ABYSS_TIERS.size(), int(Data.ABYSS_MAX_TIER)])
	var prev_hp := 0.0
	var prev_speed := 0.0
	var prev_dmg := 0.0
	for t in range(1, int(Data.ABYSS_MAX_TIER) + 1):
		if not Data.ABYSS_TIERS.has(t):
			problems.append("ABYSS_TIERS 缺 tier %d" % t)
			continue
		var row: Dictionary = Data.ABYSS_TIERS[t]
		for k in ["hp", "speed", "dmg"]:
			if not row.has(k):
				problems.append("ABYSS_TIERS[%d] 缺 %s" % [t, k])
				continue
			var v: float = float(row[k])
			if not is_finite(v) or v <= 0.0:
				problems.append("ABYSS_TIERS[%d].%s 非法（%s）" % [t, k, str(v)])
		if not (row.has("hp") and row.has("speed") and row.has("dmg")):
			continue
		var hp: float = float(row["hp"])
		var speed: float = float(row["speed"])
		var dmg: float = float(row["dmg"])
		if t > 1 and (hp < prev_hp or speed < prev_speed or dmg < prev_dmg):
			problems.append("ABYSS_TIERS tier %d 乘子非单调非减" % t)
		prev_hp = hp
		prev_speed = speed
		prev_dmg = dmg


## S38 T-M M3 ＋ T-N 的源码侧闸：形态判别（V-A1/A2/A3）与近战抽取守恒（HP-2/HP-3）的静态门。
## 🔴 三段各有各自的反证刀，⛔ 拿「DEFS 里还没近战」当这一段无缺口：
##    · kind 覆盖段查的是**存量 21 条**，今天就有牙（少一条 kind 立刻红）；
##    · 字段齐全段在 T-O 落数据前是**空转**（0 条非 projectile 可查），性质＝待触发，⛔ 记作 PASS；
##    · 源码段查 `_swing()` 本体，_swing 还没落地时直接报问题（不是跳过）——这就是 T-N 的开工闸。
## ⛔ 字段名与形态名一律从 Weapons.MELEE_FIELDS / KIND_* 取，本函数内不手写第二个名单（两套账必漂移）。
func _check_weapon_kinds() -> void:
	var defs: Dictionary = WeaponsScript.DEFS
	var allowed: Array = WeaponsScript.KIND_PROJECTILE + WeaponsScript.KIND_MELEE
	var extra_outside := []
	var n_melee := 0
	for wid in defs:
		var d: Dictionary = defs[wid]
		var k := String(d.get("kind", ""))
		if k == "":
			problems.append("武器 %s 的 DEFS 缺 kind：%s" % [String(wid),
				"分派侧读 [\"kind\"] 当场崩、读 get(\"kind\",\"\") 静默当 projectile——V-A1 边界态点名「不得静默」"])
			continue
		if not allowed.has(k):
			problems.append("武器 %s 的 kind「%s」不在允许集合 %s（自创形态名＝分派两不靠，挥出去没人结算）" % [
				String(wid), k, str(allowed)])
			continue
		if WeaponsScript.is_melee_kind(k):
			n_melee += 1
			for f in WeaponsScript.MELEE_FIELDS:
				if not d.has(f):
					problems.append("非弹幕 %s（kind=%s）缺 MELEE_FIELDS 里的 %s：口径 V-A3「缺任一⇒该把不可装备，⛔ 回退 rifle 参数」" % [
						String(wid), k, String(f)])
			if int(d.get("reach", 0)) <= 0:
				problems.append("非弹幕 %s 的 reach=%s 须 >0：0 距离的扇形扫不到任何敌人，命中面恒空" % [
					String(wid), str(d.get("reach", 0))])
			var arc := float(d.get("arc_deg", 0.0))
			if arc <= 0.0 or arc > 180.0:
				problems.append("非弹幕 %s 的 arc_deg=%f 须 ∈ (0,180]：>180 的扇形角度判据会翻面，360 就成了环盾 AoE（实稿 §3.2）" % [
					String(wid), arc])
			if float(d.get("interval", 0.0)) <= 0.0:
				problems.append("非弹幕 %s 的 interval=%f 须 >0：0 射速＝每物理帧一抽（E1 守恒数被帧数绑架）" % [
					String(wid), float(d.get("interval", 0.0))])
			if int(d.get("mag", 0)) < 1:
				problems.append("非弹幕 %s 的 mag=%d 须 >=1：配额 0＝永远在过载，第一次挥击就交不出去" % [
					String(wid), int(d.get("mag", 0))])
			if float(d.get("reload", 0.0)) <= 0.0:
				problems.append("非弹幕 %s 的 reload=%f 须 >0：0 复位＝架式配额没有代价，「不能无限连挥」的设计落空" % [
					String(wid), float(d.get("reload", 0.0))])
			# V-A3 后半：规格外字段——「出现了不报错，但报告点名」，所以进打印不进 problems。
			for xf in ["count", "spread", "speed", "life", "pierce", "explosive"]:
				if d.has(xf):
					extra_outside.append("%s.%s" % [String(wid), xf])
	# ── 源码侧：_swing() 本体与分派单源（T-N N1/N2；HP-2 恒 1 抽、HP-3 三种规避写法）──
	var pl_src := _strip_comments(FileAccess.get_file_as_string("res://scripts/player.gd"))
	var swing := _slice(pl_src, "func _swing(", "\n\nfunc ")
	if swing == "":
		problems.append("player.gd 找不到 _swing()：真·非弹幕三种形态没有结算入口（V-A2 与 HP-2 都无从判起）")
	else:
		if swing.contains("spawn_player_bullet"):
			problems.append("_swing() 里出现 spawn_player_bullet：近战＝伪近战（V-A2「melee 任意一次挥击产生子弹即红」的源码侧同账）")
		if swing.contains("Game.fx_rng.randf"):
			problems.append("_swing() 用 fx_rng 取判定数：HP-3 禁第②条（fx_rng 是表现层种子，那样 Game.rng 那格仍然空着）")
		var draws := swing.count("Game.rng.randf(")
		if draws != 1:
			problems.append("_swing() 里 Game.rng.randf( 出现 %d 次：HP-2 要「每次动作恒消费恰 1 次」，0＝整条随机流前移一格、2＝后移（V-E1d 两把刀）" % draws)
		var top_level := false
		for ln in swing.split("\n"):
			if String(ln).contains("Game.rng.randf("):
				top_level = String(ln).begins_with("\t") and not String(ln).begins_with("\t\t")
				break
		if draws > 0 and not top_level:
			problems.append("_swing() 的 randf 不在函数体顶层（被缩进＝它进了某个分支）：HP-3 禁第③条「没打中就不抽」的字面形态")
		if not swing.contains("melee_rng_draws += 1"):
			problems.append("_swing() 未累加 melee_rng_draws：计数器与真实抽取两套账，守恒断言只能自证（V-E1a 假绿面）")
		if not swing.contains("_stance_open()"):
			problems.append("_swing() 没走 _stance_open() 这个架式窗口共用入口（实施单 B1 约束：近战⛔ 另起一套窗口）")
	var aim := _slice(pl_src, "func _update_aim_and_fire(", "\n\nfunc ")
	if not aim.contains("_swing()") or not aim.contains("_fire()"):
		problems.append("_update_aim_and_fire 未按形态分派到 _swing()/_fire()：近战没有触发路径（N2）")
	if not aim.contains("is_melee_kind"):
		problems.append("分派没走 Weapons.KIND_MELEE 单源（形态名散写在 if 里＝validate 查一份、player 认另一份）")
	print("[S38-A1] DEFS %d 条 kind 全覆盖 · 真·非弹幕 %d 条（字段/范围查 %d 条规格外字段）· _swing 源码段=%s" % [
		defs.size(), n_melee, extra_outside.size(), "已落地" if swing != "" else "缺失"])
	if not extra_outside.is_empty():
		print("[S38-A3] 规格外字段（V-A3 只点名不判红）：[%s]" % ", ".join(extra_outside))


## Sprint 36 T-C3：Boss 专武「一部分性能比 Boss 还强」的死值断言（实稿 §7.2／实施单 C3）。
## 🔴 dps 一律从 Weapons.DEFS 与 Data.BOSS_PULSE_BASE **现算**，⛔ 把 §7.2 那几个 0.667/0.909/0.769
##    抄进代码——抄进来就成了「断言自证自己」，改 Boss 脉冲不会红（AGENTS §5「前提守卫型恒过」）。
## ⛔ 也不写死「14 把」这种名单数：那是实稿 §6.3 的事，增删一把专武不该把这道门判红（GUARD-1 同型缺陷）。
func _check_boss_weapons() -> void:
	var defs: Dictionary = WeaponsScript.DEFS
	var own: Dictionary = WeaponsScript.BOSS_WEAPON
	var per_total := {}
	var per_surpass := {}
	for wid in own:
		var id := String(wid)
		if not defs.has(id):
			problems.append("BOSS_WEAPON 指向 DEFS 里没有的专武：%s（掉落会给到未知 id → give_weapon 静默回退 rifle）" % id)
			continue
		var bid := String(own[id])
		if not Data.CODEX_BOSS_NAMES.has(bid):
			problems.append("专武 %s 的归属 Boss「%s」不在 CODEX_BOSS_NAMES 三键里" % [id, bid])
			continue
		if not Data.BOSS_PULSE_BASE.has(bid):
			problems.append("Data.BOSS_PULSE_BASE 缺 Boss「%s」的脉冲基准，反超无从比较" % bid)
			continue
		var w: Dictionary = defs[id]
		if not w.has("dmg") or not w.has("interval") or float(w["interval"]) <= 0.0:
			problems.append("专武 %s 缺 dmg/interval 或 interval<=0：§7.2 的反超口径要求每条 bw_* 都有这两个字段" % id)
			continue
		if w.has("meta"):
			problems.append("专武 %s 带了 meta 键「%s」：W3=A 裁定不给专武建 UNLOCKS 节点，建了就把「无限制」重新变成收费" % [id, w["meta"]])
		per_total[bid] = int(per_total.get(bid, 0)) + 1
		var p: Dictionary = Data.BOSS_PULSE_BASE[bid]
		var dps_boss: float = float(p["dmg"]) / float(p["interval"])
		var dps_w: float = float(w["dmg"]) / float(w["interval"])
		if dps_w >= dps_boss * Data.WEAPON_SURPASS_RATIO:
			per_surpass[bid] = int(per_surpass.get(bid, 0)) + 1
		elif dps_w > dps_boss:
			problems.append("专武 %s 落进灰区：dps %.3f 没到反超线 %.3f 却高于 Boss 自身 %.3f（C3 要求非反超把须 <= dps_boss）" % [
				id, dps_w, dps_boss * Data.WEAPON_SURPASS_RATIO, dps_boss])
	# bw_ 前缀但没归属＝定向掉落永远抽不到它（名单与表脱钩的静默半截活）
	for id in defs:
		var sid := String(id)
		if sid.begins_with("bw_") and not own.has(sid):
			problems.append("bw_ 专武 %s 未登记进 BOSS_WEAPON（有定义、无归属 → 永远不掉落）" % sid)
	# 专武不得挤进随机池：DROP_POOL 是商店/大宝箱/旧 Boss 房的共用入口（W3=A 的补偿条款）
	for pid in WeaponsScript.DROP_POOL:
		if String(pid).begins_with("bw_"):
			problems.append("专武 %s 进了 DROP_POOL：那会把「定向掉落」重新变成随机掉落，且牵动 random_unlocked() 的取模分母" % pid)
	# 每组恰好 2 把反超（实施单 C3），且组不能空到「一部分」不成立
	for bid in Data.CODEX_BOSS_NAMES:
		var total := int(per_total.get(bid, 0))
		var surpass := int(per_surpass.get(bid, 0))
		if total == 0:
			problems.append("Boss「%s」名下没有任何专武，但 BOSS_WEAPON 本应覆盖三只主题 Boss" % bid)
			continue
		if total < 3:
			problems.append("Boss「%s」的专武只有 %d 把，「一部分性能更强」在 1–2 把组里没有意义" % [bid, total])
		if surpass != 2:
			problems.append("Boss「%s」的专武反超把数 = %d，口径要求恰好 2（R=%.2f，abyss_tier=0 取表值）" % [
				bid, surpass, Data.WEAPON_SURPASS_RATIO])
	# 🔴 C3 补漏（运行时闭环）：上面全绿只证明「表」自洽，不证明掉落侧查这张表时拿对了 key。
	#    BOSS_WEAPON 的 key 是 CODEX_BOSS_NAMES 三键，而 Data.boss_for_floor 返回的是主题 Boss id
	#    （skeleton_king / demon / dragon / boss），两个集合无交集 ⇒ 子集恒空 ⇒ 静默退回随机池，
	#    T-B3「一枪没响」而表门一条不红。这里把「掉落侧的 Boss id 从哪儿来」钉成机检。
	var main_src := FileAccess.get_file_as_string("res://scripts/game_main.gd")
	var drop_fn := _strip_comments(_slice(main_src, "func _boss_weapon_drop(", "func _codex_boss_at_floor("))
	if drop_fn == "":
		problems.append("game_main.gd 找不到 _boss_weapon_drop()：Boss 房定向掉落没有实现入口")
	elif drop_fn.contains("Data.boss_for_floor"):
		problems.append("_boss_weapon_drop() 拿 Data.boss_for_floor 当 Boss id：那是主题 Boss id，与 CODEX_BOSS_NAMES 三键无交集 ⇒ 专武子集恒空、定向掉落静默退回随机池")
	elif not drop_fn.contains("_codex_boss_at_floor("):
		problems.append("_boss_weapon_drop() 没走 _codex_boss_at_floor()：Boss id 来源失去单点，掉落侧无法与生成侧对账")
	elif not drop_fn.contains('stable_hash("%s#%d"'):
		problems.append("_boss_weapon_drop() 的 key 拼法偏离 HP-3：须 Game.stable_hash(\"%s#%d\" % [key, i])（与 :1795／:4063 同源），自创拼法＝同局同层重打不再可复现")
	var map_fn := _strip_comments(_slice(main_src, "func _codex_boss_at_floor(", "func _arena_center("))
	if map_fn == "":
		problems.append("game_main.gd 找不到 _codex_boss_at_floor()：定向掉落缺「本层是哪只主题 Boss」的单源")
	else:
		for bid2 in Data.CODEX_BOSS_NAMES:
			var id2 := String(bid2)
			if not map_fn.contains('"' + id2 + '"'):
				problems.append("_codex_boss_at_floor() 不返回 Boss「%s」：这只的主题 Boss 层永远不掉专武（表有货、路不通）" % id2)
			var subset: Array = WeaponsScript.boss_weapon_ids(id2)
			if subset.is_empty():
				problems.append("Boss「%s」经 _codex_boss_at_floor 能取到、但子集为空：归属表与三键脱钩" % id2)
			for one in subset:
				if not String(one).begins_with("bw_"):
					problems.append("Boss「%s」的子集里混进了非专武 %s：商店／大宝箱的货会从这里漏进 Boss 房" % [id2, one])
		# 优先链必须与 _enter_room 生成侧同序（third > sovereign > warden）：27/59 层三只 Boss 的判定同时命中，
		# 顺序颠倒 = 掉的是另一只的专武，静态表照样全绿。
		var p_third := map_fn.find("_is_third_floor(")
		var p_sov := map_fn.find("_is_sovereign_floor(")
		var p_war := map_fn.find("_is_warden_floor(")
		if p_third < 0 or p_sov < 0 or p_war < 0:
			problems.append("_codex_boss_at_floor() 缺生成侧判定（third/sovereign/warden 三选一没出现）：会与 _enter_room 的 Boss 生成脱钩")
		elif not (p_third < p_sov and p_sov < p_war):
			problems.append("_codex_boss_at_floor() 优先链与生成侧不一致（应为 third→sovereign→warden）：共判层会掉到另一只 Boss 的专武上")
	# 🔴 补集陷阱：查不到本场 Boss 时子集必须是空表（调用方据此退回旧路径）。
	#    boss_weapon_ids 内部拿 `BOSS_WEAPON.get(id, "")` 比对，默认值正是空串——不挡这一刀，
	#    「未登记归属」的全部武器（四把基础枪＋三把 mw_*）就被当成这只 Boss 的专武，
	#    常规 Boss 房当场换掉掉落来源，而静态表门一条不红。key 用 ""＋主题 Boss id 两种真实取值。
	for bad_bid in ["", String(Data.boss_for_floor(1)), String(Data.boss_for_floor(5))]:
		if not WeaponsScript.boss_weapon_ids(bad_bid).is_empty():
			problems.append("boss_weapon_ids(\"%s\") 返回非空子集：补集泄漏——没归属的武器被当成某只 Boss 的专武，常规 Boss 房掉落来源被换掉" % bad_bid)
	print("[S36-C3] 定向掉落闭环：boss_id 单源=_codex_boss_at_floor，三键可达，优先链 third<sovereign<warden")


func _check_daily() -> void:
	var code := Game.daily_share_code()
	if not code.begins_with(Game.daily_key() + "-"):
		problems.append("每日分享码未以今日日期键开头：%s" % code)
	if not Game.daily_share_code_valid(code):
		problems.append("每日分享码校验位不匹配：%s" % code)
	if Game.daily_share_code_valid(code + "0"):
		problems.append("每日分享码篡改未被拦截")
	if Game.daily_share_code_key(code) != Game.daily_key():
		problems.append("每日分享码日期键读回不一致")
	# 坏档降级：非 Array / 非 Dictionary / 非法 key / 负数值 四类输入都必须安全返回空数组
	for bad in ["garbage", 42, {"x": 1}, [1, "x", {"key": "bad", "layers": -1, "time": -1.0}]]:
		var h := Game.sanitize_daily_history(bad)
		if not (h is Array) or not h.is_empty():
			problems.append("daily 历史坏档降级失败：%s" % str(bad))
	var hist := Game.daily_history()
	if not (hist is Array) or hist.size() > 7:
		problems.append("DAILY_PATH 读档返回的本地榜非法（应为 ≤7 条 Array）")
	for e in hist:
		if not (e is Dictionary) or String(e.get("key", "")).length() != 8 \
				or int(e.get("layers", 0)) < 0 or float(e.get("time", 0.0)) < 0.0:
			problems.append("DAILY_PATH 本地榜条目非法：%s" % str(e))
	# 主菜单显示文本同源校验（不建 UI 节点，避免启动期碰菜单树）
	var shown := Game.daily_history_text()
	if not shown.begins_with("近 7 日：") or shown.is_empty():
		problems.append("每日本地榜显示文本异常：%s" % shown)
	# Sprint 17 QA 补强 Major#1：主菜单挂接线源码回读。
	# SMOKE 下 menu._ready 走 show_page("")，_build_main_page() 从不执行；探针用脱离树
	# holder 直调 build_daily_share_widgets() → 删掉挂接行四门控与断言仍全绿。
	# 启动期锁挂接字符串（照 _check_contracts 的源码回读范式），零生产逻辑改动、零并发风险。
	var menu_src := FileAccess.get_file_as_string("res://scripts/menu.gd")
	var main_page_src := _slice(menu_src, "func _build_main_page()", "func build_daily_share_widgets(")
	if main_page_src == "" or not main_page_src.contains("build_daily_share_widgets(left)"):
		problems.append("主菜单 _build_main_page 未挂接 build_daily_share_widgets(left)（挂接线断开）")
	if Game.daily_path() == "":
		problems.append("daily_path 为空")


## 启动期全脚本编译扫描：load() 即编译，解析错误在此点名。
## --check-only --script 对非 autoload 脚本会假报 autoload 标识符缺失，本扫描在
## autoload 全部就位的运行环境里执行，无假阳性，修完即知、不用再翻 --check-only 噪声。
func _check_scripts_compile() -> void:
	var dir := DirAccess.open("res://scripts")
	if dir == null:
		problems.append("无法打开 res://scripts 目录（编译扫描跳过）")
		return
	var bad: Array = []
	var total := 0
	for f in dir.get_files():
		if not f.ends_with(".gd"):
			continue
		total += 1
		var s = load("res://scripts/" + f)
		if s == null or not (s is GDScript) or not s.can_instantiate():
			bad.append(f)
	if bad.is_empty():
		Dev.info("validate", "脚本编译扫描 %d/%d 通过" % [total, total])
	else:
		problems.append("脚本编译失败：%s" % ", ".join(PackedStringArray(bad)))


## 掉落/奖励池的静态引用与唯一性校验（A3 同批）：未知 id 在运行期会回退+告警，这里在启动期点名
func _check_payload_refs() -> void:
	for id in WeaponsScript.DROP_POOL:
		if not WeaponsScript.DEFS.has(id):
			problems.append("武器掉落池 DROP_POOL 引用了不存在的武器：%s" % id)
	var seen := {}
	for p in RelicsScript.POOL:
		var rid: String = p["id"]
		if seen.has(rid):
			problems.append("遗物池 id 重复：%s" % rid)
		seen[rid] = true
	var up_seen := {}
	for p in UPGRADES.POOL:
		var uid: String = p["id"]
		if up_seen.has(uid):
			problems.append("升级池 id 重复：%s" % uid)
		up_seen[uid] = true
		for t in UPGRADES.tags_of(uid):
			if not UPGRADES.TAGS.has(String(t)):
				problems.append("升级 %s 引用了未知流派标签：%s" % [uid, t])


func _check_rooms() -> void:
	for k in KNOWN_ROOM_KINDS:
		if not Data.ROOM_META.has(k):
			problems.append("房间类型 %s 缺少元信息（小地图会没颜色）" % k)


func _check_textures() -> void:
	var need := ["prop_barrel", "prop_barrel_hit", "prop_totem", "prop_spike",
		"prop_pillar", "secret_wall", "merchant_0", "merchant_1", "merchant_2"]
	for n in need:
		if Assets.g(n) == null:
			problems.append("缺少贴图 generated/%s.png" % n)
	if Assets.T_ENEMY2 == null:
		problems.append("缺少贴图 虫群2.png")


func _check_icons() -> void:
	for id in Relics.POOL:
		if Assets.g(String(id["icon"])) == null:
			problems.append("遗物 %s 的图标缺失：%s" % [id["id"], id["icon"]])
	# 图标 key 集中登记：HUD 状态三项 + dice + 升级池全部 icon，避免新增 key 漏检
	var icon_keys: Array = STATUS_ICON_KEYS + ["dice"]
	for p in UPGRADES.POOL:
		var k: String = String(p.get("icon", ""))
		if k != "" and not ICON_ALIAS_KEYS.has(k) and not icon_keys.has(k):
			icon_keys.append(k)
	for key in icon_keys:
		if Assets.g("icon_" + key) == null and not Assets.ICON_RECTS.has(key):
			problems.append("扩展图标缺失：icon_%s" % key)
	# 武器图标静态门（GUARD-2）：`Weapons.icon()` 写错 key 只静默回退 rifle 贴图（weapons.gd:68-72），
	# 那条回退本身「不报错」，所以只能在启动自检里咬；UNLOCKS 侧的 _meta_icon 门管不到 DEFS 侧。
	# 判的是「登记过 ＋ 解析得出」，不是一图标一武器——mw_cluster 复用 wpn_fushe 是合法先例。
	for wid in WeaponsScript.DEFS:
		var wicon := String(WeaponsScript.DEFS[wid].get("icon", ""))
		if wicon == "":
			problems.append("武器 %s 缺 icon 字段" % wid)
		elif not Assets.GEN_NAMES.has(wicon):
			problems.append("武器 %s 的图标 %s 未登记进 Assets.GEN_NAMES（漏登记＝屏上白框、只 push_warning）" % [wid, wicon])
		elif Assets.g(wicon) == null:
			problems.append("武器 %s 的图标 %s 解析不出贴图：generated/%s.png 不在盘上" % [wid, wicon, wicon])


## HUD 状态图标必须存在且只经 xicon 取用；SMOKE_RG7 下额外验证不存在 key 的白图回退（坑 7）
func _check_status_icons() -> void:
	for key in STATUS_ICON_KEYS:
		var t: Texture2D = Assets.xicon(key)
		if t == null:
			problems.append("HUD 状态图标缺失：%s" % key)
	if OS.get_environment("SMOKE_RG7") == "":
		return
	var fallback: Texture2D = Assets.xicon("__rg7_missing_key__")
	Dev.check(fallback == Assets.white_tex, "rg7", "xicon 对不存在的 key 未回退到白图")
	print("[RG-7] xicon(nonexistent) fallback=%s problems=%d" % [
		"white_tex" if fallback == Assets.white_tex else "OTHER", problems.size()])


## 词缀：name / tint / icon 齐全，且头顶图标真实存在（漏图标会静默无标记）
func _check_affixes() -> void:
	for k in Data.AFFIXES:
		var a: Dictionary = Data.AFFIXES[k]
		if String(a.get("name", "")) == "":
			problems.append("词缀 %s 缺 name" % k)
		var icon: String = String(a.get("icon", ""))
		if icon == "":
			problems.append("词缀 %s 缺 icon（头顶无标记）" % k)
		elif Assets.g("icon_" + icon) == null and not Assets.ICON_RECTS.has(icon):
			problems.append("词缀 %s 的图标缺失：%s" % [k, icon])


## 挑战因子：name / desc / icon 齐全
func _check_modifiers() -> void:
	for k in Data.MODIFIERS:
		var m: Dictionary = Data.MODIFIERS[k]
		if String(m.get("name", "")) == "" or String(m.get("desc", "")) == "":
			problems.append("因子 %s 缺 name/desc" % k)
		var icon: String = String(m.get("icon", ""))
		if icon == "":
			problems.append("因子 %s 缺 icon" % k)
		elif Assets.g("icon_" + icon) == null and not Assets.ICON_RECTS.has(icon):
			problems.append("因子 %s 的图标缺失：icon_%s" % [k, icon])


## 升级：每条必须有合法 tag（漏 tag ＝ 套装永远凑不齐，且不报错）
func _check_upgrades() -> void:
	for p in UPGRADES.POOL:
		var id: String = String(p.get("id", ""))
		if not p.has("tag"):
			problems.append("升级 %s 缺 tag（套装永远凑不齐）" % id)
			continue
		var t = p["tag"]
		var tags: Array = t if t is Array else [t]
		if tags.is_empty():
			problems.append("升级 %s 的 tag 为空" % id)
		for tg in tags:
			if not UPGRADES.TAGS.has(String(tg)):
				problems.append("升级 %s 的 tag 非法：%s" % [id, String(tg)])


## 局外 meta 自检：解锁树与三个池双向一致 + 默认可用条目数够抽
func _check_meta() -> void:
	for id in META.UNLOCKS:
		var n: Dictionary = META.UNLOCKS[id]
		if not String(id).begins_with("u_"):
			problems.append("解锁节点 %s 缺 u_ 前缀" % id)
		for f in ["name", "desc", "kind", "target", "cost", "icon", "max"]:
			if not n.has(f):
				problems.append("解锁节点 %s 缺字段 %s" % [id, f])
		var kind := String(n.get("kind", ""))
		if not ["upgrade", "relic", "weapon", "perk"].has(kind):
			problems.append("解锁节点 %s 的 kind 非法：%s" % [id, kind])
		if int(n.get("cost", 0)) <= 0:
			problems.append("解锁节点 %s 的 cost 必须为正整数" % id)
		if int(n.get("max", 1)) < 1:
			problems.append("解锁节点 %s 的 max 必须 >= 1（一次性购买语义）" % id)
		if String(n.get("desc", "")) == "":
			problems.append("解锁节点 %s 的 desc 为空" % id)
		# 图标必须真能解析：写错只会静默白框，不会报错（历史坑 #7 同型）
		if _meta_icon(String(n.get("icon", ""))) == null:
			problems.append("解锁节点 %s 的 icon 不可解析：%s" % [id, String(n.get("icon", ""))])
		for r in n.get("requires", []):
			var rid := String(r)
			if not META.UNLOCKS.has(rid):
				problems.append("解锁节点 %s 的前置 %s 不存在" % [id, rid])
			elif rid == String(id):
				problems.append("解锁节点 %s 的前置指向自己" % id)
	# 前置多节点成环：u_a -> u_b -> u_a 会让两个节点永远买不到（自检不能放过）
	for id in META.UNLOCKS:
		if _meta_requires_cycle(String(id)):
			problems.append("解锁节点 %s 的前置存在环（永远买不到）" % id)
	# target 必须真的在对应池里；同一个内容不能被两个节点同时指向
	var seen := {}
	for id in META.UNLOCKS:
		var n: Dictionary = META.UNLOCKS[id]
		var kind := String(n.get("kind", ""))
		var target := String(n.get("target", ""))
		var key := "%s:%s" % [kind, target]
		if seen.has(key):
			problems.append("解锁节点 %s 与 %s 指向同一内容：%s" % [id, seen[key], target])
		else:
			seen[key] = id
		if not _meta_pool_has(kind, target):
			problems.append("解锁节点 %s 的 target 不在 %s 池：%s" % [id, kind, target])
		# 解锁的升级必须有 max >= 1（max=0 → 权重恒 0 → 永远抽不到）
		if kind == "upgrade":
			for p in UPGRADES.POOL:
				if String(p.get("id", "")) == target and int(p.get("max", 0)) < 1:
					problems.append("解锁升级 %s 的 max <= 0（权重恒 0，永远抽不到）" % target)
	# 池条目 meta ↔ 节点 id 双向一致（写错 → 启动自检报错；运行时门控不读它，不会「买了却进不了池」）
	for kind in ["upgrade", "relic", "weapon"]:
		for pid in _meta_ids(kind):
			var entry := _meta_entry(kind, String(pid))
			var node_id := String(entry.get("meta", ""))
			if node_id == "":
				continue
			if not META.UNLOCKS.has(node_id):
				problems.append("%s 池条目 %s 的 meta 指向不存在的节点 %s" % [kind, pid, node_id])
				continue
			var nn: Dictionary = META.UNLOCKS[node_id]
			if String(nn.get("kind", "")) != kind:
				problems.append("池条目 %s 的 meta 节点 %s 的 kind 不符（池=%s）" % [pid, node_id, kind])
			if String(nn.get("target", "")) != String(pid):
				problems.append("池条目 %s 的 meta 节点 %s 的 target 不符" % [pid, node_id])
	# 默认可用条目数必须够抽：阈值用 MIN_DEFAULT_USABLE（比运行时下限更严，
	# 防止「退化态恰好卡在运行时阈值上 → 自检静默放过围栏回归」）
	for kind in ["upgrade", "relic", "weapon"]:
		var need := int(META.MIN_DEFAULT_USABLE.get(kind, 1))
		var have := _meta_default_usable(kind, _meta_ids(kind))
		if have < need:
			problems.append("%s 默认可用条目不足：需 %d，实有 %d" % [kind, need, have])
		# 每类至少 1 个未被门控的基础条目，否则新档会被锁死
		var ungated := 0
		for pid in _meta_ids(kind):
			if META.gate_of(kind, String(pid)) == "":
				ungated += 1
		if ungated < 1:
			problems.append("%s 没有任何未被解锁门控的基础条目（会锁死新档）" % kind)


## 前置依赖是否有环（DFS，沿 path 回溯）
func _meta_requires_cycle(start: String) -> bool:
	return _meta_cycle_walk(start, {})


func _meta_cycle_walk(id: String, path: Dictionary) -> bool:
	if path.has(id):
		return true
	var n: Dictionary = META.UNLOCKS.get(id, {})
	if n.is_empty():
		return false
	path[id] = true
	for r in n.get("requires", []):
		if _meta_cycle_walk(String(r), path):
			return true
	path.erase(id)
	return false


## 解锁页图标三段 resolver：ICON_RECTS 直查 → generated 直名 → generated/icon_<key>
func _meta_icon(key: String) -> Texture2D:
	if key == "":
		return null
	if Assets.ICON_RECTS.has(key):
		return Assets.icon(key)
	var t := Assets.g(key)
	if t != null:
		return t
	return Assets.g("icon_" + key)


## 取某类内容的池条目
func _meta_entry(kind: String, id: String) -> Dictionary:
	match kind:
		"upgrade":
			for p in UPGRADES.POOL:
				if String(p.get("id", "")) == id:
					return p
		"relic":
			for p in Relics.POOL:
				if String(p.get("id", "")) == id:
					return p
		"weapon":
			if Weapons.DEFS.has(id):
				return Weapons.DEFS[id]
	return {}


## 某类内容的条目 id 清单
func _meta_ids(kind: String) -> Array:
	var out := []
	match kind:
		"upgrade":
			for p in UPGRADES.POOL:
				out.append(String(p.get("id", "")))
		"relic":
			for p in Relics.POOL:
				out.append(String(p.get("id", "")))
		"weapon":
			for k in Weapons.DEFS:
				out.append(String(k))
	return out


## 该类内容里默认可用的条目数（没被解锁树 gate 的 + 初始免费节点）
func _meta_default_usable(kind: String, ids: Array) -> int:
	var n := 0
	for pid in ids:
		var gid := META.gate_of(kind, String(pid))
		if gid == "":
			n += 1
		elif bool(META.node(gid).get("default", false)):
			n += 1
	return n


## 目标 id 是否真的在该类池里
func _meta_pool_has(kind: String, target: String) -> bool:
	for pid in _meta_ids(kind):
		if String(pid) == target:
			return true
	return false


## 楼层主题：字段齐全，且池 / 精英 / Boss 引用必须存在
func _check_themes() -> void:
	for k in Data.FLOOR_THEMES:
		var th: Dictionary = Data.FLOOR_THEMES[k]
		for field in ["name", "rule", "pool"]:
			if not th.has(field):
				problems.append("楼层主题 %s 缺字段：%s" % [k, field])
		if th.has("pool") and not Data.FLOOR_POOLS.has(int(th["pool"])):
			problems.append("楼层主题 %s 的刷怪池不存在：%s" % [k, str(th["pool"])])
		for field in ["elite", "boss"]:
			if th.has(field) and not Data.ENEMIES.has(String(th[field])):
				problems.append("楼层主题 %s 的 %s 不存在：%s" % [k, field, str(th[field])])


## AI 行为参数覆盖表：敌人 id 必须存在、参数键必须合法、数值必须为正
func _check_ai_params() -> void:
	for id in Data.AI_OVERRIDES:
		if not Data.ENEMIES.has(id):
			problems.append("AI 参数覆盖引用了不存在的敌人：%s" % id)
			continue
		var ov: Dictionary = Data.AI_OVERRIDES[id]
		for k in ov:
			var key := String(k)
			if not AI_PARAM_KEYS.has(key):
				problems.append("敌人 %s 的 AI 参数键非法：%s" % [id, key])
				continue
			var v = ov[k]
			if typeof(v) != TYPE_INT and typeof(v) != TYPE_FLOAT:
				problems.append("敌人 %s 的 AI 参数 %s 不是数值" % [id, key])
			elif float(v) <= 0.0:
				problems.append("敌人 %s 的 AI 参数 %s 必须为正：%s" % [id, key, str(v)])


## 契约键一致性（SMOKE_CONTRACT 门控）：生产端定义源在 Meta，消费端取镜像 +
## game_main.gd 静态回读。坑 42 的 stats["floor"] / r["diamonds"] 型漂移不报错、
## 日志照打，只能在启动期主动点名。默认 env 为空时立即返回，零输出零副作用。
func _check_contracts() -> void:
	if OS.get_environment("SMOKE_CONTRACT") == "":
		return
	var d1 := _key_diff(META.STATS_KEYS, CONSUMER_STATS_KEYS)
	Dev.check(d1 == "", "contract", "stats 契约键不一致：%s" % d1)
	var d2 := _key_diff(META.SETTLE_RETURN_KEYS, CONSUMER_RETURN_KEYS)
	Dev.check(d2 == "", "contract", "结算返回契约键不一致：%s" % d2)
	var src := FileAccess.get_file_as_string("res://scripts/game_main.gd")
	var stats_src := _slice(src, "func _run_stats()", "func quit_estimate()")
	var settle_src := _slice(src, "func _settle_meta()", "func restart()")
	if stats_src != "" and settle_src != "":
		for k in META.STATS_KEYS:
			var skey := String(k)
			Dev.check(stats_src.find("\"" + skey + "\"") >= 0, "contract",
				"_run_stats 未产出契约键 %s" % skey)
		for k in META.SETTLE_RETURN_KEYS:
			var rkey := String(k)
			Dev.check(settle_src.find("r.get(\"" + rkey + "\"") >= 0, "contract",
				"_settle_meta 未消费结算返回键 %s" % rkey)
	else:
		print("[SMOKE-META-EXTRA] contract: game_main.gd 源码回读跳过")
	# 行为式：只含契约键的 stats 必须按规格公式折算；payout 内部键写错 → 结果偏 0 → 报出
	var stats := {}
	for k in META.STATS_KEYS:
		stats[k] = 0
	stats["diamonds"] = 120
	stats["max_floor"] = 3
	stats["time"] = 120.0
	stats["kills"] = 60
	var pay := META.payout(stats)
	Dev.check(pay == 28, "contract", "payout 未按契约键折算：实得 %d（期望 28）" % pay)
	print("[SMOKE-META-EXTRA] contract: stats_keys=%d return_keys=%d payout=%d" % [
		META.STATS_KEYS.size(), META.SETTLE_RETURN_KEYS.size(), pay])


## 表注册一致性（SMOKE_REG 门控）：新增内容「加了却没生效 / 加了就崩」在启动期暴露。
## FLOOR_POOL_FALLBACK 已由 _check_pools 覆盖，此处不重复。
func _check_registration() -> void:
	if OS.get_environment("SMOKE_REG") == "":
		return
	for k in Data.MODIFIERS:
		Dev.check(Data.MODIFIER_WEIGHTS.has(k), "reg",
			"挑战因子 %s 缺 MODIFIER_WEIGHTS 权重（永远抽不到）" % k)
	for k in Data.MODIFIER_WEIGHTS:
		Dev.check(Data.MODIFIERS.has(k), "reg",
			"MODIFIER_WEIGHTS 的 %s 不在 MODIFIERS（抽到未知因子）" % k)
	for f in Data.ELITE_BY_FLOOR:
		var e := String(Data.ELITE_BY_FLOOR[f])
		Dev.check(Data.ENEMIES.has(e), "reg",
			"ELITE_BY_FLOOR 第 %d 层引用了不存在的敌人 %s" % [f, e])
	for f in Data.BOSS_BY_FLOOR:
		var b := String(Data.BOSS_BY_FLOOR[f])
		Dev.check(Data.ENEMIES.has(b), "reg",
			"BOSS_BY_FLOOR 第 %d 层引用了不存在的敌人 %s" % [f, b])
	Dev.check(Data.ENEMIES.has(Data.ELITE_FALLBACK), "reg",
		"ELITE_FALLBACK 敌人不存在：%s" % Data.ELITE_FALLBACK)
	Dev.check(Data.ENEMIES.has(Data.BOSS_FALLBACK), "reg",
		"BOSS_FALLBACK 敌人不存在：%s" % Data.BOSS_FALLBACK)
	print("[SMOKE-META-EXTRA] reg: modifiers=%d weights=%d elites=%d bosses=%d" % [
		Data.MODIFIERS.size(), Data.MODIFIER_WEIGHTS.size(),
		Data.ELITE_BY_FLOOR.size(), Data.BOSS_BY_FLOOR.size()])


## 池 id ↔ apply 分支静态交叉校验（SMOKE_APPLY 门控）：新增池条目漏写 apply 分支会
## 「抽到却没效果」，且零异常零 WARN（relics.gd 的 match 原先无默认分支）。
func _check_apply_ids() -> void:
	if OS.get_environment("SMOKE_APPLY") == "":
		return
	var relic_src := _slice(FileAccess.get_file_as_string("res://scripts/relics.gd"), "static func apply", "")
	var upg_src := _slice(FileAccess.get_file_as_string("res://scripts/upgrades.gd"), "static func apply", "static func tags_of")
	if relic_src == "" or upg_src == "":
		print("[SMOKE-META-EXTRA] apply: 源码回读失败，静态交叉校验跳过")
		return
	var checked := 0
	for p in Relics.POOL:
		var rid := String(p.get("id", ""))
		Dev.check(relic_src.find("\"" + rid + "\"") >= 0, "apply",
			"遗物 %s 缺 apply 分支（抽到却没效果）" % rid)
		checked += 1
	for p in UPGRADES.POOL:
		var uid := String(p.get("id", ""))
		Dev.check(upg_src.find("\"" + uid + "\"") >= 0, "apply",
			"升级 %s 缺 apply 分支" % uid)
		checked += 1
	print("[SMOKE-META-EXTRA] apply: pool ids checked=%d" % checked)


## 两个键集合的差异串（顺序无关；用于 Dev.check 报出具体键名）
func _key_diff(a: Array, b: Array) -> String:
	var out: Array = []
	for k in a:
		if not b.has(k):
			out.append(String(k))
	for k in b:
		if not a.has(k) and not out.has(String(k)):
			out.append(String(k))
	return ", ".join(out)


## 源码切片 [from, to)；to 为空表示取到文件末尾
func _slice(src: String, from: String, to: String) -> String:
	var a := src.find(from)
	if a < 0:
		return ""
	if to == "":
		return src.substr(a)
	var b := src.find(to, a + from.length())
	if b < 0:
		return src.substr(a)
	return src.substr(a, b - a)


## 去掉整行注释后的源码。🔴 源码扫描型门禁一律先过这一道：
## 「⛔ 别用 X」这类写在文档注释里的警告本身含 X，不剥就会让正确的代码红、
## 而真正的误用（写在能跑的那一行里）反而和警告混为一谈。
func _strip_comments(text: String) -> String:
	var keep := []
	for ln in text.split("\n"):
		if not String(ln).strip_edges().begins_with("#"):
			keep.append(String(ln))
	return "\n".join(keep)
