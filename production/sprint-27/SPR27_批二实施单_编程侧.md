# SPR27 批二实施单（编程侧）

> **本单是批二唯一权威。** 与 `SPR27_批二设计实稿.md` / `SPR27_批二验证口径.md` 冲突时以本单为准。
> 所有行号以当前 HEAD `ece249d` 为准，动手前须自行复核（批一加探针曾使全体行号下移 570 行，本单已按批一后的实数核对）。

---

## 0. 一句话

S27 批一让「主题 × 灾祸」互相改写；批二让**上一局**改写**这一局**——连兑现誓约，下一局开局多发残响。

**为什么是这条**：项目自诊断「Mechanics 过饱和、Dynamics 贫乏」。`oath_fulfillment()` 算出的兑现结果今天**只写进 `codex["last_run"]` 给玩家看，对下一局零影响**（`:2961`）。这是全项目唯一一条「已经算出来、但没有任何系统读它」的完整链路——把它接上，零新增实体、零新增表、零新增 rng。

---

## 1. 机制口径（锁死，不许改）

### 1.1 三态映射

读上一局结束时写入的 `codex["last_run"]["oath_streak"]`（下称 S），映射为开局残响增量 N：

| S | N | 含义 |
|---|---|---|
| `S <= 0` | **0** | 没连上，不发 |
| `S == 1` | **+3** | 刚连一局 |
| `S == 2` | **+5** | 连两局 |
| `S >= 3` | **+8** | 连三局以上，**封顶** |

三条不可动的设计意图：

1. **封顶 8，且 8 < 12**。12 是共鸣契约的价位。回流单靠自己换不到它，必须继续打。任何「提高上限到 12 或以上」的后续提议会立刻把它变成主导策略，**不许**。
2. **不兑现 → S 归 0 → N=0，除此之外不再额外惩罚**。已经失去了连绩本身，不要再叠一层「倒扣」。负反馈螺旋会让玩家不敢正常玩。
3. 🔴 **不立誓不断绩，但「不立誓的那一局」不发放。** 两条必须分开看，混在一起会开出一个单向棘轮：
   - **不断绩**：由既有 `next_oath_streak(prev, H=0, D) = prev`（`:2983-2986`）保证，本批**不动这个函数**。上局没装备印记，S 保留原值。
   - **不发放**：`_oath_grant()` 必须先检查 `last_run["oath"]` 非空，空了直接返回 0。
   - **为什么必须加这个守卫**：因为 S 在 H=0 时**永不衰减**，若照发，玩家只要曾经连兑现 3 局（达到 S=3），此后**永不装印记**，每局白拿 +8，且再也不承担「立誓未兑现清零」的风险。最优解变成「拿到 3 连之后彻底退出誓约系统」——这会把回流从「鼓励立誓」变成「奖励退出」，方向完全反了。这是**本批唯一一处「看起来更慷慨、实际是漏洞」**的地方，qa 的 B07/B08 构造正是冲着它来的，我最初的写法在这里错了，已改。

### 1.2 为什么读 streak 而不读 done

`_write_codex_replay(prev_streak)`（`:2958-2968`）在局末已经把 `next_oath_streak(prev, H, D)` 的结果写回 `last_run["oath_streak"]`（`:2967`）。也就是说 **streak 里已经编码了 done**：兑现 → S+1，立誓未兑现 → 0。再读 `oath.done` 是重复判定，且会引入「done 为真但 streak 是 0」的歧义态。

**只读 S，不读 done。** 唯一额外读的是 `last_run["oath"]` 的**存在性**（`is_empty()`），那不是 done 判定，是「上局有没有立誓」判定——见 §1.1 第 3 条。

判据三句话：`oath` 空 → 不发（未立誓）；`streak == 0` → 不发（立誓未兑现）；`streak >= 1` → 按档位发。

---

## 2. 载体选型：四个禁止（含实读理由）

必装靶子是**开局残响**，不是别的。以下四条路都在实读中被否掉，写在这里是为了防止后续「顺手优化」。

### 2.1 禁止用 `Game.add_diamonds()`

看起来最自然，实际有三条独立污染通路（**三条都实读确认**）：

1. `game_state.gd:151 run_diamonds_earned += n` → 局末 `Meta.payout` 按 0.10 累积成局外货币。誓约回流会被洗成局外资源，等于把局内奖励偷偷转成永久收益。
2. `game_state.gd:154 main.oath_count("diamonds_picked", n)` → 誓约「满载而归」`watched = ["diamonds_picked"], need = 40`（`data.gd:360`）。回流残响推进「满载而归」→ 兑现 → 连绩 +1 → 回流更高 → **自激环**。
3. `game_state.gd:159 _reso_pickups += n` 再 `while >= 3: main.add_resonance(1)`。持有 mx_resocore 的玩家，开局 +8 会直接白拿 **2 层共鸣**。这条是本次实读新发现，设计稿未列，比前两条更硬——它直接改写武器成长曲线且完全不报错。

**必须直写 `Game.diamonds += n`，然后手工 `Game.diamonds_changed.emit(Game.diamonds)`。**

### 2.2 禁止用 `diamond_mult`

`_roll_modifier()`（`:1206`）在 `:1213` 无条件 `diamond_mult = 1.0`，而它在注入段之后 8 行（`:371`）。写在这里会被抹掉。更根本的是 `:2992` 与 `data.gd:341` 已明文禁用这个载体。

### 2.3 禁止用 `max_hp`

两条：boot 路径同一 player 上 `start_run()` 会被调两次（`_ready():200` + `menu.gd:1094`），`_apply_codex_boons():3006 max_hp += 1` 会叠两遍；且 `max_hp` 会被 vigor 印记（`:1505` **赋值**）与 `overload`（`:1223 maxi(1, max_hp - 1)`）吃掉 → 回流对特定配装静默消失，构成激励倒挂。

### 2.4 禁止用 `mag_cap_mult`

被灾祸覆写（`:604-611` 三分支）。12 层里有 4 种弹药荒层，玩家带了回流却在那些层静默收不到。

### 2.5 为什么 `Game.diamonds` 是唯一站得住的

`game_state.gd:136 diamonds = 0` 在 `Game.reset()` 内，而 `Game.reset()` 是 `start_run():342` 的**第一句**。所以每局开局必然归零 → 授予天然幂等，**连 boot 双击都不需要特殊处理**。这一点很重要：批二不需要任何「本局已发过」的守卫标志，见 §3.4。

---

## 3. 落地

### 3.1 新增字段与常量

在 `game_main.gd` 既有 `_calamity_theme_rule` / `_calamity_frail_ratio`（`:121-122`）附近，新增：

```gdscript
const _OG_TOAST_TAG := "誓约遗赠"
```

**文案定「誓约遗赠」。** 设计稿曾用「余誓」，作废——「余誓」与既有八条誓约术语贴太近，玩家会以为这是第九条誓约。`_OG_TOAST_TAG` 必须作为常量存在，探针 D 组靠它断言，不允许在字符串里写死。

### 3.2 两个新函数

**纯函数（放进 `oath_fulfillment()` 同段，`:2914` 之前或之后皆可，但必须与誓约相关逻辑同段）：**

```gdscript
## Sprint 27 批二：连绩档位 → 开局残响回流值（纯函数，零全局读取，零 rng）
## 封顶 8 < 12（共鸣契约价）：回流单靠自己换不到契约，必须继续打。
static func _oath_grant_amount(s: int) -> int:
	if s <= 0:
		return 0
	if s == 1:
		return 3
	if s == 2:
		return 5
	return 8
```

**授予函数：**

```gdscript
## Sprint 27 批二：誓约遗赠——把上一局的连兑现折成本局开局残响。
## 载体只能是 Game.diamonds 直写：add_diamonds 会污染 run_diamonds_earned /
## diamonds_picked（自激「满载而归」）/ _reso_pickups（白送共鸣），三条实读确认。
## 零 rng、零计时、零新实体。daily 模式一律不发（榜单可比性）。
func _oath_grant() -> void:
	if Game.daily_mode:
		return
	# 🔴 上局未立誓 → 不发。streak 在 H=0 时永不衰减（next_oath_streak 既定语义），
	# 若不守这一条，玩家达成 S=3 后「永不再装印记」即可每局白拿 +8 且零风险 → 单向棘轮。
	if (Game.codex["last_run"].get("oath", {}) as Dictionary).is_empty():
		return
	var n := _oath_grant_amount(_read_oath_streak())
	if n <= 0:
		return
	Game.diamonds += n
	Game.diamonds_changed.emit(Game.diamonds)
	if is_instance_valid(hud):
		hud.flash_toast("%s · 连兑现 %d 局，开局残响 +%d" % [
			_OG_TOAST_TAG, _read_oath_streak(), n])
```

### 3.3 调用点（**位置是硬约束**）

插在 `start_run()` 内，`_apply_codex_boons()`（`:363`）之后、`Game.run_seed = Game.rng.seed`（`:366`）之前：

```gdscript
	_apply_codex_boons()
	_oath_grant()          # ← 插这一行
	Game.run_seed = Game.rng.seed
```

两个方向的顺序理由，**两个都必须成立**：

- **必须在 `_apply_sigil_contract()`（`:360`）之后**。purse 印记是 `Game.diamonds = 15`（`:1515`，**赋值不是累加**）。插在它之前，你自己的回流会被 purse 整个抹掉，而且只在「带 purse 印记」时复现——这是最难查的一类。E 组专抓。
- **必须在 `Game.run_seed = Game.rng.seed`（`:366`）之前**。本函数零 rng，理论上放后面也不改 rng 序列，但要守住项目既有纪律「注入一律在 rng 首抽前」，否则以后有人往这个函数里加一句读状态的逻辑就会悄悄改变消耗顺序。

### 3.4 不许加的守卫标志（R2）

**禁止**引入任何 `var _og_done := false` 之类的「本局已发过」短路。

理由：幂等性由 `Game.reset()` 每局归零提供，已经天然成立。加一个守卫标志反而会引入新失败面——标志挂在 `GameMain` 实例上跨局存活（`_oath_counters` 在 `:346` 归零，新加的 var 不会），一旦某条路径没清它，玩家会在「上局有档位、本局掉到 T0」时**静默留着上次的高档位**。

`_oath_grant()` 每次都从 `_read_oath_streak()` 现读现算，不缓存。C08 / C09 专抓这个。

### 3.5 探针挂载

在 `game_main.gd` 既有 env 判定链（`:237-246`，`:247-248` 是 `SMOKE_CAL_THEME`）末尾加一行：

```gdscript
if OS.get_environment("SMOKE_OATH_GRANT") != "":
	_test_oath_grant()
```

🔴 **`SMOKE_OATH_GRANT` 不得与 `SMOKE_META_FINGERPRINT=1` 同开**。E 组真实调 `start_run()` 两次，而 `:370 _smoke_fingerprint(1)` 每次开局打一行，一次运行会打出 3 行 `[SMOKE-META] fingerprint`，三跑比对直接失效。跑 E 组时 fingerprint 关掉，E1 单独跑。

---

## 4. 文案

| 位置 | 文本 |
|---|---|
| toast 首词 | `誓约遗赠`（`_OG_TOAST_TAG` 常量） |
| 完整句式 | `誓约遗赠 · 连兑现 2 局，开局残响 +5` |
| N=0 时 | **不出 toast**（不发就别喊） |
| daily 模式 | **不出 toast** |

首词「誓约遗赠」必须逐字保留——D01 用它做锚点。数字部分必须来自实值，不许写死字符串。

---

## 5. 探针规格

### 5.1 条数写死

```
const _OG_DECLARED := 43
```

分组绝对条数，**一条不多一条不少**：

| 组 | 条数 | 覆盖 |
|---|---|---|
| A | 9 | 档位映射纯函数 |
| B | 10 | 脏数据 / 空档 / 棘轮 / 叠加非覆盖 |
| C | **10** | 授予方式 + 状态通道 + daily + 幂等 + **信号与 HUD 同步** |
| D | 5 | 文案 |
| E | 7 | E2E 集成 |
| F | 2 | 零 rng |
| **合计** | **43** | |

> 原「G 组 1 条 HUD 同步」**并入 C10**，组数由 7 降为 6。合并理由：`hud.gd:299-300` 无条件把 `diamonds_changed` 接到残响标签上，所以「信号实参对」与「标签显示对」是同一因果链的两端。但**合并成一条不等于可以少读一次**——C10 必须在**同一个 `and` 链里同时断三件事**：信号触发 ≥1 次、末次实参 == 新总值、**HUD 标签文本 == 新总值**。只断前两件，等于把「标签没更新」这个失败面丢掉；那是玩家唯一能看见的东西。（此做法与批三 ⑯「同一 and 链同时断 live 与 `_mod_*`」同一技术：读多件事、计一条数。）

探针入口无条件打点（照批一教训）：

```
[SMOKE-OATH-GRANT] enter streak=%d amount=%d baseline=%d
群组内每条断言后无条件打印实测值（不许只在 Dev.check 失败时才有输出）
[SMOKE-OATH-GRANT] done checked=%d declared=%d
```

末尾 `checked == declared` 自校验。`[ERR]=0` 不能证明断言执行过（`dev_log.gd:29-32` 只在失败时打印）。

### 5.2 各组明细

**A 组（9，纯函数 `_oath_grant_amount`）**

- A01 `s=0` → 0
- A02 `s=1` → 3
- A03 `s=2` → 5
- A04 `s=3` → 8
- A05 `s=4` → 8（封顶平台）
- A06 `s=99` → 8（远上界）
- A07 `s=-1` → 0（负输入）
- A08 `s ∈ [-2,10]` 逐点手写 13 个期望值遍历（不许用公式现算，写死数组）
- A09 `s ∈ [-2,12]` 遍历取值去重，集合恰为 `{0, 3, 5, 8}`（证明没有漏溢出的档位）

**B 组（10，脏数据与叠加；🔴 B 组基线一律探针手工置 `Game.diamonds = 0`，禁调 `_roll_modifier()` / `Data.roll_modifier()` 拉平——后者抽 rng，直接撞 F 组）**

> 🔴 **B01–B06 一律令 `last_run["oath"]` 非空**，以隔离「streak 值类型」这一个失败面。`oath` 空/缺键那个失败面由 B07 单独承担——两条混在一个构造里，红了分不清是守卫错还是类型守卫错。

- B01 `last_run` 无 `oath_streak` 键 → 读 0 → 发 0
- B02 `oath_streak` 为字符串 `"3"` → 走 `_read_oath_streak()` 得 0 → 发 0。（同时在日志里记录 `int()` 朴素转换会给 3——这条的价值就是证明必须走 `_read_oath_streak()`，不许自己 `int(...)`）
- B03 `oath_streak` 为 float `2.9` → `_read_oath_streak()` 得 2 → 发 5
- B04 `oath_streak` 为 bool `true` → 0 → 发 0（GDScript bool 不是 int）
- B05 `oath_streak = -5` → `maxi` 钳到 0 → 发 0
- B06 `oath_streak = null` → 0 → 发 0
- B07 🔴 **单向棘轮靶子（本组最重要一条）**：`last_run["oath"] = {}`（上局未立誓）但 `oath_streak = 3` → **发 0**。理由见 §1.1 第 3 条：`next_oath_streak(H=0)` 让 streak 永不衰减，若照发，玩家达成 3 连后永不再装印记即可每局白拿 +8 且零风险。**若实现里漏了 `oath.is_empty()` 守卫，只有这条会红。**
- B08 上局立誓未兑现（`oath` 非空、`oath_streak = 0`）→ 发 0，且断言 `Game.diamonds` 未被扣成负数（§1.1 第 2 条：不许追加惩罚）
  - 附注：**本批不读 `oath["done"]`**（streak 已编码 done，见 §1.2），所以**不为 `done` 构造任何断言**。特别地，`done="yes"` 这种非 bool 脏值**不是**本批的靶子——要断言它得先让代码去读 `done`，与设计相反。日后若有人开始读 `done`，须同步补类型守卫并新增断言。
- B09 基线手工置 `7`、`oath_streak = 3` → 期望 `15`。**唯一能抓住 `Game.diamonds = n` 覆盖式写法的断言**（覆盖写会得 8）
- B10 真实 purse 印记（`Game.diamonds = 15`）+ `oath_streak = 3` → 期望 `23`。同时证明注入在 `_apply_sigil_contract()` 之后

**C 组（9，授予方式与通道）**

- C01 授予后 `diamonds_changed` 至少触发一次，且末次参数 == 授予后的 `Game.diamonds`（R1）
- C02 授予前后 `run_diamonds_earned` 不变（不走 `add_diamonds`）
- C03 授予前后 `_oath_counters.get("diamonds_picked", 0)` 不变（不自激「满载而归」）
- C04 授予前后 `_reso_pickups` 不变，且 `add_resonance` 未被调用（新发现通路，mx_resocore 场景）
- C05 `Game.daily_mode = true` → `Game.diamonds` 等于基线、不发 toast
- C06 `Game.daily_mode = false` → 正常发
- C07 连续两次完整 `start_run()`：第二次结束后 `Game.diamonds` 与第一次逐字相同（幂等靠 `reset` 归零，不靠标志）
- C08 静态门：全仓 `_oath_grant()` 调用点恰 **1 处**（定义行不计）。防有人在别处再调一次而放大
- C09 无条件赋值（R2）：先按 `oath_streak = 3` 授予 → 手工改 `oath_streak = 1` → 再次调用 → 结果按 +3 重算，**不留**上次 +8 的残留
- C10 **信号与 HUD 同步（原 G01 并入）**：授予后，**同一个 `and` 链**内断三件——① `diamonds_changed` 触发 ≥1 次；② 末次实参 == 授予后的 `Game.diamonds`；③ **真实 hud 节点的残响标签文本数字 == `Game.diamonds`**（不许 mock、不许读 `hud` 的内部缓存字段）。三件缺一即红。

**D 组（5，文案）**

- D01 toast 文本以 `_OG_TOAST_TAG`（「誓约遗赠」）开头
- D02 文本含连绩局数实值（`oath_streak = 2` → 含 "2 局"）
- D03 文本含回流实值（`oath_streak = 2` → 含 "+5"）
- D04 `oath_streak = 0` → 全程无 toast 产生
- D05 字符串「誓约遗赠」不等于 `Data.OATH_CONDITIONS` 中任何一项的 `name`（防玩家误认第九条誓约）

**E 组（7，E2E 真实路径；🔴 本组必须关掉 `SMOKE_META_FINGERPRINT`）**

- E01 真实 `start_run()`：预设 `oath` 非空 + `oath_streak = 3` → 开局后 `Game.diamonds` 比基线多 8
- E02 与 purse 叠加：带 purse 印记 + `oath` 非空 + `oath_streak = 3` → 23（不是 8，证明没被 purse 覆盖）
- E03 与 barren 叠加：`modifier == "barren"` 时 `:1220 add_diamonds(10)` 之后再 +8
- E04 顺序断言：`_oath_grant()` 调用点的行号 > `_apply_sigil_contract()` 调用点行号
- E05 顺序断言：`_oath_grant()` 调用点的行号 < `Game.run_seed = Game.rng.seed` 行号
- E06 整局跑通后 `Game.run_seed` 与未装本批时的基线逐字相同
- E07 `[SMOKE-META] fingerprint` 行与未装本批时的基线逐字相同

**F 组（2，零 rng）**

- F01 `_oath_grant()` 调用前后 `Game.rng.seed` 不变、`Game.fx_rng.seed` 不变
- F02 `_oath_grant_amount()` 纯函数：同输入连调两次同输出，且不读取任何 `Game` / `player` 全局

**G 组：已取消，原 G01 并入 C10。**

### 5.3 断言分类（须在报告里闭合）

43 条必须落进四类且加总 = 43：验效果型 / 前提守卫恒过 / 常量自比较 / 只验标志。

凡归「只验标志」的必须逐条写「哪个错误只被它抓住」，写不出的一律改归强靶或删掉。

C08 是静态门（grep 计数），归「常量自比较」并标注；D04/C05 若只验「没有 toast」也须标注为标志型。

---

## 6. 门控与变异

### 6.1 五门

A 阶段（A/B/C/D/F，36 条）与 B 阶段（+E，43 条）分开跑，报两组 `[ERR]` 与 `checked/declared`。

另外必跑：`validate.gd` 全过、既有 `SMOKE_*` 探针全过、E1 fingerprint 与 `ece249d` 逐字一致。

### 6.2 五把刀（🔴 变异必须**替换目标行**，不许新增行）

新增行常被复位/兜底行盖回，批一实测过一次假绿，本批不许再犯。

| 刀 | 变异 | 预期红 |
|---|---|---|
| 刀一 | `_oath_grant_amount` 的 `s == 2` 支 `5` → `3` | A03、A08、A09（集合少 5）、B09、B10、E01、E02 |
| 刀二 | `Game.diamonds += n` → `Game.diamonds = n`（覆盖式） | B09、B10、E02、E03 |
| 刀三 | 删掉 `Game.diamonds_changed.emit(...)` 那一行 | C10（三项同时红：触发次数与标签都对不上） |
| 刀四 | 把 `_oath_grant()` 调用点上移到 `_apply_sigil_contract()` 之前 | E04、E02、B10 |
| **刀五** | 删掉 `oath.is_empty()` 那两行守卫（**替换成空注释，不留代码**） | **B07 必红**（棘轮：未立誓却发 +8）；其余全绿 |

**刀二、刀四、刀五是本批的灵魂**：
- 刀二证明「叠加不是覆盖」；
- 刀四证明「顺序不是随便放的」（purse 是赋值，前置会静默抹掉回流，且只在带 purse 时复现）；
- **刀五证明「棘轮守卫不是装饰」**——它红的样子是「本该 0 却发了 8」，如果不红，说明 B07 是哑的，而这一条漏掉会让整个机制变成「奖励退出誓约系统」。

实测红集合与上表不一致时，**如实报差异并说明哪条断言结构上抓不到**，不许改期望值凑绿。

### 6.3 判 PASS 的方式（不接受「43/43 全绿」就完事）

本批改前有 **30 条不可执行**（读 `_oath_grant`，函数不存在），所以「改后全绿」几乎是必然的，信息量接近零。PASS 必须同时满足四条：

1. 43 条全绿，`checked == declared == 43`；
2. **静态门（C08 那类）逐条过**：调用点唯一、无守卫标志、未走 `add_diamonds`、未碰 `_roll_modifier`；
3. **五把刀逐刀见红，且红的编号集合与上表对齐**；
4. **复原后全部回绿**（刀改回去，不留残余改动）。

只做到第 1 条不算过。核验方会独立重跑 1–4，并对不上就按 FAIL。

---

## 7. 不做清单

- **不推送**。提交由你做完核验后我来收口，推送另有专人。
- 不写与本批无关的 `.gd`（C1 主题倍率泄漏、C2 狂乱漏接属**批三**，本批一律不碰）。
- 不动 `next_oath_streak()` / `_write_codex_replay()` / `oath_fulfillment()` 任何一个字节。
- 不动 `Data.OATH_CONDITIONS` / `SIGILS` / `SHRINE_OFFERS` 任何机制字段。
- 不新增 `SHRINE_OFFERS` / `SIGILS` / `CODEX_KINDS` 条目。
- 不把回流值按誓约难度分级——这一条是红线，一旦分级就变成主导策略（玩家永远挑最容易那条）。
- 不修既有在册缺陷：boot 双击 `max_hp += 1` 叠加、`barren` + `scarce_ore` 文案显示 -0%、`max_hp` 钳制时 frail 比例不符、`boss.gd:61`/`boss2.gd:26` C-style `%`。
- 不碰 `daily_mode` 的 seed 派生逻辑（只加一个 early return）。

---

## 8. 交付形态

1. 一个提交，消息写清 `S27 批二：誓约遗赠（连兑现 → 开局残响） + 探针 43 条（A9/B10/C9/D5/E7/F2/G1）`。
2. 报告须含：五门实测表（两组 `[ERR]` + `checked/declared`）、**五把刀**实测红集合与编号对齐情况、43 条分类闭合小计、与上表预测不一致处的如实说明。
3. 报告须含三个"今天值"：今天这 43 条里有几条红、几条哑绿、几条不可执行（即净增量证据是多少条）。
4. 不改 `production/sprint-21/SPR21-FROZEN.md5`，不改 `production/sprint-7/SPR7-FROZEN-4.md5`。

---

## 9. 四条最容易踩的坑（贴在手边）

1. **purse 是赋值不是累加**（`:1515 Game.diamonds = 15`）。注入位置错到它前面，回流只在带 purse 时静默消失。
2. **`add_diamonds` 有三条污染通路**，第三条（`_reso_pickups` → 白送共鸣）平时不显形，只在玩家恰好持有 mx_resocore 时爆。
3. **`SMOKE_OATH_GRANT` 与 `SMOKE_META_FINGERPRINT` 不能同开**。E 组真实跑 `start_run()` 两次，一次运行会打出 3 行 fingerprint。
4. 🔴 **`oath` 空的守卫不是可选项**。`streak` 在 H=0 时永不衰减，漏了守卫 = 玩家达成 3 连后永不再装印记、每局白拿 +8、零风险 → 最优解变成退出誓约系统。这条错了机制会反向，且**表面上一切正常、只是数值偏慷慨**，不看 B07 根本发现不了。
