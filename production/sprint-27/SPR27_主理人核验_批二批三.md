# Sprint 27 批二 · 批三 · 主理人独立核验

> 核验对象：`64581e7`（批二 誓约遗赠）+ `fe7c6a3`（批三 C1 主题倍率回落 / C2 狂乱接全）。核验时 HEAD `fe7c6a3`，工作树干净。
> 方法：**全部自跑，不采信自报**。含 5 把独立变异（每把打不同的失败面）、三 seed E1 双向对照（含基线反证）、13 个既有探针门回归。
> 结论：**final PASS**。附 3 项裁定（全部接受代码）+ 5 处我方文档缺陷 + 1 处**变异判据陷阱**（不记会误杀正确实现）。

---

## 一 改动面

| 项 | 实测 |
|---|---|
| 批二 `64581e7` | `scripts/game_main.gd` **+595** + 批二实施单 +57，共 652 insertions / 0 deletions |
| 批三 `fe7c6a3` | `scripts/game_main.gd` +265 / `scripts/slug.gd` +6 −3 + 批三实施单 +58，共 318 insertions / 11 deletions |
| 两批合计（对 `ece249d`） | **11 文件 / 3688 insertions / 11 deletions**；其中代码 `game_main.gd` +860、`slug.gd` +3 净、文档 9 份 |
| `.png` / `.mp3` / `.import` | **0** |
| 冻结清单 | 核验前 `32/34 OK`（`game_main.gd` / `slug.gd` 两项 FAILED = 本批授权的两个文件，其余 32 个零字节漂移） |
| 冻结清单（本轮核验后刷新） | 两行 md5 更新 → **34/34 OK**，见 §七 |

---

## 二 静态门（自跑）

| 门 | 实测 | 结论 |
|---|---|---|
| ① `_oath_grant()` 调用点恰 1 处 | 词边界 `grep -nE "(^\|[^A-Za-z0-9_])_oath_grant\(\)"` → **2 行**（`:369` 调用、`:3258` 定义） | ✓ |
| ① 附证：朴素 grep | **4 行** —— 子串陷阱真实存在（`_test_oath_grant()` 的定义 `:3565` 与挂载 `:253` 各多算 1 行） | 陷阱实证，必须词边界 |
| ② `_read_oath_streak()` 唯一读侧 | **口径有误，见 §五-4**：全仓实测 **7 行**（`game_main.gd` 3 + `player.gd` 4）；`game_main.gd` 内 **3 行**（`:3226` 定义 / `:3265` 新增 / `:3484` 既有局末） | 门有效，措辞须改「game_main.gd 内」 |
| ③ C08 运行时自判 | `#27 C08 授予符号字面调用点==1 measured=count=1 lines=[369]` | ✓ 且形状可变异（见 §六 刀五） |

---

## 三 机制层读码（逐条对两份实施单）

### 批二

| 项 | 结论 |
|---|---|
| 三态映射 | `_oath_grant_amount()` `:3244`：`<=0→0 / 1→3 / 2→5 / else→8` ✓ |
| **棘轮守卫** | `:3263-3265` `oath` 空 → `return`，位置在 `daily_mode` 检查之后、读 `streak` 之前 ✓（`next_oath_streak` 一字未动——「不断绩」与「不发放」已分离） |
| 载体 | `Game.diamonds += n` 直写 + `emit(Game.diamonds)`，**未走 `add_diamonds()`** ✓ 三条污染通路（`run_diamonds_earned` / `diamonds_picked` 自激 / `_reso_pickups` 白送共鸣）全绕开 |
| 读侧只读一次 | `var s := _read_oath_streak()` 单次，档位与文案共用 ✓ |
| 注入顺序 | `:365 _apply_sigil_contract()` → `:368 _apply_codex_boons()` → **`:369 _oath_grant()`** → `:372 Game.run_seed = Game.rng.seed` ✓（在 purse 赋值 `:1515` 之后、rng 首抽之前） |
| daily 豁免 | `:3259-3260` 命中即 return ✓ |
| 文案 | `_OG_TOAST_TAG`（`:123`）+ 连绩实值 + 回流实值 ✓ |

### 批三

| 项 | 结论 |
|---|---|
| C1 字段分离 | `_mod_enemy_speed_mult` / `_mod_diamond_mult`（`:126-127`）✓ |
| C1 纯函数 | `_modifier_mult_pair()` `:1435`：rage(1.25,1.0) / barren(1.0,0.7) / swarm(1.0,1.5) / default(1.0,1.0) ✓ |
| C1 接线 | `_apply_modifier_mult()` `:1450` 四行赋值、零 rng 零副作用 ✓ |
| C1 单一来源 | `_roll_modifier()` `:1458` 只留一行调用；`match` 内三条字面量（rage 1.25 / barren 0.7 / overload 之外）已删；swarm 分支已删 ✓ |
| C1 复位位置 | `_apply_floor_theme()` `:1709-1710` 复位在 `th.is_empty()` 早退（`:1712`）**之前** ✓ |
| C2 四路径 | `slug.gd` `:216` / `:236`（既有）/ `:298` / `:304` 均有 `* Game.calamity_speed_mult`，插入位置统一在 `Game.enemy_speed_mult` 之后、`_slow_mult` 之前；基线 `ece249d` 仅 `:236` 一处 ✓ |

---

## 四 探针门（自跑，13 个既有门同时回归）

```
[INFO] validate: 脚本编译扫描 34/34 通过
[INFO] validate: 自检通过：敌人 29 / 房间 11 / 地图池 4 层
[SMOKE] validate problems=0
[SMOKE-CAL-THEME]   done checked=103 declared=103
[SMOKE-OATH-GRANT]  done checked=43  declared=43
[ERR] 总数 = 0                 PENDING = 0
```

回归覆盖的 13 个探针门（同一进程内并联跑通、`[ERR]=0`）：`SMOKE_RG7` / `SMOKE_STATUS` / `SMOKE_SAVE` / `SMOKE_OATH` / `SMOKE_ECHO_CHAIN` / `SMOKE_CAL_THEME` / `SMOKE_OATH_GRANT` / `SMOKE_META` / `SMOKE_META_POOLASSERT` / `SMOKE_META_UNLOCKTEST` / `SMOKE_META_APPLY` / `SMOKE_META_SAVE` / `SMOKE_META_RNGCOUNT`。
未使用 `SMOKE_DAILY`（红线 #1：不以当日日期覆盖 seed）。

---

## 五 E1 确定性（三 seed，双向对照）

### 5.1 指纹逐字一致

`SMOKE_META_FINGERPRINT=1`，HEAD vs 基线 `ece249d`：

| seed | modifier | `[SMOKE]`+`[INFO]` 全行 diff |
|---|---|---|
| 12345 | none | **逐字无差异** |
| 777 | barren | **逐字无差异** |
| 42 | swarm | **逐字无差异** |

### 5.2 基线反证（本轮新增，杜绝「对照的不是冻结版」）

把 `scripts/` 切到 `ece249d` 后跑 `md5sum -c SPR21-FROZEN.md5` → **34/34 OK**。
→ 证明 E1 对照用的基线**就是冻结版本体**，不是近似版本；跑完已 `git checkout HEAD -- scripts/` 复原，树干净。

### 5.3 开局残响（`SMOKE_RUN_START=1`，补 fingerprint 不覆盖的货币面）

| seed | HEAD | 基线 | §10 |
|---|---|---|---|
| 42 | `diamonds=3 modifier=swarm` | 同 | 3 / swarm ✓ |
| 777 | `diamonds=13 modifier=barren` | 同 | 13 / barren ✓ |
| 12345 | `diamonds=3 modifier=none` | 同 | 3 / none ✓ |

三 seed 逐字一致，且与批三 §10 预置基线完全吻合。

### 5.4 诚实标注

headless 指纹只到 `floor=1`（不推进楼层）。**第 12 层的零行为覆盖仍是已知空洞**（③ 只跑 4–11、④c 不扫 12、⑥6 只验 `Data.theme_for_floor` 返回值），本批不补，S28 量级。

---

## 六 独立变异复现（5 刀，自跑）

每把刀都**替换目标行**（不新增行），跑完 `git checkout HEAD -- scripts/` 复原。

| 刀 | 变异 | 实测红 | 我方刀表预测 | 偏差 |
|---|---|---|---|---|
| **刀六** | 拆 `oath.is_empty()` 棘轮守卫 | **B07 单红**（`measured=8` = 棘轮漏发的 +8） | 仅 B07 | ✅ 一致 |
| **刀一** | `S==2` 支 `5→3` | **5 红**：A03 / A08 / A09 / **B03** / D03 | A03/A08/A09/D03（4） | 漏 B03（构造 `streak=2.9` 也落在 s=2 支） |
| **刀五** | 授予挪到 `Game.reset()` 之前 | **4 红**：E01 / E02 / E03 / E04（E04 报 `grant=347 < sigil=366`） | E01/E02/E03/E04/**B10** | B10 实绿、E04 是真正的 reset 面守卫 |
| **刀 B** | 复位写死 `diamond_mult = 1.0` | **3 红**：⑪b / ⑪c / **⑫**；⑨ 绿、⑯ 全绿 | 仅 ⑪ | 漏 ⑫（它自己也读复位后的 dm） |
| **刀 G** | `_mod_diamond_mult = pair.x` | **4 红**：**⑨** / ⑯1 / ⑯2 / ⑯3 | ⑯1/⑯2/⑯3（3） | ⑨ 是 seed 条件红（本次开局掷出 swarm；掷 none/overload/glass 则绿） |

### 6.1 🔴 本轮最重教训：批三的红判据不能用 `ok=`

批三的 `_ct_assert()`（`:677`）**只打印 `measured=/expect=`，不带 `ok=` 字段**，通过/失败完全交给 `Dev.check()`——而 `Dev.check()` 只在失败时打印 `[ERR]`。

我第一次用 `grep "ok=false"` 判红，刀 B 得 **0 红**，看起来像「变异无效 / 探针没覆盖」。换 `grep "\[ERR\]"` 才看到真实的 3 红。

> **判据口诀**：批二看 `ok=false`（`:3268` 起自带字段），批三看 `[ERR]`。用错一次就会把**正确实现判成变异失效**。

### 6.2 刀五的假红（我自己的变异污染）

第一次跑刀五时，我把原调用替换成了注释 `# MUTATION-刀五：原 _oath_grant() 在此`——注释里含符号字面，C08 的行数统计把注释算成第 2 个调用点 → **凭空多出 1 红**（`lines=[347, 370]`）。
改用不含符号字面的注释重跑，C08 恢复 `count=1` 绿、真实红 4 条。

> **推论 1**：C08 对「挪位置」这个失败面**没有覆盖**（挪动不改变调用点数）——真正的守卫是 **E04 行号序**。
> **推论 2**：C08 的计数是**字面文本级**的，未来任何人在注释里写一句 `_oath_grant()` 都会把它判红。这是既有脆弱点，入册。

### 6.3 同文陷阱实证

`grep` 确认两条赋值各出现 **2 次**：`enemy_speed_mult = _mod_enemy_speed_mult`（`:1454` 接线 / `:1709` 复位）、`diamond_mult = _mod_diamond_mult`（`:1455` / `:1710`）。
→ 用 `replace_all` 做的刀会**一刀砍两个目标**，红表立刻失真。本轮全部用上下文唯一定位。

---

## 七 冻结快照刷新（本轮唯一非文档改动）

核验前清单为 `32/34 OK`。两行 FAILED 均为本批授权改动的文件，属预期；但若留着不刷，此后每次「交接前必查 34/34」都会看到 2 项红、必须靠口头记忆区分，与批一「改动后刷新快照行」的既有做法不一致。

故本轮把两行更新为现值：`game_main.gd` → `29a04fa7…`、`slug.gd` → `06fa0ebd…`，验后 **34/34 OK**。
这是**快照跟随 HEAD** 的常规维护，不是放松校验——32 个未授权文件依旧零字节漂移。

---

## 八 三处「如实记录」的裁定

### 裁定 1：E03 实际掷出 `overload`，不是 `barren` → **接受，入册不修**

实测 `e2e run=E03 ctrl=3 treat=11 modifier=overload`，Δ=8，断言绿。

- **无覆盖损失**：E03 用「控制组 / 处理组」差值，构造上对 modifier 无关，比「假设 barren」更强；`barren` 与授予的叠加语义分别由 B09（`7+8=15` 叠加非覆盖）与 ⑯2（`barren` → `diamond_mult=0.7`）覆盖，**没有只被 E03 抓住的错误**。
- **名不符实**：标签写「barren 场景」而实跑 overload，是**我方骨架的构造假设错误**（我以为 `SMOKE_SEED=777` 会传导，实际探针还原的是入口 rng 快照），不是编程侧偏差。
- 实操提示：读 E03 时以相邻 `e2e run=E03 … modifier=…` 行为准。

### 裁定 2：`emit` 静态门实测 7，骨架预期 6 → **接受，骨架算错**

全仓 `diamonds_changed.emit`：基线 **5**（`game_main.gd:1769` + `game_state.gd:145/163/172/222`）→ HEAD **7**，新增 2 处：
- `:3270` 授予后发射（本批功能本体）
- `:4091` `_og_restore()` 还原后发射（探针还原残响后 HUD 必须刷新，否则后续 G01 读到陈旧标签）

骨架写 6 是我漏算还原发射，属必要且正确。

### 裁定 3：`_roll_modifier` 删掉 4 行 → **接受，但「空壳 / 孤儿分支」的表述不准**

基线该 `match` 的 `"swarm":` 分支**不是空的**，它有一行 `diamond_mult = 1.5`。C1 之后该赋值由 `_apply_modifier_mult("swarm")` 承担 → 属**冗余重复赋值删除**，不是「移掉一个空壳」。

- 行为不变的实证：三 seed 开局残响与基线逐字一致（含 `swarm` 的 seed 42）、E1 三 seed 逐字一致、⑯3（`swarm` → `diamond_mult=1.5`）绿。
- 删除落在本批「倍率单一来源」目标内，**不超范围**；但后续读者若按「空壳」理解 diff，会误以为该行本来就是死的。

---

## 九 我方文档缺陷（5 处，均不影响代码）

1. **批二实施单 C08 静态门② 措辞**：写「全仓 `_read_oath_streak()` 恰 3 行」，实际全仓 7 行（`game_main.gd` 3 + `player.gd` 4，后者为 Sprint 16 既有、`gm.` 前缀、与基线逐字一致）。正确口径是「`game_main.gd` 内 3 行」。
2. **同一处行号过期**：写 `:2973` / `:3198`，现值 `:3226` / `:3484`（骨架期行号）。
3. **批三刀表 刀 B**：漏 ⑫（⑫ 既守「复位在早退前」的位置面，也读复位后的 `diamond_mult` 值面）。
4. **批二刀表 刀一**：漏 B03（`streak=2.9`）。
5. **批三刀表 刀 G**：漏 ⑨（seed 条件红）。
6. **刀五**：原表写 B10 会红，实测 B10 绿 —— B10 不经 `start_run()`，挪位置打不到它。

> 以上全是「刀表预测集合」问题，不是覆盖问题：**实测红都 ≥ 预测红且预测红全在其中**，没有出现「预测红实测绿」的漏验（唯一例外是刀五的 B10，已单列）。方向安全：错在低估，不在高估。

---

## 十 入册不修 / 状态变更

| 项 | 状态 |
|---|---|
| 🔴 **`enemy_speed_mult` / `diamond_mult` 只升不降** | **本批已关闭主干**：C1 把复位改为回落到 `_mod_*`（而非不再复位），离压后不再整局残留 1.3 / 1.5；⑧（三层离压双值）、⑫（无主题层早退）两类断言守卫 |
| `barren` + `scarce_ore` 文案 -0%、`max_hp` 钳制时 frail 比例不符 | 照旧在册；**压力层当层内**仍是 `maxf` 抬起，名义/实际比例口径未收敛 |
| 双 `enemy_speed_mult`（`Game.` vs `Game.main.`） | 在册。⑭ 首版写错后者、被自己抓红后修正，已实证两变量分属两类 |
| C08 字面文本级计数（注释含符号即判红） | 新入册（§六 6.2） |
| 第 12 层零行为覆盖 | 在册，S28 量级 |
| C3 圣所代价（`cost_kind` 空但结算用存在性布尔） | 挂 S28 |
| 既有 `Lambda capture at index 0 was freed` | 与本批无关，基线同样出现 |

---

## 十一 结论

**final PASS。**

五门（静态 / 机制读码 / 探针 103+43 / E1 三 seed 双向 / 冻结 34-34）全部自跑通过；5 把独立变异证明断言体系分层成立——

- **数值面**：刀一（映射表）、刀 B（复位值）各自独立见红；
- **位置面**：刀五只被 E04 抓住（C08 结构上抓不到，已实证）；
- **守卫面**：刀六精确单红 B07，棘轮漏发 `measured=8` 如实现形；
- **接线面**：刀 G 打穿 ⑯1-3。

三处如实记录全部裁定为**接受代码**：一处是我方骨架构造假设错（E03）、一处是我方算术漏项（emit 6→7）、一处是编程侧表述不准但行为正确（swarm「空壳」实为冗余赋值）。无一项构成 FAIL。

同时刷新冻结快照两行，恢复 `34/34 OK` 不变式。

**推送不归核验侧。** 编程侧可推 `64581e7` + `fe7c6a3` + 本核验提交。
