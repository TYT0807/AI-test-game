# Sprint 21 主理人读码核验报告

- 核验人：主理人（游承峰）
- 日期：2026-11-11
- 范围：Sprint 21（C · 深渊难度档）全部 8 个 `.gd` 改动，**未 commit**
- 结论：**附限定 PASS**（QA 首轮 FAIL 的阻断项已清零；2 项附限定如实登记）
- HEAD 仍为 `dc15efe`；工作树含 8 个 `.gd` 修改 + `production/sprint-21/` 新增

## 〇、本批角色边界变更（须记录）

长期铁律是「主理人不写 `.gd`」。本批因 eng 通道与修复 agent 接连撞 **429 频率限制**，用户明确授权「**代码也需要你了**」，故主理人临时放宽边界，**亲自落地 `slug.gd` 两处与 `game_main.gd` 探针重写**。其余代码仍由 eng 通道产出。本记录不改变后续批次的默认边界。

## 一、核验方法

- 全量 `grep -n abyss` 定位 8 文件所有落点 → 逐点 `Read` 实读上下文（不轻信 agent 自报行号）。
- **修复后重新 grep 贴输出**：因探针扩充约 55 行，`game_main.gd` 后续函数行号整体漂移（复位 `:551-553 → :607-609`、boss 解锁 `:1159-1162 → :1216-1218`），本报告全部行号取**最终态实读值**。
- 独立重跑四门控与冻结对账，不复用 agent 的日志结论。

## 二、逐条实读对照

| 契约主张 | 实读证据（最终态） | 判定 |
|---|---|---|
| 三隔离乘子，不复用会被 clobber 的既有变量 | `game_main.gd:94-97` 新增 `abyss_hp_mult`/`abyss_speed_mult`/`abyss_dmg_mult`/`abyss_tier`；`enemy_hp_mult`/`enemy_speed_mult` 仍在 rage / pressure 被 `=`/`maxf` 覆盖，`abyss_*` 全文仅出现在定义、start_run、复位、探针四处 | ✅ |
| `start_run` 确定性乘定、零 rng | `:368-377`，位于 `_roll_modifier()` 之后；只做表查 + 赋值，无 `Game.rng`/`fx_rng` | ✅ |
| hp / speed 注入生效 | `slug.gd:86` `* Game.main.abyss_hp_mult`、`:90` `* Game.main.abyss_speed_mult` | ✅ |
| **dmg 无双重计数** | `slug.gd:93-95` `dmg = int(_cfg["dmg"])`（基准）；`player.gd:1758` 是唯一缩放点，位于守卫后、`sigil_ward`(`:1760`) / 护盾(`:1765`) 之前，二者独立 | ✅ 修复后 |
| 探针 SCRIPT ERROR 清零 | `slug.gd:103/106` `if sprite:` 空守卫；生产 `sprite` 恒非 null，行为零变化 | ✅ |
| dmg 断言为验效果型 | `game_main.gd:476-502` 真调 `player.take_damage(10,...)` 并断言受创 == `round(10×abyss_dmg_mult)`；`:505-516` 完整还原玩家状态、`_oath_counters`、`_room_damaged`；`:520-523` 还原运行配置 | ✅ 修复后 |
| meta 平行只读、不碰冻结规格 | `game_state.gd:80`/`:710`/`:791-792`；`save_meta()` 遍历 `meta.keys()` 自动持久化；两键未进 `:753-754` missing 告警列表 | ✅ |
| 阶梯解锁门控 | `menu.gd:926` `mini(ABYSS_MAX_TIER, best_tier + 1)`；未解锁按钮 `:166 disabled`；`abyss_tier` 是运行时 var，每局随节点重建归 0，无旧档残留高 tier 隐患 | ✅ |
| HUD 常驻标签、不用 banner | `hud.gd:514-520` 独立 Label、`:614-621` `set_abyss_tier()` 带 null 守卫 | ✅ |
| `validate._check_abyss` 非真空 | `validate.gd:55` 在 `run()` 内派发；`:295-327` 校验尺寸/键连续/乘子有限且>0/单调非减；`prev_speed`/`prev_dmg` 在 `:326-327` **确实更新**，单调性门有效 | ✅ |
| 解锁仅真·终 Boss 层 | `game_main.gd:1216-1218`，`if _is_third_floor(Game.floor_num)` 守卫 | ✅ |
| 红线零触碰 | `ACTION_DEFS` 18 / `CODEX_KINDS` 六类 / `FLAVOR` / `FLOOR_THEMES` 8 / `CODEX_BOONS` 四档；34 个 `.gd` 不变 | ✅ |

## 三、对 QA FAIL 的裁定

QA 的 **FAIL 判定正确且必要**，拦截了一个真实的数值缺陷。根因**在主理人契约**：我把 dmg 乘子同时写进了敌人属性与受创入口，与 design-s16 §6.3「dmg 只在唯一入口缩放」的原意冲突，实施方照契约实现并无偏差。

三处修复的实测证据：

| 证据 | 数值 |
|---|---|
| t3 dmg 动态验伤 | `taken=12 expect=12`（10×1.21），若双重计数应为 14.64→15 |
| t10 dmg 动态验伤 | `taken=17 expect=17`（10×1.70），若双重计数应为 28.9→29 |
| t1/t5 | 11 / 14，全部单次缩放 |
| SCRIPT ERROR | 全档位 **0**（修复前 t≥1 各 1 条） |

## 四、四门控独立复核

| 门 | 结果 |
|---|---|
| G1 | `SMOKE=1 SMOKE_SEED=12345 --quit-after 6000`：EXIT=0、报错 0、39 条 `t=` 行 |
| G2 | 同 seed 777 默认 vs `SMOKE_ABYSS=3`：`[SMOKE-META] fingerprint` **IDENTICAL**；`SMOKE_DAILY` 0 次 |
| G3 | `git diff` 新增 `Game.rng`/`fx_rng`/raw `delta` = **0 行** |
| G4 | t=0/1/3/5/10 全 0 报错，三乘子与两处注入断言全命中；t=11 越界按预期 1 条 `[ERR]`（负向对照，不包装成多条红） |
| 冻结 | 本批快照 `SPR21-FROZEN.md5` **34 OK / 0 FAILED**；历史 Sprint 7 清单 **26 OK / 8 FAILED**（8 = 改动集，其余 26 逐字节未变），保持归档不覆盖 |
| CRLF | 8 个 CRLF、26 个 LF、无单文件内部混排；`data.gd` 曾漂成 LF 已复原，复原后 diff 仍 `+18/-0`、短跑 0 报错 |

## 五、附限定项（非阻断）

1. **Boss HP 不随深渊缩放**：三位 Boss 走 `PrismWarden` 自有 `max_hp` 公式，不走 `slug.gd setup()`，历史上亦未接 `enemy_hp_mult`。Boss 接触伤害经 `take_damage` 正常单次缩放，但 HP 不缩放 → abyss 档下 Boss 相对偏易。属设计措辞与实现结构的偏差，**非本批新回归**；补注入点列为后续候选，本批不擅自扩范围。
2. `SMOKE_ABYSS` 探针会短暂改写玩家状态后完整还原；仅 SMOKE 路径，生产不进此函数。
3. 引擎退出时 `ObjectDB leaked / resources still in use` 为历史各批同款噪声，非游戏报错。

## 六、结论

**附限定 PASS。** 阻断项（dmg 双重计数 + 探针虚假通过 + 探针 SCRIPT ERROR）已全部清零并经独立实跑证明；E1 指纹零重定、E6 零 raw delta、冻结 34/34、红线零触碰。附限定 2 项已如实登记，不隐瞒。

**尚未 commit**，提交须用户显式授权。
