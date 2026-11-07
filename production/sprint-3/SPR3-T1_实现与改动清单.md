# SPR3-T1 实现与改动清单（SPR3-FROZEN-1 冻结版订正）

> 角色：engineering-lead（程基岩） · 冲刺：Sprint 3 · 日期：2026-11-05
> 版本标识：**SPR3-FROZEN-1**（主理人已记录哈希并冻结）
> 范围（用户已拍板，未扩）：S-01 超级秘密房 / S-03 HUD 状态图标 / S-04 挑战房失败保底奖励
> 明确不做：S-02 精英词缀扩展、S-05 道具合成/武器铭刻、S-06 逐帧动画
> 引擎：Godot 4.7.2.steam；工程：`D:\Create\Game\test-1`
>
> **证据状态声明**：本文按当前磁盘上 SPR3-FROZEN-1 的代码订正事实。开发阶段产生的 `_tools/spr3_*.log`（我方 15 份）**全部是两处最终补丁之前的产物，不作放行证据**；最终放行以 quality-lead 在唯一冻结版本上重跑 B-1~B-11 的结果为准。本文不代 QA 下「最终版本 0 报错」的结论。

---

## 一、版本事件（如实记录，供 QA 对齐证据链）

| 时间 | 事件 |
|-|-|
| 14:31 | 改前备份 7 个原稿到 `_backup/spr3/` |
| 14:31–14:58 | round-1 实现 + 首版实现清单（该版方案后来按补充约束全部改写，详见第四节；此处不复用其描述） |
| 15:02–15:04 | 按 QA 阶段 A 与设计规格补充约束改代码：S-04 改 D1、S-03 改 20px + 未获得隐藏、S-01 改严格 Q 选格 |
| 15:18:04 | `game_main.gd` 加入 `NAVDBG` 自动驾驶诊断插桩（仅调试，之后已移除） |
| 15:23:33 | `game_main.gd` 移除全部 NAVDBG 插桩 |
| 15:23:46 | `dungeon.gd` 落地 `_is_special_room()` 循环修复，缓解自动驾驶多房震荡（BUG-001） |
| 阶段 B 期间 | 上述跨版本代码改写导致 QA 的 md5 前后比对 `HASH_STABLE=NO`、证据链断裂 |
| 15:34 | 主理人冻结工程，授权最后两处补丁；备份 `_backup/spr3/game_main.gd_p2`、`_backup/spr3/hud.gd_p2`（**未覆盖** 14:31 的同名原备份） |
| 15:35 | 补丁 1（`game_main.gd:318` 注释）+ 补丁 2（`hud.gd` 遮罩穿透）落地；此后未写任何代码、`_tools` 日志或文档，直到本次授权补写本文件 |
| 冻结后 | 主理人记录哈希 **SPR3-FROZEN-1**；QA 在该唯一版本上统一重跑 B-1~B-11（md5 前后 YES）并复验 15:23 的循环修复 |

**因此**：
- 首版文档（14:57 版）描述的三条 Story 方案均已过时，本文按 SPR3-FROZEN-1 代码全部订正；旧表述不作为验收依据。
- `_tools/spr3_*.log`、`_tools/spr3_intermediate/`（15 份中间诊断日志）均为补丁前或跨版本产物，**不得作为放行证据**。
- `_tools/spr3_qa_*.log` 为 quality-lead 自有产物，本文件不引用、不评价、未改动。
- 两处最终补丁按主理人指令**未由我方运行任何 Godot 命令**，其运行期验证（尤其 HUD 遮罩不穿透）由 QA 在冻结版本上完成。

---

## 二、改前备份（用户硬规矩）

`_backup/spr3/` 保留两代原稿，互不覆盖：

| 文件 | 14:31 原稿 | 15:34 `_p2` 快照 | 是否实际改动 |
|-|-|-|-|
| `dungeon.gd` | ✅ | — | 是 |
| `data.gd` | ✅ | — | 是 |
| `game_main.gd` | ✅ | ✅ | 是 |
| `hud.gd` | ✅ | ✅ | 是 |
| `validate.gd` | ✅ | — | 是 |
| `assets.gd` | ✅ | — | 否（预防性备份，`cmp` 校验与现稿一致） |
| `upgrade_panel.gd` | ✅ | — | 否（预防性备份，`cmp` 校验与现稿一致） |

另有 `_backup/spr3/round1/`（14:31 之后、补充约束之前的 5 个文件快照），用于逐 Story / 逐轮独立回退。

改动**只落在 `scripts/`**，没有碰 `project.godot`、场景、贴图、音频，也没有碰 `D:\TESST` / `D:\大纲`。
本轮**没有新增任何 PNG**：三个状态图标复用既有 `icon_guard / icon_chain / icon_venom`（已有 `.import`），因此 §五-4「新 PNG 必须先 `--headless --import`」**不触发**。

---

## 三、改动清单（SPR3-FROZEN-1 最终行号）

| 文件 | 行号 | 改动内容 | Story |
|-|-|-|-|
| `scripts/dungeon.gd` | 6 | `NO_CELL` 哨兵，替换两处 `Vector2i(999,999)` 魔法数 | S-01 |
| | 101–103 | 普通秘密房放置逻辑**原样保留** | 防误改 |
| | 105–113 | 追加 1 间 `super_secret`；`Dev.check(neighbors==1)`；SMOKE 打印 `[SMOKE-SUPER] ... neighbors=1` | S-01 |
| | 127–143 | `_find_secret_cell()`：**`cnt >= 2` 未动**（:141），`return NO_CELL` | 防误改 |
| | 149–170 | `_find_super_secret_cell()`：确定性遍历、不消耗 rng、不做 2×2 校验（与普通秘密房一致） | S-01 |
| | 173–175 | `_is_special_room()`：排除 `treasure/shop/boss/secret/super_secret`，其余正常可达房（含 `start`）可挂 | S-01 / BUG-001 |
| `scripts/data.gd` | 121 | `ROOM_META` 增 `super_secret`（金色），`Data.room_color(kind)` 有值 | S-01 |
| `scripts/game_main.gd` | 67、354、1092–1094 | `_secret_bombed` 布尔改 `_secret_bombed_dirs` 字典：一帧只炸一面墙、同房间可逐帧炸多面，避免同帧重复 `_build_arena` | S-01 / 坑 6 |
| | 133–137 | `SMOKE_RG7=1` 让 `upgrade_panel._icon_for()` 查不存在的 key，验证面板不崩 | 坑 7 测试 |
| | 173–177 | `SMOKE_STATUS=1` 强制非零状态值，验证 HUD 刷新 | S-03 测试 |
| | 318 | 注释订正：「掉血：普通掉落 + 保底 +30 分；无伤：额外遗物 + 大宝箱」 | S-04 补丁 1 |
| | 319–334 | S-04 **D1**：`Game.add_score(30)` + toast「挑战失败 · 保底 +30 分」+ `[SMOKE] challenge failed (consolation +30 score)`；原有 3 颗随机钻石保留；无伤分支逐字未动 | S-04 |
| | 368 | `_enter_room` 清场白名单加入 `super_secret`（否则会落 combat 锁门刷怪） | S-01 |
| | 389–395 | `SMOKE_CHALLENGE_FAIL=1` 探针（SMOKE 默认无敌，掉血分支否则不可达） | S-04 测试 |
| | 420–433 | `super_secret` 首次进入发 R1 稀有掉落：大宝箱 + 2 遗物 + 12 源石；独立 `super_loot_taken` 防重刷 | S-01 |
| | 467–468 | SMOKE 打印进入超级秘密房 | S-01 测试 |
| | 505–517 | `reveal_secret` 按邻居 kind 区分提示；打印 `[SMOKE] secret revealed at ... kind=...`；`SMOKE_DUMP` 下打印 `[RG-6]` 门锁转储 | S-01 / 坑 6 |
| | 550–559 | 自动驾驶 BFS 目标纳入已揭示的 `super_secret` | S-01 |
| | 697–708 | `_build_arena` 秘密墙判定同时认 `secret` / `super_secret` → 超秘墙仍是 `SecretWall`，**只吃炸弹** | S-01 / 坑 6 |
| | 724–731 | 坑 6 原解锁块**原样保留**，仅加注释与 SMOKE 下 `Dev.check(not d.locked)` 断言 | 坑 6 |
| | 735 | 障碍物分组 `["combat","elite","challenge"]` **未动**，超秘房不刷障碍 | QA 静态检查 |
| | 1077–1100 | `_smoke_secret_tick` 同时识别两类隐藏房 | S-01 |
| `scripts/hud.gd` | 5–9、42–44 | `STATUS_DEFS`（guard/chain/venom）+ 状态控件数组 | S-03 |
| | 174–175 | **`_build_status_ui(root)` 移到两个 `_overlay` 之前**，状态条不再浮在结算/暂停遮罩之上 | S-03 补丁 2 |
| | 330–358 | `_build_status_ui()`：图标 **20×20**、全部走 `Assets.xicon(key)`、单项初始 `visible=false`、整条初始 `visible=false` | S-03 |
| | 361–375 | `_refresh_status()`：每帧显示 `护盾 ×N / 连锁 N% / 淬毒 N%`；**三项全 0 时整条隐藏（不占位）** | S-03 |
| | 467 | `_process` 调用 `_refresh_status(p)` | S-03 |
| | 391–393 | `set_room_info` 加 `· 超级秘密` | S-01 |
| | 416–417 | 未揭示的 `secret` / `super_secret` 都不上小地图；颜色仍走 `Data.room_color(kind)` | S-01 / §五-8 |
| | 438–439 | 小地图标记表加 `super_secret: "*"` | S-01 |
| | 481 | `_icon_label()` **未改**，仍是 `Assets.icon(key)`，既有 bomb/face/diamond 图标用途不受影响 | 坑 7 |
| `scripts/validate.gd` | 7 | `KNOWN_ROOM_KINDS` 加入 `super_secret` | S-01 / 计数核实 |
| | 9、21、86、92–101 | `STATUS_ICON_KEYS`；`_check_icons()` 用 `STATUS_ICON_KEYS + ["dice"]` 集中登记；`_check_status_icons()` 走 `xicon` + RG-7 白图回退探针 | S-03 / 坑 7 |

按 hunk 可独立回退：S-01 集中在 dungeon/data + game_main 房间分支；S-03 集中在 hud 状态条 + validate 图标检查；S-04 只有 game_main 挑战结算一个分支。

---

## 四、三条 Story 实现要点（按冻结代码订正）

### S-01 超级秘密房（只连 1 间房 · 稀有掉落）

- **选型**：独立新房间 kind `super_secret`（QA 选项 A），**不是**复用 `secret` + 标记字段。四类硬编码 `kind == "secret"` 全部扩展为同时识别两者（见第八节 10 处契约表）。
- **生成**：`Dungeon.generate()` 在普通秘密房之后追加 1 间。候选格由 `_find_super_secret_cell()`（:149–170）确定性遍历 `rooms.keys()` 取首个合法格，**完全不消耗 rng**；要求「恰好 1 个正交邻居」、`Dev.check(neighbors==1)` 运行时断言、SMOKE 打印 `[SMOKE-SUPER] floor=N cell=... neighbors=1`。
- **Q 选格（按主理人约束订正）**：`_is_special_room()`（:173–175）把唯一邻房限定为**排除宝箱 / 商店 / Boss / 另一间隐藏房**，其余正常可达房（含 `start`、`combat`、`elite`、`challenge`）可挂。起点不是死端特殊房，允许挂靠使超秘靠近起点，避免新增叶子房挂在深层战斗房时触发 SMOKE 自动驾驶多房震荡（BUG-001）。`dungeon.gd:141` 的 `cnt >= 2` **一字未动**；与普通秘密房一致不做 2×2 校验（§3.3：`cnt==1` 本来也成不了 2×2），避免同类实体两套约束。
- **揭示链路**：`_build_arena` 对 `super_secret` 邻居同样生成 `SecretWall`（`secret_wall.gd` 未改，裂纹墙仍只响应 `bomb_hit()`）→ `explode` → `reveal_secret(dir)` → **照旧走 `_build_arena(dungeon.current)` 重建**，必经坑 6 解锁块。
- **稀有掉落（R1）**：首次进入给 `chest_big + relic×2 + diamond×12`，复用既有池、不引入新物件 / 新稀有度；用独立 `super_loot_taken` 标记防重刷（**没有复用 `skip_loot`**，因生成时 `cleared=true` 会让 `_enter_room` 置真，复用会首次进入就不发奖）。
- **可达 / 隐藏**：`autopilot_door_target()`（:550–559）把「已揭示且未访问」的超秘房列为 BFS 目标；未揭示不上小地图，揭示后显示 `*` 标记，颜色走 `Data.room_color("super_secret")`（金色），未写死颜色表。
- **每层固定 2 间隐藏房（P1）**：普通秘 `cnt>=2` + 超秘 `cnt==1`，两者互不相邻、互不计入对方 `cnt`；选格顺序为普通→超秘（工程实现选择，保证后放置的超秘 `neighbors==1` 不被破坏），未改 `_find_secret_cell()`。

### S-03 HUD 状态显示（护盾层数 / 连锁闪电 / 淬毒）

- 左上血条面板下方一行紧凑状态条（:330–358）：三个 `TextureRect` 图标 **20×20**（≤20px）+ 中文标签，数值 `护盾 ×N / 连锁 N% / 淬毒 N%`（百分比与升级卡文案一致）。
- 图标取值**全部经 `Assets.xicon(key)`**（`guard / chain / venom`，三张既有 generated 图标）；新增代码里**没有** `ICON_RECTS[...]` 直接索引，也没有复用 `_icon_label()`（该函数 :481 保持 `Assets.icon(key)` 原状，既有图标用途不受影响）。
- `_refresh_status()`（:361–375）每帧从 `player.shield_charges / chain_chance / poison_chance` 刷新；**值为 0 时该单项 `visible=false`，三项全 0 时整条 `_status_panel.visible=false`（未获得不占位）**。
- **遮罩穿透修复（补丁 2）**：`_build_status_ui(root)` 已从 `_build_dungeon_ui()` 末尾移到 `_ready` 的两个 `_overlay`（:178 / :195）之前（当前 :175）。靠 CanvasItem 树序让 `gameover_holder` / `pause_holder` 绘制在状态条之上，结算/暂停时状态条不再浮在遮罩上；未重构 HUD、未改 `game_over()` / `set_paused()` 逻辑、未改其它 UI 元素。
- **图标 key 清单**：`guard`、`chain`、`venom` —— **均为既有 key，本轮未新增任何图标 key、未新增 PNG**，因此 §五-4 `--headless --import` 不触发。

### S-04 挑战房失败也给小奖励（D1）

- **按设计推荐 D1 落地**：`_room_cleared()` 的 `challenge` 分支，原有 3 颗随机钻石**保留不动**；`_room_damaged` 为真时只做三件事：
  1. `Game.add_score(30)`（固定值、与掉血次数无关、可预期）；
  2. `hud.flash_toast("挑战失败 · 保底 +30 分")` 专属反馈；
  3. SMOKE 下 `print("[SMOKE] challenge failed (consolation +30 score)")`。
- **掉落表不动**：没有新增 `drop_pickup`，不是「3 改 6 颗钻石」；不与 S-01 炸弹经济耦合。
- **满血（无伤）分支逐字未动**：`relic×1 + chest_big×1 + banner + Game.sfx("secret") + Game.add_score(200)` 全部保持。
- **四条倒挂红线守住**：+30 远低于无伤的遗物 + 大宝箱 + 200 分；不是遗物/大宝箱/升级卡/武器/200 分；不按掉血次数递增；不是随机高价值掉落。
- **重进已清挑战房不重复结算**（C6）：由 `room_state` 流转天然保证，`_room_cleared()` 只在 combat→cleared 时调用。
- **复现探针**：`SMOKE_CHALLENGE_FAIL=1` 强制 `_room_damaged=true`（SMOKE 默认 `_immortal`，掉血分支否则永远走不到）；开发阶段观测 2 次 `forced challenge-fail probe` → 2 次 `challenge failed (consolation +30 score)`、0 次 `challenge no-hit clear`；普通种子仍出现 `challenge no-hit clear`。

---

## 五、两条坑约束落实 + 其余坑

### 坑 6「重建房间后门锁死」

- `game_main.gd:724–731` 原解锁块 **`if room_state == "cleared": for d in _doors: d.set_locked(false)` 完整保留、未绕过、未删除、未改条件**；仅加注释与 SMOKE 下 `Dev.check(not d.locked, "rg6", ...)` 断言。
- S-01 新增的揭示路径仍由 `reveal_secret()` 调 `_build_arena(dungeon.current)`，必然经过该块；没有开辟第二条重建通道。
- SMOKE 挂具改成「一帧只炸一面墙」，避免同帧两次重建产生重复门节点。
- **开发阶段 RG-6 证据（补丁前，非放行证据）**：`[RG-6] reveal rebuild: room=(0,0) state=cleared doors=[[(0,-1), false], [(0,1), false], [(-1,0), false]]`（及四门版本全部 `false`）；`[SMOKE-DOORS]` 可见战斗态 `true` → 清场态 `false` 的正常切换。冻结版本由 QA 重跑确认。

### 坑 7「新增图标直接查表导致面板崩」

- 新增三处图标使用**全部 `Assets.xicon(key)`**；`validate.gd:_check_status_icons()` 同样走 `xicon`。`_icon_label()` 未改（见上）。
- `assets.gd` / `upgrade_panel.gd` **一行未改**：`xicon` 三级回退（generated → 原图集 → 白图 + 告警）与面板 `_icon_for()` 的既有调用保持原状。
- **开发阶段 RG-7 证据（补丁前，非放行证据）**：`[RG-7] xicon(nonexistent) fallback=white_tex problems=0`、`[RG-7] upgrade_panel._icon_for(nonexistent) texture=ok`；两条 `WARNING: [assets] 图标缺失：__rg7_missing_key__` 是**预期回退告警**，恰好证明走了白图分支而非抛异常；常态基线（不带 `SMOKE_RG7`）不产生该告警。

### 其余坑

| 坑 | 落实 |
|-|-|
| §五-2 Variant 推断 | 新增变量显式标类型：`var n: Vector2i`、`var nk/rk/ck/mk/rid0/rid1: String`、`var t/fallback: Texture2D`、`Array[int]` / `Array[String]` |
| §五-4 新 PNG 需 import | 本轮无新 PNG，复用既有三张图标（已有 `.import`），不触发 |
| §五-5 物理回调 | 新增掉落/重建都不在 `_physics_process` 或 `body_entered` 里；`explode → bomb_hit → reveal` 与既有链路相同（Tween 回调，非物理回调） |
| §五-8 小地图颜色 | 仍用 `Data.room_color(kind)`，且 `ROOM_META` 补了 `super_secret` 颜色，不写死颜色表 |
| §五-9 过门落点 0.36 | 未改 |
| §五-11 障碍避开门口走廊 | `_spawn_props()` 未改；`game_main.gd:735` 障碍物分组仍是 `["combat","elite","challenge"]`，超秘房不落障碍 |
| `:100–103` 无伤判定 | 未改，`player.damaged` 仍只在 `room_state=="combat"` 且 `kind=="challenge"` 时置 `_room_damaged` |

---

## 六、`validate.gd` 计数核实结论（任务指定项）

**结论：计数代码本身不需要改；`KNOWN_ROOM_KINDS` 与图标 key 已同步登记；基线文案里的「房间 8」应更新为「房间 9」。**

1. `Validate.run()` :24 打印的是**动态值** `Data.ROOM_META.size()`，不是硬编码数字；新增 kind 后自动 8→9，无需改计数逻辑。
2. `_check_rooms()` :66 遍历硬编码 `KNOWN_ROOM_KINDS`，已在 :7 追加 `super_secret`，否则自检漏检新 kind 的元信息（小地图颜色缺项也查不出来）。
3. 图标 key 登记：`STATUS_ICON_KEYS`（:9）= `["guard","chain","venom"]`；`_check_icons()` :86 改为 `for key in STATUS_ICON_KEYS + ["dice"]` 集中登记；新增 `_check_status_icons()`（:92–101）用 `xicon` 校验三个状态图标并在 `SMOKE_RG7` 下验证不存在 key 的白图回退。
4. 实测输出（开发阶段，补丁前）：`[INFO] validate: 自检通过：敌人 28 / 房间 9 / 地图池 3 层`；`problems=0`。敌人 28（ENEMIES 未动）、地图池 3 层（FLOOR_POOLS 未动）保持原值。
5. 建议把交接稿 §六 自检期望文案由 `房间 8` 改为 `房间 9` —— **是期望值更新，不是降低标准**；0 报错 / 到第 2 层 / 过门量级等硬判据全部不变。

---

## 七、QA 阶段 B 交付说明 6 项答复

**1）S-01 实现选型？自检输出计数？**
选 **(A) 独立新 kind `super_secret`**，不是复用 `secret` + 标记字段。四类硬编码 `kind == "secret"`（裂纹墙方向 / SMOKE 炸墙 / 自动驾驶进房 / 小地图隐藏）与清场白名单共 10 处全部同步扩展（第八节）。自检输出为 **「房间 9」**：`[INFO] validate: 自检通过：敌人 28 / 房间 9 / 地图池 3 层`。小地图按 `Data.room_color(kind)` 上色，`ROOM_META` 已补新 kind 的金色。

**2）§六 自检最终计数 + `validate.gd` 新 kind / 新图标登记？**
最终计数 **房间 9**（敌人 28 / 地图池 3 层不变）。登记情况：`KNOWN_ROOM_KINDS`（:7）已加 `super_secret`；图标 key 用 `STATUS_ICON_KEYS`（:9）集中登记，`_check_icons()` :86 用 `STATUS_ICON_KEYS + ["dice"]`，另新增 `_check_status_icons()`（:92）。**S-03 未新增任何图标 key**（复用既有三个），故无「新图标 key 漏登记」风险。详见第六节。

**3）S-03 新增图标 key 完整清单（RG-7 负向探针 / 静态审计用）？**
`guard`（护盾）、`chain`（连锁闪电）、`venom`（淬毒）—— **共 3 个，全部为工程既有 key**（`resources/texture/generated/icon_guard.png` / `icon_chain.png` / `icon_venom.png`，均已存在 `.import`）。**本轮新增图标 key 数 = 0，新增 PNG 数 = 0**，故 `--headless --import` 不触发。三处取图全部走 `Assets.xicon(key)`；负向探针使用不存在的 `__rg7_missing_key__`，期望得到 `Assets.white_tex` 且不抛错。`hud.gd:481` 的 `_icon_label()` 仍是 `Assets.icon(key)`，本次未改，既有图标用途不会回退。

**4）`reveal_secret` 的 `secret revealed` 打印是否覆盖超级秘密房？爆破时打印几次？**
**覆盖**。`game_main.gd:515` 为 `print("[SMOKE] secret revealed at ", nc, " kind=", nk)`，其中 `nk = String(dungeon.rooms[nc].get("kind", "secret"))`（:505）。**每次成功揭示打印 1 次**；超秘房打印 `kind=super_secret`，普通秘密房打印 `kind=secret`。爆破另有 `[SMOKE] bombed secret wall dir=... kind=...` 1 行（不同 tag，不计入 `secret revealed` 计数）。`reveal_secret` 另在 `SMOKE_DUMP` 下打印 `[RG-6]` 门锁转储（也不计入该计数）。计数口径按 QA 要求：**≥2 为下限、允许 >2，须记录实际计数**；开发阶段（补丁前）各种子观测 2–5 次，属过程数据，**不得用旧计数反推通过**，冻结版本实际计数由 QA 重跑记录。

**5）S-04 是否按设计推荐 D1 落地？**
**是，按 D1**：固定 `Game.add_score(30)` + 专属 toast「挑战失败 · 保底 +30 分」+ `[SMOKE] challenge failed (consolation +30 score)`，**掉落表不动**（原有 3 颗随机钻石保留，未新增任何 `drop_pickup`），**满血分支逐字未动**（遗物 + 大宝箱 + 横幅 + 200 分 + 音效）。四条倒挂红线全部守住。复现用 `SMOKE_CHALLENGE_FAIL=1`；首版文档的旧保底方案已作废。

**6）是否提供 B-11 固定种子专项复现手段？**
**提供「保证能生成超秘的固定种子」**，未提供 `SMOKE_SUPER=1` 环境变量（冻结期不授权新增代码开关）。超秘生成**确定性**、不消耗 rng、每层固定 1 间（只要存在合法候选格），因此种子稳定可复现：

```bash
cd /d/Create/Game/test-1
# 保证生成 + 早期揭示 + 门锁转储（种子 4；种子 2/3 同样在 600 帧内揭示）
SMOKE=1 SMOKE_SEED=4 SMOKE_DUMP=1 <godot> --headless --path . res://scene/game.tscn --quit-after 900
# 完整链路可用 9000 帧
SMOKE=1 SMOKE_SEED=4 <godot> --headless --path . res://scene/game.tscn --quit-after 9000
```

开发阶段观测：种子 1–6 **每个都在第 1 层生成超秘**（`[SMOKE-SUPER] floor=1 ... neighbors=1`）；种子 2/3/4 的超秘挂在起点相邻格，600 帧内即出现 `[SMOKE] secret revealed at ... kind=super_secret`。QA 可检索的关键行：`[SMOKE-SUPER]`、`kind=super_secret`、`[SMOKE] entered super_secret room at`、`[SMOKE] super_secret loot dropped`、`[RG-6]`。同样地，上述观测均来自补丁前日志，**冻结版本请 QA 用相同命令重跑取证**。

---

## 八、10 处 kind 契约同步 + QA 写死的静态检查

| # | 契约点（QA/设计指定） | 冻结版本行号 | 状态 |
|-|-|-|-|
| 1 | `validate.gd` `KNOWN_ROOM_KINDS` 白名单 | :7 | ✅ 已加 `super_secret` |
| 2 | `data.gd` `ROOM_META` | :113 / :121 | ✅ 已加名称 + 金色 |
| 3 | `hud.gd` 小地图 mark 表 | :438–439 | ✅ 已加 `"super_secret": "*"` |
| 4 | `hud.gd` `set_room_info` 映射 | :391–393 | ✅ 已加 `· 超级秘密` |
| 5 | `game_main.gd` 裂纹墙方向判断 | :697–708 | ✅ 同时认两类隐藏房 |
| 6 | `game_main.gd` `reveal_secret` | :503–517 | ✅ 按 kind 区分提示 / 打印 |
| 7 | `game_main.gd` `autopilot_door_target` | :550–559 | ✅ 已揭示超秘纳入 BFS 目标 |
| 8 | `game_main.gd` `_smoke_secret_tick` | :1077–1100 | ✅ 两类隐藏房都炸、逐帧逐个 |
| 9 | `hud.gd` 小地图隐藏规则 | :416–417 | ✅ 两类未揭示都不显示 |
| 10 | `game_main.gd` `_enter_room` 进房分组（清场白名单） | :368 | ✅ 已加 `super_secret` |
| 附 | `_enter_room` 掉落分支 / 进房日志 | :420–433 / :467 | ✅ 已加 |

**QA 写死的静态检查**：

| 检查 | 结果 |
|-|-|
| `dungeon.gd:141` `cnt >= 2` 不得改成 `cnt == 1` | ✅ 一字未动 |
| `game_main.gd:735` 障碍物分组不要误落到超秘 | ✅ 仍是 `["combat","elite","challenge"]`，超秘不在其中 |
| `game_main.gd:100–103` 无伤判定不要误落到超秘 | ✅ 未改，仍只在 `kind=="challenge"` 且 `combat` 态置位 |
| `game_main.gd` 坑 6 解锁段保留 | ✅ :724–731 原样保留 |
| `assets.gd:242–249` / `upgrade_panel.gd:152` 现状完好 | ✅ 两文件一行未改 |

---

## 九、改了什么 / 验证了什么 / 还剩什么

### 改了什么

- 5 个 `scripts/` 文件：`dungeon.gd`、`data.gd`、`game_main.gd`、`hud.gd`、`validate.gd`；`assets.gd` / `upgrade_panel.gd` 未动；场景 / project.godot / 贴图 / 音频未动。
- 三条 Story：S-01 独立新 kind `super_secret`（确定性 `cnt==1` 选格、只吃炸弹、`_build_arena` 重建、R1 稀有掉落、10 处契约同步）；S-03 三图标状态条（20px、`xicon`、`未获得不占位`、移到遮罩之前）；S-04 D1 固定 +30 分保底（掉落表与无伤分支不动）。
- 两处最终补丁：`game_main.gd:318` 注释事实订正；`hud.gd:174–175` 把 `_build_status_ui(root)` 移到两个 `_overlay` 之前修遮罩穿透。
- 测试专用 SMOKE 探针（环境变量门控、常态不生效）：`SMOKE_RG7`、`SMOKE_STATUS`、`SMOKE_CHALLENGE_FAIL`；`SMOKE_DUMP` 增加 `[RG-6]` 打印；`dungeon.gd` 增加 `[SMOKE-SUPER]` 打印。**没有** `SMOKE_SUPER` 开关。

### 验证了什么

- **开发阶段过程证据（补丁前，不作放行依据）**：多轮全套基线（种子 1–6 × 9000 帧、死亡链路、纯净启动、`SMOKE_DUMP`、`SMOKE_RG7`、`SMOKE_CHALLENGE_FAIL`、窗口截图）观测到 0 个 `SCRIPT ERROR` / `Parse Error`；`entered floor` / `secret revealed` 出现；RG-6 重建后门全 `false`；RG-7 白图回退 + 面板不崩；S-04 失败/无伤互斥；HUD 状态条在 `SMOKE_STATUS=1` 下显示 `护盾 ×2 / 连锁 50% / 淬毒 60%`。
- **BUG-001 的定位与缓解验证（开发阶段）**：严格 Q 把超秘挂到深层战斗房时，某次种子 3 的 9000 帧跑出现 `use_door=74`（另有 38 / 54），并反复 `entered super_secret`；经 `NAVDBG` 插桩定位为 SMOKE 自动驾驶在「全图清空、BFS 无目标」时退回「任意开着的门」，与超秘叶子房来回震荡。改为 `_is_special_room()` 允许起点挂靠后，600 帧短跑复测：种子 1–6 全部生成超秘、0 解析错误，种子 2/3/4 在 600 帧内即揭示超秘。插桩代码已全部移除。
- **冻结版本 SPR3-FROZEN-1**：两处最终补丁按主理人指令**未由我方运行任何 Godot 命令**，因此我方**没有**冻结版本的运行期 0 报错证据，也不宣称有。放行结论以 QA 在 SPR3-FROZEN-1 上重跑 B-1~B-11 的结果为准。
- 日志说明：`ERROR: N resources still in use at exit` / `WARNING: N ObjectDB instances were leaked at exit` 是 Godot 退出期引擎提示，改动前基线日志（`final_5.log`、`r2_plain.log`）同样存在，不是脚本报错；§六 判据限定 `SCRIPT ERROR` / `Parse Error = 0`。

### 还剩什么

- QA 在 **SPR3-FROZEN-1** 上统一重跑 B-1~B-11（md5 前后 YES），并复验 15:23 的 `_is_special_room` 循环修复与两处最终补丁（尤其 HUD 结算/暂停遮罩不穿透，设计评审 P0-2）。
- 交接稿 §六 基线文案两处期望值需由主理人更新：自检「房间 8」→「房间 9」；`secret revealed` 计数口径改为「≥2 为下限、允许 >2、记录实际计数」。
- 遗留缺陷与未覆盖项见第十节：E1、普通 `secret` 房首次 loot 被跳过、BUG-001 残余震荡风险、L4 真人试玩缺口。

---

## 十、与 §六 基线的偏差（如实列出，不降标准）

| 项 | §六 基线 | 情况 | 性质 |
|-|-|-|-|
| `SCRIPT ERROR` / `Parse Error` | 0 | 开发阶段多轮为 0；**冻结版本以 QA 重跑为准** | 硬判据，不代 QA 判定 |
| `entered floor` | 出现 / 到第 2 层 | 开发阶段各种子均 ≥第 2 层 | 符合 |
| `use_door` 与房间数同量级（<40/9000 帧为宜） | 14–16（种子 4/5/6）、16–35（种子 1/2/3） | 多了一间叶子房会改变自动驾驶路线；严格 Q 版本曾出现 38/54/74（BUG-001），已通过允许起点挂靠缓解 | 需 QA 在冻结版本复核；判据以 <40 与房间数同量级为准 |
| `secret revealed` | 秘密房 2 | 新增超秘后按两类房各计一次，开发阶段观测 2–5 | 预期变化；按 QA 新口径「≥2 下限、允许 >2、记录实际值」 |
| 自检输出 | 敌人 28 / 房间 **8** / 地图池 3 层 | 敌人 28 / 房间 **9** / 地图池 3 层 | 预期变化，动态计数，建议更新基线文案 |
| 死亡链路 | 5 次重开 / 0 报错 | 开发阶段观测 4–5 次（headless 帧步长随负载波动），链路正常 | 需 QA 在冻结版本记录实际次数 |
| 纯净启动 / 截图 | 0 报错 / UI 正常 | 开发阶段符合；冻结版本截图由 QA 重取 | 符合（待复验） |

补充观察：同一固定种子两次完整跑的过门数有波动（如种子 1 曾 16、曾 23）。headless 无垂直同步、`Engine.time_scale=2.0` 下 `delta` 随运行时负载变化，推测因此产生波动；未对成因下结论。基线中的 `14–16 / 16–35` 宜按经验区间理解。

---

## 十一、遗留与建议

1. **E1 · 护盾抵挡不算掉血（本轮刻意不动，已留痕）**：`player.gd:459–464` 护盾消耗一层后提前 `return`、未 `emit damaged`，`_room_damaged` 只由 `player.damaged` 置位 → 带护盾「硬吃一下」仍算无伤通过。S-03 把护盾层数做成显眼 HUD 状态后，这个跨 Story 张力更明显。按设计规格 §5.5 / §8 E1 本轮不动 `player.gd` 与 `_room_damaged`，留待用户后续冲刺决定是否收紧。
2. **普通 `secret` 房首次 loot 被跳过（发现但未改，超出范围）**：普通秘密房生成时即 `cleared=true`，`_enter_room` 会据此把 `skip_loot` 置真，导致其 loot 分支首次进入就被跳过。本轮超级秘密房改用独立 `super_loot_taken` 标记规避；普通秘密房分支严格未动，建议后续单独排期。
3. **BUG-001 · SMOKE 自动驾驶震荡（已缓解，残余风险留痕）**：全图清空且 BFS 无目标时，`autopilot_door_target()` 会退回「任意开着的门」（`game_main.gd` 末尾），与叶子房相邻时可能来回过门。严格 Q 版本实测把 `use_door` 推到 74（>40）。已通过 `_is_special_room()` 允许超秘挂起点来避开该布局，**但未重写自动驾驶兜底逻辑**（属现有机制、超出本冲刺范围）。若 QA 在冻结版本仍观察到 >40 的过门数，应记 CONCERNS 并单独排期修 `autopilot_door_target()`，不要回退 S-01。
4. **L4 · 真人试玩缺口**：HUD 三状态目前只通过 `SMOKE_STATUS=1` 探针做确定性截图验证（护盾 ×2 / 连锁 50% / 淬毒 60%），**未做真人长时间试玩**：真实升级取得 `guard/chain/venom` 后的刷新时序、受击消耗护盾的同帧刷新、结算/暂停遮罩下的视觉，均建议 QA 在冻结版本上手复验。
5. **建议 quality-lead 重点复验**：炸开超秘墙后门锁全解锁且能过门离开（`[RG-6]`）；不存在图标 key 不崩（`[RG-7]` 两条）且常态日志无该告警；S-04 失败保底与无伤奖励互斥；`[SMOKE-SUPER] neighbors=1` 逐层出现；B-11 按第七节第 6 项命令复现超秘完整链路。
6. **未做**（用户拍板排除）：S-02、S-05、S-06；未做敌人 / 贴图 / 关卡数值调整；未改 `player.gd`、`assets.gd`、`upgrade_panel.gd`。
7. **知识缺口**：无。本轮未使用任何超出既有工程已验证范围的 Godot API；`Dev.check`、`Assets.xicon`、`Data.room_color` 均为项目内既有接口。
