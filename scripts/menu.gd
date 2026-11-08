extends CanvasLayer
## 主菜单 / 设置 / 暂停菜单 / 解锁页：单场景覆盖层，不引入多场景切换。
## 设置由 Game 读写（user://settings.cfg）；局外进度由 Game 读写（user://meta.cfg）；
## 音量走系数，不新增 audio bus。

const Meta := preload("res://scripts/meta.gd")
## 遗物池（图鉴 relics 总数与名称）
const RelicsRef := preload("res://scripts/relics.gd")

var _root: Control
var _shade: ColorRect
var _center: VBoxContainer
var _decor: Control = null   # 仅主菜单的装饰层，切页即释放
var _title: Label
var _rows: VBoxContainer
var _page := ""
var _back_page := "main"
var _unlock_icons_ok := 0   # §5.4：解锁页图标解析成功数（断言白框）
var _confirm: ConfirmationDialog = null   # G8 购买二次确认，切页即释放

# 按键重绑定
var _capturing_action := ""   # 正在等待新按键的动作名；"" = 非捕获态
var _capture_start_frame := 0 # 忽略发起点击自身的释放残波
var _bind_buttons := {}       # action -> Button（刷新用）


func _ready() -> void:
	layer = 200
	process_mode = Node.PROCESS_MODE_ALWAYS
	_root = Control.new()
	_root.set_anchors_preset(Control.PRESET_FULL_RECT)
	_root.theme = Assets.theme()
	add_child(_root)
	_shade = ColorRect.new()
	_shade.color = Color(0.05, 0.04, 0.07, 0.93)
	_shade.set_anchors_preset(Control.PRESET_FULL_RECT)
	_root.add_child(_shade)
	# Sprint 13 E：地窖背景板（art 预留兑现，纯表现层——遮罩之上、内容层之下）
	var bg := TextureRect.new()
	bg.texture = load("res://resources/texture/generated/cellar_bg.png")
	bg.set_anchors_preset(Control.PRESET_FULL_RECT)
	bg.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	bg.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
	bg.modulate = Color(0.62, 0.62, 0.72, 0.5)
	bg.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_root.add_child(bg)
	_center = VBoxContainer.new()
	_center.set_anchors_preset(Control.PRESET_CENTER)
	_center.grow_horizontal = Control.GROW_DIRECTION_BOTH
	_center.grow_vertical = Control.GROW_DIRECTION_BOTH
	_root.add_child(_center)
	_title = Label.new()
	_title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_title.add_theme_font_size_override("font_size", 40)
	_title.add_theme_color_override("font_color", Color(1.0, 0.82, 0.42))
	_title.add_theme_color_override("font_outline_color", Color(0.08, 0.05, 0.07))
	_title.add_theme_constant_override("outline_size", 6)
	_center.add_child(_title)
	_rows = VBoxContainer.new()
	_rows.add_theme_constant_override("separation", 12)
	_rows.alignment = BoxContainer.ALIGNMENT_CENTER
	_center.add_child(_rows)
	# SMOKE 自动化下不弹主菜单（会把整局卡在暂停里）；SMOKE_MENU 仅用于截图菜单
	if OS.get_environment("SMOKE") == "":
		show_page("main")
		get_tree().paused = true
	elif OS.get_environment("SMOKE_MENU") != "":
		show_page("main")
		var pg := OS.get_environment("SMOKE_MENU_PAGE")
		if pg != "":
			show_page(pg, "main")
	else:
		show_page("")
	if OS.get_environment("SMOKE_REBIND") != "":
		_rebind_selftest.call_deferred()


## 开局页：左右分栏 + 专属装饰，刻意与暂停/设置页的「居中一列按钮」区分开
func _build_main_page() -> void:
	# 开局页把遮罩加深：默认 0.93 会让游戏 HUD（血条/计时/层数）透字，画面显脏
	_shade.color = Color(0.05, 0.04, 0.07, 0.985)
	_title.visible = false
	_center.set_anchors_preset(Control.PRESET_FULL_RECT)
	_center.offset_left = 0
	_center.offset_top = 0
	_center.offset_right = 0
	_center.offset_bottom = 0
	_center.alignment = BoxContainer.ALIGNMENT_CENTER
	_rows.add_theme_constant_override("separation", 0)

	_decor = Control.new()
	_decor.set_anchors_preset(Control.PRESET_FULL_RECT)
	_decor.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_root.add_child(_decor)
	_root.move_child(_decor, 1)   # 遮罩之上、按钮之下
	_build_main_decor(_decor)

	var hbox := HBoxContainer.new()
	hbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	hbox.add_theme_constant_override("separation", 110)
	hbox.alignment = BoxContainer.ALIGNMENT_CENTER
	_rows.add_child(hbox)

	var left := VBoxContainer.new()
	left.add_theme_constant_override("separation", 16)
	left.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	hbox.add_child(left)
	var big := Label.new()
	big.text = "源石虫清剿战"
	big.add_theme_font_size_override("font_size", 58)
	big.add_theme_color_override("font_color", Color(1.0, 0.86, 0.52))
	big.add_theme_color_override("font_outline_color", Color(0.10, 0.05, 0.04))
	big.add_theme_constant_override("outline_size", 10)
	left.add_child(big)
	var en := Label.new()
	en.text = "ROGUELIKE  /  源石矿脉清剿行动"
	en.add_theme_font_size_override("font_size", 16)
	en.add_theme_color_override("font_color", Color(0.74, 0.70, 0.78))
	left.add_child(en)
	var rule := ColorRect.new()
	rule.color = Color(0.95, 0.72, 0.32, 0.85)
	rule.custom_minimum_size = Vector2(320, 2)
	rule.mouse_filter = Control.MOUSE_FILTER_IGNORE
	left.add_child(rule)
	var tag := Label.new()
	tag.text = "深入矿脉   ·   清剿虫群   ·   带回归途"
	tag.add_theme_font_size_override("font_size", 15)
	tag.add_theme_color_override("font_color", Color(0.58, 0.56, 0.63))
	left.add_child(tag)
	# D 每日挑战：当日最佳（有记录才显示）
	var best: Dictionary = Game.daily_best_today()
	if int(best.get("layers", 0)) > 0:
		var best_label := Label.new()
		var bt := int(best.get("time", 0.0))
		best_label.text = "今日最佳：第 %d 层 · %02d:%02d" % [int(best["layers"]), int(bt / 60.0), bt % 60]
		best_label.add_theme_font_size_override("font_size", 13)
		best_label.add_theme_color_override("font_color", Color(0.6, 0.9, 0.95))
		left.add_child(best_label)
	# Sprint 17 C：每日分享码 + 最近 7 天本地榜（纯局外只读；返回真实 Label 供验渲染断言）
	build_daily_share_widgets(left)

	var right := VBoxContainer.new()
	right.add_theme_constant_override("separation", 14)
	right.custom_minimum_size = Vector2(268, 0)
	right.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	hbox.add_child(right)
	_add_main_button(right, "开始游戏", "diamond", func() -> void:
		Game.daily_mode = false
		start_game(), true)
	_add_main_button(right, "每日挑战", "icon_suffix", func() -> void:
		Game.daily_mode = true
		start_game(), false)
	_add_main_button(right, "印记", "icon_suffix", func() -> void: show_page("sigils", "main"), false)
	_add_main_button(right, "解锁", "icon_pierce", func() -> void: show_page("unlocks", "main"), false)
	_add_main_button(right, "图鉴", "icon_codex", func() -> void: show_page("codex", "main"), false)
	_add_main_button(right, "设置", "icon_guard", func() -> void: show_page("settings", "main"), false)
	_add_main_button(right, "退出游戏", "wpn_launcher", func() -> void: get_tree().quit(), false)
	var foot := Label.new()
	foot.text = "v1.1  ·  Sprint 11  ·  按 Esc 暂停"
	foot.add_theme_font_size_override("font_size", 13)
	foot.add_theme_color_override("font_color", Color(0.60, 0.58, 0.64))
	foot.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	right.add_child(foot)


## Sprint 17 C：每日分享码 + 最近 7 天本地榜控件（纯局外只读、零 rng、零计时）。
## 返回真实 Label / LineEdit 节点供 SMOKE_DAILY_SHARE 做「验渲染」断言；探针可在脱离
## 场景树的容器上构建，避免与其它并发探针抢 _rows。不新增 PNG / ACTION_DEFS action。
func build_daily_share_widgets(parent: Node) -> Dictionary:
	var code := Game.daily_share_code()
	var share_label := Label.new()
	share_label.text = "今日分享码：" + code
	share_label.add_theme_font_size_override("font_size", 13)
	share_label.add_theme_color_override("font_color", Color(0.85, 0.78, 0.55))
	parent.add_child(share_label)

	# 状态行同时承载「近 7 日」榜单与载入失败提示（纯文本，不弹窗）
	var hist_label := Label.new()
	hist_label.text = Game.daily_history_text()
	hist_label.add_theme_font_size_override("font_size", 12)
	hist_label.add_theme_color_override("font_color", Color(0.62, 0.72, 0.68))

	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 8)
	var edit := LineEdit.new()
	edit.text = code
	edit.custom_minimum_size = Vector2(188, 28)
	edit.add_theme_font_size_override("font_size", 13)
	row.add_child(edit)
	var copy_btn := Button.new()
	copy_btn.text = "复制"
	copy_btn.custom_minimum_size = Vector2(52, 28)
	copy_btn.pressed.connect(_copy_daily_share)
	row.add_child(copy_btn)
	var load_btn := Button.new()
	load_btn.text = "载入"
	load_btn.custom_minimum_size = Vector2(52, 28)
	load_btn.pressed.connect(func() -> void:
		_load_daily_share(String(edit.text).strip_edges(), hist_label))
	row.add_child(load_btn)
	parent.add_child(row)
	parent.add_child(hist_label)
	return {"share": share_label, "history": hist_label, "edit": edit}


## headless 下 DisplayServer 为 dummy，剪贴板不可用 → 跳过（同 _skip_confirm 口径）
func _copy_daily_share() -> void:
	if DisplayServer.get_name() == "headless":
		return
	DisplayServer.clipboard_set(Game.daily_share_code())


## 粘贴/载入：只接受「格式+校验位合法且为今日」的码；本地功能不联网、不改 start_run 的 rng 顺序。
## 校验失败只改状态行文本，不启动游戏、不写盘。
func _load_daily_share(code: String, status: Label) -> void:
	if not Game.daily_share_code_valid(code) or Game.daily_share_code_key(code) != Game.daily_key():
		status.text = "分享码校验失败或非今日，未载入"
		return
	Game.daily_mode = true
	start_game()


## 纯几何装饰：不新增任何 PNG / 图标 key，避开「新增图标查表导致面板崩」
func _build_main_decor(d: Control) -> void:
	var band := ColorRect.new()
	band.color = Color(0.85, 0.55, 0.20, 0.06)
	band.position = Vector2(0, 0)
	band.size = Vector2(430, 720)
	band.mouse_filter = Control.MOUSE_FILTER_IGNORE
	d.add_child(band)
	for y in [64.0, 656.0]:
		var ln := ColorRect.new()
		ln.color = Color(0.92, 0.70, 0.34, 0.26)
		ln.position = Vector2(90, y)
		ln.size = Vector2(1100, 1)
		ln.mouse_filter = Control.MOUSE_FILTER_IGNORE
		d.add_child(ln)
	var sep := ColorRect.new()
	sep.color = Color(0.92, 0.70, 0.34, 0.32)
	sep.position = Vector2(700, 205)
	sep.size = Vector2(1, 310)
	sep.mouse_filter = Control.MOUSE_FILTER_IGNORE
	d.add_child(sep)
	for i in 5:
		var r := ColorRect.new()
		var sz := 26.0 - i * 3.5
		r.color = Color(0.95, 0.72, 0.32, 0.17 - i * 0.026)
		r.size = Vector2(sz, sz)
		r.pivot_offset = Vector2(sz / 2.0, sz / 2.0)
		r.rotation = PI / 4.0
		r.position = Vector2(112 + i * 34, 150 + i * 12)
		r.mouse_filter = Control.MOUSE_FILTER_IGNORE
		d.add_child(r)
	for i in 5:
		var r2 := ColorRect.new()
		var sz2 := 22.0 - i * 3.0
		r2.color = Color(0.95, 0.72, 0.32, 0.15 - i * 0.023)
		r2.size = Vector2(sz2, sz2)
		r2.pivot_offset = Vector2(sz2 / 2.0, sz2 / 2.0)
		r2.rotation = PI / 4.0
		r2.position = Vector2(1090 - i * 30, 570 - i * 10)
		r2.mouse_filter = Control.MOUSE_FILTER_IGNORE
		d.add_child(r2)


## 开局按钮：带图标 + 统一尺寸；图标复用 §5.1 三段 resolver（解析不出就留白而非崩）
func _add_main_button(parent: Node, text: String, icon_key: String, cb: Callable, primary: bool) -> void:
	var b := Button.new()
	b.text = text
	b.custom_minimum_size = Vector2(268, 50)
	b.add_theme_font_size_override("font_size", 19)
	var t := meta_icon(icon_key)
	if t != null and t != Assets.white_tex:
		b.icon = t
	if primary:
		b.add_theme_color_override("font_color", Color(1.0, 0.90, 0.60))
		var sb := StyleBoxFlat.new()
		sb.bg_color = Color(0.26, 0.19, 0.10, 0.96)
		sb.border_color = Color(0.95, 0.72, 0.32)
		sb.set_border_width_all(2)
		sb.set_corner_radius_all(4)
		b.add_theme_stylebox_override("normal", sb)
		var hov: StyleBoxFlat = sb.duplicate()
		hov.bg_color = Color(0.38, 0.28, 0.13, 0.98)
		hov.border_color = Color(1.0, 0.85, 0.45)
		b.add_theme_stylebox_override("hover", hov)
		var prs: StyleBoxFlat = sb.duplicate()
		prs.bg_color = Color(0.44, 0.32, 0.14, 1.0)
		b.add_theme_stylebox_override("pressed", prs)
	b.pressed.connect(cb)
	parent.add_child(b)


## 切页：main / settings / pause / unlocks / ""（隐藏）
func show_page(page: String, back := "") -> void:
	_close_confirm()
	_capturing_action = ""   # 切页放弃未完成的按键捕获
	_page = page
	if back != "":
		_back_page = back
	for c in _rows.get_children():
		# 先隐藏再释放：queue_free 延迟到帧末，否则同帧内旧按钮仍可点（重复购买）
		c.visible = false
		c.queue_free()
	if _decor != null and is_instance_valid(_decor):
		_decor.queue_free()
	_decor = null
	# 每次切页复位通用骨架：只有 main 临时改成左右分栏
	_shade.color = Color(0.05, 0.04, 0.07, 0.93)
	_title.visible = true
	_title.add_theme_font_size_override("font_size", 40)
	_center.set_anchors_preset(Control.PRESET_CENTER)
	# set_anchors_preset 默认 keep_offsets=false：从 main 的 FULL_RECT 切回 CENTER 时
	# 会补偿 offsets 把容器留在全屏尺寸，导致其他页按钮被拉成 100% 宽、内容左移。
	# 必须硬复位成 _ready() 的初始 offsets，让 grow BOTH 重新按内容最小尺寸居中。
	_center.offset_left = 0
	_center.offset_top = 0
	_center.offset_right = 0
	_center.offset_bottom = 0
	_center.grow_horizontal = Control.GROW_DIRECTION_BOTH
	_center.grow_vertical = Control.GROW_DIRECTION_BOTH
	_center.alignment = BoxContainer.ALIGNMENT_BEGIN
	_rows.add_theme_constant_override("separation", 12)
	_root.visible = page != ""
	if page == "main":
		_build_main_page()
		return
	match page:
		"settings":
			_title.text = "设置"
			_build_settings()
			_add_button("返回", func() -> void: show_page(_back_page))
		"pause":
			_title.text = "暂停"
			_add_button("继续", func() -> void: Game.main.toggle_pause())
			_add_button("设置", func() -> void: show_page("settings", "pause"))
			_add_button("回主菜单", func() -> void: show_page("quit_confirm", "pause"))
		"quit_confirm":
			_title.text = "退出本局？"
			var est := 0
			if Game.main != null and is_instance_valid(Game.main) and Game.main.has_method("quit_estimate"):
				est = Game.main.quit_estimate()
			var tip := Label.new()
			tip.text = "主动退出不结算，本局将损失约 %d 结晶" % est
			tip.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
			_rows.add_child(tip)
			_add_button("确认退出", func() -> void: Game.main.to_main_menu())
			_add_button("取消", func() -> void: show_page("pause"))
		"unlocks":
			_title.text = "解锁"
			_build_unlocks()
			_add_button("返回", func() -> void: show_page(_back_page))
		"sigils":
			_title.text = "地窖印记"
			_build_sigils()
			_add_button("返回", func() -> void: show_page(_back_page))
		"codex":
			_title.text = "地窖图鉴"
			_build_codex()
			_add_button("返回", func() -> void: show_page(_back_page))
		_:
			_title.text = ""


## Sprint 13 C：地窖图鉴页——只读沉淀（已遇/已发现/已击败 + 上局复盘）。
## 平行页：不读不写 meta.gd UNLOCKS（冻结规格 v2.10）
func _build_codex() -> void:
	var lr: Dictionary = Game.codex.get("last_run", {})
	var replay := Label.new()
	if lr.is_empty():
		replay.text = "上局复盘：暂无记录（完成一局后生成）"
	else:
		var t := int(lr.get("time", 0.0))
		replay.text = "上局复盘 · 最深 %d 层 · 击杀 %d · 源石 %d · 用时 %d:%02d · 得分 %d" % [
			int(lr.get("max_floor", 0)), int(lr.get("kills", 0)), int(lr.get("diamonds", 0)),
			t / 60, t % 60, int(lr.get("score", 0))]
	replay.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	replay.add_theme_font_size_override("font_size", 15)
	replay.add_theme_color_override("font_color", Color(1.0, 0.85, 0.45))
	_rows.add_child(replay)
	# Sprint 16 A/B：誓约兑现 + 抉择回声（只读 last_run 平行字段，纯展示零数值）
	var oath: Dictionary = lr.get("oath", {})
	if not oath.is_empty():
		var ol := Label.new()
		var omark := "已兑现" if bool(oath.get("done", false)) else "未兑现"
		ol.text = "本局誓约 · %s「%s」%s（%d/%d）" % [String(oath.get("name", "")),
			String(oath.get("desc", "")), omark, int(oath.get("cur", 0)), int(oath.get("need", 0))]
		ol.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		ol.add_theme_font_size_override("font_size", 14)
		ol.add_theme_color_override("font_color",
			Color(0.6, 0.95, 0.7) if bool(oath.get("done", false)) else Color(0.72, 0.75, 0.82))
		_rows.add_child(ol)
	var echo: Dictionary = lr.get("echo", {})
	if int(echo.get("count", 0)) > 0:
		var names := []
		for cid3 in echo.get("choices", []):
			names.append(String(Data.SHRINE_OFFERS.get(String(cid3), {}).get("name", cid3)))
		var el := Label.new()
		el.text = "抉择回声 · %s：%s" % [String(echo.get("tag", "")), " → ".join(names)]
		el.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		el.add_theme_font_size_override("font_size", 13)
		el.add_theme_color_override("font_color", Color(0.78, 0.82, 0.9))
		_rows.add_child(el)

	var boss_total := Data.codex_bosses_total()   # Sprint 14 A：分母单源（ENEMIES 真 Boss + 2 主题 Boss）
	_codex_section("enemies", "已遇敌人", Data.ENEMIES.size(),
		func(id: String) -> String: return String(Data.ENEMIES[id].get("name", id)))
	_codex_section("bosses", "已击败 Boss", boss_total,
		func(id: String) -> String:
			# 显示名单源：主题 Boss 中文名优先（不在 ENEMIES，防英文 id 直出），普通 Boss 走 ENEMIES
			if Data.CODEX_BOSS_NAMES.has(id):
				return String(Data.CODEX_BOSS_NAMES[id])
			return String(Data.ENEMIES[id].get("name", id)))
	_codex_section("relics", "已见遗物", RelicsRef.POOL.size(),
		func(id: String) -> String:
			for r in RelicsRef.POOL:
				if String(r["id"]) == id:
					return String(r.get("name", id))
			return id)
	_codex_section("suffixes", "已获词缀", Data.RELIC_SUFFIXES.size(),
		func(id: String) -> String: return String(Data.RELIC_SUFFIXES[id].get("name", id)))
	var theme_names := {}
	for k in Data.FLOOR_THEMES:
		theme_names[String(Data.FLOOR_THEMES[k]["rule"])] = String(Data.FLOOR_THEMES[k]["name"])
	_codex_section("themes", "已历主题", Data.FLOOR_THEMES.size(),
		func(id: String) -> String: return String(theme_names.get(id, id)))


func _codex_section(kind: String, title: String, total: int, name_of: Callable) -> void:
	var arr: Array = Game.codex.get(kind, [])
	var head := Label.new()
	head.text = "%s %d / %d" % [title, arr.size(), total]
	head.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	head.add_theme_font_size_override("font_size", 16)
	head.add_theme_color_override("font_color", Color(0.6, 0.9, 0.95))
	_rows.add_child(head)
	# Sprint 15 C：进度条可视化（纯 UI 零 rng 零 E1）
	if total > 0:
		var bar := ProgressBar.new()
		bar.max_value = total
		bar.value = arr.size()
		bar.show_percentage = false
		bar.custom_minimum_size = Vector2(560, 6)
		bar.modulate = Color(0.5, 0.9, 0.75)
		_rows.add_child(bar)
	var parts := []
	for id in arr:
		parts.append(String(name_of.call(String(id))))
	var body := Label.new()
	var undiscovered: int = total - arr.size()
	if parts.size() > 0:
		body.text = "　" + "、".join(parts) + (("　（未发现 %d）" % undiscovered) if undiscovered > 0 else "")
	else:
		body.text = "　（尚未发现 %d 项）" % total if total > 0 else "　（尚未发现）"
	body.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	body.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	body.custom_minimum_size = Vector2(560, 0)
	body.add_theme_font_size_override("font_size", 13)
	body.add_theme_color_override("font_color",
		Color(0.78, 0.82, 0.9) if parts.size() > 0 else Color(0.5, 0.52, 0.58))
	_rows.add_child(body)
	# Sprint 16 D：地窖低语展开（已发现条目附矿工手记，纯文本零 rng）
	var flavor := ""
	for id2 in arr:
		flavor += String(Data.FLAVOR.get(kind + "/" + String(id2), ""))
	if flavor != "":
		var fl_l := Label.new()
		fl_l.text = "　手记：" + flavor
		fl_l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		fl_l.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		fl_l.custom_minimum_size = Vector2(560, 0)
		fl_l.add_theme_font_size_override("font_size", 12)
		fl_l.add_theme_color_override("font_color", Color(0.62, 0.66, 0.72))
		_rows.add_child(fl_l)


func _build_settings() -> void:
	_add_slider("主音量", "master")
	_add_slider("BGM 音量", "bgm")
	_add_slider("音效音量", "sfx")
	_add_slider("屏幕震动", "shake")
	_add_toggle("精简 HUD", "compact_hud")
	_add_option("分辨率", "resolution", Game.RESOLUTION_PRESETS, Game.RESOLUTION_PRESETS)
	_add_option("窗口模式", "window_mode", [0, 1, 2], Game.WINDOW_MODES)
	_add_option("HUD 字号", "ui_font", ["0", "1", "2"], ["小", "标准", "大"])
	_add_binding_section()


## 按键重绑定：每动作一行「名称 | 当前键」，点击进入捕获态
func _add_binding_section() -> void:
	var head := Label.new()
	head.text = "按键设置 —— 点击后按新键（Esc 取消，冲突会被拒绝）"
	head.add_theme_font_size_override("font_size", 14)
	head.add_theme_color_override("font_color", Color(0.75, 0.75, 0.8))
	_rows.add_child(head)

	var scroll := ScrollContainer.new()
	scroll.custom_minimum_size = Vector2(430, 208)
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	_rows.add_child(scroll)
	var list := VBoxContainer.new()
	list.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	list.add_theme_constant_override("separation", 4)
	scroll.add_child(list)

	_bind_buttons.clear()
	for action in Assets.ACTION_DEFS:
		var def: Dictionary = Assets.ACTION_DEFS[action]
		var row := HBoxContainer.new()
		row.add_theme_constant_override("separation", 10)
		list.add_child(row)
		var l := Label.new()
		l.text = str(def["name"])
		l.custom_minimum_size = Vector2(110, 0)
		l.add_theme_font_size_override("font_size", 15)
		row.add_child(l)
		var b := Button.new()
		b.text = Assets.action_label(action)
		b.custom_minimum_size = Vector2(230, 26)
		b.add_theme_font_size_override("font_size", 14)
		row.add_child(b)
		_bind_buttons[action] = b
		b.pressed.connect(func() -> void: _start_capture(action))

	var reset := Button.new()
	reset.text = "恢复默认按键"
	reset.custom_minimum_size = Vector2(150, 30)
	reset.pressed.connect(func() -> void:
		Assets.reset_bindings()
		Game.save_settings()
		_refresh_bind_buttons()
		Game.flash_toast("按键已恢复默认"))
	_rows.add_child(reset)


func _refresh_bind_buttons() -> void:
	for action in _bind_buttons:
		var b: Button = _bind_buttons[action]
		if is_instance_valid(b):
			b.text = Assets.action_label(action)


func _start_capture(action: String) -> void:
	_capturing_action = action
	_capture_start_frame = Engine.get_process_frames()
	var b: Button = _bind_buttons[action]
	b.text = "按任意键…（Esc 取消）"


func _end_capture() -> void:
	_capturing_action = ""
	_refresh_bind_buttons()


## 捕获态吞掉所有按键/鼠标按下事件：Esc 取消，其余尝试重绑定。
## 用 _input 而非 _unhandled_input：必须先于 hud 的 Esc 暂停处理生效。
func _input(event: InputEvent) -> void:
	if _capturing_action == "":
		return
	var pressed: InputEvent = null
	if event is InputEventKey and event.pressed and not event.echo:
		pressed = event
	elif event is InputEventMouseButton and event.pressed:
		pressed = event
	if pressed == null:
		return
	get_viewport().set_input_as_handled()
	# 发起点击的同一连击（按下/释放残波）忽略
	if Engine.get_process_frames() - _capture_start_frame <= 2:
		return
	var action := _capturing_action
	if pressed is InputEventKey and pressed.physical_keycode == KEY_ESCAPE:
		_end_capture()
		return
	var err: String = Assets.rebind_action(action, pressed)
	if err == "":
		Game.save_settings()
		Game.flash_toast("%s → %s" % [Assets.ACTION_DEFS[action]["name"], Assets.event_label(pressed)])
		_end_capture()
		return
	# 冲突/拒绝：按钮上闪提示 1.4 秒后还原
	var b: Button = _bind_buttons[action]
	b.text = "✗ %s" % err
	_end_capture()
	Game.safe_delay(1.4, self, true, func() -> void:
		if _capturing_action == "" and is_instance_valid(b):
			_refresh_bind_buttons())


## SMOKE_REBIND=1：无头自测——重绑/冲突拒绝/类型禁用/存档往返/恢复默认，结论走 Dev.check
func _rebind_selftest() -> void:
	# 1) 合法重绑 move_up -> T
	var err1: String = Assets.rebind_action("move_up", Assets.event_from_code("k:84"))
	Dev.check(err1 == "", "rebind", "重绑 move_up→T：%s" % ("成功" if err1 == "" else err1))
	# 2) 冲突拒绝：move_down → T（已被 move_up 占用）
	var err2: String = Assets.rebind_action("move_down", Assets.event_from_code("k:84"))
	Dev.check(err2 == "上移", "rebind", "冲突拒绝 move_down→T（占用者=%s）" % err2)
	# 3) 类型禁用：move_up 不接受鼠标
	var err3: String = Assets.rebind_action("move_up", Assets.event_from_code("m:1"))
	Dev.check(err3 == "此动作不接受鼠标", "rebind", "move_up 拒鼠标（%s）" % err3)
	# 4) 存档往返
	Game.save_settings()
	var cfg := ConfigFile.new()
	cfg.load("user://settings.cfg")
	var saved: Dictionary = cfg.get_value("bindings", "map", {})
	Dev.check(str(saved.get("move_up", "")) == "k:84", "rebind", "存档含 move_up=k:84")
	# 5) 读档恢复
	Assets.reset_bindings()
	Game.load_settings()
	var evs := InputMap.action_get_events("move_up")
	Dev.check(evs.size() > 0 and Assets.event_code(evs[0]) == "k:84", "rebind", "读档恢复 move_up=T")
	# 6) 恢复默认并回存
	Assets.reset_bindings()
	Game.save_settings()
	Dev.check(Assets.action_label("move_up") == "W/↑", "rebind", "恢复默认 W/↑")
	print("[SMOKE-REBIND] done")


## 地窖印记页（Sprint 11 C）：shards 余额 + 解锁/携带（每局 1 枚，run 开始前注入）
func _build_sigils() -> void:
	var balance := Label.new()
	balance.text = "地窖碎片：%d（局末按到达层数结算）" % int(Game.sigils["shards"])
	balance.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	balance.add_theme_font_size_override("font_size", 20)
	balance.add_theme_color_override("font_color", Color(0.6, 0.9, 0.95))
	_rows.add_child(balance)
	var eq_name := "无"
	if String(Game.sigils["equipped"]) != "" and Data.SIGILS.has(String(Game.sigils["equipped"])):
		eq_name = String(Data.SIGILS[String(Game.sigils["equipped"])]["name"])
	var eq_label := Label.new()
	eq_label.text = "当前携带：%s（每局 1 枚，开局时注入）" % eq_name
	eq_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	eq_label.add_theme_font_size_override("font_size", 14)
	eq_label.add_theme_color_override("font_color", Color(0.78, 0.62, 1.0))
	_rows.add_child(eq_label)

	var scroll := ScrollContainer.new()
	scroll.custom_minimum_size = Vector2(560, 280)
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	_rows.add_child(scroll)
	var list := VBoxContainer.new()
	list.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	list.add_theme_constant_override("separation", 6)
	scroll.add_child(list)

	for id in Data.SIGILS:
		_add_sigil_row(list, String(id))


func _add_sigil_row(parent: Node, id: String) -> void:
	var def: Dictionary = Data.SIGILS[id]
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 12)
	parent.add_child(row)
	var ic := TextureRect.new()
	ic.texture = Assets.g("icon_suffix")
	ic.custom_minimum_size = Vector2(24, 24)
	ic.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	ic.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	row.add_child(ic)
	var info := VBoxContainer.new()
	info.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	info.add_theme_constant_override("separation", 2)
	row.add_child(info)
	var nm := Label.new()
	nm.text = String(def["name"])
	nm.add_theme_font_size_override("font_size", 16)
	info.add_child(nm)
	var ds := Label.new()
	ds.text = String(def["desc"])
	ds.add_theme_font_size_override("font_size", 12)
	ds.add_theme_color_override("font_color", Color(0.72, 0.72, 0.78))
	info.add_child(ds)

	var unlocked: bool = (Game.sigils["unlocked"] as Array).has(id)
	var equipped: bool = String(Game.sigils["equipped"]) == id
	var b := Button.new()
	b.custom_minimum_size = Vector2(170, 32)
	if equipped:
		b.text = "已携带（卸下）"
		b.pressed.connect(func() -> void:
			Game.equip_sigil("")
			show_page("sigils", _back_page))
	elif unlocked:
		b.text = "携带"
		b.pressed.connect(func() -> void:
			Game.equip_sigil(id)
			show_page("sigils", _back_page))
	else:
		var cost := int(def["cost"])
		b.text = "解锁（%d 碎片）" % cost
		b.disabled = int(Game.sigils["shards"]) < cost
		b.pressed.connect(func() -> void:
			if Game.unlock_sigil(id):
				Game.equip_sigil(id)
			show_page("sigils", _back_page))
	row.add_child(b)


## 解锁页：结晶余额 + 解锁列表（可滚动，防节点多时溢出屏幕）
func _build_unlocks() -> void:
	_unlock_icons_ok = 0
	var balance := Label.new()
	balance.text = "结晶源石：%d" % Game.meta_crystals()
	balance.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	balance.add_theme_font_size_override("font_size", 20)
	balance.add_theme_color_override("font_color", Color(1.0, 0.85, 0.45))
	_rows.add_child(balance)

	var scroll := ScrollContainer.new()
	scroll.custom_minimum_size = Vector2(560, 330)
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	_rows.add_child(scroll)
	var list := VBoxContainer.new()
	list.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	list.add_theme_constant_override("separation", 6)
	scroll.add_child(list)

	for id in Meta.unlock_ids():
		_add_unlock_row(list, String(id))
	if OS.get_environment("SMOKE") != "":
		print("[SMOKE-META] unlock page rows=%d balance=%d" % [
			Meta.unlock_ids().size(), Game.meta_crystals()])
		print("[SMOKE-META-EXTRA] unlock icons resolved=%d/%d" % [
			_unlock_icons_ok, Meta.unlock_ids().size()])
		Dev.check(_unlock_icons_ok == Meta.unlock_ids().size(), "meta",
			"解锁页图标白框：仅 %d/%d 解析成功" % [
				_unlock_icons_ok, Meta.unlock_ids().size()])
	# 带窗口视觉走查：显式开关下展开一次确认框供 SMOKE_SHOTS 截图（不实际购买）
	if OS.get_environment("SMOKE_MENU") != "" and OS.get_environment("SMOKE_UI_CONFIRM") != "" \
			and DisplayServer.get_name() != "headless":
		var ids := Meta.unlock_ids()
		if not ids.is_empty():
			_open_unlock_confirm(String(ids[0]))


## §5.1 图标三段 resolver：顺序不能反
## ① ICON_RECTS 原图集 → ② generated 直名 → ③ generated/icon_<k>
func meta_icon(k: String) -> Texture2D:
	if Assets.ICON_RECTS.has(k):
		return Assets.icon(k)
	var t := Assets.g(k)
	if t:
		return t
	return Assets.g("icon_" + k)


## 一行解锁项：图标 / 名称 / 描述 / 状态 / 解锁按钮
func _add_unlock_row(parent: Node, id: String) -> void:
	var n: Dictionary = Meta.node(id)
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 10)
	parent.add_child(row)

	var t := meta_icon(String(n.get("icon", id)))
	if t != null and t != Assets.white_tex:
		_unlock_icons_ok += 1
	else:
		Dev.warn("meta", "解锁页图标解析失败（静默白框）：%s" % id)
	var tex: Texture2D = t if t != null else Assets.white_tex
	var icon_rect := TextureRect.new()
	icon_rect.texture = tex
	icon_rect.custom_minimum_size = Vector2(32, 32)
	icon_rect.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	icon_rect.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	row.add_child(icon_rect)

	var name_l := Label.new()
	name_l.text = String(n.get("name", id))
	name_l.custom_minimum_size = Vector2(110, 0)
	name_l.add_theme_font_size_override("font_size", 17)
	row.add_child(name_l)

	var desc := Label.new()
	desc.text = String(n.get("desc", ""))
	desc.custom_minimum_size = Vector2(240, 0)
	desc.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	desc.add_theme_font_size_override("font_size", 13)
	desc.add_theme_color_override("font_color", Color(0.78, 0.78, 0.84))
	row.add_child(desc)

	var cost := int(n.get("cost", 0))
	var owned := Game.meta_is_unlocked(id)
	var req_ok := true
	for r in n.get("requires", []):
		if not Game.meta_is_unlocked(String(r)):
			req_ok = false
	var state := Label.new()
	state.custom_minimum_size = Vector2(104, 0)
	state.add_theme_font_size_override("font_size", 14)
	if owned:
		state.text = "已解锁"
		state.add_theme_color_override("font_color", Color(0.55, 0.95, 0.6))
	elif not req_ok:
		state.text = "前置未满足"
		state.add_theme_color_override("font_color", Color(0.6, 0.6, 0.65))
	elif Game.meta_crystals() < cost:
		state.text = "需要 %d（还差 %d）" % [cost, cost - Game.meta_crystals()]
		state.add_theme_color_override("font_color", Color(0.88, 0.55, 0.48))
	else:
		state.text = "可解锁 · %d 结晶" % cost
		state.add_theme_color_override("font_color", Color(1.0, 0.85, 0.45))
	row.add_child(state)

	var btn := Button.new()
	btn.text = "已解锁" if owned else "解锁"
	btn.disabled = owned or not req_ok or Game.meta_crystals() < cost
	btn.custom_minimum_size = Vector2(86, 32)
	btn.add_theme_font_size_override("font_size", 15)
	btn.pressed.connect(func() -> void: _try_unlock(id))
	row.add_child(btn)


## 购买解锁：先二次确认，确认后才由 Game.meta_unlock 校验与落盘
func _try_unlock(id: String) -> void:
	# headless / SMOKE 回归绝不弹窗（会卡住自动化）；带窗口视觉走查用 SMOKE_UI_CONFIRM 显式打开
	if _skip_confirm():
		_do_unlock(id)
		return
	_open_unlock_confirm(id)


func _skip_confirm() -> bool:
	if OS.get_environment("SMOKE") == "":
		return false
	if OS.get_environment("SMOKE_UI_CONFIRM") != "" and DisplayServer.get_name() != "headless":
		return false
	return true


func _open_unlock_confirm(id: String) -> void:
	_close_confirm()
	var n: Dictionary = Meta.node(id)
	var d := ConfirmationDialog.new()
	d.title = "确认解锁？"
	d.dialog_text = "解锁「%s」将花费 %d 结晶，确认后不可撤销" % [
		String(n.get("name", id)), int(n.get("cost", 0))]
	d.ok_button_text = "确认解锁"
	d.cancel_button_text = "取消"
	add_child(d)
	_confirm = d
	d.confirmed.connect(func() -> void: _do_unlock(id))
	d.canceled.connect(_close_confirm)
	d.close_requested.connect(_close_confirm)
	d.popup_centered()


func _close_confirm() -> void:
	if _confirm != null and is_instance_valid(_confirm):
		_confirm.hide()
		_confirm.queue_free()
	_confirm = null


func _do_unlock(id: String) -> void:
	_close_confirm()
	if Game.meta_unlock(id):
		Game.sfx("powerup")
	else:
		Game.sfx("pickup", 0.7, -6.0)
	show_page("unlocks")


func _add_button(text: String, cb: Callable) -> void:
	var b := Button.new()
	b.text = text
	b.custom_minimum_size = Vector2(240, 44)
	b.add_theme_font_size_override("font_size", 20)
	var bg := StyleBoxFlat.new()
	bg.bg_color = Color(0.14, 0.13, 0.18, 0.95)
	bg.border_color = Color(0.55, 0.4, 0.22)
	bg.set_border_width_all(2)
	bg.set_corner_radius_all(4)
	bg.content_margin_top = 8
	bg.content_margin_bottom = 8
	b.add_theme_stylebox_override("normal", bg)
	var hov: StyleBoxFlat = bg.duplicate()
	hov.bg_color = Color(0.23, 0.21, 0.27, 0.98)
	hov.border_color = Color(1.0, 0.75, 0.35)
	b.add_theme_stylebox_override("hover", hov)
	var prs: StyleBoxFlat = bg.duplicate()
	prs.bg_color = Color(0.30, 0.25, 0.18, 1.0)
	prs.border_color = Color(1.0, 0.85, 0.45)
	b.add_theme_stylebox_override("pressed", prs)
	b.pressed.connect(cb)
	_rows.add_child(b)


func _add_slider(label: String, key: String) -> void:
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 12)
	_rows.add_child(row)
	var l := Label.new()
	l.text = label
	l.custom_minimum_size = Vector2(120, 0)
	l.add_theme_font_size_override("font_size", 18)
	row.add_child(l)
	var s := HSlider.new()
	s.min_value = 0.0
	s.max_value = 1.0
	s.step = 0.05
	s.value = clampf(float(Game.settings.get(key, 1.0)), 0.0, 1.0)
	s.custom_minimum_size = Vector2(220, 26)
	row.add_child(s)
	var val := Label.new()
	val.text = "%d%%" % int(s.value * 100.0)
	val.custom_minimum_size = Vector2(60, 0)
	val.add_theme_font_size_override("font_size", 16)
	row.add_child(val)
	s.value_changed.connect(func(v: float) -> void:
		_set_setting(key, v)
		val.text = "%d%%" % int(v * 100.0))


## 下拉选项：values 为 settings 存储值，labels 为显示文本；切换即应用并保存
func _add_option(label: String, key: String, values: Array, labels: Array) -> void:
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 12)
	_rows.add_child(row)
	var l := Label.new()
	l.text = label
	l.custom_minimum_size = Vector2(120, 0)
	l.add_theme_font_size_override("font_size", 18)
	row.add_child(l)
	var o := OptionButton.new()
	for i in values.size():
		o.add_item(String(labels[i]), i)
	var cur: int = int(Game.settings.get(key, values[0])) if key == "window_mode" \
		else values.find(String(Game.settings.get(key, values[0])))
	o.selected = maxi(cur, 0)
	o.custom_minimum_size = Vector2(220, 30)
	row.add_child(o)
	o.item_selected.connect(func(idx: int) -> void: _set_setting(key, values[idx]))


func _add_toggle(label: String, key: String) -> void:
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 12)
	_rows.add_child(row)
	var l := Label.new()
	l.text = label
	l.custom_minimum_size = Vector2(120, 0)
	l.add_theme_font_size_override("font_size", 18)
	row.add_child(l)
	var c := CheckButton.new()
	c.button_pressed = bool(Game.settings.get(key, false))
	row.add_child(c)
	c.toggled.connect(func(on: bool) -> void: _set_setting(key, on))


func _set_setting(key: String, v) -> void:
	Game.settings[key] = v
	Game.apply_settings()
	Game.save_settings()


## 开始游戏：收起菜单、解除暂停并重开一局
func start_game() -> void:
	_root.visible = false
	_page = ""
	get_tree().paused = false
	if Game.main != null and is_instance_valid(Game.main):
		Game.main.start_run()
