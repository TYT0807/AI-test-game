# Sprint 17 规划草案（技术收敛批 · 主理人合成）

> 基线（本轮实校）：`git log -1` = `9b6568b`（Sprint 16 文档整理批，纯文档）；功能码基线 `2a04d4e`；`git status --short` 空；`md5sum -c` **34 OK / 0 FAILED**；**34 个 `.gd`**。
> **锁定范围（用户 2026-11-08 裁定「按推荐 A+B / C+D」）**：**两阶段全锁**，阶段一 A+B、阶段二 C+D，**每阶段单独提交**。
> **定位**：Sprint 16 已 final PASS 收官、四条在册观察都裁定不返工。本批**不上新玩法实体**，做一次零 E1 的**技术收敛**：清在册观察、补断言盘点、加一个纯局外小增量、同步文档。全批**指纹不变、冻结仍 34/34**。
> **新协作模型第一次实跑**：按用户 2026-11-08 裁定，`scripts/*.gd` 的实施由游戏开发工作室 `engineering-lead` 成员承接，`quality-lead` 承接四门控复核，**主理人只编排 + 读码核验 + 汇编、不写 `.gd`**。不再转交外部 AI。
> 本文为自包含规格；行号以 `git log` 与文件实读为准，不采信文档快照。

---

## 〇、跨批铁律（全部沿用）

1. **E6**：计时走 `Game.FIXED_DT`，禁 raw `delta`；`player._tick_buffs(delta)` 与 `toxic_cloud` 敌方云是**既有在册豁免，别顺手统一**（会改 E1 基线）。
2. **E1**：核心循环零新增 `Game.rng`；`SMOKE_*` 表外不进指纹；`_smoke_fingerprint` 只含 rooms 坐标 + kinds。
3. **坑 5**：`ACTION_DEFS` 零新增；新资源走 `Assets.g()` 须同步登记 `GEN_NAMES`。
4. **冻结规格 v2.10**：`meta.gd UNLOCKS` 与 `Meta.STATS_KEYS` 不动。
5. **登记三件套**：①写入 ②注册表/白名单/UI 分母/显示名 ③可见效果断言（验数值或验渲染）。
6. **boon 红线**：`CODEX_BOONS[*].kind` 禁 `suffixes`；兑现度不调 `mark_codex`。
7. **Boss 契约**：`variant="boss"` 严禁改；图鉴登记走 `codex_id`。
8. **其它**：`FLOOR_THEMES` 8→12 永不接；dash 保持 196–210px；终审附章休眠。
9. **纪律**：凡标 ✓ 必附本轮实读行号；commit/行号以 `git log` 与实读为准。
10. **批次流程**：实施 → 四门控 → 冻结重定 → 交付文档 → **单独提交** → 主理人读码核验。

---

## 一、候选方向（A–E）

| 方向 | 规模 | 内容 | 裁定 |
|---|---|---|---|
| **A 在册观察收口** | S | 四条观察里真正需要动代码的项 + 一处文档措辞订正 | **推荐阶段一** |
| **B E 断言盘点** | S | 给四类断言标注性质与意图（需改 `.gd` 注释），产出盘点清单 | **推荐阶段一**（由 `engineering-lead` 承接） |
| **C 每日分享码 + 本地榜** | S–M | 本批唯一小增量：纯局外、零 rng、不改 `start_run` 顺序 | **推荐阶段二** |
| **D 玩法说明补 Sprint 16** | S | 文档，主理人职权内 | **推荐阶段二并行** |
| **E 发现口径翻案** | S | `relics` 登记改挂 `pickup.gd` 拾取 | **备选不接**（Sprint 15 已裁定「已见遗物」零代码方案） |

**明确不做**（Sprint 16 设计实稿 §七 + 既定红线）：第 12 房型 / 房间事件池（改 kinds 需指纹重定、与 `shrine` 三卡同构）、武器淬炼（开火 rng 密集）、第四位主题 Boss、`FLOOR_THEMES` 8→12、每日固定词缀（改 `start_run` rng 顺序）、boon suffixes 阈值（须重做 P0 门）。

---

## 二、锁定组合（用户已裁定：A+B / C+D 两阶段全锁）

| 阶段 | 方向 | 交付物 |
|---|---|---|
| 一 | **A + B** | 观察收口 + 断言盘点；`engineering-lead` 实施、`quality-lead` 四门控、主理人读码核验 |
| 二 | **C + D** | 每日分享码 / 本地榜 + 玩法说明补 Sprint 16 节 |

两阶段各自单独提交；全批零 E1、零指纹重定、冻结仍 **34/34**（不新增脚本）。

---

## 三、阶段一：A + B 完整规格

### 3.1 A1 跳层后层签重刷（`engineering-lead`）

- **现状（实读）**：`game_main.gd:370 update_floor_sign()` 在 SMOKE 跳层块 `:371–375` **之前**；跳层块内只调 `_apply_floor_theme()`，层签不重刷 → `SMOKE_JUMP_FLOOR=11` 时层签仍显示 floor=1 的「无主题」，与实际层不符。仅影响 SMOKE 探针路径，正常游戏无跳层。
- **修法**：在跳层块的 `_apply_floor_theme()` **之后**补一次 `update_floor_sign()`。该函数已实读为纯只读（`Data.theme_for_floor()` + `_calamity_name()` + `hud.set_floor_sign()`），**零 rng / 零 fx_rng / 零抽取**。
- **验收**：`SMOKE_JUMP_FLOOR=11 + SMOKE_FLOOR_SIGN` 下断言层签文本含 11 层主题名；`Game.rng.state` / `fx_rng.state` 前后相等。

### 3.2 A2 `oath_fulfillment()` 防御性初值

- **现状**：`game_main.gd:2110` 起 `var cur := 999`，若 `watched` 为空则 `cur` 保持 999，`done = 999 >= need` 恒真。`validate` 已挡 `watched` 空（启动期），无实害，但属隐患。
- **修法**：改为显式空数组早退 `if (def["watched"] as Array).is_empty(): return {}`；或把 `cur` 初始化为首个 watched 值而非魔数。**零行为变化**（正常数据下）。
- **验收**：`SMOKE_OATH` 既有 12 断言全绿 + 补一条「空 watched 返回空字典」负向断言。

### 3.3 A3 播报覆盖口径（登记，不改代码）

- `FLAVOR` 播报走 `hud.flash_toast()`（2.2s 单例 tween），同帧多个首次发现会互相覆盖。改队列/去重会引入表现层计时（E6 风险）与体验取舍，**本批不动**，登记为产品裁定项。
- 若用户要求处理，最小方案是「同帧只播最后一条 + 交付文档注明」，由 `engineering-lead` 单列一小批。

### 3.4 A4 交付文档措辞订正（纯文档）

- `production/sprint-16/SPR16_交付_阶段一.md:36` 写「`hud.set_room_info()` 同通道」，实现其实是**独立的 `hud.set_floor_sign()`**（`hud.gd:585`，与 `set_room_info` 同容器）。订正为「与 `set_room_info` 同容器的独立常驻只读标签 `set_floor_sign()`」，避免接手方误以为要改 `set_room_info`。

### 3.5 B 断言盘点（`engineering-lead` 改注释 + 出清单）

- 分类口径（Sprint 14 起反复踩坑）：
  | 类别 | 性质 | 处理 |
  |---|---|---|
  | 验效果型 | 有真实差值、能抓回归 | 保持 |
  | 前提守卫型恒过 | 当前恒过，用于拦未来放宽 | **标注性质 + 意图**，不算假断言 |
  | 常量自比较 | 自己定义自己读 | **标注**；能补渲染/数值断言则补 |
  | 只验标志不验数值 | 易漏缺陷 | **必须补强** |
- 落点：`validate.gd` 的 B4 前提守卫门与 P0 门、`player.gd` 的显示名常量自比较断言、`SMOKE_*` 各探针。
- **Deliverables**：① 相关 `Dev.check` / `_check_*` 旁补注释标类 ② `production/sprint-17/SPR17_断言盘点清单.md`（分类 / 落点 / 是否需要补强 / 理由）。**不改断言逻辑**，只做标注与清单。
- **验收**：`quality-lead` 复核清单与注释一致；不新增任何恒过断言冒充验效果型。

---

## 四、阶段二：C + D 完整规格

### 4.1 C 每日分享码 + 本地榜（唯一小增量）

| 项 | 规格 |
|---|---|
| 挂接点（实读） | `game_state.gd:447 daily_best_today()` / `DAILY_PATH`（`user://daily.cfg`）/ `record_daily_best()`；`menu.gd:131` 主菜单「今日最佳」区；`game_main.gd` 结算处 `Game.record_daily_best(...)` |
| 分享码 | `daily_key()` 文本 + `Game.stable_hash()` 校验位，主菜单可复制/粘贴（纯文本、**零 `Game.rng`**）；不需要联网、不需要新 action（复用现有按钮或鼠标事件，坑 5 安全） |
| 本地榜 | 扩展 `daily.cfg` 存**最近 N 天**（建议 7）的 `layers/time`，纯局外只读；沿用 `SMOKE_DAILY_*` 隔离档范式，避免污染玩家档 |
| 明确不做 | **每日固定词缀**（会改 `start_run:340–345` 的 rng 顺序 → 基线重定）；不新增 `STATS_KEYS`，不碰 `UNLOCKS` |
| 三件套 | ① 分享码/榜单写入 ② `validate` 启动期校验 `DAILY_PATH` 读档容错 + 主菜单显示 ③ `SMOKE_DAILY_SHARE` 断言（分享码往返一致、榜单读写往返、坏档降级不崩、同 seed 双跑一致） |
| E1 / 冻结 | 零 rng、零计时、无新脚本 → **指纹不变、仍 34/34** |

### 4.2 D 玩法说明补 Sprint 16（主理人职权内文档）

`玩法说明.md` 当前版本注为「Sprint 15 收官版」。补：
- 版本注与标题 → **Sprint 16 收官版**；文末新增「Sprint 16 增补」节（地窖誓约 9 条 / 抉择回声与构筑标签 / 层签常驻 2 项 / 地窖低语 11 条矿工手记 / 图鉴复盘两行）。
- 工程状态更新：34 脚本、冻结 34/34、新增 `SMOKE_OATH` / `SMOKE_ECHO_CHAIN` / `SMOKE_FLOOR_SIGN` / `SMOKE_FLAVOR` 探针。
- 保留 Sprint 10–13 / 14–15 两节为历史，不重写。

---

## 五、新协作模型落地方式（本批第一次实跑）

| 环节 | 承担 |
|---|---|
| 规格 / 挂接点实读 / 范围编排 | 主理人（本草案） |
| `scripts/*.gd` 实施、自测、冻结重定、交付文档、单独提交 | **`engineering-lead`**（`eng-handoff`，已加载本项目技术上下文） |
| 四门控复核、断言有效性判定、PASS/CONCERNS | **`quality-lead`**（`qa-handoff`） |
| 读码核验、final PASS、汇编汇报 | 主理人 |
| 设计候选（Sprint 18 用，不阻塞本批） | `design-strategist`（`design-s16`，已派 `SPR17-DESIGN-01`） |

派单规则：用户裁定锁定范围后，主理人把每阶段拆成**含文件路径 / 函数名 / 验收判据的自包含任务单**发给 `eng-handoff`；成员间禁止直连；任何 `.gd` 改动与 git 提交仍须用户许可；改前备份、小步可回滚。

---

## 六、验收四门控

1. **回归纪律**：阶段一 = `SMOKE + 全量钩子 + SMOKE_FLOOR_SIGN + SMOKE_JUMP_FLOOR=11`；阶段二 = 再加 `SMOKE_DAILY_SHARE`。均 6000 帧 **0 报错**；冻结 `md5sum -c` 仍 **34 OK / 0 FAILED**；脚本数仍 34。（订正：初稿把阶段二 C 的 `SMOKE_DAILY_SHARE` 误写进阶段一门①，属跨阶段笔误，由 `engineering-lead` 在阶段一交付文档 §三 第 6 条如实指出。）
2. **E6**：grep 零新增 raw `delta` / 计时；既有豁免不动。
3. **E1 非污染**：全批零 `Game.rng` / `fx_rng` 消费（层签用 `rng.state` 前后相等自证）；同 seed 双跑指纹逐字一致；`ACTION_DEFS` / `GEN_NAMES` 零新增；`UNLOCKS` / `STATS_KEYS` / `CODEX_BOONS` 不碰。
4. **探针**：新增/改动断言必须**验数值或验渲染**；`quality-lead` 按 §3.5 四类口径复核，不收「只验标志」的绿灯。
5. **提交**：每阶段一个 commit，不混入主理人侧文档（D 随阶段二或单独文档批，需授权）。

---

## 七、落地顺序（编程侧）

**阶段一（A + B）**
1. A1 跳层块补 `update_floor_sign()` + 定向断言；A2 空 `watched` 早退 + 负向断言；A4 文档措辞。
2. B 断言分类注释 + `SPR17_断言盘点清单.md`。
3. 四门控 → 冻结重定（34/34）→ 交付文档 → **单独提交**。

**阶段二（C + D）**
4. 分享码 + 本地榜 + `SMOKE_DAILY_SHARE`；不碰 `start_run` 顺序。
5. 玩法说明补 Sprint 16 节。
6. 四门控 → **单独提交**（或文档部分随授权文档批）。

---

## 八、主理人备注

- **为什么是收敛批**：Sprint 16 换轴刚落地且零重定收官，此时再加实体会重复「内容堆叠」的老路；把四条在册观察、断言盘点、玩法说明滞后清干净，再顺手补一个零 E1 的局外小增量，性价比最高。
- **本批最大价值是验证新协作链**：`engineering-lead` 承接 `.gd`、`quality-lead` 复核、主理人只读核验。规模小、风险低，适合第一次跑通；跑顺之后再上 Sprint 18 的联动型增量。
- `design-s16` 的 Sprint 18 创意候选在后台产出，**不进本批范围**，避免像 Sprint 16 那样出现「草案已写、实稿又推翻」的返工。
- 锁定范围已由用户裁定为 **A+B / C+D 两阶段全锁**（2026-11-08），每阶段单独提交。主理人侧不写 `.gd`，实施由 `engineering-lead` 承接、`quality-lead` 复核，落地后主理人读码核验。
