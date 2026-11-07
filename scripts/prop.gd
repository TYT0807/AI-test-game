class_name Prop
extends StaticBody2D
## 地图道具：石柱（挡路）/ 爆炸桶（打爆范围伤害）/ 图腾（打爆给增益）/ 尖刺（踩到掉血）。

var kind := "pillar"
var max_hp := 1
var hp := 1

var _broken := false
var _sprite: Sprite2D
var _hit_cd := 0.0
var _flash := 0.0


func setup(k: String) -> void:
	kind = k
	var cfg: Dictionary = Data.OBSTACLES.get(k, {})
	max_hp = int(cfg.get("hp", 1))
	hp = max_hp


func _ready() -> void:
	var solid := kind == "pillar" or kind == "barrel" or kind == "totem" or kind == "vine"
	# 石柱与藤蔓全阻挡（layer 1：挡人挡弹挡虫）；桶/图腾仅挡人挡弹（layer 64）
	collision_layer = 1 if kind == "pillar" or kind == "vine" else (64 if solid else 0)
	collision_mask = 0
	add_to_group("props")
	if kind != "spike":
		add_to_group("crates")

	if kind != "spike":
		var shape := CollisionShape2D.new()
		var rect := RectangleShape2D.new()
		rect.size = Vector2(26, 22)
		shape.shape = rect
		add_child(shape)

	_sprite = Sprite2D.new()
	_sprite.texture = Assets.g("prop_" + kind)
	if kind == "spike":
		_sprite.position = Vector2(0, 2)
	add_child(_sprite)
	z_index = 3


func _process(delta: float) -> void:
	if kind != "spike" or _broken:
		return
	_hit_cd = maxf(0.0, _hit_cd - delta)
	var p: Node2D = Game.main.player
	if _hit_cd <= 0.0 and is_instance_valid(p) and not p.dead \
			and p.global_position.distance_to(global_position) < 16.0:
		_hit_cd = 1.2
		p.take_damage(1, global_position)
		_sprite.modulate = Color(2.2, 1.2, 1.2)
		if _flash <= 0.0:
			_flash = 0.12
	if _flash > 0.0:
		_flash -= delta
		if _flash <= 0.0 and is_instance_valid(_sprite):
			_sprite.modulate = Color.WHITE


func crate_take_damage(amount: float) -> void:
	if _broken:
		return
	if kind == "pillar":
		return  # 石柱不可破坏
	if kind == "spike":
		return
	hp -= int(maxf(amount, 0.0))
	if kind == "barrel":
		_sprite.texture = Assets.g("prop_barrel_hit")
	_sprite.modulate = Color(2.4, 1.8, 1.6)
	get_tree().create_timer(0.08).timeout.connect(func() -> void:
		if is_instance_valid(_sprite) and not _broken:
			_sprite.modulate = Color.WHITE)
	if hp <= 0:
		_break()


func _break() -> void:
	if _broken:
		return
	_broken = true
	match kind:
		"barrel":
			Game.main.explode(global_position, float(Data.OBSTACLES["barrel"]["explode"]), 3.0, true)
		"totem":
			Game.sfx("secret")
			Game.main.drop_pickup(global_position, ["boots", "book", "clock"].pick_random())
			Game.main.drop_pickup(global_position + Vector2(10, 0), "heal")
			Game.main.hud.flash_toast("图腾之力：获得增益")
		_:
			Game.sfx("die", 0.8, -8.0)
	queue_free()
