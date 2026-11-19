# SPR40 验证口径（不看代码实现就能判对错）

批次：Sprint 40
日期：2026-11-18
配套：`SPR40_设计实稿_武器族去火药枪化.md`、`SPR40_设计实稿_弹幕交互与盾反.md`、`SPR40_实施单_编程侧.md`
用法：每条给**可观测判据 ＋ 基准值 ＋ 边界态**。主理人独立核验时按编号复现，⛔ 采信编程侧自报数。

## 全局测量约定（🔴 违反任一条，本轮结论作废重跑）

| # | 约定 |
|---|---|
| M-1 | 采集环境：`SMOKE=1`、`SMOKE_SEED=<固定整数>`（**必钉**，不钉会有上百行假差异）、E1 指纹开关为 `SMOKE_META_FINGERPRINT=1`（不是 `SMOKE_META`）、保存类冒烟用 `--quit-after 3200` |
| M-2 | 帧/秒换算唯一口径：`帧数 = round(秒 / Game.FIXED_DT)`，`Game.FIXED_DT = 1/60 ≈ 16.667ms`。⇒ 6 帧＝100ms、8 帧≈133.3ms、10 帧≈166.7ms。**⛔ 用真实 delta 或 `Engine.time_scale` 折算**（冒烟下 time_scale=2.0，实测喂进 `_physics_process` 的 delta≈0.03333，拿它折窗口会腰斩） |
| M-3 | churn 只比断言行；原始日志里 `[SMOKE-NAV]/[SMOKE-CAM]/[SMOKE-E]/[SMOKE-LOOP]/[SMOKE-STALL]` 与时间戳属实时抖动，**不比对这些行** |
| M-4 | 汇总计数⛔ 用 `awk -F:` 配绝对路径（盘符冒号切错字段，恒得 0） |
| M-5 | 探针的 oracle **不得与生产实现共用同一个变量/同一份内联条件**（判据与实现同账＝变异刀会把判据一起删掉而仍绿）。允许共用的只有 §V-S1 那个显式声明的单一真源函数 |
| M-6 | 文档中一切行号均为易腐引用；核验时以句子为准，行号现场 `grep -n` 坐实后才算数 |

---

## 一、A 组 · 近战清扫漂浮弹幕

### V-S1 分类判据（单一真源）

| 项 | 内容 |
|---|---|
| 判据 | 对任意敌弹 `b`：`b.is_sweepable() == true` ⟺ `not b.friendly` 且 `pierce==0 ∧ explosive==0.0 ∧ bounce==0 ∧ frost==0.0 ∧ homing==false ∧ arc==0 ∧ cluster==0` |
| 基准值 | **现存全部敌弹（由 `spawn_enemy_bullet()` 生成的三处调用）100% 可清扫**——上线当天「能扫掉一切敌弹」是预期基线，不是 bug |
| 正例 | 用 `spawn_enemy_bullet(pos, dir, 130.0, 1, tint)` 造的弹 → `is_sweepable()==true` |
| 反例（必须逐个构造，缺一个不算覆盖） | ①`explosive>0` 的友方/敌方弹；②`pierce>0`；③`bounce>0`；④`frost>0`；⑤`homing=true`；⑥`arc>0`；⑦`cluster>0`；⑧`friendly==true` 的全零弹（玩家的弹）→ 八个都必须 `false` |
| 边界 | 已 `queue_free()` 但未出树的弹：⛔ 被二次计数（`is_instance_valid` 挡住） |
| 反向刀 | 把判据里的 `not friendly` 删掉 → 必须有至少一条断言红（否则说明这条判据根本没被检验） |

### V-S2 几何一致性

| 项 | 内容 |
|---|---|
| 判据 | 清扫扇区 == 本次挥击的伤害扇区：半径 == DEFS 的 `reach`，半角 == `arc_deg/2`，中心向 == `_aim` |
| 基准值 | 以 `sh_bulwark` 为例：`reach=34`、`arc_deg=150` ⇒ 半角 75°；`ml_cleaver`：`reach=46`、`arc_deg=110` ⇒ 半角 55°。**两把武器的清扫范围必须不同**（相同即说明有人写死了常数） |
| 角度环绕 | 在 ±180° 交界处放置一颗弹（玩家朝东、弹在西偏北 1°）：⛔ 被判为扇内（验 `angle_difference` 而非裸减法） |
| 距离边界 | 恰在 `reach` 上的弹：给出明确结论并在口径里登记（建议含等号），两组各测一次防漂移 |
| 一致性 | 「打得到怪」与「扫得到弹」用同一套几何 ⇒ 若某颗弹与某只怪同位同距，一次挥击应同时生效（⛔ 扫到弹就不打怪的互斥实现） |

### V-S3 rng 守恒（本组最重要的一条）

| 项 | 内容 |
|---|---|
| 判据① | 一次「清扫 N 颗弹」的操作前后，`Game.rng.seed` 与 `Game.rng.state` **逐字不变**（N∈{0,1,5,20} 各测一次） |
| 判据② | `Player.melee_rng_draws == Player.melee_swings` 全程成立（既有计数器，无需新增） |
| 判据③ | 整段冒烟（M-1 环境）的 `[SMOKE-META] fingerprint` 与改前**逐字不漂移** |
| 反证设计 | 在命中分支里加一次 `Game.rng.randf()`（变异刀）→ 判据①/②必须红；把抽取改成「有弹才抽」→ 判据②必须红 |
| 表现层随机 | 若用了 `Game.fx_rng`：确认其播种来自 `hash("spr8_fx:%d" % run_seed)`，同 seed 两次运行迸星参数完全一致 |

### V-S4 计数与配额

| 项 | 内容 |
|---|---|
| 判据 | `bullets_swept` 增量 == 探针独立遍历统计的「本拍进入扇区且 `is_sweepable()`」的弹数；`last_sweep_count` == 最近一次挥击的该值 |
| 空挥 | 扇区内无弹：`melee_swings += 1`、`bullets_swept += 0`（⛔ 空挥不计数＝抽取次数会变） |
| 过载早退 | `mag()<=0 且 not skill_active()` 那一拍：`bullets_swept` 增量必须为 0（⛔ 白嫖清场） |
| 过载中 | `skill_active()` 为真时照常清理（与近战伤害同权） |
| autopilot | E3 路径（autopilot）与手动路径的清扫结果一致 |
| 多弹同拍 | 同帧 5 颗进扇区 → 增量恰为 5（⛔ 每帧上限、⛔ 只清最近一颗） |

### V-S5 不与既有系统串味

| 项 | 内容 |
|---|---|
| 环盾 | 环盾遗物激活期间的清弹计入 `orb_shield` 那条既有路径，⛔ 同时增加 `bullets_swept`（两套计数各自独立、无双计） |
| 词缀 | 近战清弹触发的 `ON_SHIELD_BREAK` 次数必须为 **0**（霜爆/回响那两条挂在环盾上的词缀⛔ 被近战白嫖） |
| 敌弹存量 | 清扫后 `get_tree().get_nodes_in_group("enemy_bullets")` 中被清的那些不再出现（队列残留不计） |

---

## 二、B 组 · 四把基础法器

### V-W1 数值守恒（改名不改骨）

| 项 | 内容 |
|---|---|
| 判据 | 四条新条目（`zhushan/liechi/guanglei/fushe`）的 `dmg/interval/count/spread/speed/mag/reload/pierce/life/explosive/tint` 十一项，与 B0-b 快照里对应旧条目**逐字段相等** |
| 映射 | `rifle→zhushan`、`shotgun→liechi`、`railgun→guanglei`、`launcher→fushe`（顺序即槽位：直射/扇形/穿透/爆炸） |
| 允许变化 | 仅 `name`、`desc`、`icon` 三个键 ＋ DEFS 的键名本身 |
| 基准值举例 | `liechi.count==5 ∧ liechi.spread==22.0 ∧ liechi.life==0.40`；`guanglei.speed==430.0 ∧ guanglei.pierce==3`；`fushe.explosive==1.0 ∧ fushe.speed==180.0` |
| 反向刀 | 借改名偷调任一数值 → 本条必须红 |

### V-W2 表层无火药语汇

| 项 | 内容 |
|---|---|
| 判据 | 以下玩家可见文本中⛔ 出现「枪／弹／炮／膛」四字：`Weapons.DEFS[*].name/desc`、`Data.SIGILS[*].desc`、`Data.RELIC_SUFFIXES[*].desc` 与其对应的 `data.gd` 文案表条目 |
| 例外登记 | `mw_cluster` 的「集束榴弹」（`meta.gd:68`）**已知违规、本批豁免**（待裁 D4）；`bomb` 相关「炸弹」措辞本批不清理（待裁 D5） |
| 具体两处 | `SIGILS.arsenal.desc` == `"开局副手预装裂髓杵"`；`s_frostveil` 文案末句 == `"先齐射再补一发"` |
| 机检形式 | 字符串扫描 + 白名单（白名单必须显式列出上面两项豁免并注明「主理人裁定豁免，非实现缺陷」） |

### V-W3 可用集闭合（MG-PW1）

| 项 | 内容 |
|---|---|
| 判据 | 新基线下 MG-PW1 报 `missing=[] extra=[]`；`_meta_usable("weapon")` 计数与改前**相等** |
| 🔴 程序性约束 | 基线串变更**只能由主理人重新登记**。编程侧交付里必须包含「拟改后的集合内容原样」＋「我未自行宣布基线更新」两句；若发现有人就地改串让它变绿，本轮验收直接退回 |
| 语义提醒 | 这一路过滤的是**整张 DEFS**（无 gate 节点＝默认可用），而抽卡/货架走 `Weapons.random_unlocked()` 只过滤 `DROP_POOL` —— 两个池不同源，⛔ 把它们当同一个池写断言 |

### V-W4 回退链完整

| 项 | 内容 |
|---|---|
| 判据 | 传入未知 id（如 `"__nope__"`）时：`player.give_weapon()`、`Weapons.icon()`、`Weapons.random_unlocked()`（清空 DROP_POOL 情形）三处均回退到 **`zhushan`**，且 `Dev.err` 文案点名「回退朱砂笔」 |
| 冒烟 | 全仓 `grep -n '"rifle"' scripts/*.gd` 结果为 **0 命中**（B 组甲案完成后） |
| 探针自身 | D4 反向那条探针（原 `_ml_equip("rifle", 30)`）改用新 id 后仍产出与改前**同型的断言结果**（装备成功、淬毒钩子生效） |

### V-W5 图标合规

| 项 | 内容 |
|---|---|
| IHDR | 四枚新 PNG 逐字段核：宽 32、高 16、位深 8、色彩类型 RGBA（6）、纯透明底（存在 alpha=0 像素且背景全透）、⛔ 抗锯齿过渡色阶（相邻非同类像素间不允许出现第 3 种插值色） |
| 色数 | 索引色 ≤10（含透明），对齐十色基准表 |
| 注册 | 四个键 ∈ `assets.gd GEN_NAMES`；`DEFS[*].icon` 三向门通过（`icon` 在 `GEN_NAMES` 内 ∧ `Assets.g(icon) != null`） |
| 剪影互异 | 四张图的**不透明像素包围盒**与**质心 x 位置**不得两两全等（防止画成四个一样的横条） |
| 旧件 | `wpn_rifle/wpn_shotgun/wpn_railgun/wpn_launcher` 文件仍在盘上、md5 未变（⛔ 删除/覆盖） |

---

## 三、C 组 · 盾（RAISE/BLOCK/stun）

### V-P1 窗口结构

| 项 | 内容 |
|---|---|
| 判据 | RAISE 为真 ⟺ 当前武器 `kind=="shieldbash"` ∧ `_stance_t > 0`；⛔ 存在第二套并行窗口计时变量（源码级检查：新增的 `_parry_t`/`_block_t` 之类若与 `_stance_t` 语义重叠即打回） |
| 基准值 | `sh_bulwark.interval=0.90`、attack 动画 0.3333 ⇒ 窗口长度由 interval 主导（≈0.90s ≈ **54 物理帧**，按 M-2 换算） |
| 递减方式 | 窗口每拍减 `Game.FIXED_DT`（源码级：该行不存在 raw `delta`） |
| 输入顺序 | 新的 RAISE/BLOCK 扫描位于 `_update_aim_and_fire` 之后；四个输入更新的相对顺序未变 |

### V-P2 stun 语义

| 项 | 内容 |
|---|---|
| 判据① | `apply_stun(dur)` 后：AI 主动位移为 0，但 `_knock` 衰减继续（受击退不受冻结） |
| 判据② | Boss（`variant=="boss"`）调用 `apply_stun` 后 `_stun_t` 保持 0 且无任何行为变化 |
| 判据③ | stun 期间 `apply_slow` 的计时**不推进**；stun 结束后 slow 从原剩余值继续（对比：无 stun 的同场景 slow 正常走完） |
| 判据④ | stun ⛔ 改变受伤量：同一发子弹打在「被 stun 的怪」与「未被 stun 的怪」上，掉血逐字相等 |
| 签名 | `slug.take_damage(amount, from_dir, crit)` 三参签名未变；`_melee_pierce_armor` 旁路标志的置位/清零区间未扩大 |

### V-P3 BLOCK 结算（PARRY 未开工，此节只验两层）

| 项 | 内容 |
|---|---|
| 判据 | 硬格：受伤 == `round(原 dmg × BLOCK_MULT)`（BLOCK_MULT 若是占位常量，报告必须点名）；未格：受伤与改前逐字相等 |
| 优先级 | `relic_shield_t > 0` 且处于 RAISE：该弹记为「环盾摧毁」，`block_count` 与环盾销毁数**不得同时增长** |
| 分类计数 | `parry_count` / `block_count` / `shield_absorbed_dmg` 三者独立可读；未开 PARRY 时 `parry_count` 恒为 0（⛔ 把硬格混记成盾反） |
| 边界 | 同一颗弹⛔ 既触发 BLOCK 又触发近战清扫（清扫排在 `_swing()` 内、BLOCK 排在 incoming 命中时，两者时序不同但同一颗弹不能被吃掉两次） |

### V-P4（预留）返还表

PARRY 开工时本节启用，届时至少要求：
1. 每一类 `T_*` 各自的盾反次数单独可断言（⛔ 只有一个总数）；
2. 返还弹的 `dmg == DEFS[模板].dmg × RETURN_MULT`（模板从表里现读，⛔ 硬编码）；
3. 整次盾反前后 `Game.rng.state` 逐字不变（返还弹一律 `crit=false`）；
4. `T_LASER`/`T_ORBIT` 类攻击盾反尝试 → 计数为 0 且不报错。

---

## 四、通用回归门（每组都要跑）

| # | 门 | 通过条件 |
|---|---|---|
| G-a | validate | `problems=0` |
| G-b | 每个探针 | `done checked=N declared=N` |
| G-c | 错误行 | `[ERR]` 计数 == 0；`ok=false` 计数 == 0 |
| G-d | E1 指纹 | `SMOKE_META_FINGERPRINT=1` 下逐字不漂移（B 组甲案是唯一被授权可能引起武器池漂移的一档，须附主理人登记凭据） |
| G-e | churn | 只比断言行、`SMOKE_SEED` 已钉；新增断言行逐条列明 |
| G-f | 变异刀 | A 组 ≥4 把（删 `not friendly`／把清扫挪到抽取之前／给清扫加主流抽取／把清扫挪到早退 return 之前）；B 组 ≥3 把（漏改一处回退／漏改 `GEN_NAMES`／偷调一个数值）；C 组 ≥3 把（Boss 免疫去掉／stun 影响受伤／双计环盾与盾反）。每把都要贴出「预期的那条红」 |
