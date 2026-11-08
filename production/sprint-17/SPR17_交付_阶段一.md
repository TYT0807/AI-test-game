# Sprint 17 阶段一交付（A + B）

> 基线：`git log -1` = `9b6568b`（纯文档批）/ 功能码 `2a04d4e`；`md5sum -c` 34 OK / 0 FAILED；34 个 `.gd`；工作树仅 `?? production/sprint-17/`。
> 范围按 `SPR17_规划草案.md` §三：阶段一 **A + B**，阶段二 C+D 另派单独提交。
> 实施：`engineering-lead`；主理人只读核验。所有命令本轮实跑，证据落 `_tools/spr17_*.log`（`_tools/` 已 gitignore）。
> 落点以函数名索引，**行号以实读为准**。

---

## 一、改动清单（逐项对照规格）

| 项 | 落点 | 改动 | 性质 |
|---|---|---|---|
| **A1** 跳层后层签重刷 | `game_main.gd` `start_run()` 的 `SMOKE_JUMP_FLOOR` 块 | 在 `_apply_floor_theme()` **之后**补一次 `update_floor_sign()`；同块内加 `SMOKE_FLOOR_SIGN` 门控的两条断言（层签文本含跳层主题名 / `rng.state`、`fx_rng.state` 前后相等）与一行表外探针证据 | 修缺陷 + 新增验效果型断言 |
| **A2** `oath_fulfillment()` 防御 | `game_main.gd` `oath_fulfillment()` | 新增 `(def["watched"] as Array).is_empty(): return {}` 早退；为可测性新增默认参数 `def_override := {}` | 修隐患，正常数据零行为变化 |
| **A2 断言** | `player.gd` `_oath_probe()` | 补「空 watched 返回空字典」负向断言 + 成功证据打印 | 新增验效果型断言 |
| **A3** 播报覆盖 | 仅本文 §三登记 | `FLAVOR` 走 `hud.flash_toast()` 单例 2.2s，同帧多首发现互相覆盖；改队列会引入表现层计时（E6 风险）与产品取舍 → **本批不改代码** | 产品裁定项 |
| **A4** 文档措辞 | `production/sprint-16/SPR16_交付_阶段一.md` 「还剩什么」节 | 「`hud.set_room_info()` 同通道」→「与 `set_room_info` 同容器的独立常驻只读标签 `set_floor_sign()`（hud.gd:585）」 | 纯文档 |
| **B** 断言盘点 | `scripts/validate.gd`、`scripts/player.gd` | 在 B4 / P0 门、显示名常量自比较、各 `SMOKE_*` 探针旁补 `【Sprint 17 B ...】` 分类注释；产出 `SPR17_断言盘点清单.md`（25 条：分类 / 落点 / 是否需补强 / 理由） | **只标注，不改任何断言逻辑** |
| 冻结重定 | `production/sprint-7/SPR7-FROZEN-4.md5` | 重算 `game_main.gd` / `player.gd` / `validate.gd` 三条哈希，行数仍 34 | 随批重定 |

**未改**：`hud.gd` / `assets.gd` / `data.gd` / `meta.gd` / `game_state.gd` / `boss*.gd` / `toxic_cloud.gd` 等（`git diff --stat` 已核为空）。

---

## 二、四门控证据（全部实跑）

### 门① 全量回归 6000 帧

```
env SMOKE=1 SMOKE_SEED=12345 SMOKE_V8=1 SMOKE_REBIND=1 SMOKE_RELIC_PROBE=orb_shield \
  SMOKE_SUFFIX=1 SMOKE_META=1 SMOKE_META_PERSIST=1 SMOKE_BOSS=1 SMOKE_FORCE_SOVEREIGN=1 \
  SMOKE_FORCE_SQUAD=echo_pack SMOKE_JUMP_FLOOR=11 SMOKE_DAILY=1 SMOKE_CALAMITY=1 \
  SMOKE_SHRINE=1 SMOKE_CODEX=1 SMOKE_CODEX_BOON=1 SMOKE_SIGIL_COVERAGE=1 \
  SMOKE_FORCE_THIRD_BOSS=1 SMOKE_THIRD_BOSS=1 SMOKE_OATH=1 SMOKE_ECHO_CHAIN=1 \
  SMOKE_FLOOR_SIGN=1 SMOKE_FLAVOR=1 SMOKE_META_SETTLE=1 \
  "$G" --headless --path . --quit-after 6000 > _tools/spr17_full.log 2>&1
```

| 判据 | 结果 |
|---|---|
| `exit` | **0** |
| `SCRIPT ERROR` / `Parse Error` / `[ERR]` / `启动自检失败` | **0** |
| `[SMOKE] validate problems=0` | 1 次 |
| `[INFO] validate: 脚本编译扫描 34/34 通过` | 1 次 |
| `done` 标记 | 9 个：CODEX / CODEX-BOON / FLOOR-SIGN / OATH / REBIND / SHRINE / SIGIL-COV / SUFFIX / THIRD-BOSS |
| **A1** 证据 | `[SMOKE-FLOOR-SIGN] A1: floor=11 sign=层签 · 藤蔓阻挡■ ｜ 灾祸：无 theme=藤蔓阻挡 rng_same=true fx_same=true` |
| **A2** 证据 | `[SMOKE-OATH] A2: empty_watched result_empty=true` |

定向复跑（`SMOKE=1 SMOKE_OATH=1 SMOKE_FLOOR_SIGN=1 SMOKE_JUMP_FLOOR=11`，900 帧）同样 exit 0 / 0 报错 / 两条证据齐。

### 门② E6 合规

`git diff -U0 -- 'scripts/*.gd'` 的新增行中，`\bdelta\b` / `Timer.new` / `Tween` / `Engine.time_scale` **零命中**；既有豁免 `player._tick_buffs(delta)` 与 `toxic_cloud` 敌方云未动（`git diff` 为空）。

### 门③ E1 非污染

- 双跑（干净态、不挂 `FORCE_*` / `JUMP_FLOOR`，`SMOKE_META_FINGERPRINT=1`）：1200 帧与 3000 帧各一轮，`cmp` 均 **逐字一致**（`E1_PASS` / `E1_LONG_PASS`；去 `floor=N` 归一化后亦 `NORMALIZED_PASS`）。干净态只到第 1 层，故共有可比楼层为 1 行 —— 与 `HANDOFF_QA接手包.md` 门③「按共有 floor 逐字比」口径一致，未用全量日志 diff 冒充。
- 新增行中 `Game.rng.rand*` / `fx_rng.rand*` 调用 **0**；A1 只读 `.state`（getter 不推进随机流），由 `rng_same=true fx_same=true` 自证零消费。
- `ACTION_DEFS` 实读 **18** 条（基线 18）；`assets.gd` / `data.gd` / `meta.gd` diff 为空 → `GEN_NAMES` / `UNLOCKS` / `STATS_KEYS` / `CODEX_BOONS` / `FLOOR_THEMES` / Boss `variant="boss"` 均未碰。
- `_roll_calamity()` 未移动；层签未用 `hud.banner()`。

### 门④ 探针门（断言有效性）

`Dev.check` 仅在失败时打印，故两条新断言各附一行表外成功证据。另做**负向对照**：临时副本删掉 A1 的 `update_floor_sign()` 与 A2 的空 watched 守卫后实跑，得到且仅得到两条 `[ERR]`：

```
[ERR] floor_sign: A1: 跳层后层签含第 11 层主题名（层签 · 无主题 ｜ 灾祸：无）
[ERR] oath: A2: 空 watched 返回空字典（原 cur:=999 会误判 done=true）
```

证明二者均为**验效果型**（删实现即转红），非恒过假断言。负向变体跑完立即从 `_backup/spr17_p1/gm_positive.gd` 还原，`md5sum` 前后一致（`9f639501…`），**负向变体未入库未提交**。A1 另设防假绿灯：主题为空的层（`<4`）跳过文本比对，避免 `contains("")` 恒成立。

### 冻结与工作树

`md5sum -c production/sprint-7/SPR7-FROZEN-4.md5` → **exit 0 / 34 OK / 0 FAILED**；清单 34 行、`ls scripts/*.gd | wc -l` = **34**（无新脚本）。重定条目：`player.gd 2ff9a476…→19a48445…`、`validate.gd 341fa986…→261ba3d5…`、`game_main.gd b237d681…→9f639501…`。

---

## 三、与规格的偏差说明（如实登记）

1. **A2 增加默认参数 `def_override := {}`**（规格只要求加早退守卫）。原因：`Data.OATH_CONDITIONS` 是 `const`，Godot 4.7.2 实测其**内嵌 Array 亦运行时只读**（`Array is in read-only state`），探针无法靠临时改表注入空 `watched`；不做测试缝就写不出「删守卫即红」的真负向断言。该参数默认空字典，既有全部调用（`_write_codex_replay` / `_oath_probe` 共 5 处）零参数调用，**零行为变化**；`validate` 启动期仍挡空 watched。若主理人认为不宜改函数签名，可改走「抽纯 helper」方案，但改动面更大，故本批取最小缝。
2. **A1 断言放在 `start_run()` 跳层块内**（而非探针末尾）。原因：缺陷本质是「跳层块没调 `update_floor_sign()`」，只有在该调用点同步验文本才能抓到；探针在 0.6s 后才跑且会自设 floor 语境，无法直接观测启动结果。断言由 `SMOKE_FLOOR_SIGN` + `_smoke` 双门控，生产路径零影响。
3. **新增两行 `print` 证据**（`[SMOKE-FLOOR-SIGN] A1:` / `[SMOKE-OATH] A2:`）。原因：`Dev.check` 成功不打印，无法从日志证明断言真的执行过；表外探针打印不进 E1 指纹、零 rng。
4. **B 的「必须补强」项本批只登记不改逻辑**：清单 #21–#23（三处常量自比较）标「是（下批）」，按派单「**不改任何断言逻辑**」执行；#20 的 P0 断言在注释中订正了 Sprint 15 交付文档「真差值断言」的措辞，但**未改断言本身**。
5. **A3 已登记**：`FLAVOR` 播报覆盖属产品裁定项，本批不动代码。
6. **`SMOKE_DAILY_SHARE` 未挂**：属阶段二 C，本批尚未实现，全量回归未包含该钩子；规格 §六把它写进阶段一门①，属跨阶段笔误，已按「阶段一范围」如实处理。
7. **E1 可比楼层仅 1 行**：干净态不挂 `JUMP_FLOOR` 时自动驾驶 3000 帧未进第 2 层；已按 QA 口径以共有层逐字比对，未虚报多楼层证据。

---

## 四、备份与回滚

- 改前备份：`_backup/spr17_p1/`（`game_main.gd` / `player.gd` / `validate.gd` / `hud.gd` / `SPR7-FROZEN-4.md5` / `SPR16_交付_阶段一.md` / `before.md5`），该目录已 gitignore，不污染工作树。
- 回滚：`cp -a _backup/spr17_p1/{game_main.gd,player.gd,validate.gd} scripts/` → 从同目录恢复 `production/sprint-7/SPR7-FROZEN-4.md5` 与 `SPR16_交付_阶段一.md` → 删本批两份新增 `.md` → `md5sum -c` 回到 34/34 → 重跑 §二门①。本批未新增 PNG，无需 `--headless --import`。
- 需撤销提交时 `git revert <commit>`（须用户授权）。

---

## 五、提交范围

单独提交，仅含：`scripts/game_main.gd`、`scripts/player.gd`、`scripts/validate.gd`、`production/sprint-7/SPR7-FROZEN-4.md5`、`production/sprint-16/SPR16_交付_阶段一.md`、`production/sprint-17/SPR17_断言盘点清单.md`、本文件。**不含**主理人侧 `production/sprint-17/SPR17_规划草案.md`（仍为未跟踪，留给主理人文档批）。
