# SPR41 编程侧交付_A组 · 盾反主流抽取守恒笼子（A-1）＋档位输入 `k` 可观测化（A-2）＋锚闸形状统一（A-3）

批次：Sprint 41 · §A 零裁定车（⛔ 数值口径 · ⛔ 方向级 · ⛔ 放行）
日期：2026-11-20
交付人：编程侧
核验人：`六道卷游戏 · 主理人`（独立核验，本件不代替其结论）
配套判据：`SPR41_实施单_编程侧.md` §A/§F/§G/§H、`SPR41_验证口径.md`（V-A1~V-A5）、`S41_台账.md`（append-only，轮 1~13）
证据根目录：`_tools/spr41_pre`（P-2 改前基线）、`_tools/spr41_a2`（各趟）、`_tools/spr41_post3`（终盘复跑）、`_tools/spr41_static_root`（静态面复测）、`_tools/spr40_b/s15x_s16x_*`（驱动器与审计件）

**一句话状态**：§A 三件（A-1 十断言守恒笼子／A-2 甲案扩参零行为变化／A-3 锚闸形状统一）＋ K-1（P-K8 八向环三面证）＋ D-1（#76 显示位订正）全部落地，终盘 `gates exit=0`、七面 done 行与 P-2 基线**逐字 SAME**、E1 三档指纹**逐字节不变**、`[SMOKE-PARRY] done checked=83 declared=83`（实数读数，非推算）。红侧三件都咬住（A-1 一红一还原、K-1 半径造错三抓全红、A-3 三形态锚句改死全见红且现役闸 md5 未动）。**但本件申报十条偏差（§5 P-1~P-10），其中两条是本轮新坐实的机检缺陷（churn 静态面同源自比＝假绿形状；CR 尺子退化），一条是我自己写进生产码注释的机制句被自家 P-K8 证伪后的订正趟，一条是我把自己那把引文审计刀的失败态 stdout 原地冲掉了（P-9），一条是 Edit 工具三次吞掉相邻正文行（P-10，其中一次吞掉的是台账里已在案的一句改名凭据）**；换代四件套（④冻结重定）与两把共享刀的刀相修法**不在编程侧权限内**，停等清单见 §9。

---

## 0. 代码面落点（本批改了什么）

| 文件 | 改前 md5（现读） | 改后 md5（现读） | 行数（CR／LF，`python` 字节计数） | 改动内容 |
|---|---|---|---|---|
| `scripts/player.gd` | `037f261d1b2d393fa02aba6a0bed1654` | `31bafa6a72386504d925afc72bfb2d54` | 2648 → **2654**（CR=0／LF=2654） | A-2 三处（见下方 hunks）＋轮 9 注释订正 1 行（同行替换） |
| `scripts/game_main.gd` | `b934f7dd332c60374776aa9c240ca4e2` | `b9d46998f67c2cabc3efda944e2b3fa7` | 7423 → **7531**（CR=0／LF=7531） | A-1 P-RNG 面 70 行（:6170 起）＋ K-1 P-K8 面 38 行（:6239 起）＋ `_PD_DECLARED` 实数两次（:5769） |
| 其余 32 件 `scripts/*.gd` | — | — | — | **逐字节未动**：`for f in scripts/*.gd; do cmp "$f" "$WT/$f"; done` ⇒ `GD-DIFF-COUNT=2`（`$WT`＝改前工作树快照 `D:/Create/Game/wt_s41a_base`，其两靶 md5＝上表改前列同值） |

§G1 口径：冻结表 `production/sprint-21/SPR21-FROZEN.md5` 条目 34 行（`wc -l` 现算），`scripts/` 下 `.gd` 恰 34 件（`ls scripts/*.gd | wc -l` 现算）⇒ 覆盖面与改动集对齐，改前／改后 md5 两列即快照。

### 0.1 `player.gd` 三处 hunks（改后原文，行号现读）

```
844		# S41 A-2：k 累加器，定义唯一钉在 _settle_parry 上方注释。
845		var k_in_raise := 0
```
```
860		elif _parry_frames_left > 0:
861			k_in_raise += 1
862			_settle_parry(b, k_in_raise)
```
（:861/:862＝原 `_settle_parry(b)` 单行拆成「累加＋带参调用」两行；:860/:863/:864 的 `elif/else` 分支结构与 `_settle_block` 出口一字未动。）
```
871	## S41 A-2（V-A4 档位输入定义唯一）：k ＝ 本次 RAISE 内实际走了 PARRY 分支的颗数。
872	## ⛔ 改写成「同帧敌弹总数」：八向环 8 颗同帧入盾那一拍，实测＝1 颗走 PARRY＋1 颗走 BLOCK＋6 颗因负号冷却本拍不处理（证据面 P-K8 #81/#82），k 只能等于 1。
873	## A-2 只递不用：本函数行为一字不变（计数、置冷却、迸星、queue_free），返还表落地前 k 仅作可观测入参。
874	func _settle_parry(b: Node, k: int) -> void:
```
（:871-873 为新增 `##` 文档块 3 行；:874 是原签名行的**同行扩参**，⛔ 新函数、⛔ 重载、⛔ 默认值——甲案口径。）

加数清单（行数账，⛔ 只报差值）：`2654 = 2648 + 2（:844 注释＋:845 声明）+ 1（:861 拆行净增）+ 3（:871-873 文档块）`；轮 9 的注释订正是**同行替换**，`+0`。
`7531 = 7423 + 70（A-1 P-RNG 面，:6170..6239 计 70 行）+ 38（K-1 P-K8 面，:6239..6276 计 38 行）`。

### 0.2 三元组同趟混改自查（§G7）

本批按趟分车、每趟单独留尾部行：Trip1＝A-2（只动生产码，台账轮 2）；Trip2＝A-1（只动探针面＋`_PD_DECLARED`，轮 3）；D-1＝只动 #76 显示位（轮 4）；Trip3＝造错/还原（轮 5）；K-1＝只动探针面＋`_PD_DECLARED`（轮 6）；轮 9＝只动一行注释。⇒ ⛔ 出现过「同一趟里既改生产码、又改期望常数、又改文档」的混合趟；`_PD_DECLARED` 两次动值（70→80、80→83）都与各自面的落地同趟，属实施单 A-1 要求的授权重钉，留痕见轮 3/轮 6。

---

## 1. 改前基线（HP-0，独占窗内跑全套门禁到独立目录）

出处 `_tools/spr41_baseline_pre.txt`、`_tools/spr41_pre/`（11-20 00:24:14；起跑前独占体检：Godot 无进程、`_tools/.spr38_run.lock` 不存在）。

```
# S41 P-2 改前基线（现算 2026-11-20 00:24:13）
gates_rc=0 parry_rc=0 sweep_rc=0
--- 冻结（如实报，⛔ 为 PASS 去刷清单）---
     34 OK
spr38_g_chk_fp           rc=0 verdict=VERDICT=ALL_MATCH hit=1 expect=1 | doc_hits=3 hits=1 hits=1 hits=1
spr38_g_chk_verbatim     rc=0 verdict=VERDICT=VERBATIM_MATCH hit=1 expect=1 | code_hits=27 doc_hits=27 expect=27
spr38_g_chk_quota        rc=0 verdict=VERDICT=IN_SYNC hit=1 expect=1 | hits: oracle_block=1 equip_calls=34 defs_block=1
spr38_g_chk_taut         rc=0 verdict_hit=1 expect=1 | 合计 应解析=568 实解析=568 可疑(T1+T2+T3)=0
```

七面摘要行与 done 行（逐字取自 `_tools/spr41_baseline_pre.txt:4-11` 与两侧日志；`base/apply/rng/pw` 四面结构上无 `done` 行，摘要件里该字段就是空。摘要件本身把每行截在同一列上，尾部断句＝盘上形状，⛔ 补全）：

```
melee   exit=0 ERR=0 okfalse=0 SCRIPT_ERROR=0 validate problems=0 | done checked=94 declared=94 | [S38-A1] DEFS 27 条 kind 全覆盖 · 真·非弹幕 4 条（字段/范围查
stance  exit=0 ERR=0 okfalse=0 SCRIPT_ERROR=0 validate problems=0 | done checked=7 declared=7 | [S38-A1] DEFS 27 条 kind 全覆盖 · 真·非弹幕 4 条（字段/范围查
sc      exit=0 ERR=0 okfalse=0 SCRIPT_ERROR=0 validate problems=0 | done checked=19 declared=19 | [S38-A1] DEFS 27 条 kind 全覆盖 · 真·非弹幕 4 条（字段/范围查
[SMOKE-PARRY] done checked=70 declared=70 parry_total=6 block_total=5 absorbed_total=5 hp_restored=true
[SMOKE-SWEEP] done checked=56 declared=56 swept_total=44 swings_total=20 draws_total=20
C-a′ GREEN：§三 逐行与运行时组数完全对账，总账 94 条
VH10 ok |done checked=94 declared=94 swings_total=57 draws_total=57|
```

改前两靶＝§0 表「改前 md5」列；改前工作树快照 `wt_s41a_base` 的 `_PD_DECLARED`＝70、`_pd_assert(` 全文命中＝71（1 定义＋70 站点）。

---

## 2. 改后同五项（终盘复跑 `_tools/spr41_post3`，13:06:31 起跑 → 13:11:31 收）

| 项 | 实测（改后，终盘） | 与改前的关系 |
|---|---|---|
| ① E1 fingerprint 串 | 三 seed 逐字见 §3 粘贴（`floor=1 rooms=… kinds=…`） | **逐字节相同**（去行尾 `cmp`，175／206／213 字节；CR 两侧=0） |
| ② `validate problems` | **0**（base/melee/stance/apply/rng/sc/pw 七面＋parry＋sweep 全含） | 不变 |
| ③ 探针 `checked/declared` | parry **`83/83`**；melee `94/94`；stance `7/7`；sc `19/19`；sweep `56/56` | 七面 done 行**逐字 SAME**；唯一 CHANGED＝parry（`70/70 → 83/83`，新增 13 条断言） |
| ④ `[ERR]` | **0**（终盘全面） | 不变 |
| ⑤ `ok=false` / `SCRIPT ERROR` | **0 / 0**（终盘全面） | 不变 |

终盘尾部行原文粘贴（`_tools/spr41_post3_runlog.txt`）：

```
gates exit=0  13:10:42
parry exit=0
sweep exit=0  13:11:31
gates_rc=0 parry_rc=0 sweep_rc=0 parrycmp_vs_t2b_rc=1 p3_anchors_rc=0
```

七面比对行（同件「复跑 vs P-2 基线：探针 done 行与计数」段）：

```
spr38_g_base   SAME base_err=0 post_err=0 base_serr=0 post_serr=0 | base=无 | post=无
spr38_g_melee  SAME base_err=0 post_err=0 base_serr=0 post_serr=0 | base=done checked=94 declared=94 swings_total=57 draws_total=57 | post=done checked=94 declared=94 swings_total=57 draws_total=57
spr38_g_stance SAME base_err=0 post_err=0 base_serr=0 post_serr=0 | base=done checked=7 declared=7 | post=done checked=7 declared=7
spr38_g_apply  SAME base_err=0 post_err=0 base_serr=0 post_serr=0 | base=无 | post=无
spr38_g_rng    SAME base_err=0 post_err=0 base_serr=0 post_serr=0 | base=无 | post=无
spr38_g_sc     SAME base_err=0 post_err=0 base_serr=0 post_serr=0 | base=done checked=19 declared=19 | post=done checked=19 declared=19
spr38_g_pw     SAME base_err=0 post_err=0 base_serr=0 post_serr=0 | base=无 | post=无
spr41_g_parry  CHANGED base_err=0 post_err=0 base_serr=0 post_serr=0 | base=done checked=70 declared=70 parry_total=6 block_total=5 absorbed_total=5 hp_restored=true | post=done checked=83 declared=83 parry_total=11 block_total=7 absorbed_total=7 hp_restored=true
spr41_g_sweep  SAME base_err=0 post_err=0 base_serr=0 post_serr=0 | base=done checked=56 declared=56 swept_total=44 swings_total=20 draws_total=20 | post=done checked=56 declared=56 swept_total=44 swings_total=20 draws_total=20
```

其余判据面（同件）：

```
C-a′ GREEN：§三 逐行与运行时组数完全对账，总账 94 条
VH10 ok |done checked=94 declared=94 swings_total=57 draws_total=57|
spr38_g_chk_fp           rc=0 verdict=VERDICT=ALL_MATCH hit=1 expect=1 | doc_hits=3 hits=1 hits=1 hits=1
spr38_g_chk_verbatim     rc=0 verdict=VERDICT=VERBATIM_MATCH hit=1 expect=1 | code_hits=27 doc_hits=27 expect=27
spr38_g_chk_quota        rc=0 verdict=VERDICT=IN_SYNC hit=1 expect=1 | hits: oracle_block=1 equip_calls=36 defs_block=1
spr38_g_chk_taut         rc=0 verdict_hit=1 expect=1 | 合计 应解析=568 实解析=568 可疑(T1+T2+T3)=0
TAU 记账可疑=1 豁免=1 非豁免=0 STALE=0 UNUSED=0 orphan=0 ｜ T3b T3B_REGISTERED=4 T3B_UNLISTED=0
      2 FAILED
     32 OK
```

### 2.1 `_PD_DECLARED` 旧值→新值＝**实数**，不是推算（V-A2／§F 第 1 条）

| 时点 | 盘上现读（`scripts/game_main.gd:5769`） | 独立闭合校验 |
|---|---|---|
| P-2 基线 | `const _PD_DECLARED := 70` | `_pd_assert(` 命中 71＝1 定义＋70 站点 |
| A-1 落地后（轮 3） | `const _PD_DECLARED := 80` | 运行面 `done checked=80 declared=80` |
| K-1 落地后（轮 6，终值） | `const _PD_DECLARED := 83` | `_pd_assert(` 命中 **84**（终盘现算：`grep -a -c '_pd_assert(' scripts/game_main.gd` ⇒ 84）＝ :5775 定义 1 ＋站点 83 ⇒ `checked=83 == declared=83` |

V-A2 的另一半（⛔ 把「没跑到」写成「跑过且通过」）：13 条新断言在终盘面里逐条有证据行（§6 粘贴 #71~#83），且 K-1 的 #83 自带**前提反证**（`measured=8/8/18<=34`＝八颗同拍摆出、扫描前无一被吃、最远 18 落在盾 reach 34 内），⛔ 空环冒充。

### 2.2 `equip_calls` 34 → 36 的加数（V-A5「只比断言行＋钉种子」之外的机械归因）

`_ml_equip("sh_bulwark", 99)` 当前树 5 处（`:4969 :6013 :6042 :6176 :6243`，现读）对改前树 3 处（`:4969 :6013 :6042`）⇒ 新增两条恰为 A-1 P-RNG 面 :6176、K-1 P-K8 面 :6243；`34 + 1 + 1 = 36`＝终盘 `chk_quota` 读数。oracle_block／defs_block 两侧均 1，未动。

---

## 3. churn：只比断言行（`SMOKE_SEED` 钉 12345；口径＝主理人 S40 裁定件 §5 第 1 条）

### 3.1 全驱动趟（改前工作树跑同一份套件，台账轮 8）

```
=== 改前树两件靶 md5（须等于 P-2 基线值）===
037f261d1b2d393fa02aba6a0bed1654 *D:/Create/Game/wt_s41a_base/scripts/player.gd
b934f7dd332c60374776aa9c240ca4e2 *D:/Create/Game/wt_s41a_base/scripts/game_main.gd
=== base 树 gates 起跑 12:53:38（隔离档改前计数=0）===
base gates exit=0  12:58:05  隔离档改后计数=0
CHURN-DONE red=0 blind_faces=无（口径：六面结构上不存在编号断言行，只比判定形状行＋结论行；有编号断言行的仅 melee(94)／sc(19)；stance 面无编号 token 但有 done checked=7 declared=7 真断言字段，故 ⛔ 列入『无断言行』，其比对走字段级掩除（S40-R48 §D-3））
CHURN-DONE rc_gates=0 rc_cmp=0  12:58:15
```
出处 `_tools/spr40_b/s154_s41_churn2_audit.txt`（197 行，末行即上列 rc 行）。同趟另附隔离档卫生现算：`_smoke 累积=0  test_1 侧计数=1`。

### 3.2 终盘趟（AFTER 换成 `_tools/spr41_post3`，台账轮 12）

```
FP-12345 GREEN 去行尾后逐字节相同 (175 字节)｜CR-BASE=1 CR-AFTER=1 行尾一致
FP-777 GREEN 去行尾后逐字节相同 (206 字节)｜CR-BASE=1 CR-AFTER=1 行尾一致
FP-42 GREEN 去行尾后逐字节相同 (213 字节)｜CR-BASE=1 CR-AFTER=1 行尾一致
CHK spr38_g_chk_fp GREEN 逐字节相同
CHK spr38_g_chk_quota GREEN 逐字节相同
CHK spr38_g_chk_taut GREEN 逐字节相同
CHK spr38_g_chk_verbatim GREEN 逐字节相同
CHK spr38_g_clause GREEN 逐字节相同
CHURN-DONE red=0 blind_faces=无（口径：六面结构上不存在编号断言行，只比判定形状行＋结论行；有编号断言行的仅 melee(94)／sc(19)；stance 面无编号 token 但有 done checked=7 declared=7 真断言字段，故 ⛔ 列入『无断言行』，其比对走字段级掩除（S40-R48 §D-3））
```
出处 `_tools/spr40_b/s154_s41_churn3_audit.txt`（161 行）。**两件须申报的**：
1. 该趟跑的是比对器本体（`BASE=…/spr41_churn_base AFTER=_tools/spr41_post3 bash _tools/spr40_churn.sh`，零 Godot、只读已落盘日志），⛔ 驱动头（base md5／gates 起跑行）与驱动尾（`rc_gates/rc_cmp`）不进本件；退出码当时只有终端值。为把 rc 钉上盘，同参复跑一次并逐字节验证可复现：`_tools/spr40_b/s154_s41_churn3b_audit.txt` ⇒ `RC=0`，`cmp` 与 161 行那份 `REPRO-SAME`。
2. `CR-BASE=1 CR-AFTER=1` 这三行**不作 CR 证据**：该字段用的 `grep -c $'\r'` 在本机退化成了空模式（见 §5 P-3），实测把样本 `a\nb\r\nc\n`（真 CR 行＝1）数成 3＝行数。改尺子复量同一批件：`FP-12345/777/42` 三件 `base_CR=0 post_CR=0`（`tr -cd '\r' | wc -c` ＋ python 字节计数双口径），字节数两侧相等（175／206／213）⇒ **指纹不漂移的结论由 tr 尺子重新坐实，去行尾逐字节相同照旧成立**。

`CHK … GREEN 逐字节相同` 这五行同样**降级**：其中 quota/verbatim/taut 三面是假绿形状，见 §5 P-2 与 `_tools/spr41_static_root/`（轮 10：同一把刀各喂两侧，只用刀已支持的覆盖口 ⇒ `quota rc_base=0 rc_head=0 cmp=DIFF`，改前树真值 `equip_calls=34` 对当前树 `36`；`verbatim/fp/clause cmp=SAME`，rc 全 0）。

E1 三 seed 原文（终盘 vs P-2 基线，`spr41_post3_runlog.txt`）：

```
fp12345  SAME
  base=fingerprint floor=1 rooms=(-1, 0),(-1, 1),(0, -1),(0, 0),(0, 1),(0, 2),(0, 3),(1, 1),(2, 1) kinds=secret,treasure,shop,start,combat,elite,super_secret,elite,boss
  post=fingerprint floor=1 rooms=(-1, 0),(-1, 1),(0, -1),(0, 0),(0, 1),(0, 2),(0, 3),(1, 1),(2, 1) kinds=secret,treasure,shop,start,combat,elite,super_secret,elite,boss
fp777    SAME
  base=fingerprint floor=1 rooms=(-1, -1),(-1, 0),(-2, 0),(0, -1),(0, 0),(0, 1),(0, 2),(1, 1),(2, -1),(2, 0),(2, 1) kinds=treasure,cursed,super_secret,secret,start,elite,shop,elite,boss,combat,combat
  post=fingerprint floor=1 rooms=(-1, -1),(-1, 0),(-2, 0),(0, -1),(0, 0),(0, 1),(0, 2),(1, 1),(2, -1),(2, 0),(2, 1) kinds=treasure,cursed,super_secret,secret,start,elite,shop,elite,boss,combat,combat
fp42     SAME
  base=fingerprint floor=1 rooms=(-1, -1),(-1, 0),(0, -1),(0, -2),(0, -3),(0, 0),(0, 1),(1, -1),(1, -3),(2, -1),(2, 0) kinds=treasure,secret,combat,combat,elite,start,super_secret,challenge,boss,combat,shop
  post=fingerprint floor=1 rooms=(-1, -1),(-1, 0),(0, -1),(0, -2),(0, -3),(0, 0),(0, 1),(1, -1),(1, -3),(2, -1),(2, 0) kinds=treasure,secret,combat,combat,elite,start,super_secret,challenge,boss,combat,shop
```

非断言行的引擎噪声照旧单列（⛔ 藏进 GREEN）：终盘 vs P-2 基线逐文件 `DIFF` 12 件（apply 177→166／base 121→117／fp12345 137→123／fp42 154→120／fp777 138→133／melee 204→202／pw 133→139／rng 143→149／sc 155→151／stance 133→150／parry 210→200／sweep 197→192，行数与「不同行数」见 runlog），全部落在 `JITTER_EXCLUDE` 前缀（时间戳／spawn／upgrade picked），断言行口径下一处不认。

---

## 4. 红侧证明（V-A1「一红一还原」＋A-3 牙口自证）

| 件 | 造错（盘上动作） | 实测红（逐字） | 还原 | 出处 |
|---|---|---|---|---|
| **A-1** 盾反主流抽取守恒 | 在盾反结算里插一句 `Game.rng.randf()`（推进主流 rng） | `RED-STATE md5=30f08de835392f863f32812221547f0d lines=2655 backup=_backup\spr41_a1_red\20261120T043700Z` → `RED-ARMED`；趟面 `ERR=8 okfalse=8` | `还原后 md5=d0b008cb2b67c649d96a35086338a822 期望=d0b008cb…` + `RESTORE-BYTEEXACT cmp=0`；还原后绿趟 `checked=80 declared=80`、`compared=82 diff=0 A2-ZERODIFF-GREEN` | `_tools/spr41_a2/s41_a1_red_arm_t3b.txt`、`s41_a1_parry_t3b_red.log`、`s41_a1_t3b_red_err_lines.txt`、`s41_a1_restore_diff.txt`（台账轮 5） |
| **K-1** P-K8 八向环面 | 摆放半径 `_sw_place(18.0, …)` → `200.0`（把八颗推出盾 reach） | `OK red-line inserted in P-K8 ring placement (18.0 -> 200.0)`／`RED-STATE md5=a768ed3ed9c2fb8be729ac913450536d lines=7532 backup=_backup\spr41_k8_red\20261120T044608Z`；`ERR=3 okfalse=3`；红行见下 | `还原后 md5=b9d46998f67c2cabc3efda944e2b3fa7 期望=b9d46998… cmp=0` + `K8-RESTORE-BYTEEXACT`；还原后绿趟 `83/83`、face 85 行 `diff=0` | `_tools/spr41_a2/s41_k8_red_arm_t4.txt`、`s41_k8_parry_t4_red.log`、`s41_k8_restore_t4.txt`、`s41_k8_zerodiff_t4.txt`（台账轮 6） |
| **A-3** 锚句存活闸 | ⛔ 动现役闸本体——**复制三份**，各改死一条锚句（全文唯一那条／函数域那条／函数头那条） | `RUN m1_unique_dead rc=1 \| S41-ANCHOR-DEAD 1 条：`／`RUN m2_scoped_dead rc=1 \| S41-ANCHOR-DEAD 1 条：`／`RUN m3_header_dead rc=1 \| S41-ANCHOR-DEAD 1 条：` | 现役闸件首件尾两算相同：`现役闸 md5=460474291e332b0f1ac4138d20a0e525 行数=109` ⇒ `现役闸复算 md5=46047429… 与件首相同`；`A3-FALSIFY-GREEN mutants=3` | `_tools/spr40_b/s165_s41_a3_anchor_falsify.py`（驱动器）、`_tools/spr41_a2/s41_a3_falsify/`（三副本＋`s41_a3_falsify_run_out.txt` stdout 留盘；该件首跑只出终端未落盘，故同参复跑一次把 stdout 钉上盘，副本与现役闸 md5 两次相同）（台账轮 13） |
| **D-1** #76 显示位 | 非造错趟：订正我自己写错的证据行取数（同行替换，零增删行） | 订正前 `s41_a1_parry_t2.log ERR=1 okfalse=1`——唯一红＝#76 显示位取错变量（我新面的证据行，非存量行为） | `s41_a1_parry_t2c.log ERR=0 okfalse=0 checked=80 declared=80` + `A1-PREFIX-GREEN`；t2b→t2c 仅 1 行显示位文本变 | `_tools/spr41_a2/s41_a1_parry_t2.log`、`s41_a1_dispfix_t2b_vs_t2c.txt`（台账轮 4） |

K-1 三条红行原文（`s41_k8_parry_t4_red.log`，逐字）：

```
[SMOKE-PARRY] #81 P-K8 八向环同一拍内走 PARRY 分支的颗数＝1（V-A4 反向：k 只能 1，⛔ 取同帧敌弹总数） measured=0 expect=1 ok=false
[SMOKE-PARRY] #82 P-K8 八向环同拍去向实测（现测形状）：BLOCK 颗数／被吃颗数／未处理颗数 measured=0/0/8 expect=1/2/6 ok=false
```

A-1 红行全量 8 条（守恒牙的**直接**证据：rng 态被推进成四个互不相同的非零值，⛔ 停在 `20261119`；逐字取自 `s41_a1_t3b_red_err_lines.txt:1-8`）：

```
[ERR] parry: P6 同上 state 逐字不变（⛔ 拿 randf 决定哪颗被吃掉／⛔ 结算里补一次抖动） | measured=-6160444323001747342 expect=20261119
[ERR] parry: P6 源级反证：两个结算函数体内零 rand*（段取空会让上一条退化成恒真 ⇒ 两条各管一头） | measured=1/0 expect=0/0
[ERR] parry: P-RNG b 单次盾反结算后 rng=(seed,state) 逐字不变（V-A1 ①） | measured=rng=(12345,-6160444323001747342) expect=rng=(12345,20261119)
[ERR] parry: P-RNG c① 同 RAISE 连续第 1 次盾反后 rng 逐字不变（V-A1 ②） | measured=rng=(12345,-1364477166339931308) expect=rng=(12345,20261119)
[ERR] parry: P-RNG c② 同 RAISE 连续第 2 次盾反后 rng 逐字不变（V-A1 ②） | measured=rng=(12345,2467643289946842374) expect=rng=(12345,20261119)
[ERR] parry: P-RNG c③ 同 RAISE 连续第 3 次盾反后 rng 逐字不变（V-A1 ②） | measured=rng=(12345,6173861408613947912) expect=rng=(12345,20261119)
[ERR] parry: P-RNG d 硬格结算后 rng 逐字不变（V-A1 ③；截断 0 ⇒ 无伤害出口） | measured=rng=(12345,6173861408613947912) expect=rng=(12345,20261119)
[ERR] parry: P-RNG e spawn_player_bullet 那一拍后 rng 逐字不变（返还弹预留位；V-A1 边界态） | measured=rng=(12345,6173861408613947912) expect=rng=(12345,20261119)
```
⇒ 造错一处被**两路**咬住（态观测＋源码级「函数体内零 `rand*`」反证），这正是该件要的「⛔ 守恒绿成『什么都没跑』」形状。

---

## 5. 偏差申报（与本单／常规不符之处，逐条，⛔ 沉默处理）

| # | 申报 | 盘上依据 | 编程侧是否已动 | 处置归属 |
|---|---|---|---|---|
| **P-1** | 我在 A-2 生产码注释（`player.gd:872`）里照抄了验证口径 V-A4 反向的机制句「其后 7 颗因 `_parry_hit_cd > 0` 全部走 BLOCK」，被本批自家 P-K8 面 #82 实测证伪：三态冷却下（cd>0 走 BLOCK、cd<0 本拍跳过、cd==0 且在窗口才 PARRY），八向环同拍真形＝**1 PARRY＋1 BLOCK＋6 颗本拍不处理** | `_tools/spr41_a2/s41_k8_face_lines_t4.txt`（#82 `measured=1/2/6`）、轮 9 | **已订正**（s161/s162 同行替换，`A2-COMMENT-GREEN`；`compared=85 diff=0 A2-ZERODIFF-GREEN`＋`A1-PREFIX-GREEN`＋`SELFCONS-GREEN`＋`P3-GREEN`；结论 `k 只能等于 1` 未变） | 结论级已结；**口径级**（V-A4 反向那句）请主理人一并订正；R76 裁语见 §E；已代执行（口径件 :34 同行替换，139 行／md5 `eaf37a248b`），§E-3.1 判据互斥已并入 R77 呈请 |
| **P-2** | churn 的**静态面同源自比**＝假绿形状：三把静态刀把 `ROOT = r"D:\Create\Game\test-1"` 拼死在文件里，`ROOT="$WT" bash _tools/spr38_gates.sh` 跑改前树时，探针面（`--path .`，已 `cd $ROOT`）真读改前树，静态面仍读当前树 ⇒ §3.1/§3.2 的 `CHK … GREEN 逐字节相同` 中 quota/verbatim/taut 三面**无证据力** | `_tools/spr38_oracle_quota_check.py:7`、`_tools/spr38_baseline_verbatim_check.py:8`、`_tools/spr38_tautology_sweep.py:20/:243`；复测 `_tools/spr41_static_root/`（`quota rc_base=0 rc_head=0 cmp=DIFF`） | **未动刀相**（⛔ 编程侧自改共享刀＝刀相属主理人；已列 §9 停等，task #107）；本轮只用刀已支持的覆盖口把真值量出来 | 主理人裁修法（三面透传 `ROOT`／或公开该面为盲区）；R76 裁语见 §B（裁甲：三面 ROOT 环境变量化＋gates 同车透传，轮 19 已落地）；**B-4 两句作废点名（逐字转录）**：①「交付件 §3.1 全驱动趟中 `CHK … quota/verbatim/taut … GREEN 逐字节相同` 作为「改前后静态面无漂移」证据的结论句——该三行系同源自比，无证据力（fp/clause 两面不受影响：fp 读 `$OUT` 日志、clause 经 `spr41_static_root` 复测 SAME）」；②「交付件 §3.2 终盘趟同样三行的证据力。**追补义务**：task #108 跨窗复现趟必须在 B-2 落地**之后**跑，届时三行才算成立」。B-4 第 3 条（其余依赖句由编程侧用 s187 同款工序点名）已随本行处置：§3.1/§3.2 依赖这三面的只有「三面 GREEN 逐字节相同＝静态面无漂移」一处结论，本行即为点名转录，⛔ 回改原文 |
| **P-3** | **CR 尺子缺陷**：`grep -c $'\r'` 在本机 Bash 工具下**与脚本文件内**都退化成空模式。样本 `a\nb\r\nc\n`（真 CR 行＝1、行数＝3）⇒ `grep -c` 给 **3**，`tr -cd '\r' \| wc -c` 给 **1**，python 字节计数给 **1** | 台账轮 10（样本串逐字在案：`bytes=b'a\nb\r\nc\n' CR=1 LF=3`／`grep-c-CR => 3`／`tr -cd CR bytes => 1`／`python CR bytes => 1`） | **尺子已换**：本件全部 `CR=` 读数走 `tr -cd '\r' \| wc -c` ＋ python 双口径；⛔ 删改比对器（共享件，另列 §9）。历轮 paste 的 `CR-BASE/CR-AFTER` 一律当**行数**读，不作 CR 证据 | 编程侧纪律（已生效）＋比对器行尾字段的修法请裁；R76 裁语见 §D；已落地（churn `:66/:67` 尺子换 `tr -cd` 字节计数＋`:62` 语义登记，91 行／md5 `2cd95413`），干跑与尺子自证见 `_tools/spr41_r76/` |
| **P-4** | 恒真普查**覆盖盲区**：`chk_taut` 的 macro 清单不含 `_pd_assert` ⇒ 本批 13 条新断言（#71~#83）不在同源恒真普查内（568 应解析里查不到它们）。我没有擅自把 `_pd_assert` 加进清单（那会同时改动普查口径与历史基线数） | `_tools/spr38_tautology_sweep.py` 宏清单现读；终盘 `合计 应解析=568 实解析=568` 与 P-2 基线**同数**＝新断言未被解析的证据 | **未动**（属刀相）；替代自证已做：`SELFCONS-GREEN 全部证据行 measured/expect 与 ok 三态自洽`（`scope=all 解析=83 ok_true=81 ok_false=0 词面跳过=2 违反自洽=0`） | 主理人裁是否给 `_pd_assert` 立案（HP-8 意义下的「零输入面」风险由 selfcons 面兜）；R76 裁语见 §C；**呈请 R77 未施工**（§C 前提与盘上 83 处 live `_ct_assert`、`spr38_r8_verify.py:70 MACROS = 9` 死针冲突，见 §9.1 ③行与 task #112；**R77 裁：前提作废，见 §C-1.1／§C-2(a)**——「一处改动」的成本估计被盘上实测推翻，改双轨后本行的盲区由 `_tools/spr41_pd_selfconsistency_check.py` 正面覆盖（现算 `30c37421c3`／312 行，生产面 `VERDICT=CLEAN_EXEC`），task #112 随 R77 §C 关闭） |
| **P-5** | 冻结表 2 条 FAILED＝本批两靶（`scripts/game_main.gd: FAILED`、`scripts/player.gd: FAILED`），**其余 32 条 OK** | 终盘 `2 FAILED / 32 OK` 与 FAILED 条目（runlog＋§2 粘贴）；§0 `GD-DIFF-COUNT=2` | ⛔ 刷表（§G3，收官由主理人/作者手工刷）。换代四件套见 §9（④冻结重定＝作者保留） | 收官车 |
| **P-6** | 终盘趟 churn 的**驱动尾 rc 当时未落盘**（只有终端值），我按证据卫生同参复跑补齐并验证可复现 | `_tools/spr40_b/s154_s41_churn3b_audit.txt`（`RC=0`，`cmp` ⇒ `REPRO-SAME`） | **已补**（复跑零 Godot，不占独占窗） | 已结（披露为形状偏差） |
| **P-7** | 轮 8 首跑作废：我在脚本执行期间编辑了脚本本身 ⇒ 该份改名留盘 `_tools/spr41_churn_base.aborted-s154a`（16 件，未删），结论重跑 | 台账轮 8「首跑作废」行 | 已重跑（§3.1） | 已结（纪律偏差，如实登记） |
| **P-8** | 实施单 §E 的一条**静态前提在盘上不成立**：`SPR41_实施单_编程侧.md:189-201` 假定改名将牵动 E1 指纹面。实测三 seed 指纹串只含 `floor/rooms/kinds` 三类字段，⛔ 武器名 ⇒ 文案改名趟（E4）结构上不可能被 E1 抓到，只能靠 §验证口径那条 `grep -rn "三枚锥\|低语法杖" == 0` 的死引用判据 | 本件 §3 粘贴的三条 `fingerprint … kinds=…`（无 name 字段）；`SPR41_验证口径.md:118` | ⛔ 据此放宽或替换 §E 判据（§G4/§H4：发现不可执行处**如实报**，不自行降级） | 主理人复核后改口径 |
| **P-9** | 我把引文审计刀 s166 的**失败态 stdout 原地覆盖了**：首跑 27 条 MISS 那份 `_tools/spr40_b/s166_s41_quote_audit.txt` 被我随后三次「同件重跑同文件」冲掉，盘上只剩终态那份。违反实施单 §F 第 2 条（失败态须新文件名，⛔ 原地覆盖）；27 条的内容以订正后行形留在 §1/§2/§3/§4，逐条原文已无独立凭据 | §8.1；本件 §5 本行＝唯一幸存记录（首跑计数 `代码块行=93 参与核对=84 命中=57 未命中=27` 只在会话里现算过，未上盘） | **已立规矩**（本轮起：同一把刀的结论件先留序号再重跑，多份 stdout 并存——`s168_..._out.txt` / `_out2.txt` / `_out3.txt` 三份并存即此规矩的执行） | 编程侧纪律（已生效）；登记于此供主理人复核证据卫生；**R77 §F-2.1 作废，s166 本体零改动、不进门禁，见 §F-2**——引文逐字可溯这道门改由 `_tools/spr41_deliverable_quote_gate.py` 承担（现算 `0d6824227e`／296 行），本行登记的卫生规矩随 R77 §F-2.3「新刀落地那一轮 s168 三针必须同轮换靶」的硬约束一并执行（首趟红证留盘，⛔ 原地冲） |
| **P-10** | **Edit 工具「吞相邻行」形状（本批三次）**：改长文档时 new_string 复述旧行，尾部被截或把下一行开头吃掉——①§8.1 插入吞掉「## 9. …」抬头；②P-9 行插入吞掉 P-8 行开头；③台账轮 15 的留盘件 bullet 插入吞掉「订正轮 13 改名凭据」整句（被截成 `…14:10 起…`）。前两次由写后立即复核抓到并当场复原；第三次是本轮（台账轮 16）复量台账 EOL 时 tail 才抓到 ⇒ 静默窗口真实存在，「写完不 tail」＝坏件留在盘上 | 台账轮 16（三处逐字复原凭据＋可用尺子复量）；本件 §5 本行 | **三处均已复原**（整段重述原文，非补丁式补字），生产码零触碰；纪律已改：凡 Edit 现存行，写后必 tail 该段并把行数／EOL 现量一遍 | 编程侧纪律（见 §9.2 第 6 条）；该形状属工具面，登记于此供主理人复核证据卫生 |

---

## 6. 盾反面原始输出片段（终盘，粘贴 `_tools/spr41_post3/spr41_g_parry.log:97-110`，面共 200 行）

```
[SMOKE-PARRY] #71 P-RNG b 单次盾反结算后 rng=(seed,state) 逐字不变（V-A1 ①） measured=rng=(12345,20261119) expect=rng=(12345,20261119) ok=true
[SMOKE-PARRY] #72 P-RNG b 反空转：恰 1 盾反且弹被吃（⛔ 守恒绿成「什么都没跑」） measured=1/true expect=1/true ok=true
[SMOKE-PARRY] #73 P-RNG c① 同 RAISE 连续第 1 次盾反后 rng 逐字不变（V-A1 ②） measured=rng=(12345,20261119) expect=rng=(12345,20261119) ok=true
[SMOKE-PARRY] #74 P-RNG c② 同 RAISE 连续第 2 次盾反后 rng 逐字不变（V-A1 ②） measured=rng=(12345,20261119) expect=rng=(12345,20261119) ok=true
[SMOKE-PARRY] #75 P-RNG c③ 同 RAISE 连续第 3 次盾反后 rng 逐字不变（V-A1 ②） measured=rng=(12345,20261119) expect=rng=(12345,20261119) ok=true
[SMOKE-PARRY] #76 P-RNG c 反空转：同一次 RAISE 内恰 3 次盾反（⛔ 用 BLOCK 冒充 PARRY） measured=3 expect=3 ok=true
[SMOKE-PARRY] #77 P-RNG d 硬格结算后 rng 逐字不变（V-A1 ③；截断 0 ⇒ 无伤害出口） measured=rng=(12345,20261119) expect=rng=(12345,20261119) ok=true
[SMOKE-PARRY] #78 P-RNG d 反空转：恰 1 硬格且弹被吃 measured=1/true expect=1/true ok=true
[SMOKE-PARRY] #79 P-RNG e spawn_player_bullet 那一拍后 rng 逐字不变（返还弹预留位；V-A1 边界态） measured=rng=(12345,20261119) expect=rng=(12345,20261119) ok=true
[SMOKE-PARRY] #80 P-RNG e 反空转：真生成了一颗 friendly 弹（⛔ 空调 spawn 占位） measured=true/true/1 expect=true/true/1 ok=true
[SMOKE-PARRY] #81 P-K8 八向环同一拍内走 PARRY 分支的颗数＝1（V-A4 反向：k 只能 1，⛔ 取同帧敌弹总数） measured=1 expect=1 ok=true
[SMOKE-PARRY] #82 P-K8 八向环同拍去向实测（现测形状）：BLOCK 颗数／被吃颗数／未处理颗数 measured=1/2/6 expect=1/2/6 ok=true
[SMOKE-PARRY] #83 P-K8 前提反证：八颗同拍、实测最远距离落在盾 reach 内、扫描前无一被吃（⛔ 空环冒充） measured=8/8/18<=34 expect=8/8/18<=34 ok=true
[SMOKE-PARRY] done checked=83 declared=83 parry_total=11 block_total=7 absorbed_total=7 hp_restored=true
```

存量 70 条（#1~#70）与 P-2 基线／前趟的逐字对照：`compared=85 diff=0 A2-ZERODIFF-GREEN`（t4 vs t5，`_tools/spr41_a2/s41_a2c_zerodiff_t5.txt`）与 `compared=85 diff=0 A2-ZERODIFF-GREEN`（t4 vs 终盘，`_tools/spr41_a2/s41_post3_vs_t4_parrycmp.txt`）；A-1 落地趟 `base_lines=72 trip_lines=85 prefix_compared=71 new_face=13` + `A1-PREFIX-GREEN`（前缀 71 行＝70 断言＋done，⛔ 让新增面把存量行顶掉）。

---

## 7. §H 四项回账（主理人要的短答案）

**① A 组三件实测数**
- 新 `_PD_DECLARED`＝**83**（`scripts/game_main.gd:5769` 现读；路径 70→80（A-1）→83（K-1），每步为盘上实数＋`_pd_assert` 站点数 84＝1 定义＋83 站点闭合）。
- A-1 故意红的原文行＝§4 表 A-1 行 + 四条 `measured=rng=(12345,−6160444323001747342 / −1364477166339931308 / 2467643289946842374 / 6173861408613947912)` 逐字（全量 8 条在 `s41_a1_t3b_red_err_lines.txt`）。
- A-2 零 diff 结论：`compared=72 diff=0`（Trip1 落地趟，比的是 P-2 基线 71 条存量＋done）→ 终盘 `compared=85 diff=0`（对 t4），两次都 `A2-ZERODIFF-GREEN`；行为面 `parry_total/block_total/absorbed_total` 在 A-2 趟**一个数没动**（`6/5/5`，见轮 2 与轮 1 同值）。

**② P-3 锚点 `count != 1` 的现场**：**无，全部 count==1**。终盘 `P3-GREEN 全文唯一40＋函数域唯一6 ⇒ 全部坐实`（`_tools/spr41_post3/spr41_p3_anchors.txt` 末行），含本批新落的三条：`H4a PARRY 结算函数 … 全文count=1  func _settle_parry(b: Node, k: int) -> void:`、`S41-A2 k 定义锚 … 全文count=1  k ＝ 本次 RAISE 内实际走了 PARRY 分支的颗数`、`V-A4 反向 八向环摆放 … 函数域count=1(期望1)  kb.append(_sw_place(18.0, float(k8_i) * 45.0`。⚠️ 但闸本身的牙此前只有绿侧见证，本轮补了三形态造错（§4 A-3 行，3/3 `S41-ANCHOR-DEAD rc=1`）——A-3 的「形状统一」我按「⛔ 只见过 GREEN 的闸等于没证」自证到红侧，这条超出实施单字面要求，登记在此供追认。

**③ §E「三枚锥 `count=1`」错位：同意。** 复算：`scripts/weapons.gd:254` `"name": "三枚锥", "desc": "慢手近掷",`／`:255` `"dmg": 2.20, "interval": 0.90, "count": 1, "spread": 3.0,`——名字承诺三枚、机制只掷一枚，逐字在案；同族 `wd_whisper`（`:260-262`）`name=低语法杖 desc=两枚低语追踪` 与该块 `count` 对得上，本批只动措辞不动数量词的判断成立。**⇒ 请并进 E4 一起问作者（E7）。** 另附 §5 P-8：该趟真落地时 E1 指纹面抓不到，别把它当防退化面。

**④ 本单不可执行处**：§A/§F/§G 的字面要求都可执行，已逐条落地。须**呈请改口径**的是两处**判据面**（不是 §A 本身）：
- churn 静态三面（P-2）：`ROOT` 硬编码 ⇒ 「喂改前树」这一步在现有刀相下做不到真读，盘上依据 `_tools/spr38_oracle_quota_check.py:7`、`_tools/spr38_baseline_verbatim_check.py:8`、`_tools/spr38_tautology_sweep.py:20/:243`；`taut` 连覆盖口都没有（`fp` 文档侧也无），⛔ 我自行绕过、⛔ 自行降级判据。
- §E 的「改名牵 E1」前提（P-8）：`SPR41_实施单_编程侧.md:189` 起的那段按盘上指纹字段（`floor/rooms/kinds`）结构上不可成立。

---

## 8. 禁止事项 #1~#7 逐条自查（实施单 §G）

| # | 条款 | 自查 | 证据 |
|---|---|---|---|
| 1 | ⛔ 改 `scripts/*.gd` 之外冻结面时跳过现算 md5；34 件全冻结，改前改后都要快照 | **未违反**：§0 表两列＝改前/改后现算 md5；`gd_count=34` 与冻结表 34 行对齐；`GD-DIFF-COUNT=2` | 本件 §0；`_tools/spr41_pre`/`_tools/spr41_post3` |
| 2 | ⛔ 碰 `D:\大纲` | **未碰**：本批所有写操作限于 `test-1` 内 `scripts/`、`_tools/`、`production/sprint-41/` | 台账轮 1~13 全部出处路径 |
| 3 | ⛔ `git commit`／`git push`／刷 `SPR21-FROZEN.md5` | **全未做**：零 commit/push；冻结表未被写过（终盘仍 `32 OK / 2 FAILED`，FAILED＝两靶） | §5 P-5；`md5sum -c` 输出逐字在 §2 |
| 4 | ⛔ 为让门变绿而改断言期望值／探针 oracle 副本 | **未违反**：唯一动过的期望常数＝`_PD_DECLARED`（70→80→83），系实施单 A-1/K-1 明文要求的授权重钉，每步实数现读＋站点闭合（§2.1）。造错副本（A-1 插随机、K-1 改半径、A-3 三 mutant）跑完即还原，现役件 md5 首尾相同 | §4；轮 5/6/9/13；`_tools/spr41_a2/s41_a3_falsify/s41_a3_falsify_run_out.txt` |
| 5 | ⛔ Area2D／新碰撞层掩码（HP-5）；⛔ 命中相关抽取（HP-3）；⛔ 零输入面报绿（HP-8） | **未违反**：零新节点/层；A-1 的笼子**只读** `Game.rng.state` 与既有结算，⛔ 新抽取；#72/#76/#78/#80/#82/#83 六条反空转/反证行把「什么都没跑」的绿堵死（`parry_total 6→10→11`、`block_total 5→6→7`＝真跑了东西的记录在案） | §6；轮 3/5/6/7 |
| 6 | ⛔ 把 §B~§E 当「顺手做完」 | **未越界**：本批零触碰返还表（§B）、贪手惩罚（§C）、刃风余韵（§D）、改名（§E）。`_settle_parry` 只加可观测入参、行为一字不变（:873 注释钉住） | §0.1；§9 停等表 |
| 7 | ⛔ 同一趟混改三元组／哨兵／锚句三类面 | **未混改**：六趟分车（§0.2）。唯一须披露的形状＝轮 9 注释订正趟与验证趟同窗跑（s162 只跑验证件，⛔ 再写生产码） | §0.2；轮 9 末行 `S162-DONE apply=0 green=0 zerodiff=0 prefix=0 selfcons=0 p3=0 13:05:54` |

---

### 8.1 本件引文自证（§G 之外的自查加项，⛔ 冒充 §G 条款；针对的是「转述」这一类我自己在本轮犯过的错）

§F 第 1 条要求尾部行**粘贴**，但「长得像实测的行」肉眼检不出。本轮立了把只读刀 `_tools/spr40_b/s166_s41_deliverable_quote_audit.py`：把本件每个代码块行去行号前缀与行首缩进后，拿到盘上证据件／源码语料里找逐字同形；并把「只在 `production/` 文档里出现过」的单列成**二手命中**（台账是证据的抄件，⛔ 自证）。首跑结果 `代码块行=93 参与核对=84 命中=57 未命中=27`——**27 处全是我的转述**：省略号截断、目测列宽重排空格、掉了 `[ERR] parry: ` 前缀、把 `VERDICT=` 写漏。

修复用 `_tools/spr40_b/s167_s41_doc_quote_patch.py`（不手抄空格：按行键从源件把那一条原文搬过来，造错点命中数先断言==1，任一断言失败即 ABORT 不落盘）：`rules=18 patched=11 same=7 lines=323（与改前同行数）`，另三处整块（§1 七面摘要行／§2 九行比对行／§4 A-1 红行 6→8 行）由 Edit 直接换成盘上片段。终态：`_tools/spr40_b/s166_s41_quote_audit.txt` 末行 `QUOTE-AUDIT-GREEN`，且同一行上方 `一手命中` 与 `参与核对` 相等、`仅二手命中=0 未命中=0`。**本件不粘贴审计刀自己的这两行结论**——粘了就自指：抄进去的每一行都算进 `代码块行/参与核对`，抄一次就把被抄的那一行作废（本轮试过一次，`95/86 → 103/94` 就是这么来的）。要数请现跑现读。

这把刀自己也被造错自证（`_tools/spr40_b/s168_s41_quote_audit_falsify.py`，⛔ 只见过 GREEN 的闸等于没证；造错全打在副本上，现役刀与交付件 md5 件首件尾相同）：

```
RUN m1_spacing rc=1 期望牙印=MISS spr38_g_chk_quota
RUN m2_ellipsis rc=1 期望牙印=MISS [SMOKE-PARRY] #83
RUN m3_empty_corpus rc=1 期望牙印=语料一手行=0
RUN m5_doc_unreadable rc=1 期望牙印=交付件读不到
RUN m4_skip_all rc=1 期望牙印=参与核对=0
QUOTE-FALSIFY-GREEN mutants=5 副本留盘=_tools/spr41_a2/s41_quote_falsify
```

须申报的两条**这轮才暴露的形状**：
1. **s168 首跑四条全因「交付件读不到」而红**＝harness 把 DOC 重定向目录拼错，红来自别处不算证。补上「每条必须在自己的牙印上见红」断言后才真绿——这条正是 V-A1「只见过 GREEN 的闸等于没证」抓出来的第二层。
2. **审计刀语料含它自己那份 stdout** ⇒ 里面 `MISS …`／`SECONDARY …` 两行装的正是转述错句，留着等于「我把错句抄回交付件，它会在那份 stdout 里被找到」＝牙被自己的排泄物喂平。现役刀已改成**按行剔**（`feed()` 里 `startswith("MISS "/"SECONDARY ")` 丢弃）。第一版我按文件名整份剔除，副作用当场暴露：连 `QUOTE-AUDIT`／`RUN … rc=1` 结论行也进不了语料，交付件引自己那把刀的结论反而 MISS——按行剔只砍掉会自证的那两类行，两条都成立。牙口由 s168 五刀自证。

出处：`_tools/spr40_b/s166_s41_quote_audit.txt`、`s167_s41_doc_quote_patch.txt`、`s168_s41_quote_falsify_out2.txt`（`_out.txt`＝加语料剔除前的首跑，留盘作订正凭据）；台账轮 15。收尾复跑（台账轮 16／16′ 全部上盘后）＝`_tools/spr40_b/s166_s41_quote_audit_t*.txt` 一族并存，判据行逐趟同值＝本轮文档面增改没往交付件里塞进新转述（计数⛔ 粘贴在此，理由见上）。诚实的形状申报：本行一写，「终值」就属于下一趟——文档面自指没有固定点，只有"每改一趟复跑一趟"这条纪律；台账里 t2/t3/t4 三趟的差只落在语料规模行，判据行从未变过。

---

## 9. 不等点头的下一步（编程侧自裁顺序）与本批停等项


### 9.1 停等项（⛔ 编程侧自便；逐条给归属与盘上依据）

| 停等 | 内容 | 归属 | 盘上依据／坐标 |
|---|---|---|---|
| **①冻结重定＝换代四件套**（作者保留权④） | 本批两靶转正必须**四件同轮**，缺一即三处腐烂：(a) 刷 `production/sprint-21/SPR21-FROZEN.md5` 两靶行（终值 `31bafa6a…`／`b9d46998…`）；(b) 晋升绿件 `_tools/spr38_good_player.bak`（现读 `037f261d1b2d393fa02aba6a0bed1654`，2648 行）→ 新绿；(c) 三条 live green-md5 针同步：`_tools/spr38_evidence_verify.py:114 EXPECT_MD5`、`_tools/spr38_r8_verify.py:27 GREEN_MD5`（:29 `PREV_GREEN_MD5 = "dc622351…"` 降为历史串，⛔ 抹平，由 C10f 专拦）、`_tools/spr38_report_selfaudit.py:28 GOOD_MD5`；(d) 文档声称层 floors（`EXPECT_FROZEN = (34, 0)` at `_tools/spr38_evidence_verify.py:117` 等） | **收官车**（作者手工刷；⛔ 我碰表） | §2 `2 FAILED / 32 OK`；`_tools/spr38_r8_verify.py:442` 的 `bak==player==GREEN_MD5==ev_expect==sa_good` 五串全等式，在 (a)~(c) 未同轮时结构上必红 |
| **②churn 静态面 ROOT 透传修法** | quota/verbatim/taut 三面在喂改前树时仍读当前树；`taut` 与 `fp` 文档侧连覆盖口都无 | 主理人（刀相）；已立案 **task #107**；**R76 已裁**（`production/sprint-41/SPR41_主理人裁定_R76_停等六项刀相与口径收口.md`），施工按 §B——§B 已于轮 19 落地：quota／verbatim／taut 三面 `ROOT` 环境变量化＋gates 调用面同车透传（三把静态刀各加路径存在闸，缺件⇒`FAIL …（UNEXECUTED，HP-8）` rc=1）；自证 `_tools/spr41_r76/s190_r76_b_verify1.txt`、跨树喂件 `s191_r76_b_crosstree1.txt`。**B-3 第 1、2 条（链级两面）需 Godot 窗，归 #108**，本窗未跑⇒该两条仍停等；**R77 §B 补票**（`production/sprint-41/SPR41_主理人裁定_R77_三处不可执行面重裁与taut补闸.md`，md5 现算 `8944d56310`／238 行）：§B 落地时只在 `--falsify` 面加了路径存在闸、生产面漏挂 ⇒ R77 §B-2 裁「quota/verbatim 同款两行闸插两处（生产面＋falsify 面）」，本轮补齐（`_tools/spr38_tautology_sweep.py` 429→434 行；裁语 §B-2.4 写「432」系 +3 行口径、与 §B-2.1/§B-2.2 自数的五行差 2 行，本件按盘上逐字插码真值转录，差数如实申报见 `_tools/spr41_r77/s200_r77_b_taut_gate1.txt`），凭据 `_tools/spr41_r77/s200_r77_b_*` | §5 P-2 三条文件@行；`_tools/spr41_static_root/`（quota `cmp=DIFF` 34↔36，verbatim/fp/clause `cmp=SAME`） |
| **③`_pd_assert` 是否进恒真普查宏清单** | 13 条新断言在普查外（568 应解析未变＝证据）；我用了 `SELFCONS` 面替代自证 | 主理人裁；**R76 已裁**（`production/sprint-41/SPR41_主理人裁定_R76_停等六项刀相与口径收口.md`），施工按 §C——**本窗未执行，呈请 R77**：§C-2.1 的前提「`_ct_assert` 只是普查宏里的'别名'」与盘上实测冲突（`scripts/` 里 `_ct_assert` 84 处命中、其中 83 处是 live 调用站点；`_tools/spr38_r8_verify.py:70 MACROS = 9` 与 gates 宏清单系死针），改名与加宏都会牵动 568 基线数＝数值口径未裁 ⇒ 见 task #112；**R77 重裁**（`production/sprint-41/SPR41_主理人裁定_R77_三处不可执行面重裁与taut补闸.md`）：③ 不立案改双轨——九 macro 普查口径逐字不动、`MACROS = 9` 与 568 基线一个都不改，盲区由新立机检 `_tools/spr41_pd_selfconsistency_check.py` 正面覆盖（PD-T1~T4 四档，站点下限现读派生⛔ 写死 83），已接进 `_tools/spr38_gates.sh`（现算 `53ed5cee95`／135 行）的 CHK 面循环；牙口与生产面读数见 `_tools/spr41_r77/s202_r77_c4_*`、`s203_r77_c4_gates_full1.txt`、`s206*_r77_c4_extract_teeth*` | §5 P-4；`_tools/spr41_a2/s41_a2c_selfconsistency.txt` |
| **④比对器行尾字段（`CR-BASE/CR-AFTER`）的尺子修法** | `grep -c $'\r'` 退化；本件已弃用该口径 | 主理人（`_tools/spr40_churn.sh` 属共享件）；**R76 已裁**（`production/sprint-41/SPR41_主理人裁定_R76_停等六项刀相与口径收口.md`），施工按 §D——§D 已于轮 19 落地：churn `:66/:67` 同行替换为 `tr -cd '\r'` 字节计数、`:62` 补语义登记句（91 行不变，md5 `718d541f`→`2cd95413`）；尺子自证 `s192_r76_d_cr_ruler1.txt`，对账走副本干跑 `s193_r76_d_churn_dryrun1.txt`（⛔ 对登记证据目录跑 churn：它原地重写 `$AFTER/fp*.full_selftest.txt`，原证 md5 已复核未动） | §5 P-3 样本逐字 |
| **⑤§B 返还表 / §C 贪手 / §D 刃风 / §E 改名＋E7** | 全部数值与方向在作者手里（E1/E2/E3/E4/E7） | 作者→主理人→落地单 | `SPR41_实施单_编程侧.md:97/149/165/189` |
| **⑥V-A4 反向那句** | 口径件里的「其后 7 颗全部走 BLOCK」与实测 1/2/6 不符（生产码注释我已订正，口径件⛔ 我改） | 主理人；**R76 已裁**（`production/sprint-41/SPR41_主理人裁定_R76_停等六项刀相与口径收口.md`），施工按 §E——§E 属主理人文书面，由编程侧持本件**预演断言代执行**（§H-3 授权）：口径件 :34 同行替换、139 行不变、md5 `36155382`→`eaf37a248b`，验收 `s195_r76_e_acceptance1.txt`。**§E-3.1 的 grep 判据与裁语自身互斥**（替换文本内含旧短语，两口径现测 1／0 相反）⇒ 并入 R77；**R77 重裁**（`production/sprint-41/SPR41_主理人裁定_R77_三处不可执行面重裁与taut补闸.md`）：⑥′ 验收尺子重立——旧短语命中数从「==0」改判「==1 且该行即作废句本身」，另用「第一次结算走 PARRY」==0 作旧断言复活探针；R77 §E-2 五条尺子命令本轮现测全满足（零施工，`SPR41_验证口径.md` 139 行不变），凭据 `_tools/spr41_r77/s204*_r77_e2_ruler*.txt` | §5 P-1 |
| **⑦S40 侧旧挂账**（与本批并行、不受本批影响） | #77 M4 一车链验证、#89 R63 落地车、#106 R75 另车（若主理人要求复核）、#70/#38/#52/#40/#6/#10/#14、EV 丙案移档、s63 态数文案、收官车｜`spr38_promote_good.sh`→`spr40_promote_good.sh` 更名**＝轮 18 已收口**（R61 §3 第 3 条归编程侧：刀 `_tools/spr40_b/s178_s41_s92_hostlist_fix.py` 订正 s92 八宿主名单三处假路径＋补「先证路径存在」闸，验收 `_tools/spr40_b/s178b_s92_hostlist_verify.txt`＝`S178b-VERIFY GREEN issues=0`） | 各原单 | task 清单 |
| **⑧引文审计刀 s166／牙口刀 s168 是否转正进门禁** | 两把刀现只在本轮手工跑（纯文档面，零 Godot，不占独占窗）。s166 已具备一手／二手语料分级、三条零输入红线与非零退出码；s168 已证 5 个失败形态各咬各的牙印 | 主理人（刀相：接不接进 `_tools/spr38_gates.sh`／收官链、放哪一相、⛔ 我自行接线）；**R76 已裁**（`production/sprint-41/SPR41_主理人裁定_R76_停等六项刀相与口径收口.md`），施工按 §F——**本窗未执行，呈请 R77**：§F-2.1 要求 s166 宿主文档可注入，§F-2.5 又声明「三刀本体本次零改动」，二者互斥（`s166:18` 宿主件路径焊死在代码里）；§F-2.2/§F-2.3 的 checks 现算化与两条防空转纪律随本行登记，待 R77 裁后再施工 ⇒ task #112；**R77 重裁**（`production/sprint-41/SPR41_主理人裁定_R77_三处不可执行面重裁与taut补闸.md`）：⑧ 采第三条路——s166 本体零改动、不进门禁（R76 §F-2.1「s166 转正接门禁」一句作废），改立新常驻刀 `_tools/spr41_deliverable_quote_gate.py`（DOC／语料清单可注入，一手／二手分级与 `MISS`／`SECONDARY` 按行剔除照 s166 语义逐字继承，零输入面 RED＋非零退出），已接进 gates 的 CHK 面循环；s168 的 `SRC`／DOC 针／m5 针**同轮换靶新刀**并重新证牙（`QUOTE-FALSIFY-GREEN mutants=5`，失败态首趟留盘 `s208_r77_f22_teeth1.txt`），s187 维持 R76 §F-2.3/§F-2.4 原裁 | §8.1；`_tools/spr40_b/s166_s41_deliverable_quote_audit.py`、`_tools/spr40_b/s168_s41_quote_audit_falsify.py`、`_tools/spr40_b/s168_s41_quote_falsify_out3.txt`（末行 `QUOTE-FALSIFY-GREEN mutants=5`）；本轮再加第三把只读刀 `_tools/spr40_b/s187_s41_cited_path_verify.py`＝正文引用路径存在性核验（终态 GREEN，已核 39 条真件、缺件 0，凭据 `_tools/spr40_b/s187_s41_cited_path_verify_stdout3.txt`；它自身也留了两趟订正：`…_stdout1.txt` 把通配写法 `_tools/_*` 当路径误报 RED、`…_stdout2.txt` 分类口径过松把引用行里的星号当通配） |

### 9.2 不等点头、我下一轮自己排的（⛔ 需要作者/主理人介入的都不在此列）

1. 台账轮 14+：若主理人对 §5 P-1/P-8 给出裁语，按裁语落订正趟（同行替换，零增删行）。
2. 独占窗内把 A 组终盘再复跑一趟做「跨窗可复现」见证（`bash _tools/spr38_run.sh` 唯一入口，锁优先让路；不在跑时不动）。⚠️ 轮 18 实测：**这一趟结构上排在停等①之后**，不是「找个空窗就能跑」——`bash _tools/spr38_preflight.sh` 现测 rc=1，两行逐字＝`BLOCK 基线过期：绿基线=037f261d1b2d393fa02aba6a0bed1654 盘上=31bafa6a72386504d925afc72bfb2d54（先肉眼确认哪份是绿的，再 cp scripts/player.gd _tools/spr38_good_player.bak）` 与 `PREFLIGHT BLOCK 本轮只做零 Godot 的活`（凭据 `_tools/spr40_b/s179_s38_preflight_measure1.txt`；本窗更早一次同命令给出逐字相同的输出，但那趟 stdout 未落盘，⛔ 不当凭据引用）。晋升绿基线＝换代四件套之一，归作者／收官车（停等①），⛔ 我自刷 ⇒ task #108 保持 pending，本轮改做零 Godot 件。
3. §B~§E 一律**不动**：任何一步都要 E1~E4/E7 裁语开路，早落一步返工整轮手感验收（§G6）。
4. 旧挂账里属编程侧的机械件（#106 之外的更名、s63 文案）在 S41 窗空档时按 task 描述顺序做，做完只报实测数。
5. 证据卫生两条自裁纪律已在 §5 P-9／§8.1 生效并沿用：同一把刀重跑先给上一份落序号名（⛔ 原地冲失败态）；文档里⛔ 粘贴"由本件自身产生的计数行"（自指必不稳）。本轮已落 AGENTS：§5 末「证据卫生两条」＋§7 末两条工具坑（刀 `_tools/spr40_b/s176_s41_agents_hygiene_writeback.py`，改前份 `_backup/s41_doc_append/AGENTS.md.pre-s176`）。
6. Edit 工具的「吞相邻行」纪律（§5 P-10 的处置面）：凡改现存行，`new_string` 必须**整行重述**，写完立刻 `tail`／`grep -n` 复核该段并现量行数与 EOL——不复核就等于把坏件留在盘上（本轮第三次就是这么漏的）。长文档追加不再手改，改用带断言的搬盘刀（s167/s169 形状：锚点命中==1、只插不删、行数增量==计划数、任一断言失败 ABORT 且零写入）。
7. 长文档表格的两条渲染纪律（轮 18′ 实测收口，已落 AGENTS §7）：其一，表头行⛔ 省掉行尾竖线——省了表头就比数据行少一格，整张表连带被判不齐（实测一张 13 行的表报 `不齐表=1 不齐行=15`，错在表头不在数据行）；其二，表格里引用别家文档的表格行，改写成「其第 N 格＝…」的转述，ASCII 竖线不出表（实测粘了 R60 一行原文，把一格撑成 6 格）。配套教训：订正刀的锚点若恰是别行的前缀，子串口径命中天然不等于 1（实测 18），须换「整行逐字相同」口径且仍要求全文命中==1——s182 首趟因此 ABORT 零写入，属断言正常工作而非事故。另一条同族教训（本刀首趟）：把守卫写成全文件条件会撞上别人的存量——交付件 :328/:329 早有存量双空行，「无三连空行」按全文件一数就误 ABORT；正解＝改前／改后各数一遍、只要求⛔ 新增，存量不在本轮战场。第二趟又坐实一条红线：锚点文本按记忆推（把并不存在的 `pre-s185` 当成台账点名里已有的串）⇒ 命中 0 再 ABORT，＝「⛔ 未现读锚行盲插」的变体；正解＝落锚前现读该行首尾，别拿上一轮的记账当盘上现值。第三条是本刀自己踩的证据卫生：重跑同一把刀前⛔ 用 `>` 原地覆盖上一份 stdout——第一趟的 ABORT 逐字串就是被第二趟冲掉的，事后只能申报、盘上不可复算；正解＝先把上一份 `mv` 成序号名（失败态留盘）再跑，本次已按此办理（`…_out2_abort.txt`）。刀 `_tools/spr40_b/s182_s41_ledger_round18_table_fix.py`、`_tools/spr40_b/s183_s41_agents_round18p_pitfalls.py`、`_tools/spr40_b/s185_s41_ledger_row_agents_census.py`、本刀；改前份 `_backup/s41_doc_append/S41_台账.md.pre-s182`、`AGENTS.md.pre-s183`、`S41_台账.md.pre-s185`、`SPR41_编程侧交付_A组.md.pre-s186`；复量凭据 `_tools/spr40_b/s185_s41_ledger_row_agents_census_out.txt`（末段＝台账上盘后的卫生复量），本件自身计数⛔ 抄进正文（P-9／§8.1）。

### 9.3 R79 车次状态格（轮 21 转录；八格标题现读自裁定件，数字现读自凭据目录）

| 格 | 裁语标题（现读） | 本轮处置 | 盘上依据／坐标 |
|---|---|---|---|
| §C-① | ① taut 行数账 —— 裁「432 作废」 | 纯申报（作废的是裁定件自己的算术，⛔ 作者）｜本轮零施工 | R80 §B 首行＋§C-① 规则 (a) 逐块清单 |
| §C-② | ② r8 常量派生 —— 裁「800／802 双作废，803 为准」 | 纯申报（800／802 双作废，以盘上现算 803 起算为准）｜本轮零施工 | R80 §B（r8_verify 起点现读 b1bbf96d0e/803） |
| §C-③ | ③ churn 改前树两面必红 —— 裁**乙**，并补两项硬前置 | 已落地乙-1／乙-2｜第 5 条**未落地**（env 换不到件名，落地＝净变差） | R79-C35-WTPROOF GREEN issues=0；R80 §F |
| §C-④ | ④ gates 换代连带三面红 —— C15a 裁**甲**，其余裁**丙** | 甲案已落地（C15a 基线改指登记产物＋新臂 P57）｜其余丙 | R79-F237-REG RED issues=2 ok=78 declared=6；P55 冲突见 R80 §E |
| §C-⑤ | ⑤ MSYS 混合分隔符（第三次复现）—— 裁**乙＋甲合流** | 乙＋甲合流已落地（extract normpath＋AGENTS §7 追加条） | R79-C5-MIXEDSEP GREEN issues=0 declared=3｜净 +1 超裁语「净 0」，申报见 R80 §B |
| §C-⑥ | ⑥ SELFTEST-BLOCK —— 裁「不是作者格，是 ④⑦ 的结构后果」 | 纯申报：BLOCK 是 ④⑦ 的结构后果，⛔ 当阴性结论也⛔ 当阳性缺陷 | 解禁串 R79-MISSROOT GREEN issues=0 ok=13 |
| §C-⑦ | ⑦ P2b padding 空操作 —— 裁「逐字裁语作废，改现读形状」 | 已落地（P2b 转正＋`:680` 响失败断言）｜独红**结构不可达**（6 发已试） | R79-P2B-SHAPE GREEN issues=0 ok=38 shapes=6；形状表见 R80 §D |
| §C-⑧ | ⑧ 证据卫生自曝两件 —— 追认 ＋ 两条常设规矩 | 追认＋两条常设规矩沿用（立规一逐份留盘、立规二写盘⇄复核分刀） | 本车即两把刀：s244 写盘／s245 复核；R80-CLAIM-AUDIT GREEN issues=0 ok=29 |

停等归口：本轮唯一作者级停等＝**#108 独占窗放行**（链＋Godot headless 全套＋`red=0`／`miss=0`／C15e 入册三格都在那扇窗内）；§C-③④⑤⑥⑦ 的不可达项全部带可判解禁条件，登记为 DECLARED-1…24（盘上现读最大号），逐条出处按号段见 `SPR41_编程侧呈请_R80_R79车次回执_P2b独红不可达形状表_MISS9归因_F2至F7实测.md`（DECLARED-1…16）、`SPR41_编程侧呈请_R81_J4裁语转录落地_验收尺实测_生产码mtime两格归因_申报21至24.md`（DECLARED-21…24）与`SPR41_编程侧呈请_R82_s253六趟账_车后两件复跑_两条只读刀新坑_号域不新增.md`（R82 收口件，⛔ 新申报号；DECLARED-21…24 的四件正文在 R81 件，R82 件只把 s253 六趟账并到 DECLARED-22 之下续记）；号域写法本身不算单独实录（取号尺见 `AGENTS.md` §7）。
主理人侧待办：R80 §J 六项（J-1 P2b 独红三选项／J-2 P55 延后／J-3 件名漂移二选一／J-4 §F-7 命令名订正＝**已裁并落地**，裁语转录见裁定件 §K＋R81 §B／J-5「车次」口径入 `AGENTS.md` §7＝**已落**／J-6 卫生三件）；R81 §G 三项（J-A 历史生产码写入的等效凭据口径＝s161 写 `scripts/player.gd` 无编号证件／J-B #108 独占窗放行时点／J-C＝R80 §J-1 同题，已第二次带实测催办）；R82 §H 三项（J-D 快照复核刀随车作废口径＝我侧已裁、请追认／J-E 号域真源＝刀/证件面∪文档面＝我侧已裁、请追认／J-F＝J-A 同题）。R83 §G 三项（J-G 常驻登记闸的尺子重立与「上一车的刀可不可再动」／J-H 交付件指针不再逐车追改＝本行为最后一轮点名，此后各收口件的判断栏项以台账最近一条收口行为准／J-I 裸 CR 与登记面限定要不要升为常驻机检＝属放行类、在我侧裁权外）；未裁项我侧按各行「可判解禁条件」继续推进，⛔ 停等作者点头；本轮唯一作者级停等仍是上面那扇 #108 窗。

---

（本件不写自己的 md5／行数——§F3 证据卫生；一切数字请对着 §0~§6 各行的出处路径现算复现。）
