# SPR41 实施单 · 编程侧

批次：Sprint 41
日期：2026-11-19
配套：`SPR41_设计实稿_手感与玩法层增量.md`（机制口径唯一真源）、`SPR41_验证口径.md`（不看代码就能判对错的条款）
🔴 **本单分两半，界线就是「作者有没有答」**：

- **§A 零裁定车（现在就能跑完）**：只建笼子、只加可观测性，**不改任何玩家可感行为**。含 §A 三件。
- **§B~§E 停等车（⛔ 未获 E1~E6 答复前一律不动）**：返还表、余韵乘区、贪手惩罚、两条改名。

一句话优先级：**先做 §A-1**（那条 rng 守恒断言必须在返还表落地**之前**存在于生产码里，否则等于让被测实现自己证明自己没错）。

---

## §0 开工前置（顺序不可换）

| # | 动作 | 判据 |
|---|------|------|
| P-1 | `git status` 确认工作树干净；确认 `production/sprint-40/` 那台登记轮／值守件不在跑（S40 R70 §D 的 s65b 换靶单车若同时在跑，**独占窗冲突按项目既有规程让路**，⛔ 并发写 `_tools/`） | 无未提交改动；`_tools/.spr38_run.lock` 无 owner |
| P-1b | 🔴 **文档行尾卫生**（我从 S41 这批自己踩到的坑，前置成规矩）：Windows 上写文档的工具会把 LF 变成 CRLF，而**md5 对行尾敏感、`wc -l` 不敏感** ⇒ 凡交付件落盘后须现场跑一次 `python3 -c "b=open(f,'rb').read();print(b.count(b'\r'), b.count(b'\n'))"`，CR 必须为 0；非 0 就用一次性 python 字节级 `replace(b'\r\n', b'\n')` 归一（⛔ `sed`/`dos2unix` 之外的"手工看一眼"）。另：⛔ 在任何文档正文里写「本件自身的 md5／行数」——那份现值会在下一次编辑当场腐烂（S40 R70 §J③ 已把这条立成常设口径）。 | 每份交付件 CR=0；正文零自指指纹 |
| P-2 | 现算一次改前基线：validate problems=0、五门、`SMOKE_PARRY`＋`SMOKE_SWEEP`＋`SMOKE_STANCE` 三条探针的 `done checked=N declared=N`、E1 指纹串 | 存 `_tools/spr41_baseline_pre.txt`（新文件，非 gitignored） |
| P-3 | 现场坐实本单引用的每一个锚点：`grep -n` 逐条复核实稿 §1 那张表的 H1~H15。**行号会腐烂，本单所有行号只是提示，落码依据是引句** | 任一引句在生产码里 `count != 1` ⇒ 停下呈报，⛔ 自行找"最像的那处"改 |

🔴 硬前置（三条，违反即整回车作废）：
1. ⛔ 在任何盾反路径引入 `Game.rng` 消费（视觉走确定性算术或 `Game.fx_rng`）。
2. ⛔ 修改 `Bullet.setup()` / `spawn_player_bullet()` / `spawn_enemy_bullet()` 的参数位；⛔ 给敌弹新增「类型」字段。
3. ⛔ 把本批任何新状态写进存档序列化面或 E1 指纹串（对齐实稿 §3.2④／§4.2／§6 的三处「非持久」声明）。

---

## §A 零裁定车（现在执行）

### A-1 盾反主流抽取守恒断言（🔴 本单最重要的一件）

**位置**：`scripts/game_main.gd` 的 `_smoke_parry_probe()`（现读 `:5791` 起），在 P 组末尾自校验（`Dev.check(_pd_checked == _PD_DECLARED …)`，现读 `:6195`）**之前**追加一段。

**要做的事**（逐字口径，⛔ 实现细节由你定，但四条必须都测到）：

```
新面 P-RNG（命名随你，注释标题写 `[SMOKE-PARRY] P-RNG`）：
  a) 记录 seed0 := Game.rng.seed, state0 := Game.rng.state
  b) 摆一颗普通敌弹入盾内 → _pd_open(pl, Player.PARRY_FRAMES) → pl._update_shield_scan()
     → 断言 seed/state 与 0 态逐字相等（这就是今天的现状，应当绿）
  c) 同一姿势连摆 3 颗（不同位置）各扫一拍 → 再断言逐字相等
  d) 走一次 BLOCK 分支（_parry_hit_cd = 0 且 _parry_frames_left = 0）→ 再断言逐字相等
  e) 把返还语义预留出来：若将来 _settle_parry 生成返还弹，本面须覆盖
     「PARRY 成功那一拍内 spawn_player_bullet 被调用后仍逐字相等」
```

**同步要改的两处数**（漏一处当场红，这是老坑）：
- `const _PD_DECLARED := 70`（现读 `game_main.gd:5769`）⇒ 改成循环展开后的**实数**（上面 a~e 我给的形状约 +9~+13 条，取决于你把 c 写成几个点位）。⛔ 猜数——实稿 §1 H15 那条纪律原文就是「`declared` 是循环展开后的实数」。
- 台账/文档面里凡引用 `checked=70` 的字样（`production/sprint-40/*` 已收官件 ⛔ 回改；S41 的新文档由我这边写，你只需在交付件里报**新实测值**）。

**必须跑的门控**：

```bash
SMOKE=1 SMOKE_SEED=12345 SMOKE_PARRY=1 \
  "D:/SteamLibrary/steamapps/common/Godot Engine/godot.windows.opt.tools.64.exe" \
  --headless --path "D:/Create/Game/test-1" --quit-after 3200 res://scene/game.tscn
```

🔴 `--quit-after 3200` 不是可选项：`SMOKE_SAVE` 那族探针在更早的帧序里跑不完，历史上吃过「帧数不足假绿」。
🔴 `SMOKE_SEED` 必钉：churn 对比不钉种子会产生上百行假差异。
🔴 `SMOKE_PARRY` 与 `SMOKE_SWEEP` **⛔ 同进程双跑**（`game_main.gd:291-296` 有现成的 `Dev.err("parry", "SMOKE_PARRY 与 SMOKE_SWEEP 同进程双跑…")` 守卫，别去绕它）。

**A-1 的自证（要求你出证，不是要求它绿）**：故意在 `_settle_parry()` 里插一行 `_ = Game.rng.randf()`，重跑，**必须变红**，然后精确还原（`difflib` 或字节快照比对，⛔ 手工"看起来一样"）。这一红一还原的证据要进交付件。

### A-2 档位输入 `k` 的可观测化（零行为变化）

**位置**：`scripts/player.gd` 的 `_update_shield_scan()`（`:836`）与 `_settle_parry(b: Node)`（`:868`）。

**要做的事**：把「本次 RAISE 内实际走了 PARRY 分支的颗数」变成 `_settle_parry` 能读到的入参或局部量。两种形状任选，⛔ 第三种（全局统计）：

```
甲案（推荐，改动最小）：在 _update_shield_scan() 的 for 循环外 var k_in_raise := 0，
                        每次进 _settle_parry 前 += 1，签名改 _settle_parry(b: Node, k: int)
乙案：在 _settle_parry 内部读一个已有的每拍累加器 —— ⛔ 目前没有，等于要新增持久字段，故否
```

🔴 约束：
- ⛔ 新增 `static var`／⛔ 新增存档字段／⛔ 改 `_parry_hit_cd` 的三态语义（实稿 H2/H3 那套优先级是本批的地基）。
- `k` 的定义**必须是「本批 PARRY 分支的实际计数」**，⛔ 用「同帧敌弹总数」代替——后者会把八向环撑成 8，一旦返还表落地就白嫖扇档（实稿 §3.1 第三条）。这一点请在函数上方写一条注释钉住，注释要能被 `grep -a` 取到（后续静态门靠句子取数）。
- 落地后 `_settle_parry` 的行为**一字不变**（还是四行：计数、置冷却、迸星、`queue_free`）。A-2 只是把参数递进去不用。⇒ 验收判据是**零 diff**：A-2 单独一趟跑完后，`[SMOKE-PARRY]` 全部行的 measured 应与 P-2 基线**逐字相同**（除新增面的行数）。这条"应该完全没变化"本身就是最好的防越界闸。

### A-3 锚句存活闸的形状统一（纯卫生，⛔ 动 S40 已收官件）

实稿 §9.3 那句话在本单的落地形式：S41 新写的**每一个**变异/伪造探针，起手对每个锚句做

```python
assert src.count(anchor) == 1, "ANCHOR-DEAD kind=%s count=%d" % (kind, src.count(anchor))
```

任一不等于 1 ⇒ 打印专属标记 `S41-ANCHOR-DEAD` 并非零退出。理由（写给未来的我们）：md5 靶管得住宿主字节，管不住锚句语义——S40 R70 §D-2 那次 X3/X4 就是这么静默失效的。⛔ 回头改 `s65b_*` 等已收官件（那要重开三元组与冻结，属另一辆车）。

---

## §B 盾反返还表（⛔ 停等 E1/E2）

**触发条件**：作者答 E1（`HEAVY_DMG_MIN`／`RETURN_MULT`／`RETURN_COUNT_CAP`）＋ E2（`STUN_PARRY_SHORT`／`GREED_MULT`）。

**位置**：`scripts/player.gd` `_settle_parry()`（`:868`）内部扩展；档位常数放 `player.gd` 常量块（紧邻现读 `:128-134` 的 `PARRY_FRAMES`／`PARRY_HIT_CD`／`BLOCK_MULT`，⛔ 散落两处）。

**逐字口径**（数值占位待 E1 回填，形状现在就定死）：

```gdscript
## 盾反档位（SPR41 实稿 §3.1）：判据只取 (本次RAISE内PARRY颗数 k, 来弹 dmg)，
## ⛔ 敌弹没有来源类型字段（game_main.spawn_enemy_bullet 只有 speed/dmg/tint），
##    档位输入一律取现读量，⛔ 为分档新增持久字段。
const HEAVY_DMG_MIN := <E1>      # 现读敌弹 dmg ∈ {1.0, 2.0}（slug.gd 三处调用）
const RETURN_MULT := <E1>        # 返还伤害倍率，⛔ 另造伤害常数——模板取 zhushan DEFS 现值
const RETURN_COUNT_CAP := <E1>   # 扇档一次最多吐几发
const STUN_PARRY_SHORT := <E2>   # 秒；消费点 round(STUN_PARRY_SHORT / Game.FIXED_DT)
```

结算体（顺序即判据，⛔ 换序）：

```
1. parry_count += 1                          # 保持现第一行
2. k := 传入的本次 RAISE 内 PARRY 颗数（A-2 铺的路）
3. 档位判定：G1/G2/G3（G4 环档本批不做，见实稿 §3.1）
4. 返还弹生成：对每颗返还
     dir   := -b.vel.normalized()
     pos   := b.global_position            # ⛔ 从玩家位置发射
     speed := float(<zhushan DEFS speed>)  # 250.0，⛔ 新常数
     dmg   := int(float(b.dmg) * RETURN_MULT * damage_mult * bullet_dmg_mult)
             # 取整口径照 _settle_block 的 int(float(raw)*BLOCK_MULT)，允许截断到 0，⛔ maxi(1,…)
     tint  := Color(1.0, 0.62, 0.25)       # zhushan DEFS 现值
     其余实参一律显式传默认值，crit=false, crit_boom=false
5. G3 档附加：对「来弹方向的命中目标」apply_stun(round(STUN_PARRY_SHORT/Game.FIXED_DT) 拍)
     ⛔ Boss：boss.gd:331 的 apply_stun 是空实现，那是设计而非缺陷，⛔ 去"修好"它
6. _parry_hit_cd = PARRY_HIT_CD             # 保持
7. _shield_spark(b)                          # 保持
8. b.queue_free()                            # 保持，⛔ 提前 free 导致第 4 步读不到 b 字段
```

🔴 禁止事项（B 组专属）：
- ⛔ 在第 4/5 步之后插入任何 `Game.rng.*`（A-1 的面会当场红，别指望 review 能看见）。
- ⛔ 让返还弹走 `_fire()`（那条路有 `randf_range(-1.5, 1.5)` 与 `randf() < crit_chance` 两次主流抽取，`player.gd:708/710`）。
- ⛔ 修改 `_update_shield_scan()` 的优先级链（`:841-861` 的五段式）；返还逻辑只在 `_settle_parry` 内部。
- ⛔ 用 `take_damage(0,…)` 表达免伤（`:867` 的原注释已在守这条）。

**门控**：`SMOKE_PARRY`（含 A-1 新面，须仍绿）＋ `SMOKE_SWEEP`（另一进程）＋ validate ＋ E1 指纹（`SMOKE_META_FINGERPRINT=1`，⛔ 记成 `SMOKE_META`）＋ churn（钉种子）。
🔴 预期结果分两说，⛔ 混：
- **E1 指纹**：返还弹是运行期产物，不进 meta 串 ⇒ 应**逐字不漂移**。若漂了，说明有人把它写进了存档/图鉴面，立刻回滚并呈报。
- **churn 断言行**：会出现新的 `[SMOKE-PARRY]` 行 ⇒ 属预期增量，按「只比断言行」口径核，⛔ 拿全日志行数当判据。

---

## §C 贪手惩罚（⛔ 停等 E2）

**位置**：`scripts/player.gd` `_settle_block(b: Node)`（`:876`）。
**做法**：只加一个分支，零新状态——

```
现读第 4 步之后的形态：if _parry_hit_cd > 0 走的就是 BLOCK（刚盾反成功后又挨一发）
⇒ 在该分支里把 after 乘 GREED_MULT，并 parry_greed_count += 1（static var，与 :114-121 同族，
   注释须写明 ⛔ 进存档 ⛔ 进 E1 指纹串，判据一律记差值）
⛔ 改动 shield_absorbed_dmg 的记账口径（实稿 §3.3 第二条：账面上自己跟自己打架）
```

🔴 边界态必测（写进探针，不是写在文档里就算）：同一次 RAISE 内 `PARRY → BLOCK → PARRY` 序列**不可能出现**（因为 `_parry_hit_cd>0` 期间一律 BLOCK，直到冷却走完）。这条断言红了就说明 C2 的三态被我理解错了 ⇒ 停下呈报，⛔ 自行改冷却语义。

---

## §D 刃风余韵（⛔ 停等 E3）

**位置**：`scripts/player.gd` `_swing()` 清扫段尾（`:799-800` 之后）＋ `_fire()` 散布处（`:706-709`）。

```
新增实例级 var _sweep_flow_t := 0.0        # ⛔ static ⛔ 存档 ⛔ 指纹
_swing(): if swept >= SWEEP_FLOW_MIN: _sweep_flow_t = SWEEP_FLOW_T
_physics_process(): _sweep_flow_t 递减走 FIXED_DT（⛔ raw delta ⛔ Engine.time_scale ⛔ create_timer()）
_fire():  if n == 1 and not autopilot:
             offset_deg += Game.rng.randf_range(-1.5, 1.5) * (0.0 if _sweep_flow_t > 0.0 else 1.0)
             # 🔴 抽取次数一字不变（仍是那一次 randf_range），只缩取值范围
             # 🔴 消耗点：本次开火后置 _sweep_flow_t = 0.0（一次开火即消耗）
```

🔴 三条反向断言（比正向更重要）：
1. **余韵不吃近战**（实稿 §4.2 第二条的落地形状）：有余韵时（`_sweep_flow_t > 0`）用 `ml_cleaver`／`sh_bulwark` 各挥一刀，`_ml_stats()` 那套乘区读数（`game_main.gd:4856` 返回的 `dmg_mult`/`bdmg`/…）与无余韵时**逐字相等**；并且 `_swing()` 内 ⛔ 出现任何对 `_sweep_flow_t` 的读或写。⇒ 生效点**只在 `_fire()` 的散布那一行**，别顺手在 `_swing()` 里"也消耗一下"（那会变成近战也能消耗 buff 的第二套账）。
2. `_sweep_flow_t` 跨房间残留 ⇒ 必须为 false（切房时清零，清零点与既有 `_stance_t`/过房复位同处，⛔ 另起第三处复位）。
3. 余韵期间 `Game.rng` 消费次数与不余韵时**逐字相等**（这是 §0 硬前置 1 的近亲，A-1 的形状可直接扩一条 D-RNG 面）。

**HUD 侧**（`scripts/hud.gd`，现读 `flash_toast(text: String)` 在 `:688`）：扫落瞬间显示「刃风扫落 N」，N 取 `Player.last_sweep_count`，0.6s 内消失。
🔴 位置/字号/颜色/时长＝**E6 未裁** ⇒ 本批 ⛔ 落 HUD 改动，只做「计数器可读」这一半（`last_sweep_count` 已经在位，H6）。等 E6 一起走。

---

## §E 两条改名的文案包（⛔ 停等 E4；先把逐字包备着）

**位置**：`scripts/weapons.gd` 的 `th_kunai`（现读 `:252-259`）与 `wd_whisper`（`:260-268`）两块 DEFS 的 `"name"` / `"desc"` 两个键值；以及 tips／图鉴里引用这两条名字的行（现算：`grep -rn "三枚锥\|低语法杖" --include=*.gd --include=*.md --include=*.json .`，⛔ 凭记忆列清单）。

**逐字包（乙案，甲案已在实稿 §5.2 自我否决——「离手即回」没有对应实现）**：

| id | 现值 | 改为 |
|---|---|---|
| `th_kunai` | `"name": "三枚锥", "desc": "慢手近掷"` | `"name": "泥尾签", "desc": "一枚签子，掷出不回头"` |
| `wd_whisper` | `"name": "低语法杖", "desc": "两枚低语追踪"` | `"name": "低语签", "desc": "两枚签子自己找缝钻"` |

🔴 自查过的三点（请你也各自复算一遍再落）：
- `th_kunai` 的 `count` 是 **1**（`:255`），所以现名「三枚锥」本身就与机制错位——这也是我否掉「三枚」字样、并把 desc 改成「一枚签子」的原因。⚠️ 这条属于「发现既有文案与机制不符」，落地前请呈报确认是否连带更正（不是我能替你定的口径变更）。
- `wd_whisper` 的 `count` 是 **2** ＋ `homing: true`（`:263/266`）⇒「两枚」「自己找」两句都成立，可放心改。
- ⛔ 动 `kind`／⛔ 动六个弹道参位／⛔ 动 `icon`（图集零变更，避开 §9.3 硬指标）。
- ⛔ 再跑一次 M1~M12 那种全仓词表替换（S40 已收官 28 行）。

**门控**：改名会进掉落/图鉴相关的字符串面 ⇒ 必须跑 `SMOKE_META_FINGERPRINT=1` 比对 E1 指纹是否漂移。🔴 若漂：这不是"改坏了"，而是**武器名本来就在指纹串里**，属作者保留决策权④（冻结重定），停下呈报，⛔ 自行接受新指纹。

---

## §F 交付件要求（每件都要带实测数，⛔ 自报结论代替数据）

1. `production/sprint-41/SPR41_编程侧交付_A组.md`：九节结构沿用 S40 惯例，必含
   - A-1 的**一红一还原**证据（故意插 `Game.rng.randf()` 的完整 stdout 片段 ＋ 还原后的字节比对结论）；
   - `_PD_DECLARED` 旧值→新值的**实数**（不是"+9"这种推算）；
   - A-2 的零 diff 证明（`[SMOKE-PARRY]` 存量行的 measured 与 P-2 基线逐字对照结果，列出比对了几行、差了几行）；
   - 五门 + E1 指纹 + churn 的原始尾部行（粘贴，⛔ 转述）。
2. 台账追加行（S40 用的是 `production/sprint-40/_tools/s40_m4_F_register.md` 那套；S41 请新建 `production/sprint-41/S41_台账.md`，append-only，⛔ 回改历史行）。
3. 📱 证据卫生（我从 S40 R69/R70 学到的两条，这里前置成规矩）：
   - 失败态的 stdout **追加**保存，⛔ 原地覆盖（V-1 首跑空转那份被覆盖掉，只剩叙述）；
   - 临时件删除前先在台账里点名删了什么、留下哪几段（沙箱与 /tmp 那次）。

---

## §G 全局禁止事项（本批通用）

1. ⛔ 改 `scripts/*.gd` 之外的冻结面时跳过现算 md5；34 个 `.gd` 全冻结，改前改后都要快照。
2. ⛔ 碰 `D:\大纲`（那是小说工程，有自己的铁律与台账，我是外人）。
3. ⛔ `git commit`／`git push`／刷 `production/sprint-21/SPR21-FROZEN.md5`（收官由我手工刷）。
4. ⛔ 为让门变绿而修改断言期望值／探针 oracle 副本。发现假红假绿如实报给我裁（S40 净化门槛那行今天已有 3 份拷贝的前车）。
5. ⛔ 引入 Area2D 或新碰撞层掩码（HP-5）；⛔ 命中相关抽取（HP-3）；⛔ 零输入面报绿（HP-8）。
6. ⛔ 把 §B~§E 当成"顺手做完"的东西——它们各自的数值/方向都在作者手里，早落一步就要返工一整轮手感验收。
7. ⛔ 在同一趟里既改生产码又改探针期望值还改文档（三元组/哨兵/锚句三类面各自腐烂时无法归因）。分趟跑，每趟留终端尾部行。

---

## §H 我需要你回我的东西（短，四项）

1. A 组三件的实测数：新 `_PD_DECLARED`、A-1 故意红的原文行、A-2 的零 diff 结论。
2. P-3 里任何一条锚点 `count != 1` 的现场（有就报，没有就说"全部 count==1"）。
3. §E 那条「三枚锥 count=1」的错位，你复算后是同不同意（同意则我把它并进 E4 的问题一起问作者）。
4. 如果你判断本单某处**不可执行**（像 S40 那样数学上不满足的判据），直接指出是哪一步、给盘上依据（文件@行），我独立复算后改口径——⛔ 自行绕过或自行降级判据。
