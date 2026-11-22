# SPR41 编程侧呈请 R81：J-4 裁语转录落地／§F-7 验收尺实测／生产码 mtime 两格归因／申报四件（DECLARED-21…24）

- 收件：R79 裁定件 `production/sprint-41/SPR41_主理人裁定_R79_R78八格总裁与C15a历史基线改指登记产物.md`（本窗现算 md5 `6d22f9491e`／256 行——含本单 §B 追加的 §K 附录 6 行；施工起点 `ddfeafd7b8`／250）
- 上一单：`production/sprint-41/SPR41_编程侧呈请_R80_R79车次回执_P2b独红不可达形状表_MISS9归因_F2至F7实测.md` `7cdf3bf0bb`／109（未动）
- 性质：**回执＋归因＋请裁单**。主理人复核意见 J-4 已落地并过验收尺（§B）；J-3 点名的两把生产码 mtime 已现算归因（§C）；本窗新增申报四件 DECLARED-21…24（§D）；判断栏三项请裁（§G）。
- 取号：`ls production/sprint-40 production/sprint-41 | grep -oE "_R[0-9]+" | grep -oE "[0-9]+" | sort -n | uniq -c` 实测 `75×1 76×1 77×2 78×2 79×1 80×1` ⇒ **R81 未占用**，本单取 R81。
- 数字纪律：本单所有 md5／行数／计数＝本窗现读现算，凭据目录 `_tools/spr41_r79/`；失败趟按立规一逐份留号存盘（§E 给每把刀的趟数）。

## §A 硬边界回执（本窗实测，非声明）

| 边界 | 本窗状态 | 证据（现读） |
|---|---|---|
| ⛔ 起链（唯一入口 `_tools/spr38_run.sh`，本批 §F 明文禁链） | **0 趟**：本窗三把刀（s250 写盘／s246 复跑／s251 复核）的证件里没有链行 | `s246_r79_...regression7.txt` 的 `RUN $` 只有三件文档面工具；`s251_r79_j4_verify4.txt` 只读面自证 |
| ⛔ Godot headless 全套（留给 #108） | **0 次**：本窗全部为纯文档面＋只读面刀 | 同上两件证件的 RUN 行；无 `.log` 新件 |
| ⛔ 碰 `_tools/AUTORUN_LEDGER.md` | 未动：现算 `9f2e3c98f7`／999，与 s250 证件 `PRE` 行逐字等 | `s250_r79_j4_ruling_append1.txt` 第 4 条 PRE；`s251` V7 `OK 只读面 10 件 ⇄ 证件 PRE 无漂移` |
| ⛔ 动生产码 | 未动：`scripts/game_main.gd` `b9d46998f6`／7531、`scripts/player.gd` `31bafa6a72`／2654 现算 ⇄ s250 `PRE` ⇄ s251 V7 无漂移；两件 mtime 仍是 12:43:58／13:05:29（早于本窗，见 §C） | `s250_r79_j4_ruling_append1.txt` PRE 末两条；`s251_r79_j4_verify4.txt` V7 |
| ⛔ commit／push／刷 `production/sprint-21/SPR21-FROZEN.md5` | 未做；写盘只落 `_tools/`（刀＋证件＋块文件＋备份）与 `production/sprint-41/`（裁定件 §K 六行） | 本窗写入清单＝§B 落点行＋`_backup/spr41_r79_j4/20261120T134418Z/` |
| ⛔ 进 `D:\大纲` | 0 次访问 | 三把刀的目标面全部在 `production/sprint-41/` 与 `_tools/spr41_r79/` |
| ⛔ 自改锚句／期望常数让门转绿 | 本窗有一条捷径能立刻让 s246 少 5 道闸照旧报绿——把 §K 现读退回「按工具号唯一命中」的换靶分支。**没走**：按裁语把分支删了 | `s246` 刀体现读无「按工具号现查同族干件」；`s251` V6 `OK 换靶分支未再触发`＋`OK 刀体已退役换靶分支且含 §K 现读段` |
| ⛔ 回改 R60…R79 既有裁定正文 | 未改：裁定件前 250 行逐字等、§F 表第 7 行（:237）原句逐字未动，J-4 以 append 追加 §K | `s251_r79_j4_verify4.txt` V3 `OK append-only：前 250 行逐字等`＋`OK §F 表第 7 行原句逐字未动` |

## §B J-4 落地回执（裁语原文照录＋验收尺实测）

- 裁语正文（照录，⛔ 我侧改写措辞）：「裁：J-4 落裁语，按 append-only 在裁定件追加订正行（⛔ 改 :237 原句），验收尺＝s246 E0 现读命令⇄盘上真名逐字等。」
- 落点：裁定件文末追加 §K 附录 6 行（空行＋标题＋空行＋裁语行＋订正指向行＋验收尺落法行）。写盘刀 `_tools/spr41_r79/s250_r79_j4_ruling_append.py` 终态趟 `s250_r79_j4_ruling_append1.txt`：`R79-J4-TRANSCRIBE DONE app=6 前=250 后=256 原句行=1`，`WROTE … md5=6d22f9491e ins=6 del=0 edit=0 eol=lf`；改前态盘上凭据 `_backup/spr41_r79_j4/20261120T134418Z/production/sprint-41/`（现算 ⇄ 证件 PRE `ddfeafd7b8`／250）；追加体逐字件 `_tools/spr41_r79/s250_r79_j4_transcribe_block.txt`（6 行 `69438c2db1`）。
- **验收尺实测（本窗现算）**：s246 最新绿趟 `s246_r79_posttranscribe_docface_regression7.txt` 里三条

  ```
  OK   E0-J4 现读命令⇄盘上真名逐字等：`python _tools/spr38_baseline_verbatim_check.py`
  OK   E0-J4 现读命令⇄盘上真名逐字等：`python _tools/spr40_b/s187_s41_cited_path_verify.py`
  OK   E0-J4 现读命令⇄盘上真名逐字等：`python _tools/spr41_pd_selfconsistency_check.py`
  ```

  且实际跑的就是这三条：`RUN $ python _tools/spr40_b/s187_s41_cited_path_verify.py ⇒ rc=0`。真名 ⇄ 盘上文件逐字等由 `s251` V5 `OK 真名盘上存在` 独立坐实；旧名 `bash _tools/spr40_b/s187_s41_cited_path_audit.sh` 盘上仍不存在（`s251` V5 `OK 旧名盘上仍不存在（DECLARED-15 事实未翻）`）。
- 判据未变（⛔ 因换靶而松口）：终态 `R79-DOC-FACE-REG GREEN issues=0 实咬=33｜code_hits=27 doc_hits=27 expect=27｜S187-CITEDPATH GREEN 已核=45 缺=0 省略=6｜PD-CHECK 应解析=83 实解析=83 参与核对=83 可疑=0 VERDICT=CLEAN_EXEC`，三件终端行 ⇄ `s240_f7_item1…3.txt` 逐字相等。
- 实咬 28→33 的差＝本窗给 s246 新加 5 道 E0-J4 闸（刀侧加牙），不是判据变化；换靶分支与随之成死码的 `same_as()` 一并从刀体删除（DECLARED-21）。
- 独立复核（立规二，另起一把）：`_tools/spr41_r79/s251_r79_j4_verify.py` 终态 `s251_r79_j4_verify4.txt` = `R79-J4-VERIFY GREEN issues=0 实咬=37（闸口 37 减条件分支 0）｜裁定件 6d22f9491e／256（前 250＋追加 6，原句未动）｜验收尺 E0-J4=3 条 ⇄ §K 真名｜只读漂移=无`。

## §C 生产码 mtime 两格归因（主理人 J-3 例外项，如实归因）

| 件 | 现算 md5／行数 | mtime | 归因（谁趟、哪格） | 盘上凭据（本窗现读） |
|---|---|---|---|---|
| `scripts/game_main.gd` | `b9d46998f6`／7531 | 11-20 12:43:58 | **P-K8 施工车**（R79 §C 施工面，非本轮文档面车次）：写刀 `_tools/spr40_b/s158_s41_k8_apply.py`（12:43:53）；其后 12:46 的红态复现臂 `s159_s41_k8_trips.sh`／`s160_s41_k8_red_arm.py` 以 `shutil.copy2` 还原，mtime 随源件保留 | 现值与 `_backup/spr41_k8_red/20261120T044608Z/game_main.gd` **全 md5 逐字等**；三份改前备份 `20261120T044200Z／044249Z／044358Z` 均为 `652ac4b627`（⇒ 现值确由 K8 车写入） |
| `scripts/player.gd` | `31bafa6a72`／2654 | 11-20 13:05:29 | **R79 §C 的 A-2 注释订正刀** `_tools/spr40_b/s161_s41_a2_comment_fix.py`（同行替换、零增删行：把被自家探针证伪的「其后 7 颗全部走 BLOCK」按 P-K8 #81/#82 实测改为「1 颗 PARRY＋1 颗 BLOCK＋6 颗因负号冷却本拍不处理」） | 现值含该刀 NEW 句 1 处、OLD 句 0 处；改前态 `_backup/spr41_a2comment/20261120T050529Z/player.gd`（`d0b008cb2b`，OLD 句 1 处）——目录号 `050529Z`＝UTC，换算 ⇄ 现值 mtime 13:05:29 逐字对上；其后两份只读门件现读到**同一全 md5**（`s179_s38_preflight_measure1.txt` 15:03:20 命中 1 处、`s95g_r8_verify_stdout_1.txt` 15:24:35 命中 4 处）⇒ 13:05:29 之后无再写 |
| 合账 | — | — | 两格均属 R79 已授权施工面，**本轮（轮 20／21／21′／21″／21‴／21⁗）文档面车次对生产码零写入** | `s250` PRE 末两条 ⇄ `s251` V7「只读面 10 件无漂移（含两把生产码）」 |

- 顺带如实报一格：`player.gd` 现值 ≠ 在册绿件基线（`037f261d1b…`），这正是历轮红表 C10a／C10a2 两格，红集合本窗未变（⛔ 我侧动基线）。

## §D 申报四件（DECLARED-21…24；号域由交付件 §9.3 停等归口行同窗 bump）

- **DECLARED-21（工具面自改）**：`_tools/spr41_r79/s246_r79_posttranscribe_docface_regression.py` 的 §F-7 第 2 件换靶分支按 J-4 裁语退役，改现读裁定件 §K「订正指向」行的真名；同刀删除因分支退役而成死码的 `same_as()`。本窗两趟重跑均留盘：`…regression6.txt`（改刀后首趟）、`…regression7.txt`（删死码后确认趟），终态行逐字相等 `GREEN issues=0 实咬=33`；判据件与三件被复跑的工具⛔ 未动。
- **DECLARED-22（复核刀刀侧缺陷三趟）**：`s251_r79_j4_verify1…3.txt` 三趟皆我刀侧问题，修复全在刀侧：cert1 用 `s250*txt` 取证件，把块文件 `s250_r79_j4_transcribe_block.txt` 一起收进来，「成功趟＝最大号」判定被自家块文件撞翻；且 `w.groups()` 六元组塞进单个 `%s` ⇒ `TypeError`。cert2 把 WROTE 行的 `lines=`（写后行数）当写前用，行数账式子差 6。cert3 备份目录层级算少一层（`dirname` 两次已到 `production`），且 V8 自计数把源码里 `"chk("` 与 `"条件闸"` 两个字面行自己算了进去 ⇒ 站点数与实咬数各偏 1。判据件／裁定件在三趟里⛔ 未动；终态 cert4 GREEN 实咬=37（条件分支 0，每闸恰跑一次）。
- **DECLARED-23（生产码 mtime 归因）**：§C 两格结论入账——`game_main.gd`＝P-K8 施工车（12:43:58）、`player.gd`＝A-2 注释订正刀 s161（13:05:29）；均非本轮文档面车次，且各自有盘上备份与只读门件佐证。
- **DECLARED-24（卫生缺口，自曝）**：s161 那趟写生产码的 stdout **没落成编号证件**（立规一的逐份留号规矩晚于该趟），本窗只能以「改前态备份目录＋刀体自带的锚句断言＋两份后续只读门件的全 md5」三方互证；现值 `31bafa6a72`／2654 无任何**写后**快照。请裁见 §G J-A。

## §E 本窗凭据终态一览（逐刀趟数；失败趟按立规一全部留盘）

| 刀 | 性质 | 趟数（终态趟） | 终态行（现读） |
|---|---|---|---|
| `s250_r79_j4_ruling_append.py` | 写盘（裁定件 §K） | 1（cert1） | `R79-J4-TRANSCRIBE DONE app=6 前=250 后=256 原句行=1` |
| `s246_r79_posttranscribe_docface_regression.py` | 只读复跑（§F-7 三件） | 7（cert7；cert1…3 刀侧缺陷趟、cert4/5 转录前后绿趟、cert6/7 J-4 换靶后绿趟） | `R79-DOC-FACE-REG GREEN issues=0 实咬=33` |
| `s251_r79_j4_verify.py` | 独立复核（J-4 车） | 4（cert4；cert1…3 刀侧缺陷趟） | `R79-J4-VERIFY GREEN issues=0 实咬=37` |
| 承前（未在本窗重跑，仅列终态供对账） | — | — | `s245_r79_transcribe_verify6.txt` `R79-TRANSCRIBE-VERIFY GREEN issues=0 实咬=85`；`s247_r79_ledger21t_append3.txt` `R79-LEDGER-21T DONE ins_ledger=1 edit_deliv=1`；`s248_r79_ledger21t_verify3.txt` `R79-LEDGER-21T-VERIFY GREEN issues=0 实咬=41`；`s249_r79_postcar_qgate_regression2.txt` `R79-QGATE-POSTCAR GREEN issues=0 实咬=15` |

## §F 停等归口

- **作者级（唯一）**：**#108 独占窗放行**——链＋Godot headless 全套＋`red=0`／`miss=0`／C15e 入册三格只能在那扇窗内出证；本批 §F 明文禁链，我侧⛔ 自开。
- 主理人级：§G 三项（J-A 历史生产码写入的等效凭据口径／J-B #108 时点／J-C R80 §J-1 P2b 独红三选项仍未裁）。
- 编程侧自有待办（不占停等，按号可查）：#6 #10 #14 #38 #40 #52 #70 #77 #89 #106 #112 #115 #122 #131；其中 #112／#115 按 R79 §D 已作废为「被更新代次取代」，待主理人确认后关号。
- 解禁条件（可判、不需作者点头）：§C-③ 第 5 条 env 换件名（现读仍判「落地＝净变差」，保持不落地并留痕）；§C-⑦ P2b 独红结构不可达（6 发形状表已交，等 J-C）；§C-④⑤⑥ 已落地出证，无停等。

## §G 判断栏（请主理人裁三项；裁语回后我侧按裁语施工，⛔ 代裁）

- **J-A 历史生产码写入的等效凭据口径**：DECLARED-24 那格——s161 写 `player.gd` 无编号证件，现值亦无写后快照。三选项：（甲）追认「改前态备份＋刀体锚句断言＋后续只读门件全 md5」三方互证为等效凭据，并把该口径写进立规一（此后生产码写入趟一律先落证件号）；（乙）要求我侧为该类历史写入补一份现算对账件（本单 §C 已是该件的正文版，是否再落独立刀）；（丙）判为不足以入账、要求恢复该趟的可重放路径（需重跑 s161 的断言面，⛔ 再写一次生产码）。我侧倾向甲，但落地口径请裁。
- **J-B #108 独占窗放行时点**：本批文档面已全部收口到「只差那扇窗」；请给时点或给「继续等」的显式停等号，我侧⛔ 自行开窗。
- **J-C R80 §J-1 P2b 独红三选项**：仍未裁 ⇒ §C-⑦ 的解禁条件保持「待裁」，我侧继续⛔ 自改独红断言（本窗第二次带着实测催办）。

---

（本件不写自己的 md5／行数——§F3 证据卫生；一切数字请对着上表出处路径现算复现。生产码两件的 mtime 归因见 §C，申报号见 §D，本窗写盘面只有裁定件 §K 六行与 `_tools/spr41_r79/` 的刀与证件。）
