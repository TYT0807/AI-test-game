extends StaticBody2D
## 秘密房裂纹墙：只有炸弹能炸开（子弹无效），炸开后重建成正常门。

var dir := Vector2i.ZERO
var hp := 1  # 一颗炸弹就能开

var _sprite: Sprite2D


func _ready() -> void:
	collision_layer = 64
	collision_mask = 0
	add_to_group("secret_walls")

	var shape := CollisionShape2D.new()
	var rect := RectangleShape2D.new()
	rect.size = Vector2(46, 30)
	shape.shape = rect
	add_child(shape)

	_sprite = Sprite2D.new()
	_sprite.texture = Assets.g("secret_wall")
	_sprite.scale = Vector2(1.5, 1.0)
	add_child(_sprite)


## 只有爆炸会调用这里
func bomb_hit() -> void:
	hp -= 1
	_sprite.modulate = Color(2.2, 1.7, 1.4)
	get_tree().create_timer(0.08).timeout.connect(func() -> void:
		if is_instance_valid(_sprite):
			_sprite.modulate = Color.WHITE)
	if hp <= 0:
		Game.main.reveal_secret(dir)
		queue_free()
