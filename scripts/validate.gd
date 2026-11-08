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
		# B4：shrine 恒非起点房——_enter_room 早于 _roll_calamity 的时序不对称当前无害依赖此条；
		# 未来放宽房型/分配规则时在此当场报错（用断言锁前提，不改时序 → 零 E1 漂移）
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
	# 图标登记断言：PNG 已生成但 GEN_NAMES 漏登记 = Assets.g() 返回 null → 静默白框（核验 🟡 修复）
	if Assets.g("icon_codex") == null:
		problems.append("icon_codex 已生成但未登记 GEN_NAMES（Assets.g 返回 null → 主菜单图鉴按钮静默白框）")
	# Sprint 15 P0 红线（判据端切链）：CODEX_BOONS.kind 不得为 "suffixes"——
	# 否则「送词缀 → mark_codex → 发现度上升 → 更多 boon」正反馈自激。
	# 若产品确需 suffixes 阈值，须改用「不回写图鉴的内部绑定路径」（草案 §3.1 备选）并重做此门
	for bid in Data.CODEX_BOONS:
		if String(Data.CODEX_BOONS[bid].get("kind", "")) == "suffixes":
			problems.append("CODEX_BOONS.%s 以 suffixes 为阈值（boon 自激正反馈——P0 红线）" % bid)


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
