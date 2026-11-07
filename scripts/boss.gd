class_name PrismWarden
extends CharacterBody2D
## Sprint 11 B：主题相位 Boss「棱镜守望者 / Shiftwarden」
## 规格见 production/sprint-11/SPR11_B主题相位Boss_细化规格.md。
## 状态机 INTRO→ACTIVE→PHASE_2→PHASE_3→DYING；三阶段主题 = 纯函数（floor mod 8，零 rng）；
## 签名脉冲复用 F4 既有实体/机制（Boss 只作触发源，单一真相源）；
## 全部计时 Game.FIXED_DT（E6）；阶段增援路由既有 Game.rng 流 + 既有 squad 生成路径
## （Boss 战 rng 消耗已登记，E1 基线随本批重定）。

const BOSS_SKILL_INTERVAL := 3.0
const INTRO_DUR := 1.6
const SHIELD_RADIUS := 64.0
const DYING_DUR := 1.2
const ToxicCloudScript := preload("res://scripts/toxic_cloud.gd")
## 脉冲间隔参数化（C/boss2 覆写为更密节奏）；名字供 DUMP/结算区分
var skill_interval := 3.0
var boss_name := "棱镜守望者"

enum St { INTRO, ACTIVE, PHASE_2, PHASE_3, DYING }

var st: int = St.INTRO
var max_hp := 320.0
var hp := 320.0
var dmg := 2
var xp_value := 40
var score_value := 2000
var variant := "warden"
# Sprint 14 A：图鉴专用 id（不占 variant——boss2 的 variant="boss" 承载词缀必掉/宝箱/震屏
# 三条既有掉落契约，严禁改动；本字段只服务图鉴登记，boss2.setup 覆写为 "pyrothalassian"）
var codex_id := "prism_warden"
var dead := false
var speed := 42.0

var _floor_num := 1
var _phase_rules: Array = []     # 三阶段 rule（纯函数推导，零 rng）
var _phase_tints: Array = []     # 三阶段主题 tint（碎片颜色数据驱动）
var _reinforced := [false, false, false]

# E6 计时（全部 Game.FIXED_DT 累加，规格 §六）
var boss_cd_accum := 0.0
var phase_t := 0.0
var phase_dot_accum := 0.0
var _strafe_t := 0.0
var _strafe_dir := Vector2.ZERO
var _dying_t := 0.0
var _intro_shards_angle := 0.0

var core: Sprite2D
var shards: Array = []
var _hit_cd := 0.0
var _hit_flash := 0.0


## 三阶段主题纯函数（零 rng）：k=0/1/2 → FLOOR_THEMES 键（4–11）
static func phase_theme_index(floor_num: int, k: int) -> int:
	return 4 + (((floor_num - 4) + k) % 8)


func setup(floor_num: int) -> void:
	_floor_num = floor_num
	_phase_rules = []
	_phase_tints = []
	for k in 3:
		var key := phase_theme_index(floor_num, k)
		_phase_rules.append(String(Data.FLOOR_THEMES[key]["rule"]))
		_phase_tints.append(Data.FLOOR_THEMES[key]["tint"])
	# Boss 血量随层数成长（11 层首遇 ≈ 422）
	max_hp = 320.0 * (1.0 + (floor_num - 4) * 0.12)
	hp = max_hp


func _ready() -> void:
	if _phase_rules.is_empty():
		setup(Game.floor_num)
	motion_mode = CharacterBody2D.MOTION_MODE_FLOATING
	collision_layer = 4
	collision_mask = 1
	add_to_group("enemies")
	add_to_group("boss")

	var shape := CollisionShape2D.new()
	var circle := CircleShape2D.new()
	circle.radius = 16.0
	shape.shape = circle
	add_child(shape)

	core = Sprite2D.new()
	core.texture = Assets.g("boss_prism_core")
	add_child(core)
	# 三枚绕转碎片：颜色 = 各阶段主题 tint（k=0/1/2，数据驱动禁硬编码）
	for k in 3:
		var s := Sprite2D.new()
		s.texture = Assets.g("boss_prism_shard")
		s.modulate = _phase_tints[k]
		s.position = Vector2.from_angle(TAU * float(k) / 3.0) * 34.0
		add_child(s)
		shards.append(s)

	scale = Vector2(2, 2)
	Game.boss_hp_changed.emit(hp, max_hp)
	Game.sfx("boss_intro", 1.0, -2.0)
	if OS.get_environment("SMOKE_BOSS") != "":
		print("[SMOKE-BOSS] warden spawn floor=%d rules=%s tints_ok=%s thresholds=66/33" % [
			_floor_num, str(_phase_rules), str(_phase_tints.all(func(c: Color) -> bool: return c is Color))])


func _physics_process(_delta: float) -> void:
	# E6：Boss 全部计时按固定步推进（规格 §〇/§六）
	_tick(Game.FIXED_DT)
	move_and_slide()
	_intro_shards_angle += 1.5 * Game.FIXED_DT
	for k in shards.size():
		var s: Sprite2D = shards[k]
		s.position = Vector2.from_angle(_intro_shards_angle + TAU * float(k) / 3.0) * 34.0


func _tick(dt: float) -> void:
	phase_t += dt
	_hit_cd = maxf(0.0, _hit_cd - dt)
	if _hit_flash > 0.0:
		_hit_flash = maxf(0.0, _hit_flash - dt)
		if _hit_flash <= 0.0 and core != null:
			core.modulate = Color.WHITE
	match st:
		St.INTRO:
			velocity = Vector2.ZERO
			if phase_t >= INTRO_DUR:
				_enter_phase(0)
		St.ACTIVE, St.PHASE_2, St.PHASE_3:
			_tick_combat(dt)
			# HP 阈值只下不回退，每固定步检测（规格 §四）
			if st == St.ACTIVE and hp <= 0.66 * max_hp:
				_enter_phase(1)
			elif st == St.PHASE_2 and hp <= 0.33 * max_hp:
				_enter_phase(2)
		St.DYING:
			velocity = Vector2.ZERO


## 阶段内战斗行为（_tick 派生，dt 已是 FIXED_DT）
func _tick_combat(dt: float) -> void:
	var player: Node2D = Game.main.player
	if player == null or not is_instance_valid(player) or not Game.playing:
		velocity = Vector2.ZERO
		return
	var to_player := player.global_position - global_position
	var dist := to_player.length()
	var dir := to_player.normalized()

	# Boss 移动/游走：追击 + 既有 Game.rng 流抽取的游走方向（规格 §六，不新建 rng）
	_strafe_t -= dt
	if _strafe_t <= 0.0:
		_strafe_t = 2.5
		_strafe_dir = Vector2.from_angle(Game.rng.randf() * TAU)
	velocity = (dir + _strafe_dir * 0.45).normalized() * speed

	# 签名脉冲：每 skill_interval 按当前阶段主题从 Boss 位置扩环（复用 F4 机制）
	boss_cd_accum += dt
	if boss_cd_accum >= skill_interval:
		boss_cd_accum = 0.0
		var idx := 0 if st == St.ACTIVE else (1 if st == St.PHASE_2 else 2)
		_pulse_theme(String(_phase_rules[idx]), idx)

	# 接触伤害（与 slug 同路径：经 take_damage_from，环盾/词缀豁免在 player 侧判定）
	# 注意：_hit_cd 递减统一在 _tick（双重递减曾使接触冷却实际减半，已修）
	if _hit_cd <= 0.0 and dist < 22.0 and not player.dead:
		player.take_damage_from(dmg, self)
		_hit_cd = 0.8


func _enter_phase(k: int) -> void:
	st = [St.ACTIVE, St.PHASE_2, St.PHASE_3][k]
	phase_t = 0.0
	boss_cd_accum = 0.0
	# 碎片颜色切到本阶段主题 tint（玩家读色预判机制——规格 §一）
	if k < shards.size():
		shards[k].modulate = _phase_tints[k]
		shards[(k + 1) % 3].modulate = _phase_tints[k]
		shards[(k + 2) % 3].modulate = _phase_tints[k]
	Game.sfx("boss_phase", 1.0, -2.0)
	_call_reinforcement(k)
	_pulse_theme(String(_phase_rules[k]), k)
	if OS.get_environment("SMOKE_BOSS") != "":
		print("[SMOKE-BOSS] phase enter k=%d st=%s rule=%s tint=%s" % [
			k, str(st), String(_phase_rules[k]), str(_phase_tints[k])])


## 阶段增援：既有 Game.rng 流选取一支 Data.SQUADS 模板，经既有 spawn_slug 路径落地
## （不经 _telegraph_slug/_room_spawned——Boss 增援独立于房间刷怪预算，规格 §六）
func _call_reinforcement(k: int) -> void:
	var eligible: Array = []
	var total := 0
	for sid in Data.SQUADS:
		var s: Dictionary = Data.SQUADS[sid]
		if _floor_num < int(s.get("min_floor", 3)):
			continue
		eligible.append([sid, int(s.get("weight", 1))])
		total += int(s.get("weight", 1))
	if eligible.is_empty():
		return
	var r: int = Game.rng.randi_range(0, maxi(total - 1, 0))
	var picked: Dictionary = {}
	for e in eligible:
		r -= int(e[1])
		if r < 0:
			picked = Data.SQUADS[String(e[0])]
			break
	if picked.is_empty():
		return
	var delay := 0.0
	for m in picked.get("members", []):
		var count := int(m.get("count", 1))
		for i in count:
			var member: Dictionary = m
			var d := delay
			Game.safe_delay(d, self, false, func() -> void:
				if _game_over_check():
					return
				var pos: Vector2 = Game.main.clamp_to_arena(
					global_position + Vector2.from_angle(Game.rng.randf() * TAU) * 90.0)
				Game.main.spawn_slug(String(member["id"]), pos, String(member.get("affix", "")),
					bool(member.get("defuser", false))))
			delay += 0.25


func _game_over_check() -> bool:
	return Game.main == null or not is_instance_valid(Game.main) or Game.main._game_over


## 签名脉冲（复用 F4 既有机制，Boss 只作触发源——规格 §五 铁律）
func _pulse_theme(rule: String, k: int) -> void:
	var tint: Color = _phase_tints[k]
	match rule:
		"magma":
			# 扩散 DoT 脉冲环：8 个敌方毒雾云围成环（复用 ToxicCloud enemy 模式）
			# 岩浆橙云色 + E6 固定步（Boss 脉冲为新来源，须合规——主理人裁定）
			for i in 8:
				var c := ToxicCloudScript.new()
				c.life = 3.0
				c.puff_tint = Color(1.0, 0.6, 0.35, 0.55)
				c.fixed_step = true
				c.position = clamp_pos(global_position + Vector2.from_angle(TAU * i / 8.0) * 90.0)
				get_parent().add_child(c)
		"ice":
			# 减速斑块：玩家减速 + 环上冰花闪点
			if is_player_valid():
				Game.main.player.apply_slow(0.55, 3.0)
			for i in 6:
				Game.main.spawn_muzzle_spark(
					clamp_pos(global_position + Vector2.from_angle(TAU * i / 6.0) * 70.0), false)
		"vines":
			# 全向阻挡藤蔓：复用既有 prop_vine 生成路径
			for i in 4:
				Game.main._spawn_prop("vine",
					clamp_pos(global_position + Vector2.from_angle(TAU * i / 4.0 + 0.4) * 110.0))
		"toxic", "swamp":
			# 毒/沼 DoT 场：Boss 脚下 + 两翼敌方毒雾（主题色 + 固定步）
			for off in [Vector2.ZERO, Vector2(-70, 0), Vector2(70, 0)]:
				var c := ToxicCloudScript.new()
				c.life = 4.0
				c.puff_tint = _phase_tints[k]
				c.fixed_step = true
				c.position = clamp_pos(global_position + off)
				get_parent().add_child(c)
		"vein":
			# 矿脉富集：环位散落源石（拾取走既有磁吸/经验路径）
			for i in 5:
				Game.main.drop_pickup(
					clamp_pos(global_position + Vector2.from_angle(TAU * i / 5.0) * 90.0),
					"diamond", 1)
		"pressure":
			# 范围压迫脉冲：环内玩家被击退（复用 apply_blast_push）+ 震屏
			if is_player_valid():
				var pd: float = Game.main.player.global_position.distance_to(global_position)
				if pd < 200.0:
					Game.main.player.apply_blast_push(
						(Game.main.player.global_position - global_position).normalized() * 260.0)
			Game.shake(0.5)
			Game.sfx("boss_skill", 1.0, -4.0)
		"silent":
			# 静默层：能力压制 2 秒（F4 silent 仅影响生成 → 按规格降级为遗物压制 + 视觉压迫）
			if is_player_valid():
				Game.main.player.relic_suppress_t = 2.0
				Game.main.player.apply_slow(0.8, 2.0)
			Game.sfx("boss_skill", 0.8, -6.0)


func clamp_pos(p: Vector2) -> Vector2:
	if Game.main and is_instance_valid(Game.main):
		return Game.main.clamp_to_arena(p)
	return p


func is_player_valid() -> bool:
	return Game.main != null and is_instance_valid(Game.main) \
		and Game.main.player != null and is_instance_valid(Game.main.player) and not Game.main.player.dead


## 受击：Boss 血条走既有 boss_hp_changed；INTRO/DYING 免伤；阈值切换在 _tick 检测
func take_damage(amount: float, from_dir: Vector2, crit: bool) -> void:
	if dead or st == St.INTRO or st == St.DYING:
		return
	hp -= amount
	Game.boss_hp_changed.emit(maxf(hp, 0.0), max_hp)
	_hit_flash = 0.1
	if core != null:
		core.modulate = Color(2.0, 1.6, 1.6)
	if hp <= 0.0:
		hp = 0.0
		_die()


func _die() -> void:
	if st == St.DYING:
		return
	st = St.DYING
	dead = true
	collision_layer = 0
	collision_mask = 0
	velocity = Vector2.ZERO
	Game.sfx("boss_phase", 0.8)
	# 死亡碎裂 VFX：death_shard 四散 + 主题 tint（复用贴图，禁新粒子图）
	for i in 6:
		var s := Sprite2D.new()
		s.texture = Assets.g("boss_prism_death_shard")
		s.modulate = _phase_tints[mini(int(i / 2), 2)]
		s.position = global_position
		s.z_index = 50
		get_parent().add_child(s)
		var tw := s.create_tween()
		var dir := Vector2.from_angle(Game.rng.randf() * TAU) * Game.rng.randf_range(40.0, 110.0)
		tw.set_parallel(true)
		tw.tween_property(s, "position", s.position + dir, DYING_DUR)
		tw.tween_property(s, "rotation", Game.rng.randf_range(-6.0, 6.0), DYING_DUR)
		tw.tween_property(s, "modulate:a", 0.0, DYING_DUR)
		tw.chain().tween_callback(s.queue_free)
	Game.boss_hp_changed.emit(0.0, max_hp)
	Game.main.on_slug_killed(self)
	Game.safe_delay(DYING_DUR, self, false, queue_free)
