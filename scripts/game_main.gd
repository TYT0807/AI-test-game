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
const PrismWardenScript := preload("res://scripts/boss.gd")
const Boss2Script := preload("res://scripts/boss2.gd")
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
# ---- Sprint 4：挑战因子 / 源石共鸣 ----
var modifier := "none"
var enemy_hp_mult := 1.0
var enemy_speed_mult := 1.0
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
var _calamity_forced := false  # SMOKE_CALAMITY：跳过 15% 概率强制触发


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
	# 局内状态归零：源石 / 击杀 / 升级已选次数 / 里程碑。
	# 必须早于 _roll_modifier()，否则 barren 因子的开局 +10 源石会被清零。
	Game.reset()
	Upgrades.reset()
	_run_settled = false
	_boost_ticked = false
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
	# 每层地图用「由 (run_seed, 层号) 派生」的独立 rng：第 N 层地图只由 (run_seed, N)
	# 决定，与帧数 / 战斗节奏 / 解锁内容完全无关（解锁档与默认档地图逐字一致）
	Game.run_seed = Game.rng.seed
	Game.reset_fx_rng()
	var frng := _floor_rng(1)
	dungeon = DungeonClass.generate(1, frng, 7 + frng.randi_range(0, 2))
	_smoke_fingerprint(1)
	_roll_modifier()
	# E 灾祸层（Sprint 12 §6.3）：在 modifier 之后滚（scarce_ore 的 diamond_mult
	# 不会被 challenge factor 的重置抹掉）
	_roll_calamity()
	if OS.get_environment("SMOKE_RUN_START") != "":
		print("[SMOKE-META] run start diamonds=%d taken=%d modifier=%s" % [
			Game.diamonds, Upgrades.taken.size(), modifier])
	_apply_floor_theme()
	# 探针：直接跳到指定楼层（只看主题色调与 HUD 提示），仅 SMOKE
	var jump_env := OS.get_environment("SMOKE_JUMP_FLOOR")
	if _smoke and jump_env != "":
		Game.floor_num = int(jump_env)
		_apply_floor_theme()
	if _smoke:
		var kinds := {}
		for c in dungeon.rooms:
			var k: String = dungeon.rooms[c]["kind"]
			kinds[k] = int(kinds.get(k, 0)) + 1
		print("[SMOKE] dungeon map: ", dungeon.rooms.size(), " rooms ", kinds)
	_enter_room(dungeon.current, Vector2i.ZERO)


## 每局开局抽 1 个挑战因子并应用（一利一弊）
## E 灾祸层（Sprint 12 §6.3）：每层首次进入时 15% 触发一个负面灾祸（走既有 Game.rng 流），
## 本层生效、换层清除；触发过灾祸的局，shards 结算 ×1.5（风险回报，game_state.settle_shards）
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
	Game.calamity_floors.append(Game.floor_num)
	_apply_calamity()
	hud.flash_toast("灾祸降临：" + _calamity_name(_calamity))
	hud.banner("灾祸 · " + _calamity_name(_calamity))
	if _smoke or _calamity_forced:
		print("[SMOKE-CALAMITY] floor=%d calamity=%s" % [Game.floor_num, _calamity])


func _calamity_name(id: String) -> String:
	match id:
		"frail": return "虚弱（生命上限 -20%）"
		"frenzy": return "狂乱（敌人加速 25%）"
		"scarce_ammo": return "弹药荒（弹匣减半）"
		"scarce_ore": return "贫矿（源石掉落 -30%）"
	return id


func _apply_calamity() -> void:
	# 保存进入灾祸前的倍率（换层还原用——核验 #2：不抹 modifier 全局倍率）
	_calamity_saved_diamond_mult = Game.main.diamond_mult
	_calamity_saved_mag_cap_mult = player.mag_cap_mult
	match _calamity:
		"frail":
			# 核验 #3：cut 差值增量还原（与层内成长解耦，避免绝对值还原吞成长）
			# 终审边界：存「实际」削减量（max_hp 已到钳制下限时可能为 0），否则 clear 会凭空 +1 血上限
			var old_hp: int = player.max_hp
			_calamity_frail_cut = maxi(1, int(round(old_hp * 0.2)))
			player.max_hp = maxi(2, old_hp - _calamity_frail_cut)
			_calamity_frail_cut = old_hp - player.max_hp
			player.hp = mini(player.hp, player.max_hp)
			player.hp_changed.emit(player.hp, player.max_hp)
		"frenzy":
			Game.calamity_speed_mult = 1.25
		"scarce_ammo":
			player.mag_cap_mult = 0.5
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
	_calamity_frail_cut = 0
	_calamity_saved_diamond_mult = 1.0
	_calamity_saved_mag_cap_mult = 1.0


func _roll_modifier() -> void:
	modifier = Data.roll_modifier()
	enemy_hp_mult = 1.0
	enemy_speed_mult = 1.0
	diamond_mult = 1.0
	match modifier:
		"rage":
			enemy_speed_mult = 1.25
			enemy_hp_mult = 0.85
		"barren":
			diamond_mult = 0.7
			Game.add_diamonds(10)
		"overload":
			player.skill_cd_mult = 0.6
			player.max_hp = maxi(1, player.max_hp - 1)
			player.hp = mini(player.hp, player.max_hp)
		"glass":
			player.crit_chance = minf(player.crit_chance + 0.2, 0.8)
			player.speed_base *= 0.9
		"swarm":
			diamond_mult = 1.5
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
	var th: Dictionary = Data.theme_for_floor(Game.floor_num)
	if th.is_empty():
		if is_instance_valid(hud):
			hud.refresh_meta()
			hud.set_minimap_hidden(false)
		return
	_theme_rule = String(th.get("rule", ""))
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
	if _smoke and OS.get_environment("SMOKE_MAGMA_PROBE" if _theme_rule == "magma" else "SMOKE_TOXIC_PROBE") != "":
		player.hp = maxi(player.hp - 1, 1)
		player.hp_changed.emit(player.hp, player.max_hp)
		print("[SMOKE] %s tick hp=%d" % [_theme_rule, player.hp])
	else:
		player.take_damage(1, player.global_position + Vector2(0, -70))


## 源石共鸣：每拾取 1 个升级/遗物 +1 层，满 5 层触发全屏爆发
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
	# 源石共鸣核心（mx_resocore）：冲击波伤害 6 → 9
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
	hud.banner("源石共鸣 · 爆发！")
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
		"start", "treasure", "shop", "secret", "super_secret":
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
				# 表外测试钩：SMOKE_FORCE_SOVEREIGN=1 强制当前 Boss 房出熔潮主宰（低层即可验证）
				var sovereign := _is_sovereign_floor(Game.floor_num) \
					or OS.get_environment("SMOKE_FORCE_SOVEREIGN") != ""
				if sovereign:
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
		_apply_floor_theme()
		if nf >= 3:
			_milestone("floor3")
		var frng := _floor_rng(nf)
		dungeon = DungeonClass.generate(nf, frng, 7 + nf)
		_smoke_fingerprint(nf)
		_enter_room(dungeon.current, Vector2i.ZERO)
		_roll_calamity()
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


func on_slug_killed(slug) -> void:
	Game.sfx("die", Game.fx_rng.randf_range(0.9, 1.15), -6.0)
	Game.register_kill(slug.score_value)
	if Game.combo >= 20:
		_milestone("combo20")
	# 楼层主题「源石矿脉」：每次击杀额外掉 1 源石
	if _theme_rule == "vein":
		drop_pickup(slug.global_position, "diamond", 1)
	var xp: int = slug.xp_value
	var drops := mini(xp, 8)
	for i in drops:
		drop_pickup(slug.global_position, "diamond", int(ceil(xp / float(drops))))
	# 丰收印记：击杀额外 +1 源石
	if is_instance_valid(player) and player.harvester_active:
		drop_pickup(slug.global_position, "diamond", 1)
	# 回响击败增益：2s 攻速提升（规划 §5.2）
	if slug.variant == "echo":
		player.buff("echo_rate", 1.35, 2.0)
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
	# 源石共鸣核心（mx_resocore）解锁后，共鸣计数源改为源石 → 旧的「拾取升级 +1」不再计入
	if not player.has_resocore:
		add_resonance(1)
	if is_instance_valid(hud):
		hud.refresh_tags()
	if _smoke:
		print("[SMOKE] upgrade picked: ", id)
	Game.sfx("powerup", 1.1)


func give_player_weapon(id: String) -> void:
	player.give_weapon(id)
	hud.flash_toast("获得 %s（Q 切换）" % Weapons.DEFS[id]["name"])
	Game.sfx("secret")


func give_player_relic(id: String) -> void:
	Relics.apply(id, self)
	# 同上：mx_resocore 解锁后共鸣只由源石计数
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
