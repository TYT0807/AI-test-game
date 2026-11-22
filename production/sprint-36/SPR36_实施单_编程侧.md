# SPR36 实施单 · 编程侧 —— **状态：PARTIAL（rev2，部分解闸）**

> **变更公告**：本单原为 DRAFT／BLOCKED（W1–W7 全未裁）。作者 2026-11-18 裁定 W1 并立下提问规矩（「创意题走创意测主理人；绝对无法判断的才落 `D:\大纲` 判断栏；不要一直打断思考任务」——逐字见实稿 §9.0）；其余 W0/W2–W6 由主理人按该规矩**自裁生效**（实稿 §9.2），仅 W7（图鉴第七类）留判断栏闸（措辞在实稿 §9.4，回话前默认按 C＝本批不进图鉴准备代码路径）。
> ⇒ **T-GUARD、T-A、T-B1–B3、T-C 数据侧已解闸可开工**；T-B6 图标随 T-B1 名单并行；T-D 挂 W7；T-B4/T-B5 维持禁改。
> ⛔ 编程侧遇到口径疑问找主理人，**不越级问作者**；也不许把主理人已裁条目再拿去问作者一遍（那就是「打断思考任务」）。

批次：Sprint 36（rev2）
撰写／修订：主理人，2026-11-18
配套：`SPR36_设计实稿_BOSS专武与无限制口径.md`（下称「实稿」，§ 引用均指 rev2）
验收：待 W7 判断栏回话后出 `SPR36_验证口径.md`；除图鉴靶外，其余靶值（R=1.25、每组恰好 2 把反超、图标 16×16、mw_* 默认集合）已在实稿 §7/§8.5/§9.2 钉死，**编程侧可先按它们自检，正式口径文件同批补**。

---

## 0. 开工闸（rev2 改写）

| 闸 | 条件 | 状态 |
|---|---|---|
| G1 | ~~作者逐条给字母~~ ⇒ 改为：**实稿 §9.2 自裁表生效 + W7 未回话部分不碰**。各任务前置标注 `[Wx=解]` 的照做；标 `[W7 闸]` 的等判断栏回执 | ✅ 本单即按此改写 |
| G2 | S35 状态（W0=A：S35 先收官）：**T-GUARD 不等 S35**（纯机检卫生，零内容耦合）；T-A 及以后须确认 S35 已收官或经主理人书面放行 | 🟡 开工前向主理人确认一次 |
| G3 | 起点自检并留档：`git log --oneline -1`、`git status --short`、`md5sum -c production/sprint-21/SPR21-FROZEN.md5`（上轮实读 = **4 FAILED**：`data.gd` `game_main.gd` `game_state.gd` `shrine_panel.gd`，属 S32 收官后微批遗留，**不是本批造成的**，不要为了「绿」去刷清单） | 每次开工跑 |

🔴 **行号纪律（重申）**：本单所有行号是主理人 2026-11-18 在工作树 `grep -n`/`Read` 现场坐实的，工作树相对 HEAD 有未提交改动——**落地前必须重新 grep 一遍**，别把这些数字当常数。

---

## 1. 硬前置（🔴 顺序依赖，违反即返工）

| # | 前置 | 为什么硬 |
|---|---|---|
| HP-1 | **先落机检卫生，再落内容**：T-GUARD（§3）必须在 T-A/T-B 之前完成 | 否则新增武器条目会踩到两处已知假绿（K 项数量前提、DEFS.icon 无门） |
| HP-2 | **零新增 `Game.rng` 消费**是全局前提 | AGENTS §4.2；实稿 F 项：`weapons.gd:86-97` 每次出武器**恒消耗 1 次**且注释明写这是随机流锚点 |
| HP-3 | 定向掉落 key 走 `stable_hash` 纯派生，格式对齐盘上既有范式：`Game.stable_hash("%s#%d" % [key, i])`，其中 `key := "%d_%d_%d" % [Game.run_seed, Game.floor_num, int(coord.x*1000+coord.y)]`（参考用法 `game_main.gd:1790`、`:3994`） | AGENTS §4.2 既有范式（S32/S33 一路沿用）；⛔ 不许自创 hash 拼法 |
| HP-4 | 图标一律程序化生成（`_tools/spr25_art_gen.py` 范式，十色基准表 `:32-41`），⛔ ComfyUI 产物直接入库 | 实稿 §8.5：SDXL base 1.0 不服从背景指令（A/B 受控实验，本轮 Δ 值标 UNEXECUTED） |
| HP-5 | 不改 `_shrine_theme_pref()` 的 `[up, down]` 返回结构（`game_main.gd:3940-3950`，本轮复核八条 rule 各返一对数组） | 实稿 §8.4 |
| HP-6 | 不占用 `variant`；图鉴登记只走 `codex_id` | AGENTS §4.8；`boss2.gd:19`、`boss3.gd:6-7` 两条历史教训注释（本轮复核原文在位） |
| HP-7 🆕 | **文案三条硬边界**（随 W1 裁定生效）：①游戏主角＝「先贤」（原创称法，实稿 §1.3），⛔ 任何游戏内文本不得出现「索拉尔／太阳骑士」字样、不得把他写成谱系表某行；②⛔ 主角与苏瑾同框；③「藏经阁丙区古籍／先贤游记」可按口述取用于手记，但⛔ 不得在任何文档引用它为正典条目（`D:\大纲` grep 零命中，实稿 §1.3/§10 已登记反哺候选） | 实稿 §9.0/§1.3；§27 引导语「只借鉴结构与意象，不落原文」（`_04.txt:135`） |

---

## 2. 任务条目（前置已全部落定，按标记执行）

### T-A｜L1「无限制」落地 —— 前置 ~~W5~~ **[W5=P-改语义，已裁]**

改 `scripts/meta.gd:53-70`（三节点 `u_mw_swarm/u_mw_arc/u_mw_cluster`）：

1. 三节点 `"default": false → true`；
2. `u_mw_arc.requires`（`:62`）与 `u_mw_cluster.requires`（`:68`）清空为 `[]`（`u_mw_swarm` 本来就是 `[]`）；
3. 🔴 **cost 保持 40/60/100 不动**——`validate.gd:512-513` 要求 cost 为正整数，改成 0 当场红。

必跑门禁：validate ／ E1 三档 seed（12345/777/42，`SMOKE_META_FINGERPRINT=1`）／ churn（钉 `SMOKE_SEED`）。

🔴 **E1 预期与实测义务（rev2 更新，比旧稿更严）**：理论依据不变——`Weapons.random_unlocked()` 只遍历 `DROP_POOL`（`weapons.gd:88`），`mw_*` 不在其中。**但本轮实读确认 Boss 房清场那一发（`game_main.gd:3005`）就在消费这次 rng**，而解锁集合会从 3 变 6：凡在 Boss 房之前消耗 rng 的系统若其分支数依赖解锁内容，其后整条随机流都会位移。⇒ **T-A 合入当天必须实测三档指纹并逐字贴 `[SMOKE-META] fingerprint` 行**；一旦漂移：先查解锁态读取点（`Meta.is_unlocked`/`unlocked_ids` 的消费方），如实报告，⛔ 不许靠重定基线掩盖。

⚠️ 副作用要处理：军械页对「已拥有但从未购买」节点的显示态。取数链：`game_state.gd:925 meta_unlocked_ids()`、`meta.gd:141-147 is_unlocked()`（`_defaults` 命中即 true）。显示口径靶在主理人出的验证口径里给，编程侧不自定。

### T-B｜L2「专武」内容落地 —— 前置 ~~W2+W3~~ **[W2=A（3 只主题 Boss）、W3=A（定向掉落），已裁]**

| 步 | 文件 | 动作 | 约束 |
|---|---|---|---|
| B1 | `scripts/weapons.gd`（DEFS `:11-65`） | 追加 **14 条**武器定义（棱镜 5＋熔潮 5＋玄渊 4，名单见实稿 §6.3），字段照现有范式；行为位只用既有 `homing`/`arc`/`cluster`（`:47 :55 :63` 三个先例） | 🔴 子弹参位固定 7 个（`bullet.gd:25-28`），⛔ 不加第 8 参位——那会牵动 `spawn_player_bullet` 与 `player._fire` 全部调用点 |
| B2 | `scripts/weapons.gd` | 新增只读常量 `BOSS_WEAPON := { "<weapon_id>": "<boss_codex_id>" }`（boss id 以 `data.gd:336-337 CODEX_BOSS_NAMES` 三键为准：`prism_warden`/`pyrothalassian`/`third_boss`） | ⛔ 该字段**不得**被 `unlocked_ids()`／`random_unlocked()` 读取（`:76-97` 行为是既有契约）；⛔ 不给专武建 `UNLOCKS` 节点（W3=A：建了就把「无限制」重新变成收费） |
| B3 | `scripts/game_main.gd:3005`（Boss 房清场掉武器那一行） | 改为**定向掉落**：按 `Data.boss_for_floor(Game.floor_num)`（`data.gd:521-525`，本轮复核函数在位）反查 `BOSS_WEAPON` 得该 Boss 的 4–5 把子集，用 HP-3 的 key 经 `stable_hash` 选一把，直调 `drop_pickup(..., "weapon", 1, id)`；🔴 **绕开 `_random_weapon()`**（`:3030-3031`→`weapons.gd:86`，那里消耗 rng）。实现只能经过 `_random_weapon()` 视为未完成，退回重写 | 已知代价（实稿 §6.2）：shotgun/railgun/launcher 从此不出 Boss 房——**接受，勿加补偿** |
| B4 | `scripts/game_main.gd:3236`（商店货架）、`scripts/pickup.gd:154`（大宝箱） | 🔴 **一行都不许改**（W3=A 的补偿条款：基础武器仍经这两处可得）。改了要在报告里点名，别静默 | — |
| B5 | `scripts/player.gd:202-221 give_weapon()` | 🔴 **一行都不许改**（W4=A：不扩槽，双槽＋Q 是手感骨架）。未知 id 回退 rifle 的护栏（`:203-206`）继续兜住专武 id——专武进 DEFS 后自然通过 `DEFS.has(id)` | 默认禁改 |
| B6 | 图标 | 每把新武器一个 `wpn_bw_*` 键，登记进 `assets.gd GEN_NAMES`（`:109-125`）；PNG 由 `_tools/` 新脚本程序化绘制。**尺寸拍板（主理人自裁）**：统一 **16×16 RGBA8**——理由：`mw_*` 两枚现役武器图标实测 IHDR 均为 16×16，专武与其同类；32×16 是基础四枪的老口径（`spr34_pixel.py:65`），不混用。⛔ 手持大图不做（O 项先例：`mw_cluster` 复用 `wpn_launcher` 都合法） | 🔴 漏 `GEN_NAMES` = `assets.gd:149-152` 只 `push_warning`、屏上白框零报错（AGENTS §4.3）。GUARD-2 的新门必须覆盖这批 icon 才算完（HP-1 顺序保证） |

### T-C｜L3「反超」死值口径 —— 前置 ~~W6~~ **[W6=A，已裁：R=1.25、每组恰好 2 把、tier=0]**

| 步 | 动作 | 约束 |
|---|---|---|
| C1 | 在 `scripts/data.gd` 新增具名常数 `WEAPON_SURPASS_RATIO := 1.25`；Boss 侧基准直接用磁盘现值：脉冲伤害三者同为 `boss.gd:24 dmg := 2`，interval 基类 `boss.gd:16 = 3.0`、`boss2.gd:31 = 2.2`、`boss3.gd:35 = 2.6` ⇒ dps_boss ≈ 0.667 / 0.909 / 0.769 | 🔴 比值必须是**具名常数**，⛔ 散写在 if 里 |
| C2 | 卡片小字「比它自己更疼」一类句子由 C1 常数**派生**，⛔ 手写百分比数字 | 防文案与数值漂移 |
| C3 | 断言：每只 Boss 的专武中满足 `dmg/interval >= dps_boss * R` 的把数 **== 2**；其余把须 `<= dps_boss`（不留灰区）。比较一律在 `abyss_tier == 0` 语境取表值 | 配刀时注意：14 把 × DPS 表要主理人复算核对，编程侧自报逐把数值 |
| 🚫 | **绝不**让专武改写 `abyss_hp_mult/abyss_speed_mult/abyss_dmg_mult`、`enemy_hp_mult`、`damage_mult`、`bullet_dmg_mult` | `_smoke_abyss_check`（`game_main.gd:450-494`）基准构造式在 `:489`，污染它＝探针失去意义；另参照 `data.gd:339-342` 载体硬约束注释 |

### T-D｜图鉴第七类 —— **[W7 闸：判断栏未回话，默认按 C 不实施]**

回话前：T-B 交付不含图鉴登记，专武只有 HUD 拾取反馈；代码上保证「将来加类不需要重构 DEFS/BOSS_WEAPON」（id 与 boss 归属已是纯数据）。
若判断栏回 A：按实稿 §8.3 五处微批执行——`game_state.gd:282` 与 `:376` 两处 `codex` 初始化（本轮复核：六 kind 字典两处逐字重复在位）、`_codex_id_valid`(`:296-320`) 加 weapon 分支、`menu.gd` 加 `_codex_section("weapons", …, 表长派生分母)`（⛔ 硬编码 12/15）、`data.gd FLAVOR` 补 `weapons/*` 手记（`validate.gd:250-260` 覆盖门逐类点数）、旧档无该键 → `.get` 兜底。
🔴 无论做否：`CODEX_BOONS[*].kind` 仍不得为 `suffixes`（`validate.gd:264-272`）或 `shrine`（`:273-278`）。

---

## 3. T-GUARD｜机检卫生（**已解闸，且不依赖任何裁定**——本批第一批活）

| # | 缺陷 | 证据（磁盘行号） | 处置 |
|---|---|---|---|
| GUARD-1 | 「3 把新武器行为标志传到子弹」把**数量 3 写死当前提**，新增带行为位的武器不会让它变红 → 假绿 | `game_main.gd:2569` 注释「# 3 把新武器…」＋ `:2570` `for w in ["mw_swarm","mw_arc","mw_cluster"]:`（本轮复核原文在位） | 改为遍历 `Weapons.DEFS` 中所有含 `homing`/`arc`/`cluster` 任一键的条目；配变异刀：故意把某条 `arc` 写成 0，断言必须红，还原后必须绿 |
| GUARD-2 | `DEFS[*].icon` 没有静态门：写错只在运行期回退 rifle 图标（`weapons.gd:68-72`）；`validate.gd:519-520 _meta_icon` 的门**只覆盖 UNLOCKS 侧** | `weapons.gd:68-72`、`validate.gd:519-520`、`assets.gd:149-152` | validate 增三向门：`DEFS[id].icon` ∈ `GEN_NAMES` ∧ `Assets.g(icon) != null`。⚠️ O 项先例合法：`mw_cluster` 复用 `wpn_launcher`（`weapons.gd:62`），门不能把它判死 |
| GUARD-3 | `[SMOKE-META] weapon pool: [...]` 只有 print、没有断言，池内容变化无人看守 | `game_main.gd:2439`（对比 `:2440-2445` 的 POOLASSERT 才有 `Dev.check`） | 增「武器可用数 ≥ `Meta.MIN_USABLE.weapon`」之外的**内容集**断言。默认态基线串（T-A 前后）由主理人在验证口径给定；⛔ 编程侧不自定基线 |

🔴 **冻结串卫生（上一批教训，照抄不删）**：D3 那条逐字串是在 `_calamity == ""` 态采集的，**有灾祸分支从未被现有 19 条覆盖**。本批若往池过滤里加任何新项，**一律另立新断言**，⛔ 不许复用旧串冒充覆盖。

---

## 4. 必跑门控与环境变量（七件套，缺一不交）

```bash
cd "D:/Create/Game/test-1"
GODOT="D:/SteamLibrary/steamapps/common/Godot Engine/godot.windows.opt.tools.64.exe"
rm -f "/c/Users/TangUser/AppData/Roaming/Godot/app_userdata/test_1"/_smoke_*.cfg*   # 跨 run 累积会污染可比性

# 基线（干净 env，勿挂 FORCE_* / JUMP_FLOOR / SMOKE_CALAMITY —— 它们会改随机流）
SMOKE=1 SMOKE_SEED=12345 "$GODOT" --headless --path . --quit-after 3200 > _tools/spr36_base.log 2>&1
# E1 指纹三档（开关是 META_FINGERPRINT，不是 SMOKE_META）
for s in 12345 777 42; do SMOKE=1 SMOKE_SEED=$s SMOKE_META_FINGERPRINT=1 "$GODOT" --headless --path . --quit-after 3200 > _tools/spr36_fp_$s.log 2>&1; done
# T-A 特别要求：改动前后各跑一遍上面两组，指纹行逐字对照（漂移=先查解锁态读取点，不许重定基线）
SMOKE=1 SMOKE_META_POOL=1 SMOKE_META_POOLASSERT=1 SMOKE_META_APPLY=1 ...
SMOKE=1 SMOKE_ABYSS=0 ...        # C3 的比较必须在 tier=0
SMOKE=1 SMOKE_ABYSS=3 ...        # 复原校验：_SB_TIER=3 那条链（game_main.gd:5446）不受本批影响
```

| # | 判据 | 本批特别含义 |
|---|---|---|
| 1 | `validate problems=0` | 含 GUARD-2 新门 |
| 2 | 每个探针 `done checked=N declared=N` | GUARD-1 改造后 `declared` 会变（不再是 3 把 × N），如实报新数，⛔ 不许为凑旧数删断言 |
| 3 | `[ERR]`=0 | 计数用 `cat *.log \| grep -a -c '\[ERR\]'`（⛔ `awk -F:` 配绝对 Windows 路径会把盘符冒号切错、恒得 0） |
| 4 | `ok=false`=0 | 同上 |
| 5 | E1 指纹逐字不漂移 | α 路应当不漂；T-A **是否不漂是实测问题**（§2 T-A 红块），漂了按流程上报 |
| 6 | churn 只比断言行 | 必须钉 `SMOKE_SEED`；排除 `[SMOKE-NAV]/[SMOKE-CAM]/[SMOKE-E]/[SMOKE-LOOP]/[SMOKE-STALL]` 与时间戳 |
| 7 | 冻结状态如实报 | 收官由**主理人**手工刷 `SPR21-FROZEN.md5`；编程侧永不自刷 |

⚠️ `SMOKE_SAVE` 探针要 `--quit-after 3200` 才落地（不足会报出假绿）。`SMOKE_DAILY` 会用日期覆盖 `SMOKE_SEED`，跨批对照禁用。

---

## 5. 禁止事项（rev2）

1. ⛔ 不新增 `ACTION_DEFS` 动作（现 18 条，`assets.gd:333-353`）。
2. ⛔ 不新增 `bullet.gd setup()` 参位（现 7 行为位，`:25-28`）。
3. ⛔ 不改 `DROP_POOL`（`weapons.gd:9`）。
4. ⛔ 不改 `_shrine_theme_pref` 的 `[up, down]` 结构（`game_main.gd:3940-3950`）、不把专武加入 `SHRINE_OFFERS`（`data.gd:313-325`）。
5. ⛔ 不改 `CALAMITY_SHRINE_DOWN`（`game_main.gd:3953-3960`）的四种灾祸映射。
6. ⛔ 不引入新的全局倍率载体；不碰 `ABYSS_TIERS`（`data.gd:468-478`）与 `_smoke_abyss_check` 基准式（`game_main.gd:489`）。
7. ⛔ 不加计时器用 raw `delta`（E6；豁免只有 `player.gd` buff tick 与 `toxic_cloud.gd` 两处，不许顺手统一）。
8. ⛔ 不用扩散模型产物直接入库当图标／精灵；过程帧必须程序化。
9. ⛔ 不把「无限制」做成系统提示／权限弹窗／解锁面板（实稿 §5.4）。
10. ⛔ 不挪用他作专名——**含「索拉尔／太阳骑士」**（§27 引导语「只借鉴结构与意象，不落原文」＋HP-7）；轮回乐园等他人原作全文照旧禁取。
11. ⛔ 不给专武建 `UNLOCKS` 节点、不让游戏主角与苏瑾同框、不把先贤写成谱系表某行（HP-7／W3=W5 裁定推论）。
12. ⛔ 不自刷 md5、不 commit 混入主理人文档、不 push（推送需作者逐次点头）。
13. ⛔ 发现某条断言在当前数据下恒真（前提守卫型），**如实标注性质**，不许改断言迁就实现（AGENTS §5）。
14. ⛔ 不把主理人已裁的 W0/W2–W6 拿去再问作者；口径疑问只找主理人。

---

## 6. 交付回报格式（给主理人独立核验用）

编程侧自报须含：改动文件清单 + 每个文件的函数名（⛔ 只给行号，行号会腐烂）+ 七件套**实测数**（逐条原文粘贴关键行）+ **T-A 前后 E1 三档指纹逐字对照结果**（本批最大风险点）+ GUARD-1/GUARD-2 变异刀结果（改坏→红、还原→绿各贴一次）+ 14 把专武的 DPS 表（逐把 dmg/interval/所属 Boss/是否 ≥ dps_boss×1.25，供主理人独立复算 C3 计数）+ 冻结表 `md5sum -c` 原样输出。

主理人将**不看自报数**独立复现：自己 `grep -n` 坐实行号、自己跑门禁、自己算 DPS 比值表。

---

## 7. 本单当前效力边界（rev2，避免误读）

- **立即开工**：§3 T-GUARD 三条（不依赖任何裁定，且修的是既存假绿）。
- **S35 确认后开工**：T-A（单独提交、自带 E1 实测义务）→ T-B1–B3 ＋ B6（图标可与 B1 并行）→ T-C。
- **挂闸**：T-D（W7 判断栏回话前不实施；默认按 C 准备）。
- **永久禁改**：T-B4、T-B5。
- 若作者事后撤销 §9.2 某条自裁：只停对应任务（撤哪条停哪块，映射见实稿 §9.2/§9.3），其余照常。
- 本单不存在「正文引用了未落盘的条目」：所有引用都在本文与实稿 rev2 内可寻。
