# SPR3 QA 计划与用例：《源石虫清剿战》超级秘密房 / HUD 状态图标 / 挑战房保底

> 任务：SPR3-T2（quality-lead 严守真） · 阶段：A v2（只写文档，不运行 Godot、不改 `scripts/`）
> 依据：`D:\Create\Game\交接_第二轮扩展.md` §二 / §五 / §六、`交付_第二轮内容扩展.md`、team-lead 任务书 SPR3-T2
> 补充依据（阶段 A v2）：`production/sprint-3/SPR3-T3_范围检查与设计规格.md`（设计侧 10 处契约同步点 / 防误改点 / S-04 保底口径 / E1 护盾观察项），经 team-lead 中转纳入
> 阶段 B 最终口径裁定（team-lead）：S-04 以当前磁盘 **D1（`Game.add_score(30)` + toast「挑战失败 · 保底 +30 分」）为最终版，不返工**；四条倒挂红线不变、满血分支逐字未动；实现选型为**独立新 kind `super_secret`**；自检期望「房间 9」；`secret revealed` 允许 2–5
> 工程：`D:\Create\Game\test-1`（Godot 4.7.2.steam）｜引擎：`D:\SteamLibrary\steamapps\common\Godot Engine\godot.windows.opt.tools.64.exe`
> 阶段 B 产物：`tests/SPR3_测试报告.md` + `_tools/spr3_qa_*.log`
> 状态：**阶段 A 完成（v2 已纳入设计侧补充），等待 T1 完成通知后执行阶段 B**。阶段 A 期间工程由 engineering-lead 改动，任何运行结果均无效。

---

## 一、范围与质量目标

| 项 | 内容 |
|-|-|
| 本冲刺范围 | S-01 超级秘密房（只连 1 间房 / 稀有掉落）、S-03 HUD 护盾/连锁/淬毒状态图标、S-04 挑战房失败保底奖励 |
| 不做 | S-02 / S-05 / S-06（发现越界改动记为范围问题，不纳入本轮验收） |
| P0 强制回归门 | **RG-6 重建房间后门锁死**、**RG-7 新增图标直接查表导致面板崩** |
| 附带回归 | §五-8 小地图颜色走 `Data.room_color(kind)`、§六 自检输出计数随新房间 kind 变化、§五-4 新 PNG 的 `.import` |
| 用户硬要求 | 任何改动必须自己运行游戏验证到 **0 报错**，否则一律不通过；中文沟通 |
| 质量门性质 | 建议性门控（advisory）。本文件给 PASS / CONCERNS / FAIL 判定，**最终放行由用户决定** |
| 阶段 A v2 补充 | ① 新增 B-11 S-01 固定种子专项（堵自动验收假通过缺口）；② 静态清单并入设计侧 10 处契约同步点 + `dungeon.gd:130` 防误改；③ S-04 按最终裁定 **D1（+30 分 + 专属 toast + 掉落表不动 + 满血不回退）** 核验并守四条倒挂红线；④ 护盾抵挡不计掉血（E1）列为**已知风险 / 观察项，不阻断、不计入 FAIL** |

**核心原则**：没有测试证据的需求不算完成；验证驱动，只看代码不算通过。

> **观察项（不阻断）**：`player.gd:459-464` 护盾抵挡伤害时提前 `return`、未 `emit damaged`，导致「带护盾硬吃一下」仍算无伤通过。这是设计侧 E1 明确「本轮不动、只留痕」的跨 Story 一致性问题（S-03 × S-04），**不是本冲刺 Bug**；阶段 B 报告须记入「已知风险 / 观察项」章节，不得列入 Bug 清单、不得作为 FAIL 依据。

---

## 二、测试分层策略（自动 / 手动 / 烟雾 / Playtest）

| 层 | 内容 | 本轮落地方式 | 判定 |
|-|-|-|-|
| L1 静态 / 自动 | 代码通路审计：新增 kind 的硬编码串、**设计侧 10 处契约同步点（§7.4）**、`dungeon.gd:130` 防误改、图标是否走 `Assets.xicon`、PNG 与 `.import`、自检常量 | Grep 逐项核对（§七清单 S-1~S-15），输出 `spr3_qa_static.log` 等价记录写进报告 | 任一违规 = Major，触发 RG-6/RG-7 风险 = Critical；`cnt>=2` 被改成 `cnt==1` = Critical |
| L2 自动冒烟 | 固定种子 1–6 9000 帧、死亡链路 900 帧、纯净启动 600 帧、SMOKE_DUMP 600 帧、图标负向探针、**B-11 S-01 固定种子专项** | Godot `--headless` 实跑，日志落 `_tools/spr3_qa_*.log` | 逐条对数 §六 基线 + B-11 专项判据 |
| L3 手动 / 截图 | 状态图标可见性与布局、超级秘密房稀有掉落、挑战房失败保底提示 | 窗口模式 `SMOKE_SHOTS`，人工看图；无 GUI 环境时以日志锚点 + 静态审计替代并在报告标注 | ADEQUATE / INCOMPLETE / MISSING |
| L4 Playtest 签收 | 新玩家能否发现超级秘密房、HUD 状态是否可理解、挑战房失败挫败感是否缓解 | 本轮不组织真人 Playtest；报告给出签收模板与建议轮次，标记 **MISSING（建议下一轮）** | 不阻断 P0 门 |

本轮 P0 放行只依赖 L1 + L2；L3/L4 作为 CONCERNS 依据，不作为 FAIL 依据（除非 L3 发现 0 报错不达标）。

---

## 三、环境与命令规范（阶段 B 必须遵守）

```bash
cd /d/Create/Game/test-1
GODOT="D:/SteamLibrary/steamapps/common/Godot Engine/godot.windows.opt.tools.64.exe"
mkdir -p _tools
```

- 所有日志统一 `> _tools/spr3_qa_<用例>.log 2>&1`（或 `2>&1 | tee`），**必须真实读到日志内容后再判定**。
- Godot 冒烟可能超过 120s：单条命令必须显式 `timeout: 300000`，或 `run_in_background: true` + `TaskOutput` 取回完整输出。**严禁因超时/未读日志误判为 PASS**。
- 引擎路径含空格，必须加引号；环境变量前缀写在命令前（Git Bash 对原生 exe 生效，与交接文档 §二 一致）。
- Python 用绝对路径 `C:\Users\TangUser\AppData\Local\Python\bin\python.exe`（PATH 的 `python` 是坏存根）；本轮 QA 不依赖 Python。
- 阶段 B 用 Grep 工具（content / count 模式）核对日志，不用 Bash grep 做统计。

### 判据关键字（全部日志通用）

| 类别 | 关键字 | 期望 |
|-|-|-|
| 致命 | `SCRIPT ERROR`、`Parse Error`、`Invalid access to property or key` | **0** |
| 自检 | `[SMOKE] validate problems=0`、`[INFO] validate: 自检通过：敌人 28 / 房间 N / 地图池 3 层` | problems=0；N 与实现一致（见 §六.3） |
| 流程 | `[SMOKE] === entered floor 2 ===` | 出现（到第 2 层） |
| 秘密房 | `[SMOKE] secret revealed at` | 出现 ≥2（下限，两层各 ≥1）；超秘是否计入同字段按 **B-11 口径**核对，允许 >2，但须记录实际计数并与专项证据一致 |
| 过门 | `[SMOKE] use_door dir=` | 计数在基线区间 |
| 地图 | `[SMOKE] dungeon map: N rooms {...}` | 含 S-01 新 kind 计数 |
| 门锁 | `[SMOKE-DOOR] ... locked=`、`[SMOKE-DOORS] ... [[dir, false], ...]` | 清场状态下全部 `false` |
| 挑战房 | `[SMOKE] challenge failed` / `[SMOKE] challenge no-hit clear` | 与掉血状态一致 |
| S-04 保底 | `Game.add_score(30)`、专属 toast「挑战失败 · 保底 +30 分」、掉落表未改、满血分支逐字未动 | `SMOKE_CHALLENGE_FAIL=1` 下出现 `[SMOKE] forced challenge-fail probe` / `[SMOKE] challenge failed (consolation +30 score)`；toast 不进日志时以代码逐字 + 探针日志为准，B-9 截图抓到则补 L3 证据 |
| 超秘专项 | `[SMOKE] dungeon map: N rooms {...}`、超秘 kind / 标记字段、爆破与进房日志 | B-11：SMOKE 能炸超秘墙、自动驾驶能进房、稀有掉落可领 |
| 死亡 | `[SMOKE] player died —` | 900 帧内 5 次 |
| 缺图 | `[assets] 图标缺失：`、`[assets] 素材加载失败：`、`<NULL>` | 正常用例中不应出现（探针例外） |

---

## 四、§六 验收基线：逐条命令 + 判据 + 期望值

> 基线来自交接文档 §六；`自测通过`的旧值不得直接沿用，阶段 B 必须在新代码上重跑。

| # | 用例 | 命令（阶段 B 实跑） | 判据与期望值 | 日志 |
|-|-|-|-|-|
| B-1 | 种子 4 | `SMOKE=1 SMOKE_SEED=4 "$GODOT" --headless --path . res://scene/game.tscn --quit-after 9000 > _tools/spr3_qa_seed4.log 2>&1` | 0 报错；过门 14–16；出现 `entered floor 2`；`secret revealed` ≥2；`validate problems=0` | `spr3_qa_seed4.log` |
| B-2 | 种子 5 | 同上 `SMOKE_SEED=5` | 同上；过门 14–16；允许出现挑战房日志 | `spr3_qa_seed5.log` |
| B-3 | 种子 6 | 同上 `SMOKE_SEED=6` | 同上；过门 14–16 | `spr3_qa_seed6.log` |
| B-4 | 种子 1 | 同上 `SMOKE_SEED=1` | 0 报错；过门 16–35；出现 `entered floor 2` | `spr3_qa_seed1.log` |
| B-5 | 种子 2 | 同上 `SMOKE_SEED=2` | 同上 | `spr3_qa_seed2.log` |
| B-6 | 种子 3 | 同上 `SMOKE_SEED=3` | 同上 | `spr3_qa_seed3.log` |
| B-7 | 死亡链路 | `SMOKE=1 SMOKE_DEATH=1 "$GODOT" --headless --path . res://scene/game.tscn --quit-after 900 > _tools/spr3_qa_death.log 2>&1` | `player died` 计数 = 5；每次重开后自检 problems=0；0 报错；无 `restart` 残留图标/状态 | `spr3_qa_death.log` |
| B-8 | 纯净启动 | `"$GODOT" --headless --path . res://scene/game.tscn --quit-after 600 > _tools/spr3_qa_plain.log 2>&1` | 0 报错（含 `Parse Error`）；自检通过；无 `[assets] 素材加载失败` | `spr3_qa_plain.log` |
| B-9 | 截图（窗口） | `SMOKE=1 SMOKE_SEED=2 SMOKE_SHOTS="1150,1250" "$GODOT" --path . res://scene/game.tscn --quit-after 1300 > _tools/spr3_qa_shots.log 2>&1` | 门/道具/怪/UI/新状态图标正常；0 报错；图片落 `D:/Create/Game/_tools/dungeon_shot_*.png` | `spr3_qa_shots.log` |

**总判据**：`SCRIPT ERROR` / `Parse Error` = 0，出现 `entered floor`、`secret revealed`。`use_door` 与房间数同量级（<40/9000 帧为宜）。
**自检基线**：`[INFO] validate: 自检通过：敌人 28 / 房间 8 / 地图池 3 层`（改动前）。**本轮期望（选型 I，T1 已确认）**：`敌人 28 / 房间 9 / 地图池 3 层` —— `Validate.run()` 打印动态 `Data.ROOM_META.size()`，8→9 自动；交接稿 §六 的「房间 8」属需更新的期望文案，**不是降标准**。

> ⚠️ **基线 ≠ S-01 覆盖**：设计侧 `SPR3-T3` §0.1-3 与本计划 R6-8 一致 —— 若 S-01 用独立新 kind，六条基线里的 `secret revealed` 只来自普通秘密房，**B-1~B-6 全达标也不能证明 S-01 被验收**。S-01 是否通过以 **B-11 专项 X1~X7** 为准；基线只负责证明「既有流程无回归」。

### B-10 SMOKE_DUMP 门锁/贴图专项（RG-6 主证据）

```bash
SMOKE=1 SMOKE_SEED=4 SMOKE_DUMP=1 "$GODOT" --headless --path . \
  res://scene/game.tscn --quit-after 600 > _tools/spr3_qa_rg6_dump.log 2>&1
```

日志锚点（以实读代码为准，勿按帧号想当然）：
- 第 **240** 帧：`_dump_entities()` 打印 `[DUMP] ---- 全树贴图 ----` 与逐节点 `S/A ... <NULL>/resource_path`；
- 每 **180** 帧：`[SMOKE-DOORS] props=.. n=.. [[dir, locked], ..] state=..`（`game_main.gd:1032-1034`）；
- 每次进房：`[SMOKE-DOOR] room=.. dir=.. locked=.. neighbor=.. cleared=..`（`game_main.gd:433-438`）；
- 爆破：`[SMOKE] bombed secret wall dir=..` → `explode` → `[SMOKE] secret revealed at ..`（`game_main.gd:1031-1052`、`466-477`）。

**期望**：秘密墙/超级秘密墙爆破触发 `_build_arena` 重建后，`[SMOKE-DOORS]` 与 `[SMOKE-DOOR]` 中所有门 `locked=false`；`state=cleared`；`[DUMP]` 全树贴图无异常 `<NULL>`；随后出现 `use_door` 与 `entered floor`，无软锁。

> 注意：`_dump_entities()`（`game_main.gd:1096-1118`）只打印 **Sprite2D / AnimatedSprite2D 贴图**，门锁状态来自 `[SMOKE-DOORS]` / `[SMOKE-DOOR]` 两处打印，判定必须三者合看，不可只看第 240 帧。

### B-11 S-01 超级秘密房固定种子专项（堵自动验收假通过缺口 · 阶段 A v2 新增）

**来源**：设计侧 `SPR3-T3_范围检查与设计规格.md` §0.1-3 / §7 #7/#8 独立确认，与本文档 R6-8 一致 —— `game_main.gd:1044` `_smoke_secret_tick` 与 `game_main.gd:516` `autopilot_door_target` 都只认 `kind == "secret"`。若 S-01 用独立新 kind，§六 六条基线**不会覆盖 S-01**，普通秘密房仍能让 `secret revealed` 达标 → **假通过**。本用例是 S-01 是否被真正验收的唯一自动证据。

```bash
SMOKE=1 SMOKE_SEED=4 SMOKE_DUMP=1 "$GODOT" --headless --path . \
  res://scene/game.tscn --quit-after 9000 > _tools/spr3_qa_s01_super.log 2>&1
```

**固定种子选定规则**（防止「没触发就当通过」）：先以种子 4 为主；若 `[SMOKE] dungeon map` 显示该种子未生成超秘房，则在 1–6 中扫描、或按 T1 交付说明给出的专用种子 / 专用环境变量（如 `SMOKE_SUPER=1`）复跑，并在报告中记录**选定种子的依据与该种子的地图 kinds 原文明细**。任何「未观察到超秘房」的结果都不允许直接判 PASS，必须区分为「本层合法跳过（设计 A5）」还是「挂具未覆盖（覆盖缺口 / 缺陷）」。

| # | 判据 | 选型 I：独立新 kind | 选型 II：复用 `secret` + 标记字段 |
|-|-|-|-|
| X1 | 生成 | `[SMOKE] dungeon map: N rooms {...}` 含新 kind，计数符合 T1 说明（固定 2 间/层 或按概率） | `secret` 计数 = 2/层（普通 + 超秘），且静态核对**第二次独立选格**产出 `cnt == 1` 的房 |
| X2 | 隐藏性 | 超秘方向生成裂纹墙（`game_main.gd:656-673` 覆盖新 kind）；未揭示小地图不显示（`hud.gd:353`） | 标记字段传递到 `secret_dirs` / 小地图隐藏 / 掉落分流 |
| X3 | **能被 SMOKE 炸开** | 日志出现针对超秘墙的爆破 → `[SMOKE] bombed secret wall dir=..` 与揭示日志；`_smoke_secret_tick` 已覆盖新 kind | 挂具仍认 `secret`，须确认标记房同样被炸（含唯一入口方向） |
| X4 | **自动驾驶能进房** | 日志出现进入超秘房（`[SMOKE] t=.. room=.. <新kind>` 或等价），`use_door` 覆盖该房 | 同上，且确认 BFS 未把该房跳过（`game_main.gd:516-518`） |
| X5 | **稀有掉落可领且只发一次** | 静态核对掉落内容明显优于普通秘密房（`game_main.gd:394-399`）+ B-9 截图 / 一次性标记 | 标记分流确实给了不同掉落，非同一分支重复发 |
| X6 | 不回归 | `entered floor 2`、0 报错、`use_door` 量级正常、门锁全开（RG-6）、自检 `✗` 清单为空 | 同左 |
| X7 | 防误改 | `dungeon.gd:130` 仍为 `cnt >= 2`（普通秘密房规则未被改成 `cnt == 1`），超秘是并存的第二次选格 | 同左 |

**阶段 B 已确认的实现事实（team-lead 放行通知 + QA 实读）**：实现为**选型 I 独立新 kind `super_secret`**，每层 1 间；`_find_super_secret_cell` 确定性取首个合法格、不消耗 rng（不打乱固定种子地图）；`[SMOKE-SUPER] floor=N cell=.. neighbors=1` 逐层断言可作证据；SMOKE 挂具已从「一房间只炸一次」改为「按方向逐帧逐个炸」；无专用环境变量，种子 4 已实证超秘链路、任意固定种子稳定。**B-11 只按选型 I 列判据，选型 II 列留存不执行**。

**`secret revealed` 计数口径（已确认）**：`reveal_secret` 打印 `[SMOKE] secret revealed at .. kind=super_secret|secret`，**两类隐藏房各计一次**；T1 给出种子 1..6 期望 `3/4/5/3/3/3`。基线 `≥2` 只是**下限**，**不得用旧的 2 反推通过**；报告须记录实际计数并与 B-11 证据一致。

**判定**：X1~X7 全有证据 = S-01 自动验收覆盖 ADEQUATE；任一项只能靠静态推断、无运行证据 = 覆盖缺口（Major → CONCERNS，报告中逐条列明）；出现「生成了但看不见 / 炸不开 / 自检报错 / 进房锁门」= Critical → **FAIL**。

### B-11 附：逐层生成断言检查（追加检查点 X8 · team-lead 中转设计评审阶段 B）

`[SMOKE-SUPER] neighbors=1` 是**代码内断言**，**有断言 ≠ 每层都生成得出超秘**：超秘在普通秘密房之后选格，候选格可能已被占用，实现为 `NO_CELL` 静默跳过（设计侧 A5 认可合法跳过）。

**用例**：对冻结快照的 `spr3_qa_seed{1..6}_final.log` 逐个统计：
- `[SMOKE-SUPER] floor=N cell=.. neighbors=1` 的 `floor` 序列（是否 1、2、3… 逐层连续）；
- 该种子实际到达的最高层（`[SMOKE] === entered floor N ===`）；
- 每层 `dungeon map` 中 `super_secret` 计数；
- 若某层仅有 `entered floor N` 而无对应 `[SMOKE-SUPER] floor=N` → **该层跳过**，报告须记录种子 / 层号 / 该层 map kinds 原文。

**判定（不默认 PASS）**：
- **合法跳过（A5）**：该层无 `cnt==1` 合法格（候选已被普通秘密房 / 其它房占用），`_find_super_secret_cell` 返回 `NO_CELL`，静默跳过、不崩、不放非法格 → 记 **CONCERNS 观察项**，逐层列明，不影响 P0 门；
- **挂具未覆盖 / 缺陷**：断言未打印但地图存在合法 `cnt==1` 格；或 `super_secret` 已生成却无断言打印；或该层出现隐藏房不可见 / 炸不开 / 自检报错 → **Major / Critical**，按 R6-8 与 B-11 判覆盖缺口或 FAIL。
- 记录表须给出：种子、实际层数、逐层断言触发（1/2/3…）、跳过的层、判定类别、证据日志行号。

---

## 五、P0 回归门 RG-6：重建房间后门锁死

**历史缺陷**：`_build_arena` 新建的门默认 `locked=true`；炸开秘密墙会调用 `reveal_secret()` → `_build_arena(dungeon.current)` 重建，若清场状态未补解锁，玩家被关在房里出不去（交接 §五-6、交付 §四-1）。
**既有修复落点**：`scripts/game_main.gd:682-685` —— `_build_arena` 末尾 `if room_state == "cleared": for d in _doors: d.set_locked(false)`。
**本轮风险**：S-01 新增超级秘密房，极可能新增第二条重建路径或新 kind 绕过该解锁段。

### RG-6 详细步骤

| 步 | 动作 | 期望 / 证据 |
|-|-|-|
| R6-1 静态 | 确认 `game_main.gd:682-685` 解锁段仍存在、未被条件包住、未被移到 `return` 之后 | 代码片段核对 |
| R6-2 静态 | 列出所有 `_build_arena(` 调用点（已知 `350` `_enter_room`、`474` `reveal_secret`），检查 S-01 是否新增调用点；新增点必须保证调用时 `room_state == "cleared"` 或自行解锁 | 无绕过解锁段的重建路径 |
| R6-3 静态 | 检查是否有「不经过 `_build_arena` 直接 new DoorScript」的重建/揭示分支；有则必须显式 `set_locked(false)` | 无裸门 |
| R6-4 动态 | 跑 B-10（种子 4 + `SMOKE_DUMP=1`，600 帧），触发普通秘密墙爆破 | 见 B-10 期望；`[SMOKE-DOORS]` 全 `false` |
| R6-5 动态 | 跑 B-1/B-2/B-3（种子 4/5/6，9000 帧），统计 `secret revealed` 后是否持续 `use_door` 并到 `entered floor 2` | 过门数在 14–16，无停滞、无 `[SMOKE-STALL]` 长时间锁死 |
| R6-6 动态 | 对 S-01 超级秘密墙重复 R6-4/R6-5：爆破 → 重建 → 门锁全开 → 能进入超级秘密房 → 能原路返回并下楼 | 无软锁 |
| R6-7 动态 | B-8 纯净启动 + B-7 死亡重开后，首房门状态正常 | 0 报错、无锁死 |
| R6-8 负向 | 若 S-01 的 SMOKE 挂钩未覆盖新 kind（见 §七风险），按 **B-11 专项**用固定种子复现超级秘密墙爆破；无法触发则标记 **覆盖缺口** 并在报告写明，不得默认通过 | 有证据或明确缺口说明（B-11 日志） |

**FAIL 条件**：任一时点清场状态下出现 `locked=true`；`secret revealed` 后过门停滞/无 `entered floor`；出现软锁；S-01 新增绕过解锁段的重建路径且未补解锁。

### R6 附：SMOKE 挂钩只认旧 kind（本轮最高风险，须实读确认）

现状代码中以下四处**硬编码 `kind == "secret"`**，S-01 若用新 kind 字符串（如 `super_secret`）且未同步扩展，超级秘密墙将**不会生成裂纹墙、不会被 SMOKE 炸、自动驾驶也不会走过去**，用例会假通过：

| 位置 | 作用 |
|-|-|
| `game_main.gd:656-662` `_build_arena` `secret_dirs` | 决定是否用 `SecretWallScript` 替换门 |
| `game_main.gd:1039-1044` `_smoke_secret_tick` | SMOKE 是否自动炸相邻未揭示秘密墙 |
| `game_main.gd:516-518` `autopilot_door_target` | 已炸开秘密房是否被 BFS 列为目标 |
| `hud.gd:353` `refresh_minimap` | 未揭示秘密房是否隐藏 |

若实现选择「复用 `secret` kind + 新增标记字段（如 `super: true`）」则上述四处无需改动，需改为核对标记字段的传递链路。**实现选型需 T1 明确告知，QA 按实际实现核对，不臆造。**

---

## 六、P0 回归门 RG-7：新增图标直接查表导致面板崩

**历史缺陷**：新增升级图标直接 `ICON_RECTS[key]`，升级面板抛 `Invalid access to property or key 'chain'`（交接 §五-7、交付 §四-2）。
**既有修复落点**：`scripts/assets.gd:241-249` `xicon()` 三级回退（generated → `ICON_RECTS` → `white_tex` + `push_warning("[assets] 图标缺失：%s" % key)`）；`scripts/upgrade_panel.gd:149-152` `_icon_for()` 统一走 `Assets.xicon(key)`。
**本轮风险**：S-03 新增护盾/连锁/淬毒状态图标；`hud.gd:415-421` 的 `_icon_label()` 用的是 **`Assets.icon(key)`（直接查表，无回退）**，若 S-03 复用它传新 key，将原地复现 RG-7。

### RG-7 详细步骤

| 步 | 动作 | 期望 / 证据 |
|-|-|-|
| R7-1 静态 | 确认 `assets.gd:242-249` 三级回退完整未被削弱；`upgrade_panel.gd:152` 仍为 `Assets.xicon(key)` | 代码片段核对 |
| R7-2 静态 | **枚举 S-03 所有新增图标 key**，逐个确认取值走 `Assets.xicon()`；禁止 `Assets.icon(新key)` / `ICON_RECTS[新key]` / 字典直取 | 新增图标 100% 走 xicon，含 HUD 状态图标（不只升级面板） |
| R7-3 静态 | 若新增 PNG：确认 PNG 在 `resources/texture/generated/`、名字已登记 `GEN_NAMES`（`assets.gd:102-111`）、且**存在同名 `.import` 文件**（§五-4，缺 `.import` 会 `load()` 返回 null 显示棋盘格/白图） | 新 PNG 与 `.import` 一一对应 |
| R7-4 静态 | 若复用已有 `icon_chain / icon_guard / icon_venom`（`GEN_NAMES` 已含），确认 key 拼写一致（`chain`/`guard`/`venom`，见 `upgrades.gd:16-18`） | 无拼写漂移 |
| R7-5 动态·负向探针 | 请求**不存在的图标 key**，面板不得抛异常，须返回白图并打印 `[assets] 图标缺失` | 见下方探针 |
| R7-6 动态·正向 | B-1~B-8 全程搜索 `Invalid access to property or key`、 `[assets] 图标缺失`、 `[assets] 素材加载失败` | 计数均为 0（探针日志除外） |
| R7-7 动态 | 触发升级面板（SMOKE 自动选卡：`[SMOKE] upgrade picked:`）与 HUD 状态图标显示，检查 0 报错 | 面板正常、图标可见 |

### R7-5 负向探针（阶段 B 落地于 `tests/`，不改 `scripts/`）

```gdscript
# tests/spr3_icon_probe.gd —— 独立 SceneTree 探针，不依赖 autoload、不改产品代码
extends SceneTree
func _initialize() -> void:
	var a: Node = preload("res://scripts/assets.gd").new()
	root.add_child(a)                       # 触发 assets.gd._ready() 装载 generated/ 与 white_tex
	var t: Texture2D = a.xicon("spr3_missing_icon_probe")
	print("[PROBE] missing-key -> ", "WHITE" if t == a.white_tex else "OTHER", \
		" size=", t.get_size() if t else Vector2.ZERO)
	print("[PROBE] known-key -> ", "OK" if a.xicon("chain") != null else "NULL")
	quit()
```

```bash
"$GODOT" --headless --path . --script res://tests/spr3_icon_probe.gd \
  > _tools/spr3_qa_rg7_probe.log 2>&1
```

**期望**：日志出现 `[assets] 图标缺失：spr3_missing_icon_probe`（`push_warning` 输出）、`[PROBE] missing-key -> WHITE`、`[PROBE] known-key -> OK`，且**无 `Invalid access to property or key`、无 `SCRIPT ERROR`**。
若 `--script` 模式下 `assets.gd._ready()` 的资源装载或 `InputMap` 初始化受限导致探针无法运行，退化为：静态审计 R7-1~R7-4 + 正向日志 R7-6/R7-7，并在报告中标注「负向探针 MISSING，判定降为 CONCERNS」——**不得静默当作通过**。

### 附：S-03 状态数据源（用于断言图标随状态变化）

`player.gd:51-53`：`chain_chance`(0→0.75)、`poison_chance`(0→0.9)、`shield_charges`(0→3，上限 3)；`player.gd:458-464` 受击消耗一层护盾；`upgrades.gd:91-96` 三处赋值。HUD 必须读取这些字段（或等价信号），不得另建不一致的副本。

---

## 七、附带回归：§五-8 小地图颜色、§六 自检计数、静态清单

### 7.1 小地图颜色（§五-8）

- 现状 `hud.gd:381` 已用 `Data.room_color(String(info["kind"]))`；`data.gd:175-176` `room_color` 对未知 kind 回退 `Color.WHITE`（不崩，但会白块）。
- **用例**：S-01 新增 kind 后，跑 B-1 并人工看 B-9 截图，小地图该房间标记应为 `ROOM_META` 中登记的颜色（非纯白）；静态确认 `hud.gd` 无新增写死颜色表；`Data.ROOM_META` 含新 kind 的 `name` / `color`。
- 同时核对 `hud.gd:330-331` `set_room_info` 与 `hud.gd:375` 房间标记表：二者都使用 `.get(kind, 默认值)` 不会崩，但新 kind 的显示文本/标记需符合设计（超秘建议可辨识标记），记为 Major/Minor 级观感问题，不触发 P0 门。

### 7.2 自检输出计数（§六）

- 现状（阶段 B 实读）：`validate.gd:23-24` 打印 `Data.ROOM_META.size()`；`validate.gd:7` `KNOWN_ROOM_KINDS` 已扩为 **9 种**（含 `super_secret`），`data.gd:121` `ROOM_META` 已加 `super_secret` 的 `name`/`color`。
- **用例（选型 I 已确定）**：期望 `[INFO] validate: 自检通过：敌人 28 / **房间 9** / 地图池 3 层`；`[SMOKE] validate problems=0`；`KNOWN_ROOM_KINDS` 与 `ROOM_META` 均含 `super_secret`；新增 `_check_status_icons()` 校验 `guard/chain/venom` 走 `Assets.xicon`。
  - 计数与实现不一致、出现 `✗` 自检失败清单或 `problems>0` → FAIL/Critical；
  - 交接稿 §六 的「房间 8」为待更新文案，8 反而是**不符合本轮实现**的异常值。
- `validate.gd:78-84` `_check_icons` 的 `["chain","guard","dice","venom"]` 为硬编码：S-03 若新增图标 key 未加入该数组，缺图不会被自检发现 → 记为 Major（漏检），并列入报告建议。

### 7.3 静态检查清单（阶段 B 逐项勾选，结果写进报告）

| # | 检查项 | 判据 |
|-|-|-|
| S-1 | `game_main.gd:682-685` 解锁段完好 | 存在且无条件可达 |
| S-2 | 所有 `_build_arena(` 调用点 | 无绕过解锁段的新路径 |
| S-3 | `secret_dirs` / `_smoke_secret_tick` / `autopilot_door_target` / `hud.gd:353` **及设计侧 10 处契约同步点全表（§7.4）** | 逐行号核对，覆盖 S-01 新 kind 或已按「复用 kind」选型核对；任一漏改表现为「生成了但看不见 / 炸不开 / 自检报错」 |
| S-4 | `_enter_room` 的 `match kind`（`game_main.gd:353-413`） | 新 kind 归入 `"start","treasure","shop","secret"` 清场组，**否则会走 combat 分支锁门刷怪** |
| S-5 | `_room_cleared` 的 `match kind`（`game_main.gd:289-320`） | 新 kind 不误触发战斗结算；S-04 挑战分支改动不破坏门锁解锁 |
| S-6 | `Data.ROOM_META` / `validate.gd:KNOWN_ROOM_KINDS` | 与新增 kind 一致 |
| S-7 | HUD 颜色与房间文本/标记 | 走 `Data.room_color`，无新增写死表 |
| S-8 | 新增图标全部走 `Assets.xicon` | 无 `Assets.icon(新key)` / `ICON_RECTS[新key]` |
| S-9 | 新 PNG 与 `.import` | 一一对应，登记 `GEN_NAMES` |
| S-10 | 掉落只发一次 | 超级秘密房 / 挑战房保底奖励均有一次性标记（参照 `skip_loot` / `cleared`） |
| S-11 | 范围 | 无 S-02/S-05/S-06 改动 |
| S-12 | flaky | 同一种子连跑两次关键指标（过门数、`entered floor`、报错数）一致；不一致先隔离再判定，不污染门控信号 |
| **S-13** | **`dungeon.gd:130` 防误改点** | 普通秘密房 `_find_secret_cell` 仍为 **`cnt >= 2`**，**未被改成 `cnt == 1`**；超秘必须是并存的**第二次独立选格**，不是「改一个比较符」。误改 = Critical（改写既有房间规则并可能改变基线 `secret revealed` 计数） |
| **S-14** | 设计侧 §7 附注两处 | `game_main.gd:689` 障碍物分组、`:100-103` 无伤判定均按 kind 硬编码，超秘**不得**落入 `combat/elite/challenge` 分组（否则空房刷石柱/机柜） |
| **S-15** | E1 观察项登记 | 确认本轮**未**改动 `player.gd:459-464`（护盾抵挡不 emit `damaged`）；该项只登记为已知风险，**不阻断、不计入 FAIL** |

### 7.4 设计侧 10 处契约同步点（阶段 B 逐项勾选）

> 来源 `SPR3-T3_范围检查与设计规格.md` §7，经 team-lead 中转纳入。与 7.1 / 7.2 / 7.3 有交叉，本表按行号做**全量**核对，阶段 B 在「结论」列填 ✅ / ❌ / 不适用（复用 kind 选型时逐条说明等价覆盖方式）。

| # | 位置（阶段 A 快照行号） | 现状 | 漏改后果 | 阶段 B 结论 |
|-|-|-|-|-|
| 1 | `validate.gd:7` `KNOWN_ROOM_KINDS` | 8 项白名单 | 开局自检打印 `✗`「房间类型缺少元信息」；房间计数不对 | 待填 |
| 2 | `data.gd:113` `ROOM_META` | 8 项 `name`/`color` | `Data.room_color()` 回退白色，小地图标记无颜色 | 待填 |
| 3 | `hud.gd:375` 小地图 mark 表 | `secret→"?"`、`challenge→"!"` | 超秘房揭示后无区分标记 | 待填 |
| 4 | `hud.gd:330` `set_room_info` kind_text | 6 项映射 | 层数标签不显示超秘房名 | 待填 |
| 5 | `game_main.gd:661` `secret_dirs` 判断 | 只认 `kind=="secret"` | **超秘方向直接生成可见门，隐藏性丧失、不用炸弹** | 待填 |
| 6 | `game_main.gd:466` `reveal_secret` | 标 `revealed` + 重建 | 超秘炸开后不重建 / 门锁未解锁（§五-6） | 待填 |
| 7 | `game_main.gd:516` `autopilot_door_target` | 只认 `kind=="secret"` 且 revealed | 自动驾驶不主动去已揭示超秘房，**自动验收不覆盖 S-01** | 待填 |
| 8 | `game_main.gd:1044` `_smoke_secret_tick` | 只认 `kind=="secret"` | SMOKE 不自动炸超秘墙，`secret revealed` 计数不含超秘 | 待填 |
| 9 | `hud.gd:353` 小地图隐藏规则 | 只隐藏 `secret` 且未 revealed | 超秘房未揭示就暴露在小地图上 | 待填 |
| 10 | `game_main.gd:354` 进房 `cleared` 分组 | `"start","treasure","shop","secret"` | 超秘房遗漏 → 进去锁门刷怪 / 无法按已清处理 | 待填 |

**防误改点（表外，属 S-13）**：`dungeon.gd:130` `cnt >= 2` 保持不动；两层/多种子核对普通秘密房仍「夹在 ≥2 间房之间、不贴 Boss、每层 1 间」（设计 A7）。

---

## 八、三条 Story 功能验收点

### S-01 超级秘密房（只连 1 间房 / 稀有掉落）

| # | 验收点 | 判据 / 证据 |
|-|-|-|
| A1 | 生成：每层存在超级秘密房，且**只连 1 间房**（`neighbors(c).size() == 1` 语义） | `[SMOKE] dungeon map: N rooms {...}` 中该类型计数；静态核对 `dungeon.gd` 生成函数（现 `_find_secret_cell` 是 `cnt>=2` 普通秘密房，超秘需另设 `cnt==1` 且不贴 Boss 的选址） |
| A2 | 未揭示前小地图不显示，裂纹墙只吃炸弹（子弹无效） | `hud.gd:353` 隐藏逻辑；`secret_wall.gd` 只响应 `bomb_hit` |
| A3 | 揭示后重建出正常门且全解锁，可进入、可原路返回、可下楼 | RG-6 全部用例（R6-4~R6-6） |
| A4 | 稀有掉落：奖励明显优于普通秘密房（`game_main.gd:394-399` 为 大宝箱+遗物+8 源石），且**只发一次**（重进不重复刷） | 日志/截图；静态核对一次性标记 |
| A5 | 与普通秘密房共存，普通秘密房不减少；基线 `secret revealed` ≥2 仍成立 | B-1~B-6 |
| A6 | 新增 kind 不导致小地图颜色崩、自检失败、房间文本崩 | §七 7.1 / 7.2 |
| A7 | 0 报错，且能下到第 2 层 | §六 总判据 |
| **A8** | **自动验收覆盖**：SMOKE 能炸超秘墙、自动驾驶能进房、稀有掉落可领，固定种子可复现 | **B-11 专项** X1~X7；仅靠基线 `secret revealed` 达标不算通过 |
| **A9** | 防误改 / 静默跳过：普通秘密房 `cnt>=2` 规则不动；找不到合法单连接空格时静默跳过本层，不崩、不强行放非法格 | S-13 + `dungeon.gd` 生成函数静态核对 + B-11 X1 |
| **A10** | 边缘链路：唯一邻房为玩家可达正常房（非另一未揭示隐藏房）；已揭示未进入就下楼 / 死亡重开时 `revealed` 不跨层残留、不重复领奖；超秘不成为自动驾驶卡死点（全图清完兜底仍走 Boss）；不落入障碍物/无伤判定分组 | 设计规格 §2.1 边缘情况；S-14、B-7、B-11 X6 |
| **A11** | 稀有掉落不引入新稀有度层级 / 新物件表（只在既有池内提高量级，设计 R1），不越界 S-05 | 静态核对掉落分支与范围（S-11） |

### S-03 HUD 护盾 / 连锁 / 淬毒状态图标

| # | 验收点 | 判据 / 证据 |
|-|-|-|
| C1 | 获得 `guard` 后显示护盾层数（1/2/3，上限 3）；受击消耗后数字同步 −1；归零后隐藏/置灰 | B-9 截图 + 静态核对读取 `player.shield_charges` |
| C2 | `chain_chance > 0` 显示连锁图标，`poison_chance > 0` 显示淬毒图标；未获得时不显示 | 截图 + 静态核对读取 `player.gd:51-53` |
| C3 | 状态变化实时刷新：升级面板选卡后立即更新、护盾消耗后立即更新、死亡重开后归零无残留 | B-7 死亡链路 + B-9 截图 |
| C4 | 图标全部走 `Assets.xicon`（含 HUD，不只升级面板） | RG-7 R7-2 |
| C5 | 布局不遮挡血条/小地图/武器槽/技能条/Boss 条/结算 | B-9 人工看图（L3） |
| C6 | 不引入 `Invalid access to property or key`、缺图告警、白块 | RG-7 R7-6/R7-7 |

### S-04 挑战房失败保底奖励

> **阶段 B 最终口径裁定（team-lead）**：以当前磁盘 **D1（+30 分）为最终版，不返工改回 3 源石**。理由：设计侧阶段 A 原始推荐；四条倒挂红线全成立且比 3 源石更保守（固定值、与掉血次数无关、显著低于无伤 200 分、不新增稀有度、不加掉落）；代码已在磁盘，改回需第三次改动 + 重跑；用户原始需求「失败也给小奖励」两种实现都满足。
> 核验 `Game.add_score(30)` + `hud.flash_toast("挑战失败 · 保底 +30 分")` + `[SMOKE] challenge failed (consolation +30 score)`；四条倒挂红线不变；**满血分支 `game_main.gd:327-334` 逐字未动**。
> 交接稿 §七-5「掉血时只有普通掉落」与代码事实有偏差（原本已掉 3 颗钻石），`game_main.gd:318` 旧注释「掉过血则只给普通掉落」为残留误导文案，已列入**收尾补丁待办**，不作为当前冻结版本 FAIL 依据。SMOKE 默认无敌使掉血分支不可达，须用 `SMOKE_CHALLENGE_FAIL=1` 探针复现。

| # | 验收点 | 判据 / 证据 |
|-|-|-|
| **D1** | 掉血失败路径：`[SMOKE] forced challenge-fail probe` → `[SMOKE] challenge failed (consolation +30 score)` 出现；`_room_cleared` 的 `"challenge"` 掉血分支 `Game.add_score(30)`（**固定值、与掉血次数无关**）；专属 toast「挑战失败 · 保底 +30 分」；**掉落表不动**（原有随机散布 3 颗钻石仍在，不新增 pickup） | 静态核对 `game_main.gd:317-326` + `SMOKE_CHALLENGE_FAIL=1` 日志（`spr3_qa_challenge_final.log`）+ toast 文本（toast 不进日志，以代码逐字为准；B-9 截图抓到则补 L3 证据） |
| **D2** | 满血 / 无伤分支**逐字未动**：3 钻石 + 遗物 + 大宝箱 + banner「无伤通过！」+ `Game.add_score(200)` + 音效 | `[SMOKE] challenge no-hit clear` 日志 + 静态逐行比对 `game_main.gd:327-334` |
| **D3** | 守**四条倒挂红线**（见下方专节） | 静态 + 数值对照，任一违反 = Major/Critical |
| D4 | 保底奖励只发一次；重进已清挑战房不重复结算；掉血后清场瞬间死亡等边界不产生重复/丢失 | `skip_loot` / `cleared` 标记核对 + B-7 死亡链路 |
| D5 | 不破坏门锁解锁、不引入新 pickup 类型崩溃、0 报错 | RG-6 + §六 总判据 |
| D6 | 掉血判定仍准确（`game_main.gd:100-103`）；文案区分「失败但给安慰」与「无伤通过」；`SMOKE_CHALLENGE_FAIL` 仅环境变量门控、常态不生效 | 静态 + 日志一致性 + 常态基线日志搜索 |
| **D7** | 护盾抵挡不计掉血（E1）为**已知风险 / 观察项**，不列为 Bug、不计入 FAIL | 见 §一 / §九 / §十二；确认本轮未改 `player.gd:459-464`（S-15） |

**四条倒挂红线（D3 判据，来源设计规格 §5.3）**

| # | 红线 | 核验方式 |
|-|-|-|
| 1 | **掉血总收益不得超过无伤**：显著低于「遗物 + 大宝箱 + 200 分」 | 对照固定 `+30` 分 vs 无伤分支，静态确认无其他叠加收益、无额外掉落 |
| 2 | **不新增稀有度**：保底不得是遗物 / 大宝箱 / 升级卡 / 武器 / 200 分，也不得是随机高价值掉落 | 静态核对掉血分支只 `Game.add_score(30)` + toast，掉落表未动 |
| 3 | **不能故意掉血刷分**：固定值、与掉血次数无关、可预期 | 静态确认是单次固定 `30`，不在循环内、不按 `_room_damaged` 次数累加；多次掉血不重复结算 |
| 4 | **无伤奖励不回退** | D2 逐行比对 |

---

## 九、Bug 分级与报告模板

| 级别 | 定义 | 示例 | 对放行影响 |
|-|-|-|-|
| **Blocker** | 游戏不可继续 / 0 报错不达标 / 启动崩溃 | 软锁（RG-6 复现）、`SCRIPT ERROR`、无法下楼、纯净启动崩溃 | **FAIL，P0 门不放行** |
| **Critical** | 核心功能完全不可用 / P0 门缺陷复现 | `Invalid access to property or key` 面板崩（RG-7）、S-01/03/04 任一完全不生效、自检 `✗` 失败、新 kind 走 combat 分支锁门 | **FAIL，P0 门不放行** |
| **Major** | 主要功能受损但不阻断 | 状态图标不刷新、稀有掉落重复/缺失、小地图白块/颜色错、基线过门数越界、`KNOWN_ROOM_KINDS` 漏检、SMOKE 挂钩未覆盖新 kind 导致覆盖缺口 | CONCERNS（若 P0 门已过） |
| **Minor** | 观感 / 文案 / 对齐 | 图标偏移、toast 措辞、房间标记不统一 | CONCERNS 或 PASS 附清单 |

**不列为 Bug 的观察项（阶段 B 单独成章，不阻断）**

- **E1 护盾抵挡伤害不 `emit damaged`**（`player.gd:459-464`）：设计侧明确「本轮不动、只留痕」的跨 Story 一致性问题（S-03 × S-04）。报告记入「已知风险 / 观察项」，**不得列入 Bug 清单、不得作为 FAIL 或 CONCERNS 依据**。
- L4 Playtest 未组织、L3 无 GUI 环境的证据 MISSING：按 §二 只作 CONCERNS 标注，不单独构成缺陷。
- 实现与设计侧推荐选项（P/Q/R/L/M/E）不一致时：QA 不臆造验收点，先回报 team-lead 确认口径，不直接判 Bug。

**Bug 报告模板**（每条必填）：
```
[BUG-<编号>] <标题>            严重度：Blocker/Critical/Major/Minor   优先级：P0/P1/P2
环境：Godot 4.7.2.steam / 种子 N / 帧数 N / 命令（完整可复制）
前置：<进入条件，如已获得 guard 升级 / 已炸开超级秘密墙>
步骤：1. … 2. … 3. …
预期：<具体、可观测>
实际：<具体、可观测，附日志行原文>
日志证据：_tools/spr3_qa_<用例>.log 第 N 行 `<原文>`
影响范围：<关联 Story / 用例编号>
建议定位：<文件:行 或 待测假设，不臆造结论>
回归用例：<修复后必须补跑的用例编号>
```

---

## 十、放行判据（阶段 B 报告必须给出明确判定）

**P0 放行门（硬门，任一不过即 FAIL）**
1. RG-6 全过：秘密墙 / 超级秘密墙爆破重建后 `_doors` 全 unlocked，能正常过门下楼层，无软锁，且 S-01 无绕过解锁段的重建路径；
2. RG-7 全过：新增图标全走 `Assets.xicon`，不存在 key 请求返回白图 + `[assets] 图标缺失` 且不抛异常，升级面板/HUD 0 报错；
3. 全部阶段 B 用例 0 报错：`SCRIPT ERROR` / `Parse Error` / `Invalid access to property or key` = 0。

| 判定 | 条件 |
|-|-|
| **PASS** | P0 门全过 + §六 B-1~B-8 基线全达标 + **B-11 S-01 专项 ADEQUATE（X1~X7 均有证据）** + S-01/S-03/S-04 验收点全过 + 无 Blocker/Critical + L3 证据 ADEQUATE 或已标注可接受的替代 |
| **CONCERNS** | P0 门全过且 0 报错，但存在 Major/Minor 未修、L3/L4 证据 MISSING、SMOKE 挂钩/负向探针/B-11 专项存在覆盖缺口，或 S-04 保底仅部分满足 D1（+30 分 + toast）口径 / 四条倒挂红线（须逐条列明并给修复建议） |
| **FAIL** | P0 门任一不过；或任一基线用例不达标（含过门数越界、未到第 2 层、`secret revealed` 缺失）；或存在 Blocker/Critical（含 `dungeon.gd:130` 被误改、超秘进房锁门、自检 `✗`）；或日志未能真实读取（超时 ≠ 通过） |

> **不计入判定的项**：E1 护盾抵挡不计掉血（§一 / §九 / S-04 D7）为已知风险 / 观察项，**不触发 FAIL、不列入 Bug 清单**；阶段 B 报告须单列「已知风险 / 观察项」章节留痕。
> 判定为建议性门控：QA 给结论，**最终放行由用户决定**；发布签字须人工审批。

---

## 十一、阶段 B 执行清单（收到 T1 完成通知后按序执行）

1. 建 `_tools/`，确认工程无并发写入。阶段 B 前置已由 team-lead 放行通知 + 最终裁定给定：**选型 I 独立新 kind `super_secret`**、新增图标 key `guard/chain/venom`（无新 PNG）、自检期望房间 9、`reveal_secret` 覆盖超秘、**S-04 以当前磁盘 D1（+30 分）为最终版不返工**、B-11 用种子 4（无专用环境变量）。**唯一放行证据为冻结快照上重跑的 `spr3_qa_*_final.log` 组**（早期 14 份 `spr3_*.log` 只作历史记录）；md5 前后比对须 `HASH_STABLE=YES`，期间若发现任何 mtime 变化立即停下报 team-lead。QA 按此设探针，不臆造。
2. 静态检查 S-1~S-15（§七）+ **§7.4 十处契约同步点逐项勾选**（含 S-13 `dungeon.gd:130` 防误改、S-15 E1 观察项登记），结果写入报告「静态审计」章节。
3. 先跑 B-8 纯净启动 + B-10 SMOKE_DUMP（短用例，快速暴露 Parse Error / 门锁 / 缺图），**失败即停并回报 team-lead**。
4. 跑 B-1~B-6（6 条 9000 帧，单条显式 `timeout: 300000` 或后台任务 + `TaskOutput` 取回完整输出）。
5. 跑 **B-11 S-01 固定种子专项**：按选定规则确定种子（记录地图 kinds 原文），按实现选型核对 X1~X7；「未观察到超秘房」必须区分合法跳过 vs 挂具未覆盖，**不得直接判 PASS**。
6. 跑 B-7 死亡链路、R7-5 图标负向探针、B-9 截图（若环境允许窗口模式）。
7. 逐日志用 Grep（count / content）核对 §三 判据关键字与 §六 期望值，填「逐项证据表」；额外核对 S-04 的 `Game.add_score(30)` / 专属 toast / 满血分支逐字未动 / 四条倒挂红线、`SMOKE_CHALLENGE_FAIL` 探针日志、`secret revealed` 计数口径（B-11，2–5）、**种子 1–6 逐层 `[SMOKE-SUPER]` 断言与实际层数/跳过情况（追加检查点 X8）**，以及常态基线不产生 `[assets] 图标缺失` 告警。
8. 产出 `tests/SPR3_测试报告.md`：判定（PASS/CONCERNS/FAIL）、逐项证据、Bug 清单（按 §九 模板）、覆盖缺口、**「已知风险 / 观察项」单章（E1 护盾，明确不阻断）**、待用户审批项、下一步建议。
9. SendMessage 回传 team-lead 判定与证据，并把任务 #2 标 completed。

**日志命名汇总**：`spr3_qa_seed1..6.log`、`spr3_qa_s01_super.log`（+ 可选 `spr3_qa_s01_super_seedN.log`）、`spr3_qa_death.log`、`spr3_qa_plain.log`、`spr3_qa_rg6_dump.log`、`spr3_qa_rg7_probe.log`、`spr3_qa_shots.log`、`spr3_qa_static.log`（静态审计记录）。

---

## 十二、已知风险与待澄清（须 team-lead 转达 T1，QA 不臆造验收点）

1. **实现选型未定**：S-01 用独立新 kind 还是复用 `secret` + 标记字段？直接决定 §七 7.2 自检计数期望（8 还是 9）与 S-3~S-6 静态清单判法。**请 T1 交付说明中明确**。
2. **SMOKE 挂钩四处硬编码 `"secret"`**（`game_main.gd:656/1039/516`、`hud.gd:353`）：若用新 kind 而未同步，超级秘密墙不会被炸、自动驾驶不会进房，`secret revealed` 仍可能靠普通秘密房达标，形成**假通过**。请 T1 确认覆盖方式，或提供可复现触发手段（如专用环境变量 / 固定种子），否则 R6-8 只能标覆盖缺口。
3. **`hud.gd:415-421` `_icon_label()` 用 `Assets.icon()` 直接查表**：S-03 若复用该函数传新 key 会原地复现 RG-7。建议新增 HUD 专用取图函数走 `Assets.xicon()`。
4. **`_enter_room` 的 `match kind` 白名单**（`game_main.gd:354`）：新 kind 未加入清场组会走 combat 分支锁门刷怪，属 Critical，请 T1 自检。
5. **`validate.gd:7 KNOWN_ROOM_KINDS` 与 `:82` 图标 key 数组为硬编码**：新增 kind / 图标未登记会造成自检漏检，建议同步扩展。
6. **新 PNG 的 `.import`**（§五-4）：请 T1 确认已 `--headless --import`，否则 `load()` 返回 null，图标显示白图/棋盘格。
7. **阶段 A 期间代码持续变动**：本文件所有行号基于阶段 A 实读快照，阶段 B 以实际代码为准重新定位，行号漂移不视为缺陷。
8. **E1 护盾观察项（不阻断）**：`player.gd:459-464` 护盾抵挡不 `emit damaged` → 带护盾硬吃一下仍算无伤通过。设计侧 E1「本轮不动、只留痕」，team-lead 中转明确**不得列为阻断**；阶段 B 只登记、不判 Bug、不计入 FAIL（§一 / §九 / S-04 D7 / S-15）。
9. **防误改点与设计侧 10 处契约同步点**：`dungeon.gd:130` 的 `cnt >= 2` 不得改成 `cnt == 1`（普通秘密房已完成规则，误改 = Critical）；10 处契约（含 `validate.gd:7`、`data.gd:113`、`hud.gd:375/:330`、`game_main.gd:661/:466/:516/:1044/:354`、`hud.gd:353`）任一漏改表现为「生成了但看不见 / 炸不开 / 自检报错」，已并入 §7.4 与 S-3/S-13/S-14。
10. **`secret revealed` 计数口径**：设计侧 §7 指出新增超秘后「秘密房 2」是否应变 3 取决于是否把超秘计入同字段。请 T1 说明 `reveal_secret`（`game_main.gd:466-477`）的打印是否覆盖超秘；QA 按 B-11 记录实际计数并与专项证据对齐，不用旧计数反推通过。
11. **S-04 口径最终裁定（team-lead）**：**以当前磁盘 D1（`Game.add_score(30)` + toast「挑战失败 · 保底 +30 分」+ 日志 `consolation +30 score`）为最终版，不返工改回 3 源石**。四条理由见 §八；四条倒挂红线仍成立，满血分支 `game_main.gd:327-334` 逐字未动。QA 按 D1~D7（§八）核验。版本事件根因是**编排层沟通口径未同步（流程事件，非成员 Bug）**：3 源石裁定只发给 QA 与设计侧，engineering-lead 收到的是 D1 口径，责任在编排层，如实记录但不记为任何成员的 Bug。设计侧 P/Q/R/L/M/E 其余待拍板项同理，不按推荐值倒扣。
12. **自动验收覆盖缺口的处置**：B-11 是 S-01 唯一自动证据；若 T1 既未扩展 SMOKE 挂具、也未提供可复现触发手段，则阶段 B 只能标**覆盖缺口（Major → CONCERNS）**并逐条列明，不得默认通过。
