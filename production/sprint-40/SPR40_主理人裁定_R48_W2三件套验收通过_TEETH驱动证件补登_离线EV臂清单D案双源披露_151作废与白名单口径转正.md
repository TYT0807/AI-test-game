# SPR40 主理人裁定 R48｜W2 三件套验收通过（含一处证件缺口单列）＋离线 EV「臂数=0」恒红采 D 案（终端摘录双源披露，附逐字施工文本）＋「151」作废成立且后续 churn 一律引白名单口径

性质：**裁定＋逐字生效文本交付件**。本窗 ⛔ 改任何既有文件、⛔ 动 `.gd`／链件／判据件／冻结表、⛔ 跑 Godot、⛔ 起链、⛔ commit/push。只新建本件。
编号声明：占用空闲号 **R48**【盘上现读 13:1x：`ls production/sprint-40/ | grep -oE "_R[0-9]+_" | sort -u` ＝ R1–R21、R36–R47；R22–R35 空缺但**不用**——按值守/裁定序延续占 R48；`grep -rn "_R48_" production/` ＝ 零命中】。⛔ 撞 R47/R45（R46 §A 的猜号学费不重交）。
本窗取证全程只读（`md5sum -b`／`wc -l`／`grep -n`／`diff`／`sed -n`／小段 python 只读内存复算），未启动 Godot、未起链、未动锁。起手现读 `_tools/.spr38_run.lock` ＝ 无此文件 ⇒ **锁 FREE**，故本窗所有离线复算可直接跑（W-2 前置满足）。
指针口径：按 R45 §C-2 转正的通用条款，本件凡引「件:行号」**同行附可复现命令、落盘前全部实跑一次**（见 §0 与正文括注）。引句优先于行号。

---

## §0 基线总线【本窗 13:1x–13:2x 逐笔现读；⛔ 转抄 R47 的字——下表每一格都是本窗自己跑的，非"引自 R47 待复算"】

| # | 件 | 现读值 | 复现命令（本窗实跑） |
|---|---|---|---|
| 1 | `_tools/spr40_churn.sh` | md5 `-b` = `05c36e496c0b5fedde314be834f47fd6`；**58 行** | `md5sum -b _tools/spr40_churn.sh; wc -l _tools/spr40_churn.sh` |
| 2 | `_tools/spr40_churn_teeth_verify.sh` | md5 `-b` = `f5512e304090b63b1fb47f3514a09309`；112 行 | `md5sum -b _tools/spr40_churn_teeth_verify.sh; wc -l <同上>` |
| 3 | `_tools/AUTORUN_值守报告.md` | md5 `-b` = `d288bd447f00aa0843a7174344d8a7a1`；**341 行**；末行＝R45 §B-2 第二句逐字 | `md5sum -b …; tail -1 _tools/AUTORUN_值守报告.md` |
| 4 | `production/sprint-38/SPR38_交付_B1_非弹幕近战内核.md` | md5 `-b` = `d9e65dcc0c4b9080176e81e0d03742cb`；**257 行**；末行＝R45 §B-2 第一句逐字 | 同上式 |
| 5 | `scripts/player.gd` | `037f261d1b2d393fa02aba6a0bed1654`（绿基线，未动） | `md5sum -b scripts/player.gd` |
| 6 | `production/sprint-21/SPR21-FROZEN.md5` | `ace857f17d0a54002b66a3ee28fe255b`；`md5sum -c` 于仓根＝**ok=34 failed=0** | `cd test-1 && md5sum -c production/sprint-21/SPR21-FROZEN.md5 2>&1 \| awk '{if($NF=="OK")o++;else if($0~/FAILED/)b++}END{print o, b+0}'` |
| 7 | `_tools/spr38_run.sh` | `4130e4aed2338bf020e7e86389d59cfc`；288 行（W1 代，本窗未动） | `md5sum -b _tools/spr38_run.sh; wc -l <同>` |
| 8 | `_tools/spr38_evidence_verify.py` | `d4c2b3533d36bee2bd4e84e4fd7a3c3a`；897 行 | `md5sum -b …; wc -l <同>` |
| 9 | `_tools/spr38_run.all.terminal.txt` | md5 `-b` = `888f898dfdbe4b79e0504e9674dd9fb5`；**2 行**；含 `＋6 件牙口＋` 字样、含牙口打点行数＝**0** | `md5sum -b …; grep -ac "RUN 牙口" _tools/spr38_run.all.terminal.txt`（返回 0，即证呈请机制） |
| 10 | `_tools/spr38_run.all.runlog-2026-11-19T124528.log` | 含 `^RUN 牙口 \S+ ok \|` 打点行＝**6**（位于 :12–:17）；mtime 12:59:42 | `grep -anE '^RUN 牙口 \S+ ok \|' _tools/spr38_run.all.runlog-2026-11-19T124528.log` |
| 11 | CHK 五件面（两代） | 11:0x 代 `spr40_base/after` 各 **5** 份 chk/clause；12:0x 代 `*_r17` **0** 份 | `ls _tools/spr40_base/ \| grep -cE "chk_\|clause"` ＝5；`ls _tools/spr40_base_r17/ \| grep -cE "chk_\|clause"` ＝0 |
| 12 | 真快照聚合指纹 | `spr40_base_r17`＋`spr40_after_r17` 逐文件 md5 合计＝`0498f19437b06c37df7e1c73499487b2`（与证件所载跑前/跑后一致） | `md5sum _tools/spr40_base_r17/* _tools/spr40_after_r17/* \| md5sum` |
| 13 | selfaudit 站点面复算 | AUTORUN＝**8** 对、B1＝**5** 对，值集均 `{('34','0')}`；`FROZEN_SITES` 现读 `{"AUTORUN_值守报告.md": 8, "SPR38_交付_B1_非弹幕近战内核.md": 5}`（`_tools/spr38_report_selfaudit.py:40`） | 本窗 python 按 `:34` 同款正则现算；锚：`grep -n "^FROZEN_SITES = " _tools/spr38_report_selfaudit.py` |
| 14 | 「151」列合计复算 | `s19_churn_nonjit_only_audit.txt` 十面「剔抖动后漂移」＝ `[3,2,21,16,27,27,16,18,9,12]` 合计 **151** | `grep -oE "剔抖动后漂移=[0-9]+" _tools/spr40_b/s19_churn_nonjit_only_audit.txt`（本窗 python 求和） |
| 15 | `_tools/spr38_logruns/` | 仅一代 `2026-11-19T124528/`，`份数=31`；目录 mtime 12:45:28＝该轮起跑时刻 ⇒ 按 R45 §D-2 读方口径，内容＝**上一代复制** | `ls _tools/spr38_logruns/; ls _tools/spr38_logruns/2026-11-19T124528 \| wc -l` |
| 16 | 改动面铁证（vs `_backup/spr40_w2_churn/`） | 旧块 `:45-52`（12 行）→ 新块 `:45-56`（12 行）；`bash -n` rc=0；判定串行 `CHURN-DONE red=$RED …` 旧 :54 → 新 :58 **一字未动**（两行全文比对相等） | `sed -n '45,56p' _tools/spr40_churn.sh` ⇄ `sed -n '44,54p' _backup/spr40_w2_churn/_tools/spr40_churn.sh`；`bash -n _tools/spr40_churn.sh` |

备份在案：`_backup/spr40_w2_churn/before.md5` 三行现读＝churn `6e8f…`／B1 `ec81…`／AUTORUN `a2d1…`（改前逐字，与本窗 §0-1/3/4 构成改前→改后闭环）。

---

## §A 事项 1 总裁：W2 三件套 **验收通过**（其中一项以「补登证件」为随车尾巴，不影响验收定性）

### A-1 逐项独立复现结论（本窗自跑，不看 R47 自报数）

1. **§A-3 生效文本落地＝逐字节照抄**。本窗把 R45 件里第一个 ```bash 围栏块（`re.search(r"```bash\n(.*?)```")`）取出，与 `spr40_churn.sh` 现读 :44–:56 拼接体逐字比对 ⇒ **完全相等**（python 现算 `equal=True`，13 行含标题 echo 行）。无任何自创。
2. **改动面纪律坐实**：只有 CHK 段整段替换；:44 标题行、:58 判定串行未动（§0-16）；`bash -n` rc=0；缩进 TAB（新块 10 行以 `^I` 开头，空格缩进零命中，`cat -A` 现读）；局部名 `_b`/`_a` 在位（`_tools/spr40_churn.sh:46`，锚：`grep -n '_b="$BASE/$c.txt"; _a="$AFTER/$c.txt"' _tools/spr40_churn.sh`）——避开 :15-32 的 `b`/`a`，R45 §A-3 硬约束兑现。
3. **三态刀语义有牙（就证件面核）**：
   - T1 五件全 `GREEN 逐字节相同` ∧ `CHURN-DONE red=0`（`_tools/spr40_b/s40r45_churn_teeth_T1.txt` 尾部现读）；
   - T2 `CHK spr38_g_chk_taut RED 缺件 base=有 after=无` ∧ `red=1`（锚：`grep -n 'CHK spr38_g_chk_taut RED 缺件 base=有 after=无' _tools/spr40_b/s40r45_churn_teeth_T2.txt` ⇒ :158）；
   - T3 `CHK spr38_g_chk_quota 漂移 ⇒（RED 判定=披露不置红，机检件读数随产品面合法演变）` ∧ `red=0` **等于 T1**（漂而不误红这条**新语义本身**被断言到，证件 :157/:163 现读）。
4. **阴性对照坐实旧假绿**：同一 T2 现场喂改前件 ⇒ 旧打 `CHK spr38_g_chk_taut 漂移 ⇒`＋`red=0`（缺件冒充漂移、且零输入不置红——R45 §A-1(ii) 描述的形状原样复现）；新打 `RED 缺件`＋`red=1`（`s40r45_churn_teeth_negative_control_audit.txt` 全文现读，OLD/NEW 两段逐行对齐）。
5. **隔离自证**：两代真快照 in-situ 重放跑前/跑后指纹一致（11:0x 代 `c64b71cc…`、12:0x 代 `0498f194…`，`s23_w2_churn_in_situ_verify.txt` :3/:10/:12/:19 现读），且本窗独立复算 12:0x 代聚合＝`0498f19437b06c37df7e1c73499487b2` 逐字相符（§0-12）⇒ churn FP 段那个「往 `$AFTER/fp*.full_selftest.txt` 写」的副作用（`spr40_churn.sh:36`）没碰到证据目录。
6. **§B 两行文档订正**：两句由程序从 R45 件逐字抽取（本窗复算：两句在 R45 件里各恰 1 命中、len=129/105、均不含 `FROZEN_CLAIM` 可抽取声称对）；两宿主 EOF 各 +1 行、`:193`/`:314` 原文未动（append-only 不变量，§0-3/4 末行逐字）；站点数复算仍 8/5、值集 {('34','0')} ⇒ `FROZEN_SITES{8,5}` 精确相等闸未炸（§0-13，R45 §B-3 兑现）。
7. **首跑 `--expect 12` 假红一枪**：如实申报合格。红的确实是"我对预期的猜测"不是盘（写发生与否由 `wc -l`＋`diff` 独立坐实，本窗 §0-3/4 复核成立）。教训采纳并入 §G-4。

### A-2 🔴 唯一证件缺口（如实钉下，不掩）：`TEETH-VERIFY GREEN states=3 fails=0` 这行**盘上无载体**

- 现象：该串是刀脚本 stdout 的末行汇总（生成点 `_tools/spr40_churn_teeth_verify.sh:108`，锚：`grep -n 'note "TEETH-VERIFY GREEN states=3 fails=0（缺件硬红 ∧ 漂移硬披露 ∧ 真快照未被写）"' _tools/spr40_churn_teeth_verify.sh` ⇒ 恰 1 命中）。但本窗全库扫 `grep -rl "TEETH-VERIFY GREEN" . --include="*.txt" --include="*.log"` ⇒ **零证件命中**（只命中生成它的 `.sh` 本体与两份叙述件）。刀的设计就是 stdout 不落盘（`run_state()` 只把 churn 的输出重定向进 T*.txt，驱动自身的 note/want 行走 stdout），所以那 11 条 want 断言结果与汇总行**当场蒸发**。
- 定性与处置：三张 T*.txt 的内容侧证据（§A-1-3）＋本窗 §0-12 的隔离复算已足以支撑**验收通过**；缺的是"驱动层自己也留过影"。这不是造假信号——若驱动根本没跑完，T2/T3 的差异态不会恰好各自落在 `red=1`/`red=0` 且披露行形状逐字对。但按 HP-8（零输入不许报绿）与本项目"结论必须能被盘上证"的一贯口径，**该汇总行的存在性目前只能靠叙述件转述**。
- 裁定：登记为**随车尾巴 V-1**（下一个空闲锁窗顺路补，⛔ 单独开窗、⛔ 跑 Godot）：重跑一次刀并把 stdout 全量 tee 进带六子串之一的证件。**逐字生效文本见 §A-4**（含一处防呆：现行 `run_state()` 会把 scratch 建在证件目录里，V-1 直跑会污染 `spr40_b/`——必须先挪 scratch）。

### A-3 churn 件新 md5 正式转入基线总线

自本件起，churn 口径基线＝`05c36e496c0b5fedde314be834f47fd6`（58 行）。旧值 `6e8f6703c071824b7fa4817c9b93aba3`（54 行）退役，仅允许出现在写明「⛔ 再引用」的作废/对照语境（比照 selfaudit `RETIRED` 的规矩）。今后任何窗要引用 churn 现状，第一步现读 `md5sum -b _tools/spr40_churn.sh` 与本值全等，不等即先归因再说话。

### A-4 V-1 逐字生效文本（两处补丁，一次落地）

**补丁 V-1a（防呆：scratch 搬出证件目录）**——`_tools/spr40_churn_teeth_verify.sh` 现读 :54 一行整行替换（锚：`grep -n 'local state="$1" mutate="$2" scr="$ROOT/_tools/spr40_b/_teeth_scratch_$1" log' _tools/spr40_churn_teeth_verify.sh` ⇒ 恰 1 命中）：

```
	local state="$1" mutate="$2" scr="$ROOT/_tools/spr40_b/_teeth_scratch_$1" log
```

改为：

```
	local state="$1" mutate="$2" scr="$ROOT/_tools/spr40_teeth_scratch/$1" log
```

（🔴 保持 TAB 缩进；`rm -rf "$scr"` 在现读 :65 已有，scratch 搬家后清理逻辑不变；新落点 `_tools/spr40_teeth_scratch/` 顶层不被 run.sh F-2 的三个 glob（`g_*/k*/teeth*`，`spr38_run.sh:115`）命中——目录名不在 glob 形状内，且其内无匹配文件。V-1a 的动机：现行 :54 把 scratch 建在**证件目录** `spr40_b/` 里面，任何中途失败都会往证据面里留 `_teeth_scratch_T*` 垃圾。）

**补丁 V-1b（最终文本，逐字照抄——除此段外本件任何"示范文本"均⛔ 落地）**——`_tools/spr40_churn_teeth_verify.sh` 现读 :107-112 整段替换（锚：`grep -n 'note "TEETH-VERIFY GREEN states=3 fails=0（缺件硬红 ∧ 漂移硬披露 ∧ 真快照未被写）"' _tools/spr40_churn_teeth_verify.sh` ⇒ 恰 1 命中＝:108；块首 `if [ "$FAIL" -eq 0 ]; then`＝:107、块尾 `exit 1`＝:112，两条命令同窗实跑各恰 1 命中）：

```
if [ "$FAIL" -eq 0 ]; then
	note "TEETH-VERIFY GREEN states=3 fails=0（缺件硬红 ∧ 漂移硬披露 ∧ 真快照未被写）"
	exit 0
fi
note "TEETH-VERIFY RED fails=$FAIL ⇒ CHK 面语义无牙或刀自身钝了，先修再谈 W2 收官"
exit 1
```

改为：

```
if [ "$FAIL" -eq 0 ]; then
	note "TEETH-VERIFY GREEN states=3 fails=0（缺件硬红 ∧ 漂移硬披露 ∧ 真快照未被写）"
	exec >> _tools/spr40_b/s40r45_churn_teeth_driver_audit.txt 2>&1
	note "TEETH-VERIFY DRIVER-AUDIT 已落 _tools/spr40_b/s40r45_churn_teeth_driver_audit.txt（本行为末行，其上有全部 want 断言行与两行快照指纹）"
	exit 0
fi
note "TEETH-VERIFY RED fails=$FAIL ⇒ CHK 面语义无牙或刀自身钝了，先修再谈 W2 收官"
exec >> _tools/spr40_b/s40r45_churn_teeth_driver_audit.txt 2>&1
note "TEETH-VERIFY RED DRIVER-AUDIT 已落同件（红态同样要留影）"
exit 1
```

（说明：`exec >>` 放在 GREEN/RED 两条路径的 note **之前**——GREEN 分支里若先 note 后 exec，汇总行自己反而进不了证件；exec 之后驱动的全部 stdout（含 :79-:105 的 want 断言行、隔离自证行、末行汇总）追加进同一份 driver_audit。证件名含 `audit`＝CHAIN_EXCLUDE 六子串之一（`_tools/spr38_r8_verify.py:152` 现读），不会被 latest_chain/F-2 卷走。🔴 上面这段是 V-1b 的**唯一生效文本**。）

**V-1 验收条件（四条全中才算结）**：
1. `bash -n _tools/spr40_churn_teeth_verify.sh` rc=0；
2. 跑一把（锁 FREE 前提，W-2 三行由刀自己打印）⇒ 退出码 0，且 `_tools/spr40_b/s40r45_churn_teeth_driver_audit.txt` 存在、**末行**逐字含 `TEETH-VERIFY GREEN states=3 fails=0（缺件硬红 ∧ 漂移硬披露 ∧ 真快照未被写）`、其上可数出 `断言 ok` 行 ≥ 8 条、`隔离自证 ok` 行 1 条；
3. `grep -rc "TEETH-VERIFY GREEN" _tools/spr40_b/*.txt` ≥ 1（此前本窗实测＝0，即 §A-2 缺口的原始证据）；
4. 真快照复算 `md5sum _tools/spr40_base_r17/* _tools/spr40_after_r17/* | md5sum` 跑后仍＝`0498f19437b06c37df7e1c73499487b2`；`_tools/spr40_b/` 下**无** `_teeth_scratch_*` 残留（V-1a 生效后应天然为 0，锚：`ls _tools/spr40_b/ | grep -c _teeth_scratch`）。
5. 🔴 卫生：V-1 落地前后 `spr40_churn_teeth_verify.sh` 新旧 md5 都要打印进回执；churn 件 `05c36e49…` 必须**不动**（本补丁⛔ 碰 churn 件）。

### A-5 附带裁定：12:0x 代（`*_r17`）CHK 五件缺失维持 R45 §E-3 待裁不变

本窗复算确认该代两侧 0 份 chk/clause（§0-11）、in-situ 面 `red=1` 属盲区显形非回归坏。⛔ 授权任何人**造** chk 内容；补建绑 M4 后首个完整 RUN-GREEN 轮真跑五个判据件产出。该代 churn 在此之前**结构性不可用**，引用者须知。

---

## §B 事项 2 总裁：离线 EV 恒红一条——**四案裁 D**（不取 A/B/C 原样，理由在下）

### B-1 事实底盘（本窗独立复现，非转抄）

- 红的原文（证件 `_tools/spr40_b/s22_r45_terminal_artifact_verify.txt`）：
  - `:24` `FAIL 链声称臂数=0 != 期望 6（⛔ 少臂当正常）`
  - `:25` `EVIDENCE-VERIFY RED issues=1 checks=9`
  - `:10` 选件行 `RUNLOG 选中=_tools/spr38_run.all.terminal.txt mtime=11-19 12:59:42｜终端行 |RUN-GREEN step=all gates=0 knife=0 run=9 …＋6 件牙口＋…|`
  - （锚：`grep -n "FAIL 链声称臂数=0 != 期望 6（⛔ 少臂当正常）\|EVIDENCE-VERIFY RED issues=1 checks=9\|RUNLOG 选中=" _tools/spr40_b/s22_r45_terminal_artifact_verify.txt`）
- 机制（盘上现读）：`_tools/spr38_evidence_verify.py:734` `claimed = None if INCHAIN_AS else re.findall(r"^RUN 牙口 (\S+) ok \|([^|]*)\|$", raw_run, re.M)`，而 `raw_run`（`:524`）读的是**选中件**；选中件按 mtime 已是 2 行的终端摘录（§0-9：`grep -ac "RUN 牙口"` 返回 0），打点行只在整轮 runlog 里（§0-10：6 处，:12–:17）。⇒ 每轮必红，`issues=1` 之外九查全过，时间窗面完好（证件 :13「存在=20 落在本次链窗内=20 早于窗=[]」）。
- 上一窗那条「F-1(b) 会让离线面定不到窗」的预测：**彻底不成立，撤回继续成立**（本窗 §0-9/证件 :13 双证）。

### B-2 三案逐一裁语

- **A（扩 release() 落 6 行打点进 TERM_TXT）— 不取**。①它把"摘录件"重新长成"缩小版 runlog"，与 F-1 立架构的初衷（摘录＝窄、单一身份）相悖；②`release()` 运行在**父壳**（trap 于 `spr38_run.sh:98`），而 `CHAIN_ISO/RUNLOG` 定义在快照子进程（`:104-105`）——父壳里 `"$RUNLOG"` 为空，打点行会静默落不进去，测试还测不到（这是我在盘上读出来的形状，不是推测：锚 `grep -n 'CHAIN_ISO="\$(date' _tools/spr38_run.sh` ⇒ :104，在 :35-44 的快照分叉之后）；③改链件＋重跑一整代链才能验，F-1 刚稳定，风险收益比最差。
- **B（判据改成解析终端行 `＋N 件牙口＋` 字样）— 不取**。数量字样是**自我声称**：链说 6 我们信 6，正是"打点数对就算臂齐"的空转形状；而且它会把 V-H #13 那颗"拆竖线"变异刀的靶子拆掉——现造错态（`_tools/spr38_evidence_verify.py:447`，want=`链声称臂数=0`）之所以能咬，是因为臂清单真的从 prose **逐对**抽出来；换成一个数字字样后，同样的造错不再改变任何东西。⛔ 为灭一条已知红而废一把已验证有牙的刀。
- **C（收官只认 in-chain EV，离线降披露）— 部分吸收**。方向对（活链臂清单来自盘上承载件互认，不依赖 prose），但它把离线面整个降级，扔掉了离线面**独有的**跨轮审计价值；且"永远带一条已知红"没有规定呈现口径，将来一定有人顺手抹红。
- **D（本裁）**：离线 EV 保留全套判据，只把**臂清单的来源**从"选中件里的 prose"改为"**选中件（终端摘录）指名的那一代整轮 runlog 里的 prose**"——指名方式＝摘录件的链起始 ISO ∩ runlog 原件命名规则（`spr38_run.<STEP>.runlog-<ISO>.log`），不新增任何"链自己说了算"的数字声称。prose 仍是逐对 (臂名↔判定串)，V-H #13 刀原样有牙；终端摘录件继续当**资格凭证**（有它才证明这轮真收过官），整轮 runlog 继续当**打点台账**。接口缝两头都不许伪造中间人。

### B-3 D 案逐字生效文本（PROTECT 件 `spr38_evidence_verify.py`，本窗明确授权，两处补丁＋一处可选补丁）

**补丁 R-X1**——现读 :524 一行整行替换：

```
raw_run = None if INCHAIN_AS else (rd(RUNLOG_REL) if RUNLOG_REL else None)
```

改为：

```
raw_run = None if INCHAIN_AS else (rd(RUNLOG_REL) if RUNLOG_REL else None)
ARM_RUNLOG_REL = None
if not INCHAIN_AS and RUNLOG_REL:
    _m_iso_x = re.search(r"(?:runlog-)?(\d{4}-\d{2}-\d{2}T\d{6})", os.path.basename(RUNLOG_REL))
    _m_step_x = TERMINAL_PAT.match((RUNLOG_TERM or "").strip())
    _step_x = (_m_step_x.group(1).lower() if _m_step_x else None) or \
              (re.search(r"spr38_run\.([a-z0-9]+)\.", os.path.basename(RUNLOG_REL)).group(1)
               if re.search(r"spr38_run\.([a-z0-9]+)\.", os.path.basename(RUNLOG_REL)) else None)
    if _m_iso_x and _step_x:
        _cand_x = "_tools/spr38_run.%s.runlog-%s.log" % (_step_x, _m_iso_x.group(1))
        if _cand_x != RUNLOG_REL and rd(_cand_x) is not None:
            ARM_RUNLOG_REL = _cand_x
            raw_run = rd(_cand_x)
```

（语义：选中件若是终端摘录（件名带链 ISO、且本身不含打点也无所谓——判断只看名字形状），就把**打点来源**换到同 ISO 同 STEP 的整轮原件；原件不存在 ⇒ `ARM_RUNLOG_REL=None`、`raw_run` 维持选中件本体 ⇒ 老行为、老红，**⛔ 静默放行**。`TERMINAL_PAT` 现读 :48、`RUNLOG_TERM` 现读 :100、`rd()` 现读 :156，均在补丁点之前已定义。）

**补丁 R-X2**——现读 :792-:794 三行整块替换：

```
if len(claimed) != m_expected:
    fails.append("%s臂数=%d != 期望 %d（⛔ 少臂当正常）"
                 % ("本窗承载" if INCHAIN_AS else "链声称", len(claimed), m_expected))
```

改为：

```
if claimed is None:
    fails.append("链披露臂数=0 != 期望 %d（选中件无打点行；打点台账=%s）（⛔ 少臂当正常）"
                 % (m_expected, ARM_RUNLOG_REL or "无（选中件即打点件）"))
elif len(claimed) != m_expected:
    fails.append("%s臂数=%d != 期望 %d（⛔ 少臂当正常）"
                 % ("本窗承载" if INCHAIN_AS else "链声称", len(claimed), m_expected))
```

（语义：`claimed is None` ＝"选中件是终端摘录且**连打点台账都找不到**"——此时 `len(None)` 会 TypeError、:828 的逐对循环也会崩，崩虽然也出非零但报错不可读、还会吞掉同轮其它面的红。所以给它一条**明说的红**，并用 R-X3 把 :828 的循环护住；找到台账并抽出 6 对则走原判据、走原循环。）

**补丁 R-X3（配套，必做）**——现读 :827-:828 两行之间插入守卫：

```
known_names = dict(TEETH_ARMS)
for label, sentinel in claimed:
```

改为：

```
known_names = dict(TEETH_ARMS)
for label, sentinel in (claimed or []):
```

（`claimed=None` 时跳过逐对核验，红由 R-X2 那条负责；其余逻辑一字不改。）

**可选 R-X4（建议同车）**——:778-:781 的 `牙口面 表互证 …｜%s臂=%d` 打印行在 `claimed=None` 时 `%d` 配 None 会 TypeError。本窗核对过：该 print 用的是 `len(claimed)`（:781 末参），None 会崩。⇒ 同块内把 :781 的 `len(claimed)` 改为 `(0 if claimed is None else len(claimed))`。锚：`grep -n '"本窗承载" if INCHAIN_AS else "链声称", len(claimed)))' _tools/spr38_evidence_verify.py` ⇒ :781。

### B-4 D 案验收条件（五条，全中才算结）

1. **离线复跑**（锁 FREE、W-2 三行入证件、`player.gd==037f261d…` 现读相等后跑）：`python _tools/spr38_evidence_verify.py` ⇒ 期望 `EVIDENCE-VERIFY GREEN checks=10`（不再是 RED issues=1）；证件里必须能看到 `RUNLOG 选中=_tools/spr38_run.all.terminal.txt` 与打点来源分离的事实（选中件≠打点件）。
2. **V-H #13 刀仍有牙**：`python _tools/spr38_evidence_verify.py --falsify` ⇒ 末行 `EVFALSIFY VERDICT=ALL_DETECTED states=…`，且态 6『牙口打点形状破坏（拆竖线）』命中期望串。⚠ 若该态因 `链声称臂数=0` 字样漂移而不命中，**允许**把 :447 的 want 串同步为 `链披露臂数=0`（仅此一词，⛔ 动别的）；同步后 `grep -n "链披露臂数=0" _tools/spr38_evidence_verify.py` 须恰 2 命中（:447 want ＋ R-X2 消息体）。
3. **负对照（证 D 不吞缺件）**：临时沙箱里把整轮 runlog 改名/移走（只动副本，⛔ 动 `_tools/` 真件）⇒ 离线 EV 必须红，且红文含 `链披露臂数=0 … 打点台账=无（选中件即打点件）`。这条防的就是"D 案把找不到台账当成没发生"。
4. **活链面零变化**：下一次**本就需要的**链（M4 区）跑完 ⇒ runlog 里 `RUN 牙口 证据重算活链 ok |EVIDENCE-VERIFY-INCHAIN ok checks=10 …|` 在位、`RUN-GREEN step=all` 在位；⛔ 为验证 D 案专门起链（与 R45 §B-4 同理，纯工具面补丁搭任一存窗链顺路验）。
5. **卫生**：补丁落地前后 `spr38_evidence_verify.py` 新旧 md5 都进回执（现值 `d4c2b3533d36bee2bd4e84e4fd7a3c3a`，897 行）；`spr38_run.sh` 保持 `4130e4ae…` **一字不动**（D 案零链件改动是其核心卖点）；`check_after_write.py --expect` 的数**先跑只读 touched 计数再定**（§G-4 新规首次生效）。

### B-5 归属与禁止事项

- 本补丁属 PROTECT 判据件，**本窗已给逐字文本**，编程侧⛔ 自行改写语义（措辞微调可以，判据形状不可以）；落地窗＝下一个空闲锁窗，与 V-1 同车（V-1 零风险在前、D 案在后，红了也好回滚——`_backup/` 相对路径镜像范式）。
- ⛔ 动 `release()`、⛔ 动 `TERM_TXT` 形状、⛔ 动 F-2 归档逻辑、⛔ 动两张臂表（`TEETH_ARMS`/`TOOTH_ARMS`）的任何一对。

---

## §C 事项 3 总裁：「151」**作废成立**；后续 churn 证据面**统一白名单口径＋blind_faces 申报**

### C-1 复现结论

- 出处坐实：本窗独立求和 §0-14 ⇒ 十面列合计恰＝151，与 `s19_churn_nonjit_only_audit.txt`（12:22:19 落盘）声明值相符 ⇒ **R43 §K-2 转录无误，当年确实跑得出来**。
- 不可重算坐实：`s21_churn_blacklist_151_verify.txt` 现读两把写得出口径＝**705**（AGENTS §3 逐字五前缀）与 **179**（再加 `[SMOKE-P]`＋`^[SMOKE] t=`），都不是 151；汇总件只留每面四个数，**抖动族黑名单本体从未随件落盘**。
- 结论：**151 作废、公开撤回**，依据 R18 §3-2「生成器补不出 ⇒ 此数不得进入任何后续引用链」。编程侧⛔ 反推凑数名单的处理**正确，追认**——那是 D-R18-1（先有结论再编算法）同族。
- 方向性论据核定成立且不依赖 151：残差 705/179/151 任一 ≫ 白名单漂移 **2**（白名单件现读：`s20_churn_whitelist_audit.txt` 末表「合计断言行=24 ｜ 漂移①=2 ②=1 ③=0」，他窗 12:55:36 落盘）。
- 纠一处指针：R47 §E 把白名单件写成 `s20_churn_whitelist_verify.py`（那是**生成器**，12:55:30）；漂移 2 的实测值在**证件** `s20_churn_whitelist_audit.txt`（12:55:36）。本件起以证件为准、生成器为源，两者分开引。

### C-2 口径转正（即刻生效，零代码）

1. 后续一切 churn 证据面**只引白名单口径**：算法件 `_tools/spr40_b/s20_churn_whitelist_verify.py`（AST 七前缀＋JITTER_KEYS 十二键掩码，现读 :37/:39/:47-51）＋ 其证件；引用格式＝「合计断言行=N ｜ 漂移①=x ②=y ③=z ｜ blind_faces=…」。
2. `blind_faces` 取自 churn 判定串行（`spr40_churn.sh:58` 自带），引用者⛔ 把"六面无编号断言行"当"六面无事"——那是盲区申报不是绿。
3. **151 及其两个残差数（705/179）入档后只许用于"作废说明"语境**，⛔ 再进任何结论链；谁引谁违规（比照 selfaudit `RETIRED` 名单的处置，是否把这串加进 `RETIRED` 常量＝M4 区顺路题，本窗不动判据件）。
4. R47 §E 那句「他窗 12:54:08 落盘」与盘上 mtime（12:55:36/12:55:30）差约一分半——不影响结论，登记为转录毛边，以后 mtime 直接跟 `ls --time-style=full-iso` 现读值。

---

## §D 边界与挂账（增量）

| # | 事项 | 状态 |
|---|---|---|
| D-1 | V-1（driver_audit 补登＋scratch 防呆） | **可点单**：下一空闲锁窗，随 §B D 案同车；验收 §A-4 四条 |
| D-2 | D 案（R-X1/X2/X3/X4）落地后的 EV 回归 | 排 D-1 同窗；验收 §B-4 五条；第 4 条搭 M4 区**本就需要的**那代链顺路 |
| D-3 | 12:0x 代 CHK 五件补建 | 维持 R45 §E-3：绑 M4 后首个完整 RUN-GREEN 轮真跑生成，⛔ 造数据 |
| D-4 | run.sh:116 四字披露（"上一代"） | 维持 R45 §E-4：任一并存窗顺路，⛔ 单开车 |
| D-5 | 本窗未动清单 | 任何 `.gd`／链件／判据件／冻结表／`AUTORUN_LEDGER.md`／`D:\大纲`／git；未起链未跑 Godot；锁全程 FREE 未碰 |

---

## §G 结论区（六句）

1. **事项 1＝验收通过**：churn 新块＝R45 §A-3 逐字节照抄（本窗 python 全等复算）、三态刀 T1/T2/T3 语义各有牙、阴性对照复现旧假绿、隔离自证与站点数 8/5 全部独立复算相符；唯一尾巴＝`TEETH-VERIFY GREEN states=3 fails=0` 盘上无载体，登记 V-1 补登（§A-4 逐字文本＋四条验收）。churn 基线正式转 `05c36e496c0b5fedde314be834f47fd6`（58 行）。
2. **事项 2＝四案裁 D**：A 不取（父壳变量断裂＋摘录件变质＋换架构风险）、B 不取（拿自我声称数字当臂清单＋废 V-H #13 刀）、C 部分吸收（整个降级扔掉离线跨轮审计、红无呈现口径）；D＝终端摘录继续当资格凭证、臂清单改从**同 ISO 同 STEP 的整轮 runlog** 逐对抽取，找不到台账就明说式见红（§B-3 逐字文本 R-X1/X2/X3＋可选 X4，§B-4 五条验收）。链件 `spr38_run.sh` 在 D 案下**零改动**。
3. **事项 3＝作废成立**：151 出处（列合计）本窗复算吻合、两把可写口径 705/179 复算在案、名单本体未落盘 ⇒ 按 R18 §3-2 撤回；后续 churn 一律「白名单口径＋blind_faces 申报」（§C-2 即刻生效），并纠正一处指针混淆（verify.py＝生成器、audit.txt＝证件）。
4. **新规一条（编程侧 §D 的教训转正）**：`check_after_write.py --expect` 的数**必须先跑只读 touched 计数再喂闸**，⛔ 心算——本窗起写入所有实施单模板。
5. 本件全程只读、结论区**无开放项**：三个事项均已终局裁定，无需作者点头；作者侧唯一知悉项＝logruns 磁盘增长维持"设计后果"（R45 §D-2-3，不变）。
6. 给作者看的一句话：W2 三件套收了；离线面那条"每轮必红"不是产品坏，是判据还在读一份已经不装打点的摘录件——裁定让它去读真正的台账，读不到就明说，不掩盖也不误红；那个对不上账的 151 已正式作废，以后 churn 只用白名单口径说话。
