# SPR40 编程侧值守 R42｜R14 §B/§C 由并发窗落地（本窗双实现逐字节收敛复验）＋ M2'/M3 已落但 `EXPECT_FROZEN` 残件坐实

性质：**只读复验＋申报**。本窗对 `scripts/*.gd`、`production/sprint-39/SPR39_对照表.json`、链件、判据件、`SPR21-FROZEN.md5` **零写盘**（自证见 §A-3）；⛔ commit／push、⛔ 自刷冻结、⛔ 起第二条链。
编号声明：与 `S38-R42` 无涉；上游＝`S40-R14`（现读 150 行）、`S40-R13`（141 行）、`S40-R12`（58 行）、`S40-R11`（187 行）。
本窗全部数字为 **11:02–11:17 现场实读**，收工快照时刻逐节标注（盘在此期间被另一窗写了三次：11:07:03／约 11:15／11:16:49 起链）。

---

## §0 现场时间线（两侧现读，非推演）

| 时刻 | 事实 | 谁 |
|---|---|---|
| 10:26:05 | run.sh `337f9f98→e14c0987`（R12 §3 原地版） | 本窗（上轮） |
| 10:40:14 | `data.gd 5f8f832f→45e7da88`（R12 §5 十行 tips） | 本窗（上轮） |
| 10:51:27 | `spr38_knife.sh 4d9ff4e3(51)→92ade129(57)`（R11 §D 刀族 23 把子步） | 本窗（上轮） |
| 10:51:49–11:01 | `STEP=knife` 链：十刀全 BIT＋`KNIFE 刀族23把 ok`，在 `:144` 4a 截断 | 本窗（上轮） |
| **11:07:03** | `data.gd 45e7da88→50989837`＋`对照表.json d896e3f8→89e5f3ed`（**R14 §B/§C**） | **另一窗**（备份 `_backup/spr40_s17_r14sync/20261119-110703/`，manifest 自报 `data_sites=2 table_sites=9 expect_failures=8`） |
| 11:07:16–11:11 | 另一窗 `STEP=gates`（锁 `owner=pid-23314`） | 另一窗 |
| 11:1x | `spr38_knife.sh 92ade129→283cdd51`（**M2'**：`:25/:26/:29` 正名 `KNIVES_ARG`＋`:57` 带 `exit 2`） | 另一窗 |
| 11:15:38 | M3 备份 `_backup/spr40_s19_m3register/20261119-111538/`，manifest 宣布 `player_after=4d438e3f` | 另一窗 |
| 11:16:49 | 另一窗起 `STEP=all` 全量链（锁 `owner=pid-24606`，本窗收工时仍在跑） | 另一窗 |

本窗 11:05:26 已按让路规则③写 `_tools/.s40_watchdog.stamp`（`step=s16-r14-merge`）声明写盘意图 ⇒ 11:07:03 那笔写与本窗意图重叠。**后果＝零**（两窗目标字节完全相同，见 §B），但形状是危险的，登记于 §G-1。

---

## §A 本窗动作

1. **R14 §G-1 前置闸（11:02 实读，全过）**：`data.gd=45e7da88…`／580 行、`对照表.json=d896e3f8…`、FLAVOR 键行 **74**、无锁。
2. **施工件 `_tools/spr40_s16_r14_merge_landing.py` 写好但未落盘**：`--apply` 缺省（仅内存构造），首跑即 `R14-RED 基线 md5 不符 scripts/data.gd 现=50989837… 期望=45e7da88…` ⇒ 并发窗已抢先落完，**幂等拒绝生效**。该件自此作废（同 `spr40_s10_orphan_comment_landing.py` 命运），⛔ 再拿它跑 `--apply`。
3. **零写盘自证**：全盘 `ls _tools/*.r14tmp scripts/*.r14tmp` ＝ 无残留；本窗写过的只有 `_tools/spr40_b/` 三份证据（`s16_contract_before_audit.txt`／`s16_contract_after_r14_audit.txt`／`s16_fp_before_audit.txt`／`s16_churn_audit.txt`）＋`_tools/spr40_b/s16_after_churn_audit/`（日志副本集）＋本件。件名均含 `audit`／`verify` ⇒ 合 AGENTS §7 `CHAIN_EXCLUDE`。

---

## §B R14 §B/§C 的独立复验：**双实现逐字节收敛**（本轮主证据）

手法＝拿**并发窗自己的改前备份**（`45e7da88`／`d896e3f8`，已核 md5），用**本窗独立录入**的 R14 §B/§C 逐字串在内存重放，再与盘上现字节 `cmp`。件＝`_tools/spr40_b/s16_concurrent_replay_verify.py`（只读，⛔ 写盘）。实测（11:13）：

```
备份 data=45e7da881112f92353430653b96713b8 表=d896e3f87570c1005ca44e2d03771a53
盘上 data=5098983723e6741009d087051886c3d9 表=89e5f3ed0865427b90699b9e47a20d34
重放 data 改动行=2 与盘上逐字节相等=True
重放 表 命中键=10 实际改动=9 与盘上逐字节相等=True
非 text 字段被改=无
text 实际改动键=9（pressure 表侧 0 改动 ✔ 合 §C-2「只有盘上要动」）
行数 data 580->580 / 表 1357->1357（净增行 0 ✔）
REPLAY-VERIFY MATCH
```

⇒ 结论不是「两边都绿所以大概没错」，而是**两份互不知情的实现对同一 12＋10 个字节落点收敛到同一 md5**。这条同时坐实：`prev_text`／`anchors`／`must_contain`／`reserved_phrases`／`forbidden_substrings`／键序／`meta`／`mechanism_votes` **一字未动**（R14 §B 落点纪律达成）。

## §C R14 §G-4／§G-5 后置闸（本窗亲跑）

| 判据 | 实测 | 对账 |
|---|---|---|
| `SPR39_flavor_contract.py` 改前 | **20 红**（G-3×13／G-4×3／G-5×4）rc=1 | == R14 §F「现状」== R41 形状 B ✅ |
| 同件改后（11:12） | **8 红**（G-3×3／G-4×3／G-5×2）rc=1 | 逐条 == R14 §F 残余清单：`prism_warden`/`silent`/`s_frostveil` 三条 G-3、禁用串 `光缝`/`多看小地图`/`砸它的核` 三条 G-4、`prism_warden(碎片变色)`/`silent(小地图)` 两条 G-5 ✅ **本批制造 0 条** |
| `--selftest` | `SELFTEST OK: 3/3 把刀都变红`（K1 failures=10／K2 12／K3 7） | 门不是假闸 ✅ |
| FLAVOR 语汇回归 | 段内 `弹`=**0**／`炮`=**0**／`弹匣留一半`=**0**；键行 74；文件 580 行 | R14 §G-5 ✅ |

## §D 门禁面（**另一窗 11:07:16 `STEP=gates` 的产物**，本窗只读复算，不是本窗跑的）

- `spr38_g_chk_fp` rc=0 `VERDICT=ALL_MATCH hit=1 expect=1` ⇒ **E1 漂移问**（三档逐字 == `SPR32_验证口径.md` §5.4 各自那行，`_tools/spr38_fp_vs_5_4.py` 机检）✅
- 三档指纹互不相同：`distinct=3` ⇒ **E1 种子生效问** ✅（两问两答齐）
- 本轮 10 份新烟测日志（`spr38_g_{base,melee,stance,apply,rng,sc,pw,fp12345,fp777,fp42}.log`，mtime ≥11:07）合并计数：`[ERR]`=**0**、`ok=false`=**0**、`SCRIPT ERROR`=**0**
- 探针落地：`done checked=94 declared=94`／`19/19`／`7/7` 三面对齐；`VH10 ok`；`文档 §三 加总=94；日志普查=94；探针 declared=94`；`chk_verbatim VERBATIM_MATCH 27/27`；`chk_quota IN_SYNC`；`chk_taut 可疑=0 非豁免=0 STALE=0`
- 链定性：`STEP=gates` 无 `RUN-GREEN`（本窗在 `_tools/spr38_run.gates.log` 内 `grep -a -c "RUN-"` = **0**，终端行未落该件；链尾在 `:144` 4a 截断，因当时冻结 33/34）⇒ 牙口六臂与文档面承载件 mtime 仍是 **10:24**（未跑到），本窗 ⛔ 拿旧件当本轮证据。

## §E 冻结面：本窗两次如实读（⛔ 自刷）

- 11:12（R14 §C 后、M3 前）：`33 OK / 1 FAILED`，FAILED 行＝`scripts/data.gd`
- 11:16:56（另一窗 M3 重登后）：**`34 OK / 0 FAILED`**；清单 md5 `11b8eb7e→dbbea4228fc7f3c2508f1a6461d15e95`，其中 `:9 data.gd=50989837…`、`:22 player.gd=4d438e3f…`
- ⚠️ AGENTS §2 钉「**转录须作者逐项放行**」，本窗未见该项放行 ⇒ 列 §I 待追认（不回退，回退才是更大的破坏）。

## §F M2'／M3 落地核对＋**一处残件**（下一窗必处理）

- **M2' 已完**：`knife.sh=283cdd51…`／57 行；`:25/:26/:29` 三处 `KNIVES_ARG`（`KNUVES` 零残留）；`:57` `[ "$fail" -eq 0 ] && echo "ALL KNIVES BIT" || { echo "SOME KNIFE DID NOT BITE CLEANLY"; exit 2; }` == R12 §2 逐字件。
- **M3 的 label 已完且逐字合 R13 §C-3**：`player.gd=4d438e3f…`，`:2009` 现读＝`Dev.check(Data.FLAVOR.size() == 74, "flavor", "手记 74 条（全六类覆盖：29 敌+12 遗+8 词+8 题+7 Boss+10 圣所+10 tips 逐字件 S40-R12）")`；与 R13 件内目标串 `count==1` ＋ 整行 `==` ⇒ **半角 `+` 作准**，R41 §29 登记的 `＋`/`+` 分歧就此结案（R12 全角版作废）。`.bak` 已晋升为 `4d438e3f…`（与 `player.gd` 互等）。
- 🔴 **M3 残件（本窗坐实）**：`_tools/spr38_evidence_verify.py` 只更新了 `:114 EXPECT_MD5 = "4d438e3f…"`，**`:117 EXPECT_FROZEN` 仍是 `(24, 10)`**，而盘上实算 `34/0` ⇒ `:727-728` 判据必红（「冻结现算 34/0（缺 0）!= 文档声称 24/10」）。R11 §G-M3 原文要求「`:114`／`:117` 两处期望值**同窗**更新」⇒ 该窗只落一处。正在跑的 `STEP=all` 链的文档面会把它打出来，⛔ 下轮把它归因成「新缺陷」。
- 另两处过期锚（不阻塞链，属施工件卫生）：`spr40_s4_register_round.py:41 NEW_GREEN="5835d2e6…"`／`:42 OLD_GREEN="dc622351…"`（锚的是**上一代**绿件，⛔ 重跑该件）、`:63 SA_BASELINE_MD5="0d3ecd07…"` vs 判据件现值 `dbbc3d5e…`。

## §G churn 与三条纪律观察

1. **churn ＝ `UNEXECUTED`（本批不可归因），⛔ 记 PASS**。原因实测：改前那轮烟测日志（10:43–10:44）已被 11:09 的 gates 就地覆盖，`find _tools _backup -name 'spr38_g_*.log' -newermt 10:40 ! -newermt 11:05` ＝ **0 命中**，无留存；唯一在盘基线 `_tools/spr40_base/`（11-18 18:53）期间夹着武器改名族等批次 ⇒ 拿它当 BASE 跑出的逐面漂移（118–153 行/面）不可归因到 R14 §C。件＝`_tools/spr40_b/s16_churn_audit.txt`。
   其中**唯一有效的一条**：`FP-12345／777／42 三条指纹行改前后逐字节相同（175/206/213 字节）`——跨 11-18→11-19 多批次地图面零漂移。
   🔴 纪律回写（给下一窗）：**跑 gates 前先把 `_tools/spr38_g_*.log` 整集快照成 BASE**，否则每轮 gates 都在销毁自己下一轮的对照件。
2. **写盘先于抢锁**（另一窗 11:07:03 写 `.gd`，11:07:16 才建 `.spr38_run.lock`）：本次同字节收敛所以无害，文本若不同即静默覆盖。建议口径：`让路规则③` 的判定应在**写 `.gd` 之前**完成，而非起链之前。
3. **R14 §0 第 9 行的事实偏差**（登记防照抄）：它断言「`knife.sh=92ade129…`／57 行 ⇒ **M2' 已在另一窗落地**、R12 §2 退出码行 `:57` 实读到」。本窗 11:07 对同一 md5 现读 `:57` 是 `[ "$fail" -eq 0 ] && echo … || echo "SOME KNIFE DID NOT BITE CLEANLY"`（**无 `exit 2`**），`KNUVES` 三处未正名 ⇒ 那个时刻 M2' 未落。M2' 真正落地在 11:1x（`283cdd51…`）。⛔ 下轮拿 R14 §0 的 knife 状态当现值。

## §H 未做（如实）

- ⛔ 落 R14 §B/§C（并发窗已落，本窗改为其复验方；重复落盘只会撞 md5 门）
- ⛔ 起 gates／全量链（11:16:49 起 `STEP=all` 在跑，让路规则①）
- ⛔ 动 `EXPECT_FROZEN`／`SA_BASELINE_MD5`／`.bak`／冻结清单（判据件与登记面非本窗职责，且链在跑）
- `UNEXECUTED`：本批 churn（§G-1）、R6 §F 53 项复算、`spr40_s4_*` 的 `--dry` 幂等检查（链占用 `_tools/` mtime，跑它污染 `latest_chain()` 选件）
- tips 的「③可见效果断言」（登记三件套第三件）仍**无**：`FLAVOR` 值改动没有任何探针断言其内容，只有离线门 `SPR39_flavor_contract.py` 在看它，而该门按 R14 §E **不在链上** ⇒ 这条暴露面本窗不自行补（补断言＝改判据面），交主理人定位。

## §I 待作者放行项（⛔ 问作者，仅登记）

1. **M3 的 `SPR21-FROZEN.md5` 重登追认**：`:9`/`:22` 两行新值由另一窗 11:16 自行写入并令冻结面 34/0，AGENTS §2 要求该项「转录须作者逐项放行」。
2. 若作者不追认，回滚件在 `_backup/spr40_s19_m3register/20261119-111538/`（`SPR21-FROZEN.md5` 旧件 md5 `11b8eb7e…`）。

## 下一个动作（一条具体指令）

等 `owner=pid-24606 step=all` 这条链释放锁后，下一窗跑：
`python _tools/spr38_fp_vs_5_4.py` 复核 ＋ 读 `RUN-*` 终端行确认文档面把 `spr38_evidence_verify.py:117 EXPECT_FROZEN=(24,10)` 打成红，随后**只在**主理人 ticket 授权下把 `:117` 改为 `(34, 0)`（同行原地替换、⛔ 增删行）＋同窗把本轮 gates 前的 `_tools/spr38_g_*.log` 整集存成 `_tools/spr40_base_r14/` 作 churn 基线；改完跑 `STEP=all` 一次，验收判据＝`RUN-GREEN step=all`（或批准红逐条 == 清单）＋冻结如实报数。

---

## §J 同轮追加实测｜M2'/M3 新件的语法闸 ＋ 「绝对路径一律回 127」这条纪律的**成立条件**（11:19–11:21）

先给结论：并发窗落完 M2'／M3 后**没人语法验过**。本窗补验（零 Godot、零写产品盘，篡改副本只落系统临时目录并已 `rm -rf`）：

```
bash -n _tools/spr38_knife.sh（283cdd51…/57 行） rc=0   ← 正对照
bash -n _tools/spr38_run.sh  （e14c0987…/250 行） rc=0   ← 正对照
临时目录内追加 `if [ x = x ]; then`（断句）      rc=2   ← 反对照被抓（门有牙）
临时目录内指向不存在的件                          rc=127  ← 不可达，不算语法过
```

⇒ **M2'／M3 之后的两份链件语法全绿**，且反对照证明 `bash -n` 这道门本环境有效。

纪律精确化（⛔ 删原文，本段为限定成立条件的追加）：原口径「`bash -n` 只认相对路径＋cwd，**绝对路径一律回 127**」在**施工件里成立、作为 `bash -n` 的性质不成立**。实测八格（同目录 cwd＝`D:\Create\Game\test-1`）：

| 调用方式 | 路径形态 | rc |
|---|---|---|
| `subprocess(['bash','-n',X])`（shell=False） | `_tools/spr38_knife.sh` | **0** |
| 同上 | `D:/…`／`D:\…`／`/d/…`／`/cygdrive/d/…` | **全 127**（stderr＝`/bin/bash: …: No such file or directory`；`D:\…` 还会被吞成 `D:CreateGametest-1_toolsspr38_knife.sh`） |
| `subprocess('bash -n "X"', shell=True)` | `D:/…`／`D:\…`／`/c/…hosts` | **0** |
| Bash 工具里交互执行 | 四种形态全试 | **0** |

⇒ 真正的判据是「**那个 bash 自己的挂载命名空间里能不能解析这个串**」，与「绝对／相对」无因果，与 `shell=` 强相关。三条可执行口径：①施工件一律 **相对路径＋显式 `cwd=ROOT`**（本窗 `spr40_s14/s16` 就是这么写的，行为正确）；②`rc=127` 一律读成**探针不可达 ⇒ 换形态重跑**，⛔ 当语法过、也⛔ 当语法错；③`rc=2` 才是真语法错。建议 M4 文档面登记时按本表口径写，⛔ 再留「绝对路径必 127」这种会被一次交互实测证伪的句子。

---

## §K 🔴 P0（11:22 实测，本窗最重发现）｜M3 的 label 补丁吃掉了 `player.gd:2009` 的行首 tab ⇒ 新绿基线**编译不过**，正在跑的 `STEP=all` 十刀全在死构建上

> **【11:35 追加式订正】** 本节写于坏档在盘期间，其中「等 §K-4 四处同窗修复」这步**不是由 §K-4 的形状完成的**：另一窗 11:28:14 整站回滚、11:30:33 带 tab 重落，终态与逐字节因果证明见 §L。§K 保留原文当过程证据，⛔ 拿 §K-4 当待办。

### K-1 实测（三行 repr 就够，⛔ 推断）

```
old(5835d2e6)  :2009 前 12 字符 = '\tDev.check(D'
bak(4d438e3f)  :2009 前 12 字符 = 'Dev.check(Da'      ← 顶格
disk(现读)      :2009 前 12 字符 = 'Dev.check(Da'      ← 与 .bak 同
:2007 = \tDev.check(note_shown, "flavor", "图鉴…")     ← 同类邻居，一个 tab
:2008 = \t# --- Sprint 20 …
:2010 = \tDev.check(not (Data.FLAVOR_BROADCAST_KINDS as Array).has("enemies"), …)  ← 一个 tab
```

⇒ `:2009` 落在函数体中间却降阶到第 0 列＝GDScript 解析错。**M3 相对旧绿基线只有两处差异：label 文案（应改，与 R13 §C-3 逐字等）＋行首那个 tab（不该改）**——后者把整份 `player.gd` 改到不能编译；且它同时被 `cp` 进了 `_tools/spr38_good_player.bak`（绿基线）并登记进 `SPR21-FROZEN.md5:22`（`4d438e3f…`）⇒ **三份面一起带病**，preflight 与 4a 表体都查不出来（它们只比 md5 字节相等，编译错天生不在其视野内）。

### K-2 后果实测（本轮链，锁 `owner=pid-24606 step=all` 起跑 11:16:49）

```
_tools/spr38_run.knife.log 里 10 把刀全部 script_err=251（上一轮 11:01 同件是 script_err=0 ×10）
分类去重：190× Parse Error: Could not resolve class "Player", because of a parser error.
            2× Cannot infer the type of "s_swings" variable …
            2× Cannot infer the type of "s_draws" variable …
            1× Could not resolve script "res://scripts/player.gd".
            1× Could not preload resource script "res://scripts/player.gd".
            1× Could not parse global class "Player" from "res://scripts/player.gd".
```

- 按 V-H #8：`script_err != 0` ⇒ 判定串里的 `BIT` 来自**死构建**，`ok_false>0` 不算证据；刀件已把 `fail=1`，**M2' 刚落地的 `:57 exit 2` 第一次上岗就抓到了真东西**（这条是正面收获）。
- ⚠️ 因果口径要诚实：`grep -a -c 2009 _tools/spr38_k1.log` ＝ **0**，Godot 在这批行里没有把解析错定位到 `:2009`。所以「降阶→这批 Parse Error」是**强推断**（缩进缺陷与编译失败各自独立实测、时间上同窗出现，且 `s_swings/s_draws` 类型推断失败正指向 `_swing()` 所在类解析崩了），⛔ 当已隔离因果写进核验。**证伪式验收＝补回那个 tab 后 `script_err` 必回 0**；若仍非 0 则 K-1 另有因，须重新归因。

### K-3 本窗处置（受让路规则约束）

链在跑 ⇒ ⛔ 编辑 `scripts/*.gd`（正被 Godot 读）、⛔ 动 `.bak`、⛔ 动 `SPR21-FROZEN.md5`、⛔ 起第二条链、⛔ 起 Godot 复现。本窗只做：实测落盘（本节）＋派主理人出 P0 ticket。

### K-4 修复形状（等 ticket，⛔ 编程侧自行动手）

一行三处同窗，顺序不可换：①`scripts/player.gd:2009` 行首补回 **一个 tab**（原地改现存行，⛔ 增删行；除这一个字符外逐字不动，label 文案本身经 §F 核过与 R13 §C-3 全等）→ ②`cp scripts/player.gd _tools/spr38_good_player.bak`（新绿基线串由落盘窗现算，⛔ 抄本件）→ ③`SPR21-FROZEN.md5:22` 那一行换成新 md5（**登记面重登＝AGENTS §2 须作者逐项放行**，列 §I 第 3 项）→ ④`spr38_evidence_verify.py:114 EXPECT_MD5` 同步成新串 → ⑤顺手补 §F 那处 `:117 EXPECT_FROZEN` → ⑥跑 `STEP=all`，验收＝十刀 `script_err=0` ＋ `RUN-GREEN`（或批准红逐条等集）。
回滚件已在盘：`_backup/spr40_s19_m3register/20261119-111538/`（旧 `player.gd=5835d2e6`、旧 `.bak`、旧清单 `11b8eb7e`）。




## §L 🔴 P0 全案（11:26–11:35 实测）｜M3 第一次晋升的 `4d438e3f` 是**编译不过的档**：只差一个行首 tab；11:28:14 整站回滚 → 11:30:33 带 tab 重落 → **R15（11:28:01）整份抬头基线作废**

### L-1 时序（每行都有盘上现读依据，⛔ 转抄）

| 时刻 | 事实 | 依据 |
|---|---|---|
| 11:16:13 | M3 第一次晋升：`player.gd`＝`.bak`＝`4d438e3f…`，清单 `dbbea422`（`:22` 同步），`md5sum -c` **34 OK／0 FAILED** | 本窗 11:16:56／11:17:22 实读（已写进本件 §F-3、§结论 4） |
| 11:16:53–11:20:27 | 那一轮 gates 的 **10 份证据日志**每份都含 `190× Could not resolve class "Player"` ＋ `250× Parse Error`，且**一条 `[SMOKE] validate problems=` 都没打出来** | 本窗 11:3x 逐份 `grep -a -c`（11 份里唯一干净的是昨天 21:47 的 `g_melee_pre_oraclefix.log`） |
| 11:26:35 | knife 步：十刀全 `\| GREEN-FAIL(判据无牙)+DEAD-BUILD(okfalse 不可信)+PROBE-INCOMPLETE(跑不够帧，加 QA) \| ok_false=0 script_err=251 \|`；`KNIVES VERDICT=HAS_GAP ok=0 阴性=1 INCOMPLETE=23`；尾行 `KNIFE-RED 刀族23把 rc=1 判定串命中=0` ⇒ **M2' 的 `:57 exit 2` 与 M1'③ 子步骤各自第一次上岗就各抓／各报了一次真红**，链在 knife 步断 | `_tools/spr38_run.knife.log`（31 行）＋ `_tools/spr38_knives23.log` 末行 |
| 11:28:14 | **四件同刻整站回滚**（`player.gd`→`5835d2e6`、`.bak`→`5835d2e6`、清单→`11b8eb7e`、EV→11-18 版）：三件 ctime 同秒，mtime 是 `cp -a` 保来的旧值 | `stat -c %z` ＋ `md5sum` 四件 |
| 11:28:01 | **R15 出具**（比回滚早 13 秒），其 §0 基线总线记的正是坏档态 | R15 文件 mtime ＋ `SPR40_主理人裁定_R15_…:14-19` |
| 11:30:33 | M3 **带 tab 重新落地**：`player.gd`＝`.bak`＝`037f261d…`；清单 `ace857f1…`、实算 **34 OK／0 FAILED**；EV `:114=037f261d`、**:117=(34, 0)**（本件 §F-4 那处残件已被并列做掉）；`selfaudit:28 GOOD_MD5="037f261d…"`（件 `6bee0d96…`）；归档件 `spr38_good_player.037f261d.bak` ＋ `_tools/spr40_good_player_archives/` 同名各在；DELIVERY EOF 追加行含 `037f261d` | 本窗 11:3x 逐件实读 |
| 11:33:00 | 另一窗起重跑独占链（`g_base.log` 11:34:10 落地）；本窗按让路规则转只读，**未起第二条链、未起 Godot、未碰 `scripts/`** | `_tools/.spr38_run.lock`（48 B，11:33） |

### L-2 因果：逐字节重构把它钉死（坏档盘上已无留存，⛔ 只靠推断）

坏档 `4d438e3f` 被「回滚→重落」两次覆盖，`_backup/spr40_s19_m3register/` 三份快照存的都是好档 ⇒ 取不到原件。改做**重构对照**：以 11:16:17 旧好档（`5835d2e6`，LF，2649 段）为底，只把 `:2009` 换成 M3 的 label 文案，分「带行首 tab／不带」两版：

```
旧档 + 新文案 + 带 tab  →  md5 = 037f261d1b2d  == 现盘 player.gd / .bak        ✅ 命中
旧档 + 新文案 + 去 tab  →  md5 = 4d438e3f363c  == 11:16 坏档（本窗当时实录）  ✅ 命中
```

⇒ **两版唯一差异就是那一个 tab**，「坏档＝少一个 tab」由哈希闭合证明，不是猜。再把两版各剥掉 `class_name`（消「Class Player hides a global script class」噪声）跑只读 `--check-only`：

```
去 tab 版  : 1× SCRIPT ERROR: Parse Error: Unexpected identifier "Dev" in class body.
带 tab 版  : 0× Parse Error
```

另附同形最小平复现（同一引擎、六行件）：函数体内「缩进行 → 顶格行 → 缩进行」必报 Parse Error，正确缩进版零报。临时件跑完即删，盘上无残留。

### L-3 🔴 系统性洞（本件最该被引用的一条）

**三条常驻判据全部对「编译不过的晋升」失明**：`md5(player.gd)==md5(.bak)`（R15 §D-2 恒等式）、`md5sum -c` 34 OK、EV `EXPECT_MD5` 比对——**它们只验字节一致，不验这堆字节能不能跑**。11:16 那次是「三份面自洽的坏档」，所以 11:16:56 本窗自己也被骗过（§F-3 当时写下「冻结面 34 OK／0 FAILED ✅」）。本轮唯一抓到它的是**刀面的 `DEAD-BUILD(script_err≠0)`／`ok_false==0` 与 gates 日志里的 `Could not resolve class` 级联**——即：抓编译的能力目前只存在于链的第 3／5 步，不在晋升动作的当口。⇒ 已列「请主理人裁一道晋升前机检」（建议形状：`--check-only` 因 autoload 会恒报 `Identifier not found: Assets`，不宜直接当闸；可行的是**跑一次 base 探针后断言 `Could not resolve class`＝0 且 `[SMOKE] validate problems=0` 在场，才允许 `cp` 晋升**）。

### L-4 R15 抬头失效（须 R16 追加式订正，⛔ 回改 R15 原文）

R15 出具于 11:28:01，早于回滚 13 秒，其 §0／§A／§D-3 全线锚在坏档上：

| R15 条目 | R15 写的值（＝坏档态） | 盘上现值（11:3x） | 若照字面执行的后果 |
|---|---|---|---|
| §0 行 1–2 | `player.gd`／`.bak` ＝ `4d438e3f…` | `037f261d…` | 第 0 步进场闸当场红（好事） |
| §0 行 4 | 清单 `dbbea422…` | `ace857f1…` | 同上 |
| §A-3 | 授权 `GOOD_MD5 → "4d438e3f…"` | 已是 `"037f261d…"` | 🔴 **把编译不过的串写进判据件**（现值恰好没错，是因为另一窗没照 R15 抄） |
| §B-2 | `EXPECT_FROZEN → (34, 0)` | 已＝`(34, 0)` | 无风险，已完成 |
| §D-3 | 补归档 `spr38_good_player.4d438e3f.bak` | 盘上是 `…037f261d.bak` | 🔴 补出一份**坏档归档**，归档闸要的那份反倒没命名依据 |
| §A-5 | 两份文档追加行含 `4d438e3f…` | DELIVERY 追加行含 `037f261d…` | 文档面会把坏串当现役声称 |

⇒ 结论：**R15 的裁定逻辑（谁授权、改哪行、为什么）全部有效，但其中每一个 `4d438e3f` 字面量都要顶替成 `037f261d`**；`AUTORUN` 那份文档我没找到（`find production -name "AUTORUN*"` 零命中），其现役路径待 R16 指认。

### L-5 本窗两处探针错（自报，别当证据引用）

1. `grep -an "EXPECT_MD5="`（等号无空格）在 EV 上零命中，让我一度判「EV 一分钟内又被改写」——**是探针模式错，不是盘在动**；正确写法 `grep -an "^EXPECT_MD5 = "`。
2. 第一次对真档跑 `--check-only` 得 0 Parse Error，差点否掉缩进假说——**那次跑在 11:28:14 回滚之后**，测的已是好档。教训：**并发窗在写时，每个探针必须与一份同时刻 md5 绑定**，否则证据与结论会错位（本节每条都补了 md5）。

### L-6 现状与未决

- 11:33 起跑的链**结果未读**（本窗只等它的日志，⛔ 插队）。它若绿，M3 终态＝`037f261d`，L-4 那张表就成了「已被另一窗绕开的废纸」；它若红，红在哪个臂决定下一手。
- 仍挂：M1'④（`run.sh:185` 串顶替）、`SPR39_flavor_contract.py:83` 的 `74 tips` 旧锚、R15 §E-3 刀族标签（挂 M4）、EV `:112-113` 注释脱节（挂 M4）、本件 §G-3 三条并发纪律。
- 冻结面现值 `ace857f1…`／34 OK／0 FAILED ——**这一次额外做了 L-2 的编译面自证**，「34 OK」与「能编译」是两条独立证据，⛔ 互相代称。

---

## 结论区（六行版）

1. 🔴 **M3 第一次晋升（11:16:13）落的是编译不过的档**：label 补丁在 `player.gd:2009` 吃掉了行首 tab，同刻被 `.bak` 与 `SPR21-FROZEN.md5:22` 一起认下 ⇒ 「34 OK／0 FAILED」是**坏档的自洽**。11:26:35 由刀面 `DEAD-BUILD` 抓到，11:28:14 整站回滚，11:30:33 带 tab 重落成 `037f261d…`。**因果已由逐字节重构＋`--check-only` A/B 钉死（§L-2），不是推断**；R15（11:28:01）整份抬头基线随之作废（§L-4）。
2. **R14 §B/§C 已全量落地并经双实现逐字节收敛复验**：`data.gd→50989837…`（2 行）、`对照表.json→89e5f3ed…`（9 处 text，`pressure` 表侧零改动），净增行 0、非 text 字段一字未动。
3. **离线门从 20 红降到 8 红且 8 条全是 S39 遗留面**（本批制造 0 条），`--selftest` 3/3 变红证明门活着；语汇 `弹/炮/弹匣留一半` 在 FLAVOR 段归零。
4. **M1'／M1.5'／M2'／M3 四站至此全部落地**（M3 的注册三件齐：文件＋`.bak`＋`:114`＋清单 `:22`，冻结面 `11b8eb7e→dbbea422`、实算 **34 OK / 0 FAILED**）——⚠️ **其中 M3 是带病落地**（结论 1），另有**一处漏做**：`spr38_evidence_verify.py:117 EXPECT_FROZEN` 仍 `(24,10)`，与 `:114` 不同窗，将在跑着的 `STEP=all` 文档面见红。
5. **本窗零写产品盘**；churn 因改前日志被并发 gates 覆盖而 `UNEXECUTED`，已把「跑 gates 前先快照 BASE」写成纪律回写。
6. **M2'／M3 之后的两份链件语法全绿**（`bash -n` 正对照 rc=0＋断句反对照 rc=2 被抓），且「绝对路径一律回 127」这条老纪律已按八格实测**限定成立条件**：它是 `shell=False` 下 bash 命名空间解析问题，⛔ 当 `bash -n` 的性质写进 M4 文档面。⚠️ 本窗自纠：曾据「`34 OK / 0 FAILED`」判 M3 注册干净——**冻结清单只比 md5 字节，编译错它天生看不见**；验注册必须叠一条「真起 Godot 且 `script_err=0`」的判据（§K-3）。
