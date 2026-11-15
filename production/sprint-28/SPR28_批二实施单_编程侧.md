# Sprint 28 批二 · 实施单（编程侧）——第 12 层覆盖 + 灾祸文案实际值

> 本文是批二**唯一权威**。上游：`production/sprint-28/SPR28_批二验证口径.md`（144 行，断言规格 / 判据 / 刀表全在里面，先读它）。
> 基准 HEAD `8d07279`（S28 文档链），`scripts/` 34 个 `.gd`，冻结 34/34 OK。
> **只改 `.gd`**；**推送不归你**。

---

## 一 一句话

批二由两件互不耦合的事组成：**(1) 第 12 层补真跑覆盖**（生产代码零改动，纯探针）、**(2) 灾祸文案从名义比例改成实际比例**（生产代码一处函数）。两组的断言编号、变异刀都分开，红了能看出是哪一件出的事。

---

## 二 硬红线

1. 🔴 **第 12 层生产代码零改动**。`_apply_calamity()` 已经走 `Data.theme_for_floor()`（现值正确），本批只补探针，**不许「顺手优化」派生逻辑**——一动就打不着我们想抓的错误实现。
2. 🔴 **文案首词逐字不动**：`虚弱` / `狂乱` / `弹药荒` / `残响枯竭`。历史断言全是 `contains` 首词，改一个字会连带打红既有断言。
3. 🔴 **不许显示 `-0%`**：实际削减为 0 时必须走「不再削减」分支。
4. 🔴 `frenzy` / `scarce_ammo` **不在本批范围**，两条分支一个字不动。
5. 零新增 `Game.rng` 消费、零计时改动、零新增实体。冻结清单除 `game_main.gd` 外零漂移。
6. **不改既有断言或期望值**（既有 103 条批三断言必须零 churn）；新增断言接在末尾。
7. **不要自己刷新冻结快照**（核验侧收官统一刷）。

---

## 三 生产代码改动（仅 1 处函数）

`scripts/game_main.gd:566-578 func _calamity_name(id: String) -> String:`

只改 `frail` 与 `scarce_ore` 两个分支，**`frenzy` / `scarce_ammo` 与 `return id` 一字不动**。

### 3.1 `frail` 分支

现状读名义比例 `_calamity_frail_ratio`。改成读**实际削减**：

- 实际削减量已在 `_apply_calamity()` 里算出并存进 `_calamity_frail_cut`（`old_hp - player.max_hp`，钳制后重算，可为 0）。
- 原上限 = `player.max_hp + _calamity_frail_cut`（钳制后仍能还原）。
- 实际百分比 = `int(round(100.0 * float(_calamity_frail_cut) / float(maxi(1, player.max_hp + _calamity_frail_cut))))`
- 若 `_calamity_frail_cut <= 0` → 返回 `虚弱（生命上限不再削减）`
- 否则 → 返回 `虚弱（生命上限 -%d%%）`，`%d` 用上面的实际百分比

🔴 不要复用 `_calamity_frail_ratio` 做分母或分子——它就是这次要修掉的名义值。

### 3.2 `scarce_ore` 分支

现状 `base = maxf(_calamity_saved_diamond_mult, 0.001)`、`1.0 - 0.7/base`，`barren` 局 `base=0.7` 得 0。

- 先算 `var cut_ratio := 1.0 - 0.7 / base`（`base` 钳制保留原样）
- 若 `cut_ratio <= 0.0` → 返回 `残响枯竭（残响不再削减）`
- 否则 → 返回 `残响枯竭（残响掉落 -%d%%）`，`%d = int(round(cut_ratio * 100.0))`

🔴 不要给 `cut_ratio` 加 `maxf(0.0, ...)` 再照旧显示 `-0%`——那等于没修。

### 3.3 为什么这样改不会打红既有断言

实读确认：没有任何探针断言卡面 `desc` 或 `_calamity_name()` 的**完整**返回值；图鉴/菜单只读 `SHRINE_OFFERS[*].name`；既有灾祸断言只 `contains` 首词。首词保留 ⇒ 既有 103 + 76 条零 churn。

---

## 四 探针改动（仅新增，接在 `_ct_assert` 序列末尾）

挂载仍然是 `SMOKE_CAL_THEME=1` → `_smoke_cal_theme_probe()`，不新增环境变量。

### 4.1 G 组 8 条（第 12 层）

按 `SPR28_批二验证口径.md §1.3` 逐条实现。`_ct_floor_advance(12)` 从 11 推进（**不要从 4 直接跳 12**——每格改变 rule 才能验到回卷链；但本组重点是 12 的回卷结果，若从 11 推更省构造，写明选择理由即可）。

必须做到的构造：

- 手工设 `_calamity = "frail"`，`Game.floor_num = 12`，调 `_apply_calamity()`（不要走 `_roll_calamity()`，它会抽 rng）。
- G02 读 `_calamity_theme_rule == "vein"`（**靶心**：直查 `FLOOR_THEMES.get(12, {})` 的实现在这里拿空串）。
- G03 读 `_calamity_frail_ratio` 的 **vein 实值**——🔴 **先实读 `game_main.gd:559 _frail_ratio()` 再写 expect**，验证口径 §1.2 里我给的数字可能已过期。
- G04 读 `old_hp - player.max_hp`，expect 用同一实读比例算，别写死。
- G05 调 `_clear_calamity_effects()` 后读 `_calamity_theme_rule == ""`。
- G06 四通道还原到**入口快照**。

🔴 **读数时点**：`_ct_floor_advance()` 会触发 `_apply_floor_theme()`，它无条件把 `enemy_speed_mult` / `diamond_mult` 回落到 `_mod_*`。G06 读倍率必须在主题重建前，或先把 `_mod_*` 归一；**出口从入口快照还原，不许还原成 1.0**（barren/swarm 局约 28.6% 会误红）。

🔴 G01 / G07 必须标注「前提守卫（恒过），不构成覆盖」——它们只验 `Data` 函数返回值，直查表的错误实现照样绿。

### 4.2 H 组 7 条（文案）

按 `SPR28_批二验证口径.md §2.3` 逐条实现。关键构造：

- **H01 必须造名义 ≠ 实际的局**：例如 `frail` 在 magma / barren 组合下比例不同，或把 `max_hp` 设到接近钳制下限，让名义 10%/40% 与实际 cut/max 不同。若两者恰好相等，这条恒过、不算覆盖。
- **H02**：`player.max_hp = 2` 后 apply `frail`，文案必须含「不再削减」且**不含 `-0%`**。
- **H05**：`_calamity_saved_diamond_mult = 0.7`（barren 局）后调 `_calamity_name("scarce_ore")`，同样必须含「不再削减」。
- H03 / H06 是 H02 / H05 的前提守卫，**标注恒过**，不许计入有效覆盖。

### 4.3 收尾还原

G/H 两组共用一份入口快照：`Game.floor_num` / `_calamity` / `_calamity_theme_rule` / `_calamity_frail_ratio` / `_calamity_frail_cut` / `_calamity_saved_diamond_mult` / `player.max_hp` / `player.hp` / 四通道 / `Game.rng.seed` 与 `.state`。收尾逐项还原并 `update_floor_sign()`，否则污染同进程其它探针。

---

## 五 验证门

| 门 | 期望 |
|---|---|
| G1 `validate` | 34/34、`problems=0` |
| G2 探针 | `done checked=118 declared=118`（103 + G组8 + H组7；若你实际条数不同按实报，但 declared 必须与 `#NN` 行数一致）；`[ERR] == 0` |
| G3 既有零 churn | 批三原 103 条的 `measured=` / `expect=` 文本与 HEAD `2ebdc38` **逐字相同** |
| G4 E1 | seed `12345` / `777` / `42` 对 `2ebdc38` 指纹逐字一致 |
| G5 回归 | `SMOKE_OATH_GRANT` 43/43 + 其余既有探针同进程跑，`[ERR] == 0` |
| G6 冻结 | 除 `game_main.gd` 外 33 行 OK |

🔴 **判红用 `grep -c "\[ERR\]"`**，`_ct_assert()` 不打 `ok=`。用 `ok=false` 判本批会得到 0 红、把正确实现判成变异无效。

---

## 六 变异刀（5 把，核验侧独立复现）

| 刀 | 改法 | 预测红 |
|---|---|---|
| 刀一 | `_apply_calamity()` 派生改直查 `FLOOR_THEMES.get(floor_num, {})` | G02 / G03 / G04；G01 / G07 必绿 |
| 刀二 | clear 里 `_calamity_theme_rule = ""` 换成现查主题 | 仅 G05 |
| 刀三 | frail 文案改回读 `_calamity_frail_ratio` | H01 / H02 |
| 刀四 | scarce_ore 文案改回 `1.0 - 0.7/base` 原式 | H05 |
| 刀五 | 任一文案首词改字 | H07 + 既有跨批断言 |

变异纪律：替换目标行、不新增行；注释里不写符号字面（文本级静态门会凭空多红）。

---

## 七 完成定义

六门全过 + 五刀逐刀见红且编号对齐 + 复原后复跑全绿 + 既有 103 条零 churn + 工作树只含 `game_main.gd` 一个生产文件与探针块。
报交付时附：commit hash、六门实测数、五刀红表、**G03 的实读比例来源行号**、以及任何偏差的如实记录。**不 commit 文档、不推送。**
