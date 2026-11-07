# Sprint 10 交付（第三批）：F3 敌人编队 + 毒巢 DoT 口径统一

> 日期：2026-11-07｜依据 `SPR10_规划草案.md` §二 + 主理人毒巢口径裁定｜分工：编程侧
> 改动文件：`scripts/data.gd`、`scripts/slug.gd`、`scripts/game_main.gd`、`scripts/bomb.gd`、`scripts/validate.gd`、`resources/texture/generated/icon_affix_mender.png`（新）、`_tools/gen_assets.py`（+mender 画师）

## 一、改了什么

1. **`data.gd`**
   - 新增 `SQUADS` 编队模板表（4 模板，风格与既有池表一致）：护盾+召唤（orc[护盾]+mush 召唤+goblin×2，4 层起）、治疗+冲锋（zombie[治疗]+wolf×2 蓄力扑咬，5 层起）、狙击+拆弹（flameskull×2 远程+imp[拆弹]，6 层起）、潮涌（rusher×4+goblin×3+imp×3 共 10 只，3 层起）；各带 min_floor/weight
   - `AFFIXES` 新增 `"mender"`（治疗词缀：+2hp / 半径 90 / CD 4s，含 icon 键）
2. **`slug.gd`**
   - 新增 `defuser` 标志与 `_mender_cfg`；setup 词缀块接入 mender
   - **治疗脉冲**：E6 固定步（`Game.FIXED_DT`）计时，CD 到点对半径 90 内存活友军 +2hp（含自身），有实际治疗才闪绿出声
   - **拆弹行为**：240px 内有玩家炸弹（`bombs` 组）时**优先追弹**（覆盖贴身停顿与普通追击），触碰 18px 内 `bomb.defuse()`
3. **`bomb.gd`**：入 `bombs` 组；新增 `defuse()`（掐引信哑弹消散，`_defused` 防重）与 `set_fuse()`（探针用）；`_boom` 加防重护栏
4. **`game_main.gd`**
   - `_roll_squad()`：combat 房 40% 概率整组编队（走 Game.rng 主流；权重抽取；`SMOKE_FORCE_SQUAD=<id>` 表外测试钩可钉死选取并跳过概率门）；`_room_budget` = 编队人数
   - `_spawn_batch()`：编队房按成员出怪（front 210px 近点 / back 300px 远点，<150 自动补位）；`_telegraph_slug`/`spawn_slug` 增加 `defuser` 参数透传
   - **`SMOKE_DEFUSER_PROBE=1`**：拆弹成员落位 1.2s 后在其旁种一颗 9s 长引信哑弹（确定性验证钩）
5. **`validate.gd`**：新增 `_check_squads()`——成员 id ⊆ ENEMIES、词缀 ⊆ AFFIXES、数量/权重/起始层合法性
6. **毒巢 DoT 口径统一（主理人裁定落地）**：`_tick_floor_theme` toxic 分支 raw delta → `Game.FIXED_DT`，与 magma 同口径；实测 floor-5 探针 1500 帧 = 8 次 tick，与 25 游戏秒 ÷ 3 秒周期**精确吻合**

## 二、验证了什么（全部实跑）

| 项 | 结果 |
|-|-|
| 自检（含新 `_check_squads`） | 通过（编队表 4 条全合法） |
| 潮涌编队实 spawn（floor-6 自然抽取） | `[SMOKE-SQUAD] squad=tide(潮涌) total=10` + 房内敌人证实 |
| **狙击+拆弹全链路**（SMOKE_FORCE_SQUAD 钉死） | 3 房编队 + 3 哑弹种植 + **2 次追近拆除**（第 3 颗探针哑弹落点在场外钳制区外，探针自身小瑕疵不影响判定） |
| 毒巢 FIXED_DT 统一 | floor-5 探针 8 ticks = 固定步数学精确值 |
| 组合回归（SMOKE+V8+REBIND 3000 帧） | 0 报错，三探针全过 |
| 冻结清单 | 重定 29/29 OK |

## 三、踩坑记录

1. **`_roll_squad` 的 40% 概率门挡住了 FORCE 钩子**——首轮 4 种子 × 4500 帧零命中曾误判为概率运气，周期快照行（t= 行）是「房内状态」不是「进门事件」，26 条 combat 快照 ≠ 26 次进房。修正：FORCE 时跳过概率门（rng 消耗保持）。
2. **多行 lambda 作尾参时后置逗号参数不可靠**——`safe_delay` 的 `process_always` 因此重排到 cb 之前（上批已记，本批 menu 调用按新签名）。
3. GDScript 同名变量重复声明不报错（`var forced` 两处）——静默遮蔽，靠读码发现；大段替换后必须通读整个函数。

## 四、E1 指纹影响声明（坑 45 预案）

编队选取走 Game.rng 主流（规划草案 §二 明确允许）——**每房多消耗 1-2 次随机数，E1 指纹与 spr8 基线全体漂移**，按坑 45 既有口径：跨版本日志作废，E1 重定基线留待下一 QA 窗口（按楼层取交集）。`[SMOKE-SQUAD]` 为表外探针，不参与任何 diff。

## 五、还剩什么

- Sprint 10 剩余：F2 主动遗物（输入表已定稿，前置全清）
- 拆弹探针哑弹落点未钳制场内（探针自身小瑕疵，不影响链路判定；下批顺手钳制）
