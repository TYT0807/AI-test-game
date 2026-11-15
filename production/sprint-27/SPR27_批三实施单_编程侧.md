# SPR27 批三实施单（编程侧）

> **本单是批三唯一权威。** 与 `SPR27_批三方向评估.md` / `SPR27_批三验证口径.md` 冲突时以本单为准。
> 所有行号实读于 `ece249d`（`game_main.gd` 3249 行 / `slug.gd` 489 行）。批三实施后必漂移，**动手前逐条复核**。

---

## 🔴 首批必读（不读完不许动手）

**1. `:815` 与 `:1053` 的期望值必须同时改，不许分批。**
这两条是**同一段构造**（6 层 pressure → scarce_ore → 换到 7 层 → 再 `_apply_floor_theme()` → 断言 `diamond_mult == 1.5`）。只改 `:1053` 不改 `:815`，后果不是「少改一条」，而是 **A 组红在 ④ 上、而红的样子看起来像 C1 写错了**。你会去动探针，越动越糟。

**2. 改完期望值必须补 ⑮1/⑮2，否则等于拆掉一个检测器。**
C1 落地后上游多了一次 `_apply_floor_theme()`，它无条件把 `diamond_mult` 复位成 `_mod_diamond_mult`。于是**无论 `_clear_calamity_effects()` 有没有正确还原 1.5，末值都是复位后的值，改后的断言照样绿**。批一靠那个 1.5 才抓得到「clear 里现查新层主题」（变异 D）。**修一个 bug 顺手拆掉检测器的靶子**，是本批最容易漏的一手。

**3. 复位必须写在 `th.is_empty()` 早退之前。**
实际结构：`:1456 _theme_rule = ""`、`:1457 _theme_t = 0.0`、`:1458 var th := Data.theme_for_floor(...)`、`:1459 if th.is_empty():`、`:1463 return`。复位两行插在 **`:1457` 之后、`:1458` 之前**。写在 `:1463 return` 之后 → 从 6 层跳回 1–3 层仍然残留，⑫ 会红。

**4. pressure 分支的 `maxf` 一字不改。**
`:1472 enemy_speed_mult = maxf(enemy_speed_mult, 1.3)`、`:1473 diamond_mult = maxf(diamond_mult, 1.5)`。改成乘法（`barren 0.7 × 1.5 = 1.05`、`swarm 1.5 × 1.5 = 2.25`）会直接改平衡。

**5. 「期望写 1.0」有前置条件：进 ④ / ⑥4 段之前必须先把 `_mod_*` 归一到 1.0。**
C1 之后第 7 层复位出的是 `_mod_diamond_mult`，**不是 1.0**。写死 1.0 而不管 `_mod_*`，在 `barren` / `swarm` 局（合计约 **28.6%**）会**红在正确实现上**——换 seed 就绿，最容易被误判成「探针不稳定」。归一做法见 §4。

---

## 1. 批三做两件事（都不加实体）

| 项 | 现状（实读） | 病 |
|---|---|---|
| **C1** | `_apply_floor_theme()`（`:1455`）只复位地形系数（`:1468-1469`），从不复位 `enemy_speed_mult` / `diamond_mult`。二者只在 `_roll_modifier()`（`:1206`）`:1209` / `:1213` 置 1.0，随后 rage 1.25 / barren 0.7 / swarm 1.5 | 进过第一个压力层后，两个倍率**整局只升不降**。`barren`（残响 ×0.7）与 `swarm`（残响 ×1.5）在 6 层之后永久失效，玩家感知为「这局后期残响突然正常了 / 变多了」 |
| **C2** | `slug.gd:236`（`_move_with`）三乘子齐全；`:216`（defuser 冲向炸弹）、`:298`（`_ai_echo` 追痕迹）、`:304`（`_ai_echo` 游走/突进）**缺 `Game.calamity_speed_mult`** | 批一加了「狂乱加速」这个灾祸，但三类敌人对它免疫。玩家在狂乱层看到 defuser 和 echo 慢吞吞地走，感知为「这灾祸是假的」 |

两项都**零新增实体、零新增表、零新增 rng**。

---

## 2. C1 实施（3 处改动）

### 2.1 新增两字段

在 `game_main.gd` 既有 `_calamity_*` 字段群（`:118-125`）之后：

```gdscript
var _mod_enemy_speed_mult := 1.0   # S27 批三：modifier 贡献的敌速倍率（与主题贡献分离）
var _mod_diamond_mult := 1.0       # S27 批三：modifier 贡献的残响倍率（同上）
```

**分离的意义**：`enemy_speed_mult` / `diamond_mult` 从此是「live 值 = modifier 贡献 + 主题贡献」的合成结果，`_mod_*` 单独持有 modifier 那一份。主题复位只回落到 `_mod_*`，不抹掉 modifier。这正是批一处理狂乱的范式（狂乱没乘进 `enemy_speed_mult`，而是新开 `Game.calamity_speed_mult`），照抄即可。

### 2.2 新增纯函数（放在 `_roll_modifier()` 之前）

```gdscript
## S27 批三：modifier → (敌速倍率, 残响倍率)。纯函数：零 rng、零副作用、不读成员。
## 两个倍率的唯一来源，match 里不再写字面量（防"两处来源各自漂移"）。
func _modifier_mult_pair(m: String) -> Vector2:
	match m:
		"rage":   return Vector2(1.25, 1.0)
		"barren": return Vector2(1.0, 0.7)
		"swarm":  return Vector2(1.0, 1.5)
		_:        return Vector2(1.0, 1.0)
```

覆盖全集实读（`data.gd:271-278`）：`none / rage / barren / overload / glass / swarm`，共 6 个，无第 7 个。`none` 权重 4（`MODIFIER_WEIGHTS :279`）是最常见一档，正因如此它最容易掉进默认分支而无人发现——⑯4 必须显式验它。

### 2.3 改 `_roll_modifier()`（`:1206`）

插在 `:1213 diamond_mult = 1.0` 之后、`match modifier:`（`:1214`）之前：

```gdscript
	var pair := _modifier_mult_pair(modifier)
	_mod_enemy_speed_mult = pair.x             # 先落 _mod_*
	_mod_diamond_mult = pair.y
	enemy_speed_mult = _mod_enemy_speed_mult    # live 再从 _mod_* 读
	diamond_mult = _mod_diamond_mult
```

🔴 **然后必须删掉 `match` 里这三行**（是「必须删」，不是「可以删」）：

- `:1216 enemy_speed_mult = 1.25`（rage）
- `:1219 diamond_mult = 0.7`（barren）
- `:1229 diamond_mult = 1.5`（swarm）

**为什么必须删**：留着这三行，倍率就有**两个来源**——纯函数一个、match 字面量一个。今天两者数值相同，所以测试全绿；但任何一次只改一边，`_mod_*` 与 live 值就会分叉，而 `_apply_floor_theme()` 下次复位会把 live 拉回 `_mod_*` → **「本局看起来生效、离压后突然变回另一个值」**，正是 C1 想消灭的那类 bug 换了个位置复现。删掉之后倍率唯一来源是纯函数。

「先写 `_mod_*`、live 再从 `_mod_*` 读」这个顺序也不是风格偏好：这样 live 值没有第二个可写来源。

**以下副作用全部留在 `_roll_modifier()` 原位，禁止搬进纯函数**（搬进去就把副作用面也扩大了）：

- `:1217 rage → enemy_hp_mult = 0.85`
- `:1220 barren → Game.add_diamonds(10)`
- `:1222-1224 overload → skill_cd_mult / max_hp / hp 夹取`
- `:1226-1227 glass → crit_chance / speed_base`

**diff 形状应为：新增 1 函数（6 行）+ 1 处插块（5 行）+ 3 行删除。**展开多于这个形状就说明你动到了不该动的地方。

### 2.4 改 `_apply_floor_theme()`（`:1455`）

插在 `:1457 _theme_t = 0.0` 之后、`:1458 var th := ...` 之前：

```gdscript
	# S27 批三：主题倍率先回落到 modifier 贡献（复位必须在 th.is_empty() 早退之前，
	# 否则 1–3 层走早退分支、复位不执行，离压残留）
	enemy_speed_mult = _mod_enemy_speed_mult
	diamond_mult = _mod_diamond_mult
```

`match _theme_rule:` 段（`:1470` 起）只保留 pressure 的两行 `maxf`，其余一字不动。

---

## 3. C2 实施（3 处补乘子）

`slug.gd` 三处各补 `* Game.calamity_speed_mult`，**位置与 `:236` 对齐**（跟在 `Game.enemy_speed_mult` 后面）。

| 行 | 现状 | 改后 |
|---|---|---|
| `:216` | `... * speed * 1.25 * Game.enemy_speed_mult * _slow_mult + _knock` | `... * speed * 1.25 * Game.enemy_speed_mult * Game.calamity_speed_mult * _slow_mult + _knock` |
| `:298` | `... limit_length(speed * chase_mult * Game.enemy_speed_mult * _slow_mult)` | `... limit_length(speed * chase_mult * Game.enemy_speed_mult * Game.calamity_speed_mult * _slow_mult)` |
| `:304` | `... dir * speed * mult * Game.enemy_speed_mult * _slow_mult + _knock` | `... dir * speed * mult * Game.enemy_speed_mult * Game.calamity_speed_mult * _slow_mult + _knock` |

`:236 _move_with` **已有**该乘子，不要动。

**只加一项、不改原有项。** ⑭ 就是查这个的。

---

## 4. `_mod_*` 归一纪律（🔴 不做这个，新期望会变成 flaky 门）

C1 之后，无 pressure 分支的层（如第 7 层 silent）把 `diamond_mult` 复位成 **`_mod_diamond_mult`**，而它取决于本局真实抽到的 modifier：

| 本局 modifier | `_mod_diamond_mult` | 第 7 层复位后 |
|---|---|---|
| `none` / `overload` / `glass`（8/14） | 1.0 | 1.0 |
| `barren`（2/14） | 0.7 | **0.7** |
| `swarm`（2/14） | 1.5 | **1.5** |

所以「:`815`/`:1053` 写死 1.0」在约 **28.6%** 的局里会红在正确实现上。

**规定做法（四步，别自创）**：

1. 进 ④ 段 / ⑥4 段**之前**，显式置 `_mod_enemy_speed_mult = 1.0`、`_mod_diamond_mult = 1.0`（覆盖本局真实值）。
2. 段内期望按 `_mod_* == 1.0` 写死（`:815` / `:1053` 写 **1.0**）。
3. **出口还原块**（`:1181` 起）从**探针入口快照**恢复这两个字段——**不许还原成 1.0**，那会污染本局真实 modifier，属于静默改状态。
4. 归一化必须是**段级**的：④ 段与 ⑥4 段各自归一，互不依赖执行顺序。

**归一化范围要收住，别全局铺开**（铺开会牵动批一已成立的断言）：

| 段 | 归一？ | 理由 |
|---|---|---|
| ④ 段（`:815` 及其上游） | **要** | 第 7 层复位出的是 `_mod_diamond_mult` |
| ⑥4 段（`:1053`） | **要** | 同上 |
| ④c 的 13 号格 | **不要** | 三步读数全被 `maxf` 掩蔽，与本局 modifier 无关 |
| ⑧ / ⑩ / ⑪ | **要**（本来就是构造的一部分） | 必须精确控制 `_mod_*` 才验得出「贡献有没有被抹掉」 |
| ①–③ / ⑤ / ⑦ | **不要** | 不读这两个字段 |

一句话判据：**只有「读数落在无 pressure 分支的层上、且读的是这两个倍率」的地方才需要归一。**

---

## 5. 探针规格

### 5.1 条数写死

`:650 const _CT_DECLARED := 76` → 改 **103**。分组绝对条数，一条不多一条不少：

| 组 | 内容 | 条数 |
|---|---|---|
| ①–⑦ | 批一既有（其中 **2 条期望值变更**，但不改条数） | 76 |
| ⑮ | 换层还原真值前移（④ ore / ⑥4 各 1） | 2 |
| ⑧ | 离压回落（7 主题 + pressure 自身） | 8 |
| ⑨ | `_mod_*` 接线巡检（只验标志） | 1 |
| ⑩ | modifier × pressure（**只对乘法回归有效**） | 3 |
| ⑪ | modifier × 非压力层（**C1 正面靶子**） | 3 |
| ⑫ | 无主题层早退 | 1 |
| ⑬ | C2 四路径 | 4 |
| ⑭ | C2 零回归（聚合） | 1 |
| ⑯ | modifier 映射覆盖（纯函数直调 6 档） | 4 |
| **合计** | | **103** |

逐行加一遍：76 → 78（⑮²）→ 86（⑧8）→ 87（⑨1）→ 90（⑩3）→ 93（⑪3）→ 94（⑫1）→ 98（⑬4）→ 99（⑭1）→ **103（⑯4）**。

### 5.2 各组构造

**⑮（2）**——在 `_ct_floor_advance(7)` 之后、`_calamity = ""` + `_apply_floor_theme()` **之前**读数。此时 `_calamity` 仍是旧值、clear 刚跑完、主题还没换，`diamond_mult` 必须是 **1.5**。
⑮ 可以放心写死 1.5，**不受 §4 归一影响**：pressure 的 `maxf(_mod_diamond_mult, 1.5)` 在 `_mod_diamond_mult ≤ 1.5` 时恒等于 1.5（swarm 的 1.5 也一样），所以 `saved` 恒 1.5。**这是唯一一处「写死数值仍安全」的地方，理由要记住：maxf 把 modifier 的影响吃掉了。**

**⑧（8）**——构造统一为：`_mod_* = 1.0` → `floor_num = 6` → `_apply_floor_theme()`（1.5 / 1.3）→ `floor_num = <目标层>` → `_apply_floor_theme()` → 读两值。
目标层 4/5/7/8/9/10/11（7 条）期望 `1.0 / 1.0`；目标层 6（1 条）期望 `1.5 / 1.3`（压力层自身幂等）。**每条同时断两个值。**

**⑨（1）**——读当前 `modifier`，用探针内的**字面量表**（不读 `Data`，防同源）判期望，断言 `_mod_*` 与该表一致。它**不验映射对不对**（⑯ 管），只验「真实调用点有没有把返回值接上」。

**⑩（3）**——`_mod_enemy_speed_mult=1.25` + pressure → `enemy_speed_mult == 1.3`；`_mod_diamond_mult=0.7` + pressure → `1.5`；`_mod_diamond_mult=1.5` + pressure → `1.5`。
🔴 **必须在注释里写明这 3 条抓不到什么**：`maxf` 会掩蔽。漏写 `_mod_*` 时字段恒 1.0，`maxf(1.0,1.3)=1.3`、`maxf(1.0,1.5)=1.5`——**与写对时逐值相同**。所以⑩**只对「把 maxf 改成乘法」这一种错误有效**，统计有效覆盖时按 0 计或单列「乘法回归」一类，**不许并入 C1 正面证据**。

**⑪（3，C1 正面靶子）**——`_mod_enemy_speed_mult=1.25` → **第 7 层 silent** → 断言 `1.25`；`_mod_diamond_mult=0.7` → 第 7 层 → `0.7`；`_mod_diamond_mult=1.5` → 第 7 层 → `1.5`。选**非压力层**是关键：压力层上 maxf 会把差异吃掉。

**⑫（1）**——`floor_num = 6` → apply（1.5/1.3）→ `floor_num = 3` → apply → 断言 `== _mod_*`。**专打「复位写在早退之后」这种错法**，⑧ 覆盖不到（⑧ 目标层都在 4–11）。

**⑬（4）**——`var s := SlugScript.new()`、`entities.add_child(s)`、`s.setup("rusher", 1, 8)`、`s._knock = Vector2.ZERO`，每测一次前重置。同一实例上把 `Game.calamity_speed_mult` 在 `1.0` / `1.25` 间切换，**比值必须恰好 1.25**。

| # | 路径 | 触发条件 |
|---|---|---|
| ⑬1 | defuser 冲向炸弹（`:216`） | `s.defuser = true`；假 `BombScript` 加入 `"bombs"` 组、置于 ~100px（**不许 <18px**，否则触发 `defuse()`） |
| ⑬2 | echo 追击（`:298`） | `player.trail` 至少 1 点；`s._echo_t = 0.0`（< `mirror_time` 2.5） |
| ⑬3 | echo 游走-爬行（`:304` creep） | `s._echo_t = 3.0` → `fmod(3,3)=0` ≤ 2.5 → creep |
| ⑬4 | echo 游走-突进（`:304` dash） | `s._echo_t = 2.9` → `cycle=2.9 > 3.0-0.5` → dash |

两条防假绿硬要求：

1. 🔴 **`v0 == 0.0` 必须直接判红，不许静默跳过。** 目标缺失时两值都可能为 0，`0/0` 行为不可依赖，而「两值都为 0」会让比值断言恒过 → **假绿**。固定写法：`_ct_assert(v0 > 0.0, "⑬2 echo-chase 基底速度", v0, ">0")`，失败信息打 **`探针未造出目标`**。**严禁 `if v0 > 0: assert(...)`** —— 这是最典型的假绿写法：目标没造出来时它什么都不做，探针照绿。
2. 比值用 `is_equal_approx(v1/v0, 1.25)`，打印 4 位小数，**禁 `== 1.25`** 浮点直比。

**⑭（1，聚合）**——csm 恒 1.0 下把 `Game.enemy_speed_mult` 从 1.0 切到 1.25，⑬ 的四处读数（⑬1–⑬4）各自也必须恰好放大 1.25。证明补 csm 时没碰坏既有的 `enemy_speed_mult` / `_slow_mult` 因子。任一不满足 → `bad` 表非空。
（注意：`speed` 在 `setup()` 时已烘焙，live 改 `Game.enemy_speed_mult` 不会改 `speed`，所以比值只有显式那一项贡献 = 1.25，不会出现平方。）

**⑯（4）**——`var pair: Vector2 = _modifier_mult_pair(<modifier>)`，**只读返回值**，不碰 `player` / `Game` / rng，所以**不属于**下面的禁调项（禁的是 `_roll_modifier()`）。

| # | 入参 | 期望 |
|---|---|---|
| ⑯1 | `"rage"` | `(1.25, 1.0)` |
| ⑯2 | `"barren"` | `(1.0, 0.7)` |
| ⑯3 | `"swarm"` | `(1.0, 1.5)` |
| ⑯4 | `"none"` / `"overload"` / `"glass"` **逐个过一遍**（1 条聚合） | 三者均 `(1.0, 1.0)` |

**⑯ 必需而 ⑨ 替代不了**：⑨ 每局只看得到抽中的那 1 个 modifier（`none` 最常见），⑯ 一次覆盖全部 6 档且不依赖随机。**诚实边界：⑯ 验映射表、验不到「`_roll_modifier()` 有没有调用它」，那一层由 ⑨ 兜——两者合起来才闭环，各自单独都不完整。**

### 5.3 探针纪律（沿用批一 + 本批四条）

1. **无条件打点**：入口 `[SMOKE-CAL-THEME] entry ...`；每条断言后 `#NN`；末尾 `done checked=%d declared=%d` 并 `Dev.check(checked == declared)`。
2. 🔴 **扫描 / 多值打印行不许用 `#NN`**：⑧ 的 8 组、⑬ 的成对读数、⑯4 的三档、`bad` 表一律用 `[SMOKE-CAL-THEME] v ...` / `... pair ...` 前缀。批一踩过：混用后 `grep -c` 会把从属行算进断言数，自校验永久假绿。
3. 🔴 **探针禁止调 `_roll_modifier()`**：它内部走 `Data.roll_modifier()` → `Game.rng.randi_range` → **消耗 rng**，一调就撞 ⑤5 的 `Game.rng.state` 不变断言（`:972`）。要构造 modifier 场景，⑩/⑪ **直接写 `_mod_*` 两字段**、⑯ **直接调纯函数**——两条合规路径，不要绕道图省事。
4. 🔴 **`v0 == 0` 一律判红，不许 if 包裹断言**（见 ⑬）。
5. **`_apply_floor_theme()` 有副作用**：每次都 `Game.mark_codex("themes", rule)`（`:1465`）。探针已多次在调（④/13 号格/⑥），会往图鉴登记主题——**既有行为，非批三引入**，但别据此认为「探针无副作用」。
6. **出口还原**：⑬ 新建的 slug、`"bombs"` 组里的假炸弹、`player.trail` 注入点、`_mod_*` 两字段，都必须进既有出口还原块（`:1181` 起）。`_mod_*` 的还原值取**探针入口快照**，别还原成 1.0。

### 5.4 分类闭合（须在报告里重算一遍）

`103 = 覆盖 88（批一 62 + 本批 26）+ 渲染 6 + 常量自比较 1 + 前提守卫恒过 3 + 只验标志 5（批一 4 + ⑨）`。

本批新增 27 条的分类：**验效果型 26**（⑮2、⑧8、⑩3、⑪3、⑫1、⑬4、⑭1、⑯4）+ **只验标志 1**（⑨）。

四条诚实声明（核验方会逐条引用）：
① ⑩ 三条得分很低，只对「maxf 改乘法」有效。
② ⑨ 是只验标志、不计入覆盖，且每局只覆盖 1/6 个 modifier，**⑨ 绿不代表映射表对**。
③ ⑯ 验映射表、验不到调用点；⑨ 验调用点、验不到映射表。
④ ⑬ 必须带 `v0 > 0` 前置断且 `v0==0` 判红。

---

## 6. 门控与变异

### 6.1 门控

PASS = `grep -c "^\[SMOKE-CAL-THEME\] #"` == **103** **且** `grep -c "\[ERR\] cal_theme"` == 0，两条同时成立。

另必跑：`validate.gd` 全过；批一既有 `SMOKE_*` 探针全过；E1 三跑对照。

**E1 是越界探针，不是预期重定。** C2 只改移动表达式、不抽 rng，指纹（`rooms=` 坐标 + `kinds=`）**理论上必须逐字不变**。基线取法：`git checkout ece249d -- scripts/` → 跑 → `git checkout HEAD -- scripts/`。**若指纹出现任何差异 → 说明 C1/C2 越界动了 rng 或地图生成，按红处理，不许写成「预期重定」。**

### 6.2 六把刀（🔴 一律替换目标行，不许新增行）

批一教训：**新增行会被复位行盖回去**。例如把复位「加在」`_apply_floor_theme()` 尾部，前面的 `= _mod_*` 仍生效 → 变异不生效、探针全绿 → 假绿。每刀改完 `git diff` 应看到**对应行被改**而不是新增。

| 刀 | 替换哪一处 | 期望红 |
|---|---|---|
| **A · 复位挪到早退之后** | 把 `:1457` 后插入的两行复位**移到** `:1463 return` 之后（替换位置，不留副本） | **⑫ 1 条**（其余全绿——这就是 ⑫ 单独存在的理由） |
| **B · 复位写死 1.0** | `enemy_speed_mult = _mod_enemy_speed_mult` → `= 1.0` | **⑪ rage 1 条** + ⑨（仅当本局 modifier 是 rage） |
| **C · pressure 改乘法** | `:1473` → `diamond_mult = _mod_diamond_mult * 1.5` | **⑩ barren + ⑩ swarm 2 条**（1.05 / 2.25） |
| **D · C2 各去一个乘子** | `:216` / `:298` / `:304` 各删 `* Game.calamity_speed_mult`（**三刀分开做**） | 各 **⑬ 对应 1 条**；⑭ 应仍绿 |
| **E · 纯函数映射写错** | `"rage": return Vector2(1.25, 1.0)` → `Vector2(1.0, 1.0)` | **⑯1 必红**；⑨ 仅当本局 modifier 恰为 rage 时附带红；⑪ 全绿 |
| **F · 调用点漏接线** | `_mod_enemy_speed_mult = pair.x` → `= 1.0`（替换该行，**不要删行**） | **⑨ 1 条**（且仅当本局 modifier 命中 rage）；⑯ 全绿、⑪ 全绿 |

**刀 E / 刀 F 分别对应两层，缺一层就有盲区：**
- **刀 E → ⑯ 必红**，⑪ 全绿——因为 ⑪ 用探针自己写的 `_mod_*`，根本不经映射表。这是「⑪ 再强也测不到映射表」的实证。
- **刀 F → 只有 ⑨ 红**，⑯ 绿（纯函数没动）、⑪ 绿（探针自写字段）。**跑刀 F 前先用固定 seed 确认本局 modifier 是 rage**，否则这一刀砍下去可能全绿，会误判成「变异无效」。

### 6.3 负向对照

任何一刀一条都没红，立刻停下报我——说明对应断言组是哑的，不要自己往下补。

---

## 7. 不做清单

- **不推送。** 提交做完自检后我来收口，推送另有专人。
- 不写批二的东西（誓约遗赠 / `_oath_grant` / 开局残响）——与批三无交集，混进来会污染 E1 基线。
- **不改 `Data` 里任何表**：`MODIFIERS` / `FLOOR_THEMES` / `SHRINE_OFFERS` / `SIGILS` / `OATH_CONDITIONS` / `ACTION_DEFS` 一个字段不动。
- **不动 `_clear_calamity_effects()`**（批一刚落地、刚核验过，C1 不需要碰它）。
- 不改 `:1472` / `:1473` 的 `maxf` 语义。
- 不修 `slug.gd:90` + `:236` 的双乘子（`speed` 出生时已乘 `enemy_speed_mult`，`:236` 又乘一次 → rage/swarm 下敌速被平方）。**既有行为，本批不修**：改它会动平衡，且与本批目标无关。⑬/⑭ 全用**比值**判定，不受双乘子影响——这也是选比值而非绝对值的原因。
- **C3（圣所代价不咬人）留 S28，本批零断言、零改动。**
- **N1（Boss 接深渊速度）只补文档标注**，不动 `boss*.gd` 速度路径。
- 不修在册缺陷：`barren` + `scarce_ore` 文案显示 -0%、`max_hp` 钳制时 frail 比例不符、`boss.gd:61`/`boss2.gd:26` C-style `%`。
- 不改 `production/sprint-21/SPR21-FROZEN.md5`、`production/sprint-7/SPR7-FROZEN-4.md5`。

---

## 8. 交付形态

1. 一个提交，消息写清 `S27 批三：C1 主题倍率回落（_mod_* 分离）+ C2 狂乱四路径接全 + 探针 103 条`。
2. 报告须含：五门实测表、六把刀实测红集合（与上表逐刀比对，**不一致处如实说明哪条断言结构上抓不到**）、103 条分类闭合、`checked/declared` 实测值。
3. 报告须含 E1 三跑对照的指纹逐字比对结果（**不是「一致」两个字，要贴出三行指纹**）。
4. 报告须写明：`:815` 与 `:1053` 是**同一次提交内同时改**的，不是分批。

---

## 9. 三条最容易踩的坑（贴在手边）

1. **只改 `:815` 不改 `:1053`（或反过来）** → A 组红的样子像 C1 写错，你会去改探针。
2. **改了期望值不补 ⑮** → 变异 D 的靶子被拆了，以后「clear 里现查新层主题」这种 bug 再也没有断言能抓。
3. **`_mod_*` 不归一就写死 1.0** → 约 28.6% 的局红在正确实现上，换 seed 就绿，会被误判成「探针不稳定」。
