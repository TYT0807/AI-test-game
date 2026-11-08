# Sprint 17 阶段二交付（C：每日分享码 + 本地榜）

> 基线：`git log -1` = `15eb9d8`（阶段一 A+B）；`md5sum -c` 34 OK / 0 FAILED；34 个 `.gd`；工作树仅 `?? production/sprint-17/SPR17_规划草案.md` 与 `?? production/sprint-18/`。
> 范围按 `SPR17_规划草案.md` §四 **C**，阶段二 D（玩法说明补 Sprint 16）由主理人自己做，**本批未改 `玩法说明.md`**。
> 实施：`engineering-lead`；主理人只读核验。所有命令本轮实跑，证据落 `_tools/spr17_p2_*.log`（`_tools/` 已 gitignore）。
> 落点以函数名索引，**行号以实读为准**。

---

## 一、改动清单

| 项 | 落点 | 内容 |
|---|---|---|
| 分享码 | `game_state.gd` `daily_share_checksum()` / `daily_share_code()` / `daily_share_code_key()` / `daily_share_code_valid()` | `YYYYMMDD-XXXXXX`（日期键 + `stable_hash("daily:"+key)` 取低 24 位的 6 位大写十六进制校验位）。纯文本、零 `Game.rng`、零计时、不联网、不新增 `ACTION_DEFS` action、不触 `GEN_NAMES` |
| SMOKE 隔离档 | `game_state.gd` `DAILY_SMOKE_PATH` / `daily_path()` / `daily_path_override` | 补齐 `SMOKE_DAILY_PATH` 覆盖 → SMOKE 下走 `user://_smoke_daily.cfg` → 默认 `user://daily.cfg` 的三级路径；`record_daily_best()` / `daily_best_today()` / `daily_history()` 全部改走 `daily_path()` |
| 本地榜 | `game_state.gd` `sanitize_daily_history()` / `daily_history()` / `daily_history_text()` / `record_daily_best()` | `daily.cfg` 的 `daily/history` 存最近 **7 天** `{key, layers, time}`；坏档经纯函数规整降级；`daily_history()` 每次重读并返回全新容器（只读派生）；`daily_history_text()` 产出「近 7 日：」显示文本 |
| 主菜单 | `menu.gd` `build_daily_share_widgets()` / `_copy_daily_share()` / `_load_daily_share()`；`_build_main_page()` 挂接 | 分享码 Label + 可粘贴 LineEdit + 「复制」「载入」按钮 + 近 7 日状态行。复用现有 Button/LineEdit/Label 与鼠标事件；headless 下 `DisplayServer.clipboard_set` 跳过（`get_name() == "headless"`，同 `_skip_confirm` 口径） |
| 启动期校验 | `validate.gd` `_check_daily()`（加入 `run()`） | 校验分享码格式/校验位/日期键/篡改拦截、4 类坏档输入降级、`DAILY_PATH` 读档返回 ≤7 条合法 Array、显示文本同源。**纯只读，不写盘** |
| 探针 | `player.gd` `_daily_share_probe()`（`SMOKE_DAILY_SHARE` 门控） | 15 条 `Dev.check`：分享码往返 + 2 条负向 / 零 rng 消费 + 同码双跑 / 榜单读写数值往返 + 更差·更优成绩 / 7 天上限 / 真实 Label 与 LineEdit 验渲染 / 坏档降级不崩 |
| 冻结重定 | `production/sprint-7/SPR7-FROZEN-4.md5` | 重算 `game_state.gd` / `menu.gd` / `player.gd` / `validate.gd` 四条，行数仍 34 |

**未改**：`game_main.gd`、`hud.gd`、`assets.gd`、`data.gd`、`meta.gd`、`boss*.gd`、`toxic_cloud.gd`、`玩法说明.md`、`SPR17_规划草案.md`、`production/sprint-18/`（`git diff --stat` 已核为空）。

### 登记三件套落实

1. **写入**：`record_daily_best()` 同节写 `history`（同日只留最优一条、新日追加、截尾 7 条）；分享码为纯派生无需写入。
2. **读档容错 + 主菜单显示**：`validate._check_daily()` 启动期校验 `daily_path()` 读档容错与「近 7 日」显示文本同源；`menu.build_daily_share_widgets()` 把分享码与榜单落到真实控件。
3. **可见效果断言**：`SMOKE_DAILY_SHARE` 全部验数值或验渲染，无「只验字段存在」绿灯（见 §二门④ 与 §三负向对照）。

---

## 二、四门控证据（全部实跑）

### 门① 全量回归 6000 帧

```
env SMOKE=1 SMOKE_SEED=12345 SMOKE_V8=1 SMOKE_REBIND=1 SMOKE_RELIC_PROBE=orb_shield \
  SMOKE_SUFFIX=1 SMOKE_META=1 SMOKE_META_PERSIST=1 SMOKE_BOSS=1 SMOKE_FORCE_SOVEREIGN=1 \
  SMOKE_FORCE_SQUAD=echo_pack SMOKE_JUMP_FLOOR=11 SMOKE_DAILY=1 SMOKE_CALAMITY=1 \
  SMOKE_SHRINE=1 SMOKE_CODEX=1 SMOKE_CODEX_BOON=1 SMOKE_SIGIL_COVERAGE=1 \
  SMOKE_FORCE_THIRD_BOSS=1 SMOKE_THIRD_BOSS=1 SMOKE_OATH=1 SMOKE_ECHO_CHAIN=1 \
  SMOKE_FLOOR_SIGN=1 SMOKE_FLAVOR=1 SMOKE_META_SETTLE=1 SMOKE_DAILY_SHARE=1 \
  "$G" --headless --path . --quit-after 6000 > _tools/spr17_p2_full.log 2>&1
```

| 判据 | 结果 |
|---|---|
| `exit` | **0** |
| `SCRIPT ERROR` / `Parse Error` / `[ERR]` / `启动自检失败` | **0** |
| `[SMOKE] validate problems=0` | 1 次 |
| `[INFO] validate: 脚本编译扫描 34/34 通过` | 1 次 |
| `done` 标记 | **10 个**（阶段一 9 个 + `[SMOKE-DAILY-SHARE] done`） |
| C 正向证据 | `[SMOKE-DAILY-SHARE] evidence code=20261108-A0F1D4 best=5层/60.0s hist=1 text=近 7 日：11/08 5层 01:00` |
| 既有 DAILY 未受影响 | `[SMOKE-DAILY] key=20261108 seed=1393530245`（与阶段一同值） |

定向复跑（`SMOKE=1 SMOKE_DAILY_SHARE=1`，900 帧）同样 exit 0 / 0 报错 / 证据齐。

### 门② E6 合规

`git diff -U0 -- 'scripts/*.gd'` 新增行中 `\bdelta\b` / `Timer.new` / `Tween` / `Engine.time_scale` **零命中**；既有豁免 `player._tick_buffs(delta)` 与 `toxic_cloud` 敌方云未动。新增的 `await get_tree().create_timer(0.6, true).timeout` 是**全部既有 `SMOKE_*` 探针共用的调度范式**（`_oath_probe` / `_floor_sign_probe` / `_codex_probe` 同款），属探针启动延迟，不是玩法计时，也不引入逐帧 delta。

### 门③ E1 非污染

- 干净态双跑（`SMOKE_META_FINGERPRINT=1`，不挂 `FORCE_*` / `JUMP_FLOOR`）：`cmp` **逐字一致**（`E1_PASS`，共有 1 层可比）。
- **附加**：挂 `SMOKE_DAILY_SHARE=1` 的双跑同样逐字一致（`E1_SHARE_PASS`），证明新探针不扰动随机流。
- 新增行 `Game.rng.rand*` / `fx_rng.rand*` 调用 **0**；探针内 `rng.state` / `fx_rng.state` 只做读取比对（getter 不推进），前后相等自证零消费。
- `ACTION_DEFS` 实读 **18** 条（基线 18）；`assets.gd` / `data.gd` / `meta.gd` / `game_main.gd` / `hud.gd` diff 为空 → `GEN_NAMES` / `UNLOCKS` / `STATS_KEYS` / `CODEX_BOONS` / `FLOOR_THEMES` / Boss `variant="boss"` / `_roll_calamity()` 均未碰。层签未用 `hud.banner()`。

### 门④ 探针门（断言有效性）

新增 15 条 `Dev.check` 全部按「验数值或验渲染」设计。因 `Dev.check` 只在失败时打印，探针附一行表外成功数值证据（见门①）。另做**负向对照**：临时副本把 `daily_share_code_valid()` 改为恒 false、`record_daily_best()` 去掉 `cfg.save`、去掉 7 天截尾后实跑，得到 **8 条 `[ERR] daily_share:`**：

```
分享码格式+校验位往返一致 / 今日最佳读回数值一致 / 本地榜历史读回 1 条且数值一致 /
较差成绩不覆盖最佳 / 更优成绩覆盖最佳 / 同日不重复追加 / 本地榜上限 7 天 /
主菜单本地榜渲染实值
```

证明这些断言不是恒过假断言。负向变体跑完立即从 `_backup/spr17_p2/gs_positive.gd` 还原，`md5sum` 前后一致（`286848c1…`），**未入库未提交**。

### 冻结与工作树

`md5sum -c production/sprint-7/SPR7-FROZEN-4.md5` → **exit 0 / 34 OK / 0 FAILED**；清单 34 行、`ls scripts/*.gd | wc -l` = **34**（无新脚本）。重定条目：`player.gd 19a48445…→3eb8331b…`、`validate.gd 261ba3d5…→0df43d91…`、`menu.gd 5517e53b…→ebea1702…`、`game_state.gd f06b07ca…→286848c1…`。

---

## 三、与规格的偏差说明（如实登记）

1. **补齐了原本缺失的 SMOKE 离档**（规格要求「沿用 `SMOKE_DAILY_*` 隔离档范式」）：实读发现原 `record_daily_best()` / `daily_best_today()` **直接写 `user://daily.cfg`，SMOKE 下会污染玩家档**，且代码里并不存在 `SMOKE_DAILY_PATH`。本批新增 `DAILY_SMOKE_PATH` + `daily_path()` 三级路径并让三处全部改走它。这是 SMOKE 路径下的行为修正（只影响落盘位置、零 rng、零 E1），玩家档路径不变。
2. **`daily_path_override` 测试缝**：与阶段一 `def_override` 同理，给 `SMOKE_DAILY_SHARE` 探针一条独立 `_smoke_daily_share.cfg`，避免与 `SMOKE_DAILY=1` 结算写入同档互相污染；探针结束复原空档并把 override 置回原值。
3. **「主菜单显示」拆成两处校验**：`validate._check_daily()` 只做纯文本同源校验（启动期不碰菜单树，避免建 UI 节点）；真实控件文本由 `SMOKE_DAILY_SHARE` 对 `Label`/`LineEdit` 节点做验渲染断言。为避开 0.6s 并发探针抢 `_rows`，`build_daily_share_widgets(parent)` 返回真实节点并支持在**脱离场景树**的容器上构建 —— 主菜单仍照常挂 `left`，探针只用独立 holder。
4. **「载入」的产品口径**：只接受「格式 + 校验位合法 **且为今日**」的码，校验失败只改状态行文本、不启动游戏、不写盘；合法码走既有 `Game.daily_mode = true` + `start_game()`，**不改 `start_run` 的 rng 顺序**。跨日期码不重放（本地功能、不联网），这是为规避「每日固定词缀」类 rng 变更做的取舍。
5. **`record_daily_best()` 现在每次结算都写盘**（原先仅 `better` 时写）：因为要同时维护 `history`。属局外结算期磁盘写入，零 rng、零计时、零 E1，且不新增脚本。
6. **分享码校验位为 6 位十六进制**（`stable_hash("daily:"+key) & 0xFFFFFF`）；`daily_share_code_valid()` 只验格式与校验位，是否今日由 UI 载入时另判 —— 这样校验函数可复用于任意日期码，也便于负向断言。
7. **探针用 `create_timer(0.6, true)` 调度**：全项目 `SMOKE_*` 探针同款，非玩法计时；E6 grep 已确认零 `Timer.new` / `Tween` / raw delta。
8. **E1 干净态只到第 1 层**（3000 帧内自动驾驶未进第 2 层），按 `HANDOFF_QA接手包.md` 门③「按共有 floor 逐字比」口径判定，未虚报多楼层证据。
9. **D 未做**：按派单由主理人自行处理，`玩法说明.md` 本批零改动；`SPR17_规划草案.md` 与 `production/sprint-18/` 亦未动、未混入提交。

---

## 四、备份与回滚

- 改前备份：`_backup/spr17_p2/`（4 个 `.gd`、`SPR7-FROZEN-4.md5`、`before.md5`；另有 `gs_positive.gd` / `gs_negative.gd` 为负向对照副本），目录已 gitignore。
- 回滚：`cp -a _backup/spr17_p2/{game_state.gd,menu.gd,player.gd,validate.gd} scripts/` → 恢复 `production/sprint-7/SPR7-FROZEN-4.md5` → 删本批 `SPR17_交付_阶段二.md` → `md5sum -c` 回 34/34 → 重跑 §二门①。本批未新增 PNG，无需 `--headless --import`。
- 需撤销提交时 `git revert <commit>`（须用户授权）。

---

## 五、提交范围

单独提交，仅含：`scripts/game_state.gd`、`scripts/menu.gd`、`scripts/player.gd`、`scripts/validate.gd`、`production/sprint-7/SPR7-FROZEN-4.md5`、本文件。**不含** `玩法说明.md`、`SPR17_规划草案.md`、`production/sprint-18/`。
