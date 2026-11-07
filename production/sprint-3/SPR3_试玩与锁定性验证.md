# Sprint 3 试玩与可拓展性 / 错误锁定性验证

> 日期：2026-11-05
> 版本：SPR3-FROZEN-3（本轮补强后）
> 方式：实跑游戏（headless + 窗口截图）+ 故障注入 + 像素取样

## 一、试玩实跑

| 跑法 | 结果 |
|--|--|
| headless 种子 4 × 600 帧 | `exit=0`；自检「敌人 28 / 房间 9 / 地图池 3 层」；超秘爆破→掉落→进房→商店购买全链正常 |
| 窗口 种子 2 × 1200 帧（OpenGL 3.3 / RTX 4060） | 截 200 / 600 / 1000 帧：战斗、击杀、技能冷却、秘密房爆破、精英房进入均正常；无棋盘格、无缺图标、UI 不重叠 |
| 结算画面（`SMOKE_DEATH=1`） | 全屏遮罩正常；状态条、小地图、技能条、武器槽均被压暗（小地图区域平均亮度 33.8 → 17.2） |

全部日志（`_tools/playtest_*.log`、`_tools/pt_*.log`）中 `SCRIPT ERROR` / `Parse Error` / `Invalid access` 为 0。

## 二、错误锁定性：注入故障实测

### 补强前（5 项注入，4 报 1 漏）

| 注入到 `data.gd` 的故障 | 启动自检 |
|--|--|
| 删 `ROOM_META["super_secret"]` | ✅「房间类型 super_secret 缺少元信息（小地图会没颜色）」 |
| `goblin.tex` 改不存在 | ✅「敌人 goblin 的贴图缺失：nonexistent_tex」 |
| `goblin.ai` 改未知 | ✅「敌人 goblin 的 ai 未实现：unknown_ai」 |
| 刷怪池加 `ghost_id` | ✅「第 1 层刷怪池引用了不存在的敌人：ghost_id」 |
| `slime.split` 改不存在 | ❌ **静默漏检** |

4 项均带 backtrace（`validate.gd:27` → `game_main.gd:131`），可直接点到行；注入后游戏仍能跑（有 fallback），不会一崩了之。

### 补强后（复测 2 项，全部命中）

| 注入 | 启动自检 |
|--|--|
| `slime.split` 改不存在 | ✅「敌人 slime 的 split 引用了不存在的敌人：nonexistent_split」 |
| `atk` 图标改不存在 | ✅「扩展图标缺失：icon_nonexistent_icon」 |

## 三、可拓展性：四类扩展的成本与风险

| 扩展 | 改动点 | 漏改后果 |
|--|--|--|
| 新敌人 | `data.gd` 一条 + 贴图（或 `atlas`+`row`） | 自检抓得到（贴图 / atlas / ai / hp） |
| 新升级 | `POOL` 一条 + `apply()` 一个分支 | 补强后：漏写 `apply` 分支会在抽到卡时 `Dev.err` 点名 |
| 新房间 kind | **10 处契约**（生成 / 元信息 / 小地图 mark+隐藏 / 进房分组 / 重建 / 自动驾驶 / SMOKE / validate 白名单） | 多数静默：看不见 / 炸不开 / 不进房；自检只抓 `ROOM_META` 缺失 |
| 新图标 | `generated/icon_*.png` 或 `ICON_RECTS` | `xicon` 回退白图 + 告警，不崩；补强后升级图标纳入自检 |

结论：数据层（`Data` 注册表）确实做到「加一条数据多一种怪 / 一层池」；**行为层（kind 分支、升级效果、ai）仍是静默风险区**，新增时必须按上面清单逐项核对。

## 四、本轮补强（3 处）

| 文件 | 改动 |
|--|--|
| `validate.gd` | 新增 `_check_enemy_refs()` 校验 `split` / `summon` 引用；`_check_icons()` 遍历 `UPGRADES.POOL`（`drone` 走面板特殊映射，列入 `ICON_ALIAS_KEYS` 跳过）；因 autoload 解析期看不到全局类名，用 `const UPGRADES := preload("res://scripts/upgrades.gd")` |
| `upgrades.gd` | `apply()` 加 `_:` 默认分支，未知 id 走 `Dev.err("upgrades", ...)`，避免「抽到卡没效果」的静默失效 |
| `hud.gd` | `_build_dungeon_ui(root)` 前移到两个 `_overlay` 之前（`:176`），删除原 `:235` 调用，结算 / 暂停遮罩覆盖全部 HUD |

## 五、回归结果（SPR3-FROZEN-3）

| 用例 | 结果 |
|--|--|
| 种子 1–6 × 9000 帧 | `err=0`；过门 18 / 9 / 12 / 16 / 11 / 15（全部 <40）；6/6 `entered floor 2`（种子 3 到第 3 层）；`[SMOKE-LOOP]` 0 |
| 死亡链路 | 4 次 `player died` / 0 报错 |
| 纯净启动 | 0 报错 |
| RG-6 | `[RG-6] reveal rebuild: room=(0,0) state=cleared doors=[...(false)]` 清场门全开；战斗态 `locked=true` 正常 |
| RG-7 | `[RG-7] xicon(nonexistent) fallback=white_tex problems=0`、`upgrade_panel._icon_for(nonexistent) texture=ok`；仅探针假 key 产生告警 |
| 自检 | 敌人 28 / 房间 9 / 地图池 3 层，`problems=0` |

## 六、版本哈希（SPR3-FROZEN-3）

| 文件 | md5 |
|-|-|
| dungeon.gd | `74286a0bfc9660b622bfab85f8db220a` |
| data.gd | `bb36856b47b8c20ed69b302c6eae025c` |
| game_main.gd | `55744d35125e4d2aa5a9c3fc51aef103` |
| hud.gd | `eefa0a5fcc42aac64acff77d8a65c9a7` |
| validate.gd | `ed1ffeb077f748ad9cc6ec3877b48d55` |
| upgrades.gd | `1abef13fcb8aec3f51c45e93103560b8` |
| assets.gd | `97bbf33bd6d1025e41073ab94f83d328` |
| upgrade_panel.gd | `18f44160159c483696e1684d3636cb9b` |

回滚点：`_backup/playtest/`（`data.gd_pre`、`data.gd_pre2`、`upgrades.gd`、`validate.gd`、`hud.gd`）。

## 七、遗留观察项（不阻断）

1. 冒烟非确定性仍在（headless + `time_scale=2`），过门数 9–18 浮动；已有 `[SMOKE-LOOP]` 断言兜底。
2. L4 真人试玩缺；暂停遮罩自动触发、挑战房 toast 截图未覆盖。
3. 种子 2 / 5 超秘房已揭示但 9000 帧内未进入领取（不违反 A5/A10，但拿不到稀有奖励）。
4. E1 护盾抵挡不算掉血、普通秘密房首次 loot 被跳过、O-1~O-4（见交接稿 §七）。
