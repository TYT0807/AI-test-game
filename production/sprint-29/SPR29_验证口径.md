# SPR29 · 验证口径（发现度改写深渊起点）

> 任务 **SPR29-QA-01**｜角色：验收接手方（QA）｜**只产出本文件**：不改 `.gd`、不改资产、不 commit、不联系其它成员。
> 上游：`SPR29_方向评估.md`(84行) + `SPR29_设计实稿_发现度改写深渊起点.md`(132行，六点已拍板) + `SPR29_实施单_编程侧.md`。
> 基准 HEAD `318ac8b`（领先 origin 1 笔系网络故障，与口径无关），树干净；冻结 `production/sprint-21/SPR21-FROZEN.md5` 34/34 OK；S19–S28 全收官 PASS。
> **行号全部实读本文当天**：`game_main.gd:343`(E1 指纹) / `:370`(`_apply_codex_boons()` 调用) / `:374`(`run_seed`) / `:378` 指纹 / `:379` modifier / `:384-388` 深渊乘子 / `:3367` 函数定义 / `:686-691`(`_ct_assert`)；`game_state.gd:280-281`(CODEX_KINDS/codex) / `:406-413`(`codex_boons()`)；`player.gd:61` / `:671` / `:1844-1848`；`data.gd:343-348`；`menu.gd:989`。

---

## 〇 三条先读（否则整份口径会用错）

| # | 事实 | 后果 |
|---|---|---|
| 1 | **跑法必须带 `SMOKE=1`**，否则 `_smoke` 假、探针整段不执行，日志空 = 假绿 | 所有命令首段一律 `SMOKE=1` |
| 2 | 🔴 **两种探针格式判红方式不同，绝不混用**：批二式（`_og_assert`/`_pc_assert`，`game_main.gd:3692/4198`）打印 `ok=` 字段 → 判红看 `ok=false`；批三式 `_ct_assert()`（`game_main.gd:686-691`）**只打 `measured=/expect=`，没有 `ok=`** → 成败只走 `Dev.check()`，失败才打 `[ERR] cal_theme` | **本批新探针统一采用批二式**（§四给 helper 契约与双门判红）。若拿 `ok=false` 去判批三式探针，得 **0 红**，会把正确实现误判成"变异无效"（S27 实测踩坑） |
| 3 | **满档深渊局盾 = 5，不是 4**：`enemies_5` 被动 +1（`data.gd:344`，任意局）＋ 起点缓冲 +4（仅 tier>0） | 验数值断言必须**差分**测缓冲（Δ=0/2/4），或按含被动的绝对值测（0/2/5）。只报"有盾"= 恒过假覆盖 |

**《验数值断言为什么不能只验"有盾"》**：`enemies_5` 被动本就给 +1 盾，`SMOKE_ABYSS` 之类的"盾>0"断言在基线就绿。本批核心断言必须在**同一 `abyss_tier` 下构造发现档数不同的局**，证明各档盾值**互不相同**——这是 S28 H01/H04「构造名义与实际不等的局」同型纪律。

---

## 一 构造口径（探针必须按此造局，否则断言无靶）

| 项 | 口径 |
|---|---|
| 档数读数 | `n = Game.codex_boons().size()`（0..4，纯只读零 rng，`game_state.gd:406-413`） |
| 四档阈值（`data.gd:343-348`） | `enemies_5`=enemies≥5 → shield+1；`relics_4`=relics≥4 → diamonds+3；`themes_3`=themes≥3 → max_hp+1；`bosses_2`=bosses≥2 → suffix |
| **n=0 局** | `Game.codex` 六类全空数组 → `boons.is_empty()` 早退（`:3369`），S29 块不执行 |
| **n=2 局（无 enemies_5）** | `bosses` 填 2 个 id + `themes` 填 3 个 id，其余空 → boons = {bosses_2, themes_3}，被动盾 0，缓冲应 = 2 |
| **n=4 局（满档）** | enemies=5 / relics=4 / themes=3 / bosses=2 全填 → boons 4 个，**含 enemies_5**，被动盾 1，缓冲应 = 4，tier>0 总盾应 = 5 |
| tier 设置 | 探针内直接写 `Game.main.abyss_tier`（`:97` 默认 0），**同 SMOKE_ABYSS 范式**（`game_main.gd:455/459`）；不依赖菜单点击 |
| 拉平/还原 | 入口快照 `Game.codex`（深拷贝）、`abyss_tier`、`player.shield_charges/max_hp/hp`、`Game.diamonds`、`Game.rng.seed`+`.state`；每段后还原。**禁止调 `Game.save_codex()` / `set_codex_last_run()`**（都写盘） |
| 侧效应注意 | `relics_4` 走 `add_diamonds`（会记 `oath_count("diamonds_picked")`）、`themes_3` 改 max_hp、`bosses_2` 挂词缀 → n=2/n=4 两次调用之间必须全部还原，否则后续断言读到脏基线 |
| 零 rng 还原 | 连续两次造局前 **`.seed` 与 `.state` 都还原**（只还原 `.state` 不够，`reset`/`daily` 路径读 `.seed`，S27 批二缺口②教训） |
| **调用方式（刀表推演前提）** | A01/A02/A03/B01/B02/B03/C01/C02/C03/D01/D02 **直调 `_apply_codex_boons()`**（手置 `abyss_tier`，射程只到该函数体）；**A04 是全口径唯一走完整 `start_run()` 的断言**（专抓漏接线）。此分工是 §五 刀三/刀八红集合的前提——若改成全走 start_run，刀三与刀八预测全部作废 |

---

## 二 断言规格（20 条＝探针内 15 + 外部 5；编号冻结，实施/核验/变异记录一律按此对齐）

**分类定义**：**验效果型**＝观测到真实字段值且有专属变异刀能打红；**前提守卫型恒过**＝正确实现下必然成立，**不构成覆盖**；**只验标志**＝只验"发生/没发生"，不是数值覆盖；**走查守卫**＝无专属刀，**不构成行为覆盖**。

| 编号 | 断言内容 | measured 取什么 | expect 取什么 | 分类 | 抓哪个错误实现（刀号） |
|---|---|---|---|---|---|
| A01 | n=0 深渊局缓冲 = 0（起点基线） | `shield(t>0) − shield(t=0)` | `0` | **前提守卫型恒过·不构成覆盖**（早退使 S29 块不执行，任何改块 mutant 都碰不到它） | 无专属刀；只作基线自证 |
| A02 | n=2 深渊局缓冲 = 2 | 同上（无被动干扰，绝对 shield 差） | `2`（t0=0 → tT=2） | 验效果型 | 刀一/二/三/四/六/九 |
| A03 | n=4 深渊局缓冲 = 4 | 同上（t0=1 被动 → tT=5） | `4` | 验效果型 | 刀一/二/三/四/**五**/六/九 |
| A04 | **真实 `start_run()`**（tier=T, n=4）落盾 = 5 | `player.shield_charges`（跑完一次完整 start_run 后） | `5` | 验效果型 | 漏调用 `_apply_codex_boons()`(刀八)·刀一/二/四/五/九 |
| B01 | n=2 **普通局**（tier=0）盾 = 0（无缓冲、无被动） | `shield_charges` | `0` | 验效果型 | gate 写反(刀二)·gate 恒真(刀六) |
| B02 | n=4 普通局盾 = 1（**只含 enemies_5 被动**） | `shield_charges` | `1` | 验效果型 | 刀二/刀六（普通局基线被污染） |
| B03 | n=0 构造自检：`codex_boons().size()` | 派生值 | `0` | 前提守卫型恒过·**不构成覆盖** | 无（构造正确性，不是玩法断言） |
| C01 | n=1（仅 enemies_5）tier=0 盾 = 1，证明被动来源独立存在 | `shield_charges` | `1` | 验效果型 | gate 恒真(刀六)·gate 写反(刀二) |
| C02 | n=1（仅 enemies_5）tier=T 盾 = 2 = 1 被动 + 1 缓冲（**叠加非覆盖**） | `shield_charges` | `2` | 验效果型 | 覆盖式 `=`(刀五)·刀二/三/四 |
| C03 | n=4 tier=T 盾 = 5 = 1 被动 + 4 缓冲（**不重复计数、无全局钳 3**） | `shield_charges` | `5`（不可为 3 或 6） | 验效果型 | 重复计数(刀九)·刀一/二/三/四/五；`player.gd:61` 无全局上限、`:671 mini(...,3)` 只是 `brief_shield` 局部上限 |
| D01 | 加盾分支前后 `Game.rng.seed` 逐字不变 | `rng.seed`(后) vs `rng.seed`(前) | 相等 | 验效果型 | 分支内插入 rng 消费(刀七) |
| D02 | 同上 `Game.rng.state` 逐字不变（**只比 seed 不够**） | `rng.state`(后) vs `rng.state`(前) | 相等 | 验效果型 | 刀七 |
| E01 | E1 指纹 seed 12345 对基线 `318ac8b` 逐字一致 | `[SMOKE-META] fingerprint` 的 `rooms=`+`kinds=` | 基线逐字串 | 前提守卫型恒过·**不构成覆盖**（结构性恒真；它只管地图，不管映射） | 无；指纹被改即越界红，不是本批映射证据 |
| E02 | 同上 seed 777 | 同上 | 基线逐字串 | 前提守卫型恒过·**不构成覆盖** | 同 E01 |
| E03 | 同上 seed 42 | 同上 | 基线逐字串 | 前提守卫型恒过·**不构成覆盖** | 同 E01 |
| F01 | 既有 `SMOKE_ABYSS` 三乘子断言逐字不变 | `grep '^\[SMOKE-ABYSS\]'` 新旧日志 | `diff` 空 | 前提守卫型恒过·**不构成覆盖** | 无（churn 守卫） |
| F02 | 既有 `SMOKE-OATH-GRANT`/`SMOKE-PURIFY-COST`/`SMOKE-CAL-THEME` `#NN` 行逐字不变 | 各探针 `#NN` 行 | `diff` 空 | 前提守卫型恒过·**不构成覆盖** | 无（churn 守卫） |
| G01 | 满档 5 层逐层消耗，`oath_count("shield_blocks")` 逐次 0→1→2→3→4→5 | `_oath_counters["shield_blocks"]` 六次读数 | `0,1,2,3,4,5` | **走查守卫·不构成行为覆盖**（本批零改 `player.gd`，无专属刀；只验 R4 正特性成立） | 无（真要打红须改 player.gd，越界） |
| G02 | 首次消耗时 toast 含「护盾抵挡」 | `hud` toast 文本 | `contains("护盾抵挡")` | 只验标志·**不构成数值覆盖**，且无专属刀 | 无（走查守卫） |
| H01 | 源码序：S29 加盾块行号 **<** `run_seed` 赋值行（限 `_apply_codex_boons()` 函数体内定位） | 探针读 `res://scripts/game_main.gd` 算两行号 | 前者<后者 | 前提守卫型恒过·**不构成覆盖**（静态门，计 PASS 不计覆盖） | 落点挪到 run_seed 后(刀三)——它是**唯一的结构观测点**；但刀三另有 4 条行为红（A02/A03/C02/C03），并非只红它 |

**分类小计（20 条逐条可加）**：
- **验效果型 10**：A02 A03 A04 B01 B02 C01 C02 C03 D01 D02 —— **唯一的有效行为覆盖**，每条都有专属变异刀。
- **前提守卫型恒过 8·不构成覆盖**：A01 B03 E01 E02 E03 F01 F02 H01。
- **只验标志 1·不构成数值覆盖**：G02。
- **走查守卫 1·不构成行为覆盖**：G01（无专属刀，本批零改 player.gd）。
- 其中**探针内 `declared=15`** = A4+B3+C3+D2+G2+H1；**外部 5** = E3+F2（E1 三跑 / churn diff 不入探针 declared）。

> 🔴 **对外报数只报**：「本口径 20 条断言 / **有效行为覆盖 10 条** / 非覆盖 10 条（前提守卫 8 + 只验标志 1 + 走查守卫 1）」。**禁止把 E1 指纹、churn diff 或「有盾」算进有效覆盖**——上一稿承诺的验数值断言就是为补这个洞。

---

## 三 E1 三 seed 基线（**QA 当天实跑当前树**，非从旧稿抄录）

> 当前树 HEAD `af3cc61` 只比任务书基准 `318ac8b` 多 3 个 S29 **文档** commit（`git diff --stat 318ac8b HEAD` 仅 3 个 `.md`），**零 `.gd` 改动** → 代码基线等价 `318ac8b`，以下为权威基线。
> 实跑命令：`SMOKE=1 SMOKE_SEED=<s> SMOKE_META_FINGERPRINT=1 <GODOT> --headless --path . --quit-after 300`，与 `SMOKE_RUN_START=1` 两次独立跑互证。`diamonds`/`modifier` 亦实跑确认 3/13/3、none/barren/swarm。

| seed | `run start diamonds=` | modifier | `rooms=` / `kinds=`（**逐字，含逗号后空格**） |
|---|---|---|---|
| 12345 | 3 | none | `(-1, 0),(-1, 1),(0, -1),(0, 0),(0, 1),(0, 2),(0, 3),(1, 1),(2, 1)` / `secret,treasure,shop,start,combat,elite,super_secret,elite,boss` |
| 777 | 13 | barren | `(-1, -1),(-1, 0),(-2, 0),(0, -1),(0, 0),(0, 1),(0, 2),(1, 1),(2, -1),(2, 0),(2, 1)` / `treasure,cursed,super_secret,secret,start,elite,shop,elite,boss,combat,combat` |
| 42 | 3 | swarm | `(-1, -1),(-1, 0),(0, -1),(0, -2),(0, -3),(0, 0),(0, 1),(1, -1),(1, -3),(2, -1),(2, 0)` / `treasure,secret,combat,combat,elite,start,super_secret,challenge,boss,combat,shop` |

**为什么结构上必然零重定**：`:343` 只打 rooms+kinds，**不含玩家起始数值**；加盾在 `run_seed` 前且不碰 rng。若三跑任一漂移，说明有人把起始数值混进指纹或把块塞进 rng 抽取路径，按 FAIL。
**判据**：改前 1 次 + 改后 2 次，三次 `rooms=`/`kinds=` 逐字相同，且每次运行 `grep -c "[SMOKE-META] fingerprint"` == 1。

---

## 四 探针契约与判红命令（🔴 本批采用**批二式**，不是 `_ct_assert()` 式）

**helper 契约（实施方照此写，不新开第三套格式）**：
```gdscript
func _sb_assert(ok: bool, nn: String, what: String, measured, expect) -> void:
    _sb_checked += 1
    Dev.check(ok, "start_buffer", "%s %s | measured=%s expect=%s" % [nn, what, str(measured), str(expect)])
    print("[SMOKE-START-BUFFER] #%02d %s measured=%s expect=%s ok=%s" % [
        _sb_checked, nn + " " + what, str(measured), str(expect), str(ok)])
```
`SMOKE_START_BUFFER=1` 挂进既有 env 判定链，与 `SMOKE_OATH_GRANT` 同级、**不新增机制、不改既有判定行**。输出前缀独立 `[SMOKE-START-BUFFER]`，**禁止写进 `[SMOKE-META]`**。探针内 `declared` 写死 **15**（A组4+B组3+C组3+D组2+G组2+H组1），末尾 `Dev.check(_sb_checked == 15)` + 无条件打 `done checked= declared=`。

```bash
GODOT="D:/SteamLibrary/steamapps/common/Godot Engine/godot.windows.opt.tools.64.exe"
# 探针（⚠️ 必带 SMOKE=1；⚠️ 绝不同时开 SMOKE_META_FINGERPRINT / SMOKE_RUN_START）
SMOKE=1 SMOKE_SEED=12345 SMOKE_START_BUFFER=1 "$GODOT" --headless --path . --quit-after 300 2>&1 | tee sb.log
grep -c '^\[SMOKE-START-BUFFER\] #' sb.log          # 期望 15（执行证明）
grep -c 'ok=false' sb.log                            # 判红主门：期望 0；>0 即红
grep -c '\[ERR\] start_buffer' sb.log                # 交叉门：期望 0（与主门必须一致）
grep 'done checked=' sb.log                          # 期望 checked=15 declared=15
# E1 三跑（绝不加 SMOKE_START_BUFFER）
for s in 12345 777 42; do
  SMOKE=1 SMOKE_SEED=$s SMOKE_META_FINGERPRINT=1 "$GODOT" --headless --path . --quit-after 300 2>&1 \
    | grep '\[SMOKE-META\] fingerprint'
done
```
**判 PASS 四条同时成立**：① `#NN`==15 且 `ok=false`==0 且 `[ERR] start_buffer`==0 且 `checked=15 declared=15`；② 九刀（§五）逐刀见红、红集合对表；③ E1 三跑逐字一致；④ §六 churn diff 全空。
> 🔴 **若实施方误用 `_ct_assert()` 式写本探针**：它没有 `ok=` 字段，上面 `grep 'ok=false'` 恒为 0 → **必须改判** `grep -c '\[ERR\] start_buffer'`。本口径统一要求批二式，故给双门；**两门读数不一致 = 有人改了 helper，按 FAIL**。
> 若 300 帧内未打出 `done` 行 → 探针窗口不足，按 FAIL 回报主理人，**不改期望值**。

---

## 五 变异刀表（9 把；每把**替换目标行、不新增行**）

| 刀 | 改法（改哪一行） | 预测红编号 | 独占面 / 说明 |
|---|---|---|---|
| 一 | `+= boons.size()` → `+= 1`（各档加同样盾） | A02 A03 A04 C03 | A01 因 n=0 早退必绿，**别拿它判刀一无效** |
| 二 | gate 写反 `if abyss_tier == 0:` | A02 A03 A04 B01 B02 C01 C02 C03 | 同时打红正向差分与 tier=0 反向守卫 |
| 三 | 加盾块挪到 `run_seed` 之后（移出 `_apply_codex_boons()` 到深渊段） | A02 A03 C02 C03 **H01** | 🔴 直调断言全部失去缓冲块 → Δ=0、C02=1、C03=1；**A04 仍绿**（start_run 走到深渊段拿得到）。原文写"仅 H01/零行为红"是错的，已实测订正 |
| 四 | 载体改 `player.max_hp += boons.size()` | A02 A03 A04 C02 C03 | 验 shield 数值断言全红；B/C01 绿（tier0 无缓冲） |
| 五 | 覆盖式 `player.shield_charges = boons.size()`（`=` 换 `+=`） | **A03** A04 C02 C03 | 🔴 **A03 必红**：n=4 有被动基数，`=` 把 t0 的 1 层冲掉 → Δ=4−1=3≠4。A02 仍绿（n=2 无被动、t0=0，Δ 不变）——二者差值正是 A03 的独占面 |
| 六 | 删 `if abyss_tier > 0:` 守卫（恒真无条件加） | **A02 A03** B01 B02 C01 | 🔴 t0 也被加缓冲 → A02 Δ=0、A03 Δ=0 **必红**。原文"A 组差分全绿"正好说反，已实测订正；A04/C02/C03 仍绿（tier=T 本就该加） |
| 七 | 加盾块内插入一次 `Game.rng.randi()`（替换一条空行/注释行） | D01 D02 | 零 rng 唯一实证；seed/state 双比，只比其一会漏 |
| 八 | `:370` 的 `_apply_codex_boons()` 调用行整行替换为注释（不留调用、不新增行） | **仅 A04** | 直调断言全绿——**只有走 `start_run()` 的 A04 能抓漏接线** |
| 九 | 重复计数：把加盾塞进 `for id in boons:` 循环内每档 `+= boons.size()` | A02 A03 A04 C03 | 满档吐 16+1≠5；C02(n=1) 仍绿属正确，别当漏网 |

**刀表复核实测推演**（QA 用 Godot 4.7.2 独立算术模型实跑，逐条按 §一造局算 measured，**不按断言名推**；模型在仓库外的临时目录，未动项目任何 `.gd`）。括号内为 measured，与 expect 不等即红：

| 刀 | A02 Δ(exp 2) | A03 Δ(exp 4) | C02(exp 2) | C03(exp 5) | A04(exp 5) | B01/B02/C01 | 复核红集合 |
|---|---|---|---|---|---|---|---|
| 一 | 1 红 | 1 红 | 2 绿 | 2 红 | 2 红 | 0/1/1 绿 | A02 A03 A04 C03 |
| 二 | −2 红 | −4 红 | 1 红 | 1 红 | 1 红 | 2/5/2 红 | A02 A03 A04 B01 B02 C01 C02 C03 |
| 三 | 0 红 | 0 红 | 1 红 | 1 红 | **5 绿** | 0/1/1 绿 | A02 A03 C02 C03 H01 |
| 四 | 0 红 | 0 红 | 1 红 | 1 红 | 1 红 | 0/1/1 绿 | A02 A03 A04 C02 C03 |
| 五 | **2 绿** | **3 红** | 1 红 | 4 红 | 4 红 | 0/1/1 绿 | A03 A04 C02 C03 |
| 六 | 0 红 | 0 红 | 2 绿 | 5 绿 | 5 绿 | 2/5/2 红 | A02 A03 B01 B02 C01 |
| 七 | 2 绿 | 4 绿 | 2 绿 | 5 绿 | 5 绿 | 0/1/1 绿 | D01 D02 |
| 八 | 2 绿 | 4 绿 | 2 绿 | 5 绿 | **0 红** | 0/1/1 绿 | A04 |
| 九 | 4 红 | 16 红 | 2 绿 | 17 红 | 17 红 | 0/1/1 绿 | A02 A03 A04 C03 |

> 三条关键订正：**刀五**（team-lead 指出）补 A03——n=4 被动基数被 `=` 冲掉，Δ=3；**刀三**从"仅 H01/零行为红"改为 5 红——直调断言的块被搬走后全失效，只有 A04 绿；**刀六**从"B01 B02 C01"改为加 A02/A03——gate 恒真使 t0 也加缓冲，差分塌成 0。两次订正同因：**按断言名推刀表不可靠，必须按造局算 measured**。

**纪律**：① 每刀前 `git checkout -- scripts/` 复原，**不许叠刀**；② 替换前 `grep -c` 确认目标串出现次数，`replace_all` 只用于确认唯一的串；③ **注释里不许写符号字面**（`+=`、`abyss_tier` 等）——文本级静态门会凭空多红（S27 实测）；④ 某刀把探针打断（`checked<15`）则结果作废重跑，不算红；⑤ 复原后复跑必须全绿。

---

## 六 既有零 churn 对比方法（F01/F02 的可执行做法，不是"不回改"一句）

```bash
# 1) 基线（HEAD 318ac8b，改动前各跑一次并存日志，环境/seed 固定）
SMOKE=1 SMOKE_SEED=12345 SMOKE_ABYSS=3        "$GODOT" --headless --path . --quit-after 300 > base_abyss.log 2>&1
SMOKE=1 SMOKE_SEED=12345 SMOKE_OATH_GRANT=1    "$GODOT" --headless --path . --quit-after 300 > base_oath.log 2>&1
SMOKE=1 SMOKE_SEED=12345 SMOKE_PURIFY_COST=1   "$GODOT" --headless --path . --quit-after 300 > base_purify.log 2>&1
SMOKE=1 SMOKE_SEED=12345 SMOKE_CAL_THEME=1     "$GODOT" --headless --path . --quit-after 300 > base_cal.log 2>&1
# 2) 改后同命令生成 new_*.log，逐条 diff（只比断言/输出行，忽略 [SMOKE] t= 帧序）
diff <(grep '^\[SMOKE-ABYSS\]' base_abyss.log)      <(grep '^\[SMOKE-ABYSS\]' new_abyss.log)
diff <(grep '^\[SMOKE-OATH-GRANT\] #' base_oath.log) <(grep '^\[SMOKE-OATH-GRANT\] #' new_oath.log)
diff <(grep '^\[SMOKE-PURIFY-COST\] #' base_purify.log) <(grep '^\[SMOKE-PURIFY-COST\] #' new_purify.log)
diff <(grep '^\[SMOKE-CAL-THEME\] #' base_cal.log)  <(grep '^\[SMOKE-CAL-THEME\] #' new_cal.log)
# 期望：四条 diff 全空
```
**为什么预期无 churn（实读支撑）**：`SMOKE_ABYSS` 探针（`:455-533`）直接写 `abyss_tier` 复算乘子，**不调 `start_run()`**，新块不被它触发；其 dmg 验伤段 `:495` 先 `player.shield_charges = 0` 后原样还原 `shield0`，与新起始盾隔离。既有探针读盾的段也各自先置 0（实施单 §四：`player.gd:689/894/941/1208`）。普通局探针 `abyss_tier` 默认 0（`:97`），加盾分支不执行。**任一条 diff 非空 = 越界，按 FAIL，不许改基线文件。**

---

## 七 本口径不覆盖什么（诚实清单）

1. **1/3 档与发现集全组合**：只构造 0/2/4（+ n=1 仅供 C01/C02 共存验证），不遍历全部 16 种发现集组合；`n=1` 取哪个档由具体配置决定，换档可能改变被动盾基数。
2. **盾 HUD 视觉**：>3 层时环盾图标是否溢出/重叠、toast 排版——只读 `shield_charges` 数值与文本，无人眼/像素断言。
3. **tier 与 codex 边界**：tier≥11 / 负 tier、畸形 codex 存档（非字符串 id、`need` 被改）——菜单限定 0..10，本批不构造哨兵。
4. **bulwark 完整兑现链**：G01 只验 `_oath_counters["shield_blocks"]` 逐次 +1，不验 `oath_fulfillment()` 兑现、`_write_codex_replay()` 写盘与下局回流；G01/G02 无专属刀，按走查守卫登记。
5. **落点结构错误被抓的机制边界**：刀三（块挪到 run_seed 后）实测 5 红，但其中 A02/A03/C02/C03 红的是「**块不在 `_apply_codex_boons()` 里**」这一功能后果，H01 红的才是「**行序在 run_seed 之后**」这一结构后果；**真正只违反行序、不违反"块在该函数内"的实现仍只有 H01 能抓**，而 H01 是静态门、不计行为覆盖。因盾加法不消费 rng，D01/D02 对本刀恒绿。另：`start_run()` 双击既有现象（S27 已登记在册）不重开、不验双击叠盾。

---

**口径结论（给实施方与核验方）**：本批唯一硬净增量证据 = **A02/A03/A04/B01/B02/C01/C02/C03/D01/D02 十条验效果型断言 + 九刀红矩阵**；E1 指纹、churn diff、H01 均属前提守卫，**计 PASS 但不计覆盖**。判红一律按 §四批二式双门（`ok=false` 主、`[ERR]` 辅），**绝不用 `ok=false` 去判 `_ct_assert()` 式探针**。质量门为建议性（advisory）：QA 给判定，最终放行由用户决定。
