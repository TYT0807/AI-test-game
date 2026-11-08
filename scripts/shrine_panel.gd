extends CanvasLayer
## Sprint 13 A 抉择圣所：三选一状态交换面板（薄面板——规划 §4.4 退路：
## upgrade_panel 的 tags/rarity/reroll/鼠标闭包深耦合 UpgradesClass（mouse_exit 闭包
## 对无 rarity 字典会直接报错），故独立薄面板；键位门控复用已注册的 card_1/2/3
## （坑 5：不新增 ACTION_DEFS 条目），卡片渲染骨架参照 upgrade_panel.gd。

signal chosen(index: int)

var autopilot := false

var _offers: Array = []
var _ok: Array[bool] = []
var _cards: Array[PanelContainer] = []
var _names: Array[Label] = []
var _descs: Array[Label] = []
var _costs: Array[Label] = []
var _hints: Array[Label] = []
var _flavors: Array[Label] = []   # Sprint 18 阶段二 D：三卡灰字（Data.FLAVOR["shrine/<id>"] 直查，纯只读）
var _root: Control


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_WHEN_PAUSED
	layer = 21   # 高于升级面板（20）：圣所选「源石淬炼」时先关本面板再弹升级面板
	_root = Control.new()
	_root.set_anchors_preset(Control.PRESET_FULL_RECT)
	_root.theme = Assets.theme()
	_root.visible = false
	add_child(_root)

	var shade := ColorRect.new()
	shade.color = Color(0, 0, 0, 0.55)
	shade.set_anchors_preset(Control.PRESET_FULL_RECT)
	_root.add_child(shade)

	var cc := CenterContainer.new()
	cc.set_anchors_preset(Control.PRESET_FULL_RECT)
	_root.add_child(cc)
	var vbox := VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 10)
	cc.add_child(vbox)
	var title := Label.new()
	title.text = "—— 抉择圣所 · 三选其一 ——"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override("font_size", 22)
	title.add_theme_color_override("font_color", Color(0.62, 0.9, 1.0))
	vbox.add_child(title)
	var hb := HBoxContainer.new()
	hb.add_theme_constant_override("separation", 18)
	vbox.add_child(hb)
	for i in 3:
		var parts := _make_card(i)
		hb.add_child(parts["card"])
		_cards.append(parts["card"])
		_names.append(parts["name"])
		_descs.append(parts["desc"])
		_costs.append(parts["cost"])
		_hints.append(parts["hint"])
		_flavors.append(parts["flavor"])
	for i in 3:
		_ok.append(false)


func _make_card(index: int) -> Dictionary:
	var card := PanelContainer.new()
	card.custom_minimum_size = Vector2(220, 220)
	var sb := StyleBoxFlat.new()
	sb.bg_color = Color(0.1, 0.12, 0.17, 0.97)
	sb.border_color = Color(0.35, 0.6, 0.75)
	sb.set_border_width_all(2)
	sb.set_corner_radius_all(6)
	sb.set_content_margin_all(14)
	card.add_theme_stylebox_override("panel", sb)

	var vb := VBoxContainer.new()
	vb.add_theme_constant_override("separation", 10)
	vb.alignment = BoxContainer.ALIGNMENT_CENTER
	card.add_child(vb)

	var name_l := Label.new()
	name_l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	name_l.add_theme_font_size_override("font_size", 20)
	name_l.add_theme_color_override("font_color", Color(0.75, 0.92, 1.0))
	vb.add_child(name_l)

	var desc := Label.new()
	desc.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	desc.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	desc.custom_minimum_size = Vector2(190, 0)
	desc.add_theme_font_size_override("font_size", 14)
	vb.add_child(desc)

	var cost := Label.new()
	cost.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	cost.add_theme_font_size_override("font_size", 15)
	cost.add_theme_color_override("font_color", Color(1.0, 0.85, 0.45))
	vb.add_child(cost)

	# Sprint 18 阶段二 D：熟客呼应灰字（比 desc 小两档，暗灰，恒显但查不到即隐藏）
	var flavor := Label.new()
	flavor.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	flavor.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	flavor.custom_minimum_size = Vector2(190, 0)
	flavor.add_theme_font_size_override("font_size", 11)
	flavor.add_theme_color_override("font_color", Color(0.62, 0.64, 0.70))
	flavor.visible = false
	vb.add_child(flavor)

	var hint := Label.new()
	hint.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	hint.add_theme_font_size_override("font_size", 13)
	hint.add_theme_color_override("font_color", Color(0.7, 0.7, 0.75))
	vb.add_child(hint)

	card.gui_input.connect(func(ev: InputEvent) -> void:
		if ev is InputEventMouseButton and ev.pressed and ev.button_index == MOUSE_BUTTON_LEFT:
			_pick(index))
	return {"card": card, "name": name_l, "desc": desc, "cost": cost, "hint": hint, "flavor": flavor}


func open(offers: Array) -> void:
	if offers.is_empty():
		return
	_offers = offers
	var can_afford: Array = []
	for o in offers:
		var ok := true
		if Game.main != null and is_instance_valid(Game.main):
			ok = Game.main._shrine_affordable(o)
		can_afford.append(ok)
	for i in _cards.size():
		if i < offers.size():
			var o: Dictionary = offers[i]
			_cards[i].visible = true
			_names[i].text = String(o["name"])
			_descs[i].text = String(o["desc"])
			_costs[i].text = _cost_text(o)
			# D：灰字直查 FLAVOR["shrine/<id>"]；查不到 → 空文本 + 隐藏（不改卡的任何可用性）
			var fv := String(Data.FLAVOR.get("shrine/" + String(o.get("id", "")), ""))
			_flavors[i].text = fv
			_flavors[i].visible = fv != ""
			_set_state(i, i < can_afford.size() and bool(can_afford[i]))
		else:
			_cards[i].visible = false
			_flavors[i].visible = false
	_root.visible = true
	get_tree().paused = true
	# SMOKE 自动驾驶：选第一张可支付的卡（升级面板同范式；SMOKE_NO_AUTOPICK 可关闭）
	if autopilot and OS.get_environment("SMOKE_NO_AUTOPICK") == "":
		Game.safe_delay(0.5, self, true, func() -> void:
			if _root.visible:
				for i in _ok.size():
					if i < _offers.size() and _ok[i]:
						_pick(i)
						return)


func _cost_text(o: Dictionary) -> String:
	match String(o.get("cost_kind", "")):
		"diamonds":
			return "代价：源石 -%d" % int(o["cost"])
		"max_hp":
			return "代价：生命上限 -%d" % int(o["cost"])
		"score":
			return "代价：积分 -%d" % int(o["cost"])
	return "代价：×1.5 加成或失效"


## 置灰：代价不足的卡不可选（主侧 _on_shrine_chosen 再校验，双保险）
func _set_state(i: int, ok: bool) -> void:
	_ok[i] = ok
	_cards[i].modulate = Color(1, 1, 1, 1) if ok else Color(0.45, 0.45, 0.45, 0.75)
	_costs[i].add_theme_color_override("font_color",
		Color(1.0, 0.85, 0.45) if ok else Color(0.95, 0.45, 0.45))
	_hints[i].text = "按 %d / 点击" % (i + 1) if ok else "代价不足，不可选"


func _unhandled_input(event: InputEvent) -> void:
	if not _root.visible:
		return
	for i in 3:
		if event.is_action_pressed("card_%d" % (i + 1)) and i < _offers.size():
			get_viewport().set_input_as_handled()
			_pick(i)
			return


func _pick(i: int) -> void:
	if _offers.is_empty() or i >= _offers.size() or not _ok[i]:
		return
	_offers = []
	_root.visible = false
	# 核验 #2：先解除自身暂停再 emit——ore_upgrade 链会在 emit 内打开升级面板
	# （paused=true），emit 之后再解暂停会把它覆盖成 false，游戏在面板底下继续跑
	get_tree().paused = false
	chosen.emit(i)
