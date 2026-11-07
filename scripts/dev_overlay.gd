extends CanvasLayer
## F3 调试面板：帧率、种子、当前房间、实体计数、日志尾部。
## 目的：出问题时不用翻日志文件，一屏看到「哪一层哪间房、多少实体、刚报了什么」。

var open := false

var _panel: PanelContainer
var _label: Label
var _acc := 0.0


func _ready() -> void:
	layer = 60
	process_mode = Node.PROCESS_MODE_ALWAYS

	_panel = PanelContainer.new()
	_panel.position = Vector2(10, 118)
	_panel.custom_minimum_size = Vector2(430, 250)
	var sb := StyleBoxFlat.new()
	sb.bg_color = Color(0.06, 0.06, 0.09, 0.9)
	sb.border_color = Color(0.45, 0.38, 0.22)
	sb.set_border_width_all(1)
	sb.set_content_margin_all(8)
	_panel.add_theme_stylebox_override("panel", sb)
	_panel.visible = false
	add_child(_panel)

	_label = Label.new()
	_label.add_theme_font_size_override("font_size", 13)
	_label.add_theme_color_override("font_color", Color(0.82, 0.86, 0.9))
	_panel.add_child(_label)


func _input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and not event.echo and event.keycode == KEY_F3:
		open = not open
		_panel.visible = open
		get_viewport().set_input_as_handled()


func _process(delta: float) -> void:
	if not open:
		return
	_acc += delta
	if _acc < 0.2:
		return
	_acc = 0.0
	_label.text = _build()


func _build() -> String:
	var main: Node = Game.main
	if main == null or not is_instance_valid(main):
		return "Game.main 未就绪"
	var dungeon = main.dungeon
	var coord := "-"
	var kind := "-"
	var state := "-"
	if dungeon != null:
		coord = str(dungeon.current)
		kind = Data.room_name(String(dungeon.room(dungeon.current).get("kind", "?"))) if dungeon.rooms.has(dungeon.current) else "?"
		state = String(main.room_state)
	var lines: Array = [
		"FPS %d   种子 %d   %s" % [Engine.get_frames_per_second(), Game.rng.seed,
			"SMOKE" if main._smoke else "正常"],
		"层 %d   房间 %s (%s)   状态 %s" % [Game.floor_num, coord, kind, state],
		"敌 %d  弹 %d  箱 %d  掉落 %d" % [
			_n(main, "enemies"), _n(main, "bullets"), _n(main, "crates"), _n(main, "pickups")],
		"玩家 HP %d/%d  源石 %d  击杀 %d  得分 %d" % [
			main.player.hp, main.player.max_hp, Game.diamonds, Game.kills, Game.score],
		"日志：错误 %d / 告警 %d" % [Dev.errors, Dev.warnings],
		"-----------------------------",
	]
	for e in Dev.snapshot(7):
		var tag: String = {"0": "·", "1": "!", "2": "×"}[str(e["lvl"])]
		lines.append("%s [%s] %s" % [tag, e["tag"], _clip(String(e["msg"]), 46)])
	return "\n".join(lines)


func _n(main: Node, group: String) -> int:
	return main.get_tree().get_nodes_in_group(group).size()


func _clip(s: String, n: int) -> String:
	return s if s.length() <= n else s.substr(0, n) + "…"
