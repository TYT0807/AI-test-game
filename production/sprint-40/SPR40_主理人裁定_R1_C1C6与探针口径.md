# SPR40 主理人裁定_R1 · C1~C6 数值口径 ＋ A 组探针三问 ＋ 台账通道

批次：Sprint 40
日期：2026-11-18（作者同日三条裁定转录见 §0）
性质：**裁定件**（新文件，⛔ 重写实施单／验证口径原文；对旧件的逐行订正列 §5）
配套：`SPR40_实施单_编程侧.md`、`SPR40_验证口径.md`、`SPR40_设计实稿_弹幕交互与盾反.md`、`SPR40_特色创新候选清单.md`
本件零 Godot 进程、零锁文件、零 `.gd` 写盘。§7 的机检全部**请编程侧跑**。

---

## 0. 作者 2026-11-18 三条裁定的转录（照录，⛔ 引申）

| # | 作者裁定 | 我的处置 |
|---|---|---|
| D2′ | **武器 id 与显示名一起换**（甲案获批）：`rifle/shotgun/railgun/launcher → zhushan/liechi/guanglei/fushe`；牵动 `META_WEAPON_POOL_BASELINE` 的那一次**冻结基线重登归作者**，串只能逐字转录，编程侧不自刷 | B1~B11 闸门解除，按实施单 §2 执行；基线串「拟改后集合内容原样」交回我登记 |
| J1′ | **K3《借一刀》先行试点 ＋ K1《留痕》作正签** | S40-c 落地 PARRY 后开 K3 单批；K1 单独一批（独立通道纪律照候选清单 §1 K1） |
| — | **GitHub 当仓库**：备份／主题分支可自主 push；`main`、发版、tag 逐次授权；⛔ force push、⛔ 改写已推送历史、⛔ 推没绿门禁的提交（AGENTS §12） | 工程面，不进任何设计判据；每次 push 前把「推了什么、几个 commit、门禁哪条绿」写进交付报告（§12 原文要求） |

---

## 1. (a) C1~C6 —— 逐条裁定

### C1 完美窗口 `W_parry`：**12 物理帧 = 0.20s**（自裁，终局）

外部经验（只取机制结论，来源见文末）：
- 《只狼》默认弹开判定窗＝**12 帧 @60fps ≈ 0.2s**，且普遍解读为「比传统魂系更宽容」（[fextralife Deflection](https://sekiroshadowsdietwice.wiki.fextralife.com/Deflection)、[Arqade](https://gaming.stackexchange.com/questions/387925/how-precise-is-the-deflect-mechanic-in-sekiro)）。
- 《重生细胞》盾反：点按约 **0.3~0.4s**、按住只有 **0.2s**，空反后约 **0.6s** 内不能再格挡（[Dead Cells Wiki Shields](https://deadcells.fandom.com/wiki/Shields)、[Reddit parry window](https://www.reddit.com/r/deadcells/comments/mbgv5b/parrying_any_reason_not_to_hold_button_down/)）。

裁定理由：本项目是**顶视角弹幕游戏**，同屏 incoming 颗数远高于以上两款动作游戏，玩家注意力在走位上，完美窗应当比它们更宽而不是更窄；但返还表的经济收益（免伤＋反击）又要求它不能白给。**取 12 帧＝0.20s 起步**（恰好落在两家参照的下沿，对我们的高密度场景反而是宽容档），手感若需放宽走「返工常数」不走「加机制」。

施工口径（🔴 逐字）：
```
const PARRY_FRAMES := 12                    # ⛔ 写成秒的浮点常量
var _parry_frames_left := 0                 # 实例整型，⛔ 持久化、⛔ 进 E1 指纹串
# _stance_open() 之后紧接一行：_parry_frames_left = PARRY_FRAMES
# 每个 _physics_process 拍（⛔ raw delta、⛔ Engine.time_scale、⛔ create_timer）：
#   if _parry_frames_left > 0: _parry_frames_left -= 1
RAISE  ⟺ kind=="shieldbash" ∧ _stance_t > 0.0        # 完全照实施单 C2，共用 _stance_t
PARRY  ⟺ RAISE ∧ _parry_frames_left > 0              # 起手即开窗（弹幕实稿 §3.1 口径不变）
BLOCK  ⟺ RAISE ∧ not PARRY
```
- 🔴 `_parry_frames_left` 是**派生态不是第二套窗口计时**：它从 `_stance_open()` 那一拍起算、由同一个入口置位，V-P1 禁的是「另立一个 `_parry_t/_block_t` 浮点秒表与 `_stance_t` 并行衰减」，这条整数计数器不构成 V-P1 违规——但它**必须只在 RAISE 成立期间被读取**（RAISE 一假，PARRY/BLOCK 同时假，⛔ 出现「架式已关、完美窗还开着」的双账）。
- 换算校验照 M-2：`round(0.20 / (1/60)) == 12` ✅。冒烟 `time_scale=2.0` 下这 12 帧对应真实时间减半，属预期，⛔ 拿真实秒时断言。
- 已知粗糙处（起手即开窗 vs 延迟开窗）如实保留：这是弹幕实稿 §3.1 末那条 ⚠ 的既定口径，先实现最可证伪的版本，手感问题等 S40-c 有真日志再议。

### C2 环形弹幕撞同一窗口：**一颗弹一次处理 + 冷却闸**（自裁）

裁定：**不采「窗口内全吃」**（那等于范围无敌帧，与 `T_RING` 的设计压力相悖），也**不采裸「一次窗口只吃一颗」**（那会出现「窗口明明开着，第二颗穿过来打脸」这种读不懂的失败）。落法：

1. 每颗敌弹各自结算：命中瞬间查 RAISE/PARRY/BLOCK（优先级照弹幕实稿 §3.2 步骤 3，环盾豁免在最前）。
2. 成功盾反后设 `PARRY_HIT_CD := 6` 物理帧（0.10s）——CD 内的后续弹走 **BLOCK**（有 RAISE 就硬格减伤），CD 外走正常受伤。
3. BLOCK 同样吃这颗 CD：一次成功处理后的 6 帧内不再进入第二次 BLOCK 结算（防「八向环一次性把伤害 ×BLOCK_MULT 连乘八次＝变相全免」）。
4. 分类计数逐颗各记各的（`parry_count`/`block_count` 按实际发生的次数增长，⛔ 合并成「本次举盾共处理 N 颗」这种总数）。

这一档等价于「窗口能吃到第一颗、按 6 帧节奏继续吃」，压力保留、无双无敌帧。数值本身（6 帧）是我裁的实现常数，若实测手感不对，回来找我改常数，⛔ 自行调。

### C3 眩晕词缀（双向 stun）：**不做**（方向级，作者未点名 ⇒ 我按最小主张裁）

作者原话只说「还可以造成眩晕类型」，主语是玩家对敌人。双向 stun 牵动 `player.take_damage` 的控制锁定与输入层禁用，成本明显更高且未被点名 ⇒ **本批单向（玩家晕敌人）**。将来要做双向是新批次新裁定，⛔ 顺手实现。

### C4 近身撞击拼刀（`T_MELEE` 盾反）：**本批不做**，登记为 K3《借一刀》的正典母体

超出作者原话的那处推演，按最小主张否掉——但**否得有去处**：《借一刀》（作者已选定的招牌）的题材形态正是「挡下那只怪的一记横扫之后，你手上这半秒变成它的武器」，拼刀才是它的原生载体。⇒ `T_MELEE` 接触攻击今天维持「不可盾反、不可清扫、正常受伤、UI 不给提示」，与 `T_ORBIT`/`T_LASER` 同档；待 S40-c 的 PARRY 落地后，拼刀随 K3 一并立项。**这不是永久否决，是排期裁定。**

### C5 代价载体：**独立帧计数**（采纳弹幕实稿表格口径）

不挂 `mag/reload` 配额。理由：①配额制改变玩家资源模型，而盾的反饋已经由返还表承担，再加一层「盾没用多久了」是双重教学负担；②配额制要复用 `_reload_t`/`slot_mags` 通路，牵动的既有断言面大得多；③独立计数器的可证伪性最好（M-2 换算直接对上）。风险如实报：这样盾反可以高频刷，唯一节流是 C2 的 6 帧 CD ＋ 盾自身的 `interval`（0.90s ≈ 54 帧）天然限制了重新开窗的频率——这两层够不够，看 S40-c 实测日志说话。

### C6 `BLOCK_MULT` / `RETURN_MULT` / 眩晕时长（数值口径）：**待作者裁**（保留域②），推荐如下

| 项 | 候选 | **推荐（第一位）** | 理由 | 风险等级 / 可否回滚 |
|---|---|---|---|---|
| `BLOCK_MULT` 硬格减伤系数 | 0.5 ／ 0.34 ／ 0.25 | **0.5** | 敌弹现行 dmg 只有 1 与 2 两档（G2），×0.5 后 `int()` 截断得 0 或 1：轻弹硬格近乎免伤、重弹仍掉 1 心。硬格「几乎免费」的问题交给 C5 之外的另一道闸：见下行 | 低；纯常数，回滚＝改一行 |
| ├ 配套建议（同一条裁定） | — | **硬格至少掉 1 点血**（`maxi(1, round(dmg*BLOCK_MULT))`）还是允许 0？推荐 **允许 0**（元气骑士式硬格的直觉是「挡住了」），但若作者认为硬格必须有代价则选 `maxi(1,…)` | 这是 `BLOCK_MULT` 裁定不可拆的后半句，请一并点头 | 低；同段代码 |
| `RETURN_MULT` 返还倍率 | 1.0 ／ 1.5 | **1.0** | 防御型反击不该比主动开火强（否则最优解变成「引弹到脸上」）；1.0 还有个可机检红利：返还弹伤害逐字等于模板 DEFS 现值，V-P4 第 2 条不用引入浮点容差 | 低；纯常数 |
| `STUN_SHORT`（`T_RING` 盾反命中者） | 0.5s ／ 1.0s ／ 1.5s | **1.0s = 60 帧** | 参照既有 `apply_slow(0.6, 1.2)`（shieldbash 命中自带 1.2s 慢）同量级，眩晕略短于慢速才不至于「晕比慢狠」 | 低；纯常数 |
| `STUN_LONG`（预留，随 K3/拼刀启用） | 1.5s ／ 2.0s | **1.5s = 90 帧** | 同上量级放大一档；本批无消费点，登记备裁 | 低 |

> 🔴 上面这四个数是**作者保留域②**，我已给出推荐与理由，按项目规矩异步供阅即可——**S40-b/c 的其余条目不等它**：`BLOCK_MULT`/`RETURN_MULT`/`STUN_*` 先用占位常量（照实施单 C4「点名它是占位」）把管线搭完，作者点头后单次替换，替换不算越权（凭本件 §1-C6 的放行记录）。

---

## 2. (b) A 组探针三问 —— 逐条表态

### b1 env 名与落点：**批准 `SMOKE_SWEEP=1`，落点 `scripts/game_main.gd`**

- 现场复算（零 Godot）：`grep -rhoE 'get_environment\("[A-Z0-9_]+"' scripts/ | sed ... | sort -u` → **79 个**，名单里无 `SWEEP` 子串 ⇒ 零碰撞。⚠️ AGENTS §6 写的「76 个」是旧数（S38 之后新增的没同步），以现读为准；该行的「别从旧文档抄名单」本身仍然成立。
- 落点同意 `game_main.gd`，沿用 `_ml_assert` 范式（`:4766`）与 `SMOKE_MELEE` 块的组织纪律（`:4736` 起）：前置不成立就打 `Dev.err` 并明确标 **UNEXECUTED**，⛔ 静默跳过记 PASS；`declared` 必须是循环展开后的实数。
- 驱动方式补一条：挥击调用**优先走输入层**（喂 `Input.action_press("shoot")` 之类，具体 API 编程侧坐实），因为过载早退发生在 `_swing()` 函数体内（`player.gd:693-696`），直调 `_swing()` 同样能测到早退，但走输入层才能证明「手动路径与 autopilot（E3）路径同权」这条 V-S4 边界。两条都跑更好。

### b2 V-S1 反例构造姿势：**批准你的方案，M-5 让位于单一真源条款**

- 你说的姿势成立：探针用 `spawn_enemy_bullet(...)` 造不了行为位非零的弹（G1：入口把所有行为参位钉死为零），所以反例必须经 `BulletScript.new()` ＋ `setup(...)` 显式传不同行为参位（8 个反例分别占用 `pierce/explosive/bounce/frost/homing/arc/cluster` 七位 ＋ 一颗 `friendly==true` 全零弹），再断言「一次挥击后 8 颗仍在树 ＋ 正例那颗消失 ＋ `bullets_swept` 增量恰为 1」。
- **口径冲突点名裁决**：以**单一真源条款**为准（实施单 A1「生产侧与探针 oracle 必须同引此函数」＋ M-5 自己写的例外「允许共用的只有 §V-S1 那个显式声明的单一真源函数」）。M-5 的字面禁令与 A1 在同一份验证口径里本来就互相打脸，裁定：**oracle 允许调 `is_sweepable()`，但「这 8 颗应当不可扫」的期望集必须在探针里逐条硬编码**（即：反例是按参数摆出来的，不是探针运行时拿别的表达式现算出来的）。这样变异刀删掉 `not friendly` 时，友方那颗会进清扫集 → 「仍在树」断言必红，独立性靠构造方式而非重复表达式保证。
- 补充一条强制（V-S1 反向刀的执行细则）：`Game.rng.state` 在摆位前后快照比对——顺带覆盖 V-S3 判据①。

### b3 过载场景构造：**批准「写零配额」，⛔ 用 skill 机制造过载态**

- 事实先摆清（磁盘实读）：`skill_active()` ⟺ `skill_t > 0.0`（`player.gd:302-303`），`SKILL_DUR := 6.0`，激活入口 `activate_skill()`（`:293-297`）——**技能是「免配额」不是「配额归零」**：`_swing()` 里 `if not skill_active(): slot_mags[...] = mag()-1`，过载态没有任何现成 env 能稳定制造。所以「现读哪个 SMOKE_* 能把近战配额打到 0」的答案是**没有**，不必找。
- 认可的构造＝探针卫生规则③的自然延伸：装备 melee 武器后 `pl.slot_mags["ml_cleaver"] = 0`（探针有权写这个字段，`SMOKE_MELEE` 块已有同类先例 `:5279/:5287`），然后触发一次输入层的挥击请求，断言：
  ```
  bullets_swept 增量 == 0
  melee_swings   增量 == 0     # N7/V-C1：过载那一拍「不算一次动作」
  melee_rng_draws 增量 == 0    # 恒 1 次口径的前提是这次根本没执行
  _reload_t > 0.0              # 早退分支确实走进了 _start_reload()
  扇区内摆的弹仍在树
  ```
- 「过载中照常清理」的另一半（V-S4 第 4 行）＝ `skill_active()` 为真时扇区弹被清、且 `slot_mags` 不被扣——这条用 `activate_skill()` 摆，合法且零发明。
- 🔴 以上两段都是**探针摆位**，⛔ 为此新增任何产品机制/env/字段。

---

## 3. (c) 台账豁免与交付通道 —— 结论：**#11 维持有效，本批流水收口在 sprint-40/**

裁定理由：
1. `AUTORUN_LEDGER.md`/`AUTORUN_值守报告.md` 是**值守包（run 链）的键集产物**（A48-1/A49-1 反复钉「⛔ 每轮重跑整条链」「基准一律现读并与上一轮存件成对 diff」）。S40 开发窗不在 run 链上；往共享台账插一段非值守窗的流水，下一窗成对 diff 就会撞上外来行——这正是 #11 立条要防的事。
2. 批次纪律本来就是「交付即收口」：`production/sprint-NN/SPR40_交付_*.md` 是既成惯例（S38 四件交付均在 sprint 目录），AGENTS §1.1 没有「值守台账之外不得记账」的要求，也没有「每批必须碰共享台账」的要求。
3. **不解除**。本轮三条裁定转录、AGENTS §12 落盘确认、A 组实施与基线，一律写进 `SPR40_交付_A组.md`（或你按项拆分的交付件），那就是台账。
4. 附带义务一条：值守窗下次接管时若发现台账缺 S40 这段，**那是正确的**，值守窗自己按自己的口径补一行指针（指向 sprint-40 交付件），⛔ 把正文搬进共享台账。编程侧现在⛔ 动那两份文件，包括⛔ 追加。

---

## 4. 连带裁定（本轮转录触发的既有件订正）

| # | 位置 | 订正 |
|---|---|---|
| X1 | 实施单 §0 第 2 条「B 组等 D2 答复」 | **D2 已答（甲案）**。B1~B11 闸门解除；禁止事项 #13 前半句失效，后半句（PARRY 等 C1~C6）由本件 §1 替代——PARRY 现已可开工，唯 C6 四个常数按 §1-C6 的占位流程走 |
| X2 | 弹幕实稿 §7 C1/C2/C3/C5 | 已裁（12 帧／一颗一处理＋6 帧 CD／单向 stun／独立帧计数），§7 那段文字视为历史，以本件为准；C4 是**推迟**不是否决（随 K3 立项） |
| X3 | 特色创新候选清单 §7 J1 | 已答：K3 先行＋K1 正签。J2/J3/J5 与本批无关，继续挂着，⛔ 据此开工 K5/Git 工程单 |
| X4 | AGENTS §6「76 个」 | 现读 79 个（现场命令见 b1）。⛔ 编程侧代改 AGENTS 文字（A49-4/A51 的先例：AGENTS 改动归主理人，且与冻结重定同车）；我已在 §10 式口径里记下，收官批统一落笔 |
| X5 | slug 侧 stun 施工提醒（C1 组第一条的镜像处） | `slug.gd` 的位移合成有 **4 处** `+ _knock`（现场 grep 坐实四处，行号易腐不落此文）。`apply_stun` 的「主动位移归零」必须**四处全覆盖**，漏一处＝stun 期间怪还能带着 knock 之外的速度挪窝，V-P2 判据① 假过。boss.gd 镜像处同理先数清出口个数再动手 |

---

## 5. 请编程侧跑的机检（我本轮零 Godot，以下结果交回来我做独立核验）

1. **A 组改后全套门控**：M-1 环境（`SMOKE=1 SMOKE_SEED=<钉死> SMOKE_META_FINGERPRINT=1 --quit-after 3200`）＋ churn 只比断言行；`[SMOKE-SWEEP] done checked=N declared=N` 两数相等。
2. **V-S1 变异刀一把**：删 `is_sweepable()` 里的 `not b.friendly` → 预期「8 反例仍在树」中友方那颗报红；贴出红的断言原文。
3. **V-S3 判据①**：N∈{0,1,5,20} 四档清扫前后 `Game.rng.seed/state` 逐字快照（探针打印，⛔ 事后口头声称）。
4. **b3 过载断言**：§2-b3 那五条增量的实测值原样贴回。
5. **X5 覆盖自查**：`grep -n "+ _knock" scripts/slug.gd scripts/boss.gd` 的命中数与 `apply_stun` 实际拦住的出口数对照表。
6. （D 组三项照实施单 §4 原样跑，与本件无冲突。）

---

## 6. 状态一句话

A 组口径已全部闭合（b1/b2/b3 三个口子都给了结论，无剩余停等）；B 组按甲案全速推进；C 组结构层（RAISE/BLOCK/PARRY 窗口/stun/计数）可按 §1-C1/C2/C5 开工，仅 `BLOCK_MULT/RETURN_MULT/STUN_*` 四个数走占位＋异步供阅，作者点头后单次替换。

Sources（本件引用的外部公开设计经验，只取机制结论）:
- [Deflection | Sekiro Shadows Die Twice Wiki](https://sekiroshadowsdietwice.wiki.fextralife.com/Deflection)
- [How precise is the Deflect Mechanic in Sekiro? - Arqade](https://gaming.stackexchange.com/questions/387925/how-precise-is-the-deflect-mechanic-in-sekiro)
- [Shields - Dead Cells Wiki](https://deadcells.fandom.com/wiki/Shields)
- [Parrying - Any reason not to hold button down? : r/deadcells](https://www.reddit.com/r/deadcells/comments/mbgv5b/parrying_any_reason_not_to_hold_button_down/)
