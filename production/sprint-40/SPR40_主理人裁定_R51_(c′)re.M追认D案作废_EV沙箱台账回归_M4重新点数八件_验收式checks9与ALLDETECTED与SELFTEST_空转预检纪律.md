# SPR40 主理人裁定 R51｜(c′)＋`re.M` 偏离追认为生效版本、R48-W2「D 案」整体作废；EV 反证臂沙箱缺打点台账＝真红立案（补 rels 派生项，禁第二套命名轴）；M4 重新点数＝一车九项（含 EV 沙箱回归、不含臂面）；M4 验收式订正为离线 `checks=9` ∧ 活链 `checks=10` ∧ `EVFALSIFY VERDICT=ALL_DETECTED` ∧ `SELFTEST ok`；「逐字文本照抄必空转」立为 AGENTS §5 通用纪律

- 本件编号：**R51**。取号自证（本窗实跑）：
  ```
  ls production/sprint-40/ | grep -oE "_R[0-9]+_" | sort -u | wc -l   ⇒ 36
  ls production/sprint-40/ | grep -oE "_R[0-9]+_" | sort -u | tail -3 ⇒ _R7_ _R8_ _R9_（数字序末位＝R9；最大已用＝R50）
  ls production/sprint-40/ | grep -c "_R5[1-9]_\|_R6[0-9]_"            ⇒ 0（No matches found）
  ```
  ⇒ **R51 未被占**，本件按号起手，未顺延。
- 取证纪律（按作者令执行）：本窗 **⛔ 重跑 EV／r8／selfaudit／`--falsify`／`--selftest`／churn 判据件本体**；全部数值吸收编程侧 13:1x–13:3x 落盘证件（R47 §H/§I、`s30_falsify_sandbox_regression_audit.txt`、`s22_r45_terminal_artifact_verify.txt`、`s22_falsify_clean_window_audit.txt`）。本窗只跑**只读锚点复现命令**（grep / sed / ls / md5sum -b / wc），共 **15 条**，见 §A。
- 本窗写盘面：**仅本件一份**。⛔ 修改任何既有文件（含同号的 R48-W1／R48-W2／R50-W1／R50-R49）、⛔ 动 `.gd`／链件／判据件、⛔ 起链、⛔ 跑 Godot、⛔ commit/push、⛔ 碰锁文件、⛔ 刷冻结表。

---

## §A 本窗实跑的锚点复现命令（15 条，逐条现跑，结果如实贴）

| # | 命令 | 本窗实测输出（逐字摘录） |
|---|---|---|
| A-1 | `md5sum -b _tools/spr38_evidence_verify.py; wc -l < _tools/spr38_evidence_verify.py` | `88ea0b459b0c701a2e7aa2122b290e91 *_tools/spr38_evidence_verify.py` ／ `927` ⇒ 与 R47 §I-1 第四态一致，本窗期间未再换值 |
| A-2 | `grep -n "ARM_LINE_PAT = re.compile" _tools/spr38_evidence_verify.py` | :164 ＝ `ARM_LINE_PAT = re.compile(r"^RUN 牙口 (\S+) ok \|([^|]*)\|$", re.M)` ＋行内注释点名「偏离 R48 §B-3 逐字文本…登记见值守件 §Q-1」⇒ **`re.M` 在盘** |
| A-3 | `grep -n "def runlog_sibling" _tools/spr38_evidence_verify.py` ＋ `sed -n '172,182p' …` | 定义位在 :172；函数体 docstring 已写明「路径口径走 (α)＝与 rd() 内部同款…本窗选 α」；回落按 `glob(stem + ".runlog-*.log")`，找不到 `return None` |
| A-4 | `grep -n "if not INCHAIN_AS and not claimed:" _tools/spr38_evidence_verify.py` | :757（换源块首行）⇒ R48-W1 §B-3 改点 2 的形状已在盘 |
| A-5 | `grep -n '"本窗承载" if INCHAIN_AS else "链声称", len(claimed)))' _tools/spr38_evidence_verify.py` | **无命中** ⇒ R48-W2 §B-3 R-X4 用来定位它的那条锚串在当代盘上不存在；`grep -n "臂=%d"` ⇒ :807 打印行已是 `…｜%s臂=%d｜臂面真源=%s` 形状，实参 :810 `len(claimed)` ＋ `_arm_src if not INCHAIN_AS else "盘上承载件"` |
| A-6 | `grep -n "def arm_lines" _tools/spr38_evidence_verify.py; sed -n '167,169p' …` | :167 定义；:169 `return ARM_LINE_PAT.findall(text or "")` ⇒ **`text` 为 None 时返回 `[]`，不返回 None**（决定 §B-3 的三态不能由 `claimed` 承担） |
| A-7 | `grep -c "ARM_RUNLOG_REL" _tools/spr38_evidence_verify.py; grep -c "链披露臂数=0" _tools/spr38_evidence_verify.py` | `0` ／ `0` ⇒ R48-W2「D 案」的 R-X1/X2 **从未落地**，盘上是 (c′) 那一族 |
| A-8 | `grep -n "def sandbox_files" _tools/spr38_evidence_verify.py; sed -n '207,240p' …` | :207 定义；清单里 runlog 只有裸一个条目 `…, "_tools/spr38_good_player.bak", runlog, AUDITOR_SRC, …`；:221 结构守卫 `if not runlog or rels.count(runlog) != 1 or chain_terminal(rd(runlog) or "") is None:`；末尾对每个 `r` 做 `os.path.exists` 过滤，缺件打 `EVFALSIFY INVALID 沙箱缺源件：%s` |
| A-9 | `grep -n "SPR38_EV_ROOT" _tools/spr38_evidence_verify.py` | :34（`ROOT = os.path.abspath(os.environ.get("SPR38_EV_ROOT") or …)`）与 :259（`env["SPR38_EV_ROOT"] = dst`）⇒ 子进程 ROOT 确实被改指沙箱，编程侧 §I-4 的机理成立 |
| A-10 | `ls _tools/spr38_run.all.runlog-*.log` ＋ `grep -c "^RUN 牙口" _tools/spr38_run.all.runlog-2026-11-19T124528.log` | 盘上恰一份台账；该件内 `^RUN 牙口` 行数＝**7**（其中 6 行是本轮六臂，第 7 行属上一代残留——与 `s30` 断言「真台账件在盘且含 6 行打点」口径不同，⚠ 见 §C-3 附注） |
| A-11 | `grep -n -- "--in-chain-as=证据重算活链" _tools/spr38_run.sh` | :261 **唯一命中** ⇒ 链里 EV 只挂 in-chain 一臂，`--falsify` 不在链面上 ⇒ 「链不断」是事实，但不是降级理由 |
| A-12 | `grep -n "src_teeth = sorted(glob.glob(os.path.join(ROOT, \"_tools\", \"spr38_run.teeth\*.txt\")))" _tools/spr38_report_selfaudit.py` | :551 唯一命中 ⇒ R50-W1 §D 锁守卫那条锚可复现（本件只在 M4 清单里引用，不重述其内容） |
| A-13 | `grep -n "合计 应解析=564" _tools/spr38_r8_verify.py` | :597（`P1`）与 :599（`P2b`）两处死串在盘 ⇒ R50-R49 §B-Q5 的 (α) 派生化仍是**未做的活** |
| A-14 | `ls -la --time-style=+%H:%M:%S production/sprint-40/SPR40_主理人裁定_R48_*.md …R50_*.md` | R48-W1 `13:16:07`／R48-W2 `13:20:15`／R50-W1 `13:25:43`／R50-R49 `13:29:10` ⇒ 同号两对的**先后顺序坐实**（注意：R50-R49 抬头 §C 撞号披露自称 mtime `13:28:11`，盘上现读 `13:29:10`，两者相差 59 秒，属披露后又被写过一次，不影响称法） |
| A-15 | `grep -n "变异刀" AGENTS.md` ＋ `grep -n "^## 5\." AGENTS.md` | AGENTS.md :113 `## 5. 断言有效性四类（本项目连续多轮踩坑的根因）`；:124 `**变异刀**：临时把被测分支改坏 → 断言必须变红 → 还原。变不红即 \`INCOMPLETE\`，不是 PASS。` ⇒ §E 那条纪律的落点选在这里（紧接变异刀那句之后） |

未跑而引用的格子：本件对「落地前 `FALSIFY ok 15 态 rc=0`」「落地后 `FALSIFY INVALID 正对照（绿件窗）rc=1`」「离线 `GREEN checks=9 rc=0`」「r8 `checks=52 ok=50 red=2`」四组数**均为采信编程侧证件**（作者明令 ⛔ 复现），标注为 `UNEXECUTED-ADOPTED`，⛔ 当作本窗实测。

---

## §B 问 1 总裁：EV 臂面文本正名——**(c′)＋`re.M` 偏离＝生效版本；R48-W2「D 案」整体作废（零吸收）**

### B-1 生效版本认定

盘上 `88ea0b45…`/927 的 **(c′) 三件套（`ARM_LINE_PAT`:164 带 `re.M` ＋ `runlog_sibling()`:172 走 (α) ＋ 换源块 :755-763 ＋ 打印面 `｜臂面真源=%s`:807）就是 EV 臂面的最终生效文本**。施工窗补 `re.M` 这一处**是对裁定件逐字文本的必要修正，追认有效**（口径见 §E），不构成越权：它没改判据形状、没扩池、没双写，只把一个正则的第二参补回来。

### B-2 R48-W2 §B-3「D 案」四补丁逐一作废裁语（**整体作废，不做部分吸收**）

| 补丁 | 裁 | 理由（均可证伪） |
|---|---|---|
| **R-X1**（从选中件**件名**正则取链 ISO 再拼 `spr38_run.<STEP>.runlog-<ISO>.log`） | ⛔ **作废** | ①结构性 no-op：`s30` 断言 6/7 实测件名 `spr38_run.all.terminal.txt` 与正文**都无 ISO 形状**，两处 `re.search` 均 `None` ⇒ `_m_iso_x=None` ⇒ 回落永不触发，而 §B-4-1 期望的正是它变绿；②违反 `pick_runlog()` 自己的 docstring（HP-13：坐标≠身份，⛔ 把件名长什么样硬编进判据）——`s30` 断言 8 直接引到那句原文；③盘上已由 (c′) 的同 stem glob 覆盖同一需求，`grep -c ARM_RUNLOG_REL`=0（A-7）证明它从未落地，**没有需要保留的既成事实**。 |
| **R-X2**（`claimed is None` ⇒ 打「链披露臂数=0 … 打点台账=…」） | ⛔ **作废** | 不可达分支：`arm_lines(None)` 返回 `[]` 而非 `None`（A-6），且 :823 仍无条件 `len(claimed)`，所以 D 案的 `None` 语义在 (c′) 形状下永远不会发生。它的**语义价值**（「找不到台账要明说」）由 §C 的沙箱结构守卫承担——那里已有 `EVFALSIFY INVALID 沙箱缺源件：%s` 这条明说式，无需在判据面再造一条不可达的红。 |
| **R-X3**（`for label, sentinel in (claimed or []):`） | ⛔ **作废** | 护的是一个不会出现的 `None`；且盘上 :857 那行 today 就是不带 `or []` 的原形，加它＝给判据面添一处常量短路，属 AGENTS §5「常量自比较」同族。 |
| **R-X4**（:781 `len(claimed)` → `(0 if claimed is None else len(claimed))`） | ⛔ **作废** | 锚串在盘上**零命中**（A-5），打印面已被 (c′) 改成 `｜%s臂=%d｜臂面真源=%s`（:807/:810）。目标行不存在，补丁无处落。 |

### B-3 「找不到台账就明说式见红」这条语义要不要补进 (c′)：**不要**（裁「不补」）

- (c′) 已经把它想表达的两种状态都说明了：`_arm_src` 保持 `RUNLOG_REL`（＝没回落）或换成台账相对名（＝回落发生过），并且**这个值就在打印面上**（`｜臂面真源=`）。机检看得见，不需要额外一条红。
- 更关键的是判据形状：D 案要求的是 `claimed is None` 这种**永远为假**的条件（A-6）。造一条永不点燃的红，比不造更坏——它会在下一次真出问题时仍然沉默。
- 若将来出现「选中件无打点 **且** 同 stem 也没有台账」的新形状，正确出口是 §C 的结构守卫（沙箱建不出→显式 INVALID），⛔ 在判据面补第四种三态。

### B-4 「批准红第 1 条」结清措辞（追加式，供 R48-W1 §B-6 台账与后续回执照抄；⛔ 回改原句）

> 【R51 §B-4 结清】R48-W1 §B-6 批准红清单第 1 条「EV 链外 `链声称臂数=0 != 期望 6`」**已结清并撤销登记**。
> 消红者＝并发施工窗落地的 (c′) 三件套（宿主 `_tools/spr38_evidence_verify.py`，现读 `88ea0b459b0c701a2e7aa2122b290e91`／927 行），**非** M4 那车、**非** R48-W2「D 案」。
> 证件＝`_tools/spr40_b/s30_falsify_sandbox_regression_audit.txt` TRANSCRIPT 段 13:29:30 那两行：`…｜链声称臂=6｜臂面真源=_tools/spr38_run.all.runlog-2026-11-19T124528.log` ＋ `checks_run=9 / EVIDENCE-VERIFY GREEN checks=9  rc=0`（本窗 UNEXECUTED-ADOPTED，按作者令不复现）。
> 同轮裁定：R48-W2 §B-3 R-X1/X2/X3/X4 **整体作废**（逐条理由见本件 §B-2），R48-W2 §B-4 五条验收中第 1 条以 `checks=9` 收口（见 §D-1），第 2 条改由 §C 的沙箱回归达成。
> ⚠ 本条只结「臂面」这一处；§C 那颗反证臂新红**不是**这条的一部分，它是**另一条红**，登记在本件 §C-1。

---

## §C 问 2 总裁：🔴 EV 反证臂回归——**立案、定性真红、给逐字文本、并进 M4 一车**

### C-1 立案与定性

- **缺陷名**：`EV-FALSIFY-SANDBOX-NO-LEDGER`（沙箱底缺打点台账 ⇒ 正对照自己先红）。
- **定性**：**真红，且方向是「反证能力失效」向**（不是假绿向，但同样不可放行）。机理与编程侧 §I-4 一致并经本窗独立复核：`sandbox_files()`(:207) 的 `rels` 只带 `runlog` 本体（A-8），⛔ 带同 stem 的 `.runlog-<ISO>.log`；`sandbox_run()` 把子进程 `SPR38_EV_ROOT` 指进沙箱（A-9）⇒ 沙箱内 `runlog_sibling()` glob 空 ⇒ `claimed=[]` ⇒ 臂数=0 ⇒ `positive()` 判 `FALSIFY INVALID 正对照（绿件窗）…` rc=1。
- **不许降级**：链里 EV 只挂 `--in-chain-as`（A-11），所以「链不断」是事实，但它与本条无关。**⛔ 任何窗以「反正链不断」为由把这颗红写成披露、挪出批准红清单、或塞进「已知无害」**。它的合法出口只有一个：修好，然后 `EVFALSIFY VERDICT=ALL_DETECTED` rc=0。
- **登记**：R48-W1 §B-6 那张表的**第 4 行**（追加式，⛔ 回改前三行）：
  `| 4 | EV --falsify 正对照（绿件窗）RED issues=1 checks=9（沙箱缺打点台账） | 真红·反证失效向（R51 §C） | M4 第 1′ 件（§C-3 逐字文本）＋ §C-4 两把刀 |`

### C-2 形状选择：裁 **(甲) 补 `rels` 派生项**，否决 (乙)(丙)，并把「禁第二套命名轴」钉成硬约束

三条候选逐一裁（判据＝是否引入第二套真源／是否破坏 HP-13／是否需要换代链）：

- **(甲) 在 `sandbox_files()` 里按同一个 `runlog` 参数派生台账并追加** —— ✅ **采**。零新命名轴、零新架构、保持「按面列举」这条文件头声明、复用 :235 既有存在性过滤（缺件自动走已有的 `EVFALSIFY INVALID 沙箱缺源件` 明说式）。改动落在**判据件自己**，与 M4 其余七件同车同链验证，成本最低。
- **(乙) 让沙箱底自带打点台账（即在 `release()`／链侧多落一份进摘录件旁）** —— ⛔ **不采**。它要么改链件（R48-W2 §B-2 A 案已因「父壳变量断裂＋摘录件变质＋需重跑一整代链」被否，同一理由在此复现），要么给台账再造一个副本槽＝**第二套真源**。且 F-2 归档目录 `spr38_logruns/<ISO>/` 已经提供「按代次取任意一代」的能力，再加一层复制是重复建设。
- **(丙) 给 `--falsify` 的正对照换一个自带台账的底** —— ⛔ **不采**。`positive()` 的两个候选底目前由盘上事实决定（`RUNLOG_REL` 与 `NEWEST_REL`，见 :350/:379-385 的「底·合一」逻辑）；为绿件窗单开第三种底＝把「正对照用的是哪块盘」变成人工挑选，正是 HP-13 反对的「靠位置认领身份」，而且会让「绿件窗」这个词失去可核对的含义。
- 🔴 **硬前置（HP-13 延伸，AGENTS §7 有同名条目）**：**⛔ 为本补丁新增或改写任何文件名格式**。台账必须**只能**由 `runlog_sibling(<选中终端摘录>)` 这一个函数找到；⛔ 在 `sandbox_files()` 里另拼 `<ISO>`、⛔ 另拼 STEP、⛔ 引入第二套 glob 形状。否则「回落能不能触发」就有了两个答案来源，下次改名又是一次静默 no-op。

### C-3 逐字生效文本（宿主＝PROTECT 判据件 `_tools/spr38_evidence_verify.py`；本件明确授权 M4 落地窗改这两处，⛔ 动别的面）

**改点 ①（锚句子，不给裸行号）**——现读整行：

```python
    rels += ["_tools/spr38_run.gates.log", "_tools/spr38_run.knife.log",
             "_tools/spr38_good_player.bak", runlog,
             AUDITOR_SRC, "scripts/player.gd", FROZEN]
```

替换为（前两行与第三行**逐字不动**，只在中间插一项；锚复现：`grep -n '"_tools/spr38_good_player.bak", runlog,' _tools/spr38_evidence_verify.py`）：

```python
    rels += ["_tools/spr38_run.gates.log", "_tools/spr38_run.knife.log",
             "_tools/spr38_good_player.bak", runlog]
    # R51 §C-3 回归修复：臂面真源（(c′) 回落件）必须和选中件一起进沙箱，否则子进程 ROOT 被
    # SPR38_EV_ROOT 指进沙箱后 runlog_sibling() glob 为空 ⇒ claimed=[] ⇒ 臂数=0 ⇒ 正对照自己先红
    # ⇒ 整套反证臂作废（HP-10 ①：正对照不绿，后面每一次红都可能与造错无关）。
    # 🔴 单一真源：台账只由 runlog_sibling(runlog) 派生，⛔ 在本件另拼 <ISO>/STEP/第二套 glob（HP-13）。
    # 非 .terminal.txt 的底（＝选中件本身就是整轮 runlog）返回 None ⇒ 不加，沿用下面的存在性过滤。
    _arm_sib = runlog_sibling(runlog)
    if _arm_sib:
        rels.append(_arm_sib)
    rels += [AUDITOR_SRC, "scripts/player.gd", FROZEN]
```

**为什么这样切而不是在原块里就地插一项**：原块是一个连续的 `+= [...]` 字面量，就地插会把它变成混合表达式；拆成「先列既有、再条件追加、再列尾部」三段，读的人一眼看见「这项是条件来的」，也天然满足「找不到就不加」。三段合起来的集合内容与原来一致（`AUDITOR_SRC/"scripts/player.gd"/FROZEN` 仍在原位，只是换了写法），⛔ 顺手重排其它条目。

**改点 ②（可选，建议同车，纯披露）**——在 `sandbox_files()` 里那条结构守卫的 print **之前**插入两行（锚复现：`grep -n 'rels.count(runlog) != 1' _tools/spr38_evidence_verify.py` ⇒ :221；⛔ 只引句子不引行号落地）：

```python
    if runlog and chain_terminal(rd(runlog) or "") is not None and not runlog_sibling(runlog):
        print("EVFALSIFY 披露 选中件 %s 无打点行且同 stem 无 .runlog-*.log 台账 ⇒ 臂面真源＝选中件本体（离线臂数会红，属预期）" % runlog)
```

（语义：把「没有台账」这件事在**建沙箱阶段**就说出来——它只在「底是合格链件、但确实没有回落台账」这一形状下打印，⛔ 点燃任何红、⛔ 改 rc、⛔ 改判定条件；红仍由判据面那格 `%s臂数=%d != 期望 %d（⛔ 少臂当正常）` 负责，两边不打架。若落地窗认为这句多余，可以整块省略——**改点 ② 不作硬性要求**，改点 ① 才是必修。）

**附注（⛔ 顺手改的东西）**：A-10 现读真台账里 `^RUN 牙口` 行数＝**7**，而 `s30` 断言写「含 6 行打点」。差异来自上一代残留在同一件里（arm 名↔判定串逐对比对仍只认出当代 6 对，故判据不受影响）。**本件 ⛔ 让编程侧为此清理台账件**——那是历史数据，动它就是造第二条真源。若某日 :823 那格因此报「臂数=7 != 期望 6」，那才是新缺陷，另立案。

### C-4 两把反证刀（落地窗必跑，缺一把不算有牙；原始 stdout 落 `_tools/spr40_b/s31_ev_sandbox_ledger_{verify,falsify}.txt`，名字含 verify/falsify ⇒ 天然在 `CHAIN_EXCLUDE` 之外）

- **刀 I（验台账真的进了沙箱）**：临时把改点 ① 的 `if _arm_sib:` 改成 `if False:` ⇒ `python _tools/spr38_evidence_verify.py --falsify` **必须**回到 `FALSIFY INVALID 正对照（绿件窗）… rc=1`。还原后必须 `EVFALSIFY VERDICT=ALL_DETECTED states=<现算，⛔ 印死>` 且 rc=0。
- **刀 II（验臂数不是恒过的常量自比较）**：在**沙箱副本**里删掉任意一条 `RUN 牙口 … ok |…|`（⛔ 动 `_tools/` 真件）⇒ 该态必须抓到、且离线严格面对同一份底必须 `RED …臂数=5 != 期望 6`。期望是**精确等于**，⛔ 拿「删两条还是红」当通过。
- 两把刀的结论只允许三种写法：`OK 抓到`／`❌FAIL`／`UNEXECUTED`。⛔ 记 PASS 而不附原始 stdout。

### C-5 归属与时序：**并进 M4 一车**（＝M4 第 1′ 件），⛔ 单独占用空闲锁窗

- 裁由四条：①它与 M4 第 2/3/8′ 件同宿主（`spr38_evidence_verify.py`／`spr38_r8_verify.py`），拆开就要跑两代链；②它**必须**和第 6 件（编译面第 7 臂）同轮——加臂会改变台账里的臂行数，回归修复若不先在盘，第 7 臂落地当天 `--falsify` 的正对照照样红，届时无法归因；③R48-W2 §B-5 说的「下一个空闲锁窗、与 V-1 同车」那个语境是**D 案**，D 案本件已裁作废，那句话随之失效（追加式留档，⛔ 回改）；④⛔ 拆窗是 R20 §F 的原令，不是我的偏好。
- 因此：**不新开一扇空闲锁窗专做此件**；它随 M4 一起做，做完一次 `STEP=all` 链统一验。V-1（driver_audit 补登＋scratch 防呆）按其自身条件走顺路，⛔ 与本件绑定。

---

## §D 问 3 总裁：M4 重新点数——**九件 → 一车九项**（第 1 件外部完成移出、第 8 件裁撤、新增 1′ 与 10 两项）

### D-1 现状盘点（谁做了什么，编号面上怎么记）

R50-R49 §D 那张「九件 → 八件」表的两处变动同时生效：
- 原**第 1 件**（EV 臂面换源＋两把反证刀）已由**并发施工窗**落地并被本件 §B-1 追认为生效版本 ⇒ **从 M4 手术清单移除**（它不再是待办；它的两把反证刀 §B-4 刀 I/II 也随之移交该并发窗记录，未跑的标 `UNEXECUTED`，⛔ 让 M4 补跑并据此声称绿）。
- 原**第 8 件**（flavor 十条 94→104）按 R50-R49 §B-Q2 裁 **(ii) 撤下** ⇒ 结案措辞以 R50-R49 §B-Q2 那段为准（追加式，只追加、⛔ 回改既有行），`_ML_DECLARED` 维持 94，AUTORUN/B1 两份文档的 26 行半角 `94` **一行都不改**。
- 本件新增 **1′**（EV 沙箱打点台账回归）。
- 另把 R50-W1 §D 的**牙口面锁守卫**显式列为 **10**（它一直在 §C-2 第 5 步里被打包，但从未进 R50-R49 §D 那张表——这是表的漏项，不是新需求）。

⇒ **M4 现在＝九项动作**：2、3、4、5、6、7、8′、1′、10（原第 1 件外部完成移出、原第 8 件裁撤）。为避免「几件」这个词继续歧义，本件起统一称 **「M4 一车（9 项）」**，⛔ 在任何新文档里再写「M4 九件」「M4 八件」这两个词。条目与出处见下表。

| 项 | 事项 | 生效文本出处（逐字在哪） | 宿主文件 |
|---|---|---|---|
| **1′** | 🔴 EV 反证臂沙箱缺打点台账回归（＋可选披露） | **本件 §C-3 改点 ①（必修）／②（可选）＋ §C-4 两把刀** | `_tools/spr38_evidence_verify.py` |
| 2 | r8 `GREEN_MD5` 转正＋`C10a2` 三处绿串同源＋换代义务注释＋投毒刀 | R48-W1 §C-2（含第四串转正 `037f261d…`） | `_tools/spr38_r8_verify.py` |
| 3 | r8 `C12 census` 改「单调不减＋逐 macro 明细＋应==实／可疑==0」＋刀 A/B/C | R48-W1 §C-3 ＋ R50-R49 §C-2（drift 档位**已裁 (甲)**，⛔ 再自选） | `_tools/spr38_r8_verify.py` |
| 4 | churn stance 字段级掩除＋ `:58` 措辞**同轮**换 | R48-W1 §D-3 四条硬约束（实现自拟，已追认）＋ §D-5 逐字句 | `_tools/spr40_churn.sh` |
| 5 | 刀标签更名（`knife.sh` 两行） | R15 §E-3 | `_tools/spr38_knife.sh` |
| 6 | 编译面第 7 件牙口臂（run.sh 行＋承载件＋两张臂表 6→7＋7 处站点值；`TOOTH_SITES` 不动） | R50-R49 §B-Q1 (a)(b)(c)（run.sh 逐字块、标签 `编译面逐档`、插入位置锚已给全） | `spr38_run.sh`／新建 `spr40_compile_arm.py`／两张臂表 |
| 7 | `bak_archive_check` 扩展（`BAK-CLAIM ok`／RED／UNEXECUTED 三态文案＋1 个 falsify 态＋末行五态→六态＋晋升审计件生成义务） | R50-R49 §B-Q3（双源优先级、降级态、判定串、falsify 态数已给全；`spr40_promote_audit.log` 盘上 MISSING 已复核） | `_tools/spr38_bak_archive_check.py`／`_tools/spr40_promote_good.sh` |
| 8′ | r8 `P1`/`P2b` 毒臂死串派生化＋`:233` 门牌现算化＋验收式 SELFTEST 条款 | R50-R49 §B-Q5 (α)（A-13 现读两处死串仍在盘＝**未做**，硬前置：字面串里 ⛔ 再出现阿拉伯数字常数） | `_tools/spr38_r8_verify.py` |
| 10 | 牙口面锁守卫（`do_falsify()` 起手判锁在场 ⇒ `UNEXECUTED-CONCURRENT`＋rc=1） | R50-W1 §D（锚句子 :551 已由 A-12 复现；三条硬约束 (i)(ii)(iii) 照它，⛔ 替换 `:552` 份数守卫） | `_tools/spr38_report_selfaudit.py` |

### D-2 缺件的当场补齐（本窗不欠编程侧任何东西）

- 项 1′：本件 §C-3 即全文，无缺口。
- 项 10：R50-W1 §D 已给「约束＋锚句子＋三条硬约束＋一把刀」，**这就是完整单**；本窗不再重写，只把它升格为表内一行，消除「藏在 §C-2 第 5 步里」的归属歧义。
- 项 4 的实现细节：R48-W1 §D-3 的四条硬约束即边界，**实现自拟已被追认**（R50-R49 §C-3），不需我再给什么；若做不到与 `s20_churn_whitelist_verify.py` 的单源对账，走 §D-3(iv) 降级路径并回报。
- ⛔ 「编程侧自拟」以外的口头待补项：**本件清单里没有一项处于那种状态**。若落地时发现某项文本与盘上形状不符（像 §B-2 那样），按 §E 纪律就地补正＋申报，⛔ 停下来等下一张裁定。

### D-3 窗归属裁语：M4 那一扇独占锁窗**仍由 R49 窗开**（维持 R50-W1 §C-1，不因第 1 件被别人做完而改判）

- 裁由：R50-W1 §C 的判据是「谁此刻握着不被 M4 打断的施工连续性」，那条判据在 R49 窗身上依然成立（它已全文吸收 R48、订正锚已落、就绪度表在它手上）；第 1 件被并发窗做完**不减少**剩余工作的耦合度——剩下的 9 项里 5 项集中在 r8/EV/selfaudit 三件判据文件上，仍然必须同窗同链。改判只会造成第三次交接。
- 并发窗的下一件事**不变**＝W2 的 CHK 残项（R45 §A 逐字文本＋§E-2 三态变异刀，只动 `spr40_churn.sh` 的 CHK 段、⛔ 动 stance），做完进收官车面。
- 🔴 **两窗串行怎么保证不同时握锁（本件给的机制，⛔ 靠约定）**：
  1. **互斥由 `_tools/.spr38_run.lock` 这把原子锁自己执行**——创建用 `O_CREAT|O_EXCL` 语义（bash 侧即 `set -C`／`mkdir` 型原子操作），⛔ 手工 touch 后再检查（那是 check-then-create，两窗都能过）。
  2. **起手自检三行，缺一不可**（两窗都用，逐字）：
     ```
     ls _tools/.spr38_run.lock 2>/dev/null && echo BUSY || echo FREE
     ps -W | grep -ci godot        # 非零 ⇒ 有 Godot 在飞，等同 BUSY
     md5sum -b scripts/player.gd _tools/spr38_good_player.bak   # 两串不等 ⇒ 有窗正在换代，等同 BUSY
     ```
     任一为 BUSY ⇒ 本轮标 `DEFERRED-CONCURRENT`、⛔ 开工、⛔ 顺手跑判据件（R50-W1 §A-4 那条纪律同样约束离线件的每一个读盘子面）。
  3. **锁在场 ≠ 授权**：拿到锁只证明「没有别的持锁窗」，不证明「盘上状态是我预期的那一代」。所以 M4 起手必须先复现基线总线（R48-W1 §0 的 0-1/0-3/0-4/0-5 各行现读换新值，EV 现值以 A-1 为准），对不上就先停手回报，⛔ 边改边猜。
  4. **⛔ 手工碰锁文件**（删除、改名、改 mtime、touch 一个假锁去骗过 §C-4 那把刀）——R50-W1 §C-1 已把这条列为红线，本件重申：为了跑通锁守卫的刀而搭的临时锁，**必须在同一轮内删除并在回执里写明 age 与删除时间**。

---

## §E 问 5 总裁：`re.M` 这类「照抄必空转」的偏离口径——**处置正确，立为通用纪律**

### E-1 对该施工窗的处置裁定

✅ **正确，追认**。它做了三件对的事：①发现裁定件的逐字文本照抄必然空转（而不是默默落地一个恒 0 命中的正则）；②就地补最小必要项（一个 flag，不改判据形状、不扩池、不双写）；③在值守件 §Q-1 申报偏离并点名到具体裁定件的具体小节。
它唯一的不足是**申报的位置**：偏离登记在编程侧自己的值守件里，而裁定件（我这边的产物）没有对应更正——这正是本次「同号两件互相矛盾」局面的成因之一。纪律要补的就是这一环：**偏离必须回写到生效文本的权威面**。

### E-2 通用纪律（即刻生效，零代码）

> 🔴 **逐字文本空转预检（S40-R51 §E-2）**：任何窗把裁定件的**逐字生效文本**落盘之前，必须先跑一次**只读的空转预检**——用盘上的真实输入喂这段文本将要产生的效果（正则喂真件内容、路径拼喂 `os.path.exists`、变量名喂 `grep -n` 定义位、函数名喂本件符号表），确认它**至少命中一次／至少可达一次**；预检不过 ⇒ **就地补正最小必要项**（只补形状、⛔ 改判据语义），并在**两处**申报：(i) 本窗值守件，点名「偏离 <裁定件> §<节> 的逐字文本：<丢了什么/补了什么/为何必补>」；(ii) **引用该文本的后续生效面**（下一张裁定件或收官车的口径段）里带上更正后的文本，使权威面与盘面对齐。⛔ 静默照抄一个恒不命中的判据（那是把红换成永久的沉默）；⛔ 自行放宽判据形状来「让预检过」（那是改断言）；⛔ 停下来等一张新裁定才肯动手（除非补正超出「最小必要项」的范围）。

### E-3 落哪个文件哪一节（由我落笔，⛔ 编程侧代改）

- **落点**：`AGENTS.md` §5「断言有效性四类」表格之后、紧接现有那句 `**变异刀**：临时把被测分支改坏 → 断言必须变红 → 还原。变不红即 \`INCOMPLETE\`，不是 PASS。`（A-15 复现：AGENTS.md :124）**之后**追加一段，标题 `**逐字文本空转预检**`，正文＝§E-2 那条引文的去缩进版。
- 理由：§5 管的就是「断言看起来绿但什么都没验」这四类，恒 0 命中的正则与该族的「常量自比较」同宗；放 §3（门禁七件套）会被读成新的门禁项，放 §7（工具链坑）会被当成 Windows 专属。
- **执行时序**：⛔ 任何窗为本条单独开一扇锁窗。它随**下一次合法触碰 AGENTS.md 的窗**（按惯例＝收官车那一窗）落笔；在那之前，本件 §E-2 的引文即为生效口径，效力等同 AGENTS（R48-W1 §D-1、R50-W1 :49 都是同一处理方式的前例）。
- ⛔ 编程侧代改 AGENTS.md（R50-R49 §C-3 已明文「AGENTS 那句话由我本人在收官车落盘」，本条同等待遇）。

---

## §F 问 4 总裁：M4 验收式的最终形态（可直接逐条打勾）

### F-1 先把那条写错的数改掉

R48-W2 §B-4-1 期望离线 `EVIDENCE-VERIFY GREEN checks=10` —— **该数与盘上形状不符，作废**。形状：`ran += 1` 在 `if INCHAIN_AS:` 支内另有一处专属计数（R47 §I-6 现读；本窗不复算，采信），故**离线恒 9、活链才 10**。
⇒ 验收式一律以 **离线 `checks=9`／活链 `checks=10`** 两格分别收口。⛔ 任何窗为凑那个 10 去动计数器（S40 禁止事项 #8），⛔ 把两格合并成一句「checks 数一致」这种没法判对错的写法。

### F-2 M4 验收清单（最终形态，逐条打勾；每条给「观测判据」，⛔ 允许「看起来没问题」）

> 打勾规则：每格只允许写 `PASS`＋**该行原始 stdout 逐字**、`FAIL`＋原始 stdout、或 `UNEXECUTED`＋原因。⛔ 空白、⛔ 「同上」、⛔ 只写 ✓。

| # | 时机 | 跑什么 | 必须看到（逐字形状） |
|---|---|---|---|
| X-0 | 起手（持锁后第一件事） | `ls _tools/.spr38_run.lock`／`ps -W \| grep -ci godot`／`md5sum -b scripts/player.gd _tools/spr38_good_player.bak` | `lock 在场`、`godot=0`、两串**相等**且等于 `037f261d1b2d393fa02aba6a0bed1654` |
| X-1 | 施工前 | `md5sum -b` 五个宿主（EV／r8／selfaudit／churn.sh／knife.sh／run.sh） | EV＝`88ea0b459b0c701a2e7aa2122b290e91`／927（A-1 现值）；其余以 R47 §I-1 现值为底，⛔ 拿 R20 §G-1／R45 §0 旧值当「改动前」 |
| X-2 | 语法闸 | `bash -n _tools/spr38_run.sh _tools/spr40_churn.sh _tools/spr38_knife.sh`；`python -c "compile(open(p,encoding='utf-8').read(),p,'exec')"` × 四件判据件 | 全部 rc=0 |
| X-3 | 离线严格面（链外） | `python _tools/spr38_evidence_verify.py` | `EVIDENCE-VERIFY GREEN issues=0 checks=9` ∧ 打印面含 `｜臂面真源=_tools/spr38_run.all.runlog-<ISO>.log`（**不是**选中件自己） |
| X-4 | 🔴 离线反证面（**本单核心新格**） | `python _tools/spr38_evidence_verify.py --falsify` | 末行 `EVFALSIFY VERDICT=ALL_DETECTED states=<现算数>` ∧ rc=0 ∧ **无** `FALSIFY INVALID 正对照` 字样；态 6『牙口打点形状破坏（拆竖线）』记 `OK 抓到` |
| X-5 | 两把回归刀 | §C-4 刀 I／刀 II | 刀 I：`if False:` 版必须 `FALSIFY INVALID 正对照（绿件窗）… rc=1`，还原版必须 ALL_DETECTED；刀 II：`RED …臂数=5 != 期望 6`（精确等于）；stdout 落 `s31_ev_sandbox_ledger_{verify,falsify}.txt` |
| X-6 | r8 严格面（链外） | `python _tools/spr38_r8_verify.py` | `R8-VERIFY checks=52 ok=52 red=0 unexecuted=0`（**基准红两条清零**：`C10a 绿件==盘上件==台账串`、`C12 census 复现==历史`；`checks` 总数 **不变**＝52，drift 按 (甲) 并进 ok ⇒ ⛔ 因 drift 项动三个计数） |
| X-7 | r8 毒臂卫生 | `grep -n "合计 应解析=[0-9]" _tools/spr38_r8_verify.py` | **零命中**（8′ 项完成的机器判据：字面串里不再有阿拉伯数字常数） |
| X-8 | 活链 | 一扇 `STEP=all` 独占链 | `RUN-GREEN step=all` 在位；runlog 里「`RUN 牙口 编译面逐档 ok` ＋竖线＋`COMPILE-ARM GREEN`」那一行在位（第 7 臂）；链承载件末行声称 `checks=10` |
| X-9 | 链后立即（不带 `--in-chain-as`） | `python _tools/spr38_evidence_verify.py` | `EVIDENCE-VERIFY GREEN issues=0 checks=9`（＝R48-W1 §B-5 那句「老病自愈证据」，⛔ 拿活链的 10 冒充这格） |
| X-10 | 🔴 链后 r8 牙口（R50-R49 §B-Q5 追加条款，逐字并入本清单） | `python _tools/spr38_r8_verify.py --selftest` | ①末行含 `SELFTEST ok`；②面上 `基准红=[]`；③七把反证刀逐臂 `抓到`，其中 `P1`／`P2b` 期望判定分别为 `C1c`／`C1a`。三者任一不合 ⇒ M4 记 FAILED，⛔ 以「SELFTEST-BLOCK 是过渡态」放行 |
| X-11 | 链后 EV 反证面复跑 | `python _tools/spr38_evidence_verify.py --falsify` | 同 X-4（换代后底会变，这一格必须**链后再点亮一次**；链在飞时读数一律 `DEFERRED-CONCURRENT`，见 R50-W1 §A-4） |
| X-12 | 锁守卫（项 10） | 临时新鲜锁（age≈0）跑 `python _tools/spr38_report_selfaudit.py --falsify`，随后删锁复跑 | 有锁 ⇒ `FALSIFY UNEXECUTED-CONCURRENT 牙口对面：锁在场 age=<N>s …` ∧ rc=1；无锁 ⇒ 回到 `FALSIFY ok <现算> 态…` ∧ rc=0。⛔ 用超过 900 秒的陈锁（会被判 FREE 而放过＝刀没架在正确的面上）；回执须写明临时锁的建立与删除时刻 |
| X-13 | bakclaim（项 7） | `python _tools/spr38_bak_archive_check.py --falsify` | 末行 `BAKGATE-FALSIFY ok 六态全非绿＋正对照绿` ∧ rc=0（五态→六态是本项唯一要改的态数文案） |
| X-14 | 卫生 | `git status --porcelain` ＋ 新旧 md5 对照 | 改动仅限：EV／r8／selfaudit／churn.sh／knife.sh／run.sh／bak_archive_check／promote_good／新建 compile_arm ＋ 文档站点行；`.gd` 与冻结表**零改动**；`spr38_run.sh` 只允许多出第 7 臂那 4 行（注释 3＋调用 1） |
| X-15 | 收官登记 | 基线总线重登 | X-1 那六个宿主的新 md5/行数在**链后**换新值重登（⛔ 提前刷）；R48-W1 §B-6 表追加第 4 行并按 §B-4 措辞撤销第 1 行 |

**收口式（一句话）**：`X-3 ∧ X-4 ∧ X-6 ∧ X-8 ∧ X-9 ∧ X-10 ∧ X-11 ∧ X-12 ∧ X-13 全 PASS` ⇒ M4 绿；任一格 `FAIL` 或 `UNEXECUTED` ⇒ M4 记 FAILED，⛔ 以「链不断」「离线面本来就挂着一条红」为由放行。

---

## §G 同号并存事件的定性与引用称法（作者令：⛔ 改名换号）

### G-1 事件定性

**这不是事故，是分窗并发的正常产物，但它在编号面上留下了一个不可判别引用**：同一批里出现了两组「同号两件」，两件的裁定内容**互不重叠、互不冲突**（经本窗逐节比对：R48-W1 裁 (c′)／R48-W2 裁 D 案；R50-W1 裁牙口混代与归窗／R50-R49 裁 R49 五问），因此**没有任何一条断言被两次裁定成不同值**——除了「M4 是几件」这一项，它由 R50-R49 §D 单方面给出八件，本件 §D-1 接续修订，不构成冲突。

真正的风险是**后续引用**：裸写「R48 §B-3」时，磁盘上有两个候选（一个给 (c′)、一个给 D 案），读者无法判别。这正是 HP-13「坐标≠身份」在文档面的复现，也是幻影坐标纪律要管的形状。

### G-2 引用称法（本件起强制，⛔ 改名、⛔ 换号）

- **称法表**（简称只用于行文，任何**机器判据／验收条款**里必须写文件名全称）：

| 盘上文件（全称，mtime 见 A-14） | 称法 | 它裁的核心 |
|---|---|---|
| `SPR40_主理人裁定_R48_W1独立核验…churn第6条口径转正.md` | **R48-W1** | (c′) 臂面换源、r8 两单、批准红三条 |
| `SPR40_主理人裁定_R48_W2三件套验收通过…白名单口径转正.md` | **R48-W2** | W2 验收、D 案（本件 §B-2 作废）、151 作废 |
| `SPR40_主理人裁定_R50_W1第5问牙口面混代现场总裁…通用口径.md` | **R50-W1** | 牙口混代四候选、M4 归 R49 窗、锁守卫单 |
| `SPR40_主理人裁定_R50_R49五问总裁…M4验收式加SELFTEST.md` | **R50-R49** | R49 五问、第七臂、flavor 撤、M4 表 |
| 本件 `SPR40_主理人裁定_R51_(c′)re.M追认D案作废_EV沙箱台账回归_M4重新点数八件_验收式checks9与ALLDETECTED与SELFTEST_空转预检纪律.md` | **R51** | 本单五问 |

- **三条使用规则**：
  1. ⛔ 裸号引用这四件（「见 R48 §B-3」「R50 说过」）一律视为**不合格引用**，必须写成 `R48-W1 §B-3` / `R50-R49 §B-Q5` 这样的**带后缀称法**。
  2. ⛔ 任何人改名或换号——R50-W1 §C 已写「换号请作者裁」，作者此刻不在场，本窗**不申请也不实施**改名；称法层解决歧义，文件名保持不动（改名会打断所有已落盘的引用，制造第二批幻影坐标）。
  3. ✅ 后续若有第五份裁定需要引用「R48」这一批，**默认指向 R48-W1**（mtime 先者，13:16:07 vs 13:20:15，A-14 现读），若要指 W2 必须显式写后缀。这条默认规则的判据与 R49 抬头自证的「mtime 先者为准」惯例一致。

### G-3 入账（追加式台账句，供收官车照抄）

> 【R51 §G-3 入账】S40 期间存在两组同号裁定件（R48×2、R50×2），成因＝两扇主理人窗并发落盘且均未先 `ls` 清点。定性：**内容无冲突、编号面有歧义**；处置：**不改名不换号**，以带后缀称法（R48-W1/R48-W2/R50-W1/R50-R49）+ 「裸号默认指向 mtime 先者」的规则消化掉。此后**任何主理人窗起手第一件事＝`ls production/sprint-NN/ | grep -oE "_R[0-9]+_" | sort -u` 清点已用号**，取空号并在抬头贴自证（本件抬头那段即范式）。

---

## §H 结论区（五问一句话）

1. **臂面正名**：盘上 (c′)＋`re.M` ＝生效版本，R48-W2「D 案」R-X1/X2/X3/X4 **整体作废、零吸收**，「找不到台账要明说」不补进 (c′)（由 `_arm_src` 打印面与沙箱结构守卫承担），批准红第 1 条按 §B-4 措辞结清并撤销登记。
2. **反证臂回归**：立案 `EV-FALSIFY-SANDBOX-NO-LEDGER`，真红、⛔ 降级成披露；生效文本＝§C-3 改点 ①（在 `sandbox_files()` 里用 `runlog_sibling(runlog)` 派生追加，单一真源、禁第二套命名轴），归属＝**并进 M4 一车（项 1′）**，⛔ 单独占空闲锁窗。
3. **M4 点数**：第 1 件外部完成移出、第 8 件裁撤、新增 1′ 与 10 ⇒ **九项动作／统一称「M4 一车（9 项）」**，每项生效文本出处见 §D-1 表，无一项还欠编程侧东西；M4 锁窗**仍由 R49 窗开**，串行由原子锁＋起手三行自检＋基线总线复现三步保证，⛔ 靠约定。
4. **验收式订正**：离线 `checks=9`／活链 `checks=10` 分两格（⛔ 凑数、⛔ 动计数器），`EV --falsify ⇒ EVFALSIFY VERDICT=ALL_DETECTED` 与 `r8 --selftest ⇒ SELFTEST ok ∧ 基准红=[] ∧ P1/P2b 抓到 C1c/C1a` 已写进同一张可打勾清单（§F-2，X-0…X-15）。
5. **偏离口径**：施工窗处置**正确并追认**；「逐字文本落盘前先跑只读空转预检，不过就地补正并在值守件＋生效面两处申报」**立为通用纪律**（§E-2 逐字），落点＝`AGENTS.md` §5 变异刀那句之后，由我在下一次合法触碰 AGENTS 的窗（收官车）落笔，⛔ 编程侧代改。

## §I 本窗未执行项（如实报）

- `UNEXECUTED-ADOPTED`：EV/r8/selfaudit 的 `--falsify`／`--selftest`／严格面四组数值全部采信编程侧证件（作者令 ⛔ 复现），本件对它们是**引用**，不是复算。
- `UNEXECUTED`：未起链、未跑 Godot、未跑任何判据件本体、未跑 §C-4 与 §F-2 的任何一把刀、未改 AGENTS.md、未碰锁文件、未动 `.gd`／冻结表／链件／判据件。
- 本窗写盘仅一处：本件。
- 一处指针自查：A-14 现读 R50-R49 的 mtime 是 `13:29:10`，而该件抬头 §C 自报 `13:28:11`——差 59 秒说明它在自报之后还被写过一次。**不影响称法**，但按幻影坐标纪律如实登记，⛔ 有人拿那个 13:28:11 去论证「谁先谁后」。
