# Sprint 13 阶段一 主理人读码核验报告

> 日期：2026-11-07 21:50｜对象：编程侧阶段一提交 `bf2010b`（A 抉择圣所 + E 打磨批）
> 方法：实读修复后源码 + `git diff/show` + `md5sum -c` 实校；**不采信交付文档自述结论**。主理人侧不写 `.gd`。
> 基线：Sprint 12 已收官（九提交）；本批 `bf2010b` 后工作树干净、冻结 **33/33 OK**（+`shrine_panel.gd`）、脚本 33 个。
> **判定：CONCERNS（不予阶段一 PASS）** —— A/E 主体规格与四门控扎实落地，但有 **1 处必现语义反转（🔴）+ 1 处面板暂停冲突（🟠）**，另有 3 条低优先观察。

---

## 一、结论速览

| 门控 | 判定 | 说明 |
|---|---|---|
| 冻结 / git | ✅ PASS | `md5sum -c` 33/33 全 OK；工作树干净；十提交在册；新增 `shrine_panel.gd` 已入清单 |
| A 数据表 / 房型 / 生成 | ✅ PASS | 见 §四，全部符合草案 §4.1–4.4 |
| E1 非污染 | ✅ PASS | 三卡 `stable_hash` 零 `Game.rng`；`ACTION_DEFS` 零新增；validate 抽查用本地固定 rng |
| E6 / E 打磨批 | ✅ PASS | 新面板无计时；ECHO_TUNING / `_fs` / 背景板 / SFX 别名全部实装 |
| **功能正确性** | 🔴 **FAIL** | `purify` 把灾祸 debuff **永久固化**（§二 #1） |
| **交互正确性** | 🟠 **CONCERNS** | `ore_upgrade` 后升级面板失去暂停（§二 #2） |

---

## 二、缺陷清单（可直接转编程侧）

### 1. 🔴 `purify` 语义反转：净化反而把灾祸 debuff 永久固化

**位置**：`game_main.gd:1976–1980`
```
"purify":
    Game.calamity_floors.erase(Game.floor_num)
    _calamity = ""            # ← 先清空
    _clear_calamity_effects() # ← 再按 _calamity 条件还原
```

**根因**：Sprint 12 二轮整改后 `_clear_calamity_effects()` 是 **`match _calamity` 条件还原**（`game_main.gd:427–440`）：只有 `frail` / `scarce_ammo` / `scarce_ore` 分支各自还原对应项，**`_calamity == ""` 无分支、完全不碰倍率与 max_hp**。purify 先把 id 清空 → clear 走空分支 → 三项全不还原；而 clear 末尾 `:441–443` 又把 `_calamity_frail_cut` 与两个 saved 值**无条件清零**，连之后换层再还原的信息也一并丢失。

| 本层灾祸 | 选「净化」后的实际结果 | 应有结果 |
|---|---|---|
| `frail` | `max_hp` 永久少 1–2 点（无分支补回，cut 被清零） | 补回实际削减量 |
| `scarce_ammo` | `mag_cap_mult = 0.5` **永久弹匣减半** | 还原 saved |
| `scarce_ore` | `diamond_mult = 0.7` **永久掉率 -30%** | 还原 saved |
| `frenzy` | `calamity_speed_mult` 恢复 ✓（`:431` 无条件） | 恢复 ✓ |

同时 `calamity_floors.erase(本层)` 让玩家失去整局 `shards ×1.5` 补偿（`settle_shards` 判的是 `calamity_floors.size() > 0`）——**代价付了、debuff 没解除、补偿也没了**，与该选项「解除本层灾祸」的语义完全相反。

**附带口径问题**：`settle_shards`（`game_state.gd:269`）的 ×1.5 是**整局一次**判定，不是按层累加。若本局之前已有灾祸层，erase 当层后 `size()` 仍 > 0 → ×1.5 依旧生效，desc 里「本层 ×1.5 结算加成作废」并不成立。建议 desc 改为「本层灾祸记录清除」或改结算为按层累计。

**修复方向（一行顺序调整）**：先按原 id 还原、再清空状态——
```
Game.calamity_floors.erase(Game.floor_num)
_clear_calamity_effects()   # 此时 _calamity 仍是原灾祸 id，条件还原能命中
_calamity = ""
```
**必补断言**（`SMOKE_SHRINE`，四种灾祸各跑一遍）：选 purify 后断言 `max_hp == 进层值` / `mag_cap_mult == 1.0` / `diamond_mult == 进层值` / `calamity_speed_mult == 1.0`，并断言换层后不复现。

### 2. 🟠 `ore_upgrade` 打开升级面板后被解除暂停

**位置**：`shrine_panel.gd:171–177` 与 `upgrade_panel.gd:162–163`
- `upgrade_panel.show_choices()` `:163` 设 `get_tree().paused = true`（三选一面板依赖暂停）。
- `shrine_panel._pick()` 的顺序是 `_root.visible=false` → `chosen.emit(i)` → `get_tree().paused = false`。
- `chosen` → `_on_shrine_chosen` → `_shrine_execute("ore_upgrade")` → `upgrade_panel.show_choices(Upgrades.roll(3))` 设 `paused=true`；返回后 `_pick` 的 `:177` **又把它设回 false**。

**影响**：选「源石淬炼」后升级三选一面板虽显示，但游戏未暂停 —— 玩家可移动/射击、敌人照常行动、楼层 DoT 继续结算；面板关闭时 `upgrade_panel._pick:276` 再设一次 false（无害）。属交互破坏，非崩溃。

**修复方向**：`_pick()` 把 `get_tree().paused = false` 移到 `chosen.emit(i)` **之前**（先关面板并解除暂停，再让主侧弹升级面板由其自行设 paused）。改后需回归「源石淬炼 → 升级面板 → 选卡 → 关闭」全链，断言面板期间 `get_tree().paused == true`。

---

## 三、低优先观察（不阻塞，建议顺手清）

| # | 观察 | 说明 |
|---|---|---|
| 3 | 空池护栏的不完整态 | `_shrine_offers_for` 返回 `[]` 时（`:1929–1930`），`_open_shrine` 仍播 `sfx("shrine")` + 点 `first_shrine` 里程碑（`:1958–1959`），但 `shrine_panel.open([])` 早退、不写 `cleared` → 该房永远「有横幅无面板」。正常流程因 `floor>=3` 且池 ≥4 不触发，仅探针边界 |
| 4 | 扣源石影响共鸣计数 | `Game.add_diamonds(-8)`（`:1989`）内部 `_reso_pickups += n`（`game_state.gd:149`），持有 `mx_resocore` 时共鸣计数会倒扣。建议代价走独立的余额扣减而非 `add_diamonds` |
| 5 | `_calamity` 跨层残留的脆弱点 | `next_floor` 顺序是 `_clear_calamity_effects()` → `_enter_room()` → `_roll_calamity()`（`:1261/:1268/:1269`），而 `start_run` 是 roll 在 enter 之前（`:353/:367`）。换层瞬间 `_calamity` 仍是上一层 id，故 `_shrine_offers_for` 的 `purify` 过滤（`:1926`）基于可能过期的状态。因圣所从不分配在起始房（`dungeon.gd:140` 排除 `Vector2i.ZERO`），正常流程不触发；建议 `next_floor` 的 clear 之后显式 `_calamity = ""` 以消除时序不对称 |

---

## 四、核验通过项（PASS，逐条实读依据）

- **A 数据表**：`ROOM_META` +`shrine`（`data.gd:307`，mark "+"）、`MILESTONES` +`first_shrine`（`:291`）、`SHRINE_OFFERS` 6 条（`:313–320`，cost_kind/min_floor 齐）、`ECHO_TUNING` 7 常量（`:325–326`）。
- **A 生成**：`dungeon.gd:137–146` `floor>=3` 从非死端 combat 房按坐标排序取首改 kind，**只改 kind 不动坐标/总数、零 rng**；`dungeon.gd` 全局只使用传入的 `rng`（grep 无 `Game.rng`），故 `validate._check_shrine`（`:204–207` 本地固定 `seed=20261107` 的 5 层抽样）**零 E1 影响** ✓。
- **A 挂接**：`_enter_room` 已清组加 `shrine`（`:1062`，门不锁）+ loot 分支（`:1137–1142`）；**防重入成立**——`_on_shrine_chosen` 写 `info["cleared"]=true`（`:2014`），重进时 `:1070–1072` 会置 `info["skip_loot"]=true` 使 loot 分支跳过（此点我特意回读确认，非缺陷）。
- **坑 5 / E1**：`shrine_panel.gd:165` 复用已注册 `card_1/2/3`，`assets.gd ACTION_DEFS` 零 diff；三卡由 `stable_hash("%d_%d_%d" % [run_seed, floor, coord])` 派生（`:1931–1939`，线性探查去重），铭刻同源派生（`:1999–2004`），**选项集零 `Game.rng`**；`Relics.roll` / `Upgrades.roll` 属玩家驱动的既有路径，交付文档已登记 ✓。
- **代价与置灰**：`_shrine_affordable`（`:1944–1952`）覆盖 diamonds/max_hp/score 且 `max_hp` 保底 1；`shrine_panel._set_state`（`:153–158`）+ `_on_shrine_chosen:2011` 双保险；`_shrine_execute` 结构完整（上次截断已修复，代价 match 在正确作用域内）。
- **E 打磨批**：`slug.gd:287–299` 实读 `Data.ECHO_TUNING`；`hud.gd:70 _fs()` + 25 处折算 + `ui_font` 档（`game_state.gd` settings + `menu.gd:307`）；`menu.gd:36–43` 地窖背景板（MOUSE_FILTER_IGNORE）；`assets.gd` SFX 别名 +`shrine`/`calamity`；FLOOR_THEMES mark 色盲标记 ✓。
- **E6 / 冻结 / git**：`shrine_panel.gd` 无 `_process`、无 raw delta；`md5sum -c` 33/33 全 OK；`git status` 干净；交付文档 `SPR13_交付_阶段一.md` 与草案均已随 `bf2010b` 入库。

---

## 五、断言覆盖根因（第四次同构）

交付文档称「六效果代价逐条」全过，但 #1 未被抓到 —— 说明 purify 的断言只验了 `calamity_floors.erase` / `_calamity == ""` 这类**状态标志**，没验**被灾祸改动的数值是否还原**。这与 Sprint 12 前两轮「9 断言全绿却漏缺陷」同构：只验直驱路径的中间状态，不验跨函数的最终效果。

**下批必补**：把 §二 #1 的四灾祸还原断言、#2 的暂停断言纳入 `SMOKE_SHRINE`，沿用「断言 + [ERR] + done 落地」门控范式（本批已证明它能当场拦下 offer 缺 id、size 断言污染、函数截断三类问题）。

---

## 六、收尾状态

- **功能门 CONCERNS**，阶段一不予 PASS；修 #1 / #2 + 补断言后再走四门控 → 冻结重定 → 交付文档 → 单独提交 → 主理人复核。
- 阶段二（C 地窖图鉴）与阶段一**零耦合**，若编程侧愿意可并行开工，但**建议 #1 先修**（purify 与 C 的 `mark_codex` 记录点会共用 `_apply_floor_theme` / 灾祸路径）。
- 主理人本轮**未改任何 `.gd`**，仅新建本核验报告 + 更新工作日志与长期记忆。

---

## 附：修复批 `89edfc8` 复核终审（2026-11-07，阶段一 **PASS**）

> 复核对象：`89edfc8`（代码 + 交付文档 + 冻结清单，6 文件）／`2c84a24`（本核验报告入库）。
> 方法：逐行实读落点 + git 历史对照 + 冻结 `md5sum -c` + 断言有效性反查；**不采信交付文档自述**。
> 主理人本轮**未改任何 `.gd`**。

### 一、结论

**功能门 PASS → Sprint 13 阶段一（A 抉择圣所 + E 打磨批）正式收官。**
#1–#5 全部真闭环；编程侧自查新发现的 `frenzy` 跨层固化一并修复且修复到位；四门控复核通过；三条非阻塞前瞻登记在册（§六）。阶段二 C 与本批零耦合，**准予开工**。

### 二、五项修复逐条实读判定

| # | 落点 | 实读结果 | 判定 |
|---|---|---|---|
| 1 🔴 purify 顺序 | `game_main.gd:1983–1988` | 先 `_clear_calamity_effects()`（`_calamity` 仍在，match 命中）→ `_calamity = ""` → `calamity_floors.erase(本层)`；`:433–451` clear 末尾重置 cut/saved 不再有害（后续 `next_floor` 再 clear 走空分支） | **PASS** |
| 2 🟠 暂停交接 | `shrine_panel.gd:171–179` | `_offers=[]` → `_root.visible=false` → `paused=false` → `chosen.emit(i)`；`upgrade_panel.show_choices` 在 emit 内设 `paused=true` 不再被覆盖 | **PASS** |
| 3 🟡 空池护栏 | `game_main.gd:1958–1968` | `is_empty()` 分支直接写 `cleared=true` 并 return；`_milestone` / `Game.sfx("shrine")` / `panel.open` 全在其后 | **PASS** |
| 4 🟡 源石代价 | `game_main.gd:1995–1998` + `game_state.gd:157–163` | 改走 `Game.spend(cost)`，只动 `diamonds` / `meta_spent`，不触 `run_diamonds_earned` / `_reso_pickups`；主侧 `_on_shrine_chosen:2020` 与面板 `open:113–118` 双保险（实读：`can_afford` 由 `Game.main._shrine_affordable` **内部计算**，非外部传参，置灰确实生效） | **PASS** |
| 5 🟡 换层残留 | `game_main.gd:1282–1283` | `_clear_calamity_effects()` 后显式 `_calamity = ""`，早于 `_enter_room` / `_roll_calamity` | **PASS** |
| 文案 | `data.gd:316` / `shrine_panel.gd:149` | desc「若为唯一灾祸层，×1.5 结算作废」、代价「×1.5 加成或失效」，与 `settle_shards` 整局 `size()>0` 判定一致 | **PASS** |

### 三、主理人事实错误认领与更正（重要）

上一轮本报告 §二表格 `:42` 写：

> `frenzy` | `calamity_speed_mult` 恢复 ✓（`:431` 无条件） | 恢复 ✓

**这句是错的，我认领。** 它引的是 round-1 `266651a` 的旧码（该版 clear 确有无条件 `Game.calamity_speed_mult = 1.0`），不是 `bf2010b` 当时磁盘上的现状：`bf2010b` 的 `_clear_calamity_effects()` 只有 frail / scarce_ammo / scarce_ore 三分支，`:431` 是空行；全仓 `calamity_speed_mult` 写入仅 `_apply_calamity:423`（设 1.25）与 `game_state.gd:135 reset()`（整局归零），**换层没有任何还原路径** → frenzy 自 Sprint 12 二轮 `0c7f94f` 起就跨层固化整局，且四轮探针都没测过 frenzy 分支。

git 历史对照（实查）：`266651a` 有 speed reset → `0c7f94f` / `bf2010b` 无 → `89edfc8` 在 clear 补 `"frenzy": Game.calamity_speed_mult = 1.0`（`game_main.gd:447–448`）。消费者 `slug.gd:232` 实读确认该系数直接进入敌人移速，是有实害的数值缺陷，不是注释或口味问题。

**更正后的表格行**：`frenzy` | ❌ 未还原（`bf2010b` 现状，跨层固化整局） | 应在 clear 补分支。

**教训**：核验报告里打 ✓ 的每一项都必须绑定到**当前 commit 的行号**，不能沿用上一轮的行号印象。这与我连续三轮批评编程侧的「断言只验标志、不验数值」是同一类错误 —— **核验侧自己也犯了「凭旧码下结论」**。已列入下批复核纪律：凡标 ✓，必须附本轮实读行号。

### 四、断言有效性反查（防第五次「全绿却漏」）

| 检查 | 实读 | 判定 |
|---|---|---|
| frenzy 断言是否有真实差值 | `_apply_calamity:422–423` 设 `1.25`；探针 `player.gd:787–800` 逐灾祸先归零再 apply 后 purify，验 `is_equal_approx(speed_mult, 1.0)` | 若 clear 无 frenzy 分支断言必失败 → **真断言，非恒过** |
| 四灾祸是否全部入循环 | `for cid in ["frail","frenzy","scarce_ammo","scarce_ore"]`，逐项验 `max_hp` / `mag_cap_mult` / `diamond_mult` / `calamity_speed_mult` + `_calamity == ""` + 当层剔除 | PASS |
| append / erase 是否净平衡 | `_roll_calamity:390` 才 append；`_apply_calamity:408–429` 不 append；循环 4 次 append/erase 各 4 次 → `has()` 为 false 可达成 | PASS |
| 暂停交接双断言 | `player.gd:836–844`：圣所 autopick 后 0.8s 验 `paused == true`（升级面板期间）、再 0.9s 验 `paused == false`（autopick 收尾后） | PASS |
| 置灰是否真生效 | `shrine_panel.open:109–118` 内部调 `_shrine_affordable` 构造 `can_afford` → `_set_state` 置灰 → `_pick:172` 再拦 | PASS |

### 五、四门控复核（本轮实校，不复用编程侧结论）

| 门 | 结果 |
|---|---|
| 冻结 | `md5sum -c production/sprint-7/SPR7-FROZEN-4.md5` → **exit 0 / 33 OK / 0 FAILED**；清单 33 行、`scripts/*.gd` 33 个 |
| git | `git status --short` 空（工作树干净）；`89edfc8` 6 文件（交付文档 + 冻结清单 + `data.gd`/`game_main.gd`/`player.gd`/`shrine_panel.gd`）、`2c84a24` 仅新增本报告 103 行 |
| E1 | `shrine_panel.gd` 全文件零 `Game.rng` / `randi` / `randf` / `delta`；`game_main.gd` 圣所区段 `:1909–2026` 无 rng 调用（Grep 最高命中 `:1913` 为注释）；三卡 / 铭刻仍 `stable_hash` 纯派生；`ACTION_DEFS` 零新增 |
| E6 | 本批改动无计时逻辑，`shrine_panel.gd` 无 `_process` / raw delta |
| 探针 | 编程侧 `SMOKE_SHRINE` 定向 + 全量 6000 帧 0 报错；本轮以「差值可观察性」反查确认新增断言不是恒过假断言 |

### 六、非阻塞前瞻（不要求本批返工，登记在册）

1. **换层 roll 时序**：`next_floor:1288–1291` 是 `_enter_room` → `_roll_calamity`，进入新层起点房瞬间 `_calamity` 仍为 `""`。当前 `dungeon.gd` 保证 shrine 不落在 `Vector2i.ZERO`，故 `_shrine_offers_for:1929` 的 purify 过滤不受影响；若未来允许圣所落在起点房、或把三卡派生提前到 `_enter_room`，purify 会被误过滤。
2. **`Array.erase` 只删首个匹配**：真实流程每层仅 `:390` append 一次，无重复；若未来同层重复 roll，`erase` 后 `calamity_floors` 会残留同层项。
3. **clear 末尾三 saved 值无条件重置**（`:449–451`）：`_calamity == ""` 时也执行，目前空分支不碰倍率 / max_hp 故无害；若 saved 未来承担更多信息需复核。

### 七、收尾状态与放行

- **阶段一 PASS，正式收官**。阶段二 C（地窖图鉴 / 局末复盘）与本批零耦合，**准予开工**；规格以 `SPR13_规划草案.md` §C 为准：`user://codex.cfg` 双档 / 只读 `Game.mark_codex(kind,id)` / 主菜单只读图鉴页 / 本局复盘 / `SMOKE_CODEX` 表外探针 / **不碰 `meta.gd UNLOCKS`**（冻结规格 v2.10）。
- 本附章为报告文档追加，**尚未提交**；按批次流程待授权后单独提交（不涉及任何 `.gd`）。
- 主理人本轮**未改任何 `.gd`**，仅追加本附章 + 更新工作日志与长期记忆。
