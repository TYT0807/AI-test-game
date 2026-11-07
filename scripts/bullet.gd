class_name Bullet
extends Area2D
## 双向子弹：friendly=true 打虫，false 打玩家。
## 支持武器参数：射程(life)、爆炸弹(explosive)、弹墙(bounce)、冰冻(frost)。
## SPR7 局外解锁武器行为：追踪(homing)、电弧(arc)、集束分裂(cluster)。

const ExplosionScript := preload("res://scripts/explosion.gd")

var vel := Vector2.ZERO
var dmg := 1.0
var friendly := true
var pierce := 0
var explosive := 0.0
var bounce := 0
var frost := 0.0
var crit := false          # 这一发是否暴击（致命共振 mx_critboom 用）
var crit_boom := false     # 玩家是否持有「致命共振」→ 暴击时在命中点引爆
var homing := false         # 蜂群导弹 mw_swarm：自动追踪最近敌人
var arc := 0               # 电弧发射器 mw_arc：命中后连锁跳数
var cluster := 0           # 集束榴弹 mw_cluster：爆炸时分裂的小弹数
var _life := 1.4
var _prev_pos := Vector2.ZERO


func setup(pos: Vector2, dir: Vector2, speed: float, dmg_v: float, friendly_v: bool,
		tint: Color, scale_f: float, pierce_v: int, explosive_v := 0.0, life_v := 1.4,
		bounce_v := 0, frost_v := 0.0, crit_v := false, crit_boom_v := false,
		homing_v := false, arc_v := 0, cluster_v := 0) -> void:
	position = pos
	_prev_pos = pos
	vel = dir * speed
	dmg = dmg_v
	friendly = friendly_v
	pierce = pierce_v
	explosive = explosive_v
	bounce = bounce_v
	frost = frost_v
	crit = crit_v
	crit_boom = crit_boom_v
	homing = homing_v
	arc = arc_v
	cluster = cluster_v
	rotation = dir.angle()
	_life = life_v if life_v > 0.0 else 1.4


func _ready() -> void:
	if friendly:
		collision_layer = 8
		collision_mask = 1 | 4 | 64
	else:
		collision_layer = 16
		collision_mask = 1 | 2
		add_to_group("enemy_bullets")  # 环绕护盾（主动遗物）的摧毁目标
	monitoring = true

	var shape := CollisionShape2D.new()
	var circle := CircleShape2D.new()
	circle.radius = 3.0
	shape.shape = circle
	add_child(shape)

	var s := Sprite2D.new()
	s.texture = Assets.at(Assets.T_TURRET, Assets.TURRET_SHOT_RECT)
	s.scale = Vector2.ONE * 0.9
	add_child(s)
	body_entered.connect(_on_body_entered)


func _physics_process(delta: float) -> void:
	_prev_pos = position
	# 蜂群导弹（mw_swarm）：朝最近的敌人缓慢转向
	if homing and friendly:
		var t := _nearest_enemy()
		if t != null:
			var want := (t.global_position - position).normalized()
			vel = vel.lerp(want * vel.length(), clampf(delta * 6.0, 0.0, 1.0))
			rotation = vel.angle()
	position += vel * delta
	_life -= delta
	if _life <= 0.0:
		queue_free()


func _on_body_entered(body: Node) -> void:
	_handle_hit.call_deferred(body)


func _handle_hit(body: Node) -> void:
	if not is_inside_tree():
		return
	# 弹墙（遗物弹射弹壳）：用射线取法线反射
	if body is TileMapLayer and bounce > 0 and friendly:
		var space := get_world_2d().direct_space_state
		var q := PhysicsRayQueryParameters2D.create(_prev_pos, position)
		q.collision_mask = 1
		var hit := space.intersect_ray(q)
		var n := Vector2.UP
		if hit.has("normal"):
			n = hit["normal"]
		vel = vel.bounce(n)
		position = _prev_pos
		bounce -= 1
		return
	if friendly:
		if body.is_in_group("enemies"):
			body.take_damage(dmg, vel.normalized(), false)
			if is_instance_valid(Game.main.player):
				var pl = Game.main.player
				if pl.chain_chance > 0.0 and Game.rng.randf() < pl.chain_chance:
					_chain(global_position, dmg * 0.45, body)
				if pl.poison_chance > 0.0 and Game.rng.randf() < pl.poison_chance and body.has_method("apply_poison"):
					body.apply_poison(2.0, 3.0)
				# 火力套装：命中处小范围溅射
				if pl.set_fire:
					_splash(global_position, dmg * 0.35)
			# 致命共振（mx_critboom）：暴击时在命中点引爆，爆炸 = 子弹伤害 60%
			if crit and crit_boom:
				Game.main.explode(global_position, 42.0, dmg * 0.6, false)
			# 电弧发射器（mw_arc）：命中时向附近敌人放电，连锁 3 次、每跳衰减 30%
			if arc > 0:
				_arc_chain(global_position, dmg, body, arc)
			if frost > 0.0 and Game.rng.randf() < frost:
				body.apply_slow(0.6, 2.0)
			if explosive > 0.0:
				# 集束榴弹（mw_cluster）：爆炸前分裂出 3 枚小弹
				if cluster > 0:
					_split_cluster(dmg)
				Game.main.explode(global_position, 34.0 + 10.0 * explosive, dmg * 0.8, false)
				queue_free()
				return
			if pierce > 0:
				pierce -= 1
				return
		elif body.is_in_group("crates"):
			body.crate_take_damage(dmg)
			if explosive > 0.0:
				if cluster > 0:
					_split_cluster(dmg)
				Game.main.explode(global_position, 34.0 + 10.0 * explosive, dmg * 0.8, false)
	else:
		if body.is_in_group("player"):
			body.take_damage(int(dmg), global_position - vel.normalized() * 4.0)
	_impact()


## 最近的活着的敌人（追踪用）
func _nearest_enemy() -> Node2D:
	var best: Node2D = null
	var best_d := 260.0
	for e in get_tree().get_nodes_in_group("enemies"):
		if not is_instance_valid(e) or e.dead:
			continue
		var d: float = e.global_position.distance_to(global_position)
		if d < best_d:
			best_d = d
			best = e
	return best


## 火力套装：命中处小范围溅射
func _splash(from: Vector2, dmg_v: float) -> void:
	for e in get_tree().get_nodes_in_group("enemies"):
		if not is_instance_valid(e) or e.dead:
			continue
		if e.global_position.distance_to(from) > 44.0:
			continue
		e.take_damage(dmg_v, (e.global_position - from).normalized(), false)


## 连锁闪电：命中后找最近的另一个敌人补一段伤害
func _chain(from: Vector2, dmg_v: float, exclude: Node) -> void:
	var best: Node2D = null
	var best_d := 130.0
	for e in get_tree().get_nodes_in_group("enemies"):
		if e == exclude or not is_instance_valid(e) or e.dead:
			continue
		var d: float = e.global_position.distance_to(from)
		if d < best_d:
			best_d = d
			best = e
	if best == null:
		return
	best.take_damage(dmg_v, (best.global_position - from).normalized(), false)
	var ex := ExplosionScript.new()
	ex.setup("spark", 0.5, false)
	ex.position = best.global_position
	ex.modulate = Color(0.6, 0.95, 1.0)
	get_parent().add_child(ex)


## 电弧发射器（mw_arc）：命中后向附近敌人放电，连锁 jumps 次、每跳衰减 30%
func _arc_chain(from: Vector2, dmg_v: float, exclude: Node, jumps: int) -> void:
	var cur := from
	var src := exclude
	var d := dmg_v
	for _j in jumps:
		var best: Node2D = null
		var best_d := 150.0
		for e in get_tree().get_nodes_in_group("enemies"):
			if e == src or not is_instance_valid(e) or e.dead:
				continue
			var dd: float = e.global_position.distance_to(cur)
			if dd < best_d:
				best_d = dd
				best = e
		if best == null:
			return
		best.take_damage(d, (best.global_position - cur).normalized(), false)
		var ex := ExplosionScript.new()
		ex.setup("spark", 0.5, false)
		ex.position = best.global_position
		ex.modulate = Color(0.5, 0.8, 1.0)
		get_parent().add_child(ex)
		cur = best.global_position
		src = best
		d *= 0.7


## 集束榴弹（mw_cluster）：命中爆炸后分裂出 3 枚小弹（伤害 40%、速度 220）
func _split_cluster(dmg_v: float) -> void:
	for i in 3:
		var ang := TAU * float(i) / 3.0 + Game.rng.randf() * 0.4
		var b := Bullet.new()
		b.setup(global_position, Vector2.from_angle(ang), 220.0, dmg_v * 0.4, true,
			Color(1.0, 0.75, 0.35), 0.7, 0, 0.0, 0.5, 0, 0.0)
		get_parent().add_child(b)


func _impact() -> void:
	var ex := ExplosionScript.new()
	ex.setup("spark", 0.35, vel.x < 0.0)
	ex.position = global_position
	ex.z_index = 45
	get_parent().add_child(ex)
	queue_free()
