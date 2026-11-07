# Sprint 12 主理人读码核验报告（两阶段全量）

> 日期：2026-11-07｜核验侧：主理人（规划/QA，**不写实现代码**）｜对象：`d2807b8` 阶段一 + `d70b6c5` 阶段二
> 方法：实读源码交叉核验 + `md5sum -c` 实校冻结清单；不采信交付文档的自述结论。
> **判定：CONCERNS（不予 final PASS）** —— 修复批完成后重验。E6 / E1 / 冻结基线 / 数据表 / 接入链均通过，但存在 1 处付费内容零实现与 2 处运行时真缺陷。

---

## 一、结论速览

| 门控 | 判定 | 说明 |
|---|---|---|
| 冻结基线 | ✅ PASS | `md5sum -c` 实跑 **32/32 全 OK**，清单 32 条均为 `.gd`（0 条 `.uid`） |
| E6 固定步 | ✅ PASS | 新增计时全 `Game.FIXED_DT`，零 raw delta |
| E1 非污染 | ✅ PASS | 注入/种子/指纹时序正确（详见 §三） |
| 数据表与接入链 | ✅ PASS | SIGILS 3→9、SQUADS 4→7、echo AI、菜单/结算闭环 |
| **功能完整性** | 🔴 **FAIL** | **bulwark 印记零效果**（缺注入分支） |
| **运行时正确性** | 🟠 **CONCERNS** | 换层清灾祸抹掉整局掉率倍率；frail 回退层内生命上限成长 |
| 验证口径 | 🟠 CONCERNS | 任意 SMOKE 模式隐式强制灾祸 |

按批次流程「实施 → 三层验证 → 冻结重定 → 交付文档 → 单独提交」，本批**停在核验门**，需一修复批后再收官。

---

## 二、缺陷清单（按严重度，可直接转编程侧）

| # | 严重度 | 位置 | 问题 |
|---|---|---|---|
| 1 | 🔴 高 | `game_main.gd:722–750` | bulwark 印记完全不生效 |
| 2 | 🔴 中高 | `game_main.gd:423` | 换层清灾祸抹掉整局 `diamond_mult` |
| 3 | 🟠 中 | `game_main.gd:401 / 418` | frail 绝对值还原回退层内 max_hp 成长 |
| 4 | 🟠 中 | `game_main.gd:376` | 任意 SMOKE 模式隐式强制灾祸 |
| 5 | 🟡 低 | `boss2.gd:10–24` | 熔潮主宰身份未区分（名字/variant 残留） |
| 6 | 🟡 低 | `game_state.gd:295–296` | 每日 seed 依赖 `hash()`，跨版本稳定性待复核 |
| 7 | 🟡 文档 | 交付文档 §验证 / 草案 §6.1 | 两处口径瑕疵（详见 §四） |

### 1. 🔴 bulwark 印记零效果（交付声明与实现不符）
- **证据**：`data.gd:219` 定义 `bulwark`（cost 35，「开局获得 1 层环盾护盾 2.5 秒」）；但 `_apply_sigil_contract` 的 match 仅 8 分支（vigor / arsenal / purse / kindred / sprinter / harvester / ward / scholar），**无 bulwark**。全 `scripts/` grep `bulwark|relic_shield_t`：`relic_shield_t` 的置位只在 `player.gd:472`（主动遗物 `_activate_relic("orb_shield")`），与印记无关。
- **影响**：玩家花 35 地窖碎片解锁并装备后，开局毫无效果；交付文档 §A 第 9 行声称已实现「`relic_shield_t` 置初值」，实测未接。阶段一实战只验了 `kindred`，未覆盖 bulwark，故 0 报错不能证明其生效。
- **修复方向**：在 match 增 `"bulwark":` 分支，置 `player.relic_shield_t = 2.5`（建议读 `Data.ACTIVE_RELICS["orb_shield"]["duration"]` 免硬编码）。**无需手动建 orbit** —— `player.gd:534–536` 的 `_tick_relic_shield()` 在 orbit 为空时会自动 `_ensure_relic_shield()`。
- **验收断言**：扩 `SMOKE_SIGIL` 表外探针，装备 bulwark 开局打印 `relic_shield_t>0` 且 2.5s 后归零；9 枚印记逐个做「装备→开局状态变化」的覆盖检查（本次漏项的根因是覆盖率，不是逻辑）。

### 2. 🔴 换层清灾祸抹掉整局掉率倍率
- **证据**：`_roll_modifier()`（`game_main.gd:429–449`）**整局仅 start_run 调一次**，按挑战因子设 `diamond_mult` = 0.7（barren）/ 1.5（swarm），`:692` 还有升级 `maxf(diamond_mult, 1.5)`。而 `_clear_calamity_effects()` `:423` **无条件** `Game.main.diamond_mult = 1.0`，`next_floor()` `:1248` 每层必调。
- **影响**：从第 2 层起，挑战因子与升级带来的源石倍率被永久重置为 1.0，且不可恢复（modifier 不会重掷）。量化：swarm 局第 2 层起掉率 **1.5 → 1.0（-33%）**。交付踩坑 #3 只修了 `Game.X` / `Game.main.X` 作用域，未修这个覆盖。
- **修复方向**：`scarce_ore` 不要覆写 `diamond_mult` 本体 —— 改用独立 `calamity_ore_mult`（默认 1.0，与 `diamond_mult` 相乘结算），或在 apply 前保存旧值、clear 时精确还原。
- **验收断言**：swarm/barren 局跨 3 层连续打印 `diamond_mult`，断言恒定；`scarce_ore` 灾祸层单独断言倍率叠加正确、换层后恢复。

### 3. 🟠 frail 绝对值还原回退层内 max_hp 成长
- **证据**：`_apply_calamity()` `:401` 保存 `_calamity_saved_max_hp = player.max_hp`、`:402` 降至 80%；`_clear_calamity_effects()` `:418` 换层 `player.max_hp = _calamity_saved_max_hp`（绝对赋值）。而层内存在真实增长点：`upgrades.gd:121`、`relics.gd:92` 均 `player.max_hp += 1`。
- **影响**：灾祸层内升级或拿到 +生命上限遗物后，换层会把该成长回退。交付文档称「保存值精确还原」，但精确的是进入层时的快照，不是层内终值。
- **修复方向**：改为差值增量还原（只补回灾祸扣掉的那部分），而非绝对赋值；同时保留 `player.hp = mini(player.hp, player.max_hp)`。
- **验收断言**：frail 层内 +1 max_hp → 换层后断言仍保留该 +1。

### 4. 🟠 任意 SMOKE 模式隐式强制灾祸
- **证据**：`_roll_calamity()` `:376` `if not _smoke and not _calamity_forced and rolled > 0.15: return` —— 当 `_smoke=true`（**任何** SMOKE 探针）即跳过概率门，第 2 层起必触发灾祸。
- **影响**：所有历史 SMOKE 回归（BOSS / SQUAD / META / DAILY …）都在灾祸状态下运行（敌速 +25% / 弹匣减半 / 掉率变动），回归可比性受损；额外的 `randi_range` 消费让战斗内随机序列分叉。交付「八探针 4000 帧 0 报错」成立，但**不等于基线等价**。
- **✅ 值得保留的正确设计**：`_smoke_fingerprint()` 在 `_roll_calamity()` **之前**调用（`:347` / `:1254`），地图 E1 指纹未受污染。修 #4 时**不要改动这个调用顺序**。
- **修复方向**：强制条件收敛为 `SMOKE_CALAMITY` 环境变量 / `_calamity_forced`；其余 SMOKE 走正常 15% 概率，保持历史基线可比。

### 5. 🟡 熔潮主宰身份残留
- **证据**：`boss2.gd` 覆写 `setup()` 但未覆写继承的 `boss_name`（`boss.gd:17` = 「棱镜守望者」）与 `variant`（`:27` = `"warden"`）；`game_main.gd:261 / :274` 的 SMOKE-E DUMP 按 `e.variant` 打印，会把熔潮主宰输出成 warden。
- **影响**：表现层/探针身份混淆，非玩法阻塞。规格 §6.1③ 只要求 tint 区分，tint 已正确数据驱动（`boss2.gd:23, 29`）。
- **修复方向**：`setup()` 内覆写 `boss_name = "熔潮主宰"`、`variant = "sovereign"`；改前确认无结算/成就路径按 `variant == "warden"` 判定（当前 grep 仅 DUMP 打印使用）。

### 6. 🟡 每日 seed 的 `hash()` 稳定性待复核
- **证据**：`game_state.gd:295–296` `daily_seed_for(key) = absi(int(hash(key))) % 2147483647`。交付「双 run 同 seed 打印一致」若为**同一进程内**两次 `start_run`，无法排除跨进程/跨引擎版本差异；`hash()` 一般不承诺跨版本稳定。
- **影响**：若引擎升级或跨进程不稳定，「同一天同一局」的每日挑战前提失效。
- **修复方向**：跨进程各跑一次 `SMOKE_DAILY` 比对输出；或改为显式按日期字符逐位累加的纯函数派生（不依赖引擎 hash 实现）。

### 7. 🟡 文档口径两处瑕疵
- **交付文档 §验证**：「32/32 OK（30 脚本 + boss2/ally .uid 计入）」—— 实测清单 **32 条全为 `.gd`、0 条 `.uid`**，项目现有 32 个 `.gd`，一一对应。括注请同步。
- **规划草案 §6.1**：「每 16 层一次，与守望者每 8 层错开，互不冲突」为**数学错误** —— 若 `(n-4)%16==15`，则 `(n-4)%8 = 15%8 = 7`，**必然同时命中 `_is_warden_floor`**，sovereign 层是 warden 层的子集（19 / 35 / 51…），并非错开。编程侧用 `sovereign` 优先分支（`game_main.gd:1056–1067`）正确兜住，实际效果为「每 16 层把其中一次守望者战替换为熔潮主宰」，**实现无误，仅草案措辞已由主理人修正**。

---

## 三、核验通过项（PASS，实读实校）

- **冻结基线**：`md5sum -c production/sprint-7/SPR7-FROZEN-4.md5` 实跑 32/32 全 OK，与当前 32 个脚本一致，无未登记改动。
- **E6**：`ally.gd` 生命周期/命中冷却全 `FIXED_DT`；`slug.gd:284` `_ai_echo` 走 `FIXED_DT`；`player.gd:246–251` 轨迹 0.1s 采样 `FIXED_DT`；`boss2.gd` 继承 `boss.gd:104–106` 全固定步；灾祸效果为换层清除、无计时。新增计时零 raw delta。
- **E1 时序**：契约注入 `game_main.gd:340` 早于 rng 首抽 `:343`；`kindred` 零 rng（`clamp_to_arena :1344–1347` 为纯常量边界，不依赖尚未生成的 dungeon，疑点排除）；daily seed `:335` 同样早于 `:343`；`_smoke_fingerprint` 早于 `_roll_calamity`；编队/Boss 随机路由既有 `Game.rng` 流，无新建 rng。
- **数据表与实体**：SQUADS 4→7（hunt / alchemy / echo_pack，schema 一致）；SIGILS 3→9；`validate.gd:5` `KNOWN_AI += "echo"`；回响镜像→突进→击败 `echo_rate` buff（`:1681–1684`）链路闭合；零新美术（复用 shadow 贴图）。
- **A 其余 5 枚均落地**：sprinter `:477`、harvester `:1678`、ward `player.gd:749–751`（仅 Boss 房）、scholar `:959`（`_scholar_floor_done` 每层首次门控）、kindred `ally.gd`。
- **C/D**：`_is_sovereign_floor` `:939–940` 公式与规格一致、sovereign 优先分支正确；`boss2.gd` 继承而非复制，主题偏移 +4、脉冲 2.2s、tint 数据驱动；每日菜单入口 `menu.gd:137–139` + 结算钩 `:2032` + 本地榜闭环。
- **F 未接**：`assets.gd` 输入表未动，坑 5 纪律守住。

---

## 四、修复批建议（编程侧）

1. 先修 **#1 / #2 / #3**（功能与经济正确性），再修 **#4 / #5**（验证口径与表现层），#6 做跨进程复核，#7 同步文档措辞。
2. 补覆盖率：**9 枚印记逐枚**做「装备→开局状态变化」断言（本次漏项根因是只测了 kindred）；灾祸与 modifier 组合做跨 3 层倍率恒定断言。
3. 修完重跑四门控 + 冻结重定（改了脚本必然重定），修 #4 时**保持 `_smoke_fingerprint` 在 `_roll_calamity` 之前**的时序。
4. 交付文档 `SPR12_交付_两阶段全量.md` 当前为**未跟踪状态**（`git status ??`），与修复批一并单独提交；底账 `706a8c3` 已在，之后每批一个 commit。
5. 主理人侧在修复批落地后再做一次读码复核，届时给 final PASS / CONCERNS 判定。
