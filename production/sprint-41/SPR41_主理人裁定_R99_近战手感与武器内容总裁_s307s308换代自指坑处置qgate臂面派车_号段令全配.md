# SPR41 主理人裁定 R99 · 近战手感与武器内容总裁 ＋ s307/s308 换代 ＋ 自指坑处置 ＋ qgate 臂面派车

- 件种＝裁定件（R99 立项总裁）。目标盘面＝本件＋实施单一件（见 §G）。
- 作者原话（本轮方向，逐字）：「先把R98收完，下一轮就按你说的做近战手感和武器内容。」⇒ **R99 主项＝玩家可见面：近战手感＋武器内容**；账面／尺面／卫生类只作附带项（§D），⛔ 反客为主。
- 编程侧不自裁面在本件全部裁毕：号段令（§C-0，实施单逐车转载）、AGENTS 追加授权（§C-7）、台账写盘刀点名（§C-8）、判断栏三项（§D）。

## §A 独立核验表（主理人当趟现读，⛔ 抄呈请件转述）

| 项 | 现读数 | 采集方式 |
| --- | --- | --- |
| git tip | `e655739`（本地＝远端；链 `8eceedb→b518f33→e655739`） | `git log --oneline -4` 当趟实跑 |
| AGENTS.md | 350 行（呈请件 §G 记「现读 345」系 e655739 追加前时次）・md5 前 10=`420fec94b1` | python 当趟现算（⛔ 抄 G 表转述） |
| S41_台账.md | 246 行・末行键＝轮 21⁗×10・md5 前 10=`dea01bc24c` | 同上 |
| 呈请件 | 123 行（§L 回写后） | `wc -l` 当趟实跑 |
| s 号真源 | 刀证面 max＝s318（借号三处申报在位：刀头注释／证件末行三段形／commit 正文③） | `_tools/spr41_r99/` 目录列面当趟实读 |
| _tools/spr41_r99/ | `_r99_pet.py`＋证件 3—8／p2b・`s318_r99_t1_ledger_writer.py`＋证件 1—4 | 同上 |
| porcelain | 1 行＝`?? %TEMP%/`（仓根未跟踪残留，≠任何生产文件改动） | `git status --porcelain` 当趟实跑 |
| 冻结表 | 2 FAILED／32 OK（`game_main.gd`⇄`player.gd`） | 照 SPR21-FROZEN.md5 现读口径 |
| 码底（手感面） | `player.gd` 2654 行 `31bafa6a72…`⇄`slug.gd` take_damage `_knock += from_dir * 60.0`（:479）＋闪白 modulate `(1.9,1.25,1.25)`＋`create_timer(0.08)` 还原＋`Game.sfx("hit", fx_rng, -10)`（:483）⇄`game_state.gd` `_process(:107)`⇄`shake()→main.add_shake`（:671）⇄`Engine.time_scale = 2.0 if _smoke`（`game_main.gd:158`） | grep／sed 当趟实读 |
| 码底（武器面） | `weapons.gd` DROP_POOL=`["liechi","guanglei","fushe"]`・MELEE_FIELDS 六项・KIND_MELEE 三族・近战队现 4 支・校准注释 `dmg = interval × 步枪 dps(3.33)`⇄`game_main.gd` META_WEAPON_POOL_BASELINE 27 id（:42-49）⇄`assets.gd` SFX 注册表现无 melee 键 | 同上 |

⚠ 与呈请件 §G 的分歧登记（以本表为准）：AGENTS 行数＝350（呈请件 §G 的 345 是 e655739 追加**前**时次，属「前」格合法但已过期）；md5 两格（AGENTS `5571690b69`⇄台账 `564813f438`）为回写后未重算的陈值——现读 `420fec94b1`／`dea01bc24c`，该族尺恒红见 §D-② 与 B-7。

## §B 常设口径（承 R98 §B，逐条有效，本件只补不覆）

- B-1 终态词六裸形尺不变；本件所有待落文案的落点句若含档位名，必须裸形，⛔ 复合形。
- B-2 含/不含某串尺：作用域（申报面⇄全文）先行分向，双向臂各立一闸。
- B-3 更正格两时次并列，⛔ 互改⛔ 回填。
- B-4 交付件⛔ 自证自身 md5（本件同受此条约束：§F 各串的落盘证明由生成刀证件承载，件面只登「前」时次与指针）。
- B-5 号段规程（R98 §C-⑤）不变：常驻尺⛔ 占 s 号；每车段由该车实施单固定；起点＝现读 max+1；借未派段首一枚须三处申报。
- B-6 【新立】⛔ 把**文档文件名**当代码靶面：R99 呈请件名内含「R98收口车」字样即触发 `SPR41_*R98*` 族 glob 假红一枚（第三类）。凡按题族取文档面的刀，靶集须显式排除呈请件/裁定件/实施单命名族，或改用白名单枚举；由此类误伤产生的历史红格只登记为**尺失效见证**，⛔ 计入生产缺陷账。
- B-7 【新立】⛔ 用 HEAD 相对代数（`HEAD~k`）表达「上一批 commit」：pre_ref／改前 ref 一律由内容在场性沿 first-parent 现读派生（AGENTS §7 条 B 正典）。凡该表达式随仓库增长而语义漂移者，视为腐烂尺，换代方向只有「派生化」，没有「放宽档期」。

## §C 主裁 · 近战手感与武器内容（R99 主项）

### C-0 号段令（原文，实施单逐车转载，⛔ 改写）

```
R99 号段令（主理人 2026-11-24 定，唯一合法分配面）：
避让集＝s297／s298r／s299—s318（历车已用全段，⛔ 复用⛔ 再借）。
T-1 设计实稿车＝s319—s321｜T-2 武器内容车＝s322—s327｜T-3 命中反馈车＝s328—s333｜
T-4 窗口连段扫击车＝s334—s339｜T-5 验收形车＝s340—s342｜T-6 入账车＝s343—s344｜
附带甲 qgate 臂面机检车＝s345—s346｜附带乙 措辞替换车＝s347—s348｜附带丙 s307/s308 换代车＝s349—s350。
各车首枚 s 号由该车实施单条目点名；⛔ 跨车借用；确需借＝借自己段尾后一枚并三处申报（B-5），⛔ 碰他车段内号。
```

### C-1 顿帧（hitstop）——命中微冻，走 FIXED_DT 计数，⛔ 动时间尺度

- 规格：敌受近战命中瞬间进入**全局短冻**：时长＝**4 个物理步**（`Game.FIXED_DT` 计数，≈0.066s），实现载体＝`game_state.gd` 新增 `hitstop_t: float`，在既有 `_process`（:107）里递减；`hitstop_t > 0.0` 期间 `game_main` 对敌人⇄弹幕⇄玩家的**行为步**跳过推进（渲染与 UI ⛔ 停）。
- 触达面：仅近战命中（`take_damage` 的 `crit` 入参不足以辨源，故由 player._swing 调用侧置旗：`Game.hitstop_t = HITSTOP_STEPS * Game.FIXED_DT`，普通 4 步／重击 6 步）。Boss 命中同样触发但减半（3 步／5 步），用既有 `is_boss` 分支。
- 硬禁：⛔ `Engine.time_scale`（E6 红线；且 smoke 下 :158 已钉 2.0，叠乘即污染一切既有计时断言）⇄⛔ `create_timer()` 承载玩法窗口⇄⛔ 任何 rng 消费（E1：零新抽，HITSTOP 常量不入池）⇄⛔ 停掉 `_process` 本体（探针 done 计数依赖主循环活着）。
- 守恒口径：churn 钉 `SMOKE_SEED` 后 `rng.seed`/`rng.state` 逐字不动；既有 `[S41-G4]` 等断言行⛔ 因本项翻红（翻红＝改时序语义，须先回主理人裁，编程侧不自修断言）。

### C-2 受击方向（视觉层）——朝向压扁，零状态零 rng

- 规格：`slug.take_damage` 已有 `from_dir` 入参（生产码事实，⛔ 新加参数）。视觉层在该函数入口追加一次瞬时形变：`sprite.scale` 沿打击轴压扁（切向压扁系数 0.8，0.08s 还原，与既有闪白共用一个 create_timer 还原回调——呈现层允许 create_timer，因为它不承载玩法窗口，与闪白同族）。
- 边界：⛔ 影响碰撞形状（`collision_shape` scale 不动）⇄⛔ 与 `modulate` 闪白互相覆盖（同一回调内各自还原各自的量）⇄ boss 变体不做压扁（体型大、抖动即错形），只保留闪白。

### C-3 击退——走 `_knock` 系数表，⛔ blast push 通道

- 规格：近战击退强度＝武器 DEFS 新增可选字段 `knock`（默认值＝现常数 60.0，保证既有四支近战数值零变化）；`slug.take_damage` 改为 `_knock += from_dir * knock_in`（`knock_in` 由调用方传入，缺省 60.0）。新武器按族给值：阔刃类 90—110、刺/枪类 40—60、快剑类 30—50、盾击类 120。
- 硬禁：⛔ `apply_blast_push`（player.gd:770 注释明令：与 dash 196—210px 位移区间纠缠）⇄⛔ 把 `knock` 加进 MELEE_FIELDS required 列表（required 六项是 validate/dispatch 共享契约，扩项＝改契约，须另裁）——`knock` 只能是**可选**字段，validate 遇到未知可选键按既有宽松面处理。
- 守恒口径：`knock` 默认 60.0 ⇒ 老装备路径下 `_knock` 轨迹与改前逐字一致（验证口径 V-B3 用同种子差分坐实）。

### C-4 音效与视觉帧——注册表别名复用，⛔ 新 wav

- 规格：`Assets.SFX` 注册表新增三键，全部**复用既有 wav**（音频导演先例：boss_intro/shrine/calamity 即别名复用形）：`melee_sw`（挥空，取自 shoot 组最短样本，pitch 0.8、vol -8dB）⇄`melee_hit`（命中，取自 hit 样本，pitch 1.0、vol -4dB）⇄`melee_heavy`（重击命中，取自 hit，pitch 0.7、vol 0dB）。播放走 `Game.sfx(name, Game.fx_rng.randf_range(...), vol)`——**只准 `fx_rng`**（呈现层旁路，E1 合法面），⛔ `Game.rng`。
- 未知名静默返回是 `Game.sfx()` 既有隐患面：新键必须先注册后引用，注册面断言（V-C3）＝三键在 `Assets.SFX.keys()` 现读集合内。
- 挥空音只在 `mag() > 0` 的真实出手路径播（overload 零伤害零计数路径同时零音效，与 HP-2 面同构）。

### C-5 攻击架式窗口——只读观测常量，⛔ 改判定

- 规格：不改 `_stance_open()` 语义（`_stance_t = maxf(_attack_anim_len(), _interval())`、`PARRY_FRAMES=12` 均为 S40 底子，动它＝改盾反判定＝方向级变更，待裁）。本项只落**可观测性**：每次 `_swing()` 结束时发一行 `[S41-W1] kind=<kind> stance_t=%.3f anim_len=%.3f interval=%.3f parry=%d`（`%.3f`，⛔ 时间戳外带），供验收形与后续 E 系回填对齐用。断言行⛔ 进 churn 白名单外的面。
- 若实测发现某武器 `stance_t` 被 `_interval()` 拖尾超过动画长 2 倍（手感黏滞征兆），登记进呈请件，由主理人下轮裁是否拆双窗，⛔ 编程侧自调常数。

### C-6 连段——近战命中喂现有 combo，⛔ 平行系统

- 规格：近战每次有效命中（至少命中 1 个敌人，⛔ 空挥）执行 `Game.combo += 1; Game.combo_t = Game.COMBO_WINDOW`——与射击命中同一计数器（AGENTS §12 反平行系统条）。若现状已是统一计数则本项降为纯验证（V-C6 先现读射击命中路径的递增语句，确认近战缺的是哪半截，⛔ 重复接线）。
- 硬禁：⛔ 新建 `melee_combo` 计数器⇄⛔ 触碰分数乘式（`×(1+(combo-1)×0.1)` 是元层既有账，改它须另裁）。

### C-7 扫击扇形——余韵窗口落地为机制层，接 S40/E 系口径

- 规格：`_swing()` 扫击段（零 rng 面，保持零 rng）统计 `swept`；`swept >= SWEEP_FLOW_MIN(2)` 时置 `_sweep_flow_t = SWEEP_FLOW_T(0.6)`（FIXED_DT 递减，挂在 `_physics_process` 既有递减簇里）；窗口内下一次近战 `arc_deg` 实耗值乘 `SWEEP_SPREAD_MULT(0.5 加成，即 ×1.5)`。常量全部沿用《盾反返还表》E 系既定默认（E5 缓行⛔ 动它）。
- 硬禁：⛔ 扫击加击退（player.gd:770 同族禁令）⇄⛔ 扫击消费 `Game.rng`（C 项实测事实：出卡/扫击面今天零 rng，保持）⇄⛔ 把 `_sweep_flow_t` 塞进 stable_hash/出卡路径。
- 守恒口径：`bullets_swept`/`last_sweep_count` 既有申报不变；新态只有 `_sweep_flow_t` 一枚浮点，`_PD_DECLARED := 83` ⇒ 若探针申报面被触及则 +1 须走 DECLARED-25 号域程序，⛔ 手写。

### C-8 武器内容·新近战两支（原创命名，素材判据已过三问）

| id | 名称 | kind | dmg | interval | reach | arc_deg | mag | reload | knock |
| --- | --- | --- | --- | --- | --- | --- | --- | --- | --- |
| `ml_frostbite` | 裂髓杵·霜枝 | melee | 1.95 | 0.585 | 44 | 96 | 4 | 0.95 | 55 |
| `wd_cinnifuse` | 燃符匣 | wand | 2.60 | 0.78 | —（弹道族不适用） | — | 5 | 1.15 | — |

- 死值依据：`dmg = interval × 3.33`（S36 §7.2 校准式，两支各自验算 0.585×3.33≈1.95⇄0.78×3.33≈2.60，容差 ±0.03）。⛔ 六弹道字段入 melee 项（[S38-A3]）；wand 项走弹道族既有字段面，⛔ MELEE_FIELDS。
- 特性附加（克制实用主义，皆代价）：`frostbite` 命中附带 `apply_slow(0.5, 1.0)`（复用 shieldbash 既有通道与其 N8 注释先例）；`cinnifuse` 每第 3 发（`mag` 计数相位）炸 42.0 半径×0.6——爆炸走既有 `explode()`，⛔ 新爆参数进 melee 字段。代价面：两者 reload/mag 劣于同级基准，DEFS 注释里写明「代价」一句。
- 落点：`weapons.gd` DEFS 追加两枚 dict（纯插，⛔ 改既有条目字节）；`META_WEAPON_POOL_BASELINE`（27 id）**不在本车动**——见 §E 待作者①。

### C-9 武器内容·掉落池与定向掉落

- 随机池：`DROP_POOL := ["liechi","guanglei","fushe","ml_frostbite"]`（+1 枚，新近战入池；`wd_cinnifuse` **不入池**，走定向面——稀缺法系留给 Boss 叙事位）。
- 定向掉落：`BOSS_WEAPON` 只读归属表新增映射：Boss 焚舍（既有 Boss 位，具体哪一尊由 BOSS 表现读坐实，实施单 T-2 点名）→ `wd_cinnifuse`。定向面走 codex_id 既有通道（W3=A 口径：Boss专武⛔ UNLOCKS 节点）。
- 已知副作用如实登记（不回避）：DROP_POOL size 3→4 使全部 `stable_hash % size()` 重排——这是**设计接受**的全层重分布（S33 实测事实 A 同源），⛔ 拿旧池出卡快照当回归基线；基线换代在 T-5 验收形车里由新 DEFS 快照重建。
- 守恒口径（数值类改动的硬前置）：T-2 首趟产**改前 DEFS 快照**（id⇄字段全表 md5）登进证件；改后快照第二格；断言＝既有 id 集合逐项字段零漂移（除 DROP_POOL 引用面），新增恰两枚，⛔ 顺手调任何既有数值。

### C-10 AGENTS 追加授权面（窄授权）

- 授权＝§F 串 7 一条，落 AGENTS §7 尾部，由 T-6 写盘刀落；⛔ 其他 AGENTS 追加授权（§8/§9/§11 本车一字不动）。
- 台账新行＝T-6 由 `s343` 写盘刀落（键＝盘上现读 10＋1 派生，⛔ 手打序号符），末行锚＝轮 21⁗×10 现读定位。

## §D 判断栏总裁（三项附带项，⛔ 挤占主项号段）

- **D-①　qgate 臂面机检车**：立案，派附带甲（s345—s346）。范围＝把 R98 单 §5 悬空的臂面补齐：qgate 三种调用面既有实测皆不可用（R94 呈请坐实），本车只做**只读机检刀**——对 `33a399c0bf／403` 面现读校验＋一红一还原双臂各证一次；⛔ 改 qgate 本体⛔ 起 Godot。完成定义＝证件 GREEN 且两臂红格留盘。
- **D-②　s307/s308 pre_ref 腐烂尺换代**：裁**换代，不归档**。理由＝B-7/AGENTS §7 条 B 为正典，归档等于承认「这批刀只配 R96 活在 HEAD=e655739 前一秒」，而复跑名单的价值恰在跨代见证。换代形：两把刀的 pre_ref 表达式改为「按枚题前缀（`S41 R96`）沿 first-parent 现读派生本车枚集最早一枚的父 commit」，⛔ `HEAD~k`⛔ 最迟一枚~1（该尺已在 R99 呈请件登记换代，同族延伸）。派车＝附带丙（s349—s350），改后首跑预期＝generation 形不再是 `b518f33` 而是当趟现读的 R96 车父 commit，复跑器代次 13 落盘。⚠ 注意：本项属卫生面，实施单里排在 T-5 之后执行，⛔ 抢主项趟次。
- **D-③　自指措辞坑（`_r98_pet.py:326`）**：处置＝**授权改刀**，派附带乙（s347—s348）。替换串＝呈请件 §B 给出并经本件采认的「追加后真值见本刀证件 P2b 格（件面⛔ 自指）」形；同步把 B-4（§B 常设口径本件已成文）作为 AGENTS §7 候选句交 T-6 一并裁——**AGENTS 句是否落**由 T-6 首趟按 §F 串 7 现读判，若串 7 与既有句撞意则只落台账不 duplicating 落 AGENTS（⛔ 同义两条）。改刀⛔ 顺带重跑生成历史 §L（历史行⛔ 回填，B-3）。
- **D-④　s243 换靶与否**（呈请件遗留）：裁**不换靶**。s243 现靶仍成立，其历史红格按 §B-6 归入「尺失效见证」登记一次即封；下轮若再红再议。

## §E 待作者（真需要作者拍板的，仅此两处，选项已给）

- **待作者①（保留权④）**：新武器入 `META_WEAPON_POOL_BASELINE` 基线（27→29 重登＝冻结表相关基线换代）。选项 A＝随 T-2 同车重登（推荐，一步到位，⛔ 分两轮留不一致窗口）；选项 B＝先不入基线、两支仅作局内掉落不进元池。**主理人倾向 A**，但重定基线属作者保留权，编程侧与本理人都⛔ 自落。 【R99a §M-2 终态：主理人已登记 27→29，作者保留否决权（下一到场可撤），不再停等点头】
- **待作者②（停等 #108 继承）**：Godot 窗口停等项自 R96 起挂账，R99 全程⛔ 起 Godot ⇒ 继续停等或由作者一次性解除。选项 A＝继续停等（推荐，R99 主项全部可离线验证）；选项 B＝解除后由编程侧在 T-3/T-4 各跑一趟真人感确认（手感主观面确实需要人玩，但可延至 R100）。**不阻塞本车放行**。

## §F 逐字串（**串 N** 行首锚＋次行「」括起，与 R98 裁件 §F 同形；落点由实施单点名）

**串 1**（T-2・`weapons.gd` DEFS 新条目注释头）
「[S41-R99-W] 近战增量两支：裂髓杵·霜枝（ml_frostbite・melee・knock=55・命中附 slow(0.5,1.0)）⇄燃符匣（wd_cinnifuse・wand・三发相位爆 42.0×0.6）。死值式 dmg=interval×3.33（S36 §7.2）；代价面＝reload/mag 劣于同级基准。⛔ 六弹道字段入 melee 项（[S38-A3]）⛔ knock 进 MELEE_FIELDS required。」

**串 2**（T-2・DROP_POOL 行尾注释）
「[S41-R99-D] DROP_POOL 3→4：+ml_frostbite；wd_cinnifuse 走 BOSS_WEAPON 定向面不入池。size 变⇒全层 stable_hash%size 重排＝设计接受（S33 事实 A 同源），基线以本车改后 DEFS 快照重建⛔ 拿旧池出卡快照当回归。」

**串 3**（T-3・`game_state.gd` hitstop 声明处）
「[S41-R99-H] hitstop_t：近战命中全局微冻，FIXED_DT 计数（普 4 步／重 6 步／Boss 减半 3⇄5），递减在 _process(:107) 既有簇内。⛔ Engine.time_scale（E6＋smoke 2.0 叠乘污染）⛔ create_timer 承载玩法窗⛔ 任何 rng。零新抽守恒：SMOKE_SEED 钉后 rng.seed/state 逐字不动。」

**串 4**（T-3・`slug.gd` take_damage 视觉段注释）
「[S41-R99-V] 受击方向＝from_dir 入参既有面复用：sprite.scale 沿打击轴压扁 0.8、0.08s 与闪白同回调还原；⛔ 动 collision_shape；boss 只闪不扁。击退＝_knock += from_dir * knock_in（缺省 60.0＝老装备轨迹逐字不变）；⛔ apply_blast_push（player.gd:770 dash 196—210px 纠缠禁令）。」

**串 5**（T-3・`assets.gd` SFX 三键注册处）
「[S41-R99-S] melee_sw/melee_hit/melee_heavy＝别名复用既有 wav（音频导演先例），播放只经 Game.sfx(name, fx_rng 抖程, vol)；空挥路径零音效（mag()<=0 分支不播）；引用先于注册＝静默失败隐患族，V-C3 闸＝三键在 Assets.SFX.keys() 现读集合内。」

**串 6**（T-4・`player.gd` 三处观测/接线点注释，同一串文本复用）
「[S41-R99-C] 连段＝近战有效命中（≥1 敌）喂 Game.combo/combo_t=COMBO_WINDOW，与射击同一计数器（§12 反平行系统）⛔ melee_combo 平行态⛔ 动分数乘式。架式窗口＝只读观测 [S41-W1] 行（kind/stance_t/anim_len/interval/parry，%.3f），⛔ 改 _stance_open 判定。扫击余韵＝swept>=SWEEP_FLOW_MIN(2) 置 _sweep_flow_t=0.6（FIXED_DT 递减），窗口内 arc_deg 实耗 ×1.5；⛔ 扫击击退⛔ 扫击吃 Game.rng。」

**串 7**（T-6・AGENTS §7 尾部一条）
「⛔ 让交付件自证自己的哈希，也⛔ 把文档文件名当代码靶面：闭合形须由车外件或他件承载，件面只能登『前』时次与指针；按题族 glob 取文档面的刀须显式排除呈请/裁定/实施单命名族（S41 R99 坐实：SPR41_*R98* 命中新呈请件自身名＝第三类假红）。」

**串 8**（T-6・台账新行正文头段，写盘刀派生键后拼接）
「R99 主项车组（近战手感＋武器内容）：hitstop FIXED_DT 微冻⇄_knock 系数化⇄SFX 三别名键⇄combo 统一计数⇄扫击余韵 0.6s；新两支 ml_frostbite⇄wd_cinnifuse；DROP_POOL 3→4 设计接受重排；附带三小车（qgate 臂面／_r98_pet 措辞／s307s308 换代）编号 s345—s350 全落地；待作者两枚＝基线重登④⇄#108 停等继承。」

## §G 入库面与禁止事项

- 入库面恰 2 件＝本裁定件＋实施单 `SPR41_实施单_R99编程侧落地单.md`；⛔ 触 AGENTS／台账（那是 T-6 写盘刀的目标）。
- ⛔ 起 Godot⛔ 占独占锁⛔ 动生产码⛔ 碰 AUTORUN⛔ 任何 GitHub 令牌字面入仓内文件（含掩码前后缀与长度，AGENTS §8 现行）。
- 文档面一律 LF；本件由主理人直写，非刀生成（自证豁免：§A 全部为当趟实跑读数，落盘证明按 B-4 由后续 T-1 生成刀证件承载「前」时次）。
