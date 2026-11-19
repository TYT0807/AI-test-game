# SPR40 交付_B组 · 武器族去火药枪化原子迁移（M1~M11＋M6b＋乙-1~乙-7，EXEMPT-1 已用）

批次：Sprint 40 · B 组
日期：2026-11-18
交付人：编程侧
核验人：`六道卷游戏 · 主理人`（裁定件 `SPR40_主理人裁定_R2_M9图标键与印记断言.md`；本件不代替其结论）
配套判据：`SPR40_设计实稿_武器族去火药枪化.md`（M1~M11／乙案）、`SPR40_主理人核验_C组与B12.md` §3.1（`META_WEAPON_POOL_BASELINE` 逐字串）、`SPR40_主理人裁定_R2_…` §1.1~§1.4／§2.2／§3.2／§3.3／§5、`SPR40_实施单_编程侧.md` §6（禁止事项 #1~#14）、`SPR40_验证口径.md`（V-W1）

**一句话状态**：四把基础武器 `rifle/shotgun/railgun/launcher` → `zhushan/liechi/guanglei/fushe` 的**整批原子迁移已落地并成为现役绿基线**（`player.gd 733a4b3c → 5835d2e6`，归档闸自证 `ARCHIVE-GATE GREEN 归档=5 份`）。33 条锚点全部恰好命中、9 个文件行行数逐文件守恒、旧符号残留归零（`leftover=0`）、图标 4 枚转正且旧 4 枚 PNG 一字节未动。运行期正证：**V-W1 `VW1-GREEN` 四把×12 项数值逐字段相等＋name/desc/icon 全换＋14 条局外事实全过**、十面门控全绿（`[ERR]=0`、`ok=false=0`、`SCRIPT ERROR=0`、`validate problems=0`）、三档指纹逐字节不变、印记契约反向自证 `SIGIL-REV-GREEN` 五步全过（含「合法但错 id」的纯红臂）。**本件另报十三条偏差（§5 P-1~P-13），其中七条要主理人处置：R2 §2.2 给的印记面判据在本面结构上不存在、V-W1 的「空池回退」不可测（M5b 属写法级条款）、B 打破两处刀表锚点（其中 `spr36_knives.py:296` 是**会永久撒谎的自证行**）、`CHURN-DONE blind_faces=无` 这句在本口径下说过头、stance 结论行两条未归因新形状（`_sp_pending`／`blocks` 不对称）、主理人给的冻结重登三值在本仓任何树上都复现不出、施工单第 5 项的证据件曾被固定文件名就地覆盖（现已独立归档 `_tools/spr40_b/qa3200/`，但我早前引用的 `checked=48` 在本仓根本不存在，且 `equip_calls` 与帧数无关）。另有两条属登记轮口径：冻结普查 22/12→21/13（`menu.gd` 因乙-3 离开冻结集）、文档面 `issues=5` 里新增的第 5 条是 B 换 id 的连带红（归档 S38 交付件逐字引用旧 id）。**⛔ 编程侧自行抹平任何一条。

**数值状态**：本批**不动任何数值字段**——`dmg/interval/count/spread/speed/mag/reload/pierce/life/explosive/tint` 十一项逐字段等于改前（§2 V-W1 表）。含「枪/弹/炮/膛」的 28 行文案属作者保留域（D4 集束榴弹／D5 全局语汇），本批⛔ 动，仅供 V-W2 记账（原文在 `_tools/spr40_b/migrate.apply.txt` 第 17~44 行）。

---

## 0. 代码面落点（本批改了什么）

### 0.1 站点分布（体检原话：`体检通过：锚点 33 条全部恰好命中 ＋ 图标 4 枚 IHDR/占位合规`／`MIGRATE-OK sites=33 files=9 png=4 leftover=0`）

`33` 是**锚点条数**：M 案 27 条 ＋ 乙案条目 5 条 ＋ 乙-5 一条。其中乙-7 一条要命中 2 行 ⇒ **实际替换落点 34 处**，⛔ 把 33 读成落点数。

| 文件 | 站点 | 内容 |
|---|---|---|
| `scripts/weapons.gd` | 18 | M1key×4、M1名×4（name＋desc 同行）、M1图×4（带 `tint` 前缀锚，裸串会命中 2 次）、M2、M2注、M3（文件头注释）、M5a、M5注、M5b ＋ 乙-4（`mw_cluster` 复用键） |
| `scripts/player.gd` | 4 | M4a `weapon_slots`、M4b `slot_mags`、M5c 未知 id 回退（文案＋id 两行同锚）、M6b 印记自证 `ok = weapon_slots[1] == "liechi"` |
| `scripts/game_main.gd` | 3 | M6 武备印记注入（两行三处字面量）、M10 `_ml_equip("zhushan", 30)`、M11 `META_WEAPON_POOL_BASELINE`（逐字转录核验件 §3.1，两行换两行） |
| `scripts/data.gd` | 2 | M7「开局副手预装裂髓杵」、M8「先齐射再补一发」 |
| `scripts/assets.gd` | 1 | 乙-1 `GEN_NAMES` 同位换四键（总数守恒 76） |
| `scripts/menu.gd` | 1 | 乙-3 主菜单「退出游戏」按钮图标键 `wpn_launcher`→`wpn_fushe`（旧键唯一 UI 消费者） |
| `scripts/validate.gd` | 1 | 乙-6 认可复用的注释（只改 11 个字） |
| `scripts/meta.gd` | 1 | 乙-5／EXEMPT-1 `UNLOCKS` 内 `"icon": "wpn_launcher", "max": 1,` → `"icon": "wpn_fushe", "max": 1,` |
| `_tools/spr36_knives.py` | 2 | 乙-7 K5 刀锚点跟随（⛔ 改期望话 `缺 [mw_cluster]`） |

### 0.2 逐文件 md5（改前戳＝`_backup/spr40_b/before.md5` ＋ 同目录 `scripts/` 原件副本 68 件；改后戳＝`_tools/spr40_b/after.md5`，均为落地窗当场盖的直接戳）

| 文件 | 改前 md5 | 改后 md5 | 行数（改前→现行，HP-13） |
|---|---|---|---|
| `scripts/weapons.gd` | `315e9283d6b879eb5a1717a048c54dfd` | `c07867231a42097196e3e5693528a3f2` | 354 → 354 OK |
| `scripts/player.gd` | `733a4b3c524219c237441d53e3ebc9b2` | `5835d2e6e9e89d3a6dd4155bcadc0b19`（**现役绿件**） | 2648 → 2648 OK |
| `scripts/game_main.gd` | `5978d36835881a40e42f532f0098c7e8` | `b934f7dd332c60374776aa9c240ca4e2` | 7423 → 7423 OK |
| `scripts/data.gd` | `9aab58fde16d5c83a76fb0f0835e3dc5` | `87ddf3a35c5c771b63b39079869eaaed` | 580 → 580 OK |
| `scripts/assets.gd` | `e0f2d2ac1b214ac0df97e928a1c13cb1` | `e917a28ed54dc0d10c2af9d4c2de7c73` | 510 → 510 OK |
| `scripts/menu.gd` | `ae20204f70d966be4b0f91714ae92d24` | `0ddd65f5a372e71c0e2f8d8f2ba3780f` | 1094 → 1094 OK |
| `scripts/validate.gd` | `10eb44a55e54b1865d9eba3e50e80faf` | `fe9d84ecdbc9c9c63205fe81d94bbc6f` | 1020 → 1020 OK |
| `scripts/meta.gd` | `0bdf0e840c3c4859a96304c54220468b` | `3eaa7d3b84cb241c04dedba9b284a402` | 176 → 176 OK（差异仅 `71c71` 一行，见 §7-①） |
| `_tools/spr36_knives.py` | — | 同路径 | 315 → 315 OK |

未动的 26 个 `.gd` 与 `before.md5` 逐字节相同（34 件里 8 件变动、26 件同值：`bullet.gd 95370e21`、`boss.gd 0303ce20`、`game_state.gd 7d10f3d1`、`slug.gd 341880b4` 等，全表见 `_tools/spr40_b/after.md5`）。

绿件转正链：`dc622351`（S38）→ `4f907fbb`（A 组清扫块）→ `2364e3b1`（A 组收官）→ `733a4b3c`（C 组）→ **`5835d2e6`（B 组，现役）**。归档五份均在 `_tools/spr40_good_player_archives/spr38_good_player.<前8位>.bak`，转正件 `_tools/spr40_b/promote_5835d2e6.txt`。

图标转正：`_tools/_artgen/preview_spr40_wpn/` → `resources/texture/generated/` 四枚（`wpn_zhushan.png`、`wpn_liechi.png`、`wpn_guanglei.png`、`wpn_fushe_w.png`→`wpn_fushe.png`），IHDR 合规校验＝32×16/8bit/6 通道；目标已存在即拒绝覆盖。旧 4 枚 `wpn_{rifle,shotgun,railgun,launcher}.png` 在盘 mtime 仍是 `11-07 22:28`（R2 §169 第 4 条：⛔ 删／覆盖）。

证据目录：`_tools/spr40_b/`（`migrate.apply.txt` 落地窗 stdout／`import.log` 资产重导入／`after.md5` 改后戳／`gates.txt` 十面＋三机检＋TAU／`vw1.txt`＋`vw1_afterfix.txt` V-W1／`w2_vw1.out`＋`w2_vw1self.out`＋`w2_m5b.out` 收官窗④／`promote_5835d2e6.txt` 窗①／`w2_b1snap.out` 窗②／`sigilrev_chain3.log` 反向自证整窗／`docaudit_2240_chain.txt` 文档面原文留档／`window2.log`＋`window2_chain.log` 收官窗账）。⚠️ 本目录内文件是**我抄出来的副本**：`_tools/spr38_run.*.log` 与 `_tools/spr38_*` 会被并发窗就地覆盖（11-18 22:42 实测有三件证据被别窗写没），引用一律以本目录为准。

---

## 1. 改前基线（HP-0）

B 组改前树 = C 组收官树（`player.gd = 733a4b3c…`）。环境一律 `SMOKE=1 SMOKE_SEED=12345 [--quit-after 3200]`，每次跑前擦 `%APPDATA%/Godot/app_userdata/test_1/_smoke_*.cfg*`。

| 项 | 实测（改前） | 取源 |
|---|---|---|
| ①~⑤ 五项（指纹串／validate／checked-declared／`[ERR]`／`ok=false`＋`SCRIPT ERROR`） | 同 `SPR40_交付_C组.md` §2「改后」一列（同一棵树，本批⛔ 重贴以免两处漂移）：melee `94/94`＋`swings=57 draws=57`、sweep `56/56`、parry `70/70`、stance `7/7`、sc `19/19`，三档指纹逐字节相同，`[ERR]=0`、`ok=false=0`、`SCRIPT ERROR=0` | `_tools/spr40_c_after/` |
| 冻结普查（改前） | **22 OK / 12 FAILED / 缺 0**（A 轮 24/10 → C 轮 23/11 → B 改前 22/12） | C 组文档面 |
| DEFS 数值快照 B0 | `weapons.gd md5=315e9283`；四把 `rifle/shotgun/railgun/launcher`；`DROP_POOL=["shotgun", "railgun", "launcher"]`；`icon(不存在的id)` 回退 `wpn_rifle.png`；`Assets.g(wpn_launcher)=true`、`g(wpn_zhushan)=false` | `production/sprint-40/SPR40_B0_DEFS快照.txt`（落地窗 21:34，`_tools/spr40_b0_run.log`） |
| 印记面（`SMOKE_SIGIL_COVERAGE=1`）改前 | `seed=12345 enter_arsenal=1 cov_done=1 ERR_sigil_cov=0 ERR_all=0 SCRIPT_ERROR=0 lines=49` ＋ `weapon: shotgun=24 liechi=0 rifle=0 zhushan=0`，`first_err` 行数=0 | `_tools/spr40_sigil/sigil_before.metrics.txt`（窗 `_tools/spr40_sigil_before_run.log` 22:03:54） |

---

## 2. 改后同五项（＋B 组专项三面）

| 项 | 实测（改后） | 与改前的关系 |
|---|---|---|
| ① fingerprint 串 | 三档逐字节相同（`cmp` 整份 `fp<seed>.full_selftest.txt`：175／206／213 字节） | 不变 ⇒ B 没扰动 E1（§3） |
| ② `validate problems` | **0**（十面各 1 条） | 不变 |
| ③ 探针 checked/declared | melee `94/94`＋`swings_total=57 draws_total=57`；stance `7/7`；sc `19/19`；sweep `56/56`；parry `70/70` | 既有面**逐字不变** |
| ④ `[ERR]` 计数 | **0**（十面＋印记面＋V-W1 面） | 不变 |
| ⑤ `ok=false` / `SCRIPT ERROR` | **0 / 0** | 不变 |
| ⑥（专项）V-W1 数值守恒 | `VW1-GREEN 四把 × 12 项逐字段相等 ＋ name/desc/icon 全换 ＋ 14 条局外事实全过` | 改前无此面对照（新面），逐字段基线取自 B0 快照 |
| ⑦（专项）印记契约自证面 | `SG-OK tag=falsify_a enter=1 cov_done=1 weapon: liechi=21 zhushan=0`，`ERR_sigil_cov=0 ERR_all=0 SCRIPT_ERROR=0` | 面上副手位由恒 `shotgun=24` 变恒 `liechi`、旧 id 归零 |
| ⑧（专项）B1 运行期事实 | `Assets.g()` 四把新键全非空、`icon(不存在的id)` 回退 `wpn_zhushan`、`GEN_NAMES.size()=76`、`DROP_POOL=["liechi", "guanglei", "fushe"]` | 由「旧键」改「新键」的同型对照 |

机检三件与同源普查（`_tools/spr40_b/gates.txt` 第 21~29 行原文）：

```
spr38_g_chk_fp           rc=0 verdict=VERDICT=ALL_MATCH hit=1 expect=1 | doc_hits=3 hits=1 hits=1 hits=1 
spr38_g_chk_verbatim     rc=1 verdict=VERDICT=VERBATIM_MATCH hit=0 expect=1 | code_hits=27 doc_hits=27 expect=27 
spr38_g_chk_quota        rc=0 verdict=VERDICT=IN_SYNC hit=1 expect=1 | hits: oracle_block=1 equip_calls=34 defs_block=1 
spr38_g_chk_taut         rc=0 verdict_hit=1 expect=1 | 合计 应解析=568 实解析=568 可疑(T1+T2+T3)=0
TAU 记账可疑=1 豁免=1 非豁免=0 STALE=0 UNUSED=0 orphan=0 ｜ T3b T3B_REGISTERED=4 T3B_UNLISTED=0
```

`chk_verbatim rc=1` 是**本批连带红**（不是判据抓到回归也不是我改口径）：它把归档件 `production/sprint-38/SPR38_交付_B1_非弹幕近战内核.md` 里逐字引用的 `game_main.gd` 武器 id 串与代码比对，B 换 id 后 `only_code=['fushe','guanglei','liechi','zhushan']` / `only_doc=['launcher','railgun','rifle','shotgun']`。归档交付件⛔ 由我回改（同 §5 P-3 的处置），这笔红属 R2 §3.3 登记轮。

冻结普查（改后）：**21 OK / 13 FAILED / 缺 0**（文档面自算：`冻结 自算 OK=21 FAILED=13 缺文件=0`）。差分＝`menu.gd ae20204f→0ddd65f5`（乙-3）离开冻结集。⛔ 我自刷 `SPR21-FROZEN.md5`／⛔ 我改 `FROZEN_SITES`。

---

## 3. churn：只比断言行（`SMOKE_SEED=12345` 已钉）

口径＝`_tools/spr40_churn.sh`（主理人裁定件 §5 第 1 条）：只比探针自己打的 `[SMOKE*]/[S38*]/[VH*]/[MG*]/[SW*]` 行；BASE=改前树日志 `_tools/spr40_c_after/`，AFTER=改后树日志 `_tools/spr40_b/after_w3/`（转正后那次 `STEP=all` 的 gates 归档；⛔ 用落地窗的 `after/`——它跑在未转正树上）。

### 3.1 原口径合计（`_tools/spr40_b/churn.txt` 逐行转录）

| 面 | 探针行 改前 | 改后 | 漂移 | `ok=false` |
|---|---|---|---|---|
| base | 124 | 125 | 109 | 0 |
| melee | 201 | 195 | 100 | 0 |
| stance | 139 | 127 | 142 | 0 |
| apply | 154 | 139 | 131 | 0 |
| rng | 138 | 123 | 111 | 0 |
| sc | 148 | 137 | 121 | 0 |
| pw | 130 | 128 | 120 | 0 |
| fp12345 | 131 | 125 | 120 | 0 |
| fp777 | 127 | 126 | 123 | 0 |
| fp42 | 104 | 115 | 117 | 0 |

`CHURN-DONE red=0 blind_faces=无`（这一句的问题见 §3.2 与 §5 P-10）。

### 3.2 🔴 上面那个「漂移」合计把三类行加在了一起，⛔ 单独引用

①**本批必须变**的更名行（`[SMOKE-P] weapon=rifle` → `weapon=zhushan`——它不变才说明迁移没生效）；②同 seed 下敌人点位／走位／击杀数的现场抖动；③带判据结论的行。为此另跑只读件 `_tools/spr40_b_churn_numbered.py`（零 Godot，输出 `_tools/spr40_b/churn_numbered.txt`），按全集（⛔ 抽样）把三类分开：

| 面 | 编号断言行 `] #NN … ok=` 改前/改后 | 逐字相同 | 判定形状行 改前/改后 | 更名归一后相同 | `[SMOKE-P]` 行 改前/改后 |
|---|---|---|---|---|---|
| base | 0 / 0 | Y | 1 / 1 | Y | 21 / 22 |
| melee | **94 / 94** | Y | 96 / 96 | Y | 20 / 19 |
| stance | 0 / 0 | Y | 2 / 2 | **N ⇒ 见 §3.3** | 24 / 22 |
| apply | 0 / 0 | Y | 5 / 5 | Y | 22 / 22 |
| rng | 0 / 0 | Y | 3 / 3 | Y | 22 / 22 |
| sc | **19 / 19** | Y | 21 / 21 | Y | 22 / 21 |
| pw | 0 / 0 | Y | 1 / 1 | Y | 22 / 21 |
| fp12345 | 0 / 0 | Y | 1 / 1 | Y | 21 / 22 |
| fp777 | 0 / 0 | Y | 1 / 1 | Y | 23 / 22 |
| fp42 | 0 / 0 | Y | 1 / 1 | Y | 21 / 22 |

⇒ **十面里只有 melee(94) 与 sc(19) 真的有 `#NN` 形状的行**；其余八面一条都没有 ⇒ ⚠️ `CHURN-DONE blind_faces=无` 在这个口径下说过头了（它只证明「结论行没红」，不证明「八面有可比断言行」），登记为 §5 P-10。分开算之后的真话是：**编号断言行 0 条漂移；判定形状行 9 面 0 条漂移；stance 一面见下**。

### 3.3 stance 那条结论行的字段级读数（本轮唯一非绿的判定行）

```
改前 spr40_c_after : shots=95 len=0.3333 window=235 moving_window=233 leaks=0 blocks(idle/walk)=55/55 released=7  死亡打断=0 闩锁未结算=1 done checked=7 declared=7
改后 after（落地窗）: shots=84 len=0.3333 window=240 moving_window=238 leaks=0 blocks(idle/walk)=85/85 released=27 死亡打断=0 闩锁未结算=0 done checked=7 declared=7
改后 after_w3（收官）: shots=83 len=0.3333 window=243 moving_window=239 leaks=0 blocks(idle/walk)=87/85 released=25 死亡打断=0 闩锁未结算=0 done checked=7 declared=7
```

- **真判据字段全部保持**（逐条对着 `scripts/player.gd` 的 `Dev.check` 站点核过，不是看数顺眼）：`leaks==0`（:620）、`blocks_idle+blocks_walk>0`（:616）、`released>0`（:625）、`window>=40`（:602）、`moving_window>=4`（:605）、`checked==declared==7`（:628）。⇒ 架式窗口守卫的七条断言在迁移树上仍全绿，且「挡住过切走」与「交还过动画」两头都有样本。
- **幅值漂移不是 B 带来的新形状**：同字段跨轮历史带＝`42/42`（`spr40_after`，A 组）→ `55/55`（`spr40_c_after`）→ `56/56`（S38 期归档）→ `85/85`、`87/85`（本批两个 B 窗）；`shots` 带 71～100 已由 C 组交付件 §3.2 当既有已裁形状登记过。⇒ 归噪声底，⛔ 我据此说「守卫变强了」或「变弱了」。
- 🔴 **两条我没归因的新形状，交主理人定处置**（详 §5 P-11）：①`闩锁未结算`（＝`player.gd:633` 打的 `1 if _sp_pending else 0` 快照）改前三份归档**全是 1**，本批两个独立 B 窗**全是 0**；②`blocks(idle/walk)` 首次出现**两值不等**（87/85）。两处都⛔ 在任何 `Dev.check` 的判据里（`_sp_pending` 只打印；idle/walk 只比「和 > 0」）⇒ 既不能报成回归，也不该顺手报成无关抖动；样本 3 对 2，我不推因果。

### 3.4 机检五件 ＋ E1 指纹逐字节

```
FP-12345 GREEN 逐字节相同 (175 字节)   FP-777 GREEN 逐字节相同 (206 字节)   FP-42 GREEN 逐字节相同 (213 字节)
CHK spr38_g_chk_fp GREEN ｜ chk_quota GREEN ｜ chk_taut GREEN ｜ clause GREEN
CHK spr38_g_chk_verbatim 漂移 ⇒ only_code=['fushe','guanglei','liechi','zhushan'] only_doc=['launcher','railgun','rifle','shotgun']
```

🔴 卫生提示（§5 P-8）：`CHURN-DONE red=0` **不等于**机检五件全等——`spr40_churn.sh:47-53` 的 `chk_*` 段只报漂移、不计 RED。本轮它恰好报出 `chk_verbatim` 漂移：那是**单侧漂移**（代码侧已换新 id、文档侧基线串还写旧 id），与 §2 文档面第 5 条 FAIL 同源，属登记轮（R2 §3.3）四件事之一，⛔ 我改文档侧基线串。

---

## 4. 变异刀清单（声明的应红面号 → 实测红号）

B 组**没有自己的新刀族**（R2 未点、实稿 §4 未列）。所以本批「刀还咬人」这件事靠三件拼起来：①既有十把近战刀（`_tools/spr38_mut.py`）在**迁移后树上**逐把复跑仍咬合；②印记契约的 M6 单方破缺**反向自证**（§6，五步 `SIGIL-REV-GREEN`）；③V-W1 三臂自证件 `VW1-SELFTEST-GREEN 三臂全按期望`（证明「数值守恒」那条判据自己会红）。

### 4.1 十把近战刀（`_tools/spr40_b/w3_knife.log`，`STEP=all` 刀段 22:58:09 起跑，逐字转录）

| 刀 | 打哪（`spr38_mut.py` 文档串原义） | 实测红条数 | 实测红号 | `validate problems` |
|---|---|---|---|---|
| 1 | E1d① 零抽取（删掉那次 `randf()`） | 4 | `#48 #53 #55 #56` | 1 |
| 2 | E1d② 抽两次（前置另起一行真抽） | 1 | `#48` | 1 |
| 3 | B6 HP-4 `from_dir` 写废（传 `Vector2.ZERO`） | 1 | `#31` | 0 |
| 4 | B7 旁路标志不清零（跨帧泄漏） | 2 | `#34 #35` | 0 |
| 5 | C1 过载仍算动作（去掉配额见底早退） | 4 | `#47 #48 #71 #72` | 0 |
| 6 | B3 只扫组内第一只（melee 退化 spear） | 2 | `#21 #22` | 0 |
| 7 | D3 爆炸系数 0.6 写死改 1.0 | 2 | `#55 #56` | 0 |
| 8 | C2c 复位令牌失效（摘掉 `gen != _reload_gen`） | 1 | `#85` | 0 |
| 9 | E1d③ 空挥不抽（抽取前预扫描扇内） | 7 | `#36 #45 #46 #47 #48 #84 #85` | 0 |
| 10 | E1d③ 空挥不抽（同行内联三元式） | 3 | `#45 #46 #48` | 0 |

- 十把全 `BIT`；每把 `script_err=0`；`done checked=94 declared=94` 十份全在；`swings_total/draws_total`＝57/57（刀 5＝255/255、刀 9＝34/34）。
- 链尾逐字：`restored md5=5835d2e6e9e89d3a6dd4155bcadc0b19` ＋ `ALL KNIVES BIT`（＝现役绿基线，十把刀都逐字节还原了）。
- **跨轮对照**：红条数串 `4/1/1/2/4/2/2/1/7/3` 与 `#48` 红集合 `{k1,k2,k5,k9,k10}` **与 S38 B1 收官那轮主理人终局复扫同数**（`SPR38_交付_B1_非弹幕近战内核.md:223`／`:249`）⇒ 迁移没让任何一把刀改咬别的面。刀 1／2 的 `problems=1`、刀 10 的 `problems=0` 也与该件 §二 第 8 条按 R4 收窄后的措辞一致（静态门抓不到同行内联，只有 state 神谕抓得住）。
- ⚠️ 口径如实报：本族的驱动 `_tools/spr38_knife.sh:38-46` **只闸**「`ok_false>0` ∧ `SCRIPT ERROR=0` ∧ `done` 行在场 ∧ 还原 md5 相符」，**没有写死的 EXPECT 红号表**（盾反族 `spr40_parry_knife.sh:24-32` 才有）。⇒ 上面那句「跨轮同数」是**两份交付件转录对照**，不是机检；要机检得由主理人点单补表（S41 候选，见 §9）。

### 4.2 spr36 刀表（K／N／P 三家族共 22 把）：本轮**没跑**，改用静态锚点普查，查出 2 把死锚

跑全套要 ~46 次 headless 启动，而「刀能不能落下去」＝`knife()` 落刀前的锚点命中数（`_tools/spr36_knives.py:205-222` 的 `land()`＋`count(old)!=1` 即 `INCOMPLETE`），静态就能算准 ⇒ 只读件 `_tools/spr40_b_knife_anchor_census.py`（`ast` 解析三张表，⛔ import 该件——它末行是裸 `main()`，一 import 就启动 Godot 全家）。**普查只报锚点可命中性，⛔ 报成「门有牙」**——后者要真跑。结果（`22 把 / 死锚 2`）：

| 刀 | 锚点／注入串 | 现盘命中 | 判定 |
|---|---|---|---|
| **N4** 专武挤进 DROP_POOL | `const DROP_POOL := ["shotgun", "railgun", "launcher"]` | **0** | 🔴 死锚，B 打破的（退役 id） |
| **P4** 摘掉开火记账钩子 | `\t_probe_stance_shot()` | **2**（`player.gd:698`／`:747`） | 🔴 死锚，⚠️ **不是 B 打破的**：改前树 `_backup/spr40_b/scripts/player.gd`（`733a4b3c`）同样命中 2 |
| :296 收尾「旧串是否都回来了」自证行 | 同 N4 的旧 `DROP_POOL` 串 | — | 🔴 B 起**永久打印「残留！」**（假红），详 §5 P-9 |
| **N14** 注入串 | `b'\t"rifle": "prism_warden",…'` | 锚点命中 1（活刀） | ⚠️ 注入用的是退役 id ⇒ 它模拟的坏法语义过时 |
| 其余 19 把（K1–K5／N1–N3／N5–N13／P1–P3） | — | 恰 1 | 锚点仍在位（⚠️ 未真跑，不主张红号） |

- 普查件对 N13 另打了一条「新串已在盘上=1」提示——那是**我自己启发式的误报**：`Game.stable_hash(key)` 这种短调用在 `game_main.gd` 本来就有别处在用，⛔ 读成「这把刀已等效落地」。
- K5 那两行锚点已由乙-7 同步（`_tools/spr36_knives.py:25-28`，各 1 处）；**其余旧 id 字面量乙-7 未覆盖**，就是上表三条 ⇒ 处置见 §5 P-9 与 §9。

### 4.3 K5 专项（R2 §1.4 要求本轮说清的一条）

- 乙-7 已把 `_tools/spr36_knives.py:25-28` 那两行锚点里的 `"icon": "wpn_launcher",'` 同步为 `"icon": "wpn_fushe",'`（各 1 处，共 2 处），⛔ 期望话 `缺 [mw_cluster]` 未动。
- **订正我早前口头说过的一条**：我此前判断「K5 锚点带 `\r\n` 而 `meta.gd` 是纯 LF ⇒ 这把刀早就死了」。实读 `_tools/spr36_knives.py:205-222 land()`：锚点在比对前会按**目标文件自己的 EOL 归一**，`meta.gd` 纯 LF ⇒ 归一后恰命中 1 次，K5 是**活刀**。本轮同步锚点属于「跟随实现」，不是救活死刀。
- S41 待办（R2 §1.4 记名，本轮⛔ 做）：K5 锚点同时耦合 `default` 与 `icon` 两字段，脆；应改成只锚 `"target": "mw_cluster"` 附近的最小唯一子串。

---

## 5. 偏差申报（与本单／常规不符之处，逐条，⛔ 沉默处理）

**P-1｜R2 §2.2 给的印记面判据在本面结构上不存在（要主理人订正口径，⛔ 我照做不到）**
§2.2 要「`done checked=N declared=N` 两数与改前相等」＋「`arsenal` 那行 `ok=true` 且 `slot1=liechi`」。实读 `_sigil_coverage_probe()`：每条判据走 `Dev.check()`，而 `scripts/dev_log.gd:29` **只在条件不成立时 `err()`**，成立则静默；收尾只打 `[SMOKE-SIGIL-COV] done`（无分母）。⇒ 绿态既没有 `checked/declared` 两数，也**根本没有 `arsenal` 那行**（`ok=true` 行不存在）。
改用的三条真在盘上可观测判据（已写进 `_tools/spr40_sigil.sh` 头注与 METRICS 字段）：①`[SMOKE-SIGIL] contract enter: eq='arsenal'` 在场且次数不变（证明分支真跑到）；②`[ERR]`／`SCRIPT ERROR` 恒 0（`Dev.check` 一失败就打 `[ERR] sigil_cov: arsenal slot1=…`，所以「0」是真判据、不是空话）；③`[SMOKE-P] … weapon=<id>` 面真身——改前恒 `shotgun`（实测 24 条）、改后必须恒 `liechi` 且旧 id 归零。反向自证照做且加码，见 §6。

**P-2｜V-W1 的「空池回退」判据不可测 ⇒ 改判据 ＋ 独立可达性证明（要主理人在实稿 §8 订正）**
原口径要断言「`DROP_POOL` 全被 gate 锁住时 `random_unlocked()` 回退起始武器」。实测该分支**在盘上不可达**：`weapons.gd:343-354 random_unlocked()` 先 `ids = 可用池`、仅 `ids.is_empty()` 才 `return "zhushan"`，而 `meta.gd UNLOCKS` 里 `kind=="weapon"` 只有 `mw_swarm/mw_arc/mw_cluster` 三条（`target` 全是 `mw_*`，没有一个落在 DROP_POOL 三把上）⇒ `Meta.gate_of("weapon", id)` 恒 `""` ⇒ `content_available` 恒真 ⇒ 池恒满。零 Godot 证明件 `_tools/spr40_b_m5b.out`：`M5b-PROOF 空池回退分支在盘上不可达：3/3 把无 gate ⇒ content_available 恒真 ⇒ 池恒满.`（并列出 `random_unlocked()` 的全部调用点）。
⇒ M5b 属**写法级条款**（AGENTS／核验 §1.2「写法即语义」同源），正解是源级断言＋反证＋登记刀，⛔ 运行期面。处置：探针/比对器/自证件三件同批改口径（改后 `VW1-GREEN`、`VW1-SELFTEST-GREEN 三臂全按期望`），把「空池回退可达性=不可达」作为**事实**打印而不是当判据骗自己。⛔ 我改实稿（归属在主理人）。

**P-3｜B0 快照第 8 行的标签误标（归档件⛔ 回改，只此申报）**
`SPR40_B0_DEFS快照.txt` 打的是 `[B0-SNAP] 未解锁空池 random_unlocked()=launcher`，读起来像「空池回退抓到了」。**它不是**：改前 `DROP_POOL=["shotgun","railgun","launcher"]` 三把同样无 gate（同 P-2 的证明），池恒满，那行只是**满池随机抽取的一次结果**。探针里那句话的字面标签在 `_tools/spr40_defs_snapshot.gd:25`。快照的**数值内容全部可用**（V-W1 就是拿它当基线），错的只是那一行的命名。

**P-4｜B 组落地窗按定义以 `RUN-RED` 收尾；转正走的是窗外（⚠️ 并更正我自己早前的一条不实印象）**
`_tools/spr40_b_apply_run.log` 原文：`=== run 起跑 22:07:37 cmd=bash _tools/spr40_b_apply.sh ===` → `PREFLIGHT ok 可以开跑（无并发、基线合身、锁不存在）` → `RUN-RED 收尾 player.gd=5835d2e6e9e89d3a6dd4155bcadc0b19 ≠ 绿基线=733a4b3c524219c237441d53e3ebc9b2` → `RUN 锁已释放 pid=36708`。
- 这笔 RED 是链的**结构性质**：收尾闸要求「盘上 `player.gd` == 现役绿基线」，而 M4a/M4b/M5c/M6b 正在改 `player.gd`，落地窗必然撞上它。我没有为转绿去动收尾闸，也没有在窗内刷基线。
- 转正只能在**窗外**用 `_tools/spr40_promote_good.sh` 做（它只写 `_tools/*.bak`，⛔ 碰 `scripts/`）：原因是 preflight 在「绿基线 md5 ≠ 盘上 `player.gd`」时**拒绝抢锁**，不先转正就开不了下一个窗。转正自证：`promote_5835d2e6.txt` ＋ 同窗 `RUN 归档闸 … |ARCHIVE-GATE GREEN … 归档=5 份|`。
- ⚠️ 更正：我早前的内部笔记里写过「22:0x 那次 B1 快照/门控没走锁（并发纪律偏差）」。**现读日志证明该说法不成立**（上面那四行），故本件**不申报**这笔偏差；记下更正痕迹，⛔ 把未经核实的自我指控写进交付件。

**P-5｜文档面 `issues=5`（比 C 轮的 4 多一条）＋ R2 §3.2 要的归因订正（我撤回一条早前说法）**
命令原文（`_tools/spr38_run.sh:161`）：`SPR38_AUDIT_IN_CHAIN=1 python _tools/spr38_report_selfaudit.py >"$OUT.docaudit.txt" 2>&1`。本轮原始输出尾段逐字：

```
冻结 自算 OK=21 FAILED=13 缺文件=0
基线 绿件=5835d2e6e9e89d3a6dd4155bcadc0b19 盘上=5835d2e6e9e89d3a6dd4155bcadc0b19 相等=True
AUTORUN_值守报告.md 绿件 md5 出现=6 次 ｜ 其它 32 位十六进制串=['df57d7dd4a86ef10b1e09a1f9e049d68']
spr38_fp_vs_5_4.py rc=0 含ALL_MATCH=True
spr38_baseline_verbatim_check.py rc=1 含VERBATIM_MATCH=False
spr38_oracle_quota_check.py rc=0 含IN_SYNC=True
FAIL 冻结实测 21 OK/13 FAILED/缺0 != 24/10/0
FAIL 绿基线或盘上件 != dc622351a75e8da9d943d72332ec2a28（刀没还原／基线过期）
FAIL AUTORUN_值守报告.md 冻结声称抽到 8 处，登记表 7 处（多 1 处）⇒ …
FAIL SPR38_交付_B1_非弹幕近战内核.md 冻结声称抽到 5 处，登记表 4 处（多 1 处）⇒ …
FAIL _tools/spr38_baseline_verbatim_check.py 非绿（rc=1）
SELF-AUDIT RED checks_run=27 issues=5 docs=2
```

⇒ 按 R2 §3.2 认账：**「改 `GOOD_MD5` 会新增两条 md5 FAIL」这个前提没有证据支持，我撤回**。实测里 `绿件 md5` 声称计数没有产生 FAIL，第②条（盘上≠`dc622351`）始终在；多出来的第 5 条是 `chk_verbatim` 非绿（＝§2 那笔连带红），属 B 换 id 的合法后果。⛔ 我改自审脚本硬编码、⛔ 我动 `GOOD_MD5`、⛔ 我回改归档 S38 件——三条都挂在登记轮。

⚠️ **订正这条红的宿主文件名**（我早前写成「S38 交付件」）：`_tools/spr38_baseline_verbatim_check.py:10` 的 `DOC` 现读＝`production/sprint-38/SPR38_主理人核验_B1.md`，旧 id 只在该文件 **:92** 一行（`"rifle", "shotgun", "railgun", "launcher", "mw_swarm", "mw_arc", "mw_cluster",`）。⇒ 要收这条红只能改**主理人自己的核验件**，编程侧⛔ 代改的边界比「归档交付件」更硬。满帧重跑的逐字取证（§5 P-13 的归档件）：

```
code_src=game_main.gd
code_hits=27 doc_hits=27 expect=27
FAIL 非逐字/非顺序相等
  first_diff code=zhushan doc=rifle
  only_code=['fushe', 'guanglei', 'liechi', 'zhushan'] only_doc=['launcher', 'railgun', 'rifle', 'shotgun']
VERDICT=SEE_ABOVE
```
数量三边都是 27（⛔ 站点丢失／多写），差的只有**那四个位置的 id 文本**——这条红的形状本身就是「实现已换、核验件未换」的最小证明。

**P-6｜冻结普查 22/12 → 21/13（`menu.gd` 因乙-3 离开冻结集）**
差分只此一件：`menu.gd ae20204f70d966be4b0f91714ae92d24 → 0ddd65f5a372e71c0e2f8d8f2ba3780f`。属 R2 §1.1 乙案明令要改的点（旧图标键的唯一 UI 消费者，不改则主菜单按钮 `Assets.g()` 返回 null ⇒ 屏上白框零报错，AGENTS §4.3）。整串 24/10 → 23/11 → 22/12 → **21/13** 的四轮差分请主理人一并登记。

**P-7｜我自己的量具里查出四处纪律级 bug（都在取数件，不在判据语义）**
①`_tools/spr40_sigil.sh:63` 把 `$TAG` 写成 `$tag`，`set -u` 下当场 `unbound variable` 打死一条已经跑绿的面（证据：metrics 文件已写全，判据行没打出来）；②反向自证件 `bail` 文案里的反引号＝命令替换，打出 `[ERR]: command not found` 污染证据；③`grep '^ERR_sigil_cov='` 恒不命中——METRICS 是**一行七字段**、行首是 `seed=`，加 `^` 就永远走 else（假红）；④`liechi=[1-9]` 少写 `[0-9]*`，凡计数是两位数就恒不命中（本轮 ④ 步的假红即此，实测 `liechi=21`／`22`）。四处都是**同行替换、⛔ 改判据语义**，且都在动判据前先用磁盘上已有的 metrics 文件离线复算过一遍。

**P-8｜`CHURN-DONE red=0` 与「机检件全等」不是同一件事**（口径卫生，见 §3 的 🔴 注）——`spr40_churn.sh` 的 `chk_*` 段不计 RED。本轮两者恰好分叉（churn 报红=0，`chk_verbatim` 漂移）。后续任何引用 churn 的交付件⛔ 只贴 `red=`。

**P-9｜B 打破了两处刀表锚点，其中一处是**会永久撒谎的自证行**（要主理人点逐字施工单，⛔ 我自行改刀表）**
静态普查（§4.2）实测，`_tools/spr36_knives.py` 里乙-7 未覆盖的旧 id 字面量还剩 4 行：
- `:47`／`:48`＝**N4** 的锚点与注入串，都写死 `["shotgun", "railgun", "launcher"]` ⇒ 现盘命中 0，这把刀落不下去（`knife()` 会 loud 报 `INCOMPLETE 锚点命中 0 次`，⛔ 假绿，但「定向掉落退回随机池」那条门从此没有反证）。
- `:296`＝main() 末尾**残留自证表**里的同一旧串 ⇒ 从 B 起这一行**恒打印「残留！」**。这是四处里最危险的：它把「十把刀都还原干净」的收尾自证变成永久噪声，下一轮很容易有人为了去掉这条噪声去**改判据**（禁止事项 #8 的形状）。
- `:99`＝**N14** 的注入串（`"rifle": "prism_warden"`）——锚点仍命中 1、刀能落，但它模拟的「非专武漏进 Boss 房子集」现在拿一个 DEFS 里不存在的 key 去模拟；语义等价物应是起始武器 `zhushan`（`rifle` 的原身份），⛔ 我自行决定，建议归主理人。
- 请主理人按**乙-7 的先例**出施工单（三处都是「锚点跟随实现」，⛔ 改判据语义、⛔ 改期望话）；我建议的逐字串：`:47`/`:296` → `const DROP_POOL := ["liechi", "guanglei", "fushe"]`，`:48` → 同串尾加 `, "bw_half_beat"`，`:99` → `\t"zhushan": "prism_warden",\n`。
- ⚠️ 同批还查出**与 B 无关**的一处：`:124` 的 **P4** 锚点 `\t_probe_stance_shot()` 在盘上有 2 个调用点（`player.gd:698` 弹幕侧、`:747` 近战侧），改前树同数 ⇒ **P4 在 B 之前就是死锚**。`_tools/sp_logs/` 无 `spr36_P4_*` 残留件，⛔ 我能断定它哪一轮变哑。修法同 S41「K5 锚点解耦」一族：把锚点换成带各自行尾注释的长串，或拆成 P4a／P4b 两把各打一个调用点。

**P-10｜`CHURN-DONE blind_faces=无` 这句在本口径下说过头了（要主理人订正 churn 件的结论文案）**
`_tools/spr40_b_churn_numbered.py` 实测：十面里**只有 melee（94 条）与 sc（19 条）存在 `] #NN … ok=` 形状的行**，其余八面是 0 条。⇒ 「只比断言行」对那八面退化成「只比叙述行 ＋ 结论行没红」，把它写成「无盲区」会让下一轮把 `red=0` 读成「十面判据逐字可比」。本件按 §3.2 的三档口径重算并申报；⛔ 我改 `spr40_churn.sh` 的结论文案（那是判据件）。

**P-11｜stance 结论行里两条未归因的新形状（既不当回归报，也不当无关抖动吞）**
- `闩锁未结算`（`player.gd:633` 的 `1 if _sp_pending else 0`）：改前三份归档（`spr40_after`／`spr40_c_after`／S38 期）全为 **1**，本批两个独立 B 窗（落地窗 84 发、收官窗 83 发）全为 **0**。
- `blocks(idle/walk)`：历史全为对称值（42/42、55/55、56/56），本批收官窗首次出现 **87/85**（落地窗仍对称 85/85）。
两处都⛔ 进任何 `Dev.check`（`_sp_pending` 只打印；idle/walk 只比「和 > 0」，:616），所以判据面没红。样本 3 对 2，我不推因果，⛔ 请主理人据此判「要不要给 `_sp_pending` 收尾态立一条判据」——若立，P4／K5 那两条锚点卫生问题正好同轮一起修。

**P-12｜主理人 11-18 消息 §3 给的冻结重登三值，在本仓任何树上都复现不出来（阻塞登记轮第 3 步）**
消息里写的是 `data.gd 63573022…`／`validate.gd 4a999c98…`／`weapons.gd 0888615a…`，并点名⛔ 用 `150f0a6a`（R19-Q 期）／`21379c8e`／`0e7e805a`（M1~M8 未落盘态）。盘上现读与直接戳：

```
scripts/data.gd     87ddf3a35c5c771b63b39079869eaaed   ←= _tools/spr40_b/after.md5（B 落地窗当场盖的直接戳，同值）
scripts/validate.gd fe9d84ecdbc9c9c63205fe81d94bbc6f   ←= 同上
scripts/weapons.gd  c07867231a42097196e3e5693528a3f2   ←= 同上
改前戳 _backup/spr40_b/before.md5：data.gd 9aab58fd…（＝C 组件记的「本批未动·同值」）
```

- 全仓 grep 六个前缀——含主理人点名⛔ 用的那三个——**0 命中**（含 `_backup/`、所有 `.md`/`.txt` 归档）；
- 穷举 54 个候选（`现盘 / _backup/spr40_b / _backup/spr38_final` × `原样 / CRLF / LF / 去尾换行 / tab→4 空格 / CRLF 去尾`）：**无一命中** ⇒ 不是行尾、尾换行或缩进口径差异，也不是「未落盘态」这种陈旧解释；
- 我这三值内部自洽：`data.gd` 现盘相对改前备份只有 M7（`:217` `"开局副手预装裂髓杵"`）与 M8（`:455` `"…再补一发。"`）两处文案变化。
⇒ 请主理人复算一次，或点名取用上面三值。**登记轮第 3 步（重登 `SPR21-FROZEN.md5`）在哈希对上之前不能走**；⛔ 编程侧代刷冻结串（红线 #8）本来就是我的禁止项——这里申报的是「值对不上」这个事实，不是「我该不该写」。

**P-13｜施工单第 5 项（我读作「跑满态归因 `equip_calls=34`」）：三件事——证据件曾被同路径覆盖（现已独立归档）、我早前引用的那个数在本仓根本不存在、而这个数在机制上与帧数无关**
- `_tools/spr38_gates.sh` 的产物名是**固定的**（`_tools/spr38_g_<face>.log`、`_tools/spr38_g_chk_quota.txt`…）。我在 22:4x 跑的那次满帧门控**没有单独归档**，随后 22:53 的 `STEP=all` 收官跑把这些同名件就地覆盖了 ⇒ 盘上只剩最后一跑：`_tools/spr38_g_chk_quota.txt`（mtime 22:58）`hits: oracle_block=1 equip_calls=34 defs_block=1 ｜ VERDICT=IN_SYNC`。
- 我早前把那次满帧跑的口算结论说成「`checked=48 declared=48`、48=48=48 自洽」。现查：全仓 grep `declared=48` **0 命中**，`_tools/spr40_b_knife.log` **不存在**（我把它和 `_tools/spr40_b/w3_knife.log` 混了）。⇒ ⛔ 这两个数（文件与 48）我⛔ 再引用，主理人 §施工单第 5 项与判断栏回复里跟着用的那份引用同源，请一并订正。
- 补齐**已做完**（本件落盘前最后一个独占窗，`STEP=run`，23:26:36 起跑，归档到独立目录 `_tools/spr40_b/qa3200/`，链尾 `_tools/spr40_b/qa3200_audit.log`）：
  - 链判定：`RUN 收尾 player.gd == 绿基线 5835d2e6…` ＋ `RUN 归档闸 … ARCHIVE-GATE GREEN 归档=5 份` ＋ `RUN 工具面 … SELFTEST GREEN states=9`，末行 `RUN-RED 文档面 spr38_report_selfaudit rc=1`（＝P-5/P-6 那五条已知红，主理人已裁⛔ 阻塞）。`STEP=run` 按定义只出 **RUN-PARTIAL**，本件⛔ 拿它当收官证据（V-H #14）。
  - 七面逐字（同一次跑，`--quit-after 3200`）：`base/melee/stance/apply/rng/sc/pw` **全部** `ERR=0 okfalse=0 SCRIPT_ERROR=0 validate problems=0`；`done` 行全仓只有三种：`checked=94 declared=94`（melee）／`checked=7 declared=7`（stance）／`checked=19 declared=19`（sc）。
  - 🔴 对第 5 项的直接结论：`grep -a -rho "done checked=[0-9]* declared=[0-9]*" _tools/spr40_b/qa3200/*.log | sort -u` **只返回上面三行** ⇒ 满帧归档里 `declared=48` 同样 **0 命中**：我那个「48」不是被覆盖丢的，是**根本不存在的数**，P-13 第 2 条的订正成立（不是取证缺口）。
  - 三件机检：`chk_fp rc=0 VERDICT=ALL_MATCH hit=1`、`chk_quota rc=0 VERDICT=IN_SYNC hit=1 | hits: oracle_block=1 equip_calls=34 defs_block=1`（与 22:11 那跑**同数**，跨窗可复现）、`chk_verbatim rc=1`（＝P-5 那条，逐字见 P-5 的块）、`chk_taut rc=0 合计 应解析=568 实解析=568 可疑(T1+T2+T3)=0`；另 `C-a′ GREEN：文档 §三 加总=94；日志普查=94；探针 declared=94`、`VH10 ok |done checked=94 declared=94 swings_total=57 draws_total=57|`、冻结 `21 OK / 13 FAILED`（＝P-6 第三次独立复现）。
  - 三档指纹 `fp12345/fp777/fp42` 各自 `ERR=0 okfalse=0 SCRIPT_ERROR=0`，逐字比对经 `chk_fp=ALL_MATCH` 收口。
- ⚠️ 顺带订正一处我自己搞混的量具口径（现读源码，`_tools/spr38_gates.sh:11-14`／`:22`、`_tools/spr38_knife.sh:6/:13`）：**`QA=` 是十刀件的旋钮（默认 1600 物理帧），gates 根本不读它**——gates 的 `run()` 把 `--quit-after 3200` 写死在命令行里，帧数从 S38 起就恒是满帧 ⇒ 「1600 帧版 vs 3200 帧版」这个二分法⛔ 适用于 `chk_quota`，我早前把它标成「1600 帧版」是错的（更根本的错见下条：它与帧数毫无关系）。
- 还有一处更要紧的：`spr38_oracle_quota_check.py` **是零 Godot 的纯源码静态件**（读 `game_main.gd`＋`weapons.gd`，正则抽 `for i in N`／`_ml_equip(id, quota)`／`DEFS[id].mag`）⇒ `equip_calls=34` 是**源码里 `_ml_equip(...)` 的站点计数**，与跑多少帧**无关**，任何 `--quit-after` 都改不动它。施工单第 5 项若要的是「用满帧跑证明 34」，那这条**在机制上无法被上机证明**——静态件已经把它钉死了；跑 3200 帧真正能多拿的只有各面的 `done checked=NN declared=NN` 与 `swings/draws` 计数。请主理人确认第 5 项要的是哪个数，我按确认后的口径补件（⛔ 我自择一个数报成已完成）。
- 这条同时是一处**量具卫生**问题（与 S41 的 P7 归档闸同族）：gates 类件若无窗内归档，同窗多跑必然互覆，下一轮只能拿到最后一跑。⛔ 我自改 `spr38_gates.sh` 的产物路径约定（改法要主理人点单）。

---

## 6. 印记契约反向自证的原始输出（`_tools/spr40_b/sigilrev_chain3.log`，独占窗 22:51:52）

跑法（R2 §2.2 ＋ AGENTS §8.2 碰锁唯一入口）：`RUN_CMD='bash _tools/spr40_sigil_reverse.sh' bash _tools/spr38_run.sh run`。

```
=== ① 改后绿跑（M6 已落 liechi、M6b 已比 liechi）===
SG-OK tag=falsify_a enter=1 cov_done=1 weapon: liechi=21 zhushan=0
=== ② 只打破注入方（M6 退回旧 id，M6b 仍比 liechi）===
FALSE-BROKEN(shotgun) game_main.md5 b934f7dd -> 5b7beb33（M6 退回 shotgun，M6b 仍比 liechi）
SIGIL-REV ② 咬住了：first_err=[ERR] sigil_cov: arsenal slot1=shotgun
seed=12345 enter_arsenal=1 cov_done=1 ERR_sigil_cov=1 ERR_all=3 SCRIPT_ERROR=11236 lines=52
weapon: shotgun=27 liechi=0 rifle=0 zhushan=0
FALSE-RESTORED 逐字节还原 ok md5=b934f7dd332c60374776aa9c240ca4e2
=== ②b 换成「合法但错」的 id 再破一次（排除「红是崩出来的」这种假证）===
FALSE-BROKEN(guanglei) game_main.md5 b934f7dd -> c43877ec（M6 退回 guanglei，M6b 仍比 liechi）
SIGIL-REV ②b 纯红：first_err=[ERR] sigil_cov: arsenal slot1=guanglei
seed=12345 enter_arsenal=1 cov_done=1 ERR_sigil_cov=1 ERR_all=1 SCRIPT_ERROR=0 lines=46
weapon: shotgun=0 liechi=0 rifle=0 zhushan=0
=== ③ 逐字节还原 ===
FALSE-RESTORED 逐字节还原 ok md5=b934f7dd332c60374776aa9c240ca4e2
=== ④ 复跑确认回到绿基线（判据字段逐字相同；体量计数只报数不判）===
SG-OK tag=falsify_c enter=1 cov_done=1 weapon: liechi=22 zhushan=0
SIGIL-REV-GREEN seed=12345 五步全过：①绿 ②破旧 id 咬住 ②b 破合法错 id 纯红(SCRIPT_ERROR=0) ③逐字节还原 ④判据字段与①逐字相同
```

链尾：`run exit=0` → `RUN 收尾 player.gd == 绿基线 5835d2e6e9e89d3a6dd4155bcadc0b19` → `ARCHIVE-GATE GREEN 归档=5 份` → `RUN 工具面 … SELFTEST GREEN states=9` → `RUN-RED 文档面 spr38_report_selfaudit rc=1`（＝§5 P-5/P-6 的登记轮红，⛔ 我抹） → `RUN 锁已释放`。

🔴 为什么 ② 之后还要 ②b（本件加的一条臂，R2 没要求）：退回**旧 id** `shotgun` 时 `DEFS` 里已无此键，下游崩出 `SCRIPT_ERROR=11236`，那种「红」分不清是 M6b 咬住还是空字典撞崩的。换 `guanglei`（合法 id、错的内容）后 `SCRIPT_ERROR=0` 而 `[ERR] sigil_cov=1` ⇒ **那条断言自己有牙**，纯红。另：② 那一步的 `weapon: shotgun=27` 说明旧 id 一旦回到注入方，面上立刻复现——M6 与 M6b 是同一契约两端，缺一即恒 `ok=false`。

⚠️ 证据体量提醒：`_tools/spr40_sigil/sigil_falsify_broken.log`（② 那跑）约 5 MB，全是 11 236 条崩溃噪声，正是 ②b 存在的原因；跨轮引用请取 `.metrics.txt`（134~187 字节）而不是原日志。

---

## 7. 裁定回账（R2 §5 六项）

**① §1.3 EXEMPT-1 豁免令原文（照抄）**

> **主理人豁免令（S40-B / EXEMPT-1）**：实施单 §6 禁止事项 #4「⛔ 修改 `meta.gd` 的 `UNLOCKS`」，就 `scripts/meta.gd:71` 的字符串字面量 `"wpn_launcher"` → `"wpn_fushe"` **这一次替换予以豁免**。
> ⛔ 覆盖：`kind`／`target`／`cost`／`requires`／`default`／`max`／`name`／`desc` 任一字段；⛔ 覆盖：节点增删、顺序调整、其它任何 UNLOCKS 节点的任何字节。

豁免范围自证（现盘 vs 备份逐字节 diff，仅一行）：

```
71c71
<               "icon": "wpn_launcher", "max": 1,
>               "icon": "wpn_fushe", "max": 1,
差异行数=2（即同一行的改前/改后两行，⛔ 其它字节）
```

**② §2.2 施工句（照抄）**

> **M6b｜`scripts/player.gd:1190`（SMOKE_SIGIL_COVERAGE 探针 · `_sigil_coverage_probe()` 的 `"arsenal"` 分支）**
> 现文本：`				ok = weapon_slots[1] == "shotgun"`
> 改为：　　`				ok = weapon_slots[1] == "liechi"`
> 约束：①同行替换，⛔ 增删行、⛔ 缩进改动；②紧邻下行 `detail = "slot1=%s" % weapon_slots[1]` **一字不动**（它是消息格式串，改了会污染 `[SMOKE-SIGIL]` 面比对基线）；③⛔ 顺带把该 match 块其它分支的文案或判据「优化」一遍；④M6 与 M6b 必须**同批**，缺一则该分支恒 `ok=false`（假失败，非漏测）。

门控句（照抄，实跑见 §6）：

> ```
> SMOKE=1 SMOKE_SEED=<与改前同一个整数> SMOKE_SIGIL_COVERAGE=1 \
>   godot --headless --path "D:/Create/Game/test-1" --quit-after 3200
> ```

指针现读（`grep -n`，与 §2.2 给的行号**逐号相同**，本批没有行号漂移）：M6b＝`player.gd:1190`，M6 注入＝`game_main.gd:2802`（§2.2 反向自证点名的正是这一行），`META_WEAPON_POOL_BASELINE`＝`game_main.gd:42`（声明）／`:2488`（唯一消费点）。

执行差异：`SMOKE_SEED` 钉 `12345`（与 §1 改前印记面同值）；判据按 §5 P-1 换成三条真可观测项；反向自证做了且多一条纯红臂；`player.gd` 该 match 块其它分支一字未动（`weapons.gd` 侧 M5a 文案改动属 M5 明令，不是「优化」）。

**③ §1.4 K5 同步说明** → 见 §4 K5 专项（含我把「K5 已死」订正为「K5 是活刀」的自纠）。
**④ §3.2 归因订正** → 见 §5 P-5（撤回不实前提，贴命令原文与输出尾段）。
**⑤ §3.3 md5 粘贴** → 链释放后单独原样粘给主理人（本件不落盘，避免与链内 `after.md5` 两处漂移）。
**⑥ §169 四条 ⛔ 遵守** → `GOOD_MD5` 仍 `dc622351…`（`spr38_report_selfaudit.py:28` 现读）；`spr34_*` 三件 mtime 仍是 `11-17`；旧 4 枚 PNG 在盘 mtime `11-07 22:28`；`SPR21-FROZEN.md5` 一字节未动。

**⑦ 主理人 11-18 核验消息（C 组收官确认 ＋ B 落地顺序 ＋ 六项施工单）回账**

- **GOOD_MD5 口径冲突的裁定已收到并执行**：以**更新的那份（R2）为准** ⇒ 本轮⛔ 动 `GOOD_MD5`（现盘仍 `dc622351…`）。B 转正后**一轮原子做完**的四件事我这边全部备料齐了：`GOOD_MD5`→`5835d2e6e9e89d3a6dd4155bcadc0b19`、`FROZEN_SITES`→`8`（站点数已是 8，见 §7-②）、两张声称表各 +1 行（`值守报告` 8/8、`B1 交付件` 5/5）、引用位宿主＝**本件**（`5835d2e6` 在本件出现次数见 §9 末行实测）。⛔ 拆轮、⛔ 编程侧代做（禁止事项 #11 明令⛔ 动 `AUTORUN_值守报告.md`，含⛔ 追加）。
- ⚠️ **一处归因仍两说，我两边都摆出来**：主理人 §2 说改 `GOOD_MD5` 会让 `dc622351` 变成「登记表里没有的哈希」⇒ 触发**两条** md5 FAIL（`DOCS = [值守报告, B1 交付件]` 都还写着它）；而我 B 窗实测的原始输出（§5 P-5 那条块）里**没有任何 md5 FAIL**，第 5 条是 `FAIL _tools/spr38_baseline_verbatim_check.py 非绿（rc=1）`。差别在于我这轮跑的是 **`GOOD_MD5` 未改（＝dc622351）** 的状态，主理人那句是**改后**状态的机制预测 ⇒ 两者不矛盾，但**「改后到底出几条」这件事我盘上没有实测件**。要我在登记轮开工前用临时改值跑一次并留件，说一声即可（跑完逐字节还原，同 §5 P-5 的做法）。
- **落地顺序 ①→⑤ 全部按序完成**：①V-W1 探针与比对器改口径（§5 P-2）→ ②B1 快照 `SPR40_B1_DEFS快照_迁移后.txt` → ③M1~M11＋M6b＋乙-1~乙-7 原子迁移（§0）→ ④`5835d2e6` 转正进现役绿基线（§5 P-4，`ARCHIVE-GATE GREEN 归档=5 份`）→ ⑤`STEP=all` 收官链 ＋ 印记面 `SMOKE_SIGIL_COVERAGE=1` ＋ M6 反向自证（§6）。六项施工单里 1/2/3/4 已落（逐字串已转录进 §0.1 与本节），第 6 项（`rc=1` 不阻塞收官）按裁定原样执行。
- 🔴 **第 5 项（我读作「用跑满态证明 `equip_calls=34`」）我不能报成已完成**：见 §5 P-13 —— 我早前口头引用的 `checked=48 declared=48` 与 `_tools/spr40_b_knife.log` 在**本仓不可复现**（全仓 grep `declared=48` 0 命中、该文件不存在），而 3200 帧那跑的归档件被同路径的收官跑覆盖了。盘上现在能查的是最后一跑留下的：`_tools/spr38_g_chk_quota.txt`（22:58）`hits: oracle_block=1 equip_calls=34 defs_block=1 ｜ VERDICT=IN_SYNC` ＋ `_tools/spr40_b/gates.txt`（22:11）同数。补齐办法＝重跑并归档到独立目录（**已做完**：23:26 独占窗，`STEP=run`，归档 `_tools/spr40_b/qa3200/`，逐字实测见 §5 P-13 的补齐块）。⚠️ 但见 §5 P-13 末两条：`equip_calls` 出自**零 Godot 静态件**，与帧数无关 ⇒ 若第 5 项要的确实是这个数，它无法用「跑满态」证明，请主理人确认要的数。

---

## 8. 禁止事项 #1~#14 逐条自查（S40 实施单 §6）

| # | 条款 | 自查结论 |
|---|---|---|
| 1 | ⛔ 改与本单无关的行 | 9 个文件的改动逐处可追到 §0.1 的 33 条锚点；行行数 9/9 守恒（§0.2），无插行/删行 |
| 2 | ⛔ 新增/修改 `ACTION_DEFS`（18 条） | 未动。正证：`assets.gd` 改前/改后**只有 110 行**变（乙-1 `GEN_NAMES` 四键），而 `ACTION_DEFS := {` 在 `assets.gd:341`、块闭合在 `:361` ⇒ 本批对该常量零接触（同文件改一行最容易蹭到的红线，特意比对行号段） |
| 3 | ⛔ 触 `bullet.gd setup()` 第 8 参位 | `bullet.gd` 未动（`95370e21` 同值） |
| 4 | ⛔ 改 `meta.gd UNLOCKS` | 仅 `meta.gd:71` 一个 token，靠 R2 §1.3 EXEMPT-1；范围自证见 §7-① |
| 5 | ⛔ 换 `shardbearer.png` | 未动：`resources/texture/shardbearer.png` 在盘 mtime `11-15 18:50`（本批只**新增** 4 枚 `resources/texture/generated/wpn_*`） |
| 6 | ⛔ 新计时用 raw `delta`／`time_scale`／`create_timer` | 本批不新增任何计时（纯 id/文案迁移） |
| 7 | ⛔ 破坏「每次有效挥击恒 1 次 `randf()`」 | `swings_total=57 draws_total=57` 恒等未变（§2 ③／VH10 行） |
| 8 | ⛔ 自改断言或冻结串让门转绿（含 `META_WEAPON_POOL_BASELINE`） | M11 那串是**逐字转录主理人核验件 §3.1**，非自定；`GOOD_MD5`／`FROZEN_SITES`／`SPR21-FROZEN.md5` 一字节未动；文档面与 verbatim 两条红如实挂着（§5 P-5/P-6） |
| 9 | ⛔ 新增持久状态不申报 | 本批零新增 `static var`／存档字段；三档指纹逐字节相同为反证（§3） |
| 10 | ⛔ 蹭既有 trigger | 未涉及（清扫/盾反属 A/C 组） |
| 11 | ⛔ 动 `AUTORUN_值守报告.md`／`AUTORUN_LEDGER.md`（含⛔ 追加） | 未打开、未追加。盘上 mtime：`AUTORUN_LEDGER.md`／`AUTORUN_ATTRIBUTION.jsonl` 22:06、`值守报告` 20:20——`_tools/spr38_run.sh` 内 `AUTORUN` 引用 **0 处**，可证不是链写的，属外部值守进程；我未参与 |
| 12 | ⛔ 动 `D:\大纲` | 一字节未动 |
| 13 | ⛔ 未获 D2 答复前执行 B1~B11 | 作者判断栏已裁「认＋id 一起换（走冻结重登）」⇒ 冻结重登为授权条件，本件 §5 P-6 即该笔账 |
| 14 | ⛔ 交付件省略改前基线（HP-0） | §1 完整给（含 B0 快照与改前印记面） |

补充红线自查：⛔ 取管道尾码当链退出码（退出码一律先落变量再判）；⛔ 并发开跑／手工碰锁；⛔ 编辑正在被 Godot 读的 `scripts/*.gd`（所有 `.gd` 改动都在窗内）；⛔ 拿过期 `.bak` 当绿基线（转正件先按内容哈希归档再比）；⛔ 编程侧代改 AGENTS 文字（X4）。

---

## 9. 不等点头的下一步（编程侧自裁顺序）与本批停等项

已在本件内自裁完成：反向自证五步、V-W1 三件同批改口径、`STEP=all` 收官链、churn 两口径分档（§3.2）、刀表锚点静态普查（§4.2，落盘前又复跑一次逐字相同）、施工单第 5 项的独立归档窗（§5 P-13）、交付件落盘。

顺序（⛔ 等点头）：
1. ✅ **施工单第 5 项的独立归档件已落**：`RUN_CMD='bash _tools/spr38_gates.sh _tools/spr40_b/qa3200' bash _tools/spr38_run.sh run`（23:26:36 独占窗，RUN-PARTIAL）——七面全 `ERR=0/okfalse=0/SCRIPT_ERROR=0/problems=0`、`checked=94|7|19` 三种、`equip_calls=34 IN_SYNC`、`ALL_MATCH`、`568/568 可疑=0`、冻结 `21/13` 已在 `_tools/spr40_b/qa3200/` 逐字归档（读数见 §5 P-13）。剩下的只有主理人确认「第 5 项要的数」＝`equip_calls`（静态、与帧数无关）还是 `done checked=` 那三条。
2. 把 `md5sum scripts/*.gd` 原样粘主理人（R2 §5 第 5 条／§3.3），随附**五项**要主理人处置的口径/施工单：§5 P-1（印记面判据句）、P-2（V-W1 空池回退＝M5b 写法级）、P-9（刀表 3 处旧 id 锚点＋1 条永久假红自证行，乙-7 先例）、P-12（冻结重登三值不可复现）、P-13（`declared=48`／`spr40_b_knife.log` 不可复现的订正）。
3. 主理人登记轮（唯一能收 §5 P-5/P-6 那五条文档面红的工序）：`GOOD_MD5`→`5835d2e6` ＋ `SPR21-FROZEN.md5` 全文重登（先解决 P-12）＋ 两张声称表各 +1 行 ＋ `FROZEN_SITES` 处数复算改表。⛔ 编程侧代做（R2 §3.3 写死归属，禁止事项 #11/#8）。
4. 登记轮之后重跑一次 `STEP=all`，取一条真 `RUN-GREEN` 作为 B 组收官门控的终态证据（本轮链末那笔 `RUN-RED 文档面 rc=1` 按主理人裁定不阻塞，但真绿要等登记轮）。
5. V-W2：28 行含「枪/弹/炮/膛」的文案清单（`migrate.apply.txt:17-44` 已逐字留档）——D4 集束榴弹／D5 全局语汇属作者保留域②，⛔ 我自定词。
6. S41 待办（本批⛔ 做）：P7 归档闸修复（主 `.bak` 被就地覆盖那笔）、K5 锚点解耦 `default`＋`icon`、**P4 锚点去歧义**（§4.2）、gates 产物路径归档约定（§5 P-13）、十刀族补写死 EXPECT 红号表（§4.1 末条）、`_sp_pending` 收尾态要不要立判据（§5 P-11）。

停等项（⛔ 编程侧自裁）：
- 冻结串／`GOOD_MD5`／文档声称的登记轮——归属主理人＋作者保留④，本件只交实测与不可复现证据。
- 数值口径本身（含是否给四把新武器调 `dmg/interval`）——作者保留域②；本批是**纯同值搬运**，任何后续数值改动都要单独一轮。
- §9.3 美术硬指标（四枚新图标是否够格当正式件）——作者保留域⑤；现状态＝「生图过关、`wpn_fushe` 由 `_w` 预览转正」。

**本件对自身引用位的实测**（供登记轮第 4 件事直接用，⛔ 手填）：取数命令 `grep -o '<绿基线全串>' production/sprint-40/SPR40_交付_B组.md | wc -l` ⇒ 全串 **7** 次（落在 6 行；本句自身⛔ 含全串，所以数它⛔ 受本句影响），文档面「宿主至少 1 次收尾 md5 引用」的形状要求已满足。
