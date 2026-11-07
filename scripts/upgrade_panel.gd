extends CanvasLayer
const UpgradesClass := preload("res://scripts/upgrades.gd")
## 各卡片的流派标签行
var _tag_rows: Array[HBoxContainer] = []
## 三选一升级面板：暂停游戏，亮出 3 张卡，点击或按 1/2/3 选择。

signal chosen(id: String)

var autopilot := false

var _choices: Array = []
var _cards: Array[PanelContainer] = []
var _icons: Array[TextureRect] = []
var _names: Array[Label] = []
var _descs: Array[Label] = []
var _hints: Array[Label] = []
var _set_hints: Array[Label] = []
var _rarity: Array[Label] = []
var _styles: Array[StyleBoxFlat] = []
var _reroll_label: Label
var _rerolled := false
var _root: Control


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_WHEN_PAUSED
	layer = 20
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
	var hb := HBoxContainer.new()
	hb.add_theme_constant_override("separation", 18)
	vbox.add_child(hb)
	for i in 3:
		var parts := _make_card(i)
		hb.add_child(parts["card"])
		_cards.append(parts["card"])
		_icons.append(parts["icon"])
		_names.append(parts["name"])
		_descs.append(parts["desc"])
		_hints.append(parts["hint"])
		_set_hints.append(parts["set_hint"])
		_rarity.append(parts["rarity"])
		_styles.append(parts["style"])

	_reroll_label = Label.new()
	_reroll_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_reroll_label.add_theme_font_size_override("font_size", 14)
	vbox.add_child(_reroll_label)


func _make_card(index: int) -> Dictionary:
	var card := PanelContainer.new()
	card.custom_minimum_size = Vector2(210, 280)
	var sb := StyleBoxFlat.new()
	sb.bg_color = Color(0.12, 0.11, 0.16, 0.97)
	sb.border_color = Color(0.55, 0.35, 0.2)
	sb.set_border_width_all(2)
	sb.set_corner_radius_all(6)
	sb.set_content_margin_all(12)
	card.add_theme_stylebox_override("panel", sb)

	var vb := VBoxContainer.new()
	vb.add_theme_constant_override("separation", 8)
	vb.alignment = BoxContainer.ALIGNMENT_CENTER
	card.add_child(vb)

	var icon := TextureRect.new()
	icon.custom_minimum_size = Vector2(64, 64)
	icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	icon.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	icon.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	vb.add_child(icon)

	var name_l := Label.new()
	name_l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	name_l.add_theme_font_size_override("font_size", 20)
	name_l.add_theme_color_override("font_color", Color(1.0, 0.8, 0.4))
	vb.add_child(name_l)

	var desc := Label.new()
	desc.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	desc.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	desc.custom_minimum_size = Vector2(180, 0)
	desc.add_theme_font_size_override("font_size", 14)
	vb.add_child(desc)

	var tag_row := HBoxContainer.new()
	tag_row.alignment = BoxContainer.ALIGNMENT_CENTER
	tag_row.add_theme_constant_override("separation", 6)
	vb.add_child(tag_row)

	var set_hint := Label.new()
	set_hint.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	set_hint.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	set_hint.custom_minimum_size = Vector2(180, 0)
	set_hint.add_theme_font_size_override("font_size", 12)
	vb.add_child(set_hint)

	var rarity := Label.new()
	rarity.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	rarity.add_theme_font_size_override("font_size", 12)
	vb.add_child(rarity)

	var hint := Label.new()
	hint.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	hint.add_theme_font_size_override("font_size", 13)
	hint.add_theme_color_override("font_color", Color(0.7, 0.7, 0.75))
	vb.add_child(hint)

	card.gui_input.connect(func(ev: InputEvent) -> void:
		if ev is InputEventMouseButton and ev.pressed and ev.button_index == MOUSE_BUTTON_LEFT:
			_pick(index))
	card.mouse_entered.connect(func() -> void:
		sb.border_color = Color(1.0, 0.75, 0.35))
	card.mouse_exited.connect(func() -> void:
		sb.border_color = UpgradesClass.rarity_color(_choices[index]) if index < _choices.size() \
			else Color(0.55, 0.35, 0.2))
	_tag_rows.append(tag_row)
	# set_hint 由 _ready 的 parts 循环统一 append（此处再 append 会导致 _set_hints
	# 每卡两项、show_choices 填充整体错位一格、第三张卡永远空白——已实测踩坑）
	return {"card": card, "icon": icon, "name": name_l, "desc": desc, "hint": hint,
		"rarity": rarity, "style": sb, "tag": tag_row, "set_hint": set_hint}


func show_choices(choices: Array) -> void:
	if choices.is_empty():
		return
	_choices = choices
	for i in _cards.size():
		var card := _cards[i]
		if i < choices.size():
			card.visible = true
			var up: Dictionary = choices[i]
			_icons[i].texture = _icon_for(up["icon"])
			_names[i].text = up["name"]
			_descs[i].text = up["desc"]
			_fill_tags(_tag_rows[i], up)
			_fill_set_hint(_set_hints[i], up)
			_rarity[i].text = UpgradesClass.rarity_name(up)
			_rarity[i].add_theme_color_override("font_color", UpgradesClass.rarity_color(up))
			_hints[i].text = "按 %d" % (i + 1)
			_styles[i].border_color = UpgradesClass.rarity_color(up)
		else:
			card.visible = false
			_set_hints[i].text = ""
	_rerolled = false
	_root.visible = true
	get_tree().paused = true
	_update_reroll_label()
	if autopilot and OS.get_environment("SMOKE_NO_AUTOPICK") == "":
		Game.safe_delay(0.5, self, true, func() -> void:
			if _root.visible:
				_pick(0))
	_shot_upgrade_panel()


## 套装进度提示：选上这张即达成时点名「再选 1 件集齐」，否则显示还差几件。
## 只读 UpgradesClass 的 tag_counts / sets_active，不改抽取逻辑与 _weight()
func _fill_set_hint(label: Label, up: Dictionary) -> void:
	var tags := UpgradesClass.tags_of(String(up.get("id", "")))
	var best_key := ""
	var best_left := 999
	for t in tags:
		var key := String(t)
		if not UpgradesClass.TAGS.has(key) or bool(UpgradesClass.sets_active.get(key, false)):
			continue
		var need := int(UpgradesClass.TAGS[key]["need"])
		var have := int(UpgradesClass.tag_counts.get(key, 0))
		var left := need - (have + 1)
		if left < best_left:
			best_left = left
			best_key = key
	if best_key == "":
		label.text = ""
		return
	var nm := String(UpgradesClass.TAGS[best_key]["name"])
	if best_left <= 0:
		label.text = "再选 1 件集齐「%s」套装" % nm
		label.add_theme_color_override("font_color", Color(1.0, 0.85, 0.45))
	else:
		label.text = "「%s」套装还差 %d 件" % [nm, best_left + 1]
		label.add_theme_color_override("font_color", Color(0.72, 0.72, 0.78))


## 探针：升级面板打开瞬间截一张图（验证卡片标签徽章）
var _shot_idx := 0   # 每次开面板独立编号，避免后开覆盖先开（A3 需要看第一次 2/3 状态）


func _shot_upgrade_panel() -> void:
	if OS.get_environment("SMOKE_SHOT_UPGRADE") == "":
		return
	await RenderingServer.frame_post_draw
	var img := get_viewport().get_texture().get_image()
	_shot_idx += 1
	img.save_png("D:/Create/Game/_tools/dungeon_shot_upgrade_%d.png" % _shot_idx)
	print("[SMOKE] upgrade panel shot #%d saved" % _shot_idx)


## 卡片上的流派标签徽章（crit 是双标签）
func _fill_tags(row: HBoxContainer, up: Dictionary) -> void:
	for c in row.get_children():
		c.queue_free()
	for t in UpgradesClass.tags_of(String(up.get("id", ""))):
		var l := Label.new()
		l.text = "【%s】" % String(UpgradesClass.TAGS[t]["name"])
		l.add_theme_font_size_override("font_size", 12)
		l.add_theme_color_override("font_color", UpgradesClass.TAGS[t]["color"])
		l.add_theme_color_override("font_outline_color", Color(0.1, 0.06, 0.08))
		l.add_theme_constant_override("outline_size", 4)
		row.add_child(l)


func _icon_for(key: String) -> Texture2D:
	if key == "drone":
		return Assets.at(Assets.T_TURRET, Assets.TURRET_FRAME_A)
	return Assets.xicon(key)


func _unhandled_input(event: InputEvent) -> void:
	if not _root.visible:
		return
	for i in 3:
		if event.is_action_pressed("card_%d" % (i + 1)) and i < _choices.size():
			get_viewport().set_input_as_handled()
			_pick(i)
			return
	if event.is_action_pressed("reload"):
		get_viewport().set_input_as_handled()
		_try_reroll()


const REROLL_COST := 15


func _try_reroll() -> void:
	if _rerolled or _choices.is_empty():
		return
	if not Game.spend(REROLL_COST):
		_reroll_label.text = "源石不足（需要 %d）" % REROLL_COST
		return
	_rerolled = true
	show_choices(UpgradesClass.roll(3))
	_update_reroll_label()


func _update_reroll_label() -> void:
	if _reroll_label == null:
		return
	_reroll_label.text = "已刷新" if _rerolled else "按 R 刷新（%d 源石，每次升级一次）" % REROLL_COST
	_reroll_label.add_theme_color_override("font_color",
		Color(0.6, 0.6, 0.65) if _rerolled else Color(1.0, 0.85, 0.45))


func _pick(index: int) -> void:
	if _choices.is_empty() or index >= _choices.size():
		return
	var id: String = _choices[index]["id"]
	_choices = []
	_root.visible = false
	chosen.emit(id)
	get_tree().paused = false
