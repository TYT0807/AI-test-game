extends CanvasLayer
## 升级池（流派标签 / 套装数据）
const Upgrades := preload("res://scripts/upgrades.gd")
const Meta := preload("res://scripts/meta.gd")
## HUD：状态面板、波次横幅、Boss 血条、连杀、暂停/结算覆盖层。
## process_mode = ALWAYS：暂停与死亡时仍接收输入（Esc / R）。

## 状态图标一律走 Assets.xicon(key)（坑 7）；新增状态只追加这里，禁止直接查表
const STATUS_DEFS := [
	{"key": "guard", "name": "护盾"},
	{"key": "chain", "name": "连锁"},
	{"key": "venom", "name": "淬毒"},
]

var _hp_bar: ProgressBar
var _hp_label: Label
var _xp_bar: ProgressBar
var _bomb_label: Label
var _diamond_label: Label
var _score_label: Label
var _time_label: Label
var _kills_label: Label
var _wave_label: Label
var _banner: Label
var _banner_tw: Tween
var _combo: Label
var _boss_box: VBoxContainer
var _boss_bar: ProgressBar
var _gameover_box: VBoxContainer
var _gameover_holder: Control
var _pause_holder: Control
var _stats_label: Label
var _crystal_label: Label
var _balance_label: Label
var _unlock_label: Label
var _crystal_tw: Tween
var _pause_box: VBoxContainer
var _game_over := false
var _paused := false

# 肉鸽扩展
var _minimap: Control
var _slot_icons: Array[TextureRect] = []
var _slot_panels: Array[PanelContainer] = []
var _skill_bar: ProgressBar
var _skill_label: Label
var _toast: Label
var _toast_tw: Tween
var _hint_label: Label
var _suffix_label: Label   # F2/A 反应词缀行（附着后显示）
var _tag_sig := ""   # 流派计数签名：apply 调用点分散，_process 里变化检测统一刷新
var _status_panel: PanelContainer
var _status_boxes: Array[HBoxContainer] = []
var _status_labels: Array[Label] = []
var _modifier_label: Label
var _modifier_icon: TextureRect
var _resonance_label: Label
var _tag_labels := {}
var _theme_label: Label
var _minimap_panel: PanelContainer
var _meta_panel: PanelContainer
var _compact := false


## Sprint 13 E：HUD 字号档（设置页 ui_font：0=小 0.85 / 1=标准 1.0 / 2=大 1.2）。
## HUD 每局构建时读取一次（菜单改档 → 下局生效）；全部字号经 _fs 折算，最小 9px 兜底
var _font_scale := 1.0


func _fs(n: int) -> int:
	return maxi(9, int(round(n * _font_scale)))


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	layer = 10
	_font_scale = [0.85, 1.0, 1.2][clampi(int(Game.settings.get("ui_font", 1)), 0, 2)]
	var root := Control.new()
	root.set_anchors_preset(Control.PRESET_FULL_RECT)
	root.mouse_filter = Control.MOUSE_FILTER_IGNORE
	root.theme = Assets.theme()
	add_child(root)

	# ---- 左上：头像 + 血条 + 资源 ----
	var panel := PanelContainer.new()
	panel.position = Vector2(12, 12)
	_style_panel(panel)
	root.add_child(panel)
	var hb := HBoxContainer.new()
	hb.add_theme_constant_override("separation", 10)
	panel.add_child(hb)
	var face := TextureRect.new()
	face.texture = Assets.icon("face")
	face.custom_minimum_size = Vector2(44, 44)
	face.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	face.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	hb.add_child(face)
	var vb := VBoxContainer.new()
	vb.add_theme_constant_override("separation", 3)
	hb.add_child(vb)

	_hp_bar = ProgressBar.new()
	_hp_bar.custom_minimum_size = Vector2(170, 14)
	_hp_bar.show_percentage = false
	_style_bar(_hp_bar, Color("6ab04c"))
	vb.add_child(_hp_bar)
	_xp_bar = ProgressBar.new()
	_xp_bar.custom_minimum_size = Vector2(170, 6)
	_xp_bar.show_percentage = false
	_style_bar(_xp_bar, Color("4c9db0"))
	vb.add_child(_xp_bar)
	_hp_label = Label.new()
	_hp_label.add_theme_font_size_override("font_size", _fs(12))
	vb.add_child(_hp_label)

	var res_row := HBoxContainer.new()
	res_row.add_theme_constant_override("separation", 6)
	hb.add_child(res_row)
	_icon_label(res_row, "bomb")
	_bomb_label = Label.new()
	res_row.add_child(_bomb_label)
	_icon_label(res_row, "diamond")
	_diamond_label = Label.new()
	res_row.add_child(_diamond_label)
	_score_label = Label.new()
	_score_label.add_theme_font_size_override("font_size", _fs(14))
	res_row.add_child(_score_label)

	# ---- 右上：时间/击杀/波次 ----
	var tr := VBoxContainer.new()
	tr.set_anchors_preset(Control.PRESET_TOP_RIGHT)
	tr.grow_horizontal = Control.GROW_DIRECTION_BEGIN
	tr.offset_right = -14.0
	tr.offset_top = 10.0
	tr.offset_left = -190.0
	tr.add_theme_constant_override("separation", 2)
	root.add_child(tr)
	_time_label = _right_label(tr, 20)
	_kills_label = _right_label(tr, 14)
	_wave_label = _right_label(tr, 14)

	# ---- 顶部中央：横幅 + Boss 条 ----
	_banner = Label.new()
	_banner.set_anchors_preset(Control.PRESET_CENTER_TOP)
	_banner.grow_horizontal = Control.GROW_DIRECTION_BOTH
	_banner.offset_top = 64.0
	_banner.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_banner.add_theme_font_size_override("font_size", _fs(30))
	_banner.add_theme_color_override("font_outline_color", Color(0.1, 0.06, 0.08))
	_banner.add_theme_constant_override("outline_size", 8)
	_banner.modulate.a = 0.0
	root.add_child(_banner)

	_boss_box = VBoxContainer.new()
	_boss_box.set_anchors_preset(Control.PRESET_CENTER_TOP)
	_boss_box.grow_horizontal = Control.GROW_DIRECTION_BOTH
	_boss_box.offset_top = 14.0
	_boss_box.offset_left = -170.0
	_boss_box.offset_right = 170.0
	_boss_box.visible = false
	root.add_child(_boss_box)
	var boss_name := Label.new()
	boss_name.text = "巨岩虫之王"
	boss_name.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	boss_name.add_theme_font_size_override("font_size", _fs(13))
	_boss_box.add_child(boss_name)
	_boss_bar = ProgressBar.new()
	_boss_bar.custom_minimum_size = Vector2(0, 10)
	_boss_bar.show_percentage = false
	_style_bar(_boss_bar, Color("d64541"))
	_boss_box.add_child(_boss_bar)

	# ---- 连杀 ----
	_combo = Label.new()
	_combo.set_anchors_preset(Control.PRESET_CENTER_RIGHT)
	_combo.grow_horizontal = Control.GROW_DIRECTION_BEGIN
	_combo.offset_right = -36.0
	_combo.offset_top = 200.0
	_combo.add_theme_font_size_override("font_size", _fs(22))
	_combo.add_theme_color_override("font_color", Color(1.0, 0.7, 0.3))
	_combo.add_theme_color_override("font_outline_color", Color(0.1, 0.06, 0.08))
	_combo.add_theme_constant_override("outline_size", 6)
	_combo.modulate.a = 0.0
	root.add_child(_combo)

	# ---- 底部提示（按键重绑自适应：文本从当前 InputMap 动态生成）----
	_hint_label = Label.new()
	_hint_label.text = _build_hint_text()
	_hint_label.set_anchors_preset(Control.PRESET_CENTER_BOTTOM)
	_hint_label.grow_horizontal = Control.GROW_DIRECTION_BOTH
	_hint_label.grow_vertical = Control.GROW_DIRECTION_BEGIN
	_hint_label.offset_bottom = -12.0
	_hint_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_hint_label.add_theme_font_size_override("font_size", _fs(14))
	_hint_label.add_theme_color_override("font_outline_color", Color(0.1, 0.06, 0.08))
	_hint_label.add_theme_constant_override("outline_size", 5)
	root.add_child(_hint_label)
	var hint_tw := _hint_label.create_tween()
	hint_tw.tween_interval(9.0)
	hint_tw.tween_property(_hint_label, "modulate:a", 0.0, 1.2)
	Game.bindings_changed.connect(func() -> void: _hint_label.text = _build_hint_text())

	# 全部 HUD（小地图/技能条/武器槽/toast/状态条）先于覆盖层挂到 root：
	# 结算/暂停遮罩绘制在其上，不会穿透露出
	_build_dungeon_ui(root)
	_build_status_ui(root)
	_build_meta_ui(root)

	# ---- 覆盖层：结算 / 暂停 ----
	var go := _overlay(root, "你倒下了", Color(0.9, 0.25, 0.2))
	_gameover_holder = go["holder"]
	_gameover_box = go["box"]
	_stats_label = Label.new()
	_stats_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_stats_label.add_theme_font_size_override("font_size", _fs(18))
	_gameover_box.add_child(_stats_label)
	# G9 结算 5 行：结晶行是唯一高亮，累计 / 解锁物行灰色
	_crystal_label = Label.new()
	_crystal_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_crystal_label.add_theme_font_size_override("font_size", _fs(20))
	_crystal_label.add_theme_color_override("font_color", Color(1.0, 0.82, 0.42))
	_gameover_box.add_child(_crystal_label)
	_balance_label = Label.new()
	_balance_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_balance_label.add_theme_font_size_override("font_size", _fs(16))
	_balance_label.add_theme_color_override("font_color", Color(0.72, 0.72, 0.78))
	_gameover_box.add_child(_balance_label)
	_unlock_label = Label.new()
	_unlock_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_unlock_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_unlock_label.custom_minimum_size = Vector2(420, 0)
	_unlock_label.add_theme_font_size_override("font_size", _fs(16))
	_unlock_label.add_theme_color_override("font_color", Color(0.72, 0.72, 0.78))
	_gameover_box.add_child(_unlock_label)
	var retry := Label.new()
	retry.text = "按 R 重新开始"
	retry.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	retry.add_theme_font_size_override("font_size", _fs(16))
	_gameover_box.add_child(retry)
	var blink := retry.create_tween()
	blink.set_loops()
	blink.tween_property(retry, "modulate:a", 0.25, 0.55)
	blink.tween_property(retry, "modulate:a", 1.0, 0.55)
	# 结算屏出口：回主菜单（局外解锁页在主菜单里）
	var to_menu := Button.new()
	to_menu.text = "返回主菜单"
	to_menu.custom_minimum_size = Vector2(160, 36)
	to_menu.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	to_menu.add_theme_font_size_override("font_size", _fs(16))
	to_menu.pressed.connect(func() -> void:
		if Game.main != null and is_instance_valid(Game.main):
			Game.main.to_main_menu())
	_gameover_box.add_child(to_menu)

	var ps := _overlay(root, "已暂停", Color(0.9, 0.8, 0.5))
	_pause_holder = ps["holder"]
	_pause_box = ps["box"]
	var p2 := Label.new()
	p2.text = "Esc 继续"
	p2.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	p2.add_theme_font_size_override("font_size", _fs(16))
	_pause_box.add_child(p2)

	# ---- 信号 ----
	Game.player_hp_changed.connect(func(hp: int, max_hp: int) -> void:
		_hp_bar.max_value = max_hp
		_hp_bar.value = hp
		_hp_label.text = "生命 %d/%d" % [hp, max_hp])
	Game.bombs_changed.connect(func(n: int, _cap: int) -> void:
		_bomb_label.text = "×%d" % n)
	Game.score_changed.connect(func(_s: int) -> void: _refresh_counters())
	Game.combo_pop.connect(_on_combo_pop)
	Game.xp_changed.connect(func(xp: int, need: int, _lv: int) -> void:
		_xp_bar.max_value = need
		_xp_bar.value = xp)
	Game.wave_changed.connect(func(_n: int, _kind: String) -> void:
		# 层数标签由 set_room_info 维护，这里只刷新计数，避免清房后被"第 N 波"覆盖
		_refresh_counters())
	Game.boss_hp_changed.connect(func(hp: float, max_hp: float) -> void:
		_boss_box.visible = hp > 0.0
		_boss_bar.max_value = max_hp
		_boss_bar.value = hp)
	_hp_label.text = "生命 3/3"
	_hp_bar.max_value = 3
	_hp_bar.value = 3
	_xp_bar.max_value = 5
	_xp_bar.value = 0
	_bomb_label.text = "×2"
	_diamond_label.text = "0"
	_score_label.text = "得分 0"
	_time_label.text = "00:00"
	_kills_label.text = "击杀 0"
	_wave_label.text = "第 1 层"

	# ---- 扩展信号 ----
	Game.diamonds_changed.connect(func(n: int) -> void:
		_diamond_label.text = str(n))
	Game.toast.connect(func(text: String) -> void: flash_toast(text))
	Game.main.player.weapon_changed.connect(_on_weapon_changed)
	_on_weapon_changed(Game.main.player.weapon_slots, Game.main.player.slot)


func _build_dungeon_ui(root: Control) -> void:
	# ---- 小地图（右上，时间块下方）----
	var map_panel := PanelContainer.new()
	_minimap_panel = map_panel
	map_panel.set_anchors_preset(Control.PRESET_TOP_RIGHT)
	map_panel.grow_horizontal = Control.GROW_DIRECTION_BEGIN
	map_panel.offset_right = -14.0
	map_panel.offset_top = 92.0
	_style_panel(map_panel)
	root.add_child(map_panel)
	_minimap = Control.new()
	_minimap.custom_minimum_size = Vector2(130, 96)
	_minimap.mouse_filter = Control.MOUSE_FILTER_IGNORE
	map_panel.add_child(_minimap)

	# ---- 技能冷却 + 武器槽（左下）----
	var bl := VBoxContainer.new()
	bl.set_anchors_preset(Control.PRESET_BOTTOM_LEFT)
	bl.grow_vertical = Control.GROW_DIRECTION_BEGIN
	bl.offset_left = 12.0
	bl.offset_bottom = -44.0
	bl.add_theme_constant_override("separation", 5)
	root.add_child(bl)

	var skill_row := HBoxContainer.new()
	skill_row.add_theme_constant_override("separation", 6)
	bl.add_child(skill_row)
	_skill_label = Label.new()
	_skill_label.text = "空格·过载"
	_skill_label.add_theme_font_size_override("font_size", _fs(12))
	_skill_label.add_theme_color_override("font_outline_color", Color(0.1, 0.06, 0.08))
	_skill_label.add_theme_constant_override("outline_size", 4)
	skill_row.add_child(_skill_label)
	_skill_bar = ProgressBar.new()
	_skill_bar.custom_minimum_size = Vector2(110, 8)
	_skill_bar.show_percentage = false
	_skill_bar.max_value = 1.0
	_skill_bar.value = 1.0
	_style_bar(_skill_bar, Color("e6a23c"))
	skill_row.add_child(_skill_bar)

	var slots_row := HBoxContainer.new()
	slots_row.add_theme_constant_override("separation", 6)
	bl.add_child(slots_row)
	for i in 2:
		var p := PanelContainer.new()
		var sb := StyleBoxFlat.new()
		sb.bg_color = Color(0.08, 0.08, 0.12, 0.85)
		sb.border_color = Color(0.35, 0.35, 0.4)
		sb.set_border_width_all(2)
		sb.set_corner_radius_all(4)
		sb.set_content_margin_all(4)
		p.add_theme_stylebox_override("panel", sb)
		p.custom_minimum_size = Vector2(46, 26)
		var icon := TextureRect.new()
		icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		icon.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
		p.add_child(icon)
		slots_row.add_child(p)
		_slot_panels.append(p)
		_slot_icons.append(icon)

	var swap_hint := Label.new()
	swap_hint.text = "Q 切换武器"
	swap_hint.add_theme_font_size_override("font_size", _fs(11))
	swap_hint.add_theme_color_override("font_color", Color(0.75, 0.75, 0.8))
	swap_hint.add_theme_color_override("font_outline_color", Color(0.1, 0.06, 0.08))
	swap_hint.add_theme_constant_override("outline_size", 4)
	bl.add_child(swap_hint)

	# ---- F2/A 反应词缀行（附着后显示）----
	_suffix_label = Label.new()
	_suffix_label.text = ""
	_suffix_label.add_theme_font_size_override("font_size", _fs(11))
	_suffix_label.add_theme_color_override("font_color", Color(0.78, 0.62, 1.0))
	_suffix_label.add_theme_color_override("font_outline_color", Color(0.1, 0.06, 0.08))
	_suffix_label.add_theme_constant_override("outline_size", 4)
	bl.add_child(_suffix_label)

	# ---- toast（底部提示上方）----
	_toast = Label.new()
	_toast.set_anchors_preset(Control.PRESET_CENTER_BOTTOM)
	_toast.grow_horizontal = Control.GROW_DIRECTION_BOTH
	_toast.grow_vertical = Control.GROW_DIRECTION_BEGIN
	_toast.offset_bottom = -40.0
	_toast.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_toast.add_theme_font_size_override("font_size", _fs(17))
	_toast.add_theme_color_override("font_color", Color(1.0, 0.85, 0.4))
	_toast.add_theme_color_override("font_outline_color", Color(0.1, 0.06, 0.08))
	_toast.add_theme_constant_override("outline_size", 6)
	_toast.modulate.a = 0.0
	root.add_child(_toast)


## 左上状态条：护盾层数 / 连锁闪电 / 淬毒概率，成组一行、图标 ≤20px、未获得不占位（B5/L1）
func _build_status_ui(root: Control) -> void:
	_status_panel = PanelContainer.new()
	_status_panel.position = Vector2(12, 84)
	_style_panel(_status_panel)
	_status_panel.visible = false  # 三项全 0 时整条隐藏，不占常驻 HUD 位
	root.add_child(_status_panel)
	var hb := HBoxContainer.new()
	hb.add_theme_constant_override("separation", 10)
	_status_panel.add_child(hb)
	for def in STATUS_DEFS:
		var box := HBoxContainer.new()
		box.add_theme_constant_override("separation", 3)
		var icon := TextureRect.new()
		icon.texture = Assets.xicon(String(def["key"]))
		icon.custom_minimum_size = Vector2(20, 20)
		icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		icon.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
		icon.mouse_filter = Control.MOUSE_FILTER_IGNORE
		box.add_child(icon)
		var lbl := Label.new()
		lbl.add_theme_font_size_override("font_size", _fs(12))
		lbl.add_theme_color_override("font_outline_color", Color(0.1, 0.06, 0.08))
		lbl.add_theme_constant_override("outline_size", 4)
		lbl.text = "%s 0" % String(def["name"])
		box.add_child(lbl)
		box.visible = false
		hb.add_child(box)
		_status_boxes.append(box)
		_status_labels.append(lbl)


## 左上第三块：挑战因子 + 源石共鸣（Sprint 4）
func _build_meta_ui(root: Control) -> void:
	var panel := PanelContainer.new()
	_meta_panel = panel
	panel.position = Vector2(12, 118)
	_style_panel(panel)
	root.add_child(panel)
	var vb := VBoxContainer.new()
	vb.add_theme_constant_override("separation", 2)
	panel.add_child(vb)

	var row1 := HBoxContainer.new()
	row1.add_theme_constant_override("separation", 4)
	vb.add_child(row1)
	_modifier_icon = TextureRect.new()
	_modifier_icon.texture = Assets.xicon("mod_silent")
	_modifier_icon.custom_minimum_size = Vector2(16, 16)
	_modifier_icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	_modifier_icon.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	row1.add_child(_modifier_icon)
	_modifier_label = Label.new()
	_modifier_label.text = "静默"
	_modifier_label.add_theme_font_size_override("font_size", _fs(12))
	_modifier_label.add_theme_color_override("font_outline_color", Color(0.1, 0.06, 0.08))
	_modifier_label.add_theme_constant_override("outline_size", 4)
	row1.add_child(_modifier_label)

	var row2 := HBoxContainer.new()
	row2.add_theme_constant_override("separation", 4)
	vb.add_child(row2)
	var ri := TextureRect.new()
	ri.texture = Assets.xicon("resonance")
	ri.custom_minimum_size = Vector2(16, 16)
	ri.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	ri.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	row2.add_child(ri)
	_resonance_label = Label.new()
	_resonance_label.text = "共鸣 0/5"
	_resonance_label.add_theme_font_size_override("font_size", _fs(12))
	_resonance_label.add_theme_color_override("font_outline_color", Color(0.1, 0.06, 0.08))
	_resonance_label.add_theme_constant_override("outline_size", 4)
	row2.add_child(_resonance_label)

	# 第三行：三流派套装进度
	var row3 := HBoxContainer.new()
	row3.add_theme_constant_override("separation", 8)
	vb.add_child(row3)
	for key in ["fire", "elem", "surv"]:
		var l := Label.new()
		l.text = "%s 0/3" % String(Upgrades.TAGS[key]["name"])
		l.add_theme_font_size_override("font_size", _fs(12))
		l.add_theme_color_override("font_color", Upgrades.TAGS[key]["color"])
		l.add_theme_color_override("font_outline_color", Color(0.1, 0.06, 0.08))
		l.add_theme_constant_override("outline_size", 4)
		row3.add_child(l)
		_tag_labels[key] = l

	# 第四行：楼层主题（4 层起才有）
	_theme_label = Label.new()
	_theme_label.text = ""
	_theme_label.add_theme_font_size_override("font_size", _fs(12))
	_theme_label.add_theme_color_override("font_outline_color", Color(0.1, 0.06, 0.08))
	_theme_label.add_theme_constant_override("outline_size", 4)
	vb.add_child(_theme_label)


## 静默层主题：小地图整块隐藏
func set_minimap_hidden(v: bool) -> void:
	if _minimap_panel != null:
		_minimap_panel.visible = not v


func refresh_tags() -> void:
	for key in _tag_labels:
		var l: Label = _tag_labels[key]
		var n: int = int(Upgrades.tag_counts.get(key, 0))
		var need: int = int(Upgrades.TAGS[key]["need"])
		l.text = "%s %d/%d" % [String(Upgrades.TAGS[key]["name"]), mini(n, need), need]
		l.add_theme_color_override("font_color",
			Upgrades.TAGS[key]["color"] if n < need else Color(1.0, 0.85, 0.35))


func refresh_meta() -> void:
	if _modifier_label == null:
		return
	var m: Dictionary = Data.MODIFIERS.get(Game.main.modifier, {})
	_modifier_label.text = String(m.get("name", Game.main.modifier))
	_modifier_icon.texture = Assets.xicon(String(m.get("icon", "mod_silent")))
	if _theme_label != null:
		var th: Dictionary = Data.theme_for_floor(Game.floor_num)
		# Sprint 13 E：主题符号标记与色值并列展示（色盲友好——颜色不是唯一编码通道）
		_theme_label.text = ("主题 · %s %s" % [String(th.get("name", "")), String(th.get("mark", ""))]) \
			if th.has("name") else ""


func refresh_resonance() -> void:
	if _resonance_label == null:
		return
	_resonance_label.text = "共鸣 %d/%d" % [Game.main.resonance, Game.main._resonance_step]


func _refresh_status(p) -> void:
	var vals: Array[int] = [
		int(p.shield_charges),
		int(roundf(p.chain_chance * 100.0)),
		int(roundf(p.poison_chance * 100.0)),
	]
	var texts: Array[String] = ["×%d" % vals[0], "%d%%" % vals[1], "%d%%" % vals[2]]
	var any_active := false
	for i in _status_boxes.size():
		var on: bool = vals[i] > 0
		_status_boxes[i].visible = on
		if on:
			any_active = true
			_status_labels[i].text = "%s %s" % [String(STATUS_DEFS[i]["name"]), texts[i]]
	_status_panel.visible = any_active and not _compact


## 精简 HUD（设置项）：隐藏 meta 面板与状态条
func set_compact(v: bool) -> void:
	_compact = v
	if _meta_panel != null:
		_meta_panel.visible = not v
	if Game.main != null and is_instance_valid(Game.main) and is_instance_valid(Game.main.player):
		_refresh_status(Game.main.player)


func _on_weapon_changed(slots: Array, slot: int) -> void:
	for i in _slot_icons.size():
		var id: String = slots[i] if i < slots.size() else ""
		if id == "":
			_slot_icons[i].texture = null
			_slot_panels[i].modulate = Color(1, 1, 1, 0.4)
		else:
			_slot_icons[i].texture = Weapons.icon(id)
			_slot_panels[i].modulate = Color.WHITE if i == slot else Color(1, 1, 1, 0.55)
			var sb: StyleBoxFlat = _slot_panels[i].get_theme_stylebox("panel")
			sb.border_color = Color(1.0, 0.72, 0.3) if i == slot else Color(0.35, 0.35, 0.4)


func set_room_info(floor_num: int, kind: String) -> void:
	var kind_text: String = {"start": "", "combat": "", "elite": " · 精英", "treasure": " · 宝箱",
		"shop": " · 商店", "boss": " · BOSS", "super_secret": " · 超级秘密"}.get(kind, "")
	_wave_label.text = "第 %d 层%s" % [floor_num, kind_text]


## F2/A 反应词缀行：附着变化时重绘（词缀名·所属遗物名）
func refresh_suffixes(relic_suffixes: Dictionary) -> void:
	var parts := []
	for relic_id in relic_suffixes:
		var sd: Dictionary = Data.RELIC_SUFFIXES.get(String(relic_suffixes[relic_id]), {})
		if sd.is_empty():
			continue
		var rn: String = String(Data.ACTIVE_RELICS.get(relic_id, {}).get("name", relic_id))
		parts.append("%s(%s)" % [String(sd.get("name", "?")), rn])
	_suffix_label.text = "词缀 " + " · ".join(PackedStringArray(parts)) if parts.size() > 0 else ""


func refresh_minimap(d: Dungeon) -> void:
	if _minimap == null:
		return
	for c in _minimap.get_children():
		c.queue_free()
	# 以房间包围盒居中
	var min_c := Vector2i(99, 99)
	var max_c := Vector2i(-99, -99)
	for coord in d.rooms:
		min_c.x = mini(min_c.x, coord.x)
		min_c.y = mini(min_c.y, coord.y)
		max_c.x = maxi(max_c.x, coord.x)
		max_c.y = maxi(max_c.y, coord.y)
	var span := Vector2(max_c.x - min_c.x + 1, max_c.y - min_c.y + 1)
	var origin := Vector2(65 - span.x * 14 / 2.0, 48 - span.y * 12 / 2.0)
	for coord in d.rooms:
		var info: Dictionary = d.rooms[coord]
		# 秘密房/超级秘密房未炸开前不显示；颜色一律走 Data.room_color(kind)（坑 8）
		var rk: String = String(info.get("kind", ""))
		if (rk == "secret" or rk == "super_secret") and not bool(info.get("revealed", false)):
			continue
		var near_visited: bool = info["visited"]
		if not near_visited:
			for n in d.neighbors(coord):
				if d.room(n).get("visited", false):
					near_visited = true
					break
		if not near_visited:
			continue
		var r := ColorRect.new()
		var pos := origin + Vector2(coord.x - min_c.x, coord.y - min_c.y) * Vector2(14, 12)
		r.position = pos
		r.size = Vector2(11, 9)
		if coord == d.current:
			r.color = Color(1, 1, 1)
		elif info["visited"]:
			r.color = Color(0.95, 0.6, 0.25) if not info["cleared"] else Color(0.5, 0.52, 0.58)
		else:
			r.color = Color(0.28, 0.3, 0.36)
		r.mouse_filter = Control.MOUSE_FILTER_IGNORE
		_minimap.add_child(r)
		var mark: String = Data.ROOM_META.get(String(info["kind"]), {}).get("mark", "")
		if mark != "" and near_visited:
			var l := Label.new()
			l.text = mark
			l.position = pos + Vector2(3, -2)
			l.add_theme_font_size_override("font_size", _fs(9))
			l.add_theme_color_override("font_color", Data.room_color(String(info["kind"])))
			l.mouse_filter = Control.MOUSE_FILTER_IGNORE
			_minimap.add_child(l)


func flash_toast(text: String) -> void:
	_toast.text = text
	if _toast_tw and _toast_tw.is_valid():
		_toast_tw.kill()
	_toast.modulate.a = 1.0
	_toast_tw = _toast.create_tween()
	_toast_tw.tween_interval(2.2)
	_toast_tw.tween_property(_toast, "modulate:a", 0.0, 0.5)


func _process(_delta: float) -> void:
	_time_label.text = Game.fmt_time()
	if Game.main and is_instance_valid(Game.main.player):
		var p = Game.main.player
		var total: float = p.SKILL_CD if p.skill_cd > 0.0 else 1.0
		_skill_bar.value = 1.0 - p.skill_cd / total if p.skill_cd > 0.0 else 1.0
		_skill_label.text = "空格·过载！" if p.skill_active() else ("空格·过载" if p.skill_cd <= 0.0 else "过载冷却")
		_refresh_status(p)
	# 流派进度变化检测：选卡/预置/meta 发放/读档都会改 tag_counts，逐一挂接容易漏
	var sig := str(Upgrades.tag_counts) + str(Upgrades.sets_active)
	if sig != _tag_sig:
		_tag_sig = sig
		refresh_tags()


## 底部提示行：从当前 InputMap 动态生成（按键重绑后自动跟随）
func _build_hint_text() -> String:
	var parts := [
		"%s 射击" % Assets.action_label("shoot"),
		"%s 炸弹" % Assets.action_label("bomb"),
		"%s 技能" % Assets.action_label("skill"),
		"%s 切枪" % Assets.action_label("swap"),
		"%s 购买" % Assets.action_label("buy"),
		"%s 换弹" % Assets.action_label("reload"),
		"%s 暂停" % Assets.action_label("pause"),
	]
	return "    ".join(PackedStringArray(parts))


func _right_label(parent: Container, size: int) -> Label:
	var l := Label.new()
	l.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	l.add_theme_font_size_override("font_size", size)
	l.add_theme_color_override("font_outline_color", Color(0.1, 0.06, 0.08))
	l.add_theme_constant_override("outline_size", 5)
	parent.add_child(l)
	return l


func _icon_label(parent: Container, key: String) -> void:
	var t := TextureRect.new()
	t.texture = Assets.icon(key)
	t.custom_minimum_size = Vector2(16, 16)
	t.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	t.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	parent.add_child(t)


func _style_panel(p: PanelContainer) -> void:
	var sb := StyleBoxFlat.new()
	sb.bg_color = Color(0.10, 0.10, 0.14, 0.82)
	sb.border_color = Color(0.55, 0.35, 0.2)
	sb.set_border_width_all(2)
	sb.set_corner_radius_all(4)
	sb.set_content_margin_all(8)
	p.add_theme_stylebox_override("panel", sb)


func _style_bar(bar: ProgressBar, fill: Color) -> void:
	var bg := StyleBoxFlat.new()
	bg.bg_color = Color(0.08, 0.08, 0.1, 0.9)
	bg.set_corner_radius_all(3)
	var fg := StyleBoxFlat.new()
	fg.bg_color = fill
	fg.set_corner_radius_all(3)
	bar.add_theme_stylebox_override("background", bg)
	bar.add_theme_stylebox_override("fill", fg)


## 覆盖层：遮罩 + 居中内容整体装进 holder，显隐一起切（遮罩绝不单独留着盖屏幕）
func _overlay(root: Control, title: String, color: Color) -> Dictionary:
	var holder := Control.new()
	holder.set_anchors_preset(Control.PRESET_FULL_RECT)
	holder.visible = false
	root.add_child(holder)
	var shade := ColorRect.new()
	shade.color = Color(0, 0, 0, 0.62)
	shade.set_anchors_preset(Control.PRESET_FULL_RECT)
	holder.add_child(shade)
	var cc := CenterContainer.new()
	cc.set_anchors_preset(Control.PRESET_FULL_RECT)
	holder.add_child(cc)
	var vb := VBoxContainer.new()
	vb.add_theme_constant_override("separation", 10)
	cc.add_child(vb)
	var t := Label.new()
	t.text = title
	t.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	t.add_theme_font_size_override("font_size", _fs(42))
	t.add_theme_color_override("font_color", color)
	t.add_theme_color_override("font_outline_color", Color(0, 0, 0))
	t.add_theme_constant_override("outline_size", 10)
	vb.add_child(t)
	return {"holder": holder, "box": vb}


func banner(text: String) -> void:
	_banner.text = text
	if _banner_tw and _banner_tw.is_valid():
		_banner_tw.kill()
	_banner.modulate.a = 0.0
	_banner_tw = _banner.create_tween()
	_banner_tw.tween_property(_banner, "modulate:a", 1.0, 0.22)
	_banner_tw.tween_interval(1.4)
	_banner_tw.tween_property(_banner, "modulate:a", 0.0, 0.45)


func _on_combo_pop(n: int) -> void:
	_refresh_counters()
	if n < 2:
		return
	_combo.text = "连杀 ×%d" % n
	_combo.modulate.a = 1.0
	_combo.scale = Vector2(1.25, 1.25)
	var tw := _combo.create_tween()
	tw.set_parallel(true)
	tw.tween_property(_combo, "scale", Vector2.ONE, 0.18)
	tw.tween_property(_combo, "modulate:a", 0.0, 1.6).set_delay(0.9)


func _refresh_counters() -> void:
	_kills_label.text = "击杀 %d" % Game.kills
	_score_label.text = "得分 %d" % Game.score


func game_over(extra: String = "") -> void:
	_game_over = true
	_boss_box.visible = false
	_stats_label.text = "存活 %s   ·   击杀 %d   ·   第 %d 层\n最终得分 %d\n本局复盘 · 最深 %d 层 · 源石 %d" % [
		Game.fmt_time(), Game.kills, Game.floor_num, Game.score, Game.max_floor, int(Game.run_diamonds_earned)]
	# 结算文案由 game_main 提供（串本身冻结不动），这里只取两个数用于 5 行排版
	var pay := 0
	var balance := Game.meta_crystals()
	if extra != "":
		var plus := extra.split("+", true, 1)
		if plus.size() > 1:
			pay = int(String(plus[1]).strip_edges().split(" ", false, 1)[0])
		var tail := extra.split("余额", true, 1)
		if tail.size() > 1:
			balance = int(String(tail[1]).strip_edges())
	var picked := int(Game.run_diamonds_earned)
	_crystal_label.text = _crystal_line(picked, pay)
	_balance_label.text = "结晶累计 %d" % balance
	_unlock_label.text = "本局遇到的解锁物：%s" % _encountered_unlock_names()
	_gameover_holder.visible = true
	_roll_crystal(picked, pay)


func _crystal_line(picked: int, pay: int) -> String:
	return "本局源石 %d            本局结晶  +%d" % [picked, pay]


## 0 → +N 的 0.8s 数字滚动；SMOKE 下直接落终值，不拖慢 / 卡住 headless
func _roll_crystal(picked: int, pay: int) -> void:
	if _crystal_tw != null and _crystal_tw.is_valid():
		_crystal_tw.kill()
	if pay <= 0 or OS.get_environment("SMOKE") != "":
		_crystal_label.text = _crystal_line(picked, pay)
		return
	_crystal_tw = create_tween()
	_crystal_tw.tween_method(func(v) -> void:
		_crystal_label.text = _crystal_line(picked, int(v)), 0, pay, 0.8)
	Game.sfx("powerup")


## 本局实际拿到的解锁物名称（升级 / 遗物 / 武器槽），按解锁表顺序去重
func _encountered_unlock_names() -> String:
	var targets := {}
	for id in Meta.unlock_ids():
		var n := Meta.node(id)
		targets[String(n.get("target", ""))] = String(n.get("name", id))
	var found: Array = []
	for k in Upgrades.taken.keys():
		_collect_unlock_name(targets, String(k), found)
	if Game.main != null and is_instance_valid(Game.main) and is_instance_valid(Game.main.player):
		var p = Game.main.player
		for r in p.relics:
			_collect_unlock_name(targets, String(r), found)
		for w in p.weapon_slots:
			_collect_unlock_name(targets, String(w), found)
	if found.is_empty():
		return "无"
	var out := ""
	for s in found:
		if out != "":
			out += "、"
		out += String(s)
	return out


func _collect_unlock_name(targets: Dictionary, content_id: String, found: Array) -> void:
	if content_id == "" or not targets.has(content_id):
		return
	var nm := String(targets[content_id])
	if not found.has(nm):
		found.append(nm)


func set_paused(v: bool) -> void:
	_paused = v
	_pause_holder.visible = v


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("pause"):
		get_viewport().set_input_as_handled()
		Game.main.toggle_pause()
	elif _game_over and event is InputEventKey and event.pressed and not event.echo:
		if event.physical_keycode == KEY_R:
			get_viewport().set_input_as_handled()
			Game.main.restart()
