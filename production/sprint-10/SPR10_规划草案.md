# Sprint 10 规划草案（SPR10-PLAN-01）

- **状态**：纯规划，未落地任何产品代码。本文件由 design-strategist 产出、主理人汇编，经用户批准落盘（2026-11-07）。
- **基线**：Sprint 9 已冻结（路线 A：E7/V16 整局确定性降级为已知限制），零产品代码改动、规格未动、基线全保留。冻结基线 `SPR7-FROZEN-4.md5`（29/29 OK）。规格 `Sprint7_解锁树规格.md` v2.10 冻结不可改。
- **范围**：F2 主动遗物 / F3 敌人编队 / F4 主题地形 / 分辨率选项。
- **首批落地决策**：分辨率选项（用户拍板——零 rng / 指纹纠缠，最稳，可独立先行）。

---

## 一、F2 主动遗物（规模 M，设计推荐首选）

概念：玩家持有可主动触发的遗物（区别于现有被动遗物），按键释放、带冷却。

四种候选：
1. 环绕护盾：释放后在身边生成持续 2.5s 的环盾，抵挡来袭弹/近身伤害；冷却 9s。
2. 冲刺闪避：朝当前准星方向瞬移一小段并获 0.4s 无敌帧；冷却 6s。
3. 齐射爆发：向八方向发射弹幕；冷却 12s。
4. 毒云/冻结弹：复用现有 toxic_cloud.gd 机制，释放一团区域控制。

接入路径：
- 新增独立 POOL（区别于被动遗物池）+ 对应 apply 分支 + validate.gd 校验（T4 契约键 / T6 注册一致性 / T9 池 id↔apply 分支，同 Sprint 8/9 守卫）。
- 新动作键进 assets.gd 动作总表（当前 318–332 行运行时注册 13 个动作，非 project.godot）。

前置硬门槛：
- assets.gd 输入表须先定稿（坑 5：先定稿才能加键，否则改键会牵一发动全身）。

rng 纪律：
- 主动遗物本身不进三抽卡入口（upgrades/relics/weapons）；释放判定若用随机须走 Game.rng（表现层走 fx_rng），不污染源玩法指纹。

---

## 二、F3 敌人编队（规模 M）

概念：把零散敌人按 squad 模板编组，提升战斗节奏与多样性。

四种模板：
1. 护盾+召唤：前排持盾吸引火力，后排周期召唤小怪。
2. 治疗+冲锋：治疗者续航，冲锋者贴脸压制。
3. 狙击+拆弹：远程狙击 + 拆弹单位限制玩家爆发。
4. 潮涌（虫潮）：大量低血虫群淹没走位。

接入路径：
- squad 模板集中入 data.gd 单表（与现有池表一致风格）；每房生成时从 squad 表取模板。

指纹隔离：
- 每房 squad 组合用表外探针打印，不写进 E1 指纹逻辑，守坑 45（全量 diff 假 FAIL，E1 须按楼层取交集）。

rng 纪律：
- squad 选取走 Game.rng 主流；不进三抽卡入口。

---

## 三、F4 主题地形（打磨，仅加 FLOOR_THEMES 字段）

概念：按楼层主题改变地形效果，仅新增 FLOOR_THEMES 字段，不重构地形系统。

四种主题：
1. 岩浆灼烧：站地面每 0.5s 掉 1 血；DoT 计时走固定步 time（守 E6）。
2. 冰面打滑：改动 player 物理参数（摩擦/加速度），L 规模。
3. 毒沼减速：区域 -30% 移速。
4. 藤蔓阻挡：扩展 prop，制造遮挡/阻挡，S 规模。

铁律：
- 全部守 E6 固定步长，不引入 raw delta；DoT/计时不得用每帧 raw delta 累加。

---

## 四、分辨率选项（打磨，首批落地）

概念：设置菜单增加分辨率 / 窗口模式 / UI 自适应。

三项：
1. 分辨率下拉：枚举常见分辨率，应用后重建视口。
2. 窗口模式：set_mode 切换 全屏 / 窗口 / 无边框。
3. UI 自适应：关键控件锚点化，避免不同分辨率下错位。

锚点纠正（重要）：
- 原 brief 写的 `settings.gd:696-703` 实际不存在。
- 设置读写真实位置在 `game_state.gd`（~236 读 / ~251 写），落盘 `user://settings.cfg`（ConfigFile）。
- 新增分辨率键须复用该 ConfigFile，不要新建 settings.gd 段或另起炉灶。

优势：
- 零 rng 纠缠、零 E1 指纹影响，可独立于玩法系统先行，是预算紧张下最稳的首批落地项。

---

## 五、关键裁定与落地顺序

- 若只做一件 → F2（玩法增益最大）。
- 备选 / 首批 → 分辨率选项（最稳）。
- F2 前置 = assets.gd 输入表先定稿（坑 5）。
- 建议落地顺序：分辨率选项先行（独立、低风险）→ 视预算再开 F4（小字段）→ F3（需守指纹隔离）→ F2（需输入表定稿，门槛最高）。

---

## 六、已知风险与护栏

- 坑 5：assets.gd 输入表未定稿前动 F2 加键会踩雷。
- 坑 45：squad 改动若污染 E1 指纹会导致全量 diff 假 FAIL。
- E6：F4 任何计时必须走固定步，禁止 raw delta。
- 锚点漂移：settings 真实在 game_state.gd，勿信旧 brief 的 settings.gd 行号。
- 通用：任何落地窗口须沿用专家团规矩——改前备份、先方案后落地、小步可回滚、写入前用户许可。

---

## 七、文档索引与交接

- 上游：`production/sprint-9/SPR9_汇编交付.md`、`production/sprint-9/SPR9_验证门控与已知限制.md`
- 本文件：`production/sprint-10/SPR10_规划草案.md`
- 下游：待用户批准实施后，按「分辨率选项先行」开 Sprint 10 实施窗口；实施前须先备份 + 方案待确认（沿用 Sprint 7–9 专家团规矩），不得直接在规划阶段改动代码。
- 同步说明：本规划为自包含文档，可直接转发给并行等待规划的另一路 AI；专家团规矩禁止成员间直连，故以文档交付而非直接投递。

## 八、实施状态（首批分辨率选项）
- **状态：已完成并经主理人交叉核验 PASS**（2026-11-07）。
- 交付文档：`production/sprint-10/SPR10_交付_分辨率选项.md`（与本草案对照验收）。
- 核验结论（主理人实际读码/读盘，非凭描述）：代码改动与交付 100% 吻合；锚点纠正落实（复用 `game_state.gd` 的 `user://settings.cfg` ConfigFile，scripts 目录未建 settings.gd）；备份链 `_backup/pre_res/` 真实存在；实时 `settings.cfg` 已恢复默认 1280x720 / window_mode=0（无 1600x900 残留），新键经 ConfigFile 正确落盘；headless guard（:592）确认存在，解释 29/29 自检不报错。
- 主理人未独立重跑的两项（os_size=(1600,900) 实测探针、29/29 组合回归）为实施侧自证，headless=dummy 无法复现 OS 窗口尺寸；如需独立复核可随时触发回归 harness。
- 后续批次仍按本草案第五节顺序：F4 主题地形 → F3 敌人编队 → F2 主动遗物。

- **争议定案（11-07 10:50，两棵 `_tools` 树）**：截图路径之争根因是**两棵同名 `_tools`**：`D:\Create\Game\_tools\`（项目外，编程侧证据树，含 `dungeon_shot_0.png`=1600x900 证据 + `upgrade_1/2.png`，绝对路径实查全部存在）与 `D:\Create\Game\test-1\_tools\shots_*\`（项目树内，另一会话的 22 帧系列 + `.import`，10 组，亦真实存在）。双方各执一词是**搜索根不同**：复核侧 find 根在项目树、编程侧 ls 根在项目外，各自树内结论都对，错在泛化为全局。本主理人 10:33/10:39 的复核及 10:39 的「反向勘误」同样属于范围歧义产物——**上一轮「我判断正确未被推翻」需撤销**，改为「两棵树各自正确」。交付文档 §二:24 与 §四（第三版中性勘误，含两树归属表 + 绝对路径规范）经主理人绝对路径复核全部成立，无需再改。结构性修复：`test-1/_tools/` 加 `.gdignore`（已实查，0 字节，2026-11-07 10:46）停止 Godot 导入，`.godot/imported` 已累计 342 条 dungeon_shot 缓存停止增长；新截图探针统一写项目外 `D:\Create\Game\_tools\`。前瞻规范：交付/交接文档引用证据一律写绝对路径。

## 九、第二批「F4 主题地形」完成 + 主理人核验（11-07 11:14）
- 编程侧交付 `SPR10_交付_F4主题地形.md`。主理人读码 + 读盘核验（非凭描述验收）：
  - `data.gd`：FLOOR_THEMES 扩为 8 主题（4–11，含 magma/ice/swamp/vines），`theme_for_floor` 按 `FLOOR_THEMES.size()` 取模（=8）；OBSTACLES 新增 `vine`(hp2/solid)。
  - `game_main.gd`：`_apply_floor_theme` 进房先复位 terrain 两系数、ice→accel 0.3、swamp→speed 0.7、楼层色调+横幅；`_tick_floor_theme` match 分发；`_spawn_props` spots 8→12 且藤蔓带 `idx % spots.size()` 防越界；`_dump_entities` 增强（props 按种类统计 + 每 1200 帧）。
  - `player.gd`：新增 `terrain_speed_mult` / `terrain_accel_mult`，移速(:232)与加减速(:234 move_toward)均接入。
  - `prop.gd`：vine 入 solid 集合，collision_layer=1 全向阻挡（与石柱同级，区别于桶/图腾的 64），贴图 `Assets.g("prop_vine")`，hp2 可打掉。
  - 贴图：`resources/texture/generated/prop_vine.png` 生成并导入（`.godot/imported` 有 2 条缓存）——新资源已 `--import`，隐形实体问题闭环。
  - **E6 合规**：magma DoT 走 `Game.FIXED_DT`(:631，=1/60 常量)，固定步、不随帧率/time_scale 漂移。
- 质量门判定：**PASS**（代码+贴图+导入+spots 扩界+系数接入 全绿；组合回归与 29/29 冻结为实施侧自证，headless=dummy 未独立重跑）。
- **规划侧裁定（毒巢 raw delta vs 岩浆固定步 口径差异）**：统一——将 `toxic` 分支 `_theme_t += delta`（:625）改为 `_theme_t += Game.FIXED_DT`，与 magma 同钟。理由：① 完全遵守 E6（禁 raw delta，两楼层 DoT 同口径）；② 稳态下 physics tick≈1/60，行为与现 toxic 一致、floor-5 平衡不变；③ 增益 time_scale/刷新率鲁棒性。唯一权衡：若设计有意让 DoT 在慢动作下同步变慢则 FIXED_DT 不随 time_scale——默认按 E6 统一，交由编程侧作小补丁落地并更新交付 §三。
- 后续批次：**F3 敌人编队（规划草案 §二 已就位，守 E1 指纹隔离）→ F2 主动遗物（输入表已定稿）**。F3 为下一批，编程侧可据 §二 开工；规划侧若对 squad 数据/隔离规格有创新补充，会先改 §二 再交付。

## 十、第三批「F3 敌人编队 + 毒巢口径统一」完成 + 主理人核验（11-07 续）
- 编程侧交付 `SPR10_交付_F3敌人编队.md`。主理人读码 + 读盘复验（非凭描述，锚点全部命中）：
  - `data.gd`：`SQUADS` 单表 4 模板齐全（shield_summon/min4/weight10、heal_charge/min5/weight10、sniper_defuser/min6/weight8、tide/min3/weight12），成员 id/词缀/数量/起始层合法；`mender` 词缀(heal2.0/range90/cd4.0/icon affix_mender) 就位；`defuser` 字段透传。
  - `slug.gd`：mender 治疗脉冲 `_heal_t += Game.FIXED_DT`（:201，E6 合规）到点 `_heal_allies(2.0,90.0)`（:204）；defuser 追弹 `_nearest_bomb(240.0)`（:206）18px 内 `bomb.defuse()`（:211）；`_nearest_bomb` 扫 `get_nodes_in_group("bombs")`（:233）。
  - `bomb.gd`：`_defused`（:10）、`add_to_group("bombs")`（:21）、`defuse()` 防重（:28-33）、`set_fuse(t)`（:41）、`_boom()` 防重护栏（:66-67）。
  - `game_main.gd`：`_roll_squad`（:734-777）gate=Game.rng.randf()（:737）、`forced=SMOKE_FORCE_SQUAD`（:739）、40% 门跳过逻辑（:740，FORCE 钉死时保持 rng 消耗）、eligible 按 min_floor 过滤、加权抽取、`[SMOKE-SQUAD]` 表外探针（:775，不入 E1 指纹，守坑 45）；`_spawn_batch`/`spawn_slug` 透传 defuser + SMOKDEFUSER_PROBE 种弹。
  - `validate.gd`：`_check_squads()`（:133）存在且被 `_validate_all` 调用（:49），守卫成员 id⊆ENEMIES/词缀⊆AFFIXES/数量·权重·起始层合法性。
  - **毒巢口径统一已落地**：`game_main.gd:628` `"toxic":` → `_theme_t += Game.FIXED_DT`，与 magma :633 同钟，E6 合规（数学验证 floor-5 探针 1500 帧=8 ticks=25s÷3s 精确吻合）。
- 质量门判定：**PASS**（代码侧 100% 吻合交付；组合回归与 29/29 冻结为实施侧自证，headless=dummy 未独立重跑）。
- 已知待办（探针小瑕疵，非阻塞）：SMOKDEFUSER_PROBE 第 3 颗哑弹落点未钳制场内，下批顺手钳制；E1 重定基线留待下一 QA 窗口（坑 45，编队走 Game.rng 主流致 spr8 基线指纹漂移，跨版本日志作废、`[SMOKE-SQUAD]` 表外不进 diff）。
- 后续批次：**仅剩 F2 主动遗物**（输入表已定稿✓、前置全清）→ 规划侧给最终口径（见 §十一），编程侧据以收尾 Sprint 10。

## 十一、第四批「F2 主动遗物」最终落地口径（规划侧，收尾 Sprint 10 用）
承接 §一 设计。以下为编程侧可直接落地的可执行规格（规划侧只读，不落产品代码）。

### 11.1 四遗物数值/冷却/效果（最终）
| 遗物 id | 名称 | 效果 | 持续 | 冷却 | 计时钟 |
|---|---|---|---|---|---|
| orb_shield | 环绕护盾 | 玩家周身生成半径 ~64px 环盾：摧毁触碰的敌方子弹、激活期间豁免敌人接触伤害 | 2.5s | 9s | Game.FIXED_DT（E6） |
| dash_dodge | 冲刺闪避 | 朝当前移动/准星方向瞬移 ~120px，获 0.4s 无敌帧（player.invuln 标记） | 0.4s（无敌） | 6s | Game.FIXED_DT |
| volley_burst | 齐射爆发 | 向八方向发射 8 发子弹（复用 player 子弹 prefab，伤害=当前武器基础、速度 ~400px/s） | 瞬发 | 12s | Game.FIXED_DT |
| toxic_freeze | 毒云冻结弹 | 朝准星落点释放 toxic_cloud（复用 toxic_cloud.gd）：半径 ~120px、持续 4s、范围内敌人减速 50% + 每 0.5s 微量 DoT | 4s | 10s | Game.FIXED_DT |

- 全部计时（冷却 + 持续 + DoT 周期）一律走 `Game.FIXED_DT` 累加，与 F4 岩浆/毒巢、F3 mender 同钟，禁 raw delta（E6 一致性）。
- rng 纪律：八方向为确定性方向，无需 rng；毒云落点若随机须走 Game.rng；不进 upgrades/relics/weapons 三抽卡入口。

### 11.2 接入键位（开工前先 grep assets.gd 318–332 确认无冲突）
- 新增 4 个动作进 assets.gd 运行时动作总表：`relic_shield` / `relic_dash` / `relic_volley` / `relic_toxic`。
- 建议物理键绑定（待 grep 确认未占用后定稿）：Q / E / R / F。
- 坑 5 护栏：必须先读 assets.gd 318–332 现有 13 动作键位，确认 Q/E/R/F 无占用再落键；若有冲突改用未占用键，并在交付文档登记实际绑定。

### 11.3 数据结构与代码接入（规划侧指定落点，编程侧实现）
- `data.gd`：新增 `const ACTIVE_RELICS := {...}` 单表（4 条，含 id/name/cd/duration/effect_kind/key_action），风格同 SQUADS。
- `assets.gd`：4 个新动作键进 318–332 动作总表（见 11.2）。
- `player.gd` 或 `game_main.gd`：新增主动遗物 apply 分支——输入回调 → 查 ACTIVE_RELICS → 查冷却 → 触发对应效果（环盾 Area2D / invuln 标记 / 八向发弹 / toxic_cloud 释放）→ 启动 FIXED_DT 计时。
- `validate.gd`：新增 `func _check_active_relics()`，守卫 T4 契约键存在、T6 动作注册一致（ACTIVE_RELICS 的 key_action ⊆ assets 动作表）、T9 池 id↔apply 分支映射；成员/效果参数合法性。

### 11.4 验收门（编程侧交付时须自证，主理人复核）
- 静态：`data.gd` ACTIVE_RELICS 4 条齐全；assets 4 动作键注册；validate._check_active_relics 存在且被调用；player 冷却/持续计时全走 FIXED_DT。
- 运行期探针（表外，不入 E1 指纹）：`SMOKE_RELIC_PROBE=<id>` 触发单次释放并打印（effect 生效 + 冷却置位 + 持续结束自动复位）；八向发弹数=8、毒云半径/持续吻合、环盾期间子弹被摧毁、无敌帧豁免接触伤害。
- 回滚：改前备份（沿用 `_backup/` 链），单遗物独立可回滚；不污染源玩法指纹（不进三抽卡）。

## 十二、第四批「F2 主动遗物」主理人核验 —— HOLD（2 阻断缺陷，待修复补验）
- 编程侧交付 `SPR10_交付_F2主动遗物.md` 并宣称 Sprint 10 四项全收官。主理人读码 + 读盘复验结论：**主体 PASS，但 2 处阻断级缺陷须修复并补验方可 final PASS；Sprint 10 收官暂缓**。
- **已核验绿项（非穷举）**：`ACTIVE_RELICS` 4 条数值/key_action 与 §11.1/§11.2 吻合；坑 5 护栏实锤（全仓 `KEY_F/Z/X/C` 仅 4 条 relic 定义占用，`KEY_F3` 为功能键无关）；环盾 64px 扫描 `enemy_bullets`+摧毁（player.gd:488-491）+ `take_damage_from` 早退豁免接触（:601）；齐射八向 8 弹复用 `spawn_player_bullet`（:444-451）；毒云 friendly 双模 `setup_friendly`/`_tick_friendly` 落位；`bullet.gd` 入 `enemy_bullets` 组（:54）；910 报错根因修复正确（`Game.main.clamp_to_arena` 确存 game_main.gd:1171）；`validate._check_active_relics` 守卫完整（T4 冷却>0 / T6 key_action 已注册 / T9 effect_kind∈{shield,dash,volley,toxic}）；冻结基线 29/29（`SPR7-FROZEN-4.md5` 计 29 行）。
- **阻断缺陷 D1（dash 位移缺失）**：`dash_dodge` 的 `_dash_dir`（player.gd:439 赋值）**全仓无任何消费位移的代码**；移动段（:237-248）`target_vel` 仅由 `input_vec`+`_knock` 构成，`_dash_t` 仅递减（:479）不驱动 velocity。该遗物当前只给 0.4s 无敌帧、**完全无冲刺位移**，违反 §11.1「朝准星瞬移 ~120px」。交付「moved≈120px」证据属探针等待期正常走位假阳性（探针未锁 `input_vec`）。**修复**：当 `_dash_t > 0` 时把 `_dash_dir` 注入 velocity（约 300px/s，0.4s≈120px），或激活时一次性 `global_position += _dash_dir * 120` 并经 `Game.main.clamp_to_arena`；**补验须锁 `input_vec=0` 后单独量冲刺位移**，排除正常走位干扰。
- **阻断缺陷 D2（E6 口径不符）**：friendly 毒云 `toxic_cloud.gd:41-42` 用 raw `delta` 累加 `_t`/`_tick_t`，驱动云生命周期（life=4s）与 DoT 周期（tick=0.5s），违反 §11.1「全部计时（持续+DoT 周期）一律走 `Game.FIXED_DT`」。敌方毒云为 Sprint 10 前既有代码（grandfather，本批未动）不强制改；F2 新增 friendly 云须合规。**修复**：:41-42 改为 `Game.FIXED_DT` 累加，与 F4 岩浆/毒巢、F3 mender、player 遗物计时同钟。
- 两项均为小范围、低风险修正（各 1–3 行 + 探针补验）。修复后由编程侧重跑探针复证、主理人复核 final PASS，Sprint 10 方算收官。
- 非阻塞遗留（同编程侧交付，下 QA 窗口）：拆弹探针哑弹落点钳制、环盾期 HUD 无冷却显示、E1 重定基线（坑 45）。

### 12.1 主理人复核 final PASS（11-07 13:21 续）
- D1/D2 经读码 + 读盘复验确认已正确修复：
  - **D1**：冲刺注入 `player.gd:248-249`（`_dash_t>0` 时 `velocity = _dash_dir*300`，不受输入影响）+ `:484-487` 按 `Game.FIXED_DT` 递减 `_dash_t`、到期 `velocity = Vector2.ZERO` 硬停（消除滑步过冲）。逐帧 trace（`SMOKE_DASH_TRACE` 钩 :250-252 真实打印 pos/vel）定案：24 ticks × 5px = 120px 直驱精确，速度恒 300 模长；实测 196-210px 超出部分为冲入虫群后 `move_and_slide` depenetration 挤出，**非走位、非代码缺陷**。
  - **D2**：`toxic_cloud.gd:42` 按 side 分流 `step := Game.FIXED_DT if friendly else delta`——friendly 云生命周期/DoT 周期走固定步（与 F4 岩浆/F3 mender/player 遗物同钟），enemy 云维持 raw delta（grandfather，行为冻结）；friendly tick 门控打印（:55-56）按 0.5s 固定周期出现。
  - 探针锁输入补验（`_relic_probe` :534-535 `control_locked=true` 测量期）证实位移零走位成分；四遗物数值/坑5/环盾/齐射/毒云双模/910修复/validate/冻结29/29 全绿。
- **裁定：F2 转 PASS，Sprint 10 四项（分辨率 / F4 / F3 / F2）全部收官。**
- 非阻塞设计备注：dash 实测位移 196-210px（120 直驱 + 碰撞挤出）。若规划侧后续要求严格 ~120px 无视碰撞（纯传送语义），可走 option b 传送式落位；当前实现（速度冲刺 + 硬停 + 碰撞挤出）符合「~120px 间隙位移 + 无敌帧」意图，**不阻塞**。
