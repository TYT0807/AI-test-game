# Sprint 27 批一 · 技术约束（主理人实读）

> 用途：**在写任何代码之前必须遵守的时序纪律**。S27 批一改的是「灾祸的施加与还原」，
> 这块是全项目最容易出「静默错还原」的地方。本文所有行号实读于 `aba6ccb`。
> 配合 `SPR27_批一验证口径.md`（qa-s27）与 `SPR27_批一设计实稿.md`（design-s25）一起读。

## 一 三条时序陷阱（全部实读确认）

### 陷阱 1 🔴 换层时 `floor_num` 已经是新层，但灾祸还是旧层的

`game_main.gd:1505-1509`：

```
1505  Game.floor_num = nf            # ← 先变成新层
1506  Game.max_floor = maxi(...)
1507  _clear_calamity_effects()      # ← 然后才还原旧层灾祸
1508  _calamity = ""
1509  _apply_floor_theme()           # ← 主题最后才换
```

**后果**：任何写成「在 `_clear_calamity_effects()` 里按 `Game.floor_num` 现查主题、据此选还原分支」的实现，
都会用**新层的主题**去还原**旧层的变体** → 静默错还原，而且不会报错、不会红断言（除非专门验）。

这不是理论风险。S21 已经踩过同型的坑：`frenzy` 曾跨层固化整局（`game_main.gd:595-596` 有原文注释）。

### 陷阱 2 两条路径的「灾祸 / 主题」顺序相反

| 路径 | 顺序 | 位置 |
|---|---|---|
| `start_run` | 先 `_roll_calamity()`，后 `_apply_floor_theme()` | `:381` → `:385` |
| `next_floor` | 先 `_apply_floor_theme()`，后 `_roll_calamity()` | `:1509` → `:1516` |

（`next_floor` 行号经 qa-s27 校正：`:1512` 是 `var frng := _floor_rng(nf)`，不是主题应用点。）

**生产路径无害**：`FLOOR_THEMES` 只有 4–11 层，开局固定 1 层无主题，所以 `start_run` 里永远没有主题可冲突。

**但探针路径有害**：`SMOKE_JUMP_FLOOR` 是把 `floor_num` 直接写死再走 `start_run` 的尾巴，
于是走的是「先灾祸后主题」顺序 → 6 层（pressure）的 `diamond_mult = maxf(..., 1.5)` 会覆盖
`scarce_ore` 的 `minf(..., 0.7)` → **探针读到的「残响枯竭失效」是假阴性**。
禁止用 `SMOKE_JUMP_FLOOR` 验 6 层差额，改用同帧直接写 `Game.floor_num`（见 §三）。

### 陷阱 3 施加与还原共用同一个数值通道

| 通道 | 谁在用 | 位置 |
|---|---|---|
| `diamond_mult` | **pressure 主题** `maxf(...,1.5)` 与 **scarce_ore** `minf(...,0.7)` | `:871` / `:577` |
| `enemy_speed_mult` | 只有 pressure 主题 | `:870` |
| `Game.calamity_speed_mult` | 只有 frenzy | `:571` |
| `player.mag_cap_mult` | 只有 scarce_ammo | `:573` |
| `player.max_hp` | 只有 frail | `:566-568` |

**更正一处**：qa-s27 报告里写「`:870-871` 动 `enemy_speed_mult`/`diamond_mult`，与 frenzy/scarce_ore 同通道」——
`frenzy` 走的是**独立的** `Game.calamity_speed_mult`，与 `enemy_speed_mult` 不冲突。
**真正共用的只有 `diamond_mult` 一条**（pressure ↔ scarce_ore）。这条仍需重点验，但范围比报告说的小一半。

## 二 强制纪律（实施方照此写，核验方照此查）

### 2.1 施加时快照主题，还原时读快照——不许现查

在 `_apply_calamity()` 开头（`_calamity_saved_*` 那两行旁边）新增一个实例字段快照：

```
_calamity_theme_rule = String(Data.theme_for_floor(Game.floor_num).get("rule", ""))
```

- 🔴 **必须用 `Data.theme_for_floor()`，不许写成 `Data.FLOOR_THEMES.get(Game.floor_num)`。**
  实读 `data.gd:491-495`：`theme_for_floor()` 内部是 `key = 4 + ((n - 4) % FLOOR_THEMES.size())`，
  **第 12 层会回卷到 key 4（vein）**。直接 `FLOOR_THEMES.get(12)` 拿到空字典 → 12 层主题被判成"无主题"，
  变体永远不生效，而且不报错。这是我自己第一版写错的地方，已改正。
- 从 **`Game.floor_num` 派生**，不要读 `_theme_rule`。
  理由：`next_floor` 里 clear 发生在 `_apply_floor_theme()`（`:1509`）**之前**，此刻 `_theme_rule` 恰好还是旧值——
  看着能用，但这是**依赖调用顺序的巧合**，任何人调整一次层流程就静默崩。快照才是稳的。
- `_clear_calamity_effects()` 里**只读 `_calamity_theme_rule`**，禁止再读 `Game.floor_num` 或 `_theme_rule`。
- 在既有那段「saved 值重置收拢」里（`:597-601`，`if _calamity != ""` 内）一并重置 `_calamity_theme_rule = ""`。

### 2.2 还原必须用 saved 值，不许重新派生

现有还原走 `_calamity_saved_diamond_mult` / `_calamity_saved_mag_cap_mult` / `_calamity_frail_cut` 差值——
这是对的，**继续保持**。变体若引入新的数值改动，也必须按「施加时存、还原时取」写，
不许写成「按当前主题重新算一遍还原值」。

### 2.3 净化时序不能动

`game_main.gd:2224-2226`：**先 `_clear_calamity_effects()`，再 `_calamity = ""`**。
顺序反了会让 `clear` 的 `match` 走进空分支，把 debuff 永久固化。变体不改这个顺序。

### 2.4 零新增 rng

灾祸在 `:536` 已经抽过。复合只能看两个已有值：`_calamity`（抽出来的）与
`_calamity_theme_rule`（从 `floor_num` 派生的）。**不许再调 `Game.rng` / `_floor_rng` 任何一次**。

## 三 探针构造纪律

1. **同帧差额对照**：`_calamity` 和 `Game.floor_num` 都是可写字段 → 同一帧内换 `floor_num` 连测两个主题，
   不要跨帧、不要跳层。这样绕过了 `SMOKE_JUMP_FLOOR` 的顺序陷阱（§一 陷阱 2）。
2. 🔴 **换层构造必须让 rule 真的改变**：用 4→5 / 6→7 / 8→9 / 10→11。
   **禁用 4→12**——`theme_for_floor()` 回卷后 12 层仍是 `vein`，rule 相同，
   「在 clear 里现查主题」的错误实现在这种情况下也能蒙过 → 变异测试假绿。
   （此条由 qa-s27 在口径侧提出，我核准于 `data.gd:491-495`。）
2. **三段式缺一不可**：施加后验值 → 换层（先把 `floor_num` 改成下一层，**再**调 `_clear_calamity_effects()`）验精确还原 → 再施加一次验幂等。
   **只验第一段不算通过。**
3. **不许往 `_smoke_fingerprint`（`:318-333`）加内容**——那会让 E1 全量重定。
4. **探针开关**挂进 `:235-243` 既有 env 判定链（与 `SMOKE_META_*` 同级），不新增机制。
5. **证明断言真的跑过**：`Dev.check()` 只在失败时打印（`dev_log.gd:29-32`），所以
   `[ERR]=0` 本身不能证明覆盖。必须有：入口无条件打点 + 每条断言后无条件打印实测值 + 末尾自校验条数。
   判 PASS 要「打点条数 == 声明条数」**且** `[ERR]=0` 同时成立。

## 四 E1 与冻结

- 同 seed 只比 `[SMOKE-META] fingerprint` 行的 `rooms=` + `kinds=`；**禁用 `SMOKE_DAILY`**（`:349-353` 会覆盖 seed）。
- 批前基线用 `git checkout <ref> -- scripts/` 取，跑完 `git checkout HEAD -- scripts/` 还原。
- 冻结快照只刷被改文件对应行，其余行必须仍 OK（反证未越界）。

## 五 已在册、本批不修

| 项 | 判断 | 理由 |
|---|---|---|
| 跳层探针顺序陷阱（陷阱 2） | 不修 | 只在 SMOKE 跳层路径出现，生产路径因开局恒为 1 层而不可达；改它要动 `start_run` 顺序 → 直接改 E1 基线，代价远大于收益。纪律上「探针别用跳层」即可规避 |
| 6 层净化连带抹掉主题 `diamond_mult 1.5` | 不修 | 同上，仅跳层路径可复现 |
