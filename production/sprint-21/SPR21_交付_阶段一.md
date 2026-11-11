# Sprint 21 交付 · 阶段一（实施）

- 日期：2026-11-11
- 方向：**C · 深渊难度档**（`SPR21_规划草案.md` / `SPR21_设计实稿.md`）
- 状态：实施完成，四门控通过；**尚未 commit**（提交待用户显式授权）
- 改动规模：8 个 `.gd`，`+266 / -7`，纯加性；`scripts/*.gd` 仍 34 个

## 一、方向与设计裁定

依项目自身诊断「Mechanics 过饱和、Dynamics 贫乏，优先系统间关系」选 C：**只加「难度与进程的关系」，不加任何机制 / 实体 / 资源 / 输入动作**。通关后解锁深渊档，以纯乘算因子叠加既有敌人数值，形成「再打一次冲更高档」的长线目标。

用户拍板两项：

| 决策 | 结果 |
|---|---|
| 档位选择门控 | **阶梯解锁**：`0..min(ABYSS_MAX_TIER, abyss_best_tier + 1)`，永远只比当前手艺高一档 |
| 难度曲线 | **采纳 design 默认**：N=10，`hp=1+0.10t` / `speed=1+0.05t` / `dmg=1+0.07t`，t10 = 2.00 / 1.50 / 1.70 |

### 主理人两项技术裁定

1. **三乘子，非四乘子**：design-s16 指出「敌人 damage」与「玩家受创」是同一物理事件，若各乘一遍即双重计数。锁定 `hp` / `speed` / `dmg` 三个乘子，`dmg` 只在 `player.take_damage()` 唯一入口缩放，覆盖接触 / 敌弹 / Boss / AoE。
2. **隔离乘子，不复用 `enemy_hp_mult`/`enemy_speed_mult`**：实读发现二者会被运行时**直接赋值覆盖**（`game_main.gd` rage 减益、pressure 主题的 `maxf`，以及 game_state 的共鸣/减速 tween）。复用乘入会被 clobber 导致难度静默失效。故新增三个**隔离**全局 `abyss_hp_mult` / `abyss_speed_mult` / `abyss_dmg_mult`，与既有变量完全脱钩。

> 事实更正：项目无 `enemy.gd`，敌人类是 `Slug`（`scripts/slug.gd`），普通/Boss/精英共用、靠 `variant` 区分；乘算注入点锁定 `slug.gd` 的 `setup()` 算术链。

## 二、逐文件落地（行号为修复后实读）

| 文件 | 行号 | 内容 |
|---|---|---|
| `data.gd` | `:467-480` | `ABYSS_MAX_TIER := 10` + `ABYSS_TIERS` 常量表（tier 1..10，每档 hp/speed/dmg） |
| `game_main.gd` | `:94-97` | 三隔离乘子 + `abyss_tier := 0` |
| `game_main.gd` | `:368-377` | `start_run` 在 `_roll_modifier()` 之后**确定性乘定**选定档位，并刷 HUD 标签；零 rng |
| `game_main.gd` | `:607-609` | `_roll_modifier()` 复位块内防御性复位三乘子 |
| `game_main.gd` | `:1216-1218` | `_room_cleared` boss 分支，仅 `_is_third_floor()` 为真时置 `abyss_unlocked` / 记 `abyss_best_tier` |
| `game_main.gd` | `:418`、`:429-523` | `SMOKE_ABYSS` 探针门与探针本体（见阶段二） |
| `slug.gd` | `:86`、`:90` | `max_hp` / `speed` 算术链末尾折入 `abyss_hp_mult` / `abyss_speed_mult` |
| `slug.gd` | `:93-95` | **`dmg` 保持基准**（修复 QA 阻断项，见阶段二） |
| `slug.gd` | `:103`、`:106` | 染色的 `if sprite:` 空守卫（修探针 SCRIPT ERROR，生产零行为变化） |
| `player.gd` | `:1756-1758` | `take_damage` 在守卫后、`sigil_ward` 前折入 `abyss_dmg_mult`，带 null 守卫 |
| `game_state.gd` | `:80`、`:710`、`:791-792` | meta 字典 / `_default_meta` / `_read_meta` 的 `abyss_unlocked` / `abyss_best_tier` 平行键；不进 `missing` 告警列表 |
| `menu.gd` | `:154-166`、`:377`、`:908-934` | 右栏「深渊档」按钮（未解锁 disabled）+ `abyss` 页（阶梯门控） |
| `hud.gd` | `:62`、`:514-520`、`:614-621` | 常驻只读 `_abyss_tier_label` + `set_abyss_tier()`；不用 `banner()` |
| `validate.gd` | `:55`、`:295-327` | `_check_abyss()` 启动期门：尺寸/键连续/乘子有限且>0/跨档单调非减 |

**meta 落盘**：两键是 `Game.meta` 字典的平行只读键，`save_meta()` 遍历 `meta.keys()` 自动持久化；**未**碰 `meta.gd UNLOCKS` 与 `Meta.STATS_KEYS`（冻结规格 v2.10）。

## 三、红线自检

| 红线 | 结论 |
|---|---|
| `ACTION_DEFS` 18 条 / `CODEX_KINDS` 六类 / `FLAVOR` / `FLOOR_THEMES` 8 / `CODEX_BOONS` 四档 | 全部零触碰 |
| E1 零新增 rng 消费、零顺序变化 | 乘子在 `start_run` 确定性乘定；`git diff` 新增 `Game.rng`/`fx_rng` = 0 行 |
| E6 走 `FIXED_DT`、零 raw `delta` | `git diff` 新增 raw `delta` = 0 行 |
| 零新增实体 / 资源 / 输入动作 | 34 个 `.gd` 不变 |

## 四、协作过程说明（如实记录）

- 实施由 eng 通道 `general-purpose-1` 完成；独立交叉核验由 `general-purpose-2` 完成，其结论为 **FAIL**，抓出 dmg 双重计数与探针虚假通过（见阶段二）。
- 修复派单 `general-purpose-3` 与 `eng-handoff` 均因 **429 频率限制**中断；用户在此时授权「代码也需要你了」，**主理人角色边界临时放宽，亲自落地后续 `.gd` 修复**。`general-purpose-3` 在中断前已完成 `slug.gd:93-95` 的 dmg 回退，其余两处由主理人补齐。
- 本批全程**未 commit**；提交须用户显式授权。
