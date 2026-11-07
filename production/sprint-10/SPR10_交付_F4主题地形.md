# Sprint 10 交付（第二批）：F4 主题地形

> 日期：2026-11-07｜依据 `SPR10_规划草案.md` §三｜分工：编程侧（规划侧只读）
> 改动文件：`scripts/data.gd`、`scripts/prop.gd`、`scripts/player.gd`、`scripts/game_main.gd`、`resources/texture/generated/prop_vine.png`（新）、`_tools/gen_assets.py`（+vine 画师）

## 一、改了什么

1. **`data.gd`**
   - `FLOOR_THEMES` 新增 4 主题（楼层循环 4→…→11→4）：岩浆灼烧(magma, pool4/精英牛头人/Boss炎魔)、冰面打滑(ice, pool2/盾骑士/骷髅王)、毒沼减速(swamp, pool3/食人魔/炎魔)、藤蔓阻挡(vines, pool2/眼魔/黑龙)，各带主题色调
   - `OBSTACLES` 新增 `"vine": {"hp": 2, "solid": true}`
2. **`prop.gd`**：vine 加入 solid 集合；碰撞层与石柱同级（layer 1 全向阻挡——挡人挡弹挡虫），可打掉（hp 2，走既有 crates 组伤害路径）；贴图走 `Assets.g("prop_vine")`
3. **`player.gd`**：新增 `terrain_speed_mult` / `terrain_accel_mult` 两系数（默认 1.0），接入移速与 move_toward 加减速率
4. **`game_main.gd`**
   - `_apply_floor_theme()`：进房先复位地形系数，ice → accel ×0.3（打滑），swamp → speed ×0.7
   - `_tick_floor_theme()`：重构为 match 分发；**magma DoT 计时走 `Game.FIXED_DT` 固定步（守 E6 铁律）**，每 0.5s 结算 1 血；环境 DoT 结算抽公共 `_theme_damage_tick()`（毒巢探针语义不变）
   - `_spawn_props()`：藤蔓层在 vines 主题追加 3 处藤蔓；点位数组 8→12（避开门口走廊）
5. **`_dump_entities()`**：新增 props 按种类统计行；dump 触发扩为 240 帧 + 每 1200 帧（验证钩具增强）

## 二、验证了什么（全部实跑）

| 项 | 结果 |
|-|-|
| 跳层实测 floor=8 | `rule=magma` + **38 次 magma tick**（固定步 DoT 持续结算）+ 0 报错 |
| 跳层实测 floor=9 / 10 | `rule=ice` / `rule=swamp` 激活，0 报错（地形系数直连 player 物理） |
| 跳层实测 floor=11 | `rule=vines` + **DUMP 实证藤蔓生成**：`{vine: 1}` → `{vine: 4}`（随房间推进） |
| 藤蔓贴图 | `prop_vine.png` 生成并导入（首次实测发现未导入导致隐形——已补 `--import`，**新资源必须先 import 再验证**，已记入流程） |
| 藤蔓可见性 | 截图绿色像素扫描 + 多帧追踪（眼魔精英绿贴图为假阳性源，最终以 DUMP 实体计数为准） |
| 组合回归（SMOKE+V8+REBIND，3000 帧） | 0 报错；V8/REBIND/自检全过 |
| 冻结清单 | 重定 29/29 OK |

## 三、设计取舍与铁律遵守

- **E6**：magma DoT 用 `Game.FIXED_DT` 累加（不随帧率/time_scale 漂移），符合规划铁律；毒巢既有实现保持 raw delta 原样未动（不在本轮范围，行为已冻结验证）——两主题计时口径差异已在本文件记录，若要统一由规划侧裁定
- **藤蔓定位**：全向阻挡（区别于桶/图腾的只挡人挡弹），hp 2 可打掉——提供「改变走位路线」而非「永久墙」
- **冰面**：只降加减速系数（0.3），不改最高速——打滑手感靠「停不下来」，不惩罚走位输出
- 主题循环 4→…→11→4（`theme_for_floor` 自动适配 8 主题）

## 四、还剩什么

- Sprint 10 剩余：F3 敌人编队（守 E1 指纹隔离）→ F2 主动遗物（输入表已定稿）
- 已知边界：藤蔓/石柱为全向阻挡，敌人 AI 无绕路寻路（直线追击 + 滑动），密集藤蔓房虫群可能短暂卡顿——与石柱行为一致，属既有特性
