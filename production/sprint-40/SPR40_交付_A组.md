# SPR40 交付_A组 · 近战清扫漂浮弹幕（S40-a／A1~A6）

批次：Sprint 40 · A 组
日期：2026-11-18
交付人：编程侧
核验人：`六道卷游戏 · 主理人`（独立核验，本件不代替其结论）
配套判据：`SPR40_实施单_编程侧.md` §7（六段格式）、`SPR40_主理人裁定_R1_C1C6与探针口径.md` §5（六项回账）、`SPR40_验证口径.md`（V-S1~V-S4）

**一句话状态**：A 组口径全部落地，改后 10 面门控 + 清扫面 56 条全绿（`checked==declared`、`[ERR]=0`、`ok=false=0`、`SCRIPT_ERROR=0`、`validate problems=0`），四把变异刀 + 一把归因对照刀全部咬住，E1 三档指纹串逐字节不变。**但本件同时申报两条不属于 A 组代码的红（§5 P-4 冻结普查期望过期、§5 P-5 并发窗刀没还原）和一条口径用错（§5 P-8 指纹不能当主流探针）**，三条都要求主理人处置，编程侧⛔ 自行抹平。

---

## 0. 代码面落点（本批改了什么）

| 文件 | 改前 md5 | 改后 md5 | 改动内容 |
|---|---|---|---|
| `scripts/bullet.gd` | `aa687ff422fbe682440db19e48f5673e` | `95370e21eec900789d2d53284fe82fd1` | 新增 `is_sweepable()` 单一真源 getter（A1，7 个行为位 + `not friendly`） |
| `scripts/player.gd` | `dc622351a75e8da9d943d72332ec2a28` | `2364e3b156ab6e4e1b34965851dfcd7d` | `_swing()` 内新增扇形清扫块（A2~A4，排在暴击抽取**之后**）＋ 两个 `static var`（A6 遥测） |
| `scripts/game_main.gd` | `057d7a2d741e3cc5f0aca7138e42a43e` | `bf719278d6a1a1669d9f22f72b405924` | `SMOKE_SWEEP` 探针块（A5，`_SW_DECLARED=56`／`_smoke_sweep_probe()`）＋ 源码次序断言 |
| `scripts/weapons.gd` | `315e9283d6b879eb5a1717a048c54dfd` | **未动**（同值） | A 组不涉及武器表 |

绿件转正链（归档逐份留盘，`_tools/spr38_good_player.<md5>.bak`）：`dc622351` → `4f907fbb`（清扫块首次落地）→ `2364e3b1`（现役）。归档闸自证：`RUN 归档闸 绿基线配套归档已核 |ARCHIVE-GATE GREEN 现役绿基线有逐字节相同的配套归档 归档=3 份|`。

🔴 冻结面申报（不粉饰）：`scripts/bullet.gd` 因 A1 新增函数**离开了 `SPR21-FROZEN.md5` 的匹配集**，冻结普查由 `24 OK / 10 FAILED` 变成 **`23 OK / 11 FAILED`**，新增的恰好只有它一条。⛔ 编程侧自刷冻结表（红线 #8），重登归作者／主理人 ⇒ 详见 §5 P-4。

证据目录：`_tools/spr40_base/`（改前 18 件）、`_tools/spr40_after/`（改后 15 件 + 3 份指纹 selftest 抽取件）、`_tools/spr40_sweep/`（清扫面日志 + 56 行断言对照表）、`_tools/spr40_det/`（同码同种两跑＝噪声底）、`_tools/spr40_knives/`（四把刀 × 3 件）、`_tools/spr40_attrib/`（归因对照刀）、`_tools/spr40_d1/`（D 组探针）、`_tools/spr40_churn.txt`（对账表全文）、`_backup/spr40_sweep/before.md5`（改前 34 件快照）。

---

## 1. 改前基线（HP-0，独占窗内跑全套门禁到独立目录）

环境一律 `SMOKE=1 SMOKE_SEED=12345 [--quit-after 3200]`，指纹面另加 `SMOKE_META_FINGERPRINT=1`（seed 12345／777／42），每次跑前擦 `%APPDATA%/Godot/app_userdata/test_1/_smoke_*.cfg*`。

| 项 | 实测（改前） |
|---|---|
| ① fingerprint 串 | 见下方三条逐字串（floor=1） |
| ② `validate problems` | **0**（10 面各 1 条，`grep -o 'validate problems=[0-9]*'` 全量 = `20×"problems=0"` 含改后） |
| ③ 探针 checked/declared | melee `94/94`（且 `swings_total=57 draws_total=57`）；stance `7/7`；sc `19/19`；base/apply/rng/pw/fp 面无 done 行（该四面的判据在 `S38-*`/`MG-*` 行里） |
| ④ `[ERR]` 计数 | **0**（10 面全部） |
| ⑤ `ok=false` 计数 | **0**（10 面全部）；`SCRIPT ERROR` 亦 **0**（V-H #8：死构建的 `okfalse=0` 是假绿，故单列） |

改前指纹串（逐字，改后完全相同 ⇒ 见 §2）：

```
seed=12345 [SMOKE-META] fingerprint floor=1 rooms=(-1, 0),(-1, 1),(0, -1),(0, 0),(0, 1),(0, 2),(0, 3),(1, 1),(2, 1) kinds=secret,treasure,shop,start,combat,elite,super_secret,elite,boss
seed=777   [SMOKE-META] fingerprint floor=1 rooms=(-1, -1),(-1, 0),(-2, 0),(0, -1),(0, 0),(0, 1),(0, 2),(1, 1),(2, -1),(2, 0),(2, 1) kinds=treasure,cursed,super_secret,secret,start,elite,shop,elite,boss,combat,combat
seed=42    [SMOKE-META] fingerprint floor=1 rooms=(-1, -1),(-1, 0),(0, -1),(0, -2),(0, -3),(0, 0),(0, 1),(1, -1),(1, -3),(2, -1),(2, 0) kinds=treasure,secret,combat,combat,elite,start,super_secret,challenge,boss,combat,shop
```

清扫面在改前**不存在**：`SMOKE_SWEEP` 未开 ⇒ 无 `done checked=` 行。这就是 HP-0 的意义——本批新增的 56 条判据在改前树上一条都跑不出来，⛔ 拿改前日志的「没红」当「过了」。

---

## 2. 改后同五项

| 项 | 实测（改后） | 与改前的关系 |
|---|---|---|
| ① fingerprint 串 | 三条逐字同上（长度 161／192／199 字符） | **逐字节相同**；`cmp` 整份 `fp<seed>.full_selftest.txt` 亦相同（175／206／213 字节） |
| ② `validate problems` | **0**（含清扫面，11 面） | 不变 |
| ③ 探针 checked/declared | melee `94/94` 且 `swings_total=57 draws_total=57`；stance `7/7`；sc `19/19`；**sweep `56/56`（新增）** | 既有三面**逐字不变**；新增面 `declared` 是循环展开后的实数 56 |
| ④ `[ERR]` | **0**（11 面） | 不变 |
| ⑤ `ok=false` / `SCRIPT ERROR` | **0 / 0**（11 面） | 不变 |

关键恒等式未被本批扰动（V-S3／V-C1 的正证）：

```
[SMOKE-MELEE] done checked=94 declared=94 swings_total=57 draws_total=57     # 改前
[SMOKE-MELEE] done checked=94 declared=94 swings_total=57 draws_total=57     # 改后（逐字相同）
```

近战面的 57 次挥击 ↔ 57 次主流抽取的 1:1 账本，在清扫块插入后**一个数都没动**——清扫排在该次抽取之后，不新增、不减少、不参与命中判定。

---

## 3. churn：只比断言行（`SMOKE_SEED=12345` 已钉）

比对口径：只取以 `[SMOKE…`／`[S38-…`／`[VH…`／`[MG…`／`[SW…` 开头的探针行做 `diff`，其余引擎噪声不进账。全文 `_tools/spr40_churn.txt`。

| 面 | 改前行 | 改后行 | 漂移行 | `ok=false` | 定性 |
|---|---|---|---|---|---|
| base | 133 | 133 | 114 | 0 | 遥测噪声（同码同种两跑即 109，见下） |
| melee | 212 | 204 | 138 | 0 | 噪声 + **两条可机械归因**（#43／#94，见 3.2） |
| stance | 136 | 129 | 121 | 0 | 遥测噪声（**已做归因实验**，见 3.3） |
| apply | 145 | 177 | 152 | 0 | 噪声 |
| rng | 138 | 149 | 123 | 0 | 噪声 |
| sc | 149 | 132 | 109 | 0 | 噪声 |
| pw | 128 | 143 | 111 | 0 | 噪声 |
| fp12345 | 106 | 152 | 152 | 0 | 噪声（指纹串本身逐字节相同，见 3.4） |
| fp777 | 121 | 135 | 102 | 0 | 噪声 |
| fp42 | 112 | 109 | 109 | 0 | 噪声 |

`CHURN-DONE red=0 blind_faces=无`（十面全部有断言行命中，⛔ 零命中面被当成绿——V-H #11 卫生；首版脚本正是栽在这里，报过假绿，已修）。

### 3.1 噪声底（先证明「漂」不等于「坏」）

同一份码、同一个种子、跑两次（`_tools/spr40_det/base.1.log` vs `base.2.log`）：

```
断言行 130 vs 121，漂移 109 行
```

⇒ 现役码自身的 run-to-run 抖动就有 109 行，改前→改后的 base 漂移 114 行与之同量级，**不可归因于本批**。自动驾驶遥测（`[SMOKE]`／`[SMOKE-CAM]`／`[SMOKE-NAV]`／`[SMOKE-E]`）记的是墙钟相关的位置／时间／房间态，从来不是确定性的。

配套的结构证据：base／apply／rng／sc／pw／fp 六面 `ml_` 关键词命中数 **0/0**（改前后都是 0）⇒ `_swing()` 在这些面**一次都没执行**，清扫代码块在结构上不可达，其漂移只可能是噪声。

### 3.2 两条能机械归因的 melee 面漂移（都是断言**自指源码**造成的，非语义变化）

```
< [SMOKE-MELEE] #43 B9 自证·_swing 源码段存在（39 行）且无破坏通路入口 … ok=true
> [SMOKE-MELEE] #43 B9 自证·_swing 源码段存在（54 行）且无破坏通路入口 … ok=true
< [SMOKE-MELEE] #94 D5 反证·该段确为 _swing 本体 measured=1401/true expect=1401/true ok=true
> [SMOKE-MELEE] #94 D5 反证·该段确为 _swing 本体 measured=1932/true expect=1932/true ok=true
```

`_swing()` 从 39 行变 54 行、字符数 1401→1932，正是本批插入的 15 行清扫块；两条断言的期望写的是「存在／非空」，不锁死长度 ⇒ 两侧都 `ok=true`。**如实报：这两条判据是「自指源码」型，天然会随任何 `_swing()` 改动漂移，不具备回归探测力**（要探测力在清扫侧由 §4 的四把刀提供）。

### 3.3 stance 连带面归因实验（窗口 4，`bash _tools/spr38_run.sh` + `RUN_CMD='bash _tools/spr40_attrib.sh'`）

比的是 `[SMOKE-STANCE]` 的**汇总行**（⛔ 比首行常量）：

```
改前留档   shots=96  window=231 moving_window=230 blocks=58/58 released=7 leaks=0 死亡打断=0 闩锁未结算=1 done checked=7 declared=7
现役码 #1  shots=93  window=234 moving_window=234 blocks=58/58 released=7 … done checked=7 declared=7
现役码 #2  shots=90  window=234 moving_window=233 blocks=69/68 released=7 … done checked=7 declared=7
k5 摘清扫#1 shots=92  window=231 moving_window=229 blocks=55/53 released=7 … done checked=7 declared=7
k5 摘清扫#2 shots=100 window=236 moving_window=235 blocks=55/54 released=7 … done checked=7 declared=7
```

三条独立证据指向同一结论：

1. **同码两跑自身就漂**：现役码 #1 vs #2（93 vs 90 shots，58/58 vs 69/68 blocks）之差，与改前→改后之差同量级；改前 96 落在两跑的区间里。
2. **摘掉清扫语义照样漂**：k5 之后两跑 92 vs 100、window 231 vs 236，漂幅不小于带清扫的现役码 ⇒ 漂移不由清扫通路产生。且 k5 的自证成立：`C) k5 生效自证 | SMOKE_SWEEP 面 ok=false=14（>0 ⇒ 对照真摘掉了清扫）`。
3. **判定项七字段逐字相同**：`len=0.3333`、`leaks=0`、`released=7`、`死亡打断=0`、`闩锁未结算=1`、`done checked=7`、`declared=7` 在改前／现役×2／k5×2 五跑里一个字符都没变；`shots/window/moving_window/blocks` 是遥测计数，不进 `checked`。

⇒ **stance 面连带漂移定性为遥测噪声，非本批回归。** 附加结构证据同 3.1：stance 日志 `ml_`=0、无 melee 行，`_swing()` 未执行。

### 3.4 指纹与机检件逐字节

```
FP-12345 GREEN 逐字节相同 (175 字节)    FP-777 GREEN 逐字节相同 (206 字节)    FP-42 GREEN 逐字节相同 (213 字节)
CHK spr38_g_chk_fp        GREEN 逐字节相同
CHK spr38_g_chk_verbatim  GREEN 逐字节相同
CHK spr38_g_clause        GREEN 逐字节相同
CHK spr38_g_chk_quota     漂移（可归因，见 3.5）
CHK spr38_g_chk_taut      漂移（可归因，见 3.5）
```

### 3.5 两个机检件的漂移逐条归因（都不是判据被改）

- `chk_quota`：`equip_calls=14 → 29`。A5 新增 15 个 `_ml_equip(...)` 站点（清扫探针自己的摆位调用），oracle_block／defs_block 不变 ⇒ 是「计数口径随新增站点自然增长」，⛔ 该数被任何断言当判据。
- `chk_taut`：`Dev.check 站点 285 → 287`、`game_main.gd grep=53 → 55`（+2 = A5 新增的两个 `Dev.check` 记账站点）；T3b 三行（`game_main.gd:2583`、`player.gd:1576`×2、`player.gd:1959`）**内容逐字相同、只有行号随插入平移**；`STALE=0`、`T3B_UNLISTED=0`、`WAIVED` 无孤儿。

---

## 4. 变异刀清单（声明的应红断言 → 实测红条）

驱动：`bash _tools/spr38_run.sh`（独占窗）内 `RUN_CMD='bash _tools/spr40_knife.sh'`；补丁器 `_tools/spr40_knife_patch.py` 先断言每个锚点在全文件**恰好命中 1 次**且**行数守恒**，否则整批拒绝写盘（`KNIFE-ABORT …（未写盘）`）。每把刀跑完当场还原并 `md5sum` 逐字节自证。

| 刀 | 动作（删哪行／改哪个常数） | 目标文件 | 声明应红 | 实测红条 | 数 | 还原自证 |
|---|---|---|---|---|---|---|
| k1 | 删 `is_sweepable()` 里的 `not friendly`（友方弹也当漂浮死物扫掉） | `bullet.gd` | `09 18` | `#09 #18 #19 #20` | 4 | `md5 95370e21… GREEN` |
| k2 | 清扫整段挪到暴击抽取**之前**（违反「⛔ 排在抽取之后」次序） | `player.gd` | `37` | `#37` | 1 | `md5 2364e3b1… GREEN`（当窗） |
| k3 | 清扫循环内加一次 `Game.rng.randf()`（命中相关抽取） | `player.gd` | `31 33 35 37` | `#31 #33 #35 #37` | 4 | 同上 |
| k4 | 清扫段挪到 `_swing()` 首行（越过过载早退 ⇒ 过载也白嫖清场） | `player.gd` | `42 46` | `#42 #46 #37` | 3 | 同上 |
| k5 | `is_sweepable()` 首 token 改 `return false and (`（摘除清扫语义、保留 27 行代码＝归因对照） | `bullet.gd` | 不适用（对照刀，判据是「清扫面必须大面积红」） | `sweep 面 ok=false=14` | 14 | `RESTORE scripts/bullet.gd GREEN 95370e21…` |

首条红原文（逐字，供独立核验比对）：

- **k1（V-S1 反向刀，裁定件 §5 第 2 项点名这把）**：
  `[SMOKE-SWEEP] #09 S1 反例⑧friendly 全零弹（oracle 与硬编码期望同号） measured=true expect=false ok=false`
  连带：`#19 S2 bullets_swept 增量恰为 1 … measured=2 expect=1 ok=false` ⇒ 友方弹进了清扫集并被计入，正是「⛔ 把反例也计进去」那条判据要拦的。
- **k2**：`[SMOKE-SWEEP] #37 S4 清扫段源码零 Game.rng（V-S3 反证面第③条） measured=1 expect=0 ok=false`
- **k3**：`[SMOKE-SWEEP] #31 S4 N=1 落点 state==N=0 参考档落点 ⇒ 清扫颗数不进主流序列 measured=-2158352560253560225 expect=5922163526861011269 ok=false`（#33/#35 同族；`#37 measured=1` 同步红）
- **k4**：`[SMOKE-SWEEP] #42 S5 过载那一拍 swept 增量==0（⛔ 白嫖清场） measured=1 expect=0 ok=false` + `#46 …扇区里的弹仍在 measured=true expect=false ok=false`

🔴 口径如实报（§5 P-3）：k4 的实测比声明多了 `#37`。机制清楚——k4 把清扫段搬到抽取之前，等价于 k2 的次序破坏，源码次序断言顺带红。是**我声明的应红集少写了一条**，不是判据误红；下一轮该刀的期望集补成 `42 46 37`。

V-S1 反例构造姿势照裁定件 §2-b2 执行：8 个反例由 `BulletScript.new() + setup(...)` 显式摆位（`pierce/explosive/bounce/frost/homing/arc/cluster` 七位各占一颗 + 一颗 `friendly=true` 全零弹），**期望集在探针里逐条硬编码**（不是运行时用别的表达式现算），故 oracle 与探针互为独立；M-5 的「⛔ 内联重写条件」在此让位于 A1 的单一真源条款，红条 #09/#18 证明这条豁免没有把判据掏空。

---

## 5. 偏差申报（与本单／常规不符之处，逐条，⛔ 沉默处理）

**P-1｜实施单给的行号与盘上不符（已按现读锚定，未据旧号施工）**
`_ml_equip("rifle", 30)` 实际在 `game_main.gd:5340`（单上 `:5337`）；`DROP_POOL` 在 `weapons.gd:9`（同）；`player` 未知 id 回退在 `player.gd:260-261`（单上 `:254-258`）；`META_WEAPON_POOL_BASELINE` 串在 `game_main.gd:50`。全部按 `grep -n` 现读落点，施工用函数名／常量名为锚。

**P-2｜B 组（武器 id 迁移）盘点发现 4 个未列入 M1~M11 的真实碰撞点**（本批⛔ 动，仅盘点交回，见 §9）
1. `player.gd:1070` `ok = weapon_slots[1] == "shotgun"` —— 图鉴断言按旧 id 比较，改 id 不改这里 ⇒ 该条恒 false。
2. `menu.gd:171` 「退出游戏」按钮复用图标键 `wpn_launcher` —— M9 若把 `wpn_launcher` 从 `GEN_NAMES` 摘掉，主菜单按钮 `Assets.g()` 返回 null ⇒ **屏上白框零报错**（AGENTS §4.3 老坑）。
3. `meta.gd:71` `"icon": "wpn_launcher", "max": 1` —— 位于 `UNLOCKS` 内，受红线 #4 保护，⛔ 编程侧改。
4. `weapons.gd:88` `mw_cluster` 的 `icon` 同为 `wpn_launcher`，且 `validate.gd:633` 明文认可「mw_cluster 复用 wpn_launcher 是合法先例」 ⇒ 同一个图标键现有 **3 个非本族消费点**。
⇒ 结论：`wpn_launcher` **不能按「同位替换、数量不变」处理**，M9 需要主理人裁定是「保留旧键 + 另加 4 个新键」还是「连带改这三处（其中一处撞红线 #4）」。这是设计／口径题，本批不自裁。

**P-3｜k4 变异刀的声明应红集少写一条**（实测多红 `#37`，机制见 §4）。

**P-4｜文档面两条红臂＝登记表期望过期，非 A 组回归**
`RUN-RED 文档面 spr38_report_selfaudit rc=1`，两条 FAIL 原文：
```
FAIL 冻结实测 23 OK/11 FAILED/缺0 != 24/10/0
FAIL 绿基线或盘上件 != dc622351a75e8da9d943d72332ec2a28（刀没还原／基线过期）
```
- 第 1 条：`_tools/spr38_report_selfaudit.py:176` 把冻结普查硬编码成 `(24, 10)`；A1 让 `bullet.gd` 合法离开冻结集 ⇒ 实测 `23/11`。修法只有两个：**重登 `SPR21-FROZEN.md5`**（作者保留④／主理人登记，红线 ⛔ 我自刷）或**改自审脚本的硬编码**（红线 #8 明文禁止「改断言或冻结串让门由红转绿」，且脚本自己警告「⛔ 靠调表把 RED 抹平」）。⇒ 本批**两条都不做**，如实挂着。
- 第 2 条：`GOOD_MD5` 常量仍是 S38 的 `dc622351`，而现役绿基线已经本批两次转正到 `2364e3b1`；且该臂还会把**并发窗在飞的刀**（P-5）也算成「基线过期」。⇒ 需要带文档包的登记轮（S38 A23 同型工序）才能收，而那道工序要改的 `_tools/AUTORUN_值守报告.md` 被本批禁止事项 #11 明令⛔ 动（含⛔ 追加）。**已按裁定件 §3 遵守：一个字节没碰那两份台账。**

**P-5｜并发窗改用了同一棵树，且此刻刀没还原（盘上态≠本件基线）**
现读：`_tools/.spr38_run.lock` = `owner=pid-22009 at=2026-11-18 19:47:30 step=all`；`scripts/player.gd` 磁盘 md5 = **`930119374c817448c8d6d41fd4bfcb46`**（≠ 现役绿 `2364e3b1`），mtime 19:52:40；差异**只有 1 行**：
```
734c734
< 		e.take_damage(dmg, to_e.normalized(), crit)     （绿基线）
> 		e.take_damage(dmg, Vector2.ZERO, crit)          （盘上现值）
```
该串与 `_tools/spr38_mut.py` 的 knife `"3"` 目标串逐字相同 ⇒ 判定为**另一窗正在跑的 S38 变异刀在飞态**，不是真实改动；同窗还在写 `_tools/spr38_r33_wb_mk.py`、`_tools/_patch_mk_r33_c.py/_d.py`、`_tools/_patch_extract_r33_b.py/_c.py`（19:40~19:45），Godot 实例 pid 25028 于 19:54:03 起。
⇒ 编程侧处置：本轮之后**不再对 `scripts/*.gd` 下任何手**、⛔ 抢锁／放锁（并发纪律 + 手工碰锁禁令），A 组证据全部钉在 §0 的 md5 与留档日志上。⚠️ 后续任何门控复跑前必须先确认盘回到 `2364e3b1`，否则跑的是别人的刀态。

**P-6｜`--check-only` 误落件已改名保留**：`_tools/spr40_sweep/_DISCARD_check_only_不是门控.txt` 内容是 `SCRIPT ERROR: Compile Error: Identifier not found: Game`（`--check-only --script` 解析不到 autoload，本就不能当门控证据），旧名 `chk.txt` 会被读成「门控失败」，故改名留证不删。

**P-7｜新增两个 `static var` 的主动申报（红线 #9）**：`player.gd:114-115` `static var bullets_swept := 0` / `static var last_sweep_count := 0`。均**不进存档、不进 E1 指纹串**（实测：三档指纹串逐字节相同，§3.4），仅供探针读增量。

**P-8｜口径用错：E1 指纹不能当「主流未被扰动」的探针**（要主理人订正验证口径措辞）
`_smoke_fingerprint()` 的串来自 `_floor_rng(floor) = hash("%d:%d" % [Game.run_seed, floor_num])`，而 `Game.run_seed` 在主流任何抽取**之前**捕获 ⇒ 指纹**结构上对主流消耗免疫**，它只钉住 `run_seed` 与地图布局。§2 的「三档指纹逐字节相同」是**必要条件不是充分条件**；主流守恒的正证是清扫面 `#29~#37`（N∈{0,1,5,20} 的 seed/state 快照 + `draws==swings`）与近战面 `swings_total=57 draws_total=57` 恒等。D 组实测（§6）另给了一条**反例级证据**：既有的 `mw_cluster` 分裂扰动主流，而指纹看不见。

---

## 6. D 组三项实测的原始输出片段（贴句子，`_tools/spr40_d1/spr40_d1.log`）

探针是**独立场景**（`_tools/spr40_d1.tscn` + `_tools/spr40_d1_probe.gd`），⛔ 为测量而往 `scripts/*.gd` 加任何代码；跑法 `SMOKE=1 SMOKE_SEED=12345`，跑前跑后擦 `_smoke_*.cfg*`，`done` 行必须恰 1 条且 `SCRIPT_ERROR=0` 才认证。

```
[SMOKE-D1] ①分裂一次 | 新增子节点=3 | state -7751912382566491497 -> 560928343928037253 | 反查主流抽取次数=3
[SMOKE-D1] ②主链下游 5 值 | 未命中=["0.252042", "0.666673", "0.023082", "0.742242", "0.873262"] | 命中后=["0.742242", "0.873262", "0.977105", "0.638560", "0.737958"] | 逐字相同=false
[SMOKE-D1] ③指纹串(未命中) |fingerprint floor=2 rooms=(-1, -2),(-1, 0),…, kinds=treasure,secret,shop,elite,combat,start,challenge,combat,super_secret,elite,boss|
[SMOKE-D1] ③指纹串(命中一次)|fingerprint floor=2 rooms=(-1, -2),(-1, 0),…, kinds=treasure,secret,shop,elite,combat,start,challenge,combat,super_secret,elite,boss|
[SMOKE-D1] ③逐字相同=true | run_seed=12345 | 两态层 rng 首值=0.557104/0.557104
[SMOKE-D1] ④阳性对照 run_seed+1 串与③不同=true（⇒③的『相同』不是恒真比空串）
[SMOKE-D1] done
```

三项结论（D1／D2／D3 对应实施单 §4 三项，逐字片段即上）：
- **D-1｜`_split_cluster()` 每分裂一次吃主流 3 次抽取**（`Game.rng.randf() * 0.4` × 3，`bullet.gd:231-237`），落点态 `-7751912… → 5609283…`，反查命中 3。
- **D-2｜因此爆炸弹命中与否会改主链下游**：下游 5 值「逐字相同=false」——注意「命中后」的前两个值恰是「未命中」的后两个值（`0.742242`/`0.873262`），说明是**序列被整体前移 3 格**，不是数值本身变了。这是 `mw_cluster` 的既有行为，**本批没碰**，但它意味着 E1 守恒的口径必须区分「主流位置」与「主流数值」。
- **D-3｜同一 run_seed 下，分裂与否的指纹串逐字相同**，而态层两把 rng 首值亦相同（`0.557104/0.557104`）；阳性对照④证明该「相同」不是拿空串比空串 ⇒ **实测坐实 P-8**：指纹对主流扰动是盲的。

---

## 7. 裁定件 §5 六项回账（我本轮请编程侧跑的机检）

| # | 要求 | 实测回账 |
|---|---|---|
| 1 | A 组改后全套门控（M-1 环境 + churn 只比断言行 + `[SMOKE-SWEEP] done checked=N declared=N` 两数相等） | 11 面 `validate problems=0`、`[ERR]=0`、`ok=false=0`、`SCRIPT ERROR=0`；`[SMOKE-SWEEP] done checked=56 declared=56`；churn 十面见 §3（`red=0 blind_faces=无`），噪声底 109 行同报 |
| 2 | V-S1 变异刀一把：删 `is_sweepable()` 的 `not b.friendly` → 预期友方那颗报红，贴红条原文 | 红 4 条，首条：`#09 S1 反例⑧friendly 全零弹（oracle 与硬编码期望同号） measured=true expect=false ok=false`；连带 `#18`（仍在树）与 `#19/#20`（增量 2≠1）。见 §4 |
| 3 | V-S3 判据①：N∈{0,1,5,20} 四档清扫前后 `Game.rng.seed/state` 逐字快照（探针打印） | 探针打印：`#29/#30/#32/#34 seed measured=12345 expect=12345 ok=true`；`#31/#33/#35 state measured=5922163526861011269`（三档与 N=0 参考档**逐字相等**）；`#36 draws 增量==swings 增量 measured=4/4`。快照是日志原文，非事后口头 |
| 4 | b3 过载断言五条增量 | `#42 swept 增量==0` ✓、`#43 melee_swings 增量==0` ✓、`#44 draws 增量==0` ✓、`#45 _reload_t measured=0.9 expect=>0` ✓、`#46 扇区里的弹仍在 measured=false expect=false`（false＝未仍在？⚠️ 见下）| 
| 5 | X5 覆盖自查：`grep -n "+ _knock"` 命中数 vs `apply_stun` 实际拦住的出口数对照表 | 见下表。**前置事实：全库 `apply_stun`／`stun_t` 命中 0 条 ⇒ 该机制尚未存在，本轮只能交「分母」，V-P2 判据① 现在无法预验** |
| 6 | D 组三项照实施单 §4 原样跑 | §6，原始片段逐字贴出 |

**第 4 项的一条读法澄清（⛔ 让它含糊）**：`#46` 的 `measured=false expect=false ok=true` 里，measured 是「弹**不在**树」的布尔（清扫排在过载早退之后 ⇒ 过载那一拍不该扫，故「不在树」应为 false＝仍在树）。断言成立，但句子命名反直觉。k4 把清扫段搬到早退之前时同一条报 `measured=true expect=false ok=false`（§4），说明它咬得住。建议下一版把该条的谓词改名成 `bullet_still_in_tree`。

**第 5 项对照表（C 组开工前的分母，全部 `grep -n` 现读）**

| 文件 | 自身位移出口（含 `+ _knock`） | 纯击退出口（`velocity = _knock`） | 其余 `velocity =` 出口 | `apply_stun` 需覆盖 | 现覆盖 |
|---|---|---|---|---|---|
| `scripts/slug.gd` | **6** 处：`:216 :236 :298 :304 :360 :395` | 4 处：`:140 :204 :320 :330` | — | **6**（⛔ 漏一处＝晕着还能挪窝，V-P2 判据①假绿；裁定件 X5 原话点名「四处全覆盖」，现读实为 6 处——**以现读为准**） | 0（机制未实现） |
| `scripts/boss.gd` | **0** 处（无 `_knock` 字段） | 0 | 5 处，其中 4 处恒 `Vector2.ZERO`（`:135 :146 :153 :335`），真正自身位移只有 `:164 velocity = (dir + _strafe_dir * 0.45).normalized() * speed * _slow_mult` | **1**（`boss.gd:164`） | 0 |
| 减速镜像模板 | `slug.gd:31 var _slow_mult`、`:130 func apply_slow(mult, dur)`、`:175 _slow_mult = 1.0`；`boss.gd:55 var _slow_mult`、`:128 _slow_mult = 1.0` | | | stun 走同一条 `_slow_mult` 式「入口置位 + 出口读取」通路最省，但 boss 侧无 `apply_slow` 函数 ⇒ 需新建（新计时一律 `Game.FIXED_DT`，红线 #6） | |

---

## 8. 禁止事项 #1~#14 逐条自查

| # | 禁令 | 自查结论 | 证据 |
|---|---|---|---|
| 1 | ⛔ 改与本单无关的 `.gd` 行 | **遵守**，但见 P-4/P-5：`bullet.gd` 因 A1 合法离开冻结集；盘上 `player.gd` 现差 1 行是**并发窗的刀**，非我所改 | §0 md5 表、§5 P-5 逐行 diff |
| 2 | ⛔ 动 `ACTION_DEFS`（现值 18） | **未动**（A 组不需要新 action；清扫复用既有射击输入路径） | 清扫面 #53~#56 走 `Input.action_press("shoot")` + E3 同一条分派 |
| 3 | ⛔ 碰 `bullet.gd setup()` 第 8 参位 | **未动**：`is_sweepable()` 是**零参 getter**，⛔ 加参位、⛔ 改签名 | `bullet.gd:52-54` |
| 4 | ⛔ 改 `meta.gd UNLOCKS` | **未动**（发现的 `meta.gd:71` 碰撞点只盘点不施工） | §5 P-2 第 3 条 |
| 5 | ⛔ 换 `shardbearer.png` | 未涉及 | 本批零图片改动 |
| 6 | ⛔ 新计时用 raw delta／time_scale／create_timer | **本批无新计时**（清扫是「每次挥击即时结算」，无跨帧窗口） | `player.gd:740-766` 块内无 delta 累计 |
| 7 | ⛔ 破坏「每次有效挥击恒 1 次主流抽取」／清扫侧新增抽取 | **遵守且有正证**：melee 面 `swings_total=57 draws_total=57` 逐字不变；清扫面 `#37` 断言源码零 `Game.rng`；k3 一把（多抽一次）实测红 4 条 | §2、§4 |
| 8 | ⛔ 自行改断言／冻结串让门转绿 | **遵守**：P-4 两条红如实挂着，⛔ 刷 `SPR21-FROZEN.md5`、⛔ 改 `spr38_report_selfaudit.py` 的 `(24,10)` 与 `GOOD_MD5` | §5 P-4 |
| 9 | ⛔ 新增持久状态字段不申报 | 已申报：两个 `static var`，非持久、不进指纹串 | §5 P-7 |
| 10 | ⛔ 把清扫蹭到既有 trigger（如 `ON_SHIELD_BREAK`） | **未蹭**，并加了断言：`#49` 阳性对照（环盾确实记 `suffix_fires`）＋ `#50` 近战清弹不触发该词缀（measured=0/3） | §4、`spr40_sw_sweep.lines.txt` #49/#50 |
| 11 | ⛔ 动 `AUTORUN_值守报告.md`／`AUTORUN_LEDGER.md`（含追加） | **一个字节未碰**，本批流水收口在本件 | `git status` 无该两文件改动 |
| 12 | ⛔ 动 `D:\大纲` | 未涉及 | — |
| 13 | 未获 D2／C1~C6 答复前⛔ 做 B1~B11／PARRY | **遵守**：B 组只做到只读盘点（P-2），C 组 PARRY 一行未写（等 §9 的停等项解开） | 本件零武器 id 改动 |
| 14 | ⛔ 交付报告省略改前基线（HP-0） | §1 全量给出 | — |

---

## 9. 不等点头的下一步（编程侧自裁顺序）与本批停等项

**现在就做（无需锁、无需授权）**
1. 写 B12 图标生成器 `_tools/spr40_wpn_icons.py`（新文件，纯标准库，按设计实稿 §3.1 的 32×16 规格与剪影差；⛔ 改 `spr25_art_gen.py`／`spr34_gen.py` 的共享逻辑）。**⛔ 在并发窗在飞时执行它**——新 PNG 会触发那个 Godot 实例（pid 25028）重扫导入，污染它的门控日志；等锁自由再落盘产物。
2. 把本件的 P-2 四碰撞点、P-4 两条红臂、P-5 并发态、P-8 口径修正，作为**裁定请求**交主理人（它裁设计／口径，作者保留④冻结重登）。
3. C 组施工单细化：`apply_stun` 的 6+1 出口清单（§7 第 5 项表）先写成施工锚点，⛔ 动码（PARRY 等 C6 四常数走占位＋异步供阅，已由裁定件 §1-C6 放行，可在独占窗内搭管线）。

**停等（必须主理人先裁，⛔ 我绕）**
- B1~B11 原子迁移的 M9：`wpn_launcher` 键能否从 `GEN_NAMES` 摘除（撞 `menu.gd:171`／`meta.gd:71`／`weapons.gd:88` 三个消费点，其中 `meta.gd:71` 在红线 #4 后面）。
- 冻结重登：`bullet.gd` 的 `SPR21-FROZEN.md5` 条目（作者保留④）。
- 文档包登记轮：`spr38_report_selfaudit.py` 的 `GOOD_MD5`／`(24,10)` 与 `值守报告` 七处冻结声称——本批禁止事项 #11 挡着，⛔ 我动。

**⛔ 任何门控复跑前**：先确认 `scripts/player.gd` 回到 `2364e3b1…`（并发窗的刀还原完），并走 `bash _tools/spr38_run.sh` 抢锁，⛔ 手工碰锁文件。
