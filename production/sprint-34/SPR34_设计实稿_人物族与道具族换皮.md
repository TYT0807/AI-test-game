# SPR34 设计实稿 · 人物族与道具族换皮（风格统一追加件）

批次：Sprint 34（换皮线追加，不另开批）
日期：2026-11-17
上游：`SPR34_设计实稿_六道怪物志换皮.md`（下称**主稿**）。本件只补两族的**设计文案**，主稿 §1–§11 全部结论继续有效，冲突处以本件为准的条目在 §9 逐条列明。
作者硬指标（2026-11-17）：「生成出来的怪物那些记得统一风格啊，还有主角那几个也记得统一风格啊，道具啥的也是」。
性质：**表层视觉 + 显示名/手记文案。机制层零改动。**本批仍不写验证口径与实施单，等主稿 §11 U1–U5 与本件 V1–V4 一并裁完再点单。

---

## 1. 一句话

**三族各共用一句逐字相同的框架 prompt，只替换主体名；尺寸一律不动（代码里有硬编码缩放系数）；16×16 小图标不走 SDXL，改由程序化从共享调色板绘制——而"同族全局共享调色板"这个机制必须先扩到含拾痕者图集与 8 虫轨，否则统一不了真正最大面积的那块屏幕。**

---

## 2. 先纠正三个前提（实测磁盘，编程侧会用到）

| # | 你给我的前提 | 磁盘实况 | 后果 |
|---|---|---|---|
| ① | 商人「现用图 32×40」 | ✅ `generated/merchant_0/1/2.png` = **32×40** | 成立 |
| ② | 道具「32×32」、图标「16×16」分别怎么处理 | ⚠ **两者都不是真的**。道具族今天实际是 **6 种尺寸**：chest 20×16 / door 32×28 / stairs 32×32 / pedestal 16×22 / secret_wall 32×32 / prop_barrel·barrel_hit·pillar·totem 32×32 / prop_spike 32×16 / prop_vine 16×16。武器图标更杂：rifle·shotgun·railgun·launcher = **32×16**，arc·swarm = **16×16** | 「统一尺寸」这件事**没有既有纪律可破坏**，但也意味着不能靠"改成同尺寸"来统一风格——见 §3 |
| ③ | 浮游炮是「`shardbearer.png` 图集里那格」 | ❌ **不在玩家图集里**。`assets.gd:7 T_TURRET := preload("res://resources/texture/浮游炮.png")`（**384×32**），取帧区 `TURRET_FRAME_A := Rect2(2,1,12,30)`、`TURRET_FRAME_A2 := Rect2(50,1,12,30)`，经 `turret_frames()` → `turret.gd:32`。`shardbearer.png` 是 160×288 = 5×9 格 @32px，九行全被 `SHARDBEARER_ROW_*` 占满（idle/walk×3/attack/die），**没有空行可塞浮游炮** | 浮游炮归**道具族**管，不归人物族；且它是 S25/S26 原创程序化产物，不是 CC0 借来的脸 |

另两条必须进单的实测事实：

- 🔴 **`ally.gd:28` 与 `boss.gd:99` 共用同一张 `boss_prism_shard.png`（12×12）**，靠运行期 tint 分家：`ally.gd:29 modulate = Color(0.6,1.0,0.9,0.95)`（青绿协战水晶）、`boss.gd:101` 注释「碎片色运行期按主题 tint」。**换这张 = 同时改 Boss 外观**，一处变两处可见。
- **全仓 PNG 都是 color type 6（RGBA8）、无 `PLTE` 块**（我逐文件读过 IHDR/chunk）。所以 spr25 那句「索引色 ≤10 色」是**像素值层面的纪律，不是容器格式**。你的校验口径（ct=6 + 不透明色 ≤10）是对的，别去加 PLTE。

---

## 3. 尺寸口径（待确认点 1）——裁定：**一族一尺寸、逐张保尺寸，一个字节都不改宽高**

### 3.1 为什么不能"统一成 32×32"

因为尺寸今天**写在代码里**，而且是肉眼可见的错位，不是理论风险：

| 位置 | 硬编码 | 若把该图改成 32×32 会发生什么 |
|---|---|---|
| `secret_wall.gd:23` | `scale = Vector2(1.5, 1.0)` | 32×32 → 屏上 **48×32**，而碰撞盒是 `rect.size = Vector2(46, 30)`（`:17`）。横向凭空鼓 16px，墙比它的碰撞体宽出一截 |
| `pickup.gd:42` | chest `scale = Vector2(1.4,1.4)` | 20×16 → 屏上 28×22；改 32×32 → **45×45**，宝箱大到压过玩家剪影 |
| `pickup.gd:60` | weapon `scale = Vector2(1.1,1.1)` | wpn_rifle 32×16 → 35×18；改 32×32 → **35×35**，掉落物变成一块砖 |
| `pickup.gd:50` / `shop_stand.gd:44` | stairs/pedestal 无 scale | stairs 已是 32×32（不动）；pedestal 16×22 → 32×32 会把柜台垫高到盖住 `_icon.position.y = -8` 那件商品 |

这些全是 `.gd` 逻辑行，属主稿 §9 的**机制层禁改区**，编程侧应拒单。

### 3.2 正面裁定

1. **人物族**：
   - `shardbearer`（拾痕者）**保 160×288、5×9 格 @32px、逐格 region 不变**。这是动画图集，动它 = 动 `w_rect()`/九个 row 常量 = 机制面。
   - `merchant_0/1/2` **保留 32×40**（现状即最优：多出的 8px 给头巾与肩上货袋，正是商人剪影需要的）。
   - `boss_prism_shard` **保留 12×12**（见 V1）。
   - `prop_vine` **保留 16×16**（它在道具族里但走物件档）。
2. **道具／物件族**：**逐张保持现尺寸**，不做归一；逐条数值以 **§3.2b 表**为准（§2② 只是发现过程）。
3. **图标族（16×16）**：relic_* 10 枚 + arc/swarm + 其余 icon_* 一律 **16×16 不动**。
4. **怪物族**：32×32 不动（主稿 §4.1 T1）。

> **"同族尺寸一致"这条纪律本来不存在，现在也不需要造。** 真正的统一来自 §4 的框架句 + §5 的共享调色板 + §4.5.2 的按族占比／地平线，跟画布多大无关。

### 3.2b 🔴 目标画幅真源表（逐张保现尺寸；我 2026-11-17 现场读 `resources/texture/generated/*.png` 的 IHDR 得到，编程侧照抄成机检基准，⛔ 运行时猜尺寸）

你实测的那串数字**与磁盘逐条相符**（我把 59 个 PNG 全过了一遍 IHDR），下面是补全后的权威表。`fill_w ≤` 列是 §4.5.5 要求的道具档宽度上限，按画幅折算。

| id | 目标 W×H | 路线 | fill_w ≤ | 备注 |
|---|---|---|---|---|
| `chest_closed` / `chest_open` | **20×16** | SDXL→后处理 | 0.95 | 成对差分（§4.5.5 边界态 3） |
| `door_closed` / `door_open` | **32×28** | SDXL→后处理 | 0.90 | 成对差分 |
| `stairs` | **32×32** | SDXL→后处理 | 0.90 | — |
| `pedestal` | **16×22** | SDXL→后处理 | 0.95 | `shop_stand.gd:33` |
| `secret_wall` | **32×32** | SDXL→后处理 | 1.00 | 须先对 `瓦片.png` 取样（§7.1） |
| `prop_barrel` / `prop_barrel_hit` | **32×32** | SDXL→后处理 | 0.90 | 成对差分 |
| `prop_pillar` | **32×32** | SDXL→后处理 | 0.90 | — |
| `prop_spike` | **32×16** | SDXL→后处理 | 1.00 | 横条，`prop.gd:40` |
| `prop_totem` | **32×32** | SDXL→后处理 | 0.90 | 首跑漂移，见 §4.6.2 |
| `merchant_0` / `merchant_1` / `merchant_2` | **32×40** | SDXL→后处理 | 0.60 | 人物档，`gap=0` |
| `wpn_rifle` / `wpn_shotgun` / `wpn_railgun` / `wpn_launcher` | **32×16** | SDXL→后处理 | 1.00 | 横排朝向强制（§7.3） |
| `prop_vine` | **16×16** | 程序化 | 0.88 | 图标档（§4.5.5：fill 0.69–0.88）；今天实测 0.94，重画后须落进区间 |
| `relic_fang` / `_thorn` / `_bounce` / `_frost` / `_bigbullet` / `_mag` / `_eye` / `_radar` / `_drone` / `_heart` | **16×16** ×10 | 程序化 | 0.88 | 图标档留白 |
| `wpn_arc` / `wpn_swarm` | **16×16** | 程序化 | 0.88 | 图标档；今天实测 1.00，属越界件 |
| `boss_prism_shard` | **12×12** | 程序化（附条件 V1） | 0.88 | 本批不跑 |
| 怪物族 21 只 | **32×32** | SDXL→后处理 | 按主稿 §4.4 | `FRAC/GAP = 0.88/2` 维持现状 |

🔴 **两条我读盘读出来的连带后果，比这张表本身更容易踩**：

1. **`spr34_pixel.py` 今天整条链假设方图**：`frame()` 返回 `s×s`、`to_pixel()` 无条件 `resize((SIZE, SIZE))`、`verify()` 断言 `im.size == (32, 32)`。直接喂非方图 id 会得到"FAIL size=(20,16)"——那不是缺陷，那是断言在正确地拦一件错事。必须先把这三处改成读 §3.2b 的目标画幅，才谈得上道具／人物族入库。
2. ⚠ **`FAMILIES["prop"]` 缺两个成员**：磁盘上 `generated/` 有 `chest_closed`/`chest_open`/`door_closed`/`door_open`，但 `spr34_pixel.py:36-38` 的 prop 列表只有 12 项，**不含 chest/door**。照现状 `--family prop --all` 会静默少跑 4 张（更糟的是不会报错）。请补齐为 §3.2b 里 prop 路线那 13 项（含 `prop_vine` 走程序化则单列）。

---

## 4. 框架 prompt（风格统一的软性来源）

### 4.1 三条纪律（🔴 硬约束，写进生成器）

1. **一族一句框架，逐字复制粘贴，只允许替换 `<SUBJECT>` 一个槽位。**视角、机位、距离、姿态、材质、光照、背景、留白与占比全部锁死在框架里。任何人（包括未来的我）想调构图，必须**整族一起调**，不许单改一张——单改一张就是破坏统一。
2. **负面词沿用怪物族那套**（`spr34_gen.py:NEG`），只在个别族尾部追加**专属排除项**，且必须写明为什么加。
3. **框架句一旦定稿就上盘为唯一真源**：生成器 `HEAD` / `HEAD_PERSON` / `HEAD_PROP` 三个常量的内容必须与本节指定的**那一小节代码块逐字节相同**（怪物族 → §4.2b，不是 §4.2）。我的核验方式是现场 `grep -n` 生成器常量与该小节比对，不比摘要、不比行数。
   - ⚠ 代码块里是**折行拼接**的字符串字面量，"逐字节相同"判的是**拼接后的运行时值**，不是源码行的排版。核验口径固定为：把常量求值（或在生成器里 `print(HEAD)`）后与文档小节整段（去掉首尾空白、内部换行统一成单空格）做 `==`。**别拿源码行去 diff 文档行**——那是假红的典型来源。

⚠ 顺带一条口径修正：你说「纯中性灰无缝底」，但已跑绿的 `spr34_gen.py:HEAD` 写的是 `plain pure white background`，而 `spr34_pixel.py:key_background()` 的 docstring 明确说**SDXL 给的其实是带渐晕的灰底**，所以它放弃了洪水填充、改用边框环中位色自适应抠图。裁定：**三族统一沿用 `plain pure white background` 这句措辞 + 沿用同一个 `key_background()` 抠底函数**。理由是既然后处理已经证明能吃下渐晕灰底，换措辞只会让新跑的 20+ 张与已入库的怪物概念稿分叉，白白引入一轮对不上账的风险。

### 4.2 怪物族框架（**历史对照件 ⛔ 不是生成器真源**）

> 本小节只保留「§4.6.1 强化之前」的原句，用途是让你我核对该句被改写了哪几段。**生成器不得从这里抄**。现行真源在 §4.2b。

```
creature concept art for a dark folk roguelike, single subject, full body centered, plain pure white background, no cast shadow, bold readable silhouette, flat muted colors, limited palette, slightly desaturated, weathered cloth and bone textures, front three-quarter view, game sprite reference sheet, no text, no border
```

### 4.2b 怪物族框架（**现行唯一真源 ✅ `spr34_gen.py:HEAD` 逐字节 = 本块**）

> （2026-11-17 §4.6.1 裁定并入；本次修订把"建议"升为"定稿"。）与 §4.2 的差异**只有两处受控替换**，其余三十七个词组一字不动：
> ① `no cast shadow` → `no cast shadow, no pedestal, no platform, no stand, no ground plane`（压住摄影棚投影台效应，见 §4.6.1）；
> ② 尾部追加 `no floating parts`（补悬浮排除项）。
> **改这一句＝改框架＝怪物族整族重跑**，这条后果声明原样有效。

```
creature concept art for a dark folk roguelike, single subject, full body centered, plain pure white background, no cast shadow, no pedestal, no platform, no stand, no ground plane, bold readable silhouette, flat muted colors, limited palette, slightly desaturated, weathered cloth and bone textures, front three-quarter view, game sprite reference sheet, no text, no border, no floating parts
```

配套负面词追加件（拼在 `spr34_gen.py:NEG` 之后，**三族共用同一串**，理由见 §4.6）：

```
, pedestal, display platform, product stand, ground plane, contact shadow, floating object, detached floating limbs
```

### 4.3 人物族框架 `HEAD_PERSON`（新增）

> 与原框架只差三处受控替换：`creature`→`character`、姿态段、材质段。**镜头／背景／剪影／配色／渲染五句逐字相同**，这是跨族不发散的主锚。

```
character concept art for a dark folk roguelike, single subject, full body standing upright and centered with feet on the bottom margin, plain pure white background, no cast shadow, bold readable silhouette, flat muted colors, limited palette, slightly desaturated, weathered cloth, aged wood and tarnished metal textures, front three-quarter view, game sprite reference sheet, no text, no border
```

追加负面词（在 §4.2b 那串共用排除项**之后**再拼接，只写本族独有的；理由随条注明）：

```
, visible face, eyes detail, portrait, headshot, zoomed crop, modern clothing, zipper, plastic, chrome shine
```

- `visible face, eyes detail, portrait, headshot`：项目正典是**无名记录员**——`icon_codex.png` 画的就是一盏矿灯，从没画过脸；而且 32px 上的脸必糊。全片兜帽/面具/无面，一次解决风格统一和身份留白两件事。
- `zoomed crop`：防止 SDXL 把人物画成胸像（人物族最容易犯的错，怪物族不会）。
- `modern clothing, zipper`：本项目是「克制实用主义」调性，拉链是现代工业符号，与矿灯/麻布/铜牌同屏会穿帮。

### 4.4 道具／物件族框架 `HEAD_PROP`（新增）

> 镜头与渲染五句仍逐字相同；只把姿态换成「落地摆放 + 基座阴影接触」，把朝向换成四分之三侧视。

```
game prop asset concept art for a dark folk roguelike, single object only, standing on the ground with its base on the bottom margin, plain pure white background, no cast shadow, bold readable silhouette, flat muted colors, limited palette, slightly desaturated, weathered wood, aged stone, frayed rope and tarnished brass textures, three-quarter side view, game sprite reference sheet, no text, no border
```

追加负面词（接在 §4.2b 共用串之后，只写本族独有的）：

```
, human figure, creature, animal, hands, room interior, floor tiles, wall, glowing runes
```

- `human figure, creature, animal, hands`：道具族最大的失败模式是 SDXL 往画面里塞一只手或一个人当比例参照。
- `room interior, floor tiles, wall`：防它把"密室墙"画成一堵有透视的走廊。
- ~~`floating object`~~ / ~~`drop shadow beneath object`~~：**已上收到 §4.2b 共用串**（分别写作 `floating object` 与 `contact shadow`），本族不再重复列——重复列会让三族的 NEG 拼接结果对不上同一份真源。
- `glowing runes`：发光交给引擎的 `modulate`，烤进贴图会在 tint 下洗成一片。

### 4.5 留白与占比（代替"尺寸一致"的真正纪律）

#### 4.5.1 prompt 侧：三族共用「脚/座贴下边距」措辞（裁定，不再逐族另写）

`HEAD_PERSON` 与 `HEAD_PROP` 都保留 `with its base on the bottom margin` / `with feet on the bottom margin` 这类**贴边**措辞，⛔ 不改成"居中留边"。两条理由：

1. **像素侧本来就会把这一信息抹掉**：`spr34_pixel.py:frame()` 第一步是 `im.getbbox()` 裁到主体包围盒，概念稿里"画布下方那段空白"在抠完底后根本不存在——占比与地平线全由 §4.5.2 的 `frac`/`gap` 两个常量重建。所以这句 prompt **只影响 SDXL 会不会把主体画残、有没有把脚切在框外**，不影响终态构图。为它重跑一族不值。
2. 真正的对齐风险在别处：SDXL 听"贴底边"时偶尔会把脚趾压在画布最外一行上，`key_background()` 的边框环中位色自适应抠图会把它当背景啃掉。**处置归像素侧**（§4.5.2 的 `gap ≥ 1` 保证重建后必有留白），不归 prompt 侧。

#### 4.5.2 像素侧真源：`FRAC` / `GAP` 改成**按族取值**（🔴 这是本件对 `spr34_pixel.py` 唯一要求的机制面改动）

现行单常量 `FRAC = 0.88` / `GAP = 2` 只对怪物族成立（它们本来就是 32×32）。三族画幅不同，必须分档。**下表是唯一真源，编程侧照抄进生成器常量，我现场比对**：

| 族 | `FRAC_BY_FAMILY` | `GAP_BY_FAMILY` | 落地说明 |
|---|---|---|---|
| monster | `0.88` | `2` | 维持现值不变；`frame()` 现有行为即合规基准 |
| character | `0.90` | `0` | 人物最高，脚要踩到底边沿（`gap=0`）——见 §4.5.3 的商人账 |
| prop | `0.84` | `0` | 底座贴底边沿，同账 |

🔴 **一条必改的缩放缺陷（我在磁盘上算出来的，不是理论风险）**：`spr34_pixel.py:99` 现在是

```
oy = s - h - int(round(gap * s / float(SIZE)))
```

`SIZE` 恒为 32。非 32px 高的画幅走这条公式，落位会从 `gap` 漂成 `round(gap*s/32)`：merchant 高 36 → gap 2 变 2（侥幸没漂），但 chest 高 14 → gap 2 变 **1**，pedestal 高 19 → 变 **1**。也就是说**同一份代码在不同画幅上画的不是同一条地平线**，"同族统一构图"这句话在非方形画幅上不成立。
裁定：改为**末行直接贴边**，把比例换算彻底删掉——

```
oy = (s - h) // 2 if name in FLOATING else s - h - gap
```

配套：`frame()` 的返回值必须是**目标画幅本身**（见 §3.2b 那张表），⛔ 继续无条件返回 `s×s` 方图；`to_pixel()` 的 `resize((SIZE, SIZE))` 与 `verify()` 的 `if im.size != (SIZE, SIZE)` 都要改成读该 id 的目标尺寸。否则 §3.2「一个字节都不改宽高」会在 `verify()` 里被自己的断言判 FAIL。

#### 4.5.3 与既有 `.gd` 偏移的兼容性核算（🔴 已实测坐实；结论＝图迁就代码，代码一行不动）

Sprite2D 默认居中锚点 ⇒ 主体最底行距画布底 `gap` px 时，它在屏幕上落在 `node.position.y + H/2 - gap`。据此逐条核：

| 引用点（现场 `grep -n` 坐实） | 现值 | 代入本表 | 结论 |
|---|---|---|---|
| `scripts/merchant.gd:12` `body.position = Vector2(0, -4)` | 32×40，`gap=0` | 脚线 ≈ `-4 + 20 = +16` | ✅ 与你的"脚踩底边沿"意图一致，**无需改码**。柜台基座顶面在 `+6 + 11 = +17`，脚线比它高 1px——人站在台后、略高于台面，正是想要的遮挡关系 |
| `scripts/shop_stand.gd:33` `base.position = Vector2(0, 6)` | pedestal 16×22，`gap=0` | 座底 ≈ `+6 + 11 = +17` | ✅ 兼容。⚠ **但你引的这条行号不对**：实稿原文写的是"`pedestal` 有 `position.y = 6`"，磁盘上是 `shop_stand.gd:33` 的 `base.position = Vector2(0, 6)`，且 `shop_stand.gd` 里没有 `position.y = 6` 这行。文档已按磁盘实况改写，后续引用以本节为准 |
| `scripts/shop_stand.gd:45` `_icon.position = Vector2(0, -8)` | 商品图标 16×16 | 图标占 `y ∈ [-16, 0]`，基座占 `y ∈ [-5, +17]` | ✅ 不冲突，但两者**重叠 5px**。这是既有观感，不是本批引入的；换图时若把圣物图标画得顶满 16×16，重叠会更显眼 ⇒ 归入 §4.5.4 的图标档留白，别顶格 |
| `scripts/prop.gd:40-41` spike `position = Vector2(0, 2)` | prop_spike 32×16，`gap=0` | 刺条底 ≈ `+2 + 8 = +10`，无碰撞体 | ✅ 兼容。横条贴地即可，⛔ 不要画竖刺 |
| `scripts/pickup.gd:42` chest `scale 1.4` / `:60` weapon `scale 1.1` | 20×16 / 32×16 | 屏上 28×22.4 / 35.2×17.6 | ✅ 只要保尺寸就不动这条账；`gap=0` 让宝箱底沿贴近节点原点，掉落物落地手感更实 |
| `scripts/secret_wall.gd:23` `scale (1.5, 1.0)` vs `:17` `rect.size (46, 30)` | 32×32 → 屏上 48×30 | — | ✅ 保尺寸则鼓包量固定在横向 +2px（不是原稿写的 +16px，那是按"改成 32×32"算的旧口径）。数字已订正 |

#### 4.5.4 悬空主体名单（✅ 你拟的五只全部批准，另加两条边界）

批准：`wraith` / `beholder` / `faerie` / `slime` / `flameskull` —— 保持 `spr34_pixel.py:42 FLOATING` 现状，垂直居中、不做地平线对齐。

追加裁定两条：
- **`drone`（浮游炮系）不进 `FLOATING`**：本批不换、不生成（§8.1），它出现在 `FAMILIES["character"]` 里只是台账残留，⛔ 为它跑图。
- **prop 族整体不入 `FLOATING`**：包括 `prop_totem`。它的"飘"是 prompt 缺陷（§4.6.1 第 2 条），不是设计上的悬浮生物，用负面词修，不用居中绕。

#### 4.5.5 机检区间（验证口径将据此立条；判据一律在**终态像素**上量，不在概念稿上量）

定义：`fill_h = 主体不透明像素 bbox 高 / 画布高`，`fill_w` 同理，`bottom_gap = 画布高 - 1 - bbox 底行`。

| 族／档 | `fill_h` | `fill_w` | `bottom_gap` | 备注 |
|---|---|---|---|---|
| 怪物·杂兵（18 只） | **0.70–0.82** | ≤0.92 | `= GAP_BY_FAMILY.monster = 2` | 执令三只除外 |
| 怪物·执令（`skeleton_king` / `demon` / `dragon`） | **0.86–1.00** | ≤1.00 | `≤ 1` | "顶满"写成可判数：至少 86%，且允许贴边 |
| 人物（merchant ×3） | **0.85–0.92** | **≤0.60** | `= 0` | 宽 ≤60% 是防 SDXL 把货笼画撑出画幅 |
| 道具／物件（§7.1 十二张） | **0.75–0.86** | 按各 id 画幅另给上限（§3.2b 表右列） | `= 0` | — |
| 图标（16×16 程序化批） | **0.69–0.88** | ≤0.88 | `≥ 1`（四边都 ≥1，主体不触边框） | ⚠ 区间不是我拍的：我把现存 36 张 16×16 量了一遍（最长边／画布），relic_* 十枚与 icon_affix_*、icon_mod_* 全落在 **0.69–0.88**；顶到 0.94–1.00 的只有 `icon_chain`/`icon_pierce`/`prop_vine`/`icon_codex`/`icon_crit`/`wpn_arc`/`wpn_swarm` 这 7 张。新画的圣物按 0.69–0.88 走，才和"没重画的那一大批"成套。**注意本批 `wpn_arc`/`wpn_swarm`/`prop_vine` 要重画**，它们今天 0.94–1.00 属越界件，重画后须落进本区间 |
| 悬空主体（§4.5.4 五只） | 各自族的区间 | 各自族的区间 | **不参与判定**，改判 `abs(top_gap - bottom_gap) ≤ 1` | 否则"垂直居中"没有可证伪判据 |

三条边界态（缺一条就会有假绿）：
1. **全透明图**：`frame()` 已经 `raise RuntimeError`，属硬失败，不算阴性通过。
2. **宽度撑破画幅**（`bbox` 触到左右第 0 列或末列）：直接 FAIL，不进入 `fill_w` 区间判断——触边意味着下一轮 `key_background()` 可能把主体当背景啃。
3. **成对差分件**（`chest_closed`/`chest_open`、`door_closed`/`door_open`、`prop_barrel`/`prop_barrel_hit`）：除各自区间外，追加一条**配对判据**——两图的 `bbox` 左上角坐标差 `≤1px`、`bbox` 宽高差 `≤1px`。开合只许改内容，不许改外形与站位（`prop.gd:73` 是直接换 texture，尺寸一跳肉眼可见）。

### 4.6 怪物族首跑暴露的两处框架缺陷（✅ 已裁定并入真源 §4.2b）

1. **`no cast shadow` 压不住"摄影棚投影台"效应**：`plant` 概念稿长出一个椭圆灰色展示台，被当成主体的一部分抠了出来；`beholder` 头顶多出两根触角状伪影。→ **定稿**：§4.2b 已在 `no cast shadow` 之后插入 `no pedestal, no platform, no stand, no ground plane`，并在共用 NEG 串补 `pedestal, display platform, product stand, ground plane, contact shadow`。**后果：怪物族整族重跑 20 张**（`goblin`/`skeleton_king` 的重跑记录随之作废，种子台账按新跑覆盖）。
2. **缺悬浮排除项**：`prop_totem` 这类该落地的东西会漂着画。→ **定稿**：`floating object` 上收进 §4.2b 共用 NEG 串（三族同享），HEAD 侧怪物族补 `no floating parts`；prop 族**不**因此进 `FLOATING`（§4.5.4）。

---

## 5. 16×16 小图标（待确认点 2）——裁定：**确认，你的判断成立，而且比你以为的更必要**

`--confirm`。理由三条，第三条是我实测出来的、你没提到的：

1. **算术上就不成立**：SDXL 1024×1024 → 16×16 是 **64× 降采样**。最近邻等于每 64×64 区域只采 1 个像素——你不是在缩小，是在**抽样**，主体偏一点就丢胳膊。而 `spr34_pixel.py` 的抠底是在 **256 工作分辨率**上做连通域的，256→16 同样要再塌 16×。中间态越干净不代表终态越准。
2. **色数上打不平**：D-C 要 ≤10 色含透明，其中至少 1 色给轮廓、1 色给高光、1 色留给透明——16×16 上剩给你描述材质的只有 6–7 色。扩散模型的渐变在这里全是噪声。
3. 🔴 **它们本来就出自同一只手**：`generated/` 下 30 多个 16×16（relic_*、icon_affix_*、icon_mod_*、wpn_arc/swarm…）**全部是程序化生成的原创资产**，不是 CC0 素材包。CC0 只有 `monsters/` 那 21 张（主稿 §2 事实 A，`data.gd:25` 注释自认）。所以"图标改回程序化"**不是退步，是回到它自己的正典**——而且这正是 spr25 范式（纯标准库、无 AI、10 色索引、硬边、透明底、自带 `verify()`）。

### 5.1 程序化图标的共享调色板（接你下一步的机制）

沿用 `spr25_art_gen.py` 的十色（我已核对：`BONE (220,213,196)` 与 `LIT (232,178,96)` 与怪物族 `skeleton_king` 量化结果**逐字节相同**，说明这套色板已经是事实上的跨族公共色）：

`CLR 透明 / INK (26,26,31) / GREY (43,43,51) / BROWN (74,64,56) / STONE (110,105,96) / BONE (220,213,196) / RUST (194,114,58) / RUST_DIM (146,100,64) / LIT (232,178,96) / CYAN (95,140,134)`（+ `COPPER (150,116,76)` 备用）

### 5.2 但「同族全局 median-cut」有一个致命反例 —— 🔴 必须扩范围

如果只对**新量化的这一族**做 median-cut，你会得到三套互不相同的调色板，而屏幕上同时出现的是：

| 资产 | 来源 | 屏幕面积占比 |
|---|---|---|
| `monsters/*.png` 21 张 | 本批新量化 | 中 |
| `shardbearer.png` 玩家图集 | **S25 程序化，本批不动** | **最大**（玩家永远在场） |
| `wraithswarm.png` 8 虫轨 | **S26 程序化，主稿 §10.3 排除** | 大（每房都刷） |
| `generated/` 图标与道具 | 部分本批、部分不动 | 中 |

**结果是：你把新做的两族互相统一了，却让它俩跟玩家、跟 8 虫各自为政——观感反而更花。**

裁定（写成硬前置）：

> 🔴 **共享调色板必须是"全项目一张表"，不是"一族一张表"。** 做法：以 spr25 那十色为**固定基准表**（因为它已经是 `shardbearer.png` / `wraithswarm.png` / 现有图标的出彩色），新量化的所有族**量化到这张固定表**，而不是各族自己 median-cut。median-cut 只在"某族需要额外专色"时用来**提议**新色，提案进本表须逐色登记并说明为什么十色不够。
>
> 机检判据（可直接进你的 `verify()`）：**每张新图的"不透明色集合" ⊆ 全局基准表**。违反即返工。这条比"≤10 色"强得多，而且能自动抓住"两套灰混在一起"这种最典型的风格分裂。

---

## 6. 人物族 prompt 逐字列（`<SUBJECT>` 前的部分，拼在 §4.3 框架之后）

> id 键名一律不改（主稿 §10.1）。显示名列给的是**中文可见名**，仅用于图鉴/标签文本。

| id | 显示名 | SUBJECT 逐字 | 归属与取舍 |
|---|---|---|---|
| `shardbearer` | 拾痕者 | `hooded mine-lamp record-keeper in a short oil-stained canvas coat, round lantern helmet with a single warm lamp core at the chest, no visible face, gloved hands, satchel of blank tally tags at the hip, heavy boots` | **⛔ 不换图**（§8.1）。此 prompt 仅作未来扩容参考，本批不生成、不量化、不覆盖 |
| `merchant_0` | 秤伯 | `hunched pedlar in layered oiled canvas wraps, a wide-brim conical hood shading an absent face, spring balance scale with two empty pans held forward, ledger board strapped to the back` | 🔄 **换**。三层皮肤靠配件剪影分档，不靠颜色 |
| `merchant_1` | 担兄 | `standing hawker with a shoulder pole and two hanging crate baskets, coiled rope at the belt, folded cloth cap over a featureless head, crouched ready posture` | 🔄 **换** |
| `merchant_2` | 背市 | `bulk pedlar crushed under a lashed-together cargo cage on the back, plank spine brace, one arm raised holding a brass weigh-tag, no face inside the hood` | 🔄 **换** |
| `boss_prism_shard` | （无显示名） | `a single detached faceted obsidian splinter, thick ink outline, clean internal facet lines, faint cold inner sheen confined to one facet` | 🔄 **换（附条件 V1）**。12×12 小件，SDXL 不可行 → 走程序化，此 prompt 只作造型参考 |

**三商人的统一手段**（这才叫一族）：同一副**杆秤 / 两只空秤盘**作为家族徽章出现在三只身上，位置固定在持物的那只手前；档位区分只用「背篓 → 扁担双筐 → 整个人被货笼压弯」三级递进。玩家不需要读名字就知道楼层越深、摊子越大、这位欠的货越多。

### 6.1 关于浮游炮（纠正后的位置：道具族）

`turret.gd:3` 注释「浮游炮：环绕玩家自动索敌开火；Mk1-4 用颜色区分（红→铁灰→紫→金）」——但 `assets.gd:289 turret_frames()` 只喂了 `hover` 两帧，Mk 全靠运行期 tint。**这正是主稿 §4.2「禁止绝对色相」的活教材**：现在的 Mk1-4 分级在暖金层和冷蓝层会互相洗掉。

- 裁定：**本批不换**（S25 原创、风格已在基准表内、region 硬编码 `Rect2(2,1,12,30)` 属机制面）。列入 §8.2 观察项。
- 若将来要换：`<SUBJECT>` = `small hovering ore-cart gun pod, riveted brass barrel housing, a stubble lamp eye, twin mounting lugs, no crew visible`，并且**必须把 4 档合并进同一张 48×32 格内的四个几何变体**（加长枪管＝Mk 递增），让等级可读性脱离色相。

---

## 7. 道具／物件／图标族 prompt 逐字列

### 7.1 场景物件（🔴 逐张保尺寸，见 §3.2）

| id | 目标画幅（§3.2b 真源） | SUBJECT 逐字 | 取舍 |
|---|---|---|---|
| `chest_closed` | 20×16 | `low iron-bound supply crate, lid shut with a hasp and a blank tally tag nailed on, rope lashings crossing the top` | 🔄 换 |
| `chest_open` | 20×16 | `same low iron-bound supply crate with the lid thrown open, empty interior shown as one flat dark band, contents suggested by a single rim highlight` | 🔄 换（🔴 必须与 closed **同形同尺度**，只做开合差分） |
| `door_closed` | 32×28 | `plank door set in a timber frame, cross braces, a ring pull, seams sealed with daub, no handle ornament` | 🔄 换 |
| `door_open` | 32×28 | `same plank door swung inward revealing a black rectangular void behind it, identical frame and hinge positions` | 🔄 换（🔴 同上，成对差分） |
| `stairs` | 32×32 | `rough-cut stair mouth descending into solid black, one handrail of tied timbers, a hanging lamp bracket at the top step` | 🔄 换。顶阶那盏灯 = 与拾痕者矿灯同源的**跨族母题钉** |
| `pedestal` | 16×22 | `short stone counter block with a worn top slab, chisel marks, a copper price plaque left blank on the face` | 🔄 换（`shop_stand.gd:32` 在用；空白铜牌 = spr25 `COPPER` 语义延续） |
| `secret_wall` | 32×32 | `wall panel of stacked brick whose mortar joints are drawn slightly fresher and lighter than the surrounding course, one loose stone at the lower corner` | 🔄 换。🔴 **必须与瓦片墙同源**：先比对 `瓦片.png`（64×64，4×4 格 16px，`TILE_WALL := Vector2i(3, 2)` 那格）取样后再定砖纹，否则贴到墙上就是一块明显的补丁 |
| `prop_barrel` | 32×32 | `staved timber cask with two rust-dim hoops, shallow dome lid, standing upright` | 🔄 换 |
| `prop_barrel_hit` | 32×32 | `same staved timber cask split along one seam, a wedge chip knocked out, splinter edges drawn as hard steps` | 🔄 换（🔴 与 barrel **同形同尺度**，只加破损差分；`prop.gd:73` 直接换 texture，尺寸一变就跳一下） |
| `prop_pillar` | 32×32 | `squat dressed stone column with a plain capital and base, hairline crack running one course` | 🔄 换 |
| `prop_spike` | 32×16 | `row of short forged spikes lying flat in a floor track, tips all pointing the same way, blunt wear on each point` | 🔄 换。🔴 注意它是 **32×16 的横条**，不是立着的刺——`prop.gd:38` 给它单独 `position = Vector2(0, 2)` 且不挂碰撞体，画成竖的会露馅 |
| `prop_totem` | 32×32 | `carved waymarker post on a stone base, three stacked carved bands, a small offering bowl lashed near the top, planted firmly on the ground` | 🔄 换（首跑漂移，见 §4.6.2） |
| `prop_vine` | 16×16 | `knot of trailing creepers with broad leaves, cut stem at the base` | 🔄 换（16×16 → 走程序化；`boss.gd:261` 全向阻挡藤蔓复用它，别画成方向性的） |

### 7.2 圣物图标（16×16 × 10 枚，**程序化绘制**；prompt 只作造型意图备案）

命名总则同主稿 §5：**三字口语带因果**；⛔ 不用「X 之 Y」翻译腔奇幻名。以下新名与现行显示名的对应见括号，`meta.gd` / `Relics` 里的 id 键一个不改。

| id | 现显示名 | 新显示名 | SUBJECT（造型意图，供程序化画手参考） |
|---|---|---|---|
| `relic_fang` | 吸血獠牙 | **咬还** | `a single worn animal fang tied to a short cord, hollow base, tip bright from use`（↔ 杀敌回血＝它替你咬一口，回头你得还） |
| `relic_thorn` | 荆棘装甲 | **扎手** | `a bent iron thorn spike with a flat mounting foot, barb facing outward`（↔ 撞你的付出代价） |
| `relic_bounce` | 弹射弹壳 | **弹壁** | `a spent cartridge case dented on one shoulder, struck-flat rim`（↔ 墙角也是武器） |
| `relic_frost` | 冰霜涂层 | **挂霜** | `a short bar of coating stock with frost bloom crawling up one end, rime specks`（↔ 命中带减速） |
| `relic_bigbullet` | 巨型弹头 | **粗钝** | `an oversized blunt-nosed projectile body, three driving bands, no casing`（↔ 又粗又痛） |
| `relic_mag` | 加长弹匣 | **续命匣** | `an extended magazine box with a filler port on top and two stack ribs`（↔ 少换一次弹，多活一秒） |
| `relic_eye` | 猎手印记 | **看痕** | `a stylised drilled-eye charm on a bead chain, one clear facet mark, plain pupil`（↔ 暴击看天，装了看常；接「见痕」母题） |
| `relic_radar` | 六感警报 | **风铃牌** | `a small hung alarm plate with a clapper, chipped edge, suspension loop`（↔ 无敌更长；与残响悬铃同源意象） |
| `relic_drone` | 双浮游炮 | **双挂件** | `two miniature gun pods joined by a short link bar, matching lug holes`（↔ 多一个帮手） |
| `relic_heart` | 黄金心脏 | **满斗** | `a brass counterweight heart shape with a filling hatch and a bright seal line`（↔ 上限加一还回满） |

### 7.3 武器图标（🔴 混合路线，这是我改判的一条）

**不要整体走程序化**——`wpn_rifle/shotgun/railgun/launcher` 今天是 **32×16**，是个横长条，正好放得下一件有方向的器械；程序化画 32×16 的机械细节并不比人贵，但**收益低于风险**（这 4 张在 HUD、掉落、商店柜台三处出现，`shop_stand.gd:41 _icon.scale = Vector2.ONE` 原样显示）。裁定分两路：

- **32×16 四件（rifle/shotgun/railgun/launcher）→ 走 SDXL 概念稿 + 后处理**，用 §4.4 的 `HEAD_PROP` 框架，`<SUBJECT>` 如下。它们的画幅够，是唯一能从扩散模型的结构暗示里获益的一档。
- **16×16 两件（arc/swarm）→ 走程序化**，与 §7.2 同批同表。

| id | 目标画幅（§3.2b 真源） | 路线 | SUBJECT 逐字 |
|---|---|---|---|
| `wpn_rifle` | 32×16 | SDXL | `a long lean hand-cannon with a wooden stock, single barrel, ring-sight at the muzzle, laid horizontally muzzle-right` |
| `wpn_shotgun` | 32×16 | SDXL | `a stubby wide-mouthed breaker gun with a ribbed double-thick muzzle, laid horizontally muzzle-right` |
| `wpn_railgun` | 32×16 | SDXL | `a long twin-railed magnetic lance with two parallel guide bars and a bare coil section, laid horizontally muzzle-right` |
| `wpn_launcher` | 32×16 | SDXL | `a fat short shoulder mortar with an oversize bell muzzle and a drum of charges behind it, laid horizontally muzzle-right` |
| `wpn_swarm` | 16×16 | 程序化 | `three tiny dart-missiles bundled in a launcher clip, folded fins`（↔ homing=true） |
| `wpn_arc` | 16×16 | 程序化 | `a rod emitter tipped with a forked spark gap, two terminals`（↔ arc=3 连锁） |

🔴 四件 32×16 的 `<SUBJECT>` 里 `laid horizontally muzzle-right` 是**族内强制项**：现在这几张朝向不统一，横排摆进 HUD 时一眼就是拼的。

---

## 8. 哪些值得换、哪些保留（待确认点 3）

### 8.1 保留清单（🔴 本批不许碰，碰了要写理由）

| 资产 | 为什么不换 |
|---|---|
| `shardbearer.png`（160×288） | ①它是**拾痕者正典**，也是全游戏辨识度最高的一张脸（虽然没脸）；②S25 程序化原创，风格已在基准色表内；③九行动画格 + `w_rect()` 硬编码，动它 = 美术批不是换皮批（主稿 §3 同款爆炸半径） |
| `wraithswarm.png`（96×192） | 8 虫 slug 轨，主稿 §10.3 明文排除 |
| `浮游炮.png`（384×32） | S25 原创 + `TURRET_FRAME_A` region 硬编码（§2③） |
| `瓦片.png` / `动态瓦片.png` / `爆炸特效.png` | 主稿未纳入；瓦片是**平铺纹理**，不是单体剪影，§4.4 的 `HEAD_PROP` 里那句 `single object only` 对它根本不适用。特效是序列帧 |
| `cellar_bg.png`（320×180） | 大画幅静态背景，是 Comfy 的正当用途（章程 §五），但不属于这三族的统一命题 |
| `icon.png`（512×512） | 应用图标，非游戏内精灵 |

### 8.2 换（本批目标集）

- **怪物族 21 张**：主稿已定，✅ 概念稿 20 张已跑完（种子台账 20261117 我核过：21 个 id 全覆盖，`goblin`/`skeleton_king` 各出现两次是重跑，不算漏）。
- **道具／物件族 13 张**：§7.1 全部 🔄（含 `secret_wall` 需先对砖、`prop_spike` 需注意横条画幅）。
- **商人 3 张**：§6 🔄。
- **武器 4 张（32×16）**：§7.3 SDXL 路线。
- **`boss_prism_shard`**：🔄 附条件（V1）。

### 8.3 程序化重绘（不进生图队列）

- **圣物 10 枚 + `wpn_arc`/`wpn_swarm` + `prop_vine`**：§7.2/§7.3/§7.1，共 13 张 16×16。
- **`icon_*` 全套**（affix 7 + mod 6 + chain/guard/dice/venom/crit/pierce/resonance/suffix/codex 等 ≈ 22 张）：本来就是程序化原创，**本批不重画**，但**必须把它们的重量化纳入全局色表核算**（§5.2）——否则你会看到"新道具很协调，头顶一堆词缀标记还是老味道"。

---

## 9. 与主稿的关系（冲突逐条声明，避免两份文档打架）

| 主稿条款 | 本件是否改变 |
|---|---|
| §4.1 T1「32×32 同名覆盖」 | **仅对怪物族成立**。人物/道具族逐张保尺寸（§3.2），不套用 32×32 |
| §4.3 D-A/D-B/D-C/D-D | **完全继承，一字不改**，并追加 §5.2 的「不透明色 ⊆ 全局基准表」为 **D-E** |
| §4.5 生图工作流 | 继承，且三族共用同一 `key_background()` 与同一 HEAD 措辞（§4.1 纪律 3） |
| §4.2 禁止绝对色相 | 继承，并在浮游炮 Mk1-4 上找到活教材（§6.1） |
| §10.1 不改内部 id | 继承 |
| §10.3 不动 slug 轨与 `shardbearer.png` | **继承并加强**：本件把「不动」的范围扩到 `浮游炮.png`/`瓦片.png`/`动态瓦片.png`/`爆炸特效.png`/`icon.png`（§8.1） |
| §10.4 一律 32×32 单帧 | **本件放宽为"逐张保现尺寸"**，但「不做高清、HD 降采样成品算违规入库」这条**原样保留** |
| §11 U1–U5 | 全部继续有效，本件另加 V1–V4 |

---

## 9b. 🔴 真源索引（编程侧只认这张表，别再在文档里找"哪句算数"）

| 东西 | 唯一真源位置 | 生成器落点 |
|---|---|---|
| 怪物族框架句 | **§4.2b**（§4.2 是历史对照件，⛔ 抄它） | `spr34_gen.py:HEAD` |
| 人物族框架句 | §4.3 | `spr34_gen.py:HEAD_PERSON` |
| 道具族框架句 | §4.4 | `spr34_gen.py:HEAD_PROP` |
| 三族共用 NEG 追加串 | **§4.2b 末块** | `spr34_gen.py:NEG_EXTRA`（新常量，拼在 `NEG` 后） |
| 各族专属 NEG 追加 | §4.3 / §4.4 各自代码块 | `NEG_PERSON` / `NEG_PROP` |
| 背景措辞 | `plain pure white background`（三族一字不改，裁定见 §4.1 ⚠ 段） | 三个 HEAD 内联 |
| 抠底函数 | 同一个 `key_background()`，⛔ 分族另写 | `spr34_pixel.py:45` |
| 逐张目标画幅 | **§3.2b 表** | `TARGET_SIZE` 字典（新增；同时把 `to_pixel()`／`verify()` 从硬编码 32 改为读它） |
| 按族占比／地平线 | **§4.5.2 表** + §4.5.2 那条 `oy` 公式修正 | `FRAC_BY_FAMILY` / `GAP_BY_FAMILY` |
| 悬空主体名单 | **§4.5.4**（五只，prop 族整体不入） | `spr34_pixel.py:42 FLOATING` |
| 机检区间 | **§4.5.5 表** + 三条边界态 | 验证口径据此立条（下批） |
| 全局基准色表 | §5.1 十色（+ `COPPER` 备用），median-cut 降级为提议器 | `BASE_PALETTE` 常量 + `verify()` 的 D-E |

---

## 10. 素材取用声明（章程 §二 体例）

- **取材（属性层，非情节层）**：
  - 母题「见 / 记 / 留痕 / 代价」与「克制实用主义」调性：`D:\大纲\统一大纲\角色资料库\19_漏洞体质与至高意志（天道）谱系.txt`（只读，未改动）——**只取气质，不取事件**。
  - 「皆代价」绑定写法：同上，及 `33_铁活家（佟长贵·佟长河·佟小满）.txt` 一脉的匠作语汇（用于 `prop_totem`／`pedestal` 的"凿痕/铜牌/榫绑"质感词）。
  - 悬铃／残响意象：项目自有正典 `残响悬铃`（`icon_resonance.png`、`relic_radar` → 风铃牌），**不引小说**。
- **未取**：任何具体情节事件、章节顺序、台词原文、章名、未定稿走向；⛔ `D:\大纲\库\05_代价与污染\` 他人原作全文零引用；⛔ 他作专有名词与独特比喻。
- **写入范围**：本件对 `D:\大纲` **零写入、零脚本**。
- **命名合规复核**：§6/§7 全部新名为原创三字口语；`<SUBJECT>` 词汇全为材质/形态/机制描述词，无一处他作角色特征、徽章、制服。特别自查了两处高危：`relic_eye` 的"钻刻眼符"已限定为 `drilled-eye charm`（民俗护身符形制，非他作器官形象）；`wpn_railgun` 用 `twin-railed magnetic lance`（纯机构描述，不指涉任何具名武器）。

---

## 11. 🕐 待作者裁（V1–V4，与主稿 U1–U5 一并问，裁完才开工）

| 编号 | 事项 | 选项 | 本稿立场 | 改裁影响面 |
|---|---|---|---|---|
| **V1** | `boss_prism_shard`（12×12）要不要重画 | 不画 / 画 | **不画**。`ally.gd:28` 与 `boss.gd:99` **共用此图**，换了等于同时改「棱镜守望者」的外观与「协战水晶」的外观，而三杰是 README 宣传门面（主稿 §3 终局位） | 若画：Boss 与 ally 必须**同批重做 tint 鲁棒性 D-B 双试色**，且要新增断言确认两者仍可分辨；纯程序化小件，工时低但牵动可见面最广 |
| **V2** | 商人三档怎么分 | 配件递进（本稿） / 服饰民族志分档 / 体型分档 | **配件递进**：杆秤恒定 + 背篓→扁担→被货笼压弯 | 服饰分档会让三人在 32px 上糊成一团（花纹吃不掉）；体型分档会与 `ogre`/`minotaur` 撞剪影 |
| **V3** | 武器 32×16 四件走 SDXL 还是程序化 | SDXL（本稿） / 全程序化 | **SDXL**：画幅够，能吃到结构暗示红利；四件在 HUD/掉落/柜台三处出现，值得一次投入 | 选全程序化：省一轮生图，但磁轨枪的双导轨与榴弹炮的喇叭口要靠手写像素，工时更高且更硬 |
| **V4** | 全局共享色表要不要扩色 | 锁 spr25 十色（本稿） / 每族 +1～2 专色 | **先锁十色跑一轮**，跑完看 D-E 违反率再决定加不加 | 加专色：跨族统一度下降，且 `shardbearer.png`/`wraithswarm.png` 不在可改范围内，新色永远追不上旧图 |

**另有两处请作者顺手点头/摇头**：①§6 三个新商人名「秤伯／担兄／背市」口味对不对（纯文案面，不合就换词）；②§7.2 十枚圣物改名（咬还/扎手/弹壁/挂霜/粗钝/续命匣/看痕/风铃牌/双挂件/满斗）——这批会进 `meta.gd`/`Relics` 显示名与 `FLAVOR["relics/*"]` 手记，`data.gd` 在冻结表内会变 md5，如实上报由我收官刷。

---

## 12. 本批明确不做（追加件版）

1. 不改任何图片的宽高（§3.2b 真源表就是"保现尺寸"的落盘形式）。
2. 不改任何 `.gd` 逻辑行，包括为了"适配新尺寸"而改 scale/offset——那是让我重新出单的信号，不是编程侧自行消化的事。
3. 不重画 `shardbearer.png` / `wraithswarm.png` / `浮游炮.png` / 瓦片 / 特效 / 应用图标（§8.1）。
4. 不把 SDXL 原始产物入库；三族同样过主稿 §4.5 原创性闸口。
5. 不让各族自己 median-cut 出自己的调色板（§5.2 那条是红线）。
6. 不引用小说未定稿情节/台词/章名，不挪用他作专名。
7. 本轮仍不写验证口径与实施单——等 U1–U5 + V1–V4 裁完一起点单。

---

## 13. 修订记录（2026-11-17 第二次落笔，回应编程侧卡点）

| # | 编程侧报的问题 | 我的处置 |
|---|---|---|
| R1 | §4.1.3「逐字节相同」× §4.2「原文照录」× §4.6.1「强化该句」三者不能同时成立 | 采**你建议的第 2 种**：新增 **§4.2b** 作现行唯一真源，§4.2 降级为历史对照件，§4.1 纪律 3 的比对目标改为 §4.2b。另补一句"逐字节判的是拼接后的运行时值，不是源码行排版"——原写法会诱导你去 diff 源码行，那是假红制造机。选第 2 种而不选第 1 种的理由：强化前后的差异本身要留档，将来若作者回退这条裁定，得有原句可对 |
| R2 | 逐张保尺寸的表要写死 | 新增 **§3.2b**。你实测的数字**逐条正确**（我读全部 59 个 IHDR 复核），表里只是补全了怪物族与 12×12／16×16 各档，并加了 `fill_w ≤` 列 |
| R3 | 三族 `frac`／`gap` 取值 + 悬空名单 + 与 `.gd` 偏移兼容性 | 见 **§4.5.2 / §4.5.3 / §4.5.4**。顺带算出两个你没报的缺陷：①`spr34_pixel.py:99` 的 `gap * s / float(SIZE)` 在非 32px 画幅上会让地平线漂移（chest 2→1、pedestal 2→1），已裁定改成末行直接贴边；②`frame()`／`to_pixel()`／`verify()` 整链硬编码方图 32×32，不先改这三处，道具族会在 `verify()` 被自家断言判 FAIL |
| R4 | §4.5 留白占比落成可机检区间 | 见 **§4.5.5**，含执令"顶满"的可证伪写法（≥0.86）、三条边界态、成对差分配对判据。图标档区间不是我拍的数，是量现存 36 张 16×16 得出来的 0.69–0.88 |
| R5 | 背景措辞是否换成"居中留边" | **不换**，`plain pure white background` 与"贴下边距"两句都原样保留。理由：`frame()` 第一步就 `getbbox()`，概念稿的空白在抠底后不存在，构图全由 `frac`/`gap` 重建——为一句不影响终态的措辞重跑一族不值。写在 §4.5.1 |
| R6 | 你引的行号有错（我这边也有一处） | `pedestal` 的偏移在 **`scripts/shop_stand.gd:33` `base.position = Vector2(0, 6)`**，磁盘上不存在 `position.y = 6` 这行；实稿 §4.5 旧表述已按磁盘改写。`secret_wall` 的横向鼓包量按"保尺寸"口径订正为 **+2px**（原写 +16px 是按"改成 32×32"算的旧账）。另：`FAMILIES["prop"]` 少列 `chest_*`/`door_*` 四件，`--family prop --all` 会静默少跑且不报错 |

**你的施工顺序批准**，只加一条前置：**§3.2b 的两条连带后果（非方图链路 + prop 缺成员）要在跑道具族之前落地**，否则第一张非方形图就会以 FAIL 收场，你会误判成新 prompt 有问题。怪物族整族重跑 20 张不受它影响（本来就 32×32），可以先跑。
