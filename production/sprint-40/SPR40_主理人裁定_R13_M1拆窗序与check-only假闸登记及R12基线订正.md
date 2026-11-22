# SPR40 主理人裁定 R13｜M1'① 拆窗序＋Q2 check-only 假闸登记＋R12 §4 基线订正＋M1.5' 结清追认

性质：**纯裁定件**。本窗 ⛔ 改任何既有文件、⛔ 动链件/判据件、⛔ commit/push。只新建本件。

基线【本窗盘上现读，2026-11-19】：
- `scripts/data.gd`＝`5f8f832f0dd733b09fe489523b5dcc81`、580 行 ✅（与 R12 §4 一致）
- `scripts/player.gd`＝`5835d2e6e9e89d3a6dd4155bcadc0b19` ✅（与绿基线 `.bak` 逐字节相同）
- `_tools/spr38_run.sh`＝**`e14c0987e50554af6f5221e1f26ca3aa`、250 行**（见 §A 订正）
- `_tools/spr38_knife.sh`＝`4d9ff4e3ef05273358580d54cc6db16e`、51 行 ✅
- `_tools/spr38_preflight.sh`＝`e6ab6d81e3c71f4e73beab6194c54365`
- 冻结 **34 OK / 0 FAILED** rc=0 ✅

---

## §A R12 §4 基线行订正（追认 R41 两处事实偏差）

R12 抬头写「`_tools/spr38_run.sh`＝`95c501dd6ee3f2a98407e5075754b0e1`、**250 行**」——两个值互相排斥：
- `95c501dd…` 是 R10 §0 宣布的终态，实为 **249 行**；
- 盘上现值 `e14c0987…` 才是 **250 行**（由 S12 headnote 施工件于 10:26:05 落地）。

R41 §1 已如实申报这一矛盾，本件确认订正：

> **M1' 开工基准总线（以本件为准）**：`spr38_run.sh`＝`e14c0987e50554af6f5221e1f26ca3aa`、**250 行**；`data.gd`＝`5f8f832f…`、580 行；`player.gd`＝`5835d2e6…`。

R12 §3「原「249→250」预期作废」的前提在它自己的基线行上已不成立——该句针对的是 R11 §F-5 追加版产生的临时 250 行态，而 S12 headnote 原地版落完后恰好也是 250 行，两者 md5 不同。**净行数 0 达成**，无返修必要，⛔ 再动那四行。

---

## §B M1.5' 结清追认

R41 §2 所报「两窗合完 M1.5'」属实：
- 值守定时件窗（`spr40_s11_m15_comment_pack.py`，10:17:11）落了前三处（`95c501dd…` 249 → `337f9f98…` 250）；
- S12 headnote 窗（`spr40_s12_headnote_landing.py`，10:26:05）把第四处从追加版原地换成 R12 §3 文本（`337f9f98…` → `e14c0987…`），同时覆盖了你按 R11 §G-5 落的括注行。

两处均为注释面、零行为变化、`^teeth` 计数仍 6、总行数不变。**追认 M1.5' 至此结清**，run.sh 新基准＝`e14c0987…`／250 行，后续窗口以本件 §A 为准。

---

## §C Q1 主裁：M1'① 拆窗序（选 (b) 并扩展）

### C-1 裁定结论

取 **(b)**：§5.1 的 player.gd label 补丁从 M1'① 拆出，并入 M3 登记轮同窗。M1'① 的 tips 十行只动 `data.gd`。

理由：preflight 比的是 `scripts/player.gd` 对 `_tools/spr38_good_player.bak` 的字节相等，不比 `data.gd`（代码实证：`spr38_preflight.sh:34` 只取这两个文件的 md5）。label 补丁是纯文档面（条件表达式 `size()==74` 不变、`checked/declared` 计数不变），却会触发 preflight BLOCK 使整个独占链不可用。把它留在 M1'① 同窗等于把一个零机制收益的改动绑死一个有机制收益的改动，不值。

### C-2 M1'① 重放工序（data.gd only）

前置闸（施工件须先验）：
1. `md5sum scripts/data.gd` ＝ `5f8f832f0dd733b09fe489523b5dcc81`；
2. `wc -l scripts/data.gd` ＝ 580；
3. 十个键各命中恰 1（`grep -c '"<键>"' scripts/data.gd`）；
4. 原文与 R12 §5「原文」列逐字相同；
5. 新串已在则幂等拒绝。

落盘后预期状态：
- `data.gd` → `45e7da881112f92353430653b96713b8`（S13 实测值，可作候选校验锚）；
- `player.gd` 不变 → preflight ok、链可跑；
- 冻结 **33 OK / 1 FAILED**（`data.gd`），这条 FAILED 等 M3 收。

M1'① 落盘后须跑的验证：
- `SMOKE_SEED=12345` 钉住跑 gates，validate `problems=0`；
- E1 指纹三档（`SMOKE_META_FINGERPRINT=1`，12345/777/42）与 R12 §5 前逐字相同；
- churn 比对只比断言行，排除抖动族。

### C-3 M3 登记轮同窗（label 补丁归此）

生效文本（宿主＝现场 `grep -n 'Dev.check(Data.FLAVOR.size() == 74, "flavor"' scripts/player.gd` 命中行）：

当前盘上值：
```gdscript
Dev.check(Data.FLAVOR.size() == 74, "flavor", "手记 74 条（全六类覆盖：29 敌+12 遗+8 词+8 题+7 Boss+10 圣所）")
```

M3 目标值：
```gdscript
Dev.check(Data.FLAVOR.size() == 74, "flavor", "手记 74 条（全六类覆盖：29 敌+12 遗+8 词+8 题+7 Boss+10 圣所+10 tips 逐字件 S40-R12）")
```

变更范围：仅第三参数字符串末尾加 `+10 tips 逐字件 S40-R12`；条件表达式、`"flavor"` 键名、`checked/declared` 计数均 0 改动。

M3 同窗须执行的动作序列：
1. 落 player.gd label 补丁；
2. `cp scripts/player.gd _tools/spr38_good_player.bak`（晋升绿基线）；
3. 更新 `spr38_evidence_verify.py:114 EXPECT_MD5` 为新 player.gd md5；
4. 更新 `spr40_s4_register_round.py:63 SA_BASELINE_MD5` 为新 run.sh md5（若 M3 牵动 run.sh）；
5. 重刷 `SPR21-FROZEN.md5`（data.gd 和 player.gd 两条同步）；
6. 跑完整七件套门禁，确认 34/0/0。

**授权谁执行 M3**：编程侧（施工窗）。M3 登记轮的 `.bak` 晋升与 EXPECT_MD5 更新属登记动作，不是自刷冻结，在编程侧权限内。

### C-4 R12 §5 措辞订正

R12 §5 配套硬前置第 1 条原文「🔴 **同窗**把 `player.gd:2009` 那条 Dev.check 的 label……」中的「同窗」二字，由本件改判为「**M3 登记轮同窗**」。M1'① 开工不再依赖 player.gd 改动。

---

## §D Q2 裁：`--check-only --script` 假闸登记

### D-1 结论

`--headless --check-only --script` **对本项目不成立**，不得当 `.gd` 语法闸使用。

实证：对未改动的冻结件 `scripts/data.gd` 它也 rc=1 报 `Identifier not found: Dev`——原因是 check-only 模式在 autoload 注册之前执行，裸标识符 `Dev`/`Game`/`Data` 无法解析。这是 Godot 4.x 引擎行为，非项目 bug。

### D-2 处置（按 §七 四条规矩登记）

1. **备案条目**（登记位置＝M3 后的 `_tools/README_gates.md` 或等效口径文档）：
   > `--check-only` 不适用于含 autoload 引用的 GDScript 文件；本项目所有 `.gd` 均引用至少一个 autoload，故该标志恒报误红。禁止将其用作语法闸门。

2. **新机检条目建议**（供 M3 实现参考）：
   施工件的 GATE4 应替换为**结构闸**（你已实现的 4 条反对照范式：越界改行／裸双引号／键名漂移／偷改条件），并在施工件头部注释披露「为何不用 `--check-only`」（S13 施工件 `:141-142` 已有这段注释，格式正确）。

3. **不新增常驻门禁臂**：这不是链级问题而是施工工具选型问题，在每个施工件内部以结构闸自证即可，⛔ 新开第 7 臂。

### D-3 你的 GATE4 替代方案认定

`_tools/spr40_s13_tips_landing.py:140-196` 的结构闸（正对照 2 件通过＋4 条反对照全被抓）满足验效果型要求，可作为 M1'① 的施工件内置闸使用，无需改动。

---

## §E Q3 裁：M1'① 正确重放顺序（一句话指令级）

```
1. 前置闸：md5/wc/grep 五道全过（§C-2 前置条件 1-5）
2. 落 data.gd 十行 tips（原地改写，键名不动，净增行 0）
3. 后置闸：结构闸 GATE4 正/反对照全过
4. 跑 gates（SMOKE_SEED=12345）⇒ validate problems=0
5. 跑 E1 指纹三档 ⇒ 与改动前逐字相同
6. 跑 churn 比对（SMOKE_SEED 必钉）⇒ 无非抖动差异
7. 报告冻结态 33 OK / 1 FAILED（data.gd）——如实报，⛔ 自刷
8. ⛔ 不等 player.gd 补丁、⛔ 不等 M3、⛔ 不碰 .bak/EXPECT_MD5/冻结清单
   （步骤 8 即「哪一步必须等 M3」的答案：label 补丁和绿基线晋升全部推迟到 M3，M1'① 本身不阻塞。）
```

---

## §F 待裁项（本件不留悬案）

无。Q1/Q2/Q3 均已给出结论与生效文本。
