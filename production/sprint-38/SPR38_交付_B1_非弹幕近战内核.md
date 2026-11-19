# SPR38 交付 · B1 非弹幕近战内核（编程侧）

批次：Sprint 38 B1（机制先行）
日期：2026-11-18
配套：`SPR38_设计实稿_非弹幕武器形态族.md`（实稿）、`SPR38_验证口径.md`（口径，§ 引用指该文件）、`SPR38_实施单_编程侧.md`
主线：T-K → T-M → T-N → T-O（**全部完成**；B2a 架式窗口守卫另见前轮交付）
不做（按作者已裁／红线）：T-P1 补帧换图、T-P2 rifle `interval`、T-D 图鉴第七类、B3 投放、T-Q

> 本文只报**实测数**。所有数取自盘上日志（`_tools/spr38_*.log`），命令在 §三。
> 🔴 编程侧未刷任何冻结串、未 commit、未 push；MG-PW1 的新串照原样抄回，⛔ 不自改。

---

## 一、改动清单（文件 : 行）

| 文件 | 位置 | 内容 |
|---|---|---|
| `scripts/weapons.gd` | `:13` `:27` | `MELEE_FIELDS`（形态必填字段单一真源）＋ `is_melee_kind()`；校验与分派共用，⛔ 字段名散写在 if 里 |
| `scripts/weapons.gd` | `:222-268` | 六条新 DEFS（`ml_cleaver/ml_needler/sp_thorn/sh_bulwark/th_kunai/wd_whisper`），`kind` 齐；`DROP_POOL` 一行未改 |
| `scripts/player.gd` | `:688-737` | `_swing()` 命中内核：极坐标扇形（`angle_difference` 防 ±180° 环绕）、恒 1 次 `Game.rng.randf()`、乘区同弹幕侧、`from_dir`＝玩家→敌人、spear 旁路标志同栈内置位清零、`shieldbash` 减速、暴击共振走 `explode()` |
| `scripts/player.gd` | `:740-753` | `_start_reload()` 复位归属在**起手时**钉 `wid`（旧写法在回调里取 `cur_weapon()`，过载中切枪会灌错武器） |
| `scripts/validate.gd` | `:56` `_check_weapon_kinds()` | A1 机检：每条 DEFS 必须有 `kind`；真·非弹幕三形态字段／范围齐；规格外字段点名 |
| `scripts/assets.gd` | `:131-133` | T-M M4 六枚图标登记行（照 `_tools/spr38_icons.py` 打印粘贴，⛔ 手抄） |
| `scripts/game_main.gd` | `:276` | `SMOKE_MELEE=1` → `call_deferred("_smoke_melee_probe")`（异步段要真等物理帧） |
| `scripts/game_main.gd` | `:4637-4736` | K3 两档tier 探针 `_melee_tier_probe()`／`_melee_probe_swing()`（`SMOKE_META_RNGCOUNT` 入口） |
| `scripts/game_main.gd` | `:4727-5115` | **本轮主体**：`_smoke_melee_probe()` ＋ 8 个 helper，87 条断言 |
| `_tools/spr38_icons.py` | 新 | 六枚 16×16 RGBA8 程序化绘制＋IHDR 逐字段回读＋两两像素差＋接触表 |
| `_tools/spr38_mut.py` `_tools/spr38_knife.sh` | 新 | 七把变异刀（锚点命中数≠1 拒绝落盘；逐刀还原并校 md5） |

---

## 二、门禁七件套（口径 V-H）实测

| # | 判据 | 实测 | 日志 |
|---|---|---|---|
| 1 | `validate problems=0` | **0**（8 份日志逐一均为 `validate problems=0`） | 全部 |
| 2 | 探针 `done checked=N declared=N` | 近战 **94/94**；圣所 **19/19**；架式 **7/7**（`SMOKE_STANCE`）；META 族不用 checked 口径，其自证是覆盖行 `[S38-K1] DEFS=27 段A(弹幕)=23 其中带行为位=6 段B(近战)=4 未分派=0`（23+4=27 ✓）与 `[S38-A1] DEFS 27 条 kind 全覆盖 · 真·非弹幕 4 条（字段/范围查 0 条规格外字段）` | `spr38_melee.log` `spr38_sc.log` `spr38_apply.log` |
| 3 | `[ERR]`=0 | **0**（改后树 11-18 复跑 9 份：base／melee／stance／apply／rng／sc／pw／fp×3）。`pw` 的 `[ERR]` 已由 **1 → 0**：主理人核验 §三 重登的 27 条武器段基线串逐字转录进 `META_WEAPON_POOL_BASELINE`，MG-PW1 不再是预期红 | 同名 |
| 4 | `ok=false`=0 | **0**（同上，`spr38_pw.log` 另计） | 同上 |
| 5 | **E4 三指纹逐字不漂移** | seed 12345／777／42 三行 `fingerprint floor=1 rooms=… kinds=…` 与 `production/sprint-32/SPR32_验证口径.md`:144-146 基线**逐字全等**（机检 `spr38_fp_vs_5_4.py`：`VERDICT=ALL_MATCH`、三档 `hits=1`、rooms/kinds 分段 71/69、88/83、91/87 字节；同件 `--falsify` 三档全 DIFFER ⇒ 有牙。⚠️ 旧措辞"两侧各 495 字节"是整行长度口径，11-17 起⛔ 再引用）。改后树 22:33–22:39 单窗口串行重跑仍全等——⚠️ 按主理人裁定只作「随机流等价」附注，⛔ 代偿 churn（§八） | `spr38_fp_*.log` |
| 6 | churn 只比断言行 | 🔴 **FAILED（主理人 11-18 终局裁定：本批 churn＝不可测，`git worktree` 路线作废）**。实测依据：`git log -1`＝`4dafdaf`（停在 S32），`git status --short`＝**80** 个未提交路径，`git show HEAD:scripts/game_main.gd` 里 `SMOKE_MELEE`／`SMOKE_APPLY`／`MG_PW1` 均 **0** 命中 ⇒ HEAD 树里本批探针根本不存在，基线侧 `done` 行永不出现，C-a 差集会混进 S33–S37 六批内容；`_tools/`、`_backup/` 又被 `.gitignore`:6-7 排除，`_backup/spr38_final/scripts/game_main.gd:4737` 是 `_ML_DECLARED := 87`（B1 途中件）也不可用。⇒ 改用主理人指定的三条零 Godot 替代断言面 C-a′／C-b′／C-c′，实测见 §八。**🔴 R5 补记（核验件 §十三.5）**：§六b 的 (c) 快照合成基线树已由并发轮**实跑证伪**——`wt_spr38_base` 十份日志全数 `SCRIPT ERROR`（唯一签名 `_melee_pierce_armor` on `Slug.take_damage (slug.gd:452)`），根因＝`_backup/spr38_final/scripts/slug.gd` md5 与现树逐字节同、本身已含 B1 期代码 ⇒ **盘上不存在自洽的 B1 改前树，(c) 结构性不可行，终局＝FAILED/N-A，不留重建钩子**。另更正：§六b fallback 的 B1 触碰面成员写错——`grep -l 'S38' scripts/*.gd` 实测五件＝game_main／player／slug／validate／weapons（⛔ assets：`grep -c 'S38' scripts/assets.gd`=0，其 +8 行属 S33–S37 图标登记）。重启 churn 的唯一前提＝作者点单的 commit 锚点。 | `spr38_base.log` `spr38_g_*.log` `churn_base/*.log` |
| 7 | 冻结状态如实报 | `md5sum -c SPR21-FROZEN.md5` = **34 OK / 0 FAILED**（11-18 改后树复跑同数）；FAILED 名单：（重登后无 FAILED）。⛔ 编程侧不自刷，收官由主理人统一刷 | — |
| 8 | 每份刀日志三查：`SCRIPT ERROR`=0 **且** `done checked=declared` 在 **且** 该刀预期红项在 | 十份全过：`SCRIPT ERROR`=**0**×10、`done checked=94 declared=94`×10、预期红项逐刀存在（红表见 §七）。⚠️ 按主理人 R4 收窄：`validate problems>0` **不是**静态类刀的必备特征——同行内联抽取消 M10 `problems=0`（静态门没抓到），删／加抽取的 M1／M2 反而 `problems=1`。这句与 §二 原预期相反，已回主理人改口径措辞 | `spr38_k1..k10.log` |
| 9 | 命令清单固定含 `SMOKE_STANCE=1` 与 `SMOKE_MELEE=1`；`declared` 按展开后实数计 | `_tools/spr38_gates.sh` 固定清单第 2、3 条就是这两把 env（base／melee／stance／apply／rng／sc／pw ＋ fp×3，无遗漏跑）；`_ML_DECLARED=94` ＝ 标签行集计数 94 ＝ 日志普查 94（`spr38_clause_sum.py` 机比） | 同上 |
| 10 | 近战动作基线串逐字 `done checked=94 declared=94 swings_total=57 draws_total=57` | 改后树实测**逐字命中**；已编进 `_tools/spr38_gates.sh` 末段 `VH10`。反证两把：把该行改成 `34/34`（正是刀 9 的形态）或 `57/58` ⇒ 均见红、退出码 1。⚠️ 主理人点明的盲区照抄：计数器**相等 ≠ 对**，M9 下 `34/34` 相等、M10 下 `57/57` 相等 ⇒ 本条只是必要条件，承重仍在 #44/#45/#46/#47/#48 的 state 神谕 | `spr38_g_melee.log` |

复现命令（每条前都清了隔离档 `…/app_userdata/test_1/_smoke_*.cfg*`，`--quit-after 3200`；11-18 改后树那一轮走 `bash _tools/spr38_gates.sh`，帧数与全部实测数见 §十／§八）：

```bash
SMOKE=1 SMOKE_SEED=12345 SMOKE_MELEE=1            "$GODOT" --headless --path . --quit-after 3200
SMOKE=1 SMOKE_SEED=12345 SMOKE_META_APPLY=1       "$GODOT" …   # [S38-K1] 覆盖行
SMOKE=1 SMOKE_SEED=12345 SMOKE_META_RNGCOUNT=1    "$GODOT" …   # K3 两档
SMOKE=1 SMOKE_SEED={12345,777,42} SMOKE_META_FINGERPRINT=1 "$GODOT" …
SMOKE=1 SMOKE_SEED=12345 SMOKE_S32_SHRINE=1       "$GODOT" …   # E6
SMOKE=1 SMOKE_SEED=12345 SMOKE_META_POOLASSERT=1  "$GODOT" …   # E7／MG-PW1
bash _tools/spr38_knife.sh                        # 十刀（QA= 可调帧；开刀前校基线守卫）
```

---

## 三、SMOKE_MELEE：94 条断言的条款对号（改后树 `done checked=94 declared=94`）

观测手段＝口径 V-B 说的那个「摆位工具」：`_ml_place(变体, r, Δθ, 朝向)` 把一只静止靶放到相对玩家的极坐标，`_aim` 钉世界角 0°，同步挥一击，**取 `hp` 差额**作伤害读数。
🔴 三条观测纪律（写进探针头注释）：①伤害 ⛔ 取 `Game.damage_number` 文本（那条走 `str(int(amount))`，0.54／0.6 会被截成同一个数，V-B6／V-D3 的账就废了）；②每次挥击前把 `Game.rng.state` 钉回 `_ML_STATE0=20261118`，否则 Δstate 跨摆位不可比；③靶一律 `speed=0 / dmg=0 / hp=1e9` 且几何段**同步**挥——AI 每物理帧覆写 `_face`，V-B6／V-B7 要的正是"我指定的朝向"。

| 条款 | 断言 | 关键 measured |
|---|---|---|
| V-A3 | 6 条：三把真·非弹幕的表值逐字 ＋ 规格外字段 | `[1.8, 46.0, 110.0, 0.55, 4.0, 0.9]`／`[2.4, 78.0, 42.0, 0.72, 3.0, 1.1]`／`[1.2, 34.0, 150.0, 0.9, 3.0, 1.3]`，规格外字段 **0 条** |
| A3x（新增） | 1 条：第 4 条 `melee`＝`ml_needler` **在场**（⛔ 探针不钉它的数值，配平域未裁） | `in DEFS=True`；A3 那三把表值仍逐字对账 |
| V-A2 | 1 条：全程子弹节点数 | `0`（近战一次子弹都没生成过） |
| V-B1/B2 | 5＋1 条：B1 `#14` r40 Δ0 恰一次全额、`#15/#16` Δ±50 命中、`#17/#18` Δ±60 不命中（半角 55）；B2 `#19` r52 超 reach 不命中 | `1.8 / 1.8 / 1.8 / 0 / 0`＋`0` |
| V-B3 | 3 条：同扇三只各吃全额 | `1.8 1.8 1.8` |
| V-B4 | 5 条：荆刺 r70 Δ±15 中／Δ±25 不中 ＋ 同距命中数比较 | `2.4 2.4 0 0`；比较靶 `1<=3`（⛔ 首版我把比较距离写在 r=70，阔刃 reach=46 必然 0 命中，测成 `1<=0`——那是探针自己的错，已改到 r40／Δ±30） |
| V-B5 | 3 条：命中者 `0.6`／`1.2s`、未命中者不受影响 | `0.6 / 1.2 / 1.0,0.0` |
| V-B6 | 2 条：盾骑士正面＝`dmg×(1-0.7)`、绕背全额 | `0.54`／`1.80` |
| V-B7 | 3 条：荆刺正面捅盾骑士全额、标志结算末已清零、**紧接一次子弹路径 `take_damage` 仍按 armor 减伤** | `2.40 / false / 0.30` |
| V-B8 | 3 条：空场挥击仍算一次动作、`kills` 不变、组内 `dead==true` 不命中 | `1/1 / 0 / hp 不变` |
| V-B9 | 4 条：木箱挨三刀 `hp=3` 不变＋**反证**它确在 `crates` 组、暗墙挨三刀 `hp=1` 未开、`_swing` 源码段（39 行）内无 `crates/secret_walls/bomb_hit` 入口 | 全绿 |
| V-C1 | 4 条：第 4 发进 0.9s 过载、第 5 次输入不结算、期间配额不动、**不重置计时** | `0.9 / 0.0 / 0 / 0.9` |
| V-C2 | 3＋4 条：0.9s 后自动回满；**边界态**过载中切枪 ⇒ 切枪优先、复位落在起手那把（cleaver 回 4）、切过去的 thorn 不被误灌（仍 3） | `4`／`sp_thorn/0.00`／`4`／`3` |
| V-C2c（新增，3 条） | **换弹代数令牌 `_reload_gen`**：起手换弹后捡新武器 ⇒ 旧 pending 复位不得灌到新武器上；前提守卫＝阔刃配额见底且复位确已在飞（令牌已发）；反证＝`give_weapon` 确实执行且配额系统没坏 | #84 `0/true`、#85 `measured=0`（刀 8 砍掉守卫后 #85 变 `4`） |
| V-C3 | 2 条：`mag_cap_mult=0.5` 下阔刃配额 `floor(4×0.5)=2`、恢复后回 4（⛔ 为近战开形态豁免） | `2 / 4` |
| V-C4 | 3 条：`#87` Q 切换 `_swap_t=0.25`、`#88` 切换窗（`_swap_t>0`）内不许挥、`#76` 双槽满捡新武器替换当前槽（`#89` 挂 E3／C4 双标签，计入 V-E3 行） | `0.25 / 0`、`sh_bulwark/sp_thorn` |
| V-D1 | 3 条：`damage_mult`／`bullet_dmg_mult` 同步放大、**`bullet_scale` 不参与** | `2.70 / 2.70 / 1.80` |
| V-D2 | 3 条：`crit=0` 永不暴、`crit=1` 必暴 ×2.0、暴击与否不改抽取数 | `1.80 / 3.60 / 1/1` |
| V-D3 | 3 条：暴击目标＝全额＋自家爆炸、扇外第二只吃 `0.6×衰减0.8`、非暴击无爆炸 | `5.76 / 1.728 / 0.0`（爆炸走 `explode()`，不是自造 AoE） |
| V-D4 | 6＋6＋1 条：`chain/poison/set_fire/frost/bounce/pierce` 挂上后近战总伤不变；**反向**＝bullet.gd 六个钩子源码各恰 1 处 ＋ 淬毒真跑一条仍生效 | 全 `1.80`；`measured=1 expect=1` ×6；弹幕侧 `_poison_t=3.0` |
| V-D5（新增，3 条） | 近战挥击不喂主动遗物：同帧数对照组里四键冷却差逐键相等，另两道上限反证证明时钟确实在跑 | `_ml_relic_decay(true)` vs `(false)` 四键 Δ 全等；`d_shield>0`、`orbit=True` |
| V-E1/E2/E5 | 2＋2＋1 条：E1 `#44` 全程 `draws==swings` ＋ `#48` 200 次输入（含 196 次过载无效）后 state 与独立复算逐字一致；E2 `#45`/`#46` 命中 1 个、命中 5 个与命中 0 个的 Δstate **逐字相同**；E5 `#47` 过载期无效输入不增计数 | `25/25` 与 `-2585114045049353277`、`5922163526861011269` 两档同值、`4/4` |
| V-E3 | 2 条：`#89` 切换完成后 autopilot 确实挥出近战（分派真走了 `_swing`）＋ `#90` 全程计数相等 | `true`／`53/53`（`swings_total` 基线 52→57 后该计数器同抬，见 §九 偏差 3） |
| V-E7／HP-6 | 6 条：六把新 id **都不在 `DROP_POOL`** ⇒ B1 阶段零获取途径，取模分母不变 | 全 `false` |
| 自校验 | `checked == declared` | `94 == 94`（标签行集计数亦＝94） |

**读数口径**：本机是单精度 `real_t`，`1.8` 落盘是 `1.79999995231628`，故全部浮点对比走 `_ml_close(±0.001)`，⛔ 逐字比浮点。

---

## 四、探针自己的四个错（都是实测逼出来的，已钉进注释）

1. **乘区不是 1.0**：烟雾台架在 `SMOKE=1` 时把 `bullet_dmg_mult` 拍到 **10.0**（`game_main.gd:240`），首轮 8 条绝对伤害断言因此红成 18.0／5.4。⇒ `_ml_equip` 一律把 `damage_mult/bullet_dmg_mult/mag_bonus/mag_cap_mult/skill_t/crit_*` 钉回基准，要倍率的用 `_ml_shot(…, mods)` 在装备**之后**施加；`stats0` 打印行留了对账原值。
2. **异步段必须关自动驾驶**：`auto=true` 下 await 的几十帧里玩家自己开枪把配额吃光，`C2b thorn 仍是 3` 测成 0——**伪装成"复位灌错了武器"这个它正要抓的 bug**。⇒ 异步段先 `autopilot=false`，E3 要的那段再单独打开。
3. **V-B4 比较距离写错**（见上表）：跨 reach 的比较不是设计断言。
4. **恒真判据要自己拆**：V-E1b 两档比对首版拿整行相等当判据，而整行里带 tier 标签 ⇒ 恒假、第一轮就红（这条红正好证明门有牙）；改成只比 tag-free body。B9 同理补了"靶确在组内"与"`_swing` 源码无破坏入口"两道反证。

---

## 五、请主理人处置（编程侧不自行裁定，也不停工：可即刻开工的都已开工）

| # | 事项 | 实测／现状 | 我要的结论 |
|---|---|---|---|
| **1** | **MG-PW1（GUARD-3）新串** | `SMOKE_META_POOLASSERT=1` 实测：`缺 [] 多 [bw_prism_latch, bw_seam_light, bw_core_hammer, bw_sixfold_ring, bw_quiet_gauge, bw_tide_gauge, bw_clinkant_fang, bw_slack_half, bw_cinder_rake, bw_red_dial, bw_abyss_ledger, bw_half_beat, bw_black_silt, bw_third_key, ml_cleaver, ml_needler, sp_thorn, sh_bulwark, th_kunai, wd_whisper]`＝**20 把**（S36 的 14 把专武＋本批 6 把近战）。⚠️ 前 14 把我上一轮交回时就在，说明这条**不是本批新坏**，是基线串自 S36 起就没重登。`pool assert=OK pool=14` | **已落**：主理人核验 §三 的 27 条武器段串逐字转录进 `META_WEAPON_POOL_BASELINE`；11-18 复跑 `pw` 门 `[ERR]` **1→0**、`okfalse=0`、`validate problems=0` |
| **2** | **口径 V-A3 只钉了三把的表值，盘上 `melee` 有两条** | `ml_needler`（`dmg 0.65 / interval 0.26 / reach 34 / arc 60 / mag 7 / reload 0.8`）是第 4 条 melee，实稿 §3.8 未钉它的数值 | 认可这组配平值，或给新钉值。另：三把近战的 `dmg` 实稿都**没钉**，我按 `dmg = interval × 步枪 dps(3.33)` 反推（1.80／2.40／1.20）——这条也请一并裁 |
| **3** | **V-D5（主动遗物四键与近战无关）本探针未覆盖** | 遗物走 F/Z/X/C 输入层，`SMOKE_MELEE` 不注输入；我只覆盖了 V-D5 的另一半（`orb_shield` 不因盾武器存在而被削弱——装备 `sh_bulwark` 后主动遗物字段无分支） | 认下"V-D5 另立一条输入层门"或指定并入既有遗物探针；**已落**（主理人 §十一 D5，手法偏差见 §九 偏差 1）|
| **4** | **V-H #6 churn 无改前基线日志** | `_tools/` 里没有 B1 之前的同 seed 日志可比对；本轮以 E4 三指纹**逐字**比对代偿（口径 V-E4 的最强形式），但那是随机流等价、不是断言行 churn | 要么认可"本批以 E4 代偿 churn"，要么给一份改前基线日志的位置（`git stash` 之类会动工作树，我不擅自做）⇒ **已裁（主理人 11-18 终局）：churn＝不可测，V-H #6 记 FAILED，E4 只作附注、⛔ 代偿；commit 锚点等作者点单**，全文见 §八 |

---

## 六、本批状态一览（给收官用）

- **B1 机制**：T-K／T-M／T-N／T-O 全绿，94 条断言 ＋ 十刀见红（红表见 §七）；V-H #6 churn 按裁定记 FAILED（§八）。
  - **取证口径（11-17 22:4x 补）**：本件 §二／§三／§七 的数在 **22:33–22:39 单窗口串行重跑**里逐格复现（`_tools/spr38_A12_gates.log`／`_tools/spr38_A12_knife.log`／`.spr38_A12.done`；起跑前 `spr38_preflight.sh` 判 ok、全程持运行锁），由另一窗口只读重算核对一致（`ok_false`＝4/1/1/2/4/2/2/1/7/3、`#48` 红集合＝{k1,k2,k5,k9,k10}、10/10 门禁四项全 0、`done checked=94 declared=94 swings_total=57 draws_total=57`、冻结在树回绿后重取＝34 OK／0 FAILED）。⚠️ **22:21–22:25 那批 15 份日志作废**（两个值守窗口并发跑 Godot、共用同一 `_smoke_*.cfg`）。§八 的 C-b′／C-c′ 是零 Godot 静态面（磁盘常量与日志目录互比），不随重跑变；C-a′ 在新 melee 日志上重跑仍 `rc=0`、94＝94＝94。
- **B2a 代码侧**：前轮已交（架式窗口守卫，G2 的"未完不切走"＋时长对齐，对着 Q4 实测语义而非推断）。
- **B2b 美术侧**：G1 仍是复制件 ⇒ 挂 T-P1（换玩家图集撞 AGENTS §9.3 硬指标，已由作者裁"本批不动帧"）；G2c 登记 T-P2 不动手。
- **B3 投放**：未做（HP-6 的"零获取途径"已用 6 条断言钉住；投放另立 V-F 全套）。

---

## 七、变异刀十把 · 红表（对口径 V-E8；11-18 全量复跑）

驱动：`bash _tools/spr38_knife.sh`（`SMOKE=1 SMOKE_SEED=12345 SMOKE_MELEE=1 … --quit-after ${QA:-1600}`，逐刀还原并校 md5；十份 `_tools/spr38_k<N>.log`）。
锚点卫生：`_tools/spr38_mut.py` 每刀＝**整串唯一锚点**替换，命中数≠1 直接 `ANCHOR-FAIL` 且不落盘 ⇒ ⛔"刀没砍进去"伪装成"判据通过"。本轮**十把全部落刀成功**（无 ANCHOR-FAIL／无 APPLY-FAIL），十份日志 `SCRIPT ERROR` 全 **0**（V-H #8），十份都跑到 `done checked=94 declared=94`（V-H #9 探针自校验未截断），跑完 `player.gd` 回到绿件 `df57d7dd4a86ef10b1e09a1f9e049d68`（**当时快照·旧基线期，已作废**；现绿件 `dc622351a75e8da9d943d72332ec2a28`，R7 §15.2 拆两条后换号，真源＝实读 `_tools/spr38_good_player.bak`）。
🔴 **刀号真源＝磁盘 `_tools/spr38_mut.py` 的 1–10**（主理人口径写作 M1–M10，二者一一对应）。主理人核验件 §二 实验期私有标签按其 §（永久锁定映射）转录：K8＝**本表刀 9**、K10＝**本表刀 10**；K9b（`… if true else false`，静态门 parse 期拦住）与 K9(废)（`if true:` 包一层 ⇒ Parse Error＝死构建假绿）**不登记为新刀**，只作「死构建反例」留在文档里，逼出 V-H #8 的三查。

🔴 **开刀前拦下的一次工具事故**（不是判据红，是套件自己的洞）：`_tools/spr38_good_player.bak` 停在主理人 `before.md5` 那一版（`80fd3fb1…`，`_reload_gen` 命中 **0**），而盘上 `player.gd` 已带本批修复（旧基线 `df57d7dd…`〔已作废，现绿件 `dc622351a75e8da9d943d72332ec2a28`〕，当时命中 **6**）。若直接开跑，**第一刀跑完的还原步骤就会把这条修复从盘上静默抹掉**，且按新代码找锚点的刀 8 必然 APPLY-FAIL。⇒ 绿基线已重铺成当前绿件（旧件在 `_backup/spr38_final/scripts/player.gd` 仍有存档，零丢失），并给 `spr38_knife.sh` 加了**开刀前基线守卫**：`md5($GOOD) != md5(scripts/player.gd)` ⇒ 停机不砍。

| 刀 | 砍在哪 | ok_false | validate problems | 变红的断言（编号＝改后树探针序号） |
|---|---|---|---|---|
| 1 | 零抽取：`var crit := Game.rng.randf() < crit_chance` → `false`（删掉 HP-2 那次抽取） | **4** | **1** | #48 E1 state 与复算不一致（`measured=20261118`＝`_ML_STATE0`，抽取一次没发生）、#53 D2 `crit=1` 不暴（1.8 vs 3.6）、#55/#56 D3 整条爆炸消失（1.8 vs 5.76／0.0 vs 1.728） |
| 2 | 多抽一次：抽取后另起一行 `Game.rng.randf()` | **1** | **1** | 只咬 #48（`measured=4037560458653957451`） |
| 3 | HP-4 `from_dir` 写废：`take_damage(dmg, to_e.normalized(), …)` → `Vector2.ZERO` | **1** | 0 | #31 B6 盾骑士正面吃到全额（1.8 vs 0.54） |
| 4 | 旁路标志不清零：`_melee_pierce_armor = false` → `pass` | **2** | 0 | #34 B7 标志已清零（`true` vs `false`）、#35 B7 紧接下一次子弹路径不再减甲（1.0 vs 0.3）＝跨帧泄漏 |
| 5 | 过载仍算动作：配额见底的早退改成 `if false` | **4**（R5 订正，旧记 3；原表漏登的 #47 已在列） | 0 | #47 E5（`200/200` vs `4/4`）、**#48 E1 state 与复算不一致（`measured=-4222757136798409013` vs `-2585114045049353277`＝神谕自钉 4 次、实现抽了 200 次）**、#71 C1 第 5 次输入仍结算（1.8 vs 0.0）、#72 C1 过载期间配额继续掉（-2 vs -1）。全程 `swings_total` **57 → 255** |
| 6 | 只打最近一只：`for e in …get_nodes_in_group("enemies")` → `.slice(0, 1)` | **2** | 0 | #21/#22 B3 第 2、3 只吃 0 伤（近战退化成 spear 语义） |
| 7 | 爆炸系数 0.6→1.0 | **2** | 0 | #55 `7.2` vs `5.76`、#56 `2.88` vs `1.728`（证明 V-D3 测的是**系数**不是"有没有爆炸"） |
| 8 | **本批修复自己的反证**：换弹回调守卫 `if dead or gen != _reload_gen:` → `if dead:`（代数令牌失效） | **1** | 0 | #85 C2c 捡武器后旧 pending 复位不生效（`measured=4` vs `expect=0`＝旧回调真的把新武器的弹灌满了） |
| 9 | **空场早退**：`_swing` 先用正典几何扫扇内有无敌人，没有就 `return`（"看起来更省"的那类改动） | **7**（R5 订正，旧记 6） | 0 | #36 B8 空场挥击不算动作（`0/0` vs `1/1`）、#45/#46 E2 Δstate 漂移（`5922163526861011269` vs `20261118`）、#47 E5（`0/0` vs `4/4`）、**#48 E1（`measured=20261118`＝一次没抽 vs `-2585114045049353277`）**、#84/#85 C2c 前提守卫连带崩。⚠️ 该行日志仍写 **`swings_total=34 draws_total=34`——相等** |
| 10 | **抽取挪进条件式**：`(Game.rng.randf() < crit_chance) if not 敌组为空 else false`（`randf` 不在函数体顶层） | **3** | **0** | #45/#46 E2（`5922163526861011269` vs `20261118`）、#48 E1（`20261118` vs `-2585114045049353277`＝无敌人时一次都没抽）。⚠️ **`swings_total=57 draws_total=57` 依旧相等** |

**这把套件最有价值的三条负结果（如实报，别只报"十刀全红"）：**

1. 🔴 **计数器在刀 1／2／9／10 下全程恒绿。** `melee_rng_draws += 1` 记的是"我以为我抽了"，不是"随机流真的前进了"。⇒ 口径 HP-2 说"恒消耗 1 次"**不能**用 `swings==draws` 作证；V-E1a 这类计数断言只能算**前提守卫型**（AGENTS §5 分类）。🔴 **R5 订正（本条原句与改前事实不符）**：原文把 #48 直接称作「真正有牙的绝对值神谕」——**改前它并没有牙**：复算次数取自 `Player.melee_swings` 的增量（实现自报数），对**刀 5／刀 9 两把漏抓**（刀 9 的 pre 日志实测 `#48 … ok=true` 两侧同值＝同源自比较恒过；刀 5 盘上无 pre 日志，源码级同罪、运行时反证记 UNEXECUTED）。按口径 V-E1 R5 措辞改成探针自钉次数后，#48 才是绝对值神谕并新咬住这两把（十刀表见 §十一）。**新的永久教训：神谕写法本身可以假绿——"固定起点＋已知次数＋独立复算"三件里任何一件来源不独立，gate 就长期自证。** 改前七刀只有刀 1、2 命中这个盲区，本轮新增的刀 9、10 把它**再证了一遍**——尤其刀 10 的形态正是"抽取次数随分支变化"，是 HP-2 要防的那一类。
2. 🔴 **V-H #8 里"静态门类刀预期 `validate problems>0`"这条预期与实测相反。** 把 `randf` 挪出函数体顶层的刀 10 `problems=0`（静态门没抓到），反倒是删／加抽取的刀 1、2 报 `problems=1`（静态门另有判据命中）。十份日志的 `problems` 已按刀逐列排进上表。⇒ 请主理人改口径措辞：⛔ 把 `problems>0` 当静态类刀的必备特征；不可让的那条是 `SCRIPT ERROR`=0（十份全 0 ✓）。
3. **V-B7 对刀 3 不敏感**（`from_dir` 恒零时"正面荆刺全额"恰好仍是全额），它靠刀 4 才自证；V-D1 的两条倍率、V-E7 六条、A3x、D5 三条**没有专刀**，属"表值／常量断言"，其有效性由 §三 的 measured 原值对账而非变异保证 ⇒ 请主理人记进口径的"未由变异覆盖"清单。

---

## 八、V-H #6 churn：按主理人裁定记 FAILED ＋ 三条替代断言面实测

主理人 11-18 裁定（终局）：§十一.5 假设 `HEAD` 是"B1 改前树"，**该前提不成立**（HEAD 停在 S32、S33–S38 全未提交，此账记主理人头上，不算实现缺陷）；⛔ 不许拿 `_backup/spr38_final` 充基线（B1 途中件）；V-H #6 收官记 **FAILED**（语义＝无基线可用，非判据变红）；E4 三指纹＋`validate=0`＋rng 计数**不等价于** churn，只作"随机流等价"附注；改走三条**零 Godot**替代断言面 C-a′／C-b′／C-c′；commit 锚点不由主理人代作者授权。

| 子门 | 判据（主理人口径） | 实测 | 结论 |
|---|---|---|---|
| C-a′ | 新 94 条标题 token ⊎ 既有各探针标签集合，与历轮口径文档逐条对账 | 机检 `_tools/spr38_clause_sum.py`（拿日志 `#NN <条款>` 的组计数逐行比 §三 声称数）：**日志普查 94 ＝ 探针 declared 94 ＝ 文档加总 94，C-a′ GREEN**；首跑报出 3 处**文档声称数错**（V-B1/B2 7→6、V-C4 2→3、V-E1/E2/E5 6→5，87 时代表就只对上 77 条），已按日志实测改行、⛔ 未动探针。机检件自身由 `bash _tools/spr38_clause_selftest.sh` 四态反证：正典 GREEN ＋ 三处人为造错各 RED（其中一处是**两个 ±1 互相抵消、加总仍＝94** 的形态 ⇒ 证明判据逐行比、不是只比总和） | ✅ |
| C-b′ | MELEE 侧 `done checked=94 declared=94` ＋ 既有 `_*_DECLARED` 常量磁盘值不变 | `_tools/spr38_g_melee.log`＝`done checked=94 declared=94`；对 `_backup/spr36_tb/game_main.gd`（今日 17:57，早于 B1）逐项机比：**_CT=117 / _OG=43 / _PC=28 / _S31=12 / _S32=19 / _SB=15 / _SCL=9 七项逐字相等**，盘上唯一新增 `_ML_DECLARED=94`（本批应有；另 `scripts/player.gd:154` 的 `_STANCE_DECLARED=7` 属 B2a） | ✅ |
| C-c′ | 两侧 `[ERR]`／`ok=false`／`SCRIPT ERROR`／`validate problems` 全 0 | 基线侧 `_tools/spr38_base.log`＝**0/0/0/0**；改后侧 `_tools/spr38_g_base.log`＝**0/0/0/0**；改后树另外 8 份（melee／stance／apply／rng／sc／pw／fp×3）同四项亦全 0，其中 `pw` 由 1→**0** | ✅ |
| 附注 | E4 三指纹（⛔ 不得当 churn 用） | seed 12345／777／42 三行与 `production/sprint-32/SPR32_验证口径.md`:144-146 **逐字全等**：机检件 `python _tools/spr38_fp_vs_5_4.py` → `doc_hits=3/3`、逐档 `hits=1` 且两侧 substring **MATCH**、`VERDICT=ALL_MATCH`（rc=0）；同件 `--falsify` 造错三档全 DIFFER、`VERDICT=ALL_DETECTED` ⇒ 这机检有牙。⚠️ 旧措辞"两侧各 495 字节"是另一口径的整行长度，11-17 起⛔ 再引用（现值按段报 71/69、88/83、91/87） | 随机流等价 |

流程补丁（主理人给的，转记于此免得下批再开一轮）：**今后每批开工前先落一次作者点单的 commit 锚点**；在作者点单之前，每批 churn 一律按本节口径记 FAILED，⛔ 不再重开此问。

---

## 九、三处偏差申报（我做了与施工单不同的选择，逐条自陈）

1. **D5 的实现手法与主理人 §十一 给的不同。** 给的法子是"装备盾武器前后各读一次主动遗物状态再比"——按原样写会**恒真**：`_tick_relic_timers()` 只在物理帧推进，同步挥击不消耗帧 ⇒ 两次读数必然相等，断言永远绿、刀砍不动。⇒ 改成**同帧数对照神谕**：`_ml_relic_decay(true)`（四帧、每帧先挥一击）vs `_ml_relic_decay(false)`（同样四帧不挥），要求四键冷却差逐键相等，再合取 `d_shield>0` 与 `orbit=True` 证明时钟确实在跑。反证：刀 9 一砍 #84/#85 连带崩 ⇒ 门有牙 ✓。**主理人 R4 ⑤：本手法追认**，并据此在口径里新增 **HP-7**（同步段内不推进计时器 ⇒ 凡"改前后各读一次再比"的断言默认恒真，须先证明两次读数之间真的消耗了帧）。
2. **`_ML_DECLARED` 我交 94，主理人 §六 写 93。** C2c 我写**三条**不是两条：主前提（旧 pending 复位不生效）＋前提守卫（配额见底且复位确已在飞、令牌已发）＋**反证 `give_weapon` 确实执行且配额系统没坏**。第三条不是装饰——没有它，`give_weapon` 静默不执行时主前提会"因为错的理由"变绿（弹夹停在 0 是因为根本没捡起来，而不是因为令牌把旧回调作废了）。⇒ 请主理人把 §六 的 93 改 94，或在口径里把这条降格；我按 94 交盘。**主理人 R4 ①：`_ML_DECLARED` 定为 94，第三条反证追认**（93 已改，本偏差结案）。
3. **`swings_total` 基线由 52 抬到 57**（＋1 来自 C2c 的那一击、＋4 来自 D5 对照组），`draws_total` 同步 57。按主理人自己的 HP-2 补句"动作集合变了就要重设基线"，这条是照章办事，但**新串是我实测出来的、不是主理人给的** ⇒ 按 ⛔ 编程侧不自定基线纪律，回主理人转录／重登。**主理人 R4 ②：基线串已重登为 `swings_total = draws_total = 57`**（旧 52 作废），并编成 **V-H #10**（逐字串对账，实测见 §二 第 10 行）。重登值由主理人给，盘上串由我逐字转录，⛔ 我不自改。
4. **R4 的其余四条与本轮工具账（一并结案）**：③ V-H #8 收窄——⛔ 把 `validate problems>0` 当"静态类刀"的必备特征，不可让的是 `SCRIPT ERROR`=0；这正是 §七 负结果 2 报的"与主理人原预期相反"那条，口径已按实测改写。④ 变异刀**唯一编号真源＝盘上 `_tools/spr38_mut.py` 的 M1–M10**，K8→M9、K10→M10，K9b／K9(废) 不登记为刀（映射与理由见 §七 注）。⑤ HP-7 入册（本条 1 的连带产物）。⑥ churn 流程补丁落 V-H #6（见 §八 末）。
⇒ **§九 三处偏差全部结案，无遗留待裁项**；本轮另新增的机检面（`spr38_clause_sum.py` ＋ 四态反证自测）见 §十。

---

## 十、工具面与本轮纪律自证

- 一把钥匙跑七件套：`bash _tools/spr38_gates.sh [输出目录]`（`ROOT=` 可换树；每条前清 `%APPDATA%/Godot/app_userdata/test_1/_smoke_*.cfg*`；计数一律 `cat 文件 | grep -a -c`，AGENTS §7 的盘符冒号坑）；末段现在直接跑 **V-H #10 逐字基线串对账** ＋ **C-a′ 条款对账**，任一红即退出码 1。取码写法是"先落文件再 `$?`"，⛔ `python … | tail -2` 那种把退出码让给 `tail`（恒 0）的假绿。
- 变异刀：`bash _tools/spr38_knife.sh [刀号…]`（`QA=` 调帧）。新增开刀前基线守卫＋逐刀三查（`SCRIPT ERROR`／`validate problems`／`done` 行齐不齐，V-H #8/#9），还原后 md5 与绿件不符即停机。
- 比对器：`python _tools/spr38_churn.py <改前目录> <改后目录>`（C-a/C-b/C-c 三子门；单侧缺日志**点名**报出，⛔ 静默跳过）。worktree 路线作废后它仍可用于两份日志目录互比。
- 条款账机检：`python _tools/spr38_clause_sum.py [日志] [文档] [declared]`——拿日志 `#NN <条款>` 的**运行时组计数**逐行比 §三 声称数，加总再比 `declared`；只读、⛔ 改盘。首跑即抓出我文档里 3 处声称数错（87 时代表的表也只对上 77 条，属陈旧账，见 §八 C-a′）。
- 机检件的反证自测：`bash _tools/spr38_clause_selftest.sh`（四态＝正典 GREEN／±1 抵消的两处声称错 RED／`declared` 漂移 RED／日志缺一条 RED），4/4 符合预期 ⇒ C-a′ 有牙；零 Godot，只动 `_tools/_scratch/`，⛔ 不碰正典。造错由 `_tools/spr38_clause_falsify.py` 按**条款 token** 定位植入（⛔ 硬写行号：本轮 §二 追加三行就把 §三 整段顶下去，行号版当场 ABORT——这个 ABORT 正是它没被静默跳过的证据）。
- 🔴 本轮自伤一次（已记 `_tools/AUTORUN_LEDGER.md`）：后台正跑 `spr38_gates.sh` 时我改了这个脚本本身 ⇒ bash 增量读错位，`line 35: f: unbound variable`，5/7 门已绿后整件退出 1。那次红**不是判据红**。⚠️ 但当时补的那次重跑**又与另一个值守窗口撞在同一时间段**（两家共用同一份 `%APPDATA%/Godot/app_userdata/test_1/_smoke_*.cfg`），所以那批 15 份日志（22:21–22:25）**作废**；本件所有数最终出自 **22:33–22:39 的单窗口串行重跑**（取证口径见 §六）。规矩：**⛔ 编辑正在后台运行的脚本，也 ⛔ 编辑正在被 Godot 读的 `scripts/*.gd`**；⛔ 并发起第二个 Godot，占位／释放只走 `bash _tools/spr38_run.sh` 一个入口（⛔ 手工 `printf >` 或 `rm` 那个锁文件——11-17 22:33 就有窗口这么把别人的锁覆盖又删掉，逼得对方只能靠三重证据自证没并发）。
- 并发防护与独占取证（11-17 新增，四个值守窗口共用一棵树之后才立的）：`bash _tools/spr38_preflight.sh [--wait]` 只读体检（Godot 存活／运行锁新鲜度／绿基线==盘上 `scripts/player.gd`／台账与交付文档 240s 内被改过），BLOCK 即 exit=1；`bash _tools/spr38_run.sh [gates|knife|--wait]` 是**唯一开跑入口**：preflight 放行 → `set -o noclobber` 原子抢锁（抢不到⛔ 覆盖别人锁文）→ 串行 gates→knife（退出码各自落文件后取 `$?`）→ `trap` 按 `pid-$$` 只释放自己那份 → 收尾再核 `player.gd`==绿基线，不等即 exit=2。三件新机检（都带 `--falsify`／造错自测，⛔ 尚未接进 `spr38_gates.sh`）：`spr38_fp_vs_5_4.py`（E4 三指纹 vs §5.4 逐字）、`spr38_baseline_verbatim_check.py`（27 条武器段串血统＝代码↔主理人 §三 顺序逐字）、`spr38_oracle_quota_check.py`（神谕复算次数⛔ 取计数器增量，须＝`DEFS.mag` 配额；R5 那条口径的机检面）。
- 无人值守纪律：全程未 commit、未 push、未 `git stash/checkout/reset`、未删盘上既有文件、未自刷 md5（`SPR21-FROZEN.md5` 仍 34 OK／0 FAILED 如实报）、未动 `D:\大纲`、未换 `shardbearer.png`、未编辑 `AGENTS.md`。新建的两件是本次工具与备份目录（`_tools/` 在 \`.gitignore\`:6）。

订正（R17-4，11-18）：本节以上各处 24/10 系 11-18 上午快照；盘上现值以当轮 gist `frozen_ok/frozen_failed` 现读为准（主理人 R17 窗实读 34 OK / 0 FAILED），R10 转录落地后回归。（S40 再更正：清单已重登，本行为活声称位）原行一字未改，本行为追加式订正。

## 十一、§七 十刀表订正：E1 绝对值神谕改写后全量复跑（编程侧第二个并发值守轮，11-17 23:4x）

> 🔴 **本节目的**：§七 上表 5／9 两行与「最有价值的负结果」第 1 条，是**改前** `#48` 的实测，现已过期。
> 本轮只读复核那十份日志时发现神谕本身有洞并修掉了，⇒ 同一把套件的 `ok_false` 有两格变化。
> ⚠️ 与另一并发轮的写入可能交叠：本节**纯追加**，未回改 §七 任何一行（请主理人或下一轮按本节把 §七 表体订正）。

### 11.1 缺陷（源码级，两处同一写法）

- `game_main.gd:5151-5154`（V-E1b 的绝对值神谕 `#48`）原写法：`oracle.state = _ML_STATE0` 后 **`for i in d_sw2:`** `oracle.randf()`。
  `d_sw2` 是 `Player.melee_swings` 的增量＝**实现自己的计数**。⇒ 凡是「连挥击计数一起不涨」或「计数与抽取一起多涨」的实现，
  神谕跟着实现走，两侧永远同落点 ⇒ **同源自比较恒过**（AGENTS §5 第三类），只是它长得像绝对值神谕。
- `game_main.gd:4710-4712`（`_melee_probe_swing()`，产物喂 `:2655` 的 `Dev.check(state_ok,"meta",…)`）同写法：`for i in d_sw:`。
  本批被 `:2647` 的 `swings == cnt`（**请求值**，独立）兜住，没有活体假绿，但同罪，一并改。

### 11.2 改法（两处各**一行内替换**：⛔ 增删行、⛔ 改断言编号与标题 ⇒ C-a 取材面仍 94、`_ML_DECLARED` 仍 94）

- `for i in d_sw2:` → `for i in 4:`（探针自钉的 mag 配额，与 `#47` 的 `expect=4/4` 同源）
- `for i in d_sw:` → `for i in count:`（调用方请求值）
- 备份：`_backup/spr38_e1oracle/`、`_backup/spr38_e1oracle_b/`（各 34 件＋`before.md5`）

### 11.3 复跑实测（改后代码，同一套 `_tools/spr38_gates.sh` ＋ `_tools/spr38_knife.sh`）

| 判据 | 实测 |
|---|---|
| 绿基线不破 | `spr38_g_melee.log`：`done checked=94 declared=94 swings_total=57 draws_total=57`，`[ERR]`=0、`ok=false`=0、`SCRIPT ERROR`=0、`validate problems=0` |
| 行为零漂移 | `#48` 落点与改前**逐字同值** `measured=expect=-2585114045049353277` ⇒ 正确实现下「固定 4 次」≡ 旧 `d_sw2` |
| E4 三指纹 | seed 12345／777／42 与 `SPR32_验证口径.md` §5.4 三行**逐字全等**（python 断言，非目视）⇒ 神谕用独立 `RandomNumberGenerator`，不碰 `Game.rng`，随机流零位移 |
| 全套 10 档 | base／melee／stance／apply／rng／sc／pw／fp×3 全 `ERR=0 okfalse=0 SCRIPT_ERROR=0 problems=0`；冻结如实报 **34 OK / 0 FAILED** |
| 十刀 | `ALL KNIVES BIT`，`ok_false`＝4/1/1/2/**4**/2/2/1/**7**/3（⚠️ 旧表 3／6 两格作废），十份 `SCRIPT ERROR`=0，十份都到 `done 94/94`；收尾 `player.gd`＝`df57d7dd4a86ef10b1e09a1f9e049d68`（当时快照·已作废，现绿件 `dc622351a75e8da9d943d72332ec2a28`）|

**新咬住的两把（都是 V-E8 明列必须红的形态，改前神谕对它们失效）**：

- **刀 5（V-E8 ④「过载也算动作」）**：`#48` 由绿转红 `measured=-4222757136798409013` vs `expect=-2585114045049353277`；该刀 `ok_false` 3→4（另三条 #47/#71/#72 不变）。
  ⇒ 改前：200 次输入把 `d_sw2` 抬到 200，神谕也跟着推 200 次，**与实现一起错**，恒绿。
- **刀 9（V-E8 ③「空场早退不抽」）**：`#48` 由绿转红 `measured=20261118`（＝`_ML_STATE0`，一次没抽）vs `expect=-2585114045049353277`；该刀 `ok_false` 6→7。
- 未改钝其余各刀：刀 1 仍 4 红（#48 红，落点仍 `20261118`）、刀 2 仍只咬 #48、刀 8 仍独咬 #85、刀 10 仍 3 红（含 #48）。

### 11.4 请主理人处置（不阻塞：本节全部实测已落盘）

1. §七「最有价值的负结果」第 1 条现文把 `#48` 直接称作「真正有牙的绝对值神谕」⇒ 与改前事实不符，
   建议改成：改前它对**刀 5／刀 9 两把**漏抓（次数取自实现），改写后才是绝对值神谕；计数器盲区的新证据同时包括「神谕写法本身可以假绿」。
2. §七 表体 5／9 两行 `ok_false` 与红集合按 §11.3 订正。
3. 口径 V-E1 补句建议加一条机检化措辞：**「神谕的复算次数必须由探针自钉常量或调用请求值，⛔ 取 `Player.melee_swings` 的增量」**，
   否则「固定起点＋已知次数＋独立复算」三件里「已知次数」是假的，这条 gate 会长期自证。

---

## 十二、主理人 R5 结案（2026-11-18，针对 §十一；作者离线，我裁＝终局）

**结论：缺陷属实、改法追认、§11.4 三条全部由我执行完毕。**逐条：

1. **§11.4-1／-2 已落**：本件 §七 表体 5／9 两行 `ok_false` 改 **4／7** 并补 #48 红项（含实测落点串），负结果第 1 条按订正口径改写——原句「真正有牙的是绝对值神谕」与改前事实不符，现文注明**改前 #48 对刀 5／9 漏抓、按同源改写后才是绝对值神谕**，并升格为通用教训「神谕写法本身可以假绿」。
2. **§11.4-3 已落**：口径 V-E1 加 R5 机检措辞（N ⛔ 取 melee 计数器增量）；V-H #10 与 V-E8 同步登记（M9/M10 反证资格归修正后的 #48）。
3. **一处表述订正**：你们消息说「旧表刀 9 的红集合根本没有 #48」——那只对**本件 §七 表体**成立；pre 日志 `_tools/spr38_k9_pre_oraclefix.log` 里 #48 是**在场且转绿**（`measured=expect=20261118 ok=true`）。定性统一为「漏抓（转绿）」，不是「缺席」。这个区分重要：转绿才是同源自比较的铁证，缺席只能说明没跑。
4. **一格 UNEXECUTED 如实记**：盘上无 `spr38_k5_pre_oraclefix.log`，M5 的改前漏抓只有源码级推断＋我的私有 K 件（不含 MELEE 档）⇒ 不作实测申报，永久反证靶以改后 k5 的 #48 红项为准（我已复扫十刀全量：`ok_false`＝4/1/1/2/**4**/2/2/1/**7**/3，#48 红集合 {k1,k2,k5,k9,k10}，三查×10，绿基线 94/94·57/57·ERR=0·problems=0，E4 三指纹 python 逐字段 MATCH，`player.gd` 收尾 md5==绿基线件）。
5. **一个诚实边界态入档**（不阻塞）：`for i in 4:` 把 mag 配额硬编进探针，将来改配额忘同步 ⇒ #48 因错误原因变红。这是刻意选择的 loud-red 失败模式，可接受；防它的是 V-E1 R5 措辞＋本批注释已把「与 expect 4/4 同源」写死在行尾。
6. **并发纪律**：本轮你们两个值守轮互踩已实际发生（A4–A7 三分钟被划 ✅、交付 mtime 一路跳）。裁定见核验件 §十三.6：**一仓一轮、文档纯追加、⛔ 回改对方段落（我对本件 §七／§二 第 6 行的回改系 §11.4 点单授权，属例外）、跑门控期间独占 Godot 与 cfg**。下一轮接活前先读那一条。

⇒ §十一 请办事项**全部结案**；B1 记账不变（机制通过、churn 终局 FAILED/N-A 见 §十二.5〔核验件〕与本件 §八 R5 补记、⛔ 不 commit、⛔ 不刷冻结）。
- S40 登记轮补记：SPR21-FROZEN.md5 重登后 `md5sum -c` 复跑，通过 34 件、失败 0 件、缺 0；现役绿基线 player.gd = 5835d2e6e9e89d3a6dd4155bcadc0b19。
- S40-M3 登记轮补记：绿基线晋升后现役 player.gd = 037f261d1b2d393fa02aba6a0bed1654；上一版 5835d2e6e9e89d3a6dd4155bcadc0b19 的归档在 `_tools/spr38_good_player.5835d2e6.bak`（双份：`_tools/spr40_good_player_archives/` 同名）。⛔ 再引用旧串当活声称。
- S40 R17 同步：本文件上述冻结声称位（8 处／5 处）由 (24,10)/(23,11) 更新为 (34,0)，依据 S40 冻结重登（md5 ace857f1…）；旧值原文存于 _backup/spr40_r17_docsync/。此行不含可抽取声称对。
- S40-R45 订正：:193 那句「本节以上各处 24/10」的指涉对象已被 R17 13 站同步清空（本文件半角 24/10 今仅存 :193 自身一处，本窗 grep 现算），该句按「本节以上各处＝零」读；:193 原文一字不动，本行为追加式订正。
