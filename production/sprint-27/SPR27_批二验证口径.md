# SPR27 批二 · 验证口径（誓约遗赠）

> 任务号 **SPR27-B2-QA-01**｜角色：验收接手方（QA）｜**只产出文档**：本批不改 `.gd`、不改资产、不 commit。
> **行号基准：全部实读于 HEAD `ece249d`**（工作树干净，`scripts/` 34 个 `.gd`，`production/sprint-21/SPR21-FROZEN.md5` 34/34 OK）。
> 机制由主理人定死（见 §〇），本文只做三件事：**把机制翻成可执行断言**、**给死数**、**标出"哪种写错能被哪条断言抓住"**。
> 读者：① 实施方（照 §一/§四 写授予块与探针）② 核验方（照 §三 下刀、照 §五 判 PASS/FAIL）。

## 〇 前置：行号复核（主理人给的值 vs 实读）

主理人明确要求自行复核。**核对结果：核心锚点全部命中；5 处需订正 + 1 处范围注记**（偏差均 < 5 行，但照着写会找错位置、或漏掉半个靶子）：

| 项 | 主理人给 | **实读 @`ece249d`** | 判定 |
|---|---|---|---|
| `start_run()` | `:339` | **`:339`** | ✓ |
| `Game.reset()` 调用 | `:342` | **`:342`** | ✓ |
| `diamonds = 0` | `game_state.gd:136` | **`:136`** | ✓ |
| `_oath_counters = {}` | `:346` | **`:346`** | ✓ |
| daily seed 覆盖段 | `:352-357` | **`:351-357`**（注释 351-352，代码 353-357） | ≈ |
| `_apply_sigil_contract()` | `:358` | **调用在 `:360`**（注释在 358-359） | ✗ 差 2 |
| `_apply_codex_boons()` | `:362` | **调用在 `:363`**（注释在 361-362；`func` 定义在 **`:2994`**） | ✗ 差 1 |
| `Game.run_seed = Game.rng.seed` | `:366` | **`:366`** | ✓ |
| `oath_fulfillment()` | `:2914` | **`:2914`**（体 2915-2929；`done = cur >= need` 在 **`:2929`**） | ✓ |
| `_write_codex_replay()` | `:2953-2967` | **`func` 在 `:2958`**，体 2959-2968；`oath` 写 **`:2961`**、`echo` **`:2962`**、`oath_streak` **`:2963-2967`** | ✗ 给的是注释段起点 |
| `_read_oath_streak()` | `:2973` | **`:2973-2977`** | ✓ |
| `add_diamonds()` 的 `oath_count` | `game_state.gd:149-155` | 函数 **`:149-163`**；`run_diamonds_earned += n` 在 **`:151`**、`oath_count("diamonds_picked")` 在 **`:153-154`** | ✗ 范围窄了（`:151` 也是靶子） |
| env 判定链 | `:236-248` | **`:237-246`**（`SMOKE_META*` 链）+ **`:247-248`**（`SMOKE_CAL_THEME`）；**新开关插在 `:248` 之后** | ✗ 范围 |
| `_ready` 内 `start_run()` | `:200` | **`:200`** | ✓ |
| 开始按钮 `start_run()` | `menu.gd:1094` | `start_game()` 在 `:1089`，`start_run()` 在 **`:1094`** | ✓ |

**顺带订正一条批一文档的漂移**（防核验方拿旧值找不到）：`_smoke_fingerprint()` 批一口径记 `:318-333`，**实读 `:322-337`**（`func` 322、`print` 336）——批一 B 组落地后整体 +4。本文所有"门控"行号一律用实读值。

### 0.1 机制复述（不改设计，只固定断言口径）

| 项 | 口径（主理人定死） |
|---|---|
| 新字段 | `_oath_grant := 0`：本局**实际发放**的残响数（供断言与文案读，不是"意图值"） |
| 插入位置 | `start_run()` 内，**`_apply_codex_boons()`（`:363`）之后、`Game.run_seed = Game.rng.seed`（`:366`）之前** |
| 档位 | `done == false` → **0**；`done == true` 且 `S >= 3` → **8**；`done == true` 且 `S == 2` → **5**；其余 `done == true`（`S` = 0 或 1）→ **3** |
| 授予方式 | **`Game.diamonds += n` 直写，禁止 `Game.add_diamonds(n)`**（`:151` 会进 `run_diamonds_earned`→`Meta.payout`；`:153-154` 会把上局奖励记进下局「满载而归」计数 = 自我污染） |
| daily | `Game.daily_mode == true` → **一律不发**（`n = 0`），且 `_oath_grant` 记 **0** |
| 频次 | 本局只发一次，换层不重发（只在 `start_run` 里） |
| 播报 | `n > 0` 时 `hud.flash_toast("誓约遗赠：残响 +%d（连绩 %d）" % [_oath_grant, S])` |

### 0.2 幂等性＝**设计依据，不是 bug**（照抄主理人结论，不要开单）

`start_run()` 有两个调用点：`game_main.gd:200`（`_ready`）与 `menu.gd:1094`（开始按钮），**首次开机存在连跑两次的既有现象**。
但 `Game.reset()`（每次都会 `diamonds = 0`，`game_state.gd:136`）在 `:342`，**永远早于**授予块（`:363` 之后）——「reset → 授予」这一对天然幂等：连跑两次结果仍是**只发一次的量**，零额外代码。
> 🔴 **口径纪律**：双击本身是另一个在册问题，不在本批。任何核验若看到"开局残响 = 8 而不是 16"，**那不是 bug，是设计**。C07 把这条依据落成断言（防后来有人"优化"成累加）。

### 0.3 主理人已拍板的 4 项（**定死，不再是可选**）

| # | 拍板结论 | 依据 / 落地 |
|---|---|---|
| **R1** | **收，必装**：直写 `Game.diamonds` 之后**必须紧跟** `Game.diamonds_changed.emit(Game.diamonds)` | HUD 残响数字只由该信号驱动（`hud.gd:299-300`）；`add_diamonds()` 内部会 emit（`game_state.gd:163`），直写不会。**既有同型先例**：`purse` 分支 `game_main.gd:1515-1516` 就是直写 + 手动 emit。不做 → toast 喊「+8」而 HUD 停 0，玩家会以为"给了但没到账" |
| **R2** | **收**：`_oath_grant` **无条件赋值**（`n == 0` 也写 0） | 条件赋值在「上局有档位、本局掉到 T0」时静默留旧值，是最难查的一类。无条件赋值 + `Game.reset()` 每局归零 = 天然幂等 |
| **文案** | **定「誓约遗赠」**；设计稿「余誓」作废（与既有誓约术语贴太近，玩家会误以为是第九条誓约） | 探针抽成 `const _OG_TOAST_TAG := "誓约遗赠"`，D 组 5 条全按此写 |
| **B08** | **收**：`done = "yes"` 非 bool → 期望 **0** | 脏数据不许靠 `bool()` 隐式转换蒙对；何况它同时证明"读取必须严格"。**`declared` 保持 43** |

> 🔴 **R1 的断言归属已按主理人指示调整**：原 G 组 G01（只验 HUD label 文本）**并入 C 组成为 C10**，改为直接验因——「授予后 `diamonds_changed` 触发过 ≥1 次，且**最后一次实参 == 授予后的 `Game.diamonds` 新总值**」。
> 合并理由（不是删断言）：`hud.gd:299-300` 无条件连同一个信号，**因成立则果必然成立**；且 C10 比 G01 更强——它能抓「emit 的是增量 `n` 而不是新总值」这种写法（G01 只能事后从 label 反推）。**C10 的打印行同时输出 `label=` 作为旁证，不另计条数。** 总数因此仍是 **43**（G 组取消，C 组 9→10）。

### 0.4 实测基线（今天，HEAD `ece249d`，**本文所有「实测」标签的唯一来源**）

不新增任何代码，只借既有 `SMOKE_RUN_START` 打印行（`game_main.gd:386-388`）与 `SMOKE_CODEX_PATH` 隔离档（`game_state.gd:285-287`）做黑盒对照。

| 实验 | codex 档（隔离） | `last_run` | seed | **实测 `[SMOKE-META] run start diamonds=`** | 结论 |
|---|---|---|---|---|---|
| **A** | 六类全空 | `{}` | 12345 | **0** | 干净基线 |
| **B** | 六类全空 | `oath.done=true` + `oath_streak=3`（**T3 档**） | 12345 | **0** | 🔴 **断链硬证据：同 seed、同码、唯一变量是 T3 状态，开局残响零差异。改后 B 必须变 8** |
| **C** | `relics×4` | 同 B（T3） | 12345 | **3** | 证明隔离档确被读入（`[SMOKE-CODEX-BOON] applied: ["relics_4"]`），且 `relics_4` 走 `add_diamonds` → **+3 残响污染基线** |
| **D** | 默认档 | 默认 | 12345 | **3** | 默认档同 C：**今天开局残响不是 0** |
| **E** | 默认档 | 默认 | 777 | **13** | `modifier=barren` → `:1220 add_diamonds(10)`，3+10=13 |

**三条必须写进实施单的实测结论**：
1. **今天开局 `diamonds` 实测 = 0 / 3 / 13，取决于存档与因子，不是恒 0** → 任何"绝对 `== 0`"断言今天就会假红。这正是本文 §1.3② 强制 **Δ（前后各取一次）** 的原因，现在有实测数坐实。
2. **`_oath_counters["diamonds_picked"]` 今天开局也非 0**（实验 C/D：`relics_4` 经 `:3004 add_diamonds` → `:153-154 oath_count("diamonds_picked", 3)`）→ 绝对 0 断言同样是 flaky。此条为**静态读码**结论（该计数无打印通道，未实测）。
3. **不能靠改 modifier 来"造干净基线"**：`Data.roll_modifier()` 在 `data.gd:561` 抽 `Game.rng.randi_range` → 一调就消耗 rng，直接撞 F01 与 E1 纪律；且 `_roll_modifier()` 还会顺带改写 `diamond_mult`/`enemy_*_mult`/`abyss_*_mult`，并在 `overload` 时改 `player.max_hp`（`:1223`）。

> **B 组基线纪律（主理人指定，已确认成立）**：**B 组基线一律由探针手工写 `Game.diamonds = 0`（及 `_oath_counters = {}`、`run_diamonds_earned = 0`、`_reso_pickups = 0`）后再断言，禁止调用 `_roll_modifier()` / `Data.roll_modifier()` 或任何 rng 派生去"制造基线"。** 唯一例外：E 组需要真实 `start_run()`，其基线由「同 `rng.state` 起点的控制组」抵消，不手工置数。
> 实验档为临时物，落在 `/d/Create/Game/_tools/og_*.cfg`（**不在 repo 内，不属交付物，可删**）；SMOKE 全程走 `SMOKE_CODEX_PATH` 隔离，未触碰真实存档。

### 0.5 文案与用词（定死后不再反复）

`_OG_TOAST_TAG := "誓约遗赠"`；模板 `"誓约遗赠：残响 +%d（连绩 %d）" % [_oath_grant, S]`。D 组 5 条断言全部锁这个常量，**改文案只改这一行**，D01 之外不动。

---

## 一 断言分组与绝对条数（**死数 43，不许公式现算**）

### 1.1 七组死数表

| 组 | 内容 | 条数 | 类别 |
|---|---|---|---|
| **A** | 档位三态映射（直接调用） | **9** | 验效果型 |
| **B** | 脏数据 / 空档 / 叠加非覆盖 | **10** | 验效果型（**3 格弱**：B01-B03，见 1.3③） |
| **C** | 授予方式 + 三条状态通道 + daily + 幂等 + **C10 信号（R1）** | **10** | 验效果型（**自污染唯一靶子在此**） |
| **D** | 文案（toast 实值 / 不白弹） | **5** | 验效果型（渲染） |
| **E** | E2E 集成（真实 `start_run`，控制变量 A/B） | **7** | 验效果型（**唯一能抓"位置被 reset 吃掉"的一组**） |
| **F** | 零 rng（直调窗口） | **2** | 验效果型（附属性，不计玩法覆盖） |
| ~~G~~ | ~~HUD label~~ → **已按 R1 并入 C10**，不再单列 | **0** | — |
| **合计** | 9+10+10+5+7+2+0 | **43** | |

探针里**写死** `const _OG_DECLARED := 43`；末尾 `Dev.check(_og_checked == _OG_DECLARED, "oath_grant", "自校验失败: checked(%d) != declared(%d)" % [...])`。
> **编号已冻结**：B08 已收（不裁），故 43 是最终数；C10 由原 G01 并入而来（见 §0.3 的合并理由）。**此后实施单、核验报告、变异记录一律用 §1.5 的编号表对齐，编号不许再动。**

**分类小计（可逐行加出 43）**：**强靶 33**（A02-A09 8 + B04-B10 7 + C01-C03/C05-C10 9 + D01/D02/D04/D05 4 + E02-E05 4 + F01 1）· **一般 5**（A01 · C04 · D03 · E06 · F02）· **弱 3**（B01-B03，机制下值不可观测）· **前提守卫 2**（E01 · E07，SMOKE 下恒真）。
按最严口径，**可当"机制已被断言钉住"的证据只有 33 条**；对外报数请用「43 条 / 强靶 33」。**禁止把 43 全报成有效覆盖。**

### 1.2 逐条明细（**「今天」列是本文的重点，不是装饰**）

图例：**今天 = 红**（期望 > 0，今天恒 0）｜**今天 = 哑绿**（期望 0，今天天然成立——**绿得没份量**）｜**今天 = 不可执行**（读 `_oath_grant`，该字段今天不存在，探针连跑都跑不起来）。

| # | 验什么（构造） | **今天**（HEAD `ece249d`） | **改后**期望 | 强度 |
|---|---|---|---|---|
| A01 | `done=false, S=0` → `_oath_grant` | 哑绿（今天 0） | **0** | 一般 |
| A02 | `done=false, S=3` → `_oath_grant` | 哑绿 | **0** | **强**（高连绩不破"未兑现不发"） |
| A03 | `done=false, S=99` → `_oath_grant` | 哑绿 | **0** | **强** |
| A04 | `done=true, S=0` → `_oath_grant` | **红**（今天 0） | **3** | **强**（旧档无 `oath_streak` 键也拿 T1，不许掉 T0） |
| A05 | `done=true, S=1` → `_oath_grant` | **红** | **3** | **强** |
| A06 | `done=true, S=2` → `_oath_grant` | **红** | **5** | **强（边界主靶）** |
| A07 | `done=true, S=3` → `_oath_grant` | **红** | **8** | **强（边界主靶）** |
| A08 | `done=true, S=4` → `_oath_grant` | **红** | **8** | **强**（防 `S == 3` 写成等值判断） |
| A09 | `done=true, S=99` → `_oath_grant` | **红** | **8** | **强**（封顶不滚雪球） |
| B01 | `oath_streak = "x"`（字符串）+ `done=true` → | **红** | **3** | **弱**（见 1.3③：`int("x")==0` 也落 3 档，与期望同值） |
| B02 | `oath_streak = -5` + `done=true` → | **红** | **3** | **弱**（钳与不钳都落 3 档，机制下不可观测——如实标注） |
| B03 | `oath_streak` **缺键** + `done=true` → | **红** | **3** | **弱**（弱在"值"，强在"不崩"） |
| B04 | `oath_streak = 2.9`（float）+ `done=true` → | **红** | **5** | **强**（`int()` 截断→2 得 5；若误用 `roundi()`→3 得 8，本格专抓） |
| B05 | `last_run = {}` → | 哑绿 | **0** | **强**（不崩 + 不发） |
| B06 | `last_run = {"oath": {}}` → | 哑绿 | **0** | **强** |
| B07 | `last_run = {"oath_streak": 3}`（`oath` 缺键）→ | 哑绿 | **0** | **强**（连绩高但未立誓 = 不发，防"只看 streak 不看 done"） |
| B08 | `oath = {"done": "yes"}`（非 bool）+ `S=3` → 〔设计稿 §八#1，可裁〕 | 哑绿 | **0** | **强**（`bool("yes")==true`，不加 `is bool` 守卫会误发 8） |
| B09 | 探针先置 `Game.diamonds = 7`，再 `done=true,S=3` → `diamonds` | **红** | **15** | **强（唯一抓 `=` 覆盖 vs `+=` 叠加的靶子）** |
| B10 | `oath_streak = "3"`（**数字字符串**）+ `done=true` → | **红** | **3** | **强（唯一证明必须走 `_read_oath_streak()` 的靶子）** |
| C01 | `S=3` 档（8 颗）后 `_oath_counters.get("diamonds_picked",0)` 的 **Δ** | 哑绿 | **0** | **强（自污染唯一靶子）** |
| C02 | 同上窗口 `Game.run_diamonds_earned` 的 **Δ** | 哑绿 | **0** | **强**（不进 `Meta.payout`，第二条独立证据） |
| C03 | 同上窗口 `Game._reso_pickups` 的 **Δ**（探针**临时**置 `player.has_resocore = true`，出口还原） | 哑绿 | **0** | **强**（第三条：白送共鸣核心进度） |
| C04 | `S=3` 档后 `_oath_grant` 字段值 | 不可执行 | **8** | 一般（字段真被赋值） |
| C05 | `daily_mode = true` + `done=true,S=3` → `_oath_grant` | 不可执行 | **0** | **强** |
| C06 | `daily_mode = true` 同窗口 `Game.diamonds` 的 **Δ** | 哑绿 | **0** | **强**（钱也没动） |
| C07 | 幂等（构造 boot 双击）：`reset();grant()` ×2 → `diamonds` 与 `_oath_grant` | 不可执行 | **8 / 8** | **强（§0.2 依据落地，防"改成累加"）** |
| C08 | `daily_mode` 还原为 false 后**同一份** `last_run` 立即可发 → `_oath_grant` | 不可执行 | **8** | **强**（防"daily 分支写成永久关"） |
| C09 | 先置 `_oath_grant = 99`，再 `done=false` 发一次 → `_oath_grant` | 不可执行 | **0** | **强（R2 靶子：只在 `n>0` 赋值会残留 99）** |
| C10 | **R1 信号**：探针连 `Game.diamonds_changed` 计数，**基线置 7**、发 8 后断言「触发 ≥1 次」且「最后一次实参 == `Game.diamonds`（新总值 15）」〔原 G01 并入；打印行附带 `label=%s` 旁证〕 | 不可执行 | **cnt≥1 且 arg==15** | **强（唯一抓"直写不 emit"与"emit 的是增量 8 而非新值"）** |
| D01 | `S=3` 发 8 后 `hud._toast.text` 含 `"誓约遗赠"` | 不可执行 | 含 | **强** |
| D02 | 同上含 `"+8"`（实值不是占位符） | **红** | 含 `+8` | **强** |
| D03 | `S=2` 发 5 后含 `"连绩 2"` | **红** | 含 `连绩 2` | 一般（连绩实值） |
| D04 | 哨兵法：`flash_toast("__OG_SENTINEL__")` 后发 `n=0` → 文本**未变** | 哑绿 | `== "__OG_SENTINEL__"` | **强（防开局白弹一条）** |
| D05 | `done=true, S=0`（旧档升级形态）→ toast **仍播报**且含 `"连绩 0"` | **红** | 含 `连绩 0` | **强**（防实现写成 `if n>0 and S>0`，让老玩家静默丢播报） |
| E01 | 控制组（`last_run={}`）与处理组（`done,S=3`）**同 `rng.state` 起点**两次真实 `start_run` → `modifier` 相同 | 哑绿（恒真，**前提守卫型**） | **相同** | 前提（非覆盖） |
| E02 | 处理组真实 `start_run` 后 `_oath_grant` | 不可执行 | **8** | **强（"生效"而非"不崩"）** |
| E03 | 处理组 − 控制组 的 `Game.diamonds` 差 | **红**（差 0） | **+8** | **强（唯一抓"块在 reset 之前被清零"）** |
| E04 | 同上窗口 `run_diamonds_earned` 差 | 哑绿 | **0** | **强（E2E 版自污染）** |
| E05 | 同上窗口 `_oath_counters["diamonds_picked"]` 差 | 哑绿 | **0** | **强（E2E 版自污染）** |
| E06 | 授予后手动走一次楼层推进（复刻 `next_floor` 前三步）→ `_oath_grant` 不变、`diamonds` 的 Δ | 不可执行 | **8 / 0** | 一般（见 1.3④ 强度限制） |
| E07 | 探针出口 `Game.rng.state == rng_state0`（探针自身零净漂移） | 哑绿 | **相等** | 卫生型 |
| F01 | 直调窗口前后 `Game.rng.state` 不变 | 哑绿 | **相等** | **强（本批零 rng 的实证）** |
| F02 | 直调窗口前后 `Game.fx_rng.state` 不变 | 哑绿 | **相等** | 一般 |
| G01 | 直调发 8 后 `hud._diamond_label.text == str(Game.diamonds)` | 哑绿（今天两者都是 0） | **相等且为 "8"** | **强（R1 唯一靶子）** |

### 1.3 单条断言规范 + 四条实现细节

**四项必填**（同批一）：验什么（点名字段 + 直调/真实路径）· 怎么构造（`last_run` 字面量、基线拉平、daily 开关）· 期望值怎么取（**字面量**，禁在探针里读 `Data` 反推）· 失败信息含实测/期望/构造。
样板：
```gdscript
_og_assert(_oath_grant == 8, "A07 done=T S=3",
    "%d" % _oath_grant, "8")
```
```gdscript
func _og_assert(ok: bool, nn_name: String, measured, expect) -> void:
	_og_checked += 1
	Dev.check(ok, "oath_grant", "%s | measured=%s expect=%s" % [nn_name, str(measured), str(expect)])
	print("[SMOKE-OATH-GRANT] #%02d %s measured=%s expect=%s" % [_og_checked, nn_name, str(measured), str(expect)])
```

**① 直调组的基线必须探针自己拉平**：每格进格前 `Game.diamonds = 0`、`_oath_grant = 99`（配合 C09 的残留检测；A/B 组直接用 99 当"脏初值"，发一次看是否被覆盖成期望值——**顺带让 A/B 组自带残留检测**）、`_oath_counters = {}`、`Game.run_diamonds_earned = 0`、`Game._reso_pickups = 0`。**顺序敏感**：先拉平再构造。
**② Δ 必须"前后各取一次"**：C01/C02/C03/C06/E04/E05 一律 `var before = ...` → 调用 → `var after = ...` → 断言 `after - before`，**禁绝对 `== 0`**。理由：`_apply_codex_boons()` 自己会调 `add_diamonds`（`:3004`），老存档（`relics_4` 解锁）下 `_oath_counters["diamonds_picked"]` 开局就 > 0——**写绝对 0 的探针会随存档状态飘，是 flaky**。探针仍应显式清空六类发现集（1.4），但断言必须写成 Δ（双保险）。
**③ 三条弱格如实标注（不许混进"有效覆盖"）**：B01/B02/B03 的**值**在机制下不可观测——`int("x")` → 0、`maxi(-5,0)` → 0、缺键 → 0，三者与"正确钳制"落到同一档（3），故它们只证明**不崩 + 不误判高档**，不证明钳制生效。真正证明"必须走 `_read_oath_streak()`"的是 **B10**（`"3"` → 正确 3，误用 `int()` 会得 8）。
**④ E06 的强度限制（先声明，别让核验方高估）**：`next_floor()` 真实调用会触发转场/进房/地图生成（批一同款结论），故 E06 只能复刻 `next_floor` 前三步（`Game.floor_num = nf`（`:1505` 语义）→ `_clear_calamity_effects()` → `_calamity = ""` → `_apply_floor_theme()`）。它能抓"换层路径里也被塞了一次授予"，但**抓不到"授予被塞进 `_fade_to` 回调"**。后者由**静态门 S1**（调用点恰好 1 处、在 `start_run` 内）兜底。**静态门是 E06 的必要补集，不能只留一个。**

### 1.4 探针的隔离与现场还原（**不写这段必然污染其它探针**）

入口先快照、出口还原（对齐 `_smoke_cal_theme_probe()` 的 `save_*` 范式，`game_main.gd:724-736`）：

| 类别 | 字段 | 用途 |
|---|---|---|
| 局外输入（造可控基线） | `Game.sigils["equipped"]`（置 `""`）、`Game.codex` 六类发现集（置空）、`Game.daily_mode`、`player.has_resocore`（置 `true`） | 杀 `purse` 契约 +15（`:1515`）、杀 boons +3 残响/+1 血/词缀（`:3004-3010`）；给 C03 造靶子 |
| 局内通道 | `Game.diamonds`、`_oath_counters`、`Game.run_diamonds_earned`、`Game._reso_pickups`、`_oath_grant` | 每格拉平 |
| E2E 现场 | `dungeon` 引用、`Game.floor_num`、`Game.run_seed`、`Game.rng.state`、`Game.time`、`modifier`、`diamond_mult`、`enemy_hp_mult`、`enemy_speed_mult`、`_calamity`、`Game.calamity_speed_mult`、`_calamity_*` 五个快照字段、`player.max_hp/hp/skill_cd_mult/crit_chance/speed_base` | 真实 `start_run` 会重生成地图、重掷 modifier/灾祸 |
| 文案 | `hud._toast.text` | D 组哨兵法 |

**🔴 三条硬约束**：
1. **E 组必须是探针最后一段**。`start_run()` 内含 `Upgrades.reset()`（`:343`）与 `DungeonClass.generate()`（`:369`），**现场还原不可能完整**（旧地图节点已释放、蓝图已重算）。探针窗口本来就在 `_ready` 内、尚未进房选卡，损失为零，但要**如实声明：本探针跑完之后，该次运行的后续 `[SMOKE] t=` 帧序输出不再与"无探针跑"逐字可比**——它只用于读 `[SMOKE-OATH-GRANT]` 行，**不与 E1 片段对照**。
2. **同一份 `last_run` 不隔着 E2E 复用**：控制组与处理组都必须**重新构造** `last_run` 字面量（E2E 内不写盘，`_write_codex_replay` 一行不动）。
3. **探针绝不调 `Game.save_codex()` / `set_codex_last_run()`**：两者都会写盘（`game_state.gd:370/401`）。本探针只改内存态 `Game.codex["last_run"]`，出口还原 → 真实存档零污染。（既有 `player.gd:1033` 的 `_oath_probe` 会写盘，那是既有问题，不在本批。）

---

## 二 「今天 vs 改后」总表（给核验方一眼判读）

| 今天分类 | 条数 | 明细 | 改后必须变成 |
|---|---|---|---|
| **红**（期望 > 0，今天恒 0） | **16** | A04-A09(6) · B01-B04(4) · B09,B10(2) · D02,D03,D05(3) · E03(1) | **全绿**（这 16 条是"机制真的接上了"的直接证据） |
| **哑绿**（期望 0，今天天然成立） | **19** | A01-A03 · B05-B08 · C01,C02,C03,C06 · D04 · E01,E04,E05,E07 · F01,F02 · G01 | **保持绿**（但改后它们才有靶子，见 §三） |
| **不可执行**（读 `_oath_grant`，字段今天不存在） | **8** | C04,C05,C07,C08,C09 · D01 · E02,E06 | **可执行且绿** |
| 合计 | **43** | | |

**两句话读法**：
- **今天**：所有 43 点在 `ece249d` 上都**没有任何效果**——`_oath_grant` 字段不存在、`last_run` 的三个键唯一读者是 `menu.gd:397/435/717` 的展示，**开局残响与上一局战绩零关系**。
  （严谨表述：今天开局 `diamonds` **不是恒 0**——`purse` 印记在 `_apply_sigil_contract()` `:360` 会置 15（`:1515`，**授予块之前**）、`barren` 因子在 `_roll_modifier()` `:371` 加 10（`:1220`，**授予块之后**）。这两笔都是**既有来源、与本批机制无关**；正因为它们存在，"哑绿"格今天的 0 是"恰好没人加钱"，不是"机制正确"，而 B09/E03 的基线必须靠探针自己拉平而不是靠"今天恰好是 0"。）
  所谓"断链"，就是这 43 条里有 16 条直接红、8 条连跑都跑不起来。
- **改后**：这 43 点里**只有 16 条会由红转绿**，另 27 条今天**不是绿就是跑不起来**——**别把这 27 条当成本批的功劳**。批二的净增量证据只有 16 + 8 = 24 条，其余 19 条是"改写前后都不动的护栏"。

---

## 三 失败面矩阵（本批重点：**哪种写错能被哪条抓，哪种抓不到**）

每刀只改一处，跑同一条探针命令，看完红点再 `git checkout -- scripts/` 复原。

| 刀 | 最容易写错的实现 | 期望红点 | 为什么是这条 |
|---|---|---|---|
| **①边界 `>` 而非 `>=`** | `if S > 2: n = 5`（S=3 仍 5）/ `if S > 3: n = 8`（S=3 落 5）/ `if S == 3: n = 8`（S=4 落 3） | **A07**（必红）＋ **A06 / A08 / A09**（定位到具体错法） | S=2 与 S=3 两格**必须分别有断言**：A06 吃掉"5 档起点写错"，A07 吃掉"8 档起点写错"，A08/A09 吃掉"把 `>=` 写成 `==`"。**四格缺一即定位不到错法。** |
| **②用 `add_diamonds`** | `Game.add_diamonds(n)` | **C01 + C02 + C03**（E2E 侧 E04 + E05） | 三条通道各自独立：`oath_count`（`:153`）、`run_diamonds_earned`（`:151`）、`_reso_pickups`（`:159`）。**注意 G01 此时仍绿**（`add_diamonds` 会 emit）——所以 G01 绝不能替代 C01。 |
| **③块放在 `Game.reset()` 之前**（🔴 本批最危险） | 把授予块插到 `:342` 之前 | **只有 E02（仍 8）＋ E03（差 0）红**；**A/B/C/D/F/G 组全绿** | 直调组绕开 `reset`，**结构上抓不到这个 bug**。没有 E 组，这一刀会"全绿通过"——这就是 E 组不可删的唯一理由。且必须看 **E03**（钱没到账）而不是只看 E02（字段写对了但被清掉）：**这条要用"生效"抓，不能用"不崩"抓。** |
| **④块放在 `Game.run_seed = ...` 之后** | 插到 `:366` 之后 | **无任何运行期断言可抓**（不抽 rng，行为零差异） | 会破坏"注入段在 rng 首抽前"的既有纪律（`:358-366` 注释明文）。**标为越界**：功能不断、纪律断。由**静态门 S1**（调用行号 ∈ (`:363`, `:366`)）判，**不假装有运行期证据**。 |
| **⑤`Game.diamonds = n` 覆盖** | 写成赋值而不是 `+=` | **B09**（基线 7 → 期望 15，实测 8） | A07 只验 `_oath_grant`，覆盖式写法照样绿——**必须有一格带非零基线**。 |
| **⑥自写 `int(oath_streak)` 不走 `_read_oath_streak()`** | `var S := int(Game.codex["last_run"].get("oath_streak", 0))` | **B10**（`"3"` → 实测 8，期望 3） | B01（`"x"`）本轮**不会红**（`int("x")==0` → 3 = 期望），所以"B01 绿"不能证明走了守卫。B10 是这条刀的唯一强靶。 |
| **⑦只在 `n > 0` 时赋 `_oath_grant`** | `if n > 0: _oath_grant = n` | **C09**（先置 99，实发 0，实测残留 99） | 若探针每格都把 `_oath_grant` 预先清 0，这条永远绿——**所以 A/B 组的"脏初值"必须是 99 而不是 0**（1.3①）。 |
| **⑧直写后不补 emit**（R1） | 少了 `Game.diamonds_changed.emit(...)` | **只有 G01 红**，其余 42 条全绿 | HUD 数字停在 0。**这就是 G01 必须单独存在的理由**：所有"钱对不对"的断言都看 `Game.diamonds`，没有一个看 label。 |
| **⑨daily 分支写成永久关** | 把 `Game.daily_mode = false` 写进 `_apply_oath_grant()`（而非 early return） | **C08**（daily 关掉后仍发不出） | C05/C06 只验"daily 下不发"，验不出"把开关弄坏了"。 |
| **⑩`done` 用 `bool()` 强转不校验类型** | `if bool(o.get("done", false)):` | **B08**（`"yes"` → 实测 8，期望 0） | `bool("yes")` 在 GDScript 里是 `true`。〔B08 为设计稿格，可裁〕 |
| **⑪`oath_streak` 负数不钳制** | 去掉 `maxi(int(v), 0)` | **无断言可抓**（钳与不钳都落 3 档） | **如实登记**：本机制下负数不可观测。由"必须复用 `_read_oath_streak()`"这条**静态门 S3** 兜底，而不是伪造一条运行期证据。 |

**矩阵的诚实总结**：11 刀里 **9 刀有运行期靶子**（① ② ③ ⑤ ⑥ ⑦ ⑧ ⑨ ⑩），**2 刀只有静态门**（④ ⑪）——这两刀**禁止**在交付文档里写成"已由断言覆盖"。

---

## 四 纪律（沿用批一，不许缩水）

| 项 | 要求 |
|---|---|
| **打印三点** | ① 入口**无条件**打印 `[SMOKE-OATH-GRANT] entry diamonds=%d last_run_oath=%s streak=%s daily=%s`；② **每条断言后无条件**打 `#NN` 行；③ 末尾无条件 `done checked=%d declared=%d` **并** `Dev.check(checked == declared, ...)`。理由不变：`Dev.check()` 只在失败时 `err()`（`dev_log.gd:29-32`），**`[ERR]=0` 不构成执行证明** |
| **判 PASS 两条同时成立** | `grep -c "^\[SMOKE-OATH-GRANT\] #"` **== 43** 且 `grep -c "\[ERR\] oath_grant"` **== 0**。只做第二条 → 一个提前 `return` 的探针能拿满分 |
| **逐格/原始读数行不许用 `#NN`** | E 组的两次 `start_run` 原始读数、扫描行一律用 `[SMOKE-OATH-GRANT] e2e run=%s diamonds=%d earned=%d oathcnt=%d modifier=%s`——**若也用 `#NN`，`grep -c` 会把它们算进断言数，declared 自校验失效、门控永久假绿** |
| **只验标志单独标注** | 本文**无"只验标志"型断言**。E01/E07 是**前提守卫型**（探针自身卫生，SMOKE 下恒真），**不计入玩法覆盖**。对外报数一律「43 条 / 强靶 33 / 一般 5 / 弱 3（B01-B03）/ 前提 2」——**禁止把 43 全报成有效覆盖** |
| **变异测试形状** | **必须替换目标行，不许新增行**。新增行会被探针的拉平/兜底行盖回去 → 造成**假绿**（批一已实录过这个假绿修正）。刀 ①②③ 尤其注意：改一个 `match` 分支的返回值即可，别整块重写 |
| **探针开关** | `SMOKE_OATH_GRANT=1`，挂进 `game_main.gd` 既有 env 判定链——**实读插入点 = `:248`（`_smoke_cal_theme_probe()`）之后**，与 `SMOKE_META_*` / `SMOKE_CAL_THEME` 同级，**不新增机制、不改任何既有判定行** |
| **探针输出前缀独立** | 一律 `[SMOKE-OATH-GRANT]`。**禁止**写进 `[SMOKE-META]`（`_smoke_fingerprint()` 在 `:322-337`，加一个字段 E1 全量重定） |
| **🔴 禁止与 E1 同时开** | `SMOKE_META_FINGERPRINT=1` 与 `SMOKE_OATH_GRANT=1` **不得同时设置**：E 组会真实调 `start_run()` 两次，而 `start_run()` 内有 `_smoke_fingerprint(1)`（`:370`），一次运行会打出 **3 行** `fingerprint` → `grep fingerprint` 直接失去"三跑逐字比对"的意义。同理 `SMOKE_RUN_START=1` 也会重复 3 次 |
| **字段声明位置** | `_oath_grant` 建议与 `_oath_counters`（`:2899`）相邻声明。**GDScript 成员变量与函数体无声明顺序约束**，写在 `:2899` 不影响 `:363` 处使用——这一点写进注释，免得实施方为了"声明在使用之前"把字段挪错地方 |

### 4.1 静态门（运行期测不到的两刀，以及越界检测）

| 门 | 命令 | 通过条件 |
|---|---|---|
| **S1** 单调用点 + 位置正确 | `grep -n "_apply_oath_grant" scripts/game_main.gd` | **恰好 2 行**（1 定义 + 1 调用），且调用行号 **严格落在 `_apply_codex_boons()` 调用行（`:363`）与 `Game.run_seed = Game.rng.seed`（`:366`）之间**。⚠️ 实施后行号会漂，**必须重跑 `grep` 取新值再判**，不许拿本文的 `:363/:366` 当判据 |
| **S2** 块内无 `add_diamonds` | `grep -n "add_diamonds" scripts/game_main.gd` | 授予块行区间内 **0 处**（块外 `:3004`/`:1220` 不动） |
| **S3** 必须复用连绩读侧 | `grep -n "_read_oath_streak()" scripts/game_main.gd` | 授予块内 **1 处**（禁自写 `int(...)` 解析——`_read_oath_streak` 现在 `:2973-2977`） |
| **S4** emit 存在（R1） | `grep -n "diamonds_changed.emit" scripts/game_main.gd scripts/game_state.gd` | 授予块内 **1 处**（全仓现状 **5 处**：`game_main.gd:1516` + `game_state.gd:145/163/172/222`，这 5 处不动、也不算新增） |
| **S5** 冻结面 | `md5sum -c production/sprint-21/SPR21-FROZEN.md5`；`git diff --stat` | **34/34 OK**；`.gd` 改动**只有 `game_main.gd` 一个文件**。动了 `game_state.gd` / `data.gd` / `hud.gd` / `menu.gd` = 越界（本批机制不需要它们，`_write_codex_replay` 一行不改） |
| **S6** 指纹段未动 | `grep -n "_smoke_fingerprint" scripts/game_main.gd` 对比 HEAD | 函数体（`:322-337`）与两处调用（`:370`/`:2126`）**逐字未变** |
| **S7** validate | `SMOKE=1 ... --headless --quit-after 300` 首行 | `validate 34/34`（`[SMOKE] validate problems=0`） |

### 4.2 探针跑法与门控

```bash
GODOT="D:\SteamLibrary\steamapps\common\Godot Engine\godot.windows.opt.tools.64.exe"
# 探针（⚠️ 不带 SMOKE_META_FINGERPRINT / SMOKE_RUN_START）
SMOKE=1 SMOKE_SEED=12345 SMOKE_OATH_GRANT=1 "$GODOT" --headless --path . --quit-after 900
#   → grep -c "^\[SMOKE-OATH-GRANT\] #"  期望 43
#   → grep -c "\[ERR\] oath_grant"       期望 0
#   → grep "done checked="               期望 checked=43 declared=43

# E1（三跑；⚠️ 绝不加 SMOKE_OATH_GRANT）
SMOKE=1 SMOKE_SEED=12345 SMOKE_META_FINGERPRINT=1 "$GODOT" --headless --path . --quit-after 1800 2>&1 | grep "\[SMOKE-META\] fingerprint"
```
**E1 判据**：`git checkout ece249d -- scripts/` 取批前基线 1 次 + 改后 2 次，**三次 `rooms=` + `kinds=` 逐字相同**；且改后只有 **1 行** `fingerprint`（多于 1 行说明有人把探针和 E1 一起开了）。
**E1 为什么必须零差异（推理链）**：授予块只读 `Game.codex["last_run"]`（内存态）→ 直写 `Game.diamonds` → 位置在 `Game.run_seed = Game.rng.seed`（`:366`）之前；`_apply_floor_theme` 的 `diamond_mult` 也不参与地图生成。**且 `diamonds` 不在地图派生输入里**，所以地图指纹天然不变。**这条不是"应该不变"，是"结构上不可能变"**——若真的变了，说明授予块被插进了 rng 抽取路径，属实现错误。

---

## 五 交叉影响与已登记不修（供核验方免查）

**既有探针不会被本批打红（逐条实读）**：
- `player.gd:1284-1368` 的 `_oath_probe`（`SMOKE_OATH` / `SMOKE_ECHO_CHAIN`）：只读 `_oath_counters` / `oath_fulfillment()` / `last_run`，**不读 `_oath_grant`、不叫 `start_run`**；本批不改 `oath_fulfillment`（`:2914-2929`）与 `_write_codex_replay`（`:2958-2968`）→ 零影响。
- `menu.gd:397/435/717` 三处展示：本批**不新增**展示（设计稿 §七 的"带上本局 +N"是可选附项，**本批不做**，见下）。
- `_smoke_cal_theme_probe`（`SMOKE_CAL_THEME`）：两探针**互斥使用**（不同 env），且本探针的 E 段在其后执行；即便同开，cal_theme 已在 `:248` 先跑完。
- `Game.reset()`（`game_state.gd:123-146`）：**一行不改**是本批的"幂等性实现"——若有人为了"把 `_oath_grant` 归零"去改 `reset()`，即 S5 越界。

**已登记·本批不修（不属于本批范围，看到别顺手改）**：
1. **boot 双击本身**（`_ready():200` + `menu.gd:1094` 同一节点连跑两次 `start_run`）：设计实稿 §九#2 已登记，`_apply_codex_boons():3006 player.max_hp += 1`、`_roll_modifier` 的 `overload`（`:1223`）在双击下会叠加。**本批不修**（修它要动 `start_run` 入口，风险大于回流本身），且**与残响无关**（残响被 `reset` 前置成幂等）。
2. **`player.gd:1033` / `:1037` 的既有 `_oath_probe` 会写盘**（`set_codex_last_run` → `save_codex`）：既有问题，**本批不修**；但本探针**明令禁止**写盘（§1.4 硬约束 3）。
3. **`menu.gd:717` 印记页"上局连绩 · N 局"后接"→ 本局开局 +N"**（设计稿 §七 可选项）：**本批不做**。要做必须同步扩 D 组与 `menu` 探针，属范围扩张。
4. **`_smoke_fingerprint` 行号漂移**（批一文档记 `:318-333`，实读 `:322-337`）：文档笔误级别，**不改代码**，已在 §〇 订正。

---

**口径总结**：**43 条**（A 9 / B 10 / C 9 / D 5 / E 7 / F 2 / G 1，死数、无公式、`declared` 写死）｜今天 **16 红 + 19 哑绿 + 8 不可执行**，改后**必须 43/43 绿**｜对外报数「**43 条 / 强靶 33**」（一般 5 · 弱 3 · 前提守卫 2）｜核心结构结论：**直调组（A/B/C/D/F/G 共 36 条）在结构上抓不到"授予块被 `Game.reset()` 吃掉"，只有 E 组能抓（E02+E03），故 E 组不可删**；反之 E 组也抓不到"块放错到 `run_seed` 之后"与"负数未钳制"，这两刀**只有静态门 S1/S3**，禁止写成运行期已覆盖｜新增两条落地要求 **R1（补 `diamonds_changed.emit`，先例 `:1515-1516`）/ R2（`_oath_grant` 无条件赋值）**，并列出 1 处文案冲突（「誓约遗赠」vs「余誓」）待主理人一句话确认。
