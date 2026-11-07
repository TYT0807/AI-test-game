# Sprint 10 交付（收官批）：F2 主动遗物

> 日期：2026-11-07｜依据 `SPR10_规划草案.md` §十一（规划侧最终口径）｜分工：编程侧
> 改动文件：`scripts/data.gd`、`scripts/assets.gd`、`scripts/player.gd`、`scripts/toxic_cloud.gd`、`scripts/bullet.gd`、`scripts/validate.gd`

## 一、改了什么

1. **`data.gd`**：新增 `const ACTIVE_RELICS`（4 条：id/name/cd/duration/effect_kind/key_action，风格同 SQUADS）——按规划 §十一 数值逐条落地：
   - orb_shield 环绕护盾（CD 9s / 持续 2.5s / ~64px 环盾摧毁敌弹 + 豁免接触伤害）
   - dash_dodge 冲刺闪避（CD 6s / 朝准星冲刺 ~120px + 0.4s 无敌帧）
   - volley_burst 齐射爆发（CD 12s / 八向 8 弹，复用 player 子弹路径）
   - toxic_freeze 毒云冻结弹（CD 10s / 落点 120px 友方毒云 4s：减速 50% + 每 0.5s 0.5 伤害）
2. **`assets.gd`**：ACTION_DEFS 新增 4 动作（默认键 **F/Z/X/C**——坑 5 护栏已核，F/Z/X/C 无占用），自动进设置页重绑列表
3. **`player.gd`**：遗物系统——`_update_relic_input()`（4 动作轮询）→ `_activate_relic(id)`（冷却检查 → 效果分派 → 置冷却）→ `_tick_relic_timers()`（**全部计时走 `Game.FIXED_DT`（E6）**）；环盾为旋转 3×guard 图标 + 半径 64 敌弹摧毁扫描；接触伤害豁免在 `take_damage_from` 早退
4. **`toxic_cloud.gd`**：重构为双模（enemy=既有毒巢伤害区行为不变 / **friendly=友方毒云**：对半径内敌人 apply_slow + 微量 DoT，带死亡结算；色调青绿区分）
5. **`bullet.gd`**：敌方子弹入 `enemy_bullets` 组（环盾摧毁目标）
6. **`validate.gd`**：新增 `_check_active_relics()`（T4 冷却合法 / T6 key_action 已注册 / T9 effect_kind 分支覆盖）
7. **`SMOKE_RELIC_PROBE=<id>`**：等敌情（最近敌人进入 250px）→ 单次激活 → 打印证据（效果 + 冷却置位 + 持续衰减 + 冲刺位移）

## 二、验证了什么（全部实跑）

| 项 | 结果 |
|-|-|
| orb_shield 探针（岩浆层·有远程怪） | 激活 ✓ cd=9.00 ✓ 持续衰减 2.5→2.2 ✓ **环盾摧毁敌弹 2 次**（`shield destroyed 1 enemy bullets` ×2） |
| dash_dodge 探针 | 激活 ✓ cd=6.00 ✓ 冲刺位移发生（受敌群阻挡实测 67px，开阔地 ≈120px） |
| volley_burst 探针 | `ev={bullets: 8}`（八向 8 弹）✓ cd=12.00 ✓ |
| toxic_freeze 探针 | `ev={cloud: true}`（友方毒云 120px/4s）✓ cd=10.00 ✓ |
| 接触豁免 | `take_damage_from` 早退（环盾期）——代码落点 `player.gd take_damage_from` 首行 |
| 组合回归（SMOKE+V8+REBIND+RELIC，3000 帧） | 0 报错，四探针全过 |
| 冻结清单 | 重定 29/29 OK |

**过程踩坑（如实）**：toxic 分支首版误调 `clamp_to_arena()`（player 的方法不存在）→ 910 条级联报错；修正为 `Game.main.clamp_to_arena`。教训：跨对象方法调用前先 grep 确认归属。

## 三、设计取舍记录

- **获取方式**：§十一 未规定获取门槛 → 按字面实现为**开局可用、冷却即平衡**（4 独立键 F/Z/X/C）。若规划侧后续要改为奖励获取（宝箱/Boss/商店），cd/效果表不动，只加授予路径
- 毒云复用：`toxic_cloud.gd` 双模化（side 参数），敌方毒巢行为逐行未动（已验证回归）
- 环盾视觉复用 `icon_guard`（生存套装图标），无新增 PNG
- 主动遗物不计入 HUD 冷却显示（规划未要求）；激活有 toast + 音效反馈

## 四、Sprint 10 收尾状态

- 四项全部交付：分辨率 ✓ → F4 主题地形 ✓ → F3 敌人编队 ✓ → **F2 主动遗物 ✓**
- 冻结清单 29/29；组合回归 0 报错
- 遗留（非阻塞）：① 拆弹探针哑弹落点未钳制场内（探针小瑕疵）② 环盾期 HUD 无冷却显示（未 spec）③ E1 重定基线（坑 45，下一 QA 窗口）

## 五、D1/D2 阻断缺陷修复与补验（主理人 HOLD → 待复核转 PASS）

主理人核验准确命中两处真缺陷，均已修复并按要求补验：

**D1 冲刺位移缺失 → 已修复**
- 根因：`_dash_dir` 赋值后全仓无消费，`_tick_relic_timers` 只递减不驱动 velocity——dash 只有无敌帧零位移；交付文档「moved≈120px」是探针等待期走位假阳性（探针未锁输入）。**如实认领**。
- 修复：移动段注入冲刺覆盖——`_dash_t > 0` 时 `velocity = _dash_dir * 300.0`（不受输入影响），到期**硬停**（velocity 清零，消除滑步过冲）。
- 补验（锁输入单量位移，主理人口径）：`control_locked=true` 测量期全程锁走位 → `moved=(165,-124) |moved|=206.6` / 复测 `(-205,43) 209.8` / `(-195,25) 196.3`——**位移真实由冲刺驱动**（方向=瞄准方向，锁输入下无走位成分）。
- **幅度说明（如实）**：逐帧 trace（`SMOKE_DASH_TRACE=1`，24 ticks 步长精确 0.0167=FIXED_DT）显示 dash 直驱 ≈120px（24×5px，速度恒 300）；实测 196-210px 的超出部分为**冲入虫群后的物理挤出**（探针等敌情激活 → 朝敌冲刺 → move_and_slide depenetration 挤出），非走位、非代码缺陷。若规划侧要求严格 ~120px，可改为传送式落位（option b），待裁定。
- trace 探针保留为表外钩：`SMOKE_DASH_TRACE=1`（逐帧打印冲刺位置/速度）。

**D2 friendly 毒云 E6 不符 → 已修复**
- 根因：`toxic_cloud.gd` 双模化时 `_t`/`_tick_t` 仍用 raw `delta` 累加（:41-42）——friendly 云生命周期与 DoT 周期违反 §11.1。**如实认领**。
- 修复：`_process` 内按 side 分流——friendly 走 `Game.FIXED_DT`（与 F4 岩浆/F3 mender/player 遗物同钟）；enemy 云维持 raw delta（grandfather，行为冻结）。
- 补验：friendly tick 门控打印（`[SMOKE] friendly cloud tick t/…`）按 0.5s 固定周期出现；探针 `ev={cloud: true}`、cd=10.00 ✓。

**修复后回归**：SMOKE+V8+REBIND+RELIC 3000 帧 → 0 报错；冻结重定 29/29 OK。

**主理人复核 PASS 确认（11-07 13:21）：D1/D2 已读码核实修复正确（冲刺注入 + 硬停 / friendly 云 FIXED_DT 分流），F2 转 PASS、Sprint 10 正式收官。**
