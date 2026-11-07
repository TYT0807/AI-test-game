class_name Turret
extends Node2D
## 浮游炮：环绕玩家自动索敌开火；Mk1-4 用颜色区分（红→铁灰→紫→金）。

const TIER_COLOR := [
	Color(1, 1, 1),
	Color(1, 1, 1),
	Color(0.55, 0.62, 0.8),
	Color(0.78, 0.5, 1.0),
	Color(1.0, 0.82, 0.3),
]
const TIER_DMG := [0.0, 1.0, 2.0, 3.0, 4.0]
const TIER_INTERVAL := [0.0, 1.3, 1.05, 0.85, 0.65]
const TIER_RANGE := [0.0, 130.0, 140.0, 150.0, 170.0]

var target: Node2D
var tier := 0

var _orbit_angle := 0.0
var _fire_cd := 0.0
var _unit_angles: Array = [0.0]  # 炮位相位；双浮游炮遗物追加
var _unit_index := 0
var sprites: Array = []


func _ready() -> void:
	_add_sprite()


func _add_sprite() -> void:
	var s := AnimatedSprite2D.new()
	s.sprite_frames = Assets.turret_frames()
	s.animation = "hover"
	s.play()
	add_child(s)
	sprites.append(s)


func set_tier(t: int) -> void:
	tier = clampi(t, 0, 4)
	_apply_tier_visual()


func add_unit() -> void:
	if _unit_angles.size() >= 2:
		return
	_unit_angles.append(PI)
	_add_sprite()
	_apply_tier_visual()


func _apply_tier_visual() -> void:
	visible = tier >= 1
	for s in sprites:
		s.modulate = TIER_COLOR[tier]


func _physics_process(delta: float) -> void:
	if tier <= 0 or target == null or not is_instance_valid(target):
		return
	_orbit_angle += 1.6 * delta
	var anchor: Vector2 = target.global_position + Vector2(0, -10)
	# 多炮位均匀分布
	for i in sprites.size():
		var ang := _orbit_angle + float(_unit_angles[i])
		sprites[i].global_position = anchor + Vector2.from_angle(ang) * 22.0
		sprites[i].flip_h = cos(ang) < 0.0

	_fire_cd -= delta
	if _fire_cd > 0.0:
		return
	var prey := _nearest_in_range(TIER_RANGE[tier], sprites[0].global_position)
	if prey == null:
		return
	_fire_cd = TIER_INTERVAL[tier] / sprites.size()
	_unit_index = (_unit_index + 1) % sprites.size()
	var from: Vector2 = sprites[_unit_index].global_position
	var dir := (prey.global_position - from).normalized()
	_fire(dir, from)
	if tier >= 4:
		_fire(dir.rotated(deg_to_rad(10.0)), from)


func _fire(dir: Vector2, from: Vector2) -> void:
	Game.main.spawn_player_bullet(
		from + dir * 8.0, dir, 230.0, TIER_DMG[tier], 1 if tier >= 3 else 0,
		TIER_COLOR[tier], 0.8, 0, 1.4, 0, 0.0)
	Game.sfx("shoot", 1.5, -12.0)


func _nearest_in_range(range_v: float, from: Vector2) -> Node2D:
	var best: Node2D = null
	var best_d := range_v * range_v
	for e in get_tree().get_nodes_in_group("enemies"):
		if not is_instance_valid(e) or e.dead:
			continue
		var d: float = e.global_position.distance_squared_to(from)
		if d < best_d:
			best_d = d
			best = e
	return best
