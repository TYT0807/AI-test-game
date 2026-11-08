# Sprint 16 阶段一交付：A 地窖誓约 + B 抉择回声

> 日期：2026-11-08｜依据 `SPR16_规划草案.md` 定稿（锁定 A+B / C+D；本批 = 阶段一）｜分工：编程侧
> 改动文件：`data.gd` / `game_main.gd` / `game_state.gd` / `player.gd` / `menu.gd` / `validate.gd`
> 三份待授权文档（草案 / 设计实稿 / 全锁存档）按令未混入

## A 地窖誓约（联动型核心增量，§二）

- `data.gd OATH_CONDITIONS` **9 条一一对应 SIGILS 键**（validate 启动期校验 + 探针复验）：vigor 流血不退（受击3）/ arsenal 双持共鸣（词缀触发2）/ purse 圣所常客（进圣所2）/ kindred 并肩清扫（击杀30，直读 Game.kills）/ bulwark 盾未破身（护盾格挡1）/ sprinter 残影连闪（冲刺15）/ harvester 满载而归（获得源石40）/ ward 净化誓约（净化1）/ scholar 兼修并蓄（圣所+词缀各1，**多条件取最小**）
- **只读既有事件计数**：计数点全部挂在既有分支（`take_damage` 受击/盾挡、`dash` 起手、`add_diamonds` 正增量、`_fire_relic_suffixes` 冷却消耗后、`_open_shrine` 非空路径、`_shrine_execute` purify）——**零新事件、零 rng、零计时、不调 mark_codex（P0 自激红线）**
- 兑现度派生 `oath_fulfillment()` 纯只读；**不回注局内数值**（v1 硬边界）
- **落盘（§2.3 口径）**：`_settle_meta` 中 `set_codex_last_run(stats)` **之后**调 `_write_codex_replay()`（写 `last_run.oath` / `last_run.echo` + 再 `save_codex()`——两次写盘为既定代价）；位置在 `if pay <= 0: return` **之前**；`set_codex_last_run` 本体与 `STATS_KEYS` 零改动

## B 抉择回声（数据地基，§三）

- `_on_shrine_chosen` 登记 `_echo_choices`（offer 依时间序）+ `_echo_costs`（代价类型分布）；局末派生**构筑标签**：主导代价 → 血偿流 / 散财流 / 功勋流 / 实用流（矿工实用主义口吻）
- 复盘页新增两行：「本局誓约 · …（cur/need，绿=已兑现）」+「抉择回声 · 标签：offer 名 → …」——纯展示、不进任何分母

## 验证（全部实跑）

| 项 | 结果 |
|-|-|
| SMOKE_OATH / SMOKE_ECHO_CHAIN 定向 1500 帧 | 12 断言全过、0 [ERR]：表对应 / 计数增量 / 阈值边界（2/3 未兑现 → 3/3 兑现）/ 多条件取最小 / 标签派生 / **写 → load_codex → 逐字段读回**（含 done）/ **五类发现集不被抹**（P0-3.2 写法）/ **渲染验证**（真调 `menu._build_codex()` 扫描生成标签——验渲染非验字段） |
| 全量回归（20 钩子含 OATH+ECHO_CHAIN+META_SETTLE，6000 帧） | **0 报错**、8 done 标记 |
| E1 / E6 / 坑 5 / 冻结规格 | 零 rng / 零计时 / `ACTION_DEFS` `GEN_NAMES` 零新增 / `UNLOCKS` `STATS_KEYS` `CODEX_BOONS` 不碰 |
| 冻结重定 | `md5sum -c` **34/34 OK**（无新脚本） |
| 指纹 | 零新增 rng 消费（计数点全在既有分支内，不动任何抽取顺序） |

## 过程如实记录

1. 首跑 1 红：探针 echo 断言期望值与自建数据不符（构造 2 项断言写 3）——文件实读确认写入正确后修断言期望
2. 中途自查撤掉一处 no-op 占位（`oath_count("kills", 0)`——kindred 直读 Game.kills，占位无意义）

## 还剩什么

- **阶段二 C 层签 + D 地窖低语**：与 `set_room_info` 同容器的独立常驻只读标签 `set_floor_sign()`（hud.gd:585）两调用点（start_run roll+theme 后 / enter 前；next_floor roll 后 / drop_pickup 前，**不移动任何 roll**）、默认 2 项可展开、`FLAVOR` 文案表（废弃矿窟实用主义）+ 首发现播报（`mark_codex` 新增时查表 toast）+ 图鉴展开
- 主理人并行：E 断言盘点、文档整理批
