extends Node2D
## 商店商人：按楼层换皮肤，站柜台后轻轻起伏。

var _t := 0.0
var _base_y := 0.0


func _ready() -> void:
	var skin := (Game.floor_num - 1) % 3
	var body := Sprite2D.new()
	body.texture = Assets.g("merchant_%d" % skin)
	body.position = Vector2(0, -4)
	add_child(body)

	var label := Label.new()
	label.text = "商人"
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	if Assets.font():
		label.add_theme_font_override("font", Assets.font())
	label.add_theme_font_size_override("font_size", 12)
	label.add_theme_color_override("font_color", Color(1.0, 0.88, 0.6))
	label.add_theme_color_override("font_outline_color", Color(0.1, 0.08, 0.06))
	label.add_theme_constant_override("outline_size", 4)
	label.position = Vector2(-18, -34)
	add_child(label)
	_t = Game.fx_rng.randf() * TAU
	_base_y = position.y


func _process(delta: float) -> void:
	_t += delta
	position.y = _base_y + sin(_t * 2.0) * 1.5
