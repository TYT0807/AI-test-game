class_name Slug
extends CharacterBody2D
## 敌人：数值与行为由 Data.ENEMIES 驱动。
## ai: chase 追击 / erratic 飘忽 / spitter 风筝 / turret 定点 / bomber 自爆 /
##     leap 蓄力突进 / summon 召唤 / boss 冲锋+弹幕+召唤

var variant := "rusher"
var hp := 3.0
var max_hp := 3.0
var speed := 50.0
var dmg := 1
var xp_value := 1
var score_value := 10
var dead := false
var affix := ""
var shield_hits := 0
var defuser := false            # F3 拆弹单位：优先追近并拆除玩家炸弹
var _mender_cfg := {}           # F3 治疗词缀配置（空 = 非治疗者）
var _heal_t := 0.0

var _cfg: Dictionary = {}
var _knock := Vector2.ZERO
var _hit_cd := 0.0
var _shoot_cd := 2.0
var _summon_cd := 6.0
var _primed := false
var _prime_t := 0.0
var _dash_cd := 4.5
var _dash_t := 0.0
var _dash_dir := Vector2.ZERO
var _slow_mult := 1.0
var _slow_t := 0.0
var _phase := 0.0
var _bob := 0.0
var _face := Vector2.RIGHT
var _echo_t := 0.0   # F3/B 回响：镜像/突进周期计时（E6 固定步）
var _poison_t := 0.0
var _poison_dps := 0.0
var _poison_acc := 0.0
var sprite: AnimatedSprite2D
var _shadow: Sprite2D


func _ready() -> void:
	motion_mode = CharacterBody2D.MOTION_MODE_FLOATING
	collision_layer = 4
	collision_mask = 1 | 4
	add_to_group("enemies")

	var shape := CollisionShape2D.new()
	var circle := CircleShape2D.new()
	circle.radius = 9.0
	shape.shape = circle
	add_child(shape)

	_shadow = Sprite2D.new()
	_shadow.texture = Assets.monster("shadow")
	_shadow.position = Vector2(0, 12)
	_shadow.z_index = -1
	add_child(_shadow)

	sprite = AnimatedSprite2D.new()
	sprite.sprite_frames = _frames_for(variant)
	sprite.play("walk")
	add_child(sprite)


func _frames_for(id: String) -> SpriteFrames:
	var c: Dictionary = Data.ENEMIES.get(id, {})
	if c.get("atlas", "") == "slug":
		return Assets.slug_frames(int(c.get("row", 0)))
	return Assets.monster_frames(String(c.get("tex", "goblin")))


func setup(id: String, wave: int, floor_num := 1, affix_id := "") -> void:
	if not Data.ENEMIES.has(id):
		Dev.err("slug", "未知敌人：%s（已回退地精）" % id)
		id = "goblin"
	variant = id
	affix = affix_id
	_cfg = Data.ENEMIES[id].duplicate()
	# 叠加 AI 手感参数覆盖（见 Data.AI_OVERRIDES）；缺省值仍由各 AI 函数自己兜
	var ov: Dictionary = Data.AI_OVERRIDES.get(id, {})
	for k in ov:
		_cfg[k] = ov[k]
	max_hp = float(_cfg["hp"]) * (1.0 + wave * 0.12) * (1.0 + floor_num * 0.55) * Game.main.enemy_hp_mult
	if affix_id == "armored":
		max_hp *= 1.15
	hp = max_hp
	speed = float(_cfg["speed"]) * (1.0 + floor_num * 0.05) * Game.main.enemy_speed_mult
	if affix_id == "swift":
		speed *= float(Data.AFFIXES["swift"]["speed"])
	dmg = int(_cfg["dmg"])
	xp_value = int(_cfg["xp"])
	score_value = int(_cfg["score"])
	scale = Vector2.ONE * float(_cfg["scale"])
	if is_inside_tree() and sprite:
		sprite.sprite_frames = _frames_for(id)
		sprite.play("walk")
	# 词缀染色 + 头顶标记
	sprite.self_modulate = Color.WHITE
	if affix_id != "":
		sprite.self_modulate = Data.AFFIXES[affix_id]["tint"]
		if affix_id == "shielded":
			shield_hits = int(Data.AFFIXES["shielded"]["shield"])
		if affix_id == "ranged":
			_shoot_cd = Game.rng.randf_range(0.4, 1.6)
		if affix_id == "mender":
			# F3 治疗+冲锋编队：周期治疗范围内友军（E6 固定步计时）
			_mender_cfg = Data.AFFIXES["mender"]
		var ic := Sprite2D.new()
		ic.texture = Assets.xicon(String(Data.AFFIXES[affix_id].get("icon", "")))
		ic.position = Vector2(0, -20)
		ic.scale = Vector2(0.7, 0.7)
		ic.z_index = 6
		add_child(ic)
	if variant == "boss":
		Game.boss_hp_changed.emit(hp, max_hp)


func apply_poison(dps: float, dur: float) -> void:
	_poison_dps = maxf(_poison_dps, dps)
	_poison_t = maxf(_poison_t, dur)


func apply_slow(mult: float, dur: float) -> void:
	_slow_mult = mult
	_slow_t = dur


func _physics_process(delta: float) -> void:
	if dead:
		return
	var player: Node2D = Game.main.player
	if player == null or not is_instance_valid(player) or not Game.playing:
		velocity = _knock
		_knock = _knock.move_toward(Vector2.ZERO, 400.0 * delta)
		move_and_slide()
		return
	var to_player := player.global_position - global_position
	var dist := to_player.length()
	var dir := to_player.normalized()
	_face = dir

	# 场外兜底
	if global_position.x < 20.0 or global_position.y < 20.0 \
			or global_position.x > Game.main.ARENA_W * 16.0 - 20.0 \
			or global_position.y > Game.main.ARENA_H * 16.0 - 20.0:
		global_position = Game.main.clamp_to_arena(global_position)

	_hit_cd = maxf(0.0, _hit_cd - delta)
	_phase = fmod(_phase + delta, TAU)
	_bob += delta
	_slow_t = maxf(0.0, _slow_t - delta)
	# 中毒：每 0.5 秒结算一次
	if _poison_t > 0.0:
		_poison_t -= delta
		_poison_acc += delta
		sprite.self_modulate = sprite.self_modulate.lerp(Color(0.6, 1.3, 0.6), 0.5)
		if _poison_acc >= 0.5:
			_poison_acc = 0.0
			hp -= _poison_dps * 0.5
			Game.damage_number(global_position, _poison_dps * 0.5, false)
			if hp <= 0.0:
				_die()
				return
		if _poison_t <= 0.0:
			_poison_dps = 0.0
			sprite.self_modulate = Color.WHITE if affix == "" else Data.AFFIXES[affix]["tint"]
	if _slow_t <= 0.0:
		_slow_mult = 1.0
	if affix == "ranged":
		_shoot_cd -= delta
		if _shoot_cd <= 0.0 and dist < 560.0:
			_shoot_cd = float(Data.AFFIXES["ranged"]["shoot_cd"])
			Game.main.spawn_enemy_bullet(global_position, dir, 130.0, 1, Color(1.0, 0.85, 0.5))
			Game.sfx("shoot", 0.6, -9.0)

	match String(_cfg.get("ai", "chase")):
		"spitter":
			_ai_spitter(dist, dir, delta)
		"turret":
			_ai_turret(dist, dir, delta)
		"bomber":
			_ai_bomber(dist, dir, delta)
		"leap":
			_ai_leap(dist, dir, delta)
		"summon":
			_ai_summon(dist, dir, delta)
		"boss":
			_ai_boss(dist, dir, delta)
		"erratic":
			_ai_erratic(dist, dir, delta)
		"echo":
			_ai_echo(dist, dir, delta)
		_:
			_ai_chase(dist, dir, delta)

	if dist < 14.0 and _dash_t <= 0.0:
		velocity = _knock

	# F3 编队行为：治疗脉冲（E6 固定步计时）/ 拆弹优先（覆盖贴身停顿与追击）
	if not _mender_cfg.is_empty():
		_heal_t += Game.FIXED_DT
		if _heal_t >= float(_mender_cfg.get("heal_cd", 4.0)):
			_heal_t = 0.0
			_heal_allies(float(_mender_cfg.get("heal", 2.0)), float(_mender_cfg.get("heal_range", 90.0)))
	if defuser:
		var bomb: Node2D = _nearest_bomb(240.0)
		if bomb != null:
			velocity = (bomb.global_position - global_position).normalized() * speed * 1.25 \
				* Game.enemy_speed_mult * _slow_mult + _knock
			if global_position.distance_to(bomb.global_position) < 18.0:
				bomb.defuse()

	_knock = _knock.move_toward(Vector2.ZERO, 400.0 * delta)
	move_and_slide()
	sprite.flip_h = dir.x < 0.0
	# 呼吸/浮动：静态贴图也能看出「活着」
	sprite.position.y = sin(_bob * 6.0 + _phase) * 1.2 - 1.0
	_shadow.scale = Vector2.ONE * (1.0 + sin(_bob * 6.0) * 0.04)

	if _hit_cd <= 0.0 and dmg > 0 and dist < 14.0 and not player.dead:
		player.take_damage_from(dmg, self)
		_hit_cd = 0.7
		if _cfg.get("drain", false):
			hp = minf(hp + 1.0, max_hp)
			Game.damage_number(global_position, 1, false)


func _move_with(dir: Vector2, mult: float) -> void:
	velocity = dir * speed * Game.enemy_speed_mult * Game.calamity_speed_mult * _slow_mult * mult + _knock


## F3 拆弹：范围内最近的玩家炸弹
func _nearest_bomb(range_v: float) -> Node2D:
	var best: Node2D = null
	var best_d := range_v * range_v
	for b in get_tree().get_nodes_in_group("bombs"):
		if not is_instance_valid(b):
			continue
		var d: float = b.global_position.distance_squared_to(global_position)
		if d < best_d:
			best_d = d
			best = b
	return best


## F3 治疗脉冲：范围内存活的友军回血（含自身），有实际治疗才闪绿与出声
func _heal_allies(amount: float, range_v: float) -> void:
	var healed := 0
	for a in get_tree().get_nodes_in_group("enemies"):
		if not is_instance_valid(a) or a.dead:
			continue
		if a.global_position.distance_to(global_position) > range_v:
			continue
		if a.hp < a.max_hp:
			a.hp = minf(a.hp + amount, a.max_hp)
			healed += 1
	if healed > 0:
		Game.sfx("powerup", 1.6, -12.0)
		sprite.modulate = Color(0.65, 1.5, 0.75)
		get_tree().create_timer(0.12).timeout.connect(func() -> void:
			if is_instance_valid(sprite) and not dead:
				sprite.modulate = Color.WHITE if affix == "" else Data.AFFIXES[affix]["tint"])


## 统一弹幕发射：n 发、夹角 spread；弹速与伤害取 ai_* 字段
func _fire_burst(dir: Vector2, n: int, spread: float, color := Color(0.85, 0.85, 1.0)) -> void:
	var cnt: int = maxi(n, 1)
	for i in cnt:
		var off: float = (float(i) - float(cnt - 1) * 0.5) * spread
		Game.main.spawn_enemy_bullet(global_position, dir.rotated(off),
			float(_cfg.get("ai_bullet_speed", 95.0)), float(_cfg.get("ai_bullet_dmg", 1.0)), color)


func _ai_chase(_dist: float, dir: Vector2, _delta: float) -> void:
	_move_with(dir, 1.0)


## F3/B 回响（Sprint 12）：前 2.5 秒沿玩家轨迹缓冲倒放镜像玩家走位，
## 之后 3 秒周期游走、末 0.5 秒突进。全部计时走 Game.FIXED_DT（E6）。
## 数值 Sprint 13 E 提为 Data.ECHO_TUNING（零逻辑改动，调数值只改 data.gd）
func _ai_echo(dist: float, dir: Vector2, _delta: float) -> void:
	_echo_t += Game.FIXED_DT
	var pl: Node2D = Game.main.player
	var mirror: float = float(Data.ECHO_TUNING["mirror_time"])
	if _echo_t < mirror and is_instance_valid(pl) and not pl.trail.is_empty():
		var trail: Array[Vector2] = pl.trail
		var idx := clampi(int((_echo_t / mirror) * float(trail.size())), 0, trail.size() - 1)
		var target: Vector2 = trail[trail.size() - 1 - idx]
		var to_target := target - global_position
		velocity = to_target.limit_length(speed * float(Data.ECHO_TUNING["chase_mult"])
			* Game.enemy_speed_mult * _slow_mult) + _knock
		return
	# 镜像结束：游走 + 周期突进（压制玩家走位节奏）
	var cycle := fmod(_echo_t, float(Data.ECHO_TUNING["cycle"]))
	var mult := float(Data.ECHO_TUNING["dash_mult"]) if cycle > float(Data.ECHO_TUNING["cycle"]) - 0.5 \
		else float(Data.ECHO_TUNING["creep_mult"])
	velocity = dir * speed * mult * Game.enemy_speed_mult * _slow_mult + _knock


func _ai_erratic(_dist: float, dir: Vector2, _delta: float) -> void:
	var sway := dir.rotated(sin(_bob * float(_cfg.get("ai_sway", 3.2)) + _phase) * float(_cfg.get("ai_sway_amp", 0.8)))
	_move_with(sway, 1.0)


func _ai_spitter(dist: float, dir: Vector2, delta: float) -> void:
	# 行为参数全部来自 Data.ENEMIES 的 ai_* 字段，缺省值即原硬编码
	var keep: float = float(_cfg.get("ai_keep", 100.0))
	if dist > keep + 30.0:
		_move_with(dir.rotated(sin(_bob * 1.7 + _phase) * 0.5), 1.0)
	elif dist < keep - 20.0:
		_move_with(-dir, 0.7)
	else:
		velocity = _knock
	_shoot_cd -= delta
	if _shoot_cd <= 0.0 and dist < float(_cfg.get("ai_range", 220.0)):
		var cd: float = float(_cfg.get("ai_cd", 1.8))
		_shoot_cd = Game.rng.randf_range(cd, cd + 0.8)
		_fire_burst(dir, int(_cfg.get("ai_burst", 1)), float(_cfg.get("ai_spread", 0.25)))
		Game.sfx("shoot", 0.6, -10.0)


func _ai_turret(dist: float, dir: Vector2, delta: float) -> void:
	velocity = _knock
	_shoot_cd -= delta
	if _shoot_cd <= 0.0 and dist < float(_cfg.get("ai_range", 260.0)):
		var cd: float = float(_cfg.get("ai_cd", 1.6))
		_shoot_cd = Game.rng.randf_range(cd, cd + 0.8)
		_fire_burst(dir, int(_cfg.get("ai_burst", 3)), float(_cfg.get("ai_spread", 0.16)))
		Game.sfx("shoot", 0.55, -12.0)


func _ai_bomber(dist: float, dir: Vector2, delta: float) -> void:
	if _primed:
		_prime_t -= delta
		velocity = Vector2.ZERO
		sprite.modulate = Color(1, 1, 1) if fmod(_prime_t, 0.12) > 0.06 else Color(2.0, 1.2, 0.6)
		if _prime_t <= 0.0:
			dead = true
			Game.main.explode(global_position, 52.0, 3.0, true)
			queue_free()
		return
	_move_with(dir, 1.0)
	if dist < float(_cfg.get("ai_range", 40.0)):
		_primed = true
		_prime_t = 0.55
		Game.sfx("pickup", 1.6, -8.0)


func _ai_leap(dist: float, dir: Vector2, delta: float) -> void:
	_dash_cd -= delta
	if _dash_t > 0.0:
		_dash_t -= delta
		velocity = _dash_dir * float(_cfg.get("ai_dash", 260.0)) + _knock
		if _dash_t <= 0.0:
			_dash_cd = float(_cfg.get("ai_cd", 3.4))
	elif _dash_cd <= 0.0 and dist < float(_cfg.get("ai_range", 220.0)):
		sprite.modulate = Color(1.8, 1.3, 1.3)
		velocity = Vector2.ZERO
		if _dash_cd < -0.45:
			_dash_dir = dir
			_dash_t = float(_cfg.get("ai_dash_time", 0.28))
			sprite.modulate = Color.WHITE
			Game.sfx("reload", 0.9, -8.0)
	else:
		_move_with(dir, 1.0)


func _ai_summon(dist: float, dir: Vector2, delta: float) -> void:
	var keep: float = float(_cfg.get("ai_keep", 200.0))
	if dist > keep:
		_move_with(dir, 1.0)
	else:
		_move_with(-dir, 0.45)
	_summon_cd -= delta
	if _summon_cd <= 0.0:
		_summon_cd = float(_cfg.get("ai_cd", 6.5))
		var kid := String(_cfg.get("summon", "mini"))
		var cnt: int = int(_cfg.get("ai_n", 2))
		for i in cnt:
			Game.main.spawn_slug(kid, global_position + Vector2.from_angle(Game.rng.randf() * TAU) * 26.0)
		Game.sfx("powerup", 0.6, -12.0)


func _ai_boss(dist: float, dir: Vector2, delta: float) -> void:
	_dash_cd -= delta
	if _dash_t > 0.0:
		_dash_t -= delta
		velocity = _dash_dir * float(_cfg.get("ai_dash", 250.0)) + _knock
		if _dash_t <= 0.0:
			_dash_cd = float(_cfg.get("ai_cd", 3.8))
	elif _dash_cd <= 0.0:
		sprite.modulate = Color(2.0, 1.4, 1.4)
		velocity = Vector2.ZERO
		if _dash_cd < -0.45:
			_dash_dir = dir
			_dash_t = float(_cfg.get("ai_dash_time", 0.42))
			sprite.modulate = Color.WHITE
			Game.sfx("reload", 0.8, -6.0)
	else:
		_move_with(dir, 1.0)
	# 弹幕
	_shoot_cd -= delta
	if _shoot_cd <= 0.0:
		_shoot_cd = 3.2
		_boss_volley(dir)
	# 召唤
	_summon_cd -= delta
	if _summon_cd <= 0.0:
		_summon_cd = 8.0
		var kid := String(_cfg.get("summon", "mini"))
		for i in 2:
			Game.main.spawn_slug(kid, global_position + Vector2.from_angle(Game.rng.randf() * TAU) * 42.0)


func _boss_volley(dir: Vector2) -> void:
	match variant:
		"demon":
			for i in 8:
				Game.main.spawn_enemy_bullet(global_position, dir.rotated(TAU * i / 8.0), 110.0, 2, Color(1.0, 0.45, 0.2))
		"dragon":
			_fire_burst(dir, int(_cfg.get("ai_burst", 4)), float(_cfg.get("ai_spread", 0.19)),
				Color(0.55, 0.7, 1.0))
		_:
			_fire_burst(dir, int(_cfg.get("ai_burst", 3)), float(_cfg.get("ai_spread", 0.2)))
	Game.sfx("shoot", 0.5, -8.0)


func take_damage(amount: float, from_dir: Vector2, crit: bool) -> void:
	if dead:
		return
	if shield_hits > 0:
		shield_hits -= 1
		Game.sfx("hit", 1.4, -6.0)
		sprite.modulate = Color(0.7, 1.3, 1.5)
		get_tree().create_timer(0.12).timeout.connect(func() -> void:
			if is_instance_valid(sprite) and not dead:
				sprite.modulate = Color.WHITE)
		return
	var final := amount
	# 正面甲：子弹逆着朝向打来
	var armor := float(_cfg.get("armor", 0.0))
	if armor > 0.0 and from_dir.dot(_face) < -0.35:
		final *= (1.0 - armor)
	if affix == "armored":
		final *= float(Data.AFFIXES["armored"]["taken"])
	hp -= final
	Game.damage_number(global_position, final, crit)
	Game.sfx("hit", Game.fx_rng.randf_range(1.1, 1.3), -10.0)
	_knock += from_dir * 60.0
	if variant == "boss":
		Game.boss_hp_changed.emit(maxf(hp, 0.0), max_hp)
	sprite.modulate = Color(1.9, 1.25, 1.25)
	get_tree().create_timer(0.08).timeout.connect(func() -> void:
		if is_instance_valid(sprite) and not dead:
			sprite.modulate = Color.WHITE)
	if hp <= 0.0:
		_die()


func _die() -> void:
	dead = true
	collision_layer = 0
	collision_mask = 0
	sprite.play("die")
	sprite.self_modulate = Color(0.6, 0.55, 0.55)
	if affix == "volatile":
		Game.main.explode(global_position, float(Data.AFFIXES["volatile"]["death_boom"]), 2.0, false)
	if affix == "death":
		var n := int(Data.AFFIXES["death"]["split"])
		for i in n:
			Game.main.spawn_slug("mini", global_position + Vector2(-10 + i * 20, 0))
	# 元素套装：中毒的敌人死亡时爆炸
	if is_instance_valid(Game.main.player) and Game.main.player.set_elem and _poison_t > 0.0:
		Game.main.explode(global_position, 34.0, 2.0, false)
	if _cfg.has("death_cloud"):
		Game.main.spawn_toxic_cloud(global_position)
	Game.main.on_slug_killed(self)
	var kid := String(_cfg.get("split", ""))
	if kid != "":
		for off in [Vector2(-10, 0), Vector2(10, 0)]:
			Game.main.spawn_slug(kid, global_position + off)
	Game.safe_delay(0.35, self, false, queue_free)
