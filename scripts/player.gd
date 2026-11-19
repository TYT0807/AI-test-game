class_name Player
extends CharacterBody2D
## W：8 向移动 + 鼠标瞄准 + 双武器槽（Q 切换）+ 主动技能「极限过载」+ 遗物被动。

signal died
signal damaged(amount: int)
signal hp_changed(hp: int, max_hp: int)
signal bombs_changed(n: int, cap: int)
signal mag_changed(n: int, cap: int)
signal weapon_changed(slots: Array, slot: int)

const BulletScript := preload("res://scripts/bullet.gd")
const BombScript := preload("res://scripts/bomb.gd")
const WeaponsClass := preload("res://scripts/weapons.gd")
const ToxicCloudScript := preload("res://scripts/toxic_cloud.gd")

const BASE_SPEED := 95.0
const ACCEL := 14.0
const SKILL_CD := 22.0
const SKILL_DUR := 6.0

const BASE_MAX_HP := 3
var max_hp := BASE_MAX_HP
var hp := 3
var bombs := 2
var bomb_cap := 3
var bomb_level := 0

# 武器双槽
var weapon_slots: Array = ["zhushan", ""]
var slot := 0
var slot_mags := {"zhushan": 8}
var extra_count := 0        # 散射弹升级
var fire_rate_mult := 1.0   # 射速升级
var bullet_speed_mult := 1.0
var mag_bonus := 0          # 遗物加长弹匣

# 技能
var skill_cd := 0.0
var skill_cd_mult := 1.0
var skill_t := 0.0

# 遗物衍生字段
var relics: Array = []
var lifesteal_chance := 0.0
var thorns := false
var bounce_count := 0
var frost_chance := 0.0
var bullet_scale := 1.0
var bullet_dmg_mult := 1.0
var invuln_bonus := 0.0
var speed_base := 1.0
var terrain_speed_mult := 1.0   # 楼层主题地形：移速系数（毒沼 0.7，其余 1.0，由 game_main 设置）
var terrain_accel_mult := 1.0   # 楼层主题地形：加减速系数（冰面 0.3 = 打滑）
var crit_chance := 0.0
var _boss_slow_mult := 1.0   # Boss 冰面脉冲等来源的减速（E6 固定步计时）
var _boss_slow_t := 0.0
var relic_suppress_t := 0.0  # Boss 静默脉冲：压制主动遗物输入
var chain_chance := 0.0     # 连锁闪电
var poison_chance := 0.0    # 淬毒弹头
var shield_charges := 0     # 护盾层数（挡一次伤害）
# F2 主动遗物：开局可用、独立按键、E6 固定步冷却（定义见 Data.ACTIVE_RELICS）
var active_relic_cds := {}
# Sprint 12 A：印记注入字段（_apply_sigil_contract 绝对置位，幂等）
var harvester_active := false  # 丰收：击杀额外 +1 残响
var sigil_ward := false        # 守护：Boss 房受伤 -20%
var scholar_active := false    # 博学：每层首次清场 +2 地窖碎片
var dash_boost_mult := 1.0     # 疾行：冲刺距离/无敌帧倍率
var mag_cap_mult := 1.0        # 灾祸·弹药荒：弹匣容量系数（0.5，换层恢复）
var rate_buff_mult := 1.0      # 回响击败增益：攻速临时倍率（_tick_buffs 每帧复位）
# 回响镜像源：玩家轨迹缓冲（echo AI 读取；0.1s 采样 × 30 = 3 秒）
var trail: Array[Vector2] = []
var _trail_t := 0.0
var relic_shield_t := 0.0
var _dash_t := 0.0
var _dash_dir := Vector2.ZERO
var _relic_shield_orbit: Node2D = null
# F2/A 反应式词缀（Sprint 11 §三）：relic id → 附着词缀 id（每遗物 1 条）；效果由数据表驱动
var relic_suffixes := {}
var _suffix_cds := {}
## SPR7 局外解锁内容的持有标记（由 apply() 置位，不写玩家初始数值字段）
var pierce_bonus := 0       # 贯穿弹头 mx_pierce：额外穿透层数
var crit_boom := false      # 致命共振 mx_critboom：暴击时在命中点引爆
var has_resocore := false   # 残响共鸣核心 mx_resocore：共鸣计数源改为残响
var has_resoshield := false  # 谐振护盾 mr_resoshield：共鸣爆发加盾 + 免疫中毒
var has_kinetic := false     # 动能转换器 mr_kinetic：受击后 2 秒加速
var set_fire := false       # 火力套装：子弹命中溅射
var set_elem := false       # 元素套装：中毒敌人死亡爆炸
var set_surv := false       # 生存套装：濒死保护
var survive_used := false   # 濒死保护每局仅一次
var luck := 0.0             # 幸运：影响掉落
var magnet_radius := 60.0
var damage_mult := 1.0
var speed_mult := 1.0

var dead := false
var autopilot := false
var control_locked := false  # 过门淡入淡出期间锁操作
var _immortal := false

var _reload_t := 0.0
## 换弹复位**代数令牌**：每次起手换弹 +1，`give_weapon()` 也 +1（取消在飞回调）。
## 回调只在 `gen == _reload_gen` 时落账，否则认账失效——`_reload_t = 0.0` 清不掉已注册的 safe_delay。
var _reload_gen := 0
var _swap_t := 0.0
var _fire_cd := 0.0
# S38 T-N N10（HP-1 要求它先于任何近战逻辑落地）：近战族计数器，口径 V-E1a 的唯一观测面。
# 🔴 `static`：探针与 `_smoke_rngcount_probe()` 读同一对账本；本批不每局归零，
#    所以**所有判据都记前后差值**——拿绝对值断言会在第二局假红（那是判据的错，不是实现的错）。
static var melee_swings := 0
static var melee_rng_draws := 0
# S40-a／V-S4：近战清扫漂浮弹幕的两个计数器（命名照上面两行）。🔴 同为 `static`、同样**不每局归零**
#    ⇒ 判据一律记前后差值；⛔ 进存档、⛔ 进任何 E1 指纹串（实施单 A4／禁止事项 #9：持久状态＝指纹风险源）。
static var bullets_swept := 0
static var last_sweep_count := 0
# S40-c／C5：盾的三层窗口计数器，🔴 **三个分开记**（实稿 §3.2 末：只有总数的断言永远查不出
# 「所有攻击都返同一种东西」这种偷懒实现）。同为 `static`、同样**不每局归零** ⇒ 判据一律记前后差值；
# ⛔ 进存档、⛔ 进任何 E1 指纹串（禁止事项 #9）。
static var parry_count := 0
static var block_count := 0
static var shield_absorbed_dmg := 0
# S40-c／C1（裁定件 §1-C1 施工口径逐字）：完美窗＝**物理帧计数**，⛔ 写成秒的浮点常量。
# 🔴 `_parry_frames_left` 是 `_stance_t` 的**派生态**、不是第二套窗口计时：只由 `_stance_open()` 那一拍
# 置位、只在 RAISE 成立期间被读取（RAISE 一假 ⇒ PARRY/BLOCK 同时假，⛔「架式已关、完美窗还开着」双账）。
# ⛔ 持久化、⛔ 进 E1 指纹串。`_parry_hit_cd` 一字段承载 C2 的归属：**>0＝刚盾反成功**（此窗内后续弹走
# BLOCK）、**<0＝刚硬格成功**（此窗内不再进入第二次 BLOCK 结算，防八向环把 ×BLOCK_MULT 连乘八次）、
# **0＝可开新结算**；向零递减，⛔ 第二个 bool 位。
const PARRY_FRAMES := 12
const PARRY_HIT_CD := 6
var _parry_frames_left := 0
var _parry_hit_cd := 0
# S40-c／C6 **占位常数**（🔴 作者保留域②未点头）：取主理人推荐的 0.5，且按同一条裁定的后半句
# 推荐**允许硬格免伤到 0**（⛔ `maxi(1,…)`）。作者点头后单次替换，替换不算越权（裁定件 §1-C6 放行记录）。
const BLOCK_MULT := 0.5
var _invuln_t := 0.0
var _knock := Vector2.ZERO
var _aim := Vector2.DOWN
var _facing := "down"
var _last_facing := "down"
var _turn_t := 0.0
var _buffs := {}
var _wander := Vector2.ZERO
var _wander_t := 0.0
var _dbg_t := 0.0
# S38 B2a 架式窗口：开火置位，>0 期间 ⛔ 把 animation 从 "attack" 切到 walk/idle（实施单 T-P／P0 两处成因的正解）。
# 🔴 E6：新增计时一律走 `Game.FIXED_DT`，⛔ raw `delta`（实测喂进 `_update_anim()` 的 delta=0.03333
#    ＝1/60×`Engine.time_scale`2.0，≠FIXED_DT 0.016667；拿它倒计时＝窗口随 tick 疏密漂移，也踩线）。
var _stance_t := 0.0
# SMOKE_STANCE=1 的只读采样器（V-G2 验收＋反证刀靶）：只数帧，⛔ 写任何游戏状态、⛔ 抽随机数
# 🔴 `_sp_hold_t` 是探针**自己按规格重算**的窗口（同样 FIXED_DT 递减），⛔ 复用被测试的 `_stance_t`：
#    否则反证刀 P3（把代码侧窗口打成 0）会连判据一起打掉 ⇒ 恒绿。判据与实现必须两套账。
var _stance_probe := OS.get_environment("SMOKE_STANCE") != ""
var _sp_shots := 0
var _sp_pending := false
var _sp_hold_t := 0.0
var _sp_window := 0
var _sp_moving_window := 0
var _sp_leaks := 0
var _sp_leak_first := ""
var _sp_leaks_dead := 0
var _sp_len := 0.0
var _sp_delta_sum := 0.0
var _sp_samples := 0
var _sp_frame_max := -1
var _sp_gap_min := 1 << 30
var _sp_gap_max := 0
var _sp_gap_last := 0
var _sp_truncated := 0
var _sp_pf_last := -1
var _sp_last_frame := -1
var _sp_played_out := 0
var _sp_released := 0
# 承重计数：两处切口「想切走却被架式窗口按住」的帧数。⛔ 拿它当「守卫在工作」的充分证据它才算数——
# 只有它 > 0，leaks=0 才不是「根本没人想切走」的空转（实施单禁止事项 16 点名的就是这种）。
var _sp_blocks_idle := 0
var _sp_blocks_walk := 0
const _STANCE_DECLARED := 7
var _auto_swapped := false
var _nav_last := Vector2.ZERO      # 自动驾驶：上一采样点（查卡死用）
var _nav_t := 0.0                  # 自动驾驶：距上次采样的时间
var _avoid_t := 0.0                # 自动驾驶：绕障剩余时间
var _avoid_sign := 1.0             # 自动驾驶：绕障方向（左右交替）
var _door_wait := 0.0              # 自动驾驶：贴门却进不去计时

var sprite: AnimatedSprite2D


func _ready() -> void:
	motion_mode = CharacterBody2D.MOTION_MODE_FLOATING
	collision_layer = 2
	collision_mask = 1 | 4 | 64
	add_to_group("player")

	var shape := CollisionShape2D.new()
	var circle := CircleShape2D.new()
	circle.radius = 7.0
	shape.shape = circle
	shape.position = Vector2(0, 4)
	add_child(shape)

	sprite = AnimatedSprite2D.new()
	sprite.sprite_frames = Assets.w_frames()
	sprite.animation = "idle"
	sprite.play()
	add_child(sprite)

	hp_changed.emit(hp, max_hp)
	bombs_changed.emit(bombs, bomb_cap)
	mag_changed.emit(mag(), mag_cap())
	weapon_changed.emit(weapon_slots, slot)
	for id in Data.ACTIVE_RELICS:
		active_relic_cds[id] = 0.0
	if OS.get_environment("SMOKE_RELIC_PROBE") != "":
		_relic_probe.call_deferred()
	if OS.get_environment("SMOKE_SUFFIX") != "":
		_suffix_probe.call_deferred()
	if OS.get_environment("SMOKE_SIGIL_COVERAGE") != "":
		_sigil_coverage_probe.call_deferred()
	if OS.get_environment("SMOKE_SIGIL_OATH") != "":
		_sigil_oath_probe.call_deferred()
	if OS.get_environment("SMOKE_SHRINE") != "":
		_shrine_probe.call_deferred()
	if OS.get_environment("SMOKE_CODEX") != "":
		_codex_probe.call_deferred()
	if OS.get_environment("SMOKE_CODEX_BOON") != "":
		_codex_boon_probe.call_deferred()
	if OS.get_environment("SMOKE_THIRD_BOSS") != "":
		_third_boss_probe.call_deferred()
	if OS.get_environment("SMOKE_STANCE") != "":
		_stance_probe_report.call_deferred()
	if OS.get_environment("SMOKE_OATH") != "" or OS.get_environment("SMOKE_ECHO_CHAIN") != "":
		_oath_probe.call_deferred()
	if OS.get_environment("SMOKE_FLOOR_SIGN") != "" or OS.get_environment("SMOKE_FLAVOR") != "":
		_floor_sign_probe.call_deferred()
	if OS.get_environment("SMOKE_ABYSS") != "":
		_abyss_probe.call_deferred()
	if OS.get_environment("SMOKE_STREAK") != "":
		_streak_probe.call_deferred()
	if OS.get_environment("SMOKE_DAILY_SHARE") != "":
		_daily_share_probe.call_deferred()
	if OS.get_environment("SMOKE_LAYOUT") != "":
		_layout_probe.call_deferred()


# ---------------- 武器 ----------------

func cur_weapon() -> String:
	return weapon_slots[slot]


func cur_def() -> Dictionary:
	return WeaponsClass.DEFS[cur_weapon()]


func mag_cap() -> int:
	return mag_cap_of(cur_weapon())


## 配额上限按**指定武器 id** 算（灾祸 `mag_cap_mult` 一并折进去，V-C3 要求近战同样被压）。
## 🔴 与下面 `mag_cap_for()` 的区别是有意保留的：那条是捡起时的初始值（不折灾祸系数，
##    本批不改它——改了会挪动 reload 触发时机，进而挪动 autopilot 的抽取次数），
##    这条是复位回调的落点（必须折系数，否则弹药荒层复位完就是满配额）。
func mag_cap_of(id: String) -> int:
	return maxi(1, int((int(WeaponsClass.DEFS[id]["mag"]) + mag_bonus) * mag_cap_mult))


func mag() -> int:
	return int(slot_mags.get(cur_weapon(), mag_cap()))


func refresh_mag_cap() -> void:
	slot_mags[cur_weapon()] = mini(int(slot_mags.get(cur_weapon(), mag_cap())), mag_cap())
	mag_changed.emit(mag(), mag_cap())


func give_weapon(id: String) -> void:
	if not WeaponsClass.DEFS.has(id):
		# 未知 id 会在 mag_cap_for 直接崩，点名并回退
		Dev.err("weapon", "未知武器 id：%s（回退朱砂笔）" % id)
		id = "zhushan"
	if weapon_slots[1] == "":
		weapon_slots[1] = id
		slot_mags[id] = mag_cap_for(id)
		slot = 1
	elif weapon_slots[0] == "":
		weapon_slots[0] = id
		slot_mags[id] = mag_cap_for(id)
		slot = 0
	else:
		# 两槽满：替换当前槽
		slot_mags.erase(cur_weapon())
		weapon_slots[slot] = id
		slot_mags[id] = mag_cap_for(id)
	_reload_t = 0.0
	_reload_gen += 1
	weapon_changed.emit(weapon_slots, slot)


func mag_cap_for(id: String) -> int:
	return int(WeaponsClass.DEFS[id]["mag"]) + mag_bonus


func swap_weapon() -> void:
	if weapon_slots[1] == "" or _swap_t > 0.0:
		return
	_swap_t = 0.25
	_reload_t = 0.0
	slot = 1 - slot
	Game.sfx("reload", 1.3, -8.0)
	weapon_changed.emit(weapon_slots, slot)
	mag_changed.emit(mag(), mag_cap())


# ---------------- 技能：极限过载 ----------------

func activate_skill() -> void:
	if skill_cd > 0.0 or dead:
		return
	skill_cd = SKILL_CD * skill_cd_mult
	skill_t = SKILL_DUR
	Game.sfx("powerup", 1.2)
	Game.main.hud.flash_toast("极限过载！")


func skill_active() -> bool:
	return skill_t > 0.0


# ---------------- 主循环 ----------------

func _physics_process(delta: float) -> void:
	if autopilot and not dead:
		_dbg_t += delta
		if _dbg_t >= 2.0:
			_dbg_t = 0.0
			print("[SMOKE-P] hp=%d mag=%d weapon=%s skill=%.1f" % [hp, mag(), cur_weapon(), skill_cd])
	if dead:
		velocity = velocity.move_toward(Vector2.ZERO, 300.0 * delta)
		move_and_slide()
		return
	_tick_buffs(delta)
	_tick_timers(delta)
	_tick_relic_timers()
	# S40-c／C1：完美窗与冷却闸的逐拍递减（🔴 ⛔ raw `delta`、⛔ `Engine.time_scale`、⛔ `create_timer()`
	#    ＝整型帧计数，根本不碰时间；换算校验照 M-2：`round(0.20 / (1/60)) == 12`）。
	#    位置即口径：必须排在 `_update_aim_and_fire()` **之前**——起手那一拍要读到刚置位的 `PARRY_FRAMES`，
	#    窗长才是整整 12 拍；排在之后会被自己减成 11，窗长静默腰斩成 0.183s（冒烟 2× 下按真实秒时断言也必错）。
	if _parry_frames_left > 0:
		_parry_frames_left -= 1
	if _parry_hit_cd > 0:
		_parry_hit_cd -= 1
	elif _parry_hit_cd < 0:
		_parry_hit_cd += 1
	# 回响镜像源：轨迹缓冲采样（0.1s × 30 = 3 秒；echo AI 读取）
	_trail_t += Game.FIXED_DT
	if _trail_t >= 0.1:
		_trail_t = 0.0
		trail.append(global_position)
		if trail.size() > 30:
			trail.pop_front()

	# 安全钳：只在真正穿墙 8px 以上时硬拉，避免和物理去重叠打架
	if Game.main:
		var lim := Vector2(Game.main.ARENA_W, Game.main.ARENA_H) * 16.0
		if global_position.x < 8.0 or global_position.y < 8.0 \
				or global_position.x > lim.x - 8.0 or global_position.y > lim.y - 8.0:
			if autopilot:
				print("[SMOKE-P] clamped from ", global_position.round())
			global_position = Game.main.clamp_to_arena(global_position)
			_knock = Vector2.ZERO

	var input_vec := Input.get_vector("move_left", "move_right", "move_up", "move_down")
	if control_locked:
		input_vec = Vector2.ZERO
	elif autopilot:
		input_vec = _autopilot_move(delta)
		if Game.main and Game.main._transitioning:
			input_vec = Vector2.ZERO
	var target_vel := input_vec * BASE_SPEED * speed_mult * terrain_speed_mult * _boss_slow_mult * _reload_slow()
	# 冰面主题：terrain_accel_mult 降低 → 起步/停步都变慢（打滑手感）
	velocity = velocity.move_toward(target_vel + _knock, ACCEL * 60.0 * delta * terrain_accel_mult)
	# F2 冲刺闪避：冲刺期覆盖走位速度（~300px/s × 0.4s ≈ 120px），不受输入影响
	if _dash_t > 0.0:
		velocity = _dash_dir * 300.0
		if OS.get_environment("SMOKE_DASH_TRACE") != "":
			print("[SMOKE-DASH] t=%.3f pos=%s vel=%s" % [
				_dash_t, global_position.round(), velocity.round()])
	_knock = _knock.move_toward(Vector2.ZERO, 400.0 * delta)
	move_and_slide()

	if input_vec.length() > 0.1:
		_facing = _dir_to_facing(input_vec)
	_update_anim(delta)
	_update_aim_and_fire(delta)
	# S40-c／C3（实稿 §4.3 G10）：盾的扫描排在 `_update_aim_and_fire()` **之后**——同帧「刚挥的盾 vs 刚到的弹」
	# 由此有确定答案（本拍开的窗本拍就能吃到弹）。🔴 插在四个输入更新之间不改变它们的**相对**顺序
	# （anim→fire→bomb→skill→relic 一字未动），⛔ 把它挪到 :368 之后会改变与 relic 的先后，那是另一笔账。
	_update_shield_scan()
	_update_bomb_input()
	_update_skill_input()
	_update_relic_input()

	if autopilot and skill_cd <= 0.0 and _nearest_enemy() != null:
		activate_skill()
	if autopilot and not _auto_swapped and weapon_slots[1] != "":
		_auto_swapped = true
		swap_weapon()


func _reload_slow() -> float:
	return 0.6 if _reload_t > 0.0 else 1.0


func _dir_to_facing(v: Vector2) -> String:
	if absf(v.x) > absf(v.y):
		return "side"
	return "up" if v.y < 0 else "down"


func _update_anim(delta: float) -> void:
	if skill_active():
		sprite.modulate = Color(1.3, 1.05, 0.85) if fmod(skill_t, 0.3) > 0.15 else Color.WHITE
	elif _invuln_t <= 0.0:
		sprite.modulate = Color.WHITE

	# 转向灵敏：朝向一变立刻切动画并短暂加速播放，停步时朝准星
	var moving := velocity.length() > 8.0
	var want := _dir_to_facing(velocity) if moving else _dir_to_facing(_aim)
	if want != _last_facing:
		_last_facing = want
		_turn_t = 0.16
	_facing = want
	_turn_t = maxf(0.0, _turn_t - delta)
	sprite.speed_scale = 2.0 if _turn_t > 0.0 else 1.0

	# 架式窗口（B2a「未完不切走」）：窗口没走完，两处「切走 attack」的分支一律按住——这就是实施单 R3
	# 那两处成因（①移动即切回 walk、②interval 短于动画 ⇒ 一停手就回 idle）共同的收口点。
	# ⛔ 改帧数、⛔ 改 interval（T-P1／T-P2 另裁）：这里只按时序，不动任何美术资产与射速。
	# 🔴 「按住」这件事本身必须计数：leaks=0 既可能是守卫挡住了、也可能是根本没人想切走，两者天差地别；
	#    只有拦截次数不为 0，leaks=0 才是证据而不是空转（实施单禁止事项 16）。
	# 🔴 采样排在两处切口**之后**：判据要看的正是「这一帧的切换有没有把没挥完的一刀切走」。
	_stance_t = maxf(0.0, _stance_t - Game.FIXED_DT)

	var swing := _swing_open()
	if sprite.animation == "attack" and not sprite.is_playing():
		if swing:
			if _stance_probe:
				_sp_blocks_idle += 1     # 想回 idle 而被窗口按住＝守卫真有活干
		else:
			sprite.play("idle")
	if moving:
		var anim := "walk_down"
		match _facing:
			"up": anim = "walk_up"
			"side": anim = "walk_side"
		sprite.flip_h = _facing == "side" and velocity.x < 0.0
		var want_walk := sprite.animation != anim and not (sprite.animation == "attack" and sprite.is_playing())
		if want_walk:
			if swing:
				if _stance_probe:
					_sp_blocks_walk += 1
			else:
				sprite.play(anim)
				sprite.frame = 0
	elif sprite.animation != "idle" and sprite.animation != "attack":
		sprite.play("idle")

	if _stance_probe:
		_sample_stance(delta, moving)


## 动画自身时长：跟着图集走（4 格 ÷ 12fps = 0.333s），⛔ 写死秒数——补帧一变它自动跟。
## 🔴 现在只有探针拿它当「预算帧数」的分母做诊断；判据本身不看秒数（见 `_swing_open()`），
##    所以⛔ 把它误读成窗口长度来源，更⛔ 拿它反向去改 interval／帧数（T-P1／T-P2 另裁）。
func _attack_anim_len() -> float:
	if sprite.sprite_frames == null or not sprite.sprite_frames.has_animation("attack"):
		return 0.0
	return float(sprite.sprite_frames.get_frame_count("attack")) \
		/ maxf(float(sprite.sprite_frames.get_animation_speed("attack")), 1.0)


func _attack_last_cell() -> int:
	if sprite.sprite_frames == null or not sprite.sprite_frames.has_animation("attack"):
		return -1
	return sprite.sprite_frames.get_frame_count("attack") - 1


## 「这一刀还在架式窗口内」＝ 窗口没到期，或动画还在播（后者是兜底：窗口长度取
## max(动画时长, interval)，若图集 fps／射速改动使动画比窗口长，⛔ 让挥到一半的动作被切走）。
func _swing_open() -> bool:
	if _stance_t > 0.0:
		return true
	return sprite.animation == "attack" and sprite.is_playing()


## 开火＝近战 `_swing()`（B1 落地后共用此入口）置位架式窗口：长度＝本发该占的时序，
## 取「动画播完所需」与「这一发的射速间隔」的较大者——R3 的成因②正是 interval 短于动画。
## ⛔ 在这里改帧数／改 interval：T-P1／T-P2 是另外的待办，本批只动时序。
func _stance_open() -> void:
	_stance_t = maxf(_attack_anim_len(), _interval())
	_parry_frames_left = PARRY_FRAMES	# S40-c／C1：起手那一拍即开窗（裁定件 §1-C1 逐字「紧接一行」）


## 置位观测——枪械开火用，近战 B1 的 `_swing()` 落地后共用这一个入口（实施单 P0）。
## 🔴 `_sp_hold_t` 是探针**独立复算**的规格窗口（⛔ 读 `_stance_t`／⛔ 调 `_stance_open()`）：
##    判据若跟实现共用一个变量，反证刀 P3 就会把判据一起删掉 ⇒ 假绿（禁止事项 16）。
func _probe_stance_shot() -> void:
	if not _stance_probe:
		return
	if _sp_last_frame < 0:
		_sp_last_frame = _attack_last_cell()
	# 闩锁还开着就来下一发 ⇒ 上一发的架式窗口被这一发从头截断（射速快于动画，T-P2 那条线）
	if _sp_pending and _sp_hold_t > 0.0:
		_sp_truncated += 1
	_sp_pending = true
	_sp_hold_t = maxf(_attack_anim_len(), _interval())   # 与 `_stance_open()` 同规格、各记各的账
	_sp_shots += 1
	_sp_len = _attack_anim_len()
	if _sp_shots == 1:
		# 窗口时长是这条判据的分母：图集没登记 attack／格数为 0 ⇒ 守卫等于没上，
		# ⛔ 让「window=0」被读成「没问题」，必须把来源打出来。
		var nf := 0
		var fpsv := 0.0
		if sprite.sprite_frames != null and sprite.sprite_frames.has_animation("attack"):
			nf = sprite.sprite_frames.get_frame_count("attack")
			fpsv = sprite.sprite_frames.get_animation_speed("attack")
		print("[SMOKE-STANCE] 首发：len=%.4f 格=%d fps=%.1f 最后一格=%d frames=%s anim=%s" % [
			_sp_len, nf, fpsv, _sp_last_frame, sprite.sprite_frames != null, sprite.animation])
	# 🔴 发间隔用「物理帧数」量：实测 skill 生效时 _interval() = 0.30×0.35 ÷ 射速倍率 ≈ 0.067s
	#    ⇒ 两发只差 2～3 帧，而动画要 4 格 ÷12fps = 0.333s ⇒ 前一发必然被后一发从头截断。
	var pf := Engine.get_physics_frames()
	if _sp_pf_last >= 0:
		_sp_gap_last = pf - _sp_pf_last
		_sp_gap_min = mini(_sp_gap_min, _sp_gap_last)
		_sp_gap_max = maxi(_sp_gap_max, _sp_gap_last)
	_sp_pf_last = pf


func _sample_stance(delta: float, moving: bool) -> void:
	# 帧账两件套：mean_delta 是「为什么按秒算的收口上限永远撞不到」的分母，也是 E6 那根线的证据。
	_sp_delta_sum += delta
	_sp_samples += 1
	if not _sp_pending:
		# 闩锁关着＝窗口已交还。这条计数是**反向刀**：守卫若把角色冻死在 attack，
		# leaks 恒为 0 看着全绿，只有「交还过」能证伪它。
		if _sp_shots > 0 and sprite.animation != "attack" and sprite.animation != "die":
			_sp_released += 1
		return
	# 🔴 先递减、再判到期，最后才判漏：本拍代码侧 `_stance_t` 同样在 0，切口正当放开动画，
	#    顺序反了就会把「窗口到期的那次正当交还」读成漏帧（上一轮那 2 帧假红就是这么来的）。
	_sp_hold_t = maxf(0.0, _sp_hold_t - Game.FIXED_DT)
	if _sp_hold_t <= 0.0:
		_sp_pending = false
		return
	_sp_window += 1
	if sprite.animation != "attack":
		if sprite.animation == "die":
			_sp_leaks_dead += 1   # 死亡打断＝合法切断：⛔ 记成守卫失效，也⛔ 静默吞掉
			_sp_pending = false
		else:
			# 规格窗口内动画已不是 attack ⇒ 这一刀被真的切走了。判据只看探针自己的账（_sp_hold_t），
			# 与被测实现（_stance_t／_swing_open()）无耦合——否则反证刀一砍判据就跟着失效。
			_sp_leaks += 1
			if _sp_leak_first == "":
				_sp_leak_first = String(sprite.animation)
			_sp_pending = false
		return
	if sprite.frame > _sp_frame_max:
		_sp_frame_max = sprite.frame
	if moving:
		_sp_moving_window += 1
		if _sp_last_frame >= 0 and sprite.frame >= _sp_last_frame:
			_sp_played_out += 1   # 边走边挥且动画已到底格＝V-G2 的正身证据


## SMOKE_STANCE=1：V-G2「架式窗口内不把 attack 切走，窗口到期后照常交还」的机器验收。
## 🔴 前四条是覆盖前提：没跑到「够多帧的窗口＋移动中挥砍＋真播到底」，后面的零漏说明不了任何事——
##    那叫空转，⛔ 报成通过。判据用探针自己的 `_sp_hold_t`（⛔ 读被测试的 `_stance_t`）。
func _stance_probe_report() -> void:
	# 🔴 收口条件＝「跑到够多帧」，⛔「等够几秒」：实测战斗到第 337 物理帧（≈11.2s 游戏时间）
	#    才开第一枪，早先钉死 12.0s 定时器刚好卡在枪声刚起的位置 ⇒ 报告只截到「开场尾巴」。
	#    上限也用同一把尺（采样帧数）：按秒算的上限在坏构建里可能永远撞不到 ⇒ 报告行整段消失，
	#    [ERR]=0 被读成「绿」——沉默冒充通过，比假绿更坏。
	# 🔴 采样帧上限 1000：3200 进程帧 × 实测 0.45 物理帧/进程帧 ≈ 1440 物理帧——再钉高，反证刀
	#    P4（探针瞎掉、shots 永远 0）就撞不到收口，报告行整段消失，沉默冒充证据。
	#    `released == 0` 也纳入等待条件：窗口到期后「动画确实交还过」是防冻死的反向刀，
	#    但连射期间闩锁一直被下一发续期（实测发间隔 2～9 帧 < 窗口 20 帧），不等它就没样本。
	#    人已死就⛔ 再等（死后再无交还可言），让第 7 条自己报覆盖不足。
	var waited := 0.0
	while _sp_samples < 1000 and (
			_sp_shots < 12 or _sp_window < 40 or (_sp_released == 0 and not dead)):
		await get_tree().create_timer(1.0, true).timeout
		waited += 1.0
	var mean_delta := 0.0 if _sp_samples == 0 else _sp_delta_sum / _sp_samples
	var budget := 0.0 if mean_delta <= 0.0 else _sp_len / mean_delta
	var checked := 0
	checked += 1
	Dev.check(_sp_shots >= 12, "stance",
		"覆盖不足：窗口只置位 %d 次（须 ≥12 次；采样帧=%d／定时器轮=%d 已撞到上限）⇒ 判据没被跑到" % [
			_sp_shots, _sp_samples, int(waited)])
	checked += 1
	Dev.check(_sp_window >= 40, "stance",
		"覆盖不足：窗口内采样帧 = %d（须 ≥40）⇒ 守卫生效期间太短，漏 0 说明不了任何事" % _sp_window)
	checked += 1
	Dev.check(_sp_moving_window >= 4, "stance",
		"覆盖不足：边走边挥的窗口帧 = %d（须 ≥4）⇒ 移动分支这条成因链没被触发" % _sp_moving_window)
	checked += 1
	# 🔴 这条才是 V-G2 的正身：不数帧、只看动画自己有没有走到最后一格。
	#    tick 再稀也照样成立——「播完了」是可以直接观测的，「撑了几帧」不可以。
	Dev.check(_sp_last_frame >= 0 and _sp_played_out > 0, "stance",
		"移动窗口内 attack 从没够到最后一格（观测到的最大格 = %d／最后一格 = %d，够到底的帧 = %d）⇒「挥砍被移动打断」并未被证伪" % [
			_sp_frame_max, _sp_last_frame, _sp_played_out])
	checked += 1
	# 🔴 承重断言：守卫到底有没有活干。leaks=0 单独看是**恒真风险最高的那条**——没人试图切走时它
	#    自动成立（实施单禁止事项 16 点名的就是这种）。所以先证明「想切走而被挡住」发生过。
	Dev.check(_sp_blocks_idle + _sp_blocks_walk > 0, "stance",
		"两处切走点一次都没被守卫挡住（idle 拦截=%d／walk 拦截=%d）⇒ leaks=0 是空转不是证据，本跑【未测出】" % [
			_sp_blocks_idle, _sp_blocks_walk])
	checked += 1
	Dev.check(_sp_leaks == 0, "stance",
		"挥砍未完动画被切走 %d 帧（第一次切到「%s」）⇒ 架式窗口守卫失效" % [_sp_leaks, _sp_leak_first])
	checked += 1
	# 🔴 反向刀：守卫也不能把角色**冻死**在 attack——窗口到期后必须交还动画。
	#    只看 leaks==0 的话，「永远不切走」同样恒绿，这条是它唯一的对偶证据。
	Dev.check(_sp_released > 0, "stance",
		"架式窗口到期后动画从未交还（交还帧=0／采样帧=%d／定时器轮=%d／死亡打断=%d）⇒ 要么守卫把角色冻在 attack，要么这一跑全程连射／中途阵亡没留出样本，两种都⛔ 报成通过" % [
			_sp_samples, int(waited), _sp_leaks_dead])
	Dev.check(checked == _STANCE_DECLARED, "stance",
		"自校验失败: checked(%d) != declared(%d)——有断言被跳过" % [checked, _STANCE_DECLARED])
	print("[SMOKE-STANCE] shots=%d len=%.4f window=%d moving_window=%d leaks=%d blocks(idle/walk)=%d/%d released=%d 死亡打断=%d 闩锁未结算=%d done checked=%d declared=%d" % [
		_sp_shots, _sp_len, _sp_window, _sp_moving_window, _sp_leaks,
		_sp_blocks_idle, _sp_blocks_walk, _sp_released, _sp_leaks_dead,
		1 if _sp_pending else 0, checked, _STANCE_DECLARED])
	# 帧账：把「窗口为什么只摊上几帧」写在同一条日志里，⛔ 留给下一轮猜。
	# 实测 mean_delta=0.0333（1/60 × time_scale 2.0）、len=0.3333 ⇒ 单发预算 10 帧；
	# 但 skill 生效时 _interval()≈0.067s ⇒ 发间隔只有 2～3 帧，窗口首尾相接成一整段，
	# 所以 window 是「并集」而不是「每发 10 帧的和」——逐发帧数在这里没有意义。
	print("[SMOKE-STANCE] 帧账：samples=%d mean_delta=%.4f（1/60=%.4f, time_scale=%.1f, FIXED_DT=%.4f）⇒ 单发预算 %.2f 帧  物理帧=%d  格：%d/%d  播到底=%d  拦截 idle/walk=%d/%d" % [
		_sp_samples, mean_delta, 1.0 / 60.0, Engine.time_scale, Game.FIXED_DT, budget,
		Engine.get_physics_frames(), _sp_frame_max, _sp_last_frame, _sp_played_out,
		_sp_blocks_idle, _sp_blocks_walk])
	# 🔴 发间隔／截断数＝本批「不动帧数」裁定的直接代价：动画长 0.3333s 而射速 0.067s 一发，
	#    下一发必然在上一发放完之前重新 play("attack") ⇒ 从第 0 格重来。
	#    这条⛔ 当断言用（作者已裁「帧数本批不动，T-P1/T-P2 另议」），只把量摊开供复验。
	print("[SMOKE-STANCE] 发间隔（物理帧）min=%d max=%d 末段=%d／被下一发截断的开火=%d／%d（动画 %.4fs vs 实测射速 ≈%.3f～%.3fs）" % [
		0 if _sp_gap_min > 1 << 20 else _sp_gap_min, _sp_gap_max, _sp_gap_last,
		_sp_truncated, _sp_shots, _sp_len,
		(0 if _sp_gap_min > 1 << 20 else _sp_gap_min) * mean_delta, _sp_gap_max * mean_delta])


func _update_aim_and_fire(delta: float) -> void:
	var want_shoot := false
	if autopilot:
		var target := _nearest_enemy()
		if target:
			var tv: Vector2 = target.velocity if "velocity" in target else Vector2.ZERO
			var flight := global_position.distance_to(target.global_position) / maxf(250.0, 1.0)
			var lead := target.global_position + tv * flight
			_aim = (lead - global_position).normalized()
			if _aim == Vector2.ZERO:
				_aim = Vector2.DOWN
			want_shoot = true
	elif not control_locked:
		_aim = (get_global_mouse_position() - global_position).normalized()
		if _aim == Vector2.ZERO:
			_aim = Vector2.DOWN
		want_shoot = Input.is_action_pressed("shoot")

	_fire_cd -= delta
	if want_shoot and _fire_cd <= 0.0 and _reload_t <= 0.0 and _swap_t <= 0.0:
		# S38 T-N N2：按形态分派。🔴 形态名单只认 `Weapons.KIND_MELEE` 这一份（M2 的「校验与分派共用」
		#    落点）；在此另抄一遍 kind 字符串＝validate 查 A 表、player 认 B 表，两套账必漂移。
		# throw/wand 走 `_fire()` 不是兜底，是实稿 §3.3/§3.6 的裁定：它们本来就是弹道参数变体。
		# ⛔ 不动四个输入更新的调用顺序（_update_anim→本函数→bomb→skill→relic），同帧竞争裁定依赖它。
		if WeaponsClass.is_melee_kind(String(cur_def().get("kind", ""))):
			_swing()
		else:
			_fire()
		_fire_cd = _interval()


func _interval() -> float:
	var base: float = cur_def()["interval"]
	if skill_active():
		base *= 0.35
	return base / (fire_rate_mult * rate_buff_mult)


func _fire() -> void:
	if not skill_active() and mag() <= 0:
		_start_reload()
		return
	if not skill_active():
		slot_mags[cur_weapon()] = mag() - 1
		mag_changed.emit(mag(), mag_cap())
	sprite.play("attack")
	_stance_open()       # B2a：这一发起架式窗口，窗口内 ⛔ 把动画切回 walk/idle（近战 B1 的 `_swing()` 复用同一入口）
	_probe_stance_shot() # 探针记账（⛔ 参与任何游戏逻辑；SMOKE_STANCE 未开时首行即 return）
	var d := cur_def()
	var muzzle := global_position + _aim * 10.0 + Vector2(0, -6)
	Game.main.spawn_muzzle_spark(muzzle, _aim.x < 0.0)
	Game.sfx("shoot", Game.fx_rng.randf_range(0.92, 1.1), -4.0)
	var n: int = int(d["count"]) + extra_count
	var base_angle := _aim.angle()
	for i in n:
		var offset_deg := (float(i) - float(n - 1) * 0.5) * float(d["spread"])
		if n == 1 and not autopilot:
			offset_deg += Game.rng.randf_range(-1.5, 1.5)
		var dir := Vector2.from_angle(base_angle + deg_to_rad(offset_deg))
		var crit := Game.rng.randf() < crit_chance
		var dmg: float = float(d["dmg"]) * damage_mult * bullet_dmg_mult * (2.0 if crit else 1.0)
		var tint: Color = d["tint"]
		if crit:
			tint = Color(1.0, 0.35, 0.2)
		Game.main.spawn_player_bullet(
			muzzle, dir, float(d["speed"]) * bullet_speed_mult, dmg,
			int(d["pierce"]) + pierce_bonus, tint, bullet_scale * (1.25 if crit else 1.0),
			float(d["explosive"]), float(d["life"]), bounce_count, frost_chance,
			crit, crit_boom, bool(d.get("homing", false)), int(d.get("arc", 0)),
			int(d.get("cluster", 0)))
	if not skill_active() and mag() <= 0:
		_start_reload()


## S38 T-N：近战／长兵／盾共用的即时结算入口（口径 V-A2 说的「真·非弹幕」三种形态）。
## 与 `_fire()` 对称，但**一条子弹都不生成**：命中面是扇形几何扫描，伤害当场结在敌人身上。
## 🔴 HP-2 的物理事实（⛔ 用「近战不该抽随机数」的直觉去改这一段）：每一次**有效**执行恒消费
##    `Game.rng.randf()` **恰 1 次**，且不随命中数、敌人在否、autopilot、灾祸、主题、暴击结果变化。
##    0 次＝清场后整条随机流往前挪一格（指纹与冻结串全漂）；2 次＝往后挪两格。V-E1d 两把刀各咬一头。
func _swing() -> void:
	if not skill_active() and mag() <= 0:
		# N7／V-C1／V-E5：配额见底＝架式过载。这次输入**不算一次动作**，所以零抽取、零伤害、零计数。
		_start_reload()
		return
	var d := cur_def()
	var kind := String(d["kind"])
	# 🔴 这一发排在任何命中分支之前：抽进循环＝「命中几个抽几个」，抽进 `if hits > 0` 之后
	#    ＝「空挥不抽」（HP-3 禁第③条的字面形态），补进 start_run ＝「整局凑一次」（禁第①条）。
	var crit := Game.rng.randf() < crit_chance
	melee_rng_draws += 1
	melee_swings += 1
	if not skill_active():
		slot_mags[cur_weapon()] = mag() - 1
		mag_changed.emit(mag(), mag_cap())
	sprite.play("attack")
	_stance_open()          # B2a：与弹幕侧**同一个**架式窗口入口（实施单：⛔ 近战另起一套窗口）
	_probe_stance_shot()
	var reach := float(d["reach"])
	var half := deg_to_rad(float(d["arc_deg"])) * 0.5
	# N5／V-D1：乘区与弹幕侧同式；`bullet_dmg_mult` 名字带 bullet 但它是玩家侧全局伤害倍率，
	# 近战吃它是有意的（否则一半升级卡对近战失效）；⛔ `bullet_scale`——那是贴图尺寸。
	var dmg := float(d["dmg"]) * damage_mult * bullet_dmg_mult * (2.0 if crit else 1.0)
	var booms := []
	# N9／V-B7：spear 无视正面甲（实稿 §3.4）。🔴 只在本结算内有效，置位与清零夹住整个扫描，
	#    ⛔ 改 slug.take_damage 签名、⛔ 写进任何持久字段（跨帧残留＝下一发子弹也不减甲，红）。
	Game.main._melee_pierce_armor = kind == "spear"
	# N3：⛔ Area2D、⛔ 新碰撞层/掩码（HP-5）——方向级变更会与 bullet.gd 的 layer 8/mask 1|4|64 打架。
	for e in get_tree().get_nodes_in_group("enemies"):
		if not is_instance_valid(e) or e.dead or not e.has_method("take_damage"):
			continue
		var to_e: Vector2 = e.global_position - global_position
		if to_e.length() > reach:
			continue
		# `angle_difference` 而非减法：±180° 环绕处直接相减会把正后方读成「在扇内」。
		if absf(angle_difference(to_e.angle(), _aim.angle())) > half:
			continue
		# HP-4／V-B6：from_dir 必须是玩家指向敌人的单位向量——正面减伤只认它，⛔ Vector2.ZERO。
		e.take_damage(dmg, to_e.normalized(), crit)
		if kind == "shieldbash" and is_instance_valid(e) and not e.dead:
			e.apply_slow(0.6, 1.2)		# N8／V-B5；⛔ 击退（apply_blast_push 与 dash 位移区间纠缠）
		if crit and crit_boom:
			booms.append(e.global_position)
	Game.main._melee_pierce_armor = false
	# S40-a／V-S1／V-S2：近战清扫漂浮弹幕——第二条**独立**扫描，🔴 复用上面同一个 `reach`／`half`／`_aim`
	#    （实稿 §7 A1 未裁 ⇒ ⛔ 另算一套清扫半径引入第二个常数；⛔ Area2D／⛔ 新碰撞层与掩码，HP-5）。
	#    判据一律走 `Bullet.is_sweepable()` 单一真源，⛔ 在此内联重写那七个条件（M-5 唯一豁免＝该函数本身）。
	# 🔴 HP-3：整段零 `Game.rng` 消费——每次有效挥击恒 1 次抽取已由上面 `melee_rng_draws += 1` 那行钉死，
	#    本段再抽一次就变成「扫到抽 2 次、没扫到抽 1 次」＝命中相关的抽取（实稿 §2.3 禁止形态第①条）。
	# 排在清 `_melee_pierce_armor` **之后**：⛔ 让「扫弹」蹭到 spear 那条无视护甲的结算窗口。
	var swept := 0
	for b in get_tree().get_nodes_in_group("enemy_bullets"):
		# 🔴 `is_queued_for_deletion()` 不是多余的：同帧里环盾 `_tick_relic_shield()`（player.gd 的 64px 摧毁圈）
		#    已经 `queue_free()` 的弹**仍在组内且 `is_instance_valid` 仍为真**，只判 valid 挡不住
		#    ⇒ 一颗弹被环盾与刃风各记一次，V-S5「两套计数各自独立、无双计」当场破。
		if not is_instance_valid(b) or b.is_queued_for_deletion() or not b.is_sweepable():
			continue
		var to_b: Vector2 = b.global_position - global_position
		if to_b.length() > reach:
			continue
		if absf(angle_difference(to_b.angle(), _aim.angle())) > half:
			continue
		# A5 视觉：确定性迸星。`flip` 取「回指玩家的方向」`-b.vel.normalized()` 的 x 符号，
		#    符号约定照 `bullet.gd` 的 `ex.setup("spark", 0.35, vel.x < 0.0)`；⛔ 抽 `Game.rng`，
		#    要随机观感只准走 `Game.fx_rng`（`game_state.gd` 的 `reset_fx_rng()` 随局播种）。
		var back: Vector2 = -b.vel.normalized()
		Game.main.spawn_muzzle_spark(b.global_position, back.x < 0.0)
		b.queue_free()
		swept += 1
	bullets_swept += swept
	last_sweep_count = swept
	# 🔴 引爆排在清标志**之后**：`explode()` 内部同样遍历 enemies 调 take_damage，
	#    标志还置位时炸＝AoE 顺路无视护甲（V-B7 之外的同帧泄漏，一样红）。
	for p in booms:
		Game.main.explode(p, 42.0, dmg * 0.6, false)		# N6／V-D3：半径与系数逐字＝bullet.gd:119
	if not skill_active() and mag() <= 0:
		_start_reload()


## ── S40-c 盾与盾反：三层窗口（实稿 §3.1 结构 ＋ 裁定件 §1-C1/C2/C5）────────────────
## RAISE ⟺ kind=="shieldbash" ∧ `_stance_t > 0.0`。🔴 与 B2a 的架式守卫**共用** `_stance_t`，
## ⛔ 另起第二套窗口计时（§3.1：再起一个并行秒表必然出现「一个还开着、一个已关」的双账）。
## ⛔ 新增 action：`ACTION_DEFS` 真值 18 条一字不动——举盾＝「正拿着盾且刚挥过」，没有第四个键。
func _shield_raise() -> bool:
	return String(cur_def().get("kind", "")) == "shieldbash" and _stance_t > 0.0


## PARRY ⟺ RAISE ∧ 完美窗未耗尽。🔴 RAISE 一假这里必假：`_parry_frames_left` 是 `_stance_t` 的派生态，
## 单独读它会读出「架式已关、完美窗还开着」的双账（裁定件 §1-C1 那条 ⛔ 的实现位）。
func _shield_parry() -> bool:
	return _shield_raise() and _parry_frames_left > 0


## BLOCK ⟺ RAISE ∧ not PARRY（宽窗、减伤不免伤、无返还）。冷却闸在结算里查，不在这里。
func _shield_block() -> bool:
	return _shield_raise() and not _shield_parry()


## 盾的有效范围**直接取这面盾的近战 `reach`**（`sh_bulwark`=34px），⛔ 另立第二个半径常数：
## 与实施单 A2「⛔ 另算一套清扫半径」同源——多一个自由参数就多一处没人管的数值，而实稿 §3.2
## 写的 `R_shield` 在 C1~C6 里没有数值裁定，能复用已裁的 `reach` 就不该发明。
func _shield_reach() -> float:
	return float(cur_def().get("reach", 0.0))


## 每颗敌弹各自结算（裁定件 §1-C2 第 1~4 条），优先级照实稿 §3.2 步骤 3，⛔ 窗口内全吃。
func _update_shield_scan() -> void:
	if not _shield_raise():
		return
	# 步骤 3：环盾豁免在最前。`_tick_relic_shield()` 在本拍 `_tick_relic_timers()` 里已经先扫过一遍，
	# 且环盾半径 64 包住盾 reach 34 ⇒ 环盾开着时这里整面让路，这颗弹记给环盾，⛔ 既算盾反又算环盾摧毁。
	if relic_shield_t > 0.0:
		return
	var reach := _shield_reach()
	for b in get_tree().get_nodes_in_group("enemy_bullets"):
		if not is_instance_valid(b) or b.is_queued_for_deletion():
			continue
		# 🔴 判据复用 `is_sweepable()` 单一真源：实稿 §4.1 明写「T_LASER 的定义故意与 §2.1 互补，
		#    不可清扫的＝不可盾反的，⛔ 两套『什么算激光』的说法」⇒ ⛔ 在此内联重写那七个条件。
		if not b.is_sweepable():
			continue
		var to_b: Vector2 = b.global_position - global_position
		if to_b.length() > reach:
			continue
		if _parry_hit_cd > 0:
			_settle_block(b)		# 盾反后的 6 帧内后续弹走硬格（C2 第 2 条）
		elif _parry_hit_cd < 0:
			continue				# 硬格后的 6 帧内不再进入第二次 BLOCK 结算 ⇒ 正常受伤（C2 第 3 条）
		elif _parry_frames_left > 0:
			_settle_parry(b)
		else:
			_settle_block(b)


## PARRY：弹被消耗、不结算伤害、`parry_count` 单独记一条。
## 🔴 返还表（`T_DIRECT`/`T_FAN`/`T_HEAVY` 三行的返还物、`RETURN_MULT`、`apply_stun` 的消费点）
##    **不在本批**：裁定件 §6 放行的是「RAISE/BLOCK/PARRY 窗口／stun／计数」结构层，返还表随下一批开。
## ⛔ 用 `take_damage(0,…)` 表达免伤——0 点会走受伤函数的早退，等于白拿一次无敌帧语义，那是两套账。
func _settle_parry(b: Node) -> void:
	parry_count += 1
	_parry_hit_cd = PARRY_HIT_CD
	_shield_spark(b)
	b.queue_free()


## BLOCK：伤害 ×`BLOCK_MULT`（占位 0.5，C6 后半句推荐档＝**允许截断到 0**，⛔ `maxi(1,…)`）。
func _settle_block(b: Node) -> void:
	var raw := int(b.dmg)
	var after := int(float(raw) * BLOCK_MULT)
	var hit_from: Vector2 = b.global_position - b.vel.normalized() * 4.0	# 受伤方向口径逐字照 bullet.gd:153
	shield_absorbed_dmg += raw - after
	block_count += 1
	_parry_hit_cd = -PARRY_HIT_CD	# 负号＝这根冷却由硬格武装（见上面 `_parry_hit_cd` 的三态注释）
	_shield_spark(b)
	b.queue_free()
	if after > 0:
		take_damage(after, hit_from)


## 视觉照 A5 的确定性口径：⛔ `Game.rng`（盾反路径新增主流抽取＝禁止事项 #7），回指方向取 x 符号。
func _shield_spark(b: Node) -> void:
	var back: Vector2 = -b.vel.normalized()
	Game.main.spawn_muzzle_spark(b.global_position, back.x < 0.0)


func _start_reload() -> void:
	if _reload_t > 0.0 or mag() >= mag_cap():
		return
	# 🔴 复位归属在**开始时**钉死这把武器：旧写法在延时回调里取 `cur_weapon()`，
	#    过载期间切枪（V-C2 边界态）就会把配额灌进切过去的那把、原武器永远停在 0
	#    ——近战尤其致命：mag 归零＝永远卡在过载，第一次挥击都交不出去。
	#    更旧的写法还会往 `slot_mags` 塞新 key 留下跨层幽灵弹匣（主理人核验 §八.2）。
	var wid := cur_weapon()
	_reload_gen += 1
	var gen := _reload_gen
	_reload_t = float(cur_def()["reload"])
	Game.sfx("reload", 1.0, -3.0)
	Game.safe_delay(_reload_t, self, false, func() -> void:
		if dead or gen != _reload_gen:
			# 代数令牌：`give_weapon()` 清 `_reload_t` 取消不了已在飞的 safe_delay 回调，
			# 只有让回调自己认账失效，才不会"过载中捡武器 ⇒ 旧槽白得一次复位"。
			return
		slot_mags[wid] = mag_cap_of(wid)
		mag_changed.emit(mag(), mag_cap()))


func _update_bomb_input() -> void:
	var want_bomb := false
	var target := global_position + _aim * 90.0
	if autopilot:
		if _nearest_enemy() != null and bombs > 0 and Game.rng.randf() < 0.004:
			want_bomb = true
			var t := _nearest_enemy()
			target = t.global_position if t else target
	else:
		want_bomb = Input.is_action_just_pressed("bomb")
		if want_bomb:
			target = get_global_mouse_position()
			if target.distance_to(global_position) > 130.0:
				target = global_position + (target - global_position).normalized() * 130.0
	if want_bomb and bombs > 0 and not dead:
		bombs -= 1
		bombs_changed.emit(bombs, bomb_cap)
		var bomb := BombScript.new()
		bomb.setup(global_position, target, 46.0 + 8.0 * bomb_level, 6.0 + 2.0 * bomb_level)
		Game.main.entities.add_child(bomb)


func _update_skill_input() -> void:
	if control_locked:
		return
	if Input.is_action_just_pressed("skill"):
		activate_skill()
	if Input.is_action_just_pressed("swap"):
		swap_weapon()


# ---------------- F2 主动遗物（Sprint 10 §十一）----------------

func apply_slow(mult: float, dur: float) -> void:
	_boss_slow_mult = mult
	_boss_slow_t = dur


func _update_relic_input() -> void:
	if control_locked or relic_suppress_t > 0.0:
		return
	for id in Data.ACTIVE_RELICS:
		var ka: String = String(Data.ACTIVE_RELICS[id]["key_action"])
		if Input.is_action_just_pressed(ka):
			_activate_relic(id)


## 激活遗物：冷却检查 → 按效果分派 → 置冷却；返回证据 dict（探针/调试用）
func _activate_relic(id: String) -> Dictionary:
	var def: Dictionary = Data.ACTIVE_RELICS[id]
	if float(active_relic_cds.get(id, 0.0)) > 0.0:
		return {"blocked": true}
	active_relic_cds[id] = float(def["cd"])
	var kind := String(def["effect_kind"])
	var ev := {}
	match kind:
		"shield":
			relic_shield_t = float(def["duration"])
			_ensure_relic_shield()
			ev = {"shield": true}
		"dash":
			_dash_dir = _aim if _aim != Vector2.ZERO else Vector2.DOWN
			_dash_t = float(def["duration"]) * dash_boost_mult
			grant_invuln(_dash_t + 0.05)
			if Game.main != null and is_instance_valid(Game.main):
				Game.main.oath_count("dashes")   # Sprint 16 A：誓约计数（残影连闪）
			# F2/A 反应词缀触发点：冲刺开始（ON_DASH_START）
			_fire_relic_suffixes("dash_dodge", "ON_DASH_START", global_position)
			ev = {"dash": true}
		"volley":
			var n := 8
			for i in n:
				var vdir := Vector2.from_angle(TAU * float(i) / float(n))
				var crit := Game.rng.randf() < crit_chance
				var dmg := 1.0 * damage_mult * bullet_dmg_mult * (2.0 if crit else 1.0)
				Game.main.spawn_player_bullet(global_position + vdir * 12.0, vdir,
					250.0 * bullet_speed_mult, dmg, 0, Color(1.0, 0.8, 0.4), 1.0, 0, 0.0, 0, 0)
			# F2/A 反应词缀触发点：齐射开火（ON_VOLLEY_FIRE）
			_fire_relic_suffixes("volley_burst", "ON_VOLLEY_FIRE", global_position)
			ev = {"bullets": n}
		"toxic":
			if Game.main == null or not is_instance_valid(Game.main):
				return ev
			var cloud := ToxicCloudScript.new()
			cloud.setup_friendly(120.0, float(def["duration"]), 0.5, 0.5)
			cloud.position = Game.main.clamp_to_arena(global_position + _aim * 80.0)
			Game.main.entities.add_child(cloud)
			ev = {"cloud": true}
	Game.flash_toast(String(def["name"]))
	Game.sfx("powerup", 1.3, -4.0)
	return ev


## 主动遗物计时（E6 固定步：冷却/环盾/冲刺全部按 FIXED_DT 递减）
func _tick_relic_timers() -> void:
	for id in active_relic_cds:
		active_relic_cds[id] = maxf(0.0, float(active_relic_cds[id]) - Game.FIXED_DT)
	if relic_shield_t > 0.0:
		relic_shield_t = maxf(0.0, relic_shield_t - Game.FIXED_DT)
		_tick_relic_shield()
		if relic_shield_t <= 0.0 and _relic_shield_orbit != null:
			_relic_shield_orbit.queue_free()
			_relic_shield_orbit = null
	elif _relic_shield_orbit != null and is_instance_valid(_relic_shield_orbit):
		_relic_shield_orbit.queue_free()
		_relic_shield_orbit = null
	if _dash_t > 0.0:
		_dash_t = maxf(0.0, _dash_t - Game.FIXED_DT)
		if _dash_t <= 0.0:
			velocity = Vector2.ZERO  # 冲刺结束硬停（闪避语义，消除滑步过冲）
	if _boss_slow_t > 0.0:
		_boss_slow_t = maxf(0.0, _boss_slow_t - Game.FIXED_DT)
		if _boss_slow_t <= 0.0:
			_boss_slow_mult = 1.0
	if relic_suppress_t > 0.0:
		relic_suppress_t = maxf(0.0, relic_suppress_t - Game.FIXED_DT)
	for sid in _suffix_cds:
		_suffix_cds[sid] = maxf(0.0, float(_suffix_cds[sid]) - Game.FIXED_DT)


## 环盾：旋转图标 + 半径 64 内摧毁敌弹（接触伤害豁免在 take_damage_from）
func _tick_relic_shield() -> void:
	if _relic_shield_orbit == null or not is_instance_valid(_relic_shield_orbit):
		_ensure_relic_shield()
	_relic_shield_orbit.rotation += 4.0 * Game.FIXED_DT
	var destroyed := 0
	for b in get_tree().get_nodes_in_group("enemy_bullets"):
		if is_instance_valid(b) and b.global_position.distance_to(global_position) < 64.0:
			b.queue_free()
			destroyed += 1
			Game.sfx("hit", 1.7, -14.0)
			# F2/A 反应词缀触发点：环盾摧毁敌弹（ON_SHIELD_BREAK）
			_fire_relic_suffixes("orb_shield", "ON_SHIELD_BREAK", b.global_position)
	if destroyed > 0 and OS.get_environment("SMOKE_RELIC_PROBE") != "":
		print("[SMOKE-RELIC] shield destroyed %d enemy bullets" % destroyed)


func _ensure_relic_shield() -> void:
	if _relic_shield_orbit != null and is_instance_valid(_relic_shield_orbit):
		return
	_relic_shield_orbit = Node2D.new()
	_relic_shield_orbit.z_index = 8
	for i in 3:
		var s := Sprite2D.new()
		s.texture = Assets.xicon("guard")
		s.scale = Vector2(1.1, 1.1)
		s.position = Vector2.from_angle(TAU * float(i) / 3.0) * 64.0
		_relic_shield_orbit.add_child(s)
	add_child(_relic_shield_orbit)


func _relic_probe() -> void:
	await get_tree().create_timer(0.8, true).timeout
	var id := OS.get_environment("SMOKE_RELIC_PROBE")
	if not Data.ACTIVE_RELICS.has(id):
		print("[SMOKE-RELIC] unknown id: ", id)
		return
	# 等敌情：最近敌人进入 250px 才激活（环盾的摧毁目标 / 毒云的覆盖对象才存在）
	var waited := 0.0
	while waited < 30.0:
		var e := _nearest_enemy()
		if e != null and e.global_position.distance_to(global_position) < 250.0:
			break
		await get_tree().create_timer(0.5, true).timeout
		waited += 0.5
	var before := global_position.round()
	# D1 补验口径：测量期锁走位（主理人指令），位移只可能来自冲刺本身
	control_locked = true
	var ev := _activate_relic(id)
	var cd_left := float(active_relic_cds.get(id, 0.0))
	await get_tree().create_timer(0.7, true).timeout
	var moved := global_position - before
	control_locked = false
	print("[SMOKE-RELIC] id=%s ev=%s cd_left=%.2f moved=%s |moved|=%.1f shield_t=%.1f" % [
		id, str(ev), cd_left, str(moved.round()), moved.length(), relic_shield_t])


# ---------------- F2/A 反应式词缀（Sprint 11 §三）----------------

## 附着词缀到对应遗物（每遗物 1 条，新词缀替换旧词缀）；返回证据 dict
func attach_suffix(sid: String) -> Dictionary:
	var def: Dictionary = Data.RELIC_SUFFIXES.get(sid, {})
	if def.is_empty():
		Dev.err("suffix", "未知词缀 id：%s" % sid)
		return {"attached": false}
	var relic: String = String(def["relic"])
	relic_suffixes[relic] = sid
	Game.mark_codex("suffixes", sid)   # Sprint 13 C：已获词缀登记（图鉴）
	if OS.get_environment("SMOKE_SUFFIX") != "":
		print("[SMOKE-SUFFIX] attached %s to %s" % [sid, relic])
	if Game.main and is_instance_valid(Game.main.hud):
		Game.main.hud.refresh_suffixes(relic_suffixes)
	return {"attached": true, "relic": relic, "name": String(def["name"])}


## 触发点统一入口：查附着的词缀 → 冷却检查 → 按 effect 分派（效果由状态确定，每帧零新 rng）
func _fire_relic_suffixes(relic_id: String, trigger: String, pos: Vector2) -> Dictionary:
	var sid: String = String(relic_suffixes.get(relic_id, ""))
	var ev := {}
	if sid == "":
		return ev
	var def: Dictionary = Data.RELIC_SUFFIXES.get(sid, {})
	if def.is_empty() or String(def.get("trigger", "")) != trigger:
		return ev
	if float(_suffix_cds.get(sid, 0.0)) > 0.0:
		return {"cooldown": true}
	_suffix_cds[sid] = float(def.get("cd", 2.0))
	if Game.main != null and is_instance_valid(Game.main):
		Game.main.oath_count("suffix_fires")   # Sprint 16 A：誓约计数（双持共鸣/兼修并蓄）——触发即计
	match String(def.get("effect", "")):
		"theme_hazard":
			if Game.main == null or not is_instance_valid(Game.main):
				return ev
			var tint: Color = Data.theme_for_floor(Game.floor_num).get("tint", Color(0.6, 0.9, 0.9))
			var cloud := ToxicCloudScript.new()
			# triggerless=true：词缀云不再触发 ON_POISON_TICK（防 miasma 无限连锁）
			cloud.setup_friendly(70.0, 2.0, 0.6, 0.5, tint, true)
			cloud.position = Game.main.clamp_to_arena(pos)
			Game.main.entities.add_child(cloud)
			ev = {"cloud": true}
		"heal":
			var amt := int(def.get("amount", 1))
			heal(amt)
			ev = {"heal": amt}
		"slow_all":
			var slowed := 0
			for e in get_tree().get_nodes_in_group("enemies"):
				if is_instance_valid(e) and not e.dead:
					e.apply_slow(float(def.get("slow", 0.5)), float(def.get("slow_dur", 2.0)))
					slowed += 1
			ev = {"slowed": slowed}
		"brief_shield":
			shield_charges = mini(shield_charges + 1, 3)
			ev = {"shield_charge": shield_charges}
	Game.sfx("suffix", 0.9, -6.0)
	return ev


## SMOKE_SUFFIX=1：词缀链路自测（附着 → 触发 → 冷却拦截），表外不进 E1
## 【Sprint 17 B 断言盘点】全为「验效果型」：触发返回字典的真值 / 冷却拦截 / trigger 不匹配空返回 /
## 护盾层数差值。无恒过守卫、无「只验标志」（shield_charges 是数值断言）。
func _suffix_probe() -> void:
	await get_tree().create_timer(0.8, true).timeout
	attach_suffix("s_frostburst")
	var ev1 := _fire_relic_suffixes("orb_shield", "ON_SHIELD_BREAK", global_position)
	Dev.check(ev1.get("cloud", false) == true, "suffix", "霜爆触发生成主题危害云：%s" % str(ev1))
	var ev2 := _fire_relic_suffixes("orb_shield", "ON_SHIELD_BREAK", global_position)
	Dev.check(ev2.get("cooldown", false) == true, "suffix", "冷却期内二次触发被拦截：%s" % str(ev2))
	var wrong := _fire_relic_suffixes("orb_shield", "ON_DASH_START", global_position)
	Dev.check(wrong.is_empty(), "suffix", "trigger 不匹配时不出效果：%s" % str(wrong))
	shield_charges = 0   # 基线清零：开局图鉴 boon 可能已给护盾（Sprint 14 C），断言只验词缀自身效果
	attach_suffix("s_bulwark")
	_fire_relic_suffixes("dash_dodge", "ON_DASH_START", global_position)
	Dev.check(shield_charges == 1, "suffix", "小壁垒给予 1 层护盾：%d" % shield_charges)
	print("[SMOKE-SUFFIX] done")


## SMOKE_SIGIL_COVERAGE=1：9 枚印记逐枚覆盖断言（核验 #1 修复批：每枚验证可观察效果）
## 【Sprint 17 B 断言盘点】全为「验效果型」：每枚验可观察数值/状态差值（max_hp / diamond_mult /
## mag_cap_mult / frail 削减与还原），非标志位；结束恢复印记存档现场。
func _sigil_coverage_probe() -> void:
	await get_tree().create_timer(0.6, true).timeout
	var bak := {"shards": int(Game.sigils["shards"]), "unlocked": (Game.sigils["unlocked"] as Array).duplicate(),
		"equipped": Game.equipped_sigil()}
	for id in Data.SIGILS:
		Game.equip_sigil(String(id))
		Game.main._apply_sigil_contract()
		var ok := false
		var detail := ""
		match id:
			"vigor":
				ok = max_hp == Player.BASE_MAX_HP + 1
				detail = "max_hp=%d" % max_hp
			"arsenal":
				ok = weapon_slots[1] == "liechi"
				detail = "slot1=%s" % weapon_slots[1]
			"purse":
				ok = Game.diamonds == 15
				detail = "diamonds=%d" % Game.diamonds
			"kindred":
				ok = is_instance_valid(Game.main._ally)
				detail = "ally=%s" % str(ok)
			"bulwark":
				ok = relic_shield_t >= 2.5
				detail = "shield_t=%.1f" % relic_shield_t
			"sprinter":
				ok = dash_boost_mult == 1.3
				detail = "dash=%s" % str(dash_boost_mult)
			"harvester":
				ok = harvester_active
				detail = "flag=%s" % str(harvester_active)
			"ward":
				ok = sigil_ward
				detail = "flag=%s" % str(sigil_ward)
			"scholar":
				ok = scholar_active
				detail = "flag=%s" % str(scholar_active)
		Dev.check(ok, "sigil_cov", "%s %s" % [id, detail])
	# 核验 #2/#3 单测（时序：先灾祸、后层内成长、再换层还原）
	var pre := max_hp
	Game.main._calamity = "frail"
	Game.main._apply_calamity()
	Dev.check(max_hp < pre, "sigil_cov", "frail 削减: %d→%d" % [pre, max_hp])
	max_hp += 1   # 层内成长
	Game.main._clear_calamity_effects()
	Dev.check(max_hp == pre + 1, "sigil_cov", "frail 还原保成长: max_hp=%d" % max_hp)
	var dm: float = Game.main.diamond_mult
	Game.main.diamond_mult = 1.0   # Sprint 23 附带：确定性基线——多探针并发下 dm 可能已被其它灾祸路径削减到 ≤0.7，相对断言会间歇假红（stash 实证）
	Game.main._calamity = "scarce_ore"
	Game.main._apply_calamity()
	Dev.check(Game.main.diamond_mult < 1.0, "sigil_cov", "scarce_ore 削减")
	Game.main._clear_calamity_effects()
	Dev.check(Game.main.diamond_mult == 1.0, "sigil_cov", "scarce_ore 还原")
	Game.main.diamond_mult = dm   # 还原探针前现场
	# 终审补·层流程①：无灾祸层 clear 完全不碰倍率（modifier 全局倍率不得被换层抹掉）
	Game.main._calamity = ""
	var dm0: float = Game.main.diamond_mult
	var mc0: float = mag_cap_mult
	Game.main.diamond_mult = 1.5   # 模拟 swarm modifier
	mag_cap_mult = 1.7             # 模拟任意在局倍率
	Game.main._clear_calamity_effects()
	Dev.check(Game.main.diamond_mult == 1.5 and mag_cap_mult == 1.7, "sigil_cov",
		"层流程①: 无灾祸 clear 不动倍率 dm=%s mc=%s" % [Game.main.diamond_mult, mag_cap_mult])
	# 终审补·层流程②：swarm 1.5 跨 3 层恒为 1.5（无灾祸层 / scarce_ore 层 / frail 层各一）
	for i in 3:
		if i == 1:
			Game.main._calamity = "scarce_ore"
			Game.main._apply_calamity()
		elif i == 2:
			Game.main._calamity = "frail"
			Game.main._apply_calamity()
		Game.main._clear_calamity_effects()
		Dev.check(Game.main.diamond_mult == 1.5, "sigil_cov",
			"层流程②: 跨层 %d diamond_mult=%s" % [i + 1, Game.main.diamond_mult])
	Game.main.diamond_mult = dm0
	mag_cap_mult = mc0
	# 终审补·边界③：max_hp 已到钳制下限 2 时 apply 必须存「实际」削减量，clear 不得凭空 +1
	var hp0 := max_hp
	max_hp = 2
	Game.main._calamity = "frail"
	Game.main._apply_calamity()
	Dev.check(max_hp == 2 and Game.main._calamity_frail_cut == 0, "sigil_cov",
		"边界③: 钳制层 cut 存实际值 max_hp=%d cut=%d" % [max_hp, Game.main._calamity_frail_cut])
	Game.main._clear_calamity_effects()
	Dev.check(max_hp == 2, "sigil_cov", "边界③: clear 无凭空 +1 max_hp=%d" % max_hp)
	max_hp = hp0
	Game.main._calamity = ""
	print("[SMOKE-SIGIL-COV] done")
	# 恢复印记存档现场（测试不污染玩家进度）
	Game.sigils = bak
	Game.save_sigils()


## SMOKE_SIGIL_OATH=1：印记页「上局誓约」一行（Sprint 18 阶段二 C）
## 【断言盘点 · 全部「验效果型」，验渲染不验字段】
##   ① 真调 `menu.show_page("sigils")` 重建印记页 → 遍历 `_rows` 找 Label，断言文本含
##      「上局誓约」+ name 实值 + 兑现态 + 进度 (cur/need) —— 不是"字段存在"而是"渲染出来"；
##   ② `last_run.oath` 为空 → 该 Label **不创建**（非建后隐藏）；
##   ③ 零副作用：`show_page("sigils")` 前后 `Game.codex` 深拷贝全等（**同步比对，不跨 await**，
##      避免与同期探针的 codex 写入互相干扰）。
## 探针自设语境（改内存 oath、切页），结束全部还原：oath 原值回填、切回原页。
func _sigil_oath_probe() -> void:
	await get_tree().create_timer(0.6, true).timeout
	var gm: Node = Game.main
	if gm.menu == null or not is_instance_valid(gm.menu):
		Dev.check(false, "sigil_oath", "探针前置失败：menu 未就绪")
		return
	var menu: Node = gm.menu
	var bak_page: String = String(menu._page)
	var bak_oath = Game.codex["last_run"].get("oath", {})
	Game.codex["last_run"]["oath"] = {"id": "keep_hp", "name": "守血",
		"desc": "生命上限不低于 5", "done": true, "cur": 5, "need": 5}
	# ③ 零副作用（同步段：构建页面不得改动 codex 任何字段）
	var snap: Dictionary = Game.codex.duplicate(true)
	menu.show_page("sigils")
	Dev.check(Game.codex == snap, "sigil_oath", "页面构建零副作用（Game.codex 前后深等）")
	await get_tree().process_frame
	# ① 有 oath → 渲染出「上局誓约」行，且含实值
	var hit := _find_label_containing(menu._rows, "上局誓约")
	Dev.check(hit != null, "sigil_oath", "有 last_run.oath → 印记页出现「上局誓约」行")
	if hit != null:
		var t: String = String(hit.text)
		Dev.check(t.begins_with("上局誓约 · "), "sigil_oath",
			"用词为「上局誓约」（与图鉴页「本局誓约」区分）：%s" % t)
		Dev.check(t.contains("守血") and t.contains("已兑现") and t.contains("（5/5）"),
			"sigil_oath", "上局誓约行含 name/兑现态/进度实值：%s" % t)
	# ② 无 oath → 整个 Label 不创建
	Game.codex["last_run"].erase("oath")
	menu.show_page("sigils")
	await get_tree().process_frame
	Dev.check(_find_label_containing(menu._rows, "上局誓约") == null, "sigil_oath",
		"last_run.oath 为空 → 该行不创建（非建后隐藏）")
	# 还原：oath 原值回填 + 切回原页
	if (bak_oath as Dictionary).is_empty():
		Game.codex["last_run"].erase("oath")
	else:
		Game.codex["last_run"]["oath"] = bak_oath
	menu.show_page(bak_page)
	print("[SMOKE-SIGIL-OATH] done")


func _find_label_containing(root: Node, needle: String) -> Label:
	for c in root.get_children():
		if c is Label and String((c as Label).text).contains(needle):
			return c as Label
		var d := _find_label_containing(c, needle)
		if d != null:
			return d
	return null


## SMOKE_SHRINE=1：圣所断言——三卡确定性 / 效果+代价逐条 / 置灰 / 实开面板全链（Sprint 13 A）
## 【Sprint 17 B 断言盘点】以「验效果型」为主：代价数值（20→12 残响 / 5→4 上限 / 40 残响）、
## 面板可见状态、cleared 回写、暂停态。两条限时 buff 已由 Sprint 15 收口批从「只验标志」
## 升级为 mult=1.25/1.3 + t>0 + 分数的数值断言；其余无「只验标志」绿灯。
func _shrine_probe() -> void:
	await get_tree().create_timer(0.6, true).timeout
	var gm: Node = Game.main
	var bak_floor: int = Game.floor_num
	# 圣所三卡 min_floor>=3：探针统一在第 5 层语境派生（结束还原真实层号）
	Game.floor_num = 5
	# ① 确定性：同 key 两次派生逐字一致；不同 key 打印对照（表外打印，坑 45 口径）
	var coord := Vector2i(3, 4)
	var ids_a := _shrine_ids(gm._shrine_offers_for(coord))
	var ids_b := _shrine_ids(gm._shrine_offers_for(coord))
	# R7 §15.2：两句分开登记（Dev.check 静默通过、只在假时打 [ERR]，合句无法归因）。
	# 定位＝玩家视角入口的廉价回归哨；红线 2 的主守卫在 S32 探针 D1（game_main.gd 八坐标双调用）名下。
	Dev.check(ids_a == ids_b, "shrine", "三卡同 key 两次派生逐字一致：%s" % str(ids_a))
	Dev.check(ids_a.size() == 3, "shrine", "floor5 语境三卡满额：%s" % str(ids_a))
	var ids_c := _shrine_ids(gm._shrine_offers_for(coord + Vector2i(1, 0)))
	print("[SMOKE-SHRINE] det offers=%s other-coord=%s" % [str(ids_a), str(ids_c)])
	# ② 效果 + 代价逐条（先记基准再执行，断言可观察差值）
	var bak_max := max_hp
	var bak_dia := Game.diamonds
	var ents_before: int = gm.entities.get_child_count()
	max_hp = 5
	gm._shrine_execute(gm._shrine_entry("blood_relic"))
	Dev.check(max_hp == 4, "shrine", "blood_relic 代价上限 5→4：%d" % max_hp)
	Dev.check(gm.entities.get_child_count() > ents_before, "shrine", "blood_relic 掉落遗物")
	Game.diamonds = 20
	gm._shrine_execute(gm._shrine_entry("ore_upgrade"))
	Dev.check(Game.diamonds == 12, "shrine", "ore_upgrade 代价残响 20→12：%d" % Game.diamonds)
	await get_tree().create_timer(1.2, true).timeout   # 升级面板 autopick 收尾（暂停期照走）
	# 核验 #1 补断言：四种灾祸逐一验「净化后数值还原」——只验标志位是 Sprint 12 两轮同款根因
	for cid in ["frail", "frenzy", "scarce_ammo", "scarce_ore"]:
		max_hp = 6
		mag_cap_mult = 1.0
		Game.main.diamond_mult = 1.0
		Game.calamity_speed_mult = 1.0
		Game.calamity_floors.append(Game.floor_num)
		gm._calamity = cid
		gm._apply_calamity()
		gm._shrine_execute(gm._shrine_entry("purify"))
		Dev.check(max_hp == 6 and is_equal_approx(mag_cap_mult, 1.0) \
			and is_equal_approx(Game.main.diamond_mult, 1.0) \
			and is_equal_approx(Game.calamity_speed_mult, 1.0) \
			and String(gm._calamity) == "" and not Game.calamity_floors.has(Game.floor_num),
			"shrine", "purify %s 数值全还原 + 当层剔除" % cid)
	shield_charges = 0
	gm._shrine_execute(gm._shrine_entry("ward_boon"))
	Dev.check(shield_charges == 1, "shrine", "ward_boon 护盾 +1：%d" % shield_charges)
	hp = 1
	gm._shrine_execute(gm._shrine_entry("heal"))
	Dev.check(hp == 3, "shrine", "heal 回复 1→3：%d" % hp)
	var sid: String = gm._shrine_suffix_pick()
	gm._shrine_execute(gm._shrine_entry("relic_suffix"))
	# 断言绑定值而非 size：SMOKE_SUFFIX 前置探针可能已绑满，铭刻是同值覆盖（size 不变）
	Dev.check(String(relic_suffixes.get(String(Data.RELIC_SUFFIXES[sid]["relic"]), "")) == sid,
		"shrine", "relic_suffix 确定性绑定 %s→%s" % [sid, String(Data.RELIC_SUFFIXES[sid]["relic"])])
	# ---------------- Sprint 15 D：圣所池 6→10（新增四选项效果+代价逐条） ----------------
	var pre_hp2 := max_hp
	Game.diamonds = 30
	gm._shrine_execute(gm._shrine_entry("greed_pact"))
	Dev.check(Game.diamonds == 40 and max_hp == pre_hp2 - 1, "shrine", "D: greed_pact 上限换残响 30→40")
	Game.score = 200
	gm._shrine_execute(gm._shrine_entry("wind_dance"))
	Dev.check(_buffs.has("boots") and is_equal_approx(float(_buffs["boots"].mult), 1.25) \
		and float(_buffs["boots"].t) > 0.0 and Game.score == 120, "shrine",
		"D: wind_dance 积分换移速 buff（mult=1.25/t>0 数值验证）")
	gm._shrine_execute(gm._shrine_entry("power_surge"))
	Dev.check(_buffs.has("book") and is_equal_approx(float(_buffs["book"].mult), 1.3) \
		and float(_buffs["book"].t) > 0.0 and max_hp == pre_hp2 - 2, "shrine",
		"D: power_surge 上限换增伤 buff（mult=1.3/t>0 数值验证）")
	Game.diamonds = 20
	var sh0 := int(Game.sigils["shards"])
	gm._shrine_execute(gm._shrine_entry("shard_pact"))
	Dev.check(int(Game.sigils["shards"]) == sh0 + 6 and Game.diamonds == 8, "shrine", "D: shard_pact 残响换碎片")
	# ③ 置灰：余额/血量不足不可支付（面板据此置灰，主侧 _on_shrine_chosen 双保险同口径）
	Game.diamonds = 0
	Dev.check(gm._shrine_affordable(gm._shrine_entry("ward_boon")) == false, "shrine", "残响 0 → ward_boon 置灰")
	max_hp = 1
	Dev.check(gm._shrine_affordable(gm._shrine_entry("blood_relic")) == false, "shrine", "上限 1 → blood_relic 置灰（防扣死）")
	Game.score = 10
	Dev.check(gm._shrine_affordable(gm._shrine_entry("heal")) == false, "shrine", "积分不足 → heal 置灰")
	max_hp = maxi(3, bak_max)
	Game.diamonds = maxi(0, bak_dia)
	# ④ 实开面板全链：_open_shrine → autopick 可支付卡 → 面板关闭 + cleared 回写
	var cur := Vector2i.ZERO
	var found := false
	for c in gm.dungeon.rooms:
		if c != Vector2i.ZERO and not bool(gm.dungeon.rooms[c].get("cleared", false)):
			cur = c
			found = true
			break
	if found:
		shield_charges = 0
		# Sprint 19 终审查修：④ 强制可支付语境——池扩到 10 条后派生三卡可能全为积分/残响代价卡，
		# 而 ③ 的 score=10 残留 + 余额未知会让 autopick 无卡可选 → 面板不关（审查实录）。
		# ④ 测的是面板链路不是置灰逻辑，故把余额置足并测后还原
		var dia_bak: int = Game.diamonds
		var score_bak: int = Game.score
		Game.diamonds = 50
		Game.score = 500
		gm._open_shrine(cur)
		Dev.check(gm.shrine_panel._root.visible, "shrine", "面板已打开（三卡渲染）")
		await get_tree().create_timer(1.4, true).timeout   # autopick 0.5s + 执行收尾
		Dev.check(not gm.shrine_panel._root.visible, "shrine", "选择后面板关闭")
		Dev.check(bool(gm.dungeon.rooms[cur]["cleared"]), "shrine", "选择后 cleared 回写（重进不再扣/发）")
		Game.diamonds = dia_bak
		Game.score = score_bak
		# 核验 #2 补断言：ore_upgrade 全链（圣所面板 autopick → _pick → 升级面板）暂停交接不丢失
		Game.diamonds = 20
		gm._shrine_offers = [gm._shrine_entry("ore_upgrade")]
		gm._shrine_coord = cur
		gm.shrine_panel.open(gm._shrine_offers)
		await get_tree().create_timer(0.8, true).timeout   # 圣所 autopick 已发、升级面板 autopick 未到
		Dev.check(get_tree().paused, "shrine", "ore_upgrade 链：升级面板打开期间保持暂停")
		await get_tree().create_timer(0.9, true).timeout   # 升级面板 autopick 收尾
		Dev.check(not get_tree().paused, "shrine", "升级链收尾后恢复运行")
	else:
		Dev.warn("shrine", "无未清房可做实开面板断言（跳过④，不影响①②③）")
	# ⑤ 空池护栏：floor 1 无三卡（房型门槛 min_floor>=3）
	Game.floor_num = 1
	Dev.check(gm._shrine_offers_for(coord).is_empty(), "shrine", "floor1 空池护栏返回 []")
	Game.floor_num = bak_floor
	# ---------------- Sprint 18 阶段二 D：三卡灰字（FLAVOR["shrine/<id>"] 直查） ----------------
	# 验渲染：断言「三卡每张的 _flavors[i].text == 表值」且 visible，而不是"表里有键"。
	# 三卡由探针自控（不依赖派生），避免 floor/coord 变化导致命中集合不同。
	var fset: Array = [gm._shrine_entry("blood_relic"), gm._shrine_entry("ore_upgrade"),
		gm._shrine_entry("heal")]
	gm.shrine_panel.open(fset)
	var f_hits := 0
	var f_list := ""
	for i in 3:
		var oid := String(fset[i]["id"])
		var want := String(Data.FLAVOR.get("shrine/" + oid, ""))
		var got := String(gm.shrine_panel._flavors[i].text)
		var vis: bool = gm.shrine_panel._flavors[i].visible
		f_list += "%s=[%s]" % [oid, got]
		Dev.check(want != "" and got == want and vis, "shrine",
			"D: 卡 %d(%s) 灰字 == FLAVOR 实值且可见：[%s]" % [i, oid, got])
		if want != "" and got == want and vis:
			f_hits += 1
	Dev.check(f_hits == 3, "shrine", "D: 三卡灰字全部命中（%d/3）" % f_hits)
	# Sprint 26 批二：灰字六道新词逐字上屏（上方为「与表自比较」，本条为字面量锁，防表被改成同款错值）
	var s26_blood := false
	for i in 3:
		if String(fset[i].get("id", "")) == "blood_relic":
			var fl_lit := String(gm.shrine_panel._flavors[i].text)
			s26_blood = gm.shrine_panel._flavors[i].visible and fl_lit.contains("血祭。以血换遗物")
	Dev.check(s26_blood, "shrine",
		"S26: blood_relic 灰字含「血祭。以血换遗物」（六道新词逐字上屏）")
	print("[SMOKE-SHRINE] D flavors %s" % f_list)
	# 自开自关：不留给 autopick 触发真实选择（隐藏后 safe_delay 回调会因 _root.visible=false 跳过）
	gm.shrine_panel._root.visible = false
	gm.shrine_panel._offers = []
	get_tree().paused = false
	print("[SMOKE-SHRINE] done")


func _shrine_ids(offers: Array) -> Array:
	var out: Array = []
	for o in offers:
		out.append(String(o["id"]))
	return out


## SMOKE_CODEX=1：图鉴断言——隔离档 / 未知 id 忽略 / 读写往返 / 负数钳制（Sprint 13 C）+
## Sprint 14 A 登记三件套 + B 批加固断言
## 【Sprint 17 B 断言盘点】多数为「验效果型」：未知 id 忽略 / 记录→存盘→读回 / 负数钳制 0 /
## B3 越界键 / B5 同层幂等 / B6 空 clear 保留 saved / P0-3.2 现场恢复；
## 分母与显示名比对为「表一致性门 + 常量自比较」（已单行标注），B2 读档钳制属验效果型。
func _codex_probe() -> void:
	await get_tree().create_timer(0.6, true).timeout
	var gm: Node = Game.main
	# ① 隔离档：SMOKE 下路径必须是 _smoke_codex.cfg（主档不被污染）
	Dev.check(String(Game.codex_path()).contains("_smoke_codex"), "codex",
		"SMOKE 隔离档：%s" % Game.codex_path())
	# ② 未知 id 两次登记均被忽略（登记与读档同一张校验）
	var before: int = (Game.codex["enemies"] as Array).size()
	Game.mark_codex("enemies", "no_such_enemy")
	Game.mark_codex("enemies", "no_such_enemy")
	Dev.check((Game.codex["enemies"] as Array).size() == before, "codex", "未知 id 登记被忽略")
	# ③ 记录 → 存盘 → 清内存 → 读回一致
	Game.mark_codex("enemies", "goblin")
	Game.mark_codex("themes", "toxic")
	Game.mark_codex("bosses", "skeleton_king")
	Game.set_codex_last_run({"diamonds": 12, "kills": 34, "max_floor": 5, "time": 83.0, "score": 900})
	var snap: Dictionary = Game.codex.duplicate(true)
	for k in Game.CODEX_KINDS:
		(Game.codex[k] as Array).clear()
	Game.codex["last_run"] = {}
	Game.load_codex()
	Dev.check((Game.codex["enemies"] as Array).has("goblin")
		and (Game.codex["themes"] as Array).has("toxic")
		and (Game.codex["bosses"] as Array).has("skeleton_king"), "codex", "记录→存盘→读回一致")
	Dev.check(int(Game.codex["last_run"].get("max_floor", -1)) == 5
		and int(Game.codex["last_run"].get("kills", -1)) == 34, "codex", "上局复盘快照读回一致")
	var same := true
	for k in Game.CODEX_KINDS:
		if (Game.codex[k] as Array) != (snap[k] as Array):
			same = false
	Dev.check(same, "codex", "读回与快照逐分类一致")
	# ④ 负数钳制：负值读回为 0（防穿透）
	Game.set_codex_last_run({"max_floor": -3, "kills": -7})
	Dev.check(int(Game.codex["last_run"].get("max_floor", -1)) == 0
		and int(Game.codex["last_run"].get("kills", -1)) == 0, "codex", "负数钳制 → 0")
	# ---------------- Sprint 14 A：登记三件套断言 ----------------
	# ① 写入：两个主题 Boss 专用 id 可登记（只撤销本次新增——若 id 已在档中则保留，防误删既有发现；
	# smoke 档跨 run 累积，Sprint 14 回归已写入过这两个 id）
	var had_pw: bool = (Game.codex["bosses"] as Array).has("prism_warden")
	var had_pt: bool = (Game.codex["bosses"] as Array).has("pyrothalassian")
	Game.mark_codex("bosses", "prism_warden")
	Game.mark_codex("bosses", "pyrothalassian")
	Dev.check((Game.codex["bosses"] as Array).has("prism_warden")
		and (Game.codex["bosses"] as Array).has("pyrothalassian"), "codex", "A: 主题 Boss 专用 id 登记成功")
	if not had_pw:
		(Game.codex["bosses"] as Array).erase("prism_warden")
	if not had_pt:
		(Game.codex["bosses"] as Array).erase("pyrothalassian")
	Game.save_codex()
	# ② 白名单：非 Boss 敌人被拒（B1）；巨岩虫之王键仍合法（旧档兼容 §3.4，不隐式迁移）
	Dev.check(not Game._codex_id_valid("bosses", "rusher"), "codex", "B1: 非 Boss 敌人 id 被白名单拒绝")
	Dev.check(Game._codex_id_valid("bosses", "boss"), "codex", "旧档兼容: 巨岩虫之王键仍合法")
	# ③ 分母与显示名单源（防 6/4 错位与英文 id 直出）
	# 【Sprint 17 B 断言性质】分母比对属「表一致性门」（扩表漂移会红，有效）；
	# 下一行显示名比对属「常量自比较」：自己定义自己读，防错字/表被改，非行为断言 → 建议下批补渲染断言。
	Dev.check(Data.codex_bosses_total() == 7, "codex", "A: bosses 分母 = 7（ENEMIES 真 Boss + 3 主题——Sprint 15 A 起）")
	Dev.check(String(Data.CODEX_BOSS_NAMES["prism_warden"]) == "棱镜守望者"
		and String(Data.CODEX_BOSS_NAMES["pyrothalassian"]) == "熔潮主宰", "codex", "A: 显示名中文映射")
	# ---------------- Sprint 14 B 批加固 ----------------
	# B3：last_run 键白名单（越界键忽略，只收 META.STATS_KEYS 五项）
	Game.set_codex_last_run({"diamonds": 3, "bogus_key": 99, "max_floor": 2})
	Dev.check(not (Game.codex["last_run"] as Dictionary).has("bogus_key")
		and int(Game.codex["last_run"].get("diamonds", -1)) == 3
		and int(Game.codex["last_run"].get("max_floor", -1)) == 2, "codex", "B3: 越界键被 STATS_KEYS 白名单忽略")
	# B5：同层重复 roll 只登记一次 calamity_floors（Array.erase 只删首个的残留防线）
	var bak_floor: int = Game.floor_num
	Game.floor_num = 5
	gm._calamity_forced = true
	gm._roll_calamity()
	gm._roll_calamity()
	var cnt5 := 0
	for f in Game.calamity_floors:
		if f == 5:
			cnt5 += 1
	Dev.check(cnt5 == 1, "codex", "B5: 同层 roll 两次仅登记一次")
	gm._calamity_forced = false
	gm._calamity = ""
	gm._clear_calamity_effects()
	Game.calamity_floors.clear()
	Game.floor_num = bak_floor
	# B6：空灾祸层 clear 不再无条件重置 saved（纯语义收拢——验证保持不变）
	gm._calamity = ""
	gm._calamity_saved_diamond_mult = 0.42
	gm._clear_calamity_effects()
	Dev.check(is_equal_approx(float(gm._calamity_saved_diamond_mult), 0.42), "codex", "B6: 空 clear 保留 saved 值")
	gm._calamity_saved_diamond_mult = 1.0
	# B2：读档路径钳制（手工写负数 → load_codex → 归 0）——「实现保证」升级为「断言覆盖」；
	# 放最后：会覆盖 last_run 现场
	var cfgf := ConfigFile.new()
	cfgf.load(Game.codex_path())   # Sprint 15 P0-3.2：先读回原档再改——否则 save() 抹掉六类发现集（非隔离环境会清玩家图鉴）
	cfgf.set_value("codex", "last_run", {"max_floor": -9, "time": -2.5})
	cfgf.save(Game.codex_path())
	Game.load_codex()
	Dev.check(int(Game.codex["last_run"].get("max_floor", -1)) == 0
		and int(Game.codex["last_run"].get("time", -1)) == 0, "codex", "B2: 读档负数钳制 → 0")
	# P0-3.2 验收：B2 断言后六类发现集与探针执行前逐类一致（现场恢复，非隔离环境也不清档）
	var sets_same := true
	for k in Game.CODEX_KINDS:
		if (Game.codex[k] as Array) != (snap[k] as Array):
			sets_same = false
	Dev.check(sets_same, "codex", "P0-3.2: B2 后六类发现集现场恢复")
	# ---------------- Sprint 19 A：shrine 第六类发现集（负向对照 ①-⑤ + 正向断言） ----------------
	# ① 白名单正反两向：合法 id = SHRINE_OFFERS 键集，未知 id 被拒
	Dev.check(not Game._codex_id_valid("shrine", "no_such_offer"), "codex",
		"S19①: 未知圣所 id 被白名单拒绝")
	Dev.check(Game._codex_id_valid("shrine", "blood_relic"), "codex",
		"S19①: 合法圣所 id 通过白名单")
	# ② 首发现登记 + toast 含手记句 + 重复登记幂等且不重复播报（先撤销既有发现，保证首发现路径可测）
	# Sprint 22 D：首发现走帧末聚合冲洗——探针用「清 pending + 直调冲洗」确定性驱动同一入口
	# （不赌帧边界：多探针同帧 mark 会互相聚合，直调冲洗净化时序）
	(Game.codex["shrine"] as Array).erase("blood_relic")
	Game._flavor_pending.clear()
	Game.mark_codex("shrine", "blood_relic")
	Game._flush_flavor_toast()
	Dev.check((Game.codex["shrine"] as Array).has("blood_relic"), "codex", "S19②: 首发现登记成功")
	Dev.check(String(Game.main.hud._toast.text).contains("血祭"), "codex",
		"S19② 正向: toast 含手记句（FLAVOR shrine/blood_relic）")
	var toast_at_first: String = Game.main.hud._toast.text
	Game.mark_codex("shrine", "blood_relic")
	Dev.check((Game.codex["shrine"] as Array).count("blood_relic") == 1
		and Game.main.hud._toast.text == toast_at_first, "codex",
		"S19②: 重复登记幂等且不重复播报")
	# ③ kind 写成复数则播报键查不到（单数 shrine 的存在依据——icon_codex 同型静默坑的负向对照）
	Dev.check(Data.FLAVOR.has("shrine/blood_relic") and not Data.FLAVOR.has("shrines/blood_relic"),
		"codex", "S19③: FLAVOR 键为单数 shrine（复数键必查不到——负向对照）")
	# ④ 旧 codex.cfg 无 shrine 键 → load_codex 给空数组且不报错（快照全部分类+last_run，测后恢复
	# ——S19 子代理低危观察①：last_run 不恢复的话，未来在本探针之后新增依赖 last_run 现场的断言会静默踩空）
	var lr_b4: Dictionary = (Game.codex["last_run"] as Dictionary).duplicate()
	var sets_b4 := {}
	for k in Game.CODEX_KINDS:
		sets_b4[k] = (Game.codex[k] as Array).duplicate()
	var old_cfg := ConfigFile.new()
	old_cfg.set_value("codex", "enemies", ["goblin"])
	old_cfg.save(Game.codex_path())
	Game.load_codex()
	Dev.check((Game.codex["shrine"] as Array).is_empty()
		and (Game.codex["enemies"] as Array).has("goblin"), "codex",
		"S19④: 旧档无 shrine 键 → 空数组且不报错")
	for k in Game.CODEX_KINDS:
		Game.codex[k] = sets_b4[k]   # 恢复内存（P0-3.2 写法）
	Game.codex["last_run"] = lr_b4
	Game.save_codex()
	Game.load_codex()
	# ⑤ 渲染：图鉴含「已行抉择」标题与动态分母（S20 附限定①：分母读 SHRINE_OFFERS.size()，
	# 不硬编码 "/ 10"——SHRINE_OFFERS 扩到 11 时本断言不假红）、已知条目显中文名不直出英文 id
	Game.main.menu._build_codex()
	var shrine_title := false
	var shrine_name := false
	var shrine_denom: int = Data.SHRINE_OFFERS.size()
	for c in Game.main.menu._rows.get_children():
		if c is Label:
			if String(c.text).contains("已行抉择") and String(c.text).contains("/ %d" % shrine_denom):
				shrine_title = true
			if String(c.text).contains("血祭"):
				shrine_name = true
	Dev.check(shrine_title and shrine_name, "codex",
		"S19⑤: 图鉴渲染「已行抉择 n / %d」+ 中文名（不直出英文 id）" % shrine_denom)
	print("[SMOKE-CODEX] done")


## SMOKE_CODEX_BOON=1：图鉴发现度被动断言——阈值边界 / 派生确定性 / 起始状态落地 / 载体零命中（Sprint 14 C）
## 【Sprint 17 B 断言盘点】阈值边界 / 起始状态四项落地 / §5.4 倍率零命中为「验效果型」；
## 「派生确定性」为「常量自比较」，「P0 派生不变」为「前提守卫型恒过」（二者已单行标注）。
func _codex_boon_probe() -> void:
	await get_tree().create_timer(0.6, true).timeout
	var gm: Node = Game.main
	# 阈值边界：need-1 不生效 / need 生效（enemies 分类构造 4→5）
	(Game.codex["enemies"] as Array).clear()
	var eids := ["goblin", "rusher", "skeleton", "zombie", "orc"]
	for i in 4:
		Game.mark_codex("enemies", eids[i])
	Dev.check(not Game.codex_boons().has("enemies_5"), "codex_boon", "阈值边界: 4/5 不生效")
	Game.mark_codex("enemies", eids[4])
	Dev.check(Game.codex_boons().has("enemies_5"), "codex_boon", "阈值边界: 5/5 生效")
	# 构造其余三档生效
	(Game.codex["bosses"] as Array).clear()
	Game.mark_codex("bosses", "skeleton_king")
	Game.mark_codex("bosses", "dragon")
	(Game.codex["relics"] as Array).clear()
	for rid in ["fang", "thorn", "bounce", "frost"]:
		Game.mark_codex("relics", rid)
	(Game.codex["themes"] as Array).clear()
	for tid in ["vein", "toxic", "pressure"]:
		Game.mark_codex("themes", tid)
	var boons: Dictionary = Game.codex_boons()
	Dev.check(boons.size() == 4, "codex_boon", "全四档生效: %s" % str(boons.keys()))
	# 【Sprint 17 B 断言性质：常量自比较】同档连读两次纯派生必然相等；只防「派生被改成有状态」，
	# 不是行为断言、无真实差值 → 建议下批改为「改档前后差值」或删除，勿冒充验效果型。
	Dev.check(Game.codex_boons() == Game.codex_boons(), "codex_boon", "派生确定性（同档两次逐字一致）")
	# 起始状态实际落地（验数值，不只验返回字典——「只验标志」根因防线）
	shield_charges = 0
	Game.diamonds = 0
	max_hp = Player.BASE_MAX_HP
	hp = max_hp
	relic_suffixes.clear()
	var dm0: float = gm.diamond_mult
	var mc0: float = mag_cap_mult
	var sp0: float = Game.calamity_speed_mult
	# Sprint 15 P0：自激切断真差值断言——送词缀回写图鉴（suffixes 分类增长）后，
	# boon 派生必须逐字不变（判据端切链：无 suffixes 阈值则回写不影响判定）
	# 【Sprint 17 B 断言性质订正：前提守卫型恒过，非「真差值」】当前 codex_boons() 不读 suffixes，
	# 前后必然相等；真防线是 validate._check_codex() 的启动期判据门。价值在「未来误加 suffixes
	# 阈值 / 误把 boon 回写图鉴」时报错。订正 Sprint 15 交付文档措辞，本批不改断言逻辑。
	var boons_before: Dictionary = Game.codex_boons()
	gm._apply_codex_boons()
	Dev.check(Game.codex_boons() == boons_before, "codex_boon", "P0: 送词缀回写后派生不变（自激已切断）")
	Dev.check(shield_charges == 1, "codex_boon", "shield 落地: %d" % shield_charges)
	Dev.check(Game.diamonds == 3, "codex_boon", "diamonds 落地: %d" % Game.diamonds)
	Dev.check(max_hp == Player.BASE_MAX_HP + 1 and hp == max_hp, "codex_boon",
		"max_hp 落地: %d/%d" % [hp, max_hp])
	Dev.check(relic_suffixes.size() == 1, "codex_boon", "suffix 落地: %s" % str(relic_suffixes))
	# §5.4 载体零命中：apply 前后三个全局倍率不动（防回归）
	Dev.check(is_equal_approx(gm.diamond_mult, dm0) and is_equal_approx(mag_cap_mult, mc0)
		and is_equal_approx(Game.calamity_speed_mult, sp0), "codex_boon",
		"§5.4: 全局倍率载体零命中（apply 前后不变）")
	# Sprint 19 §九-1 配套（验效果型·真差值断言）：shrine 三态 0 / 1 / 10 条下派生逐字相等。
	# 真差值来自「输入确实变了」，若 _codex_boon_suffix() 漏掉 continue 则三态输出各异 → 本条转红。
	var shrine_bak: Array = (Game.codex["shrine"] as Array).duplicate()
	(Game.codex["shrine"] as Array).clear()
	var sfx_empty: String = gm._codex_boon_suffix()
	(Game.codex["shrine"] as Array).append("blood_relic")
	var sfx_one: String = gm._codex_boon_suffix()
	(Game.codex["shrine"] as Array).clear()
	for oid19 in Data.SHRINE_OFFERS:
		(Game.codex["shrine"] as Array).append(String(oid19))
	var n_full: int = (Game.codex["shrine"] as Array).size()
	var sfx_full: String = gm._codex_boon_suffix()
	Dev.check(n_full == Data.SHRINE_OFFERS.size(), "codex_boon",
		"S19: 三态输入样本确为 0 / 1 / %d 条（非恒定输入）" % n_full)
	Dev.check(sfx_empty != "" and sfx_empty == sfx_one and sfx_one == sfx_full, "codex_boon",
		"S19: _codex_boon_suffix 三态逐字相等：%s / %s / %s" % [sfx_empty, sfx_one, sfx_full])
	Game.codex["shrine"] = shrine_bak
	print("[SMOKE-CODEX-BOON] done")


## SMOKE_THIRD_BOSS=1：第三 Boss 断言——层判定 / 优先链前提 / 三件套单源红利（Sprint 15 A）
func _third_boss_probe() -> void:
	await get_tree().create_timer(0.6, true).timeout
	Dev.check(Game.main._is_third_floor(27) and Game.main._is_third_floor(59),
		"third_boss", "层判定: 27/59 命中")
	Dev.check(not Game.main._is_third_floor(26) and not Game.main._is_third_floor(43)
		and not Game.main._is_third_floor(11), "third_boss", "层判定: 26/43/11 不命中")
	Dev.check(not Game.main._is_sovereign_floor(27) and Game.main._is_warden_floor(27),
		"third_boss", "优先链前提: 27 是首领层且避开主权层")
	Dev.check(Data.codex_bosses_total() == 7, "third_boss", "分母单源: 7（ENEMIES 真 Boss + 3 主题）")
	# 【Sprint 17 B 复核】维持「前半常量自比较 / 后半真校验门」分类，建议下批补菜单显示名渲染断言。
	# 【断言性质：前半为常量自比较守卫（防表被误改/错字，非行为断言）；后半 _codex_id_valid 是真校验门】
	Dev.check(String(Data.CODEX_BOSS_NAMES["third_boss"]) == "玄渊之主"
		and Game._codex_id_valid("bosses", "third_boss"), "third_boss", "表+校验器: third_boss 合法")
	# 击杀登记路径单元证据：构造 boss3 实例直调 on_slug_killed——与 boss.gd _die :338 同一入口；
	# 自动驾驶在小图布局下进 boss 房的运气不稳定（kill2/3/4 实录），真实流程证据由
	# 全量回归的 FORCE_THIRD_BOSS 生成打印 + 本单元路径共同构成
	var b3: PrismWarden = load("res://scripts/boss3.gd").new()
	Dev.check(String(b3.codex_id) == "third_boss", "third_boss", "boss3 默认 codex_id 正确")
	Game.main.on_slug_killed(b3)
	Dev.check((Game.codex["bosses"] as Array).has("third_boss"), "third_boss",
		"on_slug_killed 走 codex_id 登记 third_boss（非 variant 回退）")
	Dev.check(not (Game.codex["bosses"] as Array).has("boss"), "third_boss", "无 \"boss\" 假阳性登记")
	b3.free()
	print("[SMOKE-THIRD-BOSS] done")


## SMOKE_OATH / SMOKE_ECHO_CHAIN：地窖誓约 + 抉择回声断言（Sprint 16 A/B）
## 【Sprint 17 B 断言盘点】本探针以「验效果型」为主：计数器增量 / 阈值 2→3 边界 /
## 多条件取最小 / 落盘读回逐字段 / 复盘页渲染扫描；A2 为「验效果型·负向构造」。
## 表结构 size 比对属表一致性门（常量自比较类），非行为断言；无「只验标志」绿灯。
func _oath_probe() -> void:
	await get_tree().create_timer(0.6, true).timeout
	var gm: Node = Game.main
	# 表结构：9 条与印记一一对应（validate 同源，探针复验）
	Dev.check(Data.OATH_CONDITIONS.size() == Data.SIGILS.size(), "oath", "誓约 9 条对应 9 印记")
	# ① 计数器增量
	var c0: int = int(gm._oath_counters.get("hits_taken", 0))
	gm.oath_count("hits_taken")
	Dev.check(int(gm._oath_counters.get("hits_taken", 0)) == c0 + 1, "oath", "计数器增量")
	# ② 兑现度派生：阈值边界（vigor 3 次受击）
	Game.equip_sigil("vigor")
	gm._oath_counters["hits_taken"] = 2
	var f: Dictionary = gm.oath_fulfillment()
	Dev.check(String(f.get("id", "")) == "vigor" and not bool(f.get("done", true))
		and int(f.get("cur", -1)) == 2, "oath", "兑现度 2/3 未兑现")
	gm._oath_counters["hits_taken"] = 3
	f = gm.oath_fulfillment()
	Dev.check(bool(f.get("done", false)) and int(f.get("need", -1)) == 3, "oath", "兑现度 3/3 已兑现")
	# 多条件取最小（scholar：shrine 计 0 → cur=0）
	Game.equip_sigil("scholar")
	f = gm.oath_fulfillment()
	Dev.check(int(f.get("cur", 99)) == 0, "oath", "多条件取最小")
	# 【Sprint 17 A2 / B：验效果型·负向构造】空 watched 必须命中早退返回空字典。
	# 若无早退，cur 保持 999 → done 恒真、返回非空 → 本断言红。删守卫即失效，是真差值断言。
	var empty_watched: Dictionary = {"name": "t", "desc": "t", "watched": [], "need": 1}
	var empty_res: Dictionary = gm.oath_fulfillment(empty_watched)
	Dev.check(empty_res.is_empty(), "oath",
		"A2: 空 watched 返回空字典（原 cur:=999 会误判 done=true）")
	# 表外探针落地证据：Dev.check 只在失败时打印，显式留一行成功证据
	print("[SMOKE-OATH] A2: empty_watched result_empty=%s" % str(empty_res.is_empty()))
	# B：抉择链 + 主导代价标签
	gm._echo_choices.clear()
	gm._echo_costs.clear()
	gm._echo_choices.append("purify")
	gm._echo_costs[""] = 1
	gm._echo_choices.append("greed_pact")
	gm._echo_costs["max_hp"] = 2
	Dev.check(String(gm._echo_tag()) == "血偿流", "echo", "构筑标签：主导代价 max_hp → 血偿流")
	# A/B 落盘（真实入口 _write_codex_replay）：写 → load → 逐字段读回 + 六类发现集不被抹
	var sets_before := {}
	for k in Game.CODEX_KINDS:
		sets_before[k] = (Game.codex[k] as Array).duplicate()
	var done_before: bool = bool(gm.oath_fulfillment().get("done", false))
	gm._write_codex_replay()
	Game.load_codex()
	var lr: Dictionary = Game.codex["last_run"]
	Dev.check(String((lr.get("oath", {}) as Dictionary).get("id", "")) == "scholar"
		and bool((lr["oath"] as Dictionary).get("done", true)) == done_before, "oath",
		"誓约字段落盘读回（含 done）")
	var echo: Dictionary = lr.get("echo", {})
	Dev.check(int(echo.get("count", -1)) == 2 and String(echo.get("tag", "")) == "血偿流"
		and (echo.get("choices", []) as Array).size() == 2
		and int(((echo.get("costs", {}) as Dictionary).get("max_hp", 0))) == 2, "echo",
		"抉择链+标签+计数+代价分布读回")
	var sets_ok := true
	for k in Game.CODEX_KINDS:
		if (Game.codex[k] as Array) != (sets_before[k] as Array):
			sets_ok = false
	Dev.check(sets_ok, "oath", "六类发现集不被抹（P0-3.2 写法）")
	# ③ 渲染验证：真调 menu._build_codex 扫描生成标签（验渲染非验字段）
	Game.main.menu._build_codex()
	var oath_shown := false
	var echo_shown := false
	for c in Game.main.menu._rows.get_children():
		if c is Label:
			if String(c.text).contains("本局誓约"):
				oath_shown = true
			if String(c.text).contains("抉择回声"):
				echo_shown = true
	Dev.check(oath_shown and echo_shown, "oath", "复盘页渲染誓约+回声行")
	print("[SMOKE-OATH] done")


## SMOKE_LAYOUT=1：Sprint 18 A(v3) 层签**房型计数**断言（`game_main.floor_layout_hint()` 纯只读派生）
## 【Sprint 18 v3 断言盘点】
##   · 验效果型（真值重数）：独立遍历 `dungeon.rooms` 重数 elite 个数与 cursed 有无，与返回值全等比对——
##     验真值不验形状。**不靠改 `Game.floor_num` 造楼层**：被测函数读的是已生成的那张图，改 floor_num
##     不会重生成地图，重生成要消费 `Game.rng`（破零抽取红线）；那样写出的断言等于「同一张图换个标签」，是假断言。
##   · 验效果型（格式锁）：按「 ｜ 」切分，首段为「无精英」或「精英 N」（N 纯数字）；
##     诅咒段出现**当且仅当**本图确有诅咒房，且只允许字面「有诅咒房」（反条件即可两侧全红，与地图内容无关）
##   · 验效果型（零位置泄漏）：输出不含 `(` `,` `Vector2i` `[`——只报计数不报坐标
##   · 验效果型（零抽取）：调用前后 `Game.rng.state` / `Game.fx_rng.state` 全等
##   · 验效果型（空图守卫）：dungeon 置空时返回 ""；置空后立即还原、同图输出不变（无 await 间隙）
##   · 恒等型：同图连调两次全等（幂等锁，可抓状态泄漏）
## 本探针只读 `dungeon.rooms`；除「置空立即还原」外不改任何状态，不写盘、不抽取、不重生成地图。
func _layout_probe() -> void:
	await get_tree().create_timer(0.6, true).timeout
	var gm: Node = Game.main
	if not is_instance_valid(gm.dungeon):
		Dev.check(false, "layout", "探针前置失败：dungeon 为空，无法重数房型")
		return
	# ① 真值重数（独立遍历，不调用被测函数；期望串按规格格式独立构造）
	var ne_truth := 0
	var cursed_truth := false
	var kinds := {}
	for c in gm.dungeon.rooms:
		var k := String(gm.dungeon.rooms[c].get("kind", ""))
		kinds[k] = int(kinds.get(k, 0)) + 1
		if k == "elite":
			ne_truth += 1
		elif k == "cursed":
			cursed_truth = true
	var lay: String = gm.floor_layout_hint()
	var exp_parts: Array[String] = []
	exp_parts.append(("精英 %d" % ne_truth) if ne_truth > 0 else "无精英")
	if cursed_truth:
		exp_parts.append("有诅咒房")
	var exp_lay := " ｜ ".join(PackedStringArray(exp_parts))
	Dev.check(lay == exp_lay, "layout",
		"房型计数与 dungeon.rooms 独立重数全等：实返=%s 重数=%s" % [lay, exp_lay])
	Dev.check(ne_truth == int(kinds.get("elite", 0)), "layout",
		"elite 计数自洽：%d / kinds=%s" % [ne_truth, str(kinds)])
	# ② 格式锁（不依赖重数值，抓格式退化）
	var segs := lay.split(" ｜ ")
	Dev.check(segs.size() >= 1 and segs.size() <= 2, "layout", "房型段数 ∈ [1,2]：%d" % segs.size())
	var head: String = segs[0]
	var head_ok: bool = head == "无精英" or (head.begins_with("精英 ") and head.substr(3).is_valid_int())
	Dev.check(head_ok, "layout", "首段为「无精英」或「精英 N」：%s" % head)
	Dev.check((segs.size() == 2) == cursed_truth, "layout",
		"诅咒段出现当且仅当本图有诅咒房（重数=%s）：%s" % [str(cursed_truth), lay])
	if segs.size() == 2:
		Dev.check(segs[1] == "有诅咒房", "layout", "次段只允许「有诅咒房」：%s" % segs[1])
	# ③ 零位置泄漏：只报计数，不报坐标
	var leak := ""
	for bad in ["(", ",", "Vector2i", "["]:
		if lay.contains(bad):
			leak = bad
	Dev.check(leak == "", "layout", "输出零位置泄漏（命中：%s）：%s" % [leak, lay])
	# ④ 红线：零推荐语（只陈述房型事实，不给主导策略）
	var hit := ""
	for bad2 in ["建议", "推荐", "优先", "带"]:
		if lay.contains(bad2):
			hit = bad2
	Dev.check(hit == "", "layout", "房型文案零推荐语（命中：%s）" % hit)
	# ⑤ 零 rng / fx_rng 消费（state 前后相等，与地图生成解耦自证）
	var rs_state = Game.rng.state
	var fx_state = Game.fx_rng.state
	gm.floor_layout_hint()
	Dev.check(Game.rng.state == rs_state and Game.fx_rng.state == fx_state, "layout",
		"floor_layout_hint 零 Game.rng / fx_rng 消费")
	# ⑥ 幂等：同图连调两次全等（可抓状态泄漏）
	Dev.check(gm.floor_layout_hint() == lay, "layout", "同图连调两次全等（幂等）：%s" % lay)
	# ⑦ 空图守卫：置空返回 ""，立即还原后同图输出不变（无 await 间隙，不影响后续探针）
	var bak_dungeon = gm.dungeon
	gm.dungeon = null
	var empty_ret: String = gm.floor_layout_hint()
	gm.dungeon = bak_dungeon
	Dev.check(empty_ret == "", "layout", "dungeon 为空时返回空串（守卫生效）：[%s]" % empty_ret)
	Dev.check(is_instance_valid(gm.dungeon) and gm.floor_layout_hint() == lay, "layout",
		"置空后立即还原，同图输出不变")
	print("[SMOKE-LAYOUT] done lay=%s ne=%d cursed=%s kinds=%s" % [
		lay, ne_truth, str(cursed_truth), str(kinds)])


## SMOKE_FLOOR_SIGN / SMOKE_FLAVOR：层签 + 地窖低语断言（Sprint 16 C/D，Sprint 18 B 扩展第二行）
## 【Sprint 17 B 断言盘点】全为「验效果型」：层签文本包含实值 / rng.state 与 fx_rng.state 前后相等 /
## toast 文本与重复登记不变 / 分母不变 / 图鉴手记行渲染扫描；A1 跳层断言另见 game_main.start_run。
## 【Sprint 18 B / A-v3 增补】第二行「验效果型」：floor=1 第二行**非空且可见**、全等「本层 · <房型>」/
## floor=4 第二行显示且含「本层」+ 房型段实值 + 主题手记实值 / 主行文本一字不改（与实值全等比对）。
## 注：本探针用 floor_num 切主题语境，地图始终是已生成的同一张（floor_layout_hint 不随 floor_num 变），
## 故 floor=4 段验的是**界面拼装**，不代表真实 4 层地图；真实地图真值由 _layout_probe 独立重数。
func _floor_sign_probe() -> void:
	await get_tree().create_timer(0.6, true).timeout
	var gm: Node = Game.main
	# 探针间 floor 互相影响（shrine 探针临时置 5）——本探针自设语境，结束还原
	var bak_floor: int = Game.floor_num
	Game.floor_num = 1   # 无主题语境
	# C：层签内容与实值一致（1-2 层无主题 → 「无主题」；灾祸空 → 无）
	gm._calamity = ""
	gm.update_floor_sign()
	var sign: String = Game.main.hud._floor_sign_label.text
	Dev.check(sign.contains("无主题") and sign.contains("灾祸：无"), "floor_sign",
		"层签与实值一致（无主题/无灾祸）：%s" % sign)
	# C：灾祸实值反映
	gm._calamity = "frail"
	gm.update_floor_sign()
	sign = Game.main.hud._floor_sign_label.text
	Dev.check(sign.contains("虚弱"), "floor_sign", "层签反映灾祸实值：%s" % sign)
	gm._calamity = ""
	# C：刷新零 rng 消费（state 前后不变——零抽取自证）
	var rng_state = Game.rng.state
	gm.update_floor_sign()
	Dev.check(Game.rng.state == rng_state, "floor_sign", "层签刷新零 Game.rng 消费")
	var fx_state = Game.fx_rng.state
	gm.update_floor_sign()
	Dev.check(Game.fx_rng.state == fx_state, "floor_sign", "层签刷新零 fx_rng 消费")
	# Sprint 18 A v3：floor=1 → 第二行**非空且可见**（v2 中此处为空；v3 房型段恒有内容）
	# 推导与硬编码解耦：先取同一张图的房型段实值，再逐步比对结构。
	# 注意探针运行时 SMOKE 已可能推进楼层，故这里**不硬编码**层号/计数，只锁「本层 · <当前图房型段>」
	var lay1: String = gm.floor_layout_hint()
	var sub1: String = String(Game.main.hud._floor_sign_sub_label.text)
	Dev.check(Game.main.hud._floor_sign_sub_label.visible and sub1 != "", "floor_sign_sub",
		"floor=1 层签第二行非空且可见：%s" % sub1)
	Dev.check(sub1.begins_with("本层 · "), "floor_sign_sub",
		"floor=1 第二行以「本层 · 」开头：%s" % sub1)
	Dev.check(sub1.contains(lay1), "floor_sign_sub",
		"floor=1 第二行含房型段实值：%s（房型段=%s）" % [sub1, lay1])
	# theme_for_floor(n<4) 返回 {} → 1 层无手记段 → 第二行收尾即房型段末尾（全等锁）
	Dev.check(sub1 == "本层 · " + lay1, "floor_sign_sub",
		"floor=1 第二行全等「本层 · <房型>」（无主题故无手记段）：%s" % sub1)
	# Sprint 18 B / A-v3：floor=4（往生脉 vein）→ 第二行显示，含「本层」房型段 + 主题手记实值
	Game.floor_num = 4
	gm.update_floor_sign()
	var lay4: String = gm.floor_layout_hint()
	var sub: String = String(Game.main.hud._floor_sign_sub_label.text)
	Dev.check(Game.main.hud._floor_sign_sub_label.visible and sub.contains("本层 · "), "floor_sign_sub",
		"floor=4 层签第二行显示且含「本层 · 」：%s" % sub)
	Dev.check(sub.contains(lay4), "floor_sign_sub",
		"floor=4 第二行含房型段实值（floor_layout_hint）：%s（房型段=%s）" % [sub, lay4])
	Dev.check(sub.contains("往生脉"), "floor_sign_sub",
		"floor=4 第二行含主题手记实值（FLAVOR themes/vein，Sprint 25 随主题改名同步）：%s" % sub)
	# Sprint 26 批二：六道卷语义深绑——第二行六道新词逐字上屏（首词之外的插入语，验渲染非验表）
	Dev.check(sub.contains("人间拾痕"), "floor_sign_sub",
		"S26: floor=4 第二行含六道新词「人间拾痕」（FLAVOR themes/vein value 全文上屏）：%s" % sub)
	# 拼接分隔符（房型段/诅咒段与手记段之间为「 ｜ 」——锁组合结构，不锁具体文案）
	Dev.check(sub.contains(" ｜ "), "floor_sign_sub",
		"floor=4 第二行以「 ｜ 」连接房型与手记：%s" % sub)
	# Sprint 18 B：主行一字不改（全等回归锁——防 B 项改动溢出到主行格式）
	var main4: String = String(Game.main.hud._floor_sign_label.text)
	Dev.check(main4 == "层签 · 往生脉◆ ｜ 灾祸：无", "floor_sign_sub",
		"floor=4 主行文本一字未改：%s" % main4)
	print("[SMOKE-FLOOR-SIGN] B: sub1=%s sub4=%s main4=%s" % [sub1, sub, main4])
	Game.floor_num = 1   # 还原本探针自设语境（后续 D 段在 1 层跑）
	gm.update_floor_sign()
	# D：首发现播报（清条目 → mark → toast 文本含手记；重复 mark → 文本不变）
	# Sprint 22 D：清 pending + 直调冲洗（确定性；防其它探针同帧 mark 的聚合串扰）
	(Game.codex["themes"] as Array).erase("vein")
	Game._flavor_pending.clear()
	Game.mark_codex("themes", "vein")
	Game._flush_flavor_toast()
	Dev.check(String(Game.main.hud._toast.text).contains("见痕手记"), "flavor",
		"首发现播报：%s" % String(Game.main.hud._toast.text))
	var toast_after_dup: String = Game.main.hud._toast.text
	Game.mark_codex("themes", "vein")
	Dev.check(Game.main.hud._toast.text == toast_after_dup, "flavor", "重复登记不再播报")
	# D：分母不受影响（文案不入分母）
	Dev.check(Data.codex_bosses_total() == 7, "flavor", "分母仍 7（手记不入分母）")
	# D：图鉴手记行渲染（真调 _build_codex 扫描）
	Game.main.menu._build_codex()
	var note_shown := false
	for c in Game.main.menu._rows.get_children():
		if c is Label and String(c.text).contains("手记"):
			note_shown = true
	Dev.check(note_shown, "flavor", "图鉴渲染手记行")
	# ---------------- Sprint 20 A：手记扩容到全六类 ----------------
	Dev.check(Data.FLAVOR.size() == 74, "flavor", "手记 74 条（全六类覆盖：29 敌+12 遗+8 词+8 题+7 Boss+10 圣所+10 tips 逐字件 S40-R12）")
	Dev.check(not (Data.FLAVOR_BROADCAST_KINDS as Array).has("enemies"), "flavor",
		"enemies 不在播报白名单（防开局刷屏——S20 裁定）")
	# 播报白名单负向：enemies 首发现入图鉴但 toast 不变（撤销既有发现保证首发现路径可测）
	var had_rusher: bool = (Game.codex["enemies"] as Array).has("rusher")
	(Game.codex["enemies"] as Array).erase("rusher")
	var t_en_b4: String = Game.main.hud._toast.text
	Game.mark_codex("enemies", "rusher")
	Dev.check((Game.codex["enemies"] as Array).has("rusher") and Game.main.hud._toast.text == t_en_b4,
		"flavor", "enemies 首发现入图鉴但不播 toast（白名单负向）")
	if not had_rusher:
		(Game.codex["enemies"] as Array).erase("rusher")
	# 渲染：enemies 分区手记行含特征句（真调 _build_codex 扫描）
	Game.main.menu._build_codex()
	var enemy_note := false
	for c in Game.main.menu._rows.get_children():
		if c is Label and String(c.text).contains("成群来"):
			enemy_note = true
	Dev.check(enemy_note, "flavor", "图鉴 enemies 手记行渲染（含机制应对句）")
	# ---------------- Sprint 22 D：同帧首发现聚合（合并语义，验渲染非验标志） ----------------
	# 构造同帧三条白名单首发现（先撤销既有发现保证首发现路径可测）+ 一条非白名单对照；
	# 清 pending 防其它探针残留串扰，mark 后直调冲洗（与 call_deferred 同一入口，确定性时序）
	(Game.codex["themes"] as Array).erase("swamp")
	(Game.codex["bosses"] as Array).erase("dragon")
	(Game.codex["shrine"] as Array).erase("shard_pact")
	Game._flavor_pending.clear()
	Game.mark_codex("themes", "swamp")
	Game.mark_codex("bosses", "dragon")
	Game.mark_codex("shrine", "shard_pact")
	Game.mark_codex("enemies", "rusher")   # 非白名单：不进聚合
	Game._flush_flavor_toast()
	Dev.check(String(Game.main.hud._toast.text) == "图鉴新发现 ×3", "flavor",
		"S22 D: 同帧 3 条白名单首发现渲染为一条聚合 toast，非白名单不计入（%s）" % String(Game.main.hud._toast.text))
	Dev.check(is_equal_approx(Game.main.hud._toast.modulate.a, 1.0), "flavor",
		"S22 D: 聚合 toast 可见（modulate.a=1）")
	# 单条回归：清 pending 后单条首发现维持「见痕手记 ·」原格式
	(Game.codex["themes"] as Array).erase("magma")
	Game._flavor_pending.clear()
	Game.mark_codex("themes", "magma")
	Game._flush_flavor_toast()
	Dev.check(String(Game.main.hud._toast.text).contains("见痕手记 · 岩浆层"), "flavor",
		"S22 D: 单条首发现维持原格式（%s）" % String(Game.main.hud._toast.text))
	# Sprint 26 批二：toast 六道新词逐字上屏（「见痕手记 · 」格式串不变，只扩 value 内容）
	Dev.check(String(Game.main.hud._toast.text).contains("见痕手记 · 岩浆层。地狱热狱"), "flavor",
		"S26: toast 含「见痕手记 · 岩浆层。地狱热狱」（FLAVOR themes/magma value 逐字上屏）：%s" % String(Game.main.hud._toast.text))
	# ---------------- Sprint 22 附限定①：聚合冲洗结果断言（确定性直调版） ----------------
	# 【Sprint 24 降级登记——主理人处方 2】本断言原为 deferred 生产调度路径回归锁
	# （回调经 call_deferred 排队列尾、FIFO 排在 3 次冲洗之后）；S23 三次跑绿 2 红 1 实录证明
	# `await process_frame` 恢复点与帧末冲洗存在竞态，回调版间歇假红——**降级为直调冲洗断言**：
	# 验聚合冲洗逻辑（确定性），deferred 调度路径的常驻回归锁暂缺，登记为已知限制（Sprint 24/25 候选）。
	# 【Sprint 24 观察①②随批落地】完成标记移入探针侧 / floor_num 恢复点后移——见本块末尾注释
	Game._flavor_pending.clear()
	Game.main.hud.flash_toast("哨兵文本")
	# 三条均先撤销既有发现（smoke 档可能已有）——保证首发现路径可测，否则 mark 早退不入缓冲
	(Game.codex["themes"] as Array).erase("toxic")
	(Game.codex["bosses"] as Array).erase("demon")
	(Game.codex["shrine"] as Array).erase("ore_upgrade")
	Game.mark_codex("themes", "toxic")
	Game.mark_codex("bosses", "demon")
	Game.mark_codex("shrine", "ore_upgrade")
	Game._flush_flavor_toast()   # 直调冲洗：聚合逻辑断言（确定性）；F1-F3 的 deferred 排队此后各自空转
	Dev.check(String(Game.main.hud._toast.text) == "图鉴新发现 ×3", "flavor",
		"附限定①: 聚合冲洗结果（哨兵被覆盖，%s）" % String(Game.main.hud._toast.text))
	# Sprint 26 批二：图鉴手记行六道新词逐字上屏（themes/toxic 已在上方首发现登记，value 全文入行）
	Game.main.menu._build_codex()
	var s26_note := false
	for c in Game.main.menu._rows.get_children():
		if c is Label and String(c.text).contains("　手记：") \
			and String(c.text).contains("毒巢。饿鬼食毒"):
			s26_note = true
	Dev.check(s26_note, "flavor",
		"S26: 图鉴 themes 手记行含「毒巢。饿鬼食毒」（FLAVOR themes/toxic value 全文上屏）")
	# Sprint 24 观察①：完成标记保留探针侧打印（时序确定——回调版已降级，见上方降级登记）
	# Sprint 24 观察②：floor_num 恢复点位于断言之后——回调内若加依赖 floor_num 的断言会踩坑（当前无回调）
	Game.floor_num = bak_floor
	print("[SMOKE-FLOOR-SIGN] done")


## SMOKE_DAILY_SHARE=1：Sprint 17 C 每日分享码 + 本地榜断言
## 【Sprint 17 B 口径】全为「验效果型」：验数值 / 验渲染 / 负向构造 / 零 rng 状态差值，无恒过绿灯。
func _daily_share_probe() -> void:
	await get_tree().create_timer(0.6, true).timeout
	# 表外探针用独立隔离路径，避免与 SMOKE_DAILY 结算写入同一档互相污染（结束还原）
	var bak_override := Game.daily_path_override
	Game.daily_path_override = "user://_smoke_daily_share.cfg"
	var p := Game.daily_path()
	var fresh := ConfigFile.new()
	fresh.save(p)   # 复位空档，清掉跨 run 残留

	# ① 分享码往返（格式 + 校验位 + 日期键）+ 两条负向
	var code := Game.daily_share_code()
	Dev.check(Game.daily_share_code_valid(code) and code.begins_with(Game.daily_key() + "-"),
		"daily_share", "分享码格式+校验位往返一致：%s" % code)
	Dev.check(Game.daily_share_code_key(code) == Game.daily_key(), "daily_share", "分享码日期键读回一致")
	Dev.check(not Game.daily_share_code_valid(code + "0"), "daily_share", "篡改校验位被拒（负向）")
	Dev.check(not Game.daily_share_code_valid("garbage"), "daily_share", "非法格式被拒（负向）")

	# ② 零 rng 消费 + 同 seed 双跑逐字一致
	var rs = Game.rng.state
	var fs = Game.fx_rng.state
	var code2 := Game.daily_share_code()
	Dev.check(code2 == code and Game.rng.state == rs and Game.fx_rng.state == fs,
		"daily_share", "分享码零 Game.rng/fx_rng 消费且两次派生逐字一致")

	# ③ 榜单读写往返（真数值，不只验字段存在）
	Game.record_daily_best(3, 125.0)
	var today := Game.daily_best_today()
	Dev.check(int(today.get("layers", -1)) == 3 and is_equal_approx(float(today.get("time", -1.0)), 125.0),
		"daily_share", "今日最佳读回数值一致（3 层 / 125.0s）")
	var hist := Game.daily_history()
	Dev.check(hist.size() == 1 and String(hist[0].get("key", "")) == Game.daily_key()
		and int(hist[0].get("layers", -1)) == 3
		and is_equal_approx(float(hist[0].get("time", -1.0)), 125.0),
		"daily_share", "本地榜历史读回 1 条且数值一致")
	Game.record_daily_best(1, 200.0)   # 更差：不覆盖
	Dev.check(int(Game.daily_best_today().get("layers", -1)) == 3, "daily_share", "较差成绩不覆盖最佳")
	Game.record_daily_best(5, 60.0)    # 更好：覆盖
	Dev.check(int(Game.daily_best_today().get("layers", -1)) == 5
		and is_equal_approx(float(Game.daily_best_today().get("time", -1.0)), 60.0),
		"daily_share", "更优成绩覆盖最佳（5 层 / 60.0s）")
	Dev.check(Game.daily_history().size() == 1, "daily_share", "同日不重复追加（仍 1 条）")

	# ④ 7 天截尾（Sprint 17 QA 补强 Major#4：不只验 size，还验保留的是「最新 7 条」——
	# 把 out.slice(size-7) 改成 out.slice(0,7) 留最旧 7 条时，此断言必须转红）
	var many: Array = []
	for i in 9:
		many.append({"key": "202611%02d" % (i + 1), "layers": i + 1, "time": float(i)})
	var trimmed := Game.sanitize_daily_history(many)
	Dev.check(trimmed.size() == 7
		and String(trimmed[0].get("key", "")) == "20261103"
		and String(trimmed[6].get("key", "")) == "20261109", "daily_share",
		"7 天截尾保留最新 7 条（首 20261103 / 尾 20261109，非最旧 7 条）")

	# ⑤ 验渲染：真实 Label / LineEdit 节点文本（脱离 _rows 构建，避免与其它并发探针抢树）
	var holder := VBoxContainer.new()
	var w: Dictionary = Game.main.menu.build_daily_share_widgets(holder)
	var share_label: Label = w["share"]
	var hist_label: Label = w["history"]
	var edit: LineEdit = w["edit"]
	Dev.check(String(share_label.text).contains(code) and String(edit.text) == code,
		"daily_share", "主菜单分享码标签/输入框渲染实值：%s" % String(share_label.text))
	Dev.check(String(hist_label.text).begins_with("近 7 日：")
		and String(hist_label.text).contains("5层"), "daily_share",
		"主菜单本地榜渲染实值：%s" % String(hist_label.text))
	holder.free()
	# 表外探针落地证据：Dev.check 只在失败时打印，显式留一行成功数值证据（零 rng、不进指纹）
	print("[SMOKE-DAILY-SHARE] evidence code=%s best=%d层/%.1fs hist=%d text=%s" % [
		code, int(Game.daily_best_today().get("layers", -1)),
		float(Game.daily_best_today().get("time", -1.0)),
		Game.daily_history().size(), Game.daily_history_text()])

	# ⑥ 坏档降级不崩（放最后：会覆盖探针档）
	var bad := ConfigFile.new()
	bad.set_value("daily", "history", "not_an_array")
	bad.set_value("daily", Game.daily_key() + "_layers", "oops")
	bad.set_value("daily", Game.daily_key() + "_time", "bad")
	bad.save(p)
	Dev.check(Game.daily_history().is_empty(), "daily_share", "坏档 history 类型错误 → 降级为空 Array")
	Dev.check(int(Game.daily_best_today().get("layers", -1)) >= 0,
		"daily_share", "坏档今日最佳不崩且非负")
	Dev.check(Game.daily_history_text() == "近 7 日：暂无记录", "daily_share", "坏档显示文本降级")

	# ⑦ Sprint 17 QA 补强 Major#3：_load_daily_share / _copy_daily_share 四条定向断言。
	# 全部验文本 + 验字节/状态数值，不只验标志；复用 daily_path_override 隔离档。
	var menu_ref = Game.main.menu
	var bak_mode := Game.daily_mode
	Game.daily_mode = false
	var other := "20261107"
	var cross_code := other + "-" + Game.daily_share_checksum(other)
	# ① 跨日码拒绝：校验位合法但日期不是今日 → 状态行文本变化 + daily_mode 未置位 + 档字节未变
	var f_a := FileAccess.get_file_as_bytes(p)
	var status_a := Label.new()
	menu_ref._load_daily_share(cross_code, status_a)
	Dev.check(Game.daily_share_code_valid(cross_code)
		and String(status_a.text).contains("校验失败或非今日")
		and not Game.daily_mode
		and FileAccess.get_file_as_bytes(p) == f_a,
		"qa_fix", "跨日码拒绝：状态行文本变化 + daily_mode 未置位 + 档字节未变")
	# ② 篡改/垃圾码拒绝：状态行文本 + 未置位 + 未写盘 + rng 状态未变（未触发 start_game→start_run）
	var f_b := FileAccess.get_file_as_bytes(p)
	var rs_b = Game.rng.state
	var status_b := Label.new()
	menu_ref._load_daily_share(code + "0", status_b)
	menu_ref._load_daily_share("garbage", status_b)
	Dev.check(String(status_b.text).contains("校验失败或非今日")
		and not Game.daily_mode
		and FileAccess.get_file_as_bytes(p) == f_b
		and Game.rng.state == rs_b,
		"qa_fix", "篡改/垃圾码拒绝：状态行文本 + 未置位 + 未写盘 + rng 状态未变")
	# ③ headless 剪贴板跳过不抛错：护栏源码回读 + 调用无异常 + 档字节/rng 状态未变
	var f_c := FileAccess.get_file_as_bytes(p)
	var rs_c = Game.rng.state
	menu_ref._copy_daily_share()   # 若抛错，下面这行根本到不了
	var menu_src := FileAccess.get_file_as_string("res://scripts/menu.gd")
	Dev.check(String(menu_src).contains('if DisplayServer.get_name() == "headless":')
		and DisplayServer.get_name() == "headless"
		and FileAccess.get_file_as_bytes(p) == f_c
		and Game.rng.state == rs_c,
		"qa_fix", "headless 剪贴板跳过：护栏存在 + 未抛错 + 档字节/rng 状态未变")
	# ④ 合法今日码载入（最后一条断言）：临时置空 Game.main 隔离 start_game()→start_run()
	# 的重开局副作用（start_game 内有 null 守卫），同步还原、无帧穿插；之后不再断言。
	var f_d := FileAccess.get_file_as_bytes(p)
	var status_d := Label.new()
	var saved_main = Game.main
	Game.main = null
	menu_ref._load_daily_share(code, status_d)
	Game.main = saved_main
	Dev.check(Game.daily_mode == true
		and not String(status_d.text).contains("校验失败")
		and FileAccess.get_file_as_bytes(p) == f_d,
		"qa_fix", "合法今日码载入：daily_mode 置位 + 未走拒绝分支 + 未写盘")
	print("[SMOKE-QA-FIX] done cross=%s tamper=%s loaded_mode=%s bytes_unchanged=%s" % [
		String(status_a.text), String(status_b.text), str(Game.daily_mode),
		str(FileAccess.get_file_as_bytes(p) == f_d)])
	Game.daily_mode = bak_mode
	# 现场恢复：还原空档 + 取消 override
	var restore := ConfigFile.new()
	restore.save(p)
	Game.daily_path_override = bak_override
	print("[SMOKE-DAILY-SHARE] done code=%s" % code)


func _nearest_enemy() -> Node2D:
	var best: Node2D = null
	var best_d := 1e9
	for e in get_tree().get_nodes_in_group("enemies"):
		if not is_instance_valid(e) or e.dead:
			continue
		var d: float = e.global_position.distance_squared_to(global_position)
		if d < best_d:
			best_d = d
			best = e
	return best


## 直线朝目标走；若 0.4 秒内几乎没位移（被石柱/墙角顶住），横向绕半秒再继续
func _nav_steer(dir: Vector2, delta: float) -> Vector2:
	if _avoid_t > 0.0:
		_avoid_t -= delta
		return (dir + dir.orthogonal() * 1.4 * _avoid_sign).normalized()
	_nav_t += delta
	if _nav_t >= 0.4:
		if _nav_last != Vector2.ZERO and global_position.distance_to(_nav_last) < 8.0:
			_avoid_t = 0.5
			_avoid_sign = -_avoid_sign
		_nav_last = global_position
		_nav_t = 0.0
	return dir


func _autopilot_move(delta: float) -> Vector2:
	# 清场后：优先踩楼梯下楼，否则走向门
	if Game.main and Game.main.room_state == "cleared":
		var stairs: Node2D = get_tree().get_first_node_in_group("stairs_target")
		if stairs:
			return _nav_steer((stairs.global_position - global_position).normalized(), delta)
		var door_pos: Vector2 = Game.main.autopilot_door_target()
		if door_pos != Vector2.ZERO:
			if autopilot and Engine.get_process_frames() % 120 == 0:
				print("[SMOKE-NAV] room=%s player=%s -> door=%s" % [Game.main.dungeon.current, global_position.round(), door_pos.round()])
			# 贴身 1.2 秒仍进不去触发区（被机柜/墙角挡住）：直接过门，挂具测流程不测走位
			if global_position.distance_to(door_pos) < 90.0:
				_door_wait += delta
				if _door_wait >= 1.2:
					_door_wait = 0.0
					Game.main.use_door(Game.main.auto_door_dir)
			else:
				_door_wait = 0.0
			return _nav_steer((door_pos - global_position).normalized(), delta)
	var target := _nearest_enemy()
	if target == null:
		_wander_t -= delta
		if _wander_t <= 0.0:
			_wander_t = 1.2
			_wander = Vector2.from_angle(Game.rng.randf() * TAU)
		return _wander * 0.5
	var away := (global_position - target.global_position).normalized()
	if away == Vector2.ZERO:
		away = Vector2.from_angle(Game.rng.randf() * TAU)  # 与目标重叠时随机脱身
	var d := global_position.distance_to(target.global_position)
	var move := away * (1.0 if d < 100.0 else (0.0 if d < 150.0 else -0.5))
	move += away.orthogonal() * 0.5 * sin(Game.time * 2.2)
	return move.limit_length(1.0)


# ---------------- 受击/增益 ----------------

## 敌人接触伤害入口（带反伤判定）
func take_damage_from(dmg: int, from_node: Node) -> void:
	# 环绕护盾（主动遗物）：环盾期间豁免接触伤害（敌弹已在半径内被摧毁）
	if relic_shield_t > 0.0:
		return
	if thorns and not dead and is_instance_valid(from_node) and from_node.has_method("take_damage"):
		from_node.take_damage(1.0, Vector2.ZERO, false)
	take_damage(dmg, from_node.global_position if is_instance_valid(from_node) else global_position)


func grant_invuln(sec: float) -> void:
	_invuln_t = maxf(_invuln_t, sec)


func take_damage(dmg: int, from_pos: Vector2, _from_node: Node = null) -> void:
	if dead or _invuln_t > 0.0 or control_locked:
		return
	if _immortal:
		return
	# Sprint 21 C：深渊受创倍率（唯一入口，覆盖接触/敌弹/Boss/AoE；不改 sigil_ward 分支）
	if Game.main != null and is_instance_valid(Game.main):
		dmg = int(round(float(dmg) * Game.main.abyss_dmg_mult))
	# 守护印记：Boss 房受伤 -20%（round 取整：3→2 实际生效；保底 1）
	if sigil_ward and Game.main and is_instance_valid(Game.main) \
			and Game.main.dungeon.room(Game.main.dungeon.current).get("kind", "") == "boss":
		dmg = maxi(1, int(round(dmg * 0.8)))
		return
	# 护盾：优先消耗一层抵挡本次伤害
	if shield_charges > 0:
		shield_charges -= 1
		if Game.main != null and is_instance_valid(Game.main):
			Game.main.oath_count("shield_blocks")   # Sprint 16 A：誓约计数（盾未破身）
		Game.main.hud.flash_toast("护盾抵挡了这次伤害（剩 %d 层）" % shield_charges)
		Game.sfx("powerup", 1.4, -6.0)
		_invuln_t = 0.6
		return
	hp = maxi(hp - dmg, 0)
	if Game.main != null and is_instance_valid(Game.main):
		Game.main.oath_count("hits_taken")   # Sprint 16 A：誓约计数（流血不退）
	# 动能转换器 mr_kinetic：受击后 2 秒内移速 +40%
	if has_kinetic:
		buff("kinetic", 1.4, 2.0)
	_invuln_t = 0.9 + invuln_bonus
	_knock = (global_position - from_pos).normalized() * 130.0
	hp_changed.emit(hp, max_hp)
	damaged.emit(dmg)
	Game.shake(0.35)
	Game.sfx("hit", 0.7, -2.0)
	sprite.modulate = Color(1.0, 0.4, 0.4)
	get_tree().create_timer(0.15).timeout.connect(func() -> void:
		if is_instance_valid(sprite):
			sprite.modulate = Color.WHITE)
	if hp <= 0:
		if set_surv and not survive_used:
			survive_used = true
			hp = 2
			_invuln_t = 1.6
			hp_changed.emit(hp, max_hp)
			Game.main.hud.banner("生存套装 · 濒死保护")
			Game.sfx("powerup", 1.5)
			return
		_die()


func _die() -> void:
	if autopilot:
		print("[SMOKE-P] _die called")
	dead = true
	sprite.play("die")
	collision_mask = 1
	Game.sfx("player_die")
	Game.safe_delay(0.8, self, false, func() -> void: died.emit())


func heal(n: int) -> void:
	hp = mini(hp + n, max_hp)
	hp_changed.emit(hp, max_hp)


func add_bomb(n: int) -> void:
	bombs = mini(bombs + n, bomb_cap)
	bombs_changed.emit(bombs, bomb_cap)


func apply_blast_push(v: Vector2) -> void:
	_knock += v


func buff(id: String, mult: float, dur: float) -> void:
	if _buffs.has(id):
		_buffs[id].t = dur
	else:
		_buffs[id] = {"mult": mult, "t": dur}


func _tick_buffs(delta: float) -> void:
	speed_mult = speed_base
	damage_mult = 1.0
	rate_buff_mult = 1.0
	if skill_active():
		speed_mult *= 1.2
	var expired: Array[String] = []
	for id in _buffs:
		_buffs[id].t -= delta
		if _buffs[id].t <= 0.0:
			expired.append(id)
		else:
			match id:
				"boots", "kinetic":
					speed_mult *= _buffs[id].mult
				"book":
					damage_mult *= _buffs[id].mult
				"echo_rate":
					rate_buff_mult *= _buffs[id].mult
	for id in expired:
		_buffs.erase(id)


func _tick_timers(delta: float) -> void:
	_invuln_t = maxf(0.0, _invuln_t - delta)
	_reload_t = maxf(0.0, _reload_t - delta)
	_swap_t = maxf(0.0, _swap_t - delta)
	skill_cd = maxf(0.0, skill_cd - delta)
	skill_t = maxf(0.0, skill_t - delta)
	if _invuln_t > 0.0:
		sprite.visible = fmod(_invuln_t, 0.2) > 0.1
	else:
		sprite.visible = true


## SMOKE_ABYSS=1：深渊档 Boss 血量缩放断言（Sprint 21 收口批·验效果型——真构造 Boss 读 max_hp）
func _abyss_probe() -> void:
	await get_tree().create_timer(0.6, true).timeout
	var gm: Node = Game.main
	var boss_s: GDScript = load("res://scripts/boss.gd")
	var boss2_s: GDScript = load("res://scripts/boss2.gd")
	var boss3_s: GDScript = load("res://scripts/boss3.gd")
	var hp_mult_bak: float = gm.abyss_hp_mult
	var ehp_bak: float = gm.enemy_hp_mult
	var base_w: float = 320.0 * (1.0 + (11 - 4) * 0.12)
	var base_b: float = 360.0 * (1.0 + (11 - 4) * 0.12)
	# 基线：abyss=1.0 且 enemy_hp_mult=5.0 —— Boss max_hp 必须与 enemy_hp_mult 无关（P1 红线：只接 abyss）
	gm.abyss_hp_mult = 1.0
	gm.enemy_hp_mult = 5.0
	var w0: PrismWarden = boss_s.new()
	w0.setup(11)
	var b20: PrismWarden = boss2_s.new()
	b20.setup(11)
	var b30: PrismWarden = boss3_s.new()
	b30.setup(11)
	Dev.check(is_equal_approx(w0.max_hp, base_w), "abyss",
		"warden 基线（enemy_hp_mult=5 不影响）%.1f" % w0.max_hp)
	Dev.check(is_equal_approx(b20.max_hp, base_b) and is_equal_approx(b30.max_hp, base_b), "abyss",
		"boss2/boss3 基线 %.1f/%.1f" % [b20.max_hp, b30.max_hp])
	# 真差值：abyss_hp_mult 1.0 → 1.1，三 Boss max_hp 同步 ×1.1
	gm.abyss_hp_mult = 1.1
	var w1: PrismWarden = boss_s.new()
	w1.setup(11)
	var b21: PrismWarden = boss2_s.new()
	b21.setup(11)
	var b31: PrismWarden = boss3_s.new()
	b31.setup(11)
	Dev.check(is_equal_approx(w1.max_hp, base_w * 1.1) and is_equal_approx(b21.max_hp, base_b * 1.1)
		and is_equal_approx(b31.max_hp, base_b * 1.1), "abyss",
		"abyss_hp_mult=1.1 → 三 Boss max_hp ×1.1（%.1f/%.1f/%.1f）" % [w1.max_hp, b21.max_hp, b31.max_hp])
	# Sprint 21 订正批补档位：t=1 / t=10 读 ABYSS_TIERS 实表数值对照（主理人核验附限定③）
	gm.abyss_hp_mult = float(Data.ABYSS_TIERS[1]["hp"])
	var w_t1: PrismWarden = boss_s.new()
	w_t1.setup(11)
	Dev.check(is_equal_approx(w_t1.max_hp, base_w * 1.1), "abyss",
		"t=1（hp=1.10）warden %.1f" % w_t1.max_hp)
	w_t1.free()
	gm.abyss_hp_mult = float(Data.ABYSS_TIERS[10]["hp"])
	var w_t10: PrismWarden = boss_s.new()
	w_t10.setup(11)
	var b_t10: PrismWarden = boss2_s.new()
	b_t10.setup(11)
	Dev.check(is_equal_approx(w_t10.max_hp, base_w * 2.0) and is_equal_approx(b_t10.max_hp, base_b * 2.0),
		"abyss", "t=10（hp=2.00）warden/boss2 ×2.0（%.1f/%.1f）" % [w_t10.max_hp, b_t10.max_hp])
	w_t10.free()
	b_t10.free()
	gm.abyss_hp_mult = hp_mult_bak
	gm.enemy_hp_mult = ehp_bak
	w0.free()
	w1.free()
	b20.free()
	b21.free()
	b30.free()
	b31.free()
	print("[SMOKE-ABYSS] done")


## SMOKE_STREAK=1：Sprint 23 誓约连绩断言（V1/V2/V3/V4/V5/V6/V7 + n3/n8——实稿 §六口径；
## V10 静态核对 / V11 链路确认 / V12 前提守卫型如实单列不计绿灯——主理人裁定）
func _streak_probe() -> void:
	await get_tree().create_timer(0.6, true).timeout
	var gm: Node = Game.main
	# V1 纯函数四态真差值（先断言输入互不相同——四态断言的前提）。
	# Sprint 24 观察⑥：前提校验扩为全 6 对互异（原 3 对 → 全量；信息级、不计绿灯）
	Dev.check([0, 1, 1] != [3, 1, 1] and [0, 1, 1] != [3, 1, 0] and [0, 1, 1] != [3, 0, 1]
		and [3, 1, 1] != [3, 1, 0] and [3, 1, 1] != [3, 0, 1] and [3, 1, 0] != [3, 0, 1], "streak",
		"V1 前提: 四组输入全 6 对互不相同")
	Dev.check(gm.next_oath_streak(0, 1, 1) == 1 and gm.next_oath_streak(3, 1, 1) == 4
		and gm.next_oath_streak(3, 1, 0) == 0 and gm.next_oath_streak(3, 0, 1) == 3, "streak",
		"V1: f 四态 (0,1,1)=1 / (3,1,1)=4 / (3,1,0)=0 / (3,0,1)=3")
	# V7 一致性不变量（I1/I2/I3——f 的性质复述，T2）
	Dev.check(gm.next_oath_streak(3, 1, 1) >= 1, "streak", "V7 I1: D=1 ⇒ streak ≥ 1")
	Dev.check(gm.next_oath_streak(3, 1, 0) == 0, "streak", "V7 I2: H=1,D=0 ⇒ 0")
	Dev.check(gm.next_oath_streak(5, 0, 0) == 5, "streak", "V7 I3: H=0 ⇒ S_prev")
	# V2 落盘往返（★专打代价 1：覆盖式 set_codex_last_run 抹键 → (B) 覆盖前快照 → 第二次写盘还原）
	Game.equip_sigil("vigor")
	gm._oath_counters["hits_taken"] = 3   # vigor watched=[hits_taken] need=3 → done=true
	Game.codex["last_run"]["oath_streak"] = 3   # 置 S_prev=3（模拟已持久化）
	var prev: int = gm._read_oath_streak()
	Dev.check(prev == 3, "streak", "V2 前置: 覆盖前快照 prev=3")
	var stats: Dictionary = gm._run_stats()
	Game.set_codex_last_run(stats)
	Dev.check(not (Game.codex["last_run"] as Dictionary).has("oath_streak"), "streak",
		"V2 代价 1 实证: 覆盖式 set_codex_last_run 抹掉 streak 键")
	gm._write_codex_replay(prev)   # (B) 第二次写盘：连绩与 oath 同次落盘（T3 无撕裂）
	Game.load_codex()
	Dev.check(int(Game.codex["last_run"].get("oath_streak", -1)) == 4, "streak",
		"V2: prev=3 → 真调覆盖+写回 → load 读回 4")
	Dev.check(int((Game.codex["last_run"].get("oath", {}) as Dictionary).get("cur", -1)) == 3, "streak",
		"V2 T3: oath 与 streak 同次写回（无撕裂）")
	# D=0 → 断绩 0
	gm._oath_counters["hits_taken"] = 2
	gm._write_codex_replay(prev)
	Game.load_codex()
	Dev.check(int(Game.codex["last_run"].get("oath_streak", -1)) == 0, "streak",
		"V2: D=0 → 断绩 0")
	# n3 数据级负向：oath_streak 塞进 stats → STATS_KEYS 白名单静默丢弃（不改代码即证）
	var stats_n3: Dictionary = gm._run_stats()
	stats_n3["oath_streak"] = 3
	Game.set_codex_last_run(stats_n3)
	Game.load_codex()
	Dev.check(not (Game.codex["last_run"] as Dictionary).has("oath_streak"), "streak",
		"n3: 塞进 stats 被白名单静默丢弃")
	# V4 渲染真差值：真调 show_page("codex")——连绩行文本随 streak 4→7 跟变
	gm._oath_counters["hits_taken"] = 3
	Game.codex["last_run"]["oath"] = gm.oath_fulfillment()
	Game.codex["last_run"]["oath_streak"] = 4
	Game.main.menu.show_page("codex")
	# Sprint 24 交叉陈述适配：连绩行追加发现度段——S23 精确断言改子串断言（原文本子串保留）
	Dev.check(_scan_codex_label("连绩 · ").contains("连绩 · 4 局"), "streak",
		"V4: streak=4 渲染含「连绩 · 4 局」（%s）" % _scan_codex_label("连绩 · "))
	Game.codex["last_run"]["oath_streak"] = 7
	Game.main.menu.show_page("codex")
	Dev.check(_scan_codex_label("连绩 · ").contains("连绩 · 7 局"), "streak",
		"V4 真差值: streak=7 渲染含「连绩 · 7 局」（%s）" % _scan_codex_label("连绩 · "))
	# V6 T1 用词区分：新前缀 + 既有「本局誓约」一字不变
	Dev.check(_scan_codex_label("本局誓约") != "", "streak", "V6: 既有「本局誓约」行仍在（一字未改）")
	# V5：H=0（oath 空）→ 连绩行不创建（即便 streak 键存在——I3 后半）。
	# 走 show_page（清场+重建，queue_free 旧标签）而非直调 _build_codex（不清 _rows 会累积）
	(Game.codex["last_run"] as Dictionary)["oath"] = {}
	Game.main.menu.show_page("codex")
	Dev.check(_scan_codex_label("连绩 · ") == "", "streak", "V5: H=0 → 连绩行不创建")
	# Sprint 24 订正③补：H=0 → 复盘行不含连绩段（streak_seg 与独立行同判据——oath 空则段为空）
	Dev.check(_scan_codex_label("上局复盘 · ").contains("连绩 · ") == false, "streak",
		"订正③补: H=0 → 复盘行不含连绩段")
	# 印记页：真调 show_page("sigils")——上局连绩 + 既有「上局誓约」一字不变（V6）
	Game.codex["last_run"]["oath"] = gm.oath_fulfillment()
	Game.codex["last_run"]["oath_streak"] = 7
	Game.main.menu.show_page("sigils")
	Dev.check(_scan_codex_label("上局连绩 · ").contains("上局连绩 · 7 局"), "streak",
		"V6: 印记页「上局连绩 · 7 局」（%s）" % _scan_codex_label("上局连绩 · "))
	Dev.check(_scan_codex_label("上局誓约") != "", "streak", "V6: 既有「上局誓约」行仍在")
	# V3：旧档无键 + 坏档非数值 → 读侧归 0（三道防线之一；不迁移不补写不改 load_codex）
	Game.codex["last_run"].erase("oath_streak")
	Dev.check(gm._read_oath_streak() == 0, "streak", "V3a: 旧档无键 → 读侧 0")
	var bad_cfg := ConfigFile.new()
	# 坏值必须嵌进 last_run 字典（load_codex 读的是 codex/last_run 键；写在 codex 节顶层
	# 会被静默忽略——首跑真空转实证）。非数值 String 走 int() 强转仍归 0（弱靶）；
	# 布尔 true 是强靶：无守卫 int(true)=1 ≠ 守卫后 0（n4 变异靶点）
	bad_cfg.set_value("codex", "last_run", {"oath": {}, "oath_streak": "not_a_number"})
	bad_cfg.save(Game.codex_path())
	Game.load_codex()
	Dev.check(gm._read_oath_streak() == 0, "streak", "V3b: 坏档非数值 → 类型守卫归 0")
	bad_cfg.set_value("codex", "last_run", {"oath": {}, "oath_streak": true})
	bad_cfg.save(Game.codex_path())
	Game.load_codex()
	Dev.check(gm._read_oath_streak() == 0, "streak", "V3c: 坏档布尔 → 类型守卫归 0")
	# V3 后清场：oath_streak 键归零态——n8 断言前提（防 V3c 布尔跨节残留误伤）
	Game.codex["last_run"].erase("oath_streak")
	Game.save_codex()
	Game.load_codex()
	# n8 哨兵负向：无参直调（prev=-1）不写 streak 键——哨兵语义常驻回归锁
	Game._flavor_pending.clear()
	Game.codex["last_run"]["oath"] = {}
	gm._write_codex_replay()
	Game.load_codex()
	Dev.check(not (Game.codex["last_run"] as Dictionary).has("oath_streak"), "streak",
		"n8: 无参直调（哨兵 -1）不写 streak 键")
	# ---------------- Sprint 24 B：发现度档 + 三刻度交叉（零字段，验渲染真差值） ----------------
	# 构造两档达成（enemies_5 + relics_4）——mark_codex 走真实登记路径（SMOKE 隔离档累积）；
	# 全清六类消除探针间状态累积（前跑 4/4 vs 2/4 前置矛盾即此——隔离后增量构造）
	for k in Game.CODEX_KINDS:
		Game.codex[k] = []
	Game.mark_codex("enemies", "goblin")
	Game.mark_codex("enemies", "rusher")
	Game.mark_codex("enemies", "skeleton")
	Game.mark_codex("enemies", "zombie")
	Game.mark_codex("enemies", "orc")
	Dev.check(Game.codex_boons().size() == 1, "streak", "S24 状态 A: 1/4 档达成")
	Game.main.menu.show_page("codex")
	Dev.check(_scan_codex_label("发现度 · ") == "发现度 · 1/4 档", "streak",
		"S24: 发现度档渲染 1/4（%s）" % _scan_codex_label("发现度 · "))
	# 状态 B：+4 遗物 → 2/4 档（真差值：渲染跟变）
	Game.mark_codex("relics", "fang")
	Game.mark_codex("relics", "thorn")
	Game.mark_codex("relics", "bounce")
	Game.mark_codex("relics", "frost")
	Game.main.menu.show_page("codex")
	Dev.check(_scan_codex_label("发现度 · ") == "发现度 · 2/4 档", "streak",
		"S24 真差值: 2/4 档跟变（%s）" % _scan_codex_label("发现度 · "))
	# 交叉陈述：复盘行追加连绩段+发现度段；连绩行追加发现度段（原文本子串保留）
	Game.codex["last_run"]["oath_streak"] = 2
	Game.main.menu.show_page("codex")
	var replay_seg: String = _scan_codex_label("上局复盘 · ")
	Dev.check(replay_seg.contains("发现度 · 2/4 档") and replay_seg.contains("连绩 · 2 局")
		and replay_seg.begins_with("上局复盘 · 最深"), "streak",
		"S24: 复盘行交叉陈述（%s）" % replay_seg)
	Dev.check(_scan_codex_label("连绩 · ").contains("发现度 · 2/4 档"), "streak",
		"S24: 连绩行交叉陈述（发现度追加）")
	# 零副作用：show_page 前后 codex 深拷贝一致（同步段不跨 await——per-call 快照）
	var c_b4: Dictionary = Game.codex.duplicate(true)
	Game.main.menu.show_page("codex")
	Dev.check(Game.codex.duplicate(true) == c_b4, "streak",
		"S24: show_page 零副作用（codex 深拷贝一致）")
	# 空判：全清六类 → 0 达成 → 发现度 Label 不创建（非建后隐藏——S24 空判）
	for k in Game.CODEX_KINDS:
		Game.codex[k] = []
	Game.main.menu.show_page("codex")
	Dev.check(_scan_codex_label("发现度 · ") == "", "streak", "S24 空判: 0 达成 → 不创建")
	# 负向对照③（数据级）：交叉陈述无评价词（禁「建议 / 最优 / 优先 / 划算」——T1 词族纪律）
	var banned := ["建议", "最优", "优先", "划算"]
	var no_advice := true
	for c in Game.main.menu._rows.get_children():
		if c is Label:
			for bw in banned:
				if String(c.text).contains(bw):
					no_advice = false
	Dev.check(no_advice, "streak", "S24 负向③: 复盘页无评价词")
	print("[SMOKE-STREAK] done")


func _scan_codex_label(prefix: String) -> String:
	for c in Game.main.menu._rows.get_children():
		# is_queued_for_deletion 过滤：show_page 清场走 queue_free（帧末才真正释放），
		# 不跳过的话同帧重建后扫描会命中旧标签（V4/V5 首跑实录）
		if c is Label and not c.is_queued_for_deletion() and String(c.text).begins_with(prefix):
			return String(c.text)
	return ""
