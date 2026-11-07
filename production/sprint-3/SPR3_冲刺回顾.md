# Sprint 3 冲刺回顾 · 双坑回归包

> 项目：《源石虫清剿战》Godot 4.7.2.steam 肉鸽地牢
> 冻结版本：**SPR3-FROZEN-3**（试玩与锁定性补强后终版）
> 主理人：游承峰（编排）｜成员：程基岩（实现）· 严守真（QA）· 文策渊（设计）
> 日期：2026-11-05

## 一、冲刺范围与就绪故事

用户拍板「双坑回归包 + 全部落地」。项目无独立 backlog，就绪故事候选池为交接稿 §七 六条遗留；按 DoR（数据源已具备 / 不依赖外部素材 / 单冲刺可验证）挑选三条：

| ID | 故事 | 来源 | 触发面 | 结果 |
|--|--|--|--|--|
| S-01 | 超级秘密房（只连 1 间房、稀有掉落） | §七-3 | 房间重建 → 坑 6 | PASS |
| S-03 | HUD 护盾 / 连锁 / 淬毒状态显示 | §七-6 | 新图标 → 坑 7 | PASS |
| S-04 | 挑战房失败也给小奖励 | §七-5 | 结算逻辑 | PASS（D1 口径） |

未纳入：S-02 精英词缀扩展（备选加码）、S-05 道具合成 / 武器铭刻（缺设计评审）、S-06 逐帧行走动画（需外部素材）。设计侧复核确认无 scope creep。

## 二、两条坑：从解法到强制回归门

| 坑 | 交接稿 §五 解法 | 冻结代码落点 | P0 回归门 | 结果 |
|--|--|--|--|--|
| 重建房间后门锁死 | ⑥ `_build_arena` 新建门默认 `locked=true`，须按 `room_state == "cleared"` 补解锁 | `game_main.gd:753-759`（含 `Dev.check` 断言） | RG-6：超秘墙爆破后门锁转储全 false、能过门下楼 | PASS |
| 新增图标直接查表导致面板崩 | ⑦ 一律走 `Assets.xicon(key)`（generated → 原图集 → 白图＋告警） | `assets.gd:242-249`；`hud.gd:343` | RG-7：双负向探针返回白图、常态基线 0 条缺图告警 | PASS |

两条解法本轮**均未改动**，只作为实现约束与 P0 回归门执行。另有 §五-8（小地图走 `Data.room_color`）、§五-4（新 PNG 先 import）等约束同步纳入静态审计；本轮 `guard/chain/venom` 为既有图标 key，新增 key 与 PNG 均为 0。

## 三、质量门

| 门 | 负责人 | 判定 | 依据 |
|--|--|--|--|
| G1 实现 | 程基岩 | PASS | 三 Story 落地、改动集中、可逐 hunk 回退、改前两代备份 |
| G2 测试 | 严守真 | **PASS（FROZEN-2 无条件）** | 28 进程 exit=0、0 报错、冻结哈希前后一致；BUG-001 九连跑 0 命中并结案 |
| G3 设计评审 | 文策渊 | PASS（§11 上调） | B3/B5/B7 三条 CONCERNS 在冻结版全实修，四红线成立、无越界 |
| 主理人汇编 | 游承峰 | **PASS** | 见 §五 |

**用户硬要求 0 报错：满足。** FROZEN-2 上 28 个 Godot 进程全部 `exit=0`；28 份 `_tools/spr3_qa_f2_*.log` 中 `SCRIPT ERROR` / `Parse Error` / `Invalid access to property or key` / 素材加载失败 / RG-6 断言失败全部 0 匹配。自检统一「敌人 28 / 房间 9 / 地图池 3 层」、`problems=0`。

冻结有效：`FROZEN2_BASELINE_MATCH=YES` / `FROZEN2_HASH_STABLE=YES` / `FROZEN2_BASELINE_MATCH_AFTER=YES`；七脚本 md5 与 SPR3-FROZEN-2 基线完全一致（`game_main.gd 55744d35…`，其余六个同 F1）。

**X8 / G-10 逐层判定**：6 种子两层 `[SMOKE-SUPER] neighbors=1` 全触发、第 1 层 `dungeon map` 的 `super_secret` 全为 1；A5 合法跳过与挂具未覆盖均未发生。注意 `dungeon map` 只在 `start_run()`（第 1 层）打印，第 2 层以上改用逐层 `[SMOKE-SUPER]` 断言与 `_find_super_secret_cell` 每层唯一 key 作为等价证据；更深层 / 更大样本未覆盖，留待后续补测。

**试玩与锁定性补强（FROZEN-3）**：实跑 headless 与窗口模式（3 张截图）+ 结算截图，画面无缺图、无 UI 重叠；故障注入 5 项，4 项被自检精准点名、1 项静默漏检（`slime.split` 引用不存在 id）。已补 `validate._check_enemy_refs()`、升级图标全量校验、`upgrades.apply()` 默认分支，并把 `_build_dungeon_ui` 前移到遮罩之前（结算时小地图平均亮度 33.8 → 17.2）。补强后复测两项全部命中，六种子 / 死亡 / 纯净 / RG-6 / RG-7 回归全过。详见 `production/sprint-3/SPR3_试玩与锁定性验证.md`。

## 四、版本事件与冻结（如实记录）

阶段 B 期间出现代码跨版本改写：15:18 插桩 → 15:23 移除插桩并落地 `_is_special_room` 选格收紧 → 15:35 两处授权补丁。期间 `HASH_STABLE=NO`，早期日志不可作放行证据。

**根因在编排层**：S-04 最终口径只同步给 QA 与设计、漏发给工程侧，叠加多次消息时序交叉，导致两个成员拿到互相矛盾的口径。责任不在任何成员，已定性为 `[FLOW-001]` 流程事件并结案，不记为 Bug。

处置：停止工程侧运行 → 两处授权补丁 → 实算七脚本哈希确立 **SPR3-FROZEN-1** → 在单一版本重跑完整 `f1` 组。早期所有跨版本日志（T1 15 份、上一版 QA 27 份、`spr3_intermediate/`）只作历史记录。

FROZEN-1 判定 CONCERNS 后，用户拍板「先修 BUG-001 再放行」。工程侧只读定位根因（`autopilot_door_target` 终端兜底零过滤，配合 `_doors` 上→下→左→右 与超秘叶子房形成自激闭环），按最小改动落地两个 hunk（兜底过滤 + 收敛点、SMOKE 诊断断言），只改 `game_main.gd`（`20c3900e…` → `55744d35…`，其余六脚本哈希不变），冻结为 **SPR3-FROZEN-2** 并完整重跑 `f2` 组。

## 五、已知风险与缓解

| 级别 | 项 | 缓解 / 待办 |
|--|--|--|
| ✅ 已结案 | **BUG-001 自动驾驶绕超秘房循环**：FROZEN-1 种子 4 过门 71 次 / 进超秘房 17 次 / 卡第 2 层；FROZEN-2 种子 4 **九连跑 0 命中**，过门 16–21、进超秘房 1–2、9/9 到第 2 层 | 修复：兜底排除已领取隐藏房与已访问已清邻房，全排除返回 `Vector2.ZERO` 形成收敛点；加 `[SMOKE-LOOP]` 重复过门 / 坐标不动断言 |
| 🟡 观察 | 种子 2、5 超秘房已揭示但 9000 帧内未进入领取（不违反 A5/A10，但拿不到稀有奖励） | 下轮评估让「已揭示未访问隐藏房」优先于普通未清房 |
| 🟡 CONCERNS | 冒烟非确定性仍在（headless + time_scale=2），过门数 11–22 浮动 | 已加 `[SMOKE-LOOP]` 断言兜底；后续可固定 delta / 关 time_scale |
| 🟡 CONCERNS | L4 真人试玩缺失；toast 截图、暂停遮罩自动触发未覆盖 | 下轮补（当前以静态层级 + 结算遮罩截图类推） |
| ⚪ 观察 | E1 护盾抵挡不算掉血、普通秘密房首次 loot 被跳过、超秘随机武器可能换掉更强武器、O-1~O-4 | 记入交接稿 §七，不阻断 |

**放行依据**：P0 门 PASS、0 报错、冻结哈希前后一致、BUG-001 九连跑 0 命中。用户此前选择「先修 BUG-001 再放行」，修复后判定由 CONCERNS 转为 **PASS（无条件）**，可交付。

## 六、交付清单

| 类别 | 路径 |
|--|--|
| 代码 | `test-1/scripts/`（dungeon / data / game_main / hud / validate 五个文件，终版 SPR3-FROZEN-2） |
| 备份 | `test-1/_backup/spr3/`（14:31 原稿 + 15:34 `_p2` 快照 + `bug001/game_main.gd_pre`） |
| 实现清单 | `test-1/production/sprint-3/SPR3-T1_实现与改动清单.md`（282 行，含 6 项答复与版本事件） |
| 设计规格与评审 | `test-1/production/sprint-3/SPR3-T3_范围检查与设计规格.md`（767 行，§10 阶段 B + §11 冻结版复核） |
| QA 计划 | `test-1/tests/SPR3_QA计划与用例.md`（433 行，含 X8 逐层断言） |
| 测试报告 | `test-1/tests/SPR3_测试报告.md`（196 行，FROZEN-2 最终判定、九连跑表与逐项证据） |
| 证据 | `test-1/_tools/spr3_qa_f2_*.log` 28 份 + 截图 `shots_f2_status/`(22) / `shots_f2_gameover/`(22) + 4 份哈希（`f1` 组只作历史记录） |
| 本回顾 | `test-1/production/sprint-3/SPR3_冲刺回顾.md` |
| 下一轮交接 | `D:\Create\Game\交接_Sprint3.md` |
| 玩家向文档 | `test-1/玩法说明.md`（已同步第三轮） |

## 七、下一步

1. 本冲刺已按用户要求先修 BUG-001 并复审通过，判定 **PASS**，可交付。
2. 下轮首批：L4 真人试玩与 toast / 暂停截图、超秘奖励领取率优化（已揭示未访问优先）、冒烟稳定化、交接稿 §七 其余遗留项。
