# Sprint 27 批一 · 实施单（编程侧唯一权威）

> 主理人出稿，行号实读于 HEAD `aba6ccb`。**本文件与 `SPR27_批一设计实稿.md` / `SPR27_批一验证口径.md` 冲突时，以本文件为准。**
> 目标：灾祸不再无视楼层主题。同一灾祸落在不同主题层上，数值必须不同。
> 性质：**只加分支，不加实体、不加表、不加随机数、不改表结构。**

---

## 〇 一句话验收

玩家打完一局能说出「同样是残响枯竭，在岩浆层和在冰层不是一回事」。说得出 → 成；说不出 → 这批复合等于没做。

---

## 一 红线（违反任一条即打回，不论功能是否正常）

1. **零新增 `Game.rng` / `_floor_rng` 调用**。复合只读已抽出的 `_calamity` 与从 `floor_num` 派生的快照。E1 指纹必须逐字不变。
2. **`_calamity_theme_rule` 必须用 `Data.theme_for_floor(Game.floor_num)` 派生**。🔴 禁止 `Data.FLOOR_THEMES.get(Game.floor_num, {})`——`theme_for_floor()` 内部 `key = 4 + ((n - 4) % 8)`（`data.gd:491-495`），**第 12 层回卷到 vein**；直接查表拿到空字典 → 主题被判「无主题」→ 变体永不生效且**不报错**。
3. **`_clear_calamity_effects()` 只读快照，禁读 `Game.floor_num` 与 `_theme_rule`**。理由见 §二 陷阱 1，这是本批唯一会「静默错还原」的地方。
4. **禁止把变体编码进 `_calamity`**（如 `"frail@magma"`）。那会让所有差额断言退化成字符串比较，只验标志、不计覆盖。变体身份 = `(_calamity_theme_rule, _calamity)` 二元组。
5. 不改 `FLOOR_THEMES` 表结构、不改四灾祸 id、不加第五灾祸/第五通道、不新增图鉴条目/分母/实体。
6. 全仓禁止项判据（改完跑，输出必须**只有 1 条**）：

```
grep -rn "FLOOR_THEMES\.get(" scripts/
```

必须只有 `scripts/data.gd:495` 这一条（`theme_for_floor` 内部，合法）。9 处下标直取属既有豁免，不许新增：`boss.gd:70-71` / `boss2.gd:26-27` / `boss3.gd:30-31`（`phase_theme_index` 派生）、`game_state.gd:312` / `menu.gd:487` / `validate.gd:667`（全表遍历）。

---

## 二 三条时序陷阱（全实读，不是推测）

### 陷阱 1 🔴 换层时 `floor_num` 已经先自增了

```
game_main.gd:1505   Game.floor_num = nf
:1507   _clear_calamity_effects()      ← 此处现查 floor_num 已是「新层」
:1508   _calamity = ""
:1509   _apply_floor_theme()
:1516   _roll_calamity()
```

在 `_clear_calamity_effects()` 里现查主题 → 会「用新层主题还原旧层变体」→ **静默错还原，不报错、不崩、数值只是不对**。S21 同型事故：`frenzy` 曾因漏还原跨层固化整局（`:595-596` 留有注释）。

**纪律**：`_apply_calamity()` 开头把 `_calamity_theme_rule` 快照下来，clear 只读它。

### 陷阱 2 两条路径施加顺序相反

- `start_run`：`:381 _roll_calamity()` → `:385 _apply_floor_theme()`
- `next_floor`：`:1509 _apply_floor_theme()` → `:1516 _roll_calamity()`

生产走 `next_floor`。`start_run` 顺序反过来的危害只在 `SMOKE_JUMP_FLOOR` 跳层探针路径下可复现（`FLOOR_THEMES` 只覆盖 4–11 层，开局恒为 1 层无主题，生产不可达）。**本批不动这条顺序**（动它 = 改 E1 基线）。

推论（写进断言期望值，别搞反）：**压力层 + 残响枯竭，生产路径是 `minf(1.5, 0.7) = 0.7`**，saved = 1.5。不是「1.5 压过 0.7」。

### 陷阱 3 主题倍率只升不降（既有缺陷，本批**不修**，只入册）

`_apply_floor_theme()` 只复位地形系数（`:866-867 terrain_accel_mult / terrain_speed_mult`），**不复位 `enemy_speed_mult` 与 `diamond_mult`**：

```
:870-871  pressure → enemy_speed_mult = maxf(...,1.3);  diamond_mult = maxf(...,1.5)
:611      diamond_mult = 1.0        ← 只在 _roll_modifier()（开局）里复位
:607      enemy_speed_mult = 1.0    ← 同上
```

后果：**进入第一个压力层之后，整局剩下一路 `enemy_speed_mult = 1.3`、`diamond_mult = 1.5`**。这是既有行为，本批不许顺手改（改它 = 改全局难度曲线，且 `enemy_speed_mult` 与 modifier 的 1.25 共用一个变量，复位会抹掉 modifier）。

**对验收的直接影响**：`残响枯竭` 在生产里实际削减可能是 -53% 而非文案宣称的 -30%。→ 这是 §五 文案必须按**实值**显示的原因。

---

## 三 变体表（最终名单，8 格，A 组 6 + B 组 2）

**判据**：每格必须给出「今天数值」与「改后数值」且两者不等。只做到「语义上说得通」而不改数值的，不许上代码。

### A 组（必做，6 格常数）

| # | 组合（主题×灾祸） | 通道 | 今天 | 改后 | 玩家感受 |
|---|---|---|---|---|---|
| 1 | vein × frail | `max_hp` 削减比例 | 0.20（cut 2） | **0.10**（cut 1） | 往生脉逼你贴身单杀换残响，站桩硬扛反而亏 → 虚弱吃不透 |
| 2 | silent × frail | 同上 | 0.20 | **0.40**（cut 4） | 看不见就绕不开，薄血更难收场 |
| 3 | magma × scarce_ammo | `mag_cap_mult` | 0.5 | **0.7** | 火让你站不定，弹匣容量不再是瓶颈 |
| 4 | vines × scarce_ammo | 同上 | 0.5 | **0.65** | 藤替你堵路，不必按原量开火 |
| 5 | swamp × frenzy | `calamity_speed_mult` | 1.25 | **1.45** | 你陷着，它们却更快 |
| 6 | ice × frenzy | 同上 | 1.25 | **1.40** | 你收不住，它们不收 |

### B 组（A 组门控通过后再做，2 格时变）

| # | 组合 | 通道 | 今天 | 改后 | 玩家感受 |
|---|---|---|---|---|---|
| 7 | toxic × scarce_ammo | 每次毒 tick（3s）`mag_cap_mult` −0.1，下限 **0.3** | 固定 0.5 | **0.5→0.4→0.3** | 毒渗着，装填的手越来越抖 |
| 8 | magma × scarce_ore | 每次火 tick（0.5s）`diamond_mult` −0.05，下限 **0.5** | 固定 0.7 | **0.7→…→0.5** | 火催你走，能弯腰捡的次数越来越少 |

B 组是唯一「时间会让代价变深」的格，是这批真正意义上的 Dynamics；但它改的是 `_theme_damage_tick()` 公共路径，故单列，**失败不拖累 A 组交付**。

### 方向配比（自检）

轻 3（#1 / #3 / #4）｜重 5（#2 / #5 / #6 / #7 / #8）。**不许全重**——全重的话玩家只会记住「复合=更惨」，不会记住「两个系统在互相改写」。
主题覆盖：vein 1 / silent 1 / magma 2 / vines 1 / swamp 1 / ice 1 **/ toxic 1 / pressure 0**。pressure 由 §四 的 13 号格（零分支强制验）单独承载，不进本表。

---

## 四 代码落点

### 4.1 新增两个字段（`game_main.gd:121` 之后，紧跟 `_calamity_saved_mag_cap_mult`）

```gdscript
var _calamity_theme_rule := ""     # 复合变体身份：施加瞬间快照，clear 只读它（禁现查 floor_num）
var _calamity_frail_ratio := 0.2   # 本层实际虚弱比例（文案按实值显示，不写死 20%）
```

### 4.2 `_apply_calamity()`（`:556` 起）

开头两行先快照，**在 `match` 之前**：

```gdscript
_calamity_theme_rule = String(Data.theme_for_floor(Game.floor_num).get("rule", ""))
_calamity_saved_diamond_mult = Game.main.diamond_mult
_calamity_saved_mag_cap_mult = player.mag_cap_mult
```

`frail` 分支改为按变体取比例（`old_hp` 必须沿用原写法，`maxi(2, ...)` 的钳制逻辑一字不动）：

```gdscript
"frail":
    var old_hp: int = player.max_hp
    _calamity_frail_ratio = _frail_ratio()
    _calamity_frail_cut = maxi(1, int(round(old_hp * _calamity_frail_ratio)))
    player.max_hp = maxi(2, old_hp - _calamity_frail_cut)
    _calamity_frail_cut = old_hp - player.max_hp
    player.hp = mini(player.hp, player.max_hp)
    player.hp_changed.emit(player.hp, player.max_hp)
```

新增一个纯函数（就放在 `_calamity_name()` 之上）：

```gdscript
func _frail_ratio() -> float:
    match _calamity_theme_rule:
        "vein": return 0.1
        "silent": return 0.4
    return 0.2
```

`frenzy`：

```gdscript
"frenzy":
    match _calamity_theme_rule:
        "swamp": Game.calamity_speed_mult = 1.45
        "ice": Game.calamity_speed_mult = 1.4
        _: Game.calamity_speed_mult = 1.25
```

`scarce_ammo`：

```gdscript
"scarce_ammo":
    match _calamity_theme_rule:
        "magma": player.mag_cap_mult = 0.7
        "vines": player.mag_cap_mult = 0.65
        _: player.mag_cap_mult = 0.5
    player.mag_changed.emit(player.mag(), player.mag_cap())
```

`scarce_ore` 不变（仍是 `minf(..., 0.7)`）。B 组的 magma 递减走 §4.4。

### 4.3 `_clear_calamity_effects()`（`:581` 起）

**还原分支一个字都不改**（`:583-596` 现有逻辑已正确）。只在 `:597` 的 `if _calamity != "":` 块里补两行：

```gdscript
if _calamity != "":
    _calamity_frail_cut = 0
    _calamity_saved_diamond_mult = 1.0
    _calamity_saved_mag_cap_mult = 1.0
    _calamity_theme_rule = ""      # 新增：变体身份随灾祸一起失效
    _calamity_frail_ratio = 0.2    # 新增
```

🔴 **不许**在还原分支里查 `Game.floor_num` 或 `_theme_rule`。`_theme_rule` 在 clear 时恰好还是旧值，写成「能跑」纯属调用顺序巧合，只要有人调整 `:1509` 的位置就会静默错还原。

### 4.4 B 组：tick 钩子

插在 `_theme_damage_tick()` 开头、`is_instance_valid(player)` 之后、SMOKE 分支之前（`game_main.gd:954` 是 `func` 行；`:962` 非 SMOKE 分支会 `player.take_damage(1, ...)`，探针每次驱动 tick 前后必须存取 `player.hp` 再回填）。用 `snappedf` 收敛浮点累加，否则 `0.5-0.1*2` 是 `0.30000000000000004`，`== 0.3` 会假红：

```gdscript
if _calamity == "scarce_ammo" and _theme_rule == "toxic":
    var mc_new := maxf(0.3, snappedf(player.mag_cap_mult - 0.1, 0.001))
    if not is_equal_approx(mc_new, player.mag_cap_mult):
        player.mag_cap_mult = mc_new
        player.mag_changed.emit(player.mag(), player.mag_cap())
elif _calamity == "scarce_ore" and _theme_rule == "magma":
    var dm_new := maxf(0.5, snappedf(diamond_mult - 0.05, 0.001))
    diamond_mult = dm_new
```

B 组两个格的还原仍走既有 `:590` / `:594` 的 saved 还原，**不需要新增还原代码**——这是选它们的重要理由。

### 4.5 文案按实值显示（`:547-553`）

现状是写死的，变体上线后 `frail` 会显示「-20%」而实际 -40%，`scarce_ammo` 会显示「弹匣减半」而实际 -35%。**必须改成读实值**，但**族名首词逐字保留**（`虚弱`/`狂乱`/`弹药荒`/`残响枯竭`）——`player.gd:1461` 断言层签含「虚弱」，`player.gd:1503` 断言无灾祸层主行为 `层签 · 往生脉◆ ｜ 灾祸：无`。

```gdscript
func _calamity_name(id: String) -> String:
    match id:
        "frail":
            return "虚弱（生命上限 -%d%%）" % int(round(_calamity_frail_ratio * 100.0))
        "frenzy":
            return "狂乱（敌人加速 %d%%）" % int(round((Game.calamity_speed_mult - 1.0) * 100.0))
        "scarce_ammo":
            return "弹药荒（弹匣 -%d%%）" % int(round((1.0 - player.mag_cap_mult) * 100.0))
        "scarce_ore":
            var base: float = maxf(_calamity_saved_diamond_mult, 0.001)
            return "残响枯竭（残响掉落 -%d%%）" % int(round((1.0 - 0.7 / base) * 100.0))
    return id
```

三个调用点（`:540` 播报 / `:541` 横幅 / `:1166` 层签）**全在 `_apply_calamity()` 之后**，读到的都是施加后的即时值，无需改调用处。字数与现状基本持平（`虚弱（生命上限 -40%）` 与原串等长），层签宽度无新增溢出风险。

### 4.6 13 号格（零分支，但必须验）

`pressure × scarce_ore`：两类**共用同一通道 `diamond_mult`**（`pressure :871 maxf(...,1.5)` ↔ `scarce_ore :577 minf(...,0.7)`）的唯一一格。生产路径落点 `0.7`、saved `1.5`、clear 后还原 `1.5`。**不写分支**，但它证明「主题加成的 1.5 被灾祸整条砍掉」，是本批最有说服力的一条差额。

---

## 五 探针规格

开关挂进 `game_main.gd:235-243` 既有 env 判定链，新增 `SMOKE_CAL_THEME`。**不许**往 `_smoke_fingerprint()`（`:318-333`）里加任何东西。

### 5.1 打印纪律（这条比断言本身重要）

`Dev.check()` 只在失败时打印（`dev_log.gd:29-32`）。所以 `[ERR]=0` **不能**证明断言执行过——探针只要在第一条断言前 `return`，日志一样干净。

强制三条：
1. 入口**无条件**打印 `[SMOKE-CAL-THEME] entry floor=%d calamity=%s`。
2. **每条断言后无条件**打印 `[SMOKE-CAL-THEME] #NN <name> measured=%s expect=%s`。
3. 末尾无条件打印 `done checked=%d declared=%d`，并用 `Dev.check(checked == declared, ...)` 自校验。

### 5.2 三段式（缺一段不算通过）

每格都跑：**段1 施加 → 段2 换层精确还原 → 段3 再施加幂等**。只验段1 = 没测。

段 2 的换层构造铁律：`floor_num` 的增量**必须让 rule 真的改变**（4→5 / 6→7 / 8→9 / 10→11）。🔴 **禁用 4→12**——回卷后 rule 相同，写错的实现照样能蒙过，变异测试会假绿。

同帧差额对照（§四 13 号格与 ⑤3 用）：先把四通道手工拉到同一基线（`max_hp=10, mag_cap_mult=1.0, diamond_mult=1.0, calamity_speed_mult=1.0`），再逐格施加取差值。`player.gd:746` 的注释已实证过「多探针并发污染导致间歇假红」，照抄那个做法。

### 5.3 断言分组与绝对条数（**不许写公式，逐条数**）

| 组 | 内容 | A 组交付 | B 组交付 |
|---|---|---|---|
| ① 基线通道 | 无主题层（floor 1–3）下 4 个灾祸的基线值 | 4 | 4 |
| ② 三段式·基线 | 4 个基线灾祸 × 3 段 | 12 | 12 |
| ③ 三段式·变体 | 6 常数格 × 3 段 = 18；B 组再加 2 时变格 × 5 段（施加 / 递减单调 / 下限钳制 / 还原 / 再施加）= 10 | 18 | 28 |
| ④ 覆盖补全 | 换层时序 4 + 幂等 4 + 零分支扫描 1（聚合断言；A 阶段扫 26 格、B 阶段 24 格，含 13 号格，格数只影响打印行数） | 9 | 9 |
| ⑤ 旁证 | 见 §5.4 明细 | 13 | 13 |
| ⑥ 快照纪律 | 结构 4 + 行为 2 | 6 | 6 |
| ⑦ 文案实值 | 4 个灾祸各 1 条：`_calamity_name()` 里的百分比与实测通道值一致 | 4 | 4 |
| **合计** | 4+12+18+9+13+6+4 / 4+12+28+9+13+6+4 | **66** | **76** |

`declared` = 66（A 组门控）/ 76（B 组完成）。**这两个数是死数，探针里写死，不许用 `k` 现算。**

### 5.4 ⑤ 组 13 条明细（一条都不许吞）

| 编号 | 断言 | 类别 |
|---|---|---|
| ⑤1 | 无主题层（1–3 层）施加后 == 基线 | 验效果型 |
| ⑤2 | `_calamity == ""` 时 clear 完全不碰倍率（复验 `player.gd:753-761`） | 验效果型 |
| ⑤3 | **差额正**：`scarce_ammo` 在 magma 实测 **0.70** ≠ 在 ice 实测 **0.50**（两格初值即不同，A 阶段就成立）。🔴 **不许用 scarce_ore 做这条** —— `#8` 的差异来自 tick 累积，apply 瞬间 magma 与 ice 都是 `minf(1.0,0.7) = 0.7`，两值相等，A 阶段必假红 | 验效果型，本批唯一直接证明「复合生效」的断言 |
| ⑤4 | 差额反：magma 层 frail 削减 ≠ frenzy 加速（通道不同） | 验效果型 |
| ⑤5 | 探针窗口内 `Game.rng.state` 不变 | 验效果型（附属性） |
| ⑤6 | `Data.FLOOR_THEMES.size() == 8` | ⚠️ 常量自比较，须标注 |
| ⑤7 | 层签文本含变体实值。楼层对照写死：**floor 4 (vein) 上 frail 满 `虚弱（生命上限 -10%）`；floor 7 (silent) 上满 `-40%`**。🔴 `magma × frail` **不是变体**（floor 8 上 frail 是基线 `-20%`），别拿它当靶子 | 验效果型（渲染） |
| ⑤8 | `_calamity_name()` 对四个 id 均不返回原始 id | 验效果型 |
| ⑤9 | `next_floor` 路径 clear 时 `_calamity` 仍为旧值（`:1507` 早于 `:1508`） | 验效果型 |
| ⑤10 | 净化路径 clear 时 `_calamity` 仍为旧值（`:2224` 早于 `:2225`） | 验效果型 |
| ⑤11–13 | `is_instance_valid(player)` / `dungeon != null` / `_smoke` 已开 | 🔴 前提守卫型恒过，须标注 |

### 5.5 ⑥ 组：两个变异靶子

| 编号 | 断言 | 打的是哪个变异 |
|---|---|---|
| ⑥1 | 施加后 `_calamity_theme_rule` == 目标层 rule 字面量 | — |
| ⑥2 | 换层 clear 后 `_calamity_theme_rule == ""` | **变异 D 正面靶子**（写错实现会残留新层或旧层 rule） |
| ⑥3 | 净化 clear 后 `_calamity_theme_rule == ""` | — |
| ⑥4 | `scarce_ore@pressure` 在 6→7 换层后 `diamond_mult` 精确还原 == 1.5 | **变异 D 行为靶子** |
| ⑥5 | 净化路径 6 层 `diamond_mult` 精确还原 == saved | — |
| ⑥6 | `floor_num = 12` 施加后 `_calamity_theme_rule == "vein"`（回卷），跑完必须还原 `floor_num` | **变异 D′ 正面靶子** |

⑥1/⑥2/⑥3/⑥6 是**只验标志**，必须标注，不许计入「施加/还原」覆盖。

### 5.6 ④ 组零分支扫描怎么写

算术先对齐，这一步最容易口径打架：

- 8 主题 × 4 灾祸 = 32 格（主题层号写死：4 vein / 5 toxic / 6 pressure / 7 silent / 8 magma / 9 ice / 10 swamp / 11 vines）
- 8 格写了变体分支（A 组 6 + B 组 2）→ 剩 **24 格零分支**
- 这 24 格全扫：**B 组完成时 24 格；A 组阶段 26 格**——A 阶段 `#7`/`#8` 还没上代码，那两格此刻也走 default，必须一起扫，否则正好漏掉最可能被 fall-through 踩到的两格
- 其中 23 格期望 = 基线字面量；**1 格（`pressure × scarce_ore`，§4.6 的 13 号格）期望 = 施加 0.7 / 还原 1.5**，见下

🔴 注意 B 组两格**本身就带分支**，不在那 24 格里，**不许再扣一次**（我第一版口径写成「20 格」就是重复扣了 B 组两格，已改）。

13 号格必须走真实生产路径，不能只置位：`floor_num = 6` → 调 `_apply_floor_theme()`（pressure 把 `diamond_mult` 拉到 **1.5**）→ `_calamity = "scarce_ore"` → `_apply_calamity()` 断言 **0.7** → `_clear_calamity_effects()` 断言 **1.5**。这一格是全批最有说服力的事实：主题承诺 1.5，灾祸 `minf(1.5, 0.7)` 砍成 0.7，相对承诺 **−53%**。⑥4 验的是换层时序与精确还原，**不验施加值**，两条不可互相顶替。

其余 23 格：设 `floor_num` + `_calamity`，apply 后与基线字面量（`cut 2 / max_hp 8`、`mag_cap_mult 0.5`、`calamity_speed_mult 1.25`、`diamond_mult 0.7`）比，clear 后与还原值比。断言聚合成 1 条 `Dev.check(bad.is_empty(), ...)` 并打印 `bad` 全表。聚合断言只负责「有没有踩」，逐格打印负责「执行过」。

🔴 **扫描行的打印前缀不许用 `#`**。若沿用 `#NN`，`grep -c "^\[SMOKE-CAL-THEME\] #"` 会把 23/25 行扫描结果算进断言条数 → `checked == declared` 自校验直接失效、门控永久假绿。扫描行格式固定为：

```
[SMOKE-CAL-THEME] scan i=%d cell=%s applied=%s cleared=%s
```

与断言行 `#NN` 分流。

---

## 六 门控（改完必跑，四条全绿才算完）

```
# 1 静态
python3 -c "print(open('scripts/game_main.gd',encoding='utf-8').read().count('theme_for_floor'))"   # 期望 2（原 1 + 新增 1）
grep -rn "FLOOR_THEMES\.get(" scripts/          # 期望只有 data.gd:495 一条
grep -rn "Game\.rng\|_floor_rng" scripts/game_main.gd | wc -l   # 与批前基线逐字相同

# 2 启动期校验
<godot> --headless --path . -s scripts/validate.gd    # EXIT 0，[ERR] 0

# 3 E1 确定性（同 seed 三跑）
#    只比 [SMOKE-META] fingerprint 行，禁整体日志 cmp，禁 SMOKE_DAILY
#    批前基线：git checkout aba6ccb -- scripts/ → 跑 → git checkout HEAD -- scripts/

# 4 探针
SMOKE_CAL_THEME=1 <godot> --headless --path . ...
#    grep -c "^\[SMOKE-CAL-THEME\] #" 日志 == 66（A 组）/ 76（B 组完成）
#    grep -c "\[ERR\] cal_theme"       日志 == 0
#    两条同时成立才 PASS。只做第二条 → 提前 return 的探针能拿满分，等于没测。
```

**变异测试自检（交付前自己先做，不要丢给核验侧）**：把 §4.2 的快照行临时改成 `Data.theme_for_floor(Game.floor_num)` 的**错版**（写在 `_clear_calamity_effects()` 里现查），期望 ⑥2 + ⑥4 + ④ 换层 4 条一起红；改回来必须全绿。这一刀是「不改会红」的唯一实证。

---

## 七 不做清单

- 不修 §二 陷阱 3 的主题倍率泄漏（`enemy_speed_mult` / `diamond_mult` 只升不降）。它要单独评估难度曲线，且与 modifier 共用变量，顺手复位会连带抹掉 modifier 的 1.25。
- 不动 `SMOKE_JUMP_FLOOR` 跳层路径的施加顺序（陷阱 2），动了就改 E1 基线。
- 不修 `boss.gd:61` / `boss2.gd:26` 的 C-style `%`（`boss3.gd:29` 已用 `posmod` 修过并留注释；正常层 ≥4 两式等价，只在强制低层生成才踩）。
- 不加第五灾祸、不改 15% 触发率（改它 = 改 `Game.rng` 消耗次数 = E1 指纹漂移）。
- 本批**不推送**。

---

## 八 交付物

1. `scripts/game_main.gd` 改动（字段 2 + 函数 2 改 1 新增 + tick 钩子）。
2. 探针代码（挂 `SMOKE_CAL_THEME`）。
3. 门控四条命令的原始输出（存文本，不要截图）。
4. 一句话：`declared=66` 还是 `76`，以及 `checked` 实测值。
