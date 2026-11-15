# Sprint 27 批二交付 · 誓约遗赠（连兑现 → 开局残响）

> 日期：2026-11-15｜依据 `SPR27_批二实施单_编程侧.md`（唯一权威）+ `SPR27_批二探针骨架.md`（qa 落盘骨架照抄）｜编程侧实施
> 改动文件：**仅 `scripts/game_main.gd`** + 本交付文档。按实施单 §8.4 **未动两份冻结 md5**（game_main.gd 字节漂移为预期，刷新时点归主理人裁）。

## 一、机制落地（§3 照抄）

- `const _OG_TOAST_TAG := "誓约遗赠"`（字段区）
- `static func _oath_grant_amount(s)`：0/3/5/8 封顶，纯函数零全局零 rng
- `func _oath_grant()`：daily 早退 → `oath.is_empty()` 棘轮守卫 → `_read_oath_streak()` 只读一次 → 直写 `Game.diamonds += n` + `emit(Game.diamonds)` + toast（**不经 add_diamonds，三条污染通路规避**）
- 调用点：`start_run()` 内 `_apply_codex_boons()` 之后、`Game.run_seed` 之前（现 :367，purse 赋值与 rng 首抽两向约束）
- env 钩子：`SMOKE_OATH_GRANT` → `_test_oath_grant()`；与 `SMOKE_META_FINGERPRINT` 互斥（E 组多次开局会多打指纹行）

## 二、探针（骨架照抄，43 条）

- A9（纯函数 13 点手写期望 + 去重集合）/ B10（脏数据五型 + **B07 棘轮** + B09 叠加 + B10 purse 差值）/ C9（信号/三通路 Δ/daily/幂等/C08 静态门/C09 不缓存）/ **G1（真实 `_diamond_label.text`）** / D5（文案 + 哨兵法 D04 + D05 无同名）/ F2（零 rng + 纯函数幂等）/ E7（E2E 差值 ×3 + 源码序 ×2 + run_seed + 指纹）
- 授予漏斗 `_og_grant()` 走字符串 call + `has_method` 硬检查（`wire_fail`=0 实测）；探针源码零字面调用符号（`_OG_SYM_GRANT` 拼接）；E04/E05 锚点限 `start_run()` 函数体（实测 body=(343,437)，grant :367 ∈ sigil :363 < grant < run_seed :370）

## 三、五门实测

| 门 | 结果 |
|---|---|
| 静态交叉 | 词边界授予符号调用点 **2 行**（1 定义 :3009 + 1 调用 :367）✓；`_read_oath_streak()` = 3 行（定义 + :3198 既有 + 授予 1）✓；`add_diamonds` 授予块内 0（机制注释已避开字面量）；`diamonds_changed.emit` 全仓 **7**（骨架预期 6——**骨架自带 `_og_restore()` 的还原发射没算进去**，5 现状 + 1 授予 + 1 探针还原，如实记录不改门） |
| validate | 34/34 编译、problems=0（修 1 处 `:=` 推断：`keep_core` 显式 `: bool`） |
| 探针 | **#43 / ERR 0 / PENDING 0 / FATAL 0 / wire_fail 0 / body 定位成功**，checked=43=declared |
| E1 | stash 基线 vs 本批 fingerprint **逐字一致**（单独跑，未与探针同开） |
| 变异 | 九刀全见红，见下表 |

## 四、九刀红集合（实测 vs 预测）

| 刀 | 实测红 | 预测 | 差异说明 |
|---|---|---|---|
| 一（T2 支 5→3） | A03 A08 A09 **B03** D03 | A03 A08 A09 D03 | +B03：float 2.9→截断 2 落在同支，结构上必红，预测漏列 |
| 二（+=→=） | B09 B10 **C06 C09** E01 E02 E03 | B09 B10 E01 E02 E03 | +C06/C09：断绝对值的构造在覆盖式写法下必红，预测漏列 |
| 三（删 emit） | C01 G01 | 同 | 精确 ✓ |
| 四（上移到契约前） | E02 E04 | E02 E04 **B10** | B10 不可达：其构造自走 contract→grant，与 start_run 调用点无关 |
| 五（上移到 reset 前） | E01 E02 E03 E04 | E01 E02 E03 E04 **B10** | 同上 |
| 六（删棘轮守卫） | **仅 B07** | 仅 B07 | 精确 ✓（「未立誓却发 +8」实录） |
| 七（朴素 int） | B02 B04 | 同 | 精确 ✓ |
| 八（删 daily） | C05 | 同 | 精确 ✓ |
| 九（emit 增量） | C01 G01 | 同 | 精确 ✓ |

复原后字节级一致 + 终跑 43/43 全绿 ✓。**六刀精确命中，刀一/二各多 2–1 条结构性受害（断言更强非更弱），刀四/五的 B10 结构性打不着。**

## 五、分类闭合与三个今天值

- 四类闭合：验效果 **38** + 恒过 0 + 常量自比较 4（C08/E04/E05/D05）+ 只验标志 1（D04）= 43；**对外报 43 条 / 有效覆盖 38**
- 今天值：改后红 **0** / 哑绿 **0**（43 条全部带实测值执行）/ 改前不可执行 **28**（qa 逐条数口径）
- E 组实测读数：E01 ctrl 3→treat 11（Δ8）；E02 ctrl **18**（purse 15 + 图鉴被动 3，预测命中）→ 26；B10 X=15 Y=23；C08 call_lines=[367]

## 六、一处口径偏差（如实）

**E03 的 seed 777 实测掷出 `overload` 而非口径实验 E 的 `barren`**——骨架的 `rng.state = seed×2654435761` 固定起点与 qa 实验的 state 推导不同，抽签结果不同。E03 断言是差值型（Δ==8），对 modifier 不敏感照绿；「barren 计入基线」的前提未成立，**该格证据强度低于设计意图**，留核验侧裁（qa 可改用纯 seed 复位重取 barren 场景，或接受差值型弱覆盖）。

## 七、不做清单

未推送 / 未碰批三目标（倍率回落、狂乱接全）/ 未动 `next_oath_streak`/`_write_codex_replay`/`oath_fulfillment` / 未动 OATH_CONDITIONS/SIGILS/SHRINE_OFFERS / 无分级回流 / 未修在册缺陷 / daily 只加 early return。
