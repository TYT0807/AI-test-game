# Sprint 31 · 主理人独立核验 —— 灾祸显示口径收敛

> 核验对象：`51f82c6`「S31 灾祸显示口径收敛：frenzy/ammo 文案改读施加时快照」
> 核验方：主理人（创造层）｜**全部自跑，不采信交付报告自报数**。
> 基准 HEAD `7656b70`（文档链），生产基线 `829d1fb`（S30 收官）。
> 结论：**final PASS**。六门自跑全过、四刀自跑复现、四条偏差全部裁定、冻结刷 1 行 → 34/34。

---

## 一 改动面

`git show --stat` 仅一个文件：

```
scripts/game_main.gd | 176 ++++++++++++++++++++++++++++-
1 file changed, 174 insertions(+), 2 deletions(-)
```

拆开看：**生产改动 12 行**（2 字段声明 / 2 处施加写 / 2 行 clear 复位 / 2 处文案分支各 3 行），其余 162 行是新增探针块 `_smoke_cal_theme_s31_probe()` + `_s31_assert()`。零 `.gd` 文件增删，零资产，零文档（文档另在 `7656b70`）。

生产改动实读确认（`scripts/game_main.gd`）：

| 位置 | 内容 | 判定 |
|---|---|---|
| `:125-126` | `_calamity_speed_mult_applied` / `_calamity_ammo_mult_applied`，默认 `1.0` | ✓ 紧邻 `_calamity_frail_ratio` |
| `:584-588` | `frenzy` 支：`_calamity_speed_mult_applied <= 1.0` → 「敌人不再加速」，否则按快照算 `%d%%` | ✓ 读快照，不读 live |
| `:591-595` | `scarce_ammo` 支：`_calamity_ammo_mult_applied >= 1.0` → 「弹匣不再削减」，否则按快照算 `-%d%%` | ✓ 同上 |
| `:597-599` | `scarce_ore` 支：`base = maxf(_calamity_saved_diamond_mult, 0.001)`、`ore_cut = 1.0 - 0.7/base` | ✓ **一字未动** |
| `:628-629` | frenzy match 三档赋值**之后** → `_calamity_speed_mult_applied = Game.calamity_speed_mult` | ✓ 存写进效果通道那个数，未另算映射 |
| `:641-642` | ammo `player.mag_cap_mult=` 之后 → `_calamity_ammo_mult_applied = player.mag_cap_mult` | ✓ 同上 |
| `:671-672` | `if _calamity != "":` 块内，五处既有复位后加两行归 `1.0` | ✓ 未延后到清 id |

**族名首词** `虚弱` / `狂乱` / `弹药荒` / `残响枯竭` 四支全部逐字保留（W1 实测 `measured=[]` 零违例）。

---

## 二 六门自跑实测

| 门 | 我跑的命令要点 | 实测 | 判 |
|---|---|---|---|
| **G1 validate** | `SMOKE=1 --quit-after 300` | `validate: 脚本编译扫描 34/34 通过`、`validate problems=0`、`[ERR]`=**0** | ✓ |
| **G2 新探针** | `SMOKE=1 SMOKE_SEED=777 SMOKE_CAL_THEME=1` | `[SMOKE-CAL-THEME-S31] done checked=12 declared=12`、`ok=false`=**0**、`[ERR]`=**0** | ✓ |
| **G3 零 churn** | 同上日志 | `[SMOKE-CAL-THEME] done checked=117 declared=117` 不动；W1 绿；⑦四条 + H01/H02/H04/H05 全绿 | ✓ 见 §四.6 |
| **G4 E1** | `SMOKE_META_FINGERPRINT=1` × seed 12345/777/42 | 三行 `rooms=`/`kinds=` 与口径 §1.4 **逐字一致** | ✓ |
| **G5 回归** | `SMOKE_SAVE=1 --quit-after 3200` + 三探针 | `[SMOKE-SAVE] roundtrip=OK` / `settings persist=OK`；OATH/PURIFY/START_BUFFER `[ERR]`=0 | ✓ |
| **G6 冻结** | `md5sum -c SPR21-FROZEN.md5` | 33 OK + `scripts/game_main.gd: FAILED`（**未自刷**） | ✓ 收官刷新见 §五 |

E1 实跑三行（我这边原样）：

```
[12345] rooms=(-1, 0),(-1, 1),(0, -1),(0, 0),(0, 1),(0, 2),(0, 3),(1, 1),(2, 1) kinds=secret,treasure,shop,start,combat,elite,super_secret,elite,boss
[777]   rooms=(-1, -1),(-1, 0),(-2, 0),(0, -1),(0, 0),(0, 1),(0, 2),(1, 1),(2, -1),(2, 0),(2, 1) kinds=treasure,cursed,super_secret,secret,start,elite,shop,elite,boss,combat,combat
[42]    rooms=(-1, -1),(-1, 0),(0, -1),(0, -2),(0, -3),(0, 0),(0, 1),(1, -1),(1, -3),(2, -1),(2, 0) kinds=treasure,secret,combat,combat,elite,start,super_secret,challenge,boss,combat,shop
```

纯显示改动 + 两字段，**零 `Game.rng` 消费**，指纹零重定——与预期一致。

---

## 三 差分构造有效性（本批真正要证的）

交付报告的核心主张是「施加后制造 live 漂移再取 measured」。我不看断言名，直接看 measured 字面：

| 编号 | 造局 | measured 实测（我这边原样） | 错实现会报 |
|---|---|---|---|
| F2 | apply=1.25 → 手工 `speed=1.6` → `update_floor_sign()` | `name=狂乱（敌人加速 25%）`、`sign=层签 · 无主题 ｜ 灾祸：狂乱（敌人加速 25%）` | `60%` |
| A2 | apply=0.5 → 手工 `mag_cap_mult=0.9` | `name=弹药荒（弹匣 -50%）`、`sign=… 灾祸：弹药荒（弹匣 -50%）` | `-10%` |
| A2t | f5 毒巢，apply=0.5 → 真实 `_theme_damage_tick()` ×2 → `mc=0.3` | `name/sign` 均 `-50%`，`mc=0.3` | `-70%` |
| O1 | f6 压力层 `diamond=1.5` → apply ore | `base=1.5 | 残响枯竭（残响掉落 -53%）` | `不再削减` |
| O2 | 承 O1 → 手工 `diamond=1.2` | `-53%` | `-42%` |
| O3 | f1 无主题，`base=1.0` | `-30%` | `不再削减` / `-53%` |
| O4 | barren `base=0.7` | `残响枯竭（残响不再削减）` | `-53%` |
| F0 / A0 | 快照置中性 1.0 | `狂乱（敌人不再加速）` / `弹药荒（弹匣不再削减）`，均不含 `0%`/`-0%` | `0%` / `-0%` |

🔴 **A2t 是这批最有价值的一条**：它走的不是手工改字段，而是真实 `_theme_damage_tick()` 把 live 从 0.5 一路啃到 0.3（毒巢 tick 弹匣 −0.1 下限 0.3），这正是线上玩家实际会遇到的漂移路径。刀二下它报 `-70%`——**证明现行错实现真的会在层签上说谎，不是理论风险**。

---

## 四 四刀自跑复现（逐刀换行 + 复原验 md5）

刀前快照 `scripts/game_main.gd` md5 = `8ae06aa74d62c74ce8d34904c150b567`；每刀跑完 `cp` 复原并 `md5sum` 复验回到同值。全部**替换目标行、未新增行**。

| 刀 | 改法（单行） | 实测红集（`ok=false`） | `[ERR]` | 对齐 |
|---|---|---|---|---|
| **一** | `:584` 快照 → `Game.calamity_speed_mult` | **F2**（`measured=…60%`） | 1 | ✓ 与口径「F2」一致 |
| **二** | `:592` 快照 → `player.mag_cap_mult` | **A2**（`-10%`）+ **A2t**（`-70%`） | 2 | ✓ 与口径「A2 A2t」一致 |
| **四** | `:591` `_calamity_saved_diamond_mult` → `diamond_mult` | **O1**（`不再削减`）/ **O2**（`-42%`）/ **O3**（`不再削减`），O4 绿 | 5 | ✓ 新编号对齐；**另连带既有 2 条，见 §四.5** |
| **七** | `:591` → `_mod_diamond_mult` | **O1** / **O2**（均 `-30%`），O3/O4 绿 | 4 | ✓ 与口径「O1 O2」一致；连带见 §四.5 |

刀一/二证明 F2、A2、A2t **非装饰**——不是"断言写了就算覆盖"，是换掉取值来源后确实红、且只有该面红。刀七作正对照：`_mod` 恰等于 `saved` 的正常局全绿、只压力局红，证明 O1/O2 打的是"快照 vs 名义"这个真实盲区。

### §四.5 刀四/刀七连带既有断言（口径未载，属正确超集）

刀四 `[ERR]`=5 而新编号只红 3 条，另 2 条是**既有 117 里的同源断言**：

```
[ERR] cal_theme: ⑦ore 实值@pressure | measured=残响枯竭（残响不再削减） dm=0.7
[ERR] cal_theme: H04 scarce_ore 常规局 -30%（base=1.0 实读） | measured=残响枯竭（残响不再削减）
```

刀七 `[ERR]`=4 = 2 新 + 2 既有（压力局 ⑦ore 同源）。

**裁定：不是缺陷，是覆盖更厚的证据。** `scarce_ore` 只有一条取值路径，改分母必然同时打到新旧两侧；口径 §三「预测红编号」只列新编号是**简写**。补注在此，防下一个核验者把"多红了"误判成实现有问题。

### §四.6 🔴 新前缀是旧前缀的严格超集（纪律条目，不返工）

`[SMOKE-CAL-THEME-S31]` 与既有 `[SMOKE-CAL-THEME]` **公共前缀完全相同**。实测：

```
grep -c "SMOKE-CAL-THEME"        → 159
grep -cE "^\[SMOKE-CAL-THEME\] #" → 117
```

松散 grep 把 12 条新断言 + entry/done 行一并收进 117 的 churn diff → **在正确实现上得到"多出 12 行"的假 churn**。

**纪律**：W2 的 churn diff 一律用带右括号的锚点 `^\[SMOKE-CAL-THEME\] #`，禁裸 `SMOKE-CAL-THEME`。
**不返工**：功能零影响，已过六门；改名要再走一轮六门换零收益。入册为下一批的施工注意项。

---

## 五 偏差裁定（交付报告列 4 条，我逐条判）

### 偏差 1｜`_s31_assert` 双门（同时打 `ok=` 且走 `Dev.check`→`[ERR]`）→ **采纳**

`_s31_assert`（`:712-717`）连 `Dev.check(ok, "cal_theme_s31", …)` 又 `print(… ok=%s)`。两个判据**同源同 bool**，不存在矛盾——`ok=false` 与 `[ERR]` 必然同时出现或同时不出现。严格比单门更保守：我原要求"批二式看 `ok=false`"、QA 口径「〇.2」要求"新断言走批三式看 `[ERR]`"，两条指令在本批是不一致的（这正是我在实施单里点名要防的坑），双门把两边都满足。

副作用面已核：tag 用 `cal_theme_s31`（非 `cal_theme`）、前缀独立、计数独立（`_s31_checked` vs `_ct_checked`）、`done` 线独立 → 既有 117 与 `[SMOKE-CAL-THEME] done` 行逐字不动（实测复现）。

### 偏差 2｜探针 `declared=12` 而非 16 → **实施方对，是我的实施单错了**

口径 §二确为"16 编号"，但同一节末尾《分类小计》写明 16 = 验效果 8 + 前提守卫 6（F1 A1 F0 A0 E1 V2）+ 走查 2（W2 V1）。**W2/E1/V1/V2 是门外断言**（shell 门 / 指纹门 / validate 门 / 跨批回归门），根本不在探针块内。探针块内行为断言只有 12 条：F1 F2 F0 A1 A2 A2t A0 O1 O2 O3 O4 W1。

我在实施单 §四写「按口径 declared（**16 条含 A2t**）」——把「编号总数」与「探针 declared」混为一谈，是**我的措辞错误**，与 S31 任务书 47% 那次同类。**订正**：探针 `declared` 报 12；对外报「16 编号 / 有效覆盖 8 / 探针 12」。**不要求实施方凑 16**——那要拆 W1 为 4 条、F2/A2/A2t 拆 name/sign，纯为凑数改断言行集合，是反覆盖行为。

### 偏差 3｜刀六红集实测 `F1 F0 W1` 而口径只写「W1＋既有」→ **正确超集**

F1 的 expect 是 `contains("狂乱") and contains("25%")`、F0 是 `contains("狂乱（敌人不再加速）")`——两条 expect **本身就嵌了首词**，首词一改必红。口径 §三写「W1＋既有」是简写（按"打首词 churn"的意图写）。A0（弹药荒）、O3（-30%）不受影响，实测绿。**不需要改断言**。

### 偏差 4｜O3/O4 造局补 `_mod_diamond_mult` → **构造保真，非生产改动**

O3 补 `_mod_diamond_mult = 1.0`、O4 补 `= 0.7`（模拟 barren），使 `_mod == saved` 这个生产前提成立。生产里 `_apply_floor_theme()` 先把 live 回落到 `_mod_*`，barren 局两者同为 0.7——不复刻这前提，O4 的 `_mod` 会残留上一条断言的值，刀七就会把 O4 误红，与口径 §四「O4 绿」冲突。**属造局对齐生产，零生产改动**（探针块内）。采纳。

---

## 六 收官动作

1. 冻结 `production/sprint-21/SPR21-FROZEN.md5` 第 15 行 `scripts/game_main.gd`：`613fe584…` → `8ae06aa74d62c74ce8d34904c150b567`（**只此一行**，其余 33 行零动）。刷后 `md5sum -c` 应 34/34。
2. 提交本核验文档 + 冻结刷新（一笔）。
3. 推送不归我（编程侧专人）。

## 七 未开事项（不入本批）

- **第 13 层以上行为覆盖**仍在册空洞（S28 已作废旧说法"⑥6 零覆盖"，但 13+ 仍无构造范式）。半径不同，另立。
- `barren` + `scarce_ore` 文案名义比例未收敛（S28 批二口径 §四已明确不覆盖）；本批 D3 维持原式，故仍在册。
- 压力层**当层内**仍 `maxf` 抬高（S28 在册项），本批不动。
