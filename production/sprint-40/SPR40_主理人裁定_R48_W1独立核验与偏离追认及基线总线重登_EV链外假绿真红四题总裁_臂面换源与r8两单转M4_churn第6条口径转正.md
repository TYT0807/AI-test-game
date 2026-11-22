# SPR40 主理人裁定 R48｜W1 独立核验（偏离追认＋基线总线重登）＋ EV 链外假绿真红四题总裁：臂面换源方案、r8 第四串与 C12/C13 内部矛盾两条转 M4 逐字单、churn 第 6 条口径转正与 151 终局句

性质：**纯裁定件 ＋ 本窗写了 AGENTS.md §3 一行**（§D-1 是我的笔，见 §D）。除此之外本窗 ⛔ 改任何既有文件、⛔ 动 `.gd`／链件（`spr38_run.sh`）／判据件（`spr38_evidence_verify.py`／`spr38_r8_verify.py`）／刀件／`SPR21-FROZEN.md5`、⛔ 跑 Godot、⛔ commit/push。施工项全部转成逐字生效文本，交空闲锁窗执行。

被复核件＝`production/sprint-40/SPR40_编程侧值守_R47_R45吸收W2三件套落地与W1链验收及离线EV一条真红与151作废.md`（现读 **93 行**／`5f4a4597…`）。上游：`S40-R46`（现读 133 行）、`S40-R45`（现读 187 行）、`S40-R21`（现读 **127 行**／`bc33ceb7…`，标题行仍写 `R15`＝§A-2 挂账）、`S40-R20` §B-2/§E-1/§F、`S40-R17` §2/§3。编号声明：`R48` 经盘上现读空闲（sprint-40 目录最大值守件＝R47、最大裁定件＝R45；R21 是改号位不是 48）。引用一律写全 `S40-R48`。

---

## §0 现场基线总线【本窗 13:1x–13:2x 逐笔现读；值由命令产出，⛔ 转抄任何旧件坐标】

| # | 对象 | 现读值 | 取法 |
|---|---|---|---|
| 0-1 | `_tools/spr38_run.sh` | `4130e4aed2338bf020e7e86389d59cfc` ／ **288 行** | `md5sum` ＋ `wc -l`（与呈报一致） |
| 0-2 | `_tools/spr38_gates.sh` | `e0115414dd327b632d967dfd1e46c67f` ／ 130 行 | 同上 |
| 0-3 | `_tools/spr40_churn.sh` | `05c36e496c0b5fedde314be834f47fd6` ／ 58 行 | 同上（并发窗落，非本窗） |
| 0-4 | `_tools/spr38_evidence_verify.py` | `d4c2b3533d36bee2bd4e84e4fd7a3c3a` ／ **897 行** | 同上 ⇒ **未动**，M4 施工后须换新值 |
| 0-5 | `_tools/spr38_r8_verify.py` | `f76239869a8102e55801eb7908790a87` ／ **729 行** | 同上 ⇒ **未动**，M4 施工后须换新值 |
| 0-6 | `_tools/spr40_b/s20_churn_whitelist_verify.py` | `e5bf53f9957b4a3a40758c8a57b78a5a` ／ 205 行 | 同上 |
| 0-7 | `scripts/player.gd` == `_tools/spr38_good_player.bak` | `037f261d1b2d393fa02aba6a0bed1654`（互等） | `md5sum` 双件 |
| 0-8 | `production/sprint-21/SPR21-FROZEN.md5` | `ace857f17d0a54002b66a3ee28fe255b`；现算 **34 OK / 0 FAILED** | `md5sum` ＋ EV 冻结面打印 |
| 0-9 | W1 链证据三件 | terminal `176 B`/2 行（首行 `=== gates 起跑 12:45:31 ===`）；runlog `1849 B`/**22 行**；`logruns/2026-11-19T124528/` 份数 **31** | `ls -la`/`wc -l`/`head -1` |
| 0-10 | runlog 的臂打点行 | `grep -c -a '^RUN 牙口 .* ok |'` = **6**；旧代 `spr38_S40M5_chain.txt` 亦 **6**／22 行 | 两件同构坐实 |
| 0-11 | 盘上带链终端行的 `.txt` 候选 | 28 份，其中 RUN-GREEN 11 份；选中＝`spr38_run.all.terminal.txt`@12:59:42 | EV 判据④打印现读 |
| 0-12 | 锁 | `_tools/.spr38_run.lock` **不存在**（已释放） | `ls` |
| 0-13 | R21 改号件 | `bc33ceb75d783d146da00136fd72e284`／127 行；快照 `_backup/spr40_r21_rename/`（`before.md5`=`6b277667…`）；标题行现读仍 `# SPR40 主理人裁定 R15｜…` | `md5sum`/`wc -l`/`head -1` |
| 0-14 | R45 §B-2 两句订正 | **均已落**：B1 文档 EOF 末行、AUTORUN EOF 末行逐字命中 §B-2 生效文本 | `tail -3`/`tail -4` |
| 0-15 | R45 §E-4 run.sh 四字披露 | **未落**：`:116` 现读 `echo "RUN 链卫生 F-2 上一代中间日志已复制入 $ARCH \|份数=…"`，无 `(上一代)` | `grep -n "已复制入"` |
| 0-16 | 白名单是否接入入口 | `grep -n "CHURN_ASSERT_WHITELIST\|WHITELIST" _tools/spr40_churn.sh _tools/spr38_gates.sh _tools/spr38_run.sh` → **零命中** | 现读坐实呈报属实 |

---

## §A W1 独立核验（只读复现，⛔ 采信转述）

### A-1 三件落盘复现

1. **R21 改号**：现读 0-13 三项全对——文件名已是 `…_R21_…`、md5 与行数等于呈报值、备份目录含改名前原件与 `before.md5`。**字节级证明成立**：改名前后 md5 同为 `bcc65d52…`（证据件明写「改名不改字节」），其后 `+1 行 −0 行` 才变 `bc33ceb7…`/127 ⇒ 追加式订正、既有 126 行未回改，符合 append-only 不变式（R19 §F-2）。
2. **AUTORUN 并发纪律行**：现读 EOF 倒数第二行＝「S40-R20 §D 并发纪律生效登记：W-1 …／W-2 …／W-3 …」，行数 339→340 加一减零成立。
3. **run.sh F-1/F-2**：现读 0-1＝`4130e4ae…`/288；F-1 块（`:104-108` 区段）与 F-2 块（`:112-116`）均在位；失败路径另存 `.failed-<ISO>.log` 且**原件原地不动**（`cp -a` 而非 `mv`/`rm`）——「⛔ 删除任何证据」这条硬约束在代码里成立，不是注释承诺。

### A-2 偏离申报：§B-2 预检收窄 —— **追认，并把它升级为通用口径**

R20 §B-2 的字面预检是 `grep -rn "R21" … | grep -v spr40_r21   # 须零命中（本件除外）`。该判据**恒不成立**：`R21` ⊂ `SPR21`，裸串在 sprint-40 与两份 AUTORUN 台账里现读 150 命中——这是一条**不可满足的预检**，不是本窗没跑。本窗收窄为 `裁定_R21|核验_R21` 且排除 R20 自身，并把偏离写进脚本注释与证据件，处置正确。

🔴 **口径转正（后续所有改号/换号类预检一律照此）**：凡「新编号未被占用」的预检，模式必须是**指涉形态**（`裁定_<号>`／`核验_<号>`／`值守_<号>`），⛔ 用裸编号——裸编号在任何有历史批次名的仓库里必然误命中，写出来就是一条恒红的死预检。反证已在盘上：本窗现读 `grep -rn "R48" production/sprint-40/ _tools/AUTORUN_LEDGER.md _tools/AUTORUN_值守报告.md` 裸串命中＝0 纯属巧合，而 `grep -rn "R21"` 裸串命中＝150，同一形状两种结果 ⇒ 判据本身没有牙，必须靠形态收窄才有牙。

🟡 **登记一条残留（归下一份值守件认领，本窗 ⛔ 动它）**：R21 的**标题行仍写 `# SPR40 主理人裁定 R15｜…`**。按 R20 §B「正文不回改」是对的（回改＝篡改改号史），但于是「文件名说 R21、正文自称 R15」这个裂口目前没有任何文档闭合——R47 现读 `grep -c "R21 订正"` = **0**，即那两处旧名引用方（R20、R43）无人认领。处置＝下一份值守件加一行订正锚，逐字见 §A-3。

### A-3 值守件订正锚逐字生效文本（宿主＝下一个持锁施工窗的值守件 EOF 一行）

```
- S40-R48 订正：`SPR40_主理人裁定_R21_*.md` 的文件名由本窗现读证实（`bc33ceb7…`/127 行），但其标题行按 R20 §B「正文不回改」仍自称「R15」——引用该件一律写全 `S40-R21`，以文件名与内容为准、⛔ 以标题号为准；R20/R43 两处旧名引用由此行认领，原文一字不动。
```

### A-4 验收链复现

链窗自证：terminal 首行 `=== gates 起跑 12:45:31 ===`、末行 `RUN-GREEN step=all gates=0 knife=0 run=9`；runlog 22 行、臂打点行恰 6（0-10）；F-2 归档 31 份。三条独立复算全过：①EV 时间面打印「窗=11-19 12:45:31→11-19 12:59:42，证据日志 20 份全部落窗内、早于窗=[]」；②EV 门禁面/十刀面重算 `[4,1,1,2,4,2,2,1,7,3]` 与期望逐项相等、`SCRIPT ERROR`=0、10/10 到 `done 94/94`；③冻结面纯 python 现算 34/0 rc 与声称相等（0-8）。⇒ **W1 判 PASS**，且它是 F-1/F-2 新架构第一代（R46 §I-4 的代次划分我认）。

### A-5 基线总线重登（应呈请，本件 §0 即登记处）

`_tools/spr38_run.sh` 新值 **`4130e4aed2338bf020e7e86389d59cfc`／288 行**（旧值 `ad612787…`/250，+38 −0，`bash -n` rc=0）。同时把 §0 一并立为**当前对照底**：gates `e0115414…`/130、churn `05c36e49…`/58、EV `d4c2b353…`/897、r8 `f7623986…`/729、清单 `ace857f1…`(34/0)、player==bak==`037f261d…`。🔴 后续任何窗引用这些坐标，**以 §0 现读值为底**，⛔ 再拿 R20 §G-1 或 R45 §0 的旧值当「改动前」——那两处都是上一代取样，拿它们比会把 F-1/F-2 那 38 行算成本批改动（假漂移）。M4 施工改了 EV/r8 之后，§0 的 0-4/0-5 两行由施工窗在**链后**换新值重登，⛔ 提前刷。

---

## §B 题 1 总裁：EV 链外「臂数=0」＝**真红，且方向是假绿向**；采 (c′)＝臂面按选中件的**形状**换源

### B-1 定性（先纠正一句措辞）

这条不是「工件形状与判据相撞」那么中性——它是 **EV 自己的回归**：F-1 之前，盘上最新 RUN-GREEN 候选就是**整轮 stdout 的 `.txt`**（例：`spr38_S40M5_chain.txt`，22 行、内含 6 条 `RUN 牙口 X ok |…|`）；F-1 之后，那份完整 stdout 改叫 `.log`（不在 `CAND_GLOB="_tools/spr38_*.txt"` 内），`.txt` 里剩下的最新 RUN-GREEN 候选只有 2 行的 terminal 摘要。于是 `:734` 的 `claimed` 抽取恒空 ⇒ `m_expected=6 != 0` 恒红。

🔴 更要命的是**资格判定跟着一起失效**：`:559-586` 那段（终端色分档、step 分档、`RUN-GREEN=1 且不与他色共存`）全建立在 `raw_run` 上，一旦选中件只剩 2 行摘要，这三道闸就在检查一个**自己刚截出来的尾巴**——自比较哨兵（AGENTS §5 第三类）。所以若有人图省事去放宽 `m_expected` 或让臂数缺失只披露不置红，就把 EV 的判据②连同牙口面一起拆了。本窗明确 ⛔ 该路线。

### B-2 裁：采 **(c′) 臂面换源，按选中件形状选真源**（⛔ 三选一里的 (a)(b)）

理由（可证伪版）：

- **(a) 终端件也写臂打点行**＝把整轮 stdout 的尾巴复制进第二份文件 ⇒ **双写真源**，正是 R8-C 警告的形状，也正是 run.sh `:78-78` 注释自己立的规矩（「拼出来的串与 stdout 不同源就是双写」）。而且它只是把问题挪一格：以后每多一类打点行就得同步一次那个 2 行摘要。⛔。
- **(b) `CAND_GLOB` 收 `.log`（或 runlog 另落同名 `.txt`）**＝扩大候选池，会连带改变 r8 `latest_chain()` 与 EV 判据④的选件语义（r8 本就同时扫 `.txt`+`.log`，两边池子一改就不再同源）；「另落一份同名 `.txt`」更是第三份副本。⛔。
- **(c′)**：选中件**仍然**由判据④按内容挑（不动，HP-13 的成果保留），但臂面的真源随形状走——**选中件里没有 `RUN 牙口` 打点行时，回落到同 stem 的 `.log` 原件**（`spr38_run.all.terminal.txt` → `spr38_run.all.runlog-<ISO>.log`）。回落件**不参与**判据②的资格分档（终端色/step 仍只由判据④选中件自己说话），只供臂名↔判定串的抽取。这样：零双写、零池子扩张、判据②语义不变、臂面重新对着真实 stdout 说话。

### B-3 逐字生效文本（施工窗照抄，宿主＝M4 那车；本件给锚⛔ 给行号）

**改点 1**：在 `# ---------- 6) 牙口面` 之前插入两个模块级辅助函数（紧随既有 `def rd(rel):` 之后即可，那里已有 `os.path.join(ROOT, rel.replace("/", os.sep))` 的同款路径口径）：

```python
ARM_LINE_PAT = re.compile(r"^RUN 牙口 (\S+) ok \|([^|]*)\|$")


def arm_lines(text):
    """一件里的臂打点行（链 stdout 的 prose）。"""
    return ARM_LINE_PAT.findall(text or "")


def runlog_sibling(rel_txt):
    """F-1 后的原件回落：终端摘要件 `*.terminal.txt` ↔ 整轮 stdout `*.runlog-<ISO>.log` 同 stem 配对。
    ⛔ 把件名硬编进判据（HP-13 坐标≠身份）——这里只按**同目录下同前缀**现找，找不到返回 None。"""
    if not rel_txt or not rel_txt.endswith(".terminal.txt"):
        return None
    stem = rel_txt[:-len(".terminal.txt")]
    d = os.path.dirname(path_of(rel_txt))
    cands = sorted(glob.glob(os.path.join(d, os.path.basename(stem) + ".runlog-*.log")))
    return (os.path.relpath(cands[-1], ROOT).replace(os.sep, "/") if cands else None)
```

🔴 上面用了 `path_of(rel)` 这个**本件今天不存在**的名字——施工窗落地时必须二选一，并在提交里写明选了哪个：**(α)** 复用本件已有的沙箱根口径 `ROOT`＋相对名直接 `os.path.join(ROOT, rel.replace("/", os.sep))`（与 `rd()` 内部同款，最稳，推荐）；**(β)** 在本件顶部新增 `def path_of(rel): return os.path.join(ROOT, rel.replace("/", os.sep))` 并把 `rd()` 内部改为调它。**⛔ 第三种：把 `path_of` 当已存在照抄**——那会得到一个 `NameError`，而它在 `--falsify` 里表现为「态 INVALID」而不是编译错，容易被当成造错环境不干净。

**改点 2**：把 `:734` 那一行（现读原文 `claimed = None if INCHAIN_AS else re.findall(r"^RUN 牙口 (\S+) ok \|([^|]*)\|$", raw_run, re.M)`）替换为：

```python
claimed = None if INCHAIN_AS else arm_lines(raw_run)
_arm_src = RUNLOG_REL
if not INCHAIN_AS and not claimed:
    _sib = runlog_sibling(RUNLOG_REL)
    if _sib:
        _sib_txt = rd(_sib)
        if _sib_txt is not None:
            claimed = arm_lines(_sib_txt)
            _arm_src = _sib
```

**改点 3**：`:777-780` 那句 `print("牙口面 表互证 …｜%s臂=%d")` 的格式串尾部追加 `｜臂面真源=%s`，实参补 `_arm_src if not INCHAIN_AS else "盘上承载件"`。⛔ 让它继续只报臂数不报来源——来源不上面，回落这件事就无法被机检，下次形状再变没人看得见。

**改点 4（造错面配套，缺一面就是假绿）**：`do_falsify()` 里态 6（现读锚 `add("牙口打点形状破坏（拆竖线）", "arm", "链声称臂数=0", landed, d=d, rl=rl)`）保持原样——它的底 `NEWEST_REL` 若也是 2 行摘要，`landed` 里那句 `n_arm == len(TEETH_ARMS)` 会当场 False ⇒ 该态记 INVALID 而非「抓到」，这是**正确的显式失败**，⛔ 为了让它绿而去放宽 `landed`。在该态上方加一行披露注释：`# F-1 后 arm 世界底的 prose 在 .log 里，摘要么走回落、要么本态显式 INVALID（⛔ 静默缩站点）`。

### B-4 反证刀（施工窗必跑，两把都要红）

- **刀 I（验回落真有牙）**：临时把 `runlog_sibling()` 改成 `return None` ⇒ 链外 `python _tools/spr38_evidence_verify.py` 必须回到 `RED issues=1 … 链声称臂数=0`。还原后必须 `GREEN checks=10`。
- **刀 II（验臂数不是恒过的常量自比较）**：在回落到的 `.log` 副本里删掉任意一条 `RUN 牙口 … ok |…|` ⇒ 必须 `RED …臂数=5 != 期望 6`。⛔ 拿「删两条还是红」当通过——期望是**精确等于**，少臂与多臂都算抓到。
- 两把刀的原始 stdout 落 `_tools/spr40_b/s22_ev_armfall_{verify,falsify}.txt`（名字含 `verify`/`falsify` ⇒ 天然落 `CHAIN_EXCLUDE` 之外，不会污染对面选件，AGENTS §7 取证命名坑）。

### B-5 归属与时序

本项属 **M4 那车**（判据件），⛔ 归 W2、⛔ 单独开链。落地次序：M4 改完 EV → 起一扇 `STEP=all` → **链后立即跑不带 `--in-chain-as` 的严格面**，期望 `EVIDENCE-VERIFY GREEN`（这就是 R20 §F「M4 验收＝新链 RUN-GREEN ∧ 链后立即 EV GREEN」那条的老病自愈证据）。链外这一红在此之前**允许挂着**，但 ⛔ 任何人把它写进「批准红清单」以外的地方——本件 §B-6 就是唯一登记处。

### B-6 批准红清单现状（本窗现读，替代 R10 §D-3 旧五条）

| # | 红 | 定性 | 出口 |
|---|---|---|---|
| 1 | EV 链外 `链声称臂数=0 != 期望 6` | 真红·假绿向（F-1 回归） | M4 §B-3 改点 1–4 ＋ §B-4 两刀 |
| 2 | r8 链外 `C10a 绿件==盘上件==台账串` | 判据件自带过期串 | M4 §C-2 逐字单 |
| 3 | r8 链外 `C12 census 复现==历史` | 判据内部矛盾（C12 vs C13） | M4 §C-3 逐字单 |

链内三面（teeth6/EV inchain、selfaudit 文档面、gates/knife）本窗无红证据可引——本窗 ⛔ 起链，链内状态以下一扇链现读为准，⛔ 拿 R45/R46 的链内读数当本轮实测。

---

## §C 题 2 总裁：r8 两条链外红，各出逐字单，转 M4

### C-1 先答呈报里那个「并存」之谜（结论在前：呈报的机制假设错了）

呈报说「`:417 field_clear=(not lock) and …` ⇒ 锁内该臂被 `busy_dependent` 吞、锁外必炸，解释了『链内工具面 13/13』与此刻红的并存」。**现读否证**：`chk()` 的 `busy_dependent` 分支只在 `f["lock"]` 为真时记 `na`，而 C10a 的 `cond` 里那个 `(not f["lock"])` 与开关是**同一条件的两次表述**，不构成「链内绿」的来源。真正的原因是 **C10a 从来就没有绿过**：`GREEN_MD5` 与盘上串四代全不相等（下表），无论锁在不在了、无论链内链外，`f["bak_md5"] == GREEN_MD5` 恒 False。所谓「链内 13/13」是**别的臂**的计数，与 C10a 无关——这条如实纠正，免得下一窗去找一个不存在的「锁态依赖」。

### C-2 `GREEN_MD5` 裁：判为**陈旧残留**，转正为**当代现役串**，并补一条防再腐烂断言

四串谱系（本窗现读）：

| 串 | 出处 | 关系 |
|---|---|---|
| `dc622351a75e8da9d943d72332ec2a28` | r8 `:27`；R15 迟件称「已腐，A 组之前的老绿基线」 | 与盘上不等 ⇒ C10a 恒红 |
| `5835d2e6e9e89d3a6dd4155bcadc0b19` | selfaudit 旧 GOOD_MD5（R15 §A 的对象） | 已作废 |
| `4d438e3f363c4c103fcc69d919366ae3` | R15 §A/D 晋升代 | 已被 037f261d 代盖过（R21 §0-14 现读） |
| `037f261d1b2d393fa02aba6a0bed1654` | **现值**：player.gd == `.bak` == EV `:114 EXPECT_MD5` == 清单现算 34/0 | 唯一活声称 |

裁：`GREEN_MD5` 转正为 `037f261d1b2d393fa02aba6a0bed1654`。

**是否属 R15 §A 那类「须作者逐项放行」的基线串转录授权面？——不属。** 判据划界（写成口径，后续照此自判）：

- 须作者放行的只有 **①冻结表 `SPR21-FROZEN.md5` 的重登/转录** 与 **②`.gd` 生产文件的字节态变更**（AGENTS §4/§8 保留域④）。
- **判据件里对着现役绿基线的镜像常量**（`GOOD_MD5`／`EXPECT_MD5`／`GREEN_MD5` 这类）**不需要逐项放行**，它的义务是「**必须与盘上现读同步**」——R15 §A 当时给的也正是这种单子（`selfaudit:28` 一处、编程侧执行），并没有把它送判断栏。所以本窗同样直裁，⛔ 问作者。
- 🔴 反向红线：**⛔ 为了绿而把 `GREEN_MD5` 改成任何非现读值**（含「留个占位」「先设成 None 跳过」）。串只能来自 `md5sum scripts/player.gd` 与 `md5sum _tools/spr38_good_player.bak` 的现读，且两件必须互等。

逐字生效文本（M4，宿主＝`_tools/spr38_r8_verify.py`）：

```python
GREEN_MD5 = "037f261d1b2d393fa02aba6a0bed1654"   # 现读＝player.gd==.bak==EV:114 EXPECT_MD5（S40-R48 §C-2 转正；上一值 dc622351… 系 S38-R8 期老绿基线，四代谱系见该件）
```

同轮**必须**补一条断言，否则这串下一代替绿基线又会烂一次（这正是本缺陷的根因，不是这一次的值）：

```python
    chk("C10a2 三处绿串同源（判据件间⛔ 各存一份）",
        f["bak_md5"] is not None and f["player_md5"] is not None,
        f["bak_md5"] == f["player_md5"] == GREEN_MD5,
        "bak=%s player=%s r8.GREEN_MD5=%s ⇒ 三者任一不等＝某件没跟上换代" % (
            f["bak_md5"], f["player_md5"], GREEN_MD5))
```

并加**换代义务注释**（紧跟 `GREEN_MD5` 定义行下方，一句）：`# 🔴 换代规则：绿基线晋升的那一窗必须同轮改这一行＋EV:114＋清单，三处不同源由 C10a2 当场拦（S40-R48 §C-2）。`

反证刀：内存变异——把 `f["bak_md5"]` 改成 `"1"*32` ⇒ `C10a2` 必须红（既有投毒臂 P32 只喂 C10a，⛔ 拿它当 C10a2 的牙）。落证件 `_tools/spr40_b/s22_r8_greenmd5_verify.txt`。

### C-3 `C12 census 复现==历史` 裁：判为**判据内部矛盾**，采「单调不减＋逐 macro 明细」口径，⛔ 放宽成不判

事实（本窗现读）：fresh 与 hist 只差**一个 macro 块**——`macro=Dev.check 应解析=285 实解析=285`（hist，`spr38_q3_census3.txt`，mtime 11-18 08:51）vs `=289 实解析=289`（fresh，`spr38_g_chk_taut.txt`，mtime 11-19 12:49），合计 564→568，其余 8 块逐字相同；生产件 `spr38_tautology_sweep.py` mtime **11-18 09:17 晚于 hist 的 08:51** ⇒ C13 已把 hist 降级为「只当复现对照」（`:492` 那句），而 C12 仍在拿它与本轮**死比相等**。两条判据在同一份输入上互相否定，这是结构缺陷，不是数据问题。

裁口径（写成可证伪判据，⛔ 靠「这次就算披露不置红」抹平）：

1. **C12 的合法比较对象只有两类**：(i) 同一份输入的两条独立取法之间（宏块另算和 ⇄ 该件汇总面，＝既有 C1a/C1b/C1c 的职责）；(ii) **同代次**的两个件之间（hist 不早于 PRODUCER）。跨代次的「复现」⛔ 判相等。
2. 既然 hist 已确定早于生产件，C12-census 改为**单调性＋明细**判据：`want_fresh >= want_hist` 且**逐 macro 差集只许出现在被点名允许的族上**（本例＝`Dev.check`，因为 S40 各批一直在往 `Dev.check` 加断言，减少才是回归信号），并且**必须把差额打印出来**——只比总数、不报哪一块变了，等于把一个可定位的事实压成一个不可定位的红。
3. **不变式（这才是判据真正的牙）**：普查件自己的 `应解析 == 实解析`（漏抽＝谎报），且 `可疑(T1+T2+T3)==0`。这两条 fresh 已满足（568/568、0）。跨代次增长属**合法演变**，一律 `DRIFT` 记账、⛔ 置红；跨代次**减少**一律 RED。

逐字生效文本（M4，宿主＝`_tools/spr38_r8_verify.py` 的 C12 循环体；锚＝现读 `out.append(("C12 %s 复现==历史" % k, "ok" if same else "red", msg))` 这一行，⛔ 引行号）：

```python
        if k == "census":
            fb, fw, fg, fs, ft, _fn = tier_stats(fresh)
            hb, hw, hg, hs, ht, _hn = tier_stats(hist)
            _same_block = (fb, ft) == (hb, ht)
            _grow_only = fw >= hw and fg >= hg
            _per_macro = [(m.group(1), int(m.group(2))) for m in re.finditer(r"^macro=(\S+)\s+应解析=(\d+)", fresh or "", re.M)]
            _hist_macro = dict((m.group(1), int(m.group(2))) for m in re.finditer(r"^macro=(\S+)\s+应解析=(\d+)", hist or "", re.M))
            _delta = [(nm, v - _hist_macro.get(nm, 0)) for nm, v in _per_macro if v != _hist_macro.get(nm, 0)]
            _shrink = [x for x in _delta if x[1] < 0]
            _verdict = "red" if (_shrink or not _same_block or fs or hs or fg != fw or hg != hw) else ("ok" if not _delta else "drift")
            msg = "fresh=(块%d,应%d,实%d,可%d,T3b%d) vs hist=(块%d,应%d,实%d,可%d,T3b%d)｜块数与T3b同代=%s 只增不减=%s 逐macro差额=%s 缩水=%s｜内部式 应==实:%s/%s 可疑==0:%s/%s ⇒ 跨代次增长记 DRIFT（S40-R48 §C-3），⛔ 死比相等" % (
                fb, fw, fg, fs, ft, hb, hw, hg, hs, ht, _same_block, _grow_only, _delta, _shrink,
                fw == fg, hw == hg, fs == 0, hs == 0)
            out.append(("C12 %s 复现⇄历史（单调＋明细）" % k, _verdict, msg))
            continue
```

🔴 落地前置核对（施工窗现读，⛔ 照抄我的断言）：`chk()`/`out.append` 这套里 **`"drift"` 是不是一个被上层接受的档位**——本件现有档位是 `ok|red|na`（见 `compute()` docstring 与汇总处的计数逻辑）。若 `drift` 不被识别，会被静默算进非红或直接漏计 ⇒ 假绿。两种合规处置，二选一并在提交里写明：**(甲)** 保持三档，把「只增」的态记 `ok`、把差额**打进 msg**（DRIFT 只在面上可见，红集为空）；**(乙)** 在同件汇总处显式加一档 `drift` 计数并保证它 ⛔ 计入 `ok`、⛔ 计入 `red`、且退出码不因它变。**默认取 (甲)**，因为它不动档位机器；选 (乙) 必须先证明汇总计数与 `R8-VERIFY checks=… ok=… red=… unexecuted=…` 那行、以及 `--selftest` 的期望数同步改过。

反证刀（两把，一把不够）：
- 刀 A：把 `census_hist` 的 `应解析=285` 改成 `应解析=290`（制造**缩水**）⇒ `C12 census` 必须 `red`。
- 刀 B：把 `census_hist` 的 `T3b` 或块数改掉（`_same_block=False`）⇒ 必须 `red`。
- 刀 C（防假绿的同形刀）：只把 hist 的 `应解析=285` 改成 `284`（差额变大、无缩水）⇒ 必须记 `ok`/`drift` 而 ⛔ 红，且 msg 里能看到 `('Dev.check', 5)` 之类的明细。这把刀证明新判据不是「一有不同红」的橡皮章。
- 证件 `_tools/spr40_b/s22_r8_census_drift_{verify,falsify}.txt`。

### C-4 关于「C12 与 C13 谁迁就谁」的一条原则（防止下轮反向改错）

⛔ 通过**升级 hist 件**（重跑普查覆盖 `spr38_q3_census3.txt`）来让 C12 变绿——那是把历史快照当活盘覆写，违反 append-only 与「⛔ 删除任何证据」；要新对照就新建一代件并把 `HIST` 指向新件，同时在 §0 基线总线登记新件 mtime。

---

## §D 题 3 总裁：churn 第 6 条口径转正（AGENTS 文字已由本窗落，见 §D-1）＋ stance 字段级为正解 ＋ 151 终局句

### D-1 AGENTS.md §3 第 6 行（我的笔，本窗已写，逐字如下）

```
| 6 | churn 比对 | 先钉 `SMOKE_SEED`；只比**白名单断言行**（探针自己打的 `[SMOKE-*]`／`[S38-*]`／`[VH*]`／`[MG-*]`／`[SW-*]`），⛔ 整行逐字比——`[SMOKE-STANCE]` 一行同载真断言字段（`done checked=N declared=N`）与每帧重算量（`shots/window/moving_window/blocks/released`），零改动代码上整行比仍报漂移＝假红；抖动族（下面那一族）按**字段级**掩除，口径与逐面行数以 `_tools/spr40_b/s20_churn_whitelist_verify.py`＋其证件为准。`151` 已作废（`BLACKLIST-151 VOID-WITHDRAWN provenance=column-sum-ok reproducible=no`），后续引用一律走白名单件＋口径名，⛔ 复活该数（S40-R48 §D） |
```

（原句「只比**带断言的行**，排除 §3 抖动族」在 stance 面上是不可执行的：它既没说怎么算「带断言」、又要求排除的抖动族与真断言同在一行。新句把「白名单」「字段级」「正解件」三件事一次写死。）

### D-2 stance 假红的实质（本窗现读复现，呈报数字对得上）

`_tools/spr40_base_r17/spr38_g_stance.log:59` vs `_tools/spr40_after_r17/spr38_g_stance.log:62`：

```
base : [SMOKE-STANCE] shots=89 len=0.3333 window=231 moving_window=230 leaks=0 blocks(idle/walk)=62/62 released=7 死亡打断=0 闩锁未结算=1 done checked=7 declared=7
after: [SMOKE-STANCE] shots=93 len=0.3333 window=230 moving_window=229 leaks=0 blocks(idle/walk)=64/63 released=7 死亡打断=0 闩锁未结算=1 done checked=7 declared=7
```

⇒ 两侧的真断言字段 `done checked=7 declared=7` **逐字相同**，变的四类全是每帧重算量。呈报的「①整行加法=2／②替换事件=1／③字段级掩抖动=0」与白名单件 `VERDICT=ALL_MATCH` 的构造（`total==24 and d1==2 and d3==0`）一致，我另核两点：①逐面白名单行数 2/3/3/3/2/3/2/2/2/2 合计 **24**，与 R20 §E-1 背书的 `s19_churn_assertonly_audit.txt` 末行对上；②反证二（内存变异刀，melee 面 `checked=94→93`）能证明口径③**不是恒绿**——一条真回归在字段级比下必须从 0 变 2，这条成立才说明口径③有牙。两把反证都在件里落了，采纳。

### D-3 裁：口径③（字段级掩抖动）＝**门禁第 6 条的正解**；接进入口归 **M4**，⛔ 塞 W2

- W2 那车的范围是 R45 §A 的 CHK 面逐字文本 ＋ R20 §E-2 的 CHK 假绿形状 ＋ 三态变异刀，**不含** stance 面。把 stance 口径手术塞进 W2 会让一车同时动「判定形状行」与「断言行抽取器」两件事，出问题无法归因。
- M4 那车已经握着 EV/r8 两处判据件手术（§B/§C），churn 的 stance 字段级化与它们是**同一族**（判据件的可执行口径），同车同链验证一次即可。
- 施工内容（M4，逐字待编程侧在落地窗现读后自拟，我给约束不给实现）：把 `_tools/spr40_churn.sh` 的 `PAT='^\[(SMOKE|S38|VH|MG|SW)'` 保留作**行选择**，但在 `diff` 之前加一道**字段掩除**：对 `[SMOKE-STANCE]` 行按空格切字段，剔 `shots=`／`window=`／`moving_window=`／`blocks(...)=`／`released=` 五个键后再比；`leaks=`／`死亡打断=`／`闩锁未结算=`／`done checked=… declared=…` **保留参与比对**（这几项是真断言）。🔴 硬约束四条：(i) 掩除清单必须写在件里并可 grep，⛔ 散进 awk 表达式；(ii) 掩除后两侧仍不等 ⇒ 照旧红，⛔ 借「字段级」之名把 stance 面整体降成盲区；(iii) 必须有一把变异刀证明「改 `leaks=` 或 `done checked=` 会红」，否则这条口径不可证伪；(iv) 白名单件 `s20_churn_whitelist_verify.py` 与新入口的逐面行数必须同轮对账，两份真源不许各自演化——若做不到单源，就把白名单件降级为**离线自证件**并在 AGENTS 那行注明「入口以 churn.sh 内联清单为准」，⛔ 两头都声称自己是正解。
- 入口接线时机：与 §B/§C 同一次 `STEP=all` 链后一并验证，⛔ 为口径单开链。

### D-4 「151」终局口径一句（供后续所有窗直接引用）

> `151` 是黑名单残差（探针行减抖动族）的**列合计**，出处坐实为盘上真实读数（`provenance=column-sum-ok`），但生成器从未落盘、抖动族名单本体不随汇总件留存 ⇒ **不可由口径重算**（现算得 705／179 皆非 151），按 R18 §3-2 判 `VOID-WITHDRAWN`：⛔ 进任何后续引用链，后续 churn 口径一律引「白名单件 `s20` ＋ 口径名（逐面 24 行／漂移 ①=2 ②=1 ③=0）」，`151` 只许以「历史残差、已作废」的身份被提及。

### D-5 顺带纠正一处易误读措辞（W2 那车落的 `spr40_churn.sh:58` 口径句）

现读该句＝「六面结构上不存在编号断言行，只比判定形状行＋结论行；有编号断言行的仅 melee(94)／sc(19) 两面」。与呈报的逐类实测并存但不精确：`validate problems=` 十面各 1 行、`[S38-*]` 合计 11（apply 面有 2）、`done checked=` 仅 melee/stance/sc、编号 token 仅 melee 29 行／sc 2 行 ⇒ **stance 有 `done` 行却无编号 token，落在该二分之外**。裁决：这句话**不算错**（它说的是「编号断言行」，stance 确实没有编号 token），但它把「无编号断言行」写得像「无断言行」，正是 §D-2 那类混淆的语言源头。处置＝M4 改 stance 口径时**同轮换措辞**为：「有**编号**断言行的仅 melee(94)／sc(19)；stance 面无编号 token 但有 `done checked=7 declared=7` 真断言字段，故 ⛔ 列入『无断言行』，其比对走字段级掩除（S40-R48 §D-3）」。⛔ 单独为措辞开一窗。

---

## §E 题 4 总裁：W2 归属与效力

1. **`_tools/spr40_churn.sh` = `05c36e49…`/58 行，归属＝并发窗**（R45 §A-3 的车由它落），本窗不认领、也不因此否认其效力。§0-3 已把它现读进基线总线当对照底。
2. **你替它补的那道逐字性核验：认，且效力等同 R45 §A-3 要求的「施工窗自证」**。我本窗独立复算：R45 全文只有 §B-2 两个 ` ``` ` bash 块之外的代码块是 13 行那个（§A-3 主体），盘上 `:44-56` 与之逐行比不等行数 0 ⇒ VERBATIM_OK 成立；循环体 TAB 缩进符合 §A-3 硬约束。核验归属＝**W1 窗代做**，登记在此，⛔ 下一窗再把它当「未核验项」重提。
3. **R45 §B-2 两句自指残句订正：已由并发窗落**（§0-14 现读：B1 文档与 AUTORUN 的 EOF 末行逐字命中生效文本，且两句均不含可抽取声称对 ⇒ {8,5} 站点数闸不会被它炸）。此项结清。
4. **R45 §E-4 run.sh `:116` 四字披露：未落**（§0-15 现读，无 `(上一代)`）。裁定＝**维持 R45 原口径**：登记待任一并存窗口顺路，⛔ 单开车。本窗 ⛔ 动 run.sh（我刚在 §A-5 把它的新值登基线，再动它就自毁对照底）。下一次合法触碰 run.sh 的窗口＝M4（若 §B 的回落方案需要链侧配合则一并带上；按现方案 §B 只动 EV，run.sh 无需再改，所以这四处披露将顺延到收官车或 M4 之后的任一链件窗）。
5. **W2 残项归属**：R45 §A 的 CHK 面逐字文本 ＋ §E-2 CHK 假绿形状 ＋ 三态变异刀 ＋ §D-5 的措辞轮换（并入 M4）＝**W2 仍未做完**，与 M4 并行排程但 ⛔ 混跑（R20 §F 原令）。顺序建议：W2（只动 `_tools/spr40_churn.sh` 的 CHK 段，不动 stance）→ M4（stance 字段级 ＋ EV 臂面 ＋ r8 两单 ＋ 编译面第 7 臂 ＋ flavor 十条 ＋ 刀标签更名 ＋ run.sh 注释卫生）→ 收官车。

---

## §F 纪律与边界回执

- 本窗写盘**只两处**：本件 ＋ `agents.md` §3 第 6 行（§D-1，我的笔，R20 §G-5 明定「churn 口径文字归主理人执笔」）。⛔ 动 `.gd`／链件／判据件／刀件／冻结表；⛔ commit/push；⛔ 刷任何 md5 清单；⛔ 起链（锁虽空闲，本窗无施工需求，起一扇只会白白产出一代 logruns）。
- 本窗跑过的取证命令（全部只读）：`git log --oneline -8`；`ls production/sprint-40/`；`md5sum`/`md5sum -b`/`wc -l`（run.sh/gates/churn/EV/r8/白名单件/player/bak/清单/R21/R47/AUTORUN）；`md5sum -c` 未跑（EV 的 python 现算等价，见 §A-4）；`cat`/`head`/`tail`（terminal、runlog、teeth6、B1/AUTORUN EOF）；`grep -n`/`grep -c -a`（CAND_GLOB、TEETH_ARMS、raw_run、claimed、field_clear、GREEN_MD5、C12/C13、tier_stats、is_chain_artifact、latest_chain、已复制入、WHITELIST×3 件、R21 裸串与形态串、R48 占用扫描、dc62 全仓追溯）；`diff`（两份 census 的 macro 行、stance 两侧）；`ls -la --time-style`（terminal/runlog/teeth/census 三代 mtime）；`python _tools/spr38_evidence_verify.py` 与 `python _tools/spr38_r8_verify.py` 各一次（链外、无锁态、只读，两者均不写产品文件）；`stat`/`ls` 锁。
- 未执行项如实报：**`UNEXECUTED`＝本窗未起链、未跑任何 Godot 探针、未跑 `--falsify` 与 `--selftest`**（§B-4/§C-2/§C-3 的反证刀全部转给 M4 施工窗，本窗只裁判据与逐字文本，⛔ 替施工窗预跑并据此声称绿）。

## §G 结论区（七句）

1. **W1 = PASS**：三件落盘、链证据、F-1/F-2 行为全部本窗现读复现；R20 §B-2 那条「裸 `R21` 须零命中」的预检**本身不可满足**，本窗收窄**追认**并升格为通用口径（改号预检必须用指涉形态）。
2. **基线总线已重登**：run.sh 新值 `4130e4ae…`/288 连同 gates/churn/EV/r8/清单/player 一并立为当前对照底（§0），后续 ⛔ 拿 R20/R45 的旧取样当「改动前」。
3. **题 1**：EV 链外那条是**真红且朝假绿方向退化**（资格面三道闸正在检查自己刚截出的尾巴）；采 **(c′) 臂面按形状换源回落到同 stem `.log` 原件**，(a) 双写、(b) 扩池两条否决；逐字文本＋两把反证刀在 §B。
4. **题 2**：`GREEN_MD5` 判为陈旧残留，转正为现读 `037f261d…`，**不属作者逐项放行面**（划界口径已写死：只有冻结表重登与 `.gd` 字节态须放行）；同轮必须补 `C10a2 三处绿串同源` 断言，否则换代再烂一次。C12 判为**与 C13 的内部矛盾**，采「单调不减＋逐 macro 明细＋内部式应==实/可疑==0」口径，跨代次增长记 DRIFT、减少记 RED，⛔ 靠放宽抹平。
5. **题 3**：churn 第 6 条口径**已转正**（AGENTS §3 第 6 行本窗落字），stance 面正解＝字段级掩除（真断言字段保留比对），接进入口归 **M4**、⛔ 塞 W2；`151` 终局口径一句已给（§D-4），此后只以「历史残差、已作废」身份出现。
6. **题 4**：churn.sh 归并发窗、你代做的逐字核验**有效并已登记**；R45 §B-2 两句**已落**（结清）、§E-4 四字披露**未落**且维持「顺路改、⛔ 单开车」；W2 残项与 M4 并行但 ⛔ 混跑。
7. **批准红清单现为三条**（§B-6），全部有出口、全部归 M4；本窗 ⛔ 起链、⛔ 预跑反证刀，凡未跑的都说 `UNEXECUTED`。
