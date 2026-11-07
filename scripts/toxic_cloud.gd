extends Node2D
## 毒雾双模：enemy = 毒囊虫/毒花死亡后的小范围伤害区（伤害玩家）；
## friendly = F2 主动遗物「毒云冻结弹」（对敌人减速 + 微量 DoT）。

var radius := 42.0
var life := 5.0
var tick := 0.8
var side := "enemy"      # enemy / friendly
var slow_mult := 0.5     # friendly：区域内敌人减速系数
var dot_dmg := 0.5       # friendly：每次 tick 对敌人伤害
var puff_tint := Color(0.62, 0.95, 0.45, 0.55)  # 云色（敌方默认绿；Boss 按主题 tint / 词缀青绿）
var triggerless := false # 词缀生成的云不再触发 ON_POISON_TICK（防连锁）
var fixed_step := false  # E6：Boss 脉冲等新来源置 true（计时走 FIXED_DT）；grandfather 敌云维持 delta

var _t := 0.0
var _tick_t := 0.0
var _puffs: Array[Sprite2D] = []


## 友方毒云（主动遗物 toxic_freeze / 词缀 theme_hazard 专用入口）
func setup_friendly(radius_v: float, life_v: float, slow_v: float, dot_v: float,
		tint_v := Color(0.45, 0.9, 0.95, 0.5), triggerless_v := false) -> void:
	radius = radius_v
	life = life_v
	tick = 0.5
	slow_mult = slow_v
	dot_dmg = dot_v
	puff_tint = tint_v
	triggerless = triggerless_v
	side = "friendly"


func _ready() -> void:
	z_index = 5
	_tick_t = tick
	for i in 5:
		var s := Sprite2D.new()
		s.texture = Assets.at(Assets.T_BOOM, Rect2(Assets.BOOM_FRAME * 4, 0, Assets.BOOM_FRAME, Assets.BOOM_FRAME))
		s.scale = Vector2(0.28, 0.28) * (0.8 + i * 0.12)
		s.modulate = puff_tint
		s.position = Vector2.from_angle(TAU * i / 5.0) * 10.0
		add_child(s)
		_puffs.append(s)


func _process(delta: float) -> void:
	# E6：friendly 云与 fixed_step 云（Boss 脉冲等新来源）走固定步；
	# grandfather 敌云维持 raw delta（Sprint 10 裁定，行为冻结）
	var step := Game.FIXED_DT if (side == "friendly" or fixed_step) else delta
	_t += step
	_tick_t -= step
	for i in _puffs.size():
		var s := _puffs[i]
		s.position = Vector2.from_angle(TAU * i / 5.0 + _t * 0.9) * (10.0 + sin(_t * 3.0 + i) * 3.0)
		s.modulate.a = 0.55 * clampf(1.0 - _t / life, 0.0, 1.0)
	if _tick_t <= 0.0:
		_tick_t = tick
		if side == "enemy":
			_tick_enemy()
		else:
			_tick_friendly()
			if OS.get_environment("SMOKE") != "":
				print("[SMOKE] friendly cloud tick t=%.2f/%.2f" % [_t, life])
	if _t >= life:
		queue_free()


func _tick_enemy() -> void:
	var p: Node2D = Game.main.player
	if is_instance_valid(p) and not p.dead and p.global_position.distance_to(global_position) < radius:
		p.take_damage(1, global_position)


func _tick_friendly() -> void:
	for a in get_tree().get_nodes_in_group("enemies"):
		if not is_instance_valid(a) or a.dead:
			continue
		if a.global_position.distance_to(global_position) > radius:
			continue
		a.apply_slow(slow_mult, tick + 0.2)
		a.hp -= dot_dmg
		Game.damage_number(a.global_position, dot_dmg, false)
		if a.hp <= 0.0:
			a._die()
	# F2/A 反应词缀：毒云每跳是 ON_POISON_TICK 触发点（词缀云自身不再触发，防连锁）
	if not triggerless and Game.main and is_instance_valid(Game.main.player) and not Game.main.player.dead:
		Game.main.player._fire_relic_suffixes("toxic_freeze", "ON_POISON_TICK", global_position)
