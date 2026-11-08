# Sprint 17 交付 · QA 四项 Major 补强批

> 基线：`git log -1` = `bbd70fb`（纯文档批）；`md5sum -c` 34 OK / 0 FAILED；34 个 `.gd`；工作树干净。
> 依据：`production/sprint-17/SPR17_QA复核报告.md`（quality-lead，CONCERNS / 7 项阻塞）。用户裁定**先补 4 项 Major 再收官**。
> 范围：**只补证据/断言覆盖，不改任何生产功能逻辑**。QA 报告 Minor #5/#6/#7 及非阻塞观察按派单不在本批范围，见 §五。
> 实施：`engineering-lead`；主理人只读核验。落点以函数名索引，**行号以实读为准**。

---

## 一、改动总览

| 文件 | 性质 | 内容 |
|---|---|---|
| `scripts/validate.gd` | 断言（启动期） | `_check_daily()` 加 1 条**源码回读门**：`FileAccess.get_file_as_string("res://scripts/menu.gd")` → `_slice(..., "func _build_main_page()", "func build_daily_share_widgets(")` 段必须含 `build_daily_share_widgets(left)` |
| `scripts/player.gd` | 断言（探针） | `_daily_share_probe()`：7 天截尾断言升级为**验首尾 key**；新增 4 条 `qa_fix` 定向断言（`_load_daily_share` / `_copy_daily_share`）；探针 `Dev.check` 由 16 → **20** 条 |
| `production/sprint-7/SPR7-FROZEN-4.md5` | 冻结重定 | 重算 `player.gd` / `validate.gd` 两条，行数仍 34 |
| 本文件 | 交付文档 | 新增 |

**最终 `git diff --stat` 仅 `scripts/player.gd`（+63/−2）与 `scripts/validate.gd`（+8）两个脚本**；`game_main.gd` / `game_state.gd` / `menu.gd` / `assets.gd` / `data.gd` / `meta.gd` / `hud.gd` / `boss*.gd` / `toxic_cloud.gd` 的 diff **均为空** —— 负向变体已全部还原（`cmp` 逐字一致），未改生产功能逻辑。四份刚入库文档（`玩法说明.md`、`SPR17_QA复核报告.md`、`SPR17_规划草案.md`、`production/sprint-18/SPR18_设计候选实稿.md`）**零改动**。

---

## 二、四项 Major 逐条证据

### Major #1 主菜单挂接线零运行时覆盖 → 源码回读门

- **修法**（按派单推荐的「最小修法」）：`validate._check_daily()` 启动期读 `menu.gd` 源码，切出 `_build_main_page()` 函数段，断言含 `build_daily_share_widgets(left)`。照 `_check_contracts()` 的既有源码回读范式；头部 `FileAccess.get_file_as_string("res://scripts/game_main.gd")` 已在项目中实证可用。
- **为什么不做真运行时树扫描**：所有 `SMOKE_*` 探针都在 `await get_tree().create_timer(0.6, true).timeout` 后并发恢复；`show_page("main")` 会先 `queue_free()` 掉 `_rows` 全部子节点、把 `_center` 改成 FULL_RECT 并新建 `_decor`，会**抹掉 `_codex_probe` / `_oath_probe` 等挂到 `menu._rows` 的真实 Label**并改变其渲染断言语境。源码回读门零并发风险、零生产逻辑改动，且断线时**启动期即报错**。
- **负向对照**：临时删 `menu.gd` 的 `build_daily_share_widgets(left)` 一行 → `_tools/spr17_neg_menu_hook.log` 出现
  `[ERR] validate: 主菜单 _build_main_page 未挂接 build_daily_share_widgets(left)（挂接线断开）`（1 条 `[ERR]`）。
- **正向**：全量回归 `[SMOKE] validate problems=0`，源码回读门通过。

### Major #2 负向对照运行时证据 MISSING → 5 份实跑日志落盘

本批把此前「实跑得到 N 条 ERR」的措辞全部改为**有路径、有哈希、有复现命令**的证据。5 份日志均在 `_tools/`（已 gitignore，与 QA 自身 `_tools/qa_spr17_*.log` 同口径），**md5 清单**如下（可据此校验未被事后改写）：

| 日志（明确文件名） | 变体（保留在 `_backup/spr17_qa/`，gitignored） | `[ERR]` 数 | 覆盖对象 |
|---|---|---|---|
| `_tools/spr17_neg_a1a2.log` | `v_a1a2.gd` ← `game_main.gd` | **2** | 删 A1 跳层 `update_floor_sign()` + A2 空 watched 早退 |
| `_tools/spr17_neg_daily_impl.log` | `v_daily_impl.gd` ← `game_state.gd` | **11** | `daily_share_code_valid` 恒 false / 去 `cfg.save` / 去 7 天截尾（8 `daily_share` + 2 `qa_fix` + 1 `validate`） |
| `_tools/spr17_neg_menu_hook.log` | `v_menu_hook.gd` ← `menu.gd` | **1** | 删主菜单挂接线 → 源码回读门启动期报错 |
| `_tools/spr17_neg_trim.log` | `v_trim.gd` ← `game_state.gd` | **1** | 截尾方向翻转为 `out.slice(0, 7)` |
| `_tools/spr17_neg_load.log` | `v_load.gd` ← `menu.gd` | **4** | 删 headless 护栏 / 拒绝状态行 / `daily_mode` 置位 |

```
md5 清单（实跑后计算）
bf324b3bcfb912da117cd5aa0a076205  _tools/spr17_neg_a1a2.log
1041e67ec7c9db0340559cd57f616f09  _tools/spr17_neg_daily_impl.log
37acb2f2d319aeb6bcab05e1abfd2cba  _tools/spr17_neg_load.log
3797dc27cb7fd69941d9a6aeec3020fa  _tools/spr17_neg_menu_hook.log
701652db2995875d1fbb5836a4c3563f  _tools/spr17_neg_trim.log
```

**复现命令**（在 `D:/Create/Game/test-1` 下；变体文件已保留，可直接 diff 与重跑）：

```bash
G="D:/SteamLibrary/steamapps/common/Godot Engine/godot.windows.opt.tools.64.exe"
U="/c/Users/TangUser/AppData/Roaming/Godot/app_userdata/test_1"
# 以任一变体为例（其余 4 组同型，替换 V/T/E/F/L）
V=v_a1a2.gd; T=game_main.gd; L=spr17_neg_a1a2.log
F=900; E="SMOKE=1 SMOKE_SEED=4 SMOKE_OATH=1 SMOKE_FLOOR_SIGN=1 SMOKE_JUMP_FLOOR=11"
cp "_backup/spr17_qa/$V" "scripts/$T"
rm -f "$U"/_smoke_daily*.cfg
env $E "$G" --headless --path "D:/Create/Game/test-1" res://scene/game.tscn --quit-after $F > "_tools/$L" 2>&1
cp "_backup/spr17_qa/$T" "scripts/$T"          # 立即还原
grep -c '\[ERR\]' "_tools/$L"                  # 期望 >0
cmp -s "scripts/$T" "_backup/spr17_qa/$T" && echo RESTORED_OK
```

5 组全部：实跑 `[ERR]` > 0、日志落盘、**还原后 `cmp` 逐字一致**（`OK game_main.gd / game_state.gd / menu.gd / player.gd / validate.gd`），负向变体**未入库未提交**。

### Major #3 `_load_daily_share()` / `_copy_daily_share()` 零断言 → 4 条定向断言

新增于 `_daily_share_probe()` 末尾（复用 `daily_path_override` 隔离档），全部**验文本 + 验字节/状态数值**：

| # | 断言 | 验的东西 | 负向对照 |
|---|---|---|---|
| ① | 跨日码拒绝 | 构造 `20261107-<合法校验位>`（校验位合法、日期非今日）→ 状态行文本含「校验失败或非今日」+ `daily_mode` 未置位 + `FileAccess.get_file_as_bytes(p)` 前后相同 | `spr17_neg_load.log` 第 1 条 |
| ② | 篡改/垃圾码拒绝 | 状态行文本 + 未置位 + 档字节未变 + **`Game.rng.state` 未变**（`start_game()→start_run()` 会消费 rng，故状态不变即证明未启动） | `spr17_neg_load.log` 第 2 条 |
| ③ | headless 剪贴板跳过不抛错 | 调用 `_copy_daily_share()` 后仍能走到断言（未抛错）+ 源码回读 `menu.gd` 含 `if DisplayServer.get_name() == "headless":` + 档字节 / rng 状态未变 | `spr17_neg_load.log` 第 3 条（删护栏即红） |
| ④ | 合法今日码载入 | `Game.daily_mode == true` + 状态行未走拒绝分支 + 档字节未变 | `spr17_neg_load.log` 第 4 条 |

- **④ 的同 run 污染规避**：不采用「放最后让 `start_game()` 真重开一局」；改为**临时置空 `Game.main`**（实读 `game_state.gd` 为 `var main: Node2D = null`，`start_game()` 内有 `if Game.main != null and is_instance_valid(Game.main)` 守卫），同步调用后立即还原 `Game.main`、`Game.daily_mode`（先存 `bak_mode`）。整段无 `await`、无帧穿插，其它 0.6s 并发探针观察不到空窗；不重启局、不消费 rng、不新增全局可变测试缝。
- **③ 未改 `_copy_daily_share()` 签名**：为遵守「不改生产功能逻辑」，护栏存在性由源码文本回读断言保证（删护栏即红），「不抛错/无副作用」由调用 + 字节/状态数值断言保证。
- **正向证据**：`[SMOKE-QA-FIX] done cross=分享码校验失败或非今日，未载入 tamper=分享码校验失败或非今日，未载入 loaded_mode=true bytes_unchanged=true`。

### Major #4 7 天截尾只验 `size()==7` → 验首尾 key

- 构造 9 条 `20261101..20261109`，断言 `size()==7` **且** `trimmed[0].key == "20261103"` **且** `trimmed[6].key == "20261109"`。
- **负向对照**：把 `out.slice(out.size() - 7)` 改成 `out.slice(0, 7)`（保留最旧 7 条）→ `_tools/spr17_neg_trim.log` 出现
  `[ERR] daily_share: 7 天截尾保留最新 7 条（首 20261103 / 尾 20261109，非最旧 7 条）`（1 条 `[ERR]`）。`v_daily_impl.gd`（去掉截尾）亦令此断言转红。
- **语义口径（如实登记，待产品裁定）**：当前 `sanitize_daily_history()` 按**数组位置**截尾，不按日期排序、不去重同日 key；`record_daily_best()` 的 `found` 只更新首个同日条目。因此实现是「**最近 7 条结算记录**」而非「7 个不同日期」，UI 文案「近 7 日」可能显示两天同一天。**本批未改 UI 文案、未改实现**（派单明确要求不擅自改）。
- **若用户裁定改为按天去重排序**：建议在 `sanitize_daily_history()` 内按 `key` 降序排序 + 同 key 保留 `layers/time` 最优者，再截前 7；同时 `record_daily_best()` 改为按 key 定位更新并回写。这会改动 `game_state.gd` **生产逻辑**、需另派单独批次并重做四门控 —— 先回报方案由主理人转用户，**本批不实施**。

---

## 三、四门控（补强后实跑）

| 门 | 命令 / 判据 | 结果 |
|---|---|---|
| ① 全量回归 | `SMOKE=1` + 24 探针变量（含 `SMOKE_DAILY_SHARE=1`、`SMOKE_JUMP_FLOOR=11`、`SMOKE_FLOOR_SIGN=1`）`--headless --path . --quit-after 6000` → `_tools/spr17_qa_full.log` | **exit 0**；`SCRIPT ERROR\|Parse Error\|[ERR]\|启动自检失败` = **0**；`validate problems=0` = 1；编译扫描 `34/34` = 1；**12 行 done / 11 个唯一 `[SMOKE-*] done` 标记**（含新增 `[SMOKE-QA-FIX] done`） |
| ① 冻结 | `md5sum -c` / 清单行数 / 脚本数 | **34 OK / 0 FAILED**；34 行；34 脚本（无新脚本） |
| ② E6 | `git diff -U0 -- 'scripts/*.gd'` 新增行 grep `\bdelta\b`/`Timer.new`/`Tween`/`Engine.time_scale` | **零命中**；新增 `ACTION_DEFS`/`GEN_NAMES` 零；既有 `_tick_buffs`/`toxic_cloud` 豁免未动 |
| ③ E1 | 干净态 `SMOKE_META_FINGERPRINT=1` 双跑 `cmp`；附加挂 `SMOKE_DAILY_SHARE=1` 双跑 `cmp` | **E1_PASS** / **E1_SHARE_PASS**；新增 `Game.rng.rand*`/`fx_rng.rand*` 调用 **0**；`ACTION_DEFS` 实读 **18**；`assets/data/meta/game_main/menu/hud/boss*/toxic_cloud` diff 空 |
| ④ 探针门 | 5 组负向对照（§二表）+ 正向 20 条 `Dev.check` | 5 份 `_tools/spr17_neg_*.log` 分别 2/11/1/1/4 条 `[ERR]`；正向全绿 |

冻结重定条目：`player.gd 3eb8331b…→e66793bf…`、`validate.gd 0df43d91…→9fd432b7…`。

---

## 四、偏差与限制说明

1. **未做真运行时主菜单树扫描**（Major#1 取派单推荐的源码回读门）：原因见 §二.1 的 0.6s 并发探针抢 `_rows` 风险。源码回读是**静态锁挂接字符串**，不等价于「窗口内视觉走查已覆盖」；若需视觉证据，须另开带窗口截图批次（`SMOKE_MENU=1`），本批未做。
2. **负向日志位于 gitignored 的 `_tools/`**：与 QA 报告自身 `_tools/qa_spr17_*.log` 同口径，靠**明确路径 + md5 清单 + 保留的变体副本**保证可复核；未把日志塞进版本库，避免把测试产物当交付物。
3. **`Game.main = null` 隔离**是测试侧手段，利用了 `start_game()` 既有 null 守卫；**未新增任何全局可变测试缝**（QA §二.2 对 `def_override` / `daily_path_override` 的观察不适用于本手法）。同步执行、无帧穿插、立即还原；`Game.daily_mode` 由 `bak_mode` 复原。
4. **③ 的剪贴板断言**为「源码护栏文本 + 调用不抛错 + 字节/状态数值」组合；headless dummy 下 `DisplayServer.clipboard_get()` 会打印引擎 `ERROR: Clipboard is not supported`，故**不调用 `clipboard_get()`**，改用文件字节与 rng 状态做数值判定。未改 `_copy_daily_share()` 签名。
5. **「7 条 vs 7 天」语义未改**：UI 文案与实现均保持原状，作为产品裁定项登记（§二.4）；改法方案已给出但**未实施**，需主理人转用户。
6. **E1 信号仍弱**：干净态双跑仅 **1 层**指纹可比（沿用 QA 接手包门③「按共有 floor 逐字比」口径），未虚报多楼层证据。
7. **Minor #5/#6/#7 不在本批范围**（派单只补 4 项 Major）：#5 生产结算挂点 `SMOKE_DEATH=1` 定向回归、#6 断言盘点清单升级到 `bbd70fb` 并删 `Game.daily_path() == ""` 死断言、#7 done/断言/钩子计数口径统一 —— 均**未动**，留待主理人排期。本批计数如实记录：探针 `Dev.check` **20** 条、全量日志 **12** 行 done / **11** 个唯一标记、正向 env 共 **24** 个探针变量（不含 `SMOKE`/`SMOKE_SEED`），未沿用旧文档的 9/10、15、23。
8. **未改任何生产功能逻辑**：负向变体全部还原（`cmp` 逐字一致），最终 diff 只有 `validate.gd` / `player.gd` 两处断言代码。

---

## 五、备份与回滚

- 改前备份：`_backup/spr17_qa/`（5 个 `.gd` 原件、`before.md5`、冻结清单副本、`v_*.gd` 五份负向变体），目录已 gitignore。
- 回滚：`cp -a _backup/spr17_qa/{player.gd,validate.gd} scripts/` → 恢复 `_backup/spr17_qa/SPR7-FROZEN-4.md5` → 删本文件 → `md5sum -c` 回 34/34 → 重跑 §三门①。本批无新增 PNG，无需 `--headless --import`。
- 需撤销提交时 `git revert <commit>`（须用户授权）。

---

## 六、提交范围

单独提交，仅含：`scripts/player.gd`、`scripts/validate.gd`、`production/sprint-7/SPR7-FROZEN-4.md5`、本文件 `production/sprint-17/SPR17_交付_QA补强批.md`。
**不含** `_tools/` 日志、`_backup/` 变体、`玩法说明.md`、`SPR17_QA复核报告.md`、`SPR17_规划草案.md`、`production/sprint-18/`。
