# Sprint 7 交付报告：局外 meta 进度 + 解锁树

> 交付时间：2026-11-06｜工程：`D:\Create\Game\test-1`｜引擎：Godot 4.7.2.steam
> **总判定：PASS（本批门禁全过，0 `SCRIPT ERROR` / 0 `Parse Error`）**
> 冻结版本：`SPR7-FROZEN-3`（最终脚本 md5 见同目录 `SPR7-FROZEN-3.md5`）
> 权威源：`Sprint7_解锁树规格.md` **v2.10（已冻结，定义）** + `SPR7_QA计划与用例.md` **v4.6（状态）**

---

## 一、本轮做了什么

Sprint 7 的目标是「局外 meta 进度 + 解锁树」：玩家在局外用**结晶源石**购买解锁节点，解锁只**扩容池子**，不写玩家初始字段；基础 14 升级 / 10 遗物 / 4 武器永远默认可用，新档不会被锁死。

本轮收口阶段由主理人直接接手（团队 `quality-lead` / `engineering-lead` 因 429 额度失败，见 §八），一次性完成：

1. 一次性原子补丁 18 处（改前全量备份 `_backup/spr7_lead_pre_final/`）；
2. headless Godot 实跑 20+ 次，覆盖六种子、两档解锁状态、4 种坏档模式、结算与退出路径；
3. 修正 5 个**真实缺陷**（其中 3 个是「日志显示成功、实际静默失效」的假通过，详见 §五）；
4. QA 状态视图升级 v4.6，规格 v2.10 保持冻结不动；
5. 补跑六种子 × 9000 帧全量矩阵、L3 UI 走查、V11 零污染、V14 回归；
6. 补齐 **G7 四态文案 / 买不起禁用态**、**G12 解锁页图标 + 三段 resolver**，并把**开局页**从「居中标题 + 一列按钮」重构成专属左右分栏版式（不再像暂停/设置页）。

---

## 二、实现清单（相对规格 §11.2 的 G 编号）

| 项 | 内容 | 状态 |
|---|---|---|
| G1 | `meta.gd` 8 项增量解锁表，总价 **500**（40/60/100/40/60/40/60/100） | ✅ |
| G2 | `ECONOMY` 六常数：rate 0.10 / floor_bonus 8 / kill_bonus 0 / run_cap 60 / min_floor 1 / min_seconds 45 | ✅ |
| G3 | `assets.gd:GEN_NAMES` 登记 4 个自创图标 | ✅ |
| G4 | 三池扩至 **17 / 12 / 7**，8 条新池条目全带 `"meta"` 冗余字段 | ✅ |
| G6 | 局外字段 `diamonds → crystals`；局内 `Game.diamonds` 与 `to_dict()` 未动 | ✅ |
| G13 | `Game.max_floor` 追踪到达过的最深层 | ✅ |
| G5 | 新解锁升级卡 3 局 ×6 引导加成（叠加 ×1.5 → ×9），遗物/武器无 boost | ✅ |
| G11 | `_floor_rng(floor_num)`：`hash(run_seed:层号)` 派生 RNG，`dungeon.gd` 内 `Game.rng` 0 命中 | ✅ |
| G15 | 规格 §11.2.1 定义的 **15 行探针全部落地**，逐字串一致 | ✅ |
| E8′ | 三个抽卡入口无条件消耗固定个数（见 §五-1） | ✅ |
| E8″ | 三入口运行时计数探针（门禁） | ✅ |
| G10 | 主动退出确认页 + `SMOKE_META_QUIT` | ✅ |
| 自检 | `validate._check_meta()` 字段/环/target/图标/默认可用阈值/未门控基础条目 | ✅ |
| G7 | 解锁页四态文案（已解锁 / 前置未满足 / 需要 N（还差 M） / 可解锁 · N 结晶）+ 买不起禁用态 | ✅ |
| G12 | `TextureRect` 图标 + `meta_icon()` 三段 resolver + `unlock icons resolved=8/8` 行为式断言 | ✅ |
| 开局页视觉 | `main` 专属左右分栏 / 大标题 / 金色装饰线与菱形 / 主按钮金色描边；其他页切页复位通用骨架 | ✅ |
| **G8** | **购买二次确认 `ConfirmationDialog`** | 🟡 **未实现（遗留）** |
| **G9** | **结算面板 5 行 + 数字滚动 Tween** | 🟡 **未实现（遗留）** |

**启动自检**：`[SMOKE] validate problems=0` + QA §8.3 的两条格式串逐字不变。

> 格式串内的 `%d` 由 `validate.gd` 的 `Data.*.size()` / `META.UNLOCKS.size()` 动态推导，**本文件不复述具体数值** —— 复述会随内容扩充立刻过期（治理规则①）。

---

## 三、实测证据（全部 headless，命令可复跑）

引擎：`D:\SteamLibrary\steamapps\common\Godot Engine\godot.windows.opt.tools.64.exe`

| 验证项 | 命令要点 | 实测结果 |
|---|---|---|
| 改动前基线 | `SMOKE=1 SMOKE_SEED=1 --quit-after 600` | exit 0 / `problems=0` / 0 script error |
| 全探针（默认档） | `SMOKE_META=1 SMOKE_RUN_START=1 SMOKE_META_RNGCOUNT=1 SMOKE_META_QUIT=1` | `run start diamonds=0 taken=0 modifier=swarm`；`rng count upgrades=60 relics=40 weapons=20`；`quit estimate=28 reason=cancel` |
| 全探针（全解锁档） | 追加 `SMOKE_META_UNLOCK=all` | `unlocked=8`；**三个计数与默认档逐字相同**；fingerprint 一致 |
| **E1 地图解耦** | 两档 `SMOKE_SEED=1 --quit-after 9000` | **第 1、2 层** `rooms=` / `kinds=` 逐字 `diff` 退出码 **0** |
| **E8″ 消耗守恒** | `SMOKE_META_RNGCOUNT=1`，六种种子 | 6/6 均为 `60/40/20`，0 报错 |
| 六种子回归 | `SMOKE_SEED=1..6 --quit-after 1200` | 6/6 exit 0、`SCRIPT ERROR`=0、`validate problems=0` |
| 坏档 4 模式 | `SMOKE_META_CORRUPT={...}` 各独立进程 | 四种**各自**的 WARN 全命中 + `corrupt fallback=OK`，见下 |
| 结算链路 | `SMOKE_DEATH=1 SMOKE_META_SETTLE=1 SMOKE_META_SETTLE_STATS=diamonds=120,kills=60,max_floor=3,time=120` | `settle payout=28 balance=28`；落盘 `best_floor=3` |
| boost 状态机 | `SMOKE_META_BOOST=1 SMOKE_META_UNLOCKTEST=1` | 8 节点扣费合计 500；`remaining=3 → 2`；遗物/武器无 boost |
| 命名口径 | `grep "\[SMOKE-META\].*diamonds"` | **只命中 `run start` 一行**（唯一例外），无串味 |
| **六种子 × 9000 帧矩阵** | `spr7_matrix/` 六种子 × 两档 | 12/12 `errors=0`、`validate0=1`、`loop=0`；**按共同楼层复核 E1 6/6 逐字一致** |
| **L3 UI 走查** | 带窗口截图 `spr7_ui_*.png` / `spr7_state_*.png` | 解锁页 8 图标全显示、四态文案逐字命中、退出确认页文案对齐规格 §4.2 |
| **最终冻结版回归** | `spr7_f3_*.log` + `spr7_f4_*.log`（切页 / 全探针两档 / 六种子 / 长帧 E1 / 结算链路 / V14） | 全部 `errors=0` / `validate problems=0`；结算文案改「结晶」后 `settle payout=28 balance=28` 仍逐字不变 |
| V11 零污染 / V14 回归 | 独立复核 | 玩家 `meta.cfg` 跑前跑后均不存在；`rg7`/`save`/`death`/`dump` 全 0 报错 |

**坏档 4 模式逐字结果**

| 模式 | WARN |
|---|---|
| `missing_field` | `[WARN] meta: 缺失字段已补默认：crystals, unlocked, …` |
| `bad_type` | `[WARN] meta: meta 存档读取失败（err=43），使用默认值` |
| `unknown_id` | `[WARN] meta: 丢弃未知解锁 id 1 个` |
| `bak_fallback` | `[WARN] meta: meta 主存档不可用，已回退 .bak` |

---

## 四、门禁判定

| 门禁 | 判据 | 结果 |
|---|---|---|
| **E1** | 同代码 / 同 run_seed / 全新档 vs 全解锁档 → **按共同楼层**逐层 fingerprint 逐字 diff 为空；**单侧独有楼层不判差异** | ✅ PASS（六种子 6/6，最终冻结版另跑一组长帧确认） |
| **E2 / E3 / E9** | `DungeonClass.generate` 第 2 实参 ≠ `Game.rng`；`run_seed` 一次性捕获；`dungeon.gd` 内 `Game.rng` 0 命中 | ✅ PASS |
| **E8′** | 三入口 `randi_range` 参数不得可能相等；空池不得 `break` 跳过消耗 | ✅ PASS（统一 `randi() % maxi(n,1)`） |
| **E8″** | 运行时三计数器，两档逐字相同 | ✅ PASS（60/40/20，六种子一致） |
| 基础盘五件套 | 0 script error / 0 `[ERR] meta:` / 余额回默认 / 空解锁集 / 有效升级池 ≥ 3 | ✅ PASS |
| **E5 / E6** | 表现层随机污染、真实 delta 墙钟依赖 | ⏭ **下一批门禁**（本轮不判，见 §八） |
| **E7 / V16** | 全日志逐字可复现 | ⓘ **信息性**，不判 FAIL |

> 判据职责分离：**E1 证明地图与解锁解耦；E8′/E8″ 证明抽卡入口消耗守恒**。地图已完全独立于 `Game.rng`，所以 fingerprint 一致**不能**反推消耗守恒，两者不可互相替代。

---

## 五、本轮发现并修复的真实缺陷

1. **三处 `randi_range(a,a)` 退化**（E8′）：`weapons.gd` 空/单元素池、`relics.gd` 末轮 `pool.size()==1`、`upgrades.gd` `total==1`。Godot 4.7 实测 `randi_range(0,0)` **不消耗随机流**，导致解锁状态改变随机流位置。统一改为 `randi() % maxi(n,1)`（恒消耗 1 次），空池用 `continue` 而非 `break`。
2. **坏档探针假通过**：`bad_type` / `bak_fallback` 原本写 `<<<not a valid config file>>>`，但 `ConfigFile.load()` 对纯垃圾行**返回 OK（err=0）** 并静默忽略 → `corrupt fallback=OK` 照打，指定的「读取失败」/「回退 .bak」WARN 永不触发。独立探针实测 `err=0`（垃圾行）vs `err=43`（`[meta]` + 未闭合字符串），已改用真正不可解析内容。
3. **`best_floor` 恒为 0**：`meta_settle_run()` 读 `stats["floor"]`，而 `_settle_meta()` 传的键是 `max_floor`。已对齐，落盘实测 `best_floor=3`。
4. **结算余额恒为 0**：`meta_settle_run()` 返回 `{"crystals": ...}`，调用方读 `r.get("diamonds", 0)`。已改为 `"crystals"`，实测 `balance=28`。
5. **boost 一局双减**：死亡结算内部递减一次，点「返回主菜单」又递减一次。新增 `_boost_ticked` 每局一次性守卫，`restart()` 也纳入。

另修：两处**注释型副本漂移**（`validate.gd` 声称 `meta` 写错会「买了却进不了池」，但运行时门控不读它；`weapons.gd` 声称恒消耗 1 次而实现做不到）。

**收口补跑阶段又抓到 2 个「假象」问题**：

6. **E1 全量 diff 假 FAIL**：六种子矩阵 seed 4 报 `E1-diff=FAIL`，实查是 default 档在 9000 帧内只到第 1 层、all 档到了 2/3 层，全量 `diff` 把**单侧独有楼层**算成差异；楼层数是终态量，与此前收回的 `use_door` 同类。裁定改为「按 floor 交集逐层比对」后 6/6 逐字一致，判据已写回 QA §6.1.1 / §7.2 / V3b。
7. **静默白框无法靠肉眼断言**：`TextureRect.texture = null` 不报错、画面只是空白。补 `[SMOKE-META-EXTRA] unlock icons resolved=8/8` + `Dev.check(...)`，把「看起来没图标」变成可测项；四个开局按钮图标同样走三段 resolver，解析失败只留白不抛异常。

8. **开局页改造引发切页布局回归（0 报错抓不到）**：`_build_main_page()` 把 `_center` 设为 `PRESET_FULL_RECT`，而 `show_page()` 复位只调 `set_anchors_preset(PRESET_CENTER)`；该 API 默认 `keep_offsets=false`，会自动补偿 offsets 让容器**保持全屏矩形** → 设置/解锁页的按钮被拉成 100% 宽、设置项整体左移。headless 回归 12/12 `0 SCRIPT ERROR` 完全没发现，是 L3 带窗口截图实看才抓到。修法：复位时把 `_center` 的 4 个 offset 硬置 0，让 `grow BOTH` 按内容最小尺寸重新居中；修复后五页截图逐张复核通过。**教训：布局类改动必须截图，日志 0 报错不等于画面正确。**

---

## 六、文档治理（本轮最终形态）

| 文件 | 版本 | 职责 |
|---|---|---|
| `Sprint7_解锁树规格.md` | **v2.10 冻结** | 唯一**定义**源：阈值、探针逐字串、表结构、判据 |
| `SPR7_QA计划与用例.md` | **v4.6** | 唯一**状态**源：§7.1 状态视图、§0.1b 闭环表、§7.5 残留项、§十二 V 表 |
| `SPR7-FROZEN-3.md5` | **最终** | 脚本 md5 冻结清单（FROZEN-1 / -2 为历史，不再作为放行依据） |

三条规则贯穿全程：① 文件内数字可写、跨文件引用数字不写；② 定义归规格、状态归 QA；③ **逐字日志串只存一份**（在规格 §11.2.1），QA §七 只留指针。表外探针统一前缀 `[SMOKE-META-EXTRA]`，不参与逐字断言、不污染计数。

v4.4 曾有「E8″ 计数探针可选」的表述，与最终裁定冲突 → v4.5 已作废并改为门禁；规格本身未改一字。

v4.6 只动 QA 的**状态**：补 G7/G12 闭环、开局页视觉、E1 共同楼层判据、六种子矩阵与 L3 证据；**规格 v2.10 仍冻结，一个字未改**。另按规则①（跨文件引用数字不写），本报告与交接稿不再复述 md5 具体值，一律只引用清单文件名。

---

## 七、冻结版本与证据索引

最终冻结清单：`production/sprint-7/SPR7-FROZEN-3.md5`（`md5sum -c` 全部 OK）。

> **不在本文件复述校验和**：md5 会随每次改动整列失效，跨文件抄一份就等于多一份必然漂移的副本（文档治理规则①）。要看数值直接读清单文件本身。

放行证据（`D:\Create\Game\_tools\`）：`spr7_lead_baseline.log`（改前）、`spr7_final_default.log` / `spr7_final_all.log`（全探针两档）、`spr7_e1_9k_default.log` / `spr7_e1_9k_all.log`（E1 两层）、`spr7_corrupt3_*.log`（4 模式）、`spr7_settle.log`（结算/boost）、`spr7_seed1..6.log`（六种子）、`spr7_final2.log`（收口复跑）；**本轮补跑**：`spr7_matrix/`（六种子 × 两档 × 9000 帧）、`spr7_frozen2_*.log`（G7/G12 后）、**`spr7_f3_*.log` / `spr7_f4_*.log`（最终冻结版全量回归与命名补丁后复跑）**、`spr7_ui_*.png` / `spr7_state_*.png`（G7/G12 阶段四页 + 三态）、**`spr7_f4_{main,unlocks,settings,pause,quit_confirm}.png`（与 FROZEN-3 同代码的最终五页）**、`spr7_main_before.png` / `spr7_main_final.png`（开局页改造前后）。
`SPR6` 及更早日志为历史产物，**不得引用为本轮放行证据**。

---

## 八、诚实披露：未覆盖 / 遗留

| 项 | 状态 |
|---|---|
| 六种子 × **9000 帧**全量矩阵（QA V3/V4） | ✅ **已补跑**（`spr7_matrix/`）；12/12 0 报错。seed 4 全量 diff 假 FAIL 已定位，按共同楼层 6/6 逐字一致 |
| L3 手动 UI 走查（V13） | ✅ **已补跑**（带窗口截图）；四页 + 解锁页三态 + 图标 8/8；⚠️ headless 下 `get_viewport().get_texture()` 为 null，**截图必须带窗口**，否则探针自身会报 `save_png on null` |
| **G8** 购买二次确认 | 🟡 **未实现**：`_try_unlock()` 仍直接落盘；补丁脚本名曾写「G712」，容易误判为已做 |
| **G9** 结算面板 5 行 + 数字滚动 Tween | 🟡 **未实现**：`hud.gd` 追加位仍在 |
| V8 空池拦截显式用例 | ⚠️ 未单独构造，由启动自检静态阈值覆盖 |
| **E5**：相机抖动 + 4 处音效音高仍用 `Game.rng` | 🔴 下一批门禁，未改 |
| **E6**：`Game.time += delta` 仍是真实 delta | 🔴 下一批门禁，未改 |
| **E7 / V16**：同 seed 三次全日志 diff 非空 | ⓘ 根因是上面两条墙钟依赖，本轮信息性记录、不判 FAIL |
| `SMOKE_META_QUIT` 的「确认退出」分支 | 探针只打印 `reason`，**不真的重载场景**（`_ready` 里 reload 会无限重启）；确认框 UI 走查属 V13 |
| 团队编排 | `quality-lead` / `engineering-lead` 因 429 额度失败，本轮收口由主理人直接完成；`design-strategist` 已 completed。团队目录已清理、无共享任务、无后台 Godot 进程，三位成员产出全部落盘 |

> 退出期 `ObjectDB instances were leaked` / `resources still in use` 为引擎 `--quit-after` 强杀提示，**改前基线同样存在**，不计入判据。
