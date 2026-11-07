class_name DoorNode
extends Area2D
## 房间门：未清场时锁死（有碰撞体），清场后开门，玩家触碰过门。

var dir := Vector2i.ZERO  # 指向相邻房间
var locked := true
var _hold := false  # 落点压在触发区时先失效，玩家离开后自动恢复

var _sprite: Sprite2D
var _blocker: StaticBody2D


func _ready() -> void:
	collision_layer = 0
	collision_mask = 2
	monitoring = true

	var shape := CollisionShape2D.new()
	var rect := RectangleShape2D.new()
	rect.size = Vector2(40, 34)
	shape.shape = rect
	add_child(shape)

	_sprite = Sprite2D.new()
	_sprite.texture = Assets.g("door_closed")
	add_child(_sprite)

	_blocker = StaticBody2D.new()
	_blocker.collision_layer = 1
	_blocker.collision_mask = 0
	var bs := CollisionShape2D.new()
	var br := RectangleShape2D.new()
	br.size = Vector2(44, 36)
	bs.shape = br
	_blocker.add_child(bs)
	add_child(_blocker)

	body_entered.connect(_on_body_entered)
	body_exited.connect(_on_body_exited)


func hold_until_exit() -> void:
	_hold = true


func set_locked(v: bool) -> void:
	locked = v
	_blocker.get_child(0).set_deferred("disabled", not v)
	_blocker.set_deferred("collision_layer", 1 if v else 0)
	_sprite.texture = Assets.g("door_closed" if v else "door_open")


func _on_body_entered(body: Node) -> void:
	if _hold or locked or not body.is_in_group("player"):
		return
	Game.main.use_door(dir)


func _on_body_exited(body: Node) -> void:
	if body.is_in_group("player"):
		_hold = false
