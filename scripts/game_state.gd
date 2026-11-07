extends Node
## 全局状态 autoload：跑局统计、信号总线、音效池、连杀与慢镜。

signal player_hp_changed(hp: int, max_hp: int)
signal bombs_changed(n: int, cap: int)
signal mag_changed(n: int, cap: int)
signal score_changed(score: int)
signal combo_changed(combo: int)
signal xp_changed(xp: int, need: int, level: int)
signal level_reached(level: int)
signal wave_changed(n: int, kind: String)
signal boss_hp_changed(hp: float, max_hp: float)
signal combo_pop(n: int)
signal diamonds_changed(n: int)
signal toast(text: String)
signal bindings_changed()
## 局外 meta 变化（余额 / 已解锁数量）
signal meta_changed(diamonds: int, unlocked_count: int)

const COMBO_WINDOW := 3.0
## 固定步长：Game.time 与 combo 窗口按帧推进，与真实 delta / Engine.time_scale 解耦
const FIXED_DT := 1.0 / 60.0
## 升级池（读档时恢复已选升级与套装计数）
const Upgrades := preload("res://scripts/upgrades.gd")
## 局外 meta 层（解锁树表 + 经济换算 + 规则函数）；autoload 里看不到全局类名，必须 preload
const Meta := preload("res://scripts/meta.gd")
## 遗物池（图鉴 relics 分类校验用）
const RelicsRef := preload("res://scripts/relics.gd")

## 局外存档路径：与 settings.cfg 分文件，回滚代码不会动玩家设置
const META_PATH := "user://meta.cfg"
const META_SMOKE_PATH := "user://_smoke_meta.cfg"

## 图鉴存档路径（Sprint 13 C：codex.cfg 双档，SMOKE_CODEX_PATH 可自定义隔离档）
const CODEX_PATH := "user://codex.cfg"
const CODEX_SMOKE_PATH := "user://_smoke_codex.cfg"

var main: Node2D = null
var rng := RandomNumberGenerator.new()
## 表现层独立随机流：相机抖动 / 音效音高 / 视觉相位专用，不参与玩法随机
var fx_rng := RandomNumberGenerator.new()

# 跑局统计（reset() 清空）
var time := 0.0
var kills := 0
var score := 0
var wave := 0
var level := 1
var xp := 0
var xp_need := 5
var combo := 0
var combo_t := 0.0
## 本局已播报的里程碑 id（每条只播一次）
var milestones := {}
## 玩家设置：master/bgm/sfx 音量、shake 震动强度、compact_hud 精简 HUD、
## resolution（"宽x高"，仅窗口模式生效）、window_mode（0 窗口 / 1 全屏 / 2 无边框）、
## ui_font（Sprint 13 E HUD 字号档："0" 小 / "1" 标准 / "2" 大——hud 构建时折算 _font_scale）
var settings := {"master": 1.0, "bgm": 0.8, "sfx": 0.9, "shake": 1.0, "compact_hud": false,
	"resolution": "1280x720", "window_mode": 0, "ui_font": "1"}
## 分辨率预设（16:9，与视口拉伸架构解耦——内容按 canvas_items 恒定 1280x720 逻辑分辨率缩放）
const RESOLUTION_PRESETS := ["1280x720", "1600x900", "1920x1080", "2560x1440"]
const WINDOW_MODES := ["窗口", "全屏", "无边框全屏"]
var enemy_speed_mult := 1.0
var playing := true
var diamonds := 0  # 可消费的源石（同时也是经验来源）
var floor_num := 1
## 本局到达过的最深层（结算用这个，不是死亡时的当前层）
var max_floor := 1
## 本局的地图种子（每层地图由它 + 层号派生，解锁内容不影响地图）
var run_seed := 0
## 本局累计获得的源石（只增不减，结算按它折算结晶，不受局内消费影响）
var run_diamonds_earned := 0
## 本局累计消费的源石（只作统计，不从局外余额扣）
var meta_spent := 0
## 源石共鸣核心（mx_resocore）：本局按源石计的共鸣计数（每 3 颗 +1 层）
var _reso_pickups := 0
## 局外 meta 状态：余额 / 已解锁集合 / 累计统计（持久化在 user://meta.cfg）
var meta := {
	"version": 1, "crystals": 0, "unlocked": [], "boost": {},
	"runs_played": 0, "best_floor": 0, "total_kills": 0,
	"total_time": 0.0, "total_earned": 0, "last_played": 0, "saved_at": 0,
}
## meta 是否已在本次进程初始化过（SMOKE 隔离档只在首次读取前删一次）
var _meta_inited := false

var _sfx_pool: Array[AudioStreamPlayer] = []
var _slow_tween: Tween


func _ready() -> void:
	# 音效池：8 个轮流占用；不受暂停影响（升级界面也能出声）
	process_mode = Node.PROCESS_MODE_ALWAYS
	load_settings()
	apply_settings()
	load_meta()
	load_sigils()
	load_codex()
	if OS.get_environment("SMOKE_META_PERSIST") != "":
		_sigil_persist_selftest.call_deferred()
	for i in 8:
		var p := AudioStreamPlayer.new()
		p.bus = "Master"
		add_child(p)
		_sfx_pool.append(p)


func _process(_delta: float) -> void:
	if not playing:
		return
	time += FIXED_DT
	if combo > 0:
		combo_t -= FIXED_DT
		if combo_t <= 0.0:
			combo = 0
			combo_changed.emit(combo)


## 由 (run_seed + 独立前缀) 派生表现层种子；与 _floor_rng() 同型但前缀不同，避免撞种子
func reset_fx_rng() -> void:
	fx_rng.seed = int(hash("spr8_fx:%d" % run_seed))


func reset() -> void:
	time = 0.0
	kills = 0
	score = 0
	wave = 0
	level = 1
	xp = 0
	xp_need = 5
	combo = 0
	combo_t = 0.0
	milestones.clear()
	enemy_speed_mult = 1.0
	playing = true
	diamonds = 0
	floor_num = 1
	max_floor = 1
	run_diamonds_earned = 0
	meta_spent = 0
	_reso_pickups = 0
	calamity_speed_mult = 1.0
	calamity_floors.clear()
	# 注意：这里绝不能碰 meta —— 局外进度跨局保留
	diamonds_changed.emit(diamonds)
	reset_fx_rng()


func add_diamonds(n: int) -> void:
	diamonds += n
	run_diamonds_earned += n
	# 源石共鸣核心（mx_resocore）：共鸣计数源改为「每拾取 3 颗源石 +1」
	# （与旧的「拾取升级/遗物 +1」互斥，不两条并存）
	if main != null and is_instance_valid(main) and is_instance_valid(main.player) \
			and main.player.has_resocore:
		_reso_pickups += n
		while _reso_pickups >= 3:
			_reso_pickups -= 3
			main.add_resonance(1)
	diamonds_changed.emit(diamonds)


## 商店消费：不够返回 false
func spend(n: int) -> bool:
	if diamonds < n:
		return false
	diamonds -= n
	meta_spent += n
	diamonds_changed.emit(diamonds)
	return true


## ---- 存档层地基：局内进度快照（只序列化元数据与清单，不含实体/世界状态）----
func to_dict() -> Dictionary:
	var relics: Array = []
	if main != null and is_instance_valid(main) and is_instance_valid(main.player):
		relics = main.player.relics.duplicate()
	return {
		"time": time, "kills": kills, "score": score, "wave": wave,
		"level": level, "xp": xp, "xp_need": xp_need, "combo": combo,
		"milestones": milestones.duplicate(true),
		"diamonds": diamonds, "floor_num": floor_num, "playing": playing,
		"run_diamonds_earned": run_diamonds_earned, "meta_spent": meta_spent,
		"modifier": (main.modifier if main != null else "none"),
		"resonance": (main.resonance if main != null else 0),
		"upgrades_taken": Upgrades.taken.duplicate(true),
		"relics": relics,
	}


## 读回局内进度；套装效果由 game_main.reapply_sets() 重新应用
func from_dict(d: Dictionary) -> void:
	time = float(d.get("time", 0.0))
	kills = int(d.get("kills", 0))
	score = int(d.get("score", 0))
	wave = int(d.get("wave", 0))
	level = int(d.get("level", 1))
	xp = int(d.get("xp", 0))
	xp_need = int(d.get("xp_need", 5))
	combo = int(d.get("combo", 0))
	var ms: Dictionary = d.get("milestones", {})
	milestones = ms.duplicate(true)
	diamonds = int(d.get("diamonds", 0))
	floor_num = int(d.get("floor_num", 1))
	playing = bool(d.get("playing", true))
	run_diamonds_earned = int(d.get("run_diamonds_earned", 0))
	meta_spent = int(d.get("meta_spent", 0))
	var taken: Dictionary = d.get("upgrades_taken", {})
	Upgrades.taken = taken.duplicate(true)
	var newly: Array = Upgrades.rebuild_tags()
	if main != null and is_instance_valid(main):
		main.modifier = String(d.get("modifier", "none"))
		main.resonance = int(d.get("resonance", 0))
		main.reapply_sets(newly)
		if is_instance_valid(main.player):
			main.player.relics.clear()
			for r in d.get("relics", []):
				main.player.relics.append(String(r))
	diamonds_changed.emit(diamonds)


func flash_toast(text: String) -> void:
	toast.emit(text)


# ---------------- 地窖印记（F2/Sprint 11 §四 契约层）----------------
## 独立存档（与 rng 流隔离）；shards 结算纯确定性（cleared × META_RATE，无 rng）。
## 印记在 run 开始前选定；注入走 game_main._apply_sigil_contract——必须在任何
## Game.rng 绘制之前调用（E1 零漂移契约：同 seed + 同印记 = 整局可复现）。
var sigils := {"shards": 0, "unlocked": [], "equipped": ""}
const SIGIL_PATH := "user://sigils.cfg"
const SIGIL_SMOKE_PATH := "user://_smoke_sigils.cfg"
## shards 结算汇率：floor(cleared_floors × META_RATE)，常数、无 rng（§四.2）
const META_RATE := 2.0


func sigil_path() -> String:
	var custom := OS.get_environment("SMOKE_SIGIL_PATH")
	if custom != "":
		return custom
	if OS.get_environment("SMOKE") != "":
		return SIGIL_SMOKE_PATH
	return SIGIL_PATH


func load_sigils() -> void:
	var cfg := ConfigFile.new()
	if cfg.load(sigil_path()) != OK:
		return
	sigils["shards"] = maxi(int(cfg.get_value("sigils", "shards", 0)), 0)
	var unl = cfg.get_value("sigils", "unlocked", [])
	if unl is Array:
		var clean: Array = []
		for id in unl:
			if Data.SIGILS.has(String(id)):
				clean.append(String(id))
		sigils["unlocked"] = clean
	# 未知携带 id 回退为不携带（先归零再校验回填，防内存旧值穿透）
	sigils["equipped"] = ""
	var eq = cfg.get_value("sigils", "equipped", "")
	if String(eq) != "" and Data.SIGILS.has(String(eq)):
		sigils["equipped"] = String(eq)


func save_sigils() -> void:
	var cfg := ConfigFile.new()
	cfg.set_value("sigils", "shards", int(sigils["shards"]))
	cfg.set_value("sigils", "unlocked", sigils["unlocked"])
	cfg.set_value("sigils", "equipped", String(sigils["equipped"]))
	cfg.save(sigil_path())


## ---------------- Sprint 13 C：地窖图鉴（局外只读沉淀，codex.cfg 双档） ----------------
## 记录已遇敌人 / 遗物 / 词缀 / 主题 / 已击败 Boss + 上局复盘摘要；纯登记零 rng（E1 零影响）。
## 不碰 meta.gd UNLOCKS（冻结规格 v2.10）——平行只读数据，只增不减。
const CODEX_KINDS := ["enemies", "relics", "suffixes", "themes", "bosses"]
var codex := {"enemies": [], "relics": [], "suffixes": [], "themes": [], "bosses": [], "last_run": {}}


func codex_path() -> String:
	var custom := OS.get_environment("SMOKE_CODEX_PATH")
	if custom != "":
		return custom
	if OS.get_environment("SMOKE") != "":
		return CODEX_SMOKE_PATH
	return CODEX_PATH


## 图鉴 id 合法性（登记与读档同一张校验——未知 id 两头都忽略）
func _codex_id_valid(kind: String, id: String) -> bool:
	match kind:
		"enemies":
			return Data.ENEMIES.has(id)
		"bosses":
			# Sprint 14 A/B1：收窄为「真 Boss」——主题 Boss 专用 id + ENEMIES 内 ai=="boss"；
			# 旧档遗留的 "boss"（巨岩虫之王）仍是合法键，不做隐式迁移（§3.4）
			return Data.CODEX_BOSS_NAMES.has(id) \
				or (Data.ENEMIES.has(id) and String(Data.ENEMIES[id].get("ai", "")) == "boss")
		"relics":
			for r in RelicsRef.POOL:
				if String(r["id"]) == id:
					return true
			return false
		"suffixes":
			return Data.RELIC_SUFFIXES.has(id)
		"themes":
			for k in Data.FLOOR_THEMES:
				if String(Data.FLOOR_THEMES[k]["rule"]) == id:
					return true
			return false
	return false


## 发现登记：未知 kind/id 忽略、重复幂等；新增即落盘（发现不因中途退出丢失）
func mark_codex(kind: String, id: String) -> void:
	if not codex.has(kind) or kind == "last_run" or id == "":
		return
	if not _codex_id_valid(kind, id):
		return
	var arr: Array = codex[kind]
	if arr.has(id):
		return
	arr.append(id)
	save_codex()


## 上局复盘摘要（_settle_meta 结算时快照 _run_stats——STATS_KEYS 内五项，不新增统计源；负数钳制）
func set_codex_last_run(stats: Dictionary) -> void:
	var clean := {}
	for k in Meta.STATS_KEYS:
		# Sprint 14 B3：键白名单——越界键直接忽略（_run_stats 的 SMOKE 覆盖键也进不来）
		if not stats.has(k):
			continue
		var v = stats[k]
		clean[String(k)] = maxi(int(v), 0) if (v is int or v is float) else v
	codex["last_run"] = clean
	save_codex()


func load_codex() -> void:
	codex = {"enemies": [], "relics": [], "suffixes": [], "themes": [], "bosses": [], "last_run": {}}
	var cfg := ConfigFile.new()
	if cfg.load(codex_path()) != OK:
		return
	for kind in CODEX_KINDS:
		var arr = cfg.get_value("codex", kind, [])
		if arr is Array:
			# 未知 id 过滤（参照 load_sigils 防穿透写法）
			var clean: Array = []
			for id in arr:
				if _codex_id_valid(kind, String(id)):
					clean.append(String(id))
			codex[kind] = clean
	var lr = cfg.get_value("codex", "last_run", {})
	if lr is Dictionary:
		var clean_d := {}
		for k in lr:
			var v = lr[k]
			clean_d[String(k)] = maxi(int(v), 0) if (v is int or v is float) else v
		codex["last_run"] = clean_d


func save_codex() -> void:
	var cfg := ConfigFile.new()
	for kind in CODEX_KINDS:
		cfg.set_value("codex", kind, codex[kind])
	cfg.set_value("codex", "last_run", codex["last_run"])
	cfg.save(codex_path())


## Sprint 14 C：图鉴发现度 → 开局加成派生（纯只读零 rng——遍历 CODEX_BOONS 按阈值判定）。
## 图鉴档是局外输入：档不同 → 起始状态不同；同档 + 同 seed 双跑仍逐字一致（交付文档登记口径）
func codex_boons() -> Dictionary:
	var out := {}
	for id in Data.CODEX_BOONS:
		var b: Dictionary = Data.CODEX_BOONS[id]
		if (codex.get(String(b["kind"]), []) as Array).size() >= int(b["need"]):
			out[String(id)] = b
	return out


## 局末结算：shards += floor(cleared × META_RATE)，纯确定性（无 rng）；
## 本局触发过灾祸 → ×1.5 风险回报（Sprint 12 §6.3）
func settle_shards(cleared_floors: int) -> int:
	var n := int(maxi(cleared_floors, 0) * META_RATE)
	if calamity_floors.size() > 0:
		n = int(n * 1.5)
	sigils["shards"] = int(sigils["shards"]) + n
	save_sigils()
	return n


## 运行期直接加 shards（博学印记层清奖励等），纯确定性
func add_shards(n: int) -> void:
	sigils["shards"] = int(sigils["shards"]) + maxi(n, 0)
	save_sigils()


# ---------------- D 每日挑战（Sprint 12 §6.2）----------------
## daily_seed = hash(YYYYMMDD) 派生，run 启动时在 rng 首抽前覆盖 seed（E1 零漂移）；
## 本地榜 user://daily.cfg 独立持久（同 sigils 范式）。
var daily_mode := false
var daily_seed := 0
const DAILY_PATH := "user://daily.cfg"


func daily_key() -> String:
	var d := Time.get_date_dict_from_system()
	return "%04d%02d%02d" % [d.year, d.month, d.day]


## 稳定字符串哈希（FNV-1a，跨引擎版本确定性——核验 #6：内建 hash() 不保证跨版本一致）
func stable_hash(s: String) -> int:
	var h := 2166136261
	for b in s.to_utf8_buffer():
		# 每步 32 位掩码（标准 FNV-1a）：无掩码时多字节键连乘溢入 64 位回绕区，跨版本行为不保证
		h = ((h ^ b) * 16777619) & 0xFFFFFFFF
	return h & 0x7FFFFFFF


func daily_seed_for(key: String) -> int:
	return stable_hash(key)


## 击败/通关时记录当日最佳（层数优先，同层比时间）
func record_daily_best(layers: int, time_sec: float) -> void:
	var cfg := ConfigFile.new()
	cfg.load(DAILY_PATH)
	var k := daily_key()
	var prev_layers := int(cfg.get_value("daily", k + "_layers", 0))
	var prev_time := float(cfg.get_value("daily", k + "_time", 0.0))
	var better := layers > prev_layers or (layers == prev_layers and (prev_time <= 0.0 or time_sec < prev_time))
	if better:
		cfg.set_value("daily", k + "_layers", layers)
		cfg.set_value("daily", k + "_time", time_sec)
		cfg.save(DAILY_PATH)


func daily_best_today() -> Dictionary:
	var cfg := ConfigFile.new()
	cfg.load(DAILY_PATH)
	var k := daily_key()
	return {"layers": int(cfg.get_value("daily", k + "_layers", 0)),
		"time": float(cfg.get_value("daily", k + "_time", 0.0))}


# ---------------- E 灾祸层（Sprint 12 §6.3）----------------
## 每层 15% 触发一个负面灾祸（走既有 Game.rng 流），换取 shards 结算 ×1.5。
## 效果以全局系数/标志落地（calamity_speed_mult 等），本层生效、换层清除。
var calamity_speed_mult := 1.0   # frenzy：敌人移速 ×1.25
var calamity_floors: Array = []  # 触发过灾祸的层号（结算 ×1.5 判定）


## 解锁印记：余额足够则扣 shards 并永久解锁
func unlock_sigil(id: String) -> bool:
	if not Data.SIGILS.has(id) or sigils["unlocked"].has(id):
		return false
	var cost := int(Data.SIGILS[id]["cost"])
	if int(sigils["shards"]) < cost:
		return false
	sigils["shards"] = int(sigils["shards"]) - cost
	sigils["unlocked"].append(id)
	save_sigils()
	return true


## 携带印记（每局 1 枚；空串 = 不携带）
func equip_sigil(id: String) -> void:
	if id != "" and not Data.SIGILS.has(id):
		return
	sigils["equipped"] = id
	save_sigils()


func equipped_sigil() -> String:
	return String(sigils["equipped"])


## SMOKE_META_PERSIST=1：印记存档往返自测（写→读→越界钳制→未知 id 忽略），表外不进 E1
func _sigil_persist_selftest() -> void:
	await get_tree().process_frame
	var bak := {"shards": int(sigils["shards"]), "unlocked": (sigils["unlocked"] as Array).duplicate(),
		"equipped": String(sigils["equipped"])}
	# ① 写入测试值并落盘
	sigils["shards"] = 77
	sigils["unlocked"] = ["vigor", "purse"]
	sigils["equipped"] = "vigor"
	save_sigils()
	# ② 清内存态后读回
	sigils = {"shards": 0, "unlocked": [], "equipped": ""}
	load_sigils()
	Dev.check(int(sigils["shards"]) == 77, "sigil", "存档往返 shards=77")
	var unl: Array = sigils["unlocked"]
	Dev.check(unl.size() == 2 and unl.has("vigor") and unl.has("purse"), "sigil", "存档往返 unlocked=[vigor,purse]")
	Dev.check(String(sigils["equipped"]) == "vigor", "sigil", "存档往返 equipped=vigor")
	# ③ 越界钳制与未知 id 忽略
	sigils["shards"] = -5
	sigils["unlocked"] = ["vigor", "nonexistent"]
	sigils["equipped"] = "nonexistent"
	save_sigils()
	load_sigils()
	Dev.check(int(sigils["shards"]) == 0, "sigil", "负 shards 钳制为 0")
	Dev.check(not (sigils["unlocked"] as Array).has("nonexistent"), "sigil", "未知解锁 id 被忽略")
	Dev.check(String(sigils["equipped"]) == "", "sigil", "未知携带 id 被忽略")
	# ④ 恢复现场
	sigils = bak
	save_sigils()
	print("[SMOKE-SIGIL] persist selftest done")


func sfx(name: String, pitch := 1.0, volume_db := 0.0) -> void:
	if not Assets.SFX.has(name):
		return
	var vol: float = volume_db + _coef_db("sfx")
	for p in _sfx_pool:
		if not p.playing:
			p.stream = Assets.SFX[name]
			p.pitch_scale = pitch
			p.volume_db = vol
			p.play()
			return
	# 池满：抢占第一个
	_sfx_pool[0].stream = Assets.SFX[name]
	_sfx_pool[0].pitch_scale = pitch
	_sfx_pool[0].volume_db = vol
	_sfx_pool[0].play()


func shake(amount: float) -> void:
	if main and main.has_method("add_shake"):
		main.add_shake(amount * clampf(float(settings.get("shake", 1.0)), 0.0, 2.0))


## 音量系数 → 分贝（0 视为静音）
func _coef_db(key: String) -> float:
	return linear_to_db(clampf(float(settings.get(key, 1.0)), 0.001, 1.0))


## 读设置（user://settings.cfg）+ 按键绑定（"bindings" 段；Assets 先注册默认，此处覆盖）
func load_settings() -> void:
	var cfg := ConfigFile.new()
	if cfg.load("user://settings.cfg") != OK:
		return
	for k in settings.keys():
		var v = cfg.get_value("settings", k, null)
		if v != null:
			settings[k] = v
	var bindings: Dictionary = cfg.get_value("bindings", "map", {})
	if bindings is Dictionary and not bindings.is_empty():
		Assets.apply_bindings(bindings)


func save_settings() -> void:
	var cfg := ConfigFile.new()
	for k in settings.keys():
		cfg.set_value("settings", k, settings[k])
	cfg.set_value("bindings", "map", Assets.bindings_codes())
	cfg.save("user://settings.cfg")
	bindings_changed.emit()


## 回调/延迟上下文的 main 有效性护栏：重开/换场景期间 main 可能已释放
func main_ok() -> bool:
	return main != null and is_instance_valid(main)


## 场景树级定时器跨 reload 仍会触发；凡回调触及场景节点的延迟调用一律走此入口，
## owner_node 失效时自动跳过（根治「previously freed instance」类报错）。
## process_always 放在 cb 之前：多行 lambda 作尾参时，后置逗号参数解析不可靠。
func safe_delay(sec: float, owner_node: Node, process_always: bool, cb: Callable) -> void:
	get_tree().create_timer(sec, process_always).timeout.connect(func() -> void:
		if is_instance_valid(owner_node) and owner_node.is_inside_tree():
			cb.call())


# ---------------- 局外 meta 层：存档 / 余额 / 解锁 ----------------

## 存档路径：SMOKE 下走隔离档，绝不写玩家文件
func meta_path() -> String:
	var custom := OS.get_environment("SMOKE_META_PATH")
	if custom != "":
		return custom
	if OS.get_environment("SMOKE") != "":
		return META_SMOKE_PATH
	return META_PATH


## 默认 meta 状态
func _default_meta() -> Dictionary:
	return {
		"version": Meta.VERSION, "crystals": 0, "unlocked": [], "boost": {},
		"runs_played": 0, "best_floor": 0, "total_kills": 0,
		"total_time": 0.0, "total_earned": 0, "last_played": 0, "saved_at": 0,
	}


## 读局外存档；损坏时回退 .bak，再坏就用默认值。
## SMOKE 隔离档在本次进程首次读取前删掉重建，保证每轮 SMOKE 从同一状态起步。
func load_meta() -> void:
	var path := meta_path()
	if OS.get_environment("SMOKE_META_PATH") != "":
		print("[SMOKE-META] path=%s" % path)
	var first := not _meta_inited
	_meta_inited = true
	if first and path == META_SMOKE_PATH:
		_remove_file(path)
		# .bak 也必须一起删：否则上一轮留下的备份会在主档缺失时被回退读出来，
		# 导致「跑前删除重建」失效、SMOKE 之间互相污染
		_remove_file(path + ".bak")
	_read_meta(path)
	_apply_meta_probes()


## 真正读档的部分（不含探针）
func _read_meta(path: String) -> void:
	var cfg := ConfigFile.new()
	var err := cfg.load(path)
	if err != OK:
		var bak := ConfigFile.new()
		if bak.load(path + ".bak") == OK:
			cfg = bak
			Dev.warn("meta", "meta 主存档不可用，已回退 .bak")
		else:
			meta = _default_meta()
			if err != ERR_FILE_NOT_FOUND:
				Dev.warn("meta", "meta 存档读取失败（err=%d），使用默认值" % err)
			return
	var ver := int(cfg.get_value("meta", "version", 0))
	if ver > Meta.VERSION:
		Dev.warn("meta", "存档版本 %d 高于当前 %d，保留原文件并使用默认值" % [ver, Meta.VERSION])
		meta = _default_meta()
		return
	meta["version"] = Meta.VERSION
	var missing: Array = []
	for f in ["crystals", "unlocked", "runs_played", "best_floor", "total_kills",
			"total_time", "total_earned", "last_played", "saved_at"]:
		if not cfg.has_section_key("meta", f):
			missing.append(f)
	if not missing.is_empty():
		Dev.warn("meta", "缺失字段已补默认：%s" % ", ".join(missing))
	meta["crystals"] = maxi(0, int(cfg.get_value("meta", "crystals", 0)))
	var raw: Variant = cfg.get_value("meta", "unlocked", [])
	var owned: Array = []
	var unknown := 0
	if raw is Array:
		for x in (raw as Array):
			var sid := String(x)
			if not sid.begins_with("u_"):
				continue
			if not Meta.UNLOCKS.has(sid):
				unknown += 1
				continue
			if not owned.has(sid):
				owned.append(sid)
	if unknown > 0:
		Dev.warn("meta", "丢弃未知解锁 id %d 个" % unknown)
	meta["unlocked"] = owned
	var boost_raw: Variant = cfg.get_value("meta", "boost", {})
	var boost := {}
	if boost_raw is Dictionary:
		for k in (boost_raw as Dictionary).keys():
			var b := int((boost_raw as Dictionary)[k])
			if b > 0 and Meta.UNLOCKS.has(String(k)):
				boost[String(k)] = b
	meta["boost"] = boost
	meta["runs_played"] = maxi(0, int(cfg.get_value("meta", "runs_played", 0)))
	meta["best_floor"] = maxi(0, int(cfg.get_value("meta", "best_floor", 0)))
	meta["total_kills"] = maxi(0, int(cfg.get_value("meta", "total_kills", 0)))
	meta["total_time"] = maxf(0.0, float(cfg.get_value("meta", "total_time", 0.0)))
	meta["total_earned"] = maxi(0, int(cfg.get_value("meta", "total_earned", 0)))
	meta["last_played"] = maxi(0, int(cfg.get_value("meta", "last_played", 0)))
	meta["saved_at"] = maxi(0, int(cfg.get_value("meta", "saved_at", 0)))


## SMOKE 探针：清空 / 强制给源石 / 强制解锁（只改内存，绝不落盘）
func _apply_meta_probes() -> void:
	if OS.get_environment("SMOKE_META_RESET") != "":
		meta = _default_meta()
		print("[SMOKE-META-EXTRA] reset")
	var give := OS.get_environment("SMOKE_META_DIAMONDS")
	if give != "":
		meta["crystals"] = maxi(0, int(give))
		print("[SMOKE-META] crystals set to %d" % meta_crystals())
	var unlock_env := OS.get_environment("SMOKE_META_UNLOCK")
	if unlock_env != "":
		var owned := meta_unlocked_ids()
		if unlock_env == "all":
			for id in Meta.unlock_ids():
				if not owned.has(String(id)):
					owned.append(String(id))
		else:
			for x in unlock_env.split(","):
				var sid := String(x).strip_edges()
				if sid != "" and not owned.has(sid):
					owned.append(sid)
		meta["unlocked"] = owned
		print("[SMOKE-META] unlocked preset: %s" % unlock_env)
	if OS.get_environment("SMOKE_META") != "":
		print("[SMOKE-META] load ok crystals=%d unlocked=%d" % [
			meta_crystals(), meta_unlocked_ids().size()])


## SMOKE 探针：写一份坏档再读回，验证降级
## （missing_field / bad_type / unknown_id / bak_fallback）
func meta_corrupt_test(kind: String) -> bool:
	var path := meta_path()
	match kind:
		"missing_field":
			# 只写 version：其余字段缺失 → 读档时补默认
			var cfg := ConfigFile.new()
			cfg.set_value("meta", "version", Meta.VERSION)
			if cfg.save(path) != OK:
				return false
		"bad_type":
			# 必须是 cfg.load() 真的返回非 OK 的内容：纯垃圾行会被静默忽略（err=0），
			# 那样探针会假通过 —— fallback=OK 照打，但「读取失败」WARN 永不触发。
			var bad := FileAccess.open(path, FileAccess.WRITE)
			if bad == null:
				return false
			bad.store_line("[meta]")
			bad.store_line('crystals = "unterminated')
			bad.close()
		"unknown_id":
			var cfg2 := ConfigFile.new()
			cfg2.set_value("meta", "version", Meta.VERSION)
			cfg2.set_value("meta", "crystals", 12)
			cfg2.set_value("meta", "unlocked", ["u_根本不存在", "atk"])
			if cfg2.save(path) != OK:
				return false
		"bak_fallback":
			# 坏主档 + 好 .bak：读档必须回退 .bak
			var broken := FileAccess.open(path, FileAccess.WRITE)
			if broken == null:
				return false
			broken.store_line("[meta]")
			broken.store_line('crystals = "unterminated')
			broken.close()
			var good := ConfigFile.new()
			good.set_value("meta", "version", Meta.VERSION)
			good.set_value("meta", "crystals", 33)
			good.set_value("meta", "unlocked", [])
			if good.save(path + ".bak") != OK:
				return false
		_:
			return false
	_read_meta(path)
	print("[SMOKE-META] corrupt fallback=OK")
	return true


## 写局外存档；旧文件先另存 .bak（ConfigFile.save 非原子的兜底）
func save_meta() -> bool:
	var path := meta_path()
	if FileAccess.file_exists(path):
		var old := ConfigFile.new()
		if old.load(path) == OK:
			old.save(path + ".bak")
	var cfg := ConfigFile.new()
	meta["version"] = Meta.VERSION
	meta["saved_at"] = int(Time.get_unix_time_from_system())
	for k in meta.keys():
		cfg.set_value("meta", k, meta[k])
	var err := cfg.save(path)
	if err != OK:
		Dev.err("meta", "meta 存档写入失败：%s（err=%d）" % [path, err])
		return false
	return true


func _remove_file(path: String) -> void:
	if FileAccess.file_exists(path):
		DirAccess.remove_absolute(ProjectSettings.globalize_path(path))


## 结晶（局外货币）余额
func meta_crystals() -> int:
	return int(meta.get("crystals", 0))


## 已解锁的节点 id 集合（副本）
func meta_unlocked_ids() -> Array:
	var a: Array = meta.get("unlocked", [])
	return a.duplicate()


## 新解锁引导加成：节点 id → 还剩几局享 ×6
func meta_boost() -> Dictionary:
	var b: Dictionary = meta.get("boost", {})
	return b


func meta_boost_rounds(node_id: String) -> int:
	return int(meta_boost().get(node_id, 0))


## 局末递减引导加成：减到 0 即删键（弃局也要递减）
func meta_boost_tick() -> void:
	var boost := meta_boost()
	var changed := false
	for k in boost.keys():
		changed = true
		var v := int(boost[k]) - 1
		if v <= 0:
			boost.erase(k)
			if OS.get_environment("SMOKE_META_BOOST") != "":
				print("[SMOKE-META] boost: id=%s remaining=0 → key removed (×1.5 only)" % String(k))
		else:
			boost[k] = v
	if not changed:
		return
	meta["boost"] = boost
	save_meta()
	if OS.get_environment("SMOKE_META_BOOST") != "":
		for k in meta_boost().keys():
			print("[SMOKE-META] boost: id=%s remaining=%d (×9 active)" % [
				String(k), int(meta_boost()[k])])


func meta_is_unlocked(node_id: String) -> bool:
	return Meta.is_unlocked(node_id, meta.get("unlocked", []))


func meta_can_unlock(node_id: String) -> bool:
	return Meta.can_unlock(node_id, meta_crystals(), meta.get("unlocked", []))


## 购买解锁：校验 → 扣费 → 入集 → 落盘；落盘失败则回滚内存变更
func meta_unlock(node_id: String) -> bool:
	if not Meta.can_unlock(node_id, meta_crystals(), meta.get("unlocked", [])):
		return false
	var prev_crystals := meta_crystals()
	var prev_unlocked := meta_unlocked_ids()
	var owned := meta_unlocked_ids()
	owned.append(node_id)
	meta["unlocked"] = owned
	meta["crystals"] = prev_crystals - int(Meta.node(node_id).get("cost", 0))
	# 新解锁的升级卡给 3 局引导加成（§10.3）：包含解锁后的第 1 局
	if String(Meta.node(node_id).get("kind", "")) == "upgrade":
		var boost := meta_boost()
		boost[node_id] = int(Meta.BOOST_RUNS)
		meta["boost"] = boost
		if OS.get_environment("SMOKE_META_BOOST") != "":
			print("[SMOKE-META] boost: id=%s remaining=%d (×9 active)" % [
				node_id, int(Meta.BOOST_RUNS)])
	if not save_meta():
		meta["crystals"] = prev_crystals
		meta["unlocked"] = prev_unlocked
		return false
	meta_changed.emit(meta_crystals(), owned.size())
	return true


## 某条池内容当前是否可用（未解锁则不进池）
func meta_content_unlocked(kind: String, entry: Dictionary) -> bool:
	return Meta.content_available(kind, String(entry.get("id", "")), meta.get("unlocked", []))


## 局末结算：把本局累计拾取折算成结晶并落盘
## stats: {diamonds=本局累计拾取, kills, max_floor, time, score}
func meta_settle_run(stats: Dictionary) -> Dictionary:
	var pay := Meta.payout(stats)
	meta["crystals"] = meta_crystals() + pay
	meta["runs_played"] = int(meta.get("runs_played", 0)) + 1
	meta["best_floor"] = maxi(int(meta.get("best_floor", 0)), int(stats.get("max_floor", 0)))
	meta["total_kills"] = int(meta.get("total_kills", 0)) + int(stats.get("kills", 0))
	meta["total_time"] = float(meta.get("total_time", 0.0)) + float(stats.get("time", 0.0))
	meta["total_earned"] = int(meta.get("total_earned", 0)) + pay
	meta["last_played"] = int(Time.get_unix_time_from_system())
	save_meta()
	meta_boost_tick()
	meta_changed.emit(meta_crystals(), meta_unlocked_ids().size())
	return {"payout": pay, "crystals": meta_crystals()}


## 应用设置到主总线与表现层
func apply_settings() -> void:
	AudioServer.set_bus_volume_db(0, _coef_db("master"))
	_apply_window_settings()
	if main != null and is_instance_valid(main):
		if main.has_method("apply_audio_settings"):
			main.apply_audio_settings()
		if main.has_method("apply_ui_settings"):
			main.apply_ui_settings()


## 窗口模式与分辨率（Sprint 10 首批）。内容走 canvas_items 拉伸，逻辑分辨率恒 1280x720，
## 这里只改 OS 窗口尺寸/模式；headless 下 DisplayServer 为 dummy，直接跳过。
## 模式语义：0=窗口（分辨率预设生效） 1=全屏（独占） 2=无边框全屏（铺满屏幕）
func _apply_window_settings() -> void:
	if DisplayServer.get_name() == "headless":
		return
	var mode := clampi(int(settings.get("window_mode", 0)), 0, 2)
	var ds_mode := DisplayServer.WINDOW_MODE_WINDOWED
	match mode:
		1: ds_mode = DisplayServer.WINDOW_MODE_EXCLUSIVE_FULLSCREEN
		2: ds_mode = DisplayServer.WINDOW_MODE_FULLSCREEN
	var cur := DisplayServer.window_get_mode()
	if cur != ds_mode:
		DisplayServer.window_set_mode(ds_mode)
	# 分辨率仅窗口模式生效；两种全屏由系统接管尺寸
	if ds_mode == DisplayServer.WINDOW_MODE_WINDOWED:
		var parts := String(settings.get("resolution", "1280x720")).split("x")
		if parts.size() == 2:
			var w := clampi(int(parts[0]), 640, 7680)
			var h := clampi(int(parts[1]), 360, 4320)
			var size := Vector2i(w, h)
			if DisplayServer.window_get_size() != size:
				DisplayServer.window_set_size(size)
				var screen := DisplayServer.window_get_current_screen()
				var screen_pos := DisplayServer.screen_get_position(screen)
				var screen_size := DisplayServer.screen_get_size(screen)
				DisplayServer.window_set_position(screen_pos + (screen_size - size) / 2)
	if OS.get_environment("SMOKE") != "":
		print("[SMOKE-WIN] mode=%d resolution=%s os_size=%s" % [mode,
			settings.get("resolution", "?"), str(DisplayServer.window_get_size())])


func damage_number(pos: Vector2, amount: float, crit := false) -> void:
	if main and main.has_method("spawn_damage_number"):
		main.spawn_damage_number(pos, str(int(amount)), crit)


func add_score(v: int) -> void:
	score += v
	score_changed.emit(score)


func register_kill(base_score: int) -> void:
	kills += 1
	combo += 1
	combo_t = COMBO_WINDOW
	combo_pop.emit(combo)
	add_score(int(base_score * (1.0 + (combo - 1) * 0.1)))


func add_xp(v: int) -> void:
	xp += v
	while xp >= xp_need:
		xp -= xp_need
		level += 1
		xp_need = 5 + (level - 1) * 4
		level_reached.emit(level)
	xp_changed.emit(xp, xp_need, level)


## 时钟道具：敌人减速 + 世界染蓝（main 里处理色调），BGM 变调由 main 做
func slowmo(duration: float, factor: float) -> void:
	if _slow_tween and _slow_tween.is_valid():
		_slow_tween.kill()
	enemy_speed_mult = factor
	get_tree().create_timer(duration, false).timeout.connect(_slow_back)


func _slow_back() -> void:
	if _slow_tween and _slow_tween.is_valid():
		_slow_tween.kill()
	_slow_tween = create_tween()
	_slow_tween.tween_property(self, "enemy_speed_mult", 1.0, 0.6)


func fmt_time() -> String:
	var t := int(time)
	return "%02d:%02d" % [t / 60, t % 60]
