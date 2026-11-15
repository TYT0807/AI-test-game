# Sprint 26 批二 · 主理人独立读码核验报告

> 主理人（创造层）自核，2026-11-15。批二由 eng-s26 实施，本报告为**独立核验**（重跑门控 + 自写脚本比对 + 独立变异测试），不采信其自报结论。
> **结论：final PASS。**

## 一 改动范围（独立实读）

`git diff --stat`：`scripts/data.gd +54/-54`、`scripts/player.gd +23/-0`，其余零动。工作树仅这 2 个 `.gd` 为 M。

- data.gd：54 行删除 + 54 行插入，**全部在 FLAVOR 块内**；FLOOR_THEMES / 播报格式串 / CODEX_KINDS / ACTION_DEFS / Meta.STATS_KEYS / UNLOCKS / CODEX_BOONS / SHRINE_OFFERS·OATH_CONDITIONS·SIGILS 机制字段零 diff（逐行读 diff 确认）。
- player.gd：+23 行 = 4 条新增渲染断言，全部落在既有 `_shrine_probe` / `_floor_sign_probe` 内，**现有断言期望值一字未改**。

## 二 独立脚本比对（不采信报告）

用 Python 直接比对 `HEAD:scripts/data.gd` 与工作树：

| 项 | 结果 |
|---|---|
| FLAVOR 条数 | 74 → 74 |
| key 集合 | 完全一致（差集为空） |
| **首词变化条数** | **0**（74 条首词逐字不变——这是 E1 零重定的根因） |
| 实际变更条数 | 恰好 54 |
| 前缀分桶 | bosses7 / themes8 / shrine10 / enemies29 / relics12 / suffixes8 —— old==new |
| relics / suffixes 变更 | 空 |

## 三 四门控（主理人重跑）

| 门 | 结果 |
|---|---|
| 批二探针 | `SMOKE=1 SMOKE_SEED=12345 SMOKE_SHRINE=1 SMOKE_FLOOR_SIGN=1 --quit-after 1800` → EXIT 0、`[ERR]` **0 条**、`[SMOKE-FLOOR-SIGN] done` + `[SMOKE-SHRINE] done` 齐 |
| validate | 自检通过（敌人 29 / 房间 11 / 地图池 4 层）、problems=0 |
| E1 | **批前基线（stash 后跑）+ 批后两跑，三跑 fingerprint 逐字 IDENTICAL**（base==a1==a2），零重定，未用 SMOKE_DAILY |
| 冻结快照 | 刷新 data.gd + player.gd 两行后 → **34 OK / 0 FAILED** |

## 四 变异测试（主理人独立做，证明断言真生效）

把 4 个新词各改一字：人间拾痕→人间拾迹、地狱热狱→地狱热域、饿鬼食毒→饿鬼食素、以血换遗物→以血换遗器。

结果：**恰好 4 条 `[ERR]` 全红**，逐条对应：
- `floor_sign_sub: S26 … 人间拾痕`（实值显示"人间拾迹"）
- `flavor: S26: toast 含「矿工手记 · 岩浆层。地狱热狱」`
- `flavor: S26: 图鉴 themes 手记行含「毒巢。饿鬼食毒」`
- `shrine: S26: blood_relic 灰字含「血祭。以血换遗物」`

同时原有断言（含往生脉 / 含矿工手记·岩浆层 / 灰字==表值）**仍绿**——印证首词未动。恢复后 md5 复原 `c84bc498…`，变异词零残留，正确新词 4 条在位。

**断言性质判定**：4 条均为字面量锁（`contains("具体新词")`），非「表里有键」、非常量自比较，属有效行为断言。

## 五 与实施单的一处偏差（eng-s26 主动补正，正确）

实施单 §五.5 只提 data.gd 快照会变；实际 player.gd 因新增断言同样变 → 快照应 2 行。eng-s26 主动指出并说明，主理人核验确认属实，已按 2 行刷新。**这是有效的自主校正，不扣分。**

## 六 如实标注

1. **`ERROR: N resources still in use at exit`**（退出期噪声，基线 5 / 改后 4）——改前基线同样存在，非本批引入。
2. **新断言在探针门控内**（`SMOKE_SHRINE` / `SMOKE_FLOOR_SIGN`），不进 E1 指纹，符合「SMOKE 表外探针」口径。
3. **`enemies/vampire` 归「妖」**（实施单已注明，diff 中为 `异常·妖`，与归族声明一致）。

## 七 结论

批二 = 54 条 FLAVOR value 六道卷化 + 4 条真渲染断言，首词零动、key 零动、条数零动、机制零动；E1 三跑 IDENTICAL、validate 0 报错、冻结 34/34、变异测试 4/4 红。**final PASS。**
