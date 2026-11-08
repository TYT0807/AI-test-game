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
var weapon_slots: Array = ["rifle", ""]
var slot := 0
var slot_mags := {"rifle": 8}
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
var harvester_active := false  # 丰收：击杀额外 +1 源石
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
var has_resocore := false   # 源石共鸣核心 mx_resocore：共鸣计数源改为源石
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
var _swap_t := 0.0
var _fire_cd := 0.0
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
	if OS.get_environment("SMOKE_SHRINE") != "":
		_shrine_probe.call_deferred()
	if OS.get_environment("SMOKE_CODEX") != "":
		_codex_probe.call_deferred()
	if OS.get_environment("SMOKE_CODEX_BOON") != "":
		_codex_boon_probe.call_deferred()
	if OS.get_environment("SMOKE_THIRD_BOSS") != "":
		_third_boss_probe.call_deferred()
	if OS.get_environment("SMOKE_OATH") != "" or OS.get_environment("SMOKE_ECHO_CHAIN") != "":
		_oath_probe.call_deferred()
	if OS.get_environment("SMOKE_FLOOR_SIGN") != "" or OS.get_environment("SMOKE_FLAVOR") != "":
		_floor_sign_probe.call_deferred()


# ---------------- 武器 ----------------

func cur_weapon() -> String:
	return weapon_slots[slot]


func cur_def() -> Dictionary:
	return WeaponsClass.DEFS[cur_weapon()]


func mag_cap() -> int:
	return maxi(1, int((int(cur_def()["mag"]) + mag_bonus) * mag_cap_mult))


func mag() -> int:
	return int(slot_mags.get(cur_weapon(), mag_cap()))


func refresh_mag_cap() -> void:
	slot_mags[cur_weapon()] = mini(int(slot_mags.get(cur_weapon(), mag_cap())), mag_cap())
	mag_changed.emit(mag(), mag_cap())


func give_weapon(id: String) -> void:
	if not WeaponsClass.DEFS.has(id):
		# 未知 id 会在 mag_cap_for 直接崩，点名并回退
		Dev.err("weapon", "未知武器 id：%s（回退标准步枪）" % id)
		id = "rifle"
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

	if sprite.animation == "attack" and not sprite.is_playing():
		sprite.play("idle")
	if moving:
		var anim := "walk_down"
		match _facing:
			"up": anim = "walk_up"
			"side": anim = "walk_side"
		sprite.flip_h = _facing == "side" and velocity.x < 0.0
		if sprite.animation != anim and not (sprite.animation == "attack" and sprite.is_playing()):
			sprite.play(anim)
			sprite.frame = 0
	elif sprite.animation != "idle" and sprite.animation != "attack":
		sprite.play("idle")


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


func _start_reload() -> void:
	if _reload_t > 0.0 or mag() >= mag_cap():
		return
	_reload_t = float(cur_def()["reload"])
	Game.sfx("reload", 1.0, -3.0)
	Game.safe_delay(_reload_t, self, false, func() -> void:
		if dead:
			return
		slot_mags[cur_weapon()] = mag_cap()
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
				ok = weapon_slots[1] == "shotgun"
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
	Game.main._calamity = "scarce_ore"
	Game.main._apply_calamity()
	Dev.check(Game.main.diamond_mult < dm, "sigil_cov", "scarce_ore 削减")
	Game.main._clear_calamity_effects()
	Dev.check(Game.main.diamond_mult == dm, "sigil_cov", "scarce_ore 还原")
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


## SMOKE_SHRINE=1：圣所断言——三卡确定性 / 效果+代价逐条 / 置灰 / 实开面板全链（Sprint 13 A）
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
	Dev.check(ids_a == ids_b and ids_a.size() == 3, "shrine", "三卡同 key 派生一致：%s" % str(ids_a))
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
	Dev.check(Game.diamonds == 12, "shrine", "ore_upgrade 代价源石 20→12：%d" % Game.diamonds)
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
	Dev.check(Game.diamonds == 40 and max_hp == pre_hp2 - 1, "shrine", "D: greed_pact 上限换源石 30→40")
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
	Dev.check(int(Game.sigils["shards"]) == sh0 + 6 and Game.diamonds == 8, "shrine", "D: shard_pact 源石换碎片")
	# ③ 置灰：余额/血量不足不可支付（面板据此置灰，主侧 _on_shrine_chosen 双保险同口径）
	Game.diamonds = 0
	Dev.check(gm._shrine_affordable(gm._shrine_entry("ward_boon")) == false, "shrine", "源石 0 → ward_boon 置灰")
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
		gm._open_shrine(cur)
		Dev.check(gm.shrine_panel._root.visible, "shrine", "面板已打开（三卡渲染）")
		await get_tree().create_timer(1.4, true).timeout   # autopick 0.5s + 执行收尾
		Dev.check(not gm.shrine_panel._root.visible, "shrine", "选择后面板关闭")
		Dev.check(bool(gm.dungeon.rooms[cur]["cleared"]), "shrine", "选择后 cleared 回写（重进不再扣/发）")
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
	print("[SMOKE-SHRINE] done")


func _shrine_ids(offers: Array) -> Array:
	var out: Array = []
	for o in offers:
		out.append(String(o["id"]))
	return out


## SMOKE_CODEX=1：图鉴断言——隔离档 / 未知 id 忽略 / 读写往返 / 负数钳制（Sprint 13 C）+
## Sprint 14 A 登记三件套 + B 批加固断言
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
	cfgf.load(Game.codex_path())   # Sprint 15 P0-3.2：先读回原档再改——否则 save() 抹掉五类发现集（非隔离环境会清玩家图鉴）
	cfgf.set_value("codex", "last_run", {"max_floor": -9, "time": -2.5})
	cfgf.save(Game.codex_path())
	Game.load_codex()
	Dev.check(int(Game.codex["last_run"].get("max_floor", -1)) == 0
		and int(Game.codex["last_run"].get("time", -1)) == 0, "codex", "B2: 读档负数钳制 → 0")
	# P0-3.2 验收：B2 断言后五类发现集与探针执行前逐类一致（现场恢复，非隔离环境也不清档）
	var sets_same := true
	for k in Game.CODEX_KINDS:
		if (Game.codex[k] as Array) != (snap[k] as Array):
			sets_same = false
	Dev.check(sets_same, "codex", "P0-3.2: B2 后五类发现集现场恢复")
	print("[SMOKE-CODEX] done")


## SMOKE_CODEX_BOON=1：图鉴发现度被动断言——阈值边界 / 派生确定性 / 起始状态落地 / 载体零命中（Sprint 14 C）
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
	# B：抉择链 + 主导代价标签
	gm._echo_choices.clear()
	gm._echo_costs.clear()
	gm._echo_choices.append("purify")
	gm._echo_costs[""] = 1
	gm._echo_choices.append("greed_pact")
	gm._echo_costs["max_hp"] = 2
	Dev.check(String(gm._echo_tag()) == "血偿流", "echo", "构筑标签：主导代价 max_hp → 血偿流")
	# A/B 落盘（真实入口 _write_codex_replay）：写 → load → 逐字段读回 + 五类发现集不被抹
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
	Dev.check(sets_ok, "oath", "五类发现集不被抹（P0-3.2 写法）")
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


## SMOKE_FLOOR_SIGN / SMOKE_FLAVOR：层签 + 地窖低语断言（Sprint 16 C/D）
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
	# D：首发现播报（清条目 → mark → toast 文本含手记；重复 mark → 文本不变）
	(Game.codex["themes"] as Array).erase("vein")
	Game.mark_codex("themes", "vein")
	Dev.check(String(Game.main.hud._toast.text).contains("矿工手记"), "flavor",
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
	Game.floor_num = bak_floor
	print("[SMOKE-FLOOR-SIGN] done")


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
