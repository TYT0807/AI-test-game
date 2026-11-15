# Sprint 23 交付：跨局闭环 · 誓约连绩（单批落地——实稿 §七第 3 条裁定）

> 日期：2026-11-15｜依据 `SPR23_设计实稿.md`（主理人评审 PASS）+ 主理人实施单（四项拍板全 A）｜分工：编程侧
> 改动文件：`game_main.gd` / `menu.gd` / `player.gd`（探针）——**game_state.gd / meta.gd / data.gd / validate.gd 零改动**（实施单零动清单全部遵守）
> 设计实稿随批入库（`production/sprint-23/SPR23_设计实稿.md`）

## 实现（实施契约逐项）

| 契约 | 落地 |
|---|---|
| `(B) prev := _read_oath_streak()` 覆盖前快照 | `_settle_meta()` 中 `set_codex_last_run(stats)` **之前**（纯读内存态、零 IO/零 rng/零计时） |
| `_write_codex_replay(prev_streak := -1)` 可选哨兵 | oath/echo 赋值之后、`Game.save_codex()` 之前写回 `oath_streak`；`prev < 0` 跳过（player.gd 无参直调零回归、SMOKE 隔离档不污染） |
| `_read_oath_streak()` | `.get(...,0)` + 类型守卫（非 int/float 归 0）+ `maxi(...,0)`；**不读盘** |
| `next_oath_streak(prev, H, D)` | **static 纯函数**零全局态读取：H=0→S；H=1,D=1→S+1；H=1,D=0→0（实稿 §一 1.2 逐字） |
| 图鉴/印记页两 Label | 键存在 + 值合法 + oath 非空才创建（非建后隐藏）；前缀「连绩 · 」/「上局连绩 · 」严格区分；既有「本局誓约 / 上局誓约」一字不改 |
| `save_codex()` 生产结算路径调用点仍 2 处 | oath / echo / oath_streak 同一次 `_write_codex_replay()`、同一次落盘（T3 防撕裂）；**生产脚本新增调用数 0**（全库 5→6 的差值为本批探针清场 1 处 `player.gd`——SMOKE 隔离档，子代理审查核对） |
| 陷阱注释 | `stats` 只有 5 个 `STATS_KEYS` 键——oath_streak 塞进 stats 会被白名单静默丢弃（n3 实证），已写进函数注释 |

**红线全守**：零新增 rng/fx_rng/delta；不扩 `CODEX_KINDS`（`_codex_boon_suffix()` 派生 key 逐字不变）；`FLOOR_THEMES`/`ACTION_DEFS`/`FLAVOR`/`CODEX_BOONS`/`STATS_KEYS`/`UNLOCKS` 不动；连绩纯展示零数值回注、不入分母。

## 验证（V1-V9 + n1-n8，实稿 §六口径）

| 项 | 结果 |
|---|---|
| **V1** 纯函数四态 | `(0,1,1)=1 / (3,1,1)=4 / (3,1,0)=0 / (3,0,1)=3`——先断言输入互不相同（真差值前提） |
| **V2** 落盘往返 ★专打代价 1 | 置 S_prev=3 → 真调覆盖式 `set_codex_last_run`（**streak 键被抹——代价 1 实证断言**）→ `_write_codex_replay(3)` → `load_codex()` 读回 **4**；D=0 → **0**；oath 同次写回（T3 无撕裂） |
| **V3a/b/c** 旧档/坏档 | 无键 → 0；非数值 String → 0；**布尔 true → 0**（V3c 为 n4 变异靶点——无守卫 int(true)=1） |
| **V4** 渲染真差值 | 真调 `show_page("codex")` 扫描：streak 4→7 文本「连绩 · 4 局」→「连绩 · 7 局」**跟变** |
| **V5** H=0 不创建 | oath 空 → 连绩行不创建（走 show_page 清场+重建） |
| **V6** T1 用词区分 | 「连绩 · 」/「上局连绩 · 」新前缀；既有「本局誓约 / 上局誓约」两行一字不变 |
| **V7** 不变量 | I1/I2/I3 显式断言 |
| **n3** 数据级 | oath_streak 塞进 stats → 白名单静默丢弃（不改代码即证） |
| **n8** 哨兵常驻锁 | 无参直调不写 streak 键 |
| **变异测试 n1/n4/n8** | 三次 edit→run→revert 循环，各 **≥1 红**实证（见过程记录）——断言能证伪，非恒过绿灯 |
| 全量回归（22 钩子，6000 帧） | **0 报错**、11 done 标记 |
| E1 | 同 seed 指纹 md5 `3125e2b2…` 与 Sprint 13 起基线逐字同值（零重定） |
| E6 / 坑 5 | 零 raw delta / `ACTION_DEFS` `GEN_NAMES` 零新增 |
| 冻结双清单 | 本批快照 **34 OK / 0 FAILED**（game_main/menu/player 三条目重算）；历史归档勿覆盖（11 FAILED 预期） |
| **子代理交叉审查（S23 专项）** | 7 项全 PASS、无功能性新问题：实施契约逐项（快照时序/哨兵/读侧守卫/纯函数 f 零全局态）、零动清单全量 diff 核对（game_state/meta/data/validate 四文件 **0 行**、_oath_probe 函数体字节一致、_codex_boon_suffix 派生 key 无漂移、CODEX_KINDS 六类未扩）、T3 防撕裂（生产两写盘结构不变）、f 语义（H/D 取自本次刚写回 oath）、UI 双页（0 删除行实证）、探针 V1-V9+n3/n8 逐条验为真差值或验效果型（V2 走真盘往返、V4 真调 show_page 真差值 4→7）、bug 排查（无撕裂变体/无读盘/static 纯净/零 rng-delta/零数值回注）。**4 条发现**：①[低·口径] 「save_codex 新增调用数 0」全库字面 5→6（探针清场 1 处）→ 交付稿已限定为「生产脚本新增 0」；②[低·文档] 设计实稿两处字面与裁定冲突未加按语 → 已补按语（见实稿头部）；③[信息] 印记页连绩守卫缺 name!=""（行为等价）；④[信息] V1 前提断言 3/6 对（输出互异已使输入塌缩必红） |

## 过程如实记录

1. **n4 变异首跑 0 红——探针注入点错误**：坏值写在 codex 节顶层，`load_codex` 读的是 `codex/last_run` 键——坏值根本没到读函数，断言真空转。改为嵌进 `last_run` 字典后 n4 红（V3c 布尔靶点：无守卫 int(true)=1）。**教训：变异测试的红必须先证「注入真的到达了靶点」**。
2. **sigil_cov `scarce_ore 削减` 间歇假红（stash 实证归因）**：断言用相对比较（`diamond_mult < dm`）——多探针并发下 dm 可能已被其它灾祸路径削减到 ≤0.7 → `minf` 无操作 → 假红；同环境 stash 前后 0 红 vs 1 红实证非确定性。修：确定性基线（置 1.0 → 断言 <1.0 / 还原 ==1.0 → 还原现场）。
3. **SMOKE 下 `await process_frame` 早于 deferred 执行**（附限定①断言全量红/定向绿实录）——探针改直调生产冲洗入口（与 call_deferred 同函数，引擎保证 deferred 必然执行它）。**【Sprint 24 订正：本条降级登记——议题已冻结】**「时序不再依赖帧界」只对直调断言成立；deferred 调度路径的常驻回归锁经四处方案实测竞态不可消除（帧界 await / 回调存结果 / 回调体内原地断言 / 确定性直调），**登记为已知限制、不再追**——仅当出现真实玩家可见缺陷时重启（口径与 SPR22_交付.md 附限定收口批一致）。

## 还剩什么

- 待主理人读码核验 → Sprint 23 final PASS；Sprint 23 技术收敛批（3 条）维持不开批裁定
- P2（origin/main 推送，需一次性 PAT）留发布侧待指令
