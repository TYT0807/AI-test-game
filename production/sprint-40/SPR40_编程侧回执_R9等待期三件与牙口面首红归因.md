# SPR40 编程侧回执 R9 等待期三件｜牙口面首红归因＋链件两次改动的基准串

性质：**纯实测回执**（编程侧自证件，⛔ 裁判定性）。本轮只动 `_tools/`（链件＋自写落地件），⛔ 动 `scripts/*.gd`、⛔ 动登记面、⛔ 动 `_tools/AUTORUN_值守报告.md`／`AUTORUN_LEDGER.md`（禁止事项 #11）。
口径：**【现读】＝本窗自己跑出来的终端行/盘上字节**；【采信】＝转述他窗自报。

---

## §0 改前基线（HP-0，⛔ 省略）

- 链件 `_tools/spr38_run.sh` 本轮起点【现读】＝**237 行 / md5 `1fd96ea46dc2ef756774f3e97bfd7347`**（与 R7/R8 登记值逐字一致）。
- 判据件 `_tools/spr38_report_selfaudit.py` 起点＝752 行 / md5 `b1a313aad9ec7e65e02a514550260c81`（② 施工前态，备份面 `_backup/spr40_s8_selfaudit99/20261119-092011/_manifest.txt` 已钉）。
- 登记面 `production/sprint-21/SPR21-FROZEN.md5` 34 条（全 `scripts/*.gd`，无注释无空行）／md5 `11b8eb7e12ce755495185869c5063978`。
- 盘上 `scripts/player.gd`＝`5835d2e6e9e89d3a6dd4155bcadc0b19`＝`_tools/spr38_good_player.bak`（收尾互证成立）。

---

## §A ③ 23 把刀族：verdict 已产＋**时长实测给 R9 §C 定价**

【现读】独占窗 `RUN_CMD='python _tools/spr36_knives.py' bash _tools/spr38_run.sh run`，起跑 **09:25:02**、链尾 `RUN 锁已释放` 落盘 **09:32:07** ⇒ 该件本体 **7 分 05 秒（425s）**。

- 判定行（只在 `_tools/spr38_run.run.log`，链在文档面 exit 2 前不落 stdout）：
  `KNIVES VERDICT=ALL_BIT ok=23 阴性=1 INCOMPLETE=0 残留=0 total=24`
  ——24 行＝KNIVES 4＋C3 14＋STANCE 5（含 P4a/P4b）＋K4 特例；`阴性=1` 唯一来源＝`NOCOVER=("P4b",)`（R3 §3 覆盖面登记，⛔ 当回归断言）；`残留=0`＝改后逐件对回备份且 `wpn_arc.png` 已回位；`run exit=0`。
- **PRE/POST 表体**【现读】：PRE `OK=34 FAILED=0 缺=0` → POST `OK=34 FAILED=0 缺=0`（34 条逐一现算，无未复原件）。

**定价结论给主理人**：425s ＞ R9 §C 的 ~4 分钟线 ⇒ 按裁定**不做成链牙臂，降级为 knife 尾部子步**。但本窗把锁预算量清了，请主理人在此数字上定：

| 项 | 实测 |
|---|---|
| 本轮 STEP=all 全程 | 09:41:28→09:48:03＝**6 分 35 秒**（gates 4′11″＋knife 2′21″＋收尾/归档/工具面/牙口/文档面） |
| 文档面被调用时的锁龄 | ≈**390s**（锁起 09:41:29，文档面 ≈09:47:5x） |
| 若把 425s 塞进 knife 尾部 | 文档面锁龄 ≈**819s**，判据件 `live` 线＝**900s**（`spr38_report_selfaudit.py:223`）⇒ **放得下，余量仅 ~81s** |
| 越线后果（⛔ 静默降级） | `:237-239` 是硬 FAIL：「声称活链（SPR38_AUDIT_IN_CHAIN=1）但锁不存在／age=… ⇒ 按严格面判」⇒ gates 一变慢就出**假红**（红在锁龄而不在内容） |

即：**降级方案机械上可行，但把 STEP=all 的余量压到 10% 以内**。是否同时抬 `live` 线（＝改判据件的 900s 口径）请主理人裁，本窗 ⛔ 自行动手（禁止事项 #8）。

---

## §B R9 §B(b′) 搬迁件：已落盘＋验收形状＋**首红当场被抓**

落地件 `_tools/spr40_s9_docface_relocate.py`（默认 `--dry`；`--apply` 只在新鲜锁 ≤900s 内落盘；快照/回退带复验；`bash -n` 三态自证：候选 0／原件正对照 0／坏控制 rc=2 且 ≠127）。

- 施工窗 09:41:22【现读】：`锁面 ok 龄=4s` → `APPLIED-GREEN lines=237 调用行=213>最后teeth=210 md5 1fd96ea4… → df2dea3e8c2d09778a448f31ef1168ca`；备份 `_backup/spr40_s9_docface/20261119-094127/`（manifest 钉改前 `1fd96ea4…`＋块 md5 `f014a1df967fd44986eecb81c1983194`）。
- 合规自查：**只搬 `:159-166` 八行整块**（块 md5 逐字节对回）；判定文字与 `exit` 码＝搬后 6 行原文在盘上各命中 1；**注释恰 2 处**（块首两行重写＋段标题 `第 5 步之后`→`牙口之后`）；行数 237→237。
- 后置检查按**调用行**锚定（⛔ 用 `spr38_report_selfaudit` 子串——该串在 `:145` 注释里也出现，按 R9 原措辞会命中 3 行歧义）：现读 `最后一根 teeth 调用=:210`，`文档面调用=:213`，`TEETH_BAD 守卫=:219`，`RUN 牙口 汇总 echo=:220`。

**验收窗（紧接一次 STEP=all，09:41:28）终端行**【现读】：

```
RUN 收尾 player.gd == 绿基线 5835d2e6e9e89d3a6dd4155bcadc0b19
RUN 归档闸 … |ARCHIVE-GATE GREEN …|
RUN 工具面 写后核查件自证 ok |SELFTEST GREEN states=9|
RUN 牙口 回写件十一态 ok |SELFTEST GREEN states=11|
RUN 牙口 回写件改钝副本 ok |SELF-SAB ok 改钝副本被自己的态集抓到 states_red=6|
RUN 牙口 三指纹比对 ok |falsify_expect=三档全 DIFFER|
RUN 牙口 冻结串逐字转录 ok |FALSIFY ok 三态全抓到 states=3|
RUN 牙口 神谕配额同步 ok |VERDICT=ALL_DETECTED|
RUN-RED 牙口 证据重算活链 rc=1 判定串 EVIDENCE-VERIFY-INCHAIN ok 命中=0（应 rc=0 且命中=1，明细 _tools/spr38_run.teeth6.txt）⇒ 无牙或已钝
RUN-RED 文档面 spr38_report_selfaudit rc=1 ⇒ 文档与盘上日志不符（明细 _tools/spr38_run.docaudit.txt）
```

三要素逐条对账：①`RUN 牙口` 出现 **6 行**（旧顺序下 0 行）✅；②**不许见 RUN-GREEN** ✅（`exitB=2`）；③红集＝2 条聚合红 ❌——**现为 3 条**，第三条＝`牙口对面有未登记的臂：[('spr38_run.teeth6.txt','EVIDENCE-VERIFY-INCHAIN RED issues=3 checks=10')]`，`SELF-AUDIT RED checks_run=27 issues=3 docs=2`。**这不是搬迁造出来的新伤，是搬迁把原来被 `exit 2` 吃掉的臂红了**（归因见下）。

### §B.1 牙口面首红三项归因【现读 `teeth6.txt`】

| # | FAIL | 现读证据 | 归属 |
|---|---|---|---|
| 1 | 盘上 player.gd md5 != 文档声称的绿件 | 盘上/`.bak`＝`5835d2e6…`，文档声称＝`dc622351…` | **M3**（GOOD_MD5 判定＋双串） |
| 2 | 绿基线备份本身 md5 != 声称值 ⇒ 收尾互证失效 | 同一根：文档侧仍写 dc62 系 | **M3** |
| 3 | 冻结现算 34/0（缺 0）!= 文档声称 24/10 | `冻结面 现算=34 OK / 0 FAILED（缺文件 0），文档声称=24 OK / 10 FAILED，⛔ 未刷` | **M4**（S41 订正车 13 站） |

⇒ 搬迁的实际收益：**M3/M4 从「靠文档自觉」变成了「链内机器逼还」**——`证据重算活链` 这一臂在重登＋订正车落地前必红，谁也过不去。请主理人在下一张裁定里定：R8 §A.2 的 RUN-GREEN 措辞是否显式加第 3 条（`牙口对面有未登记的臂`），还是记作「M3/M4 未清的临时红，随重登自动消失」——本窗 ⛔ 自选口径。

---

## §C R9 §C 第二条收尾断言：已落盘（M1' 前置就位）

落地件 `_tools/spr40_s9_frozetail_landing.py`（同款三规；额外断言：链件 md5 必须＝搬迁后基准 `df2dea3e…`、新串盘上命中数＝0、`md5sum -c`/`FZ=` 在链里原本 0 命中）。

- 施工窗 09:49:30【现读】：`锁面 ok 龄=5s` → `APPLIED-GREEN lines=237→249 md5 df2dea3e… → 95c501dd6ee3f2a98407e5075754b0e1`；备份 `_backup/spr40_s9_frozetail/20261119-094930/`。
- 插入位置＝第 4 步之后（新 4a，12 行）：`md5sum -c "$FZ"` 落 `$OUT.frozen.txt`，断言 `rc_f=0 ∧ n_ok = n_tab`，**条数读表本身**（`n_tab=$(grep -c '[^[:space:]]' "$FZ")`）⇒ 重登日自动跟随，⛔ 写死 34。
- 复跑验证窗 09:5x【现读】：`RUN 收尾 player.gd == 绿基线 5835d2e6…` ＋ **`RUN 收尾 表体 34/34 全 OK rc=0（条数随表浮动）`**；同窗载荷 `python _tools/spr38_baseline_verbatim_check.py` ⇒ `VERDICT=VERBATIM_MATCH`。
- 施工期一条现场观察值得入台账：本件 `--dry` 自证时若**恰有别的独占窗在 knife 段**，现算会给 `33/34 不符 1`——不符件＝`scripts/player.gd`（刀正挂着）。这不是探针 bug，是「刀在飞」的真信号；**⛔ 拿它当表体漂移**（本窗已用 `md5sum -c … | grep -v ': OK$'` 坐实到具体文件）。

**链件基准串本轮两跳（登记面要用）**：`1fd96ea46dc2ef756774f3e97bfd7347`（237 行）→ `df2dea3e8c2d09778a448f31ef1168ca`（237 行，§B 搬迁）→ `95c501dd6ee3f2a98407e5075754b0e1`（**249 行，现行**）。

---

## §D S41 订正车站点现读行号（对 R8 §D.3-E 的「其余两处按当轮 grep 现值钉」）

用判据件同款抽取式 `(\d+)\s*\*?\s*OK\s*([／/])\s*\*?\s*([0-9?]+)\s*\*?\s*FAILED` 现扫，**总数与 tuple 序列和窗口文档面红集逐字吻合**（AUTORUN 7×(24,10)＋1×(23,11)；B1 4×(24,10)＋1×(23,11)）：

- `_tools/AUTORUN_值守报告.md`（8 处）：**L22 / L101 / L121 / L126 / L146 / L235 / L304**（R8 已点名七处，行号未漂）＋ **L314**＝`23 OK / 11 FAILED`（R8 未列的第八处，本窗现读钉上）。
- `production/sprint-38/SPR38_交付_B1_非弹幕近战内核.md`（5 处）：**L42 / L121 / L191(行内) / L222**＋**L193**＝`23 OK / 11 FAILED`。
- ⇒ 13 处历史数字站点全部现读定位完毕，逐字件可直接按上列行号出（⛔ 沿用 11-18 旧行号）。**注**：L314/L193 那两处是 `23/11` 而非 `24/10`，订正文案要分开出——它们是 R10 之后的另一批声称，别和七处同串处理。

---

## §E R9 §D 一处署名纠错（防它长进 S41 的「落盘件署名」站点）

R9 §D 把 ② 的落盘归给 `_tools/spr40_r37_selfaudit_99_landing.py`，并说本窗把判据件 md5 误标成落盘件 md5。盘上三条证据不合该叙述【现读】：

1. `RUN` 窗日志：`=== run 起跑 09:20:10 cmd=python _tools/spr40_s8_selfaudit99_landing.py --apply ===`；
2. 备份面 `_backup/spr40_s8_selfaudit99/20261119-092011/_manifest.txt` 首行＝`b1a313aad9ec7e65e02a514550260c81 _tools/spr38_report_selfaudit.py`（＝改前态基准），且该目录里存的就是改前原件副本；
3. `_tools/spr40_r37_selfaudit_99_landing.py` mtime＝**09:20:45**（在落盘之后 35s），且值守件 `SPR40_编程侧值守_R37…:126` 自记「只跑了 `--dry`，验到的是『② 已被并行窗做掉』」、`:189`「② 于 09:20:11 由并行窗落地」。

⇒ ② 的落盘件＝**`spr40_s8_selfaudit99_landing.py`**；`r37` 那份是并行值守窗的幂等探针。S41 若要写「落盘件署名」，请用前者。本窗 ⛔ 改主理人任何已发文本，只报事实。

---

## §F 现状与等待项（⛔ 最后等作者点头）

- 已完成：R8 M1.5 **②**（DIFF-SUPPORT 定性，R9 §B 已认）、**④**（`passed=9/9 VERDICT=ARM_HAS_TEETH`，无需施工）、R9 §B(b′) 搬迁、R9 §C 第二条收尾断言、③ 的 verdict＋时长定价。
- 未动、等裁：③ 接链位置（§A 预算表请主理人落「尾部子步 vs 抬 `live` 线」）；`verbatim :31` 窗口右界脆弱点（R8 §C.2 挂号，改判定结构＝单独请示）；`SA_BASELINE_MD5`（R9 §D 定为 M3 函数，⛔ 提前单改）。
- 关键路径：**① tips 十行逐字件（主理人产出）未到 ⇒ M1' 不开工**；`scripts/*.gd` 本窗零改动，登记面零改动。
- 门禁面：`main` 分支 HEAD `4dafdaf`，工作区未提交路径 ≈95 ⇒ 链未绿（M3/M4 欠账现为机器红）**⛔ commit/push**（AGENTS §12）。
