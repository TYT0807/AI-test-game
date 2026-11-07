# SPR3 测试报告（FROZEN-2 最终版 · BUG-001 修复验证）

> 任务：SPR3-FIX-2（quality-lead 严守真） · 最终复跑：2026-11-05 17:56–18:19（北京时间）
> 工程：`D:\Create\Game\test-1`（Godot 4.7.2.steam）｜引擎：`D:\SteamLibrary\steamapps\common\Godot Engine\godot.windows.opt.tools.64.exe`
> 计划：`tests/SPR3_QA计划与用例.md`｜**唯一放行证据**：`_tools/spr3_qa_f2_*.log`（SPR3-FROZEN-2 冻结快照组，28 份）
> 历史记录（不作放行证据）：`_tools/spr3_qa_f1_*.log`（FROZEN-1）、`spr3_qa_*.log`（上一版 27 份）、`spr3_*.log`（T1 15 份）。

---

## 0. 最终判定：**PASS**（无条件）

| 门 / 项 | 结果 | 说明 |
|-|-|-|
| **P0 放行门** | **PASS** | RG-6 全过、RG-7 全过、0 报错 |
| **用户硬要求（0 报错）** | **满足** | 28 个进程全部 exit=0；全 `f2` 日志 `SCRIPT ERROR` / `Parse Error` / `Invalid access to property or key` / `[assets] 素材加载失败` / `rg6` 断言失败 **0 匹配** |
| **冻结有效性** | **满足** | 开跑前 `FROZEN2_BASELINE_MATCH=YES`；跑完 `FROZEN2_HASH_STABLE=YES` + `FROZEN2_BASELINE_MATCH_AFTER=YES` |
| **BUG-001** | **已修复 / 结案** | 种子 4 **九连跑 `[SMOKE-LOOP]` 命中 0 次**，过门 16–21（全部 <40），进超秘房 1–2 次，`entered floor` 9/9；修复前同位置 11%（1/9）触发 |
| **§六 验收基线** | **全部达标** | 6 种子过门 11–22（全部 <40）、6/6 到第 2 层、`secret revealed` 3–4、死亡 4 次、纯净启动 0 报错 |
| **三条 Story** | **全过** | S-01（B-11 + X8 + G-10）、S-03（徽标/隐藏/遮罩截图）、S-04（D1 +30 掉血结算复现、满血分支逐字未动、四条红线成立） |
| **总判定** | **PASS** | 无 Blocker / Critical / Major 未修；P0 门全过、0 报错、修复经验证有效 |

**保留的后续建议（不改变 PASS）**：L4 真人 Playtest 仍 MISSING；暂停遮罩无自动输入触发（以静态挂载层级 + 结算遮罩截图类推）；挑战房失败 toast 截图未抓到（以代码逐字 + 探针日志替代）；FROZEN-2 观察到种子 2/5 超秘房「已揭示但 9000 帧内未进入领取」（不违反设计 A5/A10，见 §7）。

---

## 1. 版本与冻结证据（SPR3-FROZEN-2）

**唯一变更**：`game_main.gd`（`20c3900e…` → `55744d35125e4d2aa5a9c3fc51aef103`）；其余六脚本与 FROZEN-1 同。

| 脚本 | md5 |
|-|-|
| dungeon.gd | `74286a0bfc9660b622bfab85f8db220a` |
| data.gd | `bb36856b47b8c20ed69b302c6eae025c` |
| game_main.gd | `55744d35125e4d2aa5a9c3fc51aef103` |
| hud.gd | `50c5e97ddb632d258b06a081b7839c36` |
| validate.gd | `21e89c19f155d3a4c629c62fdddd0497` |
| assets.gd | `97bbf33bd6d1025e41073ab94f83d328` |
| upgrade_panel.gd | `18f44160159c483696e1684d3636cb9b` |

- 哈希证据：`_tools/spr3_f2_hash_expected.txt`、`spr3_f2_hash_baseline_before.txt`、`spr3_qa_f2_hash_before.txt` / `_after.txt`，三者一致。
- **静态复核（实读）**：`dungeon.gd:141` `cnt >= 2` 未动；`game_main.gd:465` 0.36 落位、`:470` `hold_until_exit`、`:754` 坑 6 解锁段均未动；10 处 kind 契约未动；其余六脚本哈希与 F1 一致。
- **修复内容（实读 `game_main.gd`）**：
  - Hunk A（`:594-608`）：终端兜底选门时跳过**已访问的隐藏叶子房**（`secret`/`super_secret` 且 `visited`）与**已访问且已清**的邻房；全部候选被排除时返回 `Vector2.ZERO`，`_autopilot_move` 的 `if door_pos != Vector2.ZERO` 整块跳过 → 不再每隔 1.2 秒强制过门，循环有收敛点。
  - Hunk B（`:65-67` 成员、`:509-515` 重复过门计数、`:227-235` 坐标不动断言）：纯 `print("[SMOKE-LOOP] …")`，SMOKE 门控，无 `push_error` / `assert`，不会制造 `ERROR:` 行。

---

## 2. BUG-001 修复验证（主判据）

**种子 4 × 9000 帧连跑 9 次**（对应修复前「9 次 / 1 次触发 = 11%」的观测位点）：

| 运行 | 日志 | `[SMOKE-LOOP]` | use_door | 进超秘房 | `entered floor` | 0 报错 |
|-|-|-|-|-|-|-|
| #1 | `spr3_qa_f2_seed4_run1.log` | **0** | 17 | 1 | ✅ | ✅ |
| #2 | `spr3_qa_f2_seed4_run2.log` | **0** | 16 | 1 | ✅ | ✅ |
| #3 | `spr3_qa_f2_seed4_run3.log` | **0** | 16 | 1 | ✅ | ✅ |
| #4 | `spr3_qa_f2_seed4_run4.log` | **0** | 21 | 2 | ✅ | ✅ |
| #5 | `spr3_qa_f2_seed4_run5.log` | **0** | 18 | 1 | ✅ | ✅ |
| #6 | `spr3_qa_f2_seed4_run6.log` | **0** | 18 | 2 | ✅ | ✅ |
| #7 | `spr3_qa_f2_seed4_run7.log` | **0** | 20 | 1 | ✅ | ✅ |
| #8 | `spr3_qa_f2_seed4_run8.log` | **0** | 20 | 1 | ✅ | ✅ |
| #9 | `spr3_qa_f2_seed4_run9.log` | **0** | 17 | 1 | ✅ | ✅ |

**结论：BUG-001 已修复、结案**。
- 修复前（FROZEN-1）同位置：过门 71、进超秘房 17、`t=115.5→136.7` 卡在第 2 层；9 次运行 1 次触发（11%）。
- 修复后（FROZEN-2）：**9/9 无 `[SMOKE-LOOP]` 命中**、过门 16–21（全部 <40）、进超秘房 ≤2、全部到第 2 层、0 报错、无软锁。
- 三个断言口径全部满足：`[SMOKE-LOOP]` 0 次、`use_door < 40`、`entered super_secret ≤ 2`、出现 `entered floor`。

---

## 3. §六 验收基线逐项证据（FROZEN-2）

| # | 用例 | 实测 | 判定 |
|-|-|-|-|
| B-1 | 种子 1 | 0 报错 / 过门 **22** / `entered floor 2` / revealed **4** / `[SMOKE-LOOP]` 0 | ✅ |
| B-2 | 种子 2 | 0 报错 / 过门 **11** / `entered floor 2` / revealed **3** / LOOP 0 | ✅ |
| B-3 | 种子 3 | 0 报错 / 过门 **15** / `entered floor 2` / revealed **4** / LOOP 0 | ✅ |
| B-4 | 种子 4 | 0 报错 / 过门 **19** / `entered floor 2` / revealed **3** / LOOP 0（另有九连跑见 §2） | ✅ |
| B-5 | 种子 5 | 0 报错 / 过门 **12** / `entered floor 2` / revealed **4** / LOOP 0 | ✅ |
| B-6 | 种子 6 | 0 报错 / 过门 **15** / `entered floor 2` / revealed **4** / LOOP 0 | ✅ |
| B-7 | 死亡链路 900 帧 | `player died` **4 次**，每次重开 problems=0，0 报错 | ✅ |
| B-8 | 纯净启动 600 帧 | 0 报错、自检 `敌人 28 / 房间 9 / 地图池 3 层` / problems=0 | ✅ |
| B-9 | 截图（窗口） | 状态徽标 `shots_f2_status/` 22 张、结算遮罩 `shots_f2_gameover/` 22 张，0 报错 | ✅ |
| B-10 | SMOKE_DUMP 600 帧 | 清场门全 `false`、`[DUMP]` 全树贴图无 NULL | ✅ |
| B-11 | S-01 专项 9000 帧 | 两层超秘爆破→重建→掉落 1 次/层→进房→到第 2 层 | ✅ |

**总判据**：`SCRIPT ERROR` / `Parse Error` = 0 ✅；6/6 出现 `entered floor` ✅；`secret revealed` 3–4（≥2）✅；`use_door` 11–22 全部 <40 且无循环 ✅。

**用户指定复验**：

| 运行 | 日志 | use_door | LOOP | 最高层 |
|-|-|-|-|-|
| 种子 3 #1 | `spr3_qa_f2_seed3.log` | 15 | 0 | 2 |
| 种子 3 #2 | `spr3_qa_f2_seed3_run2.log` | 14 | 0 | 2 |
| 种子 3 #3 | `spr3_qa_f2_seed3_run3.log` | 11 | 0 | 2 |
| 种子 6 #1 | `spr3_qa_f2_seed6.log` | 15 | 0 | 2 |
| 种子 6 #2 | `spr3_qa_f2_seed6_run2.log` | 17 | 0 | 2 |

（种子 3 修复前历史最大 86 次过门 / 20 次进超秘房；FROZEN-2 三次均 11–15，收敛。）

---

## 4. P0 放行门逐项证据

### 4.1 RG-6 重建房间后门锁死 —— **PASS**
- 静态：`game_main.gd:754` 起 `if room_state == "cleared": for d in _doors: d.set_locked(false)` + `Dev.check`；`_build_arena(` 调用点仅 `_enter_room` / `reveal_secret`，无绕过。
- `spr3_qa_f2_rg6_dump.log`：`state=cleared` 时门锁全 `false`（如 `[[(0,1), false]]`、`[[(0,-1), false],[(-1,0), false],[(1,0), false]]`）；`[DUMP]` 全树贴图有正常 `res://` 路径、无 NULL。
- `spr3_qa_f2_s01_super.log`：第 1 层超秘 `(0,-1)`、第 2 层 `(1,0)` 均爆破→重建→门全开→进房→到第 2 层，无锁死。
- 全 `f2` 种子日志 `rg6` 断言失败 0；`locked=true` 仅 `state=combat`（战斗房正常锁门）。

### 4.2 RG-7 新增图标直接查表导致面板崩 —— **PASS**
- 静态：`assets.gd:242-249` 三级回退完好；`guard/chain/venom` 全走 `Assets.xicon`（`hud.gd:342`、`upgrade_panel.gd:152`、`validate.gd:94/99`）；无新 PNG（34/34 `.import`）。
- 内建探针（`spr3_qa_f2_rg7.log`）：`[RG-7] xicon(nonexistent) fallback=white_tex problems=0`、`[RG-7] upgrade_panel._icon_for(nonexistent) texture=ok`。
- 独立探针（`spr3_qa_f2_icon_probe.log`）：`[PROBE] missing-key -> WHITE size=(4.0, 4.0)`、`known-key(guard) -> OK`。
- 常态基线 0 条 `[assets] 图标缺失`（仅两个探针日志各有 1–2 条预期告警）。

### 4.3 0 报错 —— **PASS**
- 全 `spr3_qa_f2_*.log`（28 份）：`SCRIPT ERROR|Parse Error|Invalid access|[assets] 素材加载失败|rg6` → **0 匹配**。
- 28 进程 exit=0；全部日志 `problems=0`。
- 退出期 `WARNING: N ObjectDB instances were leaked` / `ERROR: N resources still in use` 仍出现，属 Godot 引擎退出提示（改动前 20+ 份基线日志均有，2–14 实例 / 1–4 资源），按 §六 只数 `SCRIPT ERROR` / `Parse Error`，不计入。

---

## 5. X8 逐层断言 + G-10（FROZEN-2 复跑确认）

| 种子 | `[SMOKE-SUPER] floor=` | `entered floor` | `dungeon map`（第 1 层） | 跳过 | 判定 |
|-|-|-|-|-|-|
| 1 | 1（`0,2`）、2（`1,0`） | 2 | `"super_secret": 1` | 无 | ✅ |
| 2 | 1（`0,1`）、2（`2,0`） | 2 | `"super_secret": 1` | 无 | ✅ |
| 3 | 1（`1,0`）、2（`2,0`） | 2 | `"super_secret": 1` | 无 | ✅ |
| 4 | 1（`0,-1`）、2（`0,3`） | 2 | `"super_secret": 1` | 无 | ✅ |
| 5 | 1（`2,1`）、2（`-1,0`） | 2 | `"super_secret": 1` | 无 | ✅ |
| 6 | 1（`0,-2`）、2（`0,1`） | 2 | `"super_secret": 1` | 无 | ✅ |
| seed4_run1..9 | 每轮两层均有断言 | 9/9 到第 2 层 | — | 无 | ✅ |

**G-10 结论（沿用 F1 判定 + F2 复核）**：所有已到达层 `super_secret = 1`；**A5 合法跳过未发生、挂具未覆盖未发生**；Q 收紧未更易触发 `NO_CELL`。`dungeon.gd` 哈希与 F1 相同，X8/G-10 结论在 F2 上复核一致。

---

## 6. 三条 Story 验收点（FROZEN-2）

- **S-01 超级秘密房：PASS** —— 每层 1 间 `neighbors=1`；未揭示小地图隐藏、裂纹墙只吃炸弹；两层超秘爆破重建后门全开、进出正常、到第 2 层；稀有掉落 `big chest + 2 relics + 12 diamond` 每房仅 1 次（`super_loot_taken`），不引入新稀有度；普通秘密房 `cnt>=2` 未动（防误改 ✅）；自检 房间 9 / problems=0。
- **S-03 HUD 状态图标：PASS（L4 仍 MISSING）** —— `shots_f2_status/` 截图显示「护盾 ×2」「连锁 50%」「淬毒 60%」，20px、无重叠；未获得时整行隐藏；`shots_f2_gameover/` 结算遮罩「你倒下了」全屏覆盖、状态条未穿透（补丁 2 生效）；`_refresh_status` 读同名字段、走 `Assets.xicon`。
- **S-04 挑战房失败保底（D1 +30）：PASS** —— `spr3_qa_f2_challenge.log:150` `forced challenge-fail probe` → `:167` `challenge failed (consolation +30 score)` → `:201` `entered floor 2`；满血分支 `game_main.gd:327-334` 逐字未动；四条倒挂红线成立（固定 30 ≪ 200 分、不新增稀有度、单次固定不累加、无伤不回退）；掉落表未动。

---

## 7. 新发现与观察项

1. **【新发现 · 观察项，不阻断】种子 2 / 5 超秘房「已揭示但未进入领取」**：`spr3_qa_f2_seed2.log:20`、`spr3_qa_f2_seed5.log:136/200` 揭示超秘，但两日志均无 `super_secret loot dropped` 与 `entered super_secret room`（9000 帧内未走到）。不违反设计 A5/A10（已揭示未进入就下楼/结束属允许），但意味着部分种子拿不到 S-01 稀有奖励。建议后续确认 BFS 优先级（是否可让「已揭示未访问的隐藏房」优先于普通未清房），或接受为探索取舍。**不判 Bug**。
2. **E1 护盾抵挡不 `emit damaged`**：带护盾硬吃一下仍算无伤通过；设计侧 E1「本轮不动、只留痕」，未改。
3. **普通 secret 房首次进入 loot 被跳过**：既有行为（生成即 `cleared=true`），非本轮引入；超秘已用 `super_loot_taken` 规避。
4. **退出期引擎提示**：见 §4.3。
5. **L3/L4 缺口**：暂停遮罩无自动输入触发（`pause` 需 ESC），以静态层级 + 结算遮罩截图类推；S-04 失败 toast 截图未抓到，以代码逐字 + 探针日志替代；L4 真人 Playtest MISSING。均不阻断 P0 门。
6. **探针 flaky 余留**：FROZEN-1 曾出现 CHALLENGE 探针首跑卡住（导航 flaky），FROZEN-2 一次即成功；`[SMOKE-LOOP]` 断言已纳入，后续再出现可自动标记。

---

## 8. Bug 结案与剩余风险

| 项 | 状态 | 说明 |
|-|-|-|
| **BUG-001**（自动驾驶绕超秘房循环） | **已修复 / 结案** | FROZEN-2 种子 4 九连跑 0 次 `[SMOKE-LOOP]`、过门 16–21、进超秘房 ≤2、9/9 到第 2 层；根因修复 = 兜底跳过已访问隐藏房与已访问已清邻房 + 全排除返回 ZERO；并新增 `[SMOKE-LOOP]` 断言防回归 |
| **FLOW-001**（版本事件 / 沟通口径） | **已结案** | 编排层流程事件，非成员 Bug；FROZEN-2 哈希匹配与稳定验证 |
| **观察项 1**（超秘揭示未进入领取） | 保留观察 | 见 §7.1，建议后续确认 BFS 优先级 |
| **L4 Playtest** | MISSING | 建议下一轮补；不阻断本轮 PASS |

**剩余风险**：① 冒烟非确定性本身（headless + `time_scale=2`）仍在，虽已加 `[SMOKE-LOOP]` 断言，但 delta 波动仍可能影响过门数在 11–22 间浮动（均在阈值内）；② 超秘奖励领取率受路径影响（观察项 1）；③ L4 真人体验未签收。

---

## 9. 交接稿 §六 期望文案更新

- 自检输出：`敌人 28 / **房间 9** / 地图池 3 层`（`Validate.run()` 打印动态 `Data.ROOM_META.size()`）。
- `secret revealed`：**2–5**（两类隐藏房各计一次；FROZEN-1 实测 3–4、FROZEN-2 实测 3–4）。
- 死亡链路：**4 次**（FROZEN-2 实测 4 次；FROZEN-1 曾 5 次，建议文案用「4–5 次」区间更稳妥）。
- 过门判据：由固定区间改为「与房间数同量级（**<40/9000 帧为宜**）且**无 `[SMOKE-LOOP]` 命中 / 无重复进房循环 / 无坐标长时间不动**」。FROZEN-2 实测 11–22。

---

## 10. 附录：命令与证据索引

**关键命令（FROZEN-2）**
```bash
cd /d/Create/Game/test-1
GODOT="D:/SteamLibrary/steamapps/common/Godot Engine/godot.windows.opt.tools.64.exe"
S="scripts/dungeon.gd scripts/data.gd scripts/game_main.gd scripts/hud.gd scripts/validate.gd scripts/assets.gd scripts/upgrade_panel.gd"
md5sum $S > _tools/spr3_qa_f2_hash_before.txt
# BUG-001 主验证：种子 4 × 9
for r in 1 2 3 4 5 6 7 8 9; do SMOKE=1 SMOKE_SEED=4 "$GODOT" --headless --path . res://scene/game.tscn --quit-after 9000 > _tools/spr3_qa_f2_seed4_run$r.log 2>&1; done
# 种子 1–6 / 复跑 / 回归 / 探针（同 §2–§4 表）
md5sum $S > _tools/spr3_qa_f2_hash_after.txt   # FROZEN2_HASH_STABLE=YES
```

**证据清单**：`_tools/spr3_qa_f2_*.log` 28 份；截图 `shots_f2_status/`(22)、`shots_f2_gameover/`(22)；哈希 `spr3_f2_hash_expected.txt`、`spr3_f2_hash_baseline_before.txt`、`spr3_qa_f2_hash_before/after.txt`；独立探针 `tests/spr3_icon_probe.gd`。
**历史记录（不作放行证据）**：`_tools/spr3_qa_f1_*.log`（22 份）、`_tools/spr3_qa_*.log`（上一版 27 份）、`_tools/spr3_*.log`（T1 15 份）、`shots_f1*`、`shots_s04*`。
