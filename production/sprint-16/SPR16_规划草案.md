# Sprint 16 规划草案（换轴版 · 定稿）

> **设计主干**：`production/sprint-16/SPR16_设计候选实稿.md`（`design-strategist` / 文策渊，77 行）。按工作室铁律「专业产出以成员结论为准，主理人只做编排、一致性检查与汇编」，本草案**不改写成员的设计判断**，只补技术规格、挂接点实读、四门控与落地顺序。
> **裁定沿革**：用户先裁「全部」（A–F 全锁）→ 设计实稿回传后改裁「**按实稿换轴**」。全锁版存档 `production/sprint-16/SPR16_全锁方案存档.md`，**不再执行**。
> **基线（本轮实校）**：`git log -1` = `38535f3`；`md5sum -c` **34 OK / 0 FAILED**；**34 个 `.gd`**；工作树仅 `production/sprint-16/` 未跟踪。
> **锁定范围（用户 2026-11-08 裁定）**：**阶段一 + 二全取 = A + B + C + D 全做**；**D 世界观基调 = 废弃矿窟的实用主义**（D 正式进入实施清单）。两处时序已由 `engineering-lead` 复核回传，结论并入 §2.3 / §4.2 / §十一。
> **本批定位**：**加关系，不加实体**。四方向一律零 `Game.rng`、零计时、零新 action、零新资源、零新 kinds → **指纹不变、冻结 34/34 不变、`assets.gd` / `meta.gd` / `.tscn` 零改动**。主理人侧**不写任何 `.gd`**。

---

## 〇、跨批铁律（沿用 Sprint 15，全部仍生效）

1. **E6**：计时走 `Game.FIXED_DT`，禁 raw `delta`；`player._tick_buffs(delta)` 与 `toxic_cloud` 敌方云是**既有在册豁免**，顺手统一会改 E1 基线，**别动**。
2. **E1**：核心循环零新增 `Game.rng` 消费；`SMOKE_*` 表外不进指纹；`_smoke_fingerprint` 只含 rooms 坐标 + kinds。
3. **坑 5**：`ACTION_DEFS` 不加新 action；新资源走 `Assets.g()` 须同步登记 `GEN_NAMES`（`icon_codex` 静默白框教训）。
4. **冻结规格 v2.10**：`meta.gd UNLOCKS` 不动；`Meta.STATS_KEYS` **不扩**（会动统计源与分母）；局外内容一律平行只读派生。
5. **登记三件套**：① 写入 ② 注册表 / 白名单 / UI 分母 / 显示名 ③ **可见效果断言（验数值或验渲染，不能只验字段存在）**。
6. **boon 红线**：`CODEX_BOONS[*].kind` 不得为 `suffixes`；**兑现度不得调用 `mark_codex`**（否则复刻 P0「发现度上升 → 更多 boon」自激），不扩 `CODEX_BOONS`、不碰其 `kind`。
7. **其它既定红线**：`FLOOR_THEMES` 8→12 永不接；主题 Boss `variant="boss"` 严禁改；dash 保持 196–210px；终审附章休眠。
8. **批次流程**：实施 → 四门控 → 冻结重定 → 交付文档 → **单独提交** → 主理人读码核验。
9. **纪律**：凡标 ✓ 必附本轮实读；commit 号与行号以 `git log` / 文件实读为准，不采信文档快照。

---

## 一、锁定范围与阶段（实稿 §五，用户已裁定）

| 阶段 | 方向 | 规模 | 内容 |
|---|---|---|---|
| **一 · 核心增量** | **A 地窖誓约 + B 抉择回声** | M + S | B 是 A 的数据地基（同往 `last_run` 写平行只读字段），同批共用一套断言与一次登记三件套 |
| **二 · 沉淀** | **C 层签 + D 地窖低语** | M + S–M | 把阶段一建立的「玩家开始在意自己的决策」放大为**可读 / 可感** |

实稿给了三个选择项（① 只做阶段一 ② **阶段一 + 二全取** ③ 只做 B + D）→ **用户已裁定选 ②：A + B + C + D 全做**。D 基调已拍板「废弃矿窟的实用主义」，§五 的前置条件解除。

**换轴后撤下**（实稿 §七 明确不建议做，主理人复核其批评有实码依据）：
- **第 12 房型 / 房间事件池**：改 kinds → 指纹重定；与 `shrine` 三卡骨架（`shrine_panel.gd:109/171` + `stable_hash` + `ROOM_META` 三挂点 + `dungeon.gd:138–146`）高度同构，属同类内容堆叠；Sprint 13/15 两度备选未接。
- **武器淬炼 / 词条**：`weapons.gd` 开火路径 rng 密集 + `meta_content_unlocked` 门控，重构级 E1 风险。
- **每日固定词缀**：改 `start_run` rng 顺序 → 基线重定。
- 另：`FLOOR_THEMES` 8→12 与第四位主题 Boss 均不接（硬红线 / 边际递减）。

---

## 二、方向 A 完整规格：地窖誓约（联动型核心增量）

### 2.1 设计意图（实稿 §一，不改写）

补**自主**与**胜任**：本局装备的印记即「誓约锚点」→ 局内用圣所交换 / 词缀触发 / 净化灾祸 / 跨主题清场去兑现 → 局末复盘看到兑现画像 → 下局换一枚印记走另一条路。把「局外选择 → 局内事件 → 局末复盘」接成一条 Dynamics 因果链。

**v1 硬边界**：**只做只读展示 + 局末结算，兑现度不回注局内数值**（否则变成第二条 `CODEX_BOONS` 式「局外→局内」注入）；兑现奖励刻意**不给数值**（只给复盘 / 叙事层），规避主导策略。

### 2.2 数据表与挂接点（实读）

| 项 | 落点 |
|---|---|
| 拟新增 | `data.gd` `const OATH_CONDITIONS`（**9 条，一一对应 `SIGILS` 的 9 个 key**），schema 建议 `id / name / desc / watched_events: Array / hint`；**只定义「读哪些已存在事件」，不定义任何新事件** |
| 锚点 | `game_state.gd:230 sigils["equipped"]`（单枚 String）；**不新增选择界面** |
| 事件源（只读） | `SHRINE_OFFERS` + `game_main.gd:1977 _shrine_execute`；`RELIC_SUFFIXES` 的 `ON_*` 触发点 + `player.gd:601 attach_suffix`；`ACTIVE_RELICS`；`_calamity` / `_calamity_name`；`FLOOR_THEMES.rule`；`CODEX_BOSS_NAMES`（仅加分项） |
| 播报 | `MILESTONES` / toast 通道（既有「每条只播一次」范式） |
| 落盘 | `codex["last_run"]` + `game_state.gd:328 set_codex_last_run()` / `game_main.gd:2275 _settle_meta()` |
| 展示 | `menu.gd:308 _build_codex()` / `:347 _codex_section()` 图鉴复盘页 |

### 2.3 ⚠️ 平行字段落盘口径（依 `engineering-lead` 复核结论）

`set_codex_last_run()` 实读为**覆盖式**：`codex["last_run"] = clean`，`clean` 只收 `Meta.STATS_KEYS` 五项并做负数钳制，**且函数末尾自带 `save_codex()`**；`player.gd` 的 B3 断言专防越界键。因此：

- 平行字段**绝不能**塞进 `stats` 参数（会被静默丢弃），**也不宜改函数本体**（既有统计源 + 探针多处直调）。
- **规格**：在 `game_main.gd:2275 _settle_meta()` 中 `Game.set_codex_last_run(stats)` **之后**直接对 `Game.codex["last_run"]` 赋平行字段，再**显式调一次 `Game.save_codex()`** —— **共两次写盘，接受这个代价**；且必须放在 `if pay <= 0: return` 早退**之前**。
- **更稳的可选做法**：在 `game_state.gd` 新增独立 `append_codex_last_run(fields)` 做合并 + 落盘，由 `_settle_meta` 调用（新增函数，不改既有函数本体）。若追求单次写盘就得改 `set_codex_last_run` 签名，属改既有统计源，**须用户另行裁定 → 本批不做**。
- **读档侧无忧**：`load_codex()` 对 `last_run` 逐键是 `maxi(int(v),0) if int/float else v` → Array / Dictionary **原样透传不被误钳**，且读档侧**无键白名单**、能读回；但不递归（嵌套数值不钳，写入侧自保非负）。`menu._build_codex()` 只读五个已知键，不受干扰。
- **SMOKE 陷阱**：默认 `SMOKE_META_SETTLE` 为空时 `_settle_meta` 早退 → 平行字段**默认不写入**，验证须显式 `=1`；且追加必须是本局**最后一次** `last_run` 写入（`_codex_probe` 在 SMOKE 下会多次调 `set_codex_last_run` 覆盖）。
- **探针**：补「写 → `load_codex()` → 逐字段读回 + 五类发现集不被抹」，照 P0-3.2 现场恢复写法。

零 E1（结算期无 rng）、零指纹、不碰 `UNLOCKS` / `ACTION_DEFS`。

### 2.4 红线与验收

- 9 条誓约**各配互斥可达路径**，条件一律用每局可达事件（进圣所 / 触发词缀 / 净化 / 跨主题），**不把周期性主题 Boss 设为必要条件**；不调 `mark_codex`。
- 三件套：① `OATH_CONDITIONS` 9 条 ② `SIGILS` key 一一对应校验 + 复盘页显示名 ③ `SMOKE_OATH` 断言（**逐条验兑现度数值与复盘页渲染**，不只验字段存在）。
- **E1/E6**：条件判定纯状态读取、零 rng；离散事件计数无计时（若有进度动画走 `FIXED_DT`）；指纹不变、**冻结仍 34/34**。
- 退化路径（若用户不允许任何持久字段）：**纯局内 HUD + 局末不落盘**的 S 级版本。

---

## 三、方向 B 完整规格：抉择回声（S 级数据地基）

- **循环**：进圣所三选一 → 局末复盘看到「本局抉择链」（依次选了哪些 offer、代价类型分布）与一句由数据派生的构筑标签 → 下局换一种活法。补**胜任**与轻微**自主**，不改 Mechanics。
- **挂接点**：`shrine_panel.gd:171 _pick` / `game_main.gd:1977 _shrine_execute` / `SHRINE_OFFERS`；`set_codex_last_run` / `codex["last_run"]`；`menu.gd:308/347` 复盘页。**不新增表**。
- **落盘口径（关键）**：追加字段走**完全平行的另一个 key**，**不扩 `Meta.STATS_KEYS`**（会动统计源与分母）；同 §2.3，在 `set_codex_last_run(stats)` 之后追加并**再 `save_codex()`**。
- **三件套**：① 抉择链写入 ② 复盘页显示名 / 分母不受影响（**文案与链条都不入 `codex_bosses_total()` 等分母**）③ `SMOKE_ECHO_CHAIN` 断言**验复盘页确实渲染出抉择链**（不是只验字段存在）。
- **风险**：零 E1 / 零 E6 / 零坑 5 / 零冻结影响。若复盘页已满、再加一行造成认知过载，**缩为进层一句 toast、不进图鉴**。
- **与 A 的关系**：B 是 A 的数据地基，同批共用一次登记三件套与一套断言。

---

## 四、方向 C 完整规格：层签（联动型 · 随机性可读化）

### 4.1 循环与挂点

进层看到一行「本层组合签」（主题规则 + 灾祸 + 挑战因子 + 编队倾向）→ 据此定本层打法与资源取舍 → 清层。补**胜任**（把随机性从不可知惩罚变成可预判约束）。
挂点：`FLOOR_THEMES.rule / mark`（色盲标记）、`SQUADS`、`_roll_calamity` / `_calamity_name`、`MODIFIERS`、`_apply_floor_theme` 的 banner、`hud.gd`、`apply_ui_settings` 字号档。**纯显示，不新增任何生成逻辑**。

### 4.2 ⚠️ roll 时序与层签挂点（依 `engineering-lead` 复核结论）

| 路径 | 实读顺序 |
|---|---|
| `start_run` | `_roll_modifier()` → `_roll_calamity()` → `_apply_floor_theme()` → `_enter_room()`（roll **全在 enter 前**） |
| `next_floor` 的 `_fade_to` 回调 | `_apply_floor_theme()` → `_enter_room()` → **`_roll_calamity()`**（roll 在 enter **之后**） |

**实害（eng 复核补充）**：`_roll_calamity()` **无条件**先消一次 `Game.rng.randf()`（连 `floor<2` 早退也消），且 `_build_arena` / `_spawn_decor` 链上另有 `Game.rng` 抽取 → **严禁把该 roll 提到 `_enter_room` 之前**，否则 rng 消耗顺序变、掉落 / 编队序列漂移、E1 全量重定。这正是实稿禁令的实害。

**规格（零 rng 顺序改动）**：在**两个调用点各加一次纯只读刷新**，不移动任何 roll、不新增抽取：
- `start_run`：`_roll_calamity()` **之后 / `_enter_room()` 之前**（贴合实稿字面）。
- `next_floor`：`_roll_calamity()` **之后 / `drop_pickup()` 之前**（此路径必然在 enter 后，与实稿字面「enter 前」冲突，但这是**不改 rng 的唯一解**）。若产品坚持 enter 前，拆两段：进房前刷已确定的 modifier / theme，`_roll_calamity()` 之后补刷灾祸项。
- **不要**塞进 `_roll_calamity()` 函数体（它有 3 个提前 return，且 `player.gd` B5 探针直调它两次）。
- **不要**用 `hud.banner()`（覆盖式 tween，会被 `_enter_room` 的「第 N 层」或灾祸 banner 盖掉）→ 改走 **`hud.set_room_info()` 同通道的常驻只读标签**。

**判据**：新增代码零 `Game.rng` / `fx_rng`、零 `Data.roll_*` / `_spawn_batch`；`SMOKE_META_FINGERPRINT=1` 双跑逐字一致即自证零指纹重定。

### 4.3 可访问性与验收

- **默认只显 2 项、可展开**（一行塞 4 项会冲掉 HUD 字号档与色盲 `mark` 已建立的可访问性口径）；**颜色不得为唯一编码通道**，复用既有 `mark` 符号。
- 规模 M（含 UI 分层）；退化为只显主题 `rule + mark` 则 S。若用户偏好「不预告、靠临场反应」的紧张感，整体不接 —— **手感取舍交用户拍板**（当前默认：预告但克制）。
- 三件套：① 层签数据源 ② 现有 `mark` / 字号档注册核对 ③ `SMOKE_FLOOR_SIGN` 断言验「显示内容与 `_calamity` / `modifier` / 主题实值一致」+「roll 前后 rng 消费次数不变」。

---

## 五、方向 D 完整规格：地窖低语（关联 · 叙事钩子，S–M）

- **循环**：首次遇到某印记 / 圣所 / 主题 / 主题 Boss 时播报一句条目文案 → 图鉴已发现条目展开可见 → 收集从「打勾」变成「读懂地窖」。补三者中唯一空缺的**关联**，纯 Aesthetics，不动 Mechanics。
- **挂点**：`MILESTONES`（既有「每条只播一次」通道）、`CODEX_KINDS` 五类 + `codex` 发现集、`menu.gd:347 _codex_section`、`SIGILS` / `SHRINE_OFFERS` / `FLOOR_THEMES` / `CODEX_BOSS_NAMES` 的 `name`（纯只读查表）。拟新增只读文案表 `FLAVOR`。
- **基调（用户已拍板）**：**废弃矿窟的实用主义** —— 克制、功能性的矿工手记口吻，最贴现有美术与命名；不引入神秘学或调侃调性。文案只写**已存在**的条目，**不臆造设定**。实稿「无基调不启动」的前置已解除，D 正式进入阶段二实施清单。
- **三件套是主要风险**：① 写入 `FLAVOR` 条目 ② 核对白名单 / 显示名 / **图鉴分母（文案不入分母）** ③ 可见效果断言（首次确实播报、重复不播报）。`icon_codex` 漏 `GEN_NAMES`、`bulwark` 表里有但 `match` 漏分支，都是「表写了没接上」的同款根因，**不可只验中间状态**。
- **E1/E6/坑 5/冻结**：全零（纯文本、纯只读派生）。规模由文案量决定，只给 3 位主题 Boss 各一行即 S。

---

## 六、明确不做（防范围蔓延）

第 12 房型 / 房间事件池、`FLOOR_THEMES` 8→12、第四位主题 Boss、武器淬炼、每日挑战加固定词缀；以及 §〇 全部技术红线。原全锁方案（A–F）仅存于 `SPR16_全锁方案存档.md`，**不作为实施依据**。

---

## 七、待拍板项状态

| # | 项 | 状态 |
|---|---|---|
| 1 | 阶段范围 | ✅ 用户裁定 **阶段一 + 二全取（A+B+C+D）** |
| 2 | D 世界观基调 | ✅ 用户裁定 **废弃矿窟的实用主义**；D 进入实施清单 |
| 3 | A 兑现度是否落盘 | 默认**允许**（按 §2.3 两次写盘口径）；退化 S 版需用户另说 |
| 4 | C 预告随机性手感 | 默认**预告但克制**（只显 2 项、可展开）；偏好临场紧张感可整体不接 C |
| 5 | 两处时序 | ✅ `engineering-lead` 已复核回传，结论并入 §2.3 / §4.2 / §十一 |
| 6 | 单次写盘 vs 改 `set_codex_last_run` 签名 | **本批接受两次写盘**；改签名属改既有统计源，须用户另行裁定 |

---

## 八、验收四门控

1. **回归纪律**：`SMOKE + 全量钩子 + SMOKE_OATH + SMOKE_ECHO_CHAIN + SMOKE_FLOOR_SIGN + SMOKE_FLAVOR` 6000 帧 **0 报错**；**冻结仍 34/34**（不新增脚本则分母不变）。验证平行字段须显式 `SMOKE_META_SETTLE=1`。
2. **E6**：grep 零新增 raw `delta` / 计时；既有豁免不动。
3. **E1 非污染**：四方向零 `Game.rng` / `fx_rng`、零 `Data.roll_*` / `_spawn_batch`；**同 seed 双跑指纹逐字一致（不重定）**；`ACTION_DEFS` / `GEN_NAMES` 零新增；`UNLOCKS` 与 `STATS_KEYS` 不碰；`CODEX_BOONS` 不扩表、兑现度不调 `mark_codex`。
4. **登记三件套逐项打勾**，尤其 B/D 的「**验页面渲染 / 验播报**」而非只验字段；C 的「roll 前后 rng 消费次数不变」；A 的「写 → load → 逐字段读回 + 五类发现集不被抹」。
5. **P0 红线门保持绿**：`validate` 的 `CODEX_BOONS.kind` 断言继续生效。

---

## 九、落地顺序（编程侧）

**阶段一（A + B）**
1. `OATH_CONDITIONS` 9 条 + 只读事件监听（不新增事件）+ 兑现度派生；`_settle_meta` 中 `set_codex_last_run(stats)` **之后**追加平行字段 + **再 `save_codex()`**，位置在 `if pay <= 0: return` **之前**。
2. 抉择链记录 + 复盘页渲染 + 构筑标签；与 A 共用一次登记三件套。
3. `SMOKE_OATH` / `SMOKE_ECHO_CHAIN`（含 `SMOKE_META_SETTLE=1` 的写→读回断言）→ 四门控 → 交付文档 → **单独提交**。

**阶段二（C + D）**
4. 层签：按 §4.2 在**两个调用点**各加一次纯只读刷新（start_run roll 后 / enter 前；next_floor roll 后 / drop_pickup 前），走 `hud.set_room_info()` 同通道常驻标签，默认 2 项可展开。
5. `FLAVOR` 文案表（基调：废弃矿窟的实用主义）+ 首次播报 + 图鉴展开。
6. `SMOKE_FLOOR_SIGN` / `SMOKE_FLAVOR` → 四门控 → **单独提交**。

---

## 十、主理人备注

- **换轴的实质**：Sprint 13 定下「决策深度 + 局外沉淀」，14/15 实际交付的是内容补齐；本批回到 Dynamics 层，把已有系统接成因果链，组合级收益且零重定代价。
- **两处时序由 `engineering-lead` 复核后修正了主理人的初稿**：① `set_codex_last_run()` 末尾自带 `save_codex()` → 追加字段须**再写一次盘**，且有 `if pay <= 0: return` 早退与 `SMOKE_META_SETTLE` 陷阱；② 层签不能只说「roll 后刷 banner」——`_roll_calamity()` 无条件先消一次 rng、函数体有 3 个提前 return 且被 B5 探针直调两次，**且 `hud.banner()` 会被覆盖**，须改走 `hud.set_room_info()` 常驻标签。按铁律采纳成员结论。
- 设计判断归实稿、技术结论归 `engineering-lead`、汇编与质量门归主理人；三者冲突时以成员为准并由用户裁定。
- 阶段范围、D 基调、A 落盘、C 手感均已定（§七）。主理人侧不写 `.gd`，落地后按流程读码核验。

---

## 十一、`engineering-lead` 复核结论 checklist（实施前逐条勾）

> 来源 `eng-handoff` 回传（全程只读、未改任何文件，行号以实读为准）。以下为**实施约束**，与 §2.3 / §4.2 一致。

- [ ] 平行字段**不进** `set_codex_last_run(stats)`，不改该函数本体、不扩 `Meta.STATS_KEYS`
- [ ] `_settle_meta` 中在 `set_codex_last_run(stats)` 之后赋值 + **再 `save_codex()`**（两次写盘），位于 `if pay <= 0: return` **之前**
- [ ] `load_codex()` Array/Dictionary 原样透传、读档侧无键白名单；`menu._build_codex()` 只读五已知键
- [ ] SMOKE 验证显式 `SMOKE_META_SETTLE=1`；追加是本局最后一次 `last_run` 写入
- [ ] 探针「写 → `load_codex()` → 逐字段读回 + 五类发现集不被抹」（P0-3.2 现场恢复写法）
- [ ] 层签：**不移动** `_roll_calamity()`、不塞进其函数体（3 个提前 return + B5 直调两次）
- [ ] 层签挂点：start_run `roll 后 / enter 前`；next_floor `roll 后 / drop_pickup 前`
- [ ] 层签显示走 `hud.set_room_info()` 同通道常驻标签，**不用 `hud.banner()`**
- [ ] 新增代码零 `Game.rng` / `fx_rng`、零 `Data.roll_*` / `_spawn_batch`
- [ ] `SMOKE_META_FINGERPRINT=1` 双跑逐字一致（自证零指纹重定）
