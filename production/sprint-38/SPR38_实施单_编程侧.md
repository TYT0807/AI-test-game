# SPR38 实施单 · 编程侧 —— **状态：PARTIAL（B1 解闸；S36-T-B1 已单独解闸；B2/B3 挂闸）**

批次：Sprint 38
撰写：主理人，2026-11-18
配套：`SPR38_设计实稿_非弹幕武器形态族.md`（「实稿」）、`SPR38_验证口径.md`（「口径」）、`SPR38_S36处置结论_T-B1.md`（「处置令」）
⛔ 本批不写 `production/sprint-36/`、`production/sprint-37/` 任何文件。
🔴 **T-B1 相关条目在处置令之前一律 HOLD** —— 处置令已发出且结论是「解闸复工」，故 S36 的 T-B1–B3/T-C 按 `SPR36_实施单_编程侧.md` 原样执行，本单不再重复其内容，只列 S38 自己的活。

## 0'. 本轮唯一要你先回话的一件事 —— 🔴 **R3：已关闭，无需再回**

~~P-Q2：`W.png` attack 行那 4 格到底是 4 个不同姿态还是同一张复制件？~~ ⇒ **已由实测判定＝复制件**（四格 opaque 全等 366、bbox 全等 (6,28,6,30)、内容等同；其余行都是真多帧）。连同 P-Q1（S37 实稿 §4.5 归属声明）一起，**两个口径答案都齐了**，条目状态见 §B2 表。

🔴 **现在的分工变成这样**：**P0（窗口守卫）随 B1 立即做**；**P2（补帧）转待办 T-P1**，因为换玩家图集撞 AGENTS §9.3 那条硬指标 ⇒ 须作者一裁，⛔ 编程侧自行改图。另新增一处**只登记不动手**的既有缺陷 T-P2（rifle `interval 0.30s < 动画 0.333s`），见 §B2 的 P4。
其余条目（T-K/T-M/T-N/T-O）照旧开工，不必等任何东西。

---

## 0. 开工闸

| 闸 | 条件 | 状态 |
|---|---|---|
| G1 | S36 的 T-B1–B3 ＋ T-C **先落定**（串行合入，见处置令 §5）。S38-B1 从 S36 落定后的工作树起算基线 | 🟡 等 S36 |
| G2 | 起点自检留档：`git log --oneline -1`、`git status --short`、`md5sum -c production/sprint-21/SPR21-FROZEN.md5`（本会话实测 **6 FAILED**：`data.gd` `game_main.gd` `game_state.gd` `meta.gd` `shrine_panel.gd` `validate.gd`；`weapons/player/bullet.gd` OK）。⛔ 不要为了绿去刷清单 | 每次开工跑 |
| G3 | 🔴 **行号纪律**：本单所有指针以**函数名＋句子**为准。行号是本会话实测、会腐烂，落地前重新 `grep -n` | 硬性 |

---

## 1. 硬前置（🔴 顺序依赖，违反即返工）

| # | 前置 | 为什么硬 |
|---|---|---|
| HP-1 | **E1 守恒先行**：`melee_rng_draws` / `melee_swings` 两个计数器与 `_smoke_rngcount_probe()` 的近战接线，必须在任何近战攻击逻辑能被触发之前落地 | 口径 V-E1/E8；后补计数器＝测不到早期分支 |
| HP-2 | 🔴 **每一次有效非弹幕攻击动作恒消费恰 1 次 `Game.rng.randf()`**，且不随命中数、敌人生死、autopilot、灾祸、主题、暴击结果变化 | 实稿 §3.1。弹幕侧今天每发恒抽 1 次（`player.gd:_fire()` 内 `var crit := Game.rng.randf() < crit_chance`），非弹幕若零抽取 ⇒ 整局随机流位移 ⇒ 指纹与冻结串全漂。**这是物理事实不是口味** |
| HP-3 | ⛔ 三种规避写法一律拒收：①在 `start_run` 一次性补偿抽取；②改抽 `fx_rng`；③「没打中就不抽」 | 实稿 §3.1 禁三条 |
| HP-4 | 命中结算**复用** `slug.gd:take_damage(amount, from_dir, crit)`，`from_dir` 必须是玩家指向敌人的单位向量 | 正面甲（armor）靠它，口径 V-B6；⛔ 不许新开伤害接口、不许传 `Vector2.ZERO` |
| HP-5 | ⛔ 不新增 `ACTION_DEFS` 动作（现 18）；⛔ 不新增 `bullet.gd setup()` 行为位参位；⛔ 不改 `DROP_POOL`；⛔ 不改 `_shrine_theme_pref()` 的 `[up,down]` 返回结构；⛔ 不动 `CALAMITY_SHRINE_DOWN` 四种灾祸映射 | AGENTS §4 红线；S36 禁改条款延续 |
| HP-6 | 🔴 近战在 B1 **不得有任何获取途径**（DEFS 有条目、商店/掉落/圣所都不指向它）——**但解禁条件是口径 V-G2（B2a 窗口守卫）绿，不是等美术帧**。V-G2b（帧内容是否为复制件）作为独立靶挂着，不阻塞投放 | 没有窗口的近战＝作者批评的「摇一摇」。有窗口＋待定的帧内容是「可以先交付的状态」 |
| HP-7 | 所有计时/冷却/持续效果一律 `Game.FIXED_DT`（E6）。豁免只有两条，不许顺手统一 | AGENTS §4.1 |
| HP-8 | hash key 只能用既有范式 `"%d_%d_%d" % [Game.run_seed, Game.floor_num, coord.x*1000+coord.y]` ＋ `"%s#%d"` 后缀式；⛔ 不得引入 SC1 禁的四个字面模式（`c#`／`#p2`／`#1c`／`#p2c`）——SC1 扫的是**全仓所有 .gd**，新加的文件也算 | 口径 V-F2；踩了当场红 |

---

## 2. 任务条目

### T-K｜机检卫生（第一批，不等任何东西）

| # | 缺陷 | 证据（函数名锚点） | 处置 |
|---|---|---|---|
| K1 | GUARD-1 改造版探针只遍历 DEFS 中带 `homing`/`arc`/`cluster` 任一键的条目 ⇒ 对**无这三键的新 kind 条目静默跳过**，是新增假绿面 | `game_main.gd:_meta_apply_test()` 内那段 `for wid in Weapons.DEFS:` ＋ `if not d.has("homing") and not d.has("arc") and not d.has("cluster"): continue` | 改为按 `kind` 分派的两段覆盖：projectile 类继续验行为位传递；非 projectile 类验「扇形几何参数齐全且为正」＋「rng 计数守恒」。⛔ 不许删旧断言凑数 |
| K2 | MG-PW1 可用集基线串会在 6 把新 id 进 DEFS 时涌入 pool 视图 | `game_main.gd:META_WEAPON_POOL_BASELINE` 上方注释已预告此事 | 🟢 **由主理人在核验时给新串**，⛔ 编程侧不自改串迁就实现 |
| K3 | `_smoke_rngcount_probe()` 目前只覆盖三个抽卡入口，看不到攻击动作的抽取 | `game_main.gd:_smoke_rngcount_probe()`，env `SMOKE_META_RNGCOUNT` | 扩一路近战入口，输出追加 `melee=<n>`；两档（默认/全解锁）逐字相同 |
| K4 | `player.gd` 里散布那次 `randf_range(-1.5,1.5)` 是分支相关的（仅 `n==1 and not autopilot`）——既有坏范式，容易被照抄进近战 | `player.gd:_fire()` 内 `if n == 1 and not autopilot:` | 本批**不改它**（改了动现有随机流），但实稿 §3.1 已写明近战不得沿用；K1 的新断言要能抓住「近战照抄了这个条件」的实现 |

### T-M｜形态判别基础设施（B1 第一步）

| 步 | 文件 | 动作 | 约束 |
|---|---|---|---|
| M1 | `scripts/weapons.gd`（`DEFS`） | 给**全部**条目补 `"kind"` 字段：现有 7 把一律 `"projectile"`，新增 6 把按实稿 §3.8 表 | 🔴 一次性补齐全部，⛔ 不许只给新条目加（否则老代码读 `get("kind")` 与新代码读 `["kind"]` 会分叉） |
| M2 | `scripts/weapons.gd` | 新增只读常量 `MELEE_FIELDS := ["dmg","interval","reach","arc_deg","mag","reload"]`，供校验与分派共用 | ⛔ 不许把字段名散写在 if 里 |
| M3 | `scripts/validate.gd` | 增静态门：每条 DEFS 的 `kind` ∈ 允许集合；非 projectile 条目必须 `MELEE_FIELDS` 齐全且 `reach>0`、`arc_deg ∈ (0,180]`、`interval>0`、`mag>=1` | 口径 V-A1/A3 |
| M4 | `scripts/assets.gd` | 6 枚新图标 `wpn_ml_*`/`wpn_sp_*`/`wpn_sh_*`/`wpn_th_*`/`wpn_wd_*` 登记 `GEN_NAMES`；PNG 走 `_tools/spr25_art_gen.py` 范式程序化绘制，**16×16 RGBA8**、十色索引、纯透明底、硬边 | ⛔ ComfyUI 产物直接入库；漏 `GEN_NAMES` = 静默白框（GUARD-2 门会咬） |

### T-N｜非弹幕命中内核（B1 核心，最难的一块）

| 步 | 文件 | 动作 | 约束 |
|---|---|---|---|
| N1 | `scripts/player.gd` | 新增 `func _swing() -> void`（近战/长兵/盾共用的结算入口）。位置紧邻 `_fire()`，保持两者可读性对称 | 🔴 内部第一件事就是 `var crit := Game.rng.randf() < crit_chance` —— **无条件、无分支**（HP-2） |
| N2 | `scripts/player.gd` | `_update_aim_and_fire(delta)` 内在闸门之后按 `cur_def()["kind"]` 分派：projectile/throw/wand → `_fire()`；melee/spear/shieldbash → `_swing()` | ⛔ 不改四个输入更新的调用顺序（`_update_anim`→`_update_aim_and_fire`→`_update_bomb_input`→`_update_skill_input`→`_update_relic_input`）；同帧竞争裁定依赖它。若你们的工作树上顺序不同，**停下来报告，不要自己调** |
| N3 | `scripts/player.gd` | 扇形扫描：遍历 `enemies` 组，跳过 `not is_instance_valid(e) or e.dead`，判 `distance_to <= reach` 且 `abs(angle_difference(dir_to_e.angle(), _aim.angle())) <= deg_to_rad(arc_deg)/2` | ⛔ 不用 Area2D、不加碰撞层（口径 V-A2 与 HP-5）；用 `angle_difference` 避免 ±180° 环绕错 |
| N4 | `scripts/player.gd` | 逐个 `e.take_damage(dmg_final, (e.global_position - global_position).normalized(), crit)` | HP-4；V-B6 |
| N5 | `scripts/player.gd` | `dmg_final = dmg * damage_mult * bullet_dmg_mult * (2.0 if crit else 1.0)`；⛔ 不吃 `bullet_scale` | 口径 V-D1 |
| N6 | `scripts/player.gd` | 暴击且 `crit_boom` ⇒ `Game.main.explode(hit_pos, 42.0, dmg_final * 0.6, false)`，半径与系数逐字对齐 `bullet.gd:_handle_hit()` 里那条既有实现 | 口径 V-D3；单一真源 |
| N7 | `scripts/player.gd` | 架式配额：复用 `slot_mags` / `_reload_t` / `_start_reload()` 那套既有机制，语义换成「连续命中配额→过载」。⛔ 新建第二套配额字段 | 口径 V-C1/C2；U 项让 `mag_cap_mult` 自动生效（V-C3） |
| N8 | `scripts/player.gd` | `shieldbash` 额外一条：命中后 `e.apply_slow(0.6, 1.2)` | V-B5；⛔ 不加击退（`apply_blast_push` 与 dash 区间纠缠） |
| N9 | `scripts/player.gd` | `spear` 无视护甲：**本帧局部旁路**标志（结算内置位、结算后立即清零），⛔ 不改 `slug.gd:take_damage()` 签名、⛔ 不写进任何持久字段 | V-B7 的边界态专门抓跨帧泄漏 |
| N10 | `scripts/player.gd` | 计数器：`static var melee_swings := 0`、`static var melee_rng_draws := 0`，N1 内各自 +1（无效输入/过载期不增 swings） | V-E1/E5 |

### T-O｜数据投放（B1 只做数据，不做获取途径）

| 步 | 动作 | 约束 |
|---|---|---|
| O1 | 6 条新 DEFS 数值按实稿 §3.2–§3.6 基准值表填 | 🔴 HP-6：⛔ 不进 `DROP_POOL`、不进 `SHRINE_OFFERS`、不被任何 `drop_pickup(...,"weapon",...)` 指向 |
| O2 | 显示名与卡片描述行走原创命名表（实稿 §3.8） | ⛔ 他作专名（元气骑士／重生细胞的角色、图标样式、徽章排版）一律不得出现 |
| O3 | 卡片描述里的 `kind` 措辞：近战写「贴身/架式」语系，⛔ 不许出现「弹匣」「弹药」字样 | 表层文案与机制层分界 |

### T-P｜外观与过程帧 —— **[部分解闸：P0 立即做；P1/P2 挂 S37 实例的口径回答]**

🔴 **先把依赖的形状说清楚**（实稿 §4 B2 已按 R3 改写，别照旧理解去等 S37 交货）：S37 那份规格的权威表只覆盖**怪物族与道具族**，明文「本批最小闭环 = walk + die」⇒ **S37 不会给玩家产出新挥砍帧**。而它交回的另一个答案更硬：**现役玩家图集的 attack 行 4 格是同一张复制件**（实稿 §2b Q1）。⇒ B2 的两个口径答案**都已关闭**，现在不是"等答案"，而是"B2a 立即做、B2b 转待办 T-P1"。

⚠️ **两处指针作废（R3）**：本节旧版写的 `W.png` 在现役正典里不存在（只活在 `_backup/spr18_p1/…`、`_backup/spr19_p1/…`）。真名＝**`resources/texture/shardbearer.png`**（IHDR 160×288 ＝ 5 列 × 9 行 @32px；`assets.gd:4 T_SHARDBEARER`、`:39-46` 行号常量、`:224` attack 注册句）。落地前重新 `grep -n` 坐实。

| 步 | 动作 | 前置 |
|---|---|---|
| **P0** 🟢 | `_update_anim()` 加架式窗口守卫：`_swing()` 置位的窗口内不得把 `animation` 从 `"attack"` 切到 walk/idle。**纯代码、零美术**，做完立刻能看出「挥出去了」 | 🟢 **不挂任何东西，可随 B1 一起做**。这是本轮对原计划的修正——不要把它扣在 S37 上 |
| ~~P-Q1~~ ✅ | ~~向主理人报告：S37 逐帧差异家规是否适用于玩家图集 attack 行？~~ ⇒ **已裁**（S37 实稿 §4.5）：**家规 G1/G2/G3/G5 适用、M1–M11 机检靶不适用**（该图血缘不同：直绘产物、色板非十色基准表字面值、alpha 值域含 64）。⇒ 近战补帧本批自管，走程序化＋同一张基准色表 | ✅ 关闭，⛔ 再问一次 |
| ~~P-Q2~~ ✅ | ~~现有 attack 行那 4 格是真姿态还是复制件？~~ ⇒ 🔴 **实测＝复制件**：四格 opaque 全等 **366**、bbox 全等 **(6,28,6,30)**、内容等同；对照组证明其余行都是真多帧（`walk_down` 327/319/327/316、`idle` 2 格不同、`die` 322→169→85→16 严格递减）。⇒ **P2 确实存在**，但改图须作者一裁 ⇒ 转待办 T-P1 | ✅ 关闭（主理人已独立复算） |
| P1 ⛔ HOLD | 近战动画的命中对齐：到位帧与 N1 的命中时刻同物理帧（±1 帧） | 🔴 等 **T-P1**（补帧）落地才有"到位帧"可言；今天四格同一张 ⇒ 对齐判据不可证伪 |
| P2 ⛔ → 📝 **转待办 T-P1** | attack 行确为复制件 ⇒ 需按 S37 家规（G1 相邻帧只差 1–2px 程序化位移／G3 全局一张基准色表／G5 ≤32px ⛔ 扩散出帧）**程序化补帧**，不新造图集形态 | 🔴 **不在本批**：换这张图集＝推翻 AGENTS §9.3「⛔ `shardbearer.png` 本批不换图」那条硬指标 ⇒ **方向级变更，须作者裁**。⚠️ 一并要裁：该图 alpha 含 64，补帧时整行统一二值还是写明豁免 |
| P3 | 反证刀：删掉 P0 守卫 ⇒ 「移动中挥砍播满 attack」必须变红 | 随 P0 |
| 现状提示 🔴 **R3 改写** | `assets.gd:w_frames()` 注册的 `"attack"` 有 4 格但**内容是同一张复制件**（12fps、非循环）。真正的两处成因：**①`_update_anim()` 移动即切回 walk**（那句守卫 `not (sprite.animation == "attack" and sprite.is_playing())` 只在动画还在播时挡住切换）；**②`interval` 短于动画时长**：rifle `interval=0.30s` < 4 帧 ÷12fps = **0.333s** ⇒ 每轮刚播完就被 `if sprite.animation == "attack" and not sprite.is_playing(): sprite.play("idle")` 切回 idle，而**换动画名＝复位到 0**（Q4 实测②），下一发再 idle→attack 又从 0 起 ⇒ 永远从头挥。<br>⛔ **不要写"删掉重复 `sprite.play("attack")`"**：Q4 实测①证明**播放中同名重调并不复位**（frame 与 progress 都保持），删了没有任何观感效果。那个显式 `sprite.frame = 0` 只作用在 walk 分支上，⛔ 归因到 attack。 | — |
| P4 🆕（登记，不在本批做） | 弹幕侧 rifle 那一处属**既有外观缺陷**（实稿 §4 B2c／待办 T-P2）。两条修法各有代价：提 `interval` ⇒ 撞 S36 §7.2 死值反超 DPS 口径；给 attack 单独定 fps（≥14fps）⇒ 便宜但在 T-P1 之前不可证伪。⛔ 编程侧自行择路，等主理人随 T-P1 一起裁 | 📝 排 T-P1 之后 |

### T-Q｜获取途径与投放（B3）—— **[HOLD：等 B1+B2 全绿]**

| 步 | 动作 | 约束 |
|---|---|---|
| Q1 | 定向投放：特定房型清场后按 `stable_hash` 选一把本族武器，直调 `drop_pickup(..., "weapon", 1, id)` | 🔴 零 `Game.rng` 消费；key 范式见 HP-8；⛔ 不许经过 `_random_weapon()` |
| Q2 | ⛔ 商店货架与大宝箱两条通路一行不改 | S36 补偿条款延续；V-F3 |
| Q3 | 解禁后补一条断言：近战可用集 ≠ 空 ⇔ B2 已绿 | 防「机制露怯」 |

---

## 3. 禁止事项（汇总，逐条可判红）

1. ⛔ 新增 `ACTION_DEFS` 动作（现 18）。
2. ⛔ 新增 `bullet.gd setup()` 行为位参位（现 7 行为位）。
3. ⛔ 改 `DROP_POOL`、`SHRINE_OFFERS`、`_shrine_theme_pref()` 的 `[up,down]` 结构、`CALAMITY_SHRINE_DOWN`。
4. ⛔ 非弹幕攻击零抽取 / 少抽取 / 分支相关抽取 / 抽 `fx_rng` 顶替。
5. ⛔ 为近战另造一套 AoE 实体或新伤害接口（复用 `explode` 与 `take_damage`）。
6. ⛔ 做主动格挡/招架（与 `orb_shield` 环盾重叠）。
7. ⛔ 做品质倍率（与 S36 §7 死值反超口径冲突，须另批同裁）。
8. ⛔ 扩武器槽到三槽（W4=A 延续，实稿 §3.5）。
9. ⛔ 引入全局倍率载体（`enemy_hp_mult`/`damage_mult`/`abyss_*`）；污染 `_smoke_abyss_check` 基准。
10. ⛔ 用 raw `delta` 做新增计时（E6；豁免只有 `player.gd:_tick_buffs()` 与敌方毒云两处）。
11. ⛔ 扩散模型产物直接入库当图标/精灵。
12. ⛔ 挪用《元气骑士》《重生细胞》的任何专名、角色、图标样式、徽章式排版 —— 只借类别法与双槽法这两种**结构**。
13. ⛔ 在 B1 阶段给近战开任何获取途径（HP-6）。
14. ⛔ 就地修改 `META_WEAPON_POOL_BASELINE` 或任何冻结串迁就实现（基线变更由主理人重新登记）。
15. ⛔ 自刷 `SPR21-FROZEN.md5`、commit、push。
16. ⛔ 发现断言在当前数据下恒真却不标注性质；⛔ 改断言迁就实现。
17. ⛔ 把主理人已裁条目（X1–X7）拿去问作者；口径疑问只找主理人。

---

## 4. 必跑门控与环境变量

见 `SPR38_验证口径.md` V-H 的四组命令块，逐字照跑。补充两条本批特别要求：

- 🔴 **改动前后各跑一遍 E1 三档指纹**，逐字贴 `[SMOKE-META] fingerprint` 行。漂移 ⇒ 先查近战抽取次数，⛔ 不许重定基线掩盖。
- 🔴 V-E8 两把变异刀（删抽取 / 改成抽 2 次）都要贴「改坏→红、还原→绿」原文。变不红即 INCOMPLETE。

---

## 5. 交付回报格式（给主理人独立核验用）

编程侧自报须含：

1. 改动文件清单 ＋ **每个文件的函数名**（⛔ 只给行号）；
2. 七件套**实测数**（逐条原文粘贴关键行）；
3. E1 三档指纹改动前后逐字对照；
4. `melee_swings` / `melee_rng_draws` 在至少 3 种摆位（0 敌 / 1 敌 / 5 敌）下的实测值；
5. `_smoke_rngcount_probe()` 新输出行原文（含 `melee=`）；
6. V-B6/B7 的 armor 数学实测（盾骑士正面对峙：阔刃实得 vs 荆刺实得）；
7. V-B7 的跨帧泄漏反证（spear 结算后紧接一发普通子弹是否仍减伤）；
8. V-C3 灾祸配额实测（`scarce_ammo` 下阔刃配额）；
9. 变异刀四把的结果（K1 新断言、V-E8 两把、V-G2 一把 —— P3 在 B2 才跑）；
10. `md5sum -c production/sprint-21/SPR21-FROZEN.md5` 原样输出。

主理人将**不看自报数**独立复现：自己 `grep -n` 坐实、自己跑门禁、自己算 V-B/V-C/V-D 的数学。

---

## 6. 当前效力边界

- **立即开工**：T-K（K1–K4，纯机检卫生）＋ **T-P 的 P0（架式窗口守卫，纯代码零美术）**。
- **G1 满足后开工**：T-M → T-N → T-O（B1 主线，串行）。
- **HOLD**：T-P 的 P1/P2（等 P-Q1/P-Q2 两个盘上/口径答案）、T-Q（等 B1+B2a 全绿）。
- **不在本单**：S36 的 T-B1–B3/T-C —— 见 `SPR38_S36处置结论_T-B1.md`，结论是**解闸复工**，按 S36 原单执行。

---

## 7. R14 转交两条（主理人 2026-11-18 裁，来源 `SPR38_主理人核验_R14_R29回归自证与两条口径.md`）

> 这两条**不是新机制**，是工具面／文档面的口径卫生。裁定已下，编程侧只落地，⛔ 再问作者。

### T-R14a｜README E1 句补「两问两答」（🔴 唯一动 `README.md` 的授权来源＝本条）

- 改哪：`README.md:54` 那一行「E1 确定性校验方法」。
- 改成什么：现文只答了「同 seed 只比 `[SMOKE-META] fingerprint` 行」这半句，须补上完整口径——
  ①**漂移问**＝每档指纹逐字等于 `production/sprint-32/SPR32_验证口径.md` §5.4 **它自己那一行**（机检 `spr38_fp_vs_5_4.py`）；
  ②**种子生效问**＝三档互不相同（distinct=3）。并明写 ⛔ 断言「三档彼此逐字相等」。
- 🔴 权威文本已在 `AGENTS.md` §3 判据 5 落档（主理人本轮执笔），**照那句同步 README，⛔ 自己另拟措辞**（两处不一致＝下一轮口径腐化）。
- 验收：改后 `grep -n "§5.4\|distinct" README.md` 命中该句；`md5sum README.md` 现读值写进回报（R13 登记旧值 `b54c27aae58f454ab7a7f13df2896295`，变了要如实报新值）。

### T-R14b｜取证件命名纪律落到链入口件

- 改哪：`_tools/spr38_run.sh` **顶部注释块**（`:2-5` 那段「为什么要有这件」之后；⛔ 改逻辑、⛔ 改任何退出码路径）。
- 加一句：凡整份引用链终端行的自证／测试副本，文件名必须含 `CHAIN_EXCLUDE` 之一（`verify`/`selftest`/`audit`/`falsify`/`mnow`/`md5all`），否则会被 `spr38_r8_verify.py:latest_chain()` 按 mtime 当成盘上最新链原件 → 面5 假红。处置只有 `mv`，⛔ 删除证据件。
- 🔴 **禁止事项**：⛔ 为这条改 `spr38_r8_verify.py` 或 `spr38_evidence_verify.py`（均在 PROTECT；前者现读 `9657d5fb60b3340d1422aafa87256a0c`、后者 `40fa822212bf8c75f94165f7f85b55e4`）。B 面名单滞后由**责任窗**收口，编程侧只做披露。
- 📌 配套披露口径（即刻生效，无需等落地）：五面件里 `only_a=1` 连同那个件名一起当**已知滞后**如实报，⛔ 为了让 selcmp 凑 `only_*=0` 去碰 B 面文件。
- 附带两件小订正（同一批内顺路做，均 append-only）：
  1. `_tools/_r29_falsify_*` 现读 **12 份**（listing 与 A47-9 写的 11 份漏了汇总件 `_r29_falsify_run2.txt`）⇒ 台账**新节**注一行，⛔ 回改 A47／R29 续流水行（HP-11）。
  2. `spr38_r29_extract.py` 的 mk 件消费面：七态里 3 态（`checked≠declared`／一刀变钝／判定串命中 2）是 **rc=0 ＋ `CHAIN-CLEAN=no`** 抓的，⛔ 只读 `MISSING` 判「有没有抓到」⇒ mk 件同时读 `chain_clean`。
  3. 引用指纹串一律引 `_tools/spr38_g_fp{seed}.log` 原始行，⛔ 引 `_r29_gist.json` 的 `fp[].line`（被 `spr38_gates.sh:51` 的 `cut -c1-92` 截断，`fp777`/`fp42` 尾巴缺字）。
