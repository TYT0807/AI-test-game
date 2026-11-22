# SPR41 主理人裁定 R77：R76 §C／§F／§E-3.1 三处不可执行面的重裁 ＋ taut 存在性闸补票（格③改判「零刀面」、格⑧采第三条路、§E-3 换可满足尺子）

- 收件：编程侧 S41 施工回执（R76 §B/§D/§E/§H 已落地并自报实测数；§C、§F、§E-3.1 三处申报**逐字不可执行**，呈请下一轮，未自行降级）。本窗按纪律自己现读磁盘复核，⛔ 照抄回执。
- 上一轮正典：R76（`production/sprint-41/SPR41_主理人裁定_R76_停等六项刀相与口径收口.md`，本窗现算 md5=`c184a7c0006e514b6df59627f5737c3e`／154 行，与回执相符）。编号自证见 §K-1。
- 本件管四件事：①对三处不可执行面**重新裁定**（其中一处推翻 R76 自己的前提）；②对 §B 落地下来的口子（taut 无存在性闸）给补票裁语；③独立核验披露（本窗现读现算）；④把仍锁在作者保留权的东西点名锁住——本轮**没有任何一格需要作者答**，判断栏为空。
- 硬边界回执：本窗只新建本件一份文件；未改 `S41_台账.md`、`SPR41_编程侧交付_A组.md`、任何 `_tools/*` 脚本、`scripts/*.gd`、口径件；未起链、未开独占窗、未跑 Godot、未刷冻结表、未进 `D:\大纲`。事实落盘由编程侧按 §J 转录件以带断言搬盘刀执行。

## §A 总裁一览

| 格 | 事项 | 裁定（一句话） | 落点 |
|---|---|---|---|
| ③-a | `_pd_assert` 要不要立案进普查宏清单 | **不立案**（R76 §C-2.1 的「一处改动」成本估计被盘上实测推翻）⇒ 改为**双轨**：恒真普查面维持九 macro 逐字不动；`_pd_assert` 那 83 个站点的盲区由新立机检 `spr41_pd_selfconsistency_check.py` 正面覆盖 | §C |
| ③-b | 宏清单／死针 `MACROS=9`／基线数 568 的同步次序与期望值 | **随 ③-a 一并归零**：三者本次一个都不动；另把 r8 面两处会腐烂常数改成从 census 现读派生（`C1a` 标签、`P2b` 毒臂目标串），⛔ 留死数字在判据里 | §C |
| ③-c | `_ct_assert` 83 个 live 站点本次动不动 | **零动**（它们今天已经在普查面上被逐条解析，无任何要动的理由） | §C |
| ⑧ | s166 宿主文档注入 vs 「三刀本体零改动」的自相矛盾 | **第三条路**：s166 本体本次零改动，门禁**不接**它；改立一把新的常驻包装刀持 DOC 入参审当批交付件；s168 的门禁归属**随车同判**（不进门禁，登记轮凭据）；s187 维持 F-2.3/F-2.4 不变 | §F |
| ⑥′ | §E-3.1 验收 grep 判据不可满足 | **重立尺子**：旧短语命中数从「==0」改判「==1 且该行即作废句本身」；另用「第一次结算走 PARRY」==0 作旧断言复活的探针。§E-2 已落地的替换文本**不回改** | §E |
| ②′ | taut 缺路径存在性闸（§B 落地下来的口子） | **补**：quota/verbatim 同款两行闸，插两处而非一处（生产面＋`--falsify` 面）；429→432 行 | §B |
| ① | 换代四件套／收官车／数值口径／美术硬指标 | **作者保留权，维持停等**，本件零裁语 | §G |

## §B 格②′：给 `spr38_tautology_sweep.py` 补存在性闸（补票，非回改）

### B-1 本窗独立复现【现读】

1. 现状坐实：`_tools/spr38_tautology_sweep.py:20` 逐字 `ROOT = os.environ.get("SPR38_ROOT") or r"D:\Create\Game\test-1"`（§B-2.3 已落地，md5 `1da94bd93d`／429 行与回执相符）。该件**全文无一处路径存在性闸**：`grep -n "os.path.exists" _tools/spr38_tautology_sweep.py` 只命中 `knife_proof()` 内部那一处（`:196`，只管豁免档案），对 `GM`／`scripts` 目录零防护 ⇒ 喂错 ROOT 时 `load(GM)` 直接 traceback、rc 非 0 但**读数不可读**（HP-8 说的正是这个形状：故障安全≠取证可读）。
2. 同款先例坐实【现读】：quota `:62-63`（`FAIL 路径缺失 GM=… WP=…（UNEXECUTED，HP-8）`）、verbatim `:15-16`（`FAIL DOC 缺失 code=… DOC=…（UNEXECUTED，HP-8）`）。两件都是「main/check 入口第一件事就是闸」。
3. 🔴 **坑位坐实（这条决定施工形状）**：`--falsify` 分支（`:288-289`）在 `srcs = sources(all_files)`（`:350`）**之前**就 `load(GM)`。只把闸插在 `:350` 之后 ⇒ 跨树干跑（§B-3.2）和 gates 反空转趟（`:11` `set -u`＋`cd "$ROOT"` 会让相对 OUT 落到别的树里）会拿到一个**traceback 而不是 `FAIL 路径缺失`**。所以必须插两处。

### B-2 裁语与施工（两处插入，共 +3 行）

前置备份：`_backup/spr41_r77_taut_gate/<UTC戳>/` 收 `spr38_tautology_sweep.py` 改前整件字节（现值 `1da94bd93de49ed55380a149c1e5f92d`／429）。

1. **插入点一（`--falsify` 面）**：锚＝逐字两行（全件唯一，本窗 `t.count("    if falsify:\n        src = load(GM)")`==1 已验）：
   ```python
       if falsify:
           src = load(GM)
   ```
   在这两行**之前**插入三行（一行注释＋两行闸）：
   ```python
       # HP-8 同族：喂错／喂空的 ROOT 必须打成可读的 UNEXECUTED，⛔ 让 io.open 的 traceback 冒充判定。
       if not os.path.exists(GM):
           print("FAIL 路径缺失 GM=%s（UNEXECUTED，HP-8）" % GM); return 1
   ```
2. **插入点二（生产面）**：锚＝逐字一行（全件唯一）`    srcs = sources(all_files)`，在其**之前**插入两行：
   ```python
       if not os.path.isdir(os.path.join(ROOT, "scripts")):
           print("FAIL 路径缺失 scripts=%s（UNEXECUTED，HP-8）" % os.path.join(ROOT, "scripts")); return 1
   ```
3. 除这五行的净增部分（+3 行）外，本件其余内容**逐字不动**；⛔ 顺手把 `--all` 目录也做成可注入（那是另一格，本轮不扩面）。
4. 期望终态：**432 行**（429+3）；md5 由施工趟现算登台账（⛔ 本件预设）。行数口径一律 `wc -l`。

### B-3 验收（三条，均可满足）

1. 正跑不破坏：`bash _tools/spr38_gates.sh <OUT>` ⇒ `spr38_g_chk_taut … verdict_hit=1 expect=1`、汇总行仍 `合计 应解析=568 实解析=568 可疑(T1+T2+T3)=0`（本格⛔ 改变读数，只改失效形状）。
2. 反空转（新行为，逐字命令）：
   ```bash
   SPR38_ROOT=/nonexistent_xyz python _tools/spr38_tautology_sweep.py --all _ml_assert; echo "rc=$?"
   ```
   期望 stdout 含逐字 `FAIL 路径缺失 scripts=/nonexistent_xyz/scripts（UNEXECUTED，HP-8）` 且 `rc=1`。
3. 反空转第二面（证明插入点一生效，⛔ 只跑第 2 条就宣称两面都过）：
   ```bash
   SPR38_ROOT=/nonexistent_xyz python _tools/spr38_tautology_sweep.py --falsify; echo "rc=$?"
   ```
   期望 stdout 含逐字 `FAIL 路径缺失 GM=/nonexistent_xyz/scripts/game_main.gd（UNEXECUTED，HP-8）`、`rc=1`，且 stderr **不含** `Traceback`。
4. 证件落 `_tools/spr41_r77/`，命名带序号，失败态留盘（§H-4 卫生沿用）。

## §C 格③：`_pd_assert` —— 推翻 R76 前提，改判「零刀面」双轨

### C-1 本窗独立复现【现读】（逐条对上编程侧申报，结论：申报成立）

1. `_ct_assert` **不是别名**：`grep -c "_ct_assert" scripts/game_main.gd`=84，其中定义 1 处（`:755 func _ct_assert(ok: bool, nn_name: String, measured, expect) -> void:`）、live 调用站点 83 处（首站 `:871`、末站 `:1555` 区间内连续分布，形态是灾祸通道／幂等／文案那一批真判据）。R76 §C-2.1 那句「同行替换 `_ct_assert Dev.check` → `_ct_assert _pd_assert Dev.check`」的隐含前提（它只是普查宏里的一个名字）**与盘上冲突**：加一个 macro 名进 argv 不会让 83 个既有站点变成 166 个，只会新增 `_pd_assert` 自己的 83 个站点。
2. `_pd_assert` 同样是**活宏**：`grep -c "_pd_assert"`==84，定义 1 处（`:5775`）＋站点 83 处（`:5849`–`:6270`，P1~P9／PR／K8 那一批）。⇒ 立案会让合计从 568 跳到 651（本窗算术演示：568+83），**这确实是新增覆盖面**（不是把已受检的东西冒充成新覆盖），代价就是 C-1.3 那一串会腐烂的常数同步；R76 §C 把它估成「一处改动」，是错的。
3. 牵连面逐个坐实【现读】：
   - `_tools/spr38_r8_verify.py:70` 逐字 `MACROS = 9`；`:245` 标签 `"C1a macro 块数==9"`；`:255` `blocks == MACROS`。⇒ 十 macro 后 `C1a`/`C2` 双双见红。
   - `_tools/spr38_r8_verify.py:656-657`（`P2b` 毒臂）目标串 `"合计 应解析=%s 实解析=%s" % (_tot_want.group(1), _tot_got.group(1))` 是从 census **现读派生**的（`:649-650`，assert 抽不到形状就抛错）⇒ 这一处**不**随 568 腐烂，属好消息；但同一族的 `:655`（`P2` 臂）目标串是写死的 `"应解析=70 实解析=70"`，绑的是 `_ml_assert` 的 70，与本格无关，⛔ 顺手改。
   - 宏清单在盘上是**三份复制**（这是 R76 §C 没管的真正风险）：`spr38_gates.sh:98`、`spr38_q3_wiring.py:38`（BLOCK 内）、`spr38_q3_armtest.sh:125`（I 臂夹具）。三份都逐字含 `_ct_assert Dev.check`（各 count==1）。
   - wiring 的幂等比对只抽 `RC_TT=$?`→`TAU=${TAU:-0}` 区间（`:169-175 disk_block`），调用行在区间**之外** ⇒ 只改 gates `:98` 不会触发 `DRIFT`；但一旦有人日后跑 `--reland`，它会拿 BLOCK 整段重写 gates，把 `:97` 的 `SPR38_ROOT="$ROOT"` 前缀和 `:98` 的新 macro 一起抹掉（假绿形状）。这条是「改了宏清单不改 wiring」的真实事故半径。
   - `_tools/spr38_report_selfaudit.py` 里**没有**宏数钉（本窗 `grep -n "MACROS"` 在该件零命中；R76 §C-1 的说法在此件上不成立，如实纠正我自己）。
4. 568 的性质【现读】：`合计 应解析=568 实解析=568` 写在 `_tools/spr38_g_chk_taut.txt`（普查产物，非源码常量），九块分解为 70/28/12/19/9/15/43/83/289，求和==568 本窗自算闭合。它是**历史基线数**，按边界属作者保留权②，我不能自改，也不能自定 651 为新基线。

### C-2 裁语（三个子问，逐条答）

**(a) 要不要立案 `_pd_assert`？——本轮不立案，但盲区必须以别的方式关掉。**
先把账算清（⛔ 含糊）：`_pd_assert` 的 83 个站点**今天确实完全不在恒真普查眼下**（宏清单里没有它），所以「立案」在语义上不是假覆盖面——R76 想开的这扇窗是真的。问题只在成本被误估：加这一个名字会把宏清单从九改到十，连带 gates/wiring/armtest **三份复制**＋r8 两处常数＋568 基线代次全部同步，而这笔同步里含一个只有作者能拍的数（新合计）。理由三条按权重排：①上述同步属**口径事件**，落在作者保留权②的边缘，我不该为省一件新刀的费用去动它；②R76 判「一处改动」时把 `_ct_assert` 当成了普查宏里的别名（盘上实为 83 个 live 站点），前提错、估价就错；③真正的目的（让 `_pd_assert` 的 83 站受机检）可以用一件**新只读机检**达到，零牵动既有常数。⇒ 裁「双轨」：恒真普查面（T1/T2/T3 家族）本轮**逐字不动**；另立一件专查 `_pd_assert` 三态自洽与两侧同源的常驻机检。

**(b) 若立案，三者的同步次序与期望值？——本问随 (a) 否决而失效，但把「将来真要立案时必须按这个次序」写成条文留给后续轮（⛔ 任何一轮自行执行）：**
次序固定为 **C-2b.1 现读普查 → C-2b.2 同步宏清单三份复制 → C-2b.3 改死针 → C-2b.4 代次换号登记 → C-2b.5 复跑对账**，缺一环即为假绿：
1. 先在候选树上跑十 macro 普查，拿到 `macro=_pd_assert 应解析=N 实解析=N` 与新的 `合计` 行，N 与合计**只能来自这一次实跑**（⛔ 由任何一方预先拍数，含本件：本窗按盘上站点数推得的 651 只作算术演示，不作期望值）。
2. 三份宏清单复制**同一轮**改齐（gates `:98`、wiring `:38`、armtest `:125`），并在台账点名「宏清单三份复制已同步」——这正是 R76 §C 漏掉的那道卫生。
3. `spr38_r8_verify.py:70` `MACROS = 9`→新数，`:245` 标签同步；标签与常数不同源由 `C1a` 自己拦。
4. 568 处置沿 R76 §C-2.3(c)：旧数封存、新代次现算登台账一行，⛔ 回改 R/S 系列历史正文里的 568。
5. 复跑 `bash _tools/spr38_run.sh` 全链一次（须独占锁，由作者或值守窗放行），`R8-VERIFY VERDICT=GREEN` 才算这一格收口。

**(c) `_ct_assert` 83 个 live 站点本次动不动？——零动。**
它们在普查面上已被逐条解析（`应解析=83 实解析=83`，缺口 0），改名、拆并、加豁免都属方向级动作，本轮没有任何一条证据要求动它们。⛔ 借本格「顺手统一命名」。

### C-3 附带裁语：把本格暴露出的两处「会腐烂常数」修成派生（这才是真正的机检缺陷）

前置备份同上（`_backup/spr41_r77_const_derive/<UTC戳>/` 收 `spr38_r8_verify.py` 现值 `fdb7a6876eff85f82331df754a80e1dc`／798、`spr38_q3_wiring.py` 现值 `4a3e9d24cd527482487046b7f943fd4d`／247）。

1. **`spr38_r8_verify.py` 三处同行替换／两处插入（净 +2 行 ⇒ 800 行）**：
   - `:245` 逐字 `    chk("C1a macro 块数==9", ce is not None, blocks == MACROS,`
     → 逐字 `    chk("C1a macro 块数==%d" % MACROS, ce is not None, blocks == MACROS,`
     （标签不再印死数字；`chk()` 第一实参是**标签**，`--selftest` 的 `expect` 匹配吃它，故必须同步派生。）
   - `:656-657`（`P2b` 臂）目标串从 census 现读派生。逐字原文（两行，⚠️ 引文**不带**缩进，落地时须按上下文带四空格函数体缩进；本窗现测：全件里以零缩进起始的 `poison("P2b` 行不存在，唯一命中在 `:656` 的四空格缩进态）：
     ```python
         poison("P2b macro 块被并入汇总行（tr 类抽取坑）", "C1a", lambda c, f: c.__setitem__("census", (c["census"] or "").replace(
             "合计 应解析=%s 实解析=%s" % (_tot_want.group(1), _tot_got.group(1)), "macro=x 应解析=1 实解析=1", 1)))
     ```
     替换为逐字（五行，同样四空格起）：
     ```python
         _blk_want = re.search(r"^macro=\S+\s+应解析=(\d+) 实解析=\1", corp0["census"] or "", re.M)
         assert _blk_want, "R77 §C-3 P2b 派生失败：census 无『macro=… 应解析==实解析』形状（⛔ 静默 no-op）"
         _blk_m = re.search(r"^macro=(\S+)", corp0["census"] or "", re.M)
         assert _blk_m, "R77 §C-3 P2b 派生失败：census 无 macro 块名"
         poison("P2b macro 块被并入汇总行（tr 类抽取坑）", "C1a", lambda c, f: c.__setitem__("census", (c["census"] or "").replace(
             "macro=%s 应解析=%s 实解析=%s" % (_blk_m.group(1), _blk_want.group(1), _blk_want.group(1)),
             "合计 应解析=%s 实解析=%s" % (_tot_want.group(1), _tot_got.group(1)), 1)))
     ```
     ⇒ 行序即最终行序：两个 `search` 各跟一条 `assert`，再走 `poison`（⛔ 把 assert 引用挪到定义之前——那正是下面那条自我引用呈请要防的形状）。语义＝拿 census **第一个 macro 块**（现读为 `_ml_assert 70/70`）那一行冒充汇总行，看 `C1a` 抓不抓得到；目标串与替换串都现读派生，⛔ 留 568／70 这类死数字。
     ⚠️ 编程侧若发现上面这段仍与盘上上下文冲突（缩进、`corp0` 作用域或正则不匹配），**不要自行改写判据**：按原样留盘、跑 `--selftest`、把实测贴回来呈请 R78。本格允许失败，不允许静默放宽。
   - 期望终态：**802 行**（798+2＋P2b 净增 2）。
2. **`spr38_q3_wiring.py:36` 注释那句「九 macro 全列」**：本格**不动**它。理由：`:36` 与 gates `:96` 逐字相同（本窗坐实），而 `disk_block`（`:169-175`）只抽 `RC_TT=$?`→`TAU=${TAU:-0}` 区间，调用行与注释都在区间之外 ⇒ 不动它既不触发 DRIFT、也不影响判定；等 §C-2(b) 那条路线真被执行时再随宏清单同轮处理。⛔ 本轮顺手改注释。
3. **验收**：
   - `python _tools/spr38_r8_verify.py` ⇒ 末行 `R8-VERIFY VERDICT=GREEN`（⛔ 出现 `RED`，也⛔ 把 `unexecuted=N` 读成绿）。
   - `python _tools/spr38_r8_verify.py --selftest` ⇒ `SELFTEST arms=<现算> miss=0 skip_busy=0`＋末行 `SELFTEST ok`。
   - **关键自证（一次性，跑完留证，⛔ 常驻化）**：在 `_tools/spr41_r77/` 的 census **副本**上手工把第一个 macro 块行的读数改掉（例如 `应解析=70 实解析=70` → `应解析=70 实解析=69`），派生式必须仍能拼出该串并让 `C1a` 见红——这证明 P2b 的目标串不再靠死数字。若派生结果为空／不匹配 ⇒ 按上面「允许失败」条款回呈。

### C-4 新立机检（`_pd_assert` 盲区的正面覆盖）——裁语＋验收

1. 新建 `_tools/spr41_pd_selfconsistency_check.py`（纯标准库、只读、零 Godot），职责两条，⛔ 与恒真普查混件：
   - **三态自洽**：每处 `_pd_assert(ok, name, measured, expect)` 的 `ok` 实参必须是**表达式**而非字面量 `true`/`false`；`measured` 与 `expect` 逐字相同的站点 ⇒ 记 T1 型可疑。
   - **两侧同源形状**：`measured` 串与 `expect` 串规范化后相等，或 `ok` 实参里两侧变量同名（`a == a`）⇒ 打 `SUSPECT PD-T*` 行。
   - 末行必须打 `PD-CHECK 站点=%d 参与核对=%d 可疑=%d` ＋ `VERDICT=CLEAN_EXEC`／`HAS_SUSPECT`／`UNEXECUTED`（零输入面一律 `UNEXECUTED`，HP-8）。
2. 站点数下限**从代码现读派生**（`grep -c "_pd_assert("` 减定义），⛔ 在本件或新件里写死 83。本窗的算术演示：`scripts/game_main.gd` 里 `_pd_assert` 命中 84、其中 def 1 ⇒ 站点 83；该数只作演示，⛔ 当新件的期望常数。
3. 接线：由编程侧按现行离线面形状接入 gates 零 Godot 段（与 quota/verbatim/fp 同一 for spec 循环），🔴 checks 期望数现算化（R70 §E-2 通道），⛔ 拍常数。
4. 🔴 **硬前置（先证有牙再谈绿）**：新件首趟若打出 `SUSPECT PD-T*` ⇒ 判红、如实回呈主理人，⛔ 顺手放宽判据或加豁免名单吃掉。
5. 本件不给新件的期望可疑数——盘上没跑过，任何数都是我拍的。

## §E 格⑥′：V-A4 那句的验收尺子重立（已落地文本不回改）

### E-1 本窗独立复现【现读】

- 口径件 `production/sprint-41/SPR41_验证口径.md` 现值 `eaf37a248bfdd0a971959c9e0fbbb1ba`／139 行、CRLF=0（与回执相符）。
- `:34` 现文逐字含两段：正向新表述「**1 颗走 PARRY＋1 颗走 BLOCK（`_parry_hit_cd>0`）＋6 颗本拍不处理**」，以及作废点名「旧表述「其后 7 颗全部走 BLOCK」由 R76 §E 作废」。
- 尺子现测：`grep -c "其后 7 颗全部走 BLOCK"`==**1**、`grep -c "第一次结算走 PARRY"`==**0**、`grep -c "1/2/6"`==1。⇒ R76 §E-3.1 那条「旧短语命中==0」与 §E-2 自己要求的替换文本**结构上不可能同时成立**（编程侧申报成立，责任在我）。
- 语义判别：命中的那一行是**作废句**，不是旧断言复活；旧断言的真身短语是「第一次结算走 PARRY」（盘上 0 命中）。所以正确的尺子是「旧短语恰好出现在作废句里、旧断言真身零出现」。

### E-2 裁语：重立验收（⛔ 回改 :34 文本，⛔ 把点名串删掉来凑 0）

逐字命令与期望输出（四条全过才算 §E 收口）：

```bash
cd D:/Create/Game/test-1/production/sprint-41
grep -c '其后 7 颗全部走 BLOCK' SPR41_验证口径.md          # 期望 1
grep -c '第一次结算走 PARRY'    SPR41_验证口径.md          # 期望 0
grep -c '由 R76 §E 作废'         SPR41_验证口径.md          # 期望 1
awk '/其后 7 颗全部走 BLOCK/{print NR}' SPR41_验证口径.md   # 期望 34
wc -l SPR41_验证口径.md                                    # 期望 139
```

补充说明（供后续轮引用，⛔ 当新常数）：第 4 条用行号只为指认「命中落在哪一行」，其成立条件是**该行同时含「由 R76 §E 作废」**；若日后口径件增删行，以该复合条件为准，不以 34 为准。

### E-3 口径级追认（一句，供转录）

R76 §E-3.1 作为验收条款**作废**，由本件 §E-2 五条命令取代；§E-2 的施工条款（同行替换、139 行不变、difflib 限 1 段）**仍然有效且已达成**，无需返工。

## §F 格⑧：s166 注入 vs 「三刀本体零改动」——采第三条路

### F-1 本窗独立复现【现读】

- `_tools/spr40_b/s166_s41_deliverable_quote_audit.py:17-18` 逐字：
  ```python
  ROOT = r"D:\Create\Game\test-1"
  DOC = os.path.join(ROOT, "production", "sprint-41", "SPR41_编程侧交付_A组.md")
  ```
  全文 `grep -n "OUT\|argv\|environ"` **零命中** ⇒ R76 §F-1.1「支持 OUT 注入（用法行现读）」是我读错，如实纠正：s166 既不接受 OUT 也不接受 DOC，宿主件焊死在 `:18`。
- 因此 R76 §F-2.1（把宿主件做成可注入）与 §F-2.5（三刀本体零改动）互斥，编程侧申报正确。
- s168 的耦合坐实【现读】：`_tools/spr40_b/s168_s41_quote_audit_falsify.py:15-17` 自带 `SRC = "_tools/spr40_b/s166_s41_deliverable_quote_audit.py"`、`DOC_REL = "production/sprint-41/SPR41_编程侧交付_A组.md"`；`run_audit()`（`:36-42`）靠 `once(audit_text, DOC_CONST, …)` 把 s166 源码里的 `DOC` 常量整行替换后才跑——`DOC_CONST`（`:27`）逐字 `'DOC = os.path.join(ROOT, "production", "sprint-41", "SPR41_编程侧交付_A组.md")'`；m5 臂（`:90-92`）又钉 `ROOT = r"D:\Create\Game\test-1"` 这一行。⇒ **只要 s166 的这两行任一改动，s168 立刻 `PRE … 命中=0 ⇒ 造错点不唯一` 见红**。这就是「s166 改刀体」的真实成本，R76 也没算。
- s187 的形状坐实【现读】：`:21-23` 三个常量（`ROOT`／`LEDGER`／`DELIV`）＋`OUT` 全焊死，`:129` 还会往 `OUT` 写盘 ⇒ 天然批次绑定＋自指，R76 §F-2.3 的判断不受本次影响。

### F-2 裁语（第三条路）

1. **s166 本体本轮零改动，且不接入门禁。** 它的身份回到「S41 批内的一次性审计刀」：审的就是这份焊死的交付件，批次结束后随 s187 一同归档，⛔ 常驻化。
2. **门禁离线面若要「引文逐字可溯」这道门，用新刀实现**：新建 `_tools/spr41_deliverable_quote_gate.py`，要求逐条满足——
   - 宿主文档路径经 **argv 位置参数或 env** 注入（默认值仍指当前批交付件，env 未设时行为等价）；⛔ 把任何具体批次文件名当唯一真相写进判据逻辑。
   - 语料目录清单同样可注入；一手／二手分级、`MISS`／`SECONDARY` 按行剔除这两条口径**照 s166 现有语义实现**（那是它已被 s168 证过有牙的部分）。
   - 零输入面（一手行=0／参与核对=0）一律 `QUOTE-GATE-RED`＋非零退出码，HP-8 同款。
   - 末行 `QUOTE-GATE-GREEN`／`QUOTE-GATE-REVIEW`；接点与臂数由编程侧按现行离线面形状落地，🔴 checks 期望数**现算化**（R70 §E-2 通道），⛔ 拍常数。
3. **s168 的门禁归属随车同判：不进门禁**，维持「凡动引文审计口径那一轮必须附一趟 `mutants=5` 绿证」的登记轮凭据身份（R76 §F-2.2 语义不变）。🔴 追加一条硬约束：新刀落地那一轮，s168 的 `SRC`／`DOC_CONST`／m5 针三处**必须同轮**改指新刀并重新证牙，否则 s168 的红会被误读成「老刀坏了」——届时按 C-3 的规矩：允许失败、如实回呈，⛔ 自行放宽 `once()` 的期望命中数。
4. **s187 维持 R76 §F-2.3／§F-2.4 原裁**（永久不进门禁；防复发两条成文继续适用于后续所有文档刀）。本件不回改也不重申细节，只登记「未被本轮推翻」。
5. R76 §F-2.1 中「s166 → 转正，接入门禁离线面」这一句作为**施工指令作废**（append-only，不回改 R76 正文；作废点名进 §J-2）。

## §G 作者保留权（维持停等，本件零裁语）

以下任何一方⛔ 动：换代四件套（冻结表两靶转正＋绿件晋升＋三针同步＋floors 声称层）＝作者保留权④／收官车；**普查基线数的代次重定**（若将来真要走 §C-2(b) 那条路，新合计属此项）＝作者；§9.3 美术硬指标＝作者；task #108 跨窗复现趟＝排在收官车秩序之内，不由本件提前放行。本件的判断栏为**空**：三处呈请都能在主持人权限内自裁，没有一项需要作者先答题。

## §H 施工车次与顺序（编程侧按此跑，⛔ 自行调序）

1. §B（taut 补闸，+3 行）→ §C-3（r8 常数派生化，+4 行）→ §C-4（新立 `_pd_assert` 机检＋接线）→ §F-2.2（新立引文门禁刀）→ §E（零施工，仅重立尺子）。
2. 🔴 硬前置：§C-4 与 §F-2.2 都是**新建件**，首趟必须按各自「硬前置」条款先证有牙再谈绿；任一条打红 ⇒ 停在原地回呈，⛔ 用放宽判据换取通过。
3. 🔴 全程⛔ 起链（唯一入口 `bash _tools/spr38_run.sh` 且需独占锁）、⛔ git commit/push、⛔ 刷 `production/sprint-21/SPR21-FROZEN.md5`、⛔ 进入 `D:\大纲`、⛔ 自改锚句／断言／期望常数让门转绿。
4. 证件一律落 `_tools/spr41_r77/`，命名带序号（`s197_r77_*` 起，避开已用到的 `s189`–`s196`），失败态留盘（先 `mv` 上一份 stdout 成序号名，⛔ 原地冲）。

## §I 本窗现读坐标清单（每条都现场读过，⛔ 引 R76 的行号）

| 对象 | 现值 | 现读点 |
|---|---|---|
| `production/sprint-41/SPR41_主理人裁定_R76_停等六项刀相与口径收口.md` | `c184a7c000…`／154 | 全文（§C-2.1／§F-2.1／§F-2.5／§E-2／§E-3.1 逐字） |
| `scripts/game_main.gd` | `b9d46998f6…` | `_ct_assert` 命中 84＝def `:755`＋站点 83（`:871`–`:1555`）；`_pd_assert` 命中 84＝def `:5775`＋站点 83（`:5849`–`:6270`） |
| `_tools/spr38_tautology_sweep.py` | `1da94bd93d…`／429 | `:20` ROOT 注入态；`:196` knife_proof 唯一 exists 闸；`:250-270` sweep；`:273-290` main（`--falsify` 早于 `:350`）；`:350` `srcs = sources(all_files)`；`:407` 合计行 |
| `_tools/spr38_gates.sh` | `3dd1bb03b3…`／130 | `:8 set -u`、`:11` ROOT、`:79/:80/:97` 三处 `SPR38_ROOT` 前缀（count==3）、`:96` 注释、`:97-98` 九 macro 清单、`:99-115` 判据段 |
| `_tools/spr38_r8_verify.py` | `fdb7a6876e…`／798 | `:70 MACROS = 9`、`:245` C1a 标签、`:255` C2、`:277-279` C4 `(4,0)`、`:649-652` 派生 assert、`:655` P2 死串、`:656-657` P2b、`:772-798` main/selftest |
| `_tools/spr38_q3_wiring.py` | `4a3e9d24cd…`／247 | `:36-38` BLOCK 头（`:38` 与 gates `:98` 逐字同）、`:169-175 disk_block`、`:178-187` ALREADY-WIRED/DRIFT、`:231` 整块重写 |
| `_tools/spr38_q3_armtest.sh` | `b6a350c71d…`／153 | `:23` sed 抽判据段锚、`:124-125` I 臂宏清单（含 `--emit-unused`） |
| `_tools/spr38_oracle_quota_check.py` | `3e2d812bc3…`／96 | `:7` ROOT、`:59-63` main 入口闸（先例形状） |
| `_tools/spr38_baseline_verbatim_check.py` | `983eee873e…`／118 | `:8` ROOT、`:10` DOC、`:15-16` 闸 |
| `_tools/spr40_churn.sh` | `2cd95413…`／91 | `:62` CR 语义登记句、`:66/:67 tr -cd '\r' \| wc -c`（§D 已落地） |
| `_tools/spr38_report_selfaudit.py` | — | `grep -n "MACROS"` 零命中（纠正 R76 §C-1 说法） |
| `production/sprint-41/SPR41_验证口径.md` | `eaf37a248b…`／139，CRLF=0 | `:34` 全文；三条 grep 现测 1／0／1 |
| `_tools/spr40_b/s166_s41_deliverable_quote_audit.py` | `59b0a39a1f…`／144 | `:17-18` 焊死 ROOT/DOC；全文无 OUT/argv/environ |
| `_tools/spr40_b/s168_s41_quote_audit_falsify.py` | `d51bb804f7…`／117 | `:15-17` SRC/DOC_REL、`:27 DOC_CONST`、`:36-42 run_audit`、`:90-92` m5 针 |
| `_tools/spr40_b/s187_s41_cited_path_verify.py` | `55c916cf34…`／— | `:21-23` ROOT/LEDGER/DELIV/OUT、`:129` 写盘 |
| `_tools/spr38_g_chk_taut.txt` | —／4094 B | 九块分解 70/28/12/19/9/15/43/83/289，合计 568/568，`VERDICT=CLEAN_EXEC`，`T3B_REGISTERED=4 UNLISTED=0` |
| `_tools/spr41_r76/s195_r76_e_acceptance1.txt` | — | 回执三条 grep 现测与我的复测逐字一致 |

## §J 转录件（编程侧按裁语逐字落盘，⛔ 改写语义）

1. **交付件 §9.1 表**：③⑥⑧ 三行的「R76 已裁」追加句各再加一句「**R77 重裁**（`production/sprint-41/SPR41_主理人裁定_R77_*.md`）：③ 不立案改双轨／⑥′ 验收尺子重立／⑧ 采第三条路」；②′ 行（taut 补闸）挂「R77 §B 补票」。
2. **交付件 §5 偏差申报**：P-4（§C 呈请）处置格追加「R77 裁：前提作废，见 §C-1.1／§C-2(a)」；P-9 或对应格追加「R77 §F-2.1 作废，s166 本体零改动、不进门禁，见 §F-2」。
3. **台账 append-only 追加一行**：R77 收件＋本件指纹（md5 现算）＋施工车次预告（顺序照 §H-1）。⛔ 回改轮 19 及更早各行。
4. **R76 的两条作废点名**（公开降级，不进 R76 正文）：§E-3.1 验收条款作废（由 R77 §E-2 取代）；§F-2.1「s166 转正接门禁」作废（由 R77 §F-2 取代）。§C-2.1「一处改动」的估计作废（由 R77 §C 取代）。

## §K 引用清单与边界自证

1. 编号自证：本窗 `find production -iname "*R7[7-9]*"` 现测为空 ⇒ **R77 无撞号**；盘上既有最大号＝R76（本窗现算 md5 相符）。
2. 本件不回改 R60…R76 任何正文；不设新的照抄令；本件自身 md5 与行数⛔ 写入本件（由 §J-3 台账行代记）。
3. 本件未新增任何「写死的期望数」进判据：§C-3 的两处派生、§C-4 的站点下限、§F-2.2 的 checks 臂数全部要求**现读／现算派生**；§E-2 的五条命令里唯一像常数的 `139`／`1`／`0` 是对**已落地磁盘态**的复述，不是对未来值的预言（行号那条另给复合条件兜腐）。
4. 遗留呈请（本件不裁，等下一轮证据）：§C-3.1 那段替换若自我引用不自洽 ⇒ 按 §C-3 明文「允许失败、留盘、回呈 R78」处理；§C-4 首趟的可疑数本件刻意不给。
