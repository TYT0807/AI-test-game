class_name Crate
extends StaticBody2D
## 机柜木箱：可被打爆，掉补给。

var hp := 3
var _broken := false

var _sprite: Sprite2D


func _ready() -> void:
	collision_layer = 64  # layer 7：独立于墙(1)，敌人爬得过、子弹和玩家会被挡
	collision_mask = 0
	add_to_group("crates")

	var shape := CollisionShape2D.new()
	var rect := RectangleShape2D.new()
	rect.size = Vector2(26, 12)
	shape.shape = rect
	add_child(shape)

	_sprite = Sprite2D.new()
	_sprite.texture = Assets.crate_tex(0)
	add_child(_sprite)


func crate_take_damage(amount: float) -> void:
	if _broken:
		return
	hp -= int(amount)
	_sprite.modulate = Color(2.0, 1.6, 1.6)
	get_tree().create_timer(0.08).timeout.connect(func() -> void:
		if is_instance_valid(_sprite):
			_sprite.modulate = Color.WHITE)
	if hp <= 0:
		_break()
	else:
		_sprite.texture = Assets.crate_tex(1)


func _break() -> void:
	if _broken:
		return
	_broken = true
	Game.sfx("die", 0.8, -8.0)
	# 小火花
	var ex := preload("res://scripts/explosion.gd").new()
	ex.setup("spark", 0.6)
	ex.position = global_position
	get_parent().add_child(ex)
	# 掉落
	Game.main.drop_pickup(global_position, "diamond", 1)
	Game.main.drop_pickup(global_position, "diamond", 1)
	var r := Game.rng.randf()
	if r < 0.2:
		Game.main.drop_pickup(global_position, "bomb")
	elif r < 0.35:
		Game.main.drop_pickup(global_position, ["boots", "book", "clock"].pick_random())
	queue_free()
