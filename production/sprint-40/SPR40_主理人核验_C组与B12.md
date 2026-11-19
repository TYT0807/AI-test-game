# SPR40 主理人核验 · C 组结构层 + ①~④ 裁定 + P7 归档缺陷

批次：Sprint 40（C 组 / B 组收尾件）
日期：2026-11-18
核验对象：编程侧 2026-11-18 交付汇报（`SMOKE_PARRY` 探针面、七把变异刀、B12 图标对照、冻结基线待登）
配套盘上证据（本会话现场自读，⛔ 引用编程侧转述）：
- `_tools/spr40_parry/spr40_pd_parry.lines.txt` / `spr40_pd_parry2.lines.txt`（双跑面，md5 相同 = `daceddbceb4e2d0a5390aa95561dc347`，`cmp` 逐字相同）
- `_tools/spr40_parry_knives/p1.log ~ p7.log`（红号集合与 EXPECT 表逐一对齐）
- `_tools/spr38_run.docaudit.txt`（文档审计 RED 明细）
- `_tools/_artgen/preview_spr40_wpn/{wpn_zhushan, wpn_liechi, wpn_guanglei, wpn_fushe, wpn_fushe_w}.png`（五枚 32×16 RGBA8，IHDR 全 `(32,16,8,6)`）
- `scripts/player.gd` / `slug.gd` / `boss.gd` / `bullet.gd` / `game_main.gd` / `weapons.gd` / `assets.gd` / `game_state.gd`（本窗独占，直接 Read/grep）
- `production/sprint-21/SPR21-FROZEN.md5`（34 行，现场重算 OK=22 FAILED=12 缺 0）

---

## §0 结论先行

| # | 事项 | 裁定 |
|---|---|---|
| ① | p7「等效刀 → 源级断言」的处置 | **转正正册**，附三条件收紧（见 §1） |
| ② | C2 第 2/3 条按符号位单变量实现 | **确认＝我读的 C2**，不改判；补一条"若将来要更强口径要走新批"的护栏 |
| ③(a) | `META_WEAPON_POOL_BASELINE` 新串 | 逐字串在 §3.1（M1~M11 同批原子落地硬前置照旧） |
| ③(b) | `SPR21-FROZEN.md5` 重定 + `GOOD_MD5` 更新 | 登记口径在 §3.2；`GOOD_MD5` 新值 = `733a4b3c524219c237441d53e3ebc9b2`（现算已核），由**你转录**、我在下一轮核验里复算 |
| ③(顺带) | `FROZEN_SITES` 站点数不符（7→8、4→5） | **既有态、非本轮造成**——编程侧如实报不抹平的做法对；处置走 §3.3 |
| ④ | B12 武器图标 `fushe` 甲/乙 + `zhushan` 笔锋 | **乙案**（用 `wpn_fushe_w`），§3.1 该行改词见 §4.1；`wpn_zhushan` 第三版**通过**，无需改词 |
| 🔴 P7 | 归档覆盖事故（`.bak` 被 733a 原地覆盖） | **归档闸未生效，需 S41 立项修复**，详见 §5 |

放行判定：**C 组结构层可进交付件九节落盘**（前提：先处置 §5 归档事故）。B12 图标乙案可入正式槽（仍等 M1~M11 迁移那一批一起动，⛔ 单独搬 PNG）。

---

## §1 ①：p7 处置转正为正册口径

### 1.1 事实（本会话坐实）

- `scripts/game_state.gd:22 const FIXED_DT := 1.0 / 60.0`
- `project.godot` 无 `physics/common/max_fps` 覆盖 ⇒ 引擎物理 tick = 60Hz
- ⇒ **数值恒等**：`delta == Game.FIXED_DT` 在本项目所有运行期场景下成立
- p7 首轮实测红条数 = 0（空咬）符合预期：行为面无法区分二者
- 编程侧改在 `game_main.gd` P8 尾部加了一条源码级断言 #65，用 `_ml_src_segment("res://scripts/slug.gd", "func _physics_process(delta: float)")` 取段后要求 `_stun_t = maxf(0.0, _stun_t - Game.FIXED_DT)` **字面在场且恰一次**（`measured=1 expect=1 ok=true`）；p7 打桩改成 `- delta` 后 #65 实测红（`ok=false`）——**牙口真咬**。

### 1.2 转正（三条件同时满足才允许用源级断言替代行为面）

今后凡遇"红线是**写法**而非**行为**"的条款（典型：FIXED_DT 类等价常数、单一真源函数复用、禁用某 API 名），按下列三条走：

1. **必要性证明**：写一段 ≤3 行的说明，指出为何行为面分不开（例：本项目两值恒等／该写法差异只在编译期可见／违反后果不在运行时出现）。写在断言紧邻上方注释或探针设计稿里，⛔ 只放在刀脚本的 `DESC[]` 里。
2. **反证配套**：源级断言必须配一条**段本体反证**（长度 > 阈值 ∧ 一个必然在场的 token），防止段取空退化成"空串==空串"的恒真比较。#65 已合规（`expect=1` 就是"恰一次"计数，不是布尔在场）。
3. **刀面互证**：至少有一把变异刀专打这条源级断言（如 p7），且 EXPECT 表里明确登记它咬哪一号（`[p7]="65"`）。没有刀面的源级断言视同"未验证的口头规矩"，不进正册。

### 1.3 ⛔ 再为这类红线编行为面

**明确指令**：编程侧今后遇到 FIXED_DT 类"运行期不可观测"的红线，⛔ 试图摆出某种时序去"演示差别"。那种演示要么是自证式的循环论证（我用什么手段让 delta ≠ FIXED_DT？只有改 project 设置——那是全局变更，不是探针），要么就是把等价关系藏起来假装能分。**直接写源级断言 + 上面三条件**。

### 1.4 请在交付件里明写的一段话（原样转录即可）

> 「`_stun_t` 的递减系数走 `Game.FIXED_DT` 还是 `delta` 在本项目**运行期不可观测**（`const FIXED_DT := 1.0/60.0`，`project.godot` 无 `max_fps` 覆盖 ⇒ 引擎物理 tick 也是 60Hz）。⇒ 该红线只能靠源码级断言保证（P8 #65），⛔ 用行为面冒充抓到它。这是弹幕交互红线体系里第一条『写法即语义』型条款，未来同类（等价常数、单一真源、禁用 API）按主理人核验 §1.2 三条件走。」

---

## §2 ②：C2 符号位单变量的确认

### 2.1 我的原文（裁定件 §1-C2 逐字）

> 1. 每颗敌弹各自结算：命中瞬间查 RAISE/PARRY/BLOCK（优先级照弹幕实稿 §3.2 步骤 3，环盾豁免在最前）。
> 2. 成功盾反后设 `PARRY_HIT_CD := 6` 物理帧（0.10s）——CD 内的后续弹走 **BLOCK**（有 RAISE 就硬格减伤），CD 外走正常受伤。
> 3. BLOCK 同样吃这颗 CD：一次成功处理后的 6 帧内不再进入第二次 BLOCK 结算（防「八向环一次性把伤害 ×BLOCK_MULT 连乘八次＝变相全免」）。
> 4. 分类计数逐颗各记各的。

### 2.2 你的实现（`scripts/player.gd`）

```
var _parry_hit_cd := 0     # >0 刚盾反 / <0 刚硬格 / 0 空闲；向零递减
_settle_parry → _parry_hit_cd = PARRY_HIT_CD       (=+6)
_settle_block → _parry_hit_cd = -PARRY_HIT_CD      (=-6)
_update_shield_scan 分流：
  if _parry_hit_cd > 0: _settle_block(b)   # 刚盾反 6 拍内后续弹走 BLOCK（第 2 条）
  elif _parry_hit_cd < 0: continue         # 刚硬格 6 拍内不再进 BLOCK 结算（第 3 条）
  elif _parry_frames_left > 0: _settle_parry(b)
  else: _settle_block(b)
```

### 2.3 逐字对齐

- 第 2 条："盾反后 6 帧内后续弹走 BLOCK" ⇔ `_parry_hit_cd > 0` 分支 ⇒ `_settle_block(b)` ✅
- 第 3 条："一次成功处理后（含 BLOCK）的 6 帧内不再进入第二次 BLOCK 结算" ⇔ `_settle_hit_cd < 0` 分支 ⇒ `continue`（正常受伤，不进 BLOCK）✅
- 第 4 条：`parry_count` / `block_count` 各记各的，P4 #34/#35 实测各 +1 ✅
- "同一颗⛔ 二次结算"（我从 G10 推的隐含约束）：queue_free 保证 ✅

**结论：符号位单变量＝我读的 C2，不改判。**

### 2.4 关于"更强的口径"的护栏

你没问但我预判作者会问的一种读法："一次窗口总共只结算 2 次、且第二次⛔ 与第一次同 kind"。当前实现**允许**"盾反→硬格→盾反→硬格…"交替到帧数耗尽为止（理论上 12 拍完美窗 + 0.90s 架式 ≈ 66 拍里最多 22 次交替）。这不是 bug，是我裁定的"节奏性吃到"的本意——如果嫌太宽，改的是 `PARRY_FRAMES` 或 `PARRY_HIT_CD` 这两个数（都是纯常数、回滚一行），⛔ 借改口径偷偷塞新机制。

🔴 **登记**：若将来作者要求"每窗口最多 N 次"这种**总量闸**（而非节奏闸），那是新批次新裁定（牵动第二个计数器、可能还要个 kind 集），⛔ 顺手实现。请编程侧在交付件 §禁止事项 那栏原样抄一句"总量闸未裁"。

---

## §3 ③：冻结串与基线的逐字转录

### 3.1 (a) `META_WEAPON_POOL_BASELINE` 新串（逐字，替换 `scripts/game_main.gd:42-51` 整块）

```gdscript
const META_WEAPON_POOL_BASELINE := [
	# S36 T-B1 的 14 把 Boss 专武（无 gate 节点＝默认可用，W3=A 的本意）
	"bw_prism_latch", "bw_seam_light", "bw_core_hammer", "bw_sixfold_ring", "bw_quiet_gauge",
	"bw_tide_gauge", "bw_clinkant_fang", "bw_slack_half", "bw_cinder_rake", "bw_red_dial",
	"bw_abyss_ledger", "bw_half_beat", "bw_black_silt", "bw_third_key",
	# S38 B1 的 6 把非弹幕族（DEFS 有条目、零获取途径：HP-6 靠 DROP_POOL 守，不靠这一路）
	"ml_cleaver", "ml_needler", "sp_thorn", "sh_bulwark", "th_kunai", "wd_whisper",
	# 基础法器四件套（S40-B 去火药枪化：rifle→zhushan / shotgun→liechi / railgun→guanglei / launcher→fushe）＋弹道三连＋mw_*（T-A 之后 default:true）
	"zhushan", "liechi", "guanglei", "fushe", "mw_swarm", "mw_arc", "mw_cluster",
]
```

要点：
- 集合规模 27 不变（14 + 6 + 7）；四个旧 id 顶替为新 id，其余 23 个逐字不动
- 注释句从「初始三件套＋弹道三连」改为「基础法器四件套…＋弹道三连」（M11 后半句）
- **执行序**（🔴 硬前置 HP-A）：M1~M11 必须**同一批原子落地**——只改本串不改 DEFS ⇒ MG-PW1 立刻红（extra=[zhushan…] missing=[rifle…]）；只改 DEFS 不改本串 ⇒ 同样红；只改数据不改 M9 `assets.gd GEN_NAMES` ⇒ 屏上白框**零报错**（AGENTS §4.3 老坑）
- 落地后请把 MG-PW1 的 `missing/extra` 实测原样交回，我在下一轮核验里逐 id 核对并**正式登记本次重定**（凭此件即视同登记，收官时我在 `SPR40_主理人核验.md` 里回写一行"已登记"）

### 3.2 (b) `SPR21-FROZEN.md5` 与 `GOOD_MD5`

**现场重算结果**（本会话 python 直读磁盘，逐行比对 34 条）：
- OK = 22
- FAILED = 12（缺文件 0）
- 变脸清单（前 8 位）：
  ```
  assets.gd        c67525a0 → e0f2d2ac
  boss.gd          fb40c2fe → 0303ce20
  bullet.gd        aa687ff4 → 95370e21
  data.gd          b34ce072 → 9aab58fd
  game_main.gd     f8472ec2 → 5978d368
  game_state.gd    73c8a395 → 7d10f3d1
  meta.gd          a2b4b4a2 → 0bdf0e84
  player.gd        a1390a75 → 733a4b3c
  shrine_panel.gd  a3c19f9b → 49ab2fc7
  slug.gd          06fa0ebd → 341880b4
  validate.gd      fc2eca37 → 10eb44a5
  weapons.gd       c26d847b → 315e9283
  ```

**⚠️ 编号冲突预警**：你说"盘上 `game_main.gd` = `a505762e…`"，我这边算出来是 `5978d368…`。两种可能：
- 你把 `_PD_DECLARED` 那条常量或某条 P8 断言又挪过一次位置（我们中间有一次锁空档）
- 或者读取时机不同（我读到的是你最新一版，你贴的是上一版）

⛔ 你我手工对齐——正确做法是：**你在下一次链跑完后当场 `md5sum scripts/*.gd > /tmp/on-disk.txt`，把这份原样粘给我，我据此生成新 `SPR21-FROZEN.md5` 全文**，然后你一次性 `cp` 覆盖。谁也不许凭记忆写 hash。

**`GOOD_MD5` 更新**（`_tools/spr38_report_selfaudit.py:28`）：
- 现值：`"dc622351a75e8da9d943d72332ec2a28"`（已腐，A 组之前的老绿基线）
- 新值：`"733a4b3c524219c237441d53e3ebc9b2"`（本会话实测：`scripts/player.gd` 与 `_tools/spr38_good_player.bak` md5 相等）
- 你直接 Edit 那一行即可，改完跑一次 selfaudit 应看到 `FAIL 绿基线或盘上件 != dc622351…` 那条消失。

### 3.3 (顺带) `FROZEN_SITES` 站点数不符的处置

现状：登记表 `{"AUTORUN_值守报告.md": 7, "SPR38_交付_B1_非弹幕近战内核.md": 4}`；文档审计抽到盘上分别是 8 和 5。

你的判断对：`git status` 显示这两份文件本轮⛔ 改动 ⇒ 属**既有态**（前序窗口加了声称位但没同步表）。**处置**：
1. 这**不是**你本轮造成的 RED，⛔ 你抹平。
2. 我在下一轮的独立核验里做两件事：(a) 现场 `grep -oE '\((\d+), (\d+)\)' <file>` 复算两份文档的实际声称位数；(b) 若确为 8/5，我把 `FROZEN_SITES` 改成 `{..., 8, ..., 5}` 并在提交信息里写明"A24-4 之后的第 X 处新增声称位来自 <具体段落>"。这一步归我，⛔ 你调表。
3. 若复算发现多出来的那处声称其实是**漏站的旧账**（比如 A24-4 那次改表时少算了一处），也一并修，同样在我这边。

---

## §4 ④：B12 武器图标的裁定

### 4.1 `fushe` 甲/乙 → **乙案**（`wpn_fushe_w`）

理由：
- §3.1 共同骨架那句「主体沿水平轴展开，占宽 ≥26px」是**跨四枚的一致律**，它的价值就在"HUD 上四把摆一排密度可比"。甲案给 `fushe` 单开豁免，等于把这条律降级成"三枚参考"——下一轮再加一把又要豁免一次。
- 器型层面：符匣本来就是"匣 + 托柄"的手持法器（民俗里"匣"绝大多数带托，装符、装卦板、装印信都这样），加一根漆托柄⛔ 引入新语义、⛔ 撞他作专名，只是把"右侧一块方"变成"横着一件物"。
- 视觉层面：`fushe` 现在的 bbox 15×12（高 12 已经比另外三枚高一大截），加托柄后 28×12 —— **横向密度追平、纵向仍是四枚最高**，反而强化了"这把不一样"的辨识度。opaque 130→164 也在合理范围（`liechi` 96、`guanglei` 64 是低密端，`fushe` 走高密端符合"匣体本身有厚度感"）。

**§3.1 该行改词（我这就改设计稿）**：原句
> 右侧一个方形匣体（约 9×10，带 1px 边框、内部 2 格分隔，读作多宝格）；左上角探出 2 张错开的符纸（各 2×5，略微旋转的阶梯状摆放，纸面点 1 个墨点当符文）；匣底 1px 亮边暗示烫金。⛔ 画成圆形弹鼓（那还是榴弹）。

改为：
> 右侧一个方形匣体（约 9×10，带 1px 边框、内部 2 格分隔，读作多宝格）；左上角探出 2 张错开的符纸（各 2×5，略微旋转的阶梯状摆放，纸面点 1 个墨点当符文）；匣底 1px 亮边暗示烫金；**匣体左延一段 20px 长、2px 厚的漆托柄（横贯 y=7..9，末端略收），使整件器物沿水平轴铺满 ≥26px 与另三把同量级**。⛔ 画成圆形弹鼓（那还是榴弹）。

（这一段我自己 Edit 到 `SPR40_设计实稿_武器族去火药枪化.md` §3.1 表格里那一行——那是我的正典文件，⛔ 你动。）

### 4.2 `zhushan` 笔锋 → **第三版通过，无需改词**

我看放大对照图（ASCII 复现过一遍）：细杆 cols 2..23（2px 厚）、cols 24..25 一格亮笔箍、cols 26..29 四格高的朱砂毫紧贴右端、cols 30..31 收到两格尖。**"最宽段紧贴最右端、收尖只往右收"** 这条规矩把你前两版的两个坑（钉子头 / 旗杆飘小旗）都避开了。在 32×16 这个尺寸上，这就是"笔"能给出的最强剪影信号——再往"更软更散"的方向画就会糊成一坨。

**结论**：`wpn_zhushan` 保持第三版，⛔ 你再迭代，⛔ 我改词。若作者在最终 HUD 截图上看仍说"读不出笔"，那是**上下文问题**（旁边三把都是硬器），解法是给 HUD 加中文 name 标签而不是继续磨像素——那时候再来找我裁。

### 4.3 其余两枚（`liechi` / `guanglei`）

- `liechi` 26×8、`guanglei` 27×6：均达骨架线 ✅；`guanglei` 的"尺身 + 每 4px 一格刻线 + 右下穗子"三个特征都在，与 `zhushan`（无刻线、无穗）的剪影差足够。
- 最小像素差 101（zhushan vs guanglei）≥ 下限 48 ✅。

### 4.4 归档与推进

- 五枚 PNG 现在在 `_tools/_artgen/preview_spr40_wpn/`（预览目录）——**保留原样**，作为"为什么选 w 版 fushe"的证据。
- 正式版落 `resources/texture/generated/wpn_{zhushan,liechi,guanglei,fushe}.png` 与 `assets.gd GEN_NAMES` 的换键（M9）**必须与 M1~M11 同批**（同 §3.1 硬前置 HP-A）。⛔ 单独搬 PNG。
- 旧 4 枚 `wpn_{rifle,shotgun,railgun,launcher}.png` 按 §4.2 明令：从 `GEN_NAMES` 移除后**文件留在盘上**，⛔ 删、⛔ 覆盖。

---

## §5 🔴 P7 归档覆盖事故（本会话独立发现，须 S41 立项修复）

### 5.1 现象

`_tools/spr38_good_player.bak`（spr38_run.sh 归档闸认的"现役绿基线配套归档"）现在的内容是 `733a4b3c…`（= 当前 `player.gd`）。而 `dc622351…`（A 组之前那版绿基线）**没有任何 `.bak` 文件保存**。上一次链跑的 `RUN 归档闸 GREEN 归档=4 份` 里的"4 份"是：
```
_tools/spr38_good_player.2364e3b1.bak
_tools/spr38_good_player.4f907fbb.bak
_tools/spr38_good_player.733a4b3c.bak
_tools/spr38_good_player.dc622351.bak
```
—— 其中 `dc622351.bak` 存在，但**主 `.bak`（不带 hash 后缀那份）已被 733a 覆盖**。

### 5.2 根因（读代码定位）

`spr38_run.sh:129` 的收尾自证：
```bash
G=$(md5sum _tools/spr38_good_player.bak | cut -d' ' -f1)
D=$(md5sum scripts/player.gd | cut -d' ' -f1)
[ "$G" = "$D" ] || { echo "RUN-RED 收尾 player.gd=$D ≠ 绿基线=$G"; exit 2; }
```
它拿 `.bak` 当"权威基线"和盘上比。问题是：**promote 流程（`spr40_promote_good.sh` 或类似件）在把新绿基线归档时会同步覆盖主 `.bak`**——一旦覆盖发生，下一次链跑的比较基准就是"新盘上"，`.bak` 里的历史 dc62 版本丢失（虽然 hash-suffixed 归档还在，但链自己的守卫不看它们）。

叠加：`GOOD_MD5 = "dc622351…"` 在 `spr38_report_selfaudit.py:28` 里还指着旧值 ⇒ 文档审计那条 `FAIL 绿基线或盘上件 != dc622351…` 就是这个漂移的显形。**两处指向同一个事故**：promote 走了、`GOOD_MD5` 没跟着改、`.bak` 也被就地覆盖了。

### 5.3 影响评估

- **好消息**：`dc622351.bak` 那份 hash-suffixed 归档**内容完整**（`_tools/spr38_good_player.dc622351.bak` 存在），历史没真丢。
- **坏消息**：链自己的归档闸只看主 `.bak` ⇒ 它现在认"733a 就是绿基线"，这在**当下是对的**（733a 确实是当前唯一正确基线），但它意味着**这道闸在过去某一刻静默地把旧基线吞了**——如果那次 promote 是有问题的（比如忘了跑某个门控），链不会报警。
- **不影响本轮 C 组交付件的合法性**：733a 是本轮实测跑出来的、经独立双跑 cmp 逐字相同的、经七把刀全咬的、经文档审计除已知两条 RED 外全绿的基线。它本身可信。

### 5.4 处置（三步，均在 S41 立项范围内，编程侧本轮⛔ 动）

1. **本轮**：仅按 §3.2 更新 `GOOD_MD5` 到 733a，让文档审计那条 RED 消掉。⛔ 别碰 `.bak` 系列文件。
2. **S41 立项修复**：改 `spr38_run.sh` 归档闸——把"主 `.bak` 单文件比对"改成"遍历所有 `spr38_good_player.<hash>.bak` 归档，只要盘上有任一归档与之字节相同即 GREEN"。这样 promote 时无论是否覆盖主 `.bak`，历史归档都能自证。
3. **S41 立项修复**：`spr40_promote_good.sh`（或对应件）在覆盖主 `.bak` 前先 `mv` 一份带旧 hash 后缀的归档（幂等），确保"覆盖动作本身产生归档"。

我在 S41 实施单里会把这两条写成硬任务，届时给你逐字施工口径。本轮你只需在 C 组交付件 §遗留问题 那栏原样抄一句"P7 归档闸覆盖事故，见主理人核验 §5，S41 修复"。

---

## §6 独立核验清单（本会话完成项）

| 项 | 你自报 | 我实测 | 结论 |
|---|---|---|---|
| 面行数 | 72 | 72（base0 + 70 + done） | ✅ |
| checked/declared | 70/70 | 70/70 | ✅ |
| `[ERR]=0` / `ok=false=0` / `SCRIPT ERROR=0` | 全 0 | 全 0 | ✅ |
| 双跑 cmp 逐字相同 | 是 | md5 `daceddbc…` 两遍相同 | ✅ |
| 分组划分（P1~P9） | 10/7/11/7/5/5/6/14/5 | 面文本逐条对齐 | ✅ |
| p1 咬 #09 #10 | ✓ | `p1.log` 实测红号 = [#09 #10] | ✅ |
| p2 咬 #14~#17 | ✓ | `p2.log` = [#14 #15 #16 #17] | ✅ |
| p3 咬 #36 #37 | ✓ | `p3.log` = [#36 #37] | ✅ |
| p4 咬 #31 #32 #33 #35 | ✓ | `p4.log` = [#31 #32 #33 #35] | ✅ |
| p5 咬 #58 | ✓ | `p5.log` = [#58] | ✅ |
| p6 咬 #27 #28 | ✓ | `p6.log` = [#27 #28] | ✅ |
| p7 咬 #65（源级） | ✓ | `p7.log` = [#65]（`measured=0 expect=1 ok=false`） | ✅ |
| `is_sweepable()` 单一真源复用 | ✓ | `player.gd:851` 直引 `b.is_sweepable()`，`bullet.gd:52` 定义恰一处 | ✅ |
| 盾扫描源序（fire 之后、bomb 之前） | ✓ | `player.gd:393→394→398→399` anim/fire/shield/bomb | ✅ |
| boss 免疫 stun（空实现） | ✓ | `boss.gd:331 apply_stun(_dur): return` | ✅ |
| `_knock` 四处全覆盖 | ✓ | `slug.gd:152/177` 晕分支双覆盖（X5 提醒到位） | ✅ |
| 冻结 OK/FAILED | 22/12 | 22/12（现场 python 重算） | ✅ 一致 |
| 归档闸 GREEN 归档=4 份 | ✓ | 4 份 hash-suffixed 归档在盘 | ⚠ 见 §5（主 `.bak` 被覆盖） |
| `wpn_*` 五枚 IHDR | 32×16 RGBA8 | 五枚 IHDR 全 `(32,16,8,6,0,0,0)` | ✅ |
| `wpn_fushe` bbox 15×12 | ✓ | ASCII 复现一致 | ✅ |
| `wpn_fushe_w` 加托柄 bbox 28 | ✓ | ASCII 复现 cols 8..28 有 2px 厚横条 | ✅ |

---

## §7 你现在可以做的（顺序）

1. 落 `production/sprint-40/SPR40_交付_C组.md`（按 A 组那份九节结构），把 §1.4 那段话原样抄进去，把 §2.4 那句"总量闸未裁"抄进禁止事项栏，把 §5.4 那句"P7 归档闸覆盖事故，见主理人核验 §5，S41 修复"抄进遗留问题栏。
2. 按 §3.1 逐字替换 `META_WEAPON_POOL_BASELINE`——**必须在 M1~M11 同批原子落地里做**，⛔ 单独改串。
3. 按 §3.2 更新 `GOOD_MD5 = "733a4b3c524219c237441d53e3ebc9b2"`。改完跑一次 selfaudit 应看到那条 RED 消掉。
4. 下一次链跑完后 `md5sum scripts/*.gd` 原样粘给我，我据此生成新 `SPR21-FROZEN.md5` 全文（§3.2 末尾）。
5. 图标：按 §4.1 用 `wpn_fushe_w` 转正，其余三枚不动；正式 PNG 落到 `resources/texture/generated/` 与 `assets.gd GEN_NAMES` 换键**必须与 M1~M11 同批**。
6. §3.3 FROZEN_SITES 站点数不符 → 你什么都不做，等我下轮复算改表。

## §8 停等你回报的

- 并行两件（`spr40_b0.sh` DEFS 快照、A 组两条小修）不阻塞本轮 C 组交付件落盘，你自己按 A 组那次的节奏推进就行。
- 数值终值（`BLOCK_MULT`/`RETURN_MULT`/`STUN_*` 四个数）作者保留域②——交付件里如实标"占位、待作者点头后单次替换"，⛔ 你我都替作者点头。
