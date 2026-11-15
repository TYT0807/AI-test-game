# SPR27 批二 · 探针骨架（`SMOKE_OATH_GRANT`，43 条）

> 配套：`SPR27_批二验证口径.md`（口径与编号权威）· `SPR27_批二实施单_编程侧.md`（代码落点权威）。
> **本文件是骨架，不是最终代码**：结构、构造、期望值、打印格式已定死；实施方照填即可，**不许改条数、不许改 `#NN` 顺序、不许把 `#NN` 加在旁证行上**。
> **三条命令式要求**（缺一条门控就假绿）：
> 1. **43 个 `#NN`，一行一个**，且每条后**无条件**打印实测值（不靠 `Dev.check` 失败才输出——`dev_log.gd:29-32` 只在失败时 `err()`）。
> 2. **入口与末尾各有一次 `checked/declared` 自校验**（`declared` 是字面量 `43`，不是公式）。
> 3. **带括号的 `_oath_grant()` 字面调用点全仓恰 1 处（`start_run` 内）**——探针走 `call(&"_oath_grant")` 单一漏斗，且探针源码里不写带括号字面量（用 `_OG_SYM_GRANT` 拼接），故 `C08` 的全仓计数不被探针污染。**这是 C08 静态门与本骨架的对齐点，改骨架时不许破坏**。

---

## 0. 挂载片段（唯一一次，插在 `game_main.gd:248` 之后）

```gdscript
		if OS.get_environment("SMOKE_CAL_THEME") != "":
			_smoke_cal_theme_probe()
		if OS.get_environment("SMOKE_OATH_GRANT") != "":
			_test_oath_grant()
```
`_ready` 里 `start_run()` 在 `:200`、`_smoke` 块自 `:202` 起 → **探针运行时 `hud`/`player`/`dungeon` 都已存在**，可直接读 `hud._diamond_label.text`、`hud._toast.text`（`hud` 在 `:161` 建一次，`start_run` **不重建**，E 组跑完仍可用）。
**开关必须与 `SMOKE_META_FINGERPRINT` 互斥**（E 组 8 次 `start_run` 会打出 8+ 行 `fingerprint`）。
🔴 **探针代码追加在文件末尾（`start_run` 之后）**，且**探针里不许出现字面 `_oath_grant()`**（连字符串也不行，一律用 `_OG_SYM_GRANT := "_oath" + "_grant()"` 拼接）：
- `E04/E05` 的锚点只在 **`start_run()` 函数体范围内**定位（`_og_start_run_body()`），追加在末尾 ⇒ 天然落在范围外，不吃自己的子串；
- `C08` 走**全仓**扫描且**不截断探针**：探针若图省事写了字面调用，这里就该读出 2 → **C08 自己判红**。这是纪律（"授予入口只有一处"），不是误报，所以不能用"截断探针"把它盖掉。

---

## 1. 常量与字段

```gdscript
const _OG_DECLARED := 43
const _OG_SENTINEL := "__OG_SENTINEL__"
const _OG_PLAIN_SEED := 12345      # 实测该 seed 不走 barren（§0.4 实验 D：默认档开局 3）
const _OG_E2E_SEED := 777          # 实测该 seed 掷出 modifier=barren（§0.4 实验 E：13）

var _og_checked := 0
var _og_sig_cnt := 0               # diamonds_changed 触发次数
var _og_sig_last := -999999        # 末次实参
var _og_wire_fail := 0             # 探针是否接上授予函数（call() 无静态检查，必须运行期自证）
var _og_src: PackedStringArray = []   # game_main.gd 源码行（C08/E04/E05 用）
var _og_body := Vector2i(-1, -1)      # start_run 函数体 [首行, 末行]（1-based）；E04/E05 只在此范围定位
var _og_snap := {}
```

**扫描用符号常量**（🔴 拼接构造，探针源码里不许出现字面 `_oath_grant()`，否则 C08 会数到自己）：

```gdscript
const _OG_SYM_GRANT := "_oath" + "_grant()"   # 值即 _oath_grant 的带括号形式，但源码里不构成字面调用
```

**协议常量**（`_oath_grant()` 产物，D 组逐字比）：

```gdscript
const _OG_TAG := "誓约遗赠"          # 必须等于生产常量 _OG_TOAST_TAG 的字面值
```

---

## 2. 43 条清单（执行顺序 = `#NN` 顺序，**冻结**）

| #NN | ID | 构造（一句话） | 期望实测值 |
|---|---|---|---|
| #01 | A01 | `_oath_grant_amount(0)` | `0` |
| #02 | A02 | `amount(1)` | `3` |
| #03 | A03 | `amount(2)` | `5` |
| #04 | A04 | `amount(3)` | `8` |
| #05 | A05 | `amount(4)` | `8` |
| #06 | A06 | `amount(99)` | `8` |
| #07 | A07 | `amount(-1)` | `0` |
| #08 | A08 | `s ∈ [-2..10]` 13 点逐点手写期望 | 13 点全等 |
| #09 | A09 | `s ∈ [-2..12]` 取值去重 | `{0,3,5,8}` |
| #10 | B01 | `oath` 非空、**无** `oath_streak` 键 | `diamonds` 不动 |
| #11 | B02 | `oath_streak="3"`（字符串） | 不动（并打印 `naive_int=3`） |
| #12 | B03 | `oath_streak=2.9` | `+5` |
| #13 | B04 | `oath_streak=true` | 不动 |
| #14 | B05 | `oath_streak=-5` | 不动 |
| #15 | B06 | `oath_streak=null` | 不动 |
| #16 | B07 | 🔴 `oath` **缺键** + `streak=3`（棘轮） | **不动**（漏守卫仅此条红） |
| #17 | B08 | `oath` 非空 + `streak=0`（未兑现） | 不动且 `diamonds>=0` |
| #18 | B09 | 基线 **7** + `streak=3` | `15`（抓覆盖式写） |
| #19 | B10 | purse 真实路径：`X`(streak=0) / `Y`(streak=3) | `Y-X==8` 且 `X>=15` |
| #20 | C01 | 授予后信号：触发次数 + 末次实参 | `cnt>=1` 且 `last==diamonds` |
| #21 | C02 | `run_diamonds_earned` Δ | `0` |
| #22 | C03 | `_oath_counters["diamonds_picked"]` Δ | `0` |
| #23 | C04 | `_reso_pickups` Δ **且** `resonance` Δ（`has_resocore=true`） | 两个 Δ 都 `0` |
| #24 | C05 | `daily_mode=true` → 授予 | `diamonds` 不动且 toast 未变 |
| #25 | C06 | `daily_mode=false` → 授予 | `+8` |
| #26 | C07 | 两次完整 `start_run()`（rng seed+state 双还原） | 两次 `diamonds` 相等 |
| #27 | C08 | 源码扫描：`_oath_grant()` 调用点计数 | `== 1` |
| #28 | C09 | 先 `streak=3` 授予，再 `streak=1` 授予 | 第二次 Δ `== 3` |
| #29 | G01 | 🔴 **真实 `hud._diamond_label.text`**（不 mock、不读缓存字段）数字 == `Game.diamonds` | `label == "15"`（基线 7） |
| #30 | D01 | 授予后 toast 文本 | `begins_with("誓约遗赠")` |
| #31 | D02 | `streak=2` → 文本 | 含 `"2 局"` |
| #32 | D03 | `streak=2` → 文本 | 含 `"+5"` |
| #33 | D04 | `streak=0` → 哨兵法 | 文本仍为 `__OG_SENTINEL__` |
| #34 | D05 | `"誓约遗赠"` vs `Data.OATH_CONDITIONS[*].name` | 与任何 name 都不等 |
| #35 | F01 | 授予前后 `Game.rng.seed` / `Game.fx_rng.seed` | 都不变 |
| #36 | F02 | `amount(3)` 连调两次 | 相等（静态半边由 grep 闭合） |
| #37 | E01 | 真实 `start_run()`：控制组(streak=0) vs 处理组(streak=3) | `Δ==8` |
| #38 | E02 | 同上但带 purse | `Δ==8` 且 `X>=15` |
| #39 | E03 | 同上、seed 777（barren） | `Δ==8`（并打印 `modifier`） |
| #40 | E04 | `start_run()` 函数体内：grant 调用行 **>** `_apply_sigil_contract()` 调用行 | 成立（函数体内定位） |
| #41 | E05 | `start_run()` 函数体内：grant 调用行 **<** `Game.run_seed = Game.rng.seed` 行 | 成立（函数体内定位） |
| #42 | E06 | 控制/处理两次 `Game.run_seed` | 字符串相等 |
| #43 | E07 | 控制/处理两次「层1 rooms 序 + kinds 序」 | 逐字相等 |

> **`#NN` 与 ID 的固定映射**：A `#01-#09` · B `#10-#19` · C `#20-#28` · **G `#29`** · D `#30-#34` · F `#35-#36` · E `#37-#43`。
> **C01 与 G01 分开、不合并**（主理人 v3 收回原合并裁定）：C01 断信号（因）、G01 断真实标签（果），**红了能分清是哪一层坏**。两条在刀三/刀九下同时红，这正是它们成对存在的理由。
> **E 组必须是最后一段**（`start_run()` 会重建地图与 player，现场无法完整还原）。
> **旁证行一律不带 `#NN`**：`sigcnt=/lastarg=`、`label=`、A08 的 13 点逐行、E 组 `e2e run=` 原始读数、`e04/05 line=` 全走独立行，否则 `grep -c` 会把它们算进断言数、`declared` 自校验永久假绿。

---

## 3. 骨架代码（整段贴进 `game_main.gd`）

```gdscript
## ============================================================================
## Sprint 27 批二 探针：誓约遗赠（SMOKE_OATH_GRANT=1）
## 43 条断言，declared 字面量 43。每条后无条件打印 #NN + 实测值。
## 唯一授予入口 _og_grant()：内部 call(&"_oath_grant")，故全仓 _oath_grant 的
## 带括号字面调用点仍恰 1 处（start_run 内那行）——C08 静态门依赖这一点。
## 🔴 本段代码内一律只写 `_oath_grant`（不带括号）；带括号的字面量只由 _OG_SYM_GRANT 拼接产生，
##    否则 C08 全仓扫描会把探针自己的注释/字符串数进去 → 读成 2+ 而假红。
## 本条探针绝不写盘：不调 Game.save_codex() / set_codex_last_run()。
## ============================================================================

func _test_oath_grant() -> void:
	_og_snap = _og_snapshot()
	_og_load_src()
	Game.diamonds_changed.connect(_og_on_diamonds)
	print("[SMOKE-OATH-GRANT] entry diamonds=%d last_run_oath=%s streak=%s daily=%s has_grant=%s has_amount=%s" % [
		Game.diamonds,
		"empty" if (Game.codex["last_run"].get("oath", {}) as Dictionary).is_empty() else "nonempty",
		str(Game.codex["last_run"].get("oath_streak", "<none>")),
		str(Game.daily_mode),
		str(has_method("_oath_grant")), str(has_method("_oath_grant_amount"))])
	if not has_method("_oath_grant") or not has_method("_oath_grant_amount"):
		print("[SMOKE-OATH-GRANT] FATAL 授予函数不存在 → 43 条全部 measured=MISSING 且 ok=false")
	_og_group_a()
	_og_group_b()
	_og_group_c()
	_og_group_g()
	_og_group_d()
	_og_group_f()
	_og_group_e()          # 🔴 必须最后
	Game.diamonds_changed.disconnect(_og_on_diamonds)
	_og_restore()
	Dev.check(_og_checked == _OG_DECLARED, "oath_grant",
		"自校验失败: checked(%d) != declared(%d)" % [_og_checked, _OG_DECLARED])
	Dev.check(_og_wire_fail == 0, "oath_grant",
		"探针未接上授予函数：_oath_grant 不存在或名字写错（wire_fail=%d）" % _og_wire_fail)
	print("[SMOKE-OATH-GRANT] done checked=%d declared=%d" % [_og_checked, _OG_DECLARED])


# ---------------------------------------------------------------- 基础设施

func _og_on_diamonds(n: int) -> void:
	_og_sig_cnt += 1
	_og_sig_last = n


func _og_sig_reset() -> void:
	_og_sig_cnt = 0
	_og_sig_last = -999999


## 每条断言唯一出口：先计数、再 Dev.check、最后无条件 print（顺序不许换）
func _og_assert(ok: bool, nn: String, what: String, measured, expect) -> void:
	_og_checked += 1
	var msg := "%s %s | measured=%s expect=%s" % [nn, what, str(measured), str(expect)]
	Dev.check(ok, "oath_grant", msg)
	print("[SMOKE-OATH-GRANT] #%02d %s measured=%s expect=%s ok=%s" % [
		_og_checked, nn + " " + what, str(measured), str(expect), str(ok)])


## 唯一授予漏斗：探针不许直接写 _oath_grant 的带括号调用（C08 全仓只许 1 处）
## 🔴 call() 绕过静态检查，函数名写错只在运行期炸 → 必须 has_method 硬检查，不成立**判红**、不许静默
func _og_grant() -> void:
	if not has_method("_oath_grant"):
		_og_wire_fail += 1
		print("[SMOKE-OATH-GRANT] wire_fail 探针未接上授予函数（call(\"_oath_grant\") 无此方法）")
		return
	call(&"_oath_grant")


func _og_amount(s: int) -> int:
	if not has_method("_oath_grant_amount"):
		return -9999
	return _oath_grant_amount(s)


func _og_oath_ne() -> Dictionary:
	# oath 非空：B01-B06/B08-B10、C、D、E 全部用它，把"未立誓"这一维留给 B07 独占
	return {"id": "untouched", "name": "不受伤", "desc": "probe",
		"done": true, "cur": 9, "need": 9}


func _og_set_last_run(oath: Dictionary, streak, with_key: bool) -> void:
	var lr: Dictionary = Game.codex["last_run"]
	lr["oath"] = oath.duplicate(true)
	if with_key:
		lr["oath_streak"] = streak
	else:
		lr.erase("oath_streak")
	Game.codex["last_run"] = lr


## 拉平基线：三通道 + 信号计数 + 哨兵文本。**绝不调 _roll_modifier/Data.roll_modifier**
func _og_flat(baseline: int = 0) -> void:
	Game.diamonds = baseline
	Game.run_diamonds_earned = 0
	_oath_counters.clear()
	Game._reso_pickups = 0
	resonance = 0
	Game.daily_mode = false
	if is_instance_valid(hud):
		hud._toast.text = _OG_SENTINEL
	_og_sig_reset()


func _og_toast() -> String:
	return hud._toast.text if is_instance_valid(hud) else "<no-hud>"


func _og_label() -> String:
	return hud._diamond_label.text if is_instance_valid(hud) else "<no-hud>"


## 只取标签里的数字串（"残响 15" / "15" 都要能取）——
## 但本批 HUD 写法是纯 str(n)（hud.gd:300），故按"文本是否等于 str(n)"判，
## 取不到就打印原文，由核验方看清是格式问题还是数值问题。
func _og_label_num() -> String:
	var t := _og_label()
	var digits := ""
	for i in t.length():
		var c := t[i]
		if c >= "0" and c <= "9":
			digits += c
		elif digits != "":
			break
	return digits if digits != "" else t


# ---------------------------------------------------------------- A 组（9，纯函数）

func _og_group_a() -> void:
	_og_assert(_og_amount(0) == 0, "A01", "amount(0)=0", _og_amount(0), 0)
	_og_assert(_og_amount(1) == 3, "A02", "amount(1)=3", _og_amount(1), 3)
	_og_assert(_og_amount(2) == 5, "A03", "amount(2)=5", _og_amount(2), 5)
	_og_assert(_og_amount(3) == 8, "A04", "amount(3)=8", _og_amount(3), 8)
	_og_assert(_og_amount(4) == 8, "A05", "amount(4)=8", _og_amount(4), 8)
	_og_assert(_og_amount(99) == 8, "A06", "amount(99)=8", _og_amount(99), 8)
	_og_assert(_og_amount(-1) == 0, "A07", "amount(-1)=0", _og_amount(-1), 0)
	# A08：13 点手写期望（禁公式）。旁证行不带 #NN
	var pts := [-2, -1, 0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10]
	var want := [0, 0, 0, 3, 5, 8, 8, 8, 8, 8, 8, 8, 8]
	var bad := 0
	var got_line: Array = []
	for i in pts.size():
		var got := _og_amount(int(pts[i]))
		got_line.append("s=%d→%d" % [int(pts[i]), got])
		if got != int(want[i]):
			bad += 1
	print("[SMOKE-OATH-GRANT] a08 detail: %s" % " ".join(got_line))
	_og_assert(bad == 0, "A08", "13 点逐点全等", "%d 点错" % bad, "0 点错")
	# A09：去重集合恰 {0,3,5,8}
	var seen := {}
	for s in range(-2, 13):
		seen[_og_amount(int(s))] = true
	var keys := seen.keys()
	keys.sort()
	var set_ok := keys.size() == 4 and keys.has(0) and keys.has(3) and keys.has(5) and keys.has(8)
	print("[SMOKE-OATH-GRANT] a09 detail: distinct=%s" % str(keys))
	_og_assert(set_ok, "A09", "取值集合=={0,3,5,8}", str(keys), "[0, 3, 5, 8]")


# ---------------------------------------------------------------- B 组（10，基线探针手工置）

func _og_group_b() -> void:
	# B01 无 oath_streak 键（oath 非空！）
	_og_flat(0); _og_set_last_run(_og_oath_ne(), 0, false); _og_grant()
	_og_assert(Game.diamonds == 0, "B01", "无 streak 键→不发", Game.diamonds, 0)
	# B02 字符串 "3"
	_og_flat(0); _og_set_last_run(_og_oath_ne(), "3", true); _og_grant()
	print("[SMOKE-OATH-GRANT] b02 detail: naive_int=%d (必须 3，用来证明不能用朴素 int())" % int("3"))
	_og_assert(Game.diamonds == 0, "B02", "streak=\"3\"→不发", Game.diamonds, 0)
	# B03 float 2.9 → 截断 2 → +5
	_og_flat(0); _og_set_last_run(_og_oath_ne(), 2.9, true); _og_grant()
	_og_assert(Game.diamonds == 5, "B03", "streak=2.9→+5", Game.diamonds, 5)
	# B04 bool true
	_og_flat(0); _og_set_last_run(_og_oath_ne(), true, true); _og_grant()
	_og_assert(Game.diamonds == 0, "B04", "streak=true→不发", Game.diamonds, 0)
	# B05 负数（弱：钳与不钳同档）
	_og_flat(0); _og_set_last_run(_og_oath_ne(), -5, true); _og_grant()
	_og_assert(Game.diamonds == 0, "B05", "streak=-5→不发", Game.diamonds, 0)
	# B06 null
	_og_flat(0); _og_set_last_run(_og_oath_ne(), null, true); _og_grant()
	_og_assert(Game.diamonds == 0, "B06", "streak=null→不发", Game.diamonds, 0)
	# B07 🔴 棘轮：oath 缺键 + streak=3 → 必须 0
	_og_flat(0); _og_set_last_run({}, 3, true); _og_grant()
	_og_assert(Game.diamonds == 0, "B07", "oath 空+streak3→不发(棘轮)", Game.diamonds, 0)
	# B08 oath 非空 + streak=0 → 0 且不扣成负
	_og_flat(7); _og_set_last_run(_og_oath_ne(), 0, true); _og_grant()
	_og_assert(Game.diamonds == 7 and Game.diamonds >= 0, "B08",
		"未兑现→0 且不扣负", Game.diamonds, "7 且 >=0")
	# B09 基线 7 + streak 3 → 15（唯一抓覆盖式写法）
	_og_flat(7); _og_set_last_run(_og_oath_ne(), 3, true); _og_grant()
	_og_assert(Game.diamonds == 15, "B09", "7+8=15 叠加非覆盖", Game.diamonds, 15)
	# B10 purse 真实路径：X / Y 差值
	var x10 := _og_purse_case(0)
	var y10 := _og_purse_case(3)
	print("[SMOKE-OATH-GRANT] b10 detail: X=%d Y=%d" % [x10, y10])
	_og_assert(y10 - x10 == 8 and x10 >= 15, "B10", "purse Δ=8 且 X>=15",
		"X=%d Y=%d Δ=%d" % [x10, y10, y10 - x10], "X>=15 且 Δ=8")


## purse 真实路径（走 _apply_sigil_contract，不是手工置 15）
func _og_purse_case(streak: int) -> int:
	Game.sigils["equipped"] = "purse"
	_og_flat(0)
	_apply_sigil_contract()                      # ← 真实分支：Game.diamonds = 15
	_og_set_last_run(_og_oath_ne(), streak, true)
	_og_grant()
	return Game.diamonds
```
> `_og_purse_case` 控制组返回 `X`（purse 置 15 后不授予），处理组返回 `Y`（15+8=23，清了 codex boons 时）。
> **若探针没清 codex 六类，X 会变成 18** —— 这正是 `X>=15` 而不是 `X==15` 的原因，也是 B10 不写死 23 的原因。

```gdscript
# ---------------------------------------------------------------- C 组（10）

func _og_group_c() -> void:
	# C01 信号：次数 + 末次实参
	_og_flat(7); _og_set_last_run(_og_oath_ne(), 3, true); _og_grant()
	print("[SMOKE-OATH-GRANT] c01 detail: sigcnt=%d lastarg=%d diamonds=%d" % [
		_og_sig_cnt, _og_sig_last, Game.diamonds])
	_og_assert(_og_sig_cnt >= 1 and _og_sig_last == Game.diamonds, "C01",
		"信号触发且末参==总值", "cnt=%d last=%d d=%d" % [_og_sig_cnt, _og_sig_last, Game.diamonds], "cnt>=1 last==d")
	# C02 run_diamonds_earned Δ
	_og_flat(0); _og_set_last_run(_og_oath_ne(), 3, true)
	var e0 := Game.run_diamonds_earned
	_og_grant()
	_og_assert(Game.run_diamonds_earned - e0 == 0, "C02", "run_diamonds_earned Δ=0",
		Game.run_diamonds_earned - e0, 0)
	# C03 diamonds_picked Δ
	_og_flat(0); _og_set_last_run(_og_oath_ne(), 3, true)
	var o0: int = int(_oath_counters.get("diamonds_picked", 0))
	_og_grant()
	var o1: int = int(_oath_counters.get("diamonds_picked", 0))
	_og_assert(o1 - o0 == 0, "C03", "diamonds_picked Δ=0", o1 - o0, 0)
	# C04 _reso_pickups Δ + resonance Δ（has_resocore=true 才触发该通路）
	var keep_core := player.has_resocore
	player.has_resocore = true
	_og_flat(0); _og_set_last_run(_og_oath_ne(), 3, true)
	var rp0 := Game._reso_pickups
	var rs0 := resonance
	_og_grant()
	var rp1 := Game._reso_pickups
	var rs1 := resonance
	player.has_resocore = keep_core
	_og_assert(rp1 - rp0 == 0 and rs1 - rs0 == 0, "C04", "_reso_pickups Δ=0 且 resonance Δ=0",
		"resoΔ=%d resonanceΔ=%d" % [rp1 - rp0, rs1 - rs0], "0 且 0")
	# C05 daily=true → 不发、无 toast
	_og_flat(7); _og_set_last_run(_og_oath_ne(), 3, true)
	Game.daily_mode = true
	_og_grant()
	var d05 := Game.diamonds
	var t05 := _og_toast()
	Game.daily_mode = false
	_og_assert(d05 == 7 and t05 == _OG_SENTINEL, "C05", "daily 不发且无 toast",
		"d=%d toast=%s" % [d05, t05], "d=7 toast=" + _OG_SENTINEL)
	# C06 daily=false → 正常发
	_og_flat(7); _og_set_last_run(_og_oath_ne(), 3, true); _og_grant()
	_og_assert(Game.diamonds == 15, "C06", "daily=false 正常 +8", Game.diamonds, 15)
	# C07 两次完整 start_run 幂等（rng seed+state 双还原）
	var r := _og_e2e_raw(3, "", _OG_E2E_SEED)
	var r2 := _og_e2e_raw(3, "", _OG_E2E_SEED)
	print("[SMOKE-OATH-GRANT] c07 detail: run1=%d run2=%d" % [int(r["diamonds"]), int(r2["diamonds"])])
	_og_assert(int(r["diamonds"]) == int(r2["diamonds"]), "C07", "两次 start_run 残响相同",
		"%d vs %d" % [int(r["diamonds"]), int(r2["diamonds"])], "相等")
	# C08 静态门：字面调用点恰 1（排除 func 定义行、排除 _test_oath_grant 之类前缀）
	var call_lines := _og_grant_call_lines()
	print("[SMOKE-OATH-GRANT] c08 detail: call_lines=%s" % str(call_lines))
	_og_assert(call_lines.size() == 1, "C08", "_oath_grant 字面调用点==1",
		"count=%d lines=%s" % [call_lines.size(), str(call_lines)], 1)
	# C09 不缓存：3 → 授予 8；改 1 → 再授予应为 3
	_og_flat(0); _og_set_last_run(_og_oath_ne(), 3, true); _og_grant()
	var after3 := Game.diamonds
	_og_set_last_run(_og_oath_ne(), 1, true); _og_grant()
	_og_assert(Game.diamonds - after3 == 3, "C09", "改 streak=1 后 Δ=3（不留 8）",
		Game.diamonds - after3, 3)

# ---------------------------------------------------------------- G 组（1，真实 HUD 标签）

## 只读用户能看见的那个字符串（hud.gd:300 就是 _diamond_label.text = str(n)）。
## 禁 mock、禁读 hud 内部缓存字段——"连了信号"是静态事实，"显示对了"必须实测。
func _og_group_g() -> void:
	_og_flat(7); _og_set_last_run(_og_oath_ne(), 3, true); _og_grant()
	var new_total := Game.diamonds                       # 期望 15
	var lab := _og_label_num()
	print("[SMOKE-OATH-GRANT] g01 detail: label_raw=%s label_num=%s diamonds=%d" % [
		_og_label(), lab, Game.diamonds])
	_og_assert(lab == str(new_total), "G01", "真实 hud 标签数字==Game.diamonds", lab, str(new_total))


# ---------------------------------------------------------------- D 组（5，文案）

func _og_group_d() -> void:
	_og_flat(0); _og_set_last_run(_og_oath_ne(), 3, true); _og_grant()
	var t1 := _og_toast()
	_og_assert(t1.begins_with(_OG_TAG), "D01", "toast 以「誓约遗赠」开头", t1, _OG_TAG + "…")
	_og_flat(0); _og_set_last_run(_og_oath_ne(), 2, true); _og_grant()
	var t2 := _og_toast()
	_og_assert(t2.contains("2 局"), "D02", "含连绩局数 2 局", t2, "…2 局…")
	_og_assert(t2.contains("+5"), "D03", "含回流实值 +5", t2, "…+5…")
	_og_flat(0); _og_set_last_run(_og_oath_ne(), 0, true); _og_grant()
	_og_assert(_og_toast() == _OG_SENTINEL, "D04", "streak=0 无 toast（哨兵未变）",
		_og_toast(), _OG_SENTINEL)
	var clash := ""
	for k in Data.OATH_CONDITIONS.keys():
		if String(Data.OATH_CONDITIONS[k].get("name", "")) == _OG_TAG:
			clash = String(k)
	_og_assert(clash == "", "D05", "「誓约遗赠」不与任何誓约名相同", clash, "无同名")


# ---------------------------------------------------------------- F 组（2，零 rng）

func _og_group_f() -> void:
	_og_flat(0); _og_set_last_run(_og_oath_ne(), 3, true)
	var s0 := Game.rng.seed
	var fx0 := Game.fx_rng.seed
	var st0 := Game.rng.state
	_og_grant()
	_og_assert(Game.rng.seed == s0 and Game.fx_rng.seed == fx0 and Game.rng.state == st0, "F01",
		"授予前后 两个 seed + rng.state 不变",
		"seed %d→%d fx %d→%d state_changed=%s" % [s0, Game.rng.seed, fx0, Game.fx_rng.seed,
			str(Game.rng.state != st0)], "全不变")
	var a3a := _og_amount(3)
	var a3b := _og_amount(3)
	print("[SMOKE-OATH-GRANT] f02 detail: 静态半边（函数体内不得出现 Game./player.）由 S-grep 闭合")
	_og_assert(a3a == a3b, "F02", "同输入两次同输出", "%d vs %d" % [a3a, a3b], "相等")
```

```gdscript
# ---------------------------------------------------------------- E 组（7，🔴 必须最后）

func _og_group_e() -> void:
	# E01 无印记：控制组 streak=0 vs 处理组 streak=3
	var e1 := _og_e2e_pair(0, 3, "", _OG_PLAIN_SEED)
	var d1x := int(e1[0]["diamonds"])
	var d1y := int(e1[1]["diamonds"])
	print("[SMOKE-OATH-GRANT] e2e run=E01 ctrl diamonds=%d run_seed=%s | treat diamonds=%d run_seed=%s modifier=%s" % [
		d1x, str(e1[0]["run_seed"]), d1y, str(e1[1]["run_seed"]), str(e1[1]["modifier"])])
	_og_assert(d1y - d1x == 8, "E01", "E2E 差值 +8", d1y - d1x, 8)
	# E02 purse
	var e2 := _og_e2e_pair(0, 3, "purse", _OG_PLAIN_SEED)
	var d2x := int(e2[0]["diamonds"])
	var d2y := int(e2[1]["diamonds"])
	print("[SMOKE-OATH-GRANT] e2e run=E02 ctrl diamonds=%d | treat diamonds=%d" % [d2x, d2y])
	_og_assert(d2y - d2x == 8 and d2x >= 15, "E02", "purse Δ=8 且 X>=15",
		"X=%d Y=%d Δ=%d" % [d2x, d2y, d2y - d2x], "X>=15 Δ=8")
	# E03 seed 777（barren 场景）
	var e3 := _og_e2e_pair(0, 3, "", _OG_E2E_SEED)
	var d3x := int(e3[0]["diamonds"])
	var d3y := int(e3[1]["diamonds"])
	print("[SMOKE-OATH-GRANT] e2e run=E03 ctrl=%d treat=%d modifier=%s" % [
		d3x, d3y, str(e3[1]["modifier"])])
	_og_assert(d3y - d3x == 8, "E03", "barren 场景差值仍 8", d3y - d3x, 8)
	# E04 / E05 🔴 源码序断言：一次读取算完三个锚点，读失败则两条一起红（不许 PENDING、不许静默跳过）
	# 三个锚点一律 `_og_lines_in_body()` —— **只在 start_run() 函数体内定位**，不许全文件扫（见 _og_start_run_body 注释）
	var gl := _og_lines_in_body(_OG_SYM_GRANT)
	var sl := _og_lines_in_body("_apply_sigil_contract()")
	var rl := _og_lines_in_body("Game.run_seed = Game.rng.seed")
	var g0 := int(gl[0]) if gl.size() > 0 else -1
	var s1 := int(sl[0]) if sl.size() > 0 else -1
	var rr := int(rl[0]) if rl.size() > 0 else -1
	print("[SMOKE-OATH-GRANT] e04e05 detail: body=%s grant_call_lines=%s sigil_call_lines=%s run_seed_lines=%s src_lines=%d" % [
		str(_og_body), str(gl), str(sl), str(rl), _og_src.size()])
	# 源码读不到 / start_run 找不到 / 锚点找不到 ⇒ -1 ⇒ 两条同时红（这就是设计意图，不是跳过）
	_og_assert(g0 > 0 and s1 > 0 and g0 > s1, "E04", "grant 调用行 > sigil 调用行",
		"grant=%d sigil=%d" % [g0, s1], "grant>sigil>0")
	_og_assert(g0 > 0 and rr > 0 and g0 < rr, "E05", "grant 调用行 < run_seed 行",
		"grant=%d run_seed=%d" % [g0, rr], "0<grant<run_seed")
	# E06 run_seed 逐字相同
	var rs_a := str(e1[0]["run_seed"])
	var rs_b := str(e1[1]["run_seed"])
	_og_assert(rs_a == rs_b, "E06", "两次 run_seed 逐字相同", "%s vs %s" % [rs_a, rs_b], "相等")
	# E07 地图指纹（房间序 + kinds 序）逐字相同
	var fp_a := str(e1[0]["fp"])
	var fp_b := str(e1[1]["fp"])
	print("[SMOKE-OATH-GRANT] e07 detail: fp_ctrl=%s | fp_treat=%s" % [fp_a, fp_b])
	_og_assert(fp_a == fp_b, "E07", "层1 地图指纹逐字相同", "equal" if fp_a == fp_b else "DIFF", "equal")


## 一对 E2E：控制组/处理组用同一 rng 起点（seed + state 双还原），只变 last_run
func _og_e2e_pair(streak_ctrl: int, streak_treat: int, sigil: String, seed_value: int) -> Array:
	var x := _og_e2e_raw(streak_ctrl, sigil, seed_value)
	var y := _og_e2e_raw(streak_treat, sigil, seed_value)
	return [x, y]


func _og_e2e_raw(streak: int, sigil: String, seed_value: int) -> Dictionary:
	Game.sigils["equipped"] = sigil
	Game.daily_mode = false
	# 控制组也是「立誓未兑现」（oath 非空 + streak=0），不混入"未立誓"这一维
	Game.codex["last_run"]["oath"] = _og_oath_ne()
	Game.codex["last_run"]["oath_streak"] = streak
	# 🔴 双还原：只还原 .state 不够（reset/daily 路径会读 .seed）
	Game.rng.seed = seed_value
	Game.rng.state = seed_value * 2654435761                      # 固定起点，避免依赖上一次消耗
	start_run()
	return {"diamonds": Game.diamonds, "run_seed": Game.run_seed,
		"modifier": modifier, "fp": _og_fp()}


## 与 _smoke_fingerprint（:322-337）同一算法，但不打 [SMOKE-META] 前缀
func _og_fp() -> String:
	if dungeon == null:
		return "<no-dungeon>"
	var coords: Array = []
	for c in dungeon.rooms.keys():
		coords.append(c)
	coords.sort_custom(func(a, b): return str(a) < str(b))
	var rooms_s: Array = []
	var kinds_s: Array = []
	for c in coords:
		rooms_s.append(str(c))
		kinds_s.append(String(dungeon.rooms[c].get("kind", "?")))
	return ",".join(rooms_s) + "|" + ",".join(kinds_s)
```

```gdscript
# ---------------------------------------------------------------- 源码扫描
# C08  走**全仓**（"字面调用点全仓恰 1 处"是仓库级事实）
# E04/E05 走**start_run 函数体**（"调用点在契约之后、run_seed 之前"是函数体内事实）

func _og_load_src() -> void:
	_og_src = []
	_og_body = Vector2i(-1, -1)
	var f := FileAccess.open("res://scripts/game_main.gd", FileAccess.READ)
	if f == null:
		print("[SMOKE-OATH-GRANT] WARN 读不到 res://scripts/game_main.gd → C08/E04/E05 判红（请从源码目录跑）")
		return
	var txt := f.get_as_text()
	f.close()
	_og_src = txt.split("\n")
	_og_body = _og_start_run_body()


## 定位 start_run() 函数体：[func 头下一行, 下一个顶层 func 前一行]，1-based；找不到返回 (-1,-1)
## 🔴 E04/E05 的三个锚点**必须**在本范围内找，不许全文件扫：
##    ① 探针函数名 `_test_oath_grant` 里含「_oath_grant」子串，全景扫会撞到自己；
##    ② 限死函数体后「调用点在哪」没有歧义（探针追加在文件末尾，天然落在范围外）。
##    函数体找不到（改名/被删）→ 返回 (-1,-1) → E04/E05 两条一起红，不许静默跳过。
func _og_start_run_body() -> Vector2i:
	var s := -1
	for i in _og_src.size():
		if _og_src[i].begins_with("func start_run("):
			s = i
			break
	if s < 0:
		return Vector2i(-1, -1)
	var last := _og_src.size() - 1
	for i in range(s + 1, _og_src.size()):
		var ln: String = _og_src[i]
		if ln.begins_with("func ") or ln.begins_with("static func ") or ln.begins_with("class "):
			last = i - 1
			break
	return Vector2i(s + 2, last + 1)          # 首行取 func 头下一行（跳过函数签名本身）


func _og_is_word(c: String) -> bool:
	if c == "_":
		return true
	if c >= "0" and c <= "9":
		return true
	if c >= "a" and c <= "z":
		return true
	if c >= "A" and c <= "Z":
		return true
	return false


## 词边界匹配（左边界）：符号前不能是标识符字符
## （否则 `_test_oath_grant` 会被误算成调用点，把 C08 读成 2/3）
func _og_line_has_sym(line: String, sym: String) -> bool:
	var i := line.find(sym)
	while i >= 0:
		var left_ok := i == 0 or not _og_is_word(line[i - 1])
		if left_ok:
			return true
		i = line.find(sym, i + 1)
	return false


## 全仓 1-based 行号数组（排除 func 定义行 / static func 定义行）
## 🔴 不截断探针自身：探针若写了带括号的字面调用，这里就该读出 2 → C08 判红。
##    为了让这条纪律可执行，探针自己用 `_OG_SYM_GRANT` 拼接符号，源码里不出现字面量。
func _og_lines_containing(sym: String, also_exclude_func: bool) -> Array:
	var out: Array = []
	for i in _og_src.size():
		var line: String = _og_src[i]
		if not _og_line_has_sym(line, sym):
			continue
		if line.strip_edges().begins_with("func "):
			continue
		if also_exclude_func and line.strip_edges().begins_with("static func "):
			continue
		out.append(i + 1)
	return out


## start_run 函数体 1-based 行号数组（E04/E05 专用；范围外一律不算，读不到源码则为空）
func _og_lines_in_body(sym: String) -> Array:
	var out: Array = []
	if _og_body.x < 0:
		return out
	for ln in range(_og_body.x, _og_body.y + 1):
		if ln - 1 < _og_src.size() and _og_line_has_sym(_og_src[ln - 1], sym):
			out.append(ln)
	return out


func _og_grant_call_lines() -> Array:
	return _og_lines_containing(_OG_SYM_GRANT, true)
```

```gdscript
# ---------------------------------------------------------------- 现场快照与还原

func _og_snapshot() -> Dictionary:
	var t: String = hud._toast.text if is_instance_valid(hud) else ""
	return {
		"equipped": String(Game.sigils.get("equipped", "")),
		"codex": Game.codex.duplicate(true),          # 深拷贝：本探针只改内存态
		"daily": Game.daily_mode,
		"has_resocore": player.has_resocore if is_instance_valid(player) else false,
		"diamonds": Game.diamonds,
		"earned": Game.run_diamonds_earned,
		"reso_pickups": Game._reso_pickups,
		"resonance": resonance,
		"toast": t,
	}


## 🔴 E 组会重建地图/player，运行状态不做完整还原（如实声明，不假装还原了）；
## 只还原「会污染其它探针」的全局配置与存档内存态。
func _og_restore() -> void:
	Game.sigils["equipped"] = String(_og_snap.get("equipped", ""))
	Game.codex = (_og_snap.get("codex", {}) as Dictionary).duplicate(true)
	Game.daily_mode = bool(_og_snap.get("daily", false))
	if is_instance_valid(player):
		player.has_resocore = bool(_og_snap.get("has_resocore", false))
	Game.diamonds = int(_og_snap.get("diamonds", 0))
	Game.run_diamonds_earned = int(_og_snap.get("earned", 0))
	Game._reso_pickups = int(_og_snap.get("reso_pickups", 0))
	resonance = int(_og_snap.get("resonance", 0))
	if is_instance_valid(hud):
		hud._toast.text = String(_og_snap.get("toast", ""))
		hud._diamond_label.text = str(Game.diamonds)
	Game.diamonds_changed.emit(Game.diamonds)
	print("[SMOKE-OATH-GRANT] restore equipped=%s daily=%s diamonds=%d（E 组运行态不还原，已声明）" % [
		String(Game.sigils.get("equipped", "")), str(Game.daily_mode), Game.diamonds])
```

---

## 4. 跑法与门控（判 PASS 需**四条**同时成立，缺一不算过）

```bash
GODOT="D:/SteamLibrary/steamapps/common/Godot Engine/godot.windows.opt.tools.64.exe"
SMOKE=1 SMOKE_SEED=12345 SMOKE_OATH_GRANT=1 "$GODOT" --headless --path . --quit-after 900 2>&1 | tee og.log

grep -c "^\[SMOKE-OATH-GRANT\] #" og.log        # ① 必须 == 43
grep -c "\[ERR\] oath_grant" og.log             # ① 必须 == 0
grep "done checked=" og.log                     # ① 必须 checked=43 declared=43
grep -c "ok=PENDING" og.log                     # ① 反向门：必须 == 0（本批不允许任何断言以"未判定"上线）
grep -c "e04e05 detail: body=(-1, -1)" og.log   # ① 必须 == 0（start_run 函数体没定位到 ⇒ E04/E05 判红）
grep "FATAL" og.log                             # 必须为空
grep -c "wire_fail" og.log                      # 必须 == 0（call() 无静态检查，运行期自证成功）
```

> **门控三条判据（实施单 §7 定死，缺一不算过）**：`#NN` 行数 == **43**、`[ERR] == 0`、**`ok=PENDING` == 0**。
> 第三条是反向门：本批**不允许任何断言以「未判定」形态上线**，所以"没有 PENDING 行"本身要被查一遍，而不是靠没人写。

**② E04/E05 由探针自判**（读 `res://` 源码，在 **`start_run()` 函数体内**定位三锚点；读不到源码/找不到函数体 ⇒ 两条一起红）；下面三行 grep 是**交叉核对**，用于确认探针读数没被缓存/旧文件骗过：
```bash
# 三个行号：授予调用点 / sigil 调用点 / run_seed 赋值行
# ⚠️ 必须带词边界，否则 _test_oath_grant 会一起算进来
grep -nE "(^|[^A-Za-z0-9_])_oath_grant\(\)" scripts/game_main.gd   # 期望 2 行：1 定义 + 1 调用
grep -n "_apply_sigil_contract()" scripts/game_main.gd             # HEAD 实测 :360（调用行）；:1497 是定义行
grep -n "Game.run_seed = Game.rng.seed" scripts/game_main.gd       # HEAD 实测 :366
# 判定：sigil 行 < 调用行 < run_seed 行，两条不等式必须同时成立
# 兼验探针无自命中：上面第一条若读出 3 行 ⇒ 探针里漏了带括号的字面调用 ⇒ C08 会红，改探针不是改 grep
```

**静态门（与 C08 互为双保险；`grep` 必须带词边界）**：
```bash
# ⚠️ 不能用 grep "_oath_grant()"：它会把 _test_oath_grant() 一起算上 → 假报 3
grep -n "add_diamonds" scripts/game_main.gd                          # 授予块内 0 处
grep -n "_read_oath_streak()" scripts/game_main.gd                   # 事后 3 行 = 定义 + :3198 + 授予块 1（fc455af 只读一次）
grep -nE "maxi\([^,]+,\s*1\)" scripts/game_main.gd                 # 裁(d)：授予块内 0 处
grep -rn "diamonds_changed.emit" scripts/*.gd | wc -l                # 事后 6 行（现状 5 + 授予块 1）
```

**③ 九刀逐刀见红，红集合与《验证口径》§3.1 对齐**；**④ E1 三 seed 指纹与《验证口径》§0.4.1 逐字一致，且每次运行只许 1 行 `fingerprint`**（本探针跑完之后 E 组已重建过地图，所以 E1 必须另起一次进程跑，**绝不与 `SMOKE_OATH_GRANT` 同开**）。

---

## 5. 骨架的四处对齐点（**改骨架时不许破坏**）

1. **带括号的 `_oath_grant()` 字面调用点全仓只有 1 处**（`start_run` 内）。探针一律走 `_og_grant()` → `call(&"_oath_grant")`，
   且**探针源码里不许出现带括号的字面量**（注释/字符串也不行，一律写 `_oath_grant` 或 `_OG_SYM_GRANT`）。
   若图省事直接写，`C08` 会读到 2+ → **C08 自己把自己判红**。**注意：这里不许用"扫描时跳过探针"来绕过**——那会把真违规也盖掉。
2. **`C01` 与 `G01` 分开、不合并**（主理人 v3 收回原合并裁定）：`C01` 只断**信号**（次数 + 末次实参），`G01` 只断**真实 `hud._diamond_label.text`**，各计一条。
   合并成一条 `and` 链**不丢覆盖但丢诊断**——红了看不出是信号错还是渲染错；且会动已冻结编号。**两条在刀三/刀九下同时红**，这正是它们成对存在的理由。
3. **`B07` 是棘轮、`B08` 已换**：`B07` 用 `oath={}` + `streak=3`（期望 0）；`B08` 用 `oath` 非空 + `streak=0`（期望 0 且不扣负）。
   **B01-B06/B08-B10 全部用 `_og_oath_ne()`**，把"未立誓"这一维严格留给 `B07` 独占——否则刀六（删 `oath.is_empty()` 守卫）就不会是"单刀单红"。
4. **`E04/E05` 的三个锚点只在 `start_run()` 函数体内定位**（`_og_start_run_body()` → `_og_lines_in_body()`），**不许退回全文件扫**。
   函数体找不到（改名/被删/导出包读不到源码）⇒ `_og_body == (-1,-1)` ⇒ 两条一起判红，**不许静默跳过、不许打 PENDING**。

---

## 6. 已知限制（如实登记，不许在报告里抹平）

| 项 | 限制 | 兜底 |
|---|---|---|
| **C07** | 两次 `start_run()` 依赖 `Game.rng.seed/state` **双还原**（只还原 `.state` 不够——`reset`/daily 路径会读 `.seed`）。骨架已按双还原写死，但 `start_run` 还会读 `Game.time` 等，**真飘的可能性只能靠实跑排除** | 若实测不等：先打两次 `modifier`/`run_seed`/`diamonds` 原始读数 → **如实报「C07 在 X 次运行里飘了 Y 次」**，**不许改期望值凑绿**；这是本批唯一的"未实测"项，保留标注 |
| **E04/E05** | 探针读 `res://scripts/game_main.gd` **自判**，锚点**只在 `start_run()` 函数体内**定位；**导出包里读不到源码 / 函数体找不到 → `_og_body=(-1,-1)` → 两条一起判红**（这是设计意图，不是缺陷，因为本批只从源码目录跑） | 另用 §4 的三行 `grep -nE` 交叉核对：探针读数与 grep 不一致 ⇒ 有人改了文件却没重跑，按 FAIL |
| **E 组** | 8 次 `start_run()` 重建地图/player，**运行态不可能完整还原**（已声明）。探针跑完后该次运行的后续 `[SMOKE] t=` 帧序**不再与"无探针跑"逐字可比** | 本探针只读 `[SMOKE-OATH-GRANT]` 行；**E1 指纹必须单独跑**，绝不与本探针同开 |
| **F02 静态半边** | "函数体不读任何 `Game`/`player` 全局"探针内判不了（那是读源码语义，不是运行行为） | 由 §4 `grep` + 人工读 `_oath_grant_amount` 函数体（3 行 `if`）闭合，报告写明"静态" |
| **D04** | 只验"没发生"（哨兵法），属弱靶 | 已在编号表标"弱"，**不计入有效覆盖** |
