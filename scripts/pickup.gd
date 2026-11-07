class_name Pickup
extends Area2D
## 掉落物：源石/回复/炸弹/宝箱/疾速/火力/时钟/武器/遗物/大宝箱/楼梯。

const TEX_KEY := {
	"diamond": "diamond",
	"heal": "face",
	"bomb": "bomb",
	"chest": "chest",
	"boots": "boots",
	"book": "book",
	"clock": "clock",
}

var kind := "diamond"
var value := 1
var payload := ""  # weapon id / relic id / suffix id

var _player: Node2D
var _t := 0.0
var _sprite: Sprite2D
var _life := 20.0
var _claimed := false
var _expires := true
var _magnetic := true
var _open_tex := ""


func _ready() -> void:
	collision_layer = 32
	collision_mask = 2
	monitoring = true
	_t = Game.fx_rng.randf() * TAU

	match kind:
		"chest_big":
			_expires = false
			_magnetic = false
			_open_tex = "chest_open"
			_sprite = Sprite2D.new()
			_sprite.texture = Assets.g("chest_closed")
			_sprite.scale = Vector2(1.4, 1.4)
		"suffix":
			# 反应词缀（F2/A）：不磁吸（玩家主动拾取取舍）、不过期
			_expires = false
			_magnetic = false
			_sprite = Sprite2D.new()
			_sprite.texture = Assets.g("icon_suffix")
			_sprite.scale = Vector2(1.3, 1.3)
		"stairs":
			_expires = false
			_magnetic = false
			add_to_group("stairs_target")
			_sprite = Sprite2D.new()
			_sprite.texture = Assets.g("stairs")
		"weapon":
			_expires = false
			_sprite = Sprite2D.new()
			_sprite.texture = Weapons.icon(payload)
			_sprite.scale = Vector2(1.1, 1.1)
		"relic":
			_expires = false
			_sprite = Sprite2D.new()
			_sprite.texture = Assets.g(Relics.by_id(payload)["icon"])
		_:
			_sprite = Sprite2D.new()
			_sprite.texture = Assets.icon(TEX_KEY.get(kind, "diamond"))

	var shape := CollisionShape2D.new()
	var circle := CircleShape2D.new()
	circle.radius = 8.0
	shape.shape = circle
	add_child(shape)
	add_child(_sprite)
	body_entered.connect(_on_body_entered)


func _physics_process(delta: float) -> void:
	_t += delta
	if _expires:
		_sprite.position.y = sin(_t * 3.0) * 2.0
		_life -= delta
		if _life <= 0.0:
			var tw := create_tween()
			tw.tween_property(self, "modulate:a", 0.0, 0.4)
			tw.tween_callback(queue_free)
			_life = 1e9
			return
	if not _magnetic:
		return
	if _player == null or not is_instance_valid(_player):
		_player = Game.main.player if Game.main else null
		return
	if _player.dead:
		return
	var d := global_position.distance_to(_player.global_position)
	if d < _player.magnet_radius:
		global_position = global_position.move_toward(_player.global_position, (170.0 + (60.0 - d) * 4.0) * delta)


func _on_body_entered(body: Node) -> void:
	if _claimed or not body.is_in_group("player"):
		return
	_claimed = true
	# 物理回调期不能动场景树，延迟到帧末
	_apply.call_deferred(body)
	queue_free()


func _apply(player: Node) -> void:
	match kind:
		"diamond":
			Game.add_xp(value)
			Game.add_diamonds(value)
			Game.sfx("pickup", Game.fx_rng.randf_range(1.4, 1.7), -14.0)
		"heal":
			player.heal(1)
			Game.sfx("powerup", 1.3, -4.0)
		"bomb":
			player.add_bomb(1)
			Game.sfx("reload", 1.4, -6.0)
		"chest":
			Game.add_xp(6)
			Game.add_diamonds(4)
			player.heal(1)
			Game.add_score(200)
			Game.sfx("secret")
		"boots":
			player.buff("boots", 1.3, 15.0)
			Game.sfx("powerup", 1.2)
		"book":
			player.buff("book", 1.5, 15.0)
			Game.sfx("powerup", 0.9)
		"clock":
			Game.slowmo(4.0, 0.45)
			Game.main.slowmo_fx(4.0)
			Game.sfx("secret", 0.8, -4.0)
		"weapon":
			Game.main.give_player_weapon(payload)
		"relic":
			Game.main.give_player_relic(payload)
		"suffix":
			# F2/A 反应词缀：附着到对应遗物（每遗物 1 条，新替换旧）
			var res: Dictionary = player.attach_suffix(payload)
			Game.sfx("secret", 1.2, -6.0)
		"chest_big":
			# 宝箱房大宝箱：武器或遗物二选一 + 源石
			Game.sfx("secret")
			var ex := preload("res://scripts/explosion.gd").new()
			ex.setup("spark", 0.8)
			ex.position = global_position
			get_parent().add_child(ex)
			if Game.rng.randf() < 0.5:
				Game.main.drop_pickup(global_position + Vector2(0, -14), "weapon", 1, _random_weapon())
			else:
				Game.main.drop_pickup(global_position + Vector2(0, -14), "relic", 1, _random_relic())
			Game.main.drop_pickup(global_position + Vector2(-10, 6), "diamond", 2)
			Game.main.drop_pickup(global_position + Vector2(10, 6), "diamond", 2)
		"stairs":
			Game.main.next_floor()


func _random_weapon() -> String:
	return Weapons.random_unlocked()


func _random_relic() -> String:
	var r: Array = Relics.roll(1)
	return r[0]["id"] if not r.is_empty() else "heart"
