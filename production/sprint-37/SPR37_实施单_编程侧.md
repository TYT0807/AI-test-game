# SPR37 实施单 · 编程侧 —— **状态：可开工（rev3：T0 已落地并复验；T-A 开工前须先改 M8 分母口径）**

> 解闸说明：本批**无作者待裁项**。实稿 §11 那 13 条全部是主理人自核项（作者的规矩：创意题走主理人，⛔ 打断思考任务），其中 **9 条已自答关闭**。
> 🟢 **T0 已由编程侧落地、我已独立复跑验收**（见 §2 T0 台账）⇒ **T0 不再是待办**。
> 🔴 **T-A 现在多一条硬前置 HP-9**：M8/M8b 的分母必须改成「与分子同一函数同一次调用的返回值」（实稿 §6d）。不改就开工 ⇒ 20 族比值还是三条链对比，V10 白回收一轮。
> ⚠️ R2 改了三个靶值（M3 补 x 在动、M7b 作废换 M7c、M8 改相对母版）；**R3 又改了 M8 的分母来源**——照 rev3 实现，⛔ 照 R1 的绝对像素数、也⛔ 照 R2 那句"`pixels/monster_<id>.png` 当分母"写。
> ⛔ 编程侧遇到口径疑问找主理人，不越级问作者；也不许把主理人已裁条目再拿去问作者。

批次：Sprint 37
撰写：主理人，2026-11-18（**rev3＝同日按编程侧 T0 实测回填**）
配套：`SPR37_设计实稿_动作帧图集规格.md`（下称「实稿」；§/G/M/V 编号均指该件）
正式验收口径文件 `SPR37_验证口径.md` 在 T0 跑通后同批补出；**T0 已跑通 ⇒ 该件现在可出**；**靶值 M1–M11 已在实稿 §6 钉死（分母口径见 §6d），编程侧可先按它们自检**。

---

## 0. 开工闸

| 闸 | 条件 | 状态 |
|---|---|---|
| G0-1 | S36 未收官：**⛔ 不动 `production/sprint-36/` 任何文件**；本批文档只落 `production/sprint-37/` | 🔴 全程有效 |
| G0-2 | 起点自检并留档：`git log --oneline -1`、`git status --short`、`md5sum -c production/sprint-21/SPR21-FROZEN.md5`。**改动前的 FAILED 名单原样记下**🔴 **主理人本轮现场实测 = 6 个 FAILED**：`data.gd`/`game_main.gd`/`game_state.gd`/`meta.gd`/`shrine_panel.gd`/`validate.gd`（S36 记的是 4 个，`meta.gd`/`validate.gd` 系其后新动）。**都不是本批造成**，⛔ 为凑绿去刷清单。开工时若与这 6 个不吻合 ⇒ 有第三个窗口在改盘，先停下报我。另 `assets.gd`/`slug.gd` 本轮**干净**，故 T-A-3 之后 `assets.gd` 翻 FAILED 是本批唯一净新增。⚠️ **R3 补记：T0 轮不跑这一条也不算漏跑**——T0 没动任何 `.gd`，门禁状态记 `UNEXECUTED`（实稿 V6）。 | 每次开工跑（动了 `.gd` 才跑） |
| G0-3 | ~~T-A 开工前 V1/V3 已回填~~ ⇒ 主理人已自答关闭（实稿 §11 V1/V3） | ✅ 解闸 |
| G0-4 | 新 worktree 先 `--headless --path <dir> --import`（`.godot/` 是 gitignored，没 import 过会一片假红） | 建 worktree 时 |
| **G0-5** 🆕 | 🔴 **T-A 开工前 HP-9 必须先落地**（M8 分母改同调用栈取数 + `--selftest` 重跑七条仍全红）。⛔ 带着旧分母跑 20 族——那 20 行比值是三条链对比的产物，喂不进 V10 | T-A 开工闸 |

🔴 **行号纪律**：本单行号是主理人 2026-11-18 在工作树 `grep -n`/`Read` 现场坐实的。工作树相对 HEAD 有未提交改动——**落地前必须重新 grep 一遍**，别把这些数字当常数。引用一律优先引**句子**。

---

## 1. 硬前置（🔴 顺序依赖，违反即返工）

| # | 前置 | 为什么硬 / 证据 |
|---|---|---|
| HP-1 | **先做 T0（探针转正 + 负例自证），再做 T-A 任何一张入库** | 否则 20 张图是在一套没被证伪过的判据下自证清白＝假绿温床（实稿 §7.1） |
| HP-2 | **基准色表只允许 `from spr25_art_gen import`**（`INK/GREY/BROWN/STONE/BONE/RUST/RUST_DIM/LIT/CYAN/COPPER`，`:31-41`） | D-E 判据若在新脚本里重述那 10 个 RGB 三元组，实现错了断言也会跟着错。现存 `spr34_pixel.py:36` 那份是历史复制，本批不追，**⛔ 再加第三份** |
| HP-3 | **⛔ 改任何现有 PNG 的宽高**；⛔ 改 `Data.ENEMIES[*].scale`/`position`；⛔ 动 `wraithswarm.png`/`虫群2.png`/`shardbearer.png`（旧名 `W.png`，见实稿 §4.2 R3 更正）三张既有图集的字节 | 实稿 G4/§9；尺寸写在 `.gd` 属机制面。🔴 R3 追加：玩家图集那条另见实稿 §4.5 归属声明——本批不产玩家族新帧，也⛔ 顺手补 attack 行 |
| HP-4 | **零新增 `Game.rng` 消费** | 本批纯视觉；一旦引入随机选帧就破坏 E1 指纹确定性（§4 门控 5 会当场抓到） |
| HP-5 | **接入走方案乙**：`monster_frames()` 内部"优先图集、回落单帧"；⛔ 改 `data.gd` 字段结构、⛔ 扩 `KNOWN_ATLAS`、⛔ 加 `atlas:`/`row:` | 实稿 §5.2 已裁定；甲方案会让 `KNOWN_ATLAS` 从 2 涨到 22 且 `row` 语义冲突 |
| HP-6 | **旧单帧 `resources/texture/monsters/<id>.png` 保留不删**，新图集落 `monsters/atlas/` 子目录 | 这是唯一廉价回滚路径：删 atlas 目录即回到今天的行为 |
| HP-7 | **非方图族（道具/人物）开工前必须先修 `spr34_pixel.py` 的方图假设**：真锚点是 `frame()`（返回 K 倍画布后 NEAREST 缩到目标画幅）与 `to_table()` 这两步把链子按正方构图假设串起来的 | S34 追加件一 §3.2b 连带后果 1，实稿 §4.4；不修就入库会得到 "FAIL size=(20,16)" 这种**断言在正确拦错事**的假缺陷。**🔴 R3 升格：这条现在有实测举证了**——盘上 `chest_closed_atlas.png`(48×32) 用正方格切出 walk opaque `[3,3,2]`／底边 `[13,13,5]` ⇒ M3/M5 **双双假红**（换 w=20 当格宽得 `[4,4,1]`／`[19,12,4]` 同样离谱）。那是网格切错，不是内容缺陷。举证全文与两种切法对照见实稿 **§6e**；编程侧已把这类情形改成显式 `UNEXECUTED`（不作 PASS 也不作内容 FAIL），**这个处置我认可，保持**。<br>⚠️ 顺带更正一处腐烂指针：**本仓没有名为 `to_pixel()` 的函数**（真名 `frame()`:152／`to_table()`:173／`verify()`:201），旧文档那句照抄会 grep 空手。引用一律改引句子或函数名。 |
| HP-8 | 悬空/接地判定**以 `spr34_pixel.py:75 FLOATING`（5 只）为准**，⛔ 以 `data.gd` 的 `float:true`（只有 2 只）为准 | 实稿 §2b-4：`grep '"float"' scripts/slug.gd` 零命中，那个字段今天**没有任何消费者**；用错口径会有 3 只怪的脚被抬离地平线 |
| **HP-9** 🆕🔴 | **M8/M8b 的分母必须来自「与分子同一函数、同一次调用」的返回值**＝T-A 生成链里 `to_table()` 之后、`shift()` 之前那一帧（即 `base_sprite()` 的输出 `im`，派生前先取一次 `stats(im)["n"]`）。⛔ 从 `_tools/_artgen/pixels/`、`concepts/` 或任何缓存 PNG 读数 | **实稿 §6d**。现状 `master_opaque()`（`_tools/spr35_frames.py:135`）读的是 `pixels/monster_<id>.png`＝**第三条链**，实测比值出现 >1（goblin 1.897＝330/174、wraith 1.583＝266/168）⇒ 纯位移派生不可能让帧比母版更满，分子分母不是同一个东西。**不修就整批开工＝V10 回收一轮废数据** |
| **HP-10** 🆕🔴 | **盘上那 5 张 `_tools/_artgen/frames/*_atlas.png` 不得作为 M8 的验收样本**（S35 旧链产物） | 同上。`--all-disk` 从此只用于：①喂 HP-7 举证 ②跑与分母无关的 M1/M6/M7/M7c/M9。凡打 M8 比值处输出 `DENOM-N/A (legacy S35 chain)`，⛔ 打数字冒充证据 |

---

## 2. 任务条目

### T0｜探针转正 —— 🟢 **编程侧已落地，主理人已复跑验收（2026-11-18）**

机检脚本＝**`_tools/spr35_frames.py`**（沿用 S35 那个文件名，⛔ 另起新名、⛔ 重写一套判据）。M7c/M8/M8b/M9/M3x 与七条负例**均已在该文件内实现**。下面每条后面标的是**执行结果**，不再是待办。

| 条目 | 要求（原文保留） | R3 台账 |
|---|---|---|
| T0-a | 保留 `load_pixel()` 的 exec 真链路手法（剥掉 `spr34_pixel.py` 末尾无条件 `main()`） | ✅ 已实现（`_tools/spr35_frames.py:25-31`），复制品没被拿来当数 |
| T0-b | M8（相对分母比例）＋M8b（分母绝对下限 ≥30px），🔴 分母必须打进日志 | 🟡 **判据成立、口径要改**：`--mastered` 20/20 非空且 ≥30px（最小 `flameskull`=33、最大 `ogre`=251），与实稿 §4.1 逐字吻合 ⇒ **M8b 本身 PASS**。但分母今天读的是 `pixels/monster_<id>.png`＝第三条链 ⇒ **按 HP-9 重取**。系数 0.90/0.85/0.45/0.12 在新口径下视为**未校准**（V10 重置） |
| T0-c | M9 空图哨兵：任一帧 opaque==0 ⇒ 立即 FAIL 并打印 id | ✅ 已实现且**排在 M8 之前**（`:184` 注释「空帧若混进比值会把『根本没画』洗成『画得小』」）——这个顺序是对的，保持 |
| T0-d | M7 只判 walk 色集相等；另加 M7c：die 末帧色集 ⊆ walk 色集 | ✅ 两条都在；负例⑥实测**只由 {M7c} 拦住**（M6 未红）⇒ 说明注的是池内色、判据分离干净 |
| T0-g | 🔴 M3 补一条硬判据：walk 三帧 bbox 的 x 起点必须逐帧不同 | ✅ 已实现为独立判据 **M3x**（`:218` 段）。负例⑤「walk 同图复制三遍」**只触发 {M3x}**，M2/M7 均未红 ⇒ **坐实实稿 §6b-1「M2 对纯位移派生恒真」**。这是本批最关键的一处判据修正，现已有反证支撑 |
| T0-e | `selftest()` 从 3 条扩到 7 条，每条必须红且**由应中的那条拦住** | ✅ **rc=0，七条全红**（我本轮独立复跑）：①池外色→{M6,M7} ②die不递减→{M5} ③walk底边漂移→{M3,M3x} ④某帧全透明→{M7,M9} ⑤**walk同图复制三遍→只有{M3x}** ⑥die末帧冒新色→{M7c} ⑦母版<30px→{M8b}。日志 `D:/Create/Game/_tools/sp_logs/spr37_selftest.log`。<br>⚠️ ①③④各多触发了旁支判据：负例的合格线是「触发 ⊇ 应中」，⛔ 把"多红"报成失败，也⛔ 反过来为了输出干净去删旁支断言 |
| T0-f | 目视件：5 张悬空族 die 预览单独出 `spr37_v9_floating_die.png` 交我裁 | ✅ 已出，我本轮 IHDR 复核 = **96×160**（3 列 × 5 行 @32px，行序 wraith/flameskull/faerie/slime/beholder）＋ 5× 预览 `_prev.png`(480×800)。**判据归我目视（V9），机检判不了** ⇒ 结论我另行落档，编程侧⛔ 自行拍"碎屑浮在半空没问题" |
| T0-h | `python _tools/spr35_frames.py --selftest` 七条全红 + 日志落 `sp_logs/spr37_selftest.log` | ✅ 达成。盘上真数另见 `sp_logs/spr37_disk.log`（含 goblin/wraith/dragon 三张方图 + chest_closed/merchant_0 两张记 UNEXECUTED）、分母表 `sp_logs/spr37_mastered.log` |

🔴 **门禁本轮不适用（如实记，⛔ 记成 PASS）**：T0 全部改动落在 **gitignored 的 `_tools/`**，编程侧本轮**一个 `.gd` 都没动** ⇒ 七件套（validate／探针 done=declared／[ERR]／ok=false／E1 指纹／churn／冻结表）**本轮未跑、也不该跑**。V6/V7 状态一律 `UNEXECUTED`。T-A 一开工就会动 `assets.gd` ⇒ 那时七件套恢复必跑。

**T0 交付物 = 一份能证明"这套判据抓得住现状那种烂做法"的证据。** ⇒ **已交付、已复验**（负例⑤就是现状那种做法的形态，它红了）。

### T-A｜怪物族 20 张图集（🔴 本批主体；🟡 **开工前置多一条 HP-9**）

范围（实稿 §4.1）：A 悬空 5 + B 接地 12 + C Boss 3 = **20**，另 D 档 `echo` 需**新母版**（见 T-A-4）。

- **T-A-0** 🆕🔴 **先按 HP-9 改分母取数**：在派生之前从 `to_table()` 那一帧取一次 `master_n = stats(im)["n"]`，随 atlas 一起传进 `check()`；`master_opaque()` 逐出 `check()` 的调用路径（保留给 `--mastered` 当体检表可以，⛔ 再当 M8 分母）。改完**重跑 `--selftest`**并把⑦号负例的注入方式原文贴回——它现在靠外部传参 `n_tiny` 造小分母，换成同调用栈取数后这条负例可能失去抓手（AGENTS §5「前提守卫型恒过」风险）。
- **T-A-1** 逐族派生：母版 → `walk_frames()`／`die_frames(seed)` → `assemble()` → `write_png()`。
  🔴 母版路径**显式写死 `_tools/_artgen/pixels/monster_<id>.png`**。⛔ glob `pixels/*.png`、⛔ 靠文件名猜版本——目录里并存 3 张旧命名化石件（`goblin.png` 297 / `wraith.png` 250 / `skeleton_king.png` 258，与 `monster_*` 数值不同），抓到就是静默用错稿（实稿 V11）。
  ⚠️ R3 补一句：这条"写死 pixels 路径"管的是**母版输入**，⛔ 别把它当成 M8 的分母来源（分母走 T-A-0 那条同调用栈口径，两者是两回事）。
  🔴 `seed` 必须**按 id 固定**并写进生成器常量表（例：`SEED[id] = 20261118 + index(ENEMIES 声明序)`），⛔ 用系统时间或 `random()`——否则同一张图重跑两次得到两套 die 碎屑，churn 无从对比。
- **T-A-2** 落盘：`resources/texture/monsters/atlas/<id>.png`，A/B 档 **96×64**、C 档 **96×96**（idle 放末行，尾部整格全透明）。
- **T-A-3** `assets.gd`：新增 `MONSTER_ATLASES`（**20 项，不含 `shadow`**）+ 装载循环 + `monster_frames()` 的图集分支（`Rect2(col*32, row*32, 32, 32)`，walk=行0、die=行1、Boss idle=行2）。`MONSTER_NAMES` 与旧装载循环保留。
  ⚠️ `_cache` key 沿用 `"mon_"+name`：进程内一次性构建，实际不撞车（V5），但 M10 要复证。
- **T-A-4** `echo`（`data.gd:85 tex:"shadow"`）：给它**自己的母版与图集**，⛔ 继续复用 20×8 投影贴片。
  ✅ V3 我已核毕：`grep '"shadow"' --include=*.gd scripts/` **全仓仅 3 处**（`assets.gd:106` 名单、`data.gd:85` echo 的 tex、`slug.gd:57` 投影）；图鉴走 `codex_id`/`variant`，**不按 tex 分组**。⇒ 影响面就一个条目，可以直接做。
  ⚠️ 例外上报条件：若实现要求图集名单独 key、从而必须把 `data.gd:85` 的 `tex:"shadow"` 改成 `"echo"`——**那是数据变更，先报我再动**，⛔ 顺手改（`data.gd` 一改就多一个 FAILED）。
  ⛔ 不许顺手把 `slug.gd:57` 的 `_shadow.texture` 改掉——那是投影，不是怪物贴图，两者同名不同职。
- **T-A-5** 接触表：每族 `<id>_atlas_prev.png`（NEAREST 5×），总表 `spr37_contact_monsters.png` **按道分组**（畜生→饿鬼→地狱→阿修罗→人→天，分组表见 S34 词汇层实稿 §4.1–§4.6），⛔ 按 id 字母序。
- **T-A-6** 跑 M1–M11 全量，日志落 `sp_logs/spr37_frames.log`；Godot 侧 M10 落 `sp_logs/spr37_m10.log`。

### T-B｜道具成对合并（🟡 前置 HP-7）

`chest_closed/open`→`atlas/chest.png` **40×16**；`door_closed/open`→**64×28**；`prop_barrel/hit`→**64×32**。
语义等价改造（两帧本来就在两张文件里靠代码换 texture），零新画法。改完须同步对应消费点，⛔ 留旧路径双份加载。
🔴 若 HP-7 未修好，本任务**不要开工**——会得到一堆"FAIL size="假缺陷。

### T-C｜商人 idle 2 帧（⚪ 可推迟到 S38）

`merchant_*` 32×40 → 64×40 两列。躯干上部 1px 起伏，⛔ 脚离地（它们是接地的）。
玩家最少看的东西，排最后；工时紧张就明写"本批不做"，⛔ 悄悄做一半。

---

## 3. 禁止事项

1. ⛔ 写/改任何 `scripts/*.gd` 之外的生产文件来"绕过"判据（改 `.tscn`、改 import preset 都不行）。
2. ⛔ 用 SDXL 直接产物当帧入库；⛔ 跳过 `to_table()` 量化；⛔ 抗锯齿/羽化/半透明 alpha。
3. ⛔ 一族一 median-cut（HP-2）。
4. ⛔ 给怪物加 attack/hurt/转向动画（消费侧无请求点＝死资源）。
5. ⛔ 共用一张 GIB 死亡帧跨 scale 档（实稿 §5.3 已裁：ogre 1.5 与 imp 0.85 不能共死）。
6. ⛔ 为凑 `md5sum -c` 变绿去刷新冻结清单——**收官由主理人手工刷，编程侧永不自刷**。
7. ⛔ 改 `validate.gd:6 KNOWN_ATLAS`、⛔ 改 `data.gd` 敌人条目字段结构（HP-5）。
8. ⛔ 动 `production/sprint-36/`。
9. ⛔ commit、⛔ push。

---

## 4. 必跑门控（七件套，缺一不交）

```bash
cd "D:/Create/Game/test-1"
GODOT="D:/SteamLibrary/steamapps/common/Godot Engine/godot.windows.opt.tools.64.exe"
rm -f "/c/Users/TangUser/AppData/Roaming/Godot/app_userdata/test_1"/_smoke_*.cfg*   # 跨 run 累积会污染可比性

# 基线（干净 env，勿挂 FORCE_* / JUMP_FLOOR / SMOKE_CALAMITY —— 它们会改随机流）
SMOKE=1 SMOKE_SEED=12345 "$GODOT" --headless --path . --quit-after 3200 > _tools/spr37_base.log 2>&1
# E1 指纹三档（开关是 META_FINGERPRINT，不是 SMOKE_META）
for s in 12345 777 42; do SMOKE=1 SMOKE_SEED=$s SMOKE_META_FINGERPRINT=1 "$GODOT" --headless --path . --quit-after 3200 > _tools/spr37_fp_$s.log 2>&1; done
# 贴图可达性专项（M10）
SMOKE=1 SMOKE_SEED=12345 SMOKE_ART_FRAMES=1 "$GODOT" --headless --path . --quit-after 3200 > _tools/spr37_art.log 2>&1
```

| # | 判据 | 本批特别含义 |
|---|---|---|
| 1 | `validate problems=0` | 含新 atlas 装载不产生缺失告警 |
| 2 | 每个探针 `done checked=N declared=N` | 新增 M10 探针会让 `declared` 变大，如实报新数，⛔ 为凑旧数删断言 |
| 3 | `[ERR]`=0 | 计数用 `cat *.log \| grep -a -c '\[ERR\]'`（⛔ `awk -F:` 配绝对 Windows 路径恒得 0） |
| 4 | `ok=false`=0 | 同上 |
| 5 | **E1 指纹逐字不漂移** | 本批 HP-4 声称零 rng 消费 ⇒ **应当不漂**。漂了＝有地方偷偷随机选帧，停下上报，⛔ 重定基线 |
| 6 | churn 只比断言行 | 必须钉 `SMOKE_SEED`；排除 `[SMOKE-NAV]/[SMOKE-CAM]/[SMOKE-E]/[SMOKE-LOOP]/[SMOKE-STALL]` 与时间戳 |
| 7 | 冻结状态如实报 | 预期 `assets.gd` 翻 FAILED（T-A-3 必然动它）；`slug.gd`/`data.gd`/`validate.gd` **不该翻**——翻了说明越界，立即上报 |

⚠️ `SMOKE_SAVE` 探针要 `--quit-after 3200` 才落地（帧数不足会报假绿）。`SMOKE_DAILY` 会用日期覆盖 `SMOKE_SEED`，跨批对照禁用。
⚠️ `-s` SceneTree 驱动若用来跑 M10：编译期早于 autoload 注册，裸 `Game`/`Assets` 标识符不编译，须 `root.get_node("...")`；`SceneTree` 无 `get_main_scene()`；`_initialize` 里起的协程必须 `await`。

---

## 5. 交付回报格式（给主理人独立核验用）

请给**实测数**，⛔ 给"应该没问题"。主理人会自己复跑，不看你的结论只看你的数。

```
V1  （主理人已自答关闭，无需回报）20/20 母版非空
V3  （主理人已自答关闭）唯一上报条件：是否必须改 data.gd:85 的 tex 字段 = <是/否>
T0  ✅ 已交付并已复验（七条负例 rc=0）——⛔ 重复回报旧数；只需在下面 T-A 段落里带上"分母改造后 selftest 重跑仍 rc=0"这一行
HP-9 🔴 新前置回执：M8 分母取自哪一行（贴原文）＋ ⑦号负例改造后的注入方式（贴原文）
T-A 逐族一行：id | 分母(同调用栈 opaque) | atlas WxH
              | walk opaque 三值 + walk bbox(x0,x1,y0,y1) 三组
              | die opaque 三值 + die 末帧相对分母比
              | walk 色集 / die 末帧色集⊆walk? | M1..M11(含 M7c/M8b/M9) PASS/FAIL
T-A 比值专列（我要用来定 V10 阈值收放）：id | walk帧1/分母 | walk帧2/分母 | die帧1/分母 | die帧2/分母
T-A 汇总：20 张中 PASS N / FAIL N；FAIL 逐条原因，并注明**你判它是实现错还是口径错**（不许自己改断言）
V9   ：spr37_v9_floating_die.png 已出 ✅（主理人已 IHDR 复核 96×160）⇒ 结论由主理人目视另发，无需回报
M10  ：20 个 id 的 get_frame_count("walk"/"die"/"idle") 实测
门控 ：problems=? / [ERR]=? / ok=false=? / 三档指纹是否与基线逐字一致(y/n)
       ⚠️ 只在动过 .gd 的轮次填；未动 .gd 就整段写 UNEXECUTED，⛔ 留空也⛔ 写 PASS
冻结 ：改动前 FAILED 名单 vs 改动后 FAILED 名单，新增者逐条对应到哪个任务号
日志 ：sp_logs/ 下文件名列表
```

---

## 6. 本单效力边界

- **T0 = 已收官**（编程侧落地、主理人独立复跑验收）。T-A 可做，但🔴 **先做 T-A-0（HP-9 分母改造）**。T-B 卡 HP-7（现已有实测举证，实稿 §6e）。T-C 可推迟到 S38。
- 本版即 **rev3**：§2 的 T0 段落由待办改为台账；靶值执行口径以本件为准，实稿同步升到 R3。**R2 那三处修正（M3x/M7c/M8 相对化）继续有效**，R3 只改 M8 的**分母来源**与两条新增硬前置（HP-9/HP-10），⛔ 把 R3 读成"回退 R2"。两处文字冲突时**以实施单为准**（靶值的执行口径归落地件）。
- V10 的四个系数（0.90/0.85/0.45/0.12）在新分母下等于**未校准**——它们只会因 T-A 回收数据而收放，⛔ 不会再动 G1–G5 家规。
- 若编程侧在实现中发现某条判据**今天就不可能满足**（例如某族 `to_table()` 后单帧 <30px、M8b 对它过严），**如实报上来，⛔ 擅自调阈值**。阈值归我裁：可能是改口径、也可能是那只怪需要重画母版——那是两个完全不同的结论。
- 🔴 **玩家族不在本批任何交付内**（实稿 §4.5 归属声明）。S38 实例问的那句「逐帧差异家规是否适用于玩家 attack 行」已由我在 §4.5 显式回答：**家规适用、机检靶不适用、`shardbearer.png` 不换图**；其 attack 行是复制件这一事实已登记为实稿 V13，**修复归 S38 B2b，⛔ 编程侧在本批顺手改玩家图集**（那会撞 AGENTS §9.3 那条硬指标，且必然多一个 FAILED）。
