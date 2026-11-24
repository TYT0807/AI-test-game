# SPR41 主理人补裁 R99a · 判断栏八项（J1—J8）总裁

- 件种＝补裁件（R99 车组・判断栏专裁）。目标盘面＝本件一件；⛔ 修改既有件（裁定件／实施单／实稿／AGENTS／台账各留原形，两时次并列照 §B-3）。
- 依据＝实稿 `production/sprint-41/SPR41_设计实稿_R99_近战手感与武器内容.md` §12 J1—J8 ＋ 裁定件 §C-1…C-10 ＋ 实施单 T-2…T-5。本件**只裁不重写**：与实稿现读不一致处并列两时次，⛔ 在本件里改写实稿。
- 落点纪律：本件落盘后，编程侧按 §J 解锁表与 §Z 执行序发车；§X 九条禁则全部继承有效。

## §0 时次声明（本件落盘前当趟现读，⛔ HEAD~k 表达代次 B-7）

| 项 | 读数 | 采集方式 |
| --- | --- | --- |
| git tip | `1f0bcb9181f42ce7833e9ba38cd8f5e6d435a735`（短形 `1f0bcb9`・提交题「S41 R99 设计实稿车（第二枚＝呈请件 §K 承继行落盘・T-1 车毕）」） | `git log -1 --format='%H %ci %s'` 当趟实跑 |
| 实稿 | 存在・197 行・§12 判断栏 J1—J8 在位 | Read 当趟实读 |
| s 号真源 | 刀证面 max＝s321（`_tools/spr41_r99/` 列面有 s319 采集件⇄s320 生成刀证件 1—11⇄s321 回写刀证件 1—6）⇒下一合法枚＝**s351** | 目录列面当趟实读 |
| porcelain | 空（本件落盘前行序干净） | `git status --porcelain` 当趟实跑 |
| 冻结表 | 2 FAILED／32 OK（`game_main.gd`⇄`player.gd`） | 照 SPR21-FROZEN.md5 现读口径（继承裁定件 §A） |
| 停等 | #108 Godot 独占窗未解除（待作者②选项 A 生效中）⇒本车全程⛔ 起 Godot | 实稿 §13⇄commit 正文两处申报 |
| 生产码 | 本件零改动：`scripts/*.gd` 全 34 枚字节未动 | 本件只新建文档 |

⚠ 本件全部行号＝当趟 `grep -n` 现读坐实（文件:行号），落地趟开工时**必须现场复核一遍再引用**——行号是会腐烂的引用，本件的判据一律以「函数名＋字段名＋逐字句」为主锚、行号为辅锚。

## §A J1 总裁 · 新两支字段面逐键给值

**裁语：主理人补齐全部缺键，编程侧⛔ 自填任何一键。** 两支条目按下表**逐字**落 `weapons.gd` DEFS（纯插，位置紧排 `"wd_whisper"` 条目闭合之后、DEFS 闭括号 `}` 之前——盘行 268 附近，现读复核）。

### A-1 `ml_frostbite`（melee・补 desc/icon/tint 三键）

| 键 | 值（逐字） | 出处／机检判据 |
| --- | --- | --- |
| kind | `"melee"` | 裁件 §C-8 |
| name | `"寒髓杵·霜枝"` | **改名见 §B**（原名「裂髓杵·霜枝」与 weapons.gd:41 `"name": "裂髓杵"` 前缀撞车） |
| desc | `"一杵带霜，打慢一个"` | 写实口径：只述已做到的 slow(0.5,1.0)，⛔ 吹未做到的效果（先例＝weapons.gd:97 注释「desc 随之写实」） |
| dmg | `1.95` | 裁件 §C-8（死值式 0.585×3.33≈1.948，差 0.002≤±0.03） |
| interval | `0.585` | 同上 |
| reach | `44` | 裁件 §C-8（validate 范围闸：reach>0 ⇄ arc_deg∈(0,180] 均过） |
| arc_deg | `96` | 同上 |
| mag | `4` | 同上 |
| reload | `0.95` | 同上 |
| knock | `55.0` | 可选字段（⛔ 进 MELEE_FIELDS required，§X-5 不变） |
| tint | `Color(0.66, 0.84, 0.94)` | 冷霜色形，量级对齐同族 ml_needler `Color(0.72, 0.86, 0.92)`（weapons.gd:234 现读） |
| icon | `"wpn_ml_cleaver"` | **别名复用既有档**（盘上 `resources/texture/generated/wpn_ml_cleaver.png` 在册・GEN_NAMES 登记行 assets.gd:133 在册）。先例＝mw_cluster 复用 `wpn_fushe`（weapons.gd:88・validate GUARD-2 注释明文「一图标一武器不是要求」）。⛔ 新 png⛔ 手造未登记名——GUARD-2 三道判（非空⇄∈GEN_NAMES⇄可解析）逐字咬（validate.gd:631—641 区段现读） |

### A-2 `wd_cinnifuse`（wand・补 count/desc/explosive/homing/icon/life/pierce/speed/spread/tint 十键）

| 键 | 值（逐字） | 出处／机检判据 |
| --- | --- | --- |
| kind | `"wand"` | 裁件 §C-8（KIND_PROJECTILE 含 wand ⇒ 走 `_fire()` 弹道族字段面，F11 现读） |
| name | `"燃符匣"` | 裁件 §C-8 原名保留（与「焚舍符匣」不同前缀，无撞名） |
| desc | `"第三发炸开"` | 写实口径：相位爆是本件 J6 裁后的**真实机制**，改键后仍成立 |
| dmg | `2.4` | **本件 §E-2 新值**（原 2.6 让位反超闸；两时次并列见 §E 头） |
| interval | `1.10` | **本件 §E-2 新值**（原 0.78；死值式偏离理由逐字进条目注释） |
| count | `1` | 基准＝同族唯一一枚 wd_whisper 为 2（weapons.gd:263 现读）；本把走「单发重符」形，且 count=1 使 dps=dmg/interval 恒等（validate 与 §E 反超账同一把尺），⛔ 用 count 抬 dps（见 §E） |
| spread | `2.0` | 取 fushe 同值（weapons.gd:58 现读） |
| speed | `190.0` | 取 bw_core_hammer 同值（weapons.gd:119 现读），符匣＝钝速弹形 |
| mag | `5` | 裁件 §C-8 |
| reload | `1.15` | 裁件 §C-8 |
| pierce | `0` | ⛔ 贯穿（法系稀缺位不给穿透） |
| life | `1.10` | 介于 th_kunai 0.55（weapons.gd:258 现读）与 wd_whisper 1.40（:265 现读）之间 |
| explosive | `0.0` | 🔴 **必为 0.0**：否则 bullet.gd:135⇄:147 的 `if explosive > 0.0:` 分支会把每发都引爆炸形，与 J6 的「每第 3 发」双账 |
| homing | `false` | 显式写出（同族 wd_whisper 为 true，本把不追踪＝代价面之一） |
| tint | `Color(0.95, 0.55, 0.30)` | 燃符暖色形，量级对齐 mw_cluster `Color(1.0, 0.75, 0.35)`（weapons.gd:88 现读） |
| icon | `"wpn_fushe"` | 别名复用（盘上 png 在册・GEN_NAMES 登记行 assets.gd:110 在册・先例 weapons.gd:88 逐字同形） |
| phase_boom | `{"n": 3, "radius": 42.0, "mult": 0.6}` | **新可选字段，键名与本取值由本件裁定**（理由见 §F）；⛔ 进 MELEE_FIELDS required⛔ 进 `_ML_OUTSIDE_FIELDS`（game_main.gd:4771 名单六枚一字不动） |

- 两支共同守恒断言（s325 尺不变）：既有 id 逐项字段零漂移＋新增恰两枚＋MELEE_FIELDS 六项字节未动＋knock/phase_boom 不在 required 内。
- 附带披露（不改数）：实稿 §10「代价面逐格现算」中 cinnifuse 对 wd_whisper 的 reload 一格是「优」非「劣」（1.15 < 1.2）——reload 劣于基准这半句在 wand 侧不成立，mag 5 < 6 也不成立；本件按「代价面＝单发强度换射速/弹匣」的设计语义接受现算结果，⛔ 为圆实稿断言改数。此格属两时次并列披露，回写归 T-6 呈请面。

## §B J2 总裁 · 击退族表归族方式＋改名

1. **族表降为定值出处，不落运行时结构**：族表四类（阔刃 90—110⇄刺/枪 40—60⇄快剑 30—50⇄盾击 120）**不进代码**——运行时唯一查表＝DEFS 的 `knock` 字段（缺省 60.0）。编程侧⛔ 建族映射 dict⛔ 按 kind 推系数（kind=melee 同装阔刃与密针两形，F11/KIND_MELEE 现读即证据）。
2. **认可 frostbite 归「刺/枪类」并确认 55.0**：55 ∈ [40,60] 成立；其扇形 96°／reach 44 介于 needler(60/34) 与 cleaver(110/46) 之间，取刺类不违形。
3. **既有四支不回填 `knock` 字段**：缺省链＝老装备走 60.0，V-C8 轨迹差分基线不破（实稿 §5「现读调用点仍传 3 参」同账）。
4. **改名批准**：`裂髓杵·霜枝` → **`寒髓杵·霜枝`**。id `ml_frostbite` 不变；裁定件 §F 串 1 内的旧名「裂髓杵·霜枝」随串转录为新名（转录格见 §I-1）。

## §C J3 总裁 · 连段口径＝击杀口径（选第一项）

**裁语：近战也走击杀口径——combo 递增点维持 `func register_kill`（game_state.gd:1072）唯一枚，本车零接线。**

- 论据：①盘面 combo 唯一递增在击杀体内（同体 `kills += 1`，F18 现读），射击侧命中路径零写入（实稿 §8）⇒「与射击命中同一计数器」在盘面没有对应物，接「命中口径」＝发明新口径；②分数乘式 `1.0 + (combo - 1) * 0.1`（game_state.gd:1077 现读）直接吃 combo，改命中口径＝动分数账，须另立一轮带数值配平的裁定，不入本车；③击杀口径下近战与射击天然同账（kill 不分来源，`on_slug_killed`→`register_kill` 唯一路径，game_main.gd:3865⇄3867 现读）。
- s335 执行形＝**纯验证**（实施单原句「或降级验证」就此定死）：断言甲＝全仓 `combo += 1` 现读恰 1 枚且在 `func register_kill` 体内；断言乙＝`melee_combo` 标识符全仓 0 枚；断言丙＝`Game.combo >= 20` 里程碑读点（game_main.gd:3876）未被近战侧新增旁路喂入（grep `combo` 在 player.gd/slug.gd 增量=0）。
- 裁定件 §C-6 的字面「每次有效命中→combo+=1」**由本件作废**，作废句：「§C-6 接线半句作废，落『击杀口径维持现状＋三断言纯验证』，两时次并列，⛔ 回填 C-6 原文。」
- 后续伏笔（不在本车做）：若将来要「命中即连段」，须另裁并同步分数账配平——登记进 T-6 呈请面的待议清单即可。

## §D J4 总裁 · Boss 判据落点限定 slug 侧（选第一项）

1. **slug 侧唯一判据＝既有 `variant == "boss"`**（slug.gd 现读三枚 [122, 141, 483]）；裁定件 §C-1 所称 `is_boss` 全仓 0 枚——该措辞**由本件作废**（作废句见 §I-2），凡落点句一律改写为 `variant == "boss"`。
2. **落点范围＝只 slug 侧**：hitstop 减半（Boss 3⇄5 步）与压扁豁免都落在 `slug.take_damage`（slug.gd:457）体内的 `if variant == "boss":` 分支上（现读 :483 那一枚正是 emit 用分支，压扁豁免与其同分支族）。
3. **boss.gd 不点名、不进六枚、本车零改动**：PrismWarden 自带 `take_damage`（boss.gd:309）与 `apply_slow`（boss.gd:323），独立实现、不在实施单点名文件集内；boss2/boss3 extends PrismWarden 自动随它。⇒主题 Boss 受击面本车**既不减半也不压扁**（它们根本不进 slug.take_damage），此为设计接受的已知边界，登记一句进 T-6 呈请面：「真 Boss 的 hitstop/压扁语义留待下轮点名 boss.gd 时随冻结面换代再议」。
4. 冻结面随动说明：本项裁语使 `boss.gd` md5 保持 OK（34 枚冻结表里它仍是未动者），FAILED 名单不因 J4 扩大。

## §E J5 总裁 · 定向掉落＝BOSS_WEAPON 不入，cinnifuse 走「floor 8 守关 Boss 房」确定性早退

**裁语：选第三形态——不入 BOSS_WEAPON；同时下调 cinnifuse 数值到反超线下并把键名改具语义；不另立第四尊 Boss。**

⚠ 两时次并列（§B-3）：实稿 §12 J5 原文写「从现读 Boss id 点一尊／不入 BOSS_WEAPON 走别的定向面／另立第四尊」三选项，且实稿 §10 表体登 dmg=2.6/interval=0.78；本件取「别的定向面」形并给新数值 2.4/1.10——实稿格留原形⛔ 回填，以本节为准。

1. **为何不入 BOSS_WEAPON（硬账）**：`_check_boss_weapons`（validate.gd:419 起）对每组判「反超把数恰好 2」（现读 problems 句「口径要求恰好 2（R=%.2f…」），且灰区句当场判红「没到反超线却高于 Boss 自身」。三尊反超线现读＝{prism 0.8333, pyro 1.1364, third 0.9615}（BOSS_PULSE_BASE data.gd:347 × WEAPON_SURPASS_RATIO 1.25，data.gd:341）。cinnifuse dps=3.3333 挂任何一尊都是第三把反超＝必红；即便调 dps 也会落「>dps_boss 而 <反超线」的灰区，除非一步调到 ≤dps_boss。
2. **数值下调（新值逐字）**：`dmg = 2.4`、`interval = 1.10` ⇒ dps=2.1818。
   - 反超标量（validate 实际读的 dmg/interval）2.1818 ≤ 三尊各自 dps_boss（0.6667/0.9091/0.7692）⇒**永不进反超计数、永不落灰区**，「每组恰好 2」不动。
   - 与脉冲基准的比值 2.1818/dps_boss ∈ {3.27, 2.40, 2.84}——这是**刻意保留的余量**：validate 的反超闸只认脉冲 dps，图鉴侧另有 `Weapons.surpass_note()`（weapons.gd:294 起）按 `BOSS_PULSE_BASE × WEAPON_SURPASS_RATIO` 出「反超小字」，比值 ∈ (1.25, 3.27) ⇒ 小字句自然出现、与设计意图（「一部分性能比 Boss 还强」的叙事位）吻合，且该函数只对 BOSS_WEAPON 成员出句——本把不在其中，故**不会误出小字**，两套账不打架。
   - 代价面随动如实：interval 0.78→1.10＝射速明显变钝（对比 wd_whisper 0.90），「重而慢」成立；dmg 2.6→2.4 后死值式 dmg=interval×3.33 不再闭合（2.4 vs 3.6636）——该式是 S36 步枪 dps 定价尺，本把按 J5 让位于反超闸，**偏离理由逐字写进条目注释**：「⛔ 死值式让位：入 BOSS 叙事位的法系单发按反超闸定价（本件 §E），dps 2.1818 ≤ 三尊脉冲基准」。
3. **键名随语义改**：`phase_boom_n` → **`phase_boom`**，取值 `{"n": 3, "radius": 42.0, "mult": 0.6}`（§A-2 表已按此名落）。
4. **定向面（新机制・窄授权）**：落点＝`game_main.gd` 的 `func _boss_weapon_drop()`（现读 :3159）体内**首行之前**插一条确定性早退——`if Game.floor_num == 8: return "wd_cinnifuse"`。理由：该函数正是 Boss 房武器掉落的唯一取把口（调用点现读 :3124 `"weapon", 1, _boss_weapon_drop()`），且其既有语义本就允许返回任意 id；floor==8 在 `_is_sovereign_floor`（n>4 且 (n-4)%16==15 ⇒ 首个命中 19）与 `_is_third_floor`（(n-4)%32==23 ⇒ 首个命中 27）两个特判层之下，是**常规守关层**、今天走 `_codex_boss_at_floor→""→_random_weapon()` 随机回退——本条把「floor 8 守关 Boss 房」这一格从随机改 deterministic，语义位与「Boss 叙事掉落」最贴。
   - 🔴 零 rng 硬约束：早退形**连 stable_hash 都不消费**（原函数的 key 拼法只在走 ids 分支时用），故 E1 指纹三 seed 逐字不漂；判定尺＝同 seed 两次运行 floor 8 出把逐字一致（churn 尺）＋`Game.rng.randf(` 计数不动。
   - ⛔ 动其它层取把逻辑⛔ 改 `_random_weapon()` 权重⛔ 给 DROP_POOL 加它。若编程侧实测该早退与任何既有断言（如 T-B3 探针族对 `_boss_weapon_drop` 的取样断言）冲突，如实进呈请件回主理人，⛔ 自挪落点。
5. **「Boss 焚舍」措辞作废**：裁定件 §C-9 那句「Boss 焚舍（既有 Boss 位…）」**由本件作废**（作废句见 §I-3）——「焚舍符匣」是武器名（weapons.gd:57 现读），Boss 名面零枚；本件把定向面从「BOSS_WEAPON 归属表」改道「floor 8 守关 Boss 房掉落早退」，不动 CODEX_BOSS_NAMES 三键、不动 BOSS_WEAPON 14 条。
6. V-C9 补充断言：DROP_POOL 不含 wd_cinnifuse（validate 的 bw_ 前缀禁入池闸管不到非 bw_ 把，须 s326 新设只读核点名 `not DROP_POOL.has("wd_cinnifuse")`）。

## §F J6 总裁 · 特性判别键＝两个可选字段（同 knock 处置）

**裁语：各加可选字段，⛔ 新 kind⛔ id 特判⛔ 进 required。**

- 🔴 **读点位置更正（本件现读硬事实，编程侧照此落、⛔ 照下面两行字面抄进函数体）**：validate 的源码闸把 `func _swing(` 切到下一个 `\n\nfunc `（validate.gd:382 现读），而 `_fire()` 与 `_swing()` 之间**没有别的函数**（`func _fire()` 在 player.gd:689、`func _swing()` 在 :730）⇒ 任何写在 `_fire()` 体内的 `Game.fx_rng.randf` / 第二枚 `Game.rng.randf(` 都会**落进 `_swing` 切片**并当场翻红（:388⇄:390）。故两个特性的「抖程/取数」一律不得内联在 `_fire`/`_swing` 体内。

| 条目 | 键 | 值 | 运行时读点（逐字形） |
| --- | --- | --- | --- |
| ml_frostbite | `slow_on_hit` | `{"mult": 0.5, "dur": 1.0}` | `player.gd` `_swing()` 命中循环内，紧跟既有 `e.take_damage(dmg, to_e.normalized(), crit)` 行（现读 player.gd:768）之后、shieldbash 分支之前：`if d.get("slow_on_hit", null) != null and is_instance_valid(e) and not e.dead: e.apply_slow(float((d["slow_on_hit"])["mult"]), float((d["slow_on_hit"])["dur"]))`——本读点零 rng 零 fx_rng，切片闸不伤它（validate 只禁 randf 子串，:388⇄:390 现读）。 |
| wd_cinnifuse | `phase_boom` | `{"n": 3, "radius": 42.0, "mult": 0.6}` | **helper 承载**（同 §G 的 `_swing_sfx` 手法）：player.gd 新增 `func _phase_boom_check(d: Dictionary, muzzle: Vector2) -> void:`，与 `_swing_sfx` 同区落位（`func _interval()`:682 之前，同时不入 `_fire`/`_swing` 切片——`_fire` 在 :689、`_swing` 在 :730，两函数间无第三函数，helper 若夹在其中必被 `_slice` 收进 `_swing` 段）。体内读 `d.get("phase_boom", null)`、算本匣已耗发数 `(int(d["mag"]) - int(slot_mags.get(cur_weapon(), int(d["mag"])))) % int(pbv["n"]) == 0` ⇒ `Game.main.explode(muzzle, float(pbv["radius"]), float(d["dmg"]) * damage_mult * bullet_dmg_mult * float(pbv["mult"]), false)`；`_fire()` 体内只留裸调用 `_phase_boom_check(d, muzzle)`（不含任何 randf 子串）。相位口径＝本弹匣内第 3 发，换弹归零（下一条钉死）。 |

- 为什么不选另两形：新 kind＝动 KIND_MELEE/KIND_PROJECTILE 共享契约（F11）＋分派闸（validate.gd:407 `is_melee_kind` 单源句）＝方向级变更；id 特判＝数据驱动反正典，先例全无。
- 语义钉死：**「每第 3 发」＝本弹匣内第 3 发（相位 n=3），不是全局计数**——上式为「本匣已耗发数 % 3 == 0」，换弹（`_start_reload`，player.gd:901）后相位自然归零；⛔ 新建持久计数器字段（新态触及 _PD_DECLARED/申报面须另走号域程序，本形零新态）。
- 爆炸参数出处：radius 42.0 × mult 0.6 逐字对齐 crit_boom 共振形（player.gd:804 现读 `Game.main.explode(p, 42.0, dmg * 0.6, false)`）；hurt_player=false 同形。
- validate 侧同步（s326 只读核两条）：`slow_on_hit`/`phase_boom` 出现在 melee 条目上**不算**规格外（extra_outside 名单六枚一字不动，[S38-A3] 行只点名不判红的既有宽松面延续）；`explosive` 在 wd_cinnifuse 上必为 0.0（防双爆，§A-2 已钉）。
- 连坐防护：读点一律走 `d.get(...)`，既有两支 melee（ml_cleaver/ml_needler）无此键 ⇒ 行为零变化，V-C8 同种子差分覆盖。

## §G J7 总裁 · 音效抖程落点定点（helper 方案）

**裁语：不放宽 validate 源码闸；挥空音落新 helper，命中音落 slug 侧既有形。**

1. 闸的现状（现读坐实）：validate.gd 用 `_slice(pl_src, "func _swing(", "\n\nfunc ")` 取段（validate.gd:382），段内 `Game.fx_rng.randf` 子串即问题（:388—389）、`Game.rng.randf(` 须恰 1 处（:390—392）。⇒ **`_swing` 体内一个字都不许加 fx_rng**。
2. 落点裁定：
   - **命中音**：**不在 `_swing` 体内加任何 `Game.sfx(..., fx_rng...)`**（切片闸即 §G-1）——近战命中的音效由 `slug.take_damage` 内既有那枚 `Game.sfx("hit", Game.fx_rng.randf_range(1.1, 1.3), -10.0)`（slug.gd:481 现读）承载，近战与子弹同账；`melee_hit` 别名的**注册**照裁定件 §C-4 完成，运行时是否改调 melee_hit 本车不做（避免动 slug 侧既有音频断言面）。
   - **挥空音⇄重击音**：在 player.gd 新增私有 helper，逐字签名 `func _swing_sfx(heavy: bool) -> void:`，体内形如 `Game.sfx("melee_sw" if not heavy else "melee_heavy", Game.fx_rng.randf_range(0.92, 1.1), -8.0 if not heavy else 0.0)`。放置位＝`func _fire()`（player.gd:689）定义行**之前**——切片器从 `func _swing(` 向后截到下一个 `\n\nfunc `（validate.gd:382），而 `_interval()`（:682）夹在 `_update_aim_and_fire`（:651）与 `_fire`（:689）之间，helper 落在 :682 之前即同时不入 `_swing` 段、也不入 `_fire`/任何其它被闸取段的函数体；`_swing` 体内只准出现裸调用 `_swing_sfx(false)` / `_swing_sfx(true)`（不含 `Game.fx_rng.randf` 子串，闸绿）。写盘后 s331 须现场复核一次「helper 定义行号 < `func _interval()` 定义行号」＋切片自检。
   - 时序：调用点排在配额早退 `if not skill_active() and mag() <= 0:` 分支**之后**（实稿 §6 空挥定义＝早退那支配额不播；早退分支内零音效）。
3. ⛔ 把抖程塞进 `Game.sfx` 内部（game_state.gd:653 默认参形＝改公共入口签名，波及全仓调用方）；⛔ 放宽 validate 该闸（HP-3 禁第②条的原闸，动它＝动正典）。

## §H J8 总裁 · 放宽 action 禁令，授第四键 `melee_heavy`

**裁语：选第一项——主理人明令放宽，ACTION_DEFS 18→19 枚，新键逐字如下。**

1. **新 action（assets.gd ACTION_DEFS，现读 18 键・assets.gd:341 起）**：
   `"melee_heavy": {"name": "重击", "keys": [KEY_SHIFT], "mouse": [], "kb": true, "mb": false}`
   ——逐字照上面这个 dict 形落（mouse 空数组、kb 允许重绑、mb 关闭，防与 bomb 右键抢输入）。默认物理键＝Shift（现读占用表：move WASD/方向键、shoot 左鼠、bomb 右鼠、skill Space、swap Q、reload R、buy E、card_1..3 数字 1-3、pause Esc、relic F/Z/X/C——Shift 零占用，随新键注册）。
2. **触发语义（player.gd）**：近战持握时（`WeaponsClass.is_melee_kind(String(cur_def().get("kind", "")))` 为真）长按 `Input.is_action_pressed("melee_heavy")` 累计计时入**新浮点字段** `_heavy_hold_t`（FIXED_DT 递减簇同款形，挂 `_tick_timers`，player.gd:2420 现读）；松开瞬间若 `_heavy_hold_t >= 0.30` 且 `_fire_cd <= 0.0 and _reload_t <= 0.0 and _swap_t <= 0.0` ⇒ 走一次重击挥（`_swing(true)` 形参化，见下）并照常扣配额/开窗；不足阈值＝普通出手节奏完全不变（shoot 单键路径原样）。非近战持握时新键**什么都不做**（不占 shoot 语义、不影响枪械节奏）。
   - 阈值逐字：**0.30 s**；判定窗＝「按下期间累计、松手结算」；冷却沿用 `_fire_cd = _interval()` 既有行。
3. **`_swing(heavy := false)`**：加默认参（调用点现读仅 game_main.gd 探针若干＋player 分派一处，默认参保三参兼容）；heavy=true 时置 `Game.hitstop_t = HITSTOP_STEPS_HEAVY * Game.FIXED_DT`（6 步＝0.10000s），普攻 4 步、Boss 减半 3⇄5 照 §C-1 原数（减半在 slug 侧按 `variant == "boss"` 判，J4 裁语）。伤害倍率本车**不加**（重击＝节奏与顿帧差异＋专属音，数值仍走 DEFS，防动配平域）。
4. **注释随动（同文件同批）**：player.gd:812 那句「⛔ 新增 action：`ACTION_DEFS` 真值 18 条一字不动——举盾＝『正拿着盾且刚挥过』，没有第四个键」按本件改为「举盾语义不变；ACTION_DEFS 现值 19 条＝R99a §H 授权新增 melee_heavy（重击＝长按阈值出手，与举盾无关），⛔ 再借它加第五键未经另裁」。
5. **连带账（如实登记，T-5 处理）**：
   - 设置页/重绑持久化按 ACTION_DEFS 单源遍历（assets.gd:365 现读 `for action in ACTION_DEFS:`），预期零改动即自适应——s340 须实测「19 键全渲染＋旧存档重绑不崩」一条。
   - churn 白名单：新键不改任何既有打印行的格式；若实测某 `[SMOKE-*]` 行因此变动，报主理人，⛔ 自扩白名单。
   - 裁定件 §C-4 的 `melee_heavy` 音效键自此有了触发物（helper 的 heavy 分支，§G-2）；实稿 §12 J8「死码」判定自本件起失效（两时次并列，实稿⛔ 回填）。
6. 风险披露（给作者看的一句）：加键＝动输入层，真人手感验收（#108 解除后）要专门试一次「长按重击不与换弹/切枪打架」；离线侧由 s332 常量互等尺＋同种子复现兜底。

## §I 作废句与串转录（append-only，⛔ 回填原件）

- **I-1 串 1 转录格**（T-2 落 weapons.gd 注释头时用本形；裁定件 §F 串 1 原文留档不动）：
  「[S41-R99-W] 近战增量两支：寒髓杵·霜枝（ml_frostbite・melee・knock=55・slow_on_hit={0.5,1.0}）⇄燃符匣（wd_cinnifuse・wand・phase_boom={3,42.0,0.6}・dmg=2.4/interval=1.10 按 R99a §E 让位反超闸⛔ 死值式）。icon 别名复用（wpn_ml_cleaver⇄wpn_fushe，先例 mw_cluster）。⛔ 六弹道字段入 melee 项（[S38-A3]）⛔ knock/slow_on_hit/phase_boom 进 MELEE_FIELDS required。」
- **I-2 作废句（§C-1 尾句）**：「用既有 `is_boss` 分支」作废——盘面零枚；正形＝`variant == "boss"`（slug.gd 现读 [122,141,483]）。落点句凡引此处一律用正形。
- **I-3 作废句（§C-9 定向格）**：「Boss 焚舍（既有 Boss 位，具体哪一尊由 BOSS 表现读坐实）」作废——焚舍符匣是武器名；正形＝wd_cinnifuse 走 floor==8 深渊清算确定性发放（本件 §E-4），⛔ 入 BOSS_WEAPON。
- **I-4 作废句（§C-6 接线半句）**：见 §C 第三条逐字作废句。
- **I-5 授权句（§C-4/action 禁令）**：裁定件未涉；本件 §H-1/H-4 是对 player.gd:812 注释禁令的**首次也是唯一**放宽授权，范围止于一枚键。

## §J 号段影响（实施单车次表点名 s322—s342 逐格判）

- 避让集不变：s297／s298r／s299—s321 已用尽（s321 回写刀已 GREEN 入库，commit `1f0bcb9` 现读）。
- **T-2 s322（改前 DEFS 快照）：早已放行**（不依赖任何 J 项，首趟照发）。
- **T-2 s323（DEFS 纯插）：解锁**——J1 逐键给值＋J2 归族裁语＋J6 键名裁语齐备。
- **T-2 s324（DROP_POOL＋定向格）：解锁**——池行按裁件逐字形 `["liechi","guanglei","fushe","ml_frostbite"]`（无空格形为准，实稿 §11 两形之问就此拍板）；定向格按 §E 改道：BOSS_WEAPON **零改动**，改落 `_boss_weapon_drop()` 首行早退一条（floor==8→wd_cinnifuse，零 rng）＋串 2 注释用 §K 转录形。
- **T-2 s325/s326：解锁**（s326 只读核加两条：DROP_POOL 不含 wd_cinnifuse⇄phase_boom/slow_on_hit 不入 extra_outside 名单）。
- **T-2 s327：仍卡**——元池 27→29 属作者保留权④（§E 待作者①），**未裁・挂作者**；安全默认（选项 B）生效中＝不发趟・两支不进元池（MG-PW1 集合断言按现状 27 枚恒绿，本件核实：新两支无 meta 键 ⇒ 默认可用集会多出两枚，🔴 **该断言会红**——见下条更正）。
  - 🔴 更正格（本件现读新发现，实稿未载）：`_meta_pool_ids("weapon")` 过滤的是**整张 DEFS**（game_main.gd:2556—2571 现读），而 MG-PW1 拿它与 META_WEAPON_POOL_BASELINE 判集合相等（:2501—2503 `missing.is_empty() and extra.is_empty()`）。⇒ **只要两支一进 DEFS（s323），SMOKE_META_POOLASSERT 门下的基线断言必红「多 [ml_frostbite, wd_cinnifuse]」**——「选项 B＝不发 s327 就安全」这个前提不成立。处置裁定：s323 与基线重登**原子同批**（同 commit 落 DEFS＋META_WEAPON_POOL_BASELINE 27→29），即待作者①事实上被盘面锁死为选项 A；若作者明确否 A，则唯一合规路线＝两支暂不入 DEFS（T-2 主格停发）回主理人重裁。**本件按 A 推进发车，同时在 §M 向作者一次性呈报此锁定事实**（这不是替作者行使保留权——是盘面证明「不动基线必红」，作者若要 B 请连 s323 一起叫停）。
- **T-3 s328/s329：早已放行**（hitstop 声明与门控旗不依赖 J 项）。
- **T-3 s330：解锁**——J4（slug 侧 variant 判据）＋J8（heavy 形参与 6 步档触发物）＋J2（knock_in 缺省链）。
- **T-3 s331：解锁**——J7 给出 helper 落点与逐字签名；注册面三键照裁定件 §C-4（melee_hit 的运行时调用自 J8 起不再是死码）。
- **T-3 s332/s333：解锁**（常量互等尺靶随 J8 定形：4/6/3/5 四枚常量名建议 HITSTOP_STEPS=4⇄HITSTOP_STEPS_HEAVY=6⇄HITSTOP_STEPS_BOSS=3⇄HITSTOP_STEPS_BOSS_HEAVY=5，逐字命名由 T-3 首趟落码后 s332 现读互等）。
- **T-4 s334：早已放行**（观测行格式串不变；先登申报面再进白名单的顺序铁律不变）。
- **T-4 s335：解锁**——J3 裁语＝降级为三条纯验证，无需接线。
- **T-4 s336/s337/s338/s339：早已放行**（扫击余韵三项不依赖 J 项；s337 的 grep 尺靶名 `melee_combo` 按 §C 断言乙复用）。
- **T-5 s340/s341/s342：解锁**——s340 验证口径续段须吸收本件全部改判（J5 定向面新断言⇄J8 十九键渲染断言⇄§J 更正格的基线原子性断言）。
- **是否需追加号**：**不需要**。T-2…T-5 全部落在原段 s322—s342 内；本件自身不占 s 号（文档直写件，照裁定件先例）。§C-0 号段令全文继续有效，本件不转载不修订（无变更即转载＝多余的第二份账）。若 T-2 因 §J 更正格需要一趟独立的「基线原子性」取证趟，借该车段尾一枚 s327 之后的下一空位**不允许**——正确做法是把取证并入 s325 机检刀的断言集（s325 本就读 DEFS 快照两格），⛔ 新开号。

## §K 串 2 转录格（DROP_POOL 行尾注释・T-2 s324 用本形）

「[S41-R99-D] DROP_POOL 3→4：+ml_frostbite；wd_cinnifuse 不入池、不走 BOSS_WEAPON（R99a §E 改道：_boss_weapon_drop 的 floor==8 确定性早退，零 rng）。size 变⇒全层 stable_hash%size 重排＝设计接受（S33 事实 A 同源），基线以本车改后 DEFS 快照重建⛔ 拿旧池出卡快照当回归。」

## §L 未裁项（属作者保留权，本理人不裁）

| 项 | 状态 | 安全默认（选项 B 形）——编程侧据此继续发车 |
| --- | --- | --- |
| 待作者①（保留权④：元池基线重登 A/B） | **未裁・挂作者**；但 §J 更正格证明「B 与 s323 不可共存」 | 默认仍＝B（s327 独立趟不发）；按本件 §J 路线走 A 时基线随 s323 原子落，**须作者在 T-2 开工前点头**，否则 T-2 只发 s322 快照趟、s323 及以后武器内容格全部顺延 |
| 待作者②（#108 Godot 独占窗） | **未裁・挂作者**（选项 A 生效中） | 全程⛔ 起 Godot；七件套依赖 Godot 的门照旧停等；V-C2 运行面/黏滞判据/真人手感全部挂账不销 |
| 元池之外的商店/货架可见面 | 未点名 | 本件不动 random_unlocked 路径；DROP_POOL 变化自然生效，⛔ 另开授权 |

## §M 给作者的呈报（一段，看完点头才能发 T-2 主格）

§J 更正格是新发现的盘面事实：武器可用集断言（MG-PW1）拿 `META_WEAPON_POOL_BASELINE` 对**整张 DEFS** 判集合相等，所以「新武器进 DEFS」与「基线 27→29」在代码上是原子事件——不存在「先加武器、基线以后再说」的中间态（那个中间态必红）。您的保留权④因此只剩两种真选项：A＝同意基线重登（T-2 正常发车）；B＝两支暂不进 DEFS（T-2 武器内容格全线停发，本件 §A 参数表留档待命）。⛔ 编程侧自行选边。

## §Z 给编程侧的执行序（按解锁顺序；与实施单冲突处以本件为准，冲突格已标）

1. **T-2 s322**（先行，无依赖）：改前 DEFS 快照双格第一格。完成判据＝证件含 27 枚 id 逐条字段 dump＋全表 md5。
2. **作者点头门**：§M 呈报获 A 批准 ⇒ s323 起发；未批 ⇒ 停在 s322。
3. **T-2 s323**：DEFS 纯插两支（§A 逐字表＋§B 改名＋§F 两键＋§E-2 新数值）＋META_WEAPON_POOL_BASELINE 27→29 同 commit＋串 1 用 §I-1 转录形。完成判据＝validate 静态面 problems 增量=0（Godot 门停等期以只读刀代跑文本核）。
4. **T-2 s324**：DROP_POOL 行（§J 逐字无空格形）＋串 2 用 §K 形＋`_boss_weapon_drop()` 首行早退一条（floor==8→wd_cinnifuse，零 rng・零 hash 消费）。完成判据＝三处 diff 只含点名行。
5. **T-2 s325/s326**：改后快照第二格＋只读核四条（required 六项未动⇄knock/slow_on_hit/phase_boom 不在名单⇄DROP_POOL 不含 wd_cinnifuse⇄cinnifuse.explosive==0.0）。完成判据＝四条形全部 True。
6. **T-2 s327**：**作废为独立重登趟**（基线已在 s323 原子落）——改作「基线原子性取证趟」并入 s325 断言集执行，本趟号留档不发新刀（⛔ 自取新号）。
7. **T-3 s328→s329→s330→s331**：hitstop 声明/递减→game_main 行为步门控→slug 侧 variant=="boss" 减半＋压扁豁免＋knock_in＋player 侧 heavy 形参/长按阈值 0.30/ACTION_DEFS 第 19 键→assets 三别名注册＋`_swing_sfx` helper（放 `_swing` 定义行之前）。完成判据逐趟＝s330 后 `_swing` 切片内 `Game.fx_rng.randf` 子串计数=0；s331 后 `Assets.SFX.keys()` 含三新键；ACTION_DEFS 计数=19。
8. **T-3 s332/s333**：常量互等尺（4/6/3/5 四枚名见 §J）＋knock 缺省轨迹差分（同 seed）＋造错双臂还原 GREEN。
9. **T-4 s334→s335→s336→s337→s338→s339**：观测行（申报面先行）→三条纯验证（§C）→扫击余韵（不依 J 项，原单照跑）→combo 单一性/零 rng grep 尺→造错臂→回归。完成判据＝s335 三断言全 True 且 `combo += 1` 全仓恰 1 枚。
10. **T-5 s340/s341/s342**：验证口径续段吸收本件改判（至少五处：J3 纯验证形⇄J4 variant 正形⇄J5 定向新断言与反超账⇄J7 helper 位⇄J8 十九键与 0.30s 阈值）＋面尺三查＋汇总单形。
11. **T-6 s343/s344**：入账时台账行与 AGENTS 串 7 照原单；串 1/串 2 的转录格（§I-1/§K）在呈请件登记为「R99a 取代格」，⛔ 回填裁定件。
12. 附带甲/乙/丙（s345—s350）不受本件影响，执行序照原单（附带丙仍排 T-5 后）。

- 与实施单的冲突总表（本件取代格）：实施单 s324「落 game_main.gd BOSS_WEAPON 定向映射新增一格」→ **本件取代**为「BOSS_WEAPON 零改动＋`_boss_weapon_drop()` floor==8 早退」（§E）；实施单 s327「条件趟＝基线重登」→ **本件取代**为「并入 s323 原子落，s327 转取证/不发」；其余车次格语义不变。

## §N 自检记录（本件落盘后当趟复跑）

- 本件引用的每个 `文件:行号`/字段名均已当趟 `grep -n` 复核（两遍全量＋一遍定点）：`slug.gd:457/481/482/483`⇄`player.gd:128/251/651/667/676/682/689/730/768/804/812/901/2420`⇄`game_state.gd:22/107/653/998/1072/1077`⇄`game_main.gd:42/158/2475/2501/2537/2556/3124/3159/3865/3867/3876/3921/4766/4771/5769`⇄`weapons.gd:9/13/18/30/41/57/58/88/119/222/229/234/260/263/265/276/296/325`⇄`validate.gd:382/388/390/407/419/449/470/631—641`⇄`assets.gd:14/109/110/133/187/341/365`⇄`data.gd:336/341/347`⇄`bullet.gd:135/147`——全部在位；负锚复跑：`func _check_phases`=0 枚⇄`game_state.gd` 无 `_physics_process`⇄`slug/bullet/boss.gd` 无 `_process`⇄`heavy|重击` 剥注释全码底=0 枚⇄新标识符 `hitstop|knock_in|_swing_sfx|_phase_boom_check|_heavy_hold_t|slow_on_hit|phase_boom|melee_combo` 现读全仓 0 枚（均为本件授权的新名）。
- 与实稿 §2 F1—F25 无矛盾：本件只**补充**了 F 表未覆盖的一处事实（MG-PW1 作用域=整张 DEFS，实稿 F23 只记 27 id 本身），已按规程以 §J 更正格＋§M 呈报承载，⛔ 改写实稿。
- 哈希自证豁免（B-4）：本件不含自身 md5/字节数；入库证明由 T-2 首趟 commit 的「时次＝本枚落盘前现读」承载。

## §M-2 终态总裁（第二时次・2026-11-16 编程侧催办后追加；⛔ 回填 §M/§L/§J/§Z 原文，两时次并列 §B-3）

**本节取代 §M 末句「看完点头才能发 T-2 主格」与 §Z 第 2 步「作者点头门」的发车语义。** §M 那段呈报本身一字不动、留档照旧（append-only）。

### M2-1 总裁：选 A，即日发车，终态不含「等作者」

待作者①由本节改判为 **已登记・默认放行・作者保留否决权**。T-2 主格 s323—s327 按 §Z 第 3—6 步原样发车，⛔ 停在 s322 快照趟。若编程侧收到本节后仍把车卡在作者点头上，视同违反 §X 禁则，回主理人呈报而不是继续等。

### M2-2 裁据（三条，全部当趟现读坐实）

1. **红面不在本轮，代价账因此改变**：MG-PW1 断言实体在 `game_main.gd:2475` 的 `if OS.get_environment("SMOKE_META_POOLASSERT") != "":` 门内（消费行现读 :2488，Dev.check 现读 :2501—2503），且 `validate.gd` 对 `META_WEAPON_POOL_BASELINE` **零命中**（grep 全文件现算＝0）。R99 全程 ⛔ 起 Godot ⇒ 本轮任何离线机检跑不红这条；红面属于下一次能起 Godot 的轮次。§J 更正格说的「必红」是**运行时红**，不是**本轮闸红**——两者不等价，A 的真实代价比 §M 呈现的小。
2. **C（预告债）被既有工具否掉**：`_tools/spr38_baseline_verbatim_check.py`:12 有硬码 `EXPECT_N = 27`，正跑与造错臂都先过这道条数尺。基线留 27 而 DEFS 变 29 ⇒ 该常驻刀当场 FAIL（它抽的是代码里的列表体，见 :21），「债」藏不住且会把下一车的取证面搞成双头账；要取 C 就得连这把刀的 `EXPECT_N` 与 DOC 锚（:11 指 `SPR38_主理人核验_B1.md`）一起换代——侵入面反而大于基线加两行。
3. **D（gate 路）成本最高，拒**：让新武器「进 DEFS 不进池」须给它挂 gate——链为 `_meta_pool_ids("weapon")`（现读 game_main.gd:2556—2571）→ `Game.meta_content_unlocked`（game_state.gd:998）→ `Meta.content_available`（meta.gd:135—139，无 gate 即 true），而 gate 索引是从 `Meta.UNLOCKS` 带 kind+target 的节点反查建出来的（meta.gd:101—113 区段，其 :112 那枚 `_gate` 键拼装行在盘上现读坐实）⇒ 必须往元解锁树加购买节点，连带 `MIN_DEFAULT_USABLE`（meta.gd:90，validate.gd:767 读它）与图鉴/结晶账全动——方向级变更，不入本车。
4. 补充事实（支持原子同批）：两个新 id `ml_frostbite`⇄`wd_cinnifuse` 全仓 `scripts/` 现读 **0 枚**——不存在别的文档或探针把它们预登在 27 之外，重登只有本车一个时机。

### M2-3 基线重登可执行格（主理人登记形・T-2 s323 逐字转录）

落点＝`game_main.gd` 的 `const META_WEAPON_POOL_BASELINE := [`（现读 :42）列表体内、闭括号 `]`（现读 :51）**之前纯插两行**，既有条目字节零动。新块逐字如下（含制表符缩进一枚 `\t`，注释行在上、id 行在下）：

```
	# S41 R99a §M-2 主理人重登 +2（ml_frostbite⇄wd_cinnifuse・DEFS 成员资格≠获取途径，下行红字口径不变）
	"ml_frostbite", "wd_cinnifuse",
```

- **排列位置**：紧排 `"mw_cluster"` 之后、列表体末尾——与 DEFS 插入位（weapons.gd 现读 :268 附近）无关，因断言判**集合相等**（game_main.gd:2501—2503 现读，且 :41 注释明文「不依赖 DEFS 迭代序」），尾部追加是最小扰动形。
- **注释措辞归属写法**：上面那行 `S41 R99a §M-2 主理人重登` 就是「主理人登记」的凭证形——:42 块内既有红字（:39）已有「主理人已按…重登」先例，本行沿同一句式，并显式引本件节号，使 :2502 那句「基线变更须由主理人重新登记，不许就地改串」在文本层可对账。
- 🔴 **转录纪律**：编程侧⛔ 自定注释措辞、⛔ 换行位、⛔ 拆成两行 id——只能逐字转录本格（先例＝`_tools/AUTORUN_LEDGER.md`:48「只能逐字转录主理人给的」）。
- **同 commit 原子性**：DEFS 两枚＋本基线两枚必须同一枚 commit（§J 更正格的结论维持，本件只改它的**授权来源**：从「等作者点头」改为「主理人已登记」）。

### M2-4 随动三处（离线可执行，属 s323 同批）

1. `_tools/spr38_baseline_verbatim_check.py`:12 `EXPECT_N = 27` → `29`——**这是工具件不是 `scripts/`**，不触 34 枚冻结面；改动走该车只读刀之外的登记刀，证件里记「尺换代：27→29・出处＝本件 §M-2」。⛔ 不改该刀其它逻辑、⛔ 动 :11 的 DOC 锚指向。
2. DOC 侧同步：该刀从主理人核验件抽 id 比对（:26—:33 窗口法），故 s323 落码后须由主理人在**下一份核验件**里以 §三 同款格式登 29 条全串；本轮先在 T-6 呈请面挂一行「verbatim 刀的 DOC 面待主理人核验件接续」，⛔ 编程侧自填核验件。
3. E1 指纹不受影响：基线常量非打印串、MG-PW1 只在 env 门下运行，离线 validate 面 problems 增量应为 0——此格并入 s325 断言集复述一遍。

### M2-5 待作者①处置（落到具体文件・具体行的写法）

采「**主理人已登记，作者保留否决权（下一到场可撤）**」形，不采「判断栏挂着但默认放行」形（后者会让每件引用它的文档都要追改，违 append-only）。五处指针逐字如下，一律**同行尾追加**或**纯插末行**，⛔ 删改各件既有行：

| 文件 | 落点（当趟 grep -n 现读坐实） | 追加形（逐字） |
| --- | --- | --- |
| `SPR41_主理人裁定_R99_近战手感与武器内容总裁_s307s308换代自指坑处置qgate臂面派车_号段令全配.md` | :119 行尾 | `【R99a §M-2 终态：主理人已登记 27→29，作者保留否决权（下一到场可撤），不再停等点头】` |
| `SPR41_设计实稿_R99_近战手感与武器内容.md` | :189 行尾 | `【同上：R99a §M-2 已登记・默认放行・可撤】` |
| `SPR41_实施单_R99编程侧落地单.md` | :28 行尾 | `【本行「获批才执行」条件由 R99a §M-2 取代：主理人登记即生效，作者事后否决则回滚该 commit】` |
| `SPR41_实施单_R99编程侧落地单.md` | :86 行尾 | `【禁令主体仍在：⛔ 编程侧自定串内容；转录源＝R99a §M-3 格】` |
| `S41_台账.md` | 现读末行 :246 之后纯插一行（该行现算：换行符数=246⇄splitlines 数=246⇄CR 数=0，三数形照观察号戊处置） | `- **R99a §M-2 登记格（2026-11-16）**：待作者①＝元池基线 27→29 由主理人登记完毕（可执行格见补裁件 §M-3），T-2 s323 起照常发车；作者否决路径＝撤该行＋回滚 s323 commit＋两支撤出 DEFS，回到 §M 选项 B 并重裁。` |

- 撤销协议一句话备着（作者若回来否 A）：撤 = 单枚 revert commit 同时摘 DEFS 两枚与本基线两枚＋M2-4 第 1 条的尺回 27——三处同批，正好是它落下的镜像。

### M2-6 号段影响复述

**s322—s342 全部照 §J 原样，不挪号、不追加、不开新号**；§C-0 号段令原文继续有效，本件不转载不修订。附带甲/乙/丙 s345—s350 不变。本节自身不占 s 号（文档直写件，照 §J 末格先例）。

### M2-7 自检记录（本节落盘后当趟复跑）

- 本节引用的每个坐标均当趟现读二次复核：`game_main.gd:42/:51/:2475/:2488/:2501—2503/:2556—2571/:3124/:3159` ⇄ `game_state.gd:998/:1074` ⇄ `meta.gd:90/:101—113/:135—139` ⇄ `assets.gd:341` ⇄ `validate.gd:767` ⇄ `spr38_baseline_verbatim_check.py:11/:12/:21/:26—33` ⇄ `weapons.gd:9/:268` ⇄ `player.gd:651/:682/:689/:730/:812`——全部在位且与所引语句相符（逐条打印行内容比对，⛔ 只数命中数）。
- 编程侧四条实测我独立复验结果：①耦合真（DEFS 27 ⇄ BASE 27，集合相等成立）✅复验通过；②本轮跑不红（validate 对该常量 grep＝0）✅；③gate 链需 UNLOCKS 加节点 ✅；④J8 前提（ACTION_DEFS 现读 :341 起恰 18 枚、KEY_SHIFT 全仓仅 assets.gd 声明处 1 枚非占用形）✅，J3 `combo += 1` 恰 1 枚（game_state.gd:1074）✅，J4 `is_boss` scripts/ 全仓 0 枚✅——三项不用返工确认。
- 卫生：本节零格式化占位符（百分号接字母、花括号成对空位两形均 0 枚）、无奇数星号粗体对、无令牌字面；纯 LF；只追加，§0—§N 既有 218 行零改动。
## §O cinnifuse 数值订正总裁（第三时次・2026-11-16 编程侧复核抓到 §E-2 假不等式后追加；⛔ 回填 §A/§E/§I/§J/§Z 原文，两时次并列 §B-3）

### O-1 编程侧读数逐条复验（我独立现读，全部成立）

1. ✅ **反超闸作用域＝BOSS_WEAPON**：`func _check_boss_weapons()` 实在 validate.gd:419（:415—418 是文档注释，「419 起」无误）；循环行现读 :424 `for wid in own:`（own=`WeaponsScript.BOSS_WEAPON`，:421）。反超计数 :446—447、灰区句 :448—450、「恰好 2」句 :470 全在该循环体内。非归属武器不进循环——**与它 dmg/interval 取多少无关**。另现读补充一条编程侧未点名的同族闸：validate.gd:452—455 只对 `bw_` 前缀且未入 own 的 id 判红；`wd_cinnifuse` 非 bw_ 前缀 ⇒ 不入 BOSS_WEAPON 亦不触此闸。
2. ✅ **2.1818 ≤ dps_boss 为假**：三尊基准现算 0.6667/0.9091/0.7692（BOSS_PULSE_BASE data.gd:347—351），2.1818 大于全部三枚。§E-2 bullet① 的不等式盘上可证为假，据它推的「除非一步调到 ≤dps_boss」整段前提塌掉。
3. ✅ **surpass_note 同账**：函数实在 weapons.gd:296（:293—295 是文档注释，我原文写「294 起」偏一行）；守卫现读 :297 `if not BOSS_WEAPON.has(id): return ""`——不在表里恒出空串，bullet② 前半句「比值 ∈ (1.25, 3.27) ⇒ 小字句自然出现」为假，且与其后半句自相矛盾（后半句对）。
4. ✅ **下调零收益、赔死值式**：裁件 §C-8 校准式现读在裁定件 :94（`dmg = interval × 3.33`，容差 ±0.03，S36 §7.2）；2.4 vs 1.10×3.33=3.663 不闭合，原值 2.60/0.78 闭合（0.78×3.33=2.5974，差 0.0026）。validate 全文 grep `3.33`＝0 命中——该式无静态机检，但它是裁件白纸黑字的定价尺，偏离须另授权。
5. ✅ **三处指针漂移坐实**：`th_kunai` 的 `"life": 0.55` 实在 weapons.gd:257（:258 是 tint/icon 行）；`"wpn_fushe"` 实在 assets.gd:110（:109 是 `const GEN_NAMES := [`）；surpass_note 见第 3 条。

### O-2 总裁：**回归 2.60/0.78**

`wd_cinnifuse` 的 `dmg = 2.60`、`interval = 0.78`——即回到裁件 §C-8 原值，死值式闭合（2.60≈0.78×3.33，差 0.0026≤±0.03），无需任何偏离授权。裁据三条：

1. 反超豁免的真正来源是**归属表成员资格**（O-1 第 1 条），不是 dps 标量；不入 BOSS_WEAPON 这一条已把本把完全摘出反超与灰区两套账，下调买不到任何东西。
2. 「重而慢」的设计语义今天由 wd_whisper interval=0.90（weapons.gd:263 现读）承着——0.78 < 0.90 本就更快，「慢于低语法杖」从未成立过；这格代价面披露随 O-5 一并登记，属两时次并列，⛔ 为它保留一个无据数值。
3. 若将来出于平衡要压 wand 侧 dps，那是配平域的另裁，与本车的闸账无关，届时按新据走。

### O-3 进 weapons.gd 条目注释的逐字串（s323 唯一可转录文本）

落点＝DEFS 内 `wd_cinnifuse` 条目 dict 闭合行之前同行尾或独行注释均可（纯插，⛔ 动既有条目字节），内容逐字：

```
	# [S41-R99-E] 定向掉落走 floor==8 守关 Boss 房早退（R99a §E-4），不入 BOSS_WEAPON⇒validate 反超闸与图鉴 surpass_note 均只遍历归属表，本把天然不在其作用域内；dmg/interval 维持 §C-8 校准式闭合（0.78×3.33≈2.60）。
```

- 🔴 形制依据（防转录事故）：validate 的 `_swing` 切片闸只切 player.gd（validate.gd:382），weapons.gd 无源码级闸；且该行含 `//` 子串为零、不含任何 rng 调用子串——即便未来某闸扫注释也不撞既有负锚。
- **ml_frostbite 不受影响**：其 dmg/interval 1.95/0.585 本就按 §C-8 闭合（0.585×3.33≈1.948，差 0.002），且 melee 本就不进这两套账——该条目**无新增注释需求**，§I-1 串 1 其余部分照旧。

### O-4 §I-1 串 1 的取代格（append-only；串 1 原文留档不动，T-2 s323 一律用本形）

「[S41-R99-W] 近战增量两支：寒髓杵·霜枝（ml_frostbite・melee・knock=55・slow_on_hit={0.5,1.0}）⇄燃符匣（wd_cinnifuse・wand・phase_boom={3,42.0,0.6}・dmg=2.60/interval=0.78 按 §C-8 校准式闭合）。icon 别名复用（wpn_ml_cleaver⇄wpn_fushe，先例 mw_cluster）。⛔ 六弹道字段入 melee 项（[S38-A3]）⛔ knock/slow_on_hit/phase_boom 进 MELEE_FIELDS required。」

- 与原串 1 差异恰两处：数值段回原值；删去「让位反超闸⛔ 死值式」半句（其依据即本节作废的假不等式）。

### O-5 §E-2 作废范围与随动作废句

| 作废句 | 处置 |
| --- | --- |
| :98 bullet① 整句（「2.1818 ≤ 三尊各自 dps_boss…永不进反超计数、永不落灰区」） | **作废**——不等式为假；正确因果＝「不入 BOSS_WEAPON ⇒ 不进循环 ⇒ 与标量无关」。 |
| :96 末两句（「即便调 dps 也会落…灰区，除非一步调到 ≤dps_boss」） | **作废**——由假不等式推出；非归属把无论何值不落灰区。:96 前半（作用域引证、恰好 2 句、三线数值）属实保留。 |
| :99 bullet② 前半（「比值 ∈ (1.25, 3.27) ⇒ 小字句自然出现」及「刻意保留的余量」论） | **作废**——与同句后半自相矛盾；后半（surpass_note 只对归属成员出句、本把不误出小字）**属实保留**。 |
| :100 bullet③ 末段（偏离理由逐字句「⛔ 死值式让位…dps 2.1818 ≤ 三尊脉冲基准」）连同 :92 裁语中「同时下调 cinnifuse 数值到反超线下」半句 | **作废**——该逐字句⛔ 进生产码（盘上可证的假话）；:100 前半（interval 变钝对比、代价面陈述）随数值回归一并失效，:92 其余裁语（不入 BOSS_WEAPON／改道 floor 8／键名改语义／不立第四尊）全部有效。 |
| :49/:50/:94 的 2.4/1.10 表述 | 不改写原文，以 O-2/O-4 新形为准（两时次并列）。 |
| §I-1 串 1 | 由 O-4 取代格整体取代，转录源改指本节。 |

- 登记形（T-6 呈请面入账句，逐字）：「R99a §E-2 四条 bullet 中①③及②前半、§E 头裁语下调半句、§I-1 串 1 由同件 §O 订正（编程侧复核抓到假不等式）；append-only，⛔ 回填原文，转录一律以 §O-3/§O-4 形为准。」

### O-6 对 s325/s326 尺的影响：零改动

- 编程侧 s322 现算每组恰 2 枚（prism=[bw_prism_latch,bw_seam_light]・weapons.gd:277—278 现读）⇄pyro=[bw_clinkant_fang,bw_tide_gauge]⇄third=[bw_abyss_ledger,bw_half_beat]；线={0.8333,1.1364,0.9615}＝data.gd:347—351 × :341 R=1.25——与我 §E-1 所引逐项吻合。**「恰好 2」断言口径不变**：cinnifuse 不在 own 表内，2.60/0.78 也好 2.4/1.10 也好，per_surpass 三组计数都不动。
- s326 只读核四条一字不动（required 六项⇄knock/slow_on_hit/phase_boom 不在 extra_outside 名单⇄DROP_POOL 不含 wd_cinnifuse⇄cinnifuse.explosive==0.0）；§E-6 V-C9 补充断言照旧。**不需为反超/灰区新增任何断言**——原拟「为有灾祸态新项加断言」那类顾虑在本把不存在，因为它根本不进那个循环体。
- D3 冻结串采集态（`_calamity=""`）与本节无关，不复述。

### O-7 指针订正格（两时次并列，⛔ 回填原表）

| 出处 | 原写 | 现读正形 |
| --- | --- | --- |
| §A-2 life 行（:57） | th_kunai life 在 weapons.gd:258 | **weapons.gd:257**（:258 是 tint/icon 行） |
| §A-2 icon 行（:61） | GEN_NAMES 登记行 assets.gd:110 | **assets.gd:110** ✅复核无误（:109 是 const 声明行，两数并记更稳） |
| §E-2 bullet②（:99） | surpass_note weapons.gd:294 起 | **weapons.gd:296 起**（:293—295 是文档注释） |
| §N 自检行（:216） | 负锚清单含 weapons.gd:296 | 该行系**区间列表**（:260/263/265/276/296/325），296 恰落在函数定义行上，无需改；引用纪律照 §0 尾注不变。 |

### O-8 执行序随动（最小 delta，⛔ 改 §Z 原文）

- §Z 第 3 步「§E-2 新数值」→ 按 **O-2 原值 2.60/0.78** 落，注释用 **O-3**，串 1 用 **O-4**；其余步骤（基线原子同批⇄s324 早退⇄s325/s326 断言集）一字不动。
- 卫生自检（本节落盘后当趟）：本节所有文件:行号均当趟 grep -n／Read 二次坐实；零格式化占位（百分号接字母仅出现在逐字转录的 problems 句引用之外——本节正文 0 枚）、无奇数星号对、纯 LF、只追加，§0—§M-2 既有 277 行零改动；不占 s 号。
