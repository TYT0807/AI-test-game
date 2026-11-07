# Sprint 5 交付报告 · 升级套装 / 楼层主题 / 存档层 + BUG-001 根因修复

> 日期：2026-11-05
> 版本：SPR5-FROZEN-1
> 范围：A1 升级标签+套装、A2 楼层主题（4 层起）、存档层序列化接口；并修掉一个复发的自动驾驶震荡缺陷

## 一、A1 升级标签 + 套装（构筑质变）

| 标签 | 成员升级 | 套装效果（同标签 ≥3 件） |
|-|-|-|
| 火力 fire | 火力强化 / 射速提升 / 散射弹 / 弹道加速 / **弱点洞悉**（双标签） | 射速 +30%，且**子弹命中溅射**（半径 44，伤害 35%） |
| 元素 elem | 连锁闪电 / 淬毒弹头 / 炸弹补给 / **弱点洞悉**（双标签） | 连锁概率 +15%，且**中毒的敌人死亡时爆炸** |
| 生存 surv | 疾速靴 / 生命强化 / 护盾发生器 / 磁力吸引 / 浮游炮升级 / 幸运骰 | **濒死保护**：致命伤免疫、回复 2 血、1.5 秒无敌（每局一次） |

- 标签写在 `Upgrades.POOL` 每条内（`tag` 字段，`crit` 为双标签数组），新增升级漏写 tag 会被自检抓住（`validate._check_upgrades`）。
- 展示：升级三选一卡片上显示彩色标签徽章（`【火力】`/`【元素】`/`【生存】`）；HUD 左上 meta 面板第三行显示三流派进度「火/元/生 n/3」，集齐后变金色。
- 代码：`upgrades.gd`（TAGS / tag_counts / sets_active / count_tag / _apply_set / rebuild_tags）、`player.gd`（set_fire / set_elem / set_surv / survive_used + 濒死保护分支）、`bullet.gd`（`_splash` 溅射）、`slug.gd`（中毒死亡爆炸）、`hud.gd`（进度行 + `refresh_tags`）、`upgrade_panel.gd`（`_fill_tags` 徽章）。

## 二、A2 楼层主题（4 层起按 4→5→6→7 循环）

| 层 | 主题 | 环境规则 | 刷怪池 | 精英 / Boss |
|-|-|-|-|-|
| 4 | 源石矿脉 | 每次击杀额外掉 1 源石 | 第 4 池（新增混合强敌池） | 盾骑士 / 骷髅王 |
| 5 | 毒巢 | 每 3 秒掉 1 血 | 第 3 池 | 食人魔 / 炎魔 |
| 6 | 高压层 | 敌人移速 +30%、源石 +50% | 第 4 池 | 眼魔 / 黑龙 |
| 7 | 静默层 | 小地图整块隐藏 | 第 2 池 | 牛头人 / 巨岩虫之王 |

- 每层带独立地板/墙色调（`_floor_layer.modulate` / `_wall_layer.modulate`）；HUD meta 面板第四行显示「主题 · XXX」（1–3 层为空）。
- 之前 4 层以上完全重复（池子、精英、Boss 全走 fallback），现在每层都有新规则与新掉落。
- 代码：`data.gd`（`FLOOR_THEMES` / `theme_for_floor` / `pool_for_floor` / `elite_for_floor` / `boss_for_floor` 主题覆盖 + 第 4 池）、`game_main.gd`（`_apply_floor_theme` / `_tick_floor_theme` / 矿脉与高压规则）、`hud.gd`（`set_minimap_hidden`）。

## 三、存档层（序列化接口，只做接口不做 UI）

- `Game.to_dict()`：局内进度快照——统计、源石、层数、因子、共鸣、已选升级表、遗物清单。
- `Game.from_dict(d)`：读回并恢复；套装效果由 `game_main.reapply_sets()` 重新应用（`Upgrades.rebuild_tags()` 负责重建标签计数）。
- 探针 `SMOKE_SAVE=1` 做往返自测：取快照 → 读回 → 再取一次，逐字段比对。

## 四、BUG-001 根因修复（本轮最重要的产出）

**现象**：种子 3 在本轮回归中过门 123 次、`[SMOKE-LOOP]` 命中 4 次，在第 2 层的 elite / cursed / treasure 三房之间反复横跳。

**根因（不是本轮功能引入）**：`autopilot_door_target()` 的 BFS 分支写的是
```
for d in _doors: if d.dir == dir and not d.locked:
```
BFS 的目标是**未清的战斗房**，而战斗房的门在清场前是**锁着的** → 条件永不成立 → **静默落到终端兜底** → 兜底在「开着的门」里挑一扇 → 于是自动驾驶在「未清战斗房」与「已清房间」之间反复横跳。

Sprint 4 的 Hunk A 只挡住了「已访问的隐藏房」这一类，其余房间仍会被选中，所以它并没有除根因；本轮新增的诅咒房改变了地图路径，让这个老缺陷更容易暴露（QA 在 Sprint 4 也曾报过「修复前种子 3 = 86 次过门」）。

**修复（改根因，不是再加一层过滤）**：
1. BFS 分支去掉 `and not d.locked`——目标房还在战斗时门是锁的，但「贴门 1.2 秒强制过门」照样能进，所以不该按锁过滤；去掉后 BFS 目标始终可达，不会再落兜底。
2. 终端兜底改为**只走没去过的方向**（`visited == false`），无解则返回 `Vector2.ZERO` 停下，绝不在已清房间之间横跳。

**效果**：种子 3 连跑 3 次，过门 123 → 15 / 9 / 9，`[SMOKE-LOOP]` 归零，且 3/3 到达第 2 层。

## 五、新增 SMOKE 探针（均为环境变量门控，常态不生效）

| 探针 | 作用 |
|-|-|
| `SMOKE_SAVE=1` | 存档接口往返自测 |
| `SMOKE_JUMP_FLOOR=N` | 直接跳到第 N 层（看主题色调与 HUD） |
| `SMOKE_TOXIC_PROBE=1` | 绕过 SMOKE 无敌直接扣血，验证毒巢环境伤害确实生效 |
| `SMOKE_SHOT_UPGRADE=1` | 升级面板打开瞬间截图（验证卡片标签徽章） |
| `SMOKE_NO_AUTOPICK=1` | 升级面板不自动选卡（便于截图） |

## 六、验证（本机实跑，最终代码）

| 用例 | 结果 |
|-|-|
| 六种子 × 9000 帧 | 全部 `exit=0`、`err=0`、6/6 到第 2 层、过门 9–20、`[SMOKE-LOOP]` 0 |
| 种子 3 连跑 3 次（修复验证） | 过门 15 / 9 / 9、loop 0、3/3 到第 2 层 |
| 套装触发 | 六种子共触发 fire / elem / surv 三种，日志 `[SMOKE] set activated: xxx` |
| 楼层主题 | headless 18000 帧：`floor theme: floor=4 name=源石矿脉 rule=vein` → `entered floor 4` |
| 毒巢环境伤害 | 探针实测 hp 3 → 2 → 1（每 3 秒一伤，保底留 1 血） |
| 存档往返 | 开局与 3000 帧（有 1 个升级）两处均 `roundtrip=OK` |
| 死亡链路 / 纯净启动 | 5 次重开 / 0 报错；0 报错 |
| RG-6 / RG-7 | 清场重建门全 false；双探针通过、常态 0 条缺图告警 |
| 自检 | 敌人 28 / 房间 10 / **地图池 4 层**，`problems=0` |
| 窗口截图 | HUD 四行（因子 / 共鸣 / 三流派进度 / 主题）正常；升级卡徽章橙色【火力】【元素】与绿色【生存】正确；弱点洞悉正确显示双徽章 |

## 七、版本哈希（SPR5-FROZEN-1）

| 文件 | md5 |
|-|-|
| data.gd | `761282ac93f2c1abbdd25dea45191f4d` |
| dungeon.gd | `b798daef7d96385e3a3fe8e392c3cc62` |
| game_main.gd | `24f83f5565f3e0cae35a1befc6b7436d` |
| hud.gd | `3c4cb09c4b93dbdfeb78bbb59860b118` |
| validate.gd | `ddfa10885c8dfa836a1adc18db6232e6` |
| upgrades.gd | `028d48e3e402072d8e538d9e78b27580` |
| player.gd | `adaf8ae2286e04a48b98ba9a7a331728` |
| bullet.gd | `64b58c6a35944395d56fefce19e75155` |
| slug.gd | `8f170012e3419f73a55faba6efd05b96` |
| upgrade_panel.gd | `51d0ee1ea322d56d4937b8c85d5842b4` |
| game_state.gd | `0bec58a5d40ad88c225454fa7a366a3b` |
| assets.gd | `98b00939a616c001fc08dcbebf46f0df` |

## 八、平衡观察（不阻断）

1. 元素套装要求集齐「连锁 / 淬毒 / 炸弹 / 弱点洞悉」中的 3 件，而元素类升级只有 4 个、其中 2 个是稀有 → 达成概率偏低，可能让元素流成为"极端 build"。
2. 生存套装的濒死保护每局一次且回复 2 血，比护盾更强；与「护盾发生器」并存时可能让生存流过稳。
3. 毒巢每 3 秒掉 1 血、无视护盾，会让"回血类"遗物（吸血獠牙 / 黄金心脏）价值上升，属正向耦合，可保留。
4. 楼层主题目前只到第 4 层有差异化，5/6/7 的规则生效但玩家感受可能接近，需实玩观察。

## 九、回滚

`_backup/spr5/` 保存本轮改动前的全部脚本；`_backup/spr4/` 与 `_backup/spr3/` 保留更早的原点。回滚 = 复制回去 → 重跑 `--headless --path . --import` → 重跑六种子。
