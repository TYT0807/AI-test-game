class_name Bomb
extends Node2D
## 炸弹：抛物线飞到落点 → 引信闪烁 → 爆炸结算交给 main.explode()。

var radius := 46.0
var dmg := 6.0

var _sprite: Sprite2D
var _fuse := 0.5
var _defused := false


func setup(from: Vector2, to: Vector2, radius_v: float, dmg_v: float) -> void:
	position = from
	radius = radius_v
	dmg = dmg_v
	_throw(from, to)


func _ready() -> void:
	add_to_group("bombs")
	_sprite = Sprite2D.new()
	_sprite.texture = Assets.icon("bomb")
	add_child(_sprite)


## 拆弹单位（F3 狙击+拆弹编队）调用：掐灭引信，哑弹消散
func defuse() -> void:
	if _defused:
		return
	_defused = true
	if OS.get_environment("SMOKE") != "":
		print("[SMOKE] bomb defused at ", global_position.round())
	Game.sfx("reload", 0.65, -10.0)
	var tw := create_tween()
	tw.tween_property(_sprite, "modulate", Color(0.6, 0.6, 0.6, 0.0), 0.25)
	tw.tween_callback(queue_free)


## 探针用：延长引信，给拆弹单位留出到位时间
func set_fuse(t: float) -> void:
	_fuse = t


func _throw(from: Vector2, to: Vector2) -> void:
	var tw := create_tween()
	var dur := clampf(from.distance_to(to) / 260.0, 0.25, 0.6)
	tw.tween_method(_arc_step.bind(from, to), 0.0, 1.0, dur)
	tw.tween_callback(_prime)


func _arc_step(t: float, from: Vector2, to: Vector2) -> void:
	position = from.lerp(to, t)
	_sprite.position.y = -sin(t * PI) * 26.0
	_sprite.rotation += 0.2


func _prime() -> void:
	var tw := create_tween()
	tw.set_loops(4)
	tw.tween_property(_sprite, "modulate", Color(2.5, 0.8, 0.8), _fuse / 8.0)
	tw.tween_property(_sprite, "modulate", Color.WHITE, _fuse / 8.0)
	tw.finished.connect(_boom)


func _boom() -> void:
	if _defused:
		return
	Game.main.explode(global_position, radius, dmg, false)
	queue_free()
