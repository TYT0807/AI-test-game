class_name Explosion
extends Node2D
## 爆炸/火花动画：blast（炸弹）或 spark（枪口、命中）。

var sprite: AnimatedSprite2D


func setup(kind: String, scale_f: float, flip := false) -> void:
	# 在入树前记录参数，_ready 里应用
	set_meta("kind", kind)
	set_meta("scale_f", scale_f)
	set_meta("flip", flip)


func _ready() -> void:
	var kind: String = get_meta("kind", "blast")
	var scale_f: float = get_meta("scale_f", 1.0)
	var flip: bool = get_meta("flip", false)
	sprite = AnimatedSprite2D.new()
	sprite.sprite_frames = Assets.boom_frames()
	sprite.flip_h = flip
	sprite.scale = Vector2.ONE * scale_f
	add_child(sprite)
	sprite.play(kind)
	sprite.animation_finished.connect(queue_free)
