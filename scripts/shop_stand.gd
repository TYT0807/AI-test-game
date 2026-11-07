class_name ShopStand
extends Area2D
## 商店货架：站在旁边按 E 购买；diamonds 不够会提示。

var kind := "relic"  # relic / weapon / heal
var price := 20
var payload := ""  # relic id 或 weapon id
var sold := false

var _icon: Sprite2D
var _price_label: Label
var _player_near: Node = null


func setup(kind_v: String, payload_v: String, price_v: int) -> void:
	kind = kind_v
	payload = payload_v
	price = price_v


func _ready() -> void:
	collision_layer = 0
	collision_mask = 2

	var shape := CollisionShape2D.new()
	var circle := CircleShape2D.new()
	circle.radius = 26.0
	shape.shape = circle
	add_child(shape)

	var base := Sprite2D.new()
	base.texture = Assets.g("pedestal")
	base.position = Vector2(0, 6)
	add_child(base)

	_icon = Sprite2D.new()
	match kind:
		"weapon":
			_icon.texture = Weapons.icon(payload)
			_icon.scale = Vector2.ONE
		"relic":
			_icon.texture = Assets.g(Relics.by_id(payload)["icon"])
		"heal":
			_icon.texture = Assets.icon("face")
	_icon.position = Vector2(0, -8)
	add_child(_icon)

	_price_label = Label.new()
	_price_label.text = "%d 源石" % price
	if Assets.font():
		_price_label.add_theme_font_override("font", Assets.font())
	_price_label.add_theme_font_size_override("font_size", 10)
	_price_label.add_theme_color_override("font_outline_color", Color(0, 0, 0))
	_price_label.add_theme_constant_override("outline_size", 4)
	_price_label.position = Vector2(-20, 14)
	_price_label.z_index = 5
	add_child(_price_label)

	body_entered.connect(func(b: Node) -> void:
		if b.is_in_group("player"):
			_player_near = b)
	body_exited.connect(func(b: Node) -> void:
		if b == _player_near:
			_player_near = null)


func _unhandled_input(event: InputEvent) -> void:
	if sold or _player_near == null:
		return
	if event.is_action_pressed("buy") and not Game.main._transitioning:
		get_viewport().set_input_as_handled()
		_try_buy()


func _try_buy() -> void:
	if Game.spend(price):
		sold = true
		Game.sfx("secret", 1.1, -3.0)
		match kind:
			"weapon":
				Game.main.give_player_weapon(payload)
			"relic":
				Game.main.give_player_relic(payload)
			"heal":
				_player_near.heal(2)
		_icon.visible = false
		_price_label.text = "已售出"
		_price_label.modulate = Color(0.6, 0.6, 0.6)
	else:
		Game.sfx("pickup", 0.7, -6.0)
		Game.main.hud.flash_toast("源石不足！")
