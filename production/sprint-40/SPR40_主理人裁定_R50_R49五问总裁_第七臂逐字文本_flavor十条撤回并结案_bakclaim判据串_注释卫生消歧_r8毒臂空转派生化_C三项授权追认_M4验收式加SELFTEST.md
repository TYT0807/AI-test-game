# SPR40 主理人裁定 R50｜R49 五问总裁（第 7 臂逐字文本／flavor 十条撤回并结案／bak_archive 判据串与两态文案／注释卫生消歧／r8 毒臂空转按 (α) 派生化）＋ §C 三项授权追认 ＋ M4 验收式加一条 SELFTEST

性质：**裁定件**。本窗 ⛔ 改任何判据件／链件／`.gd`／冻结表／AGENTS，⛔ 起链，⛔ commit/push；**只新建本件一份**。
编号自证：`cd /d/Create/Game/test-1/production/sprint-40 && ls | grep -oE "_R[0-9]+_" | sort -u` ＝ R1–R21、R36–**R49** 在盘、**R50 空** ⇒ 本件取 R50。
取证纪律（按本窗令执行）：源件只读 R49 一份；锚点复现命令 **20 条**（§A-0 列 18 个编号条目＋末条目录清点＋收尾 `git status --porcelain` 写盘面自证，逐条可照跑）；⛔ 重跑 EV／r8／selfaudit 判据件本体——编程侧 13:2x 已跑并留证（EV `issues=1 checks=9`、r8 `checks=52 ok=50 red=2`、`--falsify` rc=0、`--selftest` 报 `SELFTEST-BLOCK`），本窗全盘吸收为事实底。

---

## §A-0 本窗实跑的锚点复现命令（编号 18 条＋目录清点 1 条＋写盘面自证 1 条＝共 20 条，全部现跑、逐条可照跑）

| # | 命令（工作目录 `/d/Create/Game/test-1`） | 现读所得 |
|---|---|---|
| 1 | `ls production/sprint-40/ \| grep -oE "_R[0-9]+_" \| sort -u` | R50 空闲 |
| 2 | `sed -n '248,262p' _tools/spr38_run.sh \| cat -n` | 六臂 `teeth` 调用块与两段注释的位置关系 |
| 3 | `grep -n "件牙口" _tools/AUTORUN_值守报告.md` | **7 处声称站点**＝:175/:192/:211/:215/:220/:293×2（:42 是 HP-14 元规则句、无「N 件牙口」形状，不计站点） |
| 4 | `sed -n '140,162p' _tools/spr38_evidence_verify.py` | `teeth_log_of()` 定义起于 **:141**、`rd()` 起于 **:156**、缺件 `return None` 在 **:159** |
| 5 | `sed -n '594,601p' _tools/spr38_r8_verify.py` | `poison()` 定义 :594；`P1` :597、`P2` :598、`P2b` :599、`P3` :600 |
| 6 | `sed -n '231,235p;211,215p;571,575p' _tools/spr38_r8_verify.py` | :233 印死门牌串；:213 docstring 档位只有 `ok\|red\|na`；:573 `ok=%d` 是 `len(res)-len(red)-len(na)` 减法算出 |
| 7 | `sed -n '4761,4765p' scripts/game_main.gd` | `const _ML_DECLARED := 94` 在 **:4763** |
| 8 | `cat _tools/spr38_g_chk_taut.txt`（末两行区） | 当代 FRESH 汇总行逐字 `合计 应解析=568 实解析=568 可疑(T1+T2+T3)=0` |
| 9 | `ls -la _tools/spr40_promote_audit.log` | **MISSING** ⇒ R16 §C-2 第 2 层点名的这个文件盘上不存在（见 §B-Q3） |
| 10 | `sed -n '74,96p' production/sprint-40/SPR40_主理人裁定_R16_…牙口臂….md` | G-A／G-B 两条判据的逐字 bash 形状 |
| 11 | `sed -n '30,60p' production/sprint-40/SPR40_主理人裁定_R14_….md` | B1–B10 权威文本表（含长度与「盘上是否也要动」） |
| 12 | `grep -n "高压层\|熔潮。修罗嗔火" scripts/data.gd` | `data.gd:383`＝R14 B1 合并句、`data.gd:387`＝R14 B2「虫更快…残响也多」⇒ **盘上正典已是 R14 版** |
| 13 | `sed -n '596,600p' _tools/spr38_r8_verify.py; sed -n '233p' …` ＋ `tail -12 _tools/spr40_b/s27_r8_poison_noop_audit.txt` | 复算件自报 `空转毒臂数=2`、`:233 同源=False` |
| 14 | `sed -n '40,56p;236,250p' _tools/spr38_report_selfaudit.py` | `TOOTH_ARMS` :44（6 条）、`TOOTH_SITES` :54＝{AUTORUN 7, B1 0}；:236 `n_call = len(re.findall(r"^teeth ", script_txt, re.M))`；:241 只在 `live`（活链）时查脚本行数↔表臂数 |
| 15 | `grep -n "FLAVOR" scripts/game_main.gd; grep -n "func _ml_assert" scripts/game_main.gd` | `game_main.gd` FLAVOR 只读两处（:3062/:3076）；`_ml_assert` 定义在 **:4777** |
| 16 | `sed -n '4765,4800p' scripts/game_main.gd` | `_ml_assert(ok, nn, measured, expect)` 体：`_ml_checked += 1` → `Dev.check` → `[SMOKE-MELEE] #%02d …` |
| 17 | `sed -n '508,516p' _tools/spr38_evidence_verify.py; grep -n "94" _tools/AUTORUN_值守报告.md` | EV 反证末行是 `states=%d` **现算**（非硬编码态数）；AUTORUN 半角 `94` 命中 16 行（其中真声称 94 的是 :16/:56/:232/:233/:300） |
| 18 | `grep -n -- "--in-chain-as=证据重算活链" _tools/spr38_run.sh` ＋ `grep -n "再以「缺链上内容断言」为由开新探针" production/sprint-40/SPR40_主理人裁定_R21_M3残件EXPECT_FROZEN归属窗与tips第三件套及churn基线纪律.md` | run.sh 插入锚串**唯一命中**；R21 生效口径句坐实在 :56（供 §B-Q1(a)、§B-Q2 第 3 条引用） |

---

## §B-Q1 编译面第 7 件牙口臂（事项 6）——三小问全裁

### (a) `spr38_run.sh` 那一行的逐字文本与插入位置

**生效文本（整包照抄，注释在上、调用在下）**：

```sh
# 第 7 臂（主理人 R50 §B-Q1｜R16 §C-2 第 3 层的落链条）：晋升前编译面闸在链内现跑现判——它不起 Godot，
# 只读盘上 spr38_g_*.log 全集逐份过 G-A/G-B（R16 §C-1 逐字）。⛔ 把它插进前五臂那一块中间：
# 那两块之间的注释写的是「三指纹比对那一臂的判定串＝末行」的口径，位置即语义，新臂一律追加在末位。
teeth 编译面逐档       "COMPILE-ARM GREEN"    python _tools/spr40_compile_arm.py
```

**插入位置（描述＋锚串，不给裸行号）**：紧接在这一行**之后**、且在下一行 `# 活链声明（第 6 臂的配套｜R9 §B(b′) 改序：本块已搬到第 6 步全部 teeth 调用之后）：文档面在本步看到的是**本轮**的牙口承载件，` **之前**：

```
teeth 证据重算活链     "EVIDENCE-VERIFY-INCHAIN ok" python _tools/spr38_evidence_verify.py --in-chain-as=证据重算活链
```

复现：`grep -n -- "--in-chain-as=证据重算活链" _tools/spr38_run.sh` ＝ **唯一命中**（该行为块内第 14 行，`sed -n '248,262p' _tools/spr38_run.sh | cat -n` 同读）。

命令形态：**不带参**（`python _tools/spr40_compile_arm.py`）。理由：`selfaudit:236` 用 `^teeth ` 数脚本行数、`:249` 用 `sched[a][1]` 比**判定串**，参数不进比对；而 glob 口径必须锁死在件内（见 (b)），⛔ 靠调用点传参决定读哪批日志。

标签名裁 `编译面逐档`（四字＋「逐档」点明它是逐份日志判）。⛔ 用 `gates 编译面`——R16 §C-2 原文那个名字会撞 `TEETH_ARMS` 里既有的 `回写件十一态` 一类「承载件语义」，且 gates 槽位已被门禁占用。

### (b) 承载件 `_tools/spr40_compile_arm.py` 的末行语义与失败态

**末行语义约束（硬）**：GREEN 态**有且只有末行这一条打点参与认件**，其末行逐字＝`COMPILE-ARM GREEN`。依据不是"多写一行就崩"，而是两处认件口径同时吃末行：

- EV `teeth_log_of()`（定义起于 :141，复现命令 §A-0 #4）：`for p in sorted(glob(.../_tools/spr38_run.teeth*.txt))` → 取 `lines[-1]` → `if sentinel in tail and arm_name in tail`。**glob 只扫 `_tools/spr38_run.teeth*.txt`** ⇒ ①承载件必须由 `teeth()` 自己产在那批文件里，本件 ⛔ 另立日志文件指望被认到；②**臂名必须出现在末行**——判定串里没有臂名，所以只有 `teeth()` 打的 `RUN 牙口 <名> ok |<末行>|` 那一行才带名字，本件的 GREEN 行 ⛔ 出现 `编译面逐档` 之外的牙口字样，也 ⛔ 让末行之后再补任何非空行（尾随空行由 `if x.strip()` 滤掉，允许）。
- `selfaudit` 的 `TOOTH_ARMS` 条目哨兵逐字＝`COMPILE-ARM GREEN`，`:249` 的 `unsync` 比的就是这张表的串 ↔ 脚本行里的串。

**失败态（逐字）**：

```
COMPILE-ARM RED <file> <G-A|G-B> <detail>
```

- `<file>`＝相对仓库根的正斜杠路径（如 `_tools/spr38_k3.log`）；`<G-A|G-B>`＝哪一个条件咬的；`<detail>`＝`Could not resolve class=N` 或 `validate problems=0 absent`。
- **首条不满足即 `exit 2`**（对齐 R16 §C-1 的 `PROMOTE-BLOCK … exit 2` 与 run.sh 文档面 `exit 2` 的先例）。⛔ 打满 12 行红再退——链的 `RUN 牙口 <名> …` 行会把末行进 RUN-GREEN 面，红态越短越好判。
- 判据集合口径：`sorted(glob("_tools/spr38_g_*.log"))` **全集**，⛔ 白名单挑几份好看的（＝前提守卫型同族）。盘上反例现成：`spr38_k3..k10.log` 每份 `Could not resolve class` 命中 190、`[SMOKE] validate problems=` 命中 0（R16 §C-1 判别力实测表，复现命令 §A-0 #10）。

### (c) 站点数裁定：**值 6→7，`TOOTH_SITES` 留 7，⛔ 新增描述句**

裁 (i)。三条理由，均可证伪：

1. `TOOTH_SITES` 的注释自己写了加站的门槛：`11-18 A24-4：报告 §8.15 第⑤档把 STEP=all 链终端行逐字转录进正文 ⇒ 多一处链自己写的『6 件』声称，站点 6→7 同轮换掉（⛔ 改引文字形压站数／⛔ 让表静默过期）。每处的值仍＝盘上臂数。`（复现：`sed -n '40,56p' _tools/spr38_report_selfaudit.py`）——那次加站是因为**盘上事实多出一处转录**，不是因为想多说一句。M4 没有新的链终端行转录需求，凭空加一句「7 件牙口」就是把站点当修辞位。
2.  AUTORUN :293 那行本来就把臂数披露成双（表格格内「现值＝6 件牙口」＋同行「现读 6 行 `teeth` 调用」），M4 落地窗把这两处值改成 7 即可，**读者拿得到的信息量不减**。
3. 新增句子是**长期负债**：HP-14（AUTORUN :42）已把「历史转录里有数字形状」定成转正典，多一处数字形状就多一次换代义务，收益为零。

施工口径（M4 落地窗照做，⛔ 先改文档再落字，守 `selfaudit:42-43`）：
- `TOOTH_ARMS` 追加 `("编译面逐档", "COMPILE-ARM GREEN")`（6→7 条）；
- `TOOTH_SITES` **不动**（`{"AUTORUN_值守报告.md": 7, "SPR38_交付_B1_非弹幕近战内核.md": 0}`）；
- AUTORUN 那 **7 处**声称的值 6→7（站点定位见 §A-0 #3 的 `grep -n "件牙口"` 输出；:293 同一行两处都要改，漏一处就是精确相等闸当场红）。
- ⚠️ 结构提示（不改口径）：`selfaudit:241` 的行数↔臂数比对只在 `live` 分支跑 ⇒ 离线严格面**抓不到**「脚本加了臂、表没加」这一半，M4 只能靠活链面兜住。如实登记，不在本单修它（那是判据面手术，需另裁）。

---

## §B-Q2 flavor 十条（事项 8）——裁 **(ii) 撤下此项**，M4 车由九件减为八件

### 为什么撤（三条，均可证伪；R16 §F-1 的归属论证本身没错，错在它没预见成本）

1. **十条要钉的东西，盘上已经被两道零成本的面钉住了**：`data.gd:383`/`:387` 现读逐字等于 R14 §B 权威表 B1/B2（复现：`grep -n "高压层\|熔潮。修罗嗔火" scripts/data.gd`，§A-0 #12），而 R21 §B 已把 `production/sprint-39/SPR39_flavor_contract.py` 定为 tips/FLAVOR 的登记三件套第③件（G-3 双向逐字漂移／G-4 禁用串／G-5 机制落点三面，覆盖 74 键全量，覆盖面严格大于十条单点）。再加十条＝把已有全量比对复制成一份抽样副本，正是 R16 §F-1 第③条自己禁止的「oracle 两份」。
2. **代价不对称**：`_ML_DECLARED` 94→104 会牵动 AUTORUN＋B1 两份文档 **26 行**半角 `94` 声称（R49 §B-Q2 现读数），四元组 `done checked=94 declared=94 swings_total=57 draws_total=57` 同步改写，且**每条 `_ml_assert` 都是 `chk_taut` 普查的一个分母单位**（`_ml_assert` 定义 :4777，体内 `_ml_checked += 1`，复现 §A-0 #14/#16）⇒ 应解析/实解析从 568 涨到 578，连带 §B-Q5 刚修完的投毒臂基准、`DECL_OLD` 表、T3B 记账一起换代。为一个已被全量门覆盖的断言付这笔账，不值。
3. **两句确实互斥，必须有一句让位**：R21 §B 生效口径末句的原话是「⛔ 再以『缺链上内容断言』为由开新探针」（复现：`grep -n "再以「缺链上内容断言」为由开新探针" production/sprint-40/SPR40_主理人裁定_R21_M3残件EXPECT_FROZEN归属窗与tips第三件套及churn基线纪律.md` ＝唯一命中 :56；该块全文另见 `sed -n '44,58p' …`）。十条实值断言正是「以缺链上内容断言为由」往链上探针加内容级断言。R21 晚于 R16 且是**专门针对第三件套**做的裁决，故 R21 作准、R16 §F-1 作废（作废理由：它给的是范式与挂账，未预见普查分母连锁，属结论前提变化，⛔ 说它当初判错）。

### 结案措辞（追加式，供 M4 文档面登记照抄；只追加、⛔ 回改既有行）

```
【R50 §B-Q2 结案】R16 §F-1「tips 十条实值断言（game_main.gd flavor 段，_ML_DECLARED 94→104）」**作废**，
作废理由：tips/FLAVOR 的可见效果已由 R21 §B 指定的离线门 SPR39_flavor_contract.py（G-3/G-4/G-5，74 键全量
双向逐字）认领为登记三件套第③件；再上十条＝把全量比对复制成抽样副本，撞 R16 §F-1 自身第③条
「⛔ oracle 两份」，且每条 _ml_assert 都是 chk_taut 普查的一个分母单位（568→578），连带 DECL_OLD／
T3B 记账／投毒臂基准换代——收益配不上成本。const _ML_DECLARED := 94（scripts/game_main.gd:4763）**维持原值**，
M4 ⛔ 动它，⛔ 以「缺链上内容断言」为由再开此项。若将来某条 FLAVOR 文本出现「离线门绿而游戏内显示不对」
的实证缺陷，凭该实证另立一项，届时再谈 94→104。
```

### 波及面处置（既然选 (ii)，`94` 一行都不改）

- **活声称**（本应随换代改的那些）：本次**零改动**——`_ML_DECLARED` 不动 ⇒ :16/:56/:232/:300 那几处 `done checked=94 declared=94` 与 :233 的四元组对账行**继续作准**。
- **历史转录**：AUTORUN/B1 全部 26 行（R49 §B-Q2 已逐行列出）**原样不动**，理由同上（没有换代就没有义务）。
- 这条裁定的副作用请一并登记：M4 一车因此**少一件**，`_ML_DECLARED`／`chk_taut` 分母／`DECL_OLD` 三处 ⛔ 出现在 M4 手术清单里。

---

## §B-Q3 `bak_archive_check` 扩展（事项 7）——判据串、两态文案、抽取形状、falsify 四问全给

### 先纠一处盘上事实（影响判据源选择）

R16 §C-2 第 2 层写的「判据源必须是盘上证据文件（如 `_tools/spr40_promote_audit.log` 的 G-A/G-B 复核）」——**该文件盘上不存在**（复现：`ls -la _tools/spr40_promote_audit.log` → MISSING，§A-0 #9）。盘上真实存在的晋升证据是 `_tools/spr40_b/w2_promote.out`（晋升脚本自己的 stdout 转录）与 `_tools/spr38_g_*.log`（构建日志本体）。⇒ 本裁定改为**双源**，且优先级明确：

1. **首选（强证据）**：现役 `.bak` 的 md5 是否**至少被一次合格构建认领过**——即在 `sorted(glob("_tools/spr38_g_*.log"))` 中存在一份日志，其 `Could not resolve class` 计数为 0 **且** `[SMOKE] validate problems=0` 在场（＝G-A∧G-B，逐字口径见 R16 §C-1，`grep -a -c` / `grep -a -q`）。认领关系由 `_tools/spr40_promote_audit.log` **一旦产出即以其为权威**（见下面「审计件生成义务」），当前无该件 ⇒ 走下面的降级态。
2. **次选（弱证据，仅作披露不作判绿）**：`_tools/spr40_b/w2_promote.out` 里 `PROMOTE-GREEN 现役绿件已转正 <md5>` 行的 md5 == 现役 `.bak` md5。
3. **降级态（诚实的 UNEXECUTED，⛔ 记阴性）**：两源都拿不到 ⇒ 打 `BAK-CLAIM UNEXECUTED`，rc=0，并在面上写明缺哪个件。这是 R16 那句「盘上证据文件」在当前盘上的唯一诚实解，⛔ 为了凑 GREEN 去放宽 G-B。

**审计件生成义务（新增，归 M4 落地窗）**：`_tools/spr40_promote_good.sh` 每次成功晋升须把 G-A/G-B 的复核结果逐字 append 进 `_tools/spr40_promote_audit.log`，行形状 `PROMOTE-AUDIT <md5[:8]> <log_path> G-A=<count> G-B=<present|absent>`；有了它，上面第 1 源才从「推断」升级为「台账」。

### 判定串与两态文案（逐字，可直接抄）

```
GREEN： BAK-CLAIM ok 现役 .bak 被 N 份合格构建认领（G-A=0 ∧ G-B 在场）｜ 来源=spr38_g_*.log
RED ： BAK-CLAIM RED 现役 .bak md5=<md5> 无任何合格构建认领 ｜ 最新候选=<file> <G-A|G-B> <detail>
```

- 判定串（进登记表的那一列）＝ **`BAK-CLAIM ok`**（子串形状，兼容 `teeth_log_of()` 的 `sentinel in tail` 与 `selfaudit` 的串比对）。
- `N` ＝认领它的合格日志份数（现算，⛔ 印死）。
- RED 行**必须自带 `<file>`**，否则红态不可归因（与 §B-Q1(b) 同构）。
- UNEXECUTED 行逐字＝`BAK-CLAIM UNEXECUTED 晋升台账与构建认领两源皆缺（缺 _tools/spr40_promote_audit.log）⇒ 不作阴性`。

### 要不要进 `do_falsify()`：**要**，但**不需要同步任何态数文案**

- 造错态取 **1 个**：`SPR38_BAK_ROOT` 沙箱内把现役 `.bak` 追加一字节（md5 变 ⇒ 不再被任何合格构建认领）⇒ 期望 `BAK-CLAIM RED` 命中 ∧ rc≠0 ∧ 正对照绿。这正好落在 `bak_archive_check.py` 已有的 `BAKGATE-FALSIFY` 五态机器里（复现：`grep -n "print\|exit\|BAK" _tools/spr38_bak_archive_check.py` 命中 :118/:120/:126/:128/:181/:183），⇒ 该件末行由 `BAKGATE-FALSIFY ok 五态全非绿＋正对照绿…` 改为 `BAKGATE-FALSIFY ok 六态全非绿＋正对照绿…`（**这句是唯一要改的态数构成文本**，宿主＝`spr38_bak_archive_check.py` 自己，改谁归谁：M4 落地窗）。
- **EV 侧 ⛔ 动**：`do_falsify()` 的末行是 `"EVFALSIFY VERDICT=ALL_DETECTED states=%d（…）" % (len(states), …)`——态数是 `len(states)` **现算**的（复现：`sed -n '508,516p' _tools/spr38_evidence_verify.py`，§A-0 #17）。R49 §B-Q3 担心的「末行 `FALSIFY ok N 态…文档面 8＋空面 1＋牙口对面 6` 的构成同步」在盘上**不是一个硬编码常数**，⛔ 为此改 EV。若落地时发现某份**文档**把 EV 态数抄成死数，那是文档面站点，按 HP-14 处理，⛔ 反过来迁就文档。

---

## §B-Q4 「run.sh 注释卫生」（事项 9）消歧——指 **①M1.5′ 四处孤儿注释包**

- 裁：R48 §E-4-5 列表末项那件＝**M1.5′ 遗留的四处孤儿注释包**（已登记＝task #64），即「注释还在、它所解释的代码已被替换或删除」那一类卫生债。M4 处置＝逐处现读后**要么补回它现在指的代码的一句说明、要么删注释**，⛔ 保留指向不存在事物的注释。四处由落地窗 `grep -n "^#" _tools/spr38_run.sh` 对着上下文现数，⛔ 在本件预填行号（行号是会烂的引用）。
- ⛔ 指②：R45 §E-4 的 `run.sh:116` 四字 `(上一代)` 披露，R48 §E-4-4 已明令**顺延到收官后**，不属于 M4；把它拉回 M4 会同时违反那条顺延。
- 若另有第三种理解（例如「注释里不许出现死数」）：盘上无此登记，本件不予采纳；落地窗若发现新证据按 R49 的呈请格式回报，⛔ 自行扩大范围。

---

## §B-Q5 🔴 新缺陷立案：r8 投毒臂 `P1`/`P2b` 对当代 census 空转——裁 **(α) 派生化**

### 立案

- 缺陷名：**r8 投毒臂死串腐烂（P1/P2b 空转）**。类别：判据件自身的「会腐烂的常数」，与 HP-9 同族。
- 盘上事实（本窗只核形状，不复算数值；复算件由编程侧现产）：`P1` 的 replace 目标是 `合计 应解析=564`、`P2b` 的目标是 `合计 应解析=564 实解析=564`（复现：`sed -n '594,601p' _tools/spr38_r8_verify.py`，§A-0 #5/#13），而当代 FRESH 件 `_tools/spr38_g_chk_taut.txt` 汇总行逐字＝`合计 应解析=568 实解析=568 可疑(T1+T2+T3)=0`（复现：`cat _tools/spr38_g_chk_taut.txt`，§A-0 #8）⇒ 命中 0 次＝**replace 空转**；证件 `_tools/spr40_b/s27_r8_poison_noop_audit.txt` 自报 `空转毒臂数=2`。
- 今天为何不可见：`--selftest` 现跑停在 `SELFTEST-BLOCK 正对照就有判红的格 ⇒ 先修正面，⛔ 谈牙口`，基准红＝`C10a`／`C12 census`，投毒面根本没轮到。
- 后果：M4 §C-2/§C-3 落地解封 SELFTEST 后，这两臂会立刻报「没抓到」，届时极易被误读成 M4 手术做坏了。

### (α) 生效文本（宿主仍是 `_tools/spr38_r8_verify.py`；两臂整行替换，⛔ 手抄数字）

```python
    # 毒臂目标串⛔ 写死数字：11-19 R50 §B-Q5 前这里印的是「合计 应解析=564」，而盘上 FRESH 件早已是 568
    # ⇒ replace 空转、臂自我感觉有牙。改从件内现算派生（HP-9 同族修法：⛔ 会腐烂的常数进判据）。
    _tot_want = re.search(r"合计 应解析=(\d+)", c["census"] or "")
    poison("P1 汇总面求和被改坏", "C1c", lambda c, f: c.__setitem__("census", (c["census"] or "").replace(
        "合计 应解析=%s" % re.search(r"合计 应解析=(\d+)", c["census"] or "").group(1),
        "合计 应解析=%d" % (int(re.search(r"合计 应解析=(\d+)", c["census"] or "").group(1)) - 1))))
    poison("P2b macro 块被并入汇总行（tr 类抽取坑）", "C1a", lambda c, f: c.__setitem__("census", (c["census"] or "").replace(
        "合计 应解析=%s 实解析=%s" % (re.search(r"合计 应解析=(\d+)", c["census"] or "").group(1),
                                     re.search(r"合计 .*? 实解析=(\d+)", c["census"] or "").group(1)),
        "macro=x 应解析=1 实解析=1", 1)))
```

落地窗若嫌重复抽，可在 `poison` 调用前统一取一次 `w/g` 再格式化进 lambda（闭包捕获即可），语义等价；**唯一硬要求**：`P1`/`P2b` 的字面目标串 ⛔ 再出现任何阿拉伯数字常数。

**派生表达式取值域（防"从被毒对象自己抽"的空集陷阱）**：抽取必须在 `c["census"]` 被改写**之前**完成（lambda 内的 `re.search` 读的就是当时值，`replace` 在同一表达式里先算右值后写入，成立）；若件内正则匹配不到（census 形状变了），两臂须**显式抛错转红**而不是静默 no-op——生效口径：`assert _tot_want, "R50 §B-Q5 P1 派生失败：census 无『合计 应解析=』形状"` 放臂前。

### `:233` 判据消息里印死的门牌串：**同轮换现算**（裁「换」）

现读该行逐字含 `"…｜ 门牌=应解析=564 实解析=564"`（复现：`sed -n '233p' _tools/spr38_r8_verify.py`，§A-0 #6）。它不影响判定、只影响可读性，但它和刚被立案的两臂是**同一个死数的两个身体**：留着，下次换代又得记一笔「消息里还有一处」。⇒ 与两臂同轮改为现算：

```python
        bool(tot1) and (want, got) == (int(tot1[0]), int(tot1[1])),
        "另算=%d/%d ｜ 汇总面=%s/%s ｜ 门牌=应解析=%s 实解析=%s" % (want, got, (tot1 or ["-", "-"])[0], (tot1 or ["-", "-"])[1],
            (tot[0][0] if tot else "-"), (tot[0][1] if tot else "-")),
```

（`tot` 为该件内已算出的汇总面解析结果；落地窗以现读变量名为准，⛔ 为凑这段新开变量。）

### 追加进 M4 验收式（正式条款，逐字入件）

> **M4 验收式增第 (X) 条**：链后立即跑 `python _tools/spr38_r8_verify.py --selftest`，须**同时**满足：①末行含 `SELFTEST ok`；②面上 `基准红=[]`（即正对照零红）；③七把反证刀逐臂 `抓到`，其中 `P1`／`P2b` 两臂的期望判定分别为 `C1c`／`C1a`。三者任一不合 ⇒ M4 记 FAILED，⛔ 以「SELFTEST-BLOCK 是过渡态」放行。
> 依据：R48 §B-6 三条批准红的出口目前只证到判据面（EV/r8 严格面），没证到牙；本条把「牙」纳入收口。

---

## §C 三项授权确认（落字追认，⛔ 重开讨论）

> 🔴 **撞号披露（本窗 13:2x 落盘后现读发现，如实报，⛔ 自改号）**：`ls -la --time-style=+%H:%M:%S production/sprint-40/SPR40_主理人裁定_R50_*.md` 现读**两份 R50**——姊妹窗件 `…_R50_W1第5问牙口面混代现场总裁_…` mtime **13:25:43**，本件 mtime **13:28:11**。按 R49 抬头自证的惯例「若另有窗同时取同号，以 mtime 先者为准，后者改用下一空号」⇒ **W1 那件保留 R50，本件在编号面上让位、请引用时按文件名全称指代**（本窗 ⛔ 再新建／改名文件，故不改名，只在此坐实归属）。两件事面互不重叠：W1 裁的是 `--falsify` 牙口面混代与锁守卫归窗；本件裁 R49 五问＋§C 三授权。作者／编程侧引用本件内容时，⛔ 用「R50」裸号，请用文件名里的题目段。
> 交叉核对一处：W1 件 :49 已声明 AGENTS 七件套条目那行不归它塞、且 :108 自报本轮未再改 AGENTS——与本件 §C-3 的「AGENTS 那句话由我本人在收官车落盘」一致，⛔ 任何窗为本单抢改 AGENTS。

1. **R48 §B-3 `path_of` 取 (α)** —— **追认**。不新增 `path_of`，沿用既有 `rd(rel)`（现读定义 `_tools/spr38_evidence_verify.py:156`，缺件 `return None` 在 :159；复现：`sed -n '140,162p' _tools/spr38_evidence_verify.py`，§A-0 #4）＋ `ROOT` 相对名口径。R48 逐字块里那个函数名就此作废，⛔ 施工窗再造第四种读取入口。
2. **R48 §C-3 drift 档位取 (甲)** —— **追认为对 R48 逐字块的有意偏离**（`_verdict` 的 `"drift"` 分支落地为 `"ok"`，差额只进 msg）。独立复核支持它：`compute()` docstring 只声明 `ok|red|na`（`r8:213`），且汇总行 `ok=%d` 由 `len(res)-len(red)-len(na)` 减法得出（`r8:573`；复现：`sed -n '211,215p;571,575p' _tools/spr38_r8_verify.py`，§A-0 #6）⇒ 真出 `"drift"` 档会被**隐式记成 ok**，比显式记 ok 更坏。
   - **同步义务（本件落字，编程侧照此执行）**：`checks` 总数不变、`ok/red/unexecuted` 三个计数 ⛔ 因 drift 项变动（drift 恒并进 ok）；`--selftest` 的期望态数 **不变**（drift 不新增态，只新增 msg 内容）；若落地窗发现某处把「单调不减」的差额写成第二个 `chk()` 行，那才是需要改 `checks=` 期望的事件——须回报、⛔ 自改。
3. **stance 字段级掩除实现由编程侧自拟** —— **追认**（R48 §D-3 四约束为准，实现自拟）。与 `s20_churn_whitelist_verify.py` 的单源对账若做不到，走 §D-3(iv) 降级路径。
   - **AGENTS 那行注的逐字（由本件落笔；M4 之后的收官车由我本人落 AGENTS，⛔ 编程侧代改，X4）**：
     ```
     churn 的 stance 面字段级掩除清单以 `_tools/spr40_churn.sh` 内联常量为**唯一入口**；`s20_churn_whitelist_verify.py` 自本行起降级为**离线自证件**，⛔ 当第二入口引用。
     ```

---

## §D M4 一车的最终清单（九件 → **八件**）

| # | 事项 | 逐字文本出处 |
|---|---|---|
| 1 | EV 臂面换源＋两把反证刀（`path_of` 按 (α)） | R48 §B-3/§B-4 ＋ 本件 §C-1 |
| 2 | r8 `GREEN_MD5` 转正＋`C10a2` 三处绿串同源＋换代义务注释＋投毒刀 | R48 §C-2 |
| 3 | r8 `C12 census` 单调不减＋逐 macro 明细＋刀 A/B/C（drift 按 (甲)） | R48 §C-3 ＋ 本件 §C-2 |
| 4 | churn stance 字段级掩除＋ :58 措辞轮换 | R48 §D-3/§D-5 ＋ 本件 §C-3 |
| 5 | 刀标签更名（`knife.sh` :54/:55 两行） | R15 §E-3 |
| 6 | 编译面第 7 件牙口臂（run.sh 行＋承载件＋`TOOTH_ARMS`＋7 处站点值 6→7；`TOOTH_SITES` 不动） | 本件 §B-Q1 |
| 7 | `bak_archive_check` 扩展（`BAK-CLAIM ok`／RED／UNEXECUTED＋1 个 falsify 态＋`BAKGATE-FALSIFY ok 六态…`） | 本件 §B-Q3 |
| 8 | run.sh 注释卫生＝M1.5′ 四处孤儿注释包处置 | 本件 §B-Q4 |
| 8′ | 🔴 **新增（本件 §B-Q5）**：r8 `P1`/`P2b` 毒臂死串派生化＋`:233` 门牌现算化＋M4 验收式加 SELFTEST 条款 | 本件 §B-Q5 |

⛔ 拆窗不变（R20 §F:174、R48 §E-4-5）：以上八件（含 8′）在**同一个持锁独占窗**一次做完、一次 `STEP=all` 链验证。原第 8 件（flavor 十条）已按 §B-Q2 撤下，⛔ 再出现在手术清单。

---

## §E 结论区（不留待作者项）

1. 第 7 臂三问全齐：run.sh 追加行逐字给出（锚＝`--in-chain-as=证据重算活链` 行之后、活链声明块之前）；末行语义＝`COMPILE-ARM GREEN` 且臂名只许由 `teeth()` 的 RUN 行带入；**站点数裁「值 6→7、`TOOTH_SITES` 留 7」**。
2. flavor 十条**裁撤**（R21 作准、R16 §F-1 作废），结案措辞已给，`_ML_DECLARED` 维持 94，26 行 `94` 一行不改，M4 九件→八件。
3. `bak_archive_check` 判定串 `BAK-CLAIM ok`／RED／UNEXECUTED 三态文案与双源抽取形状给齐；纠正一处盘上事实：R16 点名的 `_tools/spr40_promote_audit.log` **不存在**，故改双源＋审计件生成义务；falsify 加 1 态，**EV 态数文案无需同步**（`states=%d` 本就现算）。
4. 「run.sh 注释卫生」＝M1.5′ 四处孤儿注释包（task #64），⛔ 指 R45 §E-4 的 `run.sh:116` 披露。
5. 新缺陷立案并按 **(α)** 派生化（含 `:233` 同轮换现算），并把「链后真跑 `--selftest` 须 `SELFTEST ok` ∧ `基准红=[]` ∧ P1/P2b 分别抓到 C1c/C1a」写进 M4 验收式。
6. §C 三项授权全部追认；AGENTS 那句话由本件落笔、由我在收官车落盘。
7. 🔴 落盘后现读发现**两份 R50 撞号**（姊妹窗 W1 第 5 问件 mtime 13:25:43 早于本件 13:28:11）⇒ 编号归属按 mtime：W1 留 R50，本件在裸号面上让位、以文件名题目段引用；处置见 §C 抬头与本件 §F，⛔ 本窗自行改名。

---

## §F 本窗未执行项（UNEXECUTED，如实报）

- ⛔ 重跑 EV／r8／selfaudit／`--falsify`／`--selftest` 判据件本体（按本窗令吸收编程侧 13:2x 证件：EV `RED issues=1 checks=9`、r8 `checks=52 ok=50 red=2 unexecuted=0`、`--falsify` rc=0、`--selftest` `SELFTEST-BLOCK`）⇒ 本件对这四组数值是**采信＋形状复核**，非独立复算。
- ⛔ 起链、⛔ 抢锁、⛔ 碰任何 Godot 进程；锁状态未现读核验（本窗不需要）。
- ⛔ 动 AGENTS／冻结表／`.gd`／任何判据件；本件只新建自身一份。
- ⛔ 现场枚举 AUTORUN 四处孤儿注释的具体位置（§B-Q4 交落地窗 `grep -n "^#"` 现数，避免预填行号）。
- 🔴 **撞号后的处置未执行**：本件与姊妹窗 R50（W1 第 5 问）同号（见 §C 抬头披露），本窗 ⛔ 改名、⛔ 再新建第三件；换号／合并引用口径**须作者或下一扇持锁窗裁**，本窗只坐实 mtime 归属。
- ⛔ 实测 `spr40_compile_arm.py` 的红绿两态（该件尚不存在，M4 才建）；本件给的判据形状依赖 R16 §C-1 的判别力实测表，未在本窗重跑那 12 份日志的 `grep -a -c`。
- ⛔ 核对 `s20_churn_whitelist_verify.py` 与 churn 内联清单的逐面行数（§C-3 只裁口径与降级路径，实测归 M4 落地窗）。
- 本窗实跑命令：**20 条**（§A-0 的 18 个编号条目＋末条 `ls production/sprint-40/` 目录清点＋收尾 `git status --porcelain` 写盘面自证；⛔ 未跑任何判据件本体）。
- 写盘面自证：`git status --porcelain | head` 现读盘上另有他窗既有改动（README／SPR21-FROZEN.md5／sprint-28 四件／若干 `.import`），**均非本窗笔**；本窗只新建 §抬头所列本件一份，⛔ 动上述任何一件，⛔ commit/push。
