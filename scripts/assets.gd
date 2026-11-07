extends Node
## 素材工厂：把现有图集切成帧，集中管理所有 rect 常量。
## 图集行号/列号标定有误时，只改这个文件。

const T_W := preload("res://resources/texture/W.png")
const T_SLUG := preload("res://resources/texture/源石虫.png")
const T_TURRET := preload("res://resources/texture/浮游炮.png")
const T_BOOM := preload("res://resources/texture/爆炸特效.png")
const T_TILES := preload("res://resources/texture/瓦片.png")
const T_DYN := preload("res://resources/texture/动态瓦片.png")
const T_UI := preload("res://resources/texture/道具ui.png")
const T_ENEMY2 := preload("res://resources/texture/generated/虫群2.png")

const SFX := {
	"shoot": preload("res://resources/audio/Cowboy_gunshot.wav"),
	"reload": preload("res://resources/audio/cowboy_gunload.wav"),
	"boom": preload("res://resources/audio/cowboy_explosion.wav"),
	"hit": preload("res://resources/audio/cowboy_monsterhit.wav"),
	"die": preload("res://resources/audio/cowboy_monsterdie.wav"),
	"player_die": preload("res://resources/audio/cowboy_dead.wav"),
	"pickup": preload("res://resources/audio/cowboy_gopher.wav"),
	"powerup": preload("res://resources/audio/cowboy_powerup.wav"),
	"secret": preload("res://resources/audio/Cowboy_Secret.wav"),
	# Sprint 11 B：Boss 音效别名（走注册表，复用既有 wav——audio-director 口径）
	"boss_intro": preload("res://resources/audio/Cowboy_Secret.wav"),
	"boss_phase": preload("res://resources/audio/cowboy_powerup.wav"),
	"boss_skill": preload("res://resources/audio/cowboy_gunload.wav"),
	# Sprint 13 E：圣所 / 灾祸事件别名（同口径复用既有 wav）
	"shrine": preload("res://resources/audio/Cowboy_Secret.wav"),
	"calamity": preload("res://resources/audio/cowboy_explosion.wav"),
}

const MUSIC := [
	preload("res://resources/audio/1-27 Journey of the Prairie King (Overworld).mp3"),
	preload("res://resources/audio/1-28 Journey of the Prairie King (The Outlaw).mp3"),
	preload("res://resources/audio/1-29 Journey of the Prairie King (Final Boss & Ending).mp3"),
]

# ---- W 图集：160x288，5×9 格 32px；第 0-3 列是动画帧 ----
const W_CELL := 32
const W_ROW_IDLE := 2
const W_ROW_WALK_DOWN := 0
const W_ROW_WALK_UP := 3
const W_ROW_SIDE := 6
const W_ROW_ATTACK := 1
const W_ROW_DIE := 8

# ---- 源石虫图集：96x192，3×6 格 32px；每行一种变体，3 帧行走 ----
const S_CELL := 32
const S_ROW_RUSHER := 0
const S_ROW_BRUTE := 1
const S_ROW_SPIT := 2
const S_ROW_ELITE := 3
const S_ROW_BOMBER := 4
const S_ROW_GIB := 5

# ---- 道具 ui：64x80，4×5 格 16px ----
const ICON_RECTS := {
	"clock": Rect2(0, 0, 16, 16),
	"face": Rect2(0, 16, 16, 16),
	"dot": Rect2(16, 16, 16, 16),
	"boots": Rect2(0, 32, 16, 16),
	"ears": Rect2(16, 32, 16, 16),
	"diamond": Rect2(32, 32, 16, 16),
	"bunny": Rect2(0, 48, 16, 16),
	"cards": Rect2(16, 48, 16, 16),
	"chest": Rect2(32, 48, 16, 16),
	"bomb": Rect2(0, 64, 16, 16),
	"book": Rect2(16, 64, 16, 16),
	"gold": Rect2(32, 64, 16, 16),
}
const HP_BAR_RECT := Rect2(16, 1, 48, 14)

# ---- 爆炸特效：240x48，5 帧 48px：尘点/闪光/中爆/大爆/烟雾 ----
const BOOM_FRAME := 48

# ---- 动态瓦片：64x96，2×6 格 32x16 ----
const DYN_CRATE := [Rect2(0, 80, 32, 16), Rect2(32, 80, 32, 16)]
const DYN_ALARM := [Rect2(0, 0, 32, 16), Rect2(32, 0, 32, 16)]
const DYN_SCREEN := [Rect2(0, 64, 32, 16), Rect2(32, 64, 32, 16)]

# ---- 瓦片：64x64，4×4 格 16px ----
const TILE_FLOORS := [Vector2i(0, 0), Vector2i(1, 1), Vector2i(1, 2), Vector2i(0, 1), Vector2i(0, 2)]
const TILE_FLOOR_WEIGHTS := [4, 2, 2, 2, 1]
const TILE_HAZARD := Vector2i(2, 1)
const TILE_CABLE := Vector2i(2, 2)
const TILE_TRIM := Vector2i(2, 3)
const TILE_WALL := Vector2i(3, 2)
const TILE_VOID := Vector2i(3, 0)

# 浮游炮帧区（48x32 单元格内：左侧大炮体 + 右侧小型炮体）
const TURRET_FRAME_A := Rect2(2, 1, 12, 30)
const TURRET_FRAME_A2 := Rect2(50, 1, 12, 30)
const TURRET_SHOT_RECT := Rect2(34, 2, 12, 18)

var _cache := {}
var _font: FontFile
var white_tex: ImageTexture
var gen := {}  # 自绘扩展素材（generated/）
var monsters := {}  # CC0 怪物贴图（monsters/，源自 Tiny Creatures）

const MONSTER_NAMES := [
	"goblin", "skeleton", "zombie", "orc", "imp", "wraith", "flameskull", "faerie",
	"vampire", "plant", "mush", "slime", "wolf",
	"knight", "ogre", "minotaur", "beholder",
	"skeleton_king", "demon", "dragon", "shadow",
]

const GEN_NAMES := [
	"wpn_rifle", "wpn_shotgun", "wpn_railgun", "wpn_launcher",
	"door_closed", "door_open", "stairs", "chest_closed", "chest_open", "pedestal",
	"relic_fang", "relic_thorn", "relic_bounce", "relic_frost", "relic_bigbullet",
	"relic_mag", "relic_eye", "relic_radar", "relic_drone", "relic_heart",
	# 第二轮扩展：道具 / 商人皮肤 / 图标
	"prop_barrel", "prop_barrel_hit", "prop_totem", "prop_spike", "prop_pillar", "secret_wall",
	"merchant_0", "merchant_1", "merchant_2",
	"icon_chain", "icon_guard", "icon_dice", "icon_venom",
	# Sprint 4：挑战因子 / 源石共鸣 / 词缀头顶标记
	"icon_resonance",
	"icon_mod_rage", "icon_mod_barren", "icon_mod_overload", "icon_mod_glass",
	"icon_mod_swarm", "icon_mod_silent",
	"icon_affix_swift", "icon_affix_armor", "icon_affix_boom",
	"icon_affix_death", "icon_affix_ranged", "icon_affix_shield", "icon_affix_mender",
	# Sprint 7：局外解锁内容专用图标（PNG 已生成，未登记 = Assets.g() 返回 null → 静默白框）
	"icon_pierce", "icon_crit", "wpn_swarm", "wpn_arc",
	# Sprint 11：反应词缀拾取标记（F2/A）
	"icon_suffix",
	# Sprint 11 B：棱镜守望者（核心墨黑 + 绕转碎片 + 死亡碎裂，碎片色运行期按主题 tint）
	"boss_prism_core", "boss_prism_shard", "boss_prism_death_shard",
]


func _enter_tree() -> void:
	_register_inputs()


func _ready() -> void:
	_font = load("res://resources/font/IPix.ttf")
	if _font:
		_font.antialiasing = TextServer.FONT_ANTIALIASING_NONE
		_font.subpixel_positioning = TextServer.SUBPIXEL_POSITIONING_DISABLED
	var img := Image.create(4, 4, false, Image.FORMAT_RGBA8)
	img.fill(Color.WHITE)
	white_tex = ImageTexture.create_from_image(img)
	for m in MUSIC:
		m.loop = true
	for n in GEN_NAMES:
		gen[n] = load("res://resources/texture/generated/%s.png" % n)
		if gen[n] == null:
			push_warning("[assets] 素材加载失败：generated/%s.png" % n)
	for n in MONSTER_NAMES:
		monsters[n] = load("res://resources/texture/monsters/%s.png" % n)


func monster(name: String) -> Texture2D:
	return monsters.get(name)


## 单帧怪物动画：walk/die 各一帧（Bob 由代码做），保持与源石虫接口一致
func monster_frames(name: String) -> SpriteFrames:
	var key := "mon_" + name
	if _cache.has(key):
		return _cache[key]
	var f := SpriteFrames.new()
	f.remove_animation("default")
	var tex: Texture2D = monster(name)
	if tex == null:
		tex = white_tex
	f.add_animation("walk")
	f.add_frame("walk", tex)
	f.add_animation("die")
	f.add_frame("die", tex)
	_cache[key] = f
	return f


func g(name: String) -> Texture2D:
	return gen.get(name)


func font() -> FontFile:
	return _font


func theme() -> Theme:
	var th := Theme.new()
	if _font:
		th.default_font = _font
		th.default_font_size = 16
	return th


func at(tex: Texture2D, rect: Rect2) -> AtlasTexture:
	var a := AtlasTexture.new()
	a.atlas = tex
	a.region = rect
	return a


func icon(key: String) -> AtlasTexture:
	return at(T_UI, ICON_RECTS[key])


func w_rect(col: int, row: int) -> Rect2:
	return Rect2(col * W_CELL, row * W_CELL, W_CELL, W_CELL)


func slug_rect(col: int, row: int) -> Rect2:
	return Rect2(col * S_CELL, row * S_CELL, S_CELL, S_CELL)


## 玩家 W 的全套动画
func w_frames() -> SpriteFrames:
	if _cache.has("w"):
		return _cache["w"]
	var f := SpriteFrames.new()
	f.remove_animation("default")
	_add_anim(f, T_W, "idle", [w_rect(0, W_ROW_IDLE), w_rect(1, W_ROW_IDLE)], 3.0, true)
	_add_anim(f, T_W, "walk_down", _row_rects(W_ROW_WALK_DOWN), 12.0, true)
	_add_anim(f, T_W, "walk_up", _row_rects(W_ROW_WALK_UP), 12.0, true)
	_add_anim(f, T_W, "walk_side", _row_rects(W_ROW_SIDE), 12.0, true)
	_add_anim(f, T_W, "attack", _row_rects(W_ROW_ATTACK), 12.0, false)
	_add_anim(f, T_W, "die", _row_rects(W_ROW_DIE), 6.0, false)
	_cache["w"] = f
	return f


func _row_rects(row: int) -> Array:
	return [w_rect(0, row), w_rect(1, row), w_rect(2, row), w_rect(3, row)]


## 源石虫变体动画（walk 3 帧 + 共用死亡帧）
func slug_frames(row: int) -> SpriteFrames:
	var key := "slug_%d" % row
	if _cache.has(key):
		return _cache[key]
	var f := SpriteFrames.new()
	f.remove_animation("default")
	_add_anim(f, T_SLUG, "walk", [slug_rect(0, row), slug_rect(1, row), slug_rect(2, row)], 8.0, true)
	_add_anim(f, T_SLUG, "die", [slug_rect(0, S_ROW_GIB), slug_rect(1, S_ROW_GIB), slug_rect(2, S_ROW_GIB)], 10.0, false)
	_cache[key] = f
	return f


## 第二轮新敌人图集：3 帧行走 + 共用死亡帧（第 6 行）
func enemy2_frames(row: int) -> SpriteFrames:
	var key := "enemy2_%d" % row
	if _cache.has(key):
		return _cache[key]
	var f := SpriteFrames.new()
	f.remove_animation("default")
	_add_anim(f, T_ENEMY2, "walk", [
		Rect2(0, row * 32, 32, 32), Rect2(32, row * 32, 32, 32), Rect2(64, row * 32, 32, 32)], 9.0, true)
	_add_anim(f, T_ENEMY2, "die", [
		Rect2(0, 5 * 32, 32, 32), Rect2(32, 5 * 32, 32, 32), Rect2(64, 5 * 32, 32, 32)], 10.0, false)
	_cache[key] = f
	return f


## 扩展图标：优先 generated/icon_*.png，其次原图集
func xicon(key: String) -> Texture2D:
	var t: Texture2D = g("icon_" + key)
	if t:
		return t
	if ICON_RECTS.has(key):
		return icon(key)
	push_warning("[assets] 图标缺失：%s" % key)
	return white_tex


## 爆炸：spark（枪口/命中）与 blast（炸弹）
func boom_frames() -> SpriteFrames:
	if _cache.has("boom"):
		return _cache["boom"]
	var f := SpriteFrames.new()
	f.remove_animation("default")
	_add_anim(f, T_BOOM, "spark", [Rect2(0, 0, BOOM_FRAME, BOOM_FRAME), Rect2(BOOM_FRAME, 0, BOOM_FRAME, BOOM_FRAME)], 20.0, false)
	_add_anim(f, T_BOOM, "blast", [
		Rect2(BOOM_FRAME * 2, 0, BOOM_FRAME, BOOM_FRAME),
		Rect2(BOOM_FRAME * 3, 0, BOOM_FRAME, BOOM_FRAME),
		Rect2(BOOM_FRAME * 4, 0, BOOM_FRAME, BOOM_FRAME),
	], 14.0, false)
	_cache["boom"] = f
	return f


func turret_frames() -> SpriteFrames:
	if _cache.has("turret"):
		return _cache["turret"]
	var f := SpriteFrames.new()
	f.remove_animation("default")
	_add_anim(f, T_TURRET, "hover", [TURRET_FRAME_A, TURRET_FRAME_A2], 5.0, true)
	_cache["turret"] = f
	return f


func crate_tex(frame: int) -> AtlasTexture:
	return at(T_DYN, DYN_CRATE[clampi(frame, 0, 1)])


func alarm_frames() -> SpriteFrames:
	if _cache.has("alarm"):
		return _cache["alarm"]
	var f := SpriteFrames.new()
	f.remove_animation("default")
	_add_anim(f, T_DYN, "blink", [DYN_ALARM[0], DYN_ALARM[1]], 2.0, true)
	_cache["alarm"] = f
	return f


func screen_frames() -> SpriteFrames:
	if _cache.has("screen"):
		return _cache["screen"]
	var f := SpriteFrames.new()
	f.remove_animation("default")
	_add_anim(f, T_DYN, "flicker", [DYN_SCREEN[0], DYN_SCREEN[1]], 3.0, true)
	_cache["screen"] = f
	return f


func _add_anim(f: SpriteFrames, tex: Texture2D, anim: String, rects: Array, fps: float, looped: bool) -> void:
	f.add_animation(anim)
	f.set_animation_speed(anim, fps)
	f.set_animation_loop(anim, looped)
	for r in rects:
		f.add_frame(anim, r if r is Texture2D else at(tex, r))


## 动作总表：注册、重绑定、持久化的唯一数据源。
## name=设置页显示名；keys=默认物理键；mouse=默认鼠标键；kb/mb=允许键盘/鼠标重绑
const ACTION_DEFS := {
	"move_up": {"name": "上移", "keys": [KEY_W, KEY_UP], "mouse": [], "kb": true, "mb": false},
	"move_down": {"name": "下移", "keys": [KEY_S, KEY_DOWN], "mouse": [], "kb": true, "mb": false},
	"move_left": {"name": "左移", "keys": [KEY_A, KEY_LEFT], "mouse": [], "kb": true, "mb": false},
	"move_right": {"name": "右移", "keys": [KEY_D, KEY_RIGHT], "mouse": [], "kb": true, "mb": false},
	"shoot": {"name": "射击", "keys": [], "mouse": [MOUSE_BUTTON_LEFT], "kb": true, "mb": true},
	"bomb": {"name": "炸弹", "keys": [], "mouse": [MOUSE_BUTTON_RIGHT], "kb": true, "mb": true},
	"skill": {"name": "技能·过载", "keys": [KEY_SPACE], "mouse": [], "kb": true, "mb": true},
	"swap": {"name": "切换武器", "keys": [KEY_Q], "mouse": [], "kb": true, "mb": true},
	"reload": {"name": "换弹", "keys": [KEY_R], "mouse": [], "kb": true, "mb": true},
	"buy": {"name": "商店购买", "keys": [KEY_E], "mouse": [], "kb": true, "mb": true},
	"card_1": {"name": "升级卡 1", "keys": [KEY_1], "mouse": [], "kb": true, "mb": true},
	"card_2": {"name": "升级卡 2", "keys": [KEY_2], "mouse": [], "kb": true, "mb": true},
	"card_3": {"name": "升级卡 3", "keys": [KEY_3], "mouse": [], "kb": true, "mb": true},
	"pause": {"name": "暂停", "keys": [KEY_ESCAPE], "mouse": [], "kb": true, "mb": false},
	# F2 主动遗物（默认 F/Z/X/C，均可在设置页重绑；坑 5 护栏已核：F/Z/X/C 无占用）
	"relic_shield": {"name": "遗物·环盾", "keys": [KEY_F], "mouse": [], "kb": true, "mb": true},
	"relic_dash": {"name": "遗物·冲刺", "keys": [KEY_Z], "mouse": [], "kb": true, "mb": false},
	"relic_volley": {"name": "遗物·齐射", "keys": [KEY_X], "mouse": [], "kb": true, "mb": true},
	"relic_toxic": {"name": "遗物·毒云", "keys": [KEY_C], "mouse": [], "kb": true, "mb": false},
}


func _register_inputs() -> void:
	for action in ACTION_DEFS:
		var def: Dictionary = ACTION_DEFS[action]
		_key(action, def["keys"])
		_mouse(action, def["mouse"])


func _key(action: String, keys: Array) -> void:
	if not InputMap.has_action(action):
		InputMap.add_action(action)
	for k in keys:
		var ev := InputEventKey.new()
		ev.physical_keycode = k
		InputMap.action_add_event(action, ev)


func _mouse(action: String, btns: Array) -> void:
	if not InputMap.has_action(action):
		InputMap.add_action(action)
	for b in btns:
		var ev := InputEventMouseButton.new()
		ev.button_index = b
		InputMap.action_add_event(action, ev)


# ---------------- 按键重绑定 ----------------

## 事件序列化码："k:87"（物理键码）/ "m:1"（鼠标键索引）
func event_code(ev: InputEvent) -> String:
	if ev is InputEventKey:
		return "k:%d" % ev.physical_keycode
	if ev is InputEventMouseButton:
		return "m:%d" % ev.button_index
	return ""


func event_from_code(code: String) -> InputEvent:
	var parts := code.split(":")
	if parts.size() != 2:
		return null
	if parts[0] == "k":
		var kev := InputEventKey.new()
		kev.physical_keycode = int(parts[1]) as Key
		return kev
	if parts[0] == "m":
		var mev := InputEventMouseButton.new()
		mev.button_index = int(parts[1]) as MouseButton
		return mev
	return null


func event_label(ev: InputEvent) -> String:
	if ev is InputEventKey:
		match ev.physical_keycode:
			KEY_SPACE: return "空格"
			KEY_UP: return "↑"
			KEY_DOWN: return "↓"
			KEY_LEFT: return "←"
			KEY_RIGHT: return "→"
			KEY_ESCAPE: return "Esc"
			KEY_ENTER, KEY_KP_ENTER: return "回车"
			KEY_TAB: return "Tab"
			KEY_SHIFT: return "Shift"
			KEY_CTRL: return "Ctrl"
			KEY_ALT: return "Alt"
			_:
				var s := OS.get_keycode_string(ev.physical_keycode)
				return s if s != "" else "键%d" % ev.physical_keycode
	if ev is InputEventMouseButton:
		match ev.button_index:
			MOUSE_BUTTON_LEFT: return "鼠标左键"
			MOUSE_BUTTON_RIGHT: return "鼠标右键"
			MOUSE_BUTTON_MIDDLE: return "鼠标中键"
			_: return "鼠标%d" % ev.button_index
	return "???"


## 当前动作的显示标签（多个事件用 / 连接）
func action_label(action: String) -> String:
	var parts := []
	for ev in InputMap.action_get_events(action):
		var l := event_label(ev)
		if l != "???" and not parts.has(l):
			parts.append(l)
	if parts.is_empty():
		return "未设置"
	return "/".join(parts)


## 某个事件码当前被哪个动作占用（不含 except_action）；返回动作名或 ""
func code_owner(code: String, except_action := "") -> String:
	for action in ACTION_DEFS:
		if action == except_action:
			continue
		for ev in InputMap.action_get_events(action):
			if event_code(ev) == code:
				return action
	return ""


## 重绑定：把 action 的全部事件替换为 ev。
## 返回 "" 成功；返回占用动作的显示名 = 冲突被拒；"键盘禁用"/"鼠标禁用" = 该动作不允许此输入类型。
func rebind_action(action: String, ev: InputEvent) -> String:
	var def: Dictionary = ACTION_DEFS.get(action, {})
	if ev is InputEventKey and not def.get("kb", true):
		return "此动作不接受键盘"
	if ev is InputEventMouseButton and not def.get("mb", true):
		return "此动作不接受鼠标"
	var code := event_code(ev)
	if code == "":
		return "无效事件"
	var owner := code_owner(code, action)
	if owner != "":
		return ACTION_DEFS[owner]["name"]
	InputMap.action_erase_events(action)
	InputMap.action_add_event(action, ev)
	return ""


## 恢复全部默认绑定
func reset_bindings() -> void:
	for action in ACTION_DEFS:
		var def: Dictionary = ACTION_DEFS[action]
		InputMap.action_erase_events(action)
		_key(action, def["keys"])
		_mouse(action, def["mouse"])


## 持久化：动作 → 第一个事件的码
func bindings_codes() -> Dictionary:
	var out := {}
	for action in ACTION_DEFS:
		var evs := InputMap.action_get_events(action)
		if evs.size() > 0:
			out[action] = event_code(evs[0])
	return out


## 从存档恢复（未知动作/坏码静默跳过，保留默认）
func apply_bindings(dict: Dictionary) -> void:
	for action in dict:
		if not ACTION_DEFS.has(action):
			continue
		var ev := event_from_code(str(dict[action]))
		if ev:
			InputMap.action_erase_events(action)
			InputMap.action_add_event(action, ev)
