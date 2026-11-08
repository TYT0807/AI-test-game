# Sprint 16 阶段二交付：C 层签 + D 地窖低语

> 日期：2026-11-08｜依据 `SPR16_规划草案.md` 定稿 §四/§五（本批 = 阶段二）｜分工：编程侧
> 改动文件：`hud.gd` / `game_main.gd` / `data.gd` / `game_state.gd` / `menu.gd` / `validate.gd` / `player.gd`（探针）

## C 层签（§四，随机性可读化）

- `hud.gd` 新增 `_floor_sign_label` 常驻只读标签（`_theme_label` 同容器）+ `set_floor_sign(text)`——**走 set_room_info 同通道持久显示，未用 `hud.banner()`**（覆盖式 tween 会被盖，eng 复核结论）
- `game_main.update_floor_sign()`：纯只读拼装——主题 name+mark + 灾祸名或「无」，**恰好 2 项默认**（可访问性口径：复用色盲 mark、字号档 _fs(12)）；零 rng / 零 fx_rng / 零抽取
- **两个挂点（§4.2 口径，不移动任何 roll、不塞进 `_roll_calamity` 函数体）**：
  - `start_run`：`_apply_floor_theme()` 之后、`_enter_room()` 之前（roll 全在 enter 前 ✓ 实稿字面）
  - `next_floor` 的 `_fade_to`：`_roll_calamity()` 之后、`drop_pickup()` 之前（本路径 roll 在进房后——「enter 前」不可达，这是**不改 rng 顺序的唯一解**；theme 在同一回调更早的 `_apply_floor_theme` 已就绪）
- 探针断言「roll 前后 rng 消费次数不变」用 `Game.rng.state` / `fx_rng.state` 前后相等实现（零抽取自证）

## D 地窖低语（§五，关联 · 叙事钩子）

- `data.gd FLAVOR` **11 条**（3 主题 Boss + 8 主题），基调=**废弃矿窟的实用主义**（克制、功能性矿工手记口吻，只写已存在条目）
- 播报挂 `mark_codex` **新增发现分支内**（重复登记在其上方 return，天然只播一次）→ `hud.flash_toast("矿工手记 · …")`；未命中表静默（enemies/relics 无文案不受干扰）
- 图鉴展开：`_codex_section` 已发现条目附灰色「手记：…」行
- 手记**不入分母/白名单**（`codex_bosses_total()` 仍 7）；`validate` 补「三主题 Boss 手记覆盖」防「表写了没接上」

## 验证（全部实跑）

| 项 | 结果 |
|-|-|
| SMOKE_FLOOR_SIGN / SMOKE_FLAVOR 定向 1500 帧 | 9 断言全过、0 [ERR]：层签与实值一致（无主题/灾祸名切换）+ **零 rng 消费（rng/fx_rng state 前后相等）** + 首发现播报（`_toast.text` 直读）+ 重复不播 + 分母 7 + 图鉴手记行渲染 |
| 全量回归（22 钩子含 FLOOR_SIGN+FLAVOR，6000 帧） | **0 报错**、9 done 标记 |
| E1 / E6 / 坑 5 / 冻结规格 | 零 rng（state 自证）/ 零计时 / `ACTION_DEFS` `GEN_NAMES` 零新增 / `UNLOCKS` `CODEX_BOONS` 不碰 |
| 指纹 | `SMOKE_META_FINGERPRINT` 语义下零新增抽取——层签两挂点均为纯只读刷新 |
| 冻结重定 | `md5sum -c` **34/34 OK**（无新脚本） |

## 过程如实记录

1. 首跑 1 红：floor_sign 探针的「无主题」前提被探针并发交错打破（shrine 探针临时置 floor=5 的窗口落在读取时，毒巢=5 层主题）——探针改**自设 floor 语境、结束还原**（探针间隔离纪律）
2. validate 编辑首跑锚点错（`if` vs `elif`）——修正后过

## 还剩什么

- Sprint 16 锁定范围 **A+B+C+D 全部交付完毕**（四方向零重定、冻结保持 34/34）
- 主理人并行项：E 断言盘点、文档整理批（`production/sprint-16/` 三份 + 玩法说明待授权入库）
- D/E/G 备选未接；F1 永不接
