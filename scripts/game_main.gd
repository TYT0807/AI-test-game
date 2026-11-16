extends Node2D
## 主场景：地牢流转（房间/门/楼层）+ 竞技场搭建 + 相机 + BGM + 爆炸结算。

const PlayerScript := preload("res://scripts/player.gd")
const SlugScript := preload("res://scripts/slug.gd")
const BulletScript := preload("res://scripts/bullet.gd")
const TurretScript := preload("res://scripts/turret.gd")
const BombScript := preload("res://scripts/bomb.gd")
const ExplosionScript := preload("res://scripts/explosion.gd")
const PickupScript := preload("res://scripts/pickup.gd")
const ToxicCloudScript := preload("res://scripts/toxic_cloud.gd")
const PropScript := preload("res://scripts/prop.gd")
const SecretWallScript := preload("res://scripts/secret_wall.gd")
const MerchantScript := preload("res://scripts/merchant.gd")
const CrateScript := preload("res://scripts/crate.gd")
const DoorScript := preload("res://scripts/door.gd")
const ShopStandScript := preload("res://scripts/shop_stand.gd")
const HudScript := preload("res://scripts/hud.gd")
const DevOverlayScript := preload("res://scripts/dev_overlay.gd")
const UpgradePanelScript := preload("res://scripts/upgrade_panel.gd")
const ShrinePanelScript := preload("res://scripts/shrine_panel.gd")
const PrismWardenScript := preload("res://scripts/boss.gd")
const Boss2Script := preload("res://scripts/boss2.gd")
const Boss3Script := preload("res://scripts/boss3.gd")
const AllyScript := preload("res://scripts/ally.gd")

var _ally: Node2D = null  # kindred 印记的协战水晶（每局重生成）
const PCamHost := preload("res://addons/phantom_camera/scripts/phantom_camera_host/phantom_camera_host.gd")
const PCam2D := preload("res://addons/phantom_camera/scripts/phantom_camera/phantom_camera_2d.gd")
const Upgrades := preload("res://scripts/upgrades.gd")
const Meta := preload("res://scripts/meta.gd")
const MenuScript := preload("res://scripts/menu.gd")
const Relics := preload("res://scripts/relics.gd")
const DungeonClass := preload("res://scripts/dungeon.gd")

const ARENA_W := 44
const ARENA_H := 28
const TILE := 16
const WALL_COORD := Vector2i(3, 2)
const VOID_COORD := Vector2i(3, 0)
const HAZARD_COORD := Vector2i(2, 1)
const CABLE_COORD := Vector2i(2, 2)
const ZOOM := 3.0
const FLOOR_TINTS := [
	Color(1, 1, 1),
	Color(0.82, 0.9, 1.14),
	Color(1.16, 0.85, 0.82),
	Color(0.85, 1.14, 0.88),
	Color(1.12, 1.05, 0.8),
]

var player: CharacterBody2D
var turret: Node2D
var entities: Node2D
var hud: CanvasLayer
var upgrade_panel: CanvasLayer
var shrine_panel: CanvasLayer
var camera: Camera2D
var world_mod: CanvasModulate = null  # 弃用：兼容渲染器下会把世界压暗，改用 fx_rect
var _pcam: Node2D
var _fx_rect: ColorRect
var _fade_rect: ColorRect

var _floor_layer: TileMapLayer
var _wall_layer: TileMapLayer
var _bgm: Array[AudioStreamPlayer] = []
var menu: CanvasLayer
var _bgm_track := -1
var _bgm_cur := 0

var _trauma := 0.0
var _game_over := false
var _run_settled := false   # 本局是否已结算（防止死亡→重开交错导致重复入账）
var _boost_ticked := false  # 本局引导加成是否已递减（防止结算 + 回主菜单双减）
var _telegraphs := 0
var _smoke := false
var _smoke_frame := 0
var _smoke_door_repeat: Dictionary = {}   # BUG-001：按层记录同一过门重复次数
var _smoke_stall_pos: Vector2 = Vector2.ZERO
var _smoke_stall_t: float = 0.0
var _shop_bought := false
var _room_damaged := false  # 当前房间是否掉过血（无伤挑战用）
var _secret_bombed_dirs: Dictionary = {}  # SMOKE：本房间已炸过的秘密墙方向；逐帧逐个处理，避免同帧多次重建

# 地牢流转
var dungeon: Dungeon
var room_state := "cleared"  # enter / combat / cleared
var _transitioning := false
var _room_budget := 0
# ---- Sprint 4：挑战因子 / 残响共鸣 ----
var modifier := "none"
var enemy_hp_mult := 1.0
var enemy_speed_mult := 1.0
var abyss_hp_mult := 1.0
var abyss_speed_mult := 1.0
var abyss_dmg_mult := 1.0
var abyss_tier := 0
var diamond_mult := 1.0
var resonance := 0
var _resonance_step := 5
var _theme_rule := ""
var _bfs_warned := false
var _theme_t := 0.0
var _room_spawned := 0
var _spawn_cd := 0.0
var _doors: Array = []
var auto_door_dir := Vector2i.ZERO  # 自动驾驶当前选定的过门方向（贴身卡住时兜底直触）
var _room_nodes: Array = []  # 门/装饰等房间级节点，换房时统一回收
var _squad_queue: Array = []  # F3 当前房的编队成员队列（空 = 走随机池）
var _squad_id := ""
var _shot_frames: Array = []
var _shot_idx := 0
var _stall_last_kills := 0
var _stall_t := 0.0
var _scholar_floor_done := -1  # 博学印记：本层已发过首次清场奖励
# E 灾祸层（Sprint 12 §6.3）：每层 15% 触发一个负面灾祸，本层生效、换层清除
var _calamity := ""
var _calamity_floor := -1
var _calamity_frail_cut := 0
var _calamity_saved_diamond_mult := 1.0
var _calamity_saved_mag_cap_mult := 1.0
var _calamity_theme_rule := ""     # S27 复合变体身份：施加瞬间快照主题派生结果，clear 只读它（禁现查 floor_num——陷阱 1：换层时 floor_num 已先自增）
const _OG_TOAST_TAG := "誓约遗赠"   # S27 批二：遗赠 toast 首词（D01 锚点；探针侧 _OG_TAG 须与本值逐字一致）
var _calamity_frail_ratio := 0.2   # S27：本层实际虚弱比例（文案按实值显示，见 _calamity_name / _frail_ratio）
var _calamity_speed_mult_applied := 1.0   # S31：frenzy 施加时实际倍率（文案只读快照，不读 live）
var _calamity_ammo_mult_applied := 1.0    # S31：scarce_ammo 施加时实际弹匣系数（同上）
var _calamity_forced := false  # SMOKE_CALAMITY：跳过 15% 概率强制触发
var _mod_enemy_speed_mult := 1.0   # S27 批三：modifier 贡献的敌速倍率（与主题贡献分离）
var _mod_diamond_mult := 1.0       # S27 批三：modifier 贡献的残响倍率（同上——live 值 = _mod_* + 主题 maxf）


func _ready() -> void:
	Game.main = self
	Game.reset()
	Upgrades.reset()
	_smoke = OS.get_environment("SMOKE") != ""
	Engine.time_scale = 2.0 if _smoke else 1.0

	entities = Node2D.new()
	entities.y_sort_enabled = true
	add_child(entities)

	player = PlayerScript.new()
	player.position = Vector2(ARENA_W, ARENA_H) * TILE * 0.5
	entities.add_child(player)
	player.died.connect(_on_player_died)
	player.damaged.connect(func(_amt: int) -> void:
		if room_state == "combat" and dungeon != null and dungeon.rooms.has(dungeon.current) \
				and String(dungeon.room(dungeon.current).get("kind", "")) == "challenge":
			_room_damaged = true)

	turret = TurretScript.new()
	entities.add_child(turret)
	turret.target = player

	_build_fx_layers()
	_build_camera()

	for i in 2:
		var p := AudioStreamPlayer.new()
		p.volume_db = -80.0
		add_child(p)
		_bgm.append(p)
	_switch_bgm(0, true)

	hud = HudScript.new()
	add_child(hud)
	upgrade_panel = UpgradePanelScript.new()
	add_child(upgrade_panel)
	upgrade_panel.chosen.connect(_on_upgrade_chosen)
	shrine_panel = ShrinePanelScript.new()
	add_child(shrine_panel)
	shrine_panel.chosen.connect(_on_shrine_chosen)

	Game.level_reached.connect(_on_level_up)

	# 启动自检：注册表/贴图/房间映射；F3 面板可随时看日志
	var problems := Validate.run()
	if _smoke:
		print("[SMOKE] validate problems=%d" % problems.size())
	add_child(DevOverlayScript.new())

	# 坑 7 回归：面板查一个不存在的图标 key，必须走 xicon 白图回退而不是直接查表抛错
	if _smoke and OS.get_environment("SMOKE_RG7") != "":
		var t: Texture2D = upgrade_panel._icon_for("__rg7_missing_key__")
		Dev.check(t != null, "rg7", "upgrade_panel 对不存在的图标 key 返回 null")
		print("[RG-7] upgrade_panel._icon_for(nonexistent) texture=%s" % ("ok" if t != null else "NULL"))

	if _smoke:
		# 固定种子可复现某张地图：SMOKE_SEED=12345
		var seed_env := OS.get_environment("SMOKE_SEED")
		if seed_env != "":
			Game.rng.seed = int(seed_env)
		print("[SMOKE] seed=%d" % Game.rng.seed)

	menu = MenuScript.new()
	add_child(menu)
	apply_ui_settings()

	# 验证钩（须在 start_run 之前：daily_mode 影响种子覆盖、calamity_forced 影响层数灾祸）
	if _smoke and OS.get_environment("SMOKE_DAILY") != "":
		Game.daily_mode = true
	if _smoke and OS.get_environment("SMOKE_CALAMITY") != "":
		_calamity_forced = true
	start_run()

	if _smoke:
		player.autopilot = true
		player._immortal = OS.get_environment("SMOKE_DEATH") == ""
		if OS.get_environment("SMOKE_SAVE") != "":
			_test_save_roundtrip()
		if OS.get_environment("SMOKE_SHOTS") != "":
			for s in OS.get_environment("SMOKE_SHOTS").split(","):
				_shot_frames.append(int(s))
		if not player._immortal:
			player.max_hp = 1
			player.hp = 1
			# 每秒强制受击，直到死亡：验证死亡→结算→重开链路（单次探针会被过场锁操作吞掉）
			var death_probe := Timer.new()
			death_probe.wait_time = 1.0
			death_probe.autostart = true
			death_probe.timeout.connect(func() -> void:
				if is_instance_valid(player) and not player.dead:
					player.take_damage(1, player.global_position + Vector2.RIGHT)
				else:
					death_probe.queue_free())
			add_child(death_probe)
		player.bullet_dmg_mult = 10.0
		player.fire_rate_mult = 3.0
		player.extra_count = 2
		# SMOKE_BOSS 验证钩：火力 ×5 再提速，确保 Headless 预算内走完 Boss 房全链
		if OS.get_environment("SMOKE_BOSS") != "":
			player.bullet_dmg_mult = 50.0
		upgrade_panel.autopilot = true
		print("[SMOKE] autopilot on")
		# S-03 显示探针：强制非零状态值，验证 HUD 三个图标 + 数值确实刷新
		if OS.get_environment("SMOKE_STATUS") != "":
			player.shield_charges = 2
			player.chain_chance = 0.5
			player.poison_chance = 0.6
			print("[SMOKE] status probe: shield=2 chain=50% venom=60%")
		if OS.get_environment("SMOKE_META") != "" or OS.get_environment("SMOKE_META_POOL") != "" \
				or OS.get_environment("SMOKE_META_POOLASSERT") != "" \
				or OS.get_environment("SMOKE_META_UNLOCKTEST") != "" \
				or OS.get_environment("SMOKE_META_APPLY") != "" \
				or OS.get_environment("SMOKE_META_BUY") != "" \
				or OS.get_environment("SMOKE_META_SAVE") != "" \
				or OS.get_environment("SMOKE_META_CORRUPT") != "" \
				or OS.get_environment("SMOKE_META_RNGCOUNT") != "" \
				or OS.get_environment("SMOKE_META_QUIT") != "":
			_smoke_meta_probe()
		if OS.get_environment("SMOKE_CAL_THEME") != "":
			_smoke_cal_theme_probe()
		if OS.get_environment("SMOKE_OATH_GRANT") != "":
			_test_oath_grant()
		if OS.get_environment("SMOKE_PURIFY_COST") != "":
			_test_purify_cost()
		if OS.get_environment("SMOKE_START_BUFFER") != "":
			_test_start_buffer()
		if OS.get_environment("SMOKE_S32_SHRINE") != "":
			_smoke_s32_shrine_probe()


func _process(delta: float) -> void:
	_trauma = maxf(0.0, _trauma - 2.4 * delta)
	if camera:
		var s := _trauma * _trauma * 12.0
		camera.offset = Vector2(Game.fx_rng.randf_range(-s, s), Game.fx_rng.randf_range(-s, s))
	if not _game_over:
		_tick_room(delta)
		_tick_floor_theme(delta)
	if _smoke:
		_smoke_frame += 1
		if OS.get_environment("SMOKE_REPRO_TRACE") != "" and _smoke_frame % 150 == 0:
			print("[SMOKE-META-EXTRA] repro frame=%d time=%.4f" % [_smoke_frame, Game.time])
		if OS.get_environment("SMOKE_DUMP") != "" and (_smoke_frame == 240 or _smoke_frame % 1200 == 0):
			_dump_entities()
		if _smoke_frame == 3000 and OS.get_environment("SMOKE_SAVE") != "":
			_test_save_roundtrip()
		if _smoke_frame % 150 == 0:
			print("[SMOKE] t=%.1f floor=%d room=(%d,%d) %s state=%s doors=%d kills=%d enemies=%d" % [
				Game.time, Game.floor_num, dungeon.current.x, dungeon.current.y,
				dungeon.room(dungeon.current).get("kind", "?"), room_state, _doors.size(),
				Game.kills, get_tree().get_nodes_in_group("enemies").size()])
			if _smoke_frame % 450 == 0:
				print("[SMOKE-CAM] player=%s camera=%s" % [
					player.global_position.round(), camera.get_screen_center_position().round()])
		if _smoke_frame % 900 == 0:
			for e in get_tree().get_nodes_in_group("enemies"):
				print("[SMOKE-E] %s hp=%.0f pos=%s" % [e.variant, e.hp, e.global_position.round()])
		# 击杀停滞探针：连续 8 秒没击杀且有敌人时， dump 敌情
		if Game.kills == _stall_last_kills:
			_stall_t += delta
		else:
			_stall_last_kills = Game.kills
			_stall_t = 0.0
		if _stall_t > 8.0 and not get_tree().get_nodes_in_group("enemies").is_empty():
			_stall_t = 0.0
			print("[SMOKE-STALL] player=%s room=%s state=%s" % [
				player.global_position.round(), dungeon.current, room_state])
			for e in get_tree().get_nodes_in_group("enemies"):
				print("[SMOKE-STALL]   %s hp=%.1f pos=%s dead=%s" % [
					e.variant, e.hp, e.global_position.round(), e.dead])
		if OS.get_environment("SMOKE_SHOTS") != "" and not _shot_frames.is_empty():
			if _smoke_frame >= int(_shot_frames[0]):
				_shot_frames.pop_front()
				var img := get_viewport().get_texture().get_image()
				img.save_png("D:/Create/Game/_tools/dungeon_shot_%d.png" % _shot_idx)
				_shot_idx += 1
				print("[SMOKE] shot saved at frame ", _smoke_frame)
		_smoke_shop_tick()
		_smoke_secret_tick()
		# BUG-001 断言：清场后坐标长时间几乎不动（纯 print，不产生 ERROR 行）
		if room_state == "cleared" and is_instance_valid(player):
			_smoke_stall_t += delta
			if _smoke_stall_t >= 10.0:
				if player.global_position.distance_to(_smoke_stall_pos) < 8.0:
					print("[SMOKE-LOOP] position nearly unchanged room=%s pos=%s" % [
						dungeon.current, player.global_position.round()])
				_smoke_stall_pos = player.global_position
				_smoke_stall_t = 0.0


# ---------------- 地牢流转 ----------------

## 每层地图的派生 rng：种子只由 (run_seed, 层号) 决定
func _floor_rng(floor_num: int) -> RandomNumberGenerator:
	var r := RandomNumberGenerator.new()
	r.seed = int(hash("%d:%d" % [Game.run_seed, floor_num]))
	return r


## SMOKE 探针：每层地图指纹（房间坐标集 + 房型序列）
## 用于「解锁档 vs 默认档」的第 2 层及以后地图逐字比对（规格 §8.E）
func _smoke_fingerprint(floor_num: int) -> void:
	if OS.get_environment("SMOKE_META_FINGERPRINT") == "":
		return
	if dungeon == null:
		return
	var coords: Array = []
	for c in dungeon.rooms.keys():
		coords.append(c)
	coords.sort_custom(func(a, b): return str(a) < str(b))
	var rooms_s: Array = []
	var kinds_s: Array = []
	for c in coords:
		rooms_s.append(str(c))
		kinds_s.append(String(dungeon.rooms[c].get("kind", "?")))
	print("[SMOKE-META] fingerprint floor=%d rooms=%s kinds=%s" % [
		floor_num, ",".join(rooms_s), ",".join(kinds_s)])

func start_run() -> void:
	# 局内状态归零：残响 / 击杀 / 升级已选次数 / 里程碑。
	# 必须早于 _roll_modifier()，否则 barren 因子的开局 +10 残响会被清零。
	Game.reset()
	Upgrades.reset()
	_run_settled = false
	_boost_ticked = false
	_oath_counters = {}   # Sprint 16 A/B：誓约计数与抉择链按局归零
	_echo_choices = []
	_echo_costs = {}
	Game._flavor_pending.clear()   # Sprint 22 附限定②：开局清聚合缓冲——极端帧边界不把陈旧 pending 带进新局
	Game.floor_num = 1
	# D 每日挑战（Sprint 12 §6.2）：daily 模式在 rng 首抽前覆盖 seed（E1 零漂移——
	# 同日期派生同 seed，整局可复现；run_seed 随之等于 daily_seed，指纹自然一致）
	if Game.daily_mode:
		Game.daily_seed = Game.daily_seed_for(Game.daily_key())
		Game.rng.seed = Game.daily_seed
		if OS.get_environment("SMOKE_DAILY") != "":
			print("[SMOKE-DAILY] key=%s seed=%d" % [Game.daily_key(), Game.daily_seed])
	# C 契约（Sprint 11 §四）：印记注入——必须在任何 Game.rng 绘制之前调用。
	# 只改起始状态，不改 rng 消耗顺序：同 seed + 同印记 = 整局可复现（E1 零漂移）。
	_apply_sigil_contract()
	# Sprint 14 C：图鉴发现度被动——开局一次性起始状态（复用既有接口，载体硬约束草案 §5.4）。
	# 注入在契约同段之后、rng 首抽之前：只改起始状态不改 rng 消耗顺序（E1 零漂移，同上口径）
	_apply_codex_boons()
	_oath_grant()   # S27 批二：誓约遗赠（连兑现 → 开局残响）——必须在契约（purse 是赋值会抹前置注入）之后、rng 首抽前（零 rng 纪律）
	# 每层地图用「由 (run_seed, 层号) 派生」的独立 rng：第 N 层地图只由 (run_seed, N)
	# 决定，与帧数 / 战斗节奏 / 解锁内容完全无关（解锁档与默认档地图逐字一致）
	Game.run_seed = Game.rng.seed
	Game.reset_fx_rng()
	var frng := _floor_rng(1)
	dungeon = DungeonClass.generate(1, frng, 7 + frng.randi_range(0, 2))
	_smoke_fingerprint(1)
	_roll_modifier()
	# Sprint 21 C：深渊难度档——按所选 tier 确定性乘定（零 rng / 零顺序变化）
	abyss_hp_mult = 1.0
	abyss_speed_mult = 1.0
	abyss_dmg_mult = 1.0
	if abyss_tier > 0 and Data.ABYSS_TIERS.has(abyss_tier):
		var at: Dictionary = Data.ABYSS_TIERS[abyss_tier]
		abyss_hp_mult = float(at["hp"])
		abyss_speed_mult = float(at["speed"])
		abyss_dmg_mult = float(at["dmg"])
	if is_instance_valid(hud):
		hud.set_abyss_tier(abyss_tier)
	# E 灾祸层（Sprint 12 §6.3）：在 modifier 之后滚（scarce_ore 的 diamond_mult
	# 不会被 challenge factor 的重置抹掉）
	_roll_calamity()
	if OS.get_environment("SMOKE_RUN_START") != "":
		print("[SMOKE-META] run start diamonds=%d taken=%d modifier=%s" % [
			Game.diamonds, Upgrades.taken.size(), modifier])
	_apply_floor_theme()
	update_floor_sign()   # Sprint 16 C：层签刷新（modifier/calamity/theme roll 全完成后、进房前——零 rng 顺序改动）
	# 探针：直接跳到指定楼层（只看主题色调与 HUD 提示），仅 SMOKE
	var jump_env := OS.get_environment("SMOKE_JUMP_FLOOR")
	if _smoke and jump_env != "":
		Game.floor_num = int(jump_env)
		# Sprint 17 A1：跳层后重刷层签——原先只有 :370 刷一次（floor=1 的「无主题」），
		# 跳层后若不补刷，层签文本与实际层不符。update_floor_sign() 纯只读拼装，
		# 零 Game.rng / fx_rng / 零抽取；不移动任何 roll（E1 顺序不变）。
		var rs_before = Game.rng.state
		var fs_before = Game.fx_rng.state
		_apply_floor_theme()
		update_floor_sign()
		if OS.get_environment("SMOKE_FLOOR_SIGN") != "":
			var jt: Dictionary = Data.theme_for_floor(Game.floor_num)
			var jtext := String(hud._floor_sign_label.text)
			# 无主题层（<4）没有可比对的主题名，跳过文本断言，避免 contains("") 恒过假绿灯
			if not jt.is_empty():
				Dev.check(jtext.contains(String(jt.get("name", ""))), "floor_sign",
					"A1: 跳层后层签含第 %d 层主题名（%s）" % [Game.floor_num, jtext])
			Dev.check(Game.rng.state == rs_before and Game.fx_rng.state == fs_before,
				"floor_sign", "A1: 跳层重刷零 Game.rng / fx_rng 消费")
			# 表外探针落地证据：Dev.check 只在失败时打印，故显式留一行成功证据（零 rng、不进指纹）
			print("[SMOKE-FLOOR-SIGN] A1: floor=%d sign=%s theme=%s rng_same=%s fx_same=%s" % [
				Game.floor_num, jtext, String(jt.get("name", "")),
				str(Game.rng.state == rs_before), str(Game.fx_rng.state == fs_before)])
	if _smoke:
		var kinds := {}
		for c in dungeon.rooms:
			var k: String = dungeon.rooms[c]["kind"]
			kinds[k] = int(kinds.get(k, 0)) + 1
		print("[SMOKE] dungeon map: ", dungeon.rooms.size(), " rooms ", kinds)
	_enter_room(dungeon.current, Vector2i.ZERO)
	if OS.get_environment("SMOKE_ABYSS") != "":
		_smoke_abyss_check()


## 每局开局抽 1 个挑战因子并应用（一利一弊）
## E 灾祸层（Sprint 12 §6.3）：每层首次进入时 15% 触发一个负面灾祸（走既有 Game.rng 流），
## 本层生效、换层清除；触发过灾祸的局，shards 结算 ×1.5（风险回报，game_state.settle_shards）
## Sprint 21 C：SMOKE_ABYSS 探针——验证深渊乘子接线（start_run）+ hp 注入（Slug.setup 折乘）
## + dmg 唯一入口动态验伤（player.take_damage 真实施加一次伤害）。
## 断言分类：mult 匹配 = 验效果型（证明 start_run 接线）；Slug 缩放 = 验效果型（证明 hp 注入）；
## dmg 动态验伤 = 验效果型（证明受创 = round(base × abyss_dmg_mult)，修 QA D-5 虚假通过）；
## t==0 全 1.0 = 前提守卫型恒过。harness 以 SMOKE_ABYSS=env 给定 tier 复算，保证可复现。
func _smoke_abyss_check() -> void:
	var t := int(OS.get_environment("SMOKE_ABYSS"))
	var base_hp: float = float(Data.ENEMIES["goblin"].get("hp", 1))
	if t <= 0:
		Dev.check(abyss_hp_mult == 1.0 and abyss_speed_mult == 1.0 and abyss_dmg_mult == 1.0,
			"abyss", "t=0 三乘子全 1.0（前提守卫型恒过）")
		print("[SMOKE-ABYSS] t=0 mults=1.0 ok")
		return
	if t < 1 or t > Data.ABYSS_MAX_TIER:
		Dev.err("abyss", "SMOKE_ABYSS 越界 t=%d" % t)
		return
	# 以 env 给定 tier 复算，证明 start_run 接线（不依赖菜单预置 abyss_tier）。
	# 探针仅 SMOKE 生效；末尾原样还原 tier 与三乘子，不污染本次进程后续帧（修 QA D-2）。
	var tier_orig := abyss_tier
	var hp_orig := abyss_hp_mult
	var sp_orig := abyss_speed_mult
	var dm_orig := abyss_dmg_mult
	abyss_tier = t
	abyss_hp_mult = 1.0
	abyss_speed_mult = 1.0
	abyss_dmg_mult = 1.0
	if Data.ABYSS_TIERS.has(abyss_tier):
		var at: Dictionary = Data.ABYSS_TIERS[abyss_tier]
		abyss_hp_mult = float(at["hp"])
		abyss_speed_mult = float(at["speed"])
		abyss_dmg_mult = float(at["dmg"])
	Dev.check(abyss_hp_mult == float(Data.ABYSS_TIERS[t]["hp"]), "abyss",
		"start_run 接线 hp_mult=%f 期望=%f" % [abyss_hp_mult, float(Data.ABYSS_TIERS[t]["hp"])])
	Dev.check(abyss_speed_mult == float(Data.ABYSS_TIERS[t]["speed"]), "abyss",
		"start_run 接线 speed_mult=%f 期望=%f" % [abyss_speed_mult, float(Data.ABYSS_TIERS[t]["speed"])])
	Dev.check(abyss_dmg_mult == float(Data.ABYSS_TIERS[t]["dmg"]), "abyss",
		"start_run 接线 dmg_mult=%f 期望=%f" % [abyss_dmg_mult, float(Data.ABYSS_TIERS[t]["dmg"])])
	# hp 注入验证（验效果型）：直接构造 Slug，按契约 setup("goblin", 1, 1)，
	# baseline 不含 abyss（= 基础 hp × 波次/层缩放 × enemy_hp_mult），
	# 断言 max_hp == round(baseline × abyss_hp_mult) 证明注入生效。
	# 注：spawn_slug 走 wave=0，与基线公式不一致，故此处直接 new+setup 以对齐契约。
	# Slug 未入树时 sprite 为 null，slug.gd 的染色行已有空守卫（修 QA D-1 的 SCRIPT ERROR）。
	var s := SlugScript.new()
	s.setup("goblin", 1, 1)
	var baseline := base_hp * (1.0 + 1 * 0.12) * (1.0 + 1 * 0.55) * enemy_hp_mult  # 不含 abyss
	var expect_hp := int(round(baseline * abyss_hp_mult))
	Dev.check(int(round(s.max_hp)) == expect_hp, "abyss",
		"注入：goblin max_hp=%d 期望=%d（baseline=%d abyss×%f）" % [
			int(round(s.max_hp)), expect_hp, int(round(baseline)), abyss_hp_mult])
	print("[SMOKE-ABYSS] t=%d 注入验证 goblin max_hp=%d (baseline=%d)" % [t, int(round(s.max_hp)), int(round(baseline))])
	s.queue_free()
	# dmg 动态验伤（验效果型，修 QA D-5）：真实施加一次已知基准伤害，验证
	# 「玩家受创 == round(base × abyss_dmg_mult)」，证明乘子在 take_damage 单一入口生效。
	# 旧探针只静态比对 abyss_dmg_mult 变量值，且 headless 默认 _immortal=true 令缩放分支从未执行。
	if is_instance_valid(player) and not player.dead and not player.control_locked:
		var hp0: int = player.hp
		var imm0: bool = player._immortal
		var ward0: bool = player.sigil_ward
		var shield0: int = player.shield_charges
		var inv0: float = player._invuln_t
		var kin0: bool = player.has_kinetic
		var hits0: int = int(_oath_counters.get("hits_taken", 0))
		var room_dmg0: bool = _room_damaged
		# 抬高 hp 避开濒死/死亡分支；清空会改写或抵挡 dmg 的守卫，制造纯净单一入口语境
		var hp_probe := 100000
		var test_dmg := 10
		player.hp = hp_probe
		player._immortal = false
		player.sigil_ward = false
		player.shield_charges = 0
		player._invuln_t = 0.0
		player.has_kinetic = false
		player.take_damage(test_dmg, Vector2.ZERO, null)
		var taken: int = hp_probe - player.hp
		var expect_taken: int = int(round(float(test_dmg) * abyss_dmg_mult))
		Dev.check(taken == expect_taken, "abyss",
			"dmg 动态验伤：受创=%d 期望=%d（base=%d abyss_dmg×%f）" % [
				taken, expect_taken, test_dmg, abyss_dmg_mult])
		print("[SMOKE-ABYSS] t=%d dmg 动态验伤 taken=%d expect=%d" % [t, taken, expect_taken])
		# 还原探针造成的一切玩家/本局状态（探针不改本局进程）
		player.hp = hp0
		player._immortal = imm0
		player.sigil_ward = ward0
		player.shield_charges = shield0
		player._invuln_t = inv0
		player.has_kinetic = kin0
		player._knock = Vector2.ZERO
		if is_instance_valid(player.sprite):
			player.sprite.modulate = Color.WHITE
		player.hp_changed.emit(hp0, player.max_hp)
		_oath_counters["hits_taken"] = hits0
		_room_damaged = room_dmg0
	else:
		print("[SMOKE-ABYSS] t=%d dmg 动态验伤跳过：player 不可用（前提守卫型）" % t)
	print("[SMOKE-ABYSS] t=%d hp=%f speed=%f dmg=%f" % [t, abyss_hp_mult, abyss_speed_mult, abyss_dmg_mult])
	# 原样还原运行配置（SMOKE 专用路径，生产不进此函数）
	abyss_tier = tier_orig
	abyss_hp_mult = hp_orig
	abyss_speed_mult = sp_orig
	abyss_dmg_mult = dm_orig


func _roll_calamity() -> void:
	_calamity = ""
	var rolled := Game.rng.randf()
	# 核验 #4 修复：强制开关只认 SMOKE_CALAMITY 显式环境变量；
	# 普通 SMOKE 走自然 15%（不隐式强制，保回归可比性）
	if not _calamity_forced and rolled > 0.15:
		return
	if Game.floor_num < 2:
		return  # 第 1 层保底无灾祸（新手保护）
	_calamity = ["frail", "frenzy", "scarce_ammo", "scarce_ore"][Game.rng.randi_range(0, 3)]
	if not Game.calamity_floors.has(Game.floor_num):
		Game.calamity_floors.append(Game.floor_num)   # B5：同层不重复登记（Array.erase 只删首个，防残留）
	_apply_calamity()
	hud.flash_toast("灾祸降临：" + _calamity_name(_calamity))
	hud.banner("灾祸 · " + _calamity_name(_calamity))
	Game.sfx("calamity", 0.9, -6.0)   # Sprint 13 E：灾祸事件音（assets.gd 别名，复用既有 wav）
	if _smoke or _calamity_forced:
		print("[SMOKE-CALAMITY] floor=%d calamity=%s" % [Game.floor_num, _calamity])


## S27 复合变体：虚弱削减比例按主题分层（vein 贴身单杀换残响吃不满 / silent 看不见绕不开）。
## 只读快照 _calamity_theme_rule，禁止现查 Game.floor_num（陷阱 1）
func _frail_ratio() -> float:
	match _calamity_theme_rule:
		"vein": return 0.1
		"silent": return 0.4
	return 0.2


func _calamity_name(id: String) -> String:
	# S27 §4.5：百分比按实值显示（变体上线后写死值会撒谎），族名首词逐字保留
	match id:
		"frail":
			# S28 批二：读实际削减（钳制后重算的 _calamity_frail_cut），0 削减不显示 -0%
			if _calamity_frail_cut <= 0:
				return "虚弱（生命上限不再削减）"
			return "虚弱（生命上限 -%d%%）" % int(round(100.0 * float(_calamity_frail_cut) / float(maxi(1, player.max_hp + _calamity_frail_cut))))
		"frenzy":
			# S31：读施加时快照（不读 live）；增量 <=0 走「不再加速」，禁 0%
			if _calamity_speed_mult_applied <= 1.0:
				return "狂乱（敌人不再加速）"
			return "狂乱（敌人加速 %d%%）" % int(round((_calamity_speed_mult_applied - 1.0) * 100.0))
		"scarce_ammo":
			# S31：读施加时快照（不读 live）；削减 <=0 走「不再削减」，禁 -0%
			if _calamity_ammo_mult_applied >= 1.0:
				return "弹药荒（弹匣不再削减）"
			return "弹药荒（弹匣 -%d%%）" % int(round((1.0 - _calamity_ammo_mult_applied) * 100.0))
		"scarce_ore":
			var base: float = maxf(_calamity_saved_diamond_mult, 0.001)
			var ore_cut := 1.0 - 0.7 / base
			# S28 批二：barren 局 base=0.7 → 实际削减 0 → 不许显示 -0%
			if ore_cut <= 0.0:
				return "残响枯竭（残响不再削减）"
			return "残响枯竭（残响掉落 -%d%%）" % int(round(ore_cut * 100.0))
	return id


func _apply_calamity() -> void:
	# 保存进入灾祸前的倍率（换层还原用——核验 #2：不抹 modifier 全局倍率）
	_calamity_saved_diamond_mult = Game.main.diamond_mult
	_calamity_saved_mag_cap_mult = player.mag_cap_mult
	# S27：施加瞬间快照主题 rule（clear 只读它）。🔴 必须经 Data 主题派生函数（内部 4+((n-4)%8)，
	# 12 层回卷 vein）——禁止绕过它直查 FLOOR_THEMES 表：floor_num 直下标在 12 层拿空字典 → 变体静默失效
	_calamity_theme_rule = String(Data.theme_for_floor(Game.floor_num).get("rule", ""))
	match _calamity:
		"frail":
			# 核验 #3：cut 差值增量还原（与层内成长解耦，避免绝对值还原吞成长）
			# 终审边界：存「实际」削减量（max_hp 已到钳制下限时可能为 0），否则 clear 会凭空 +1 血上限
			var old_hp: int = player.max_hp
			_calamity_frail_ratio = _frail_ratio()
			_calamity_frail_cut = maxi(1, int(round(old_hp * _calamity_frail_ratio)))
			player.max_hp = maxi(2, old_hp - _calamity_frail_cut)
			_calamity_frail_cut = old_hp - player.max_hp
			player.hp = mini(player.hp, player.max_hp)
			player.hp_changed.emit(player.hp, player.max_hp)
		"frenzy":
			# S27 复合变体：沼泽本就拖玩家脚步、冰面玩家收不住——两个主题的杠杆都压在玩家位移上，
			# 都能把「敌人加速」推得更深（方向从主题杠杆推出，不是无脑加难）
			match _calamity_theme_rule:
				"swamp":
					Game.calamity_speed_mult = 1.45
				"ice":
					Game.calamity_speed_mult = 1.4
				_:
					Game.calamity_speed_mult = 1.25
			# S31：存写进效果通道的那个数（施加时快照）——文案只读它，抗后续 live 漂移
			_calamity_speed_mult_applied = Game.calamity_speed_mult
		"scarce_ammo":
			# S27 复合变体：岩浆逼你走位站不定 → 弹匣不再是瓶颈；藤替你堵路 → 不必按原量开火
			match _calamity_theme_rule:
				"magma":
					player.mag_cap_mult = 0.7
				"vines":
					player.mag_cap_mult = 0.65
				_:
					player.mag_cap_mult = 0.5
			# S31：施加时快照实际弹匣系数（文案只读它）
			_calamity_ammo_mult_applied = player.mag_cap_mult
			player.mag_changed.emit(player.mag(), player.mag_cap())
		"scarce_ore":
			if Game.main != null and is_instance_valid(Game.main):
				Game.main.diamond_mult = minf(Game.main.diamond_mult, 0.7)


## 换层清除：按灾祸类型条件还原（_calamity == "" 时完全不碰倍率——核验 #2 层流程断言①）
func _clear_calamity_effects() -> void:
	match _calamity:
		"frail":
			if is_instance_valid(player):
				player.max_hp += _calamity_frail_cut   # 差值增量还原（含层内成长）
				player.hp = mini(player.hp, player.max_hp)
				player.hp_changed.emit(player.hp, player.max_hp)
		"scarce_ammo":
			if is_instance_valid(player):
				player.mag_cap_mult = _calamity_saved_mag_cap_mult
				player.mag_changed.emit(player.mag(), player.mag_cap())
		"scarce_ore":
			if Game.main != null and is_instance_valid(Game.main):
				Game.main.diamond_mult = _calamity_saved_diamond_mult
		"frenzy":
			Game.calamity_speed_mult = 1.0   # 二轮重写丢失的无条件还原（本轮核验补回——frenzy 曾跨层固化整局）
	if _calamity != "":
		# B6：saved 值重置收拢进条件——空灾祸层 clear 前后 saved 保持不变（纯语义收拢，零行为变化）
		_calamity_frail_cut = 0
		_calamity_saved_diamond_mult = 1.0
		_calamity_saved_mag_cap_mult = 1.0
		_calamity_theme_rule = ""      # S27：变体身份随灾祸一起失效。🔴 禁止在此处现查 floor_num/_theme_rule（陷阱 1：floor 已是新层；_theme_rule 恰为旧值纯属调用顺序巧合）
		_calamity_frail_ratio = 0.2    # S27：比例复位为基线
		_calamity_speed_mult_applied = 1.0   # S31：快照随灾祸同生共死（不跨层/跨局）
		_calamity_ammo_mult_applied = 1.0


## ---------------- Sprint 27 批一：主题×灾祸复合探针（SMOKE_CAL_THEME） ----------------
## 断言死数：A 组 66 / B 组 76（实施单 §5.3，写死不许公式现算）。
## 打印纪律（实施单 §5.1）：Dev.check 只在失败时打印（dev_log.gd:29-32），[ERR]=0 不构成执行证明——
## 故入口无条件打印、每条断言伴随无条件 #NN 行、末尾 done checked=… 并自校验 checked==declared。
## 三段式（§5.2）：段1 施加 → 段2 换层精确还原 → 段3 再施加幂等；换层构造复刻 next_floor
## 生产顺序（game_main.gd:1505-1509：floor 自增 → clear → 清 id → 主题），禁用真实 next_floor()。
const _CT_DECLARED := 117  # 批三 103 + S28 批二 G7 + H7（口径 G08=刀一变异非运行期断言；单子 118 按「按实报」条款收 117）

# A 组 6 变体格：[楼层, 灾祸, 施加期望, 还原期望, 主题 rule 字面量]（frail 的还原期望是 max_hp）
const _CT_VARIANTS := [
	[4, "frail", 1.0, 10.0, "vein"],      # vein×frail: cut 1（0.10）——轻
	[7, "frail", 4.0, 10.0, "silent"],    # silent×frail: cut 4（0.40）——重
	[8, "scarce_ammo", 0.7, 1.0, "magma"],   # magma×弹药荒: 0.7——轻
	[11, "scarce_ammo", 0.65, 1.0, "vines"], # vines×弹药荒: 0.65——轻
	[10, "frenzy", 1.45, 1.0, "swamp"],   # swamp×狂乱: 1.45——重
	[9, "frenzy", 1.4, 1.0, "ice"],       # ice×狂乱: 1.40——重
]

# B 组 2 时变格（走 _theme_damage_tick 公共路径，5 段验）：[楼层, 灾祸]
const _CT_TICK_CELLS := [
	[5, "scarce_ammo"],   # toxic×弹药荒: 0.5→0.4→0.3（每毒 tick −0.1，下限 0.3）——重
	[8, "scarce_ore"],    # magma×残响枯竭: 0.7→…→0.5（每火 tick −0.05，下限 0.5）——重
]

var _ct_checked := 0

# ---- S31：灾祸文案快照差分探针块（独立计数，不动既有 117 的 done 线）----
## 判红双门：打印带 ok= 且 Dev.check→[ERR]（团队口径 ok=false 与 QA 口径 [ERR] 同时可判）。
## 差分一律在「施加后制造 live 漂移 + 刷层签」之后取值（live==施加值时读＝现行错实现也绿＝假绿）。
const _S31_DECLARED := 12
var _s31_checked := 0


func _s31_assert(ok: bool, nn: String, measured, expect) -> void:
	_s31_checked += 1
	var m := str(measured)
	var e := str(expect)
	Dev.check(ok, "cal_theme_s31", "%s | measured=%s expect=%s" % [nn, m, e])
	print("[SMOKE-CAL-THEME-S31] #%02d %s measured=%s expect=%s ok=%s" % [_s31_checked, nn, m, e, str(ok)])


func _ct_assert(ok: bool, nn_name: String, measured, expect) -> void:
	_ct_checked += 1
	var m := str(measured)
	var e := str(expect)
	Dev.check(ok, "cal_theme", "%s | measured=%s expect=%s" % [nn_name, m, e])
	print("[SMOKE-CAL-THEME] #%02d %s measured=%s expect=%s" % [_ct_checked, nn_name, m, e])


func _ct_reset_channels() -> void:
	# 同帧差额对照的公共基线（实施单 §5.2）：四通道手工拉平，防多格间泄漏（player.gd:746 同源教训）
	player.max_hp = 10
	player.hp = 10
	player.mag_cap_mult = 1.0
	diamond_mult = 1.0
	Game.calamity_speed_mult = 1.0


func _ct_channel(id: String) -> float:
	match id:
		"frail": return float(_calamity_frail_cut)
		"frenzy": return Game.calamity_speed_mult
		"scarce_ammo": return player.mag_cap_mult
		"scarce_ore": return diamond_mult
	return -1.0


func _ct_cleared_value(id: String) -> float:
	# 还原后的读数：frail 看 max_hp（差值增量还原），其余看通道本值
	if id == "frail":
		return float(player.max_hp)
	return _ct_channel(id)


func _ct_baseline_pair(id: String) -> Array:
	# 无主题层基线 [施加期望, 还原期望]（max_hp=10 构造下 frail cut=2 / 还原 10）
	match id:
		"frail": return [2.0, 10.0]
		"frenzy": return [1.25, 1.0]
		"scarce_ammo": return [0.5, 1.0]
		"scarce_ore": return [0.7, 1.0]
	return [-1.0, -1.0]


func _ct_floor_advance(nf: int) -> void:
	# 复刻 next_floor 生产顺序前三步（:1505-1507）：floor 自增 → clear（此时 _calamity 仍为旧值，
	# ⑤9 断言点）；调用方负责随后 _calamity = "" + _apply_floor_theme()（对齐 :1508-1509）。
	# 禁用真实 next_floor()：会触发转场/进房/地图生成。
	Game.floor_num = nf
	_clear_calamity_effects()


## S27 批三 ⑬：同一 slug 上 csm 1.0 → 1.25 两次驱动，返回 [v0, v1]（velocity 模长）。
## 调用方保证 setup/环境就绪；碰撞层已清零，move_and_slide 不改 velocity。
func _ct_c2_pair(s: Slug, home: Vector2) -> Array:
	Game.calamity_speed_mult = 1.0
	s.global_position = home
	s._knock = Vector2.ZERO
	s._physics_process(Game.FIXED_DT)
	var v0: float = s.velocity.length()
	Game.calamity_speed_mult = 1.25
	s.global_position = home
	s._knock = Vector2.ZERO
	s._physics_process(Game.FIXED_DT)
	var v1: float = s.velocity.length()
	Game.calamity_speed_mult = 1.0
	return [v0, v1]


## S27 批三 ⑭：csm 恒 1.0，Game.enemy_speed_mult 1.0 → 1.25 两次驱动，返回 [w0, w1]。
## 🔴 必须写 Game（game_state）的 enemy_speed_mult——移动表达式读的是它（game_state:63，
## 减速 tween 通道）；game_main 的同名成员只在 slug setup 烘焙时被读，写它比值不动（⑭ 首跑实证）。
## speed 在 setup() 时已烘焙，live 改 esm 不改 speed——比值只有显式一项贡献。
func _ct_c2_esm_pair(s: Slug, home: Vector2) -> Array:
	Game.enemy_speed_mult = 1.0
	s.global_position = home
	s._knock = Vector2.ZERO
	s._physics_process(Game.FIXED_DT)
	var w0: float = s.velocity.length()
	Game.enemy_speed_mult = 1.25
	s.global_position = home
	s._knock = Vector2.ZERO
	s._physics_process(Game.FIXED_DT)
	var w1: float = s.velocity.length()
	return [w0, w1]


func _smoke_cal_theme_probe() -> void:
	print("[SMOKE-CAL-THEME] entry floor=%d calamity=%s" % [Game.floor_num, _calamity])
	# 现场快照（出口统一还原——多探针并发污染防线，player.gd:746 实证做法）
	var save_floor := Game.floor_num
	var save_calamity := _calamity
	var save_theme_rule := _theme_rule
	var save_dm := diamond_mult
	var save_esm := enemy_speed_mult
	var save_mod_es := _mod_enemy_speed_mult   # S27 批三：出口从快照还原 _mod_*（不许还原成 1.0——那会污染本局真实 modifier）
	var save_mod_d := _mod_diamond_mult
	var save_frail_ratio := _calamity_frail_ratio   # S28 批二：G/H 组用（出口逐项还原）
	var save_frail_cut: int = _calamity_frail_cut
	var save_saved_dm := _calamity_saved_diamond_mult
	var real_mod_es := _mod_enemy_speed_mult   # ⑨ 用：真实调用点接线值（④/⑥4 归一会改字段，故入口先存）
	var real_mod_d := _mod_diamond_mult
	var save_csm: float = Game.calamity_speed_mult
	var save_mc: float = player.mag_cap_mult
	var save_mhp: int = player.max_hp
	var save_hp: int = player.hp
	var save_tam: float = player.terrain_accel_mult
	var save_tsm: float = player.terrain_speed_mult
	var rng_state0: int = Game.rng.state
	_ct_checked = 0

	# ---- ① 基线通道（4）：无主题层（floor 1）四灾祸的基线值 ----
	for id in ["frail", "frenzy", "scarce_ammo", "scarce_ore"]:
		_ct_reset_channels()
		_calamity = id
		_apply_calamity()
		var bp := _ct_baseline_pair(id)
		_ct_assert(is_equal_approx(_ct_channel(id), float(bp[0])), "①%s 基线通道值" % id, _ct_channel(id), bp[0])
		_clear_calamity_effects()
		_calamity = ""

	# ---- ② 三段式·基线（12）：floor 2→3，每灾祸 段1 施加 / 段2 换层还原 / 段3 再施加幂等 ----
	for id in ["frail", "frenzy", "scarce_ammo", "scarce_ore"]:
		var bp2 := _ct_baseline_pair(id)
		_ct_reset_channels()
		Game.floor_num = 2
		_calamity = id
		_apply_calamity()
		_ct_assert(is_equal_approx(_ct_channel(id), float(bp2[0])), "②%s 段1 施加=基线" % id, _ct_channel(id), bp2[0])
		_ct_floor_advance(3)
		# S27 批三：读数前移到主题重建之前（⑮ 同型）——C1 后 _apply_floor_theme 会把 diamond
		# 回落到 _mod_*，段2 若读重建后的值就变成「验复位不验还原」，barren/swarm 局红在正确实现上
		_ct_assert(is_equal_approx(_ct_cleared_value(id), float(bp2[1])), "②%s 段2 换层还原" % id, _ct_cleared_value(id), bp2[1])
		_calamity = ""
		_apply_floor_theme()
		Game.floor_num = 2
		_calamity = id
		_apply_calamity()
		_ct_assert(is_equal_approx(_ct_channel(id), float(bp2[0])), "②%s 段3 再施加幂等" % id, _ct_channel(id), bp2[0])
		_clear_calamity_effects()
		_calamity = ""

	# ---- ③ 三段式·变体（A 18 = 6 格×3 段；B 组另 10 = 2 时变格×5 段，见下方 ③B 段）----
	# 段2 的换层增量必须让 rule 真的改变（4→5 / 7→8 / 8→9 / 10→11 / 11→12）；🔴 禁用 4→12（回卷后 rule 相同，写错也能蒙过）
	for v in _CT_VARIANTS:
		var f3 := int(v[0])
		var id3 := String(v[1])
		_ct_reset_channels()
		Game.floor_num = f3
		_calamity = id3
		_apply_calamity()
		_ct_assert(is_equal_approx(_ct_channel(id3), float(v[2])), "③f%d×%s 段1 施加=变体" % [f3, id3], _ct_channel(id3), v[2])
		_ct_floor_advance(f3 + 1)
		_calamity = ""
		_apply_floor_theme()
		_ct_assert(is_equal_approx(_ct_cleared_value(id3), float(v[3])), "③f%d×%s 段2 换层还原" % [f3, id3], _ct_cleared_value(id3), v[3])
		Game.floor_num = f3
		_calamity = id3
		_apply_calamity()
		_ct_assert(is_equal_approx(_ct_channel(id3), float(v[2])), "③f%d×%s 段3 再施加幂等" % [f3, id3], _ct_channel(id3), v[2])
		_clear_calamity_effects()
		_calamity = ""

	# ---- ④ 覆盖补全（9）：换层时序 4 + 幂等 4 + 零分支扫描 1 ----
	# S27 批三 §4 段级归一：④ 段读 diamond 的地方（④a ore / ④c 13 号格）落在无 pressure 分支层或
	# 依赖 saved，先显式把 _mod_* 归一到 1.0（出口统一从入口快照还原，不污染本局真实 modifier）
	_mod_enemy_speed_mult = 1.0
	_mod_diamond_mult = 1.0
	# ④a 换层时序（4）：各灾祸经换层构造后通道精确还原
	_ct_reset_channels()
	Game.floor_num = 5
	_calamity = "frail"
	_apply_calamity()
	_ct_floor_advance(6)
	_calamity = ""
	_apply_floor_theme()
	_ct_assert(is_equal_approx(player.max_hp, 10.0), "④换层时序 frail: max_hp 还原", player.max_hp, 10.0)
	_ct_reset_channels()
	Game.floor_num = 5
	_calamity = "scarce_ammo"
	_apply_calamity()
	_ct_floor_advance(6)
	_calamity = ""
	_apply_floor_theme()
	_ct_assert(is_equal_approx(player.mag_cap_mult, 1.0), "④换层时序 ammo: mag_cap 还原", player.mag_cap_mult, 1.0)
	_ct_reset_channels()
	Game.floor_num = 6
	_apply_floor_theme()   # 真实路径：pressure 把 diamond_mult 拉到 1.5
	_calamity = "scarce_ore"
	_apply_calamity()
	_ct_floor_advance(7)
	# ⑮1 真值前移：clear 刚跑完、主题还没重建——此刻 diamond 必须是 1.5（变异 D 唯一可观测点；
	# 主题重建后读数被 C1 复位掩蔽，见实施单首批必读 #2）
	_ct_assert(is_equal_approx(diamond_mult, 1.5), "⑮1 ④ore 换层 clear 后、主题重建前 diamond==1.5", diamond_mult, 1.5)
	_calamity = ""
	_apply_floor_theme()
	_ct_assert(is_equal_approx(diamond_mult, 1.0), "④换层时序 ore@pressure: 主题重建后回落 _mod_*（段级归一 1.0）", diamond_mult, 1.0)
	_ct_reset_channels()
	Game.floor_num = 5
	_calamity = "frenzy"
	_apply_calamity()
	_ct_floor_advance(6)
	_calamity = ""
	_apply_floor_theme()
	_ct_assert(is_equal_approx(Game.calamity_speed_mult, 1.0), "④换层时序 frenzy: 敌速还原", Game.calamity_speed_mult, 1.0)
	# ④b 幂等（4）：清后再施加同值
	_ct_reset_channels()
	Game.floor_num = 5
	_calamity = "frail"
	_apply_calamity()
	var idem_f := float(_calamity_frail_cut)
	_clear_calamity_effects()
	_calamity = ""
	Game.floor_num = 5
	_calamity = "frail"
	_apply_calamity()
	_ct_assert(is_equal_approx(float(_calamity_frail_cut), idem_f), "④幂等 frail: 清后再施加同值", _calamity_frail_cut, idem_f)
	_clear_calamity_effects()
	_calamity = ""
	_ct_reset_channels()
	Game.floor_num = 5
	_calamity = "frenzy"
	_apply_calamity()
	var idem_fr := Game.calamity_speed_mult
	_clear_calamity_effects()
	_calamity = ""
	Game.floor_num = 5
	_calamity = "frenzy"
	_apply_calamity()
	_ct_assert(is_equal_approx(Game.calamity_speed_mult, idem_fr), "④幂等 frenzy: 清后再施加同值", Game.calamity_speed_mult, idem_fr)
	_clear_calamity_effects()
	_calamity = ""
	_ct_reset_channels()
	Game.floor_num = 5
	_calamity = "scarce_ammo"
	_apply_calamity()
	var idem_am: float = player.mag_cap_mult
	_clear_calamity_effects()
	_calamity = ""
	Game.floor_num = 5
	_calamity = "scarce_ammo"
	_apply_calamity()
	_ct_assert(is_equal_approx(player.mag_cap_mult, idem_am), "④幂等 ammo: 清后再施加同值", player.mag_cap_mult, idem_am)
	_clear_calamity_effects()
	_calamity = ""
	_ct_reset_channels()
	Game.floor_num = 5
	_calamity = "scarce_ore"
	_apply_calamity()
	var idem_or := diamond_mult
	_clear_calamity_effects()
	_calamity = ""
	Game.floor_num = 5
	_calamity = "scarce_ore"
	_apply_calamity()
	_ct_assert(is_equal_approx(diamond_mult, idem_or), "④幂等 ore: 清后再施加同值", diamond_mult, idem_or)
	_clear_calamity_effects()
	_calamity = ""
	# ④c 零分支扫描（B 阶段 24 格）：32 格 − 8 变体格（A 6 常数 + B 2 时变）。
	# 其中 13 号格（pressure×scarce_ore）走真实路径 1.5→0.7→1.5，其余 23 格基线字面量。
	# 🔴 扫描行用 scan 前缀分流，禁用 #NN（否则污染 checked==declared 自校验，门控永久假绿）
	var scan_bad: Array[String] = []
	var scan_i := 0
	for f in range(4, 12):
		for id in ["frail", "frenzy", "scarce_ammo", "scarce_ore"]:
			var is_variant := false
			for v in _CT_VARIANTS:
				if int(v[0]) == f and String(v[1]) == id:
					is_variant = true
					break
			for t in _CT_TICK_CELLS:
				if int(t[0]) == f and String(t[1]) == id:
					is_variant = true
					break
			if is_variant:
				continue
			scan_i += 1
			_ct_reset_channels()
			Game.floor_num = f   # 每格落位：快照与 13 号格真实路径都以本格楼层为准（漏设会全部落在残留楼层上）
			var ap_exp := float(_ct_baseline_pair(id)[0])
			var cl_exp := float(_ct_baseline_pair(id)[1])
			var special: bool = f == 6 and id == "scarce_ore"
			if special:
				_apply_floor_theme()   # 真实路径：pressure 把 diamond_mult 拉到 1.5
				ap_exp = 0.7
				cl_exp = 1.5
			_calamity = id
			_apply_calamity()
			var ap := _ct_channel(id)
			_clear_calamity_effects()
			var cl := _ct_cleared_value(id)
			_calamity = ""
			if not (is_equal_approx(ap, ap_exp) and is_equal_approx(cl, cl_exp)):
				scan_bad.append("f%d×%s(ap=%s,cl=%s)" % [f, id, ap, cl])
			print("[SMOKE-CAL-THEME] scan i=%d cell=f%d×%s applied=%s cleared=%s" % [scan_i, f, id, ap, cl])
	_ct_assert(scan_bad.is_empty(), "④c 零分支扫描 %d 格（26 含 13 号格）" % scan_i, scan_bad, "0 违例")

	# ---- ⑤ 旁证（13）----
	# ⑤1 无主题层（floor 3）四灾祸施加==基线
	var n5_bad: Array[String] = []
	for id in ["frail", "frenzy", "scarce_ammo", "scarce_ore"]:
		_ct_reset_channels()
		Game.floor_num = 3
		_calamity = id
		_apply_calamity()
		if not is_equal_approx(_ct_channel(id), float(_ct_baseline_pair(id)[0])):
			n5_bad.append("%s=%s" % [id, _ct_channel(id)])
		_clear_calamity_effects()
		_calamity = ""
	_ct_assert(n5_bad.is_empty(), "⑤1 无主题层(f3)四灾祸施加==基线", n5_bad, "0 违例")
	# ⑤2 空灾祸 clear 完全不碰倍率（复验 player.gd:753-761 层流程①）
	_ct_reset_channels()
	diamond_mult = 1.5
	player.mag_cap_mult = 1.7
	_calamity = ""
	_clear_calamity_effects()
	_ct_assert(is_equal_approx(diamond_mult, 1.5) and is_equal_approx(player.mag_cap_mult, 1.7),
		"⑤2 空灾祸 clear 不碰倍率", "%s/%s" % [diamond_mult, player.mag_cap_mult], "1.5/1.7")
	_ct_reset_channels()
	# ⑤3 差额正：scarce_ammo 在 magma 实测 0.70 ≠ ice 0.50（🔴 不许用 scarce_ore——apply 瞬间两格同为 0.7）
	_ct_reset_channels()
	Game.floor_num = 8
	_calamity = "scarce_ammo"
	_apply_calamity()
	var v_magma: float = player.mag_cap_mult
	_clear_calamity_effects()
	_calamity = ""
	_ct_reset_channels()
	Game.floor_num = 10
	_calamity = "scarce_ammo"
	_apply_calamity()
	var v_ice: float = player.mag_cap_mult
	_clear_calamity_effects()
	_calamity = ""
	_ct_assert(is_equal_approx(v_magma, 0.7) and is_equal_approx(v_ice, 0.5) and not is_equal_approx(v_magma, v_ice),
		"⑤3 差额正: magma 0.70 ≠ ice 0.50（唯一直接复合证据）", "%s/%s" % [v_magma, v_ice], "0.7/0.5 且不等")
	# ⑤4 差额反：同主题不同通道互不越界
	_ct_reset_channels()
	Game.floor_num = 8
	_calamity = "frail"
	_apply_calamity()
	var frail_side := _calamity_frail_cut == 2 and is_equal_approx(Game.calamity_speed_mult, 1.0)
	_clear_calamity_effects()
	_calamity = ""
	_ct_reset_channels()
	Game.floor_num = 8
	_calamity = "frenzy"
	_apply_calamity()
	var frenzy_side: bool = is_equal_approx(Game.calamity_speed_mult, 1.25) and player.max_hp == 10
	_clear_calamity_effects()
	_calamity = ""
	_ct_assert(frail_side and frenzy_side, "⑤4 差额反: magma 上 frail/frenzy 通道互不越界", "%s/%s" % [frail_side, frenzy_side], "true/true")
	# ⑤5 探针窗口 Game.rng.state 不变（零抽取自证）
	_ct_assert(Game.rng.state == rng_state0, "⑤5 探针窗口 rng.state 不变", Game.rng.state, rng_state0)
	# ⑤6 FLOOR_THEMES 表长（⚠️ 常量自比较——护表长不被误改，不构成行为证据）
	_ct_assert(Data.FLOOR_THEMES.size() == 8, "⑤6 FLOOR_THEMES.size()==8（常量自比较）", Data.FLOOR_THEMES.size(), 8)
	# ⑤7 层签含变体实值（楼层对照写死：f4 vein=-10% / f7 silent=-40%；magma×frail 不是变体，别当靶子）
	var sign_bad: Array[String] = []
	_ct_reset_channels()
	Game.floor_num = 4
	_calamity = "frail"
	_apply_calamity()
	update_floor_sign()
	var s4 := String(hud._floor_sign_label.text)
	if not s4.contains("虚弱（生命上限 -10%）"):
		sign_bad.append("f4: " + s4)
	_ct_reset_channels()
	Game.floor_num = 7
	_calamity = "frail"
	_apply_calamity()
	update_floor_sign()
	var s7 := String(hud._floor_sign_label.text)
	if not s7.contains("虚弱（生命上限 -40%）"):
		sign_bad.append("f7: " + s7)
	_clear_calamity_effects()
	_calamity = ""
	update_floor_sign()
	_ct_assert(sign_bad.is_empty(), "⑤7 层签含变体实值（f4=-10%/f7=-40%）", sign_bad, "0 违例")
	# ⑤8 _calamity_name 四 id 均不返回原始 id
	var nm_bad: Array[String] = []
	for id in ["frail", "frenzy", "scarce_ammo", "scarce_ore"]:
		if String(_calamity_name(id)) == id:
			nm_bad.append(id)
	_ct_assert(nm_bad.is_empty(), "⑤8 _calamity_name 不返回原始 id", nm_bad, "0 违例")
	# ⑤9 换层构造：clear 时 _calamity 仍为旧值（next_floor :1507 早于 :1508）
	_ct_reset_channels()
	Game.floor_num = 5
	_calamity = "scarce_ammo"
	_apply_calamity()
	_ct_floor_advance(6)
	_ct_assert(_calamity == "scarce_ammo", "⑤9 换层 clear 时 _calamity 仍为旧值", _calamity, "scarce_ammo")
	_calamity = ""
	_apply_floor_theme()
	# ⑤10 净化路径：clear 时 _calamity 仍为旧值（:2224 早于 :2225），且已还原
	_ct_reset_channels()
	Game.floor_num = 5
	_calamity = "scarce_ore"
	_apply_calamity()
	_clear_calamity_effects()
	var purify_still := _calamity
	var purify_dm := diamond_mult
	_calamity = ""
	_ct_assert(purify_still == "scarce_ore" and is_equal_approx(purify_dm, 1.0),
		"⑤10 净化 clear 时 _calamity 仍为旧值且已还原", "%s/%s" % [purify_still, purify_dm], "scarce_ore/1.0")
	# ⑤11-13 前提守卫（🔴 恒过型，仅证明探针环境成立，不计入行为覆盖）
	_ct_assert(is_instance_valid(player), "⑤11 前提守卫: player 有效（恒过型）", is_instance_valid(player), true)
	_ct_assert(dungeon != null, "⑤12 前提守卫: dungeon 非空（恒过型）", dungeon != null, true)
	_ct_assert(_smoke, "⑤13 前提守卫: _smoke 已开（恒过型）", _smoke, true)

	# ---- ⑥ 快照纪律（6）：结构 4（只验标志）+ 行为 2 ----
	# ⑥1 施加后快照==目标层 rule 字面量（6 变体格聚合；字面量取自 _CT_VARIANTS 第 5 列）
	var rule_bad: Array[String] = []
	for v in _CT_VARIANTS:
		var f6 := int(v[0])
		var id6 := String(v[1])
		_ct_reset_channels()
		Game.floor_num = f6
		_calamity = id6
		_apply_calamity()
		if _calamity_theme_rule != String(v[4]):
			rule_bad.append("f%d×%s got=%s want=%s" % [f6, id6, _calamity_theme_rule, v[4]])
		_clear_calamity_effects()
		_calamity = ""
	_ct_assert(rule_bad.is_empty(), "⑥1 施加后快照==目标层 rule（只验标志）", rule_bad, "0 违例")
	# ⑥2 + ⑥4 共用 6→7 真实路径构造（pressure → scarce_ore → 换层）
	# S27 批三 §4 段级归一：⑥4 段读 diamond 落在第 7 层复位值，先归一 _mod_*（互不依赖 ④ 段）
	_mod_enemy_speed_mult = 1.0
	_mod_diamond_mult = 1.0
	_ct_reset_channels()
	Game.floor_num = 6
	_apply_floor_theme()
	_calamity = "scarce_ore"
	_apply_calamity()
	_ct_floor_advance(7)
	_ct_assert(_calamity_theme_rule == "", "⑥2 换层 clear 后快照清空（变异 D 正面靶子，只验标志）", _calamity_theme_rule, "空串")
	# ⑮2 真值前移：同 ⑮1——主题重建前 diamond 必为 1.5，重建后读数被 C1 复位掩蔽
	_ct_assert(is_equal_approx(diamond_mult, 1.5), "⑮2 ⑥4 换层 clear 后、主题重建前 diamond==1.5", diamond_mult, 1.5)
	_calamity = ""
	_apply_floor_theme()
	_ct_assert(is_equal_approx(diamond_mult, 1.0), "⑥4 6→7 主题重建后 diamond_mult 回落 _mod_*（段级归一 1.0）", diamond_mult, 1.0)
	# ⑥3 + ⑥5 共用净化路径构造（floor 6 pressure）
	_ct_reset_channels()
	Game.floor_num = 6
	_apply_floor_theme()
	_calamity = "scarce_ore"
	_apply_calamity()
	_clear_calamity_effects()
	_ct_assert(_calamity_theme_rule == "", "⑥3 净化 clear 后快照清空（只验标志）", _calamity_theme_rule, "空串")
	_ct_assert(is_equal_approx(diamond_mult, 1.5), "⑥5 净化路径 6 层 diamond_mult 精确还原==saved(1.5)", diamond_mult, 1.5)
	_calamity = ""
	# ⑥6 floor 12 回卷（主题派生 f12→key4→vein）：施加后快照==vein（变异 D′ 正面靶子，只验标志）；跑完必须还原 floor_num
	var save_floor_66 := Game.floor_num
	_ct_reset_channels()
	Game.floor_num = 12
	_calamity = "frail"
	_apply_calamity()
	_ct_assert(_calamity_theme_rule == "vein", "⑥6 f12 施加后快照==vein（回卷，只验标志）", _calamity_theme_rule, "vein")
	_clear_calamity_effects()
	_calamity = ""
	Game.floor_num = save_floor_66

	# ---- ⑦ 文案实值（4）：_calamity_name() 百分比与实测通道一致（族名首词逐字保留）----
	_ct_reset_channels()
	Game.floor_num = 7
	_calamity = "frail"
	_apply_calamity()
	var n7 := String(_calamity_name("frail"))
	_ct_assert(n7 == "虚弱（生命上限 -40%）" and _calamity_frail_cut == 4, "⑦frail 实值", "%s cut=%d" % [n7, _calamity_frail_cut], "-40% cut=4")
	_clear_calamity_effects()
	_calamity = ""
	_ct_reset_channels()
	Game.floor_num = 10
	_calamity = "frenzy"
	_apply_calamity()
	var n10 := String(_calamity_name("frenzy"))
	_ct_assert(n10 == "狂乱（敌人加速 45%）" and is_equal_approx(Game.calamity_speed_mult, 1.45), "⑦frenzy 实值", "%s speed=%s" % [n10, Game.calamity_speed_mult], "-45% speed=1.45")
	_clear_calamity_effects()
	_calamity = ""
	_ct_reset_channels()
	Game.floor_num = 8
	_calamity = "scarce_ammo"
	_apply_calamity()
	var n8 := String(_calamity_name("scarce_ammo"))
	_ct_assert(n8 == "弹药荒（弹匣 -30%）" and is_equal_approx(player.mag_cap_mult, 0.7), "⑦ammo 实值", "%s mag=%s" % [n8, player.mag_cap_mult], "-30% mag=0.7")
	_clear_calamity_effects()
	_calamity = ""
	_ct_reset_channels()
	Game.floor_num = 6
	_apply_floor_theme()   # 真实路径：pressure 1.5 → scarce_ore 0.7 → 相对承诺 −53%
	_calamity = "scarce_ore"
	_apply_calamity()
	var n6 := String(_calamity_name("scarce_ore"))
	_ct_assert(n6 == "残响枯竭（残响掉落 -53%）" and is_equal_approx(diamond_mult, 0.7), "⑦ore 实值@pressure", "%s dm=%s" % [n6, diamond_mult], "-53% dm=0.7")
	_clear_calamity_effects()
	_calamity = ""

	# ---- ③B B 组时变格（10）：2 格 × 5 段——施加 / 递减单调 / 下限钳制 / 换层还原 / 再施加 ----
	# tick 直调 _theme_damage_tick()；每次驱动前后存取 player.hp 再回填（§4.4：tick 会走 DoT/SMOKE 分支）
	# ③B#7 toxic×scarce_ammo：0.5→0.4→0.3（每毒 tick −0.1，下限 0.3）
	_ct_reset_channels()
	Game.floor_num = 5
	_apply_floor_theme()   # 真实路径：toxic 主题（_theme_rule="toxic"；terrain 改动由出口统一还原）
	var hp_keep: int = player.hp
	_calamity = "scarce_ammo"
	_apply_calamity()
	var ammo_apply: float = player.mag_cap_mult
	_ct_assert(is_equal_approx(ammo_apply, 0.5), "③B f5×ammo 段1 施加=0.5", ammo_apply, 0.5)
	_theme_damage_tick()
	var ammo_t1: float = player.mag_cap_mult
	player.hp = hp_keep
	_theme_damage_tick()
	var ammo_t2: float = player.mag_cap_mult
	player.hp = hp_keep
	_ct_assert(ammo_t1 < ammo_apply and ammo_t2 < ammo_t1 and is_equal_approx(ammo_t2, 0.3),
		"③B f5×ammo 段2 递减单调至 0.3", "%s→%s→%s" % [ammo_apply, ammo_t1, ammo_t2], "0.5→0.4→0.3")
	_theme_damage_tick()
	player.hp = hp_keep
	_theme_damage_tick()
	player.hp = hp_keep
	_ct_assert(is_equal_approx(player.mag_cap_mult, 0.3), "③B f5×ammo 段3 下限钳制", player.mag_cap_mult, 0.3)
	_ct_floor_advance(6)
	_calamity = ""
	_apply_floor_theme()
	_ct_assert(is_equal_approx(player.mag_cap_mult, 1.0), "③B f5×ammo 段4 换层还原=saved", player.mag_cap_mult, 1.0)
	Game.floor_num = 5
	_apply_floor_theme()
	_calamity = "scarce_ammo"
	_apply_calamity()
	_ct_assert(is_equal_approx(player.mag_cap_mult, 0.5), "③B f5×ammo 段5 再施加=初值", player.mag_cap_mult, 0.5)
	_clear_calamity_effects()
	_calamity = ""
	# ③B#8 magma×scarce_ore：0.7→0.65→…→0.5（每火 tick −0.05，下限 0.5）
	_ct_reset_channels()
	Game.floor_num = 8
	_apply_floor_theme()
	_calamity = "scarce_ore"
	_apply_calamity()
	var ore_apply: float = diamond_mult
	_ct_assert(is_equal_approx(ore_apply, 0.7), "③B f8×ore 段1 施加=0.7", ore_apply, 0.7)
	var ore_seq: Array = []
	for i in 4:
		_theme_damage_tick()
		player.hp = hp_keep
		ore_seq.append(diamond_mult)
	var ore_mono: bool = true
	for i in range(1, 4):
		if not ore_seq[i] < ore_seq[i - 1]:
			ore_mono = false
	_ct_assert(ore_mono and is_equal_approx(ore_seq[3], 0.5),
		"③B f8×ore 段2 递减单调至 0.5", "%s→%s→%s→%s" % [ore_apply, ore_seq[0], ore_seq[1], ore_seq[3]], "0.7→…→0.5")
	_theme_damage_tick()
	player.hp = hp_keep
	_theme_damage_tick()
	player.hp = hp_keep
	_ct_assert(is_equal_approx(diamond_mult, 0.5), "③B f8×ore 段3 下限钳制", diamond_mult, 0.5)
	_ct_floor_advance(9)
	_calamity = ""
	_apply_floor_theme()
	_ct_assert(is_equal_approx(diamond_mult, 1.0), "③B f8×ore 段4 换层还原=saved", diamond_mult, 1.0)
	Game.floor_num = 8
	_apply_floor_theme()
	_calamity = "scarce_ore"
	_apply_calamity()
	_ct_assert(is_equal_approx(diamond_mult, 0.7), "③B f8×ore 段5 再施加=初值", diamond_mult, 0.7)
	_clear_calamity_effects()
	_calamity = ""

	# ---- ⑧ 离压回落（8）：_mod_*=1.0 → pressure 顶到 1.3/1.5 → 各目标层回落（每条双值 and 链）----
	_mod_enemy_speed_mult = 1.0
	_mod_diamond_mult = 1.0
	for f in [4, 5, 6, 7, 8, 9, 10, 11]:
		_ct_reset_channels()
		Game.floor_num = 6
		_apply_floor_theme()
		Game.floor_num = int(f)
		_apply_floor_theme()
		var we8: float = 1.3 if int(f) == 6 else 1.0
		var wd8: float = 1.5 if int(f) == 6 else 1.0
		_ct_assert(is_equal_approx(enemy_speed_mult, we8) and is_equal_approx(diamond_mult, wd8),
			"⑧f%d 离压回落（双值）" % int(f),
			"(es=%s, dm=%s)" % [enemy_speed_mult, diamond_mult], "(es=%s, dm=%s)" % [we8, wd8])
	# ---- ⑨ _mod_* 接线巡检（1，只验标志）：真实调用点有没有把返回值接上（映射对错归 ⑯ 管）----
	# 用入口快照值：④/⑥4 段级归一已改写字段，只有入口值还代表真实 start_run 的接线结果
	var og_table := {"rage": Vector2(1.25, 1.0), "barren": Vector2(1.0, 0.7),
		"swarm": Vector2(1.0, 1.5), "none": Vector2(1.0, 1.0),
		"overload": Vector2(1.0, 1.0), "glass": Vector2(1.0, 1.0)}
	var want_pair: Vector2 = og_table.get(modifier, Vector2(1.0, 1.0))
	_ct_assert(is_equal_approx(real_mod_es, want_pair.x) and is_equal_approx(real_mod_d, want_pair.y),
		"⑨ 接线巡检（只验标志，⑨绿不代表映射表对）",
		"m=%s got=(%s,%s)" % [modifier, real_mod_es, real_mod_d],
		"%s→(%s,%s)" % [modifier, want_pair.x, want_pair.y])
	# ---- ⑩ modifier × pressure（3，🔴 maxf 掩蔽：只对「maxf 改乘法」这一种错误有效，有效覆盖按 0 计 ----
	_mod_enemy_speed_mult = 1.25
	Game.floor_num = 6
	_apply_floor_theme()
	_ct_assert(is_equal_approx(enemy_speed_mult, 1.3), "⑩a rage×pressure（maxf 掩蔽组）", enemy_speed_mult, 1.3)
	_mod_diamond_mult = 0.7
	Game.floor_num = 6
	_apply_floor_theme()
	_ct_assert(is_equal_approx(diamond_mult, 1.5), "⑩b barren×pressure（maxf 掩蔽组）", diamond_mult, 1.5)
	_mod_diamond_mult = 1.5
	Game.floor_num = 6
	_apply_floor_theme()
	_ct_assert(is_equal_approx(diamond_mult, 1.5), "⑩c swarm×pressure（maxf 掩蔽组）", diamond_mult, 1.5)
	# ---- ⑪ modifier × 非压力层（3，C1 正面靶子：压力层上 maxf 会吃掉差异，必须选第 7 层 silent）----
	_mod_enemy_speed_mult = 1.25
	Game.floor_num = 7
	_apply_floor_theme()
	_ct_assert(is_equal_approx(enemy_speed_mult, 1.25), "⑪a rage@第7层（C1 正面靶子）", enemy_speed_mult, 1.25)
	_mod_diamond_mult = 0.7
	Game.floor_num = 7
	_apply_floor_theme()
	_ct_assert(is_equal_approx(diamond_mult, 0.7), "⑪b barren@第7层（C1 正面靶子）", diamond_mult, 0.7)
	_mod_diamond_mult = 1.5
	Game.floor_num = 7
	_apply_floor_theme()
	_ct_assert(is_equal_approx(diamond_mult, 1.5), "⑪c swarm@第7层（C1 正面靶子）", diamond_mult, 1.5)
	# ---- ⑫ 无主题层早退（1）：复位在早退分支之前，1–3 层也必须回落（专打「复位写在早退后」错法）----
	_mod_enemy_speed_mult = 1.25
	_mod_diamond_mult = 0.7
	Game.floor_num = 6
	_apply_floor_theme()
	Game.floor_num = 3
	_apply_floor_theme()
	_ct_assert(is_equal_approx(enemy_speed_mult, 1.25) and is_equal_approx(diamond_mult, 0.7),
		"⑫ 无主题层（f3）回落到 _mod_*（双值）",
		"(es=%s, dm=%s)" % [enemy_speed_mult, diamond_mult], "(es=1.25, dm=0.7)")
	# ---- ⑬ C2 四路径（4）+ ⑭ 零回归（1）：真 Slug 实例驱动 _physics_process，比值判定 ----
	# 🔴 v0==0 必红（fold 进比值 and 链——v0=0 说明探针未造出目标，静默跳过=最典型假绿写法）
	var s13 := Slug.new()
	entities.add_child(s13)
	var bomb13 := Node2D.new()
	bomb13.add_to_group("bombs")
	entities.add_child(bomb13)
	var trail_keep: Array[Vector2] = player.trail.duplicate()
	s13.collision_layer = 0   # 探针驱动 move_and_slide 不与房间实体碰撞——velocity 读数才可做比值
	s13.collision_mask = 0
	var pos13: Vector2 = Game.main.clamp_to_arena(player.global_position + Vector2(220, 0))
	Game.calamity_speed_mult = 1.0
	# ⑬1 defuser 冲向炸弹（真 bomb 在 240 内、>18px 不触发 defuse）
	s13.setup("rusher", 1, 8)
	s13.defuser = true
	bomb13.global_position = Game.main.clamp_to_arena(player.global_position + Vector2(100, 0))
	var pa13 := _ct_c2_pair(s13, pos13)
	_ct_assert(float(pa13[0]) > 0.0 and is_equal_approx(float(pa13[1]) / float(pa13[0]), 1.25),
		"⑬1 defuser 冲炸弹 csm 比值 1.25（v0=0=探针未造出目标）",
		"ratio=%.4f v0=%s" % [float(pa13[1]) / maxf(float(pa13[0]), 0.0001), pa13[0]], "1.2500 且 v0>0")
	# ⑬2 echo 追痕迹（mirror 段，trail 远点保证 limit_length 封顶）
	s13.setup("echo", 1, 8)
	s13.defuser = false
	player.trail.append(player.global_position + Vector2(5000, 0))
	s13._echo_t = 0.0
	var pb13 := _ct_c2_pair(s13, pos13)
	_ct_assert(float(pb13[0]) > 0.0 and is_equal_approx(float(pb13[1]) / float(pb13[0]), 1.25),
		"⑬2 echo 追痕迹 csm 比值 1.25（v0=0=探针未造出目标）",
		"ratio=%.4f v0=%s" % [float(pb13[1]) / maxf(float(pb13[0]), 0.0001), pb13[0]], "1.2500 且 v0>0")
	# ⑬3 echo 游走-爬行（_echo_t=3.0 → 过镜像段 → creep_mult）
	s13.setup("echo", 1, 8)
	s13.defuser = false
	s13._echo_t = 3.0
	var pc13 := _ct_c2_pair(s13, pos13)
	_ct_assert(float(pc13[0]) > 0.0 and is_equal_approx(float(pc13[1]) / float(pc13[0]), 1.25),
		"⑬3 echo 游走-爬行 csm 比值 1.25（v0=0=探针未造出目标）",
		"ratio=%.4f v0=%s" % [float(pc13[1]) / maxf(float(pc13[0]), 0.0001), pc13[0]], "1.2500 且 v0>0")
	# ⑬4 echo 游走-突进（_echo_t=2.9 → cycle>2.5 → dash_mult）
	s13.setup("echo", 1, 8)
	s13.defuser = false
	s13._echo_t = 2.9
	var pd13 := _ct_c2_pair(s13, pos13)
	_ct_assert(float(pd13[0]) > 0.0 and is_equal_approx(float(pd13[1]) / float(pd13[0]), 1.25),
		"⑬4 echo 游走-突进 csm 比值 1.25（v0=0=探针未造出目标）",
		"ratio=%.4f v0=%s" % [float(pd13[1]) / maxf(float(pd13[0]), 0.0001), pd13[0]], "1.2500 且 v0>0")
	player.trail.resize(trail_keep.size())
	# ⑭ 零回归（聚合）：csm 恒 1.0，Game.enemy_speed_mult 1.0→1.25，四路径读数各 ×1.25（补乘子没碰坏既有因子）
	Game.calamity_speed_mult = 1.0
	var es14: float = Game.enemy_speed_mult
	var bad14: Array[String] = []
	s13.setup("rusher", 1, 8)
	s13.defuser = true
	bomb13.global_position = Game.main.clamp_to_arena(player.global_position + Vector2(100, 0))
	var w14a := _ct_c2_esm_pair(s13, pos13)
	if not (float(w14a[0]) > 0.0 and is_equal_approx(float(w14a[1]) / float(w14a[0]), 1.25)):
		bad14.append("defuser")
	s13.setup("echo", 1, 8)
	s13.defuser = false
	player.trail.append(player.global_position + Vector2(5000, 0))
	s13._echo_t = 0.0
	var w14b := _ct_c2_esm_pair(s13, pos13)
	if not (float(w14b[0]) > 0.0 and is_equal_approx(float(w14b[1]) / float(w14b[0]), 1.25)):
		bad14.append("echo-chase")
	s13.setup("echo", 1, 8)
	s13.defuser = false
	s13._echo_t = 3.0
	var w14c := _ct_c2_esm_pair(s13, pos13)
	if not (float(w14c[0]) > 0.0 and is_equal_approx(float(w14c[1]) / float(w14c[0]), 1.25)):
		bad14.append("echo-creep")
	s13.setup("echo", 1, 8)
	s13.defuser = false
	s13._echo_t = 2.9
	var w14d := _ct_c2_esm_pair(s13, pos13)
	if not (float(w14d[0]) > 0.0 and is_equal_approx(float(w14d[1]) / float(w14d[0]), 1.25)):
		bad14.append("echo-dash")
	player.trail.resize(trail_keep.size())
	Game.enemy_speed_mult = es14
	Game.calamity_speed_mult = save_csm
	_ct_assert(bad14.is_empty(), "⑭ esm 切换四路径比值 1.25（聚合零回归）", bad14, "0 违例")
	s13.queue_free()
	bomb13.queue_free()
	# ---- ⑯ 映射与接线覆盖（4）：直调 _apply_modifier_mult 后同链断 live+_mod_* 四值 ----
	_apply_modifier_mult("rage")
	_ct_assert(is_equal_approx(enemy_speed_mult, 1.25) and is_equal_approx(diamond_mult, 1.0)
		and is_equal_approx(_mod_enemy_speed_mult, 1.25) and is_equal_approx(_mod_diamond_mult, 1.0),
		"⑯1 rage 全四值", "(es=%s, dm=%s | mod=%s,%s)" % [enemy_speed_mult, diamond_mult, _mod_enemy_speed_mult, _mod_diamond_mult],
		"(1.25, 1.0 | 1.25,1.0)")
	_apply_modifier_mult("barren")
	_ct_assert(is_equal_approx(enemy_speed_mult, 1.0) and is_equal_approx(diamond_mult, 0.7)
		and is_equal_approx(_mod_enemy_speed_mult, 1.0) and is_equal_approx(_mod_diamond_mult, 0.7),
		"⑯2 barren 全四值", "(es=%s, dm=%s | mod=%s,%s)" % [enemy_speed_mult, diamond_mult, _mod_enemy_speed_mult, _mod_diamond_mult],
		"(1.0, 0.7 | 1.0,0.7)")
	_apply_modifier_mult("swarm")
	_ct_assert(is_equal_approx(enemy_speed_mult, 1.0) and is_equal_approx(diamond_mult, 1.5)
		and is_equal_approx(_mod_enemy_speed_mult, 1.0) and is_equal_approx(_mod_diamond_mult, 1.5),
		"⑯3 swarm 全四值", "(es=%s, dm=%s | mod=%s,%s)" % [enemy_speed_mult, diamond_mult, _mod_enemy_speed_mult, _mod_diamond_mult],
		"(1.0, 1.5 | 1.0,1.5)")
	var pair_bad := ""
	for m in ["none", "overload", "glass"]:
		_apply_modifier_mult(String(m))
		if not (is_equal_approx(enemy_speed_mult, 1.0) and is_equal_approx(diamond_mult, 1.0)
				and is_equal_approx(_mod_enemy_speed_mult, 1.0) and is_equal_approx(_mod_diamond_mult, 1.0)):
			pair_bad = String(m)
		print("[SMOKE-CAL-THEME] pair m=%s got=(%.2f,%.2f)" % [m, enemy_speed_mult, diamond_mult])
	_ct_assert(pair_bad == "", "⑯4 none/overload/glass 三档聚合（全四值）", pair_bad, "无违例")

	# ---- G 组（7，S28 批二）：第 12 层回卷真跑（G08=刀一变异，非运行期断言——口径 §1.3 明注）----
	# G01/G07 前提守卫（恒过，不构成覆盖）：只验 Data 函数返回值，直查表的错误实现照样绿
	_ct_assert(String(Data.theme_for_floor(12).get("rule", "")) == "vein", "G01 前提守卫（恒过）：theme_for_floor(12) 回卷 vein", Data.theme_for_floor(12).get("rule"), "vein")
	_ct_assert(String(Data.theme_for_floor(13).get("rule", "")) == String(Data.theme_for_floor(5).get("rule", "")),
		"G07 前提守卫（恒过）：f13 回卷 key5 与 f5 同 rule（模运算而非 12 特判）",
		"%s/%s" % [Data.theme_for_floor(13).get("rule"), Data.theme_for_floor(5).get("rule")], "相等")
	# 换层构造选择：11→12 推进（vines→vein，rule 真改变；省构造——12 的回卷结果才是靶心）
	Game.floor_num = 11
	_apply_floor_theme()
	_ct_reset_channels()
	var g_old_hp: int = player.max_hp
	var g_hp0: int = player.max_hp
	var g_mc0: float = player.mag_cap_mult
	var g_dm0: float = diamond_mult
	var g_cs0: float = Game.calamity_speed_mult
	Game.floor_num = 12
	_calamity = "frail"
	_apply_calamity()
	_ct_assert(_calamity_theme_rule == "vein", "G02 靶心：f12 施加后快照==vein（直查 FLOOR_THEMES.get(12) 的实现此处为空串）", _calamity_theme_rule, "vein")
	_ct_assert(is_equal_approx(_calamity_frail_ratio, 0.1), "G03 f12 frail 比例==vein 实值 0.1（实读 _frail_ratio vein 支）", _calamity_frail_ratio, 0.1)
	_ct_assert(float(g_old_hp - player.max_hp) == 1.0, "G04 f12 实际削减==1（10×0.1，maxi(1,…) 钳）", g_old_hp - player.max_hp, 1)
	_ct_floor_advance(13)
	_ct_assert(_calamity_theme_rule == "", "G05 f12→f13 clear 后快照清空（clear 里现查 f13 主题的错误实现此处为 toxic）", _calamity_theme_rule, "空串")
	_ct_assert(player.max_hp == g_hp0 and is_equal_approx(player.mag_cap_mult, g_mc0) and is_equal_approx(diamond_mult, g_dm0) and is_equal_approx(Game.calamity_speed_mult, g_cs0),
		"G06 f12 clear 后四通道还原入口快照（主题重建前读——⑮ 同型）",
		"(hp=%s, mc=%s, dm=%s, cs=%s)" % [player.max_hp, player.mag_cap_mult, diamond_mult, Game.calamity_speed_mult],
		"(hp=%s, mc=%s, dm=%s, cs=%s)" % [g_hp0, g_mc0, g_dm0, g_cs0])
	_calamity = ""
	# ---- H 组（7，S28 批二）：文案名义值 → 实际值 ----
	# H01 名义≠实际构造：old_hp=6、基线比例 0.2 → 名义 20%，实际 cut=1/6≈17%（相等则恒过不算覆盖）
	Game.floor_num = 1
	_ct_reset_channels()
	player.max_hp = 6
	player.hp = 6
	_calamity = "frail"
	_apply_calamity()
	var h_cut: int = _calamity_frail_cut
	var h_old: int = player.max_hp + _calamity_frail_cut
	var h_pct := int(round(100.0 * float(h_cut) / float(maxi(1, h_old))))
	var h01_name := String(_calamity_name("frail"))
	_ct_assert(h_pct != 20 and h01_name == "虚弱（生命上限 -%d%%）" % h_pct and h01_name.contains("虚弱"),
		"H01 frail 常规局文案含实际百分比（读名义即红）", "%s (nominal=20, actual=%d)" % [h01_name, h_pct], "含 -%d%% 且首词保留" % h_pct)
	# H02 钳制局：max_hp=2 → cut 重算为 0 → 「不再削减」且不含 -0%
	player.max_hp = 2
	player.hp = 2
	_calamity = "frail"
	_apply_calamity()
	var h02 := String(_calamity_name("frail"))
	_ct_assert(h02.contains("不再削减") and not h02.contains("-0%"), "H02 frail 钳制局不显示 -0%（靶心）", h02, "含「不再削减」且无 -0%")
	_ct_assert(player.max_hp == 2, "H03 前提守卫（恒过）：钳制局 max_hp 确为 2", player.max_hp, 2)
	# H04 常规 scarce_ore：base=1.0 → -30%
	_ct_reset_channels()
	_calamity = "scarce_ore"
	_apply_calamity()
	var h04 := String(_calamity_name("scarce_ore"))
	_ct_assert(h04.contains("-30%") and h04.contains("残响枯竭"), "H04 scarce_ore 常规局 -30%（base=1.0 实读）", h04, "含 -30% 且首词保留")
	# H05 barren 局：diamond=0.7 → apply 真链捕获 saved=0.7 → 不再削减（靶心）
	diamond_mult = 0.7
	_calamity = "scarce_ore"
	_apply_calamity()
	var h05 := String(_calamity_name("scarce_ore"))
	_ct_assert(h05.contains("不再削减") and not h05.contains("-0%"), "H05 barren 局 scarce_ore 不显示 -0%（靶心）", h05, "含「不再削减」且无 -0%")
	_ct_assert(is_equal_approx(_calamity_saved_diamond_mult, 0.7), "H06 前提守卫（恒过）：构造真的在 base=0.7", _calamity_saved_diamond_mult, 0.7)
	# H07 四条文案首词逐字保留（跨批回归守卫，聚合）
	var h07_bad: Array[String] = []
	for pair in [["frail", "虚弱"], ["frenzy", "狂乱"], ["scarce_ammo", "弹药荒"], ["scarce_ore", "残响枯竭"]]:
		if not String(_calamity_name(String(pair[0]))).contains(String(pair[1])):
			h07_bad.append(String(pair[0]))
	_ct_assert(h07_bad.is_empty(), "H07 四条文案首词逐字保留（跨批回归守卫）", h07_bad, "0 违例")
	_calamity = ""

	# ---- 出口：还原现场 ----
	Game.floor_num = save_floor
	_calamity = save_calamity
	_theme_rule = save_theme_rule
	diamond_mult = save_dm
	enemy_speed_mult = save_esm
	_mod_enemy_speed_mult = float(save_mod_es)   # S27 批三：还原本局真实 modifier 贡献（不许写 1.0）
	_mod_diamond_mult = float(save_mod_d)
	_calamity_frail_ratio = float(save_frail_ratio)   # S28 批二：G/H 组现场逐项还原
	_calamity_frail_cut = int(save_frail_cut)
	_calamity_saved_diamond_mult = float(save_saved_dm)
	Game.calamity_speed_mult = save_csm
	player.mag_cap_mult = save_mc
	player.max_hp = save_mhp
	player.hp = save_hp
	player.terrain_accel_mult = save_tam
	player.terrain_speed_mult = save_tsm
	_calamity_theme_rule = ""
	_calamity_frail_ratio = 0.2
	_calamity_frail_cut = 0
	_calamity_saved_diamond_mult = 1.0
	_calamity_saved_mag_cap_mult = 1.0
	player.hp_changed.emit(player.hp, player.max_hp)
	player.mag_changed.emit(player.mag(), player.mag_cap())
	update_floor_sign()
	Dev.check(_ct_checked == _CT_DECLARED, "cal_theme",
		"自校验失败: checked(%d) != declared(%d)——有断言被跳过或死数错" % [_ct_checked, _CT_DECLARED])
	print("[SMOKE-CAL-THEME] done checked=%d declared=%d" % [_ct_checked, _CT_DECLARED])
	_smoke_cal_theme_s31_probe()


## S31 灾祸文案快照差分探针：造局施加 → 制造 live 漂移 → 刷层签 → 取 _calamity_name + 层签文本。
## 12 条（F1/F2/F0/A1/A2/A2t/A0/O1/O2/O3/O4/W1）。出口整体还原，不污染后续 autopilot / 八探针。
func _smoke_cal_theme_s31_probe() -> void:
	_s31_checked = 0
	var sv_mhp: int = player.max_hp
	var sv_hp: int = player.hp
	var sv_mc: float = player.mag_cap_mult
	var sv_dm: float = diamond_mult
	var sv_csm: float = Game.calamity_speed_mult
	var sv_floor: int = Game.floor_num
	var sv_cal: String = _calamity
	var sv_rule: String = _calamity_theme_rule
	var sv_speed_app: float = _calamity_speed_mult_applied
	var sv_ammo_app: float = _calamity_ammo_mult_applied
	var sv_mod_dm: float = _mod_diamond_mult

	# F1 frenzy apply 当刻（前提守卫·恒过：live==施加值，错实现也绿）
	_ct_reset_channels()
	Game.floor_num = 1
	_calamity = "frenzy"
	_apply_calamity()
	var f1: String = _calamity_name("frenzy")
	_s31_assert(f1.contains("狂乱") and f1.contains("25%"), "F1 frenzy apply 当刻=25%", f1, "含 狂乱+25%")

	# F2 frenzy 施加后改 live=1.6，文案仍报快照 25%（验效果型·差分）
	Game.calamity_speed_mult = 1.6
	update_floor_sign()
	var f2n: String = _calamity_name("frenzy")
	var f2s: String = String(hud._floor_sign_label.text)
	_s31_assert(f2n.contains("25%") and not f2n.contains("60%") and f2s.contains("25%") and not f2s.contains("60%"),
		"F2 frenzy 名义≠实际(live=1.6)", "name=%s | sign=%s" % [f2n, f2s], "含25% 不含60%")

	# F0 frenzy 0 增量（合成前提守卫，走「不再加速」禁 0%）
	_calamity_speed_mult_applied = 1.0
	var f0: String = _calamity_name("frenzy")
	_s31_assert(f0.contains("狂乱（敌人不再加速）") and not f0.contains("0%"), "F0 frenzy 0=不再加速", f0, "含 敌人不再加速 不含 0%")
	_calamity_speed_mult_applied = 1.25

	# A1 ammo apply 当刻（前提守卫）
	_ct_reset_channels()
	Game.floor_num = 1
	_calamity = "scarce_ammo"
	_apply_calamity()
	var a1: String = _calamity_name("scarce_ammo")
	_s31_assert(a1.contains("弹药荒") and a1.contains("-50%"), "A1 ammo apply 当刻=-50%", a1, "含 弹药荒+-50%")

	# A2 ammo 施加后改 live=0.9，文案仍报快照 -50%（验效果型·差分）
	player.mag_cap_mult = 0.9
	update_floor_sign()
	var a2n: String = _calamity_name("scarce_ammo")
	var a2s: String = String(hud._floor_sign_label.text)
	_s31_assert(a2n.contains("-50%") and not a2n.contains("-10%") and a2s.contains("-50%") and not a2s.contains("-10%"),
		"A2 ammo 名义≠实际(live=0.9)", "name=%s | sign=%s" % [a2n, a2s], "含-50% 不含-10%")

	# A2t ammo 真实 toxic tick 0.5→0.4→0.3（验效果型·真实时变；live 会随 tick 漂到 -70%）
	_ct_reset_channels()
	Game.floor_num = 5
	_apply_floor_theme()
	var hp_keep: int = player.hp
	_calamity = "scarce_ammo"
	_apply_calamity()
	_theme_damage_tick()
	player.hp = hp_keep
	_theme_damage_tick()
	player.hp = hp_keep
	update_floor_sign()
	var a2tn: String = _calamity_name("scarce_ammo")
	var a2ts: String = String(hud._floor_sign_label.text)
	_s31_assert(a2tn.contains("-50%") and not a2tn.contains("-70%") and a2ts.contains("-50%") and not a2ts.contains("-70%"),
		"A2t ammo 真实 tick 至0.3 仍报-50%", "name=%s | sign=%s | mc=%s" % [a2tn, a2ts, str(player.mag_cap_mult)], "含-50% 不含-70%")

	# A0 ammo 0 削减（合成前提守卫）
	_calamity_ammo_mult_applied = 1.0
	var a0: String = _calamity_name("scarce_ammo")
	_s31_assert(a0.contains("弹药荒（弹匣不再削减）") and not a0.contains("-0%"), "A0 ammo 0=不再削减", a0, "含 弹匣不再削减 不含 -0%")
	_calamity_ammo_mult_applied = 0.5

	# O1 压力层 ore base=1.5 → -53%（验效果型；快照分母）
	_ct_reset_channels()
	_mod_diamond_mult = 1.0
	diamond_mult = 1.0
	Game.floor_num = 6
	_apply_floor_theme()
	_calamity = "scarce_ore"
	_apply_calamity()
	var o1: String = _calamity_name("scarce_ore")
	_s31_assert(o1.contains("-53%"), "O1 pressure ore 快照分母=-53%", "base=%s | %s" % [str(_calamity_saved_diamond_mult), o1], "含-53%")

	# O2 承 O1 改 live diamond=1.2，分母不变（验效果型）
	diamond_mult = 1.2
	var o2: String = _calamity_name("scarce_ore")
	_s31_assert(o2.contains("-53%") and not o2.contains("-42%"), "O2 ore 改live后分母仍快照", o2, "含-53% 不含-42%")

	# O3 常规 ore base=1.0 → -30%（验效果型·跨批回归；常态 _mod==saved==1.0）
	_ct_reset_channels()
	_mod_diamond_mult = 1.0
	Game.floor_num = 1
	_calamity = "scarce_ore"
	_apply_calamity()
	var o3: String = _calamity_name("scarce_ore")
	_s31_assert(o3.contains("-30%"), "O3 常规 ore=-30%", o3, "含-30%")

	# O4 barren ore base=0.7 → 不再削减（验效果型·跨批回归；barren 的 _mod==saved==0.7）
	_ct_reset_channels()
	_mod_diamond_mult = 0.7
	diamond_mult = 0.7
	Game.floor_num = 1
	_calamity = "scarce_ore"
	_apply_calamity()
	var o4: String = _calamity_name("scarce_ore")
	_s31_assert(o4.contains("不再削减") and not o4.contains("-0%"), "O4 barren ore=不再削减", o4, "含不再削减 不含-0%")

	# W1 四条族名首词逐字保留（验效果型）
	player.max_hp = 10
	_calamity_frail_cut = 2
	_calamity_saved_diamond_mult = 1.0
	_calamity_speed_mult_applied = 1.25
	_calamity_ammo_mult_applied = 0.5
	var w1_bad: Array[String] = []
	if not String(_calamity_name("frail")).contains("虚弱"): w1_bad.append("frail")
	if not String(_calamity_name("frenzy")).contains("狂乱"): w1_bad.append("frenzy")
	if not String(_calamity_name("scarce_ammo")).contains("弹药荒"): w1_bad.append("scarce_ammo")
	if not String(_calamity_name("scarce_ore")).contains("残响枯竭"): w1_bad.append("scarce_ore")
	_s31_assert(w1_bad.is_empty(), "W1 四首词逐字保留", str(w1_bad), "0 违例")

	# 出口整体还原
	_calamity = sv_cal
	_calamity_theme_rule = sv_rule
	_calamity_speed_mult_applied = sv_speed_app
	_calamity_ammo_mult_applied = sv_ammo_app
	Game.floor_num = sv_floor
	player.max_hp = sv_mhp
	player.hp = sv_hp
	player.mag_cap_mult = sv_mc
	diamond_mult = sv_dm
	_mod_diamond_mult = sv_mod_dm
	Game.calamity_speed_mult = sv_csm
	update_floor_sign()
	Dev.check(_s31_checked == _S31_DECLARED, "cal_theme_s31",
		"自校验失败: s31 checked(%d) != declared(%d)" % [_s31_checked, _S31_DECLARED])
	print("[SMOKE-CAL-THEME-S31] done checked=%d declared=%d" % [_s31_checked, _S31_DECLARED])


## ---------------- Sprint 32：圣所随地形改写探针（SMOKE_S32_SHRINE） ----------------
## 19 条（S1–S5 + M1–M9 + D1–D4 + P1）；P2–P5 是门外分跑门，不在此块计。
## 前缀 [SMOKE-S32-SHRINE]（非 [SMOKE-SHRINE] 超集），计数独立；双门同布尔；统计行恒打印不判红。
const _S32_DECLARED := 19
var _s32_checked := 0
const _S32_EIGHT := [Vector2i(3, 4), Vector2i(3, 5), Vector2i(4, 4), Vector2i(0, 1),
	Vector2i(-2, 7), Vector2i(7, -3), Vector2i(1, 1), Vector2i(20, 20)]
const _S32_FROZEN_F3 := "(3,4)=[blood_relic,ore_upgrade,heal] (3,5)=[greed_pact,heal,ward_boon] (4,4)=[blood_relic,greed_pact,heal] (0,1)=[blood_relic,ore_upgrade,ward_boon] (-2,7)=[blood_relic,ore_upgrade,heal] (7,-3)=[ore_upgrade,ward_boon,heal] (1,1)=[heal,ward_boon,blood_relic] (20,20)=[ward_boon,ore_upgrade,greed_pact]"


func _s32_assert(ok: bool, nn: String, measured, expect) -> void:
	_s32_checked += 1
	var m := str(measured)
	var e := str(expect)
	Dev.check(ok, "s32_shrine", "%s | measured=%s expect=%s" % [nn, m, e])
	print("[SMOKE-S32-SHRINE] #%02d %s measured=%s expect=%s ok=%s" % [_s32_checked, nn, m, e, str(ok)])


func _s32_ids(offers: Array) -> Array:
	var out: Array = []
	for o in offers:
		out.append(String((o as Dictionary).get("id", "?")))
	return out


## 在指定 floor/calamity 下扫 1681 网格，聚合 命中/首槽/次槽/重复/出现集合；出口还原现场
func _s32_scan(floor_n: int, cal: String) -> Dictionary:
	var sv_floor := Game.floor_num
	var sv_cal := _calamity
	Game.floor_num = floor_n
	_calamity = cal
	var n := 0
	var hit := {}
	var slot0 := {}
	var slot1 := {}
	var idset := {}
	var dup := 0
	for x in range(-20, 21):
		for y in range(-20, 21):
			var offers := _shrine_offers_for(Vector2i(x, y))
			if offers.size() != 3:
				continue
			n += 1
			var i0 := String(offers[0]["id"])
			var i1 := String(offers[1]["id"])
			var i2 := String(offers[2]["id"])
			hit[i0] = int(hit.get(i0, 0)) + 1
			hit[i1] = int(hit.get(i1, 0)) + 1
			hit[i2] = int(hit.get(i2, 0)) + 1
			idset[i0] = true
			idset[i1] = true
			idset[i2] = true
			slot0[i0] = int(slot0.get(i0, 0)) + 1
			slot1[i1] = int(slot1.get(i1, 0)) + 1
			if i0 == i1 or i1 == i2 or i0 == i2:
				dup += 1
	Game.floor_num = sv_floor
	_calamity = sv_cal
	return {"n": n, "hit": hit, "slot0": slot0, "slot1": slot1, "idset": idset, "dup": dup}


func _s32_rate(st: Dictionary, id: String) -> float:
	var n := int(st["n"])
	if n <= 0:
		return 0.0
	return float(int((st["hit"] as Dictionary).get(id, 0))) / float(n)


func _s32_cnt(st: Dictionary, key: String, id: String) -> int:
	return int((st[key] as Dictionary).get(id, 0))


## 现行三段抽取基线（独立复算，用于 M8 等价）：返回 id 串
func _s32_baseline_ids(floor_n: int, cal: String, coord: Vector2i) -> Array:
	var sv_floor := Game.floor_num
	var sv_cal := _calamity
	Game.floor_num = floor_n
	_calamity = cal
	var pool: Array = []
	for id in Data.SHRINE_OFFERS:
		var o: Dictionary = Data.SHRINE_OFFERS[id]
		if Game.floor_num < int(o.get("min_floor", 3)):
			continue
		if String(id) == "purify" and _calamity == "":
			continue
		pool.append(String(id))
	var out: Array = []
	if pool.size() >= 3:
		var key := "%d_%d_%d" % [Game.run_seed, Game.floor_num, coord.x * 1000 + coord.y]
		var used := {}
		for i in 3:
			var idx: int = Game.stable_hash("%s#%d" % [key, i]) % pool.size()
			while used.has(idx):
				idx = (idx + 1) % pool.size()
			used[idx] = true
			out.append(pool[idx])
	Game.floor_num = sv_floor
	_calamity = sv_cal
	return out


## 指定 floor/cal 下「偏好子集」的 id 列表（保声明序）——D4 独立复算分母
func _s32_pref_pool_ids(floor_n: int, cal: String) -> Array:
	var sv_floor := Game.floor_num
	var sv_cal := _calamity
	Game.floor_num = floor_n
	_calamity = cal
	var pref: Array = _shrine_theme_pref()[0]
	var out: Array = []
	for id in Data.SHRINE_OFFERS:
		var o: Dictionary = Data.SHRINE_OFFERS[id]
		if Game.floor_num < int(o.get("min_floor", 3)):
			continue
		if String(id) == "purify" and _calamity == "":
			continue
		if pref.has(String(id)):
			out.append(String(id))
	Game.floor_num = sv_floor
	_calamity = sv_cal
	return out


func _smoke_s32_shrine_probe() -> void:
	_s32_checked = 0
	# 预扫七靶 + vines 灾祸靶（各 1681 网格）
	var s1 := _s32_scan(9, "")
	var s2 := _s32_scan(5, "frail")
	var s3 := _s32_scan(4, "")
	var s4 := _s32_scan(6, "")
	var s5 := _s32_scan(14, "")
	var s6 := _s32_scan(7, "frail")
	var s7 := _s32_scan(7, "")
	var s8 := _s32_scan(11, "frail")
	var n1 := int(s1["n"])
	var n3 := int(s3["n"])

	# 统计行（恒打印、不判红）
	print("[SMOKE-S32-SHRINE] rate T1 ice ward=%.4f wind=%.4f | T2 heal=%.4f ward=%.4f | T3 ore=%.4f ward=%.4f greed=%.4f | T4 wind=%.4f power=%.4f | T5 wind=%.4f power=%.4f | T8 heal=%.4f" % [
		_s32_rate(s1, "ward_boon"), _s32_rate(s1, "wind_dance"),
		_s32_rate(s2, "heal"), _s32_rate(s2, "ward_boon"),
		_s32_rate(s3, "ore_upgrade"), _s32_rate(s3, "ward_boon"), _s32_rate(s3, "greed_pact"),
		_s32_rate(s4, "wind_dance"), _s32_rate(s4, "power_surge"),
		_s32_rate(s5, "wind_dance"), _s32_rate(s5, "power_surge"),
		_s32_rate(s8, "heal")])
	print("[SMOKE-S32-SHRINE] slot0 T1 ward=%d/%d | down@slot1 T1=%d T2=%d T3=%d" % [
		_s32_cnt(s1, "slot0", "ward_boon"), n1,
		_s32_cnt(s1, "slot1", "wind_dance"), _s32_cnt(s2, "slot1", "ward_boon"), _s32_cnt(s3, "slot1", "greed_pact")])

	# S1 ice 偏好卡命中率 1.0000
	var r1 := _s32_rate(s1, "ward_boon")
	_s32_assert(r1 >= 0.99, "S1 ice pref命中率", "%.4f" % r1, ">=0.99 (1.0000)")

	# S2 ice 低偏好压低且未消失
	var r2 := _s32_rate(s1, "wind_dance")
	_s32_assert(r2 >= 0.05 and r2 <= 0.20, "S2 ice down压低未消失", "%.4f" % r2, "[0.05,0.20] (0.1077)")

	# S3 toxic 交叉（pref/down 各一）
	var r3h := _s32_rate(s2, "heal")
	var r3w := _s32_rate(s2, "ward_boon")
	_s32_assert(r3h >= 0.99 and r3w >= 0.05 and r3w <= 0.20, "S3 toxic交叉",
		"heal=%.4f ward=%.4f" % [r3h, r3w], "heal>=0.99 ward∈[0.05,0.20]")

	# S4 vein 双 pref 同时抬升 + down 压低
	var r4o := _s32_rate(s3, "ore_upgrade")
	var r4w := _s32_rate(s3, "ward_boon")
	var r4g := _s32_rate(s3, "greed_pact")
	_s32_assert(r4o >= 0.70 and r4w >= 0.70 and r4g >= 0.20 and r4g <= 0.36, "S4 vein双pref+down",
		"ore=%.4f ward=%.4f greed=%.4f" % [r4o, r4w, r4g], "ore,ward>=0.70 greed∈[0.20,0.36]")

	# S5 T1 其余 7 张中性卡 各自 ∈ [0.22,0.33]（前提守卫）
	var s5bad: Array[String] = []
	for id in ["blood_relic", "ore_upgrade", "heal", "relic_suffix", "greed_pact", "shard_pact", "power_surge"]:
		var rr := _s32_rate(s1, String(id))
		if rr < 0.22 or rr > 0.33:
			s5bad.append("%s=%.4f" % [id, rr])
	_s32_assert(s5bad.is_empty(), "S5 中性7卡∈[0.22,0.33]", str(s5bad), "0 越界")

	# M1 T1 偏好唯一 → 首槽恒 ward_boon
	var m1 := _s32_cnt(s1, "slot0", "ward_boon")
	_s32_assert(m1 == n1, "M1 首槽恒偏好卡", "%d/%d" % [m1, n1], "%d/%d" % [n1, n1])

	# M2 down 不进第二槽（三靶各 0）
	var m2 := _s32_cnt(s1, "slot1", "wind_dance") + _s32_cnt(s2, "slot1", "ward_boon") + _s32_cnt(s3, "slot1", "greed_pact")
	_s32_assert(m2 == 0, "M2 down不进#1", str(m2), "0（三靶合计）")

	# M3 三卡 id 两两不等（三靶 dup 0）
	var m3 := int(s1["dup"]) + int(s2["dup"]) + int(s3["dup"])
	_s32_assert(m3 == 0, "M3 三卡两两不等", str(m3), "0（三靶合计重复组）")

	# M4 vein 首槽只在两张 pref 内且各约半 [800,880]
	var m4_nonpref := 0
	for id in (s3["slot0"] as Dictionary):
		if String(id) != "ore_upgrade" and String(id) != "ward_boon":
			m4_nonpref += int((s3["slot0"] as Dictionary)[id])
	var m4o := _s32_cnt(s3, "slot0", "ore_upgrade")
	var m4w := _s32_cnt(s3, "slot0", "ward_boon")
	_s32_assert(m4_nonpref == 0 and m4o >= 800 and m4o <= 880 and m4w >= 800 and m4w <= 880,
		"M4 vein首槽=两pref各约半", "nonpref=%d ore=%d ward=%d/%d" % [m4_nonpref, m4o, m4w, n3], "nonpref0 ore,ward∈[800,880]")

	# M5 pressure 第 6 层单向上行（power_surge 未入池）
	var m5w := _s32_rate(s4, "wind_dance")
	var m5p := _s32_rate(s4, "power_surge")
	_s32_assert(m5w >= 0.99 and m5p == 0.0, "M5 pressure首轮单向上行",
		"wind=%.4f power=%.4f" % [m5w, m5p], "wind>=0.99 power=0")

	# M6 pressure 第 14 层双向
	var m6w := _s32_rate(s5, "wind_dance")
	var m6p := _s32_rate(s5, "power_surge")
	var m6s := _s32_cnt(s5, "slot1", "power_surge")
	_s32_assert(m6w >= 0.99 and m6p >= 0.05 and m6p <= 0.20 and m6s == 0, "M6 pressure第14层双向",
		"wind=%.4f power=%.4f #1=%d" % [m6w, m6p, m6s], "wind>=0.99 power∈[0.05,0.20] #1=0")

	# M7 silent 有灾祸 → purify 唯一偏好
	var m7 := _s32_rate(s6, "purify")
	_s32_assert(m7 >= 0.99, "M7 silent灾祸 purify唯一", "%.4f" % m7, ">=0.99")

	# M8 silent 无灾祸 → 整层无偏向（=现行基线，且 purify 0 次）
	var svf8 := Game.floor_num
	var svc8 := _calamity
	Game.floor_num = 7
	_calamity = ""
	var m8_bad := 0
	var m8_purify := 0
	for x in range(-20, 21):
		for y in range(-20, 21):
			var c8 := Vector2i(x, y)
			var got8 := _s32_ids(_shrine_offers_for(c8))
			if got8.has("purify"):
				m8_purify += 1
			if got8 != _s32_baseline_ids(7, "", c8):
				m8_bad += 1
	Game.floor_num = svf8
	_calamity = svc8
	_s32_assert(m8_bad == 0 and m8_purify == 0, "M8 silent无灾祸=基线",
		"bad=%d purify=%d" % [m8_bad, m8_purify], "bad=0 purify=0")

	# M9 vines（down 空）≠ 只卖 heal：heal 1.0 且出现过 10 个不同 id
	var m9h := _s32_rate(s8, "heal")
	var m9n := (s8["idset"] as Dictionary).size()
	_s32_assert(m9h >= 0.99 and m9n == 10, "M9 vines down空≠只卖heal",
		"heal=%.4f distinct=%d" % [m9h, m9n], "heal>=0.99 distinct=10")

	# D1 同 key 两次派生逐字相同，且 8 坐标互不全同（三靶各）
	var d1_bad := 0
	var d1_var_ok := true
	for t in [[9, ""], [5, "frail"], [4, ""]]:
		var svf1 := Game.floor_num
		var svc1 := _calamity
		Game.floor_num = int(t[0])
		_calamity = String(t[1])
		var d1_seen := {}
		for c1 in _S32_EIGHT:
			var a1 := _s32_ids(_shrine_offers_for(c1))
			var b1 := _s32_ids(_shrine_offers_for(c1))
			if a1 != b1:
				d1_bad += 1
			d1_seen[str(a1)] = true
		if d1_seen.size() < 2:
			d1_var_ok = false
		Game.floor_num = svf1
		_calamity = svc1
	_s32_assert(d1_bad == 0 and d1_var_ok, "D1 同key两次一致且互不全同",
		"bad=%d var_ok=%s" % [d1_bad, str(d1_var_ok)], "bad=0 var_ok=true")

	# D2 零 Game.rng 消费（8 主题 × 1681 派生前后 seed/state 逐字不变）
	var d2_seed := Game.rng.seed
	var d2_state := Game.rng.state
	var svf2 := Game.floor_num
	var svc2 := _calamity
	for f2 in range(4, 12):
		Game.floor_num = f2
		_calamity = ""
		for x in range(-20, 21):
			for y in range(-20, 21):
				_shrine_offers_for(Vector2i(x, y))
	Game.floor_num = svf2
	_calamity = svc2
	_s32_assert(Game.rng.seed == d2_seed and Game.rng.state == d2_state, "D2 零rng消费",
		"seed %s->%s state %s->%s" % [str(d2_seed), str(Game.rng.seed), str(d2_state), str(Game.rng.state)], "seed/state 恒定")

	# D3 零偏好等价（f=3 N=5 八坐标逐字 == 冻结串；f=1/2 返回 []）
	var svf3 := Game.floor_num
	var svc3 := _calamity
	Game.floor_num = 3
	_calamity = ""
	var d3_parts: Array[String] = []
	for c3 in _S32_EIGHT:
		d3_parts.append("(%d,%d)=[%s]" % [c3.x, c3.y, ",".join(PackedStringArray(_s32_ids(_shrine_offers_for(c3))))])
	var d3_str := " ".join(PackedStringArray(d3_parts))
	Game.floor_num = 1
	var d3_f1 := _shrine_offers_for(Vector2i(0, 0)).size()
	Game.floor_num = 2
	var d3_f2 := _shrine_offers_for(Vector2i(0, 0)).size()
	Game.floor_num = svf3
	_calamity = svc3
	_s32_assert(d3_str == _S32_FROZEN_F3 and d3_f1 == 0 and d3_f2 == 0, "D3 零偏好=冻结基线",
		d3_str, _S32_FROZEN_F3 + " | f1=%d f2=%d" % [d3_f1, d3_f2])

	# D4 hash#0 逐字不动（T3 vein 8 坐标 offers[0] == 复算 pr[stable_hash(key#0)%2]）
	var svf4 := Game.floor_num
	var svc4 := _calamity
	Game.floor_num = 4
	_calamity = ""
	var pr4 := _s32_pref_pool_ids(4, "")
	var d4_ok := 0
	if pr4.size() > 0:
		for c4 in _S32_EIGHT:
			var got0 := String((_shrine_offers_for(c4))[0]["id"])
			var key4 := "%d_%d_%d" % [Game.run_seed, Game.floor_num, c4.x * 1000 + c4.y]
			var exp0 := String(pr4[Game.stable_hash("%s#0" % key4) % pr4.size()])
			if got0 == exp0:
				d4_ok += 1
	Game.floor_num = svf4
	_calamity = svc4
	_s32_assert(d4_ok == 8, "D4 hash#0逐字不动", "%d/8" % d4_ok, "8/8（pr.size=%d）" % pr4.size())

	# P1 恒可解：9 层 × 1681（size==3、无空槽、无重复）
	var p1_bad := 0
	var p1_n := 0
	var svf5 := Game.floor_num
	var svc5 := _calamity
	for f5 in [4, 5, 6, 7, 8, 9, 10, 11, 14]:
		Game.floor_num = f5
		_calamity = ""
		for x in range(-20, 21):
			for y in range(-20, 21):
				var o5 := _shrine_offers_for(Vector2i(x, y))
				p1_n += 1
				if o5.size() != 3:
					p1_bad += 1
					continue
				var a5 := String(o5[0]["id"])
				var b5 := String(o5[1]["id"])
				var c5 := String(o5[2]["id"])
				if a5 == "" or b5 == "" or c5 == "" or a5 == b5 or b5 == c5 or a5 == c5:
					p1_bad += 1
	Game.floor_num = svf5
	_calamity = svc5
	_s32_assert(p1_bad == 0 and p1_n == 9 * 1681, "P1 恒可解(9层×1681)",
		"bad=%d n=%d" % [p1_bad, p1_n], "bad=0 n=%d" % (9 * 1681))

	Dev.check(_s32_checked == _S32_DECLARED, "s32_shrine",
		"自校验失败: s32 checked(%d) != declared(%d)" % [_s32_checked, _S32_DECLARED])
	print("[SMOKE-S32-SHRINE] done checked=%d declared=%d" % [_s32_checked, _S32_DECLARED])


## S27 批三：modifier → (敌速倍率, 残响倍率)。纯函数：零 rng、零副作用、不读成员。
## 两个倍率的唯一来源，match 里不再写字面量（防「两处来源各自漂移」）。
func _modifier_mult_pair(m: String) -> Vector2:
	match m:
		"rage":
			return Vector2(1.25, 1.0)
		"barren":
			return Vector2(1.0, 0.7)
		"swarm":
			return Vector2(1.0, 1.5)
		_:
			return Vector2(1.0, 1.0)


## S27 批三：把纯函数结果落到 _mod_* 与 live 两处。零 rng、零副作用（只写 4 个倍率字段）。
## 单独抽出来的唯一目的：让探针能在不调 _roll_modifier()（会抽 rng）的前提下，
## 确定性地验到 _mod_* 与 live 的接线——包括 pair.x/pair.y 接反这种错误。
func _apply_modifier_mult(m: String) -> void:
	var pair := _modifier_mult_pair(m)
	_mod_enemy_speed_mult = pair.x             # 先落 _mod_*
	_mod_diamond_mult = pair.y
	enemy_speed_mult = _mod_enemy_speed_mult    # live 再从 _mod_* 读
	diamond_mult = _mod_diamond_mult


func _roll_modifier() -> void:
	modifier = Data.roll_modifier()
	enemy_hp_mult = 1.0
	enemy_speed_mult = 1.0
	abyss_hp_mult = 1.0
	abyss_speed_mult = 1.0
	abyss_dmg_mult = 1.0
	diamond_mult = 1.0
	_apply_modifier_mult(modifier)
	match modifier:
		"rage":
			enemy_hp_mult = 0.85
		"barren":
			Game.add_diamonds(10)
		"overload":
			player.skill_cd_mult = 0.6
			player.max_hp = maxi(1, player.max_hp - 1)
			player.hp = mini(player.hp, player.max_hp)
		"glass":
			player.crit_chance = minf(player.crit_chance + 0.2, 0.8)
			player.speed_base *= 0.9
	if _smoke:
		print("[SMOKE] modifier=%s" % modifier)
	var m: Dictionary = Data.MODIFIERS.get(modifier, {})
	Dev.info("modifier", "%s：%s" % [m.get("name", modifier), m.get("desc", "")])
	if is_instance_valid(hud):
		hud.refresh_meta()


## 探针：存档接口往返自测（取快照 → 读回 → 再取一次，逐字段比对）
func _test_save_roundtrip() -> void:
	var d1: Dictionary = Game.to_dict()
	Game.from_dict(d1)
	var d2: Dictionary = Game.to_dict()
	var keys := ["kills", "score", "level", "diamonds", "floor_num", "modifier", "resonance"]
	var ok := true
	for k in keys:
		if str(d1[k]) != str(d2[k]):
			ok = false
			print("[SMOKE-SAVE] mismatch %s: %s vs %s" % [k, str(d1[k]), str(d2[k])])
	print("[SMOKE-SAVE] roundtrip=%s upgrades=%d relics=%d" % [
		"OK" if ok else "FAIL", d1["upgrades_taken"].size(), d1["relics"].size()])
	# 设置持久化往返：验证后恢复原值，不污染玩家设置
	var orig: Dictionary = Game.settings.duplicate()
	Game.settings["sfx"] = 0.42
	Game.save_settings()
	Game.load_settings()
	var got: float = float(Game.settings.get("sfx", -1.0))
	Game.settings = orig
	Game.save_settings()
	var set_ok: bool = absf(got - 0.42) < 0.001
	if not set_ok:
		ok = false
	print("[SMOKE-SAVE] settings persist=%s" % ("OK" if set_ok else "FAIL"))


## SMOKE 探针：局外 meta 的池过滤 / 断言 / 存读往返 / 坏档回退
## 只写隔离档 user://_smoke_meta.cfg，绝不碰玩家档
func _smoke_meta_probe() -> void:
	if OS.get_environment("SMOKE_META_POOL") != "":
		print("[SMOKE-META] upgrade pool: [%s]" % ", ".join(_meta_pool_ids("upgrade")))
		print("[SMOKE-META] relic pool: [%s]" % ", ".join(_meta_pool_ids("relic")))
		print("[SMOKE-META] weapon pool: [%s]" % ", ".join(_meta_pool_ids("weapon")))
	if OS.get_environment("SMOKE_META_POOLASSERT") != "":
		for kind in ["upgrade", "relic", "weapon"]:
			var need := int(Meta.MIN_USABLE.get(kind, 1))
			var have := _meta_usable(kind)
			Dev.check(have >= need, "meta", "%s 可用条目 %d 少于需求 %d" % [kind, have, need])
		print("[SMOKE-META] pool assert=OK pool=%d" % _meta_usable("upgrade"))
	if OS.get_environment("SMOKE_META_UNLOCKTEST") != "":
		_meta_unlock_test()
	if OS.get_environment("SMOKE_META_APPLY") != "":
		_meta_apply_test()
	if OS.get_environment("SMOKE_META_BUY") != "":
		_meta_buy_test()
	if OS.get_environment("SMOKE_META_SAVE") != "":
		# 只在隔离档上往返：改 → 存 → 读 → 比对 → 还原
		var orig := Game.meta.duplicate(true)
		Game.meta["crystals"] = 12345
		Game.meta["unlocked"] = ["u_mx_pierce"]
		Game.save_meta()
		Game.load_meta()
		var ok := int(Game.meta.get("crystals", 0)) == 12345 \
			and (Game.meta.get("unlocked", []) as Array).has("u_mx_pierce")
		Game.meta = orig
		Game.save_meta()
		print("[SMOKE-META] roundtrip=%s crystals=%d unlocked=%d" % [
			"OK" if ok else "FAIL", int(Game.meta.get("crystals", 0)),
			(Game.meta.get("unlocked", []) as Array).size()])
	if OS.get_environment("SMOKE_META_RNGCOUNT") != "":
		_smoke_rngcount_probe()
	if OS.get_environment("SMOKE_META_QUIT") != "":
		# 不在 _ready 里重载场景（会无限重启）；只校验结算口径与「主动退出不结算」
		var reason: String = "cancel" if OS.get_environment("SMOKE_META_QUIT_ACTION") == "cancel" else "confirm"
		print("[SMOKE-META] quit estimate=%d reason=%s" % [quit_estimate(), reason])
	var corrupt := OS.get_environment("SMOKE_META_CORRUPT")
	if corrupt != "":
		Game.meta_corrupt_test(corrupt)


## 该类内容当前可用条目数（已解锁过滤后）
func _meta_usable(kind: String) -> int:
	var n := 0
	match kind:
		"upgrade":
			for p in Upgrades.POOL:
				if Game.meta_content_unlocked("upgrade", p):
					n += 1
		"relic":
			for p in Relics.POOL:
				if Game.meta_content_unlocked("relic", p):
					n += 1
		"weapon":
			for k in Weapons.DEFS:
				if Game.meta_content_unlocked("weapon", {"id": String(k)}):
					n += 1
	return n


## 该类内容当前可用的条目 id 清单（已解锁过滤后）
func _meta_pool_ids(kind: String) -> Array:
	var out := []
	match kind:
		"upgrade":
			for p in Upgrades.POOL:
				if Game.meta_content_unlocked("upgrade", p):
					out.append(String(p.get("id", "")))
		"relic":
			for p in Relics.POOL:
				if Game.meta_content_unlocked("relic", p):
					out.append(String(p.get("id", "")))
		"weapon":
			for k in Weapons.DEFS:
				if Game.meta_content_unlocked("weapon", {"id": String(k)}):
					out.append(String(k))
	return out


## 端到端：解锁某项 → 确认它真的进了池（测完还原解锁集）
func _meta_unlock_test() -> void:
	var saved := Game.meta_unlocked_ids()
	var saved_crystals := Game.meta_crystals()
	Game.meta["crystals"] = 100000
	for id in Meta.unlock_ids():
		var nid := String(id)
		var n: Dictionary = Meta.node(nid)
		var kind := String(n.get("kind", ""))
		var target := String(n.get("target", ""))
		var before := _meta_usable(kind)
		var before_crystals := Game.meta_crystals()
		var was_owned := Game.meta_is_unlocked(nid)
		var ok := Game.meta_unlock(nid)
		var after := _meta_usable(kind)
		var in_pool := Game.meta_content_unlocked(kind, {"id": target})
		if was_owned:
			# 已经解锁（探针预置）→ 再买必须被拒，且它本来就该在池里
			Dev.check(not ok and in_pool, "meta", "已解锁项 %s 状态异常" % nid)
		else:
			Dev.check(ok and in_pool and after == before + 1, "meta",
				"解锁 %s 未真正进池（%s，%d -> %d）" % [nid, target, before, after])
		var left := Game.meta_crystals()
		print("[SMOKE-META] unlock test=OK id=%s cost=%d left=%d" % [
			nid, int(n.get("cost", 0)), left])
		print("[SMOKE-META-EXTRA] unlock diag id=%s kind=%s target=%s usable %d->%d inpool=%s balance %d->%d" % [
			nid, kind, target, before, after, str(in_pool), before_crystals, left])
		# 幂等：重复购买必须被拒
		var dup := Game.meta_unlock(nid)
		Dev.check(not dup, "meta", "重复购买被接受：%s" % nid)
	Game.meta["unlocked"] = saved
	Game.meta["crystals"] = saved_crystals
	Game.save_meta()


## 8 项解锁物的效果自测：直接走 apply 分支 + 武器行为标志，验证效果真的落地
func _meta_apply_test() -> void:
	var pl = Game.main.player
	Upgrades.apply("mx_pierce", Game.main)
	Dev.check(pl.pierce_bonus == 1, "meta", "mx_pierce 的 apply 未生效（pierce_bonus）")
	print("[SMOKE-META-EXTRA] apply mx_pierce pierce_bonus=%d dmg_mult=%.2f" % [
		pl.pierce_bonus, pl.bullet_dmg_mult])
	Upgrades.apply("mx_critboom", Game.main)
	Dev.check(pl.crit_boom, "meta", "mx_critboom 的 apply 未生效")
	print("[SMOKE-META-EXTRA] apply mx_critboom crit_boom=%s" % str(pl.crit_boom))
	Upgrades.apply("mx_resocore", Game.main)
	Dev.check(pl.has_resocore, "meta", "mx_resocore 的 apply 未生效")
	print("[SMOKE-META-EXTRA] apply mx_resocore has_resocore=%s" % str(pl.has_resocore))
	Relics.apply("mr_resoshield", Game.main)
	Dev.check(pl.has_resoshield, "meta", "mr_resoshield 的 apply 未生效")
	print("[SMOKE-META-EXTRA] apply mr_resoshield has_resoshield=%s" % str(pl.has_resoshield))
	Relics.apply("mr_kinetic", Game.main)
	Dev.check(pl.has_kinetic, "meta", "mr_kinetic 的 apply 未生效")
	print("[SMOKE-META-EXTRA] apply mr_kinetic has_kinetic=%s" % str(pl.has_kinetic))
	# 3 把新武器：行为标志必须真的从 DEFS 传到子弹上
	for w in ["mw_swarm", "mw_arc", "mw_cluster"]:
		var d: Dictionary = Weapons.DEFS[w]
		var b := BulletScript.new()
		b.setup(Vector2.ZERO, Vector2.RIGHT, 100.0, 1.0, true, Color.WHITE, 1.0, 0, 0.0, 1.4, 0, 0.0,
			false, false, bool(d.get("homing", false)), int(d.get("arc", 0)), int(d.get("cluster", 0)))
		var ok := b.homing == bool(d.get("homing", false)) and b.arc == int(d.get("arc", 0)) \
			and b.cluster == int(d.get("cluster", 0))
		Dev.check(ok, "meta", "武器 %s 的行为标志未传到子弹" % w)
		print("[SMOKE-META-EXTRA] apply weapon %s homing=%s arc=%d cluster=%d" % [
			w, str(b.homing), b.arc, b.cluster])
		b.free()


## 端到端：走真实购买路径（Game.meta_unlock）—— 扣费 / 入集 / 重复购买被拒
func _meta_buy_test() -> void:
	var orig := Game.meta.duplicate(true)
	Game.meta["crystals"] = 100000
	for id in Meta.unlock_ids():
		var nid := String(id)
		var before := Game.meta_crystals()
		var ok := Game.meta_unlock(nid)
		Dev.check(ok, "meta", "购买解锁 %s 失败" % nid)
		Dev.check(Game.meta_is_unlocked(nid), "meta", "购买后 %s 未标记为已解锁" % nid)
		print("[SMOKE-META-EXTRA] buy %s ok=%s cost=%d balance %d->%d" % [
			nid, str(ok), int(Meta.node(nid).get("cost", 0)), before, Game.meta_crystals()])
	var dup := Game.meta_unlock(String(Meta.unlock_ids()[0]))
	Dev.check(not dup, "meta", "重复购买被接受")
	Game.meta = orig
	Game.save_meta()


## 读档后重新应用套装效果
func reapply_sets(keys: Array) -> void:
	for k in keys:
		Upgrades._apply_set(String(k), player, self)


## 里程碑提示：每局每条只播一次（复用 toast 通道，零额外 UI 成本）
func _milestone(id: String) -> void:
	if Game.milestones.has(id):
		return
	Game.milestones[id] = true
	var m: Dictionary = Data.MILESTONES.get(id, {})
	if m.is_empty():
		Dev.warn("milestone", "未知里程碑 id（表里没这条）：%s" % id)
		return
	hud.flash_toast(String(m.get("text", "")))
	Game.sfx("powerup", 1.1)
	if _smoke:
		print("[SMOKE] milestone: %s" % id)


## 应用当前楼层主题：环境规则倍率 + 地板色调 + HUD 提示
func _apply_floor_theme() -> void:
	_theme_rule = ""
	_theme_t = 0.0
	# S27 批三 C1：主题倍率先回落到 modifier 贡献（复位必须在 th.is_empty() 早退之前，
	# 否则 1–3 层走早退分支、复位不执行，离压残留）。pressure 的 maxf 在此之上抬起。
	enemy_speed_mult = _mod_enemy_speed_mult
	diamond_mult = _mod_diamond_mult
	var th: Dictionary = Data.theme_for_floor(Game.floor_num)
	if th.is_empty():
		if is_instance_valid(hud):
			hud.refresh_meta()
			hud.set_minimap_hidden(false)
		return
	_theme_rule = String(th.get("rule", ""))
	Game.mark_codex("themes", _theme_rule)   # Sprint 13 C：已历主题登记（图鉴）
	# 地形系数先复位，再按主题覆写（冰面/毒沼作用于 player 物理）
	if is_instance_valid(player):
		player.terrain_accel_mult = 1.0
		player.terrain_speed_mult = 1.0
	match _theme_rule:
		"pressure":
			enemy_speed_mult = maxf(enemy_speed_mult, 1.3)
			diamond_mult = maxf(diamond_mult, 1.5)
		"ice":
			if is_instance_valid(player):
				player.terrain_accel_mult = 0.3
		"swamp":
			if is_instance_valid(player):
				player.terrain_speed_mult = 0.7
	var tint: Color = th.get("tint", Color.WHITE)
	if is_instance_valid(_floor_layer):
		_floor_layer.modulate = tint
	if is_instance_valid(_wall_layer):
		_wall_layer.modulate = tint.lerp(Color.WHITE, 0.35)
	if is_instance_valid(hud):
		hud.refresh_meta()
		hud.set_minimap_hidden(_theme_rule == "silent")
		hud.banner("楼层主题 · " + String(th.get("name", "")))
	if _smoke:
		print("[SMOKE] floor theme: floor=%d name=%s rule=%s" % [
			Game.floor_num, String(th.get("name", "")), _theme_rule])


## C 契约（Sprint 11 §四）：印记注入——必须在任何 Game.rng 绘制之前调用。
## 只改起始状态，不改 rng 消耗顺序（同 seed + 同印记 = 整局可复现）。
## 注入全部为「绝对置位」，start_run 重复调用幂等。
func _apply_sigil_contract() -> void:
	var eq := Game.equipped_sigil()
	if _smoke:
		print("[SMOKE-SIGIL] contract enter: eq='%s' player_valid=%s" % [eq, str(is_instance_valid(player))])
	if eq == "" or not is_instance_valid(player):
		return
	match eq:
		"vigor":
			player.max_hp = Player.BASE_MAX_HP + 1
			player.hp = player.max_hp
			player.hp_changed.emit(player.hp, player.max_hp)
			if _smoke:
				print("[SMOKE-SIGIL] vigor injected: player.max_hp=%d" % player.max_hp)
		"arsenal":
			player.weapon_slots[1] = "shotgun"
			player.slot_mags["shotgun"] = player.mag_cap_for("shotgun")
			player.weapon_changed.emit(player.weapon_slots, player.slot)
		"purse":
			Game.diamonds = 15
			Game.diamonds_changed.emit(Game.diamonds)
		"kindred":
			# Sprint 12 A：临时协战水晶（30s，追击最近敌人）。确定性生成（玩家旁固定偏移，零 rng）
			if is_instance_valid(_ally):
				_ally.queue_free()
			_ally = AllyScript.new()
			_ally.position = clamp_to_arena(player.global_position + Vector2(-40, -30))
			entities.add_child(_ally)
		"sprinter":
			player.dash_boost_mult = 1.3
		"harvester":
			player.harvester_active = true
		"ward":
			player.sigil_ward = true
		"scholar":
			player.scholar_active = true
		"bulwark":
			# Sprint 12 核验 #1 修复：此前 match 漏了本分支（印记完全不生效）
			player.relic_shield_t = maxf(player.relic_shield_t, 2.5)
	if _smoke:
		print("[SMOKE-SIGIL] applied contract: %s (before any rng draw)" % eq)


## 楼层主题的持续规则（毒巢：每 3 秒掉 1 血；岩浆：每 0.5 秒掉 1 血）。
## DoT 计时统一走 E6 固定步（Game.FIXED_DT）——Sprint 10 规划侧裁定，毒巢由 raw delta 收敛
func _tick_floor_theme(_delta: float) -> void:
	match _theme_rule:
		"toxic":
			_theme_t += Game.FIXED_DT
			if _theme_t >= 3.0:
				_theme_t = 0.0
				_theme_damage_tick()
		"magma":
			_theme_t += Game.FIXED_DT
			if _theme_t >= 0.5:
				_theme_t = 0.0
				_theme_damage_tick()


## 环境 DoT 的单次结算；SMOKE 下默认无敌会吞掉 take_damage，探针绕过并保底留 1 血
func _theme_damage_tick() -> void:
	if not is_instance_valid(player):
		return
	# S27 B 组复合变体：时间让代价变深（全批唯一非查表 Dynamics）。snappedf 收敛浮点累加——
	# 0.5-0.1*2 = 0.30000000000000004，不收敛则 == 0.3 断言假红
	if _calamity == "scarce_ammo" and _theme_rule == "toxic":
		var mc_new := maxf(0.3, snappedf(player.mag_cap_mult - 0.1, 0.001))
		if not is_equal_approx(mc_new, player.mag_cap_mult):
			player.mag_cap_mult = mc_new
			player.mag_changed.emit(player.mag(), player.mag_cap())
	elif _calamity == "scarce_ore" and _theme_rule == "magma":
		var dm_new := maxf(0.5, snappedf(diamond_mult - 0.05, 0.001))
		diamond_mult = dm_new
	if _smoke and OS.get_environment("SMOKE_MAGMA_PROBE" if _theme_rule == "magma" else "SMOKE_TOXIC_PROBE") != "":
		player.hp = maxi(player.hp - 1, 1)
		player.hp_changed.emit(player.hp, player.max_hp)
		print("[SMOKE] %s tick hp=%d" % [_theme_rule, player.hp])
	else:
		player.take_damage(1, player.global_position + Vector2(0, -70))


## 残响共鸣：每拾取 1 个升级/遗物 +1 层，满 5 层触发全屏爆发
func add_resonance(n := 1) -> void:
	resonance += n
	while resonance >= _resonance_step:
		resonance -= _resonance_step
		_resonance_burst()
	if is_instance_valid(hud):
		hud.refresh_resonance()
	if _smoke:
		print("[SMOKE] resonance=%d/%d" % [resonance, _resonance_step])


func _resonance_burst() -> void:
	Game.add_score(50)
	player.grant_invuln(1.5)
	# 残响共鸣核心（mx_resocore）：冲击波伤害 6 → 9
	var burst_dmg := 9.0 if player.has_resocore else 6.0
	for e in get_tree().get_nodes_in_group("enemies"):
		if is_instance_valid(e) and e.has_method("take_damage"):
			e.take_damage(burst_dmg, player.global_position, false)
	# 谐振护盾 mr_resoshield：爆发时获得 1 层护盾
	if player.has_resoshield:
		player.shield_charges += 1
		if is_instance_valid(hud):
			hud.flash_toast("谐振护盾 · 护盾 +1（剩 %d 层）" % player.shield_charges)
	var ex := preload("res://scripts/explosion.gd").new()
	ex.setup("blast", 1.4)
	ex.position = player.global_position
	entities.add_child(ex)
	hud.banner("残响共鸣 · 爆发！")
	Game.sfx("secret")
	_milestone("resonance_burst")
	if _smoke:
		print("[SMOKE] resonance burst")


func _tick_room(delta: float) -> void:
	if _transitioning:
		return
	var kind: String = dungeon.room(dungeon.current).get("kind", "combat")
	if room_state == "combat":
		if _room_spawned < _room_budget:
			_spawn_cd -= delta
			if _spawn_cd <= 0.0:
				_spawn_batch(kind)
				_spawn_cd = clampf(1.1 - Game.floor_num * 0.06, 0.3, 1.1)
		elif _telegraphs == 0 and get_tree().get_nodes_in_group("enemies").is_empty():
			_room_cleared()


func _spawn_batch(kind: String) -> void:
	var batch := 1 + (1 if Game.floor_num >= 2 else 0)
	for i in batch:
		if _room_spawned >= _room_budget:
			return
		# F3 编队房：按模板成员出怪（front 近点 / back 远点），取代随机池
		if not _squad_queue.is_empty():
			var m: Dictionary = _squad_queue.pop_front()
			var radius := 210.0 if bool(m.get("front", true)) else 300.0
			var pos := clamp_to_arena(player.global_position \
				+ Vector2.from_angle(Game.rng.randf() * TAU) * radius)
			if pos.distance_to(player.global_position) < 150.0:
				pos = clamp_to_arena(player.global_position \
					+ Vector2.from_angle(Game.rng.randf() * TAU) * 190.0)
			_telegraph_slug(String(m["id"]), pos, 0.55, String(m.get("affix", "")),
				bool(m.get("defuser", false)))
			# 拆弹确定性探针：在拆弹单位旁放一颗长引信哑弹，验证追近+拆除链路
			if bool(m.get("defuser", false)) and OS.get_environment("SMOKE_DEFUSER_PROBE") != "":
				Game.safe_delay(1.2, self, false, func() -> void:
					if _game_over:
						return
					var bomb := BombScript.new()
					var bpos := clamp_to_arena(pos + Vector2(70, 0))
					bomb.setup(bpos, bpos, 1.0, 0.0)
					bomb.set_fuse(9.0)
					entities.add_child(bomb)
					print("[SMOKE] defuser probe bomb planted at ", bpos.round()))
			continue
		var pick: Array = _roll_variant(kind)
		_telegraph_slug(String(pick[0]), _pick_spawn_pos(), 0.55, String(pick[1]))


## F3 敌人编队：combat 房 40% 概率整组生成（走 Game.rng 主流；
## 组合打印走 [SMOKE-SQUAD] 表外探针，不入 E1 指纹——坑 45/规划草案 §二）
func _roll_squad() -> void:
	_squad_queue = []
	_squad_id = ""
	var gate := Game.rng.randf()
	# SMOKE_FORCE_SQUAD 钉死编队时跳过 40% 概率门（保持 rng 消耗不变）
	var forced := OS.get_environment("SMOKE_FORCE_SQUAD")
	if Game.floor_num < 3 or (forced == "" and gate > 0.4):
		return
	var eligible: Array = []
	var total := 0
	for sid in Data.SQUADS:
		var s: Dictionary = Data.SQUADS[sid]
		if Game.floor_num < int(s.get("min_floor", 3)):
			continue
		eligible.append([sid, int(s.get("weight", 1))])
		total += int(s.get("weight", 1))
	if eligible.is_empty():
		return
	var picked: Dictionary = {}
	# 表外测试钩：SMOKE_FORCE_SQUAD 钉死编队选取（forced 已在函数头声明）
	if forced != "" and Data.SQUADS.has(forced) and Game.floor_num >= int(Data.SQUADS[forced].get("min_floor", 3)):
		_squad_id = forced
		picked = Data.SQUADS[forced]
	else:
		var r := Game.rng.randi_range(0, maxi(total - 1, 0))
		for e in eligible:
			r -= int(e[1])
			if r < 0:
				picked = Data.SQUADS[String(e[0])]
				_squad_id = String(e[0])
				break
	if picked.is_empty():
		return
	for m in picked.get("members", []):
		for i in int(m.get("count", 1)):
			_squad_queue.append(m)
	_room_budget = _squad_queue.size()
	if _smoke:
		var summary := {}
		for m in _squad_queue:
			summary[String(m["id"])] = int(summary.get(String(m["id"]), 0)) + 1
		print("[SMOKE-SQUAD] room=%s squad=%s(%s) total=%d" % [
			dungeon.current, _squad_id, String(picked.get("name", "")), _squad_queue.size()])


## 返回 [敌人 id, 词缀 id]
func _roll_variant(kind: String) -> Array:
	if kind == "boss" and _room_spawned == 0:
		return [Data.boss_for_floor(Game.floor_num), ""]
	if kind == "elite" and _room_spawned <= 1:
		return [Data.elite_for_floor(Game.floor_num), ""]
	return Data.roll_enemy(Game.floor_num)


func _weighted_pick(pool: Dictionary) -> String:
	var total := 0
	for k in pool:
		total += pool[k]
	var r := Game.rng.randi_range(0, total - 1)
	for k in pool:
		r -= pool[k]
		if r < 0:
			return k
	return "rusher"


## 首领层判定（Sprint 11 B）：每个 8 主题周期的最后一层生成棱镜守望者
func _is_warden_floor(n: int) -> bool:
	return n > 4 and (n - 4) % 8 == 7


## 主权层判定（Sprint 12 C）：每 16 层一次，与守望者（每 8 层）错开；命中时 Boss 房生成熔潮主宰
func _is_sovereign_floor(n: int) -> bool:
	return n > 4 and (n - 4) % 16 == 15


## Sprint 15 A：第三 Boss 层（F2 解绑）——每 32 层一次，落在首领层且避开主权层
## （23%8=7 是 warden 层、23%16=7≠15 非 sovereign）；纯函数零 rng。命中 n=27/59…
func _is_third_floor(n: int) -> bool:
	return n > 4 and (n - 4) % 32 == 23


## Sprint 18 A v3：本层**房型计数**提示的纯只读派生（主理人 2026-11-08 v3 口径）。
## 只读 `dungeon.rooms` **当前已生成那张图**的 `kind` 字段；零 rng / 零计时 / 零权重 / 零状态写入。
## 废弃 v2 的 `Data.SQUADS` 布尔特征并集：那是**每层恒定查表**——3 层恒为「远射 · 冲锋 · 成群」，
## 跑两局就背下来，不再构成信息；且 `ROOM_META` 里 start/combat/elite/cursed 的 mark 全是 ""
## （data.gd:297-306），小地图对这四类房型零标注——本函数补的正是这个信息盲区。
## 注意：本函数读的是**已生成**的地图，与 `Game.floor_num` 无关；改 floor_num 不会重生成地图，
## 而重生成会消费 `Game.rng`（破 E1 零抽取红线），故探针不得靠改楼层造语境。
## 红线：只陈述房型事实，**不得出现任何推荐语**（建议/推荐/优先/带）——从机制上杜绝主导策略。
func floor_layout_hint() -> String:
	if dungeon == null:
		return ""
	var ne := 0
	var has_cursed := false
	for c in dungeon.rooms:
		var k := String(dungeon.rooms[c].get("kind", ""))
		if k == "elite":
			ne += 1
		elif k == "cursed":
			has_cursed = true
	var parts: Array[String] = []
	parts.append(("精英 %d" % ne) if ne > 0 else "无精英")
	if has_cursed:
		parts.append("有诅咒房")
	return " ｜ ".join(PackedStringArray(parts))


## Sprint 16 C：层签刷新（纯只读拼装——主题 name+mark + 灾祸名或「无」，恰好 2 项默认）。
## 零 rng / 零 fx_rng / 零抽取；挂点：start_run 与 next_floor 的 roll 全完成之后（§4.2，严禁移动 roll）
## Sprint 18 B：主行文本**一字不改**，新增第二行 = `本层 · <房型计数>` ｜ 主题手记（`FLAVOR["themes/"+rule]`），
## 两段皆空则传 `""`（第二行隐藏）。**只走层签常驻行，不调 flash_toast()**——首发现播报归 mark_codex()。
func update_floor_sign() -> void:
	if not is_instance_valid(hud):
		return
	var th: Dictionary = Data.theme_for_floor(Game.floor_num)
	var theme_part := (String(th.get("name", "")) + String(th.get("mark", ""))) if th.has("name") else "无主题"
	var cal: String = _calamity_name(_calamity) if _calamity != "" else "无"
	var sub_parts: Array[String] = []
	var lay := floor_layout_hint()
	if lay != "":
		sub_parts.append("本层 · " + lay)
	var rule := String(th.get("rule", ""))
	if rule != "":
		var flav := String(Data.FLAVOR.get("themes/" + rule, ""))
		if flav != "":
			sub_parts.append(flav)
	hud.set_floor_sign("层签 · %s ｜ 灾祸：%s" % [theme_part, cal],
		" ｜ ".join(PackedStringArray(sub_parts)))


func _pick_spawn_pos() -> Vector2:
	for i in 10:
		var p := player.global_position + Vector2.from_angle(Game.rng.randf() * TAU) * Game.rng.randf_range(230, 320)
		p = clamp_to_arena(p)
		if p.distance_to(player.global_position) > 150.0:
			return p
	return Vector2(24, 24)


func _room_cleared() -> void:
	room_state = "cleared"
	var kind: String = dungeon.room(dungeon.current).get("kind", "combat")
	dungeon.rooms[dungeon.current]["cleared"] = true
	Game.wave += 1
	Game.add_score(30 + Game.floor_num * 10)
	# 博学印记：每层首次清场额外 +2 地窖碎片
	if is_instance_valid(player) and player.scholar_active and _scholar_floor_done != Game.floor_num:
		_scholar_floor_done = Game.floor_num
		Game.add_shards(2)
		hud.flash_toast("博学印记 +2 地窖碎片")
	for d in _doors:
		d.set_locked(false)
	match kind:
		"combat":
			for i in 2 + Game.floor_num:
				drop_pickup(player.global_position + Vector2(Game.rng.randf_range(-40, 40), Game.rng.randf_range(-40, 40)), "diamond", 1)
			if Game.rng.randf() < 0.14:
				drop_pickup(_arena_center(), "heal")
		"elite":
			drop_pickup(_arena_center(), "relic", 1, Relics.roll(1)[0]["id"])
			hud.flash_toast("精英房奖励：遗物！")
			Game.sfx("secret")
			_milestone("first_elite")
		"boss":
			_milestone("first_boss")
			# Sprint 21 C：真·终boss层（第三 Boss 层）通关 → 解锁深渊档 + 记录最高 tier
			if _is_third_floor(Game.floor_num):
				Game.meta["abyss_unlocked"] = true
				if abyss_tier > 0:
					Game.meta["abyss_best_tier"] = maxi(int(Game.meta.get("abyss_best_tier", 0)), abyss_tier)
			drop_pickup(_arena_center() + Vector2(0, 30), "stairs")
			drop_pickup(_arena_center() + Vector2(-34, -10), "weapon", 1, _random_weapon())
			drop_pickup(_arena_center() + Vector2(34, -10), "relic", 1, Relics.roll(1)[0]["id"])
			hud.banner("%s 已被击溃！楼梯出现了" % Data.enemy(Data.boss_for_floor(Game.floor_num)).get("name", "Boss"))
			Game.sfx("secret")
		"challenge":
			# 掉血：普通掉落 + 保底 +30 分；无伤：额外遗物 + 大宝箱
			for i in 3:
				drop_pickup(player.global_position + Vector2(Game.rng.randf_range(-40, 40), Game.rng.randf_range(-40, 40)), "diamond", 1)
			if _room_damaged:
				# D1：固定 +30 分保底 + 专属 toast；掉落表不动，避免「3 改 6」不可感知
				Game.add_score(30)
				hud.flash_toast("挑战失败 · 保底 +30 分")
				if _smoke:
					print("[SMOKE] challenge failed (consolation +30 score)")
			else:
				drop_pickup(_arena_center(), "relic", 1, Relics.roll(1)[0]["id"])
				drop_pickup(_arena_center() + Vector2(0, 26), "chest_big")
				hud.banner("无伤通过！奖励：遗物 + 大宝箱")
				if _smoke:
					print("[SMOKE] challenge no-hit clear")
				Game.sfx("secret")
				Game.add_score(200)
	hud.refresh_minimap(dungeon)


func _random_weapon() -> String:
	return Weapons.random_unlocked()


func _arena_center() -> Vector2:
	return Vector2(ARENA_W, ARENA_H) * TILE * 0.5


func _enter_room(coord: Vector2i, arrive_dir: Vector2i) -> void:
	dungeon.current = coord
	var info: Dictionary = dungeon.rooms[coord]
	info["visited"] = true
	var kind: String = info["kind"]
	var revisit: bool = bool(info.get("cleared", false))  # 进房前是否已清过（Boss 房补楼梯用）
	room_state = "enter"
	_secret_bombed_dirs.clear()
	_room_spawned = 0
	# 进房会清掉上一批 telegraph 节点，它们的减计数回调随节点一起被丢掉，
	# _telegraphs 只增不减会跨房间累积 → 房间永远清不了场 → 自动驾驶反复进出同一房间（BUG-001 真因）
	_telegraphs = 0
	_spawn_cd = 0.4
	_doors = []

	# 清场： entities 里除玩家/浮游炮外全是临时实体
	for c in entities.get_children():
		if c != player and c != turret:
			c.queue_free()

	_build_arena(coord)
	_spawn_decor()

	match kind:
		"start", "treasure", "shop", "secret", "super_secret", "shrine":
			room_state = "cleared"
			for d in _doors:
				d.set_locked(false)
			if kind == "start":
				# 起点房本就是清场状态；不置 true 的话 BFS 每层都会把它当"未清目标"，
				# 玩家于是在起点房与别的房间之间反复折返（BUG-001 第二条路径）
				info["cleared"] = true
			elif info["cleared"]:
				# 宝箱/商店一次性：领取后标记已清，防止重进无限刷
				info["skip_loot"] = true
		"combat", "elite", "boss", "challenge", "cursed":
			if info["cleared"]:
				# 清过的房间不重刷（以撒规则）
				room_state = "cleared"
				for d in _doors:
					d.set_locked(false)
			elif kind == "boss":
				room_state = "combat"
				# 表外测试钩：SMOKE_FORCE_THIRD_BOSS=1 / SMOKE_FORCE_SOVEREIGN=1 强制低层验证
				var third := _is_third_floor(Game.floor_num) \
					or OS.get_environment("SMOKE_FORCE_THIRD_BOSS") != ""
				var sovereign := _is_sovereign_floor(Game.floor_num) \
					or OS.get_environment("SMOKE_FORCE_SOVEREIGN") != ""
				if third:
					# Sprint 15 A：第三 Boss 层（每 32 层收尾）——优先链最高：third > sovereign > warden > 常规
					_room_budget = 1
					var boss3 := Boss3Script.new()
					boss3.position = _arena_center() - Vector2(0, 120)
					entities.add_child(boss3)
					boss3.setup(Game.floor_num)
					if _smoke:
						print("[SMOKE-THIRD-BOSS] third floor boss replaced: floor=%d" % Game.floor_num)
				elif sovereign:
					# 主权层（每 16 层）：熔潮主宰优先（与守望者错开，Sprint 12 C）
					_room_budget = 1
					var boss2 := Boss2Script.new()
					boss2.position = _arena_center() - Vector2(0, 120)
					entities.add_child(boss2)
					boss2.setup(Game.floor_num)
					if _smoke:
						print("[SMOKE-BOSS2] sovereign floor boss replaced: floor=%d" % Game.floor_num)
				elif _is_warden_floor(Game.floor_num):
					# 首领层（每 8 主题周期收尾）：棱镜守望者取代常规 Boss，
					# 常规 SQUADS 抽取暂停（增援由 Boss 状态机独立控制，避免双重召唤）
					_room_budget = 1
					var warden := PrismWardenScript.new()
					warden.position = _arena_center() - Vector2(0, 120)
					entities.add_child(warden)
					warden.setup(Game.floor_num)
					if _smoke:
						print("[SMOKE-BOSS] warden floor boss replaced: floor=%d" % Game.floor_num)
				else:
					_room_budget = 4 + Game.floor_num * 2
					_telegraph_slug(Data.boss_for_floor(Game.floor_num), _arena_center() - Vector2(0, 120), 1.2)
			else:
				room_state = "combat"
				_room_budget = int((5 + Game.floor_num * 3) * (1.6 if kind == "elite" else 1.0))
				if kind == "challenge":
					_room_damaged = false
					# SMOKE 默认无敌，掉血分支永远走不到；用探针强制复现失败结算
					if _smoke and OS.get_environment("SMOKE_CHALLENGE_FAIL") != "":
						_room_damaged = true
						print("[SMOKE] forced challenge-fail probe")
					hud.banner("无伤挑战 —— 掉一滴血就没额外奖励")
					Game.sfx("secret")
				_roll_squad()

	if modifier == "swarm" and room_state == "combat":
		_room_budget += 2

	match kind:
		"treasure":
			if not info.get("skip_loot", false):
				drop_pickup(_arena_center(), "chest_big")
				info["cleared"] = true  # 领取标记（ chest 落地即视为已用）
			hud.banner("宝箱房！")
		"shop":
			if not info.get("skip_loot", false):
				_spawn_shop()
				info["cleared"] = true
				_shop_bought = false
				var m := MerchantScript.new()
				m.position = _arena_center() + Vector2(0, -58)
				entities.add_child(m)
			hud.banner("商店 · 按 E 购买")
		"shrine":
			# 选定后 cleared=true → 重进置 skip_loot 不再出面板（宝箱/商店同范式）；
			# 未选可自由离开，重进重开面板（门不锁的非战斗房语义）
			if not info.get("skip_loot", false):
				hud.banner("抉择圣所 —— 三选其一")
				_open_shrine(coord)
		"secret":
			if not info.get("skip_loot", false):
				drop_pickup(_arena_center(), "chest_big")
				drop_pickup(_arena_center() + Vector2(-26, 6), "relic", 1, Relics.roll(1)[0]["id"])
				drop_pickup(_arena_center() + Vector2(26, 6), "diamond", 8)
				info["skip_loot"] = true
			hud.banner("秘密房！")
			Game.sfx("secret")
		"super_secret":
			# cleared=true 会让 _enter_room 置 skip_loot，故用独立标记保证首次进入确实发奖
			if not info.get("super_loot_taken", false):
				var relics: Array = Relics.roll(2)
				var rid0: String = String(relics[0]["id"])
				var rid1: String = String(relics[1]["id"])
				drop_pickup(_arena_center(), "chest_big")
				drop_pickup(_arena_center() + Vector2(-34, -12), "relic", 1, rid0)
				drop_pickup(_arena_center() + Vector2(34, -12), "relic", 1, rid1)
				drop_pickup(_arena_center() + Vector2(0, 30), "diamond", 12)
				info["super_loot_taken"] = true
				if _smoke:
					print("[SMOKE] super_secret loot dropped: big chest + 2 relics + 12 diamond")
			hud.banner("超级秘密房！稀有奖励")
			Game.sfx("secret")
			_milestone("first_super")
		"challenge":
			if not revisit:
				hud.banner("挑战房！")
		"cursed":
			if not info.get("cursed_paid", false):
				info["cursed_paid"] = true
				player.take_damage(1, _arena_center())
				if _smoke:
					print("[SMOKE] cursed room entry: -1 hp")
			if not info.get("cursed_loot", false):
				info["cursed_loot"] = true
				drop_pickup(_arena_center(), "chest_big")
				drop_pickup(_arena_center() + Vector2(-30, 0), "relic", 1, Relics.roll(1)[0]["id"])
				drop_pickup(_arena_center() + Vector2(30, 0), "diamond", 8)
			hud.banner("诅咒房 —— 生命为代价")
			Game.sfx("secret")
			_milestone("first_cursed")
		"boss":
			if revisit:
				# 已打过但没踩楼梯就出门：重进补回楼梯，否则整层卡死
				drop_pickup(_arena_center() + Vector2(0, 30), "stairs")
			hud.banner("Boss 房 —— 巨岩虫之王！")
		"start":
			hud.banner("第 %d 层" % Game.floor_num)
		"elite":
			hud.banner("精英房！")

	# 玩家落位：从门进来贴对侧门，否则居中
	# 0.36 而非 0.42：门触发区半高 17 + 玩家半径 7 = 24，0.42 时落点距门仅 24px 会立刻回触
	if arrive_dir == Vector2i.ZERO:
		player.position = _arena_center()
	else:
		player.position = clamp_to_arena(_arena_center() - Vector2(arrive_dir) * Vector2(ARENA_W, ARENA_H) * TILE * 0.36)
	player.velocity = Vector2.ZERO
	# 防落点压门：万一落点仍压在门触发区内，该门先失效，待玩家离开后恢复
	for dd in _doors:
		if dd.global_position.distance_to(player.global_position) < 24.0:
			dd.hold_until_exit()
	turret.global_position = player.global_position
	camera.position = player.position
	_pcam.global_position = player.position

	_switch_bgm(int(Data.ROOM_META.get(kind, {}).get("bgm", 0)))
	hud.refresh_minimap(dungeon)
	hud.set_room_info(Game.floor_num, kind)
	if _smoke:
		if kind == "super_secret":
			print("[SMOKE] entered super_secret room at ", coord)
		for dd in _doors:
			var nc: Vector2i = coord + dd.dir
			print("[SMOKE-DOOR] room=%s dir=%s locked=%s neighbor=%s cleared=%s" % [
				coord, dd.dir, dd.locked, dungeon.has_room(nc),
				dungeon.room(nc).get("cleared", "-") if dungeon.has_room(nc) else "-"])


func _spawn_shop() -> void:
	var price_base := 15 + Game.floor_num * 5
	var stands := [
		{"kind": "weapon", "payload": _random_weapon(), "price": price_base + 10},
		{"kind": "relic", "payload": Relics.roll(1)[0]["id"], "price": price_base + 5},
		{"kind": "heal", "payload": "", "price": price_base / 2},
	]
	var xs := [-52, 0, 52]
	for i in stands.size():
		var s := ShopStandScript.new()
		s.setup(stands[i]["kind"], stands[i]["payload"], stands[i]["price"])
		s.position = _arena_center() + Vector2(xs[i], 10)
		entities.add_child(s)


func use_door(dir: Vector2i) -> void:
	if _transitioning or not dungeon.has_room(dungeon.current + dir):
		return
	if _smoke:
		print("[SMOKE] use_door dir=", dir, " from=", dungeon.current)
	var next := dungeon.current + dir
	# BUG-001 断言：同一过门按层计数，重复到第 4 次只打印标记，不制造 ERROR 行
	if _smoke:
		var key: String = "%d:%s>%s" % [Game.floor_num, dungeon.current, next]
		var n: int = int(_smoke_door_repeat.get(key, 0)) + 1
		_smoke_door_repeat[key] = n
		if n == 4:
			print("[SMOKE-LOOP] repeated door %d times: %s" % [n, key])
	_fade_to(func() -> void: _enter_room(next, dir))


## 炸弹炸开秘密房裂纹墙：标记揭示并重建本房间（出现正常门）
func reveal_secret(dir: Vector2i) -> void:
	var nc: Vector2i = dungeon.current + dir
	if not dungeon.rooms.has(nc):
		return
	var nk: String = String(dungeon.rooms[nc].get("kind", "secret"))
	dungeon.rooms[nc]["revealed"] = true
	Game.sfx("secret")
	add_shake(0.4)
	var reveal_text := "炸开一道暗门 —— 超级秘密房！" if nk == "super_secret" else "炸开一道暗门 —— 秘密房！"
	hud.flash_toast(reveal_text)
	_build_arena(dungeon.current)
	hud.refresh_minimap(dungeon)
	if _smoke:
		print("[SMOKE] secret revealed at ", nc, " kind=", nk)
		if OS.get_environment("SMOKE_DUMP") != "":
			print("[RG-6] reveal rebuild: room=%s state=%s doors=%s" % [
				dungeon.current, room_state, _doors.map(func(d): return [d.dir, d.locked])])


func next_floor() -> void:
	if _transitioning or _game_over:
		return
	var nf := Game.floor_num + 1
	_fade_to(func() -> void:
		Game.floor_num = nf
		Game.max_floor = maxi(Game.max_floor, nf)
		_clear_calamity_effects()
		_calamity = ""   # 核验 #5：消除换层瞬间 _calamity 残留（圣所 purify 过滤读过期状态的时序不对称）
		_apply_floor_theme()
		if nf >= 3:
			_milestone("floor3")
		var frng := _floor_rng(nf)
		dungeon = DungeonClass.generate(nf, frng, 7 + nf)
		_smoke_fingerprint(nf)
		_enter_room(dungeon.current, Vector2i.ZERO)
		_roll_calamity()
		update_floor_sign()   # Sprint 16 C：层签刷新（本路径 roll 在进房后——roll 完成后补刷，零 rng 顺序改动 §4.2）
		drop_pickup(_arena_center() + Vector2(0, 40), "heal")
		if _smoke:
			print("[SMOKE] === entered floor ", nf, " ===")
		Game.sfx("powerup", 0.9))


func _fade_to(action: Callable) -> void:
	_transitioning = true
	player.control_locked = true
	var tw := create_tween()
	tw.tween_property(_fade_rect, "color:a", 1.0, 0.22)
	tw.tween_callback(action)
	tw.tween_callback(func() -> void:
		player.control_locked = false
		_transitioning = false)
	tw.tween_property(_fade_rect, "color:a", 0.0, 0.22)


## 自动驾驶过门目标：
## 1) BFS 穿过已清房间，走向最近的未清房间（路径第一扇门）
## 2) 全图清空 → 走向 Boss 房（楼梯在 Boss 倒下后才落地，必须回去踩）
## 3) 兜底 → 任意开着的门
func autopilot_door_target() -> Vector2:
	var found: Array = _bfs_find(func(c: Vector2i) -> bool:
		var r: Dictionary = dungeon.room(c)
		if not bool(r.get("cleared", false)):
			return true
		# 已炸开的秘密房/超级秘密房也要去一趟（拿奖励）
		var rk: String = String(r.get("kind", ""))
		if (rk == "secret" or rk == "super_secret") and bool(r.get("revealed", false)) \
				and not bool(r.get("visited", false)):
			return true
		return false)
	if found[0] == Vector2i(99, 99):
		found = _bfs_find(func(c: Vector2i) -> bool:
			return String(dungeon.room(c).get("kind", "")) == "boss")
	var goal: Vector2i = found[0]
	var prev: Dictionary = found[1]
	if goal != Vector2i(99, 99):
		var step: Vector2i = goal
		while prev.get(step, dungeon.current) != dungeon.current:
			step = prev[step]
		var dir: Vector2i = step - dungeon.current
		for d in _doors:
			# 目标房还在战斗时门是锁着的，但贴门 1.2 秒的强制过门照样能进，
			# 所以这里不按锁过滤——以前按锁过滤会匹配不上、静默落到兜底，
			# 兜底再挑一扇开着的门，于是自动驾驶在未清房与已清房之间反复横跳（BUG-001 复发）
			if d.dir == dir:
				auto_door_dir = d.dir
				return d.global_position
		if _smoke and not _bfs_warned:
			_bfs_warned = true
			print("[SMOKE-BFS] goal=%s dir=%s 无匹配门 → 落兜底" % [goal, dir])
	for d in _doors:
		if d.locked:
			continue
		var ri: Dictionary = dungeon.room(dungeon.current + d.dir)
		# BUG-001：兜底只走没去过的方向，绝不在已清房间之间反复横跳
		if bool(ri.get("visited", false)):
			continue
		if _smoke and not _bfs_warned:
			_bfs_warned = true
			print("[SMOKE-BFS] fallback pick %s -> %s visited=%s cleared=%s" % [
				d.dir, ri.get("kind", "?"), ri.get("visited", false), ri.get("cleared", false)])
		auto_door_dir = d.dir
		return d.global_position
	auto_door_dir = Vector2i.ZERO
	return Vector2.ZERO


## BFS：只穿过已清房间，返回第一个满足 pred 的房间 → [goal, prev]
func _bfs_find(pred: Callable) -> Array:
	var prev := {dungeon.current: Vector2i(99, 99)}
	var queue: Array[Vector2i] = [dungeon.current]
	while not queue.is_empty():
		var c: Vector2i = queue.pop_front()
		for n in dungeon.neighbors(c):
			if prev.has(n):
				continue
			prev[n] = c
			if pred.call(n):
				return [n, prev]
			queue.append(n)
	return [Vector2i(99, 99), prev]


## 过门后坐标钳制用
func clamp_to_arena(p: Vector2) -> Vector2:
	return Vector2(
		clampf(p.x, 24.0, ARENA_W * TILE - 24.0),
		clampf(p.y, 24.0, ARENA_H * TILE - 24.0))


# ---------------- 竞技场/装饰 ----------------

func _build_arena(coord: Vector2i) -> void:
	# 每个房间重建瓦片层（含门口豁口）；旧门/装饰一并清掉
	for d in _doors:
		if is_instance_valid(d):
			d.queue_free()
	_doors = []
	for n in _room_nodes:
		if is_instance_valid(n):
			n.queue_free()
	_room_nodes = []
	if _floor_layer:
		_floor_layer.queue_free()
	if _wall_layer:
		_wall_layer.queue_free()

	var ts := TileSet.new()
	ts.tile_size = Vector2i(TILE, TILE)
	ts.add_physics_layer(0)
	ts.set_physics_layer_collision_layer(0, 1)
	ts.set_physics_layer_collision_mask(0, 0)
	var src := TileSetAtlasSource.new()
	src.texture = Assets.T_TILES
	src.texture_region_size = Vector2i(TILE, TILE)
	var used: Array[Vector2i] = []
	for c in Assets.TILE_FLOORS:
		used.append(c)
	for c in [HAZARD_COORD, CABLE_COORD, Assets.TILE_TRIM, WALL_COORD, VOID_COORD]:
		used.append(c)
	for c in used:
		src.create_tile(c)
	ts.add_source(src, 0)
	var td := src.get_tile_data(WALL_COORD, 0)
	td.add_collision_polygon(0)
	td.set_collision_polygon_points(0, 0, PackedVector2Array([
		Vector2(-8, -8), Vector2(8, -8), Vector2(8, 8), Vector2(-8, 8)]))

	_floor_layer = TileMapLayer.new()
	_floor_layer.tile_set = ts
	_floor_layer.z_index = -10  # entities 容器先于本层创建，必须压到最底
	_wall_layer = TileMapLayer.new()
	_wall_layer.tile_set = ts
	_wall_layer.z_index = -9
	add_child(_floor_layer)
	add_child(_wall_layer)
	var tint: Color = FLOOR_TINTS[(Game.floor_num - 1) % FLOOR_TINTS.size()]
	_floor_layer.modulate = tint
	_wall_layer.modulate = tint

	# 门位：朝向相邻房间的墙中央开 3 格豁口
	var gaps := {}
	var mid_w := ARENA_W / 2
	var mid_h := ARENA_H / 2
	for d in Dungeon.DIRS:
		if dungeon.has_room(coord + d):
			gaps[d] = true

	for y in ARENA_H:
		for x in ARENA_W:
			var cell := Vector2i(x, y)
			var border := x == 0 or y == 0 or x == ARENA_W - 1 or y == ARENA_H - 1
			if border:
				var skip := false
				if gaps.has(Vector2i(0, -1)) and y == 0 and x >= mid_w - 1 and x <= mid_w + 1:
					skip = true
				if gaps.has(Vector2i(0, 1)) and y == ARENA_H - 1 and x >= mid_w - 1 and x <= mid_w + 1:
					skip = true
				if gaps.has(Vector2i(-1, 0)) and x == 0 and y >= mid_h - 1 and y <= mid_h + 1:
					skip = true
				if gaps.has(Vector2i(1, 0)) and x == ARENA_W - 1 and y >= mid_h - 1 and y <= mid_h + 1:
					skip = true
				if skip:
					continue
				_wall_layer.set_cell(cell, 0, WALL_COORD)
				continue
			var roll := Game.rng.randf()
			if roll < 0.02:
				_floor_layer.set_cell(cell, 0, HAZARD_COORD)
			elif roll < 0.04:
				_floor_layer.set_cell(cell, 0, CABLE_COORD)
			else:
				_floor_layer.set_cell(cell, 0, _pick_floor())

	# 门节点（秘密房未揭示时改成裂纹墙）
	var door_defs := [
		[Vector2i(0, -1), Vector2(mid_w * TILE + 8, 12)],
		[Vector2i(0, 1), Vector2(mid_w * TILE + 8, ARENA_H * TILE - 12)],
		[Vector2i(-1, 0), Vector2(12, mid_h * TILE + 8)],
		[Vector2i(1, 0), Vector2(ARENA_W * TILE - 12, mid_h * TILE + 8)],
	]
	var secret_dirs := {}
	for d in Dungeon.DIRS:
		var nc: Vector2i = coord + d
		if dungeon.has_room(nc):
			var ni: Dictionary = dungeon.room(nc)
			var nk: String = String(ni.get("kind", ""))
			if (nk == "secret" or nk == "super_secret") and not bool(ni.get("revealed", false)):
				secret_dirs[d] = true
	for dd in door_defs:
		if not gaps.has(dd[0]):
			continue
		if secret_dirs.has(dd[0]):
			var wall := SecretWallScript.new()
			wall.dir = dd[0]
			wall.position = dd[1]
			wall.z_index = 30
			add_child(wall)
			_room_nodes.append(wall)
			continue
		var door := DoorScript.new()
		door.dir = dd[0]
		door.position = dd[1]
		door.z_index = 30
		add_child(door)
		_doors.append(door)
		_room_nodes.append(door)

	# 重建（如炸开秘密墙/超级秘密墙）时：清场状态下门必须解锁，否则玩家被关在房里
	# 坑 6：任何新增的重建路径都必须经过这里，禁止绕过或删除
	if room_state == "cleared":
		for d in _doors:
			d.set_locked(false)
		if _smoke:
			for d in _doors:
				Dev.check(not d.locked, "rg6", "重建后门仍上锁 dir=%s" % d.dir)

	# 战斗房随机机柜 + 障碍物
	var info: Dictionary = dungeon.rooms[coord]
	if info["kind"] in ["combat", "elite", "challenge"]:
		for i in 6:
			var crate := CrateScript.new()
			crate.position = _crate_cell_pos()
			entities.add_child(crate)
		_spawn_props()


## 普通/可互动障碍：石柱挡路、爆炸桶、图腾、尖刺
func _spawn_props() -> void:
	var center := _arena_center()
	# 避开正上/正下门口走廊，免得石柱堵住出门路线（12 点位：基础 8 + 藤蔓层备用 4）
	var spots := [
		Vector2(-170, -80), Vector2(170, 80), Vector2(-120, 96), Vector2(120, -96),
		Vector2(-150, -120), Vector2(150, 120), Vector2(-210, 0), Vector2(210, 0),
		Vector2(-80, -176), Vector2(80, 176), Vector2(-240, -80), Vector2(240, -80),
	]
	spots.shuffle()
	var idx := 0
	# 2 根石柱
	for i in 2:
		_spawn_prop("pillar", center + (spots[idx] as Vector2))
		idx += 1
	# 2 个爆炸桶
	for i in 2:
		_spawn_prop("barrel", center + (spots[idx] as Vector2))
		idx += 1
	# 30% 图腾
	if Game.rng.randf() < 0.3:
		_spawn_prop("totem", center + (spots[idx] as Vector2))
		idx += 1
	# 25% 两处尖刺
	if Game.rng.randf() < 0.25:
		for i in 2:
			_spawn_prop("spike", center + (spots[idx] as Vector2) + Vector2(0, i * 100))
			idx += 1
	# 藤蔓层：3 处藤蔓阻挡（全向阻挡，可打掉）
	if _theme_rule == "vines":
		for i in 3:
			_spawn_prop("vine", center + (spots[idx % spots.size()] as Vector2))
			idx += 1


func _spawn_prop(kind: String, pos: Vector2) -> void:
	if _smoke and OS.get_environment("SMOKE_DUMP") != "":
		print("[SMOKE] prop %s at %s" % [kind, pos.round()])
	var p := PropScript.new()
	p.setup(kind)
	p.position = clamp_to_arena(pos)
	entities.add_child(p)


func _pick_floor() -> Vector2i:
	var total := 0
	for w in Assets.TILE_FLOOR_WEIGHTS:
		total += w
	var r := Game.rng.randi_range(0, total - 1)
	for i in Assets.TILE_FLOORS.size():
		r -= Assets.TILE_FLOOR_WEIGHTS[i]
		if r < 0:
			return Assets.TILE_FLOORS[i]
	return Assets.TILE_FLOORS[0]


func _spawn_decor() -> void:
	var corners := [
		Vector2i(1, 1), Vector2i(ARENA_W - 3, 1),
		Vector2i(1, ARENA_H - 3), Vector2i(ARENA_W - 3, ARENA_H - 3),
	]
	for c in corners:
		var a := AnimatedSprite2D.new()
		a.sprite_frames = Assets.alarm_frames()
		a.animation = "blink"
		a.play()
		a.position = Vector2(c * TILE) + Vector2(16, 16)
		a.z_index = -1
		add_child(a)
		_room_nodes.append(a)
	for i in range(6, ARENA_W - 6, 7):
		var s := AnimatedSprite2D.new()
		s.sprite_frames = Assets.screen_frames()
		s.animation = "flicker"
		s.play()
		s.position = Vector2(i * TILE + 16, TILE + 16)
		s.z_index = -1
		add_child(s)
		_room_nodes.append(s)


func _crate_cell_pos() -> Vector2:
	var center := _arena_center()
	for i in 20:
		var cell := Vector2i(Game.rng.randi_range(3, ARENA_W - 4), Game.rng.randi_range(3, ARENA_H - 4))
		var pos := Vector2(cell * TILE) + Vector2(8, 8)
		if pos.distance_to(center) > 5 * TILE:
			return pos
	return Vector2(5, 5) * TILE + Vector2(8, 8)


func _build_fx_layers() -> void:
	var fx_layer := CanvasLayer.new()
	fx_layer.layer = 5
	add_child(fx_layer)
	_fx_rect = ColorRect.new()
	_fx_rect.color = Color(0, 0, 0, 0)
	_fx_rect.set_anchors_preset(Control.PRESET_FULL_RECT)
	_fx_rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
	fx_layer.add_child(_fx_rect)

	var fade_layer := CanvasLayer.new()
	fade_layer.layer = 8
	add_child(fade_layer)
	_fade_rect = ColorRect.new()
	_fade_rect.color = Color(0, 0, 0, 0)
	_fade_rect.set_anchors_preset(Control.PRESET_FULL_RECT)
	_fade_rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
	fade_layer.add_child(_fade_rect)


func _build_camera() -> void:
	camera = Camera2D.new()
	camera.zoom = Vector2(ZOOM, ZOOM)
	camera.limit_left = 0
	camera.limit_top = 0
	camera.limit_right = ARENA_W * TILE
	camera.limit_bottom = ARENA_H * TILE
	camera.position = player.position
	camera.add_child(PCamHost.new())
	add_child(camera)
	camera.make_current()
	_pcam = PCam2D.new()
	_pcam.follow_mode = _pcam.FollowMode.SIMPLE
	_pcam.follow_target = player
	_pcam.follow_damping = false  # 即时跟随：竞技场射击不需要漂移镜头
	_pcam.zoom = Vector2(ZOOM, ZOOM)  # pcam 会接管 Camera2D 的 zoom
	add_child(_pcam)


# ---------------- 出怪/奖励 ----------------

## 出怪前摇：红色火花原地脉冲再落地
func _telegraph_slug(variant: String, pos: Vector2, delay := 0.55, affix := "", defuser := false) -> void:
	_telegraphs += 1
	_room_spawned += 1
	var mark := Sprite2D.new()
	mark.texture = Assets.at(Assets.T_BOOM, Rect2(0, 0, Assets.BOOM_FRAME, Assets.BOOM_FRAME))
	mark.scale = Vector2(0.35, 0.35)
	mark.modulate = Color(1.0, 0.25, 0.2, 0.8)
	mark.position = pos
	mark.z_index = 40
	add_child(mark)
	var tw := mark.create_tween()
	tw.set_loops(int(delay / 0.18))
	tw.tween_property(mark, "scale", Vector2(0.5, 0.5), 0.09)
	tw.tween_property(mark, "scale", Vector2(0.35, 0.35), 0.09)
	Game.safe_delay(delay, self, false, func() -> void:
		if is_instance_valid(mark):
			mark.queue_free()
		if not _game_over:
			spawn_slug(variant, pos, affix, defuser)
		_telegraphs -= 1)


func spawn_slug(variant: String, pos: Vector2, affix := "", defuser := false) -> void:
	var slug := SlugScript.new()
	slug.position = clamp_to_arena(pos)
	entities.add_child(slug)
	slug.setup(variant, 0, Game.floor_num, affix)
	slug.defuser = defuser
	Game.mark_codex("enemies", variant)   # Sprint 13 C：已遇敌人登记（图鉴）
	if _smoke and (String(Data.enemy(variant).get("ai", "")) == "boss" or affix != "" or slug.scale.x > 1.4):
		print("[SMOKE] spawned %s%s%s scale=%.2f" % [variant,
			(" [" + affix + "]") if affix != "" else "",
			" [拆弹]" if defuser else "", slug.scale.x])


func drop_pickup(pos: Vector2, kind: String, value := 1, payload := "") -> void:
	if kind == "diamond" and diamond_mult != 1.0:
		value = maxi(1, int(round(value * diamond_mult)))
	var pk := PickupScript.new()
	pk.kind = kind
	pk.value = value
	pk.payload = payload
	pk.position = clamp_to_arena(pos + Vector2(Game.rng.randf_range(-8, 8), Game.rng.randf_range(-8, 8)))
	entities.add_child(pk)
	if kind == "relic" and payload != "":
		Game.mark_codex("relics", payload)   # Sprint 13 C：已发现遗物登记（图鉴）


func on_slug_killed(slug) -> void:
	Game.sfx("die", Game.fx_rng.randf_range(0.9, 1.15), -6.0)
	Game.register_kill(slug.score_value)
	# Sprint 14 A：Boss 图鉴登记改「codex_id 优先、variant 回退」（§3.1/§3.2）——
	# boss.gd _die 实际会走本回调：守望者 variant="warden" 曾零登记（假阴性）、
	# boss2 variant="boss" 曾误登记巨岩虫之王（假阳性）；专用 id 隔离后两者各归其位
	var cid := String(slug.get("codex_id")) if "codex_id" in slug else ""   # 普通 slug 无此属性（get 返回 null，String(null) 不存在）
	if cid != "":
		Game.mark_codex("bosses", cid)
	elif String(Data.enemy(slug.variant).get("ai", "")) == "boss":
		Game.mark_codex("bosses", slug.variant)
	if Game.combo >= 20:
		_milestone("combo20")
	# 楼层主题「往生脉」：每次击杀额外掉 1 残响
	if _theme_rule == "vein":
		drop_pickup(slug.global_position, "diamond", 1)
	var xp: int = slug.xp_value
	var drops := mini(xp, 8)
	for i in drops:
		drop_pickup(slug.global_position, "diamond", int(ceil(xp / float(drops))))
	# 丰收印记：击杀额外 +1 残响
	if is_instance_valid(player) and player.harvester_active:
		drop_pickup(slug.global_position, "diamond", 1)
	# 回响击败增益：2s 攻速提升（规划 §5.2；数值 Sprint 13 E 提为 Data.ECHO_TUNING）
	if slug.variant == "echo":
		player.buff("echo_rate", float(Data.ECHO_TUNING["buff_mult"]), float(Data.ECHO_TUNING["buff_time"]))
		if _smoke:
			print("[SMOKE-ECHO] echo slain → echo_rate buff 2s")
	# F2/A 反应词缀掉落：精英/Boss 必掉，普通怪 6%（抽取走 Game.rng 掉落循环——
	# 绘制顺序变化为规划草案 §3.4 明示的预期代价，E1 基线随本批重定）
	var suffix_chance := 0.06
	if slug.variant in ["elite", "boss"]:
		suffix_chance = 1.0
	if Game.rng.randf() < suffix_chance:
		var spool: Array = Data.RELIC_SUFFIXES.keys()
		drop_pickup(slug.global_position + Vector2(0, 14), "suffix", 1,
			String(spool[Game.rng.randi_range(0, spool.size() - 1)]))
	# 吸血獠牙
	if player.lifesteal_chance > 0.0 and Game.rng.randf() < player.lifesteal_chance:
		player.heal(1)
	match slug.variant:
		"brute":
			if Game.rng.randf() < 0.10:
				drop_pickup(slug.global_position, "heal")
		"bomber":
			if Game.rng.randf() < 0.15:
				drop_pickup(slug.global_position, "bomb")
		"elite":
			drop_pickup(slug.global_position, "chest")
		"boss":
			drop_pickup(slug.global_position, "chest")
			add_shake(0.8)


# ---------------- 战斗结算 ----------------

func explode(pos: Vector2, radius: float, dmg: float, hurt_player: bool) -> void:
	var ex := ExplosionScript.new()
	ex.position = pos
	ex.scale = Vector2.ONE * (radius / 20.0)
	entities.add_child(ex)
	Game.sfx("boom")
	add_shake(0.55)
	for slug in get_tree().get_nodes_in_group("enemies"):
		if not is_instance_valid(slug) or slug.dead:
			continue
		var d: float = slug.global_position.distance_to(pos)
		if d < radius + 10.0:
			slug.take_damage(dmg * (1.0 - 0.4 * d / radius), (slug.global_position - pos).normalized(), false)
	for crate in get_tree().get_nodes_in_group("crates"):
		if is_instance_valid(crate) and crate.global_position.distance_to(pos) < radius + 6.0:
			crate.crate_take_damage(dmg)
	for wall in get_tree().get_nodes_in_group("secret_walls"):
		if is_instance_valid(wall) and wall.global_position.distance_to(pos) < radius + 14.0:
			wall.bomb_hit()
	if hurt_player and is_instance_valid(player) and not player.dead:
		var pd: float = player.global_position.distance_to(pos)
		if pd < radius + 8.0:
			player.take_damage(2, pos)
			player.apply_blast_push((player.global_position - pos).normalized() * 210.0 * (1.0 - pd / (radius + 8.0)))


func spawn_player_bullet(pos: Vector2, dir: Vector2, speed: float, dmg: float, pierce: int,
		tint: Color, scale_f: float, explosive := 0.0, life := 1.4, bounce := 0, frost := 0.0,
		crit := false, crit_boom := false, homing := false, arc := 0, cluster := 0) -> void:
	var b := BulletScript.new()
	b.setup(pos, dir, speed, dmg, true, tint, scale_f, pierce, explosive, life, bounce, frost,
		crit, crit_boom, homing, arc, cluster)
	entities.add_child(b)


func spawn_enemy_bullet(pos: Vector2, dir: Vector2, speed := 95.0, dmg := 1.0,
		tint := Color(0.8, 0.45, 1.0)) -> void:
	var b := BulletScript.new()
	b.setup(pos, dir, speed, dmg, false, tint, 0.85, 0)
	entities.add_child(b)


func spawn_toxic_cloud(pos: Vector2) -> void:
	var c := ToxicCloudScript.new()
	c.position = pos
	entities.add_child(c)


func spawn_muzzle_spark(pos: Vector2, flip: bool) -> void:
	var ex := ExplosionScript.new()
	ex.setup("spark", 0.5, flip)
	ex.position = pos
	ex.z_index = 45
	entities.add_child(ex)


func spawn_damage_number(pos: Vector2, text: String, crit := false) -> void:
	var l := Label.new()
	l.text = text
	if Assets.font():
		l.add_theme_font_override("font", Assets.font())
	l.add_theme_font_size_override("font_size", 22 if crit else 16)
	l.add_theme_color_override("font_color", Color(1.0, 0.85, 0.3) if crit else Color(1, 1, 1))
	l.add_theme_color_override("font_outline_color", Color(0.1, 0.08, 0.1))
	l.add_theme_constant_override("outline_size", 4)
	l.position = pos + Vector2(-14, -18)
	l.z_index = 60
	add_child(l)
	var tw := l.create_tween()
	tw.set_parallel(true)
	tw.tween_property(l, "position:y", l.position.y - 24.0, 0.5)
	tw.tween_property(l, "modulate:a", 0.0, 0.5).set_ease(Tween.EASE_IN)
	tw.chain().tween_callback(l.queue_free)


# ---------------- 相机/BGM/慢镜 ----------------

func add_shake(amount: float) -> void:
	_trauma = clampf(_trauma + amount, 0.0, 1.0)


func _switch_bgm(track: int, instant := false) -> void:
	if track == _bgm_track:
		return
	_bgm_track = track
	var dur := 0.2 if instant else 1.0
	var cur := _bgm[_bgm_cur]
	var nxt := _bgm[1 - _bgm_cur]
	nxt.stream = Assets.MUSIC[track]
	nxt.volume_db = -80.0
	nxt.play()
	var tw := create_tween()
	tw.set_parallel(true)
	tw.tween_property(nxt, "volume_db", _bgm_target_db(), dur)
	tw.tween_property(cur, "volume_db", -80.0, dur)
	tw.chain().tween_callback(cur.stop)
	_bgm_cur = 1 - _bgm_cur


## BGM 目标音量：基础 -6dB 叠加设置里的 bgm 系数
func _bgm_target_db() -> float:
	return -6.0 + linear_to_db(clampf(float(Game.settings.get("bgm", 0.8)), 0.001, 1.0))


## 设置里改了 BGM 音量时立刻生效
func apply_audio_settings() -> void:
	var target: float = _bgm_target_db()
	var tw := create_tween()
	tw.set_parallel(true)
	for p in _bgm:
		if p.playing:
			tw.tween_property(p, "volume_db", target, 0.15)


## 设置里的精简 HUD 开关
func apply_ui_settings() -> void:
	if hud != null and is_instance_valid(hud):
		hud.set_compact(bool(Game.settings.get("compact_hud", false)))


func slowmo_fx(duration: float) -> void:
	if _fx_rect == null:
		return
	var tw := create_tween()
	tw.tween_property(_fx_rect, "color", Color(0.35, 0.45, 0.8, 0.22), 0.25)
	get_tree().create_timer(duration, false).timeout.connect(func() -> void:
		if is_instance_valid(_fx_rect):
			var tw2 := create_tween()
			tw2.tween_property(_fx_rect, "color", Color(0, 0, 0, 0), 0.6))


# ---------------- 升级/商店/暂停/结束 ----------------

func _on_level_up(level: int) -> void:
	if _game_over:
		return
	Game.sfx("powerup")
	if _smoke:
		print("[SMOKE] level up -> Lv.%d choices" % level)
	# A3 预置档：三流派各 2/3，任意 offered 卡都应显示「再选 1 件集齐」
	if OS.get_environment("SMOKE_SET_PRESET") != "":
		for pid in ["atk", "rate", "bomb", "venom", "speed", "hp"]:
			Upgrades.apply(pid, self)
		Dev.info("a3", "预置流派计数 %s" % str(Upgrades.tag_counts))
	upgrade_panel.show_choices(Upgrades.roll(3))


func _on_upgrade_chosen(id: String) -> void:
	Upgrades.apply(id, self)
	# 残响共鸣核心（mx_resocore）解锁后，共鸣计数源改为残响 → 旧的「拾取升级 +1」不再计入
	if not player.has_resocore:
		add_resonance(1)
	if is_instance_valid(hud):
		hud.refresh_tags()
	if _smoke:
		print("[SMOKE] upgrade picked: ", id)
	Game.sfx("powerup", 1.1)


## ---------------- Sprint 13 A 抉择圣所 ----------------

var _shrine_coord := Vector2i.ZERO   # 当前圣所房坐标（选择回写 cleared 用）
var _shrine_offers: Array = []       # 本圣所房的三卡（stable_hash 派生，见 §4.5）


## 三卡选项集：stable_hash 纯派生（同 seed+同层+同坐标 = 同三选一），零 Game.rng 消费。
## 奖励执行复用既有接口（Relics.roll / Upgrades.roll 属玩家驱动的既有 rng 路径，
## 不新建 rng 流，已登记交付文档 §4.5 口径）
## S32：本层主题的圣所偏好 —— 返回 [[更常…], [更少…]]（id 列表；「更少」允许为空）
## 🔴 载体必须经 Data.theme_for_floor() 派生，禁读 _theme_rule live（探针只改 floor_num、不同步 live）
## 🔴 方向来自主题自己的杠杆（成本相对性 / 伤害的时间形状 / 兑现前提），不是「难就卖强的」
func _shrine_theme_pref() -> Array:
	match String(Data.theme_for_floor(Game.floor_num).get("rule", "")):
		"vein":     return [["ore_upgrade", "ward_boon"], ["greed_pact"]]
		"toxic":    return [["heal"], ["ward_boon"]]
		"pressure": return [["wind_dance"], ["power_surge"]]
		"silent":   return [["purify"], []]
		"magma":    return [["power_surge"], ["heal"]]
		"ice":      return [["ward_boon"], ["wind_dance"]]
		"swamp":    return [["wind_dance"], ["blood_relic"]]
		"vines":    return [["heal"], []]
	return [[], []]


## 表按 id 键存（同 RELIC_SUFFIXES 范式）；流动中的 offer 一律带 id 字段（面板/执行/探针统一）
func _shrine_entry(id: String) -> Dictionary:
	var e: Dictionary = (Data.SHRINE_OFFERS[id] as Dictionary).duplicate()
	e["id"] = id
	return e


func _shrine_offers_for(coord: Vector2i) -> Array:
	var pool: Array = []
	for id in Data.SHRINE_OFFERS:
		var o: Dictionary = Data.SHRINE_OFFERS[id]
		if Game.floor_num < int(o.get("min_floor", 3)):
			continue
		if String(id) == "purify" and _calamity == "":
			continue   # 无灾祸层不出现净化（§4.6）；起点房时序不对称（B4）当前无害的前提：shrine 恒非 Vector2i.ZERO（validate 启动期断言）
		pool.append(_shrine_entry(String(id)))
	if pool.size() < 3:
		return []   # 空池护栏：floor<3 / 过滤后不足三张（房型门槛已挡住正常流程，探针兜底）
	var key := "%d_%d_%d" % [Game.run_seed, Game.floor_num, coord.x * 1000 + coord.y]
	# S32：按本层主题偏好改写「卖哪三张」（不改价格/效果/门槛/派生 key；零 rng，全 stable_hash）
	# 🔴 候选序 = pool 原始声明序（经 min_floor / calamity 过滤后）——硬前置，换序则落卡变、D4 红
	var td: Array = _shrine_theme_pref()
	var pr: Array = []
	for o in pool:
		if td[0].has(String(o["id"])):
			pr.append(o)
	if pr.is_empty():
		# 无偏好（1–3 层 / 偏好被门槛滤掉 / silent 无灾祸）→ 逐字走现行三段抽取
		var picks: Array = []
		var used := {}
		for i in 3:
			var idx: int = Game.stable_hash("%s#%d" % [key, i]) % pool.size()
			while used.has(idx):   # 线性探查取不重复索引（pool >= 3 恒可解）
				idx = (idx + 1) % pool.size()
			used[idx] = true
			picks.append(pool[idx])
		return picks
	else:
		# 三段定向池：p0 取偏好子集（首槽）= 地形可读；p1 排除 p0+down（压低低偏好）；p2 只排 p0/p1（down 靠不进第二槽结构性压低，非永不出现）
		var dn: Array = td[1]
		var p0: Dictionary = pr[Game.stable_hash("%s#0" % key) % pr.size()]
		var c1: Array = []
		for o in pool:
			if String(o["id"]) != String(p0["id"]) and not dn.has(String(o["id"])):
				c1.append(o)
		var p1: Dictionary = c1[Game.stable_hash("%s#1" % key) % c1.size()]
		var c2: Array = []
		for o in pool:
			if String(o["id"]) != String(p0["id"]) and String(o["id"]) != String(p1["id"]):
				c2.append(o)
		var p2: Dictionary = c2[Game.stable_hash("%s#2" % key) % c2.size()]
		return [p0, p1, p2]


## 代价可支付校验（不足 → 卡置灰不可选：防负数 / 防 max_hp 扣死——§4.6）
func _shrine_affordable(offer: Dictionary) -> bool:
	match String(offer.get("cost_kind", "")):
		"diamonds":
			return Game.diamonds >= int(offer["cost"])
		"max_hp":
			return player.max_hp - int(offer["cost"]) >= 1
		"score":
			return Game.score >= int(offer["cost"])
	return true


func _open_shrine(coord: Vector2i) -> void:
	_shrine_coord = coord
	_shrine_offers = _shrine_offers_for(coord)
	if _shrine_offers.is_empty():
		# 核验 #3：空池不发选项不播音效不点里程碑，直接置已清——防「有横幅无面板」死房
		dungeon.rooms[coord]["cleared"] = true
		return
	oath_count("shrine_visits")   # Sprint 16 A：誓约计数（圣所常客/兼修并蓄）
	_milestone("first_shrine")
	Game.sfx("shrine")
	shrine_panel.autopilot = _smoke
	shrine_panel.open(_shrine_offers)
	if _smoke:
		var ids := []
		for o in _shrine_offers:
			ids.append(String(o["id"]))
		print("[SMOKE-SHRINE] floor=%d coord=%s offers=%s" % [Game.floor_num, coord, str(ids)])


## 效果 + 代价执行（探针与面板选择走同一入口；先效果后代价，顺序无 rng 影响）
func _shrine_execute(offer: Dictionary) -> void:
	match String(offer["id"]):
		"blood_relic":
			drop_pickup(_arena_center(), "relic", 1, Relics.roll(1)[0]["id"])
		"ore_upgrade":
			upgrade_panel.show_choices(Upgrades.roll(3))
		"purify":
			# 核验 #1 修复：先条件还原再清空——clear 的 match 需要 _calamity 还在，
			# 先清空会走空分支把 debuff 永久固化（max_hp/弹匣/掉率/敌速）
			_clear_calamity_effects()
			_calamity = ""
			Game.purified_run = true   # S28 批一：代价的单一来源——本局确定放弃 ×1.5
			Game.calamity_floors.erase(Game.floor_num)   # 记录如实；本行不再承担代价（代价见 Game.purified_run）
			oath_count("purify_used")   # Sprint 16 A：净化誓约计数
		"ward_boon":
			player.shield_charges += 1
		"heal":
			player.heal(2)
		"relic_suffix":
			player.attach_suffix(_shrine_suffix_pick())
		# Sprint 15 D：池扩容新增四选项（全部复用既有接口——buff/add_diamonds/add_shards，零 rng）
		"greed_pact":
			Game.add_diamonds(10)
		"wind_dance":
			player.buff("boots", 1.25, 120.0)
		"power_surge":
			player.buff("book", 1.3, 90.0)
		"shard_pact":
			Game.add_shards(6)
	match String(offer.get("cost_kind", "")):
		"diamonds":
			# 核验 #4：spend 只动余额——add_diamonds 负数会倒扣共鸣计数与 earned 统计
			Game.spend(int(offer["cost"]))
		"max_hp":
			player.max_hp = maxi(1, player.max_hp - int(offer["cost"]))
			player.hp = mini(player.hp, player.max_hp)
			player.hp_changed.emit(player.hp, player.max_hp)
		"score":
			Game.add_score(-int(offer["cost"]))


## 铭刻词缀确定性选取（同 key 同词缀——与三卡同源 stable_hash 派生，零 rng）
func _shrine_suffix_pick() -> String:
	var sids: Array = Data.RELIC_SUFFIXES.keys()
	sids.sort()
	var skey := "%d_%d_%d" % [Game.run_seed, Game.floor_num,
		_shrine_coord.x * 1000 + _shrine_coord.y]
	return String(sids[Game.stable_hash("suffix_" + skey) % sids.size()])


func _on_shrine_chosen(index: int) -> void:
	if index < 0 or index >= _shrine_offers.size():
		return
	var offer: Dictionary = _shrine_offers[index]
	if not _shrine_affordable(offer):
		return   # 置灰卡不生效（面板已拦，此处双保险）
	_shrine_execute(offer)
	dungeon.rooms[_shrine_coord]["cleared"] = true   # 重进置 skip_loot，不重复扣/发
	# Sprint 19 A：shrine 第六类发现集——只登记「实际交换过」的选项。
	# 时序：_shrine_affordable() 双保险在前（置灰卡不算），_shrine_execute() 成功返回在后（执行链早退不算）；
	# 与 _echo_choices 同源同序，零新增事件源 / 零 rng / 零计时。纯局外登记，不进 _smoke_fingerprint。
	Game.mark_codex("shrine", String(offer["id"]))
	# Sprint 16 B：抉择链登记（offer 依时间序 + 代价类型分布——只增，局末落 last_run 平行字段）
	_echo_choices.append(String(offer["id"]))
	var ck := String(offer.get("cost_kind", ""))
	_echo_costs[ck] = int(_echo_costs.get(ck, 0)) + 1
	Game.sfx("powerup", 1.1)
	if _smoke:
		print("[SMOKE-SHRINE] chose=%s coord=%s" % [String(offer["id"]), _shrine_coord])


## ---------------- Sprint 16 A/B：地窖誓约 + 抉择回声（只读事件计数 + 局末画像） ----------------

var _oath_counters := {}       # 本局誓约事件计数（只增；键集 = Data.OATH_CONDITIONS watched 并集）
var _echo_choices: Array = []  # B：本局圣所抉择链（offer id 依时间序）
var _echo_costs := {}          # B：代价类型分布 {cost_kind: count}


## 誓约事件计数：既有分支处调用（零 rng、零计时、不调 mark_codex——P0 自激红线）
func oath_count(key: String, n := 1) -> void:
	_oath_counters[key] = int(_oath_counters.get(key, 0)) + n


## 誓约兑现度派生（纯只读）：装备印记 → {id, name, desc, done, cur, need}
## 多条件（watched 多键）取最小计数，全达标才兑现；kills 直接读既有全局计数
## def_override 仅为 SMOKE 负向断言提供测试缝：默认空字典走既有表，
## 既有全部调用（_write_codex_replay / _oath_probe）零参数调用 → 零行为变化。
## Data.OATH_CONDITIONS 是 const（含内嵌 Array 运行时只读，Godot 4.7.2 实测），不能靠探针改表注入。
func oath_fulfillment(def_override: Dictionary = {}) -> Dictionary:
	var equipped: String = String(Game.sigils.get("equipped", ""))
	var def: Dictionary = def_override if not def_override.is_empty() else Data.OATH_CONDITIONS.get(equipped, {})
	if def.is_empty():
		return {}
	# Sprint 17 A2：空 watched 早退——原 cur := 999 会使 done = 999 >= need 恒真。
	# validate 启动期已挡空 watched（无实害），此处补运行期防线；正常数据下零行为变化。
	if (def["watched"] as Array).is_empty():
		return {}
	var cur := 999
	for w in def["watched"]:
		var v: int = Game.kills if String(w) == "kills" else int(_oath_counters.get(String(w), 0))
		cur = mini(cur, v)
	var need: int = int(def["need"])
	return {"id": equipped, "name": String(def["name"]), "desc": String(def["desc"]),
		"done": cur >= need, "cur": cur, "need": need}


## 抉择回声标签：按主导代价类型派生（六道卷的克制口吻）
func _echo_tag() -> String:
	if _echo_choices.is_empty():
		return "未入圣所"
	var best_k := ""
	var best_n := -1
	for k in _echo_costs:
		if int(_echo_costs[k]) > best_n:
			best_n = int(_echo_costs[k])
			best_k = String(k)
	match best_k:
		"max_hp":
			return "血偿流"
		"diamonds":
			return "散财流"
		"score":
			return "功勋流"
	return "实用流"


## A/B 平行字段落盘：写入 codex["last_run"] 的 oath / echo 键并再存一次盘。
## 不改 set_codex_last_run 本体、不扩 STATS_KEYS（字段若塞进 stats 会被其白名单静默丢弃——§2.3）
## Sprint 23 B：可选参数 prev_streak——>=0 时连绩写回（f(S,H,D) 三态，H/D 取自**本次刚写回的**
## last_run["oath"]，与 oath 同一次落盘防撕裂 T3）；**-1 哨兵跳过连绩写入**——player.gd 无参直调
## 零回归、SMOKE 隔离档不污染。注意陷阱：oath_streak 塞进 stats 会被 set_codex_last_run 的
## STATS_KEYS 白名单静默丢弃（n3 实证），故只能走本函数的平行字段
func _write_codex_replay(prev_streak := -1) -> void:
	var echo := {"choices": _echo_choices.duplicate(), "costs": _echo_costs.duplicate(),
		"tag": _echo_tag(), "count": _echo_choices.size()}
	Game.codex["last_run"]["oath"] = oath_fulfillment()
	Game.codex["last_run"]["echo"] = echo
	if prev_streak >= 0:
		var o: Dictionary = Game.codex["last_run"]["oath"]
		var H := 0 if o.is_empty() else 1
		var D := 1 if (H == 1 and bool(o.get("done", false))) else 0
		Game.codex["last_run"]["oath_streak"] = next_oath_streak(prev_streak, H, D)
	Game.save_codex()


## Sprint 23 B：连绩读侧（纯读内存态 last_run，零 IO/零 rng/零计时）——
## 旧档无键 → .get 默认 0；坏档非数值 → 类型守卫归 0（实稿三道防线，不迁移不补写不改 load_codex）
func _read_oath_streak() -> int:
	var v = Game.codex["last_run"].get("oath_streak", 0)
	if v is int or v is float:
		return maxi(int(v), 0)
	return 0


## Sprint 23 B：连绩状态转移 f（纯函数 static，零全局态读取——实稿 §一 1.2）
## f(S,H,D) = S+1 若 H=1 且 D=1（兑现续一局）；= 0 若 H=1 且 D=0（立誓未兑现 → 断）；
## = S 若 H=0（未立誓不计入、不断绩——§七① 拍板）
static func next_oath_streak(prev: int, H: int, D: int) -> int:
	if H == 0:
		return prev
	return prev + 1 if D == 1 else 0


## Sprint 27 批二：连绩档位 → 开局残响回流值（纯函数，零全局读取，零 rng）
## 封顶 8 < 12（共鸣契约价）：回流单靠自己换不到契约，必须继续打。
static func _oath_grant_amount(s: int) -> int:
	if s <= 0:
		return 0
	if s == 1:
		return 3
	if s == 2:
		return 5
	return 8


## Sprint 27 批二：誓约遗赠——把上一局的连兑现折成本局开局残响。
## 载体只能是 Game.diamonds 直写：走既有发放接口会污染 run_diamonds_earned /
## diamonds_picked（自激「满载而归」）/ _reso_pickups（白送共鸣），三条实读确认。
## 零 rng、零计时、零新实体。daily 模式一律不发（榜单可比性）。
func _oath_grant() -> void:
	if Game.daily_mode:
		return
	# 🔴 上局未立誓 → 不发。streak 在 H=0 时永不衰减（next_oath_streak 既定语义），
	# 若不守这一条，玩家达成 S=3 后「永不再装印记」即可每局白拿 +8 且零风险 → 单向棘轮。
	if (Game.codex["last_run"].get("oath", {}) as Dictionary).is_empty():
		return
	var s := _read_oath_streak()   # 只读一次，档位与文案共用（C08 静态门：读侧恰 3 行）
	var n := _oath_grant_amount(s)
	if n <= 0:
		return
	Game.diamonds += n
	Game.diamonds_changed.emit(Game.diamonds)
	if is_instance_valid(hud):
		hud.flash_toast("%s · 连兑现 %d 局，开局残响 +%d" % [_OG_TOAST_TAG, s, n])


## ---------------- Sprint 14 C：图鉴发现度被动（开局一次性起始状态） ----------------

## 落地 boons：shield/diamonds/max_hp/suffix 四类一次性增量。
## 载体硬约束（§5.4）：禁用 diamond_mult 等全局倍率——_roll_modifier/_roll_calamity/
## 换层 clear 会重置它们（Sprint 12 #2 实害教训）；本函数零 rng、零计时
func _apply_codex_boons() -> void:
	var boons: Dictionary = Game.codex_boons()
	if boons.is_empty():
		return
	for id in boons:
		var b: Dictionary = boons[id]
		match String(b["effect"]):
			"shield":
				player.shield_charges += int(b["value"])
			"diamonds":
				Game.add_diamonds(int(b["value"]))
			"max_hp":
				player.max_hp += int(b["value"])
				player.hp = mini(player.hp + int(b["value"]), player.max_hp)
				player.hp_changed.emit(player.hp, player.max_hp)
			"suffix":
				player.attach_suffix(_codex_boon_suffix())
	# S29：发现度改写深渊起点——档数 1:1 折射为开局环盾，仅深渊局生效。
	# 零 rng：codex_boons() 只读派生、tier 为菜单预置，落点在 run_seed 之前。
	if abyss_tier > 0:
		player.shield_charges += boons.size()
	if _smoke:
		print("[SMOKE-CODEX-BOON] applied: %s" % str(boons.keys()))


## 铭刻词缀稳定派生：由图鉴发现集拼 key 走 stable_hash（同档同词缀，零 rng）
func _codex_boon_suffix() -> String:
	var sids: Array = Data.RELIC_SUFFIXES.keys()
	sids.sort()
	var key := ""
	for k in Game.CODEX_KINDS:
		# Sprint 19 §九-1：跳过 shrine —— 本批只加「发现集」这一层关系，不得让 shrine 发现度
		# 改变既有 boon 的开局铭刻词缀派生（否则老档 key 平白多 "shrine=|" → 跨版本基线漂移）。
		# 图鉴档是局外输入，该漂移不属 E1 违规，但属无意的既得结果变化，主动切断。
		if String(k) == "shrine":
			continue
		key += "%s=%s|" % [String(k), ",".join(Game.codex[k])]
	return String(sids[Game.stable_hash(key) % sids.size()])


func give_player_weapon(id: String) -> void:
	player.give_weapon(id)
	hud.flash_toast("获得 %s（Q 切换）" % Weapons.DEFS[id]["name"])
	Game.sfx("secret")


func give_player_relic(id: String) -> void:
	Relics.apply(id, self)
	# 同上：mx_resocore 解锁后共鸣只由残响计数
	if not player.has_resocore:
		add_resonance(1)
	_milestone("first_relic")
	var r: Dictionary = Relics.by_id(id)
	hud.flash_toast("遗物：%s — %s" % [r["name"], r["desc"]])
	Game.sfx("powerup", 1.15)


## SMOKE：发现相邻未揭示秘密房/超级秘密房就逐帧逐个炸开（走真实 explode→bomb_hit→reveal 链路）
func _smoke_secret_tick() -> void:
	if _smoke and OS.get_environment("SMOKE_DUMP") != "" and _smoke_frame % 180 == 0:
		print("[SMOKE-DOORS] props=%d n=%d %s state=%s pos=%s" % [get_tree().get_nodes_in_group("props").size(), _doors.size(),
			_doors.map(func(d): return [d.dir, d.locked]), room_state, player.global_position.round()])
	if not _smoke or dungeon == null:
		return
	if room_state != "cleared" or _transitioning:
		return
	for dir in Dungeon.DIRS:
		var nc: Vector2i = dungeon.current + dir
		if not dungeon.rooms.has(nc):
			continue
		var r: Dictionary = dungeon.room(nc)
		var rk: String = String(r.get("kind", ""))
		# 一帧只炸一面墙：reveal_secret 会重建房间，同帧连炸会产生重复门节点
		if (rk == "secret" or rk == "super_secret") and not bool(r.get("revealed", false)) \
				and not _secret_bombed_dirs.has(dir):
			_secret_bombed_dirs[dir] = true
			var pos := Vector2(ARENA_W * TILE * 0.5, 12)
			match dir:
				Vector2i(0, 1): pos = Vector2(ARENA_W * TILE * 0.5, ARENA_H * TILE - 12)
				Vector2i(-1, 0): pos = Vector2(12, ARENA_H * TILE * 0.5)
				Vector2i(1, 0): pos = Vector2(ARENA_W * TILE - 12, ARENA_H * TILE * 0.5)
			explode(pos, 58.0, 3.0, false)
			print("[SMOKE] bombed secret wall dir=", dir, " kind=", rk)
			return


func _smoke_shop_tick() -> void:
	if not _smoke or _shop_bought:
		return
	if dungeon and dungeon.room(dungeon.current).get("kind") == "shop" and Game.time > 2.0:
		for c in entities.get_children():
			if c is ShopStand and not c.sold:
				c._try_buy()
				_shop_bought = true
				print("[SMOKE] bought shop item: ", c.kind)
				break


func toggle_pause() -> void:
	if upgrade_panel.visible or _game_over or _transitioning:
		return
	var p := not get_tree().paused
	get_tree().paused = p
	hud.set_paused(p)
	if menu != null and not _smoke:
		menu.show_page("pause" if p else "")


## 回主菜单：重载场景，新场景的菜单层会显示主菜单
## 主动退出 = 弃局：不结算，但引导加成照常递减（§10.3）
func to_main_menu() -> void:
	if OS.get_environment("SMOKE_META_QUIT") != "":
		print("[SMOKE-META] quit estimate=%d reason=%s" % [quit_estimate(), "confirm"])
	get_tree().paused = false
	_tick_boost_once()
	get_tree().reload_current_scene()


func _on_player_died() -> void:
	if _game_over:
		return
	_game_over = true
	Game.playing = false
	Game.sfx("player_die")
	add_shake(0.9)
	# 结算必须在任何 Game.reset() 之前取数：reset 只发生在 _ready / SMOKE 定时器 / restart
	var settle_text := _settle_meta()
	hud.game_over(settle_text)
	if _smoke:
		print("[SMOKE] player died — floor=%d kills=%d t=%.1f" % [Game.floor_num, Game.kills, Game.time])
		Game.safe_delay(1.0, self, false, func() -> void: Game.reset(); get_tree().reload_current_scene())


## 本局结算统计（死亡结算与「主动退出预计损失」共用同一份口径）
func _run_stats() -> Dictionary:
	var stats := {
		"diamonds": Game.run_diamonds_earned, "kills": Game.kills,
		"max_floor": Game.max_floor, "time": Game.time, "score": Game.score,
	}
	var override := OS.get_environment("SMOKE_META_SETTLE_STATS")
	if override != "":
		for part in override.split(","):
			var kv := String(part).split("=")
			if kv.size() != 2:
				continue
			var k := String(kv[0]).strip_edges()
			var v := String(kv[1]).strip_edges()
			match k:
				"diamonds": stats["diamonds"] = int(v)
				"kills": stats["kills"] = int(v)
				"max_floor": stats["max_floor"] = int(v)
				"time": stats["time"] = float(v)
				"score": stats["score"] = int(v)
		print("[SMOKE-META-EXTRA] settle stats overridden=%s" % override)
	return stats


## 主动退出确认框显示的「本局将损失约 N 结晶」；与 §3.1 经济公式同源
func quit_estimate() -> int:
	return Meta.payout(_run_stats())


## 一局只递减一次引导加成：死亡结算里已递减，回主菜单 / 重开不得再减一次
func _tick_boost_once() -> void:
	if _boost_ticked:
		return
	_boost_ticked = true
	Game.meta_boost_tick()


## E8″ 受控计数探针：固定次数调用三个抽卡入口，两档（默认 / all）计数必须逐字相同
func _smoke_rngcount_probe() -> void:
	Upgrades.rng_draws = 0
	Relics.rng_draws = 0
	Weapons.rng_draws = 0
	for i in 20:
		Upgrades.roll(3)
		Relics.roll(2)
		Weapons.random_unlocked()
	print("[SMOKE-META-EXTRA] rng count upgrades=%d relics=%d weapons=%d" % [
		Upgrades.rng_draws, Relics.rng_draws, Weapons.rng_draws])


## 局末结算：把本局累计拾取折算成结晶（一次性，幂等）
## 返回给结算屏显示的文案（空串 = 不显示）
func _settle_meta() -> String:
	if _run_settled:
		return ""
	_run_settled = true
	var picked := Game.run_diamonds_earned
	var floor_num := Game.max_floor   # 用「到达过的最深层」，不是死亡时的当前层
	var kills := Game.kills
	# SMOKE 下默认不结算（反复死亡会把隔离档刷爆，也让回归基线不可复现）；
	# 需要验证结算链路时用 SMOKE_META_SETTLE=1 显式开启
	if _smoke and OS.get_environment("SMOKE_META_SETTLE") == "":
		print("[SMOKE-META-EXTRA] settle skipped picked=%d floor=%d kills=%d" % [picked, floor_num, kills])
		return ""
	# 地窖印记 shards 结算（Sprint 11 C）：floor(cleared × META_RATE)，纯确定性无 rng
	var shard_gain := Game.settle_shards(Game.max_floor)
	# D 每日挑战：记录当日最佳（层数优先，同层比时间）
	if Game.daily_mode:
		Game.record_daily_best(Game.max_floor, Game.time)
	if _smoke:
		print("[SMOKE-SIGIL] shards +%d balance=%d" % [shard_gain, int(Game.sigils["shards"])])
	var stats := _run_stats()
	# Sprint 23 (B)：覆盖前连绩快照——纯读内存态（零 IO/零 rng），必须在覆盖式 set_codex_last_run
	# 抹掉 last_run 之前读（代价 1 实测：stats 只有 5 个 STATS_KEYS 键，oath_streak 塞进 stats
	# 会被白名单静默丢弃——实稿 §五 V3/n3）
	var prev_streak := _read_oath_streak()
	Game.set_codex_last_run(stats)   # Sprint 13 C：上局复盘快照（codex.cfg 持久化）
	_write_codex_replay(prev_streak)   # Sprint 16 A/B + 23 B：誓约+抉择+连绩同一次写盘（防撕裂 T3；两次写盘为既定代价）
	var r := Game.meta_settle_run(stats)
	_boost_ticked = true   # meta_settle_run 内部已递减一次引导加成
	var pay := int(r.get("payout", 0))
	var balance := int(r.get("crystals", 0))
	Dev.info("meta", "局末结算 +%d 结晶（累计拾取 %d / 第 %d 层 / %d 击杀），余额 %d" % [
		pay, picked, floor_num, kills, balance])
	if _smoke:
		print("[SMOKE-META] settle payout=%d balance=%d picked=%d floor=%d kills=%d" % [
			pay, balance, picked, floor_num, kills])
	if pay <= 0:
		return ""
	return "本局结算  +%d 结晶   ·   余额 %d" % [pay, balance]


func restart() -> void:
	_tick_boost_once()
	Game.reset()
	get_tree().paused = false
	get_tree().reload_current_scene()


## SMOKE 调试：全树贴图清单（找可疑/缺图）
func _dump_entities() -> void:
	var prop_counts := {}
	for p in get_tree().get_nodes_in_group("props"):
		prop_counts[p.kind] = int(prop_counts.get(p.kind, 0)) + 1
	print("[DUMP] props: ", prop_counts)
	print("[DUMP] ---- 全树贴图 ----")
	_scan_all(get_tree().root, 0)


func _scan_all(n: Node, depth: int) -> void:
	if depth > 6:
		return
	if n is Sprite2D:
		var t: Texture2D = n.texture
		var info := "<NULL>"
		if t is AtlasTexture:
			info = "atlas=%s region=%s" % [t.atlas.resource_path if t.atlas else "NULL", t.region]
		elif t != null:
			info = t.resource_path
		print("[DUMP] S %s pos=%s scale=%s mod=%s %s" % [n.get_parent().get_class(), n.global_position.round(), n.scale, n.modulate, info])
	elif n is AnimatedSprite2D:
		var sf: SpriteFrames = n.sprite_frames
		print("[DUMP] A %s pos=%s scale=%s anim=%s frames=%s" % [
			n.get_parent().get_class(), n.global_position.round(), n.scale, n.animation,
			(sf.get_frame_count(n.animation) if sf else "NULL")])
	for c in n.get_children():
		_scan_all(c, depth + 1)


## ============================================================================
## Sprint 27 批二 探针：誓约遗赠（SMOKE_OATH_GRANT=1）
## 43 条断言，declared 字面量 43。每条后无条件打印 #NN + 实测值。
## 唯一授予入口 _og_grant()：内部经字符串 call，故全仓授予符号的
## 带括号字面调用点仍恰 1 处（start_run 内那行）——C08 静态门依赖这一点。
## 🔴 本段代码内一律只写 `_oath_grant`（不带括号）；带括号的字面量只由 _OG_SYM_GRANT 拼接产生，
##    否则 C08 全仓扫描会把探针自己的注释/字符串数进去 → 读成 2+ 而假红。
## 本条探针绝不写盘：不调 Game.save_codex() / set_codex_last_run()。
## ============================================================================

const _OG_DECLARED := 43
const _OG_SENTINEL := "__OG_SENTINEL__"
const _OG_PLAIN_SEED := 12345      # 实测该 seed 不走 barren（口径 §0.4 实验 D：默认档开局 3）
const _OG_E2E_SEED := 777          # 实测该 seed 掷出 modifier=barren（口径 §0.4 实验 E：13）

var _og_checked := 0
var _og_sig_cnt := 0               # diamonds_changed 触发次数
var _og_sig_last := -999999        # 末次实参
var _og_wire_fail := 0             # 探针是否接上授予函数（字符串 call 无静态检查，必须运行期自证）
var _og_src: PackedStringArray = []   # game_main.gd 源码行（C08/E04/E05 用）
var _og_body := Vector2i(-1, -1)      # start_run 函数体 [首行, 末行]（1-based）；E04/E05 只在此范围定位
var _og_snap := {}

const _OG_SYM_GRANT := "_oath" + "_grant()"   # 值即授予符号的带括号形式，但源码里不构成字面调用
const _OG_TAG := "誓约遗赠"          # 必须等于生产常量 _OG_TOAST_TAG 的字面值


func _test_oath_grant() -> void:
	_og_snap = _og_snapshot()
	_og_load_src()
	Game.diamonds_changed.connect(_og_on_diamonds)
	print("[SMOKE-OATH-GRANT] entry diamonds=%d last_run_oath=%s streak=%s daily=%s has_grant=%s has_amount=%s" % [
		Game.diamonds,
		"empty" if (Game.codex["last_run"].get("oath", {}) as Dictionary).is_empty() else "nonempty",
		str(Game.codex["last_run"].get("oath_streak", "<none>")),
		str(Game.daily_mode),
		str(has_method("_oath_grant")), str(has_method("_oath_grant_amount"))])
	if not has_method("_oath_grant") or not has_method("_oath_grant_amount"):
		print("[SMOKE-OATH-GRANT] FATAL 授予函数不存在 → 43 条全部 measured=MISSING 且 ok=false")
	_og_group_a()
	_og_group_b()
	_og_group_c()
	_og_group_g()
	_og_group_d()
	_og_group_f()
	_og_group_e()          # 🔴 必须最后
	Game.diamonds_changed.disconnect(_og_on_diamonds)
	_og_restore()
	Dev.check(_og_checked == _OG_DECLARED, "oath_grant",
		"自校验失败: checked(%d) != declared(%d)" % [_og_checked, _OG_DECLARED])
	Dev.check(_og_wire_fail == 0, "oath_grant",
		"探针未接上授予函数：字符串 call 无静态检查，_oath_grant 不存在或名字写错（wire_fail=%d）" % _og_wire_fail)
	print("[SMOKE-OATH-GRANT] done checked=%d declared=%d" % [_og_checked, _OG_DECLARED])


# ---------------------------------------------------------------- 基础设施

func _og_on_diamonds(n: int) -> void:
	_og_sig_cnt += 1
	_og_sig_last = n


func _og_sig_reset() -> void:
	_og_sig_cnt = 0
	_og_sig_last = -999999


## 每条断言唯一出口：先计数、再 Dev.check、最后无条件 print（顺序不许换）
func _og_assert(ok: bool, nn: String, what: String, measured, expect) -> void:
	_og_checked += 1
	var msg := "%s %s | measured=%s expect=%s" % [nn, what, str(measured), str(expect)]
	Dev.check(ok, "oath_grant", msg)
	print("[SMOKE-OATH-GRANT] #%02d %s measured=%s expect=%s ok=%s" % [
		_og_checked, nn + " " + what, str(measured), str(expect), str(ok)])


## 唯一授予漏斗：探针不许直接写授予符号的带括号字面调用（C08 全仓只许 1 处）
## 🔴 字符串 call 绕过静态检查，函数名写错只在运行期炸 → 必须 has_method 硬检查，不成立判红、不许静默
func _og_grant() -> void:
	if not has_method("_oath_grant"):
		_og_wire_fail += 1
		print("[SMOKE-OATH-GRANT] wire_fail 探针未接上授予函数（字符串 call 无此方法）")
		return
	call(&"_oath_grant")


func _og_amount(s: int) -> int:
	if not has_method("_oath_grant_amount"):
		return -9999
	return _oath_grant_amount(s)


func _og_oath_ne() -> Dictionary:
	# oath 非空：B01-B06/B08-B10、C、D、E 全部用它，把「未立誓」这一维留给 B07 独占
	return {"id": "untouched", "name": "不受伤", "desc": "probe",
		"done": true, "cur": 9, "need": 9}


func _og_set_last_run(oath: Dictionary, streak, with_key: bool) -> void:
	var lr: Dictionary = Game.codex["last_run"]
	lr["oath"] = oath.duplicate(true)
	if with_key:
		lr["oath_streak"] = streak
	else:
		lr.erase("oath_streak")
	Game.codex["last_run"] = lr


## 拉平基线：三通道 + 信号计数 + 哨兵文本。绝不调 _roll_modifier/Data.roll_modifier（抽 rng 撞 F 组）
func _og_flat(baseline: int = 0) -> void:
	Game.diamonds = baseline
	Game.run_diamonds_earned = 0
	_oath_counters.clear()
	Game._reso_pickups = 0
	resonance = 0
	Game.daily_mode = false
	if is_instance_valid(hud):
		hud._toast.text = _OG_SENTINEL
	_og_sig_reset()


func _og_toast() -> String:
	return hud._toast.text if is_instance_valid(hud) else "<no-hud>"


func _og_label() -> String:
	return hud._diamond_label.text if is_instance_valid(hud) else "<no-hud>"


## 只取标签里的数字串——本批 HUD 写法是纯 str(n)（hud.gd:300），按「文本是否等于 str(n)」判，
## 取不到就打印原文，由核验方看清是格式问题还是数值问题。
func _og_label_num() -> String:
	var t := _og_label()
	var digits := ""
	for i in t.length():
		var c := t[i]
		if c >= "0" and c <= "9":
			digits += c
		elif digits != "":
			break
	return digits if digits != "" else t


# ---------------------------------------------------------------- A 组（9，纯函数）

func _og_group_a() -> void:
	_og_assert(_og_amount(0) == 0, "A01", "amount(0)=0", _og_amount(0), 0)
	_og_assert(_og_amount(1) == 3, "A02", "amount(1)=3", _og_amount(1), 3)
	_og_assert(_og_amount(2) == 5, "A03", "amount(2)=5", _og_amount(2), 5)
	_og_assert(_og_amount(3) == 8, "A04", "amount(3)=8", _og_amount(3), 8)
	_og_assert(_og_amount(4) == 8, "A05", "amount(4)=8", _og_amount(4), 8)
	_og_assert(_og_amount(99) == 8, "A06", "amount(99)=8", _og_amount(99), 8)
	_og_assert(_og_amount(-1) == 0, "A07", "amount(-1)=0", _og_amount(-1), 0)
	# A08：13 点手写期望（禁公式）。旁证行不带 #NN
	var pts := [-2, -1, 0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10]
	var want := [0, 0, 0, 3, 5, 8, 8, 8, 8, 8, 8, 8, 8]
	var bad := 0
	var got_line: Array = []
	for i in pts.size():
		var got := _og_amount(int(pts[i]))
		got_line.append("s=%d→%d" % [int(pts[i]), got])
		if got != int(want[i]):
			bad += 1
	print("[SMOKE-OATH-GRANT] a08 detail: %s" % " ".join(got_line))
	_og_assert(bad == 0, "A08", "13 点逐点全等", "%d 点错" % bad, "0 点错")
	# A09：去重集合恰 {0,3,5,8}
	var seen := {}
	for s in range(-2, 13):
		seen[_og_amount(int(s))] = true
	var keys := seen.keys()
	keys.sort()
	var set_ok := keys.size() == 4 and keys.has(0) and keys.has(3) and keys.has(5) and keys.has(8)
	print("[SMOKE-OATH-GRANT] a09 detail: distinct=%s" % str(keys))
	_og_assert(set_ok, "A09", "取值集合=={0,3,5,8}", str(keys), "[0, 3, 5, 8]")


# ---------------------------------------------------------------- B 组（10，基线探针手工置）

func _og_group_b() -> void:
	# B01 无 oath_streak 键（oath 非空！）
	_og_flat(0); _og_set_last_run(_og_oath_ne(), 0, false); _og_grant()
	_og_assert(Game.diamonds == 0, "B01", "无 streak 键→不发", Game.diamonds, 0)
	# B02 字符串 "3"
	_og_flat(0); _og_set_last_run(_og_oath_ne(), "3", true); _og_grant()
	print("[SMOKE-OATH-GRANT] b02 detail: naive_int=%d (必须 3，用来证明不能用朴素 int())" % int("3"))
	_og_assert(Game.diamonds == 0, "B02", "streak=\"3\"→不发", Game.diamonds, 0)
	# B03 float 2.9 → 截断 2 → +5
	_og_flat(0); _og_set_last_run(_og_oath_ne(), 2.9, true); _og_grant()
	_og_assert(Game.diamonds == 5, "B03", "streak=2.9→+5", Game.diamonds, 5)
	# B04 bool true
	_og_flat(0); _og_set_last_run(_og_oath_ne(), true, true); _og_grant()
	_og_assert(Game.diamonds == 0, "B04", "streak=true→不发", Game.diamonds, 0)
	# B05 负数
	_og_flat(0); _og_set_last_run(_og_oath_ne(), -5, true); _og_grant()
	_og_assert(Game.diamonds == 0, "B05", "streak=-5→不发", Game.diamonds, 0)
	# B06 null
	_og_flat(0); _og_set_last_run(_og_oath_ne(), null, true); _og_grant()
	_og_assert(Game.diamonds == 0, "B06", "streak=null→不发", Game.diamonds, 0)
	# B07 🔴 棘轮：oath 缺键 + streak=3 → 必须 0
	_og_flat(0); _og_set_last_run({}, 3, true); _og_grant()
	_og_assert(Game.diamonds == 0, "B07", "oath 空+streak3→不发(棘轮)", Game.diamonds, 0)
	# B08 oath 非空 + streak=0 → 0 且不扣成负
	_og_flat(7); _og_set_last_run(_og_oath_ne(), 0, true); _og_grant()
	_og_assert(Game.diamonds == 7 and Game.diamonds >= 0, "B08",
		"未兑现→0 且不扣负", Game.diamonds, "7 且 >=0")
	# B09 基线 7 + streak 3 → 15（唯一抓覆盖式写法）
	_og_flat(7); _og_set_last_run(_og_oath_ne(), 3, true); _og_grant()
	_og_assert(Game.diamonds == 15, "B09", "7+8=15 叠加非覆盖", Game.diamonds, 15)
	# B10 purse 真实路径：X / Y 差值
	var x10 := _og_purse_case(0)
	var y10 := _og_purse_case(3)
	print("[SMOKE-OATH-GRANT] b10 detail: X=%d Y=%d" % [x10, y10])
	_og_assert(y10 - x10 == 8 and x10 >= 15, "B10", "purse Δ=8 且 X>=15",
		"X=%d Y=%d Δ=%d" % [x10, y10, y10 - x10], "X>=15 且 Δ=8")


## purse 真实路径（走 _apply_sigil_contract，不是手工置 15）
func _og_purse_case(streak: int) -> int:
	Game.sigils["equipped"] = "purse"
	_og_flat(0)
	_apply_sigil_contract()                      # ← 真实分支：Game.diamonds = 15
	_og_set_last_run(_og_oath_ne(), streak, true)
	_og_grant()
	return Game.diamonds


# ---------------------------------------------------------------- C 组（9）

func _og_group_c() -> void:
	# C01 信号：次数 + 末次实参（只断信号侧；HUD 侧由 G01 单独断）
	_og_flat(7); _og_set_last_run(_og_oath_ne(), 3, true); _og_grant()
	print("[SMOKE-OATH-GRANT] c01 detail: sigcnt=%d lastarg=%d diamonds=%d" % [
		_og_sig_cnt, _og_sig_last, Game.diamonds])
	_og_assert(_og_sig_cnt >= 1 and _og_sig_last == Game.diamonds, "C01",
		"信号触发且末参==总值", "cnt=%d last=%d d=%d" % [_og_sig_cnt, _og_sig_last, Game.diamonds], "cnt>=1 last==d")
	# C02 run_diamonds_earned Δ
	_og_flat(0); _og_set_last_run(_og_oath_ne(), 3, true)
	var e0 := Game.run_diamonds_earned
	_og_grant()
	_og_assert(Game.run_diamonds_earned - e0 == 0, "C02", "run_diamonds_earned Δ=0",
		Game.run_diamonds_earned - e0, 0)
	# C03 diamonds_picked Δ
	_og_flat(0); _og_set_last_run(_og_oath_ne(), 3, true)
	var o0: int = int(_oath_counters.get("diamonds_picked", 0))
	_og_grant()
	var o1: int = int(_oath_counters.get("diamonds_picked", 0))
	_og_assert(o1 - o0 == 0, "C03", "diamonds_picked Δ=0", o1 - o0, 0)
	# C04 _reso_pickups Δ + resonance Δ（has_resocore=true 才触发该通路）
	var keep_core: bool = player.has_resocore
	player.has_resocore = true
	_og_flat(0); _og_set_last_run(_og_oath_ne(), 3, true)
	var rp0 := Game._reso_pickups
	var rs0 := resonance
	_og_grant()
	var rp1 := Game._reso_pickups
	var rs1 := resonance
	player.has_resocore = keep_core
	_og_assert(rp1 - rp0 == 0 and rs1 - rs0 == 0, "C04", "_reso_pickups Δ=0 且 resonance Δ=0",
		"resoΔ=%d resonanceΔ=%d" % [rp1 - rp0, rs1 - rs0], "0 且 0")
	# C05 daily=true → 不发、无 toast
	_og_flat(7); _og_set_last_run(_og_oath_ne(), 3, true)
	Game.daily_mode = true
	_og_grant()
	var d05 := Game.diamonds
	var t05 := _og_toast()
	Game.daily_mode = false
	_og_assert(d05 == 7 and t05 == _OG_SENTINEL, "C05", "daily 不发且无 toast",
		"d=%d toast=%s" % [d05, t05], "d=7 toast=" + _OG_SENTINEL)
	# C06 daily=false → 正常发
	_og_flat(7); _og_set_last_run(_og_oath_ne(), 3, true); _og_grant()
	_og_assert(Game.diamonds == 15, "C06", "daily=false 正常 +8", Game.diamonds, 15)
	# C07 两次完整 start_run 幂等（rng seed+state 双还原；本批唯一未实测项，飘了如实报）
	var r := _og_e2e_raw(3, "", _OG_E2E_SEED)
	var r2 := _og_e2e_raw(3, "", _OG_E2E_SEED)
	print("[SMOKE-OATH-GRANT] c07 detail: run1=%d run2=%d" % [int(r["diamonds"]), int(r2["diamonds"])])
	_og_assert(int(r["diamonds"]) == int(r2["diamonds"]), "C07", "两次 start_run 残响相同",
		"%d vs %d" % [int(r["diamonds"]), int(r2["diamonds"])], "相等")
	# C08 静态门：字面调用点恰 1（排除 func/static func 定义行；词边界防 _test_oath_grant 自命中）
	var call_lines := _og_grant_call_lines()
	print("[SMOKE-OATH-GRANT] c08 detail: call_lines=%s" % str(call_lines))
	_og_assert(call_lines.size() == 1, "C08", "授予符号字面调用点==1",
		"count=%d lines=%s" % [call_lines.size(), str(call_lines)], 1)
	# C09 不缓存：3 → 授予 8；改 1 → 再授予应为 3
	_og_flat(0); _og_set_last_run(_og_oath_ne(), 3, true); _og_grant()
	var after3 := Game.diamonds
	_og_set_last_run(_og_oath_ne(), 1, true); _og_grant()
	_og_assert(Game.diamonds - after3 == 3, "C09", "改 streak=1 后 Δ=3（不留 8）",
		Game.diamonds - after3, 3)

# ---------------------------------------------------------------- G 组（1，真实 HUD 标签）

## 只读用户能看见的那个字符串（hud.gd:300 就是 _diamond_label.text = str(n)）。
## 禁 mock、禁读 hud 内部缓存字段——「连了信号」是静态事实，「显示对了」必须实测。
func _og_group_g() -> void:
	_og_flat(7); _og_set_last_run(_og_oath_ne(), 3, true); _og_grant()
	var new_total := Game.diamonds                       # 期望 15
	var lab := _og_label_num()
	print("[SMOKE-OATH-GRANT] g01 detail: label_raw=%s label_num=%s diamonds=%d" % [
		_og_label(), lab, Game.diamonds])
	_og_assert(lab == str(new_total), "G01", "真实 hud 标签数字==Game.diamonds", lab, str(new_total))


# ---------------------------------------------------------------- D 组（5，文案）

func _og_group_d() -> void:
	_og_flat(0); _og_set_last_run(_og_oath_ne(), 3, true); _og_grant()
	var t1 := _og_toast()
	_og_assert(t1.begins_with(_OG_TAG), "D01", "toast 以「誓约遗赠」开头", t1, _OG_TAG + "…")
	_og_flat(0); _og_set_last_run(_og_oath_ne(), 2, true); _og_grant()
	var t2 := _og_toast()
	_og_assert(t2.contains("2 局"), "D02", "含连绩局数 2 局", t2, "…2 局…")
	_og_assert(t2.contains("+5"), "D03", "含回流实值 +5", t2, "…+5…")
	_og_flat(0); _og_set_last_run(_og_oath_ne(), 0, true); _og_grant()
	_og_assert(_og_toast() == _OG_SENTINEL, "D04", "streak=0 无 toast（哨兵未变）",
		_og_toast(), _OG_SENTINEL)
	var clash := ""
	for k in Data.OATH_CONDITIONS.keys():
		if String(Data.OATH_CONDITIONS[k].get("name", "")) == _OG_TAG:
			clash = String(k)
	_og_assert(clash == "", "D05", "「誓约遗赠」不与任何誓约名相同", clash, "无同名")


# ---------------------------------------------------------------- F 组（2，零 rng）

func _og_group_f() -> void:
	_og_flat(0); _og_set_last_run(_og_oath_ne(), 3, true)
	var s0 := Game.rng.seed
	var fx0 := Game.fx_rng.seed
	var st0 := Game.rng.state
	_og_grant()
	_og_assert(Game.rng.seed == s0 and Game.fx_rng.seed == fx0 and Game.rng.state == st0, "F01",
		"授予前后 两个 seed + rng.state 不变",
		"seed %d→%d fx %d→%d state_changed=%s" % [s0, Game.rng.seed, fx0, Game.fx_rng.seed,
			str(Game.rng.state != st0)], "全不变")
	var a3a := _og_amount(3)
	var a3b := _og_amount(3)
	print("[SMOKE-OATH-GRANT] f02 detail: 静态半边（函数体内不得出现 Game./player.）由 grep + 人工闭合")
	_og_assert(a3a == a3b, "F02", "同输入两次同输出", "%d vs %d" % [a3a, a3b], "相等")


# ---------------------------------------------------------------- E 组（7，🔴 必须最后）

func _og_group_e() -> void:
	# E01 无印记：控制组 streak=0 vs 处理组 streak=3（同 rng 起点，只断差值）
	var e1 := _og_e2e_pair(0, 3, "", _OG_PLAIN_SEED)
	var d1x := int(e1[0]["diamonds"])
	var d1y := int(e1[1]["diamonds"])
	print("[SMOKE-OATH-GRANT] e2e run=E01 ctrl diamonds=%d run_seed=%s | treat diamonds=%d run_seed=%s modifier=%s" % [
		d1x, str(e1[0]["run_seed"]), d1y, str(e1[1]["run_seed"]), str(e1[1]["modifier"])])
	_og_assert(d1y - d1x == 8, "E01", "E2E 差值 +8", d1y - d1x, 8)
	# E02 purse
	var e2 := _og_e2e_pair(0, 3, "purse", _OG_PLAIN_SEED)
	var d2x := int(e2[0]["diamonds"])
	var d2y := int(e2[1]["diamonds"])
	print("[SMOKE-OATH-GRANT] e2e run=E02 ctrl diamonds=%d | treat diamonds=%d" % [d2x, d2y])
	_og_assert(d2y - d2x == 8 and d2x >= 15, "E02", "purse Δ=8 且 X>=15",
		"X=%d Y=%d Δ=%d" % [d2x, d2y, d2y - d2x], "X>=15 Δ=8")
	# E03 seed 777（barren 场景）
	var e3 := _og_e2e_pair(0, 3, "", _OG_E2E_SEED)
	var d3x := int(e3[0]["diamonds"])
	var d3y := int(e3[1]["diamonds"])
	print("[SMOKE-OATH-GRANT] e2e run=E03 ctrl=%d treat=%d modifier=%s" % [
		d3x, d3y, str(e3[1]["modifier"])])
	_og_assert(d3y - d3x == 8, "E03", "barren 场景差值仍 8", d3y - d3x, 8)
	# E04 / E05 🔴 源码序断言：一次读取算完三个锚点，读失败则两条一起红（不许 PENDING、不许静默跳过）
	# 三个锚点一律只在 start_run() 函数体内定位（探针自身在文件末尾，天然落在范围外，不吃自己的子串）
	var gl := _og_lines_in_body(_OG_SYM_GRANT)
	var sl := _og_lines_in_body("_apply_sigil_contract()")
	var rl := _og_lines_in_body("Game.run_seed = Game.rng.seed")
	var g0 := int(gl[0]) if gl.size() > 0 else -1
	var s1 := int(sl[0]) if sl.size() > 0 else -1
	var rr := int(rl[0]) if rl.size() > 0 else -1
	print("[SMOKE-OATH-GRANT] e04e05 detail: body=%s grant_call_lines=%s sigil_call_lines=%s run_seed_lines=%s src_lines=%d" % [
		str(_og_body), str(gl), str(sl), str(rl), _og_src.size()])
	# 源码读不到 / start_run 找不到 / 锚点找不到 ⇒ -1 ⇒ 两条同时红（这就是设计意图，不是跳过）
	_og_assert(g0 > 0 and s1 > 0 and g0 > s1, "E04", "grant 调用行 > sigil 调用行",
		"grant=%d sigil=%d" % [g0, s1], "grant>sigil>0")
	_og_assert(g0 > 0 and rr > 0 and g0 < rr, "E05", "grant 调用行 < run_seed 行",
		"grant=%d run_seed=%d" % [g0, rr], "0<grant<run_seed")
	# E06 run_seed 逐字相同
	var rs_a := str(e1[0]["run_seed"])
	var rs_b := str(e1[1]["run_seed"])
	_og_assert(rs_a == rs_b, "E06", "两次 run_seed 逐字相同", "%s vs %s" % [rs_a, rs_b], "相等")
	# E07 地图指纹（房间序 + kinds 序）逐字相同
	var fp_a := str(e1[0]["fp"])
	var fp_b := str(e1[1]["fp"])
	print("[SMOKE-OATH-GRANT] e07 detail: fp_ctrl=%s | fp_treat=%s" % [fp_a, fp_b])
	_og_assert(fp_a == fp_b, "E07", "层1 地图指纹逐字相同", "equal" if fp_a == fp_b else "DIFF", "equal")


## 一对 E2E：控制组/处理组用同一 rng 起点（seed + state 双还原），只变 last_run
func _og_e2e_pair(streak_ctrl: int, streak_treat: int, sigil: String, seed_value: int) -> Array:
	var x := _og_e2e_raw(streak_ctrl, sigil, seed_value)
	var y := _og_e2e_raw(streak_treat, sigil, seed_value)
	return [x, y]


func _og_e2e_raw(streak: int, sigil: String, seed_value: int) -> Dictionary:
	Game.sigils["equipped"] = sigil
	Game.daily_mode = false
	# 控制组也是「立誓未兑现」（oath 非空 + streak=0），不混入「未立誓」这一维
	Game.codex["last_run"]["oath"] = _og_oath_ne()
	Game.codex["last_run"]["oath_streak"] = streak
	# 🔴 双还原：只还原 .state 不够（reset/daily 路径会读 .seed）
	Game.rng.seed = seed_value
	Game.rng.state = seed_value * 2654435761                      # 固定起点，避免依赖上一次消耗
	start_run()
	return {"diamonds": Game.diamonds, "run_seed": Game.run_seed,
		"modifier": modifier, "fp": _og_fp()}


## 与 _smoke_fingerprint 同一算法，但不打 [SMOKE-META] 前缀
func _og_fp() -> String:
	if dungeon == null:
		return "<no-dungeon>"
	var coords: Array = []
	for c in dungeon.rooms.keys():
		coords.append(c)
	coords.sort_custom(func(a, b): return str(a) < str(b))
	var rooms_s: Array = []
	var kinds_s: Array = []
	for c in coords:
		rooms_s.append(str(c))
		kinds_s.append(String(dungeon.rooms[c].get("kind", "?")))
	return ",".join(rooms_s) + "|" + ",".join(kinds_s)


# ---------------------------------------------------------------- 源码扫描
# C08  走全仓（「字面调用点全仓恰 1 处」是仓库级事实）
# E04/E05 走 start_run 函数体（「调用点在契约之后、run_seed 之前」是函数体内事实）

func _og_load_src() -> void:
	_og_src = []
	_og_body = Vector2i(-1, -1)
	var f := FileAccess.open("res://scripts/game_main.gd", FileAccess.READ)
	if f == null:
		print("[SMOKE-OATH-GRANT] WARN 读不到 res://scripts/game_main.gd → C08/E04/E05 判红（请从源码目录跑）")
		return
	var txt := f.get_as_text()
	f.close()
	_og_src = txt.split("\n")
	_og_body = _og_start_run_body()


## 定位 start_run() 函数体：[func 头下一行, 下一个顶层 func 前一行]，1-based；找不到返回 (-1,-1)
## 🔴 E04/E05 的三个锚点必须在本范围内找，不许全文件扫：
##    ① 探针函数名 _test_oath_grant 里含「_oath_grant」子串，全景扫会撞到自己；
##    ② 限死函数体后「调用点在哪」没有歧义（探针追加在文件末尾，天然落在范围外）。
func _og_start_run_body() -> Vector2i:
	var s := -1
	for i in _og_src.size():
		if _og_src[i].begins_with("func start_run("):
			s = i
			break
	if s < 0:
		return Vector2i(-1, -1)
	var last := _og_src.size() - 1
	for i in range(s + 1, _og_src.size()):
		var ln: String = _og_src[i]
		if ln.begins_with("func ") or ln.begins_with("static func ") or ln.begins_with("class "):
			last = i - 1
			break
	return Vector2i(s + 2, last + 1)          # 首行取 func 头下一行（跳过函数签名本身）


func _og_is_word(c: String) -> bool:
	if c == "_":
		return true
	if c >= "0" and c <= "9":
		return true
	if c >= "a" and c <= "z":
		return true
	if c >= "A" and c <= "Z":
		return true
	return false


## 词边界匹配（左边界）：符号前不能是标识符字符
## （否则 _test_oath_grant 会被误算成调用点，把 C08 读成 2/3）
func _og_line_has_sym(line: String, sym: String) -> bool:
	var i := line.find(sym)
	while i >= 0:
		var left_ok := i == 0 or not _og_is_word(line[i - 1])
		if left_ok:
			return true
		i = line.find(sym, i + 1)
	return false


## 全仓 1-based 行号数组（排除 func/static func 定义行）
## 🔴 不截断探针自身：探针若写了带括号的字面调用，这里就该读出 2 → C08 判红。
##    为了让这条纪律可执行，探针自己用 _OG_SYM_GRANT 拼接符号，源码里不出现字面量。
func _og_lines_containing(sym: String, also_exclude_func: bool) -> Array:
	var out: Array = []
	for i in _og_src.size():
		var line: String = _og_src[i]
		if not _og_line_has_sym(line, sym):
			continue
		if line.strip_edges().begins_with("func "):
			continue
		if also_exclude_func and line.strip_edges().begins_with("static func "):
			continue
		out.append(i + 1)
	return out


## start_run 函数体 1-based 行号数组（E04/E05 专用；范围外一律不算，读不到源码则为空）
func _og_lines_in_body(sym: String) -> Array:
	var out: Array = []
	if _og_body.x < 0:
		return out
	for ln in range(_og_body.x, _og_body.y + 1):
		if ln - 1 < _og_src.size() and _og_line_has_sym(_og_src[ln - 1], sym):
			out.append(ln)
	return out


func _og_grant_call_lines() -> Array:
	return _og_lines_containing(_OG_SYM_GRANT, true)


# ---------------------------------------------------------------- 现场快照与还原

func _og_snapshot() -> Dictionary:
	var t: String = hud._toast.text if is_instance_valid(hud) else ""
	return {
		"equipped": String(Game.sigils.get("equipped", "")),
		"codex": Game.codex.duplicate(true),          # 深拷贝：本探针只改内存态
		"daily": Game.daily_mode,
		"has_resocore": player.has_resocore if is_instance_valid(player) else false,
		"diamonds": Game.diamonds,
		"earned": Game.run_diamonds_earned,
		"reso_pickups": Game._reso_pickups,
		"resonance": resonance,
		"toast": t,
	}


## 🔴 E 组会重建地图/player，运行状态不做完整还原（如实声明，不假装还原了）；
## 只还原「会污染其它探针」的全局配置与存档内存态。
func _og_restore() -> void:
	Game.sigils["equipped"] = String(_og_snap.get("equipped", ""))
	Game.codex = (_og_snap.get("codex", {}) as Dictionary).duplicate(true)
	Game.daily_mode = bool(_og_snap.get("daily", false))
	if is_instance_valid(player):
		player.has_resocore = bool(_og_snap.get("has_resocore", false))
	Game.diamonds = int(_og_snap.get("diamonds", 0))
	Game.run_diamonds_earned = int(_og_snap.get("earned", 0))
	Game._reso_pickups = int(_og_snap.get("reso_pickups", 0))
	resonance = int(_og_snap.get("resonance", 0))
	if is_instance_valid(hud):
		hud._toast.text = String(_og_snap.get("toast", ""))
		hud._diamond_label.text = str(Game.diamonds)
	Game.diamonds_changed.emit(Game.diamonds)
	print("[SMOKE-OATH-GRANT] restore equipped=%s daily=%s diamonds=%d（E 组运行态不还原，已声明）" % [
		String(Game.sigils.get("equipped", "")), str(Game.daily_mode), Game.diamonds])


## ============================================================================
## Sprint 28 批一 探针：净化代价（SMOKE_PURIFY_COST=1）
## 24 条断言，declared 字面量 24。每条后无条件打印 #NN + 实测值 + ok= 字段
## （判红口径：Dev.check 只在失败时打 [ERR]；ok=false 计数为第二道门）。
## 净化驱动走真实 _on_shrine_chosen 全链（affordable → execute → 记账 → 回声桶）。
## settle_shards 会 save_sigils()：每次调用前后把 shards 还原到入口快照（直接赋值，不走 add_shards）。
## 🔴 本探针源码不得出现记账赋值符号的带上下文完整字面（F01 是文本级静态门，
##    注释命中也算一处；探针自己的记账式赋值一律走 Game.set("purified_run", …)）。
## ============================================================================

const _PC_DECLARED := 24
var _pc_checked := 0


func _pc_assert(ok: bool, nn: String, what: String, measured, expect) -> void:
	_pc_checked += 1
	var msg := "%s %s | measured=%s expect=%s" % [nn, what, str(measured), str(expect)]
	Dev.check(ok, "purify_cost", msg)
	print("[SMOKE-PURIFY-COST] #%02d %s measured=%s expect=%s ok=%s" % [
		_pc_checked, nn + " " + what, str(measured), str(expect), str(ok)])


func _pc_is_word(c: String) -> bool:
	if c == "_":
		return true
	if c >= "0" and c <= "9":
		return true
	if c >= "a" and c <= "z":
		return true
	if c >= "A" and c <= "Z":
		return true
	return false


## 组卡助手：SHRINE_OFFERS 表项不带 id 键（键名即 id，真链由 _open_shrine 注入）——
## 探针喂裸表项会让 offer["id"] 取值报错、execute 静默中止（首跑实证 7 红同源）。
func _pc_purify_offer() -> Dictionary:
	var o: Dictionary = Data.SHRINE_OFFERS["purify"].duplicate()
	o["id"] = "purify"
	return o


## 负向构造用卡：护盾祝福（残响 -5 → 盾 +1）——零 rng、效果可读数、代价走 spend 只动余额。
## 必须真能落地：置灰早退会让负向断言变前提守卫型恒过（刀五级联伪影的教训）。
func _pc_nonpurify_offer() -> Dictionary:
	var o: Dictionary = Data.SHRINE_OFFERS["ward_boon"].duplicate()
	o["id"] = "ward_boon"
	return o


func _test_purify_cost() -> void:
	var shards0: int = int(Game.sigils["shards"])
	var rng_seed0: int = Game.rng.seed
	var rng_state0: int = Game.rng.state
	var floor0: int = Game.floor_num
	var offers0: Array = _shrine_offers.duplicate()
	var coord0: Vector2i = _shrine_coord
	var echo_choices0: Array = _echo_choices.duplicate()
	var echo_costs0: Dictionary = _echo_costs.duplicate()
	var codex0: Dictionary = Game.codex.duplicate(true)
	var counters0: Dictionary = _oath_counters.duplicate()
	var floors0: Array = Game.calamity_floors.duplicate()
	print("[SMOKE-PURIFY-COST] entry shards=%d floors=%s purified=%s" % [
		shards0, str(Game.calamity_floors), str(Game.purified_run)])

	# ---- A 状态（6）----
	_pc_assert(Game.purified_run == false, "A01", "新局开局 purified_run=false", Game.purified_run, false)
	Game.set("purified_run", true)
	Game.reset()
	_pc_assert(Game.purified_run == false, "A02", "reset 后 purified_run=false（reset 漏清即红）", Game.purified_run, false)
	Game.calamity_floors = [2]
	Game.floor_num = 2
	Game.sigils["shards"] = shards0
	_shrine_offers = [_pc_purify_offer()]
	_shrine_coord = Vector2i.ZERO
	_on_shrine_chosen(0)
	_pc_assert(Game.purified_run == true, "A03", "净化全链执行后 purified_run=true（记账漏写/写错字段即红）", Game.purified_run, true)
	_pc_assert(Game.calamity_floors.has(2) == false, "A04", "erase 保留：本层已出灾祸表（删 erase 即红）", Game.calamity_floors.has(2), false)
	_pc_assert(String(Data.SHRINE_OFFERS["purify"].get("cost_kind", "x")) == "" and int(Data.SHRINE_OFFERS["purify"].get("cost", -1)) == 0,
		"A05", "purify cost_kind/cost 字段未动", "%s/%s" % [Data.SHRINE_OFFERS["purify"].get("cost_kind"), Data.SHRINE_OFFERS["purify"].get("cost")], "空串/0")
	# A06 负向：非净化卡走完 execute 全链后，记账位必须仍为 false——刀三的唯一守卫。
	# 起点归零是合法前置（同 B 组），reset 语义由 A02 独守，故本条只打「非净化不该记账」一个面。
	var a06_shield0: int = player.shield_charges
	var a06_dia0: int = Game.diamonds
	Game.set("purified_run", false)
	Game.calamity_floors = [2]
	Game.floor_num = 3
	Game.diamonds = 5
	_shrine_offers = [_pc_nonpurify_offer()]
	_shrine_coord = Vector2i.ZERO
	_on_shrine_chosen(0)
	var a06_delta: int = player.shield_charges - a06_shield0
	_pc_assert(Game.purified_run == false and a06_delta == 1, "A06",
		"负向：非净化卡全链执行后不记账（记账挪通用入口即红；盾 +1 兼证链路真跑、置灰早退即红）",
		"purified=%s 盾变化=%d" % [str(Game.purified_run), a06_delta], "false/1")
	Game.diamonds = a06_dia0
	player.shield_charges = a06_shield0

	# ---- B 结算（6，M=10；META_RATE=2.0 → 基线 20 / ×1.5 = 30）----
	Game.calamity_floors = []
	Game.set("purified_run", false)
	Game.sigils["shards"] = shards0
	var b01 := Game.settle_shards(10)
	_pc_assert(b01 == 20, "B01", "无灾祸未净化 → 基线 20", b01, 20)
	Game.calamity_floors = [2]
	Game.sigils["shards"] = shards0
	var b02 := Game.settle_shards(10)
	_pc_assert(b02 == 30, "B02", "单灾祸未净化 → ×1.5=30（1.5 被删即红）", b02, 30)
	Game.calamity_floors = [2, 3]
	Game.sigils["shards"] = shards0
	var b03 := Game.settle_shards(10)
	_pc_assert(b03 == 30, "B03", "多灾祸未净化 → 仍 ×1.5（按层累加=方案C误入即红）", b03, 30)
	Game.calamity_floors = [2]
	Game.set("purified_run", true)
	Game.sigils["shards"] = shards0
	var b04 := Game.settle_shards(10)
	_pc_assert(b04 == 20, "B04", "单灾祸净化 → 不乘（回归基线）", b04, 20)
	Game.calamity_floors = [2, 3]
	Game.set("purified_run", true)
	Game.sigils["shards"] = shards0
	var b05 := Game.settle_shards(10)
	_pc_assert(b05 == 20, "B05", "多灾祸净化 → 不乘 20 而非 30（本批靶心）", b05, 20)
	Game.calamity_floors.append(9)
	Game.sigils["shards"] = shards0
	var b06 := Game.settle_shards(10)
	_pc_assert(b06 == 20, "B06", "净化后塞别的灾祸层 → 仍不乘（作废由记账位决定非 size）", b06, 20)

	# ---- C 跨局（3）----
	Game.reset()
	Game.calamity_floors = [2]
	Game.sigils["shards"] = shards0
	var c01 := Game.settle_shards(10)
	_pc_assert(c01 == 30, "C01", "净化局 reset 后新局未净化有灾祸 → 恢复 ×1.5", c01, 30)
	var alt_bad := 0
	for i in 3:
		Game.reset()
		Game.calamity_floors = [2]
		Game.sigils["shards"] = shards0
		if i % 2 == 0:
			Game.floor_num = 2
			_shrine_offers = [_pc_purify_offer()]
			_shrine_coord = Vector2i.ZERO
			_on_shrine_chosen(0)
			if Game.settle_shards(10) != 20:
				alt_bad += 1
		else:
			if Game.settle_shards(10) != 30:
				alt_bad += 1
	_pc_assert(alt_bad == 0, "C02", "净化/未净化交替 3 轮按预期交替（状态只增不清即红）", "%d 轮错" % alt_bad, "0 轮错")
	Game.reset()
	Game.calamity_floors = [2, 3]
	Game.set("purified_run", false)
	Game.floor_num = 2
	_shrine_offers = [_pc_purify_offer()]
	_shrine_coord = Vector2i.ZERO
	_on_shrine_chosen(0)
	Game.sigils["shards"] = shards0
	var c03a := Game.settle_shards(10)
	Game.floor_num = 3
	_on_shrine_chosen(0)
	Game.sigils["shards"] = shards0
	var c03b := Game.settle_shards(10)
	_pc_assert(c03a == 20 and c03b == 20, "C03", "连续两次净化不叠加（布尔被写成计数即红）", "%s/%s" % [c03a, c03b], "20/20")

	# ---- D 零漂移（4）----
	_pc_assert(_echo_costs.has("") and int(_echo_costs.get("", 0)) >= 1, "D01",
		"净化记账走空串桶（擅迁桶即红）", str(_echo_costs), "含空串键")
	var echo_costs_keep := _echo_costs.duplicate()
	_echo_costs = {"": 1}
	var d02 := _echo_tag()
	_echo_costs = echo_costs_keep
	_pc_assert(d02 == "实用流", "D02", "_echo_tag 对空串桶返回实用流（分支被改死即红）", d02, "实用流")
	_pc_assert(int(_oath_counters.get("purify_used", 0)) >= 1, "D03", "purify_used 誓约计数在位", _oath_counters.get("purify_used", 0), ">=1")
	var d_seed0: int = Game.rng.seed
	var d_state0: int = Game.rng.state
	Game.reset()
	Game.calamity_floors = [2]
	Game.floor_num = 2
	_shrine_offers = [_pc_purify_offer()]
	_shrine_coord = Vector2i.ZERO
	_on_shrine_chosen(0)
	Game.sigils["shards"] = shards0
	Game.settle_shards(10)
	_pc_assert(Game.rng.seed == d_seed0 and Game.rng.state == d_state0, "D04",
		"净化+结算链 rng seed/state 双不变（只比 state 不够——reset/daily 路径读 seed）",
		"seed %d→%d state_changed=%s" % [d_seed0, Game.rng.seed, str(Game.rng.state != d_state0)], "全不变")

	# ---- E 文案（3）----
	_pc_assert(String(Data.SHRINE_OFFERS["purify"]["desc"]).contains("本局 ×1.5 结算加成作废"), "E01",
		"卡面 desc 新文案", Data.SHRINE_OFFERS["purify"]["desc"], "含「本局 ×1.5 结算加成作废」")
	var e02: String = shrine_panel._cost_text({"cost_kind": ""})
	_pc_assert(e02 == "代价：本局 ×1.5 加成作废", "E02", "面板代价行新文案（仍说「或失效」即红）", e02, "代价：本局 ×1.5 加成作废")
	var e03_bad: Array[String] = []
	for k in Data.SHRINE_OFFERS.keys():
		if String(k) != "purify" and String(Data.SHRINE_OFFERS[k].get("cost_kind", "")) == "":
			e03_bad.append(String(k))
	_pc_assert(e03_bad.is_empty(), "E03", "其余 9 项 cost_kind 均非空（默认分支仅净化可达）", e03_bad, "0 误伤")

	# ---- F 静态（2，文本级门；读失败判红不静默跳过）----
	var f01_cnt := -1
	var f02_ok := false
	var fg := FileAccess.open("res://scripts/game_main.gd", FileAccess.READ)
	var fg2 := FileAccess.open("res://scripts/game_state.gd", FileAccess.READ)
	if fg != null and fg2 != null:
		var lines_g: PackedStringArray = fg.get_as_text().split("\n")
		var lines_s: PackedStringArray = fg2.get_as_text().split("\n")
		fg.close()
		fg2.close()
		f01_cnt = 0
		var pc_sym := "Game.purified_run " + "= true"
		for i in lines_g.size():
			var ln := lines_g[i]
			var pos := ln.find(pc_sym)
			while pos >= 0:
				if pos == 0 or not _pc_is_word(ln[pos - 1]):
					f01_cnt += 1
				pos = ln.find(pc_sym, pos + 1)
		for i in lines_s.size():
			if lines_s[i].contains("calamity_floors.size() > 0 and not purified_run"):
				f02_ok = true
	_pc_assert(f01_cnt == 1, "F01", "全仓记账赋值词边界恰 1 处（多处记账即红）", f01_cnt, 1)
	_pc_assert(f02_ok, "F02", "settle_shards 判定行含 and not purified_run（改回存在性布尔即红）", f02_ok, true)

	# ---- 出口还原 ----
	Game.sigils["shards"] = shards0
	Game.rng.seed = rng_seed0
	Game.rng.state = rng_state0
	Game.calamity_floors = floors0
	Game.set("purified_run", false)
	Game.floor_num = floor0
	_shrine_offers = offers0
	_shrine_coord = coord0
	_echo_choices = echo_choices0
	_echo_costs = echo_costs0
	_oath_counters = counters0
	Game.codex = codex0.duplicate(true)
	Dev.check(_pc_checked == _PC_DECLARED, "purify_cost",
		"自校验失败: checked(%d) != declared(%d)——有断言被跳过或死数错" % [_pc_checked, _PC_DECLARED])
	print("[SMOKE-PURIFY-COST] done checked=%d declared=%d" % [_pc_checked, _PC_DECLARED])


## ============================================================================
## Sprint 29 批一 探针：发现度改写深渊起点（SMOKE_START_BUFFER=1）
## 15 条断言，declared 字面量 15（A4 + B3 + C3 + D2 + G2 + H1）。批二式格式：每条无条件
## 打 #NN + measured/expect + ok= 字段（判红双门：ok=false 主门、[ERR] start_buffer 辅门，
## 两门读数不一致 = 有人改了 helper，按 FAIL）。
## 造档：四类按计数填非法占位 id（只活在本探针写入的内存态，load_codex 会过滤掉）；
## tier 直写深渊档字段（同 SMOKE_ABYSS 范式），不依赖菜单点击。
## 🔴 调用分工是口径 §五 刀表的可复现前提：A01/A02/A03/B*/C*/D* 一律直调落地函数
##    （射程只到该函数体），只有 A04 走完整 start_run()——「调用行被注释」这类漏接线
##    只有 A04 抓得到，直调断言对它天然免疫。
## ============================================================================

const _SB_DECLARED := 15
const _SB_TIER := 3                 # ABYSS_TIERS 合法档内任取（断言只看是否 >0）
var _sb_checked := 0


func _sb_assert(ok: bool, nn: String, what: String, measured, expect) -> void:
	_sb_checked += 1
	Dev.check(ok, "start_buffer", "%s %s | measured=%s expect=%s" % [nn, what, str(measured), str(expect)])
	print("[SMOKE-START-BUFFER] #%02d %s measured=%s expect=%s ok=%s" % [
		_sb_checked, nn + " " + what, str(measured), str(expect), str(ok)])


## 造一档发现集：四类按计数填占位 id，suffixes/shrine 清空（不参与四类阈值判定）。
## last_run 原样保留——A04 走 start_run 时契约/遗赠两段要读它，抹了会混进别的起点增量。
func _sb_fill_codex(n_en: int, n_re: int, n_th: int, n_bo: int) -> void:
	for kind in Game.CODEX_KINDS:
		Game.codex[kind] = []
	for i in n_en:
		(Game.codex["enemies"] as Array).append("sb_e%d" % i)
	for i in n_re:
		(Game.codex["relics"] as Array).append("sb_r%d" % i)
	for i in n_th:
		(Game.codex["themes"] as Array).append("sb_t%d" % i)
	for i in n_bo:
		(Game.codex["bosses"] as Array).append("sb_b%d" % i)


## 直调一次落地并读回本次落盾层数。读前把盾归零（合法前置：player 每局不重建，
## 不清零会读到上一段残留），残响/血量上限/当前血量/词缀当场还原——
## 保证每一次读数都从同一基线出发，否则「各档互不相同」这条差分就不成立。
func _sb_shield_at(n_en: int, n_re: int, n_th: int, n_bo: int, tier: int) -> int:
	_sb_fill_codex(n_en, n_re, n_th, n_bo)
	abyss_tier = tier
	var dia0: int = Game.diamonds
	var mh1: int = player.max_hp
	var hp1: int = player.hp
	var suf1: Dictionary = player.relic_suffixes.duplicate()
	player.shield_charges = 0
	_apply_codex_boons()
	var got: int = player.shield_charges
	Game.diamonds = dia0
	player.max_hp = mh1
	player.hp = hp1
	player.relic_suffixes = suf1
	player.shield_charges = 0
	return got


func _test_start_buffer() -> void:
	var tier0 := abyss_tier
	var codex0: Dictionary = Game.codex.duplicate(true)
	var shield0: int = player.shield_charges
	var mh0: int = player.max_hp
	var hp0: int = player.hp
	var dia0: int = Game.diamonds
	var suf0: Dictionary = player.relic_suffixes.duplicate()
	var imm0: bool = player._immortal
	var ward0: bool = player.sigil_ward
	var inv0: float = player._invuln_t
	var kin0: bool = player.has_kinetic
	var lock0: bool = player.control_locked
	var counters0: Dictionary = _oath_counters.duplicate()
	var seed0: int = Game.rng.seed
	var state0: int = Game.rng.state
	var daily0: bool = Game.daily_mode
	# 图鉴档原文快照：铭刻分支 attach_suffix→mark_codex→save_codex 会落盘（SMOKE 下
	# codex_path() 走隔离档 _smoke_codex.cfg，真档永不受影响），出口按原文逐字写回。
	var cfg0 := ""
	var rfp := FileAccess.open(Game.codex_path(), FileAccess.READ)
	if rfp != null:
		cfg0 = rfp.get_as_text()
		rfp.close()
	print("[SMOKE-START-BUFFER] entry tier=%d boons=%d cfg_bytes=%d" % [
		tier0, Game.codex_boons().size(), cfg0.length()])

	# ---- A 差分（4）Δ = 同档「深渊局落盾 − 普通局落盾」，把被动那一层减干净 ----
	var a01 := _sb_shield_at(0, 0, 0, 0, _SB_TIER) - _sb_shield_at(0, 0, 0, 0, 0)
	_sb_assert(a01 == 0, "A01", "n=0 深渊局缓冲=0（早退使本批块不执行·前提守卫型恒过·不计覆盖）", a01, 0)
	var a02 := _sb_shield_at(0, 0, 3, 2, _SB_TIER) - _sb_shield_at(0, 0, 3, 2, 0)
	_sb_assert(a02 == 2, "A02", "n=2（bosses2+themes3）深渊局缓冲=2", a02, 2)
	var a03 := _sb_shield_at(5, 4, 3, 2, _SB_TIER) - _sb_shield_at(5, 4, 3, 2, 0)
	_sb_assert(a03 == 4, "A03", "n=4 满档深渊局缓冲=4（普通局 1 层被动 → 深渊局 5 层）", a03, 4)
	# A04 全口径唯一走完整 start_run() 的断言（专抓漏接线）
	_sb_fill_codex(5, 4, 3, 2)
	abyss_tier = _SB_TIER
	Game.daily_mode = false
	Game.rng.seed = seed0
	Game.rng.state = state0
	player.shield_charges = 0
	start_run()
	_sb_assert(player.shield_charges == 5, "A04",
		"真实 start_run（tier=T, n=4）落盾=5=1 被动+4 缓冲（调用行注释掉即红）", player.shield_charges, 5)

	# ---- B 普通局反向守卫（3）----
	var b01 := _sb_shield_at(0, 0, 3, 2, 0)
	_sb_assert(b01 == 0, "B01", "n=2 普通局盾=0：无缓冲且无被动（gate 写反或恒真即红）", b01, 0)
	var b02 := _sb_shield_at(5, 4, 3, 2, 0)
	_sb_assert(b02 == 1, "B02", "n=4 普通局盾=1：只含被动那一层（普通局基线被污染即红）", b02, 1)
	_sb_fill_codex(0, 0, 0, 0)
	var b03: int = Game.codex_boons().size()
	_sb_assert(b03 == 0, "B03", "n=0 构造自检派生档数（前提守卫型·构造正确性·不计覆盖）", b03, 0)

	# ---- C 被动与缓冲共存（3）----
	var c01 := _sb_shield_at(5, 0, 0, 0, 0)
	_sb_assert(c01 == 1, "C01", "n=1（仅被动档）普通局盾=1：被动来源独立存在", c01, 1)
	var c02 := _sb_shield_at(5, 0, 0, 0, _SB_TIER)
	_sb_assert(c02 == 2, "C02", "n=1 深渊局盾=2=1 被动+1 缓冲（叠加非覆盖；写成覆盖赋值即红）", c02, 2)
	var c03 := _sb_shield_at(5, 4, 3, 2, _SB_TIER)
	_sb_assert(c03 == 5, "C03", "n=4 深渊局盾=5：不重复计数、无全局钳 3（盾字段本无上限）", c03, 5)

	# ---- D 零 rng（2）seed 与 state 双比（只比其一会漏，S27 批二缺口②教训）----
	_sb_fill_codex(5, 4, 3, 2)
	abyss_tier = _SB_TIER
	player.shield_charges = 0
	var d_seed_a: int = Game.rng.seed
	var d_state_a: int = Game.rng.state
	_apply_codex_boons()
	_sb_assert(Game.rng.seed == d_seed_a, "D01", "加盾前后 rng.seed 逐字不变（分支内混进抽取即红）",
		"%d→%d" % [d_seed_a, Game.rng.seed], "不变")
	_sb_assert(Game.rng.state == d_state_a, "D02", "加盾前后 rng.state 逐字不变（只比 seed 会漏）",
		"%d→%d" % [d_state_a, Game.rng.state], "不变")
	player.shield_charges = 0

	# ---- G 兑现链（2，走查守卫：本批零改 player.gd，无专属刀，不计行为覆盖）----
	# 满档 5 层逐层消耗。抵挡分支会置无敌 0.6s 且 start_run 末尾的过门会锁操作，
	# headless 单帧内两者都不会自然解除 → 每次命中前手工归零，制造纯净单一入口语境。
	var g_shield0: int = player.shield_charges
	var g_hp0: int = player.hp
	var g_imm0: bool = player._immortal
	var g_ward0: bool = player.sigil_ward
	var g_inv0: float = player._invuln_t
	var g_kin0: bool = player.has_kinetic
	var g_lock0: bool = player.control_locked
	var g_blk0: int = int(_oath_counters.get("shield_blocks", 0))
	player.hp = 100000
	player._immortal = false
	player.sigil_ward = false
	player.has_kinetic = false
	player.control_locked = false
	player.shield_charges = 5
	_oath_counters["shield_blocks"] = 0
	var g_reads: Array[String] = ["0"]
	var g_first_toast := ""
	for i in 5:
		player._invuln_t = 0.0
		player.take_damage(1, Vector2.ZERO, null)
		if i == 0:
			g_first_toast = String(hud._toast.text)
		g_reads.append(str(int(_oath_counters.get("shield_blocks", 0))))
	_sb_assert(",".join(g_reads) == "0,1,2,3,4,5", "G01",
		"满档 5 层逐层消耗·记账六次读数（走查守卫·不计覆盖）", ",".join(g_reads), "0,1,2,3,4,5")
	_sb_assert(g_first_toast.contains("护盾抵挡"), "G02",
		"首次消耗 toast 含「护盾抵挡」（只验标志·不计数值覆盖）", g_first_toast, "含「护盾抵挡」")
	player.shield_charges = g_shield0
	player.hp = g_hp0
	player._immortal = g_imm0
	player.sigil_ward = g_ward0
	player._invuln_t = g_inv0
	player.has_kinetic = g_kin0
	player.control_locked = g_lock0
	_oath_counters["shield_blocks"] = g_blk0

	# ---- H 结构（1，静态门·前提守卫型，计 PASS 不计覆盖）----
	# 口径 §二 把本条写成「加盾块行号 < run_seed 赋值行」，但块在落地函数内（本文件
	# 三千行段）而 run_seed 赋值在 start_run 头部（数百行段），两行号恒不满足前者更小
	# ——正确实现也会被这条判红。按同一条的括注「限 _apply_codex_boons() 函数体内定位」
	# 落地成本批块物理位于该函数体内：刀三（块移出函数体）红、刀八（调用行注释）绿，
	# 与 §五 红集合逐条一致。措辞请主理人裁定后回写口径。
	var h_lo := -1
	var h_hi := -1
	var h_blk := -1
	var hfp := FileAccess.open("res://scripts/game_main.gd", FileAccess.READ)
	if hfp != null:
		var hl: PackedStringArray = hfp.get_as_text().split("\n")
		hfp.close()
		var hs := -1
		for i in hl.size():
			if hl[i].begins_with("func _apply_codex_boons("):
				hs = i
				break
		if hs >= 0:
			var he := hl.size() - 1
			for i in range(hs + 1, hl.size()):
				if hl[i].begins_with("func ") or hl[i].begins_with("static func ") \
						or hl[i].begins_with("class "):
					he = i - 1
					break
			h_lo = hs + 2
			h_hi = he + 1
			for i in range(hs + 1, he + 1):
				if hl[i].contains("abyss_tier") or hl[i].contains("boons.size()"):
					h_blk = i + 1
					break
	_sb_assert(h_lo > 0 and h_blk >= h_lo and h_blk <= h_hi, "H01",
		"本批加盾块物理位于落地函数体内（静态门·不计覆盖）",
		"block=%d body=%d..%d" % [h_blk, h_lo, h_hi], "block 落在 body 区间内")

	# ---- 出口还原 ----
	abyss_tier = tier0
	Game.codex = codex0
	Game.diamonds = dia0
	player.shield_charges = shield0
	player.max_hp = mh0
	player.hp = hp0
	player.relic_suffixes = suf0
	player._immortal = imm0
	player.sigil_ward = ward0
	player._invuln_t = inv0
	player.has_kinetic = kin0
	player.control_locked = lock0
	player._knock = Vector2.ZERO
	if is_instance_valid(player.sprite):
		player.sprite.modulate = Color.WHITE
	_oath_counters = counters0
	Game.daily_mode = daily0
	Game.rng.seed = seed0
	Game.rng.state = state0
	var wfp := FileAccess.open(Game.codex_path(), FileAccess.WRITE)
	if wfp != null:
		wfp.store_string(cfg0)
		wfp.close()
	Dev.check(_sb_checked == _SB_DECLARED, "start_buffer",
		"自校验失败: checked(%d) != declared(%d)——有断言被跳过或死数错" % [_sb_checked, _SB_DECLARED])
	print("[SMOKE-START-BUFFER] done checked=%d declared=%d cfg_restored_bytes=%d" % [
		_sb_checked, _SB_DECLARED, cfg0.length()])
