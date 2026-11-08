# QA 接手包 · Sprint 15 后验收门控
> 基线（本轮实校）：`D:\Create\Game\test-1` / Godot 4.7.2 / 单场景 / git `dbdb938` / `ls scripts/*.gd | wc -l` = **34** / `md5sum -c` **34 OK、0 FAILED** / `git status --short` 干净。
> 用途：断开后任何接手方按本文独立判定「改动有没有把项目弄坏」。本文**未修改任何既有文件**；行号基于 `dbdb938` 实读，改动前须重新实读。引擎 `G="D:/SteamLibrary/steamapps/common/Godot Engine/godot.windows.opt.tools.64.exe"`（已确认存在）；日志落 `_tools/`，判定只认日志。质量门为 **advisory**，放行签字归用户。

## 0. 共用前奏（每轮必做）
```bash
cd "D:/Create/Game/test-1"; G="D:/SteamLibrary/steamapps/common/Godot Engine/godot.windows.opt.tools.64.exe"; BASE=dbdb938; U="/c/Users/TangUser/AppData/Roaming/Godot/app_userdata/test_1"
rm -f "$U"/_smoke_*.cfg "$U"/_smoke_*.cfg.bak   # 坑 50：隔离档跨 run 累积发现度会改 boon，污染可比性
```

## 1. 四门控：执行细则、确切命令、FAIL 判据
### 门① 回归纪律（6000 帧 0 报错 + 冻结重定）
```bash
env SMOKE=1 SMOKE_SEED=12345 SMOKE_V8=1 SMOKE_REBIND=1 SMOKE_RELIC_PROBE=orb_shield SMOKE_SUFFIX=1 SMOKE_META=1 SMOKE_META_PERSIST=1 SMOKE_BOSS=1 SMOKE_FORCE_SOVEREIGN=1 SMOKE_FORCE_SQUAD=echo_pack SMOKE_JUMP_FLOOR=11 SMOKE_DAILY=1 SMOKE_CALAMITY=1 SMOKE_SHRINE=1 SMOKE_CODEX=1 SMOKE_CODEX_BOON=1 SMOKE_SIGIL_COVERAGE=1 SMOKE_FORCE_THIRD_BOSS=1 SMOKE_THIRD_BOSS=1 "$G" --headless --path . --quit-after 6000 > _tools/qa_full.log 2>&1
grep -cE 'SCRIPT ERROR|Parse Error|\[ERR\]|启动自检失败' _tools/qa_full.log; grep -cF '[SMOKE] validate problems=0' _tools/qa_full.log   # 期望 0 / >=1
md5sum -c production/sprint-7/SPR7-FROZEN-4.md5; ls scripts/*.gd | wc -l; git status --short
```
**FAIL**：任一报错命中；`problems=0` 缺失；`-c` exit≠0 或 FAILED≠0；脚本数 ≠ 清单行数（新脚本须同步加行并重定）；工作树有未说明文件；超时/未落日志记 `UNEXECUTED` 不记 PASS。改过 `.gd` 须**先重定冻结清单**（重算变动条目 md5）再跑 `-c`，否则整门无效。

### 门② E6 合规（grep 零新增 raw delta）
```bash
git diff -U0 $BASE..HEAD -- 'scripts/*.gd' | grep -E '^\+[^+]' | grep -nE '\bdelta\b' > _tools/qa_e6.txt
git diff -U0 $BASE..HEAD -- 'scripts/*.gd' | grep -E '^\+[^+]' | grep -c 'FIXED_DT'   # 新增计时须走此钟
```
**FAIL**：`qa_e6.txt` 含**新增计时行**（`+= delta` / `-= delta` / `_t -= delta` / `* delta` / 新 `_process` 计时），或新增计时未用 `Game.FIXED_DT`。**既有豁免**（不算新增、勿误判）：`player.gd:1224 _buffs[id].t -= delta`（`_tick_buffs` 通道，调用点 `:252`）、`toxic_cloud.gd` 敌方云 raw delta（grandfather）。物理位移用 delta 正常，但须逐行确认不是计时。

### 门③ E1 非污染（双跑指纹逐字一致 + ACTION_DEFS 零新增）
```bash
for R in 1 2; do rm -f "$U"/_smoke_*.cfg; env SMOKE=1 SMOKE_SEED=12345 SMOKE_META_FINGERPRINT=1 "$G" --headless --path . --quit-after 1200 > _tools/qa_e1_$R.log 2>&1; grep -F '[SMOKE-META] fingerprint' _tools/qa_e1_$R.log > _tools/qa_e1_$R.fp; done
cmp -s _tools/qa_e1_1.fp _tools/qa_e1_2.fp && echo E1_PASS || echo E1_FAIL
git diff -U0 $BASE..HEAD -- scripts/assets.gd | grep -E '^\+[^+]' | grep -E '"[a-z0-9_]+":[[:space:]]*\{"name"'
sed -n '/^const ACTION_DEFS/,/^}/p' scripts/assets.gd | grep -cE '^\s*"[a-z0-9_]+"'   # 基线 18
```
**FAIL**：`E1_FAIL`；双跑不同帧数/env/seed（数据作废）；楼层数不等时按**共有 floor 逐字比**（坑 45，禁全量日志 diff 判 PASS）；上条 diff/grep 有输出或计数 ≠18；新增资源未同步 `GEN_NAMES`（坑 5，静默白框）。`FORCE_*` / `JUMP_FLOOR` 改随机流，**E1 双跑必须干净态**，不得挂这些钩。

### 门④ 探针门（断言 + [ERR] + done 落地）
```bash
L=_tools/qa_full.log; grep -cE 'SCRIPT ERROR|Parse Error|\[ERR\]|启动自检失败' "$L"
for s in '[SMOKE-REBIND] done' '[SMOKE-SUFFIX] done' '[SMOKE-SIGIL] persist selftest done' '[SMOKE-SIGIL-COV] done' '[SMOKE-SHRINE] done' '[SMOKE-CODEX] done' '[SMOKE-CODEX-BOON] done' '[SMOKE-THIRD-BOSS] done'; do grep -qF "$s" "$L" || echo "MISSING $s"; done
```
`Dev.check` 失败时 `dev_log.gd` 打印 `[ERR] tag: msg`（仅 SMOKE 下）且不中断，故 `[ERR]` 必须清零。**FAIL**：任一 `MISSING`、任一 `[ERR]`、或断言经 §2 判为「只验标志不验数值 / 常量自比较」却标 ✓。历史：S15 阶段二全量记 **7 done**，本表列 8 条候选；差异先核对本轮是否挂 `SMOKE_META_PERSIST`，缺哪条都要写明原因，不得默认忽略。

## 2. 断言有效性判定标准（连续五轮踩坑根因）
根因：**「断言绿」被当成「效果已验证」，从不问「把实现改坏，这条会不会变红」**。凡标 ✓ 必须附本轮实读行号 + 一条反证（负向注入或 mutation）。

| 类别 | 定义 / 识别 | 可接受 | 必须补强 |
|-|-|-|-|
| **验效果型** | 两侧来自不同时点/来源，中间经过被测函数；观测实值（数值、集合内容） | 默认要求，唯一可作「功能 PASS」证据 | 只靠人眼看日志却无断言时，补断言 |
| **前提守卫型恒过** | 当前数据使条件恒真，表/时序被放宽时才报错（`validate.gd:219–221` B4、`:244–249` P0 门） | 必须**注释+交付文档标明「前提守卫型、当前恒过」**、写清触发条件，且有另一条验效果型断言或启动期门覆盖同一风险 | 若它是该风险**唯一**防线且无负向注入证明能变红 → 补负向测试；**严禁**写成「真差值 / 非恒过」 |
| **常量自比较** | 两侧同源或恒等（`player.gd:1048–1049` 一类），永远绿、无守卫价值 | 仅作占位打印并显式标「非断言」 | 一律删除或改写为验效果型；不得计入断言数 |
| **只验标志不验数值** | 只验 `has(key)` / `size()` / 布尔置位，未验倍率·伤害·时长实值（`player.gd:827` / `:829`） | 标志本身即契约（登记 id、集合成员）且数值由**另一条**断言覆盖 | 标志对应的就是效果时，补实值断言（`is_equal_approx`）；否则等于没测 |

反证模板：临时把被测分支改坏或注入违规数据 → 断言必须变红 → 还原。变不红即判 `INCOMPLETE`，不是 PASS。

## 3. 在册 5 条观察 · 各一条最小复测/订正建议（不要求现在实施）
| # | 最小动作 |
|-|-|
| ① 声明与效果不符 | 订正 `SPR15_交付_阶段一.md:10`：改称「前提守卫型断言 + `validate.gd:244–249` 启动期门」，删「不是恒过型」。**复测**：副本里把 `CODEX_BOONS` 任一 `kind` 临时改 `"suffixes"` → 自检须出现 `启动自检失败` 且含 P0 红线文案 → 还原；不变红即门失效 |
| ② 限时 buff 只验标志 | 在 `player.gd:827` / `:829` 后补 `is_equal_approx(speed_mult, speed_base * 1.25)` / `is_equal_approx(damage_mult, 1.3)`（注意 `_tick_buffs` 每帧重算基线）。**复测**：临时摘掉 `match "book"` 分支，新断言必须变红 |
| ③ `_tick_buffs` raw delta | 二选一登记：统一 `Game.FIXED_DT`，或明文登记为既有豁免。**复测**：120s / 90s buff 在两种帧率下比较到期帧数与 `FIXED_DT` 期望；偏差写入已知限制，勿 silently 放过 |
| ④ 探针直调副作用 | 交付文档登记 `player.gd:1053–1059` 直调 `on_slug_killed` 会 +2000 分 / 掉 8 次源石 / 消费一次 rng。**复测**：定向探针单跑前后打印 score/shards/codex 落盘，确认差异可解释；禁止把定向档当基线 |
| ⑤ 两门当前恒过 | 注释与文档标注「前提守卫型，当前恒过」并给负向注入：① 的 suffixes、`B4` 把 shrine 房强制设 `Vector2i.ZERO` → 自检须各出对应 `problems` 文案 |

## 4. 全量 SMOKE 钩子清单与含义速查（env 名均经 `scripts/` 实读）
| 钩子（交接稿简称） | 环境变量 | 取值 | 含义 / 易错点 |
|-|-|-|-|
| 主钩 / 种子 | `SMOKE` / `SMOKE_SEED` | `1` / 整数 | 总闸（不开则探针全不生效）；双跑必须同 seed |
| V8 / REBIND | `SMOKE_V8` / `SMOKE_REBIND` | `1` | 启动期池校验 / 按键重绑往返（落 `[SMOKE-REBIND] done`） |
| RELIC | `SMOKE_RELIC_PROBE` | **遗物 id**，如 `orb_shield` | 等敌情后单次激活；**吃 id 不是布尔**，无效 id 打印 `unknown id` 直接返回 |
| SUFFIX / SIGIL-COV | `SMOKE_SUFFIX` / `SMOKE_SIGIL_COVERAGE` | `1` | 词缀链路 / 印记逐枚覆盖，各落 done |
| META / PERSIST | `SMOKE_META` / `SMOKE_META_PERSIST` | `1` | 局外打印 / 印记存档往返（落 `[SMOKE-SIGIL] persist selftest done`） |
| CODEX / CODEX_BOON / SHRINE / THIRD_BOSS | `SMOKE_CODEX` / `SMOKE_CODEX_BOON` / `SMOKE_SHRINE` / `SMOKE_THIRD_BOSS` | `1` | 图鉴往返 / boon 派生 / 圣所十项 / 第三 Boss 九断言，各落 done |
| BOSS | `SMOKE_BOSS` | `1` | **火力提速钩**（`game_main.gd:221` `bullet_dmg_mult=50.0`），不是「Boss 存在开关」；用于预算内走完 Boss 房 |
| BOSS2 / ECHO | 无独立 env | — | BOSS2 靠 `FORCE_SOVEREIGN=1` + `JUMP_FLOOR=11` 覆盖；ECHO 由 `FORCE_SQUAD=echo_pack` 钉死（**别找 `SMOKE_BOSS2` / `SMOKE_ECHO`**） |
| FORCE_SQUAD | `SMOKE_FORCE_SQUAD` | **编队 id**，如 `echo_pack` | 吃 id 不是布尔；`=1` 无效且 `<3` 层门控拦截（S12 踩过） |
| FORCE_SOVEREIGN / FORCE_THIRD_BOSS | `SMOKE_FORCE_SOVEREIGN` / `SMOKE_FORCE_THIRD_BOSS` | `1` | 强制出熔潮主宰 / 玄渊之主 |
| JUMP_FLOOR | `SMOKE_JUMP_FLOOR` | **层号数值**，如 `11` / `27` | **吃层号不是布尔**；`=1` 只是跳 1 层空转（S12 踩过） |
| DAILY / CALAMITY | `SMOKE_DAILY` / `SMOKE_CALAMITY` | `1` | 每日 seed 复现 / 强制灾祸（仅显式 env 才 forced） |
| META_SETTLE | `SMOKE_META_SETTLE` | `1` | **只有设了才开结算**；不设打印 `settle skipped`、余额不变（`game_main.gd:2264`），全量回归刻意不设 |
| META_FINGERPRINT | `SMOKE_META_FINGERPRINT` | `1` | 打印 `[SMOKE-META] fingerprint floor=N rooms=… kinds=…`，**只含 rooms 坐标 + kinds**（`game_main.gd:313–328`） |

其余表外钩：`SMOKE_CONTRACT/REG/APPLY`（自检三条）、`SMOKE_MENU`+`SMOKE_MENU_PAGE`（截图需带窗口）、`SMOKE_UI_CONFIRM`（须配 `PAGE=unlocks`）、`SMOKE_META_PATH/CODEX_PATH/SIGIL_PATH`（隔离档，**不会自动删**）、`SMOKE_DUMP/RG7/STATUS/DEATH/REPRO_TRACE/SHOTS/DASH_TRACE` 等，一律不进 E1 diff（坑 45）。

## 5. 接手后第一次验证 · 最小检查表（勾完即确认基线完好）
- [ ] `git log --oneline -1` + `git status --short`：确认起点与未提交物
- [ ] `ls scripts/*.gd | wc -l` = 34，与冻结清单行数一致
- [ ] `md5sum -c production/sprint-7/SPR7-FROZEN-4.md5` → exit 0 / 34 OK / 0 FAILED
- [ ] 清隔离档后单跑 `SMOKE=1` 短帧（600）：0 报错 + `validate problems=0`
- [ ] §1 门① 全量 6000 帧：0 报错 + done 齐 + `[ERR]` = 0
- [ ] §1 门②③④ 全过（E6 零新增 raw delta / E1 双跑一致 / ACTION_DEFS=18）
- [ ] 按 §2 给本批每条新增或修改的断言判类，标 ✓ 附**本轮实读行号**与反证
- [ ] §3 五条观察状态复核：已修/未修/登记豁免逐条留痕，未修也算结论
- [ ] 交付文档措辞 ↔ 代码实读一致性核对（重点 `SPR15_交付_阶段一.md:10`）
- [ ] 出 `PASS / CONCERNS / FAIL` + 证据日志路径；**放行签字交用户**，本表不代替签字

## 6. 权责边界（quality-lead）
**可独立承担**：跑四门控并给 PASS/CONCERNS/FAIL（建议性）；测试用例、Bug 报告（复现步骤/严重度）、复测与回归建议；断言有效性四类判定与证据评审 `ADEQUATE/INCOMPLETE/MISSING`；flaky 检测与隔离；冻结清单/脚本数/文档↔代码一致性核对；纯文档产出（QA 计划、接手包、报告）。
**必须回交主理人 / 用户裁定**：放行与发布签字；任何 `.gd` 产品代码改动（QA 不写产品代码，含探针补强与注释标注的实施授权）；验收标准本身的定义与变更（缺 Story/GDD 验收点时先索取，不臆造）；基线重定与口径分叉裁断（boon suffixes 阈值、B 发现口径、F1 主题扩容、`_tick_buffs` 是否统一 FIXED_DT）；冻结清单改写与 git 提交授权；Blocker 定性后的返工/回滚决定；质量门由 advisory 升为 blocking。
