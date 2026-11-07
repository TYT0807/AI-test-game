# Sprint 11 · B 主题相位 Boss「棱镜守望者 / Shiftwarden」状态机细化规格

> 来源：design-strategist（玩法/状态机）+ art-director（美术）+ audio-director（音频）+ quality-lead（验收），经主理人综合裁定。
> 本文为**自包含需求规格**，编程侧据以实现；主理人侧不写代码（只读核验）。
> 依赖基线：Sprint 10 已冻结的 F4 主题地形（8 主题循环）、F3 敌人编队（SQUADS）、F2 主动遗物；Sprint 11 已交付的 A 反应词缀 + C 种子契约。
> 跨批铁律：**E6 固定步**（一切计时走 `Game.FIXED_DT`，禁 raw delta）、**E1 确定性指纹**（动 `Game.rng` 前先想清是否漂移基线，坑 45）。

---

## 〇、两条硬约束（任何实现必须遵守）
1. **E6 固定步**：Boss 全部计时（`boss_cd_accum` / `ring_t` / `phase_t` / `phase_dot_accum` / 冲刺位移步进）一律 `+= Game.FIXED_DT`，**禁止 raw `delta`**。
2. **E1 指纹**：主题选取是**纯函数零 rng**；阶段内随机（增援哪队、冲刺方向）必须**路由进既有 `Game.rng` 流**，不得新建第二条 rng。Boss 战会消耗 `Game.rng` → 改变绝对指纹 → **本批须随 B 重定 E1 冻结基线**（同 A 的词缀掉落，属预期代价，登记于 §七）。

---

## 一、概念与命名
- **玩法名**：棱镜守望者（Shiftwarden）。墨黑棱柱核心 + 三枚绕转主题碎片，把 F4 的 8 主题差异直接转化为 Boss 战可读性。
- **核心循环**：按 HP 66% / 33% 阈值切三阶段，每阶段"认领"当前楼层周期里**连续 3 个主题**之一作为本阶段签名机制，并召唤一支 F3 SQUADS 增援。玩家读 Boss 碎片颜色即可预判本阶段机制（颜色 = 该阶段主题 `tint`）。

## 二、出现条件（接入点，可转发即落地）
- **首领层判定**：`floor_num > 4 and ((floor_num - 4) % 8 == 7)`——即每个 8 主题周期的最后一层（紧接下一周期前），在该层生成棱镜守望者作为层末 Boss。
- 进入首领层时暂停常规 SQUADS 普通抽取（Boss 阶段增援由本规格独立控制，避免双重召唤）；Boss 死亡后恢复常规流程并进入下一主题周期。
- 若编程侧想改接入层，只动本判定谓词即可，不影响状态机内部。

## 三、三阶段主题选取（纯函数，零 rng）
复用 `Data.theme_for_floor(n)` 的取模逻辑（`4 + ((n-4) % 8)`）。Boss 三阶段主题**完全由首领层 floor_num 决定**：

```
phase_theme_index(k) = 4 + (((floor_num - 4) + k) % 8)   // k = 0,1,2
```

- `k=0` → 阶段一主题；`k=1` → 阶段二；`k=2` → 阶段三。
- 步长 1、模 8，保证三阶段主题**互不重复**（无绕回碰撞），且对同 floor 完全确定（复跑一致，供 `SMOKE_BOSS` 校验）。
- 8 主题 rule 键（来自 `FLOOR_THEMES`）：`vein`(源石矿脉) / `toxic`(毒巢) / `pressure`(高压层) / `silent`(静默层) / `magma`(岩浆灼烧) / `ice`(冰面打滑) / `swamp`(毒沼减速) / `vines`(藤蔓阻挡)。

## 四、状态机（显式枚举 + 切换条件）
| 状态 | 进入条件 | 行为 | 退出条件 |
|------|----------|------|----------|
| `INTRO` | 首领层生成时 | 登场无敌；播 `sfx("boss_intro")`；`phase_t` 累计到登场时长阈值 | `phase_t >= INTRO_DUR`（FIXED_DT 累计） |
| `ACTIVE`（阶段一） | INTRO 结束 | HP 100%→66%；激活 `phase_theme_index(0)` 签名机制 + 召唤第 1 支增援 | `boss_hp <= 0.66 * boss_max_hp` |
| `PHASE_2`（阶段二） | HP 跌破 66% 且未进过 | 重置阶段计时；激活 `phase_theme_index(1)` + 召唤第 2 支增援；播 `sfx("boss_phase")` | `boss_hp <= 0.33 * boss_max_hp` |
| `PHASE_3`（阶段三） | HP 跌破 33% 且未进过 | 重置阶段计时；激活 `phase_theme_index(2)` + 召唤第 3 支增援；播 `sfx("boss_phase")` | `boss_hp <= 0` |
| `DYING` | HP 归零 | 死亡动画；`boss_prism_death_shard` VFX（复用 toxic_cloud puff 改色 + 本阶段 `tint`）；纯确定性掉落结算 | 动画结束 → 移除实体、恢复常规流程 |

> 阶段只向下切换、不回退；HP 阈值检测每帧在 `_tick`（FIXED_DT 驱动）里做，避免 raw delta 误判。

## 五、每阶段签名机制复用（复用 F4 既有 theme handler，不重写）
Boss **不是**把整层 terrain 改成该主题，而是以 Boss 为"触发源/控制器"，周期性生成该主题的中期 hazard 实体——把 F4 的静态地形机制转为 Boss 攻击。按所选主题的 `rule` 分派到 F4 既有 `_apply_theme` / `_tick_theme` 分支或既有 prop 实体：

- `magma`（岩浆灼烧）→ **扩散 DoT 脉冲环**：从 Boss 位置向外扩的岩浆环，复用 F4 magma 分支的 FIXED_DT 累加逻辑 + 生成 `prop_magma` 脉冲实体。
- `ice`（冰面打滑）→ **减速斑块**：在玩家附近生成冰面斑块（经过减速），复用 ice 分支。
- `vines`（藤蔓阻挡）→ **全向阻挡藤蔓**：生成 `prop_vine`（hp2 / solid / `collision_layer=1`），复用既有 prop_vine 生成 + 导入。
- `toxic`（毒巢）/ `swamp`（毒沼减速）→ **毒/沼 DoT 场**：复用 toxic 分支 DoT 场实体（friendly 双模已固化）。
- `vein`（源石矿脉）→ **可破坏矿脉障碍 + 源石掉落**：复用 vein 分支。
- `pressure`（高压层）→ **周期范围压迫脉冲**：复用 pressure 分支的范围压迫表现。
- `silent`（静默层）→ **区域沉默/能力压制**：复用 silent 分支的沉默机制（若 F4 silent 仅影响生成则降级为视觉压迫）。

> 实现铁律：**优先调用既有 handler / 生成既有 prop 实体**，Boss 只作为这些实体的触发源与计时控制器；禁止为 Boss 重写一套并行主题逻辑（保持单一真相源，规避 E1 漂移与维护分叉）。

## 六、计时与随机（全 FIXED_DT + 既有 rng 流）
- `boss_cd_accum += Game.FIXED_DT`：到 `BOSS_SKILL_INTERVAL`（建议 3.0s）触发一次主题脉冲（调用 §五 对应机制的"脉冲变体"，从 Boss 位置扩环）。
- `ring_t += Game.FIXED_DT`：脉冲环半径/扩散计时（若脉冲采用扩张环）。
- `phase_t += Game.FIXED_DT`：阶段内累计，可用于行为梯度（如阶段越深脉冲越密）。
- `phase_dot_accum += Game.FIXED_DT`：主题 DoT 场的 FIXED_DT 驱动。
- **Boss 移动/冲刺**：随机方向 `dir` 由**既有 `Game.rng` 流**抽取（复用敌人 AI 现有 rng 调用方式），位移 `velocity`-based 以 FIXED_DT 步进，**禁 raw delta**；冲刺不新建第二条 rng。
- **阶段增援**：切换阶段时，用既有 `Game.rng` 流选取一支 `Data.SQUADS` 模板（复用 mender 治疗词缀、defuser 拆弹），经既有 squad 生成路径落地；Boss 不参与普通 SQUADS 抽取池。

## 七、rng / 指纹（坑 45 登记）
- 主题选取：`phase_theme_index(k)` 纯函数，**零 rng**（供 `SMOKE_BOSS` 确定性校验）。
- 阶段内随机（增援选取、冲刺方向）：**路由进既有 `Game.rng` 流**，保持绘制顺序一致，不新建 rng。
- **代价登记**：Boss 战对 `Game.rng` 的额外消费会改变绝对指纹 → 本批交付须在文档 §E1 重定节登记，并**随 B 重定冻结基线**（含 boss.gd 新文件后的 29/29 +1）。
- 探针 `SMOKE_BOSS`：表外、不进 E1 diff。

## 八、美术 / 音频（art / audio）
- **贴图（3 张，入 `generated/` 并 `--import`）**：`boss_prism_core.png` / `boss_prism_shard.png` / `boss_prism_death_shard.png`。
- **配色**：三枚绕转碎片颜色 = 对应阶段主题 `Data.theme_for_floor(floor_num).tint`（k=0/1/2 三阶段各取其一），**禁硬编码**；核心墨黑。
- **VFX**：生成 / 受击 / 技能 / 死亡复用 toxic_cloud puff + 现有粒子；形状不同才新增贴图。
- **音频**：`sfx("boss_intro")` / `sfx("boss_phase")` / `sfx("boss_skill")` 走既有 `sfx()` 注册表，不硬编码路径；音乐按当前阶段主题分层叠加（可开关，复用现有音乐系统）。

## 九、调试探针 `SMOKE_BOSS`（表外，不进 E1 diff）
- 打印首领层 `floor_num`、三阶段 `rule` 与 `tint`、各阶段切换触发的 HP 阈值。
- 主题选取确定性校验：同 `floor_num` 复跑两次，三阶段 `rule` 输出必须一致。
- 增援召唤记录：模板名 + 本次 `Game.rng` 消费计数（验证路由既有流、无新建 rng）。

## 十、验收四道门控（quality-lead）
1. **回归纪律**：`SMOKE+V8+REBIND+RELIC+SUFFIX+META+BOSS` 跑 3000 帧须 0 报错；冻结基线随 B 重定（含 boss.gd）。
2. **E6 合规**：grep 确认 `boss_cd_accum` / `ring_t` / `phase_t` / `phase_dot_accum` / Boss 冲刺位移全走 `Game.FIXED_DT`，无 raw delta 累加。
3. **E1 非污染**：主题选取纯函数零 rng（SMOKE_BOSS 校验）；阶段内随机路由既有 `Game.rng` 流（消费计数校验）；`SMOKE_BOSS` 表外不进 diff；Boss rng 消耗已登记 + 基线随本批重定。
4. **探针覆盖**：`SMOKE_BOSS` 必须覆盖阶段切换 + 主题确定性 + 增援路由三件事。

## 十一、落地注意事项（给编程侧一句话）
先 `--import` 新增 3 张贴图；E6 用 grep 自证；动 `Game.rng` 前想清是否漂移 E1 基线（Boss 战 rng 消耗须登记并随本批重定）；Boss 实体建议新建 `scripts/boss.gd`，**不污染既有 enemy 循环**、**不参与普通 SQUADS 抽取**；复用而非重写 F4 theme handler。

## 十二、主理人备注（不进转发文本）
- B 是 L 级，工程与评审成本最高，故放 Sprint 11 最后一批；状态机、主题复用、指纹约束已锁死，落地风险可控。
- 主题选取锁成 `phase_theme_index(k)` 纯函数后，Boss 在不同楼层呈现不同三阶段机制组合，天然扩展重玩性，且对 E1 零额外 rng 代价（仅阶段内召唤/冲刺走既有流）。
- 与 A/C 同批的 E1 基线重定需一次性合并：A 词缀掉落 + B Boss 战两条 rng 消费变更，统一重定 29/29（含 boss.gd）。
