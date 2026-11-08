# SPR18 交付 · 阶段一（**修订版：A 换 v3 房型计数**；B 层签双行不变）

> 基线 HEAD `ca948f0`（34 个 `.gd`，冻结 34/34）。本批**零新增实体、零新增资源、零新增 `Game.rng` 消费、E1 指纹零重定、`ACTION_DEFS` 零新增**。
> 修订版只改 2 个脚本：`game_main.gd` / `player.gd`；**`hud.gd` 与 `data.gd` 本批字节未动**。
> 上一版（A=v2 `floor_situation()`）已入库于 `4cf2cc4` / `8a246a6` / `ca948f0`，本次由主理人指示**整体替换为 v3**，理由与替换边界见 §十一。

## 零、结论速览

| 项 | 结果 |
|---|---|
| A `floor_layout_hint()` v3 | 落 `game_main.gd:1016`；读 `dungeon.rooms` 数 `elite` 个数 + `cursed` 有无，输出 `精英 N` / `无精英`（+ ` ｜ 有诅咒房`） |
| B 层签双行 | `hud.gd:596` `set_floor_sign(text, sub := "")` **本批未动**；`game_main.gd:1038 update_floor_sign()` 第二行改为 `本层 · <房型>` ｜ `<主题手记>`，**主行一字未改** |
| 探针 | `_situation_probe` → `_layout_probe`（`player.gd:1189`，**12 条断言** + 1 条前置自检）；`_floor_sign_probe` 内 `floor_sign_sub` 标签断言 **5 → 9 条** |
| 四门控 | 全过（§四）：全量 6000 帧多轮（全 env 含全部探针 1 轮 + E1 三方对照 3 轮 + 连跑对照 4 轮）`[ERR]`=0 / `SCRIPT ERROR`=0；E1 指纹三方 `cmp` 逐字节相同。**既有随机 `Lambda capture` 报错已在 §四-① 单独列表交代，HEAD 同样会出现，非本批回归** |
| 负向对照 | 1 基线 + 4 变体，固定 `SMOKE_SEED=12345` 实跑（§五），转红 **1 / 2 / 0(仅 SCRIPT ERROR) / 3**，逐条如实标注 |
| 冻结清单 | 重定 **2 行**（`game_main.gd` / `player.gd`），仍 34 行、**34 OK / 0 FAILED**；`data.gd` 与 `hud.gd` 保持原值 |
| 对派单的偏离 | **1 处必要偏离**：主理人给的「1 层 = `无精英`、断言不含 `诅咒`」与实测不符，已改为「实值全等」断言（§七-1，**需主理人签认**） |

## 一、A · `floor_layout_hint()` 纯只读房型计数（v3）

落点：`scripts/game_main.gd:1016`（`update_floor_sign()` 之上）。

```gdscript
func floor_layout_hint() -> String:
	if dungeon == null:
		return ""
	var ne := 0
	var has_cursed := false
	for c in dungeon.rooms:
		var k := String(dungeon.rooms[c].get("kind", ""))
		if k == "elite":
			ne += 1
		elif k == "cursed":
			has_cursed = true
	var parts: Array[String] = []
	parts.append(("精英 %d" % ne) if ne > 0 else "无精英")
	if has_cursed:
		parts.append("有诅咒房")
	return " ｜ ".join(PackedStringArray(parts))
```

- 只读 `dungeon.rooms` 的 `kind` 字段；**零 rng / 零 fx_rng / 零计时 / 零权重 / 零状态写入**；不改 `dungeon`、不重生成地图。
- **与 `Game.floor_num` 无关**：读的是"当前已生成的那张图"。这一点是 v3 的关键约束——改 `floor_num` 不会重生成地图，而真去重生成会消费 `Game.rng`（破 E1 零抽取红线）。故探针**不得**靠改楼层造语境（§六 说明）。
- 补的信息盲区：`data.gd:297-306 ROOM_META` 里 `start` / `combat` / `elite` / `cursed` 四类房型的 `mark` **全是空串**，小地图对这四类零标注；而 `cursed` 房的进入代价（扣血）与 `elite` 房的强度是**决策相关**信息。本函数是纯陈述，不给建议。
- 红线：输出**不含** 建议/推荐/优先/带（探针逐词扫描）。

## 二、B · 层签第二行改「本层房型」

`game_main.gd:1038`：

```gdscript
	var sub_parts: Array[String] = []
	var lay := floor_layout_hint()
	if lay != "":
		sub_parts.append("本层 · " + lay)
	var rule := String(th.get("rule", ""))
	if rule != "":
		var flav := String(Data.FLAVOR.get("themes/" + rule, ""))
		if flav != "":
			sub_parts.append(flav)
	hud.set_floor_sign("层签 · %s ｜ 灾祸：%s" % [theme_part, cal],
		" ｜ ".join(PackedStringArray(sub_parts)))
```

- 主行 `"层签 · %s ｜ 灾祸：%s"` **一字未改**（探针全等回归锁）。
- `if lay != ""` 守卫保留：`lay` 仅在 `dungeon == null` 时为空，留着防止出现悬空 `本层 · `。
- `hud.gd` 的 `set_floor_sign(text, sub := "")` 与 `_floor_sign_sub_label` 构建**本批零改动**（md5 恒为 `86f38f9f…`），因为 v3 只换第二行的**内容来源**，不动渲染层。
- **双播红线**：仍只走层签常驻行，未调用 `flash_toast()`（首发现播报独归 `mark_codex()`）。

## 三、实测房型段（不是查表，随图变化）

固定种子 `SMOKE_SEED=12345` 的 1 层地图（`_tools/spr18_v3_6000_new_a.fp`）：

```
kinds=secret,treasure,shop,start,combat,elite,super_secret,elite,boss   → 精英 2，无诅咒房
```

随机种子下另外观测到的四种形态（同一批 5 次运行内出现，全部 0 报错，见 `_tools/spr18_v3_base_r{1,2,3}.log` 与 `spr18_v3s_base.log`）：

| 地图形态 | `floor_layout_hint()` 实返 | 该次 `[SMOKE-LAYOUT]` |
|---|---|---|
| elite×2，无 cursed | `精英 2` | `base` / `base_r1` |
| elite×2 + cursed×1 | `精英 2 ｜ 有诅咒房` | `base_final` |
| elite×1 + cursed×1 | `精英 1 ｜ 有诅咒房` | `nc3`/`nc4` 基线 |
| elite×1，无 cursed | `精英 1` | `nc4` 基线 |
| elite×0，无 cursed | `无精英` | `base_r2` / `base_r3` |

→ **五种形态（含 `ne == 0` 与 cursed 有/无两个分支）全部实跑覆盖，断言全绿。** 这是 v3 相对 v2 的实质差别：v2 的 `Data.SQUADS` 并集在 3 层以上恒为同一句，v3 每层随图变。

层签实值（`SMOKE_SEED=12345`，`_tools/spr18_v3s_base.log`）：

```
[SMOKE-FLOOR-SIGN] B: sub1=本层 · 精英 2  sub4=本层 · 精英 2 ｜ 矿脉层。多捡点，反射值钱。  main4=层签 · 源石矿脉◆ ｜ 灾祸：无
```

## 四、四个门控实跑结果

`G="D:/SteamLibrary/steamapps/common/Godot Engine/godot.windows.opt.tools.64.exe"`，全部在沙箱 `_backup/spr18_p1/sandbox/` 内跑，**每条实测跑前/跑后双 `md5sum` 夹逼**（`22e01945… / 33551e7f…`，见 §五 每行记录）。

**① 全量回归（6000 帧，全 env 含全部探针）**
```
env SMOKE=1 SMOKE_SEED=12345 SMOKE_V8=1 SMOKE_REBIND=1 SMOKE_RELIC_PROBE=orb_shield SMOKE_SUFFIX=1 \
 SMOKE_META=1 SMOKE_META_PERSIST=1 SMOKE_BOSS=1 SMOKE_FORCE_SOVEREIGN=1 SMOKE_FORCE_SQUAD=echo_pack \
 SMOKE_JUMP_FLOOR=11 SMOKE_DAILY=1 SMOKE_CALAMITY=1 SMOKE_SHRINE=1 SMOKE_CODEX=1 SMOKE_CODEX_BOON=1 \
 SMOKE_SIGIL_COVERAGE=1 SMOKE_FORCE_THIRD_BOSS=1 SMOKE_THIRD_BOSS=1 SMOKE_OATH=1 SMOKE_ECHO_CHAIN=1 \
 SMOKE_FLOOR_SIGN=1 SMOKE_FLAVOR=1 SMOKE_META_SETTLE=1 SMOKE_DAILY_SHARE=1 SMOKE_LAYOUT=1 \
 "$G" --headless --path . --quit-after 6000 > _tools/spr18_v3_full.log 2>&1
```
→ exit 0；`[ERR]`（= `Dev.check` 失败）= **0**、`SCRIPT ERROR|Parse Error` = **0**、`脚本编译扫描 34/34 通过` = 1、`validate problems=0`、`[SMOKE-*] done` **12 行 / 12 个唯一标记**（含新增 `[SMOKE-LAYOUT] done`）。日志 `_tools/spr18_v3_full.log`；实值行：`[SMOKE-FLOOR-SIGN] B: sub1=本层 · 精英 2  sub4=本层 · 精英 2 ｜ 矿脉层。多捡点，反射值钱。  main4=层签 · 源石矿脉◆ ｜ 灾祸：无`。

> **`^ERROR:` 行必须单独交代（不掩盖）**：本次 v3 全量日志里有 **4 条 `ERROR:`**，其中 3 条是 `Lambda capture at index 0 was freed. Passed "null" instead.`、1 条是退出期字体 RID 泄漏。**这不是本批引入的回归**——同 env 同 seed 连跑对照：
>
> | 跑次 | 字节 | `Lambda capture` | `^ERROR:` |
> |---|---|---|---|
> | `spr18_v3_full` | v3 | 3 | 4 |
> | `spr18_v3_new_r1` | v3 | **0** | 2 |
> | `spr18_v3_new_r2` | v3 | 3 | 5 |
> | `spr18_v3_full_head` | HEAD | 0 | 2 |
> | `spr18_v3_head_r1` | HEAD | **0** | 1 |
> | `spr18_v3_head_r2` | HEAD | **4** | 6 |
>
> → **HEAD 也会出现（head_r2 = 4 条），v3 也有 0 条的跑次（new_r1）**，属**既有随机现象**（与某次楼层切换时挂起的计时器回调捕获了已释放对象相关，随运行时序出现），**与本批两处改动无因果关系**。本批未修，建议单开一条 issue 追（§九-4）。门控 ① 的判定口径因此明确为：**`[ERR]`=0 且 `SCRIPT ERROR`=0**，`^ERROR:` 中除上述既有两类外应无新增——本次实测 v3 与 HEAD 的 `^ERROR:` 种类**完全一致**。
> 上一批全量串里的 `SMOKE_SITUATION=1` 已按 v3 改名为 `SMOKE_LAYOUT=1`；旧串跑 v3 代码只会少跑一个探针、不会报错，但**等于漏测 A**，交付文档与派单命令串须同步（§七-5）。

**② 冻结清单**：`md5sum -c production/sprint-7/SPR7-FROZEN-4.md5` → **34 OK / 0 FAILED**，仍 34 行；`diff` 证明**只有 2 行**变化（`player.gd e8dae022…→33551e7f…`、`game_main.gd 1288d675…→22e01945…`）；`hud.gd` 保持 `86f38f9f…`、`data.gd` 保持 `0c9cf515…`。

**③ E1 指纹（三方比对，同 seed 12345，各 6000 帧）**

| 跑次 | 字节 | 指纹行数 | 指纹文件 md5 |
|---|---|---|---|
| `new_a` | 改动版 `22e01945/33551e7f` | 2 | `55bf3134969320177b9f1bacf88f534a` |
| `new_b` | 改动版（同字节） | 2 | `55bf3134969320177b9f1bacf88f534a` |
| `head` | HEAD `1288d675/e8dae022` | 2 | `55bf3134969320177b9f1bacf88f534a` |

→ `cmp` 三方逐字节相同：**双跑确定性成立**，且**改动版与 HEAD 版同 seed 指纹零漂移**（`_tools/spr18_v3_6000_{new_a,new_b,head}.fp`）。
均只取 `[SMOKE-META] fingerprint` 行做 `cmp`，不比较整体日志（整体日志含逐帧坐标/敌人数量抖动，`cmp` 必然不一致——这是上一轮已订正的方法学，见 §十二）。

**④ E6**：全库 `FIXED_DT` **33 处**（未动）；`git diff ca948f0` 新增行含 `delta` = **0**；新增行含 `rand*`（rng 消费调用）= **0**（`Game.rng.` 仅 2 处命中：一处注释、一处 `Dev.check(... Game.rng.state == rs_state ...)` 状态读，不消费）。工作树 `delta` 引用 105 = HEAD 105。

## 五、负向对照（1 基线 + 4 变体，固定种子 `SMOKE_SEED=12345`，可复现）

脚本 `_tools/spr18_v3_neg2.sh` + `_tools/spr18_v3_mut.py`：每个变体只改一处锚点（`count(old) == 1` 断言），跑完立即从 stash 还原并复验 md5。

| 变体 | 突变点 | 变异后 md5 | `[ERR]` | `SCRIPT ERROR` | 转红断言 |
|---|---|---|---|---|---|
| `base` | 无 | `22e01945` | **0** | 0 | —（绿灯基线） |
| `nc1` | `ne += 1` → `ne += 2` | `7e5b680a` | **1** | 0 | ① 实值全等（实返 `精英 4` / 重数 `精英 2`） |
| `nc2` | `if has_cursed:` → `if not has_cursed:` | `a3ce2350` | **2** | 0 | ① 实值全等 + 「当且仅当本图有诅咒房」 |
| `nc3` | 删 `if dungeon == null: return ""` | `272b3b01` | **0** | **1** | 无 `Dev.check` 红；红在 `SCRIPT ERROR: Invalid access to property 'rooms' on Nil` @ `game_main.gd:1019` |
| `nc4` | 第二行丢 `"本层 · "` 前缀 | `9c76feae` | **3** | 0 | floor=1 三条 + floor=4「含本层」 |

日志：`_tools/spr18_v3s_{base,nc1,nc2,nc3,nc4}.log`。
**注（诚实标注，两点）**：
1. **`nc3` 按设计不产生 `Dev.check` 红**。删掉空图守卫后，`floor_layout_hint()` 在 `dungeon.rooms` 上空指针报 `SCRIPT ERROR` 并中断函数，返回值被当成 `""`，故「空图返回空串」这条断言**不会红**——它属**前提守卫型**（与上一批 `v1b_noguard` 同类）。该变体的红由门控 ①（报错误计数）捕获，不由断言捕获。这条已写进 `_layout_probe` 头注释分类。
2. **`nc2` 之所以与地图内容无关**：条件取反后，图里有诅咒房则少一段、没有则多一段，**两侧必有一侧不满足**「当且仅当」与全等，故换任意地图都红。

另有一批**随机种子**（未固定 `SMOKE_SEED`）的 5 次运行 `_tools/spr18_v3_base_r{1,2,3}.log` + `_tools/spr18_v3_base_final.log` + `_tools/spr18_v3_probe.log`，覆盖 §三 全部五种地图形态，`[ERR]` 全 **0**。

## 六、断言盘点（`_layout_probe` 12 条 + `_floor_sign_probe` 净增 4 条）

> 计数口径（实读复核）：`_layout_probe` 内 `Dev.check(` 共 **13** 处 = **12 条断言** + 1 条前置自检（`dungeon` 为空时直接判失败并 `return`）；`_floor_sign_probe` 内 `Dev.check(` 共 17 处，其中标签 `floor_sign_sub` **9 条**（v2 时代为 5 条）、`floor_sign` 4 条、`flavor` 4 条。

| # | 分类 | 断言 | 转红方式 |
|---|---|---|---|
| 1 | 验效果型（真值全等） | 返回值 == 独立重数的期望串 | nc1 |
| 2 | 验效果型（自洽） | `ne_truth == kinds["elite"]` 计数自洽 | 遍历逻辑写坏即红 |
| 3 | 验效果型（格式锁） | 段数 ∈ [1,2] | 拼接写坏即红 |
| 4 | 验效果型（格式锁） | 首段 == `无精英` 或 `精英 <纯数字>` | 格式漂移即红 |
| 5 | 验效果型（逻辑锁） | 诅咒段出现 **当且仅当** 本图有诅咒房 | nc2 |
| 6 | 验效果型（格式锁） | 次段只允许字面 `有诅咒房` | 文案写坏即红 |
| 7 | 验效果型（红线） | 输出不含 `(` `,` `Vector2i` `[`（零位置泄漏） | 报坐标即红 |
| 8 | 验效果型（红线） | 不含 建议/推荐/优先/带 | 加推荐语即红 |
| 9 | 验效果型 | 调用前后 `Game.rng.state` / `fx_rng.state` 全等 | 注入 rng 即红 |
| 10 | 恒等型 | 同图连调两次全等（幂等，兼抓状态泄漏） | 有状态即红 |
| 11 | **前提守卫型** | `dungeon == null` 时返回 `""` | **不转红（nc3 实证）** |
| 12 | 验效果型 | 置空后立即还原，同图输出不变 | 还原写坏即红 |
| 13 | 验效果型（回归锁） | floor=1 第二行**非空且可见** | nc4 |
| 14 | 验效果型 | floor=1 第二行以 `本层 · ` 开头 | nc4 |
| 15 | 验效果型 | floor=1 第二行含房型段实值 `lay1` | nc4（强于格式锁） |
| 16 | 验效果型（全等） | floor=1 第二行 == `本层 · ` + `lay1`（1 层无主题 → 无手记段） | nc4 |
| 17 | 验效果型 | floor=4 第二行可见且含 `本层 · ` | nc4 |
| 18 | 验效果型 | floor=4 第二行含房型段实值 `lay4` | 拼装写坏即红 |
| 19 | 验效果型 | floor=4 含 `矿脉层`（`FLAVOR["themes/vein"]` 实值，**v2 既有**） | 既有 |
| 20 | 验效果型（结构锁） | floor=4 含 `" ｜ "`（**v2 既有**） | 既有 |
| 21 | 验效果型（回归锁） | floor=4 主行 == `层签 · 源石矿脉◆ ｜ 灾祸：无`（**v2 既有**） | 既有 |

**探针为何不靠改 `Game.floor_num` 造楼层**：`floor_layout_hint()` 读的是**已生成**的地图，改 `floor_num` 不会重生成地图，断言会变成「同一张图换个标签」，是假绿灯；真去重生成要消费 `Game.rng`，破 E1 零抽取红线。故改用**独立重数 `dungeon.rooms`** 与返回值比对——验的是真值不是形状。
**副作用（如实记）**：探针 0.6s 定时器在 headless 下按**墙钟**触发，运行时 SMOKE 可能已推进到 2/3 层，因此断言**一律不硬编码层号与计数**，全部实值派生。这也是随机种子 5 次运行能覆盖五种地图形态的原因。

## 七、偏差清单

1. **【需主理人签认】派单给的 1 层预期与实测不符，断言改为「实值全等」。**
   派单裁定「1 层 sub = `本层 · 无精英`；断言 = 非空 + 含 `本层` + 含 `无精英` + 不含 `诅咒`」。**实测两处不成立**：
   - `SMOKE_SEED=12345` 的 1 层地图 `kinds=…,elite,…,elite,…` → **elite×2**，第二行实为 `本层 · 精英 2`；
   - 随机种子下曾出现 `精英 1 ｜ 有诅咒房` → 含 `诅咒`。
   若照派单硬编码，基线就会红。故改为：**非空 + 可见 + 以 `本层 · ` 开头 + 含房型段实值 + 全等 `本层 · <lay>`**（更强，且与种子无关）。这不是设计变更，是把错误前提换成实测真值；**请主理人确认**。
2. **A 由 v2（`Data.SQUADS` 布尔并集）整体换成 v3（`dungeon.rooms` 房型计数）**，主理人指定。v2 的问题（主理人原话口径）：输出是**每层恒定查表**，跑两局就背下来，不构成信息；且 `ROOM_META` 对 `start/combat/elite/cursed` 四类 mark 全空，是真实信息盲区。
3. **§七-3（归因更正，最终定性）**：上一版本文档曾写「检测到另一个写手并发写入 `game_main.gd`」。**该定性错误，已作废**。实际情况是**同一写手（本实例）的中断前草稿与恢复后草稿产生版本回声**：那份带 `（主理人 2026-11-08 v2 口径）` 注释的字节，是主理人消息文本被本实例抄进代码后未及清理的残留；`ff5e4a68…` 与我自己留下的截断负向变体 `_backup/spr18_p1/v2_trunc.gd` 逐字节相同。**经主理人核实无第三方写入。** 主理人一度因 `ls -la _tools/ | tail -12` 在字母序下把 `spr18_*`（排最前）截掉而误判「证据文件缺失」，已更正为精确 glob 核验。本实例亦已撤回「有外部写手」的说法。
4. **`hud.gd` 本批零改动**：v3 只换第二行内容来源，不动渲染层，故 md5 恒为 `86f38f9f…`；清单里该行保持重定后的值不变（相对 `ca948f0` 无变化）。
5. **探针改名（命令串失效提醒）**：`SMOKE_SITUATION` → `SMOKE_LAYOUT`、`[SMOKE-SITUATION]` → `[SMOKE-LAYOUT]`、`_situation_probe` → `_layout_probe`。上一批文档/脚本里含 `SMOKE_SITUATION=1` 的全量命令串在 v3 代码下**不会报错但会漏跑 A 探针**，已在本文件 §四-① 给出新串。
6. **前置自检 +1 条**：`_layout_probe` 开头若 `dungeon` 无效，直接 `Dev.check(false, …)` 并 `return`。它只在异常态触发，正常跑不计数，故 §零 记「12 条断言 + 1 条前置自检」。
7. **`_floor_sign_probe` 的 floor=4 段验的是「界面拼装」不是「真实 4 层地图」**：该探针用 `floor_num = 4` 切主题语境，但地图仍是当前已生成的那张（`floor_layout_hint()` 不随 `floor_num` 变）。真实地图真值由 `_layout_probe` 独立重数承担。已在函数头注释写明，不混淆两者。

## 八、回滚

```
# 回到 ca948f0（v2 入库态）
git checkout ca948f0 -- scripts/game_main.gd scripts/player.gd production/sprint-7/SPR7-FROZEN-4.md5
md5sum -c production/sprint-7/SPR7-FROZEN-4.md5    # 回 34/34
# 连 doc 一起弃：git checkout ca948f0 -- production/sprint-18/SPR18_交付_阶段一.md
```
本轮新增的批次备份（`_backup/` 全 gitignored，不入库）：`_backup/spr18_p1/{gm_before_v3.gd,player_before_v3.gd,frozen_before_v3.md5,v3_stash/,sandbox/,sandbox_head/}`。
`_tools/` 亦 gitignored。本批无新增 PNG，无需 `--headless --import`。

## 九、遗留 / 待决策

1. **文案终审**：`精英 N` / `无精英` / `有诅咒房` / `本层` 四个词条待文策渊复审。若只改措辞 → 改 `game_main.gd:1028`（`"精英 %d"` / `"无精英"`）、`:1030`（`"有诅咒房"`）、`:1047`（`"本层 · "`）三处字面量 **+ 探针里对应字面量**（`_layout_probe` 期望串构造 + 格式锁 `head_ok`；`_floor_sign_probe` 的 `本层 · ` 三处）。
2. **`有诅咒房` 是否需要「已付过代价」区分**：目前不区分「还没进」与「已付费」，也未读 `cursed_paid`。若要区分需读房间 info（仍是纯只读，但会引入跨字段耦合），本批未做，等指示。
3. 阶段二（C 誓约连绩退化版 + D 圣所熟客呼应 10 条）未开工，等派单。
4. **【既有缺陷，非本批】** `Lambda capture at index 0 was freed` 在 HEAD 与 v3 上都会随机出现（§四-① 对照表），成因疑为楼层切换时挂起的计时器/回调捕获了已释放对象。本批未动该路径，建议单开一条追踪；若要复现：`SMOKE_SEED=12345` + 上表全 env 连跑数次即可见。

## 十、提交范围

`scripts/game_main.gd`、`scripts/player.gd`、`production/sprint-7/SPR7-FROZEN-4.md5`（重定 2 行）、本文件。
**不含** `production/sprint-18/SPR18_规划草案.md`（主理人文件，未跟踪）与 `SPR18_设计候选实稿.md`（已在 `bbd70fb` 入库）。
建议提交信息：`Sprint 18 阶段一修订：A 换 v3 房型计数`。

## 十一、修订史与替换边界

| 版本 | 做法 | 结局 |
|---|---|---|
| v1 | `Data.SQUADS` 权重主倾向（近战/远程占比） | 实跑发现 3–7 层恒输出「近战冲锋」、`拆弹` 永不浮现 → 主理人否决，整体替换 |
| v2 | `Data.SQUADS` 布尔特征并集 + 固定优先级，取前 3 | 已入库（`4cf2cc4`/`8a246a6`/`ca948f0`）；后经主理人判定为「每层恒定查表，跑两局即背下来」→ 整体替换 |
| **v3（本批）** | `dungeon.rooms` 房型计数（`elite` 数 + `cursed` 有无） | 本文件 |

替换边界：v2 的 `floor_situation()`、`SITUATION_TAGS` 相关注释、`_situation_probe` 全部删除，`grep -c "floor_situation" scripts/{game_main,player}.gd` = **0 / 0**，无残码；`hud.gd` 不动。

## 十二、方法学订正（供后续批次沿用）

1. **E1 不可用整体日志 `cmp`**：日志含逐帧玩家坐标、敌人数量等实时抖动，整体 `cmp` 必然不一致。**只提取 `[SMOKE-META] fingerprint` 行做 `cmp`**，并额外与 HEAD 版同 seed 对比（§四-③ 即此协议）。
2. **核证据必须用精确 glob**：`ls -la _tools/ | tail -12` 会因字母序把 `spr18_*` 截掉。核文件是否存在请用 `ls _tools/spr18_*`、`ls -d _backup/spr18_p1/*`，不要靠 `tail` 取尾部。
3. **任何「已改/已修」结论必须在最后一次 `cp` 之后重新 `grep` 并贴输出**；不贴不算（本批 `out.size()` 曾因此误报一次）。
4. **探针断言必须验值/渲染，不验 flag**；且要在**已知会红**的变体上实跑证明它真的会咬（§五）。对「按设计不转红」的断言（前提守卫型）如实标注，不粉饰。
5. **实测一律在沙箱副本内跑，并对每条实测做跑前/跑后双 md5 夹逼**，不一致即判该条 INVALID 作废重跑。
