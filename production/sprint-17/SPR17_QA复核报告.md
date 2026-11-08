# Sprint 17 整批独立 QA 复核报告（quality-lead · 第二层复核）

> **判定：CONCERNS**。四门控**独立复跑全部 PASS**，代码静态实读**未发现生产路径功能缺陷**；CONCERNS 来自**证据链与测试覆盖缺口**（7 项，4 Major / 3 Minor），不是「项目被改坏」。
> 基线实校：`git log -1` = `7c7dd02`（阶段一 `15eb9d8`）；`md5sum -c` **34 OK / 0 FAILED**；冻结清单 34 行；`ls scripts/*.gd | wc -l` = **34**。
> 复核方式：只读。独立重跑 headless 6000 帧 + E1 干净态双跑 + E6/E1 静态 diff 扫描 + 全项目 `scripts/` 挂接点精确检索。**本次仅新增** `_tools/qa_spr17_*.log/.fp`（gitignored）与本文件；**未修改任何既有文件**（`.gd` / `.md` / 冻结清单 / 提交）。工作树中的 `M 玩法说明.md` 为复核开始前既有状态（主理人 D 文档），非本次产生。
> 质量门为 **advisory**：本报告给判定与阻塞项，放行签字归用户；下文「阻塞项」指**在给出 PASS 前须补齐或明确登记**的项，不表示代码已坏。

---

## 一、四门控独立复跑（与交付文档分开取证）

| 门 | 独立命令 / 判据 | 实测结果 | 判定 |
|-|-|-|-|
| ① 回归纪律 | `SMOKE=1` + 26 个 env（含 `SMOKE_DAILY_SHARE=1`、`SMOKE_JUMP_FLOOR=11`、`SMOKE_FLOOR_SIGN=1`）`--headless --path . --quit-after 6000` → `_tools/qa_spr17_full.log` | **exit 0**；`SCRIPT ERROR\|Parse Error\|[ERR]\|启动自检失败` = **0**；`[SMOKE] validate problems=0` = 1；`[INFO] validate: 脚本编译扫描 34/34 通过` = 1；**11 条 done**；A1/A2/DAILY-SHARE 三条证据落地 | **PASS** |
| ① 冻结 | `md5sum -c` / `wc -l` 清单 / `ls scripts/*.gd \| wc -l` | **34 OK / 0 FAILED** / 34 行 / 34 脚本 | **PASS** |
| ② E6 | `git diff -U0 9b6568b..7c7dd02 -- 'scripts/*.gd' \| grep -E '^\+[^+]' \| grep -nE '\bdelta\b\|Timer\.new\|Tween\|Engine\.time_scale'` | **零命中**；新增行 `FIXED_DT` = 0（零新增计时）；新增 `Game.rng.rand*`/`fx_rng.rand*` = **0** | **PASS** |
| ③ E1 | 清隔离档后 `SMOKE=1 SMOKE_SEED=12345 SMOKE_META_FINGERPRINT=1 SMOKE_DAILY_SHARE=1` 双跑 1800 帧，`grep fingerprint` 后 `cmp -s` | **E1_PASS**（`_tools/qa_spr17_e1_{1,2}.fp` 各 1 行、逐字一致）；两轮报错各 0；`ACTION_DEFS` 实读 **18**；`assets.gd`/`data.gd`/`meta.gd` diff 空 | **PASS（信号弱，见 §六）** |
| ④ 探针门 | `[ERR]` 计数 / `done` 落地 / 断言性质 | `[ERR]` = 0；`[SMOKE-DAILY-SHARE] done` 落地；但**部分断言覆盖线偏移、部分为自派生恒过**（见 §三、§四） | **CONCERNS** |

`git diff --stat 9b6568b..7c7dd02`：10 文件、+645/−14，改动落在 `game_main.gd` / `game_state.gd` / `menu.gd` / `player.gd` / `validate.gd` + 冻结清单 + 交付文档，与两批声称的提交范围一致。
工作树现状：`M 玩法说明.md`（D 文档，主理人职权）、`?? production/sprint-17/SPR17_规划草案.md`、`?? production/sprint-18/` —— 与两批 commit 范围不冲突，但**当前工作树不干净**，任何「工作树干净」表述须带此时点说明。

---

## 二、逐项复核结论（7 个重点）

### 1. 四门控 → **PASS**（见 §一）
独立重跑未复用交付日志，结论与两批报告一致；E6 用整批基线 `9b6568b..7c7dd02`（覆盖两阶段）而非单批 diff，避免漏掉跨阶段新增行。

### 2. 两处规格外测试缝 → **PASS（附观察）**
- `oath_fulfillment(def_override: Dictionary = {})`（`game_main.gd:2132`）：默认 `{}` → `def = Data.OATH_CONDITIONS.get(equipped, {})`（`:2134`），与改前等价。全项目精确检索共 6 处调用，其中 **5 处非探针调用全部零参数**：`game_main.gd:2175`、`player.gd:1114/1118/1122/1144`；唯一带参的是探针 `player.gd:1127` 的 `empty_watched`。✅
- `daily_path_override := ""`（`game_state.gd:416`）：唯一 setter 在探针 `player.gd:1229/1230/1305`（取原值→设→还原），生产路径无 setter，默认空串等价于「不覆盖」。✅
- 观察（非阻塞）：两缝均为**公开可变全局/签名**，`def_override` 非空即完全绕开 `OATH_CONDITIONS`，`daily_path_override` 非空即**优先级高于 SMOKE 隔离**（`game_state.gd:420` 先于 `:422/:425`）；探针无 `try/finally`，中途异常会泄漏 override 并重定向此后所有 daily 读写。建议下批收窄为 `_smoke_*` 门控。

### 3. SMOKE 隔离档是否真闭环 → **PASS（口径需订正）**
- `daily_path()`（`game_state.gd:419–427`）实为 **4 分支**：`daily_path_override` > `SMOKE_DAILY_PATH` env > SMOKE 默认 `user://_smoke_daily.cfg` > 非 SMOKE `user://daily.cfg`。交付文档称「三级路径」未计 override 测试缝，属**口径不精确**，非缺陷。
- 全项目 `scripts/` 精确检索 `user://daily.cfg` 仅出现在 `game_state.gd:409` 注释与 `:412` 常量定义；**实际 `ConfigFile.load/save` 共 4 处**（`:503` `daily_history()`、`:524`/`:548` `record_daily_best()`、`:553` `daily_best_today()`）**全部**走 `daily_path()`；`daily_history_text()`（`:508`）、`validate._check_daily()`（`validate.gd:271`）、`menu.gd:131/179`、`game_main.gd:2377` 的读写链路同样经它。无旁路。✅
- 非 SMOKE 下玩家档路径不变；SMOKE 下不再写 `user://daily.cfg`。✅ 闭环成立。

### 4. 「验渲染」是否覆盖真实挂接线 → **INCOMPLETE（Major，阻塞项 #1）**
- 真实挂接：`menu.gd:140 build_daily_share_widgets(left)` 位于 `_build_main_page()`（`:79`）内。
- 探针 `player.gd:1276` 用**脱离场景树的独立 `VBoxContainer` holder** 直调 `Game.main.menu.build_daily_share_widgets(holder)`，只验函数返回的 Label/LineEdit 文本。
- 实读 `menu.gd:64–73`：**SMOKE 且未设 `SMOKE_MENU` 时执行 `show_page("")`**，`_build_main_page()`（`:326` 才调用）在全部门控中**从未执行**；全量回归 env 未带 `SMOKE_MENU`（日志计数 0）。`_tools/` 下亦无主菜单截图或手工视觉证据。
- **结论**：断言对「函数能否产出正确文本」是**有效验效果型**；但对规格 §4.1 三件套②「主菜单显示」**零覆盖**。删掉 `menu.gd:140` 一行，四门控与 16 条探针断言**仍全绿**。这是明确的「挂接线断了探针仍绿」缺口，按证据评审口径判 `INCOMPLETE`。
- 最小补强（不要求本批实施）：① 比照 `validate._check_registration()` 的源码回读范式，在 `_check_daily()` 加一条「`_build_main_page()` 段含 `build_daily_share_widgets(`」的源码级断言；或 ② 探针内 `show_page("main")` 后递归扫描真实 `_rows` 找 share Label。二者均不改生产逻辑。

### 5. 断言有效性 / 25 条盘点 → **#21–#23 裁定可接受；阶段二存在清单版本滞后**
- 三处定位**准确、无漏标**：`player.gd:965–966`（`CODEX_BOSS_NAMES[...] == "棱镜守望者"/"熔潮主宰"`）、`player.gd:1083`（`== "玄渊之主"`）、`player.gd:1041`（`Game.codex_boons() == Game.codex_boons()`，**字面自比较**）。#20 是**另一条** `player.gd:1058`（`== boons_before`，apply 前后），归「前提守卫型恒过」亦正确，二者非重复。
- #24 把 `codex_bosses_total() == 7` 判为「表一致性门，不归入需补强」**正确**：`ENEMIES`/`CODEX_BOSS_NAMES` 扩表会转红，属有效守门。
- **裁定**：按派单「不改断言逻辑」把 #21–#23 只登记为下批补强，**可接受**，且未发现「冒充验效果型」的措辞。条件：下批必须给出补强落点与负向证明（如「菜单图鉴页显示名渲染扫描」「改档前后差值」），不能无限期挂账。
- **但有版本滞后（阻塞项 #6）**：盘点清单基线 `2a04d4e` 早于阶段二，`validate._check_daily()`（`validate.gd:271–298`）新增的 12 项检查中**至少 5 项自派生恒过/不可达**未纳入 25 条：`code.begins_with(daily_key()+"-")`、`daily_share_code_valid(code)`、`daily_share_code_key(code) != daily_key()`、`daily_history_text()` 恒以前缀开头（且 `shown.is_empty()` 分支不可达）、**`Game.daily_path() == ""` 为不可达死断言**（`daily_path()` 四个分支均返回非空常量/覆盖值）。探针 `player.gd:1237/1239` 亦为同型自派生恒过。若把「25 条」宣称为全批断言全集，属**漏标**；建议下批把清单升级到 `7c7dd02` 并逐条标注性质。
- 因此「新增断言全部验效果型」的措辞**不严谨**：`_check_daily()` 中真正验效果型的是 4 类坏档负向注入与 `valid(code+"0")` 篡改拦截，其余多为前提守卫型/死断言。

### 6. 负向对照证据缺口 → **Major（阻塞项 #2）：静态可证变异敏感性，不可证实跑**
- 静态可证：`_backup/spr17_p1/gm_negative.gd` vs `gm_positive.gd` 精确 diff 仅 2 处（`update_floor_sign()` 一行、空 watched 早退两行）→ 对应 A1 `jtext.contains(theme name)` 与 A2 `empty_res.is_empty()` 必然转红，与文档所列 2 条 `[ERR]` 标签逐条对应。`_backup/spr17_p2/gs_negative.gd` vs `gs_positive.gd` 精确 diff 3 处（`daily_share_code_valid` 恒 false、去掉 7 天截尾、去掉 `cfg.save`）→ 命中探针 ①/③/④/⑤ 组，静态推得约 8 条 `[ERR] daily_share:`，与文档「8 条」量级自洽。**逻辑上这些断言确属验效果型（删实现即红）**。
- 但**运行时证据 MISSING**：对 10 份 `_tools/spr17*.log` 精确检索 `[ERR]` **全部为 0**（全项目仅 `_tools/playtest_fault.log` / `playtest_fix_fault.log` 两份 Sprint 3 遗留日志含 `[ERR]`）。文档引用的 `[ERR]` 文案含运行期实值（「层签 · 无主题 ｜ 灾祸：无」），只可能来自实跑 → 更可能是「跑了未留档」，但 QA 只认证据不认推测。
- 定级：**Major 证据链断裂**，不影响功能正确性判定，但**阻断「负向对照已实跑」这一声称**。要求：下批补跑并保留 `_tools/spr17_neg_*.log`，或把交付文档措辞改为「静态变异敏感性分析（未留运行日志）」，二者择一，不得维持现状。

### 7. 边界与错误路径 → **部分覆盖（阻塞项 #3 / #4）**

| 场景 | 覆盖 | 实读结论 |
|-|-|-|
| 分享码篡改 | ✅ | `player.gd:1240` `not valid(code+"0")`；`validate.gd:277` 同型 |
| 非法格式 | ✅ | `player.gd:1241` `not valid("garbage")` |
| 坏档 4 类降级 | ✅ | `validate.gd:282–285` 四种输入 + `player.gd:1293–1301` 三条坏档断言 |
| 7 天截尾 | ⚠️ | `player.gd:1272` **只验 `size()==7`**，未验保留的是哪 7 条；把 `out.slice(out.size()-7)` 改成 `out.slice(0,7)`（留最旧 7 条）断言**仍绿** |
| 同日不重复追加 | ✅ | `player.gd:1266` `daily_history().size()==1` |
| 跨日码 | ❌ | `daily_share_code_valid()` 按设计**接受**任意日期的合法校验码；拒跨日靠 `menu.gd:216` `_load_daily_share()`，而该函数**无任一断言调用** |
| 校验失败不启动/不写盘 | ❌ | `menu.gd:215–220` 仅静态可读；无断言覆盖「失败只改状态行、不 `start_game()`、不写盘」 |
| 合法码载入启动 | ❌ | `menu.gd:220 start_game()` 无断言 |
| headless 剪贴板跳过 | ❌ | `menu.gd:207–210` `_copy_daily_share()` 只被按钮 `pressed` 连接（`:193`），探针从不触发 |
| `daily_path` 生产写入挂点 | ❌ | `game_main.gd:2377 Game.record_daily_best(...)` 在 6000 帧回归中**零执行**（日志无 `settle`；`SMOKE_META_SETTLE=1` 因 `_immortal` 无死亡而空转），仅探针直调函数覆盖 |

补充语义缺口：`sanitize_daily_history()`（`game_state.gd:480–499`）按**数组位置**截尾、不按日期排序、不去重同日 key；`record_daily_best()` 的 `found` 只更新首个同日条目。因此规格「最近 N **天**」实为「最近 N **条**」，篡改档含重复同日条目时会显示两天同一天。另该函数对 `layers/time` 用 `int()/float()` **强制钳制**而非拒绝（文档称「只收…非负」），坏档不崩但措辞略有出入。

---

## 三、阻塞项清单（给出 PASS 前须补齐或明确登记）

| # | 级别 | 项 | 最小动作 |
|-|-|-|-|
| 1 | **Major** | `menu.gd:140` 主菜单挂接线零运行时覆盖；探针用脱离树 holder 直调函数，断线仍全绿（§二.4） | 补源码回读断言或真实主菜单树扫描；或明确登记「主菜单显示仅静态核验」为已知限制 |
| 2 | **Major** | 负向对照运行时证据 MISSING，10 份 spr17 日志 `[ERR]` 全 0（§二.6） | 补跑留 `_tools/spr17_neg_*.log`，或改称「静态变异敏感性分析」 |
| 3 | **Major** | `_load_daily_share()` / `_copy_daily_share()` 零断言：跨日码、校验失败不启动不写盘、headless 剪贴板跳过、合法码载入（§二.7） | 补 4 条定向断言（可复用 `daily_path_override` 隔离档，验「状态行文本变化 + `start_game` 未调用 + 档未变」） |
| 4 | **Major** | 7 天截尾只验 `size()==7` 不验内容/顺序；语义为「7 条」非「7 天」（§二.7） | 断言首尾 key（如须含最新日、不含最旧日）；明确去重/排序口径 |
| 5 | Minor | `game_main.gd:2377 → record_daily_best()` 生产结算挂点零运行时覆盖（§二.7） | 补一轮带 `SMOKE_DEATH=1 SMOKE_META_SETTLE=1` 的定向结算回归 |
| 6 | Minor | 阶段二新增 ≥5 条自派生恒过/不可达死断言未纳入 25 条盘点，清单版本滞后（§二.5） | 清单升级到 `7c7dd02`，逐条标性质；删或改写 `Game.daily_path() == ""` 死断言 |
| 7 | Minor | 交付文档计数口径与实读不符：done 称 9/10，日志实为 **10/11**（多 `[SMOKE-SIGIL] persist selftest done`）；探针断言称 15，实读 **16** 条 `Dev.check`；钩子称 23，实挂 **24** 个探针变量（不含 `SMOKE`/`SEED`） | 统一计数规则并订正，避免「凡标 ✓ 附证据」纪律失守 |

### 证据索引（重试复核实校，逐项可复现）

| # | 证据路径 / 精确检索 | 实校结果 |
|-|-|-|
| 1 | `menu.gd:140`、`:79`、`:64–73`、`:326`；`player.gd:1275–1276`；`grep -c 'SMOKE_MENU' _tools/qa_spr17_full.log` | `0` → `_build_main_page()` 全门控未执行；`_tools/*.png` 无主菜单截图 |
| 2 | `for f in _tools/spr17*.log; do grep -cF '[ERR]' "$f"; done`；`diff _backup/spr17_p1/gm_negative.gd _backup/spr17_p1/gm_positive.gd`；`diff _backup/spr17_p2/gs_negative.gd _backup/spr17_p2/gs_positive.gd` | 10 份日志 `[ERR]` **全 0**；负向变体 diff 分别 2 处 / 3 处 → 静态可证变异敏感性，运行时证据 MISSING |
| 3 | `grep -rn '_load_daily_share\|_copy_daily_share' scripts/`；`menu.gd:193/199/207/215/220` | 仅按钮连接与函数定义，**无任一 `Dev.check` 调用**；`menu.gd` 其余 `Dev.check`（`:594+`）全属 rebind 自测，与载入路径无关 |
| 4 | `player.gd:1272`；`game_state.gd:496`、`:546` | 断言只比 `size()==7`；两处 `slice(size-7)` 改成 `slice(0,7)` 断言仍绿 |
| 5 | `game_main.gd:2377`；`grep -c 'settle' _tools/qa_spr17_full.log` | `0` → 结算挂点零执行，`SMOKE_META_SETTLE=1` 空转 |
| 6 | `production/sprint-17/SPR17_断言盘点清单.md:3`（基线 `2a04d4e`）+ `grep -c '^\| [0-9]'` = **25**；`validate.gd:271–298`、`:297` | 清单早于阶段二；`Game.daily_path() == ""` 为不可达死断言 |
| 7 | `grep -c 'done' _tools/spr17_full.log` = **10**、`_tools/spr17_p2_full.log` = **11**；`sed -n '/func _daily_share_probe/,/func _nearest_enemy/p' scripts/player.gd \| grep -c '^\s*Dev.check'` = **16**；交付文档 §二门① 记 9/10、§一记 15 条、commit 记 23 钩子 | 三处计数均与实读不符 |

---

## 四、非阻塞观察（登记即可）

- **E1 信号弱**：干净态双跑仅 **1 层**指纹可比（两批已如实登记），只覆盖第 1 层地图生成；后续层 rng 漂移不在证据内。因整批新增行零 `rng.rand*`（§一门②），可接受，但 commit message「E1 双跑逐字一致」宜加「共 1 层」限定。
- `SMOKE_META_SETTLE=1` 在本次全量回归中**空转**（`_immortal` 无死亡 → 无 `settle`），与 `HANDOFF_QA接手包.md` 门①「全量回归刻意不设」的口径有出入；不影响结果，但不能据此声称结算链路已验。
- 测试缝健壮性：探针 `daily_path_override` 无 `try/finally`；0.6s 窗口内若有并发结算，写入会落进 `_smoke_daily_share.cfg` 再被 `restore.save(p)` 抹除，可能掩盖生产缺陷（§二.2）。
- `daily_path()` 实为 4 分支，文档「三级路径」未计 override（§二.3）。
- 工作树 `M 玩法说明.md` 为 D 文档（主理人职权），与两批提交范围不冲突；但冻结/回归结论须注明时点。

---

## 五、判定与权责边界

**质量门：CONCERNS**（四门控 PASS / 功能静态实读无缺陷 / 证据与覆盖 7 项缺口）。不建议据现有证据写「整批 final PASS 且验收完备」；也不构成 FAIL——无需返工或回滚。

**quality-lead 可独立承担**：本报告的门控复跑、断言四类判定、证据评审（`ADEQUATE/INCOMPLETE/MISSING`）、阻塞项定级、复测设计。
**必须回交主理人 / 用户裁定**：是否带 CONCERNS 放行；7 项阻塞项的补强排期与 `.gd` 改动授权（QA 不写产品代码）；`SPR17_断言盘点清单.md` 升级与交付文档措辞订正的授权；`玩法说明.md` / 规划草案 / `production/sprint-18/` 的入库提交；「最近 7 天」语义口径（按天去重排序 or 按条）的产品裁定；质量门由 advisory 升为 blocking。

---

## 六、复现命令（本次独立取证）

```bash
cd "D:/Create/Game/test-1"; G="D:/SteamLibrary/steamapps/common/Godot Engine/godot.windows.opt.tools.64.exe"; U="/c/Users/TangUser/AppData/Roaming/Godot/app_userdata/test_1"
# 门①
env SMOKE=1 SMOKE_SEED=12345 SMOKE_V8=1 SMOKE_REBIND=1 SMOKE_RELIC_PROBE=orb_shield SMOKE_SUFFIX=1 SMOKE_META=1 SMOKE_META_PERSIST=1 SMOKE_BOSS=1 SMOKE_FORCE_SOVEREIGN=1 SMOKE_FORCE_SQUAD=echo_pack SMOKE_JUMP_FLOOR=11 SMOKE_DAILY=1 SMOKE_CALAMITY=1 SMOKE_SHRINE=1 SMOKE_CODEX=1 SMOKE_CODEX_BOON=1 SMOKE_SIGIL_COVERAGE=1 SMOKE_FORCE_THIRD_BOSS=1 SMOKE_THIRD_BOSS=1 SMOKE_OATH=1 SMOKE_ECHO_CHAIN=1 SMOKE_FLOOR_SIGN=1 SMOKE_FLAVOR=1 SMOKE_META_SETTLE=1 SMOKE_DAILY_SHARE=1 "$G" --headless --path . --quit-after 6000 > _tools/qa_spr17_full.log 2>&1
grep -cE 'SCRIPT ERROR|Parse Error|\[ERR\]|启动自检失败' _tools/qa_spr17_full.log   # 0
# 门②
git diff -U0 9b6568b..7c7dd02 -- 'scripts/*.gd' | grep -E '^\+[^+]' | grep -nE '\bdelta\b|Timer\.new|Tween|Engine\.time_scale'   # 零命中
# 门③
for R in 1 2; do rm -f "$U"/_smoke_daily*.cfg "$U"/_smoke_meta*.cfg; env SMOKE=1 SMOKE_SEED=12345 SMOKE_META_FINGERPRINT=1 SMOKE_DAILY_SHARE=1 "$G" --headless --path . --quit-after 1800 > _tools/qa_spr17_e1_$R.log 2>&1; grep -F '[SMOKE-META] fingerprint' _tools/qa_spr17_e1_$R.log > _tools/qa_spr17_e1_$R.fp; done
cmp -s _tools/qa_spr17_e1_1.fp _tools/qa_spr17_e1_2.fp && echo E1_PASS || echo E1_FAIL
# 冻结 / 负向证据核查
md5sum -c production/sprint-7/SPR7-FROZEN-4.md5; grep -lF '[ERR]' _tools/spr17*.log   # 无输出
```
