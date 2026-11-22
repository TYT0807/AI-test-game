# SPR38 主理人独立核验 · B1 非弹幕近战内核

- 核验日期：2026-11-18　核验人：主理人（Godot 项目）
- 被验件：`production/sprint-38/SPR38_交付_B1_非弹幕近战内核.md` §二／§三／§五／§七
- 授权边界：**本文不写生产文件、不 commit、不刷 `SPR21-FROZEN.md5`**。所有"落地"动作是给你（编程侧）的指令。
- 我读码复现用的日志全部带 `owner_` 前缀，落在 gitignored 的 `D:/Create/Game/test-1/_tools/`；
  实验期间改过 `scripts/player.gd`（四把我自己加的变异刀），**已逐把还原并校 md5**：
  `diff -q _tools/spr38_owner_player_good.bak scripts/player.gd` → SAME，`80fd3fb1bda1511719772de40e355666`。

---

## 一、独立复现结果（我自己跑的，不看你的自报数）

| 项 | 你的自报 | 我的实测 | 结论 |
|---|---|---|---|
| `validate problems` | 0 | `_tools/spr38_owner_melee.log` → `[SMOKE] validate problems=0` | ✅ |
| MELEE 探针 | 87/87 | `done checked=87 declared=87 swings_total=52 draws_total=52` | ✅（🔴 R4 作废：该串出自**未含 C2c/D5 三组新断言的旧树**，动作集合已变 ⇒ 基线按 V-E1 重登为 `94/94 · swings=draws=57`，⛔ 拿本行当现值引用） |
| `[ERR]` / `ok=false`（melee 单跑） | 0 / 0 | 0 / 0，`script_err=0` | ✅ |
| E4 三指纹 | 与 SPR32 §5.4 逐字 | `owner_fp_{12345,777,42}.log` 三行 `rooms=`/`kinds=` 与 `production/sprint-32/SPR32_验证口径.md:144-146` **逐字符相同** | ✅ |
| SC 圣所零消费回归 | 19/19 | `owner_sc.log` `done checked=19 declared=19` | ✅ |
| MG-PW1 | 缺 [] 多 20 把 | `owner_pw.log` 原文复现，20 把 id 与顺序与你贴的**逐字一致**；`[ERR]`=1（这条就是那条预期红） | ✅ |
| 冻结 | 24 OK / 10 FAILED | `md5sum -c` → 24 / 10 | ✅ |
| 七刀红表 | 4/1/1/2/3/2/2 | 抽验：我另跑的四把（见 §二）计数口径与你的日志一致 | ✅ |

**一条我要点名的读数纪律（不是缺陷，是防误读）**：`META_WEAPON_POOL_BASELINE` 只有 7 条，而 `pool assert=OK pool=14`
那个 14 是 `_meta_usable("upgrade")`（`game_main.gd:2484`），**与武器池无关**。你 §五 表格把它照抄成 `pool=14`，
读的人十有八九会当成"武器池 14 把"。这行 print 的标签错位是既有的（源码注释已认账），本批不改代码，
但**报告里引用它必须写明是 upgrade 侧计数**。

### 声明数与实际调用数的对账（我自己算的）

`grep -a -c "_ml_assert("` = **64** 处调用；`_ML_DECLARED := 87`。差的 23 来自循环内调用：
V-A3 的 `for id in _ML_BASE3`（3→6）、V-E7 的 6 把（1→6）、V-D4 的六个钩子（1→6）＋ set_fire 反向（1）。
⇒ 87 是真的。**由此得出一条卫生规则**（写进 V-H #2，见 §八）：`declared` 必须是**展开后实数**，
⛔ 不许写成"循环调用数 × 猜测条目数"，且循环集合改变时 `declared` 必须同步改——
`_ML_BASE3` 从 3 条变 4 条就会踩到这个（+2）。

---

## 二、我自己补的四把刀（对着你 §七 最有价值的那条负结果）

驱动同 `_tools/spr38_knife.sh`（唯一锚点替换、命中数≠1 即 ANCHOR-FAIL），环境变量
`SMOKE=1 SMOKE_SEED=12345 SMOKE_MELEE=1 … --quit-after 900`。

| 我的刀 | 砍在哪 | validate | ok_false | 变红的断言 |
|---|---|---|---|---|
| K8 | **空挥不抽**（HP-3 禁形③的字面实现）：在抽取**之前**插一段预扫描，扇内无敌 ⇒ `return` | **0** | 3 | #44 #45（Δstate 与空场不同）＋ #47（state 神谕） |
| K9b | 同一坏形的**同行三元式**写法：`var crit := (Game.rng.randf() < crit_chance) if true else false` | **1**（`_swing() 的 randf 不在函数体顶层…`） | 0 | 静态门拦住，运行期没机会跑 |
| K9(废) | 我第一版用 `if true:` 包一层 ⇒ `SCRIPT ERROR: Parse Error: Identifier "crit" not declared`，`okfalse=0` 是**死构建造成的假绿** | — | — | ⇒ 每刀必须同时断言 `script_err=0`，见 §八 V-H #8 |
| K10 | 同行内联条件抽取（顶格、静态门看不见）：命中才抽 | **0** | 3 | #44 #45 #47 |

**结论（比你的负结果更精确）**：

1. **state 神谕确实有牙**——K8/K10 这两把静态门全绿、计数器全绿的坏实现，都被 #44/#45/#47 咬住。
2. **但你的话要收窄**：不是"只有 #47 抓到刀 1/刀 2"。#44/#45 同样是 state 比对（scratch RNG 推 Δ 次），
   它们抓到了 K8/K10；它们在刀 1/刀 2 下放过，是因为**两条都拿"非空摆位"和"空场摆位"比**，
   而"一次动作恒抽 N 次"（N≠1）在这种两两比较里会互相抵消。⇒ 真正不可替代的是
   **#47 那种绝对值 oracle**（固定起点 + 已知次数 + 独立复算落点），不是"任何 state 比较"。
3. 静态门的"顶行启发式"挡得住缩进形态（K9b），挡不住同行内联（K10）。这是**已知天花板**，
   不要为了追它把 `randf` 拆成反射式字符串检查——正确反应是让运行期 oracle 承重，静态门只当第二道。

---

## 三、裁定 1｜MG-PW1（GUARD-3）武器可用集基线串

**裁定：重登，一把登到 27 条；S36 那 14 把 `bw_*` 并入本次同一动作，不单开一案。**

理由（三条都是我坐实的，不是推断）：

1. **这一路测的不是获取途径，是 DEFS 成员资格。** `_meta_pool_ids("weapon")`（`game_main.gd:2536+`）遍历整张
   `Weapons.DEFS`，过滤条件只有 `Game.meta_content_unlocked("weapon", {"id": k})`——**没有 gate 节点＝默认可用**。
   所以任何新 DEFS 条目都会涌进这一路，与 HP-6「B1 不得有任何获取途径」**不冲突**：
   商店/抽卡走 `Weapons.random_unlocked()` 只认 `DROP_POOL`（本批一行未动，#E7 六条断言守着），
   Boss 房走 `boss_weapon_ids()`。⇒ 重登这串是**记账**，不是投放决定，不需要等作者。
2. **拆开会让门永久红。** 14 把 `bw_*` 自 S36 T-B1 起就在盘上，这条 `Dev.check` 每次都报同一串 extra；
   「只登 6 把近战」的结果是 `[ERR]`=1 常驻，门禁第 3/4 件再也判不出真红。
3. **这条串本来就是我的活。** `game_main.gd:35-39` 的注释白纸黑字写着"T-B1（14 把 bw_* 进 DEFS）……届时由主理人重新登记整串"，
   出处是 `production/sprint-36/SPR36_主理人裁定_G2与GUARD3基线与TA显示态.md` §2。它没被执行，是我的欠账，不是本批的缺陷。

**可执行指令**：把 `scripts/game_main.gd:40-43` 的常量整体替换为下面这份（顺序无所谓，判定是集合相等；
分两行只为可读性，⛔ 改动缩进结构以外的东西）：

```gdscript
const META_WEAPON_POOL_BASELINE := [
	# S36 T-B1 的 14 把 Boss 专武（无 gate 节点＝默认可用，W3=A 的本意）
	"bw_prism_latch", "bw_seam_light", "bw_core_hammer", "bw_sixfold_ring", "bw_quiet_gauge",
	"bw_tide_gauge", "bw_clinkant_fang", "bw_slack_half", "bw_cinder_rake", "bw_red_dial",
	"bw_abyss_ledger", "bw_half_beat", "bw_black_silt", "bw_third_key",
	# S38 B1 的 6 把非弹幕族（DEFS 有条目、零获取途径：HP-6 靠 DROP_POOL 守，不靠这一路）
	"ml_cleaver", "ml_needler", "sp_thorn", "sh_bulwark", "th_kunai", "wd_whisper",
	# 初始三件套＋弹道三连＋mw_*（T-A 之后 default:true）
	"zhushan", "liechi", "guanglei", "fushe", "mw_swarm", "mw_arc", "mw_cluster",
]
```

> 订正（R7 §C.2，11-19）：上方栅栏第 9 行四件 id 系 M12 前旧名，现以盘上 `game_main.gd:50` 现读为准逐字转录；原行经主理人逐字件替换，替换前后双份留档于编程侧回执。

同时把 `:35-39` 那段注释里"T-B1 会让……届时由主理人重新登记整串"改成已完成口径：
**"2026-11-18 主理人已按 S36 R-2 §2 ＋ S38 B1 §三（本文）重登为 35 条中的武器段 27 条；
本串记的是 DEFS 成员资格，⛔ 不得当作获取途径的证据（获取途径看 `DROP_POOL` 与 V-E7 六条）。"**

跑法与验收：`SMOKE=1 SMOKE_SEED=12345 SMOKE_META_POOLASSERT=1` ⇒ `[ERR]`=0、`ok=false`=0，
且不再出现 `缺 [] 多 [...]` 那行。

---

## 四、裁定 2｜V-A3 表值：`ml_needler` 的第 4 条 ＋ 三把 `dmg` 的反推

**裁定：`dmg` 1.80／2.40／1.20 采纳；`ml_needler` 数值全部采纳，但它不进 V-A3 的钉值表——降级为"由静态门守的形式不变量"。V-A3 仍然只钉三把。**

### 4.1 三个 dmg

你的推导式写错了名字但结论对：`interval × 3.33` 里的 3.33 是**步枪的单发伤害折算 dps**，
不是"步枪 dps"这个含糊说法能证的。我按设计实稿自己的平衡锚复核：

- 步枪基准 ≈ `dmg 1.0 × 射速 ≈ 3.33/s` ⇒ **dps 3.33**；
- 近战族的定价是"同等 dps、但射程风险更高 ⇒ 用大 interval 换" ⇒ `dmg = interval × 3.33`：
  cleaver `0.55×3.33=1.83→1.80`、thorn `0.72×3.33=2.40`、bulwark `0.90×3.33=3.0` —— 
  ⚠️ **稳壁这里对不上**：实稿 §3.5 直接钉了 `dmg 1.2`（盾击是控制技不是输出技，减速 0.6×/1.2s 就是它的伤害折价）。
  盘上 1.2 与实稿一致 ⇒ **以实稿为准，公式不适用于 shieldbash**。这不是矛盾，是两条不同的设计来源，
  但你 §五 把三个数一并说成"反推"，措辞不实：**1.80/2.40 是反推，1.20 是实稿原钉值**。

**旁证（我读原文读的，`validate.gd:419-470`）**：C3 反超账的循环是 `for wid in WeaponsScript.BOSS_WEAPON`——
**只遍历 14 把 `bw_*` 专武**，近战条目根本不在迭代集合里（未登记的 id 只在带 `bw_` 前缀时才被查）。
⇒ 本批 `problems=0` 说明 C3 **未被扰动**（不是"已被重算过"），V-A3 的 dmg 怎么定都动不到它。这条我核清了，不用你回话。
但它意味着**近战的 dps 没有任何静态平衡门守着**：cleaver 3.27／needler 2.50／thorn 3.33／bulwark 1.33 无人质询，
V-A3 的钉值因此对那三把格外吃紧（needler 不进钉值表 ⇒ 它是全套里唯一无门无钉的一把，记在 §十 第 9 条）。

### 4.2 `ml_needler`

- 实稿 §3.8 只给了它一句"melee（快、短距、低 dmg）"，**无数值**；§3.2 钉的是阔刃那一行。
- 它的四项形式约束我核过：`reach 34>0`、`arc_deg 60 ∈ (0,180]`、`interval 0.26>0`、`mag 7≥1`、`reload 0.8>0`，
  且不含 `_ML_OUTSIDE_FIELDS`（count/spread/speed/life/pierce/explosive）中任何一项 ⇒ 静态门 `_check_weapon_kinds()` 全守得住。
- **为什么不进钉值表**：V-A3 的价值在于"钉的是规格、不是实现的回声"。把一组我从没钉过的数写进 `_ML_BASE3`，
  等于让探针从此把你的配平当规格——以后调 needler 数值必红，而红得没有道理。
  ⇒ **裁决：`_ML_BASE3` 保持三条不动。**

**可执行指令（两处，共 1 行新增）**：

1. `scripts/game_main.gd:4919` 那行的标签 `"A3 表值 %s"` → `"A3 钉值(实稿§3.2/3.4/3.5) %s"`（引**句子**，别引行号）。
2. 紧随其后加一条**存在性**断言（不是钉值）：
   ```gdscript
   _ml_assert(Weapons.DEFS.has("ml_needler"), "A3x ml_needler 在场（数值属配平域，主理人未钉）",
       Weapons.DEFS.has("ml_needler"), true)
   ```
   ⇒ `_ML_DECLARED` **87 → 88**（`game_main.gd:4737`）。

### 4.3 口径怎么改（我来改，你不用动文档）

V-A3 基准值列补一句：**"🔴 本条只钉实稿点名的三把（`ml_cleaver`/`sp_thorn`/`sh_bulwark`）。
第四把 melee `ml_needler` 的数值属配平域，主理人不预先钉，只由 `validate._check_weapon_kinds()` 守形式不变量
（`reach>0`／`arc_deg∈(0,180]`／`interval>0`／`mag≥1`／`reload>0`／无规格外字段）；
新增同族条目一律走这条路，⛔ 不许靠扩 `_ML_BASE3` 来'顺手纳管'。"**
另在 V-A3 边界态里写实：`dmg` 三值来源分别是**反推（cleaver/thorn）＋实稿原钉（bulwark）**。

---

## 五、裁定 3｜V-D5 主动遗物与近战无关

**裁定：不新开环境变量，不并进既有遗物探针；V-D5 改写为"调用级＋源码级"判据，落在 `SMOKE_MELEE` 里加 3 条。**

理由：

- **"四键各跑一次"今天不可达**，而且不是近战欠的账：F/Z/X/C 是输入层，烟雾台架没有输入注入路径。
  新开一个 env 名去做这件事，是给一条**与近战无关的通用输入层缺口**立门——那是独立一批的活，
  不该由 B1 顺路开出第二个探针开关（每多一个 env，V-H 的命令清单就多一处漏跑的地方，本轮 G2 就是这么漏的，见 §七）。
- **D5 真正要防的坏形有两个**，都不需要输入层就能测：
  ① 装备近战后主动遗物的**冷却/效果字段**被分支掉（你已经覆盖了 orb_shield 那一半）；
  ② 近战结算**自己不去调**遗物逻辑（比如有人"顺手"给盾击接一个 orb_shield 消耗）。
  ⇒ 前者是状态断言，后者是源码级断言，两个都比"按键跑一次"更接近条款本身。

**可执行指令（`_smoke_melee_probe()` 内，紧跟你现有 D4 反向那一段）**：

⚠️ 我原先想用 `_ml_stats()` 做快照——**读了码才发现它不覆盖主动遗物**（`game_main.gd:4830-4838` 全是玩家乘区字段）。
所以这三条要你自己备一份"主动遗物字段快照"helper（下面暂名 `_ml_relic_state()`），
键集合＝你在 §五 已实测过的那一半（orb_shield 的存活/半径/吸收计数等）＋四个主动遗物的冷却与效果字段。
**取不到这些字段就回来告诉我取不到，⛔ 不许拿 `_ml_stats()` 或 `slot_mags` 凑数**——凑出来的就是恒真断言。

```gdscript
# V-D5｜主动遗物与近战无关（主理人裁定：调用级＋源码级，⛔ 不开新 env、⛔ 不注输入）
_ml_clear()
_ml_equip("sh_bulwark", 99)					# ⚠️ 用 _ml_equip，⛔ 别在这里用 _ml_shot：
												# 它在 mag_left<=mag_cap_of() 时会把 _reload_t 拍到 0.9（异步段），
												# 同步断言段里带进一个在飞的复位回调＝下一段 D4/C1 的隐性污染源
var r0 := _ml_relic_state()
for i in 4:
	player._swing()							# 真跑四次全路径（配额 99 ⇒ 永不进过载分支）
_ml_assert(str(_ml_relic_state()) == str(r0), "D5 近战结算不改主动遗物字段", _ml_relic_state(), r0)
var seg := _ml_src_segment("res://scripts/player.gd", "func _swing()", "\nfunc ")
_ml_assert(not seg.contains("relic") and not seg.contains("give_player_relic"),
	"D5 _swing() 源码段内不引用遗物入口（近战不调主动遗物）", seg.count("relic"), 0)
_ml_assert(seg.contains("take_damage") and seg.length() > 200,
	"D5 反证·该源码段确为 _swing 本体", "%d/%s" % [seg.length(), seg.contains("take_damage")],
	"%d/true" % seg.length())
_ml_restore_stats(...)						# 沿用你现有的还原收尾
```

第三条是我按本项目血泪加的**反证**：段取错／取空时前两条会双双变成"空串==空串"的恒真比较（AGENTS §5 的常量自比较类）。
`_ml_src_segment()` 若还没有就照 `validate.gd` 里切 `_swing()` 段的同一写法搬一份进探针（两处逻辑同源，注释互相指认，别改一个字各修各的）。

⇒ `_ML_DECLARED` **88 → 91**（与 §四 的 +1 叠加，最终 **91**）。
第三条是我按本项目血泪加的**反证**：段取错／取空时前两条会双双变成"空串==空串"的恒真比较（AGENTS §5 的常量自比较类）。

**口径改写（我改）**：V-D5 判据从"四键各跑一次"改为
**"装备任意非弹幕族武器后：①主动遗物四个冷却/效果字段逐字不变（状态级）；②`_swing()` 源码段内不出现任何遗物入口引用（源码级，附段本体反证）。
🔴 本批明确不覆盖『玩家真按 F/Z/X/C』这一路——输入层注入是独立缺口，见口径例外清单 X-1。"**

---

## 六、裁定 4｜churn（V-H #6）没有改前基线日志

**裁定：worktree 方法批准（比我原先设想的"就地改名取基线"更干净，就用你这个）；但 churn 的产物形态要改——自由文本 diff 在这套日志里钉不住，改用三个确定性子门。**

1. **方法可行**：`git worktree add --detach ../wt_spr38_base HEAD` 建改前树，两边同 env 跑，只比含断言的行。
   硬约束照你说的收紧一档：⛔ `stash`、⛔ `checkout`、⛔ 动当前工作树；worktree 建在 `D:/Create/Game/wt_spr38_base`
   （仓库同级，与我平时放 worktree 的位置一致），用完 `git worktree remove` 收干净。
   新树记得先 `--headless --path <dir> --import`，否则 autoload/资源没注册会假红。
2. **但纯文本 churn 会淹在噪声里**：即便钉了 `SMOKE_SEED`，出怪词缀行（如 `[SMOKE] spawned rusher [shielded]`）
   在两棵树之间本来就可能不同——那是既有实时抖动面，不是断言面。⇒ 不比对这些行之外，我建议**根本不做全文 diff**。
3. **本批用这三个子门替代（都可机检、都可跨树逐字比）**：
   - **C-a 断言行集不变**：`grep -a -o '\[SMOKE-[A-Z0-9-]*\] #[0-9]\+ [^ ]*'` 抽出"探针标签 + 断言编号 + 标题首 token"，
     两棵树排序后逐字比 ⇒ 抓"删断言凑数""改断言标题迁就实现"。
   - **C-b 各探针 `checked=/declared=` 逐字**：`done checked=N declared=N` 整行集合比对 ⇒ 抓跳过的断言。
   - **C-c `[ERR]`=0、`ok=false`=0、`SCRIPT ERROR`=0 且 `validate problems=0`**（改前树同样应为 0）。
4. **诚实标注**：E4 三指纹**不能**代偿 churn——它只证随机流等价，不证断言面等价。
   在 churn 跑出来之前，V-H #6 在本批记 **FAILED（原因：无基线日志，非判据变红）**，⛔ 记 PASS。

### 六b、裁定 4 的修订（2026-11-18，编程侧实测推翻 worktree 前提后追加）

**新事实（我独立复现坐实，不看编程侧自报数）**：`git log -1` = `4dafdaf`（S32 微批 tip），S33–S38 六批的
`scripts/` 改动**全部未提交、全在工作树里**（`git status --short -- scripts/` = 10 个 M）。
⇒ §六.1 那句「worktree 建在 HEAD = B1 改前树」**前提塌了**：HEAD 是「B1 改前 − 6 个批次」，
拿它跑 C-a/C-b 会产出一大片与 B1 无关的"新增断言"，FAIL 不指认任何缺陷。编程侧这条发现成立，收下。

**Q1 裁定＝ (c)：快照合成基线树**。盘上其实有 B1 级改前件，只是不在 git 里：

| 件 | 身份（我实测） |
|---|---|
| `_backup/spr36_tb/`（6 个散装 `.gd`） | game_main／weapons／player／validate／assets／data 六件 SMOKE_MELEE=0、SMOKE_STANCE=0、近战 id=0 ⇒ **货真价实的 B1 改前态** |
| `_backup/spr38_final/scripts/`（34 件） | 其 weapons.gd md5 `315e9283…` 与现树逐字节同 ⇒ 晚于 B1 武器落码，只能当"最后一次微批改前"；但其余 **28 件自 spr36_tb 以来 md5 未动**（ally/bomb/boss/boss2/boss3/bullet/crate/dev_log/dev_overlay/door/dungeon/explosion/game_state/hud/menu/merchant/pickup/prop/relics/secret_wall/shop_stand/slug/toxic_cloud/turret/upgrade_panel/upgrades + shrine_panel 等，含 S32 那 19 条断言所在的 dungeon/game_main 之外的稳定面） |

方法：**以 `_backup/spr38_final/scripts/` 为底、用 `_backup/spr36_tb/` 同名 6 件覆盖**，复制到
`D:/Create/Game/wt_spr38_base`（仓库同级、gitignored 区），先 `--headless --path <dir> --import`，
再 `ROOT=D:/Create/Game/wt_spr38_base bash _tools/spr38_gates.sh _tools/churn_base`。
**C-a/C-b 判据维持"集合相等"原样，⛔ 不许改成单包含**——基线对了，弱判据就不需要。
硬约束不变：⛔ stash／checkout／动当前工作树／回拷快照进 `test-1/scripts/`；用完 `git worktree remove`
不适用（没建 worktree），删掉合成目录即可（只删自己本轮合成的那份）。

**已知失真与处置**：spr36_tb 是 Nov 17 时点，比严格 B1 起点略早，其间 S37-TB 若动过这 6 件会混入少量
"B1 外差异"——**处置规则：比对红了逐条归因，能指到 S37/S36 批文档的记豁免点名，指不到的才算 B1 嫌疑**。
另：g_base／g_apply／g_rng／g_pw 四份日志今天本就零条 `[SMOKE-*] #N` 断言行（META 族走覆盖行口径），
C-a/C-b 对它们是空集==空集的恒过——这是既有形态不是本批引入，如实标注，别为它扩 C-a 取材面。

**Q3 裁定：值得跑**。门禁七件套缺一不交，且这次跑的开销比原方案**小**：基线树没有 melee/stance 探针，
这两档必然单侧独有 → 直接点名跳过，真正要等的只有 base／fp×3／rng／sc／apply／pw 约 8 次启动 ≈ 4 分钟。
顺序：放十刀之后（cfg 互斥）、A5/A6 之前——churn 是收官件状态翻转的前提，A5/A6 不依赖它。

**PASS 表述定稿（抄进交付 §二 第 6 行，逐字）**：

> V-H #6 churn：**限定通过**——基线＝`spr38_final(34) ⊕ spr36_tb(6)` 合成的 B1 改前快照树（⛔ 非 git HEAD，
> HEAD=`4dafdaf` 落后六批）；同名可比日志上 C-a 断言行集两侧逐字相等、C-b `done checked=N declared=N`
> 整行集合相等、C-c 两侧 ERR/ok=false/SCRIPT ERROR 均 0 且 validate problems=0；
> `melee/stance` 为 B1 新增探针，单侧独有、点名不参与判定。
> 本 gate 证的是"**相对 B1 改前快照，既有断言面未被啃掉**"，⛔ 不得写成"S33–S38 累计回归通过"。
> 残余风险如实报：spr36_tb 时点略早于 B1 起点，红项按上面的归因规则处置。

若合成基线跑挂（缺资源／编译错／`--import` 后仍假红）→ **退回 (b)**：V-H #6 记 N/A（原因：无 B1 改前基线树），
替代证据用可机检的源码级差分：`diff _tools/_bak_spr38_weapons.gd.orig scripts/weapons.gd`（唯一单文件正证）
＋ game_main/player 两件的改前后函数级对照，落文档点名"B1 触碰面 = weapons+player+game_main+validate+assets
五件，其中后四件的 B1 前原文盘上无存 ⇒ 不可机检部分如实 UNEXECUTED"。⛔ 两条都不许冒充完整 churn PASS。

---

## 七、追加核验 A：`_swing()` 是否满足 HP-2「恒恰 1 次、分支无关」

**结论：满足。过载不抽取作"不算动作"处理，不违反 HP-2；但 HP-2 的表述要补一句才站得住。**

我逐行读的 `player.gd:688-737`（现场 `grep` 坐实，不引你报的行号）：

- 唯一的 `Game.rng.randf(` 出现在 `var crit := Game.rng.randf() < crit_chance`，位于配额早退**之后**、
  所有几何/命中分支**之前**，函数体顶层、无条件 ⇒ 一旦这次输入被认定为动作，抽取必然发生且恰一次。✅
- **空场**：早退之后才进 `for e in get_nodes_in_group("enemies")`，扇内无敌只是循环体不执行，抽取已过 ⇒ 抽 1 次。✅（#47 与 K8 的红共同证明这条没被写反）
- **全 miss（有敌但在扇外/超距）**：同上，`continue` 在抽取之后 ⇒ 抽 1 次。✅
- **过载无效输入**：`if not skill_active() and mag() <= 0: _start_reload(); return` 在抽取**之前**返回 ⇒ 零抽取。
  更彻底的是：这种输入**根本进不到 `_swing()`**——`_update_aim_and_fire()`（`player.gd:609-638`）的分派门是
  `want_shoot and _fire_cd<=0 and _reload_t<=0 and _swap_t<=0`，过载期 `_reload_t>0` 已在分派层拦掉。
  ⇒ 双保险，语义一致。
- **技能态**（`skill_active()`）：抽 1 次但不扣配额、不改 `slot_mags` ⇒ 抽取仍恒定。✅
- `crit_boom` 的爆炸延到循环后统一 `explode()`，且 `explode()` 与 `slug.take_damage()` 都不碰 `Game.rng`
  （`slug.gd:459` 用的是 `Game.fx_rng.randf_range`，表现层种子）⇒ 不引入额外消费。✅

**但你的口径有个真洞**：HP-2 写"每一次**有效**攻击动作恒 1 次"，而"有效"由实现定义。
按现在的字面，把"命中才算有效"也能自称合规（K8 就是这把刀的合法化身）。⇒ 补一句才封住：

> 🔴 HP-2 补句：**"有效动作"的集合由实现定义，但它必须是跨构建不变的量——以探针的断言行集（C-a）
> 与 `swings_total` 基准值（**本批重登为 57**，见 §十二.2；旧记 52 作废）为不变量证人。任何改动"什么算一次动作"的实现，必须先改本口径并重定基准，
> ⛔ 不许在实现里悄悄重划边界后再拿"计数器相等"自证。**

同步改 V-E1 正文（现在它字面上就把计数器当判据，是你那条负结果的根因）：

> E1 近战族每一次有效攻击动作恒消费 `Game.rng.randf()` **恰 1 次**。
> 🔴 **作证资格**：`melee_rng_draws == melee_swings` 只能作为**前提守卫型**证据（AGENTS §5），
> **PASS 的必要条件是 state 神谕**（固定 `state` 起点 + scratch RNG 独立推进 N 次 + 比落点，即 #47 型）；
> ⛔ 计数器一致不得单独作为 E1 的通过依据。边界态列改为"连续 200 次输入（含 196 次过载无效）⇒ 有效 4 次且 **state 与 4 次复算逐字一致**"。

并把 **V-E8 从两把刀扩为四把**（原文照抄进口径）：
①删抽取 ⇒ 红；②多抽一次 ⇒ 红；③**空挥/全 miss 不抽**（HP-3 禁形③，两种写法都要试：抽取前预扫描 `return`、同行内联条件）⇒ 红；
④过载也算动作 ⇒ 红。⛔ 变不红即 INCOMPLETE。

**G2 窗口守卫不是空转（我实测的）**：`SMOKE=1 SMOKE_SEED=12345 SMOKE_STANCE=1` →
`shots=92 len=0.3333 window=231 moving_window=231 leaks=0 blocks(idle/walk)=56/56 released=7 死亡打断=0 闩锁未结算=1 done checked=7 declared=7`。
⚠️ 但它是 env 门控的，**不在默认套件里** ⇒ 本批命令清单必须显式带上它（见 §八 V-H #9），否则 V-G2 又变成"写了没接线"。

---

## 八、追加核验 B：`_start_reload()` 把复位对象从"回调时读 `cur_weapon()`"改成"起手钉 `wid`"

**裁定：保留，不回退。它没越 B1 授权，而且严格优于旧实现。**

1. **必要性**：`_swing()` 起手会 `slot_mags[cur_weapon()] = mag()-1`，复位若不认同一把，就会出现
   "扣 A 槽、灌 B 槽"这种真实资金流错误。V-C2b 四条断言正是为它存在的——**行为变更必须有断言覆盖，这一点你们做到了**。
2. **旧写法更危险（我读出来的具体后果）**：回调里读 `cur_weapon()`，若期间槽位武器被换掉，
   `slot_mags[新id] = mag_cap()` 会往 `slot_mags` **塞一个新 key**，留下一个跨层存活的幽灵弹匣，
   而 `mag()` 读的是当前槽 ⇒ 近战可能永久停在 0。新写法 `slot_mags[wid] = mag_cap_of(wid)` 从结构上消掉了这条路。
3. **切枪语义没被破坏**：`swap_weapon()` 早就把 `_reload_t` 归零（本批之前就有的行为），
   所以"过载中切枪 ⇒ 切枪优先"成立；#C2b 的 `thorn 仍是 3` 是对的方向。
4. **授权判断**：实施单 HP-6/N 系列管的是"别给近战开获取途径、别另起一套窗口"，没有禁止在换弹复位归属上做修正；
   而且这条修正是被 V-C2 的边界态**逼出来的**，属"实现条款"而非"改设计"。⇒ 在权内。

**但它留了一个洞，请你在 B1 的微收尾里补（不是回退）**：

`give_weapon()`（`player.gd`）末尾 `_reload_t = 0.0` **取消不了已在飞的 `safe_delay` lambda**。
后果：过载中捡武器 ⇒ 计时器被清（看起来"取消了换弹"），但旧武器的 pending 回调稍后照样把旧槽灌满 ⇒
玩家白得一次复位，且 V-C2b 的语义（"复位落在起手那把"）与"切枪优先"在这里打架。

修法（生成号令牌，rng-free、零新持久状态）：

```gdscript
# player.gd：新增一个探针可见的代数计数（static var 亦可，与本文件 melee_* 两兄弟同处）
var _reload_gen := 0

func _start_reload() -> void:
	if _reload_t > 0.0 or mag() >= mag_cap():
		return
	var wid := cur_weapon()
	_reload_gen += 1
	var gen := _reload_gen
	_reload_t = float(cur_def()["reload"])
	Game.sfx("reload", 1.0, -3.0)
	Game.safe_delay(_reload_t, self, false, func() -> void:
		if dead or gen != _reload_gen:
			return
		slot_mags[wid] = mag_cap_of(wid)
		mag_changed.emit(mag(), mag_cap()))
```

并在 `give_weapon()` 现有的 `_reload_t = 0.0` 旁边加 `_reload_gen += 1`。
配套断言（`_ML_DECLARED` 再加 **3** 条 ⇒ 最终 **94**）：

- `C2c 主前提·捡武器后旧 pending 复位不生效`：过载中 `give_weapon()` ⇒ 记录 `slot_mags["ml_cleaver"]`，
  await 超过 `reload` 时长 ⇒ 该值**不变**（证明令牌拦住了）。
- `C2c 前提守卫·配额确已见底且复位确已在飞、令牌已发`：⛔ 这条不许省——主前提的"值没变"只有在这个前提下
  才指认"令牌作废了旧回调"，否则它和"根本没进入换弹态"不可区分。
- 🔴 `C2c 反证·give_weapon 确实执行且配额系统没坏`（**编程侧加的第 3 条，我追认**）：没有它，
  `give_weapon` 静默不执行时主前提会"因为错的理由"变绿（弹夹停在 0 是因为根本没捡起来，不是因为令牌作废了旧回调）。
  这正是 AGENTS §5 的"恒真／空转"类，第三条把它堵住了。⇒ 口径 §六 原写"两条 ⇒ 93"**作废，以 94 为准**。

**第八把刀（请补进 `_tools/spr38_mut.py`）**：把 `if dead or gen != _reload_gen:` 改回 `if dead:`
⇒ 期望 `C2c` 变红。变不红 ⇒ 说明 C2c 是恒真断言，删掉重写。

---

## 九、我在读码里另外挖到的东西（如实报，都不阻塞本批合入）

| # | 事实（带出处） | 影响 | 处置建议 |
|---|---|---|---|
| N-1 | `mag_cap_mult` 变化时**没人调用** `refresh_mag_cap()`：全仓唯一调用点是 `relics.gd:83`；灾祸施加/清除只改系数（`game_main.gd:653-659`、`:676`、`:2833`） | V-C3 说的"换层恢复"在**上限**层面成立（`mag_cap_of()` 现算），但**已在手的 `slot_mags` 不会被钳制**：弹药荒施加瞬间，剩 4 发的阔刃仍按 4 发用，直到下次复位才回到 2 | 本批不修（近战未投放，玩家拿不到）。**记进口径例外清单 X-2**，并规定"近战投放批（V-F）必须先补一条 `slot_mags` 钳制断言" |
| N-2 | `_melee_pierce_armor` 是 `game_main.gd:115` 上的**持久字段**，只在 `_swing()` 里同步置真/清零（`player.gd:714/731`） | 今天安全（`take_damage` 同步）。将来若有人把近战结算改成异步/延迟，标志会泄漏到别的帧 | 已由刀 4 与 #33/#34 守住行为面；**V-B7 边界态补一句**："⛔ 不得把 `take_damage` 挪出置标志的同调用栈" |
| N-3 | `_probe_stance_shot()`（`player.gd:465-474`）在 `SMOKE_STANCE` 未开时首行 return，`_sp_hold_t` 与 `_stance_t` 各记各的账 | 探针专用、不参与游戏逻辑，写法正确 | 无需动作（这是**好实践**，值得在 AGENTS 探针范式里记一笔） |
| N-4 | 图标 key 用 `wpn_ml_needle`，武器 id 是 `ml_needler` | 不对称但 GUARD-2 干净（`_check_icons()` 对全 DEFS 校 `Assets.GEN_NAMES`，`problems=0` 已证六把都登记） | 保留；⛔ 别为了"看着整齐"去改 GEN_NAMES（会撞冻结） |
| N-5 | `_ml_shot()` 会把 `bullet_scale` 设成 `3.0`，只在探针末尾统一还原 | 中途崩溃/提前 return 会留脏倍率给后续探针 | 建议 `_ml_shot` 内部自带 defer 还原，或把 scale 测试排到最后一段（小改，随 C2c 一并做） |
| N-6 | `AGENTS.md` §4.1 引的 raw-delta 豁免位置写作 `player.gd:1919`，盘上现在是 `player.gd:2236`（`_buffs[id].t -= delta`） | 行号腐烂，第三次踩 | 我把 AGENTS 那句改成**引句子不引行号**（我的文档我改，你不许动 AGENTS） |
| N-7 | `_tick_buffs(delta)`（`player.gd:314`）在 `_tick_timers(delta)`（`:315`）与 `_update_aim_and_fire(delta)`（`:357`）之前 | 与 E6 的两处豁免口径一致，近战没插进新的 delta 消费者 | 确认通过，无需动作 |

---

## 十、口径（`SPR38_验证口径.md`）由我落的修改清单

我现在就把这些改进口径文档；下面是**改哪一节、改成什么**，你按新版口径复跑即可，不必等我通知第二次。

1. **V-A3**：加"只钉三把"的范围声明（§四 4.3 原文）；基准值列注明 bulwark 的 1.2 来自实稿 §3.5 原钉、其余两把来自反推。
2. **V-C3**：边界态补 N-1 的例外说明（"上限现算成立，在手配额不钳制 ⇒ 例外 X-2"）。
3. **V-D5**：整条换成 §五 的"调用级＋源码级"写法，并注明输入层不覆盖 ⇒ 例外 X-1。
4. **V-E1**：删掉"计数器逐字成立"作为判据的地位，改为 state 神谕承重（§七 原文）。
5. **V-E5**：措辞对齐实现的真语义——"过载输入在**分派层**（`_update_aim_and_fire` 的 `_reload_t<=0` 门）就被拦掉，
   `_swing()` 内的早退是第二道；两道都在 ⇒ 零抽取、零计数"。
6. **V-E8**：两把刀 → **四把刀**（§七），并新增**第八把**（reload 令牌）随 C2c 一起补。
7. **V-G2**：补一句"G2 探针受 `SMOKE_STANCE` 门控，**必须**出现在 V-H 命令清单里，否则视为未跑"。
8. **V-H**：新增 #8「每份变异刀日志须 `SCRIPT ERROR`=0 且 `validate problems` 符合该刀预期（静态门类刀应 >0）」、
   #9「命令清单固定包含 `SMOKE_STANCE=1` 与 `SMOKE_MELEE=1` 两条」；#2 补"循环内断言按展开后实数计 `declared`"；
   #6 补"无基线日志时记 FAILED，⛔ 记 PASS；churn 产物用 C-a/C-b/C-c 三个确定性子门"。
9. **新增 V-J「未由变异覆盖清单」**（你 §七 第 2 条要求的正式位置）：
   `V-D1 damage_mult`／`V-D1 bullet_dmg_mult`／`V-E7 六条不在 DROP_POOL`／`V-B7 对 from_dir 恒零不敏感（靠刀 4 自证）`
   ／`V-C3 两条（表值型）`／`V-C4 _swap_t=0.25（常量比对型）`。
   ⇒ 这些条目的有效性由 measured 原值对账担保，**不由变异担保**，报告里不得混在"七刀全红"后面让人误读。
10. **新增例外清单 X-1／X-2**（分别对应上面 3、2）。

---

## 十一、给你的动作顺序（一次做完，别再回来问我）

1. `META_WEAPON_POOL_BASELINE` → 27 条（§三 原文）＋ 注释改口；跑 `SMOKE_META_POOLASSERT=1` 确认 `[ERR]`=0。
2. `_ML_DECLARED` 87 → **94**；依次加：A3x（+1）、D5 三条（+3）、C2c 三条（+3）。
3. `player.gd` 的 `_reload_gen` 令牌 ＋ `give_weapon()` 处 `+= 1`（§八 原文）。
4. `_tools/spr38_mut.py` 补第八把（令牌失效）；把我的 **K8/K10 两把也收进套件**（它们是"计数器全绿而 oracle 见红"的永久反证靶，值得常驻）。
5. ~~churn：`git worktree add --detach D:/Create/Game/wt_spr38_base HEAD` → 两边同 env 跑 → 只交 C-a/C-b/C-c 三个子门的结果；用完 `git worktree remove`。~~ 🔴 **§六b 修订**：HEAD≠B1 改前，改走**快照合成基线树**（`spr38_final(34) ⊕ spr36_tb(6)` → `wt_spr38_base` → `--import` → `ROOT=… bash _tools/spr38_gates.sh _tools/churn_base`），判据仍集合相等；红了逐条归因 S37/S36 vs B1。跑挂退回 §六b 末的 N/A＋源码差分方案。
6. 回报格式沿用实施单 §5，但**每条断言引用一律给标题句子，不给行号**。

---

## 十二、裁定补记 R4（2026-11-18 深夜，编程侧交 94 条／十刀全红后；作者离线，按 AGENTS §1/§1.1 我裁＝终局）

### 12.1 `_ML_DECLARED` 定为 **94**（第 1 项）

收下第三条反证。理由见 §八 的改写：没有它，"弹夹停在 0"这一观测无法区分"令牌作废了旧回调"与"`give_weapon` 根本没执行"——属 AGENTS §5 的空转类断言，必须留。**⛔ 不许降格删除。**
⇒ 本文 §六（原写 93）、§十一.2（原写 +2）已就地改口为 94；下批引用以 `SPR38_验证口径.md` V-H #2 为准。

### 12.2 近战动作基线串由我重登（第 2 项）

`swings_total = draws_total = **57**`（+1＝C2c 那一击，+4＝D5 同帧数对照组的四次挥击）。逐字串与四处引用位见口径 V-E1「基准值」列 ＋ V-H #10 ＋ 本文 §七 HP-2 补句。
⚠️ 这条是**照我自己 HP-2 补句办的**：动作集合变了 ⇒ 基线必须由主理人重设，编程侧实测值只是申报，登记权在我这边。现在登记生效。

### 12.3 静态门判据收窄（第 3 项）

实测推翻了我的预期：把 `randf` 挪进同行三元式的 **M10**（＝我 §二 的 K10）`validate problems=0`（静态门没抓到），而删／加抽取的 **M1／M2** 反而 `problems=1`（静态门另有判据命中）。⇒ 口径 V-H #8 改写：**⛔ 把 `problems>0` 当"静态类刀"的必备特征**；不可让的那条只有 `SCRIPT ERROR`=0。详见口径 V-H #8 与 V-E8 注。

### 12.4 变异刀编号唯一真源＝盘上 `_tools/spr38_mut.py` 的 1–10（第 4 项）

我在 §二 用的 K8／K9b／K9(废)／K10 是我实验期的私有临时标签，**不作真源**，映射如下（永久锁定）：

| 我的私有标签 | 正式刀号 | 形态 |
|---|---|---|
| K8 | **M9** | 抽取前预扫描扇内无敌即 `return`（HP-3 禁形③的字面实现） |
| K10 | **M10** | 同一坏形的同行内联条件抽取（顶格、静态门看不见） |
| K9b | **不登记为新刀**＝M10 的失败变体 | `… if true else false`，被静态门在 parse 期拦住 |
| K9(废) | **不登记** | 首版 `if true:` 包一层 ⇒ Parse Error，死构建 |

**K9b／K9(废) 作为"死构建反例"保留在案**（写在文档里，不落 `_tools/`，那是你的地盘）：它们的价值正是逼出 V-H #8——`okfalse=0` 可以由"根本没跑起来"造成，所以每份刀日志必须三查齐验（`SCRIPT ERROR`=0 ＋ `done checked=N declared=N` 出现 ＋ 预期红项存在）。V-E8 四形覆盖表已按此登记 M9/M10 两把承担形③的两种写法。

### 12.5 D5 手法偏离：**追认**（第 5 项）

你对我原写法的否定成立。`_tick_relic_timers()` 只在物理帧推进、同步段内的挥击不吃帧 ⇒ "装备前后各读一次"必然恒真、刀砍不动。改成**同帧数对照神谕**（`_ml_relic_decay(true)` vs `(false)`，各四帧，前者每帧先挥一击）＋ 合取 `d_shield>0` 与 `orbit=True` 证明时钟确实在跑，是对的形状；反证（M9 一砍 #84/#85 连带崩）已证门有牙。⇒ **无需重写**。
同时把坑升格成通用纪律（对所有"改前后比"型断言都成立，不只 D5）：

> 🔴 **HP-7（新增）**：凡"同一状态改前改后各读一次再比"的断言，必须先证两次读数之间**确有帧被消耗**（或确有其它推进源）。同步段内的直接调用不推进任何 `_tick_*` 计时器，此类比较**默认恒真**，⛔ 不得单独承重；要么改成同帧数对照组，要么合取一条"时钟确实在跑"的证据。

### 12.6 churn 流程补丁收下（转记 §九 N-6 → 现落口径 V-H #6）

今后每批开工前先落一次**作者点单的 commit 锚点**，否则无基线可比；在作者点单之前，每批 V-H #6 一律记 **FAILED**（语义＝无基线可用，非判据变红），⛔ 记 PASS、⛔ 每批重开此问。commit 授权仍不由我代作者拍。

### 12.7 本批记账更新（替换 §十一 末段）

B1 机制 **通过**（94 条已齐）；门禁 9 件绿 ＋ 第 6 件 churn 按 §12.6 记 FAILED（已裁定，非缺陷）；MG-PW1 那条 `[ERR]` 已由 1→0 ⇒ 我在 §三 重登的 27 条武器段串**逐字转录生效，我的欠账已清**。E4 三指纹与 SPR32 §5.4 逐字全等 ⇒ V-E4 通过。
仍挂红／待办不变：V-G1（复制件 ⇒ T-P1，受作者一裁）、V-G2c（T-P2 只登记）、例外 X-1／X-2。
⛔ 不 commit、⛔ 不刷 `SPR21-FROZEN.md5`、⛔ 不动 `D:\大纲`、⛔ 不换 `shardbearer.png`。

**本批状态（我这边记账）**：B1 机制**通过**（87→94 条补齐后即为可收官件）；
门禁第 6 件 churn 记 **FAILED（无基线，待步骤 5；基线取法已按 §六b 改为快照合成树，⛔ 用 HEAD worktree）**；MG-PW1 那条 `[ERR]` 在步骤 1 之前继续如实挂红，
**算我的欠账，不算你的实现缺陷**。⛔ 不要 commit、⛔ 不要刷 md5、⛔ 不要动 `D:\大纲`。

---

## 十三、裁定补记 R5（2026-11-18，编程侧值守轮交 E1 神谕同源缺陷＋churn (c) 实跑证伪；作者离线，我裁＝终局）

### 13.1 E1 绝对值神谕的同源缺陷：**属实，改法追认，§七 的补句被我自己的标准证伪了一半**

我在 §七 写的「PASS 的必要条件是 state 神谕（固定 `state` 起点 + scratch RNG 独立推进 N 次 + 比落点）」
只立了三件的骨架，**没管「已知次数」的来源**——你们这轮挖出的正是这个洞。我独立复现坐实（不引对方自报数）：

- **改前写法真在同源**：`_backup/spr38_e1oracle/scripts/game_main.gd:5153` 实测 `for i in d_sw2:`、`:4712` 实测 `for i in d_sw:`；
  现树两处已是 `for i in 4:`／`for i in count:`（现场 `grep -n 'for i in d_sw' scripts/` 零命中）。
  备份 diff 与申报逐字一致：**行数 6554==6554、仅两行各一行内替换、断言编号与标题未动 ⇒ C-a 取材面仍 94、`_ML_DECLARED` 仍 94**（盘上 `game_main.gd:4752` 实读 = 94）。
- **改前 #48 对 M9 确实漏抓（决定性证据）**：`_tools/spr38_k9_pre_oraclefix.log` 里 #48 原文是
  `measured=20261118 expect=20261118 ok=true`——两侧同值即神谕跟着实现走，AGENTS §5 第三类恒过形态，铁证。
  ⚠️ 对方消息说「旧表刀 9 的红集合根本没有 #48」，这句只对**交付 §七 表体**成立；pre 日志本身有 #48 的**绿行**。表述以「漏抓（转绿）」为准，不是「缺席」。
- **M5 的改前漏抓 UNEXECUTED**：盘上没有 `_tools/spr38_k5_pre_oraclefix.log`，只有我 §二 实验期的私有 K 件
  （`spr38_owner_k*.log` 不含 k5/k9b 的 MELEE 档）。⇒ M5 的改前行为按源码级推断成立（`d_sw2`→200 ⇒ oracle 跟推 200 次 ⇒ 与实现同错），
  **但缺运行时反证，此格不得冒充实测**；永久反证靶由改后 k5 的 #48 红项承担（下条已复现）。
- **改后十刀我全量复扫**（`cat _tools/spr38_k<N>.log | grep -a -c`，AGENTS §7 计数坑口径）：
  `ok_false` = **4/1/1/2/4/2/2/1/7/3**，与申报逐格相等；#48 红集合＝ {k1, k2, k5, k9, k10}。
  新咬住的两把逐字复核：k5 `#48 measured=-4222757136798409013 expect=-2585114045049353277`、
  k9 `#48 measured=20261118 expect=-2585114045049353277`（一次没抽）；k5 其余三条 #47/#71/#72 不变（3→4）、k9 为 6→7 ✓。
  未钝化复核：k1 仍 4 红含 #48、k2 仍独咬 #48、k8 仍独咬 #85、k10 仍 3 红含 #48 ✓。
  每份刀日志三查齐验（V-H #8/#9）：`SCRIPT ERROR`=0×10、`done checked=94 declared=94`×10、预期红项逐刀在 ✓。
  收尾 `player.gd` md5 实读 `df57d7dd4a86ef10b1e09a1f9e049d68` == `_tools/spr38_good_player.bak` ✓（无刀残留）。
- **绿基线与零漂移**：`spr38_g_melee.log` 实读 `done checked=94 declared=94 swings_total=57 draws_total=57`、#48 `measured=expect=-2585114045049353277`、
  ERR/ok=false/SCRIPT ERROR/validate problems 全 0；全部 g_*/fp* 日志 ERR=0、problems=0 ✓。
  **E4 三指纹**我用 python 逐字段断言重跑了一遍：`spr38_fp_{12345,777,42}.log` 与 `spr38_g_fp*.log` 六个文件对 SPR32 §5.4 三行**全 MATCH**（rooms 与 kinds 分开比对，非目视）⇒ 神谕用独立 RNG、随机流零位移成立。

**裁定**：改法定型＝探针自钉常量（与既有 expect 同源）或调用请求值；两处一次性修复**追认，不回退**。
⚠️ 一个诚实的边界态：`for i in 4:` 把「配额恰为 4」硬编进探针，若将来有人改 mag 又忘同步该行，#48 会因**错误的原因**变红——这是刻意选择的失败模式（loud-red），可接受；配套纪律见口径 V-E1 新加的机检措辞（§13.3）。

### 13.2 交付 §七 表体与负结果第 1 条：本轮由我回改（定点编辑，最小触碰面）

对方 §十一.1 请我处置的三条全部执行：①表体 5 行 `ok_false` 3→**4**、红集合补 `#48 E1 state 与复算不一致（measured=-4222757136798409013 vs -2585114045049353277）`；
②9 行 6→**7**、红集合补 `#48（measured=20261118＝一次没抽 vs -2585114045049353277）`；③负结果第 1 条改写——
原文称「真正有牙的是绝对值神谕」，**改前事实是它对 M5/M9 漏抓**（次数取自实现自报数），已按 §11.3 口径订正并保留原「计数器恒绿」结论（那半句仍然成立）。
⛔ 不动其它任何行、⛔ 不重写整节。

### 13.3 口径落笔（`SPR38_验证口径.md`）

- **V-E1** 作证资格补机检措辞：state 神谕的「已知次数」**必须由探针自钉常量或调用方请求值派生，⛔ 取 `Player.melee_swings`／`melee_rng_draws` 的增量**——否则三件中「已知次数」是实现的自报数，gate 长期自证（AGENTS §5 第三类的新亚种：**长得像绝对值神谕的同源自比较**）。
- **V-H #10** 的 ⚠️ 盲区句补一句：M5 改前该神谕同样失明（同源写法所致），改后由 #48 红项覆盖；登记权仍在主理人。
- **V-E8** 加 R5 注：M9/M10 的反证资格现由**修正后的 #48** 承担；M5 的改前漏抓记 UNEXECUTED（无 pre 日志），不作为判据缺失。

### 13.4 §六b fallback 的 B1 触碰面成员：**我写错了，更正**

`grep -l 'S38' scripts/*.gd` 我现场复跑＝ **game_main／player／slug／validate／weapons 五件**。
我 §六b 末段写的「weapons+player+game_main+validate+assets」中 **assets.gd 无 S38 标记**（实测 `grep -c 'S38' scripts/assets.gd` = 0，其 +8 行属 S33–S37 图标登记族），且**漏了 slug.gd**。成员以本条为准。
⚠️ 同时声明这条新指标的边界：`S38` 标记只证「**被 S38 批次碰过**」，⛔ 等同「B1 近战内核触碰面」——`slug.gd` 那一处是 T-N N9 的旁路标志读取，属 S38 非 B1 核心；单文件差分只能覆盖带标记的改动面。

### 13.5 churn (c) 快照合成基线树：**实跑证伪，终局＝FAILED/N-A，钩子拆除**

对方照我 §六b Q1 真建真跑了（`spr38_final(34) ⊕ spr36_tb(6)` → `wt_spr38_base`，脚手架取现树资源），我独立复核：

- `_tools/churn_base/` 十份日志俱在；`SCRIPT ERROR` 944–1800 条且**只有一种签名**：`Invalid access to property or key '_melee_pierce_armor' on a base object of type 'Node2D (game_main.gd)'` ＋ `at: Slug.take_damage (res://scripts/slug.gd:452)`。
- 根因坐实：现树 `slug.gd:449-452` 注释自证 `S38 T-N N9`；md5 实读 `_backup/spr38_final/scripts/slug.gd` == 现树 `6a17a4ed…`（**spr38_final 本身已含 B1 期代码**），HEAD `06fa0ebd…` 且 `grep -c _melee_pierce_armor` HEAD=0。
- 我此前那句「其余 28 件自 spr36_tb 以来 md5 未动」是**对不在 spr36_tb 名单里的文件的不可测推论**，此处已被证伪。
- 无解判定：盘上唯一的 slug 快照就是这份带 B1 的；拿 HEAD 盖 slug 会造出「部分含 B1」的伪基线（C-a 假绿），⛔。**⇒ (c) 结构性不可行，终局定死。**

**V-H #6 终局表述（替代 §六b 的 PASS 定稿与 fallback，抄进交付 §八，逐字）**：

> V-H #6 churn：**FAILED / N-A（无自洽 B1 改前基线树，(c) 已实跑证伪）**。替代面＝`weapons.gd` 单文件正差分
> （`diff _tools/_bak_spr38_weapons.gd.orig scripts/weapons.gd`，实测纯新增）＋ S38 触碰面五件点名
> （game_main／player／slug／validate／weapons，⛔ assets）＋ 其余不可机检部分如实 UNEXECUTED。
> ⛔ 不得写成「相对 B1 改前快照既有断言面未被啃掉」（那是 (c) 通过才配有的话），⛔ 不得冒充完整 churn PASS。
> **本节不留「下轮再建一棵基线树」的钩子**；重启 churn 的唯一前提＝作者点单的 commit 锚点（§12.6 流程补丁不变）。

### 13.6 并发值守轮互斥（给下一轮的硬约束）

同一仓库两个编程侧值守轮并发写已实际发生（台账 A4–A7 在三分钟内被另一轮划 ✅、交付 mtime 22:03→22:24 一路跳）。裁定：

1. **一仓一轮**：开工前查 `_tools/AUTORUN_LEDGER.md` 与最近 30 分钟内的 `_tools/spr38_*` / 文档 mtime 变动；发现活轮 ⇒ 只读不写，等它收口。
2. **写盘协议**：文档一律**纯追加**；⛔ 并发轮回改对方刚写的段落（本轮我对交付 §七 的回改是**例外授权**——因为订正内容本身就是我 §七 补句的后续，且对方 §11.4 明确点单请我做）。
3. **跑门控期间独占**：⛔ 第二个 Godot（共享 `%APPDATA%` 的 `_smoke_*.cfg*`，双跑必互相污染出假红/假绿）；⛔ 编辑正在后台运行的脚本与被 Godot 读的 `scripts/*.gd`（对方 §十 已有自伤先例）。
4. 主理人侧（我）只在本目录追加与定点编辑，⛔ 代跑对方的刀与门禁重跑可省则省——证据日志已在盘上，我复扫即可。
5. 🔴 **R6 补**：**碰锁唯一入口＝`bash _tools/spr38_run.sh`**——⛔ 任何手工 `printf > _tools/.spr38_run.lock`（含"过期接管"场景，接管也走入口让它自己 noclobber 重建）。细则与定性见口径 V-H #12／§十四.3。

## 十四、裁定补记 R6（2026-11-18，编程侧第四值守轮交三条工具纪律派件；作者离线，我裁＝终局）

本轮三件事**都不是玩法数值、都不动 `.gd`**，属机检卫生族。我先自己复现再裁（不引对方自报数）。

### 14.1 ①机检件⛔ 在零输入面上报绿：**立，通用口径 HP-8**

我现场复跑坐实（`_tools/check_after_write.py` 是 gitignored 工具，无冻结约束）：

- `python _tools/check_after_write.py _tools/_bak_report_sec9 .`（漏传第三组 RELS）⇒ 输出 `CHECK-GREEN files=0 touched=0`、**exit=0**、一个文件都没查。与申报逐字一致。
- 正确调法 `python _tools/check_after_write.py _tools/_bak_report_sec9 . "_tools/AUTORUN_值守报告.md" --maxdelta 80` ⇒ `CHECK-GREEN files=1 touched=79`。⚠️ 对方申报 `touched=62`（22:4x 时点），现值 79 ＝差值之后 §8.5／§九 又落了追加，**非矛盾**，是同一件在不同 mtime 上的两次正确读数。

**裁定**：立成**通用口径**（不只 `check_after_write.py` 一件的病），编号 **HP-8**，与 HP-7 并列在 `SPR38_验证口径.md`「V-H 附」节（措辞见 §14.4 落笔清单第 1 条）。AGENTS §5 的并表建议**本批不动 AGENTS.md**（硬边界），登记为收官后由作者点头的一次文档同步，措辞已备好。

`check_after_write.py` 处置意见（它不是我写的，改法归编程侧排期，⛔ 别在别人正用它的那一轮改）：
1. **首选改件**：`len(RELS)==0` 时打 `CHECK-UNEXECUTED no-input-files` 并 `sys.exit(2)`（GREEN/RED 两分支之前拦）；
2. **过渡期调用方义务**（改件落地前即生效，已写进口径）：凡输出含 `files=0` 或命中数为 0，该次运行结论一律记 **UNEXECUTED**，⛔ 引用其 GREEN/PASS；调用后把 stdout 的 `files=` 值转录进台账当自证。

### 14.2 ②解析失败 ≠ 判据失败：**立，取证侧半句并入 HP-8 + V-H #11**

两处事故我都独立复现了：

- **SCRIPT ERROR 空格版 vs 下划线版**：gates 汇总行实际打的是 `SCRIPT_ERROR=`（`spr38_gates.sh:23/:47` 的 `printf` 格式串实证）。我对 `_tools/spr38_A12_gates.log` 实测：`grep -a -c 'SCRIPT ERROR'`＝**0**、`grep -a -c 'SCRIPT_ERROR='`＝**10**、`grep -a -c 'SCRIPT[ _]ERROR='`＝**10**。按空格版解析＝抽出 0 行——若把它读成「门禁 0/10」就是**把解析失败读成判据失败**（假红）；更险的反向是某条断言的正则吃空集恒真 → 假绿。
- **`ACTION_DEFS` 计数假阴性**：我在 `assets.gd` 的 DEFS 块上实跑两版正则——`^\t"([a-z_]+)":` 命中 **15**、`^\t"([a-z0-9_]+)":` 命中 **18**，缺的恰是 `card_1/card_2/card_3`。真值 18 与 HEAD 逐字同集（红线 3 未动，N-6/§9.3 结论不受影响）。

**裁定**：这是 AGENTS §5 四类病在**取证侧**的镜像（断言侧讲「验效果≠验标志」，取证侧对应「取到数≠取对数」）。归属：**通用原则进 HP-8**（一侧措辞给①、一侧给②）；**可操作细则进 V-H #11**（命中数打印＋期望数比对＋失效定性，措辞见 §14.4 第 2 条）。不另立 HP-9——同一条纪律的两个方向，拆号反而没人读全。

### 14.3 ③锁释放路径：**追认 §8.5 归因订正为正；定性＝工具缺陷 A 类（下一触碰者必修），不进并发互斥硬约束条款**

盘上事实（我实读，不采信任何一方转述）：

- `_tools/spr38_run.sh:41-47` 的 `release()` **本来就有**属主校验 `grep -a -q "pid-$$"`，且抢锁走 `( set -o noclobber; printf … >"$LOCK" )`（`:35-39`）。⇒ 台账 N-11 与值守报告 §9.1 说的「释放路径缺 pid 属主校验」**不成立**；§9.1 要的修法（释放前比锁内 pid）**在件里已经存在**。
- 真正的洞＝**手工建锁**：§8.5 的时间线闭合——22:33:07 那轮用**普通重定向** `printf > lock`（noclobber 之前先覆盖了第四窗口 22:32:42 那份锁的**内容**），随后 `rm -f` 删掉的就是那份已被改写、看起来"属于自己"的锁。`spr38_run.sh` 当晚两次真跑都停在 `RUN-DECLINE PREFLIGHT BLOCK`，从未进到抢锁/释放两步。⇒ **§8.5 为本节正典时间线，N-11／§9.1 的机制归因段作废留痕（append-only，⛔ 回改）**。
- 「noclobber 抢锁失败后再 rm 会删别人的锁」这条**假设性风险**本身仍值得防：但 `spr38_run.sh` 的实际代码路径是「抢锁失败 → 直接 exit 1」（`:38`），trap 只在持锁成功后生效，故该脚本**今天没有这个洞**。
- 危害链确认：preflight 只看「锁新鲜 ⇒ BLOCK」「锁不存在 ⇒ 放行」。非属主删锁后，下一窗口 preflight 判空闲 → 与在跑的窗口并发 → 复刻 §8.2。**本窗口 22:32–22:42 的串行重跑不因本洞降级**：独占性靠三重证据（`find -newermt` 写窗、`spr38_run/` 不存在、对方 PID 链＋RUN-DECLINE）立的，正是 §13.6 该用的取证姿势。

**裁定分两半**：
- (a) **不立进 §十三.6 硬约束**："不要 rm 不属于你的锁"是 POSIX 常识级卫生，写成项目条款只会稀释那四条。替代处置＝§13.6 新增第 5 条**指针**（一句话：手工碰锁＝违规，唯一入口 `spr38_run.sh`，见口径 V-H #12），落笔见 §14.4 第 4 条。
- (b) **立一条工具缺陷纪律**（这才是本题的通用形态）：任何「检查→动作」对（preflight→开跑、md5 比对→替换、锁检测→清理）**之间必须有重检或原子原语**，TOCTOU 间隙本身记 **A 类工具缺陷＝下一触碰者开工前必修**（可与 B 类文书修复合一轮做，但⛔ 无限期挂账）。当前盘上已知实例两条：①`spr38_preflight.sh` 判完到 `spr38_run.sh:35` 抢锁之间的 TOCTOU 窗（后果轻：noclobber 保证只有一个赢家，输家带 RUN-DECLINE 退出）；②`check_after_write.py` 的 `files=0` 报绿（§14.1，修法在其名下）。V-H #12 措辞见 §14.4 第 3 条。

### 14.4 口径落笔清单（`SPR38_验证口径.md`，由我本人落，编程侧⛔ 不必动该文件、照本节转录进台账即可）

1. 「V-H 附」新增 **HP-8** 小节（HP-7 之后）；
2. V-H 表 **#10 之后追加 #11**（取证件命中数自证）；
3. V-H 表 **#11 之后追加 #12**（工具缺陷 A/B 分级）；
4. §13.6 末尾**追加第 5 条**（锁唯一入口指针，纯追加、不动对方行）。

以上四条的可直接转录措辞**已随本裁定写入口径正文**（见该文件对应节），台账转录以口径文本为准。

### 14.5 R6 收尾自证（含一次 HP-8 的现形：我自己差点犯同款）

- **我申报过一条不存在的数**：本节初稿写「`check_after_write.py` 对备份根跑 ⇒ `CHECK-GREEN files=2 touched=37`」——那个数**从未被任何一次运行产出过**。实底：我建的"改前快照" `_tools/_bak_r6_owner/` 是用**编辑后**的盘上件 cp 出来的（快照＝现件，diff 恒 0），且 `git show HEAD:…` 取真改前面失败（`production/sprint-38/` 整目录未提交、HEAD 无此文件，rc=128）。该无效快照已 `rm -rf` 删净。**⇒ 本条即 HP-8 的又一次现场教材：比对件两侧同源时结论无意义，命中数／差异数须来自真实两侧。** R6 只落文档这一份，触碰面按下面两条肉眼+grep 复核替代机检。
- 触碰面实况（追加式核对，可复跑）：核验件＝纯追加（`### 13.6` 第 5 条一行 ＋ 全节 §十四；`grep -c '^## 十四'` **实测＝1**）；口径＝三处插入（HP-8 小节 `:156`、V-H #11 `:143`／#12 `:144` 两行），⛔ 回改既有行——V-E1 R5 措辞（`grep -c 'R5 机检措辞'` **实测＝1**，仍在 V-E1 原位原句）、HP-7 整节（`:148`，收尾句 `:154` 逐字在位）未动。
- R6 纪律自证：⛔ 未动 `.gd`、⛔ 未 commit、⛔ 未刷冻结（盘上仍 24 OK／10 FAILED，如实）、⛔ 未动 AGENTS.md（并表建议登记在 HP-8 末句等作者点头）、⛔ 未碰 `D:\大纲`、⛔ 未起 Godot、⛔ 未碰锁。
- 对方本轮交来的实测我复扫过的格：`spr38_A12_gates.log` 十份 `SCRIPT_ERROR=` 命中 10/10、`player.gd`＝`df57d7dd…`＝绿基线、刀日志 k1–k10 俱在——与 §十四.1/.2/.3 引用值一致；**刀 9 转绿与刀 5 无 pre 日志两点现状未变**，R5 的 UNEXECUTED 定性继续有效，R6 不重开。

# 十五、裁定补记 R7（2026-11-18，编程侧值守轮交「无指令运行事故自查」＋同源重言式普查三问；作者离线，我裁＝终局）

## 15.0 事故处置｜那次空占位主理人运行对 sprint-33 四份文件的自查结论（**无指令运行产物，待作者过目**）

盘上事实（全部只读实测）：`git ls-files production/sprint-33` = 0（整目录未提交、无 git 基线可对）；四份 mtime 落在 23:15:13–23:17:12，与事故窗口吻合；`_tools/_wb_bak_a18/` 只备份了 AUTORUN_LEDGER.md，**未备份这四份**。⇒ 无法机械化 diff，以下按「内容级核对」出结论。

**① 冒称作者裁定：未发现。** 四份全部「作者 2026-11-17」裁决引用逐条与当日真实裁决链对上（方案β分工两槽／U1 线性／U2 恒本层／U4 默认表恰 1 张／撤销 S32 §6.2 红线——均见 §G 与实施单 §W 原文）。⛔ 发现任何挂名「作者 2026-11-17 23:1x 之后」或 21:05 离线后新裁的条目。K-4/U6 那条是**主理人自裁**且文中明写「主理人裁定」，不冒充作者。

**② 引用盘上不存在的东西：未发现。** 本轮现场坐实：`_SCL_FROZEN_F3C`（game_main.gd:2081）✅、`_OG_DECLARED := 43`（:5460）✅、门禁句四副本（现 :1806/:1836/:4117/:4182，§G §二.4 记录一致）✅、`data.gd:316` desc / `shrine_panel.gd:170` / `data.gd:399` FLAVOR 三处文案 ✅、`knife_out{,2,3}.txt` 三份 ✅、`sp_logs/s33_prefacts.log`／`s33_r2_purify.log`／`s33chk_*`／`s33a6b_*` 全在 ✅、`_scl_offers_unwidened`（:4176）✅。§G §一.4 冻结数 24 OK／10 FAILED 与今盘一致。

**③ 与本批链冲突的方向性变更：未发现。** 四份中全部 S38/Spr38 字样仅 10 处，逐处都是「S34–S38 并行窗口导致行号平移／冻结偏离归因」这类**事实归因**，无一条给 S38 派活或改 S38 口径。

**诚实披露一个判不了的残留：** 无基线 ⇒ 我只能证明「今天盘上的内容与我历轮记忆＋磁盘互证一致」，⛔ 能证明「23:1x 那 150 回合没改出与我记忆恰好吻合的内容」。四份的行文风格、编号体系（C-6/C-7/U1–U6/K-1–K-5/M-1–M-12）与历轮连续，异常改写的可能性低，但这是**目视判断不是机检**。⇒ 已在四份文件头部各追加一行「无指令运行产物，待作者过目」banner（纯追加，⛔ 回改既有行），作者返岗后可整行撤除或升级为正式复核。

## 15.1 裁定 Q1｜F02（oath_grant 探针）：保留计数、判据换形、申报订正、外加一条入口卫生缺陷

先纠正前提：**43 不是牵动面**。purify 探针才是 declared=28 那份（`_PC_DECLARED := 43` 不存在；`checked=28 declared=28` 属 `_test_purify_cost`）。`[SMOKE-OATH-GRANT] done checked=43 declared=43` 只出现在 SMOKE_OATH_GRANT 语境，改动不外溢。

**裁定分四块：**

1. **不删 F02、`_OG_DECLARED` 保持 43。** a3a==a3b 半边确是第三类（静态可判：`_oath_grant_amount` 为 static func 纯查表，game_main.gd:4408，函数体零 `Game.`/`player.` 引用——本轮独立扫描 9 行体零命中）。但 tag 载体值钱，删条目动分母不值。
2. **改写成有牙的形状（逐字规格）。** F 组段首新增一次源码定位：锚 `static func _oath_grant_amount(` **全文件唯一**（本轮实测 grep=1，定义行 :4408），取其后连续缩进行为函数体，断言体内**不含** `Game.` 与 `player.`；同时把 a3a/a3b 的期望从「彼此相等」改为**字面常量 8**（`_og_assert(a3a == 8 and a3b == 8, ...)` 形态）。⇒ 退化分支（`has_method` 失败 return -9999）下 F02 **必红**，堵死你指出的「漏斗断了照样绿」；静态半边从探针外 grep 变成**探针内自判**，与同探针 E04/E05 的「函数体内定位源码锚点」范式同族。⛔ 不许用全文件正则扫（`_test_oath_grant` 含子串会撞自己，S27 口径 §0.4 已有这条纪律）。⛔ 不许改成读 `_og_src` 之外的新状态。
3. **「grep + 人工闭合」申报必须订正。** 你的核查成立：`_tools/` 无任何对应 grep 件；且 S27 骨架原文写的是「由 **S-grep** 闭合」（探针骨架 :440），而 S-grep **从未在任何文档登记成刀、也不存在于盘上**——这句申报从 S27 起就是空头支票，:5786 print 文案把它转述成「grep + 人工闭合」又错了一层。⇒ 授权改 :5786 该行文案为「静态半边由 F02 源码定位自判闭合（R7 落地后）」，随第 2 块同批做。
4. **另立一条入口卫生缺陷（A 类，下一触碰者必修，本轮只裁不催）：** `_og_checked` **没有任何重置行**（本轮实测 `_og_checked = 0` 零命中；对照 `_ct_checked`(:852)/`_s31_checked`(:1581)/`_s32_checked`(:1846)/`_scl_checked`(:2116) 四处都有）。今天靠「每进程最多调一次」侥幸成立；若将来出现双驱动（如某链同时挂两个 env 触发路径），第二次跑完 checked=86≠43 → **假红**，且 #NN 序号翻倍污染抽行。同名单中疑缺的还有 `_pc_checked`/`_sb_checked`/`_ml_checked`（grep 同样零命中）——此四条以编程侧现场复核为准，复核属实则一并补齐（每入口第一行 `<counter> = 0`）。

**必须跑的门控**：改后 SMOKE_OATH_GRANT 全绿 43/43；变异刀一把＝往 `_oath_grant_amount` 体内塞一行 `var x := Game.floor_num` ⇒ F02 必红；再一把＝把 :5537 退化分支伪装成接线成功（临时 `return 7`）⇒ A 组与 F02 应红、wire_fail 应 0。两刀还原后 md5 回绿基线。

## 15.2 裁定 Q2｜player.gd:1190 圣所确定性：拆两条，等定性刀，措辞现在就钉死

现状：该半边 `ids_a == ids_b` 与 F02 同形（`_shrine_ids` 纯投影 player.gd:1332；key 纯派生 game_main.gd:4122 零 rng）；但它**并非零捕面**——它抓得住「池构造被改成吃全局态」这一违规形态（两次调用之间全局态一动，返回即分岔）。真正的问题是你点出的第二个：**`and ids_a.size() == 3` 同句混装，整句有牙会掩盖半边恒真，且 Dev.check 只在假时打 [ERR]，两句合一条日志无法归因。**

**裁定：**
1. **拆成两条各自登记**：条 A 只判 `ids_a == ids_b`（tag 保留 `shrine`，消息「三卡同 key 两次派生逐字一致」）；条 B 只判 `ids_a.size() == 3`（消息「floor5 语境三卡满额」）。Dev.check 无 declared 分母，拆分不动任何计数，零口径外溢。
2. **定性刀措辞（跑之前就定死，杜绝事后选口径）**：临时在 :4122 的 key 里掺一次 `Game.rng.randf()`（掺法须让两次调用拿到**不同**扰动，例如把 randf 结果拼进 key 字符串本身；只掺固定值不算刀）。跑 `[SMOKE_SHRINE]` 语境：
   - 出现 `[ERR] shrine`（条 A 红）⇒ 定性「**能抓红线 2 违规形态的验效果型**」，保留；
   - 不出现 ⇒ 定性「第三类」，处置走 Q1 同一把尺（保 tag、改判据形状或标注不计捕面），**回来找我改口径，不许自行降级措辞**。
   - 无论哪种结果，⛔ 拿「size()==3 半边也在这条里」当整条有牙的证据——这正是本次要拆开的原因。
3. **不用重造**：S32 探针 D1（game_main.gd:1975-1976 八坐标双调用 bad/var_ok 判据）已是带分母的强化版，红线 2 的主守卫在它名下。player 侧这条的定位是「玩家视角入口的廉价回归哨」，拆完后如实如此登记，⛔ 在文档里把它写成 E1 捕面的主要来源。
4. 刀跑完**逐字节还原**并复跑 gates 确认回到绿基线，结果（红/不红＋日志行原文）转录台账给我。

## 15.3 裁定 Q3｜spr38_tautology_sweep.py 转正三问

我本轮独立复跑（只读）：`Dev.check --all` ⇒ 应解析=284 实解析=284、T3=1（正是 player.gd:1190）、T3b=4、合计可疑=1、VERDICT=HAS_SUSPECT；逐 macro：_ml 70／_pc 28／_s31 12／_s32 19／_scl 9／_sb 15／_og 43（T3=1，正是 F02）／_ct 83，全部 100% 解析；`--falsify` ⇒ base_parsed=70 inj_parsed=74 T1/T2/T3/T3b 各 0→1、VERDICT=ALL_DETECTED。**与你自报数逐格相同，覆盖门与四档探测器有牙成立。** HP-8 两条护栏（macro 名写错⇒UNEXECUTED rc=1；Dev.check 无 measured/expect 位⇒T1 打 N-A）代码路径我核过（:237/:256），采信。括号掩码修洞（:2641 文案 `(0,180]` 案）与 284/284 闭合一致，修法（字符串/注释等长掩码后再数括号）正确。

1. **接进 `spr38_gates.sh` 末段，不留在按需件。** 理由：HP-8 的教训就是「不接线的件会被遗忘到静默失效」；它零 Godot、秒级、且已证有牙。接线动作归「谁空闲谁接」，我不指定你。接线形态照 N-18 三件的范式：**跑完取 `$?` 落文件＋判定串 `^VERDICT=` 逐字命中 1 次＋打印 `应解析=/实解析=/可疑=`**（V-H #11 义务）。⚠ 接线时调用必须带 `--all` 并把九 macro 全列（默认模式只扫 game_main 的 `_ml_assert`，照默认接＝再造一个 213 站点盲区）。
2. **阈值分态，⛔ 现在一刀 FAIL。** 现存 2 条可疑（F02、player:1190）都在本案裁定中，清零前接 FAIL 会把门禁永久钉红。⇒ **过渡期**：可疑>0 ⇒ 打 `VERDICT=HAS_SUSPECT(待裁清单内)` 且 exit=0，待裁清单＝{oath_grant F02, player.gd shrine 同 key 条}，逐条登记在口径；**终态**：两条经 Q1/Q2 处置清零后，同批把阈值翻成 `可疑>0 ⇒ FAIL`（翻转动作是文本级、和接线同文件，编程侧可做，做完报我行原文）。gap 非空 ⇒ UNEXECUTED rc=1 维持原判，不受本条影响。
3. **T3b 四条不要求逐条自证刀。** 逐条实读：gm:2583 中间夹 `Game.meta_unlock(nid)`＝真动作、before/after 语义正当；player:1573 两条中间夹 codex append/clear＝真动作；player:1956 中间夹 daily_share_code_valid 校验＝真动作。四条全是合法的「改前后比」型，为其各配一刀是给 HP-7 已有纪律重复缴费。⇒ 处置＝**豁免登记制**：四条以「文件+句子锚」白名单入 sweep 输出 NOTE（现有 NOTE 行已具雏形），白名单外**新增** T3b ⇒ 才要求配刀或说明。⚠ 顺带纠正我对 gm:2583 的初读：`_meta_usable` 并非纯查表（它读 `Game.meta_content_unlocked`），它的捕面恰恰来自「中间真发生了购买」——这是 T3b 与 T3 的分界在本仓的真实形态，值得写进口径一句话。

## 15.4 本批记账更新（R7）

| 项 | 状态 |
|---|---|
| F02 改写（源码定位自判＋期望钉 8）＋ :5786 申报文案订正 | 📋 新单，编程侧，动 game_main.gd 探针段；两把验证刀必跑 |
| 四探针 checked 计数器无入口重置（_og/_pc/_sb/_ml） | 🟡 A 类工具缺陷登记，复核属实后补齐（入口各加一行 `<c> = 0`），不阻塞他项 |
| player:1190 拆两条＋定性刀（措辞已钉死） | 📋 新单，编程侧；结果两种都如实报 |
| sweep 接 gates 末段（--all＋九 macro＋判定串抽取） | 📋 新单，「谁空闲谁接」；过渡期 HAS_SUSPECT=exit 0 |
| T3b×4 豁免白名单入口径 NOTE | 📋 随接线同批 |
| sprint-33 四份 banner（无指令运行产物，待作者过目） | ✅ 本轮已落，纯追加 |
| 素材侧 D:\大纲 | ⛔ 零接触 |
| .gd / commit / 冻结 / push | ⛔ 本轮零改动、零提交、零刷表、零推送 |

# 十六、裁定补记 R7 落地回收与三条补裁（2026-11-20，编程侧值守轮交 Q1/Q2 落地实测＋三条新事实；作者离线，我裁＝终局）

## 16.0 独立复现记录（不看编程侧自报数，我自己实读盘上件／实算 md5／实 grep 日志）

| 项 | 我的取法 | 实测 | 相符？ |
|---|---|---|---|
| game_main.gd 指纹与行数 | `md5sum scripts/game_main.gd` ＋ `wc -l` | `057d7a2d741e3cc5f0aca7138e42a43e`／6590 行 | ✅ md5 相符。**行数申报不实**：称 6555→6591，盘上 wc=6590；且 `_OG_DECLARED := 43`（:5461）未动，F02 净增应为 +5 ⇒ 起点是 6585 不是 6555。定性＝笔误级、无机检后果，但**下一轮起行数一律 `wc -l` 现取现报** |
| F02 新形状 | Read :5786-5791 ＋ `_og_amount_body_polluted()`（:5979 起） | 判据逐字＝`polluted == 0 and a3a == 8 and a3b == 8`，tag F02 保留；锚 `begins_with("static func _oath_grant_amount(")`、缩进连续体、跳注释行、数含 `Game.`/`player.` 的行、哨兵 `-2001/-2002`——与 §15.1.2 规格逐条对齐；全文件该锚字面命中＝1（定义行 :4408）✅ 唯一性前提成立 | ✅ |
| :5786 申报文案 | grep clean 日志 | `[SMOKE-OATH-GRANT] f02 detail: 静态半边由 F02 源码定位自判闭合（R7 落地后） polluted=0` | ✅ |
| 入口卫生四条 | `grep -n '_og_checked = 0\|_pc_checked = 0\|_sb_checked = 0\|_ml_checked = 0'` | 各 1 命中（:4981/:5479/:6093/:6414），全带 `R7 §15.1.4` 注释 | ✅ 补齐属实 |
| Q1 三态门控 | `grep -a -c` 三份日志（⚠️ 第一次又踩了 awk-F: 坑，改用 cat\|grep -a -c 重算） | clean `[ERR]=0 ok_false=0 done checked=43 declared=43`；刀① `[ERR]=1` 红行逐字＝申报（`polluted=1`）；刀② `[ERR]=10`、红 tag A01–A09＋F02（`a3a=7 a3b=7 polluted=0`）、`探针未接上授予函数` 命中 **0** | ✅ 三态全部复现。刀②正是「wire_fail 检不出来」形态被抓的实证 |
| Q2 拆分与绿基线 | Read player.gd:1192-1193 ＋ md5 | `Dev.check(ids_a == ids_b, "shrine", "三卡同 key 两次派生逐字一致：%s")` ＋ `Dev.check(ids_a.size() == 3, …"floor5 语境三卡满额")` 两条分开、定位注释在位；`player.gd`＝`dc622351a75e8da9d943d72332ec2a28`＝bak 实算逐字节相等；player.gd wc=2497（申报 2495→2498，同款 ±1 笔误，同样只记账不返工） | ✅ |
| Q2 定性刀三态 | grep run.log ＋ q2_knife.log | clean/knife/post `ERR_shrine=0/1/0`、SCRIPT ERROR 皆 0；刀下红行 `["heal","ore_upgrade","blood_relic"]` ≠ clean det `["heal","relic_suffix","greed_pact"]`；`VERDICT=TEETH_YES` | ✅ **§15.2.2 第一分支成立：验效果型，保留** |
| 普查现状 | 读 `_tools/spr38_q3_census2.txt` | 合计 564/564、可疑(T1+T2+T3)=1、`SUSPECT T3 #player.gd:1192 \| cond=ids_a == ids_b`、T3b=4（REGISTERED=4 UNLISTED=0）、`VERDICT=HAS_SUSPECT`；`_og_assert` 段 T3=0（F02 已从普查消失） | ✅ 与申报逐格相同 |
| sweep --falsify 六臂 | 读 `_tools/spr38_q3_falsify.txt` | `base_parsed=70 inj_parsed=76 T1 0->1 T2 0->1 T3 0->1 T3b 0->3 T3B_UNLISTED 0->2 VERDICT=ALL_DETECTED` | ✅ |
| 接线现状 | grep `_tools/spr38_gates.sh` | `spr38_tautology_sweep` **0 命中** ⇒ BLOCK（锁在位）时零写盘为真、gates 尚未接上；wiring 件全文已 Read（见 16.2） | ✅ 如实 |
| selfaudit 基线常量 | Read `_tools/spr38_report_selfaudit.py` :26/:156-161/:265 ＋ mtime | `GOOD_MD5 = "df57d7dd…"` **仍在盘上（08:37 版）**；FAIL 明细两行已在盘上留档（`spr38_run.docaudit.txt`：`FAIL 绿基线或盘上件 != df57d7dd…` ＋ `SELF-AUDIT RED checks_run=27 issues=1`），且同文件内 `基线 绿件=dc622351… 盘上=… 相等=True` 与 FAIL 并存——**同一条判据里两个来源打架**，坐实病灶；文档面另有 6 处活声称仍钉旧串（交付 :131/:221、值守报告 :89/:137/:200/:266） | ✅ 申报属实，另挖出 16.3 的第二半 |
| 冻结现状 | 未动 `.gd`、未刷冻结 | 盘上仍 24 OK／10 FAILED，如实 | ✅ 本批照旧不刷 |

**结论先行**：Q1／Q2 落地**全部追认结案**（§15.4 对应两行翻 ✅）。三条新事实裁定＝①选 **(A) 刀证豁免制**并收紧豁免键形状（16.1）；②接线形态**追认合格**、T3B_UNLISTED **升级进 FAIL**（16.2）；③**立 HP-11**（判据真源单一化），selfaudit 基线常量缺陷定 A 类、归属点名另一窗口（16.3）。另：你自伤备案两件收讫，见 16.4。

## 16.1 补裁 X1｜T3 形状与刀证的冲突：**选 (A)，刀证豁免制**，豁免键收紧为「句子＋刀日志文件名」

**(B) 驳回**：把期望钉成字面三件套＝给 E1 捕面引入一个**新的会腐烂引用**（换卡面／换 theme 偏好／换 seed 表都漂），正是 HP-9 要防的病，拿一个腐烂换另一个腐烂，不干。
**(C) 驳回**：永久待裁条目会让「终态 FAIL 翻转」变成纸面口号；门禁要么能翻要么本来就不该翻。
**(A) 采纳的理由**：这条断言的有牙与否**已经有实证了**（16.0 Q2 行：刀下条 A 见红、还原归零），普查报它 T3 只是形状探测器的诚实输出——形状探测器天生分不清「恒真」与「两侧同源的验效果型（确定性双调用）」，这个歧义只能靠**反证档案**消解，而反证档案恰好存在。HP-10 的精神一以贯之：**证据来自失败真的发生过，不来自形状看起来对**。

措辞（转录台账即可，口径落笔归我，见 16.5）：

> 🔴 **X1（sweep 刀证豁免档）**：T3 条目满足以下全部条件者，从「可疑」计数中摘出、单列 `WAIVED` 档（⛔ 计入 可疑(T1+T2+3) 汇总行，⛔ 删除原 SUSPECT 签名行——豁免是解释不是抹账）：
> ①豁免键＝**文件 ＋ cond 句子原文 ＋ 刀日志文件名**三元组（⛔ 行号〔HP-9〕；⛔「哪把刀」的编号——刀号真源在 `_tools/spr38_mut.py`，把它抄进 sweep＝再造一层会腐烂的间接，直接指到盘上日志文件）；
> ②被指的刀日志必须**盘上存在、且机抽得出该条断言的红行**（判据键＝句子片段，非空命中）——豁免不许是空头名帖，这是 HP-8 在豁免面的延伸；
> ③白名单外**新增** T3 ⇒ exit 1（配刀或说明后才得豁免）；
> ④已豁免条目若其刀日志被删／红行抽不出 ⇒ 打 `WAIVER-STALE` 并 exit 1（证据档案不能比判据活得短）。
> 首条登记：`player.gd | cond=ids_a == ids_b | knife_log=_tools/spr38_q2_knife.log | 红行片段="三卡同 key 两次派生逐字一致"`。

配套处置：现有 wiring BLOCK 里的 `TAU_PENDING` 正则过渡档**随接线一并替换成上述 WAIVED 机制**（同一文件文本级动作，归编程侧，见 X3-4）。

## 16.2 补裁 X2｜接线形态验收：**追认合格**；T3B_UNLISTED **升级为 FAIL**

(a) **认。** 我把 `_tools/spr38_q3_wiring.py` 全文读了（没跑它、没碰 gates），逐项对 §15.3.1／N-18 范式：`--all`＋九 macro 全列 ✅；`^VERDICT=` 逐字命中恰 1 ✅；rc≠0（gap／UNEXECUTED）照红 ✅；**签名面计数与汇总面 `可疑=` 不符即判抽取缺口⇒红**——这条比你申报的 §15.3.1 要求还紧，是把 V-H #11 做成了自洽闭环，追认为标准形态 ✅；现场闸（锁在位／Godot 存活／进程表取不到都拒写）✅，且实测 BLOCK 零写盘、gates 盘上 0 命中互相印证 ✅；锚不唯一拒写、ALREADY-WIRED 幂等拒双份 ✅；末段守卫 `[ "${TAU:-0}" -eq 0 ] || exit 1` 补得对——只打不拦等于再造一门假门。
(b) **升级裁定：T3B_UNLISTED>0 ⇒ 红。** 你在 §15.3.3 里自行收窄是对的（当时白名单机制还没落地，先打数是稳妥中间态），现在四个条件都已具备，按我原话执行。理由再加一条硬的：T3b 的捕面恰恰来自「中间真发生了改动」（gm:2583 那例是我自己在 §15.3.3 纠正过的初读）——所以**夹行动作一旦被人挪走，条目就从合法改前后比退化成恒真**，UNLISTED 判红就是退化瞬间的门。升级后的语义：白名单（文件＋句子片段，现行 4 条）内放行打数，白名单外新增 T3b ⇒ exit 1，配刀或说明后走手工扩名单（扩名单＝口径事件，须在实施单登记，⛔ 静默加行）。

## 16.3 补裁 X3｜「绿基线常量硬编码在判据件里」：**属实，立通用口径 HP-11**；占号，不占 V-H 行

先给你一个你没数的账：这次 RED **不是 HP-9 同款病，而是它的下一级**——HP-9 管「键会平移」，这里的病灶是**同一条判据里存在两个真源**（件内常量 vs 盘上 bak），而且件自己已经抽出 `相等=True` 却仍拿常量一票否决。更重的发现：**盘上还有第二处腐烂面**——文档面 6 处活声称仍写旧基线 `df57d7dd…`（交付 :131/:221、值守报告 :89/:137/:200/:266），selfaudit 的 :265 `hits_md5 = cnt(text, GOOD_MD5)` 把它们当活话数着绿。**就算有人只把 GOOD_MD5 换成 dc622351，文档面照样全绿通过一份过期基线的文档**——那才是这轮真正没人报的那一半。故 HP-11 必须同时钉住「件内三方一致」。

> 🔴 **HP-11（通用）**：凡「不变量值」型判据（绿基线 md5、冻结串、基准计数在内）：
> ①**真源只有一个＝盘上实物**（bak 件／被检文件本身），件启动即实读；
> ②允许硬编码快照常量，但它**降级为一致性哨兵**：`实读(bak) == 盘上 == 常量` 三方不等 ⇒ 打 `BASELINE-MOOT` 并判红，⛔ 拿常量覆盖实读、⛔ 拿实读静默顶替文档声称；
> ③**文档面核对的期望值一律由①推出**（文档声称 md5 ≠ 实读绿件 ⇒ 红），杜绝「文档抄常量、常量抄自己」的同源自比较（AGENTS §5 第三类在取证面的镜像）；
> ④硬编码常量只许出现在写明「当时快照」的行里；换基线那次必须**同批**留下三方一致的机抽证据行。

占号裁定：**占 HP-11，不占 V-H 行**——它是跨件纪律（sweep／selfaudit／knife 守卫／未来任何基线比对皆适用），V-H 表装的是本批门禁动作，混编会稀释。现役 HP 至 HP-10，HP-11 空闲（grep 坐实归编程侧开工前置，见 X3-2）。

归属与执行分派（硬点名）：
- **`_tools/spr38_report_selfaudit.py` 的 GOOD_MD5 改造 ⇒ 归另一窗口**（该件正被其实时改写，你我不碰，你的处置正确）。要点给全：①:26 常量旁注明「当时快照（旧基线期）」；②:156-161 F 块改三方一致判定，FAIL 文案须指明哪一侧不符；③:265 文档面核对改为「文档引用的收尾 md5 == 实读绿件」，并把 :266 的「其它 32 位十六进制串」清单升为强制人工过目项（旧串 df57d7dd 从此在该清单里**合法现身**——它是历史事实不是活声称，判别规则＝所在行是否写明作废/快照语境，沿用 RETIRED/RETIRED_OK_MARK 既有机制扩一条）。
- **文档面 6 处旧基线活声称 ⇒ 归编程侧**（交接文档属编程侧落地面，沿用 R4/R5 既定分工）：逐处订正为 `dc622351…`，历史事故叙述处（交付 :134 那段本来就讲旧事）改写为「旧基线 df57d7dd（已作废，现绿件 dc622351）」句式，⛔ 整句删除（append-only 精神）。
- 定级：**A 类工具缺陷（下一触碰者必修）**，与 §15.2 硬前置同族；在另一窗口完成改造前，凡收官链第 5 步因此件 RED ⇒ 该日志不得作收官证据（V-H #14 语义自动生效，⛔ 绕过第 5 步凑 RUN-GREEN）。

## 16.4 备案收讫（两条，不新开案）

- **裸 prompt 派件事**：§15.0 处置维持；追加一条对我自己的纪律——今后任何派件（含我派出给子代理的）必须自带边界包（读写范围／禁改清单／交付格式），裸 prompt 一律拒收重派。这条落在我侧工作纪律，不占项目口径号。
- **并发编辑他人正在执行的 shell**：N-17 修法（自快照）＋本轮 wiring 现场闸是同族事故的两道闸，均追认；补一句口径：**凡改『正被别的链解释执行』的脚本，必须先过锁＋进程表双检**，写进实施单约束行即可，不另立 HP（已有 N-17＋V-H #14 覆盖，再拆号就通胀）。

## 16.5 口径落笔清单（`SPR38_验证口径.md`，由我本人落；编程侧⛔ 动该文件，照本节转录台账即可）

1. 「V-H 附」HP-10 之后新增 **HP-11**（§16.3 框内措辞）；
2. 同源位置登记 **X1 刀证豁免档** 措辞（§16.1 框内），标注其为 sweep 件的档位定义；
3. V-H #12 A 类清单追加：`spr38_report_selfaudit.py` GOOD_MD5 双真源缺陷（§16.3，归属另一窗口）＋文档面旧基线活声称 6 处（归属编程侧）。

## 16.6 记账更新（替换 §15.4 对应行；追加式，⛔ 回改旧表）

| 项 | 状态 |
|---|---|
| F02 改写＋:5786 申报订正＋两刀 | ✅ 结案（独立复现三态逐字吻合；game_main.gd 新指纹 `057d7a2d…`；行数申报笔误 6555→实为 6585 起点，记账不返工） |
| 四探针入口复位（_og/_pc/_sb/_ml） | ✅ 结案（grep 各 1 命中坐实） |
| player:1190 拆两条＋定性刀 | ✅ 结案（定性＝验效果型保留；绿基线换号 `dc622351…`，bak==盘上实算相等） |
| sweep 接 gates 末段 | 📋 **仍未接**（gates 盘上 0 命中属实）；形态已由 X2 追认合格，BLOCK 解除后照 wiring 件落地即终态，⛔ 再改形态 |
| T3b 豁免白名单 | 📋 随接线同批，**升级**：T3B_UNLISTED>0 ⇒ exit 1（X2-b） |
| T3 刀证豁免档（WAIVED） | 📋 新单，编程侧：wiring BLOCK 内 `TAU_PENDING` 过渡档替换为 X1 机制，首条＝player.gd shrine 条挂 `_tools/spr38_q2_knife.log`（键见 §16.1） |
| 终态翻转前置条件 | 📌 明确为三条同时满足：①X1 豁免机制上线且首条豁免挂证生效；②接线落地且 gates 跑到 chk_taut 行；③T3B_UNLISTED 升级生效。三者齐备当日，「待裁清单清零」宣告才允许把阈值翻成 `可疑(非豁免)>0 ⇒ FAIL`——F02 已物理消失、shrine 条转为刀证豁免，**清单里没有第四条悬案** |
| selfaudit GOOD_MD5 → HP-11 三方一致 | 🔴 A 类缺陷登记，**归另一窗口**（你我⛔ 碰该件）；要点已给全（X3） |
| 文档面旧基线活声称 6 处订正 | 📋 新单，编程侧（清单见 16.3） |
| 素材侧 D:\大纲 / .gd / commit / 冻结 / push | ⛔ 本轮零接触、零改动、零提交、零刷表、零推送 |

## 16.7 R7 回收轮收尾自证

- 本节所有数出自**我自己实读实算**：md5/wc 现取、三份 q1 日志 `cat|grep -a -c` 重算（第一轮 awk-F: 坑我自己踩了一次、当场弃用重算，如实记）、census/falsify/docaudit 三份件产物通读、wiring 与 sweep 与 selfaudit 源码通读、gates 盘上未接线现状 grep 坐实。
- 未重开项：Q1/Q2 原判、HP-8/9/10、V-H #11–#14、sprint-33 banner、刀 5 UNEXECUTED、冻结与放行——一律维持。

# 十七、R8 四条追认与补裁（2026-11-18，作者离线，我裁＝终局）

## 17.0 独立复现记录（⛔ 抄编程侧申报数；全部我自己实读盘上件／实算 md5／实 grep／实跑只读普查）

> ⚠️ **本节取证件的时效（追加轮自曝，如实先报）**：落完 §十七 后我对关键件做了一次**二次复现**（重跑只读普查＋重查值守 :156＋重读 docaudit 两件）。结果两条：①`spr38_r8_gates_chain.txt`／docaudit before/after 仍在盘（mtime 09:00/09:01），但**内容已不是 R8 申报时那一份**——现在两份末行同为 `SELF-AUDIT RED checks_run=27 issues=1`、且 after 里「其它 32 位十六进制串」回到 `[]`（与申报的「变化＝列出 dc622351…」不符）；值守 :156 的订正句式**在盘上确实存在**（我首次 Read 到的是旧文本，你的申报是对的，中间隔了一次并发写——N-17/§16.4 同族事故，方向与我先前设想相反）。⇒ 下表凡标「⚠️ 二查漂移」的行：**首查读数如实保留为当时实测，但此刻不可二次复现**，收官引用以能重放者（census3/armtest/falsify2/selftest/verify/gates 盘上件＋我重跑的 recheck）为准。②这正好给 F4 添了一条实证：**取证件和判据档案一样活在 `_tools/`，被实时窗口改写是常态**——台账转录义务（17.4 附加条）因此更要落。

| 项 | 我的取法 | 实测 | 相符？ |
|---|---|---|---|
| gates.sh 指纹与行数 | `md5sum` ＋ `wc -l` ＋ `grep -c ''` | `e0115414dd327b632d967dfd1e46c67f` ✅；**行数＝130 不是 131**（文件末行 `exit 0` 无换行符 ⇒ `wc -l`=130、`grep -c ''`=130、python `split("\n")`=131）。wiring_verify 打的「行数=131」是 split 口径，与项目「wc -l 现取现报」（§16.0 裁定）不同形 | ⚠️ md5 相符、行数口径混用（笔误级，无机检后果；见 17.5 纪律条） |
| chk_taut 已接线 | Read gates.sh :95-127 ＋ wiring_verify ＋ armtest 的 BLOCK 抽取自证 | 判据段在位（`waiv_all=`／`comm -23`／STALE+UNUSED 判红／终态阈值／UNLISTED 判红／`TAU ⇒ exit 1` 守卫六要素齐）；armtest 用 `sed -n '/^RC_TT=\$?$/,/^TAU=${TAU:-0}$/p'` **从盘上 gates.sh 现抽判据段**并自证非空——证的正是盘上那份，⛔ 抄写版（V-H #12 合规）✅ | ✅ |
| 普查终态 | 读 `_tools/spr38_q3_census3.txt` ＋ mtime 链 | 合计 564/564、可疑=0、`WAIVED T3 #player.gd:1192 … red_hits=1`、`合计 WAIVED=1 STALE=0 UNUSED=0`、`VERDICT=CLEAN_EXEC`、`T3B_REGISTERED=4 T3B_UNLISTED=0`；census2（08:40）/census_after（08:38）为 X1 前旧格式产物（无 WAIVED/STALE 列），census3（08:51）晚于 sweep 落盘（08:52 mtime 同分钟窗口）——新旧格式对得上演进顺序 | ✅ 逐格相同 |
| 豁免键与挂证 | Read sweep :185-190（X1_WAIVED）＋ :193-206（knife_proof）＋ 实查刀档案 | 键＝文件＋cond 句子＋日志文件名，⛔ 行号（HP-9 合规）✅；`spr38_q2_knife.log` 在盘（10300B，mtime 11-18 08:37），`[ERR]` 行含「三卡同 key 两次派生逐字一致」命中 **2**（探针内两条断言共用该文案，red_hits=1 取首个 T3 站点，⛔ 靠计数作证——W3 臂管的就是「档案在但抽不出红行」）| ✅ |
| 我只读重跑普查 | `python _tools/spr38_tautology_sweep.py --all …Dev.check`（零 Godot、零写盘）→ `_tools/spr38_r7_owner_census_recheck.txt`；**落稿后又原样重跑一次** | **564/564、可疑(T1+T2+T3)=0、WAIVED=1 STALE=0 UNUSED=0、VERDICT=CLEAN_EXEC、T3B_UNLISTED=0**——与 census3 逐格相同，且二次重跑仍逐字相同（本行＝全表最硬的一格）；另坐实一处：sweep 件自身对 UNLISTED>0 **rc 仍 0**（只有 gap/STALE/UNUSED 三类才 return 1），X2-b 的拦截全在 gates 面 ⇒ 「⛔ 链外单跑 sweep 当门」进 17.5 纪律行 | ✅ 双次复现 |
| falsify 五臂 | 读 `_tools/spr38_q3_falsify2.txt` ＋ 源码 :310-337 | W1 1/0/0、W2 0/0/1（实据=刀日志失踪）、W3 0/0/1（实据=档案在但抽不出红行）、W4 0/1/0、W5 0/1/0；总判定式含 `ui==ub+2 ∧ it==bt+6 ∧ w_ok`（F5/F6 白名单正反两形也在）；`VERDICT=ALL_DETECTED` | ✅ |
| armtest 八臂 | 读 `_tools/spr38_q3_armtest.txt` ＋ `spr38_q3_armtest.sh` 全文 ＋ 夹具目录 | A 正对照 TAU=0/arm_rc=0；B–H 七臂各见红且 arm_rc=1；F 臂喂 rc=1 即判红（UNEXECUTED 不当阴性）；夹具 mk() 带「造错落地」自证（orphan/stale/noverdict 三臂还断言了差异真存在，HP-10① 合规）；`passed=8/8 VERDICT=ARM_HAS_TEETH`。**注意 B/D/G/H 四臂的夹具文本仍带 X1 前旧措辞「本轮只打数、不进 FAIL」**——判据段吃的是数值字段，措辞陈旧不影响有牙，如实记 | ✅ |
| wiring 自证与验证 | 读 `_tools/spr38_q3_wiring_selftest.txt`／`_tools/spr38_q3_wiring_verify.txt` | selftest：现场闸三态＋BLOCK 七要素＋**禁 tr -dc hits=0**＋禁 TAU_PENDING hits=0 ⇒ `GUARD_HAS_TEETH`；verify：判据段七项盘面核对＋TAU_PENDING 残留=0＋`bash -n` rc=0 ⇒ `WIRED_OK` | ✅ |
| F3 病灶复算 | 拿 census3 汇总行实跑两种取法 | `tr -dc '0-9'` → **1230**、`sed 's/.*=//'` → **0**；`T3B_UNLISTED=0` 行 → tr 法 **30**。申报的两个失真值逐字复现 | ✅ |
| `tr -dc` 全仓残留 | grep `_tools/*.py *.sh`＋`production/**/*.md`＋scripts | 除 wiring.py :145/:147 的**注释与禁形名单**外，全仓零使用 | ✅ |
| 文档面 8 处订正 | Read 交付 :131/:134/:221、值守 :89/:137/:156/:200/:266 ＋ docfix_dry/before/after；**落稿后二次复查**：值守 :156 现盘上确有「当时快照，已作废；现绿基线 dc622351…」注（首查读到旧文本＝并发写隔了一手，你的申报正确）；docaudit 两件仍盘上但内容已随实时窗口重排（before/after 末两行现同为 issues=1、after 的 hex 清单回到 `[]`） | 落稿时点：8 处全部「当时快照·已作废＋现绿件 dc622351…」句式在位；docfix 启动即实读 bak==盘上（`dc622351…` 相等 True）⇒ @GREEN@ 由实读派生（HP-11① 合规）；锚 8/8 唯一；行数不变（split 口径 252/270，即 wc 口径 251/269）。⚠️ 「selfaudit 前后 issues=1 不变＋hex 清单变列出 dc622351」这半句**二查不可重放**——现在盘上的 after 不是 R8 那一份，该半句降级为「当时实测·以 `_tools/spr38_r8_docfix_dry.txt` 与台账转录为准」 | 🟡 订正在位、机检取证漂移 |
| 磁盘卫生 | `git status --short scripts/` ＋ md5 | game_main `057d7a2d…`、player `dc622351…` 均未动；本节之前零写盘（除我重跑的只读普查取证件）；冻结照旧 24 OK／10 FAILED 不刷 | ✅ |

**结论先行**：**F1＝三条前置全部实证达成，终态翻转合法生效，「待裁清单清零」宣告成立**（附一条归因订正＋一条观察项，均不撤销宣告，见 17.1）；**F2＝追认为 X1 第⑤条，进终态前置**（附一条补牙单，见 17.2）；**F3＝归 HP-11② 的镜像形态、不新开 HP 号；通用取数口径立为编程侧规矩（不占号）；定 A 类缺陷**（见 17.3）；**F4＝选 (a) 为主体＋一条台账义务，⛔ 动 .gitignore、⛔ 转录进版本库**（见 17.4）。通报两件收讫，见 17.4 末。

## 17.1 F1｜终态翻转是否已合法生效：**结论＝采纳「已达成」，宣告成立；附一订正一观察**

逐条对账 §16.6 三前置：

1. **①X1 上线且首条豁免挂证**——达成。豁免机制在 sweep 源码（X1_WAIVED/knife_proof/split_waived/UNUSED 检测四件套），首条豁免在 census3 与我自己的重跑里都挂证成立（WAIVED=1、red_hits≥1、STALE=0、UNUSED=0）。
2. **②接线落地且 gates 跑到 chk_taut**——达成。gates.sh 判据段六要素齐；armtest 从盘上现抽该段跑八臂全过；链内打点 `spr38_g_chk_taut rc=0 verdict_hit=1` 在 `_tools/spr38_run.gates.log` :24-26（件名订正见下方「订正一条」）。
3. **③UNLISTED 升级生效**——达成。判据段 `[ "${unl:-0}" -eq 0 ] || TAU=1` 在位，H 臂实证见红。

**你问「这算不算待裁清单清零宣告已达成」——算。** 清单两案今日物理消失：F02 改写后从普查消失（_og 段 T3=0），shrine 条转为刀证豁免且有反证档案；白名单外新增 T3/T3b、孤儿豁免、抽取缺口、STALE/UNUSED 五类都有会红的门。§16.6 那句话的三个条件同时满足，翻转即生效，⛔ 再等任何追加许可。

**订正一条（证据件名报错，事实本身站得住）**：你把「链内打点 rc=0 verdict_hit=1」申报为在 `spr38_r8_gates_chain.txt` 可指认——我二查该文件全文到末行是 `RUN-RED 文档面 spr38_report_selfaudit rc=1`（第 5 步因另一窗口的旧常量 RED，V-H #14 自动生效，你据此不作收官证据是对的），**chk_taut 打点并不在这份文件里**；它在 **`_tools/spr38_run.gates.log` :24-26**。⇒ 台账转录时把件名改对；这一错不伤 F1 结论，因为②的证据本体（gates 盘上判据段＋armtest 现抽现验）我已独立复现。另按 V-H #14 重申：`r8_gates_chain.txt` 只证到 gates 步与 RUN-RED 为止，前置②的合格佐证＝ gates 盘上件＋armtest＋run.gates.log 三件，今后引用以前三者为准。

**观察一条（不阻塞、不撤销宣告）**：终态语义今天是「双保险」——sweep 自己在 STALE/UNUSED 时 rc=1（件级），gates 判据段再核一遍（门级）。若将来有人把 sweep 的 `return 1` 软化成只打行，gates 面仍拦得住；反之亦然。这是冗余不是缺陷，登记即可，⛔ 借机收敛成单层。

**给编程侧的动作**：台账记「§16.6 终态翻转前置三条已于 R8 全部实证，阈值翻红生效」；证据件名按上述订正；后续任何轮引用「清零宣告」时带上本节 17.0 表第一列的取法。

## 17.2 F2｜`WAIVER-UNUSED`：**结论＝追认为 X1 第⑤条（进 FAIL），并进 §16.6 终态前置；牙按现有形状认可，另补一把 I 臂**

先定性：你 ④ 管「档案比判据活得短」，你加的这条管「名单比判据活得久」——**同一味病的两个方向**，症状都是豁免挂了不存在的账。HP-9 的精神（引用会腐烂）正穿在这个形状上：X1_WAIVED 里的 cond 句子是对 player.gd:1192 那行的**活引用**，判据被删/改写而名单不动，豁免档就变成一张永久免检通行证。这不是「扩形态」，是把 ③（白名单外新增必红）的镜像补齐——③拦「进来不登记的」，⑤拦「出去了还挂着登记的」。若不判红，将来谁删掉 shrine 那条断言，名单留个空挂，普查照样 CLEAN_EXEC，等于自己造了一个 §16.1(B) 驳回过的「纸面门禁」。**追认，进 FAIL，形态不再讨论。**

**进不进 §16.6 终态前置**：进——作为①的组成部分（「X1 机制上线」从来指整套豁免生命周期，不是只指 happy path），⛔ 另立第四条前置。R8 现状 UNUSED=0，翻转日已满足，无追溯问题。

**牙的认定（你如实报了 UNUSED 没配刀，我核过构造，判定如下）**：W4/W5 证的是匹配谓词 `label 全等 ∧ cond in it`——W4（文件标签变）与 W5（句子片段变）各自单独破坏合取，两臂合起来使「条目从名单键之下脱出」的两根轴都被覆盖；脱出即 `hit is None` → bad_list → 可疑>0 → 终态阈值红，所以**在真件语义下 UNUSED 与 W4/W5 火的是同一个谓词**，反向证成立，现有形状我认可。但严格讲缺一条**正向臂**：证「unused 分支真的会触发 `VERDICT=WAIVER_STALE` 且 rc=1」——现在 gates 面的 `stale_all+unused_all` 判红只有 D 类夹具间接碰过，没有一条臂直接拿「名单非空、used 为空」的真件输出喂进去。⇒ **补 I 臂**：夹具＝CENSUS 文本里摘净全部 `WAIVED` 行并把汇总行 `可疑(T1+T2+T3)` 顶回 1（等价于「判据没了、名单还在」的产物形状），期望 `TAU=1 且 unused_all=1 且 arm_rc=1`；落进 `spr38_q3_armtest.sh` 的 spec 列表，`passed=N/N` 声称随之更新（⛔ 文档先改后改链，沿用 A22 §5 的顺序纪律）。补完这把，⑤才算全牙。

**给编程侧的动作**：①台账记「WAIVER-UNUSED 追认为 X1-⑤，FAIL 级，属终态前置①」；②`spr38_q3_armtest.sh` 加 I 臂并复跑，证件落 `_tools/spr38_q3_armtest.txt`（覆盖式重生成可以，它是产物不是历史）；③sweep 头注里「自查加的一条（不在 ①–④ 里）」一句改为「X1-⑤（R8 §17.2 追认）」，消除临时感。

## 17.3 F3｜`tr -dc` 数值抽取 bug：**结论＝①归 HP-11② 镜像形态、⛔ 新号；②立通用口径为编程侧规矩（不占 HP 号）；③定 A 类缺陷（下一触碰者必修），已修即结案、留常驻禁形**

**①归类**。这个病和 HP-11 是同族不同代：HP-11 钉的是「不变量值的真源有两个」（常量 vs 盘上实物）；这里真源只有一个（普查产物），坏在**读取它的抽取面**——`tr -dc '0-9'` 把标签里的档位号当值抽出来，于是闭环判据拿 1 比 1230、恒不等。它不是 HP-8（HP-8 管命中数为 0＝这趟车没上），也不是新病：它就是 **HP-11②「⛔ 拿硬编码快照覆盖实读」的镜像——拿失真的读数冒充实读**。故：**并入 HP-11 家族记账，具体挂在 ② 的一致性哨兵语义下（哨兵两侧必须同源同形，抽取失真＝哨兵失效），⛔ 新开 HP-12**。理由：为单个写法开新号会让 HP 系变成写法大全；编号通胀本身就是 §16.4 已经警惕的那种稀释。

**②全仓扫与通用口径**。我实扫：`tr -dc` 在 `_tools/`、`production/`、`scripts/` 现存使用＝**零**（wiring.py :145/:147 是注释与禁形名单，属消毒后的疤不是伤口）。⇒ 存量无需整改。通用口径**立**，措辞（转录台账即可）：

> 🟡 **取数口径（编程侧规矩，不占 HP 号）**：凡从**含数字的标签串**里抽数值（`可疑(T1+T2+T3)=N`、`T3B_UNLISTED=N`、`checked=N declared=N` 这类），一律 `grep -o '<完整键>=<值形>'` 后 `sed 's/.*=//'`，或 `grep -oP '(?<==)\d+'` 之类**以分隔符为界**的式子；⛔ `tr -dc '0-9'`、⛔ 任何「把所有数字留下」的清洗。禁形检查（wiring `--selftest` 的 `block 禁 tr -dc`）随接线常驻，保留、⛔ 撤。

不升 HP 的理由：它有明确的机械抓手（禁形扫描）且已被 V-H #11 的「先核命中数再核值」半句部分覆盖；升号只会摊薄 HP-11/HP-8 各自的靶心。若将来第二例出现且禁形抓不住，再议升格。

**③定级**：**A 类（下一触碰者必修）**，与 §15.1.4、§16.3 同族。判定依据＝它曾让**闭环判据在真产物上恒不等**——这是判据失效不是显示失效，属于「下一触碰者若再往这段判据上加东西就会踩空」的雷。本轮你已修＋立禁形＋加了「记账面(可疑−豁免)==汇总面」的独立算式（这条算式本身是把 HP-11② 三方一致落到抽取面，追认），⇒ **本案结案**；A 类的意义转为**常驻义务**：任何后续轮次重写/迁移 chk_taut 判据段时，禁形项必须随迁，台账在每轮 gates 变更回执里勾一次「tr -dc 禁用仍在」。

## 17.4 F4｜豁免档案的存活面（`_tools/` 不进版本库）：**结论＝选 (a) 主体＋一条台账义务；(b)(c) 均驳回；⛔ 动 `.gitignore`**

我实坐实的现状：`.gitignore:6` = `_tools/`（`git check-ignore -v` 命中）；`git ls-files _tools | wc -l` = 0；`spr38_good_player.bak`、`spr38_q2_knife.log`、整套 gates/wiring/sweep 全不在库里。你推演的后果属实：**新工作树首轮 gates 必 WAIVER-STALE 判红**。

**(a) 采纳，且我要把它说得更硬一点：这轮红不是「正确代价」，而是机制在被检验时应有的行为。** 豁免制（X1）的本义＝「证据来自失败真的发生过」。新树里没有那次失败的痕迹 ⇒ 系统拒绝继续免检，这正是设计意图在工作；如果新树开箱全绿，才说明豁免档是靠「档案不存在也照样绿」活着的——那是 HP-8 的空头名帖换了个马甲。配套可行性我也核了：重建路径真实存在——`spr38_q2_shrine.sh` 的前置闸吃 `${Q2_PG_OLD:-df57d7dd…}`，新树绿基线是 `dc622351…`，**环境变量注入即可过闸**（`Q2_PG_OLD=<新树绿件>`），不必改脚本；但它会重做 §15.2.1 拆分（新树上 split 步骤应 ANCHOR-FAIL 幂等拒——**这一点未实测**，如实标注），且要 Godot＋独占锁。⇒ 接手 SOP 一句话进台账：**新树首跑 gates 见 WAIVER-STALE ＝预期红，处置＝走独占链重生成刀档案（env 注 Q2_PG_OLD），⛔ 删名单条目、⛔ 放宽判据。**

**(b) 驳回**。三个理由：其一，把红行「转录」进版本库＝再造一个硬编码快照——正是 HP-11① 说的「真源只有一个＝盘上实物」的反面，转录件与被指日志从此是两个真源，还会互相掩护；其二，落点哪边都不干净——`_backup/` 同样被 ignore（实测 .gitignore:9），落 `production/sprint-38/` 附件则要把一次性刀的原始产物升格成正典文档，语义不对；其三，动 `.gitignore` 属作者保留域（配置级变更），你我都没裁它的权限，**我不会明写动它**。若作者返岗后主动要求把门禁件整体入库，那是另一个案（牵动 34 个 .gd 之外的整条工具链血统认定），届时再立。

**(c) 驳回，你的直觉是对的**。把红行片段直接写进名单常量＝豁免不再指向任何外部反证，名单自己证明自己——AGENTS §5 第三类（同源自比较）的镜像，X1 的全部价值就是靠「证据在判据之外」站着的那口气，(c) 一口给它咽回去。

**附加义务（采纳你动机里那句「只能靠再跑一次重生成」的合理内核，但不引入新档案）**：`spr38_q2_knife.log` 的关键行（`[ERR] shrine` 红行原文＋clean/post 的 ERR=0 行＋`VERDICT=TEETH_YES` 行）**转录进台账当执行痕迹**——沿用 N-20/N-21 既有范式（台账转录＝历史叙述，⛔ 机检输入，两者不打架：knife_proof 永远只认盘上日志文件，台账转录⛔ 顶替它）。这样即使日志本体丢了，接手者也有一份可对照的「当时确实红过」的文字凭证，重生成后有对账基准。

**通报两件收讫（不裁）**：①A22 队列第 2 条与 §16.3 的冲突——你按 §16.3 不碰 `spr38_report_selfaudit.py` 正确；台账该条**不得当作欠账挂着**，请在台账 A23 动作区改写为「5 件牙口并进 selfaudit ⇒ 归另一窗口（§16.3 归属裁定），编程侧⛔ 认领」，避免下一轮又排给自己；②`r8_gates_chain.txt` 不作收官证据的处置符合 V-H #14/§16.3，收讫——连同 17.1 的归因订正一并转录（该文件其实连 chk_taut 打点都没有，佐证以 run.gates.log :24-26 为准）。

## 17.5 记账更新（替换 §16.6 对应行；追加式，⛔ 回改旧表）

| 项 | 状态 |
|---|---|
| §16.6 终态翻转前置三条 | ✅ **全部达成（R8 实证，17.1）**；「待裁清单清零」宣告成立，终态阈值（非豁免可疑>0 或 UNLISTED>0 ⇒ FAIL）生效 |
| 前置②的证据件名 | 🔴 订正：chk_taut 链内打点＝`_tools/spr38_run.gates.log` :24-26；`spr38_r8_gates_chain.txt` 止于 RUN-RED（第 5 步），⛔ 作此用途引用 |
| WAIVER-UNUSED | ✅ 追认为 **X1-⑤**（FAIL 级，属终态前置①组成）；📋 补 I 臂（正向 unused⇒rc=1）进 armtest，补完才算全牙 |
| `tr -dc` 抽取失真 | ✅ 本案结案（已修＋禁形常驻＋独立算式追认）；🟡 通用取数口径立为编程侧规矩（17.3② 框内措辞，⛔ HP 号）；A 类常驻义务＝chk_taut 判据段迁移时禁形随迁 |
| 豁免档案存活面 | ✅ 裁=(a)＋台账转录义务；(b)(c) 驳回；⛔ 动 `.gitignore`；📋 新树 SOP 一句话进台账（17.4） |
| A22 队列第 2 条（并进 selfaudit） | 🔴 改登：归另一窗口，编程侧⛔ 认领（§16.3 维持） |
| 文档面旧基线 8 处订正 | ✅ **结案（订正在位＝二查实读值守 :156 等八处句式均在盘）**；🟡 取证件限定：docaudit before/after 已被实时窗口重排，「selfaudit 前后 issues=1＋hex 清单变化」半句⛔ 再引用那两份文件自证，改以 docfix_dry＋台账转录为历史凭证 |
| 行数口径纪律 | 🟡 重申 §16.0 裁定：**行数一律 `wc -l` 现取现报**；split/grep-c 混用会在无尾换行文件上差 1（本轮 gates 130 vs 131 实例）。工具打印的 split 口径须自注口径 |
| sweep 件对 UNLISTED 的 rc 语义 | 🟡 登记事实：`T3B_UNLISTED>0` 时 sweep **rc=0**（X2-b 拦截只在 gates 判据段），⇒ ⛔ 链外单跑 sweep 当门、⛔ 拿它的 rc 证明 UNLISTED 有牙（牙在 armtest H 臂＋gates 面）；不改实现，只改引用姿势 |
| 素材侧 D:\大纲 / .gd / commit / 冻结 / push | ⛔ 本轮零接触、零改动、零提交、零刷表、零推送（我仅跑只读普查，产物落 `_tools/spr38_r7_owner_census_recheck.txt`） |

## 17.6 本轮收尾自证

- 本节所有数出自我自己实读实算：gates/sweep/wiring/armtest/falsify/selftest/verify/census2/census3/docaudit×2/knife.log/q2_shrine.sh/t3_knife.py 诸件通读；md5/wc/mtime 现取；`tr -dc` 与 `sed 's/.*=//'` 两法拿真产物现场复算（1230 vs 0 逐字重现）；`grep -rn "tr -dc"` 全仓扫（除消毒疤零命中）；`git check-ignore -v`／`git ls-files` 坐实存活面；**并以只读方式重跑了一次全量普查**（零 Godot、零写盘，结果与 census3 逐格相同）。
- 我没有重放的：armtest/falsify/selftest 五套造错臂（它们全是只读夹具＋eval 判据段，产物已在盘且内部自洽度高，我以逐行读码代替重放；若要我实跑请下轮点名）；q2_shrine.sh 重生成路径（要 Godot，且其中「新树上 split 步骤幂等拒」我标了未实测）。
- **落稿后追加的二次复现**（本轮最后一步，如实报）：①只读普查原样重跑＝与 census3/首查逐格相同（本表最硬一格）；②值守 :156 复查＝订正句式确在盘上——**首查读到旧文本是并发写隔手，编程侧申报正确，我首查的「✅」当时即已给对，无需收回；需要收回的反而是 docaudit 那半句取证**（after 文件已被实时窗口重排，hex 清单变化不可再自证）；③`spr38_r8_gates_chain.txt` 仍在盘。⇒ 这次漂移本身成为 F4 的一条实证：取证件与被指日志同活在 `_tools/`，被改写是常态，台账转录义务必须落。
- 未重开项：§十五/§十六 全部原判（X1 三元组键、X2 升级、X3/HP-11、F02/Q2 结案、Q2 刀措辞钉死）、HP-8/9/10、V-H #11–#14、冻结与放行、sprint-33 banner——一律维持；本节只做追认、补裁与订正，⛔ 回改旧章节原文。

