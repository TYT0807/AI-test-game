# Sprint 12 规划草案（主理人合成 · design-strategist 候选方向）

> 来源：design-strategist（玩法）+ art-director（美术）+ audio-director（音频）+ quality-lead（验收）四专家提案，经主理人综合裁定。
> 本文为**自包含需求候选集**，编程侧据锁定范围实现；主理人侧不写代码（只读核验）。
> 基线：Sprint 10（分辨率/F4/F3/F2）+ Sprint 11（A 反应词缀/C 种子契约/B 主题相位 Boss）已收官，冻结基线 `706a8c3`（30/30）。
> 跨批铁律：**E6 固定步**（DoT/冷却/计时禁 raw delta）、**E1 确定性指纹**（核心 rng 流不无故新增、表外探针不入 E1 diff、坑 45）、**复用优先**（新内容挂在既有系统/接口上，不另起炉灶）、**坑 5 警示**（assets.gd 输入表 318–332 未定稿前动加键踩雷）。

---

## 〇、两条跨批铁律（任何新内容必须遵守）
1. **E6 固定步**：所有新增计时一律 `Game.FIXED_DT` 累加，禁 raw `delta`。
2. **E1 确定性指纹**：核心生成/掉落循环不无故新增 rng；表外验证探针（`SMOKE_*`）不得进入 E1 diff（坑 45）；动 rng 前先想清是否漂移基线。

## 一、候选方向（design-strategist 实稿 + 他专家补充）
- **A. 元进度层扩容「Vault Sigils 深化」（C 的本体展开）**（M，必做）：C 仅交付 3 印记 + 契约接口。本批把元层做厚——新增 5–6 枚印记（协战/壁垒/疾行/丰收/守护/博学），覆盖更多开局增益维度；印记仍 rng 前注入、E1 零漂移。复用 `Data.SIGILS` + `_apply_sigil_contract` + 双档持久。
- **B. 敌人编队扩容 + 「回响」实装（F3 深化 + art 预留兑现）**（M）：新增 2–3 个 SQUADS 模板（沿用现有 schema），并实装 art 在 B 预留的「回响 / The Echo」为可召唤单位/特殊敌人；给常规层 + 守望者阶段增援更多变数。
- **C. 第二主题 Boss / Boss 变体（B 深化）**（L）：在 Prism Warden 之外新增一个主题 Boss，复用 B 的状态机骨架（`phase_theme_index` 纯函数 + 主题复用范式），换主题序列/机制权重/外观。
- **D. 每日挑战 / 种子分享（E1 红利）**（M）：游戏已有强确定性（E1 指纹 + 楼层派生 rng），新增"每日种子"模式——同日期派生同 seed，比拼层数/时间；本地结果记录（复用 ConfigFile 持久）。
- **E. 灾祸层 / 风险回报**（M）：每层小概率触发"灾祸"（血量上限-20% / 敌人加速 / 弹药减半），换取更高 shards 倍率；复用 modifier 体系。
- **F. 第五主动遗物（F2 深化）**（高危，前置定稿输入表）：新增第 5 个主动遗物 + 第 5 键。坑 5 警示：assets.gd 输入表 318–332 未定稿前动加键必踩雷，**除非先定稿输入表，否则不接**。
- **G. 非阻塞遗留折算（小修 + 设计裁定）**：① dash option b（冲刺实测 196–210px 是否改严格 ~120px 纯传送语义）——设计裁定项；② 环盾期 HUD 冷却显示（交付称本批已修，确认闭环）；③ 「回响」已并入 B 实装。

## 二、优先级裁定（主理人，与设计专家一致 · 用户 2026-11-07 拍板"全部"锁定）
- **本批全锁 A + B + C + D + E**；**F 第五遗物明确不接**（坑 5：assets.gd 输入表 318–332 未定稿前动加键必踩雷，除非先定稿输入表否则永不接）。
- **分两阶段交付（大批次，工程与评审成本分散）**：
  - **阶段一（先交付）**：A 元层扩容 + B 编队扩容/回响——接口已锁、复用彻底、风险最低，先验证"元进度+编队"范式。
  - **阶段二（紧随）**：C 第二 Boss + D 每日挑战 + E 灾祸层——在 A+B 范式验证后展开。
- A 仍为性价比最高项；B 兑现 art 预留；C/D/E 把 Sprint 10–11 的确定性与主题范式进一步变现。

## 三、锁定批次组合（全范围）
- **阶段一**：A 元进度扩容（M）+ B 编队扩容/回响（M）。
- **阶段二**：C 第二主题 Boss（L）+ D 每日挑战（M）+ E 灾祸层（M）。
- 沿用跨批铁律（E6/E1/复用优先/坑 5 不接 F）。

---

## 四、方向 A 完整落地规格预备（Vault Sigils 深化）
### 4.1 新增印记（data.gd `SIGILS` 扩表）
在现有 `vigor/arsenal/purse` 之后追加（cost 经平衡初估，可微调）：
| id | 名 | 效果 | cost |
|----|----|------|------|
| `kindred` | 协战印记 | 开局召唤 1 个临时协战单位（30s，复用 slug 基类，中立/友方判定须明确） | 50 |
| `bulwark` | 壁垒印记 | 开局获得 1 层环盾护盾（`relic_shield_t` 置初值） | 35 |
| `sprinter` | 疾行印记 | 冲刺距离/无敌帧 +30%（`_dash_t` 初值增益） | 40 |
| `harvester` | 丰收印记 | 击杀额外 +1 源石（敌人死亡结算处 +1） | 45 |
| `ward` | 守护印记 | Boss 战首阶段受到伤害 -20%（`Game.main` 伤害入口乘系数） | 60 |
| `scholar` | 博学印记 | 每层首次清场额外 +N shards（层清事件钩） | 40 |
### 4.2 注入（game_main `_apply_sigil_contract`，rng 前）
- 现有 match 按 `eq` 绝对置位；新增 6 分支同范式（幂等）：kindred→生成临时协战 / bulwark→`relic_shield_t` / sprinter→冲刺增益标志 / harvester→击杀加成标志 / ward→Boss 减伤标志 / scholar→层清加成标志。
- **E1 零漂移**：印记选择玩家驱动、run 前发生，仍零 rng；但 `kindred` 若用 `Game.rng` 生成协战单位，**须在文档登记并随本批重定基线**（同 A 词缀掉落，属预期代价）。
### 4.3 持久化与契约（沿用 C）
- 直接复用 `SIGILS` 表 + `META_RATE` + `load/save/unlock/equip_sigil` + 双档（SIGIL_PATH/SIGIL_SMOME_PATH）；新增 id 经 `Data.SIGILS.has` 校验（读档回退已防穿透）。
- 菜单印记页（menu `_build_sigils`）已按 `Data.SIGILS` 遍历渲染 → 扩表即自动出新选项，无需改 UI 循环（验收时确认）。
### 4.4 rng/指纹
- 6 新印记零额外 rng（除 kindred 生成）；`SMOKE_META_PERSIST` 表外不进 E1 diff（坑 45）。

## 五、方向 B 完整落地规格预备（编队扩容 + 回响）
### 5.1 新增 SQUADS 模板（data.gd `SQUADS`，沿用 schema）
- `hunt`：围猎（min_floor 5, weight 9）—— wolf×2 冲刺 + flameskull×1 远程。
- `alchemy`：炼金（min_floor 6, weight 8）—— mush(毒) + imp(沼) + flame×1 组合 DoT。
- `echo_pack`：回响编队（min_floor 7, weight 7）—— `echo`×1（新实体）+ rusher×2；**实装 art 预留的「回响」**。
### 5.2 「回响 / The Echo」实体（art 预留兑现）
- 新 enemy 原型 `echo`：短暂镜像玩家移动（读取 `Game.main.player` 轨迹缓冲）后突进攻击；被击败触发短暂增益（如 2s 攻速/拾取半径提升）或视野揭示——具体机制由美术+音频定调，工程上复用 slug 基类 + 现有死亡结算。
- 风险：新 enemy 实体（小到中），须过成员清单 + 编译扫描 + 不污染既有 enemy 循环。
### 5.3 接入
- 纯数据模板 → 既有 `_roll_squad` / Warden `_call_reinforcement`（`spawn_slug`）自动生效；`echo` 实体按现有 enemy 生成路径落地。
- E1：编队选取走既有 `Game.rng` 流（不新建）；`SMOKE_SQUAD` 表外探针守坑 45。

## 六、方向 C / D / E / F 落地规格预备

### 6.1 C 第二主题 Boss「熔潮主宰 / Pyrothalassian（暂名）」（L）
- **复用骨架**：新建 `scripts/boss2.gd`，**复用 `PrismWarden` 的状态机范式**（INTRO→ACTIVE→PHASE_2→PHASE_3→DYING、`phase_theme_index` 纯函数、主题复用脉冲、既有 `Game.rng` 流增援、`SMOKE_BOSS` 探针范式）。不另起炉灶。
- **差异化（避免与守望者雷同）**：① 主题序列偏移 `phase_theme_index(floor_num, k + OFFSET)`（OFFSET=4，走另一组三阶段组合）；② 机制权重偏向 DoT/压迫（magma+toxic+swamp 脉冲更密）；③ 外观换 tint（与守望者区分，数据驱动）；④ 接入点谓词 `_is_sovereign_floor(n) = n>4 and (n-4)%16==15`（每 16 层一次，与守望者每 8 层错开，互不冲突）。
- **风险**：新 Boss 实体（L），须过成员清单 + 编译扫描 + 不污染 enemy 循环 + 同套探针（`SMOKE_BOSS2` 表外，守坑 45）。
- **E1**：主题选取纯函数零 rng；阶段随机路由既有 `Game.rng` 流（不新建）；Boss 战 rng 消费登记 + 基线随本批重定（同 B）。

### 6.2 D 每日挑战 / 种子分享（M，E1 红利）
- **seed 派生**：`daily_seed = hash(YYYYMMDD) % SEED_SPACE`（`SEED_SPACE` 取 `Game.rng` 支持范围）；仅 daily 模式在 `start_run` 的 `Game.rng.seed` 首抽前覆盖为 `daily_seed`（rng 前注入，E1 零漂移）。
- **模式入口**：主菜单新增「每日挑战」按钮（复用 menu 现有结构）；选择后 `Game.daily_mode=true` + 设固定 seed + 常规流程。
- **本地结果榜**：用 ConfigFile 存 `daily_best[yyyymmdd] = {layers, time}`（复用 `sigils.cfg` 同款持久范式，独立文件 `user://daily.cfg`），主菜单展示当日最佳。
- **E1**：完全复用现有 rng 体系（固定 seed → 同 seed 同局），零新 rng 流、零新风险；`SMOKE_DAILY` 表外探针（验证同 seed 复现一致）。

### 6.3 E 灾祸层 / 风险回报（M）
- **触发**：每层进入时小概率（初估 15%，常量可调）触发灾祸，叠加一个负面 modifier：① 血量上限-20% ② 敌人加速 +25% ③ 弹药减半（齐射弹数/射速-50%）④ 源石掉率-30%；同时 **shards 倍率 +50%**（风险回报）。
- **复用**：先查明现有 modifier 体系（`_roll_modifier` 在 game_main:322 调用）是否支持运行时叠加负面效果；若支持则扩 `apply_calamity(id)`，否则新增轻量 calamity 层（禁用项挂 `Game` 全局标志，敌人/玩家读取）。
- **风险**：中（需查 modifier 体系）；灾祸触发走既有 `Game.rng` 流（不新建），E1 安全。
- **E6**：灾祸持续/衰减全 `Game.FIXED_DT`。

### 6.4 F 第五主动遗物 —— **本批不接**
- 坑 5 警示：assets.gd 输入表 318–332 未定稿前动加键必踩雷。**除非先定稿输入表，否则 Sprint 12 永不接 F**（已排除在锁定范围外）。

## 七、验收四门控（quality-lead，复用 Sprint 11 范式）
1. **回归纪律**：`SMOKE+V8+REBIND+RELIC+SUFFIX+META+PERSIST+BOSS+ECHO+BOSS2+DAILY[+CALAMITY]` 跑 3000 帧 0 报错；冻结基线随本批重定（含新实体/扩表，N/N 重定）。
2. **E6 合规**：grep 确认 A 新计时（协战存活/层清加成钩等）、B 回响移动、C 第二 Boss、D 每日 seed 注入点、E 灾祸衰减全走 `Game.FIXED_DT`，无 raw delta。
3. **E1 非污染**：A 印记零 rng（kindred 生成登记 + 基线重定）；B/C 编队与 Boss 随机路由既有流；D 固定 seed 复用现有 rng；`SMOKE_*` 表外不进 diff（坑 45）。
4. **探针设计**：扩 `SMOKE_ECHO`（回响生成/击败增益）、`SMOKE_BOSS2`（第二 Boss 阶段+主题确定性）、`SMOKE_DAILY`（同 seed 复现一致）、`SMOKE_CALAMITY`（灾祸触发+倍率），均表外守坑 45。

## 八、落地顺序与两阶段交付（编程侧）
**阶段一（先交付，复用彻底、风险最低）**：
1. A：扩 `Data.SIGILS` 6 枚 + `_apply_sigil_contract` 注入分支（幂等）+ 菜单自动渲染。
2. B：SQUADS 新模板 + `echo` 实体。
3. 跑四道门控 + 冻结重定。
**阶段二（阶段一验证后展开）**：
4. C：第二 Boss `boss2.gd`（复用守望者骨架）+ 接入点谓词。
5. D：每日挑战 seed 派生 + 菜单入口 + 本地结果榜。
6. E：灾祸层（先查 modifier 体系再扩）。
7. 每阶段完单独提交（底账已就位 `706a8c3`，之后每批 commit）。

## 九、主理人备注（不进转发文本）
- **本批全锁 A+B+C+D+E，F 不接**（坑 5）。两阶段交付：A+B 优先验证范式，C/D/E 紧随。
- 设计裁定（已定，不阻塞）：**dash option b 保持当前 196–210px（120 直驱 + 碰撞挤出）作为手感特性**，除非用户后续明确要求干净传送语义；不另起改造。
- 环盾期 HUD 冷却显示据 Sprint 11 交付已修，本批无需再动。
- 「回响」既兑现 art 预留，又给 B 阶段增援 + 常规层新花样，一举两得。
- 所有新内容挂在已冻结系统（C 契约 / F3 SQUADS / B 状态机 / E1 rng 体系）之上，复用优先、风险可控。
