# SPR41 编程侧呈请 R78：R77 车次回执＋八格停等（taut 行数账 432↔434／r8 一句两数 800·802↔803／C7b·C15a·C15e 随 gates 换代见红／churn 新两面在改前树结构性红）

- 收件：R77 裁定件 `production/sprint-41/SPR41_主理人裁定_R77_三处不可执行面重裁与taut补闸.md`（本窗现算 md5 `8944d56310343e85f9d742c809e0ce3f`／238 行，纯 LF）——§H-1 施工序 §B→§C-3→§C-4→§F-2.2→§E、§H-2「先证有牙再谈绿」、§F-2.2.3「新刀落地同轮换 s168 三针」、§J 转录口径，全部按裁语执行。
- 性质：**回执＋请裁单**。§B／§C-3／§C-4／§E-2／§F-2.2／§J 六格已落地出证（§B 节）；§C 八格属主理人专裁面（判据面／登记语义／验收尺子口径）或作者保留五类（数值口径／放行／冻结重定），⛔ 编程侧自施工、⛔ 自改期望数让门转绿。
- 取号：`ls production/sprint-40 production/sprint-41 | grep -oE "_R[0-9]+" | sort -n | tail -3` 实测 `75 76 77` ⇒ 本单取 **R78**，无撞号。
- 行号纪律：本单所有行号、md5、计数＝本窗现读或现算（凭据目录 `_tools/spr41_r77/`，失败态一律先留序号再重跑，⛔ 原地冲）；裁语与盘上不互洽处**以盘上为准并如实申报**，⛔ 为凑裁语的数去删裁定文本或删栅栏行。

## §A 总裁一览

| 格 | 一句话 | 落点 |
|---|---|---|
| 回执 | R77 六格施工实测串（牙口＋生产面＋凭据号） | §B |
| ① | taut 行数账：裁语 §B-2.4 写「429→432」，逐字插码后盘上＝434（差 2 行） | §C-① |
| ② | r8 常量派生：裁语 §C-3.1 同一句给了 800 与 802 两个期望终态，栅栏自数＝803 | §C-② |
| ③ | churn（V-H #6）改前树跑新立 PD／qgate 两面必然红＋churn 的 CHK 面清单固定 5 名不含新面 | §C-③ |
| ④ | gates.sh 两次换代（130→133→135）连带 C7b／C15a／C15e 三面红，其中 C15a 是 r8_verify 自己的对账基线口径问题 | §C-④ |
| ⑤ | §B-3.2「不可达脚本」闸与 MSYS 混合分隔符坑（本窗第三次撞上，已定因） | §C-⑤ |
| ⑥ | `--selftest` 面 SELFTEST-BLOCK：期望格落在作者保留五类里，编程侧无资格自评 | §C-⑥ |
| ⑦ | P2b padding 空操作（`bw.group(0)` 候选），属逐字裁语落地时的形状缺陷 | §C-⑦ |
| ⑧ | 证据卫生自曝两件（s214 两份 stdout 先删后读；§J 写盘刀首趟吞掉六行末列） | §C-⑧ |

## §B 回执：六格施工实测串

| 格 | 盘上落点（现算 md5／行数） | 牙口（造错必红） | 生产／离线面 | 凭据 |
|---|---|---|---|---|
| §B taut 存在性闸补票 | `_tools/spr38_tautology_sweep.py` `46267f0c8a`／434 行（改前 `1da94bd93d`／429） | falsify 面缺路径即 RED，quota/verbatim 同款两行闸插两处（生产面＋falsify 面） | 生产面 `VERDICT=TAUT_OK` 同趟复跑 | `s200_r77_b_falsifyface1.txt`／`s200_r77_b_prodface1.txt`／`s200_r77_b_taut_gate1.txt`（行数差申报件）／`s200_r77_b_gates1.txt` |
| §C-3 r8 会腐烂常数改派生 | `_tools/spr38_r8_verify.py` `b1bbf96d0e`／803 行（改前 798） | 派生值喂旧件／投毒臂 P44~P55 全数照抓 | `R8-VERIFY checks=55 ok=49 red=6 unexecuted=0`（六格归因见 §C-④） | `s201_r77_c3_const_derive2.txt`／`s201_r77_c3_verify1.txt`／`s201_r77_c3_selfprove1.txt` |
| §C-4 新立 `_pd_assert` 常驻机检 | `_tools/spr41_pd_selfconsistency_check.py` `30c37421c3`／312 行 | PD-T1~T4 四档 `VERDICT=ALL_DETECTED` 误报=0；站点下限由现读派生（⛔ 写死 83） | `PD-CHECK 应解析=83 实解析=83 参与核对=83 可疑=0 VERDICT=CLEAN_EXEC`；gates 面 `PD hits: want=83 site=83 join=83 suspect=0` | `s202_r77_c4_pd_falsify1.txt`（首趟 `NO_TEETH`＝定义行冒充站点）／`s202_r77_c4_pd_falsify2.txt`／`s202_r77_c4_pd_prod1.txt`（首趟 实解析=84）／`s202_r77_c4_pd_prod2.txt`／`s212*_r77_c4_pd_*.txt` |
| §E-2 V-A4 验收尺子重立 | 零施工（口径件 139 行不变） | 五条尺子命令现测 `1／0／1／34／139` 全满足裁语形状 | 同左 | `s204_r77_e2_ruler1.txt`／`s204b_r77_e2_ruler2.txt` |
| §F-2.2 新立常驻引文门禁刀 | `_tools/spr41_deliverable_quote_gate.py` `0d6824227e`／296 行；`_tools/spr38_gates.sh` `53ed5cee95`／135 行（CHK 面 4→5） | 刀体六臂 `QUOTE-GATE-FALSIFY arms=6 pass=6 fail=0 ALL_DETECTED`；s168 三针同轮换靶 `QUOTE-FALSIFY-GREEN mutants=5`（首趟红 `s208_r77_f22_teeth1.txt`＝m3 造错点落在清单定义之前 ⇒ 副本 NameError，按 §C-3 规矩留盘、⛔ 放宽 `once()` 期望命中数）；面数由 `spr38_r29_extract.py` 现读 gates 的 `for spec` 循环派生，两向都咬：喂旧面数日志 ⇒ `chk3-count=4(want=5) CHAIN-CLEAN=NO` rc=1，喂新日志 ⇒ `CHAIN-CLEAN=yes` rc=0 | 生产面 `QUOTE-GATE-GREEN 代码块行=101 参与核对=92 一手命中=92 仅二手命中=0 未命中=0`（V-H #11 自报数行 `hits: primary=92 secondary_only=0 miss=0`）；零输入面 `QUOTE-GATE-RED`＋非零退出（HP-8）；离线面终态 `GATES_EXIT=0` 五面全 rc=0 | `s205*_r77_f22_qgate_falsify*.txt`／`s207*_r77_f22_qgate_prod*.txt`／`s208`+`s208b`+`s215_r77_f22_s168_teeth_final1.txt`／`s209*_r77_f22_*.txt`／`s210`+`s213_r77_f22_gates_full*.txt`／`s214*_r77_f22_extract_teeth*.txt`＋`s214c_r77_f22_extract_abort_cause1.txt` |
| §J 转录件 | 交付件 `SPR41_编程侧交付_A组.md` §9.1 ②③⑥⑧＋§5 P-4/P-9 六处同行追加（355 行不变，追加后现算 `1a762f592b`）；台账 append 一行（221→222，现算 `66bb282cbd`） | 写盘刀与复核刀分两把；复核刀 TABLE-CELLS 抓住写盘刀首趟的删除语义（见 §C-⑧） | `J-TRANSCRIBE edits=6 append=1`＋`J-VERIFY-GREEN touched=8 files=2 issues=0`；§J 后回归：qgate 仍 `QUOTE-GATE-GREEN 92/92/0`、s187 `S187-CITEDPATH GREEN 已核=45 缺=0 省略=6`、verbatim 面 `code_hits=27 doc_hits=27 expect=27`、离线面全套 `GATES_EXIT=0` | `s216`（首趟红：面数派生切片取空⇒0，零写入拒红）／`s216b`／`s217`+`s217b`（缺陷态取证＋还原）／`s218`／`s219`／`s220`~`s223` |

三处 R76 作废点名按 §J 逐字挂上（§E-3.1 由 R77 §E-2 取代／§F-2.1「s166 转正接门禁」由 R77 §F-2 取代／§C-2.1「一处改动」由 R77 §C 取代），⛔ 进 R76 正文；R76 裁定件本体一行未动。

## §C 请裁八格

### ① taut 行数账：裁语「432」⇄盘上 434

- 现象：R77 §B-2.4 写「`_tools/spr38_tautology_sweep.py` 429→432（净 +3 行）」，而 §B-2.1＋§B-2.2 自己给出的插码块数出来是五行 ⇒ 按裁语逐字插码后盘上＝**434**（`wc -l` 口径，现算 `46267f0c8a`）。
- 我的处置：⛔ 删裁定文本凑数、⛔ 改插码块凑 432；按逐字插码落地，2 行差在 `s200_r77_b_taut_gate1.txt` 申报，§J 转录句按盘上真值 434 写并带该凭据号。
- 请裁口子：这条账要不要在 R77 追加栏（append-only，⛔ 改 §B-2.4 原句）订正为 434，或由 R78 直接声明「§B-2.4 的行数口径作废、以盘上现算为准」。**数值口径类，编程侧⛔ 自裁。**

### ② r8 常量派生：§C-3.1 一句里 800 与 802 两个期望终态

- 现象：裁语同一句既写「净 +2 行 ⇒ 800」又写「802＝798+2＋P2b 净增 2」，而派生栅栏自己数是 2→7 行 ⇒ 机械真值 **803**（现算 `b1bbf96d0e`／803）。
- 我的处置：按逐字栅栏落地，差 3／1 行如实申报（`s201_r77_c4_const_derive2.txt` 的 DEV 行），⛔ 删栅栏行去凑 800/802。
- 请裁口子：与①同族（裁语内部两数互斥）。请圈定哪个作废；圈定前 r8 的 C15b／C15e 类「申报数⇄盘上」格一律按盘上 803 走。

### ③ churn（V-H #6）改前树跑新立两面＝结构性红

- 现象：churn 要在**改前工作树**里跑同一份 gates 再逐字比。本轮新立的两面在改前树必然红：PD 面 `应解析=0`（改前树没有 `_pd_assert` 站点）、qgate 面 `DOC 缺失`／一手行=0（改前树的交付件没有本轮引文）。同时 churn 侧的 CHK 面清单仍写死 5 个名字（fp/quota/taut/verbatim/clause），**不含**本轮的 `spr38_g_chk_pd`／`spr38_g_chk_qgate` ⇒ 新面根本没参与改前／改后对账。
- 后果：churn 的「三面同源自比」形状（R76 §B／R77 §B 修的那个）在新面上是空的；而一旦把新名加进清单，改前树红又会被读成「改后引入的回归」。
- 请裁口子（选一）：**甲**＝新立面在改前树的期望另立（如 `应解析=0`/`DOC 缺失` 视为「新面首跑代次」合法终态，登记后不参与 churn 逐字比）；**乙**＝churn 的 CHK 名单由盘上 gates `for spec` 循环现读派生（与 `spr38_r29_extract.py` 同源），改前树期望值按代次表给出；**丙**＝本轮不动，等 #108 窗内一次性把新面的改前基线取真。
- 编程侧倾向：乙（派生制），但名单形状与「什么算合法终态」属判据面 ⇒ **⛔ 我自施工**。

### ④ gates.sh 换代连带三面红（C7b／C15a／C15e）

- 事实：本轮两次编辑 `_tools/spr38_gates.sh`（130→133 加 PD 面，133→135 加 qgate 面），现算 `53ed5cee95`／135 行。`R8-VERIFY` 由 `ok=51 red=4` 变 `ok=49 red=6`：
  - `C7b 盘上 gates.sh==产物`：产物 `e0115414`/130 ⇄ 盘上 `53ed5cee`/135 ⇒ 只能由**独占窗内登记链复跑**刷新登记产物清除（task #108）。
  - `C13 时间面`：census／falsify／fixture 登记产物早于本轮生产件（taut 等）⇒ 同属窗内登记轮。
  - `C10a`／`C10a2`：`player.gd` 盘上 `31bafa6a…` ⇄ 绿件 `037f261d…`（锁=False，非本轮引入）⇒ 同样等窗内登记。
  - `C15a 续记申报数⇄R8 件重算`／`C15e 订正节申报数⇄盘上件重算`：`_tools/AUTORUN_LEDGER.md` 的 R8 续记节 verbatim 声明「96→130 行／行数=130（wc 口径）」，而该面的期望值由**盘上现算**给出（⇒ 135），两格同时见红。
- 我认为这里有一条 r8_verify 自身的口径缺陷：件内注释立的是「两节各自对着**它自己引用的那组产物**重算：⛔ 拿 R8 的件去验 R9 的数」，但 `claims_for()` 对 s8（历史节）也用盘上 `f["gates_lines"]` ⇒ 只要 gates 换代，历史申报节必然脱钩，C15a 变成「盘上一动就红」的格。
- 请裁口子：**甲**＝C15a 的 s8 基线改指 R8 登记产物（历史节对历史件，符合件内注释）；**乙**＝编程侧 append 一节「### R77 订正与终态」把 135 现值入册（只清 C15e，C15a 仍随盘上漂）；**丙**＝三面红统一挂账到 #108 窗内登记轮，本轮⛔ 碰 `_tools/AUTORUN_LEDGER.md`。
- 本轮我按**丙**执行：`_tools/AUTORUN_LEDGER.md` 零改动（append 新节会改变 `m9` 节序与对账面，属判据面，⛔ 我自便）。

### ⑤ §B-3.2「不可达脚本」闸与 MSYS 混合分隔符（本窗第三次）

- 现象：把 `../spr41_r77/x.json` 这类**混合分隔符相对段**当路径喂进去，`os.path.join(T, "../x")` 形状在 Windows/MSYS 下 `isfile()` 返回 False／`open()` FileNotFoundError——同一坑本轮第三次复现（前两次：`isfile` 假阴、`rd()` 静默 None）。
- 证据：`s214c_r77_f22_extract_abort_cause1.txt`（把 abort 成因定死到那一个 `open()` 调用）；`s214_r77_f22_extract_teeth1.txt` 保留的是我这次误用路径导致的**两态同 rc=2**，不是判据的牙。
- 请裁口子：修法归哪一层——**甲**＝AGENTS §7 增一条「跨目录相对路径一律先 `os.path.normpath`」并给刀内自检臂；**乙**＝只在受影响刀内局部 normpath；**丙**＝维持现状、由 §B-3.2 的「不可达脚本即 MISSING」闸继续兜（现在就是它把红报出来的）。

### ⑥ `--selftest` 面 SELFTEST-BLOCK

- 现象：selftest 的期望格里有格落在作者保留五类（数值口径／放行），编程侧跑它只能得 BLOCK，不能得绿。
- 现状：本轮⛔ 用 BLOCK 当阴性结论，也未为消 BLOCK 去改期望；`s201_r77_c3_selftest1.txt` 留盘。
- 请裁口子：要请主理人复核时开那一趟（task #106/#108 同性质），或裁「BLOCK 格在 gates 面记豁免＋代次」的写法。

### ⑦ P2b padding 空操作

- 现象：§C-3 落地单的 P2b 是一条 padding 编辑（串未变⇒replace 空操作），若照它写会静默不生效；候选是把锚串改成 `bw.group(0)` 现读形状。
- 证据：`s201_r77_c3_const_derive2.txt` 首行 SIM 提示「目标串出现=%d（应 1）⇒ replace 可能空转」，该提示本身在写盘刀里是 `%d` 未渲染的字面串（我留了原样当历史证据，⛔ 回头抹）。
- 请裁口子：P2b 要不要转正（改逐字裁语），或由 R78 声明该条作废、以 `bw.group(0)` 现读派生替代。

### ⑧ 证据卫生自曝两件（编程侧自己的违规，如实入账）

1. **s214 两份 stdout 先删后读**：extract 两向首趟两态同 rc=2，我在读原因之前 `rm -f` 了那两份 stdout——正是交付件 §5 P-9 立过的「失败态证件被原地覆盖」同族。补救：不复用旧件、以同一造错**重新复现**并把成因落 `s214c_r77_f22_extract_abort_cause1.txt`，两向牙口在 `s214d_r77_f22_extract_teeth2.txt` 重取（状态 A `CHAIN-CLEAN=yes` rc=0／状态 B `chk3-count=4(want=5)` rc=1）。被删的两份 stdout 无法复原，如实报此空缺。
2. **§J 写盘刀首趟用替换语义吞掉末列**：`s211` 的六处「同行追加」把锚串尾部的 ` | §5 P-x …`／` |` 连同末列指针一起替换掉了。交付件行数与格数没变到肉眼可见，但**末列文字丢了**。复核刀 `s211b` 的 TABLE-CELLS 闸当场抓住（6→5／5→4 共 6 格，`s217_r77_j_verify1.txt`），损坏态 diff 留盘 `s217b_r77_j_cell_drop_diff1.txt`，随后从时间戳备份 `_backup/spr41_r77_j/20261120T091242Z/` 逐字还原（还原后 md5 与备份全等：交付件 `565c8dadc9…`、台账 `fb2c9004ec…`），写盘刀改为「锚串与追加句的最长公共前缀末端插入＋改后行去句必须逐字回到改前行」的结构闸后重跑（`s218`/`s219`）。
3. 另：台账「轮 20」行内一处凭据号笔误（把 f22 的 extract 两向件写成 `s212*`，实为 `s214*`）按 append-only 在新行订正，⛔ 回改该行。

## §D 停等清单（谁能解）

| 项 | 谁能解 | 现状 |
|---|---|---|
| task #108 独占窗复跑登记链（清 C7b／C13／C10a／C10a2；也是 churn 新面改前基线唯一正解） | 作者放行（保留五类之「放行／发布」） | 编程侧⛔ 起链；窗未开 |
| ①② 的行数账与 568／83／803 口径 | 作者（数值口径）或主理人 R78 裁语 | 盘上现值为准，差数已申报 |
| ③ churn 新面期望形状 | 主理人（判据面） | 三选一待圈 |
| ④ C15a 对账基线口径 | 主理人（判据面） | 甲／乙／丙待圈，本轮按丙零改动 |
| ⑤ normpath 修法归层 | 主理人＋AGENTS（作者 §12 口径） | 甲／乙／丙待圈 |
| ⑥ selftest BLOCK 格 | 主理人复核要求时开 | 不当阴性结论 |
| ⑦ P2b 转正或作废 | 主理人（逐字裁语） | 待裁 |
| R76 遗留三格（#112／#115／#106） | R77 已重裁 ⇒ 由主理人在 R78 点名为作废或改写归属 | 我侧不再单独施工 |

## §E 引用清单与边界自证

1. 本窗现读（md5 前缀／`wc -l`）：R77 `8944d56310`/238｜交付件改前 `565c8dadc9`/355→改后 `1a762f592b`/355｜台账 `fb2c9004ec`/221→`66bb282cbd`/222｜gates `53ed5cee95`/135｜r8_verify `b1bbf96d0e`/803｜taut `46267f0c8a`/434｜引文门禁刀 `0d6824227e`/296｜PD 刀 `30c37421c3`/312｜s168 牙口刀 `d8b3cc7d83`/138｜extract `0cdd269f4e`/245｜§J 写盘刀 `0651fff175`/209｜§J 复核刀 `4578a5c48d`/100。其余引用一律以现场 `md5sum`＋`wc -l` 为准。
2. 边界自证：本轮写盘＝`_tools/spr41_r77/` 下刀件与证件、`_tools/spr38_tautology_sweep.py`（§B 裁语插码）、`_tools/spr38_r8_verify.py`（§C-3）、`_tools/spr41_pd_selfconsistency_check.py`／`_tools/spr41_deliverable_quote_gate.py`／`_tools/spr38_gates.sh`（新立＋接线）、`_tools/spr40_b/s168_s41_quote_audit_falsify.py`（§F-2.2.3 三针换靶）、交付件六处同行追加＋台账一行 append、本单。**实仓 `scripts/*.gd` 零改、`_tools/AUTORUN_LEDGER.md` 零改、git 零写、未刷 `production/sprint-21/SPR21-FROZEN.md5`、未进 `D:\大纲`、⛔ 起链（本轮只跑离线面与 gates 全套，链锁未被占用）**；造错全部在沙箱副本（`_tools/spr41_a2/s41_quote_falsify/`）。
3. 本单自身指纹⛔ 落文本（R70 §Jⓐ 口径延续）；真值由后续台账 append 行外部见证代记。⛔ 回改 R60…R77 任何既有正文。
