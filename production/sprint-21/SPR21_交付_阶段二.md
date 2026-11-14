# Sprint 21 交付 · 阶段二（探针 / 门控 / QA / 修复）

- 日期：2026-11-11
- 环境：`godot.windows.opt.tools.64.exe --headless --path d:/Create/Game/test-1`
- 结论：QA 首轮 **FAIL（阻断）** → 修复后**四门控全过**，结论**附限定 PASS**（见 `../SPR21_主理人读码核验.md`）

## 一、QA 首轮抓出的阻断项（根因在规划契约）

独立交叉核验 `general-purpose-2` 判定 **FAIL**，核心缺陷：

- 主理人实施契约误把 `abyss_dmg_mult` 同时写进 **(a)** `slug.gd` 的敌人 `dmg` 属性 与 **(b)** `player.take_damage()` 的受创入口。
- slug 接触伤害走 `Slug.dmg → take_damage_from → take_damage`，被乘两遍 = `base × abyss²`；而敌弹（基准 `ai_bullet_dmg`）与 Boss 接触（基准 `boss.dmg`）只在 `take_damage` 乘一遍。同一档位下三路伤害不一致，违反「三乘子不双重计数」红线。
- **G4 的 dmg 断言是虚假通过**：探针只静态比对 `abyss_dmg_mult` 这个变量值是否等于表值，从未真正施加一次伤害；且 headless 默认 `player._immortal = true`（`game_main.gd:202`），`take_damage` 在守卫处直接 `return`，缩放分支根本没执行过。

> 归因诚实记录：这是**主理人契约写错**，不是实施方的实现偏差。design-s16 §6.3 原意本就是 dmg 只在受创入口缩放。

## 二、修复三项（主理人亲自落地）

| # | 改动 | 效果 |
|---|---|---|
| 1 | `slug.gd:93-95` 回退 `dmg = int(_cfg["dmg"])`，补注释说明单一入口 | 消除 `base × abyss²`；`slug.gd:86/90` 的 hp / speed 缩放保持不变 |
| 2 | `slug.gd:103/106` 给 `sprite.self_modulate` 加 `if sprite:` 空守卫 | 探针构造未入树 Slug 时不再抛 SCRIPT ERROR；生产环境 `sprite` 恒非 null，行为零变化 |
| 3 | `game_main.gd:429-523` 探针重写 | 补 **dmg 动态验伤**（真实施加一次伤害）、还原探针副作用、还原运行配置 |

### dmg 动态验伤的正确性设计

探针在 `t>=1` 时：临时抬高 `player.hp`（避开濒死/死亡分支）、关闭 `_immortal` / `sigil_ward` / `shield_charges` / `_invuln_t` / `has_kinetic`（制造纯净单一入口语境），施加 `test_dmg = 10`，断言 `受创 == round(10 × abyss_dmg_mult)`。随后**完整还原** `hp` / `_immortal` / `sigil_ward` / `shield_charges` / `_invuln_t` / `has_kinetic` / `_knock` / `sprite.modulate` / `hp_changed` 信号，以及被 `damaged` 信号连带置位的 `_room_damaged` 与 `oath_count("hits_taken")` 计数。末尾还原 `abyss_tier` 与三乘子，使探针**零整局副作用**（修 QA D-2）。

## 三、四门控实测（修复后）

| 门 | 命令 / 口径 | 结果 |
|---|---|---|
| **G1** | `SMOKE=1 SMOKE_SEED=12345 --quit-after 6000` | EXIT=0；`[ERR]` / SCRIPT ERROR / Parse Error = **0**；39 条 `[SMOKE] t=` 行（6000/150）。退出时 `ObjectDB leaked / resources still in use` 为引擎级拆除噪声，历史各批同款 |
| **G2** | 同 seed 777，`SMOKE_META_FINGERPRINT=1`，默认 vs `SMOKE_ABYSS=3` | `[SMOKE-META] fingerprint` 行**逐字 IDENTICAL**；`SMOKE_DAILY` 出现 0 次 |
| **G3** | `git diff -- scripts/ \| grep '^+' \| grep -iE 'Game\.rng\|fx_rng\|delta'` | **0 行** |
| **G4** | `SMOKE_ABYSS=0/1/3/5/10/11` | 见下表 |
| **冻结** | `md5sum scripts/*.gd` 重算 + 本批快照对账 | 34 个 `.gd`；`SPR21-FROZEN.md5` **34 OK / 0 FAILED** |

### G4 全档位对照

| tier | `max_hp`（baseline 6） | dmg 动态验伤（base 10） | 报错 |
|---|---|---|---|
| 0 | —（`mults=1.0 ok`） | —（前提守卫型恒过） | 0 |
| 1 | 7（×1.10） | taken 11 = expect 11（×1.07） | 0 |
| 3 | 8（×1.30） | taken 12 = expect 12（×1.21） | 0 |
| 5 | 9（×1.50） | taken 14 = expect 14（×1.35） | 0 |
| 10 | 12（×2.00） | taken 17 = expect 17（×1.70） | 0 |
| 11（越界负向对照） | — | — | 1 条 `[ERR] abyss: SMOKE_ABYSS 越界 t=11`，**预期行为** |

**关键证据**：t10 的 dmg 是 17 而非 `10×1.70²≈29`，证明双重计数已消除；`taken == expect` 全部命中，证明 dmg 断言已升级为真正的**验效果型**。所有档 `validate` 启动自检 `problems=0`。

### 断言分类（如实标注）

| 断言 | 分类 |
|---|---|
| `start_run` 三乘子 == 表值 | 验效果型（证明接线） |
| `Slug.max_hp == round(baseline × abyss_hp_mult)` | 验效果型（证明 hp 注入） |
| `player.take_damage` 受创 == `round(base × abyss_dmg_mult)` | 验效果型（证明 dmg 唯一入口） |
| t=0 三乘子全 1.0 | **前提守卫型恒过** |
| player 不可用时跳过动态验伤的分支 | **前提守卫型**，打印说明 |
| t=11 越界 `Dev.err` | 负向对照，预期报错，不包装成多条红 |

## 四、冻结双口径（避免误读）

- **历史归档** `production/sprint-7/SPR7-FROZEN-4.md5`：当前对账 **26 OK / 8 FAILED**。8 个 FAILED 恰好等于本批改动集，反而证明其余 26 个 `.gd` 逐字节零触碰。**该清单保持归档，不覆盖**。
- **本批终态快照** `production/sprint-21/SPR21-FROZEN.md5`：34 行，`md5sum -c` = **34 OK / 0 FAILED**。
- 清单是**工作树字节快照**，不是仓库归一化字节；CRLF 分布实测 **8 个**（`assets` / `bullet` / `data` / `prop` / `secret_wall` / `slug` / `upgrade_panel` / `upgrades`）、26 个 LF、**单文件内部无混排**，与基线一致。

> 过程中发现 `data.gd` 曾被整文件转成 LF（CRLF 掉到 7 个）。已复原为 CRLF，复原后 `git diff --numstat` 仍为 `+18/-0`，短跑 0 报错，基线恢复。

## 五、附限定项（非阻断，诚实披露）

1. **Boss HP 不随深渊档缩放**。三位 Boss（`boss.gd` / `boss2.gd` / `boss3.gd`）均 `extends PrismWarden`，不走 `slug.gd setup()`，其 `max_hp` 用自有公式，历史上也从未接 `enemy_hp_mult`。故 abyss 档下 Boss **接触伤害**经 `take_damage` 正常单次缩放，但 **HP 不缩放**，Boss 相对偏易。这是设计实稿「覆盖 Boss」措辞与实现结构的偏差，**非本批新引入的回归**。若产品要求 Boss HP 也随档缩放，需另补注入点（列为后续候选，本批不擅自扩范围）。
2. `SMOKE_ABYSS` 探针会短暂改写玩家状态再还原；headless 探针专用，生产路径不进此函数。
3. 全量日志尾部的 `ObjectDB leaked / resources still in use` 为引擎退出噪声，不计入游戏报错。

## 六、状态

- 8 个 `.gd` 修改 + `production/sprint-21/` 新增文档与快照，**未 commit**。
- 提交 message 建议：`Sprint 21 深渊难度档：隔离乘子 + 阶梯解锁 + 菜单/HUD/validate 门 + SMOKE_ABYSS 动态验伤探针 + 冻结 34/34`。
- **提交须用户显式授权。**

## 七、收口批补记（主理人任务单 P0 · Boss HP 深渊缩放）

> 日期：2026-11-11｜编程侧收口批，单独 commit。上节「未 commit / 须授权」状态已过期——S21 主体已于 `2ca0440` 入库。

- **缺陷**：三 Boss `setup()` 的 `max_hp` 公式（boss.gd:73 / boss2.gd:28 / boss3.gd:32）未折入深渊乘子——普通敌人自 S21 起吃 `abyss_hp_mult`，Boss 不吃 → 高深渊档下 Boss 反而相对变脆。
- **修复**：三处公式末尾折入 `* Game.main.abyss_hp_mult`（镜像 slug.gd:86 消费语义）。**红线遵守**：只接 abyss，不接 `enemy_hp_mult`（会动 E1 基线）；纯乘算零 rng。血条无需另改（`boss_hp_changed.emit` 在 `_ready()`，晚于 `setup()`，自动拿到缩放值）。
- **SMOKE_ABYSS 验效果型断言**（player.gd）：真构造三 Boss 实例读 `max_hp`——基线（abyss=1.0 且 enemy_hp_mult=5.0 时 max_hp 仍为公式原值，证明 enemy_hp_mult 未被消费）+ 真差值（abyss=1.1 → 三 Boss ×1.1）+ 订正批补档位（t=1 hp=1.10 / t=10 hp=2.00，读 `ABYSS_TIERS` 实表数值对照）。
- **验证**：SMOKE_ABYSS 定向 0 [ERR]；全量 21 钩子 6000 帧 0 报错（10 done 含 SMOKE-ABYSS）。
- **冻结双清单口径（主理人核验订正，替代本行旧表述「冻结重定 34/34（四条目重算）」）**：
  - **本批快照** `production/sprint-21/SPR21-FROZEN.md5`：每批重算，收口批后 `md5sum -c` = **34 OK / 0 FAILED**
  - **历史归档** `production/sprint-7/SPR7-FROZEN-4.md5`：已按订正单还原为 `457b38c` 字节态并**永久保持勿覆盖**——对当前工作树 `md5sum -c` = 23 OK / 11 FAILED（4 个为本批真内容变更，7 个为工作树 CRLF↔LF 行尾翻转：`core.autocrlf` 下 git diff 不可见、md5 可见——slug.gd 三哈希实证：blob `d9f447ee` / 归档 `e02b98d5` / 现工作树 `acba7808`）。归档是历史基线证据，不要求对当前树全绿
- **G2/G3 证据（订正批补录）**：G2 指纹同 seed（`SMOKE_SEED=12345`，禁 SMOKE_DAILY）`[SMOKE-META] fingerprint` 行 md5 = `3125e2b2…`（与 Sprint 13 起基线逐字同值）；G3 收口批 diff `grep '^+' | grep -iE 'Game\.rng|fx_rng|delta'` = **0 行**
- **附限定①就此关闭**，质量门 CONCERNS 依据消除。P2（origin/main 推送，需 PAT）仍属发布侧待用户指令。
