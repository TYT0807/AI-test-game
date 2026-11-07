class_name AllyDrone
extends CharacterBody2D
## 协战印记（Sprint 12 A）的临时协战水晶：追击最近敌人，接触伤害 2；30 秒后消散。
## 友方判定明确：不在 enemies 组（敌方可碰不可伤）、不在 player 组（免遭友军误伤），
## 玩家子弹 layer 8 不含本层（mask 0）→ 子弹穿过。全部计时 Game.FIXED_DT（E6）。

const LIFE := 30.0
const CONTACT_DMG := 2.0

var speed := 85.0
var _life := LIFE
var _hit_cd := 0.0
var _bob := 0.0
var sprite: Sprite2D


func _ready() -> void:
	motion_mode = CharacterBody2D.MOTION_MODE_FLOATING
	collision_layer = 0
	collision_mask = 4   # 与敌人身体碰撞（推挤），但不被敌方弹/接触逻辑命中
	var shape := CollisionShape2D.new()
	var circle := CircleShape2D.new()
	circle.radius = 7.0
	shape.shape = circle
	add_child(shape)

	sprite = Sprite2D.new()
	sprite.texture = Assets.g("boss_prism_shard")
	sprite.modulate = Color(0.6, 1.0, 0.9, 0.95)   # 青绿协战水晶
	add_child(sprite)


func _physics_process(_delta: float) -> void:
	# E6：生命周期按固定步递减
	_life -= Game.FIXED_DT
	_bob += Game.FIXED_DT
	_hit_cd = maxf(0.0, _hit_cd - Game.FIXED_DT)
	if _life <= 0.0:
		var tw := create_tween()
		tw.tween_property(sprite, "modulate:a", 0.0, 0.4)
		tw.tween_callback(queue_free)
		set_physics_process(false)
		return
	# 消散前 3 秒渐隐提示
	sprite.modulate.a = 0.95 if _life > 3.0 else 0.4 + 0.55 * absf(sin(_life * 4.0))
	sprite.position.y = sin(_bob * 6.0) * 1.5 - 1.0

	var target := _nearest_enemy()
	if target == null:
		velocity = velocity.move_toward(Vector2.ZERO, 200.0 * Game.FIXED_DT)
		move_and_slide()
		return
	var dir := (target.global_position - global_position).normalized()
	velocity = dir * speed
	move_and_slide()
	# 接触伤害（敌人走 take_damage 既有路径）
	if _hit_cd <= 0.0 and global_position.distance_to(target.global_position) < 14.0:
		target.take_damage(CONTACT_DMG, dir, false)
		_hit_cd = 0.6


func _nearest_enemy() -> Node2D:
	var best: Node2D = null
	var best_d := INF
	for e in get_tree().get_nodes_in_group("enemies"):
		if not is_instance_valid(e) or e.dead:
			continue
		var d: float = e.global_position.distance_squared_to(global_position)
		if d < best_d:
			best_d = d
			best = e
	return best
