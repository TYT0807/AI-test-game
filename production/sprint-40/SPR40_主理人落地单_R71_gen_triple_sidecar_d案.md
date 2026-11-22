# SPR40 主理人落地单 R71：gen_triple 三元组旁挂自证件（R70 §C (d) 案）——teeth 写出点已量、逐字文本全给

- 依据：R70 §C-2/§C-5（`1cb67a22`/185，本窗现读）＋ R73 裁定（同窗落盘，格 A/B/C 与两条新登记已裁）。
- 性质：**实施单**。编程侧拿到本单才动 run.sh／teeth 写出点／EV／新建 helper；主理人本窗 ⛔ 自己施工。R70 §H⑤ 期间 ⛔ 动 EV `:967-975` 与 run.sh 的禁令对本单**不豁免**——写单不受限、施工受限，施工须编程侧独占窗按本单 §七 次序执行。
- 行号纪律：本单全部落点行号为本窗现读 run.sh `d85cb050`/292、EV `17d09519`/1028 的现值；施工时若 `grep -n` 对不上锚句，**以锚句为准、⛔ 盲插**（R66 §F-3 全文有效）。

## §一 七臂写出点实测表（本窗现读，R70 §C-5 欠的那一遍量）

写出点的统一形状：**七臂判定串全部由各臂 python 脚本自己 print，经 teeth() 的 shell 重定向落承载件**——run.sh `:236` 现读逐字：

```bash
	SPR38_TEETH_SELF_LOG="$log" "$@" >"$log" 2>&1
```

无一条臂是脚本直写文件。teeth() 函数体 `:219-249`，`$OUT=_tools/spr38_run`（run.sh `:48` 现读）⇒ 承载件 rel＝`_tools/spr38_run.teeth<N>.txt`。七臂登记表现算式 `grep -n '^teeth ' _tools/spr38_run.sh` → `250/251/255/256/257/261/265`：

| 臂 | 承载件 | 判定串（登记表逐字） | 产出脚本 |
|---|---|---|---|
| 1 | spr38_run.teeth1.txt | `SELFTEST GREEN` | wb.py --selftest |
| 2 | spr38_run.teeth2.txt | `SELF-SAB ok` | spr38_wb_selfsab.py |
| 3 | spr38_run.teeth3.txt | `falsify_expect=三档全 DIFFER` | spr38_fp_vs_5_4.py --falsify |
| 4 | spr38_run.teeth4.txt | `FALSIFY ok` | spr38_baseline_verbatim_check.py --falsify |
| 5 | spr38_run.teeth5.txt | `VERDICT=ALL_DETECTED` | spr38_oracle_quota_check.py --falsify |
| 6 | spr38_run.teeth6.txt | `EVIDENCE-VERIFY-INCHAIN ok` | spr38_evidence_verify.py |
| 7 | spr38_run.teeth7.txt | `COMPILE-ARM GREEN` | spr40_compile_arm.py |

⇒ 旁挂写入点唯一收敛在 **teeth() 尾部**（一处改动覆盖七臂，⛔ 逐臂散改）；sidecar 文件名按 R73 §G.2 裁定为 **`_tools/spr38_run.teeth<N>.tri`**（R70 §C-2 的 `.tri.txt` 字面名作废：匹配 `spr38_run.teeth*.txt` glob，会被 EV `:812` tails 吸入 ⇒ `:983-986` 孤儿判据恒假红；现算式 `grep -nF 'spr38_run.teeth*.txt' _tools/spr38_evidence_verify.py` → `:160/:238/:460/:563/:812`）。

## §二 sidecar 逐字规范

1. **三行式**（R70 §C-2 口径，`<host>`＝承载件 rel）：

```
HOST=<host>
TRIPLE=<host>@<md5(承载件整件字节)前8>/<gen_triple_ok 口径行数>
CHAIN=<host>@<md5(件首到 CHAIN 行行首的前缀字节)前8>/<前缀字节的 gen_triple_ok 口径行数>
```

2. **gen_triple_ok 口径**（EV `:133-146` 现读逐字引用，⛔ 两侧各写一份不同算法）：`nlines = blob.count(b"\n")`，`blob` 不以 `\n` 结尾则 `nlines += 1`；串形状 `rel@md5(blob).hexdigest()[:8]/nlines`。⛔ 用 `wc -l` 写行数分量（R70 §C-4）——两侧同源由**结构性对拍**保证：EV 侧第三段用 `gen_triple_ok(rel)` 现算比对，helper 口径若漂移 ⇒ TRIPLE ≠ 现算 ⇒ 必红②，不另立第二真源。
3. **CHAIN 自指口径**：CHAIN 行声明覆盖 sidecar 从件首到 CHAIN 行**行首**的前缀字节（＝HOST＋TRIPLE 两行含各自换行）；⛔ 不含 CHAIN 行自身字节、CHAIN 行后不得有任何字节（含尾随空行）。此口径下 sidecar 不含自身整件摘要，与 R70 §Jⓐ 自指定理同构。
4. **宿主不动**：⛔ 往任何承载件末行追加 GENERATION-TRIPLE 行（R70 §C-3：三臂哨兵就在末行）。七臂 sidecar 的 HOST 全部是证据宿主（teeth 日志），TRIPLE＝**整件**现算比对；R70 §C-2「证据宿主去 GENERATION-TRIPLE 行后比对」分支因宿主不带行而**无实例、不落码**（若未来宿主要带行，须先呈请）。代码宿主（EV/run.sh/churn/knife/r8/selfaudit 六脚本）的代次绑定继续由盘上面＋冻结表承担，⛔ 不另发代码宿主 sidecar（避免双真源）。

## §三 新建 helper 逐字全文（`_tools/spr38_gen_triple.py`，新文件零备份负担、py_compile 必过）

```python
# -*- coding: utf-8 -*-
"""R71 (d) 三元组旁挂自证件写入件（主理人落地单 R71 §二/§三）。
gen_triple_ok 口径与 spr38_evidence_verify.py :133-146 逐字同源；同源性由 EV 侧
「TRIPLE ≠ 现算 ⇒ 红」结构性保证（本件口径漂移＝必红②），不另立第二真源。⛔ wc -l。"""
import hashlib
import io
import os
import sys

host, out = sys.argv[1], sys.argv[2]
host_rel = host.replace(os.sep, "/")
blob = io.open(host, "rb").read()
nlines = blob.count(b"\n")
if not blob.endswith(b"\n"):
    nlines += 1
tri = "%s@%s/%d" % (host_rel, hashlib.md5(blob).hexdigest()[:8], nlines)
prefix = ("HOST=%s\nTRIPLE=%s\n" % (host_rel, tri)).encode("utf-8")
chain = "CHAIN=%s@%s/%d" % (host_rel, hashlib.md5(prefix).hexdigest()[:8], prefix.count(b"\n"))
io.open(out, "wb").write(prefix + (chain + "\n").encode("utf-8"))
```

## §四 run.sh 两处逐字改动（difflib 限两段）

1. **teeth() 尾部追加块**：落点＝run.sh `:248`（verdict 块的收尾 `fi`）与 `:249`（函数收口 `}`）**之间**。逐字：

```bash
	# R71 (d)：三元组旁挂自证件（承载件字节一字不动；⛔ wc -l，两侧同源 gen_triple_ok 口径，EV 侧现算比对）
	local tri="${log%.txt}.tri"
	if python _tools/spr38_gen_triple.py "$log" "$tri"; then
		echo "RUN 牙口 $label 旁挂件 ok |$tri|"
	else
		echo "RUN-RED 牙口 $label 旁挂件写入失败（明细 $tri）"
		TEETH_BAD=$((TEETH_BAD + 1))
	fi
```

   说明：每臂**无条件**写 sidecar（含 rc≠0／空日志臂——sidecar 记录状态，红绿由 EV 现算判定，⛔ helper 里做任何红绿判断＝第二判据面）；`TEETH_BAD` 语义不变（写失败算牙口坏）。
2. **归档行追加**：`:115` 现读逐字 `cp -a _tools/spr38_g_*.log _tools/spr38_k*.log _tools/spr38_run.teeth*.txt "$ARCH"/ 2>/dev/null || true`，同行在 `_tools/spr38_run.teeth*.txt` 后追加一个 glob ` _tools/spr38_run.teeth*.tri`（其余逐字节不动）。理由：sidecar 与承载件同代，归档缺一侧＝代次证据半套。

## §五 EV 侧逐字改动（difflib 限两段；`:967-975` 块本体 ⛔ 回改，仅 `:971-972` 分支内改写）

1. **新增一：`_tri_state` 函数**。插入点＝`def gen_triple_ok` 函数块结束行（现读 `:146`）之后、现 `:147` 空行处（即在其后插「本块＋1 空行」）。逐字：

```python
def _tri_state(rel):
    """R71 (d) 旁挂自证件现核：返回 (ok, why)。缺失＝(False,'旁挂件缺失…')；
    在场但 TRIPLE/CHAIN 现算不过＝(False, why)（必红②③）。口径与 spr38_gen_triple.py 同源。"""
    import hashlib
    path = os.path.join(ROOT, (rel[:-4] + ".tri").replace("/", os.sep))
    try:
        blob = open(path, "rb").read()
    except OSError:
        return False, "旁挂件缺失(%s)" % (rel[:-4] + ".tri")
    lines = blob.decode("utf-8", "replace").split("\n")
    if lines[-1] != "":
        return False, "旁挂件末行不以换行收尾（写入形状变了）"
    lines = lines[:-1]
    if len(lines) != 3 or not lines[0].startswith("HOST=") \
            or not lines[1].startswith("TRIPLE=") or not lines[2].startswith("CHAIN="):
        return False, "旁挂件不是 HOST/TRIPLE/CHAIN 三行式（实得 %d 行）" % len(lines)
    if lines[0] != "HOST=" + rel:
        return False, "HOST=%s ≠ 本臂承载件=%s" % (lines[0], rel)
    tri_want = gen_triple_ok(rel)
    if not tri_want[0] or lines[1] != "TRIPLE=" + tri_want[2]:
        return False, "TRIPLE 现算不等（现读=%s 现算=%s）⇒ 复写旧串或口径漂移（必红②）" % (lines[1], tri_want[2])
    idx = blob.find(b"\nCHAIN=")
    if idx < 0:
        return False, "旁挂件无独立 CHAIN 行（自指面缺失）"
    prefix = blob[:idx + 1]
    _nl = prefix.count(b"\n") + (0 if prefix.endswith(b"\n") else 1)
    chain_want = "CHAIN=%s@%s/%d" % (rel, hashlib.md5(prefix).hexdigest()[:8], _nl)
    if lines[2] != chain_want:
        return False, "CHAIN 自指不过（现读=%s 现算=%s）⇒ 旁挂件被手改（必红③）" % (lines[2], chain_want)
    return True, ""
```

2. **新增二：`:971-972` 逐字替换**（该分支在 `_gtm is None` 路径上；`:967-:970` 与 `:973-:975` ⛔ 一字不动）。旧文现读：

```python
    elif _gtm is None:
        SKIP_FACES.append("代次三元组待补(臂=%s)：%s 末行无 @<md5前8>/<行数> ⇒ 本轮只披露⛔ 不置红（R66 §C-1 乙案）" % (label, rel))
```

   新文逐字：

```python
    elif _gtm is None:
        _ok3, _why3 = _tri_state(rel)
        if _ok3:
            print("  %-14s 代次旁挂已核（R71 (d)）|%s.tri|" % (label, rel[:-4]))
        elif INCHAIN_AS and _why3.startswith("旁挂件缺失"):
            SKIP_FACES.append("代次旁挂面待补(臂=%s)：%s（%s）⇒ 链内晚臂未跑豁免，⛔ 置红（R71 (d) 必红①分档）" % (label, rel, _why3))
        else:
            fails.append("臂『%s』代次旁挂件缺失或不过（%s）：%s ⇒ 缺证≠通过（R70 §C-2 必红①②③）" % (label, _why3, rel))
```

   分档依据（🔴 这是 R70 §C-2 必红①的落地细化）：**缺失**在离线＝红（离线是收官核验面，缺证不放行）；缺失在链内＝披露（EV 是第 6 臂，teeth7 的 sidecar 在 EV 跑的那一刻还没写，缺失属链内时序常态，与现盘「待补=…编译面逐档」披露同形）；**在场但不过**（必红②③）两档都红。宿主末行已带 `@<md5>/<行>` 的臂走 `:973-:975` 旧路径，与本块互斥，不受影响。
3. **`ran` 计数**：sidecar 判据**并入**现牙口面（`:966-979` 循环已有的 `ran += 1`），⛔ 不新增独立站——checks 现算式（离线 9＋走到 `:951` 的臂数；链内 10＋认领−晚臂豁免）**不变**，⛔ 任何回执把并入说成"新增 checks"。
4. **`:967-975` 块结论＝保留＋限段改写**（非退役）：块本体六行字节冻结；「待补」披露从恒发改为「sidecar 已核 ⇒ 打已核行、未核披露只剩真缺失/真晚臂」。PARTIAL→GREEN 的收敛由此达成，⛔ 用「待补已消解」措辞记账（R70 §E.3）。

## §六 三类必红态造错验收（沙箱内做，⛔ 真仓库落错；每态给可观测判据）

前置：沙箱（`SPR38_EV_ROOT` tar 复制，同 EV 既有口径）内先跑一条完整链（STEP=all）mint 七份 sidecar，再离线跑 EV 确认阴性（`代次旁挂已核` 7 行、零 FAIL、rc=0）。

1. **必红①（缺失）**：沙箱内删除任一份 `spr38_run.teeth<N>.tri`（建议 teeth3）→ 离线 EV ⇒ 期望 rc=1，FAIL 行含逐字片段 `代次旁挂件缺失或不过（旁挂件缺失`。
2. **必红②（复写旧串/口径漂移）**：沙箱内把某份 sidecar 的 TRIPLE 行换成**上一轮**链的旧值（或把承载件末行改一个字节）→ 离线 EV ⇒ 期望 rc=1，FAIL 行含逐字片段 `TRIPLE 现算不等`（改宿主末行者同时被哨兵判据抓，两红并存合规）。
3. **必红③（CHAIN 手改）**：沙箱内改某份 sidecar CHAIN 行任一字节（含：把 CHAIN 行删掉、或在其后追加一行）→ 离线 EV ⇒ 期望 rc=1，FAIL 行含逐字片段 `CHAIN 自指不过`（形状破坏态命中「三行式」或「无独立 CHAIN 行」分支亦可，须记入证件）。
4. **阴性对照**：未触碰沙箱 ⇒ 七臂 `代次旁挂已核`、rc=0；链内形态 ⇒ teeth7 一条披露（`代次旁挂面待补(臂=编译面逐档)`）、其余六臂已核、rc=0。验收汇总行建议：`S137-R71SIDECAR mint=7 必红①②③=全抓 阴性=GREEN rc=0`（S137 号如被占，顺延现算）。

## §七 施工序与落地边界（编程侧独占窗，⛔ 调序）

1. 备份先行：`_backup/spr40_r71_sidecar/<UTC戳>/` 收 run.sh＋EV 改前整件字节（helper 是新件，登记即可）；py_compile 三件（helper/EV/run.sh 的 `bash -n`）＋ difflib 限段断言（run.sh 2 段、EV 2 段，段型＝§三新文件／§四两段／§五两段）＋ 还原对拍（改前件从备份逐字节 == 复原态）。
2. 改动集＝且仅＝：新建 `_tools/spr38_gen_triple.py`、run.sh §四两处、EV §五两处。⛔ 动 scripts/*.gd、⛔ 动 churn/knife/s65b/wb_mk、⛔ 重签任何既有臂判定串（R70 §C-4）、⛔ 动三臂末行哨兵宿主（teeth1/5/7 承载件字节由链流程写，本单零直改）、⛔ git 写、⛔ Godot（本单验收链不含 Godot 步，STEP=all 的既有定义照走）。
3. 🔗 **EV 换代连锁（预期行为，⛔ 当红报）**：EV `17d09519` → 新代次后，s65b `:59` 的 md5 靶断言将自废拒跑（rc≠0）——这是 R69 J-2 同形的**设计行为**；s65b 换靶**另车呈请**（本单不授权）。churn 不涉 EV 字节，不受影响。
4. 落地后登记义务：基线总线补登（EV/run.sh 新现值＋helper 新件）；台账 append 车带本单真值外部见证；wb_mk 三处（`cf4c7652`/245 的 `:84/:109/:141`）按 R70 §C-6 改绑「(d) 已落地」后**另车**做现算同步，⛔ 本单顺手改。
5. 判据一致性自检（施工后必跑）：`grep -cF 'ran += 1' _tools/spr38_evidence_verify.py` 应仍＝12【本窗现算基线】、`grep -cF 'spr38_run.teeth*.txt' _tools/spr38_evidence_verify.py` 应仍＝5 处代码面——两数任一漂移即 difflib 段外有改动，停工归因。
6. 本单自身指纹 ⛔ 落文本（R70 §Jⓐ）；真值走台账外部见证。
