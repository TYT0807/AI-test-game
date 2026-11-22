# SPR40 主理人裁定 R2 · M9 图标键去留 / 印记自证断言 / GOOD_MD5 登记轮

批次：Sprint 40（B 组开工前的最后两道停等题）
日期：2026-11-18（夜，独占窗 `owner=pid-32560 step=all` 在跑期间出件）
性质：**裁定件**（新增，⛔ 重写既有件）。本件解开 B 组 M1~M11 的全部停等。
凭据：作者 2026-11-18 已批 **D2′ 甲案**（武器 id 与显示名一起换）；本件在该授权范围内落细节，不新开方向级变更。
盘上证据：本窗全部现读（行号现场 `grep -n` 坐实，见 §4）。

---

## §0 结论先行

| # | 题 | 裁定 |
|---|---|---|
| 一 | M9 的甲/乙/丙 | **乙案**（同位换键＋改两处消费点＋红线 #4 单次豁免）。甲案驳回，理由见 §1.2——它守的是「数量不变」这句我写错的表层描述，代价却是把 D2′ 要清的那个意象永久留在局外屏上。你对丙的否决我认。 |
| 一b | `meta.gd:71` 在甲案下是否需动作 | 甲案已驳回，该问失效。**但在乙案下你漏报了一个必改点：`_tools/spr36_knives.py` 的 K5 刀**（§1.4），不同步则 B 组当轮 K5 假红、链 RED。 |
| 二 | `player.gd:1190` 第 14 碰撞点 | **随本批改**（并入 M6，编号 `M6b`，⛔ 独立成第 12 项重排批次）。施工句逐字在 §2.2，含探针门环境变量与还原要求。 |
| 三 | GOOD_MD5 登记轮 | **不可拆轮，确认**。执行位＝**B 组收官后**、与 `SPR21-FROZEN.md5` 全文重登同一动作做（§3）。你没留半套是对的；但请订正一处归因：实测数据里根本没有「新增两条 md5 FAIL」（§3.2）。 |

放行判定：**B 组 M1~M11（＋M6b＋K5 同步）无剩余停等，可开工。** 唯一时序要求照旧：整批原子落地，且必须等当前独占链释放后再动 `scripts/`。

---

## §1 题一：M9 走乙案

### 1.1 乙案完整清单（比你列的多两条）

同一批内全部落地，缺任一条即视为破坏 HP-A：

| # | 文件:锚 | 从 → 到 |
|---|---|---|
| 乙-1 | `assets.gd:110` | `"wpn_rifle", "wpn_shotgun", "wpn_railgun", "wpn_launcher",` → `"wpn_zhushan", "wpn_liechi", "wpn_guanglei", "wpn_fushe",`（同位替换，GEN_NAMES 总数守恒 76） |
| 乙-2 | PNG 入库 | `_tools/_artgen/preview_spr40_wpn/wpn_{zhushan,liechi,guanglei,fushe_w}.png` → `resources/texture/generated/wpn_{zhushan,liechi,guanglei,fushe}.png`（fushe 用 **w 版**，按核验件 §4.1 乙案转正）。登记行⛔ 手抄：照 `_tools/spr40_wpn_icons.py` 末尾打印的「登记行」逐字贴进乙-1。旧 4 枚 PNG＋`.import` 留盘不动。 |
| 乙-3 | `menu.gd:171` | `"退出游戏", "wpn_launcher"` → `"退出游戏", "wpn_fushe"` |
| 乙-4 | `weapons.gd:88` | `"icon": "wpn_launcher"`（`mw_cluster` 行）→ `"icon": "wpn_fushe"` |
| 乙-5 | `meta.gd:71` | `"icon": "wpn_launcher", "max": 1,` → `"icon": "wpn_fushe", "max": 1,`（🔴 靠 §1.3 豁免，范围只这一串） |
| 乙-6 | `validate.gd:633` | 注释句子串 `mw_cluster 复用 wpn_launcher 是合法先例` → `mw_cluster 复用 wpn_fushe 是合法先例`（点名：**本批改**，不留收官批——它是设计侧口径文本，留到收官会让下一轮读到一句指向不存在键的「先例」。只改这 11 个字，⛔ 动该行前后任何一行） |
| 乙-7 | `_tools/spr36_knives.py:26-27` | K5 刀的两条字节串里的 `b'"icon": "wpn_launcher",'` → `b'"icon": "wpn_fushe",'`（两行都改）。详见 §1.4 |

### 1.2 为什么不取甲案（记进正典，防下一轮重议）

甲案的实质好处只有两个：不碰红线 #4、`spr36_knives.py` 不用动。它的实质代价有三条，都比那两点重：

1. **「同位替换、数量不变」是我在实稿 §4.2（M9 行）写的机制层错误描述**，不是设计约束。真正的约束是 V-W5 三条：新四键 ∈ GEN_NAMES ∧ `DEFS[*].icon` 三向门过 ∧ 旧四枚 PNG 留盘 md5 未变。甲案这三条同样全过 ⇒ 「作废那句话」只是作废一句错话，我在 §4.1 已顺手把实稿 M9 行改成引用本件。⛔ 把它当成牺牲品来权衡。
2. **甲案让 8 个 `wpn_*` 基础槽键长期共存**，其中 4 个只被非本族消费者用。V-W4 那条冒烟判据（`grep -n '"rifle"' scripts/*.gd` = 0 命中）管的是武器 id，管不住图标键 ⇒ 没有任何机检能阻止后续批次往这 4 具尸体上继续挂新消费者。
3. **视觉上甲案没做完 D2′ 的活**。「退出游戏」按钮（整个游戏第一屏）与局外解锁页的集束榴弹条目会永久显示一张榴弹发射器。D2′ 要清的就是这个意象；甲案把它从 HUD 赶出去、又请回菜单和元进度页。

补一条事实修正（你的表述偏重了）：甲案下 `meta.gd:71` **确实零动作**——`menu.gd:840 meta_icon()` 三段 resolver 第二段 `Assets.g("wpn_launcher")` 仍解析得出。这点你判断对，只是它不足以翻案。

### 1.3 红线 #4 单次豁免（原文，交付件照抄）

> **主理人豁免令（S40-B / EXEMPT-1）**：实施单 §6 禁止事项 #4「⛔ 修改 `meta.gd` 的 `UNLOCKS`」，就 `scripts/meta.gd:71` 的字符串字面量 `"wpn_launcher"` → `"wpn_fushe"` **这一次替换予以豁免**。
> 豁免范围严格限定：仅 `u_mw_cluster` 节点的 `icon` 值这一个 token。
> ⛔ 覆盖：`kind`／`target`／`cost`／`requires`／`default`／`max`／`name`／`desc` 任一字段；⛔ 覆盖：节点增删、顺序调整、其它任何 UNLOCKS 节点的任何字节。
> 越界即视为违反红线 #4，本轮验收直接退回。

我的独立论证（供你写交付件时引用）：这次替换**不会改变可用集**。`validate.gd:822/838` 与 `Game.meta_content_unlocked` 这条通路按 `kind`+`target` 推导节点，`icon` 是纯展示字段；MG-PW1 的输出串（含期望话 `缺 [mw_cluster]`）逐字不变。所以豁免的不是「冻结的数据语义」，只是一个像素来源。

### 1.4 你漏报的第 15 个点：K5 变异刀（机检卫生，必改）

现读 `_tools/spr36_knives.py:25-28`：K5（MG-PW1 可用集少一把）的锚点是

```python
b'"cost": 100, "requires": [], "default": true,\r\n\t\t"icon": "wpn_launcher",'
```

`knife()` 在 `:213-216` 断言锚点**恰命中 1 次**，否则打 `INCOMPLETE 锚点命中 0 次（须恰 1），刀没落`。你把 `meta.gd:71` 换成 `wpn_fushe` 而不同步这张表 ⇒ B 组当轮链跑到 K5 就 `INCOMPLETE`，整套刀面出现一条**假红**（不是判据抓到回归，是刀自己落空）。

处置：按乙-7 改这两行字节串，并在交付件偏差申报里写明「K5 锚点随 EXEMPT-1 同批同步，属刀表跟随实现，⛔ 改期望话 `缺 [mw_cluster]`」。
另记一笔 S41 待办（本轮⛔ 做）：K5 的锚点今天同时耦合 `default` 与 `icon` 两个字段，脆；应改成只锚 `"target": "mw_cluster"` 附近的最小唯一子串。

### 1.5 其余核查结论（阴性也如实报）

- 我把 `_tools/*.py` 全量 grep 过一遍旧四枚 `wpn_*` 键：除乙-7 外，命中的只有 `spr34_gen.py:31/108`、`spr34_pixel.py:52/65/84`、`spr34_montage.py:51` —— 全是**概念图/返修管线**，按实稿 §7 与 S34 R2 的边界它们继续以旧文件名为对照基准（旧 PNG 留盘正是为了这条证据链），**本批⛔ 动**。
- `production/sprint-40/SPR40_验证口径.md` V-W5 无需改判据（旧件留盘＋md5 未变那条本来就为乙案准备的）；我已在实稿 §4.2 M9 行加引用注。

---

## §2 题二：第 14 碰撞点随本批改（M6b）

### 2.1 为什么并进而非独立成项

1. 它与 M6 是**同一契约的两端**：M6 改注入方（`game_main.gd:2802-2803`），M6b 改自证方（`player.gd:1190`）。分两批 ⇒ 中间必然存在一个「印记契约自证面测到假失败」的提交态，那是我自己定的纪律里最坏的一种（制造静默缺陷的反面：制造响亮缺陷）。
2. 独立成项的收益只有「churn 面小一点」，而 churn 口径本来就只比断言行、且要求逐条列明新增/变更断言行（G-e），随批改完全可交代。
3. 编号走 `M6b` 而不插进 M7~M11 之间：⛔ 重排既有编号，避免你我两份文档的 M 号错位（历史教训：行号与编号都会腐烂，句子才可靠）。

### 2.2 施工句（逐字，照抄进交付件）

> **M6b｜`scripts/player.gd:1190`（SMOKE_SIGIL_COVERAGE 探针 · `_sigil_coverage_probe()` 的 `"arsenal"` 分支）**
> 现文本：`				ok = weapon_slots[1] == "shotgun"`
> 改为：　　`				ok = weapon_slots[1] == "liechi"`
> 约束：①同行替换，⛔ 增删行、⛔ 缩进改动；②紧邻下行 `detail = "slot1=%s" % weapon_slots[1]` **一字不动**（它是消息格式串，改了会污染 `[SMOKE-SIGIL]` 面比对基线）；③⛔ 顺带把该 match 块其它分支的文案或判据「优化」一遍；④M6 与 M6b 必须**同批**，缺一则该分支恒 `ok=false`（假失败，非漏测）。

配套的门控句（也要照抄进交付件的「B 组必跑门控」段）：

> ```
> SMOKE=1 SMOKE_SEED=<与改前同一个整数> SMOKE_SIGIL_COVERAGE=1 \
>   godot --headless --path "D:/Create/Game/test-1" --quit-after 3200
> ```
> 判据：`[SMOKE-SIGIL]` 面 `done checked=N declared=N` 两数与改前**相等**；`arsenal` 那一行 `ok=true` 且 `slot1=liechi`；`[ERR]=0`、`ok=false=0`、`SCRIPT ERROR=0`。
> 反向自证（必做一次）：临时把 `game_main.gd:2802` 的 `"liechi"` 改回 `"shotgun"`（M6 单方破缺），`arsenal` 行必须当场 `ok=false`；验完**逐字节还原**并复跑确认回到绿基线，把两行日志原文转录进交付件。

### 2.3 探针侧没有第二处（阴性结论）

我把印记相关的旧 id 字面量在全仓 `.gd` 扫了一遍：除 M6/M6b 外，`arsenal` 只在 `data.gd:217`（M7 文案）与 `data.gd:369`（共鸣定义，不涉及武器 id）出现。⇒ 印记面共 4 个点（M6×2 行 + M6b×1 行 + M7×1 行），无第 15 个隐藏站。

---

## §3 题三：GOOD_MD5 登记轮

### 3.1 结论：确认为**不可拆的一整轮**，执行位在 B 组收官之后

`GOOD_MD5` 一次轮换要同时满足五件事，缺任一件就留下你实测到的那种半套：

1. `scripts/player.gd` 盘上内容 ＝ 新串（且经双跑 cmp ＋ 刀面还原证明是绿件）；
2. `_tools/spr38_good_player.<hash>.bak` 归档在位（P7 事故后主 `.bak` 不可信，只认 hash 后缀归档）；
3. `SPR21-FROZEN.md5` 全文重登（作者保留④，由我刷，凭你粘的 `md5sum scripts/*.gd` 原样生成）；
4. `FROZEN_SITES` / 文档面「N OK / M FAILED」声称同步（现在盘上是 8/5 对 7/4，另有一处 `23/11` 的旧声称）；
5. 被审文档各 ≥1 次收尾 md5 引用 ⇒ 需要一份**本批自己的**交付件当宿主，因为 `值守报告` 被禁止事项 #11 挡死。

第 5 条今天在结构上无法满足（S40 还没有交付件被 `DOCS` 指着），所以「现在只改常量」必然要么半套、要么违规追加台账。**你的处置（逐字节还原成 `dc622351…`、⛔ 留半套）正确，我认。**

### 3.2 一处归因订正（拿你自己的数据）

你贴的 `checks_run=27 issues=4 → 5` 与 `_tools/spr38_run.docaudit.txt` 实测不符：那份输出里 `issues=4` 的四条 FAIL 是 ①冻结实测 22/12≠24/10 ②绿基线≠dc622351 ③值守报告冻结声称 8 处 vs 登记 7 ④SPR38 交付冻结声称 5 处 vs 登记 4。文档面对 `dc622351` 的计数是 `AUTORUN_值守报告.md 绿件 md5 出现=6 次`、`SPR38_交付_B1… 出现=3 次` ⇒ **改成 733a 只会消掉第②条，不会新增两条 md5 FAIL**（第②条与你观察一致地消失）。

两种可能：(a) 你那次是在**另一份 selfaudit 副本**（如 `_tools/_wb_bak_a24_4/_test/selfaudit_pre.py`）上跑的；(b) 你看到的两条其实是第③④条（措辞相近，都带「登记表/处数」字样）。
要求：在 B 组交付件里把当时那条命令与原始输出片段逐字贴回来，别只贴结论。**这不是追究——如果 (a)/(b) 成立，说明「改 GOOD_MD5 会炸文档面」这个前提本身没被证实，那 §3.1 的理由仍然成立（第 5 条结构性缺口独立存在），但我们的口径记录不能挂一条不实归因。**

### 3.3 登记轮的归属与时序（写死，防再问）

| 步骤 | 谁 | 时机 |
|---|---|---|
| 链跑完 `md5sum scripts/*.gd` 原样粘给我 | 编程侧 | 每次独占链结束（A 组之后、B 组之后各一次） |
| 生成并落 `production/sprint-21/SPR21-FROZEN.md5` 全文 | **主理人**（我） | 收到上面那份原样粘贴后；⛔ 你手工写 hash、⛔ 凭记忆对齐 |
| `GOOD_MD5` 常量 ＋ `FROZEN_SITES` ＋ 文档面声称 ＋ 本批交付件引用位 一轮做完 | 我出逐字施工单，你落地 | **B 组收官后**（B 组还会再轮转一次 `player.gd` 基线，现在登记 733a 立刻作废——你的判断对） |
| P7 归档闸修复（遍历 hash 后缀归档自证） | S41 立项 | ⛔ 本轮 |

补充一条你可能没注意的连带：B 组会改 `player.gd`（M4/M5/M6b），所以**当前在飞的这条链跑完后的那份 md5 快照，其 `player.gd` 值注定是短命的**。粘，我照收作 C 组/在飞态的对账凭据；但 `GOOD_MD5` 一律等 B 组落地后的那一版，别中途登记。

---

## §4 本窗现读证据（全部现场 `grep -n` / `md5sum`，⛔ 引用你的转述）

```
scripts/assets.gd:110      "wpn_rifle", "wpn_shotgun", "wpn_railgun", "wpn_launcher",     ← 乙-1
scripts/menu.gd:171        _add_main_button(right, "退出游戏", "wpn_launcher", …)          ← 乙-3
scripts/weapons.gd:88      "tint": Color(1.0, 0.75, 0.35), "icon": "wpn_launcher",         ← 乙-4
scripts/meta.gd:71         "icon": "wpn_launcher", "max": 1,                               ← 乙-5（EXEMPT-1）
scripts/validate.gd:633    # …mw_cluster 复用 wpn_launcher 是合法先例。                     ← 乙-6
_tools/spr36_knives.py:26-27  K5 锚点含 b'"icon": "wpn_launcher",'                          ← 乙-7（你未报）
scripts/player.gd:1190     ok = weapon_slots[1] == "shotgun"                                ← M6b
scripts/game_main.gd:2802-2803  player.weapon_slots[1]="shotgun" / slot_mags["shotgun"]     ← M6（两行都要改）
scripts/weapons.gd:325-329 / :343-353、scripts/player.gd:276-280                            ← M5 四处回退，实读在位
scripts/menu.gd:840-846    meta_icon() 三段 resolver（ICON_RECTS → g(k) → g("icon_"+k)）    ← 甲案下 meta 零动作的证据
```
路径可达性复核：`assets.gd:157-160` 对 GEN_NAMES 逐项 `load(.../%s.png)`，失败只 `push_warning` ⇒ 乙-2 的 PNG 入库与乙-1 的换键必须同批（否则静默白框，AGENTS §4.3）。
环境实况：`_tools/.spr38_run.lock` = `owner=pid-32560 at=2026-11-18 21:36:18 step=all`（在飞）；`scripts/player.gd` 与 `_tools/spr38_good_player.bak` 均为 `733a4b3c524219c237441d53e3ebc9b2`（两值相同＝刀已还原）。你 21:34 现读的 `game_main.gd = 5978d368…` 与我算的同值，§3.2 那条编号冲突预警按「时间差」结案，撤销。

---

## §5 你现在可以做的（顺序）

1. **等独占链释放**（`step=all` 在飞），⛔ 抢锁、⛔ 手工碰锁文件。
2. 链释放后一次性原子落地 **M1~M11 ＋ M6b ＋ 乙-1~乙-7**（含 `META_WEAPON_POOL_BASELINE` 按核验件 §3.1 逐字串替换）。
3. 跑门控：全套 `all` ＋ 额外一次 `SMOKE_SIGIL_COVERAGE=1` 面（§2.2），并按 §2.2 做一次 M6 单方破缺的反向自证后逐字节还原。
4. 交付件九节里，把 §1.3 豁免令原文、§2.2 施工句、§1.4 的 K5 同步说明分别抄进对应栏；§3.2 要求的 selfaudit 原始输出片段一并贴上。
5. 交付件落盘后把 `md5sum scripts/*.gd` 原样粘我（我据此生成新 `SPR21-FROZEN.md5`，然后开 §3.3 那轮登记）。
6. ⛔ 动 `_tools/AUTORUN_*.md` 两份台账；⛔ 动 `GOOD_MD5`（等我的逐字施工单）；⛔ 动 `spr34_*` 概念图管线；⛔ 删/覆盖旧 4 枚 PNG。
