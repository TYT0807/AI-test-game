# Sprint 26 批三 · 主理人读码核验

> 核验对象：`b61c3dd`（Sprint 26 批三：显示层「矿」字清零）
> 基线：`d2b50f5`（批三实施单）
> 核验方式：不采信编程侧报告，逐字读 diff + 独立重跑五门 + 双向变异测试
> 核验时间：2026-11-15 · HEAD `b61c3dd` · 工作树干净 · 本地领先 `origin/main`（`e2b5828`）6 提交（未推送，推送归编程侧）

## 结论

**final PASS**（附 2 项如实标注，均不阻塞）

---

## 一 改动范围核验（G1）

`git show b61c3dd --stat` 实测 9 文件 `+28/−28`，与报告一致：

| 文件 | 变更行 | 内容 |
|---|---|---|
| `README.md` | 2 | 方向表 B/D 两行「矿工手记」→「见痕手记」 |
| `production/sprint-21/SPR21-FROZEN.md5` | 6 | 6 个改动 `.gd` 的 md5 刷新 |
| `scripts/boss.gd` | 1 | 注释「矿脉富集」→「往生脉富集」 |
| `scripts/data.gd` | 3 | 1 注释 + 2 条 FLAVOR value 后半段 |
| `scripts/game_main.gd` | 2 | 灾祸名 `scarce_ore` + 1 注释 |
| `scripts/game_state.gd` | 2 | 播报前缀 + 1 注释 |
| `scripts/menu.gd` | 2 | 主菜单副标题 + 1 注释 |
| `scripts/player.gd` | 6 | 4 断言同步 + 2 注释 |
| `玩法说明.md` | 4 | `:32` `:301`（同段双改）`:320` `:334` |

**内容改行 22 行**（显示串 5 / 断言 4 / 注释 7 / 文档 6），加 md5 6 行 = 28。
零 `.png` / `.mp3` / `.import`；`git show --name-status` 无 A/D（无新增删除）。**范围无越界。**

> 口径订正：实施单预估「19 处」、编程侧报告写「显示串 6」，实测显示串为 **5**（`game_state:354` / `menu:126` / `game_main:552` / `data:384` / `data:446`），总数 22 行。属分类口径差异，非缺陷。

## 二 「矿」字清零核验

- `grep -rn "矿" scripts/ resources/ *.tscn` → **0 行**（运行时零残留）。
- `grep -rn "矿" --include=*.gd --include=*.tscn --include=*.tres --include=*.json`（排除 `_backup/` 未追踪历史备份）→ **0 行**。
- `git grep -n "矿" HEAD`（排除 `production/` 历史批次文档）→ **仅 1 行**：`README.md:19`，实施单明示保留的批一历史描述。**相符**。

## 三 FLAVOR 表结构核验（脚本比对，非肉眼）

脚本 `_tools/s26b3_verify.py` 直接解析 `git show d2b50f5:scripts/data.gd` 与 `b61c3dd` 工作树：

| 项 | 结果 |
|---|---|
| 条数 | base **74** → head **74** → 工作树 **74** |
| key 集合 | 完全一致 |
| 实际变更条数 | **恰 2 条**（`shrine/ore_upgrade`、`bosses/dragon`） |
| 首词/首句前 4 字变化 | **0 条** |
| 前缀分桶 | bosses 7 / enemies 29 / relics 12 / shrine 10 / suffixes 8 / themes 8 —— 两版逐项相同 |
| `data.gd` 变更行 | **+3 / −3**（1 注释 + 2 value） |

两条实际变更：

```
shrine/ore_upgrade  残响淬炼。以残响换一次选择，矿里人管这叫喂石头。
                 →  残响淬炼。以残响换一次选择，旧例里管这叫喂石头。
bosses/dragon       黑龙，拿下。鳞甲留痕，地精散了，矿窟安静一半。
                 →  黑龙，拿下。鳞甲留痕，地精散了，这一层安静一半。
```

两条首词（`残响淬炼` / `黑龙，拿下`）逐字保留 → **探针零 churn、E1 零重定**的机制成立。
`FLOOR_THEMES` / `SHRINE_OFFERS` / `SIGILS` / `OATH_CONDITIONS` / `CODEX_BOONS` 因 data.gd 仅 3 行变更，**逐字节零动**（结构性证明，无需再比对）。

## 四 E1 确定性（G3，三跑）

`SMOKE=1 SMOKE_SEED=12345 SMOKE_META_FINGERPRINT=1 --headless --quit-after 1800`，**未用 `SMOKE_DAILY`**：

改前基线用 `git checkout d2b50f5 -- scripts/` 取（跑后 `git checkout HEAD -- scripts/` 还原，`git status` 空）：
```
[SMOKE-META] fingerprint floor=1 rooms=(-1, 0),(-1, 1),(0, -1),(0, 0),(0, 1),(0, 2),(0, 3),(1, 1),(2, 1) kinds=secret,treasure,shop,start,combat,elite,super_secret,elite,boss
```
HEAD 两跑 + 基线一跑 = **三跑逐字相同**，且与实施单预期行逐字相同。**零重定成立。**

## 五 播报真渲染（G4）

`SMOKE=1 SMOKE_SEED=12345 SMOKE_SHRINE=1 SMOKE_FLOOR_SIGN=1`：EXIT=0、`[ERR]` **0 条**、`[SMOKE-FLOOR-SIGN] done` 与 `[SMOKE-SHRINE] done` 齐。
`SMOKE=1 SMOKE_SEED=12345 SMOKE_CODEX=1`：EXIT=0、`[ERR]` **0 条**、`[SMOKE-CODEX] done`。
日志实证 `ore_upgrade=[残响淬炼。以残响换一次选择，旧例里管这叫喂石头。]` 真渲染。

### 独立变异测试（双向，证明断言存活且分层正确）

`Dev.check()` 仅失败时打印（`dev_log.gd:29-32`），故绿=0 条不能证明断言执行过 → 必须变异。

| 变异 | 改动 | 实测 `[ERR]` | 判定 |
|---|---|---|---|
| A · 前缀 | `game_state.gd` 两处 `见痕手记` → `矿工手记` | **恰 3 条**全红（首发现播报 / 单条回归 / S26 value 断言） | 前缀层被 3 条断言锁定，**存活且真执行** |
| B · value | `data.gd` `themes/magma` 的「地狱热狱」→「地狱狱」 | **恰 1 条**红（仅 S26 value 断言），两条只验前缀的断言**仍绿** | 分层锁定正确（前缀 ≠ 内容，各自独立） |

变异 A/B 后均 `git checkout HEAD --` 还原，md5 逐字复原（`data.gd 03ee7992` / `game_state.gd b7138600`），`git status` 空。
变异 B 的 `[ERR]` 消息原文含「**见痕手记** · 岩浆层。地狱狱，地板本身就是敌人。」——**正向证明了新前缀真上屏**（不只是断言绿）。

## 六 冻结快照（G5）

`md5sum -c production/sprint-21/SPR21-FROZEN.md5` → **34 OK / 0 FAILED**，快照 34 行 = `scripts/*.gd` 34 个。
刷新行 **恰 6 条**，与 6 个改动 `.gd` 一一对应（boss / data / game_main / game_state / menu / player），其余 28 行未动仍 OK（反证未越界）。
历史归档 `production/sprint-7/SPR7-FROZEN-4.md5` **零写入**。

## 七 附限定（如实标注，不阻塞 PASS）

1. **两处显示串无断言覆盖**：`menu.gd:126` 主菜单副标题「入六道 · 清异常 · 记归途」、`game_main.gd:552` 灾祸名「残响枯竭（残响掉落 -30%）」——全库 `grep` 确认零断言引用（`player.gd:880` 的四灾祸循环只验净化后**数值还原**，不验显示文本）。二者纯显示、零逻辑，变异不可能引入运行时行为差异；且与 S25 改主标题未加断言**同口径**，故不阻塞。已列入在册观察，随下批如需补断言一并处理。
2. **本批未新增断言**：断言改动为 4 处**期望值同步**（`player.gd:1514/1569/1572` contains + `:1573` 消息串），非新增覆盖。批二新增的 4 条真渲染断言仍有效并已随本批同步前缀，故「可见效果断言」在批二已落地，本批只做同步。

## 八 未做（不在本批能力范围）

- 真机（非 headless）视觉确认：我无显示设备交互能力，菜单副标题与灾祸名的**实际排版观感**未经人眼确认，建议进游戏看一眼（不阻塞）。
- BGM 真机试听仍挂账（批一遗留）。

## 九 提交

本报告单独提交，不推送（推送归编程侧）。
