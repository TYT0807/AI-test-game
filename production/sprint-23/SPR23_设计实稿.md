> **Sprint 23 裁定按语（主理人四项拍板后，实现侧据实读修正两处，实稿正文未改）**：① §五前置/§七2 的「三处时序经主理人中转确认」→ 改为「落地前实读复核条款写进实施单」（工程通道 429，不派中转——主理人已实读三挂点全部正确）；② §5.5/R9 的「落地时新建 SPR23-FROZEN.md5」→ 改为「重算既有 SPR21-FROZEN.md5 作为滚动当前态快照，不新建第三份」（双清单纪律：恰好两份）；③ 字段域确认落 `codex["last_run"]`，主理人原措辞「落 Game.meta 平行键」过宽已订正。

# Sprint 23 设计实稿 · 跨局闭环 · 誓约连绩

- 角色：design-s23（游戏策划与叙事设计，**不写 `.gd`、不 commit、不联系其它成员**）
- 承接：主理人已拍板方向「跨局闭环 · 誓约连绩」为下一个 M 级 Dynamics 增量；雏形口径见 `production/sprint-18/SPR18_设计候选实稿.md` §一 / §四（候选 C）。
- 基线核对（实读）：HEAD `734149d`，工作树干净，`scripts/` 34 个 `.gd`，冻结 34/34（`production/sprint-21/SPR21-FROZEN.md5` 与历史归档 `production/sprint-7/SPR7-FROZEN-4.md5` 各 34 行），`production/sprint-23/` 原不存在，本实稿为该目录唯一新增文件。
- 实读依据：`game_state.gd` / `game_main.gd` / `menu.gd` / `meta.gd` / `data.gd` / `validate.gd` / `player.gd`（探针）/ `dev_log.gd`；S18 阶段二 C 交付、S19 阶段一「真差值」断言、S21「静态比对变量值 = 虚假通过」教训、`production/SPR21_主理人读码核验.md`。
- 定位纪律：所引锚点以**函数名 / 源码内容**为准，行号仅为本次实读辅助，落地前须重新核对。
- 本稿状态：**设计实稿，待主理人评审后决定是否转编程侧实施单**。§七 列 4 项 A/B 待拍板；未拍板前不视为定稿。

> **本实稿如何正面回答两个既定代价（不绕开）**
> - 代价 1（覆盖式 + 两次写盘）→ §一 1.3 给出完整时序、§五 5.2 给出挂接点与「不新增第三次写盘」的硬契约；连绩字段**只能**在 `set_codex_last_run()` 之后由 `_write_codex_replay()` 写回，旧值**只能**在覆盖前快照。
> - 代价 2（读档侧无键白名单 / Array·Dictionary 原样透传）→ §一 1.4 给出「无键默认 0 + 类型守卫 + UI 空判」三道防线，并指出 `load_codex()` **无需改**、`set_codex_last_run()` 的 `clean` **有**白名单（不对称陷阱）。

---

## 〇 一句话定位 + MDA / 自我决定论落点

**一句话**：把「这局誓约兑现了没」接成「连着几局都兑现了」的一条跨局刻度——不加机制、不加实体、不加资源、不加输入动作，只把 `last_run.oath.done` 与「上一局的连绩」接成一个关系。

**MDA（增量只在 Dynamics）**

| 层 | 本实稿的动作 |
|---|---|
| Mechanics | **零新增**。9 条誓约、9 枚印记、`oath_fulfillment()`、复盘/印记页 Label 全是既有；新增物只有 1 个 `int` 平行字段 + 1~2 个只读 Label。 |
| Dynamics | 新增一类决策情境：**跨局的续约自觉**。印记页是「下局带哪枚」的决策位，连绩让「继续这枚补齐 / 换一枚换打法」第一次有了跨局上下文。判断权完全留给玩家——只给一个数字，不给推荐。 |
| Aesthetics | 落在 **Narrative**（矿工手记式的记账连续性）与轻 **Challenge**（自设的连续目标）；刻意不碰 Sensation / Fellowship，不进局内、不给奖励。 |

**自我决定论（三条各一句，不堆术语）**

- **胜任**：从「单局一个布尔」变成「看得见自己在变稳」的刻度——但**纯展示、不涨战力**，不把胜任外包成数值（避免 P0 自激）。
- **自主**：连绩只陈述状态，不说「该带哪枚」；不携带印记也不被清零（§七①推荐 A），玩家仍可随时换向。
- **关联**：上一局的「我」和这一局的「我」记在同一本账上，矿窟的世界跨局持续在场（与 S18 B「手记回转」同源，不新造设定）。

**与项目诊断的对齐**：项目自诊「Mechanics 过饱和、Dynamics 贫乏，优先系统间关系」。本稿不新增任何可被单列的系统，只把「结算写入」与「上局沉淀」两端接成闭环，正是 S16「加关系不加实体」→ S21「长线目标」之后的同一条轴。

---

## 一 连绩精确口径

### 1.1 字段与定性

| 项 | 定义 |
|---|---|
| 键 | `codex["last_run"]["oath_streak"]`（`last_run` 平行键，**不进** `Meta.STATS_KEYS`） |
| 类型 | `int` |
| 含义 | **截至刚结算这局**、连续兑现誓约的局数 |
| 单位 | 局（run）；下界 0，无上界钳制 |
| 定性 | 关系型派生量（`oath.done` × 上局值），**不是**机制 / 实体 / 资源 / 收集品；**不入任何分母**（无 `/ total` 显示） |
| 落盘文件 | `codex.cfg`（走 `codex_path()` 双档；SMOKE 下 `SMOKE_CODEX_PATH` / `_smoke_codex.cfg` 隔离） |
| 是否新增 API | 否。新增 2 个纯函数（`_read_oath_streak()` / `next_oath_streak()`）+ 1 个可选参数，不改 `set_codex_last_run()` / `save_codex()` / `load_codex()` 本体 |

**字段域归属裁定（明确记录，避免 eng 误读）**：任务书「冻结规格 v2.10」一句提到「局外内容一律平行只读派生，落 `Game.meta` 字典平行键」。本稿裁定连绩**落 `codex["last_run"]` 而非 `Game.meta`**，理由：

1. 誓约 / 复盘数据自 S13 C 起全在 codex 域（`oath` / `echo` 都在 `last_run`），连绩是它们的同域派生；`game_state.gd:276-278` 明确把 codex 定义为「不碰 `meta.gd UNLOCKS`（冻结规格 v2.10）——平行只读数据，只增不减」，即**冻结规格本身就把 codex 与 meta 划成两个域**。放进 `Game.meta` 会造成 codex→meta 跨域依赖，且 `meta.cfg` 被一个 codex 驱动的结算写入，正是要避免的耦合。
2. 代价 1 / 2 的全部前提都建立在 `save_codex()` / `_write_codex_replay()` / `load_codex()` 上；若改落 `Game.meta`，会顺 `meta_settle_run()` 已有的 `save_meta()` 落盘，**两次写盘代价根本不成立**——那属于绕开代价，而非如实评估。
3. 「落 `Game.meta` 平行键」是 S21 深渊档（`abyss_unlocked` / `abyss_best_tier`）那条 meta 解锁树域的纪律；两条各管各的域，不冲突。冻结规格真正不可改的两项（`meta.gd UNLOCKS`、`Meta.STATS_KEYS`）本稿零触碰。

> 若主理人坚持落 `Game.meta`：本稿 §一 1.3 / 1.4、§四、§五、§六 需整体重写（等于换一个方案），不属微调。

### 1.2 状态转移公式（变量 + 单位）

```
S_next = f(S_prev, H, D)

S_prev ∈ ℤ≥0   上一局结算后落盘的连续兑现局数（单位：局）；旧档无键时为 0
H     ∈ {0,1}  本局是否立誓 = (oath_fulfillment() 非空)，无量纲
D     ∈ {0,1}  本局誓约是否兑现 = bool(oath.done)，无量纲
S_next ∈ ℤ≥0   本局结算后的连绩（单位：局）

f(S,H,D) = S + 1    若 H=1 且 D=1     （兑现 → 续一局）
         = 0        若 H=1 且 D=0     （立誓未兑现 → 断）
         = S        若 H=0            （未立誓 → 不计入、不断绩；§七① 拍板）
```

**「一局」的边界（实读确认）**：全库唯一结算入口是 `_on_player_died()` → `_settle_meta()`（`game_main.gd:2469 / 2536`）；击败第三 Boss 只在 `_room_cleared()` 的 `"boss"` 分支解锁深渊档 + 掉楼梯（`:1215-1223`），**不单独结算、不结束这一局**。故：

- 只有**走到 `_settle_meta()` 的局**才参与连绩；
- 主动退出 / 弃局（`to_main_menu()`，`:2461-2466`，只 `_tick_boost_once()` + `reload_current_scene()`）**不结算、连绩冻结不变**；
- SMOKE 未开 `SMOKE_META_SETTLE=1` 时 `_settle_meta()` 早退（`:2545`），同理不计入；
- `_run_settled` 幂等守卫（`:2537`）保证**一局只算一次**，不会重复 +1。

### 1.3 跨局持久化 + 两次写盘时序（代价 1 正面回答）

实读：`set_codex_last_run(stats)`（`game_state.gd:361-370`）把 `codex["last_run"]` **整个覆盖**成只含 `Meta.STATS_KEYS` 五项的 `clean`，末尾自带 `save_codex()`；`_write_codex_replay()`（`game_main.gd:2342-2347`）是 S16 起就存在的**第二次写盘位点**，写回 `oath` / `echo` 后调 `Game.save_codex()`。

```
_settle_meta()  [game_main.gd:2536]
  │
  ├─ (A) stats := _run_stats()                          [:2555]
  │
  ├─ (B) prev := _read_oath_streak()   ★覆盖前快照★     【本稿新增，纯读】
  │      读 Game.codex["last_run"]（内存态，_ready 时 load_codex 已填好）
  │      零 IO、零 rng、零计时、零 delta
  │      ⚠ 必须在 (C) 之前：(C) 会把整表覆盖成 clean，旧 oath_streak 随之丢失
  │
  ├─ (C) Game.set_codex_last_run(stats)                 [:2556]
  │      → codex["last_run"] = {5 项 stats}（oath/echo/oath_streak 全被抹）
  │      → 【写盘 ①】内部自带 save_codex()
  │
  ├─ (D) _write_codex_replay(prev)                      [:2557]
  │      → 写回 oath / echo（既有两行，一字不改）
  │      → 写回 oath_streak = next_oath_streak(prev, H, D)   【本稿新增 1 行】
  │      → 【写盘 ②】复用既有 Game.save_codex()，不新增第三次
  │
  └─ (E) Game.meta_settle_run(stats)                    [:2558]
         → save_meta() 写 meta.cfg（另一文件，不计入「两次写盘」口径）
```

**硬契约**：`save_codex()` 调用点仍为 **2 处**（`set_codex_last_run()` 内 1 处 + `_write_codex_replay()` 内 1 处），新增调用数 = **0**。`oath_streak` 与 `oath` 在**同一次** `_write_codex_replay()` / **同一次**写盘中落盘 → 永不出现「oath 已兑现但连绩=0」的撕裂态。

**陷阱（必须写进注释）**：`_run_stats()` 产出的 `stats` 只有 5 个 `STATS_KEYS` 内的键；若把 `oath_streak` 塞进 `stats` 想走 (C)，会被 `set_codex_last_run()` 的键白名单**静默丢弃**（`game_state.gd:363-368`）。这是 S18 §一 与 `_write_codex_replay()` 函数头注释（`game_main.gd:2341`）已登记的既有结论，本稿不改该结论。

### 1.4 旧档无键兼容（代价 2 正面回答）

实读 `load_codex()`（`game_state.gd:373-393`）：逐键 `maxi(int(v), 0) if (v is int or v is float) else v` —— **Array / Dictionary 原样透传，读档侧无键白名单**。由此得出三道防线：

1. **无键**：旧 `codex.cfg` 的 `last_run` 只有 stats / oath / echo，无 `oath_streak` → `load_codex()` 重建后的干净字典里也没有该键。读侧一律 `.get("oath_streak", 0)`；首局按 `D` 正常起算（0 → 1）。**不做迁移、不补写、不弹提示、不改 `load_codex()`**。
2. **类型守卫**：正因为 Dictionary / Array 原样透传，旧档或坏档若在 `oath_streak` 键上留了非数值（例如被误写成 Dictionary），裸 `int(v)` 会出问题。故 `_read_oath_streak()` 必须写成 `if v is int or v is float: return maxi(int(v), 0) else: return 0`。**这条是本批特有的「② 登记」形态：不是注册进白名单，而是读侧防御性默认。**
3. **UI 空判**：`last_run` 无该键（或值非法）时，连绩行**整个 Label 不创建**（沿用 `menu.gd:657-659` 的「不建了再隐藏」范式），不显示「连绩 0 局」——避免把「无记录」伪装成「有记录 0」。

**顺带澄清一处 S18 措辞**：S18 §一 第 4 条说「新字段须同步 `save_codex()` / `load_codex()` 两端」。实读后本稿修正为：由于 `last_run` 是**整字典**读写（`save_codex():400` 一次 `set_value("codex","last_run", …)`；`load_codex():387-393` 逐键透传），`last_run` **内部**新增平行键**无需改动这两个函数本体**；需要改的只有「覆盖前快照 + 覆盖后写回 + 读侧类型守卫」。此处以实读为准，不照抄旧稿。

### 1.5 与既有「上局誓约回顾」是否冲突 —— 结论：不冲突，但有三处必须锁死

实读两处既有展示：

| 位置 | 既有行 | 数据源 | 语义 |
|---|---|---|---|
| 图鉴页 `_build_codex()`（`menu.gd:400-410`） | `本局誓约 · …已兑现/未兑现（cur/need）` | `last_run.oath` | 刚结算这局的事后复盘 |
| 印记页 `_build_sigils()`（`menu.gd:654-669`） | `上局誓约 · …已兑现/未兑现（cur/need）` | 同一个 `last_run.oath` | 下局「带哪枚」的决策输入 |

**不冲突的依据**：连绩是**另一个键**，`oath` 的结构 `{id,name,desc,done,cur,need}` 一字不改；两处既有行的空判 / 文案 / 颜色 / `C-NC2` 用词断言（S18 阶段二 §四 c2）全部不回归。连绩与 `oath` 同源同写盘，反而是互相印证。

**必须锁死的三处**：

- **T1 用词区分**：既有「本局誓约 / 上局誓约」前缀已被 S18 C-NC2 断言锁死；连绩行**绝不复用**这两个前缀，另起「连绩 · 」/「上局连绩 · 」，否则会与既有行在文本扫描里混淆。
- **T2 一致性不变量**（也是 §六 断言靶子）：
  - `I1`：`oath.done == true` ⇒ `oath_streak ≥ 1`
  - `I2`：`H=1 且 oath.done == false` ⇒ `oath_streak == 0`
  - `I3`：`H=0`（未立誓）⇒ `oath_streak == S_prev` 且连绩行不创建
- **T3 时序**：连绩与 `oath` 必须在同一次 `_write_codex_replay()` 写回（见 1.3），否则 T2 会出现撕裂态。

### 1.6 边缘情况（≥3 类，实读后列全）

| # | 边缘情况 | 处置 |
|---|---|---|
| E1 | **未携带印记 / 印记无对应誓约 / 空 watched** → `oath_fulfillment()` 返回 `{}`（`game_main.gd:2305-2310`），`H=0` | `S_next = S_prev`，连绩行不创建（§七① 拍板；本稿推荐） |
| E2 | **弃局 / 主动退出 / SMOKE 未开结算** → 不走 `_settle_meta()` | `last_run` 不更新，连绩冻结不变（既不 +1 也不断）；不补写、不迁移 |
| E3 | **旧档无 `oath_streak` 键** | `.get(...,0)` → 0；首局按 D 正常起算；UI 不创建行 |
| E4 | **旧/坏档该键为非数值**（Dictionary / Array / String，因读档侧原样透传） | `_read_oath_streak()` 类型守卫 → 0；不崩、不 `[ERR]`；UI 不创建行 |
| E5 | **`last_run` 整表为空 / 仅有 5 项 stats 的旧档** | `lr.is_empty()` 分支仍走「暂无记录」；连绩行键不存在 → 不创建；无空指针 |
| E6 | **同局重复结算**（死亡 → 重开交错） | `_run_settled` 幂等守卫（`:2537`）挡住第二次；连绩不重复 +1 |
| E7 | **SMOKE 探针直调 `_write_codex_replay()`**（`player.gd:1315`，无参） | 可选参数哨兵 `-1` → 该路径**不改写** `oath_streak`，`_oath_probe()` 既有「落盘读回 / 六类发现集不被抹 / 复盘页渲染」断言零回归、SMOKE 档不被污染 |
| E8 | **`oath_fulfillment()` 的 `cur := 999`**（`:2311`，在册登记「无实害」） | 本稿**不顺手改**；连绩只读 `f.is_empty()` 与 `f.done`，不读 `cur`，与该登记无交互 |

---

## 二 玩家向文案（矿工手记口吻 · 克制 · 状态标签 · 非攻略）

**基调**：沿用 S16 D 定下的「废弃矿窟的实用主义」——短句、功能性、只陈述状态，不解释规则、不给行动指令。与 `抉择回声`（血偿流 / 散财流 / 功勋流 / 实用流）、`上局复盘 · 最深 %d 层 · …` 同一账房口吻。

| 状态 | 文案（Label 全文） | 说明 |
|---|---|---|
| `S_next ≥ 1` | `连绩 · %d 局` | 状态标签；`%d` 与 `oath_streak` 同源，阿拉伯数字与既有复盘行 `%d` 口径一致 |
| `H=1 且 D=0`（断绩 / 清零） | `连绩 · 断了` | 状态描述，非评价；不写「再试一次」「下一局补齐」等攻略句 |
| 印记页同批显示时 | `上局连绩 · %d 局` / `上局连绩 · 断了` | 与「上局誓约」用词族一致，满足 T1 区分 |
| `H=0` / 旧档无键 / 值非法 | **整行不创建** | 与 `menu.gd:657-659` 同型，不建了再隐藏 |

**自检（禁词）**：全文不含「建议 / 优先 / 划算 / 应该 / 最好 / 推荐 / 值得 / 稳 / 赚」等评价词与攻略词；不含第二人称指令；不含数值奖励话术。
**备选（不占拍板名额）**：若主理人觉得「断了」略带情绪，可换 `连绩 · 从这局起` ——同为状态词、同为禁词表外，二选一即可，不影响任何断言（断言只锁前缀与 `%d` 实值）。
**不套「矿工手记 ·」前缀**：那是 `_flush_flavor_toast()` 的首发现播报专用格式（`game_state.gd:354`）；复盘/印记页是常驻行，套用会与 S18 B 的「双播」混淆。
**文案不入 `FLAVOR`**：`FLAVOR` 是 `kind/id → 手记` 映射且 `validate.gd:250-260` 有按前缀分桶的六类覆盖门；本稿文案是纯字符串常量，加键会稀释该门的分桶口径，也违反「`FLAVOR` 不动」的冻结约束。

---

## 三 UI 形态：落哪里，为什么

**裁定：主落「图鉴复盘页」，次落「印记页」，两处同批；不进主菜单 / HUD 常驻 / 局内 toast。**

| 落点 | 具体位置 | 作用 | 为什么是这里 |
|---|---|---|---|
| **图鉴复盘页** `_build_codex()` | 紧跟 `本局誓约` 行之后（`menu.gd:410` 后），同一 `_rows` 容器 | 「这局结算了」的确认位，看到连绩被 +1 / 断掉 | 长线刻度天然属于局末复盘；与「上局复盘 / 本局誓约 / 抉择回声」同页同容器同色系，**零新增页面 / 按钮 / 输入动作** |
| **印记页** `_build_sigils()` | 紧跟 `上局誓约` 行之后（`menu.gd:669` 后） | 「下局带哪枚」的决策位，续约 / 换向的跨局上下文 | S18 阶段二 C 已把此页确立为「上局誓约」的决策落点；连绩放这里才真正闭环（Dynamics 落点） |

两页读**同一个** `last_run.oath_streak`、同一个字段、同一套渲染断言、一次登记三件套；边际成本≈0。渲染规格直接复用既有：
`Label` + `horizontal_alignment = CENTER` + `font_size 14` + 续绿 `Color(0.6,0.95,0.7)` / 断灰 `Color(0.72,0.75,0.82)`。
**可访问性**：文本自带「N 局 / 断了」，**颜色不作唯一编码通道**；沿用 `apply_ui_settings` 字号档，不新造字号 / 色盲 mark 口径。

**明确不放的三处（逐条给理由）**：

- **HUD 常驻**：连绩在**一局之内恒定**（只在结算时变），正是任务书点名的「输出跨局恒定 → 两局就背下来 → 变噪音」；且 HUD 是局内通道，连绩是局外沉淀，语义错位。放 HUD 还会引入每帧刷新与 E6 无谓耦合。
- **主菜单**：缺「完成一局后生成」的语境，且会让入口页多一行恒定文本。
- **局内 toast / banner**：会与 `mark_codex` 白名单首发现播报撞车（S18 B 双播红线同型），且任何节流都会引入计时（E6）。

**认知过载核对**：复盘页由 3 行（复盘 / 本局誓约 / 抉择回声）增至 4 行，印记页增 1 行；不新增可展开层、不新增分母行、不新增进度条。字号档与既有 `Label` 一致。

> §七④ 把「两处 vs 只留印记页」列为 A/B 拍板；本稿推荐两处。

---

## 四 红线自检表（逐条对账）

| # | 红线（任务书给定 / 项目既定） | 本实稿对账 | 结论 |
|---|---|---|---|
| R1 | **代价 1**：`set_codex_last_run()` 覆盖式 + 自带写盘；平行字段须在其后赋值 + 再写盘；复用 `_write_codex_replay()`，不新增第三次写盘 | §一 1.3 完整时序 (A)→(E)；(B) 覆盖前快照、(D) 覆盖后写回；`save_codex()` 调用点仍 2 处，新增 0 | ✅ 正面回答 |
| R2 | **代价 2**：`load_codex()` 逐键钳制 / Array·Dictionary 原样透传 / 读档侧无键白名单；旧档无键须安全默认 | §一 1.4 三道防线；`load_codex()` / `save_codex()` **零改动**；读侧 `.get(...,0)` + `is int or is float` 类型守卫 + UI 空判 | ✅ 正面回答 |
| R3 | 冻结 v2.10：`meta.gd UNLOCKS` / `Meta.STATS_KEYS` 不可改；局外内容平行只读派生 | 两表零触碰；连绩落 `codex["last_run"]` 平行键（域归属裁定见 §一 1.1）；不进 `stats`（会被白名单静默丢） | ✅ |
| R4 | **E1**：核心循环零新增 `Game.rng` / `fx_rng` | 纯结算末尾整数/布尔运算；零 `rand*` / `stable_hash`；不进 `_smoke_fingerprint`；不碰 rooms/kinds | ✅ |
| R5 | **E6**：计时走 `FIXED_DT`、禁 raw `delta` | 零 timer / 零 tween / 零 delta；纯同步计算；S22 `flash_toast` 同帧聚合通道不触碰 | ✅ |
| R6 | 🔴 `_codex_boon_suffix()` 把全部 `CODEX_KINDS` 拼 key 走 `stable_hash` → **不得扩六类**；`FLAVOR` / `ACTION_DEFS` 18 条 / `FLOOR_THEMES` 8 项不动 | 连绩**不是发现集**，不进 `CODEX_KINDS`（S19 的 `shrine` + `if k=="shrine": continue` 保护原样）→ 派生 key 逐字不变、开局铭刻词缀零漂移；`FLAVOR` 不加键（兼护 `validate` 六类覆盖门）；另三表零触碰 | ✅ |
| R7 | **登记三件套**：①写入 ②注册表/白名单/UI 分母/显示名 ③**可见效果断言**（验数值或验渲染，不能只验标志） | ① `_write_codex_replay()` 写字段；② **不进** `STATS_KEYS`/`CODEX_KINDS`/`CODEX_BOONS`/`UNLOCKS`/`FLAVOR`/`ACTION_DEFS`/`FLOOR_THEMES`，**不入任何分母**，显示名=纯字符串前缀，② 特有形态=读侧安全默认；③ 验渲染（真调 `_build_codex()` 扫 Label）+ 验数值（纯函数真差值 / 落盘往返），见 §六 | ✅ 三件齐全并逐条标注 |
| R8 | S21 教训「**静态比对变量值 = 虚假通过**」 | §六 用**真差值**输入（0/3/7 × D=0/1 × H=0/1 输出逐字不同）+ 落盘往返实读 + 负向对照 n1~n5；断言分类如实标注，静态核对单列不包装成绿灯 | ✅ |
| R9 | 冻结双清单纪律：每批重算，历史归档 `SPR7-FROZEN-4.md5` 永久勿覆盖 | **本实稿零 `.gd` 改动** → 本批无脚本可算，冻结清单 34/34 不变、**不重算**；若转实施单，落地时**新建** `production/sprint-23/SPR23-FROZEN.md5`（34 行逐文件重算），不覆盖任何 `SPR7-FROZEN-*.md5` | ✅ 如实标注 |
| R10 | HUD 常驻位不放静态常量表派生 | §三 明确不进 HUD，并给出「一局内恒定 → 噪音」的理由 | ✅ |
| R11 | 主导策略 / 经济失衡 / 认知过载 / 支柱漂移 | 纯展示、零数值回注、零奖励 → 无「兑现→变强→更易兑现」P0 自激；不碰 shards/crystals/payout；不携带印记不惩罚（§七①A）→ 不形成「必带印记」压力；复盘页 +1 行 / 印记页 +1 行；产出恒为信息层，支柱不漂移 | ✅ |
| R12 | P0 boon 自激同型（S18 §七） | 不调 `mark_codex`、不进发现集 / 分母 / `CODEX_BOONS`、不碰 `variant="boss"`；`validate.gd:264-278` 的 suffixes/shrine 禁令不回归 | ✅ |
| R13 | 与「上局誓约回顾」用词区分（S18 C-NC2） | §一 1.5 T1/T2/T3；既有两行一字不改，`oath` 结构不变 | ✅ |
| R14 | `oath_fulfillment()` 的 `cur := 999` 在册登记「无实害」，本实稿**不必顺手改** | 明确不改；连绩不读 `cur`（E8） | ✅ |
| R15 | 零新增机制 / 实体 / 资源 / 输入动作 | 1 个 `int` 字段 + 1~2 个只读 Label + 2 个纯函数；零按钮、零页面、零输入、零资源 | ✅ |
| R16 | 双档隔离（`codex.cfg` 双档，SMOKE 不污染玩家档） | 两处写盘都走 `save_codex()` → `codex_path()` → `SMOKE_CODEX_PATH` / `_smoke_codex.cfg`；探针在隔离档构造跨局场景 | ✅ |
| R17 | 与 S18 阶段二 C「纯只读展示」红线一致性 | 连绩写入只发生在**结算路径** `_settle_meta()`；`menu` 两页仍纯只读（不调 `save_codex` / `set_codex_last_run` / `mark_codex`、不读写 rng）——与 C 的零副作用断言（S18 §六 断言 4）同型 | ✅ |

---

## 五 eng 实施契约要点（转实施单时可直接复用）

> 本节为**契约要点**，不是代码；最终实现以程基岩实读挂点行号为准，经主理人中转确认时序。

### 5.1 挂接点清单（本次实读行号）

| 文件 | 函数 / 行 | 动作 |
|---|---|---|
| `game_main.gd` | `_settle_meta()` `:2536`；`stats := _run_stats()` `:2555` 后、`set_codex_last_run()` `:2556` **前** | **新增 (B) 覆盖前快照**：`prev := _read_oath_streak()` |
| `game_main.gd` | `set_codex_last_run(stats)` `:2556` | **不改** |
| `game_main.gd` | `_write_codex_replay()` `:2342-2347` | **新增可选参数 `prev_streak: int = -1`**；在既有 `oath` / `echo` 两行赋值之后、`Game.save_codex()` 之前加 1 行写入；`:2557` 调用改为 `_write_codex_replay(prev)` |
| `game_main.gd` | 新增 `_read_oath_streak() -> int` | 纯读 `Game.codex["last_run"]`，类型守卫 + `.get(...,0)` + `maxi(int(v),0)`；**不重新读盘** |
| `game_main.gd` | 新增 `next_oath_streak(prev:int, H:bool, D:bool) -> int` | 纯函数（可 `static`），零读取全局态；实现 §一 1.2 的 `f` |
| `menu.gd` | `_build_codex()` `:410` 后 | 追加连绩 Label（键存在且值 ≥0 才创建） |
| `menu.gd` | `_build_sigils()` `:669` 后 | 追加「上局连绩」Label（§七④ 选 A 时） |
| `game_state.gd` | `set_codex_last_run()` / `load_codex()` / `save_codex()` / `CODEX_KINDS` / `codex` 初始字典 | **全部零改动** |
| `meta.gd` / `data.gd` / `validate.gd` | `STATS_KEYS` / `UNLOCKS` / `CODEX_BOONS` / `OATH_CONDITIONS` / `FLAVOR` / `_check_codex()` | **全部零改动**（`validate` 无需新增分母/白名单门） |
| `player.gd` | `_oath_probe()` `:1315` 无参直调 `_write_codex_replay()` | **不改调用**；靠哨兵 `-1` 保证该路径不改写连绩 |

### 5.2 两次写盘顺序（不可调换）

1. `(A)` 取 `stats` → 2. **`(B)` 覆盖前快照 `prev`** → 3. `(C)` `set_codex_last_run(stats)`【写盘①】→ 4. `(D)` `_write_codex_replay(prev)`【写盘②，复用既有 `Game.save_codex()`】→ 5. `(E)` `meta_settle_run(stats)`（meta.cfg，另文件）。

- `(B)` **必须**在 `(C)` 之前：`(C)` 把 `last_run` 覆盖成只含 5 项 stats 的 `clean`（`game_state.gd:369`），旧 `oath_streak` 当场丢失。
- `(D)` **必须**在 `(C)` 之后：否则新值会被 `(C)` 覆盖掉。
- **不新增第三次 `save_codex()`**；新增 `save_codex` 调用数 = 0（可用 §六 V10 静态核对验证）。
- `oath` / `echo` / `oath_streak` 三者同在 `(D)` 写回、同一次落盘（T3）。

### 5.3 探针兼容（易漏，单列）

`player.gd:1315` 的 `_oath_probe()` **无参直调** `gm._write_codex_replay()`，随后 `Game.load_codex()` 逐字段读回并校验 `oath` / `echo` 与「六类发现集不被抹」。因此：

- **不改该函数签名为必填参数**；用 `prev_streak: int = -1` 默认哨兵。
- `prev_streak < 0` → **跳过** `oath_streak` 写入（既不新增键、也不改写现值），保证 `_oath_probe()` 既有断言（含 `:1330` 六类发现集不被抹、`:1341` 复盘页渲染）零回归、SMOKE 隔离档不被污染。合法 `prev` 恒 ≥0，故 `-1` 无歧义。
- 连绩的专属探针另起一组（§六），**不要**复用 `_oath_probe()` 的隐式状态。
- 尽量保持 `Game.codex["last_run"]["oath"] = oath_fulfillment()` 这一行**字节不变**，连绩计算从 `last_run["oath"]` 读回 `f`（`H = not f.is_empty()`、`D = bool(f.get("done", false))`），把改动面压到最小。

### 5.4 零 rng / 零计时 / 冻结

- `_read_oath_streak()` / `next_oath_streak()` 只做整数与布尔运算：零 `Game.rng` / `fx_rng` / `rand*` / `stable_hash` / `hash()`。
- 不进 `_smoke_fingerprint`（不碰 rooms 坐标 / kinds）；不碰 `CODEX_KINDS` → `_codex_boon_suffix()` 的 key 逐字不变（R6）。
- 零 `delta` / 零 `create_timer` / 零 `Tween`；不引入任何节流或冷却。
- `git diff` 新增行中 `save_codex` / `set_codex_last_run` / `mark_codex` / `Game.rng` / `fx_rng` / `randf` / `randi` / `delta` 真实调用数 = **0**（`save_codex` 那一行是既有代码，不算新增调用；静态核对须排除注释行，逐行核对，见 S18 §五 的做法）。

### 5.5 落地时的冻结清单纪律

本实稿零 `.gd` 改动 → 本批**不重算**冻结清单。转实施单落地后：新建 `production/sprint-23/SPR23-FROZEN.md5`，对本批 34 个 `.gd` **逐文件重算**（每批快照每批重算）；`production/sprint-7/SPR7-FROZEN-4.md5` 及其余历史归档**永久勿覆盖**。

---

## 六 验证口径（验效果型断言怎么设计 / 断言分类如实标注）

### 6.1 跨局场景如何构造

真实跨局要连跑两局结算，代价高且受 `_run_settled` / SMOKE 早退限制。本稿采用**两条互补路径**：

- **路径 P1 · 落盘往返模拟跨局（主力）**：在 SMOKE 隔离档（`SMOKE_CODEX_PATH` 指向独立文件）里，手工把 `Game.codex["last_run"]["oath_streak"]` 置为「上一局的值」，注入本局 `oath_fulfillment()` 的 `done` 状态，然后**真调** `Game.set_codex_last_run(stats)` → `_write_codex_replay(prev)` → `Game.load_codex()` → 读回断言。这一条**专打代价 1**：若实现漏了「覆盖前快照」，`(C)` 会把旧值抹掉，写回的必然是 0/1 而不是 `S+1` → 断言转红。
- **路径 P2 · 纯函数真差值**：`next_oath_streak(prev, H, D)` 是纯函数，直接喂多组不同输入断言输出逐字不同（S19 阶段一「三态真差值」同型）。先断言**输入确实不同**（防「恒定输入冒充差值」），再断言输出。
- **补充 P3 · 真跨局抽检（可选，QA 手工）**：`SMOKE_META_SETTLE=1` + 固定 `SMOKE_SEED` 连跑两局结算，读 `codex.cfg` 断言 `oath_streak` 由 0→1→2 或 →0。**不作为每日回归**，只作一次链路确认。

验渲染一律**真调** `menu.show_page("codex")` / `menu.show_page("sigils")` 并遍历 `_rows` 找 `Label`（复用 `player.gd:836-843` 的 `_find_label_containing()`），**不直接读 `Game.codex` 判「数据在不在」**——这是 S18 阶段二 §六 已确立的口径。零副作用断言用**同步段**深拷贝比对（`:808-810`，`show_page` 与深拷贝之间不跨 `await`），避免与同期 codex 写入串扰。

### 6.2 断言清单（分类如实标注）

| # | 分类 | 断言内容 | 构造 | 转红方式 / 负向对照 |
|---|---|---|---|---|
| V1 | **验效果型（数值 · 真差值）** | `next_oath_streak` 四态输出逐字不同：`(0,1,1)=1`、`(3,1,1)=4`、`(3,1,0)=0`、`(3,0,*)=3`；并先断言四组输入确实互不相同 | P2 | n2（把 `D` 判定取反）→ 至少 2 条红 |
| V2 | **验效果型（落盘往返 · 覆盖式实测）** ★专打代价 1 | 置 `oath_streak=3` → 真调 `set_codex_last_run(stats)` → `_write_codex_replay(3)` → `load_codex()` → 读回 == 4；再构造 `D=0` → 读回 == 0 | P1 | **n1（删掉覆盖前快照，改在覆盖后读）→ 红**；n3（把字段塞进 `stats` 走白名单）→ 红 |
| V3 | **验效果型（旧档兼容 · 数值）** | 旧档 `last_run` 无 `oath_streak` 键 → `save_codex()` → `load_codex()` → `_read_oath_streak()` == 0、零 `[ERR]`；另构造该键为 Dictionary 的坏档 → 仍 == 0、零 `[ERR]` | P1 | **n4（读侧去掉类型守卫）→ 红** |
| V4 | **验效果型（渲染 · 数值实值）** | 真调 `show_page("codex")`，`_rows` 中存在以 `连绩 · ` 开头且含 `%d` 实值的 Label；把 `oath_streak` 由 4 改 7 再构建，文本**跟着变**（真差值，非「标签存在」） | P1 + `show_page` | **n5（文案前缀写坏 / 写死常量）→ 红** |
| V5 | **验效果型（渲染 · 不创建）** | `last_run` 无该键 / `H=0` / 值非法 → 连绩 Label **不创建**（非建后隐藏） | P1 | n6（空判改成 `if true`）→ 红 |
| V6 | **验效果型（用词区分 · T1）** | 复盘页以 `连绩 · ` 开头；印记页以 `上局连绩 · ` 开头；**两页都不得出现把连绩行写成 `本局誓约` / `上局誓约` 前缀**；既有两行文本一字不变 | `show_page` 双页 | n7（复用既有前缀）→ 红；并复核 S18 C-NC2 不回归 |
| V7 | **验效果型（一致性不变量 T2）** | `I1`：`oath.done=true` ⇒ `oath_streak≥1`；`I2`：`H=1,D=0` ⇒ `==0`；`I3`：`H=0` ⇒ `==S_prev` | P1 四态 | n2 / n1 |
| V8 | **验效果型（零副作用）** | `show_page("codex")` / `show_page("sigils")` 同步段前后 `Game.codex.duplicate(true)` 深等（不跨 await） | 同步段 | 构建期偷写状态即红（S18 §六 断言 4 同型） |
| V9 | **验效果型（探针零回归）** | `player.gd:1315` 无参直调 `_write_codex_replay()` 后，`last_run` 中 `oath_streak` **保持调用前的值**（哨兵生效），`_oath_probe()` 既有断言全绿、`[ERR]`=0 | 现有探针 | n8（哨兵改成默认 0）→ 红 |
| V10 | **静态代码层核对（非动态断言 · 如实标注）** | `git diff` 新增行：`save_codex` **新增调用** 0、`set_codex_last_run` 0、`mark_codex` 0、`Game.rng`/`fx_rng`/`rand*` 0、`delta` 0；`STATS_KEYS`/`UNLOCKS`/`CODEX_KINDS`/`CODEX_BOONS`/`FLAVOR`/`ACTION_DEFS`/`FLOOR_THEMES` 表定义 0 行变化 | grep | 逐行核对、排除注释（S18 §五 口径） |
| V11 | **E1 指纹（非每日回归信号）** | 同 seed 地图指纹与 HEAD 逐字节相同（本稿不碰 rooms/kinds，理论必同） | 全量 SMOKE | 一次链路确认 |
| V12 | **前提守卫型（恒过 · 如实标注）** | `validate._check_codex()` 的 CODEX_BOONS kind 禁令 / FLAVOR 六类覆盖门不回归 | 启动期 | **当前数据下恒过**，价值在「未来误扩表时当场报错」，**不是每日回归信号**；不得包装成绿灯证据 |

**分类口径说明（对齐 S19/S21 教训）**：
- V1/V2/V4/V7 是**真差值 / 验效果型**，输入确实变化、输出逐字比对，不是「静态比对变量值」；V2 更是直接打在本批既定代价上。
- V3/V5/V6/V8/V9 是**验效果型（数值 / 渲染 / 不创建 / 只读）**，验的是可见行为，不是「字段存在」标志。
- V10 是**静态核对**，V11 是**一次性链路确认**，V12 是**前提守卫型恒过**——三者**如实单列，不计入「可见效果断言」的绿灯数**。S21「静态比对变量值 = 虚假通过」的规避方式就是：把 V2/V4 这类真差值断言作为主证据，静态项只作旁证。

### 6.3 负向对照（mutation，固定 `SMOKE_SEED`）

| 变体 | 突变 | 预期转红 |
|---|---|---|
| `base` | 无 | 0（绿灯基线） |
| `n1` | **删掉覆盖前快照**，`prev` 改在 `set_codex_last_run()` 之后读 | V2（+ V7）→ 红 |
| `n2` | `next_oath_streak` 里 `D` 判定取反 | V1 / V4 / V7 → 红 |
| `n3` | 把 `oath_streak` 塞进 `stats` 而非 `last_run` | V2 → 红（白名单静默丢弃） |
| `n4` | `_read_oath_streak()` 去掉类型守卫 | V3 → 红 |
| `n5` | 连绩文案写死常量 / 前缀写坏 | V4 → 红 |
| `n6` | 空判改成 `if true:` 建了再隐藏 | V5 → 红 |
| `n7` | 连绩行复用「本局誓约」前缀 | V6 → 红 |
| `n8` | 把哨兵默认值改成 `0` | V9 → 红 |

> 诚实标注：若某条前置断言先挂，后续断言自然不再报（S18 阶段二 §四 的「前提守卫型」性质），**不得把前置失败包装成多条红**。

### 6.4 验数值还是验渲染 —— 结论

**两者都要，且分工明确**：连绩的**正确性**（+1 / 清零 / 旧档 / 覆盖式）由 V1/V2/V3/V7 **验数值**；连绩**真的被玩家看见**（登记三件套③）由 V4/V5/V6 **验渲染**。只验「字段写进去了」不算完成——这正是任务书「不能只验标志」与 S21 教训的落点。

---

## 七 待主理人拍板项（4 项 · A/B · 含代价）

| # | 议题 | A（本稿推荐） | B | 代价对照 |
|---|---|---|---|---|
| **①** | **无立誓局（`H=0`）如何计入** | **不计入、不断绩**：`S_next = S_prev`，连绩行不创建 | **清零断绩**：`S_next = 0` | **A**：语义略宽（「连着几局」中间夹了没立誓的局），且理论上可「空局保连绩」——但连绩**纯展示零收益**，无可 optimize 的对象，不构成主导策略；与 `menu.gd` 既有「oath 空 → 行不创建」同型，改动最小。**B**：字面更严格，但对「不携带印记」形成软性压力（隐性主导策略红线），且新玩家 / 不携带印记玩家的刻度永远为 0，长线目标失去意义；还须在文案上把「没立誓」与「立誓没兑现」分成两态（否则玩家看到「断了」却不知缘由），多一处显示分支与断言。两种口径下写盘次数相同，均无额外写盘。 |
| **②** | **是否额外记录「历史最长连绩」** | **只存 `oath_streak` 一个 `int`** | 再加 `oath_streak_best`（`maxi(prev_best, S_next)`） | **A**：1 个字段、1 套旧档兼容、1 处显示、最小面；清零后「长线记忆」消失，刻度只反映当前链。**B**：清零后仍留个人最佳，长线感更强；但多 1 个字段 + 多 1 处读侧类型守卫 + 多 1 行 UI（认知过载 +1），且 `best` 单调递增、近似静态常量，若哪天被挪到 HUD 会直接踩 R10 红线。本稿认为「只加关系」的最小闭环不需要它。 |
| **③** | **连绩锚点：任意誓约 vs 同一枚印记分链** | **任意誓约兑现即 +1**：换印记也算连续 | **按印记分链**：换印记则新链起算（须另存 `last_oath_id`） | **A**：1 个 `int` 搞定，`f` 只看 `is_empty()` / `done`，与 `oath` 结构零耦合。**B**：关系更丰富（「这枚印记连着兑现了几局」），但隐性惩罚「换向」，与 S18 候选 C 想鼓励的「继续补齐 / 换打法」自主决策相冲，且多存 1 个 id、多一层语义与旧档兼容面，接近「加实体」。 |
| **④** | **UI 落点范围** | **图鉴复盘页 + 印记页两处同批** | **只留印记页**（决策位优先，缩面） | **A**：覆盖「结算确认位」与「下局决策位」两端，闭环完整；同一个字段、同一套断言、一次登记三件套，边际成本≈0；与 S18 C「同源两处、用词区分」口径一致。**B**：少 1 个 Label、少 1 组渲染断言，但复盘页看不到「这局 +1 还是断了」，跨局闭环缺一个可见端，玩家只能在开局前看到数字。 |

**另需主理人确认（非 A/B，属前置条件）**：

1. **§一 1.1 的字段域归属裁定**（落 `codex["last_run"]` 而非 `Game.meta`）。若推翻，本稿 §一 1.3 / 1.4、§四、§五、§六 需整体重写。
2. **时序确认（经主理人向程基岩中转）**：`(B)` 覆盖前快照的挂点位置、`_write_codex_replay()` 哨兵参数与 `player.gd:1315` 无参直调的兼容、`codex.cfg` 双档隔离不被污染。本稿不臆造 API，实现前须重新实读挂点行号。
3. **范围**：本稿**只产出文档**，零 `.gd` 改动、零 commit；是否转编程侧实施单、是否分阶段，由主理人评审后决定。若只做验证手感，可先走 S18 §四 C 已建议的「退化版」路径——但注意 S18 阶段二 C **已经落地**了退化版（印记页「上局誓约」一行），本稿是在其之上补「跨局计数」这一环，不是重做退化版。

---

## 附：实读挂点索引（行号以本次实读为准，落地前复核）

| 文件 | 行 | 内容 |
|---|---|---|
| `game_state.gd` | 279 / 280 | `CODEX_KINDS` 六类 / `codex` 初始字典（含 `last_run: {}`） |
| `game_state.gd` | 284-290 | `codex_path()`：`SMOKE_CODEX_PATH` > `_smoke_codex.cfg` > `codex.cfg` |
| `game_state.gd` | 361-370 | `set_codex_last_run()`：`clean` 白名单 + **覆盖** + 自带 `save_codex()` |
| `game_state.gd` | 373-393 | `load_codex()`：逐键 `maxi(int(v),0) if int/float else v`；**Array/Dictionary 原样透传，无键白名单** |
| `game_state.gd` | 396-401 | `save_codex()`：整字典 `set_value("codex","last_run", …)` |
| `game_state.gd` | 406-412 / 491-496 | `codex_boons()` / `stable_hash()`（均不触碰） |
| `game_main.gd` | 2293 / 2302-2317 | `oath_count()` / `oath_fulfillment()`（`cur:=999` 在 `:2311`，本稿不改） |
| `game_main.gd` | 2342-2347 | `_write_codex_replay()`：既有**第二次写盘位点** |
| `game_main.gd` | 2377-2388 | `_codex_boon_suffix()`：拼 `CODEX_KINDS` 走 `stable_hash`（🔴 不得扩六类） |
| `game_main.gd` | 2461-2466 / 2469-2481 | `to_main_menu()` 弃局不结算 / `_on_player_died()` 唯一结算入口 |
| `game_main.gd` | 2485-2505 / 2536-2569 | `_run_stats()` / `_settle_meta()`（`:2556` 写盘①、`:2557` 写盘②、`:2558` meta） |
| `menu.gd` | 385-421 / 400-410 | `_build_codex()` / 「本局誓约」行 |
| `menu.gd` | 647-678 / 654-669 | `_build_sigils()` / 「上局誓约」行（S18 阶段二 C） |
| `meta.gd` | 13 / 16 / 22 | `VERSION` / `STATS_KEYS`（5 键）/ `UNLOCKS` —— 冻结，零改动 |
| `data.gd` | 102 / 343-348 / 353-363 / 367 / 452 | `FLOOR_THEMES` 8 / `CODEX_BOONS` 4 档 / `OATH_CONDITIONS` 9 条 / `FLAVOR` / 播报白名单 |
| `validate.gd` | 25 / 229-290 / 250-260 / 264-278 | `CONSUMER_STATS_KEYS` / `_check_codex()` / FLAVOR 六类覆盖门 / boon 自激禁令 |
| `player.gd` | 796-833 / 836-843 / 1272-1342 / 1315 | `_sigil_oath_probe()` / `_find_label_containing()` / `_oath_probe()` / **无参直调 `_write_codex_replay()`** |
| `dev_log.gd` | 29-32 | `Dev.check()`：失败时 `err()` → SMOKE 下打印 `[ERR]` |
| 文档 | — | `production/sprint-18/SPR18_设计候选实稿.md` §一 / §四 C；`SPR18_交付_阶段二.md` §一 / §四 / §六；`production/SPR21_主理人读码核验.md`（虚假通过教训） |
