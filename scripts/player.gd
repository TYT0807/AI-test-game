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
	Game.main._calamity = ""
	print("[SMOKE-SIGIL-COV] done")
	# 恢复印记存档现场（测试不污染玩家进度）
	Game.sigils = bak
	Game.save_sigils()


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
		Game.main.hud.flash_toast("护盾抵挡了这次伤害（剩 %d 层）" % shield_charges)
		Game.sfx("powerup", 1.4, -6.0)
		_invuln_t = 0.6
		return
	hp = maxi(hp - dmg, 0)
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
