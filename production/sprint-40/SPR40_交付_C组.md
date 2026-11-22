# SPR40 交付_C组 · 弹幕交互与盾反结构层（S40-c／C1~C6，数值一律占位）

批次：Sprint 40 · C 组
日期：2026-11-18
交付人：编程侧
核验人：`六道卷游戏 · 主理人`（独立核验见 `SPR40_主理人核验_C组与B12.md`，本件不代替其结论）
配套判据：`SPR40_设计实稿_弹幕交互与盾反.md` §3.1~§3.3／§4.3，`SPR40_主理人裁定_R1_C1C6与探针口径.md` §1（C1~C6），`SPR40_主理人核验_C组与B12.md` §0（①~④ 裁定）／§1.4／§2.4／§5.4，`SPR40_验证口径.md`（V-P1~V-P4）

**一句话状态**：C1~C6 的**结构层**全部落地并被机检咬住——`SMOKE_PARRY` 面 70 条（`_PD_DECLARED=70`，双跑 `cmp` 逐字相同、面文本 md5 两份都是 `daceddbc…`），七把变异刀 p1~p7 实测红号集合与 `EXPECT` 表逐一对齐（含转正的 p7 源级断言 #65），改后十面门控 + 清扫面 56/56 + 盾反面 70/70 全绿（`[ERR]=0`、`ok=false=0`、`SCRIPT ERROR=0`、`validate problems=0`），E1 三档指纹串逐字节不变。**本件同时申报七条偏差（§5），其中三条要主理人处置：GOOD_MD5 未动（两份裁定的口径冲突，我取了最新那份）、冻结普查 23→22（`boss.gd` 因 C3 空实现离开冻结集）、C 组改后 md5 的取源是间接戳。**⛔ 编程侧自行抹平任何一条。

**数值状态**：`BLOCK_MULT`／`RETURN_MULT`／`STUN_FRAMES`／`STUN_DURATION` 四个数是**占位**（作者保留域②未点头）。结构层跑通 ≠ 数值定稿，本件任何一处都不构成「作者已点头」的证据。

---

## 0. 代码面落点（本批改了什么）

| 文件 | 改前 md5 | 改后 md5 | 改动内容（行号为现盘可复核位） |
|---|---|---|---|
| `scripts/player.gd` | `2364e3b156ab6e4e1b34965851dfcd7d` | `733a4b3c524219c237441d53e3ebc9b2` | C1 三段分流（`_update_shield_scan()` :836，判据同引 `is_sweepable()` :849）＋ C2 符号位单变量 `_parry_hit_cd` :131（`+6`/`-6`）＋ `PARRY_FRAMES := 12` :128、`PARRY_HIT_CD := 6` :129 ＋ C6 `BLOCK_MULT := 0.5`（占位）:134 ＋ C4/C5 `static var parry_count/block_count` :119-120 ＋ RAISE 复用 `_stance_t`（:810-825 注释块，⛔ 新增 action）＋ 结算函数 `_settle_parry` :868／`_settle_block` :876 ＋ 源序：盾扫描插在 `_update_aim_and_fire`（:394）**之后**、`_update_bomb_input`（:399）**之前**（调用行 :398） |
| `scripts/slug.gd` | `6a17a4ed7034b31a5c9b19f9e9e5fb55` | `341880b455ff2550ae85ca26556bea58` | C3 晕计时：`var _stun_t := 0.0` :33 ＋ `apply_stun()` 内 `_stun_t = maxf(_stun_t, dur)` :143 ＋ 递减 `_stun_t = maxf(0.0, _stun_t - Game.FIXED_DT)` :175 ＋ 晕分支 `velocity = _knock` :176／`_knock` 继续衰减 :177（对照未晕分支 :151-152） |
| `scripts/boss.gd` | `fb40c2fea74c106f5417856524cb9dd8` | `0303ce204215ad795af662de919652ed` | C3 免疫硬约束：主题 Boss 侧 `func apply_stun(_dur: float) -> void:` **空实现** :331（⛔ 给它加 `_stun_t`） |
| `scripts/game_main.gd` | `bf719278d6a1a1669d9f22f72b405924` | `5978d36835881a40e42f532f0098c7e8` | `SMOKE_PARRY` 探针块：`const _PD_DECLARED := 70` :5769、`_smoke_parry_probe()`（面体 :5797~:6145）、未跑声明行 :5797、`Dev.check(_pd_checked == _PD_DECLARED …)` :6195 ＋ **P8 源级断言** :6139-6145（段取 `_ml_src_segment("res://scripts/slug.gd", "func _physics_process(delta: float)")`，要求 `_stun_t = maxf(0.0, _stun_t - Game.FIXED_DT)` **字面在场且恰一次**） |
| `scripts/bullet.gd` | `95370e21eec900789d2d53284fe82fd1` | **未动**（同值） | A 组单一真源 `is_sweepable()`（:52）被 C 组直接复用，本批⛔ 新写判据 |
| `scripts/data.gd` / `scripts/weapons.gd` / `scripts/game_state.gd` | `9aab58fd…` / `315e9283…` / `7d10f3d1…` | **未动**（同值） | C 组不涉及数据表；`Game.FIXED_DT`（`game_state.gd:22`）当既正常量引用 |

🔴 **改后 md5 的取源声明（不粉饰）**：C 组改后一列**不是** C 链当场直接盖的戳，而是 B 组落地窗口（22:01 起跑）第①步写的改前快照 `_backup/spr40_b/before.md5`。两重互证：①`_tools/spr40_parry_knife_run2.log`（21:19 那窗）链尾 `RUN 收尾 player.gd == 绿基线 733a4b3c524219c237441d53e3ebc9b2`；②同文件里 `RUN 归档闸 … |ARCHIVE-GATE GREEN … 归档=4 份|` 对应的 `_tools/spr38_good_player.733a4b3c.bak` 在盘且逐字节相同。⇒ `player.gd` 的 733a 有直接戳；另外三个文件（slug／boss／game_main）只有间接戳，主理人若要独立复算请对着上面这三个哈希值现读。

绿件转正链：`dc622351` → `4f907fbb`（A 组清扫块）→ `2364e3b1`（A 组收官）→ **`733a4b3c`（C 组，现役）**。历史归档四份均在 `_tools/spr38_good_player.<hash前8位>.bak`。⚠️ 主 `.bak` 被就地覆盖那笔事故见 §5 P-7（主理人裁 S41 修复，本窗⛔ 碰 `.bak` 系列）。

证据目录：`_tools/spr40_c_after/`（C 组改后十面 + 三个 `chk_*` + `clause` + 三份指纹 selftest 抽取件）、`_tools/spr40_c_after/parry/`（面日志 ×2 ＋ 面文本 ×2 ＋ 逐条对照表 `.lines.txt` 72 行）、`_tools/spr40_c_after/sweep/`（同形双跑）、`_tools/spr40_parry/`（原始工作副本）、`_tools/spr40_parry_knives/`（七把刀 × 3 件：`p<u>.log` 全量面日志／`p<u>.face.txt` 红行／`p<u>.patch.txt` 守恒戳）、`_tools/spr40_c_churn.txt`（churn 对账表全文）、`_tools/spr40_parry_knife_run2.log`（独占链 stdout，含收尾／归档闸／工具面／文档面四行）、`_backup/spr40_parry/`（改前 7 件副本）。

---

## 1. 改前基线（HP-0）

C 组改前树 = A 组收官树（`player.gd = 2364e3b1…`）。环境一律 `SMOKE=1 SMOKE_SEED=12345 [--quit-after 3200]`，指纹面另加 `SMOKE_META_FINGERPRINT=1`（seed 12345／777／42），每次跑前擦 `%APPDATA%/Godot/app_userdata/test_1/_smoke_*.cfg*`。证据件＝`_tools/spr40_after/`（A 组改后 = C 组改前的同一棵树）。

| 项 | 实测（改前） |
|---|---|
| ① fingerprint 串 | 三档各一条 `[SMOKE-META] fingerprint floor=1 rooms=… kinds=…`，全文见 `SPR40_交付_A组.md` §1（本批⛔ 重贴以免两处漂移） |
| ② `validate problems` | **0**（十面各 1 条） |
| ③ 探针 checked/declared | melee `94/94`（且 `swings_total=57 draws_total=57`）；stance `7/7`；sc `19/19`；sweep `56/56`（A 组面，已存在）；base/apply/rng/pw/fp 面无 `done` 行（判据在 `S38-*`／`MG-*` 行里） |
| ④ `[ERR]` 计数 | **0**（十面全部） |
| ⑤ `ok=false` / `SCRIPT ERROR` | **0 / 0**（十面全部；V-H #8：死构建的 `okfalse=0` 是假绿，故单列） |

🔴 **盾反面在改前不存在**（HP-0 的本义）：`SMOKE_PARRY` 未开 ⇒ 无 `[SMOKE-PARRY] base0` 行、无 `done checked=` 行，`_PD_DECLARED` 这个常量本身也还没有。⇒ 本批新增的 70 条判据在改前树上一条都跑不出来，⛔ 拿改前日志的「没红」当「过了」。

冻结普查（改前）：**23 OK / 11 FAILED / 缺 0**。（现场合成 C 组改前树后逐条现算：七件改动文件取 `_backup/spr40_parry/`，其余取 `_backup/spr40_b/scripts/`，比对 `production/sprint-21/SPR21-FROZEN.md5` 全 34 条。）

---

## 2. 改后同五项

| 项 | 实测（改后） | 与改前的关系 |
|---|---|---|
| ① fingerprint 串 | 三条逐字同改前 | **逐字节相同**；`cmp` 整份 `fp<seed>.full_selftest.txt`（175／206／213 字节）亦相同 ⇒ C 组没碰 E1 指纹面（V-P2） |
| ② `validate problems` | **0**（十面 + 盾反/清扫两个离线面） | 不变 |
| ③ 探针 checked/declared | melee `94/94`＋`swings=57 draws=57`；stance `7/7`；sc `19/19`；sweep `56/56`；**parry `70/70`（新增）** | 既有四面**逐字不变**；新增面 `checked==declared==70` |
| ④ `[ERR]` 计数 | **0**（十面 + 离线两面） | 不变 |
| ⑤ `ok=false` / `SCRIPT ERROR` | **0 / 0**（`p<u>.log` 里出现的 `ok=false` 全是变异刀打桩态，见 §4；正跑面日志里为 0） | 不变 |

链级判定（`_tools/spr40_parry_knife_run2.log`，21:19 起跑那次独占窗，逐字）：

```
PREFLIGHT ok 可以开跑（无并发、基线合身、锁不存在）
RUN 独占确认：抢锁后重检无 Godot（TOCTOU 窗已闭）
=== run 起跑 21:19:16 cmd=bash _tools/spr40_parry_knife.sh ===
RUN 收尾 player.gd == 绿基线 733a4b3c524219c237441d53e3ebc9b2
RUN 归档闸 绿基线配套归档已核 |ARCHIVE-GATE GREEN 现役绿基线有逐字节相同的配套归档 归档=4 份（含历史档，⛔ 与现役比）|
RUN 工具面 写后核查件自证 ok |SELFTEST GREEN states=9|
RUN-RED 文档面 spr38_report_selfaudit rc=1 ⇒ 文档与盘上日志不符（明细 _tools/spr38_run.docaudit.txt）
RUN 锁已释放 pid=30759
```

🔴 上面那份是 **`STEP=run` 的刀窗链**（21:19），按 `spr38_run.sh` 三态判定它末段只能是 `RUN-PARTIAL`（gates/knife 未跑齐 ⇒ ⛔ 本件不作收官证据），且它在第 5 步文档面 `rc=1` 处 `exit 2`——**这里引它只因为「收尾==绿基线」「归档闸」「工具面」三行是自证句，不是收官判定**。C 组真正的收官证据是同夜 21:38~21:42 那次 `STEP=all` 链：盘上留存为 `_tools/spr38_run.gates.log`（十面逐行 `exit=0 ERR=0 okfalse=0 SCRIPT_ERROR=0 validate problems=0`）与 `_tools/spr38_run.knife.log`（末两行 `restored md5=733a4b3c524219c237441d53e3ebc9b2` ＋ `ALL KNIVES BIT`），副本在 `_tools/spr40_c_after/`。那次 `all` 链的**终端 `RUN-` 判定行没有单独落盘**（当时只读终端），主理人若要按 V-H #14 认定收官资格，请看上面两份件＋§6 的双跑哈希，或点名要我补跑一次 `all` 并把 stdout 存成 `_tools/spr40_c_after/chain_all.txt`。

文档面四条 RED（`_tools/spr38_run.docaudit.txt`，C 组在飞态、盘上==绿件==733a 的现场输出）：

```
FAIL 冻结实测 22 OK/12 FAILED/缺0 != 24/10/0
FAIL 绿基线或盘上件 != dc622351a75e8da9d943d72332ec2a28（刀没还原／基线过期）
FAIL AUTORUN_值守报告.md 冻结声称抽到 8 处，登记表 7 处（多 1 处）…
FAIL SPR38_交付_B1_非弹幕近战内核.md 冻结声称抽到 5 处，登记表 4 处（多 1 处）…
SELF-AUDIT RED checks_run=27 issues=4 docs=2
```

四条都不属于 C 组代码：①②是基线／冻结登记（§5 P-3、P-4），③④是主理人核验 §3.3 认定的**既有态**（前序窗口加了声称位没同步表，编程侧⛔ 抹平，改表归主理人）。

---

## 3. churn：只比断言行（`SMOKE_SEED=12345` 已钉）

全表见 `_tools/spr40_c_churn.txt`；摘要（改前=A 组收官树，改后=C 组树）：

| 面 | 探针行 改前 | 改后 | 漂移 | `ok=false` |
|---|---|---|---|---|
| base | 133 | 124 | 121 | 0 |
| melee | 204 | 201 | 113 | 0 |
| stance | 129 | 139 | 122 | 0 |
| apply | 177 | 154 | 137 | 0 |
| rng | 149 | 138 | 117 | 0 |
| sc | 132 | 148 | 128 | 0 |
| pw | 143 | 130 | 119 | 0 |
| fp12345 | 152 | 131 | 141 | 0 |
| fp777 | 135 | 127 | 114 | 0 |
| fp42 | 109 | 104 | 109 | 0 |

`CHURN-DONE red=0 blind_faces=无`。

### 3.1 噪声底

漂移全部落在 `[SMOKE] t=…`／`[SMOKE-CAM]`／`[SMOKE-E]`／`[SMOKE-NAV]` 这类**现场叙述行**（同一 seed 下敌人刷点与走位的浮点抖动），无一条落在 `[SMOKE-*] #NN … ok=` 断言行上；A 组那轮已量过同一族噪声（`SPR40_交付_A组.md` §3.1），本批未新增机制去改它。

### 3.2 stance 遥测带的既有形状

`[SMOKE-STANCE] shots=` 历轮落在 **71～100** 之间（本批改前 71、改后同带），判定字段（`len/window/leaks/blocks/死亡打断/闩锁未结算/done 7/7`）互不变 ⇒ 带内漂移属既有已裁形状，本批未新开口径。

### 3.3 机检件与指纹逐字节

```
FP-12345 GREEN 逐字节相同 (175 字节)
FP-777 GREEN 逐字节相同 (206 字节)
FP-42 GREEN 逐字节相同 (213 字节)
CHK spr38_g_chk_fp GREEN 逐字节相同
CHK spr38_g_chk_verbatim GREEN 逐字节相同
CHK spr38_g_clause GREEN 逐字节相同
CHK spr38_g_chk_quota 漂移 ⇒ equip_calls=29 → 34
CHK spr38_g_chk_taut 漂移 ⇒ Dev.check 应解析 287 → 289；game_main.gd grep=55 → 57
```

两处漂移都能机械归因，且都不是判据被改钝：`quota` 的 `equip_calls` 从 29 到 34 ＝ C 组探针块里新增的装备调用站点（同宏名计数）；`taut` 的 287→289 ＝ 新增的两条 `_pd_assert` 里的 `Dev.check` 站点（结算段源级反证 #45 与源序反证 #68），且 `应解析==实解析` 两边同步（可疑=0）。

### 3.4 T3b 豁免行：四条内容逐字不变、行号整体后移

`game_main.gd:2586 → 2594`；`player.gd:1607 → 1727`（两条）；`player.gd:1990 → 2110`。⇒ 登记表的四条**语义**没动，只是被 C 组新增块顶了位置；重锚归主理人（核验 §3.3 那条改表动作一起做）。

---

## 4. 变异刀清单（七把；声明的应红面号 → 实测红号）

`EXPECT` 表＝`_tools/spr40_parry_knife.sh:24-32`（20:57 首轮实测回填，p2/p4 各比写死的多咬两条，按裁定「⛔ 反过来把实测缩小去迁就写死数」填死）；红号列＝本件现读 `_tools/spr40_parry_knives/p<u>.log` 里 `ok=false` 行的 `#NN` 重算，非转述。

| 刀 | 打哪（`DESC[]` 原句） | 目标文件 | 预期红号 | 实测红号 | 守恒戳（`p<u>.patch.txt` 首行原样） |
|---|---|---|---|---|---|
| p1 | RAISE 的 kind 闸拆掉（cleaver 架式也算举盾＝第二套身份账） | `player.gd` | `09 10` | `#09 #10` | `KNIFE p1 scripts/player.gd 行数=2649（守恒）written` |
| p2 | 完美窗不递减（帧制被换成永不断电） | `player.gd` | `14 15 16 17` | `#14 #15 #16 #17` | `KNIFE p2 scripts/player.gd 行数=2649（守恒）written` |
| p3 | 环盾让路删除（同一颗弹既记盾反又算环盾摧毁） | `player.gd` | `36 37` | `#36 #37` | `KNIFE p3 scripts/player.gd 行数=2649（守恒）written` |
| p4 | 硬格冷却改判成正号（BLOCK 抢走『刚盾反』那 6 拍的归属） | `player.gd` | `31 32 33 35` | `#31 #32 #33 #35` | `KNIFE p4 scripts/player.gd 行数=2649（守恒）written` |
| p5 | 晕中 `velocity=_knock` 改成 `Vector2.ZERO`（把击退一起冻住） | `slug.gd` | `58` | `#58` | `KNIFE p5 scripts/slug.gd 行数=516（守恒）written` |
| p6 | 盾反判据内联＝摘掉 `is_sweepable()` 单一真源（激光／友方弹也进盾反） | `player.gd` | `27 28` | `#27 #28` | `KNIFE p6 scripts/player.gd 行数=2649（守恒）written` |
| p7 | 眩晕递减用 `delta` 不用 `Game.FIXED_DT`（🔴 **等效刀**，靠 #65 源级断言咬） | `slug.gd` | `65` | `#65` | `KNIFE p7 scripts/slug.gd 行数=516（守恒）written` |

p7 的牙口证据（`_tools/spr40_parry_knives/p7.log`，逐字）：

```
[SMOKE-PARRY] #65 P8 源级：眩晕递减那一行写死 Game.FIXED_DT（⛔ 换成 delta——本项目两者等值，行为面⛔ 分不开） measured=0 expect=1 ok=false
```

`measured=0 expect=1` ⇒ 不是布尔在场而是"恰一次"计数被打桩改成 0，符合转正条件②（段本体反证）。首轮空咬（红条数=0）的归因与转正口径在主理人核验 §1.2/§1.4，本件不再重述理由，只转录结论段（§7）。

---

## 5. 偏差申报（与本单／常规不符之处，逐条，⛔ 沉默处理）

**P-1｜`_PD` 断言数与面行数的形状**：面文本 72 行 = `base0` 1 行 + 断言 70 行 + `done` 1 行，`checked=70 declared=70` 与 `_PD_DECLARED` 三方对齐。无偏差，登记形状供主理人复算用（核验 §6 已核）。

**P-2｜p1 首轮"多咬"的处置**：p2/p4 各比写死数多咬 2 条（同一处改动掀翻同组多条面）。**处置＝把实测填死进 `EXPECT`，⛔ 反向缩数**。这与 A 组那轮的同一形状一致，属常规，登记在此是为了让下一轮不必再问"写死数是谁改的"。

**P-3｜GOOD_MD5 未动——两份裁定的口径冲突，我取了最新那份。** 核验 §7.3 要我"按 §3.2 更新 `GOOD_MD5 = 733a4b3c…`，改完跑一次 selfaudit 应看到那条 RED 消掉"；而**更新**的裁定件 `SPR40_主理人裁定_R2`（同一夜、成文晚于核验）在 §3.3 明确写：

> `GOOD_MD5` 常量 ＋ `FROZEN_SITES` ＋ 文档面声称 ＋ 本批交付件引用位 一轮做完 ｜ 我出逐字施工单，你落地 ｜ **B 组收官后**

并在末尾停等栏写「⛔ 动 `GOOD_MD5`（等我的逐字施工单）」。⇒ 我**没有改** `_tools/spr38_report_selfaudit.py:28`，盘上现值仍是 `dc622351a75e8da9d943d72332ec2a28`，文档面 RED ② 因此仍在。这一条不是遗漏，是按 R2 走；若主理人认为核验 §7.3 优先于 R2 §3.3，请点名，我按点名的顺序执行。

**P-4｜R2 §3.2 要的证据（我原判它"没被证实"这件事，我自己的记录是对的，措辞是错的）。** R2 §3.2 猜我看到的两条新 FAIL 要么是另一份 selfaudit 副本、要么是把 ③④ 看错了。**两种都不是**，现场原始输出如下——命令：把 `_tools/spr38_report_selfaudit.py` 的 `GOOD_MD5` 临时改成 `733a4b3c…` 后离线跑 `python _tools/spr38_report_selfaudit.py`（跑完**逐字节还原**，盘上现值见 §2 那四条 RED）：

```
AUTORUN_值守报告.md 绿件 md5 出现=0 次 ｜ 其它 32 位十六进制串=['dc622351a75e8da9d943d72332ec2a28', 'df57d7dd4a86ef10b1e09a1f9e049d68']
SPR38_交付_B1_非弹幕近战内核.md 绿件 md5 出现=0 次 ｜ 其它 32 位十六进制串=['dc622351a75e8da9d943d72332ec2a28', 'df57d7dd4a86ef10b1e09a1f9e049d68']
FAIL 冻结实测 22 OK/12 FAILED/缺0 != 24/10/0
FAIL AUTORUN_值守报告.md 冻结声称抽到 8 处，登记表 7 处（多 1 处）⇒ …
FAIL AUTORUN_值守报告.md 没引用收尾 md5（无法证明已还原）
FAIL SPR38_交付_B1_非弹幕近战内核.md 冻结声称抽到 5 处，登记表 4 处（多 1 处）⇒ …
FAIL SPR38_交付_B1_非弹幕近战内核.md 没引用收尾 md5（无法证明已还原）
SELF-AUDIT RED checks_run=27 issues=5 docs=2
```

⇒ 改前 `issues=4`、改后 `issues=5`：**RED ② 消失，但每份被审文档各新增一条「没引用收尾 md5」**（4−1+2=5）。根因是 `_tools/spr38_report_selfaudit.py:25` 的 `DOCS = [REPORT, DELIVERY]` 仍指着 **S38** 那两份文档，而文档面要求每份被审文档至少出现一次 `GOOD_MD5`；`值守报告` 里 `733a4b3c` 出现 **0** 次，而那份台账被禁止事项 #11 明令⛔ 动（含⛔ 追加）。R2 §3.1 第 5 条（"被审文档各 ≥1 次收尾 md5 引用 ⇒ 需要一份本批自己的交付件当宿主"）**正是这个缺口的机制**，只是我当时把它说成"新增两条 md5 FAIL"——条数对、说法含糊。请以此段原始输出为准订正归因；我⛔ 自行改 `DOCS`（那是判据件）。

**P-5｜冻结普查 23 OK/11 FAILED → 22 OK/12 FAILED，新离开的是 `scripts/boss.gd`。** 现算：`boss.gd` 冻结记录值 `fb40c2fe…` 与 C 组改前**逐字节相同**（即它原本命中冻结），C3 加的那条空 `apply_stun` 让它变成 `0303ce20…` ⇒ FAILED。⛔ 编程侧自刷 `SPR21-FROZEN.md5`（红线 #8），重登归主理人／作者（保留域④）。同批其余三个改动文件（`player`／`slug`／`game_main`）改前就已 FAILED，不新增计数。

**P-6｜C 组改后 md5 是间接戳。** 见 §0 表下那段：`player.gd` 有链尾直接戳，`slug.gd`／`boss.gd`／`game_main.gd` 三件只有 B 组备份快照这一处间接来源。主理人 §6 的"我实测"若用的是同一份 `_backup/spr40_b/before.md5`，那两处口径同源，不构成独立复算——请知悉后决定要不要现读再算一次。

**P-7｜P7 归档闸覆盖事故（主理人核验 §5 独立发现，S41 立项，本窗⛔ 动）。** 原样转录处置句：

> P7 归档闸覆盖事故，见主理人核验 §5，S41 修复

本窗按核验 §5.4 第 1 步只做了"该做的登记"（P-3 说明为什么连那一步也没做），⛔ 碰 `_tools/spr38_good_player*.bak` 任何一份，⛔ 改 `spr38_run.sh` 归档闸。

---

## 6. 盾反面的原始输出片段（贴句子，`_tools/spr40_c_after/parry/spr40_pd_parry.log`）

```
[SMOKE-PARRY] base0 reach(bulwark)=34 PARRY_FRAMES=12 PARRY_HIT_CD=6 BLOCK_MULT=0.50 parry=0 block=0 abs=0 hp=3
[SMOKE-PARRY] #04 P1 起手拍 shieldbash ∧ _stance_t>0 ⇒ RAISE 真 measured=true expect=true ok=true
[SMOKE-PARRY] #08 P1 RAISE ∧ not PARRY ⇒ BLOCK 真（架式还没到期就还有宽窗） measured=true expect=true ok=true
[SMOKE-PARRY] #11 P2 换算校验 M-2：round(0.20/(1/60))==PARRY_FRAMES measured=12.0 expect=12.0 ok=true
[SMOKE-PARRY] #23 P3 盾反把冷却武装成正号（正＝归盾反，负＝归硬格；一字段两态，⛔ 第二个 bool 位） measured=6 expect=6 ok=true
[SMOKE-PARRY] #31 P4 硬格把冷却改判成负号 measured=-6 expect=-6 ok=true
[SMOKE-PARRY] #33 P4 八向环撞同一次举盾：存活 6 颗（一次窗口只吃 2 颗） measured=6 expect=6 ok=true
[SMOKE-PARRY] #38 P5 几何前提：环盾半径 64 包住盾 reach 34 ⇒「让路」是全让而不是漏颗（⛔ 当常识默认，写成断言） measured=true expect=true ok=true
[SMOKE-PARRY] #43 P6 结算全程 melee_rng_draws 零增量 measured=0 expect=0 ok=true
[SMOKE-PARRY] #45 P6 源级反证：两个结算函数体内零 rand*（段取空会让上一条退化成恒真 ⇒ 两条各管一头） measured=0/0 expect=0/0 ok=true
[SMOKE-PARRY] #50 P7 int(1×0.5)==0 ⇒ 轻弹硬格免伤到 0（🔴 C6 占位档＝主理人推荐的「允许 0」，⛔ maxi(1,…)） measured=18 expect=18 ok=true
[SMOKE-PARRY] #63 P8 boss 变体的 Slug 免疫… 定义恰一处（段取空会让下一条退化成恒真比较 ⇒ 段本体反证） measured=1 expect=1 ok=true
[SMOKE-PARRY] #65 P8 源级：眩晕递减那一行写死 Game.FIXED_DT … measured=1 expect=1 ok=true
[SMOKE-PARRY] #69 P9 源序：盾扫描排在 `_update_aim_and_fire` **之后** measured=1851<1880 expect=升序 ok=true
[SMOKE-PARRY] #70 P9 源序：四个输入更新的相对顺序未动（anim→fire→bomb→skill→relic） measured=1880<1903 expect=升序 ok=true
[SMOKE-PARRY] done checked=70 declared=70 parry_total=6 block_total=5 absorbed_total=5 hp_restored=true
```

双跑自证：`spr40_pd_parry.lines.txt` 与 `spr40_pd_parry2.lines.txt` md5 均为 `daceddbceb4e2d0a5390aa95561dc347`（72 行）。清扫面同形双跑：`62b9859bcb77f153f45df5532addeeae`（62 行）。

分组划分（面文本 `.lines.txt` 前缀统计）：P1 10 / P2 7 / P3 11 / P4 7 / P5 5 / P6 5 / P7 6 / P8 14 / P9 5 ＝ 70。

---

## 7. 裁定回账（主理人核验 §0 ①~④ + R2 三项）

**① p7「等效刀 → 源级断言」转正**——照三条件自查：(1) 必要性证明写在断言紧邻上方注释 `game_main.gd:6139-6141`（🔴 标了等效刀披露与 21:07 实测），⛔ 只在 `DESC[]` 里；(2) 段本体反证＝`expect=1` 的"恰一次"计数（#63/#65 两条各管一头）；(3) 刀面互证＝p7，`EXPECT[p7]="65"`。三段口径（核验 §1.4，原样转录）：

> 「`_stun_t` 的递减系数走 `Game.FIXED_DT` 还是 `delta` 在本项目**运行期不可观测**（`const FIXED_DT := 1.0/60.0`，`project.godot` 无 `max_fps` 覆盖 ⇒ 引擎物理 tick 也是 60Hz）。⇒ 该红线只能靠源码级断言保证（P8 #65），⛔ 用行为面冒充抓到它。这是弹幕交互红线体系里第一条『写法即语义』型条款，未来同类（等价常数、单一真源、禁用 API）按主理人核验 §1.2 三条件走。」

**② C2 符号位单变量**——确认不改判，实现与裁定件 §1-C2 第 2/3/4 条逐字对齐（见核验 §2.3 那张表，本件不重贴）。**禁止事项栏原样抄这一句（核验 §2.4）：**

> 总量闸未裁——「每窗口最多 N 次」这种总量闸未获裁定，牵动第二个计数器与 kind 集，属新批次新裁定，⛔ 顺手实现。

**③(a) `META_WEAPON_POOL_BASELINE`**——本窗⛔ 单独改串（硬前置 HP-A：必须与 M1~M11 同批原子落地）。B 组落地窗已按核验 §3.1 逐字替换，MG-PW1 的 `missing/extra` 实测串随 B 组交付件交回。

**③(b) 冻结与 GOOD_MD5**——见 §5 P-3／P-5：本窗⛔ 动 `GOOD_MD5`（取 R2 §3.3 最新口径），冻结重登归主理人（凭 R2 §3.3 那张表：编程侧只在每次独占链跑完粘 `md5sum scripts/*.gd` 原样）。

**④ B12 图标**——`fushe` 走乙案（`wpn_fushe_w`），`zhushan` 第三版通过、⛔ 再迭代；正式 PNG 落 `resources/texture/generated/` 与 `assets.gd GEN_NAMES` 换键**与 M1~M11 同批**（同 §3.1 硬前置 HP-A）。旧 4 枚 PNG 留盘、⛔ 删、⛔ 覆盖。

**R2 三项**——题一（M9 乙案）＋题二（M6b 第 14 碰撞点随本批改）＋题三（GOOD_MD5 不可拆轮）都落在 B 组，逐字施工句与豁免令原文随 `SPR40_交付_B组.md` 转录；R2 §3.2 要的原始输出片段本件 §5 P-4 已贴。

**R2 §2.2 印记面的形状订正（我这边欠的一条，先在此登记，正式提问另发）**：R2 §2.2 给的判据（`checked=/declared=` 与 `ok=true` 计数）在 `SMOKE_SIGIL_COVERAGE` 面上**不存在**——`Dev.check` 通过时是静默的，该面没有 `done checked=` 行也没有 `ok=true` 行。盘上真实可观测量是这四类：`[SMOKE-SIGIL] contract enter: eq='arsenal'`、`[SMOKE-SIGIL-COV] done`、`[ERR] sigil_cov: …`、`[SMOKE-P] … weapon=<id>`。我的 `spr40_sigil.sh` / `spr40_sigil_reverse.sh` 已按后者重写。请订正 R2 §2.2 的判据句，⛔ 让下一轮照 §2.2 字面去 grep 一个不存在的串然后报"面没跑"。

---

## 8. 禁止事项 #1~#14 逐条自查（S40 实施单 §6）

| # | 条款 | 自查 |
|---|---|---|
| 1 | ⛔ 改 `ACTION_DEFS` | ✅ 真值 18 条一字不动；RAISE 走 `_stance_t` 复用（`player.gd:810-825`） |
| 2 | ⛔ 动 `bullet.gd setup()` 第 8 参位 | ✅ `bullet.gd` 本批未改（md5 同值） |
| 3 | ⛔ 换 `shardbearer.png` | ✅ 未动 |
| 4 | ⛔ 改 `meta.gd` 的 `UNLOCKS` | ✅ C 组未动 `meta.gd` |
| 5 | ⛔ 他作 IP 专名进游戏内文本 | ✅ 面文本只有"盾反／硬格／举盾／环盾"，⛔「只狼」类专名 |
| 6 | 新计时一律 `Game.FIXED_DT` | ✅ `_stun_t` 递减写死 `Game.FIXED_DT`（`slug.gd:175`），源级断言 #65 钉住 |
| 7 | 每次有效挥击恒 1 次 `Game.rng.randf()` | ✅ #25 实测 `measured=1`；#43/#45 证结算段零抽取 |
| 8 | ⛔ 自行修改任何断言或冻结串让门转绿 | ✅ 本窗零改判据；文档面四条 RED 原样留着（§2、§5 P-3/P-5） |
| 9 | 持久状态须申报 | ✅ `_stun_t`／`_parry_hit_cd` 均局内瞬态，⛔ 进存档、⛔ 进 E1 指纹（指纹逐字节相同为证）；`parry_count`/`block_count` 是 `static var` 遥测，申报在此 |
| 10 | ⛔ 并发开跑／手工碰锁 | ✅ 三次独占窗都走 `bash _tools/spr38_run.sh`（run／all），锁内容由链自己建 |
| 11 | ⛔ 动 `_tools/AUTORUN_值守报告.md`／`AUTORUN_LEDGER.md`（含⛔ 追加） | ✅ 未动（§5 P-4 正是撞在这条上，所以选择还原 GOOD_MD5） |
| 12 | ⛔ 动 `D:\大纲` | ✅ 未动 |
| 13 | ⛔ 取管道尾码当链退出码 | ✅ 每步退出码先落变量再判；链判定按日志内容而非进程码 |
| 14 | ⛔ 交付报告省略改前基线（HP-0） | ✅ §1；改前树里盾反面不存在这一事实也写明 |
| — | ⛔ 拿过期 `.bak` 当绿基线 | ✅ 链尾现读 == 现役绿件 733a；主 `.bak` 覆盖事故按 §5 P-7 归 S41 |

---

## 9. 不等点头的下一步（编程侧自裁顺序）与本批停等项

**已在飞的（⛔ 等新点头）**：B 组 M1~M11 原子迁移**已落盘**（`_tools/spr40_b_apply.sh`，22:01~22:13 独占窗），当前树是"已迁移未转正"状态，链尾如实报 `RUN-RED 收尾 player.gd=5835d2e6… ≠ 绿基线=733a4b3c…`。后续四步按核验 §7 与 R2 §166~§168 的既定顺序自走：

1. 修 V-W1 那条打偏的探针（`_tools/spr40_defs_snapshot_after.gd` 的"未解锁空池"从没真空过池，量的是随机分支）→ 重跑 B1 快照。
2. `bash _tools/spr40_promote_good.sh` 转正 `5835d2e6…`（先按内容指纹建归档，再替换现役）。
3. `bash _tools/spr38_run.sh all` 出 `RUN-GREEN`；额外跑 `SMOKE_SIGIL_COVERAGE=1` 面（`tag=after`，看 `weapon=liechi` 出现、`weapon=shotgun` 归零）＋ `_tools/spr40_sigil_reverse.sh` 的 M6 单方破缺反向自证（改一处 → 必见 `ERR_sigil_cov≥1` → 逐字节还原 → 指标与基线 `cmp` 相同）。
4. 落 `SPR40_交付_B组.md`（九节；把 R2 §1.3 豁免令原文、§2.2 施工句、§1.4 K5 同步说明、§3.2 原始输出片段抄进对应栏），交付件落盘后把 `md5sum scripts/*.gd` 原样粘主理人。

**停等主理人的（⛔ 我自行推进）**：

- 冻结串全文重登 + `GOOD_MD5`/`FROZEN_SITES`/文档面声称/交付件引用位的**一轮**登记（R2 §3.3；等逐字施工单）。
- `FROZEN_SITES` 站点数 8/5 vs 7/4 的复算改表（核验 §3.3，明写"这一步归我，⛔ 你调表"）。
- T3b 四条豁免行的行号重锚（§3.4）。
- R2 §2.2 印记面判据句的订正（§7 末段）。
- C 组改后 md5 要不要现读独立复算一次（§5 P-6）。

**作者保留域，本件一个都没替他点头**：`BLOCK_MULT`／`RETURN_MULT`／`STUN_*` 四个数值终值（域②）；方向级变更（域①）；放行／发布（域③）；冻结重定（域④）；§9.3 美术硬指标（域⑤）。
