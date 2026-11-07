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

---

# 附：修复批 `266651a` 主理人复核（2026-11-07 19:50）

> 复核对象：编程侧修复批提交 `266651a`（声称 7 项全闭环 + 逐枚覆盖断言 + 十探针 0 报错 + 冻结 32/32）。
> 方法：实读修复后源码 + `git show --stat` + `md5sum -c` 实校；**不采信交付文档自述结论**。
> **判定：CONCERNS（不予 final PASS、不予收官）** —— 7 项中 **#1 / #4 / #5 / #6 闭环，#7 部分**；**#2 仍为 🔴 必现缺陷、#3 语义不成立**。

## A. 逐项复核

| # | 编程侧声明 | 主理人判定 | 依据 |
|---|---|---|---|
| 1 | bulwark 补分支 | ✅ **PASS** | `game_main.gd:761–763` `relic_shield_t = maxf(cur, 2.5)`；覆盖探针 `player.gd:689–690` 断言 `>=2.5`；`_tick_relic_shield()`（`:534–536`）在 orbit 空时自动 `_ensure_relic_shield()`，无需手动建 |
| 2 | 保存值还原倍率 | 🔴 **未闭环（原缺陷仍在）** | 见 §B |
| 3 | `maxi` 保层内成长 | 🟠 **语义不成立** | 见 §C |
| 4 | 摘除 `_smoke` 强制 | ✅ **PASS** | `:380` 改 `if not _calamity_forced and rolled > 0.15: return`；`:186–187` 仅显式 `SMOKE_CALAMITY` 才置 `_calamity_forced`；`:389` 仅打印。**序保住**：`_smoke_fingerprint`（`:349` / `:1267`）仍在 `_roll_calamity`（`:353` / `:1269`）之前 |
| 5 | boss2 身份补齐 | ✅ **PASS（并附带修好隐藏缺陷）** | `boss2.gd:12–13` 设 `boss_name` + `variant="boss"`；`boss.gd:335` 死亡走 `on_slug_killed(self)` → `game_main.gd:1701 variant in ["elite","boss"]` → Boss 必掉词缀。原 `variant="warden"` 只享 6% 普通掉率，改 `"boss"` 使掉落归位，理由成立 |
| 6 | `stable_hash()` FNV-1a | ✅ **达标，建议规范化** | `game_state.gd:296–300` + `daily_seed_for :304` 已切换，跨版本确定性达成。但每步未 mask 32 位，Godot int64 下 8 字符会溢出 wrap → 非标准 FNV-1a，跨语言复现 seed 不一致。建议 `h = ((h ^ b) * 16777619) & 0xFFFFFFFF` |
| 7 | 文档两处口径 | 🟡 **部分** | 交付文档 `:47` 原文仍为「30 脚本 + boss2/ally .uid 计入」（实测 0 条 `.uid`），仅 `:78` 追加勘误；`## 还剩什么` 仍写「git 提交待授权」，与已提交 `266651a` 矛盾。草案 §6.1 规划侧已自纠 ✓ |

**其它实校**：`git status` 干净、`266651a` 在册；`md5sum -c` 实跑 **32/32 全 OK**，清单 32 条全 `.gd`、脚本 32 个；该提交已含主理人核验报告与草案修订（工作树无遗留）。
**十探针 0 报错与本次判定不矛盾**：#2 / #3 是语义缺陷，现有断言未覆盖，不会触发 `[ERR]`。

## B. 🔴 #2 原缺陷仍在（换了个初值为 1.0 的常量）

`_clear_calamity_effects()` `game_main.gd:426–436` 中 `:433` **无条件** `Game.main.diamond_mult = _calamity_saved_diamond_mult`。而：
- `_calamity_saved_diamond_mult` 初值 `:113 = 1.0`，**只在** `_apply_calamity :405` 更新；
- 第 1 层保底无灾祸（`:382–383` 在 apply 之前 return）→ 开局 saved 恒为 1.0；
- `next_floor :1261` **每层无条件**调 clear；
- `_roll_modifier :443–449` 整局只在 `start_run` 设一次 `diamond_mult`（swarm=1.5 / barren=0.7）。

**必现推演（swarm 局）**：第 1 层 1.5 且 saved=1.0 → 进入第 2 层 clear → `diamond_mult = 1.0` → **1.5 永久丢失**。与原报告 #2 完全同构，仅把字面 `1.0` 换成了初值同为 `1.0` 的变量。另 `:436` 只重置 `_calamity_saved_max_hp`，不重置两个 saved 倍率 → 历史值还会跨层串味。

**修复方向**：clear 时**按灾祸类型条件还原** —— `diamond_mult` 仅在 `_calamity == "scarce_ore"` 分支还原，`mag_cap_mult` 仅在 `"scarce_ammo"` 分支还原，`frail` 单独处理；`_calamity == ""`（无灾祸层）**不触碰任何倍率**。或引入 dirty 标志，clear 只还原本层实际改过的项。

## C. 🟠 #3 `maxi` 不等于「保成长」+ 单测时序反了

`maxi(player.max_hp, saved)`（`:428`）语义是「至少回到灾祸前」，**不是**「补回灾祸削减量」。

| 步骤 | saved=10 的实际值 |
|---|---|
| 进入灾祸层 | saved=10，`cut=round(10×0.2)=2` → `max_hp=8` |
| 层内升级 +1（`upgrades.gd:121` / `relics.gd:92`） | `max_hp=9` |
| 换层 clear `maxi(9, 10)` | **10**（正确应为 **11**，丢 +1） |

**为何单测全过**：`player.gd:708` 把「模拟层内成长」写在 `_apply_calamity()`（`:710`）**之前**，导致 saved 已含成长（=hp_before+1），`:713` 的断言恒过。真实时序是「先灾祸 → 后成长 → 再 clear」，单测把顺序倒过来，恰好绕开缺陷。

**修复方向**：改**差值增量还原** —— `_apply_calamity` 额外保存 `cut`，clear 时 `player.max_hp += cut`（或 `+= saved - reduced`），与层内成长完全解耦。

## D. 单测口径修正要求（根因）

本次 7 项里有 2 项「断言全绿但缺陷仍在」，根因是覆盖探针只验了「成对 apply→clear」的直驱路径，未验真实层流程。下一批必须补：
1. 把「模拟层内成长」移到 `_apply_calamity()` **之后**再断言还原；
2. 补「**无灾祸层也调 clear，不得改动 `diamond_mult` / `mag_cap_mult`**」断言；
3. 补「**swarm 局跨 3 层 `diamond_mult` 恒为 1.5**」的层流程断言（真正覆盖 #2 的必现场景）；
4. #6 加 mask；#7 直接改 `:47` 原文与「还剩什么」状态行，不用追加勘误。

## E. 收尾状态

- **冻结清单 / git / E6 / E1 / 数据表 / 探针框架**：全部 PASS，无需重做。
- **待修**：#2（🔴）、#3（🟠）+ 四条断言口径；#6 规范化、#7 原文修正为低优先。
- 修完再走：四门控 → 冻结重定 → 交付文档 → 单独提交 → 主理人复核给 final PASS。
- 主理人本轮**未改任何 `.gd`**（规划侧只读铁律），仅追加本复核章节。
