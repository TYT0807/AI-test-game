# SPR34 设计实稿 · 词汇层重写（六道卷正名 / 追加件二）

批次：Sprint 34（换皮线第二追加件，不另开批）
日期：2026-11-18
上游：`SPR34_设计实稿_六道怪物志换皮.md`（**主稿**）、`SPR34_设计实稿_人物族与道具族换皮.md`（**追加件一**）。
触发：作者原话——「为啥图片都是中世纪欧美风啊？跟我们的剧情有什么关系嘛？」
性质：**表层视觉词汇层。机制层零改动；尺寸口径、色表口径、机检判据一律继承，本件只改 prompt 的措辞。**
真源声明：🔴 **本件 §3–§7 覆盖主稿 §5.1/§5.2 的 SUBJECT 列与追加件一 §4.2b/§4.3/§4.4/§6/§7 的框架句和 SUBJECT 列**。覆盖之后，生成器常量的唯一真源是本件（见 §10 真源索引）。主稿的**结论性条款**（§3 Boss 分层、§4.3 D-A～D-D、§6 家族方案、§7 原创生物、§10 禁做清单）继续有效，未被本件改写。

---

## 1. 一句话

**跑偏不是审美问题，是词汇问题：框架句里的 `dark folk roguelike` 和三族 `<SUBJECT>` 里残留的欧洲符号词（tower shield / capital / staved cask / pedlar / iron-bound crate），在 SDXL 的文本编码端就把画面拉回了中世纪欧美。本件把三句框架重写成「中国/东亚民俗志怪」表述，把 39 条主体逐字换成《六道卷》自己的形象词，并把从图上肉眼数出来的欧美符号做成一组进 NEG 的排除项——判定标准只有一条：把这些词全删掉再重跑，审查表上不该再出现一件欧洲的器物。**

对作者那句问话的直接回答：**有关系，而且关系是反过来的**——游戏文案层（标题「六道拾痕录」、层名「往生脉/毒巢/静默层」、Boss 手记「天道之眼」「天道静虑」、玩家技能「人间拾痕」）早就绑死六道卷，是**视觉层单方面借用了 CC0 通用奇幻的欧洲壳**。本件是把视觉层拉回它自己该待的地方。

---

## 2. 病因（编程侧已实证，此处登记为设计依据，不重复复现）

| # | 事实 | 设计后果 |
|---|---|---|
| A | `spr34_gen.py:46-65` 的 monster SUBJECT 表是从 CC0 Tiny Creatures 的通用奇幻 id **直译**来的（goblin/orc/ogre/minotaur/beholder/skeleton_king/demon/dragon/knight） | 主稿 §5 已经换了显示名与新母题，但 **prompt 短语仍是按旧欧洲形象写的**——名字换了、画没换。这是本件要修的主漏 |
| B | 框架句三族都带 `for a dark folk roguelike` | "folk roguelike" 在训练分布里几乎等价于「欧洲中世纪地牢」。这一句是整族的向心力源头，必须换 |
| C | 追加件一 §6/§7 的人物与道具 SUBJECT 里有具体欧洲器物词：`tower shield`、`plain capital and base`（罗马柱头柱础）、`staved timber cask ... hoops`（箍木酒桶）、`pedlar`（中东/欧洲行商腔）、`iron-bound supply crate`、`ring pull`、`daub` | 这些不是氛围词，是**可数物件**，SDXL 会照画。审查表上的罗马柱、酒桶、圣爵就是从这几个词来的 |
| D | 审查表实测漏字：`chest_open` 图内出现 "LOW CULT" 字样 | 现有 `no text, no border` + NEG 首位 `text, letters, ...` **不够**，需加码（结论见 §6.4） |
| E | 项目已有两条视觉轨：程序化克制抽象几何（`shardbearer.png` 拾痕者 / `wraithswarm.png` 8 虫 / 全部 16×16 图标，本批不动）与 SDXL 具象概念稿 | 真实冲突，不能由我拍——交作者裁，选项与风险等级见 §8 |

🔴 **连带成本（必须写清）**：改框架句＝**整族重跑**。本批目标集是 **39 张**（怪物 20 ＋ 商人 3 ＋ 道具场景 12 ＋ 武器 4 ＋ 说明性差异见追加件一 §8.2），本地 ComfyUI 单张约 **20–24 s**，一轮全量约 **13–16 分钟** GPU 时间、**零积分**。⛔ 不要试图"只重跑看着最洋的那几张"——同族混两版框架必然发散（追加件一 §4.1 纪律 1），要么一族一起重跑，要么不改。

### 2c. 欧美符号 → 病源词 → 本件改法（对着作者那张审查表逐条对账）

| # | 审查表上看到的 | 病源（逐字定位到旧常量） | 本件改法 |
|---|---|---|---|
| B1 | `knight`＝板甲＋塔盾 | SUBJECT 里 `tower shield larger than its body, dense plate lamination`；NEG 里当时**没有任何**骑士/板甲排除项 | §4.4 → `tall lacquered wood shield ... dense lamellar plates laced with cord ... spear butt resting on the ground`；§6.1 NEG 加 `medieval knight, plate armour, tower shield` |
| B2 | `minotaur`＝希腊牛头人 | SUBJECT `bull-headed battering beast` 无文化坐标，裸词必出米诺陶 | §4.1 → 加 `yoked to a logging sled, rope harness across the chest`（套索拉木畜役）；§6.3 NEG 加 `minotaur of legend` |
| B3 | `beholder`＝D&D 眼魔 | SUBJECT 本身中性，缺排除项，模型自由发挥成原作形象 | §4.6 → 加 `a bronze mirror disc set into its crown`（铜镜＝天道之眼）；§6.3 NEG 加 `beholder dnd` |
| B4 | `dragon`＝有翼 wyvern | SUBJECT 已写 `wingless`，但 `dragon` 单词权重压倒否定义 | §4.1 → `no horns`＋`blunt stone-gall crown`＋`mossy back` 三重正面描述；§6.1 NEG 加 `winged dragon` |
| B5 | `imp`/`demon`＝羊角蝠翼基督教恶魔 | SUBJECT 无排除；`candle-flame motif on chest` 的 `motif` 是抽象词，被画成纹章 | §4.2/§4.3 → `single candle-flame trapped in a hollow chest cavity`、`blackened iron shackles on the ankles`；§6.1 NEG 加 `western demon, devil horns, pitchfork, imps with bat wings` |
| B6 | `wraith`/`flameskull`＝兜帽长袍修士／美式壁炉 | `hooded wraith` 裸词；`furnace mouth` 裸词 | §4.6 → 加 `damp funeral band tied across the hood`；§4.3 → `small standing brick furnace mouth, soot-glazed rim`；§6.1 NEG 加 `hooded monk robe` |
| B7 | `mush`＝红伞菇＋尖帽矮人 | SUBJECT `stout mushroom-dwarf`——`dwarf` 一个词就定了欧洲 garden gnome | §4.1 → `fungus-capped earth-sprite ... sprouting grain at its feet`；§6.3 NEG 加 `dwarf miner beard` |
| B8 | `prop_pillar`＝罗马柱（带柱头） | SUBJECT `squat dressed stone column with a plain capital and base`——`capital`/`base` 是古典柱式**术语** | §5 → `undressed stone pillar with a plain square plinth and a chamfered top, no carved capital`；§6.1 NEG 加 `greek column, roman column, classical capital, Doric order, Ionic order, Corinthian capital` |
| B9 | `prop_barrel`＝欧式箍木酒桶 | SUBJECT `staved timber cask with two rust-dim hoops`——`stave`+`cask`+`hoop` 三连 | §5 → `square-section timber water vat with four hooped bands ... grain drawn as hard planks`；§6.1 NEG 加 `wine barrel, wooden cask`，§6.2 加 `ceramic amphora` |
| B10 | `prop_totem`＝基督教圣爵＋石柱 | SUBJECT `carved waymarker post ... a small offering bowl`（碗形无任何约束）；`totem` 一词本身偏太平洋岛民而非东亚 | §5 → 加 `a red cloth strip tied near the top`（系红布做记号）＋`offering bowl lashed below it`；§6.1 NEG 加 `chalice, goblet`。⚠️ id `prop_totem` **不改**（§9b），只把它的形象从图腾柱改成路标柱 |
| B11 | `merchant_*`＝中东行商／欧洲农夫 | `pedlar`（英国民间挑贩词）＋`crate baskets`（板条箱）＋`oiled canvas` | §7 → `indigo-dyed cotton wraps / conical bamboo hood / folded account book / woven bamboo basket crates / cloth shoes`；§7 NEG 加 `middle eastern merchant arab trader, turban, fezz, toga, renaissance doublet` |
| B12 | `chest_closed/open`＝西式铁箍箱，且图内漏出 "LOW CULT" | SUBJECT `low iron-bound supply crate ... blank tally tag nailed on`——"钉个牌"就是在邀请模型写字 | §5 → `timber-plank storage chest ... blank paper tally seal pasted across it`（封纸代替挂牌）；文字三层加码见 §6.4 |
| B13 | 整体氛围＝欧洲地牢 | 三句框架各有 `for a dark folk roguelike`（`folk`→格林童话那一路，`roguelike`→地牢爬行）；旧材质段 `weathered cloth and bone textures` 只是材质词，不是文化坐标词 | §3.1/§3.2/§3.3 三句统一换成 `for a Chinese folk zhiguai bestiary of the Six Realms`，材质段分别换成麻布／纸／漆木／骨白与木板 |
| B14 | 矫枉过正的新风险（审查表上还没有，但换锚后一定会来） | 新锚含 `Chinese`，失败模式变成①和风②清宫戏/兵马俑③印度多臂神像 | §6.1 共用位加 `chinese imperial palace, dragon robe, terracotta warrior`；§6.3 族内加 `samurai kimono geisha, ninja mask, indian deity multiple arms` |

---

## 2b. 归道口径（先立规矩，再排表）

**为什么必须给「道」定口径**：现有代码里只有 4 个主题层带道名（`data.gd` FLAVOR：`themes/vein`=「往生脉。**人间拾痕**」、`themes/toxic`=「**畜生道场**」、`themes/abyss`=「**地狱道**旧客…」、`themes/silent`=「**天道静虑**」），`menu.gd:116` 标题就是「六道拾痕录」。**「层＝道」这件事今天只在文案层成立，视觉上不存在**。本件的归道就是把这条线补到剪影层，让美术去解释 UI，而不是反过来。

🔴 **三条硬规矩**（越界即返工）：

1. **归道 = 题材分组，不是出怪映射。** ⛔ 不许动 `FLOORS` 的 `pool`／`elite`、`SQUADS`、`BOSS_BY_FLOOR`、任何 `ai` 参数。一只「饿鬼道」形象的怪今天照样可能刷在毒巢层。本件只承诺：**图鉴按道分组展示、层关执令与其所在层的道对齐、手记文案可以提它的道来处**。
2. **道的读法走「气质」，不走服饰徽章。** 畜生道＝身体失控/兽形；饿鬼道＝匮乏贪食/空器；地狱道＝刑罚苦工/炉火锁绳；阿修罗道＝好战斗器/甲与墙；人间道＝当代民间规矩与纸活（本批唯一**刻意做出「非古风」**的一档）；天道＝规则本身（眼、镜、秤、文书、静）。所以「中式」≠「一律古装」——人间道那两只就该像今天的山里/镇上的人间杂物。
3. **允许创新反哺小说（作者 2026-11-17 已点头），但每条创新都要标「新造」**，并在 §9 汇总成一份给作者的回采原料清单。取既有设定的标「取设定」并写来源路径。

---

## 3. 新框架句（🔴 逐字节替换 `spr34_gen.py` 的三个常量）

### 3.1 `HEAD_MONSTER` 现行真源（覆盖主稿 §5 的 prompt 列与追加件一 §4.2b）

```
creature concept art for a Chinese folk zhiguai bestiary of the Six Realms, single subject, full body centered, plain pure white background, no cast shadow, no pedestal, no platform, no stand, no ground plane, bold readable silhouette, flat muted colors, limited palette, slightly desaturated, weathered hemp cloth, aged paper, lacquered wood and bleached bone textures, front three-quarter view, game sprite reference sheet, no text, no border, no floating parts
```

**受控差异表**（相对追加件一 §4.2b，其余词组一字不动，防"顺手改构图"）：

| 位置 | 旧 | 新 | 理由 |
|---|---|---|---|
| 第 6 词组 | `for a dark folk roguelike` | `for a Chinese folk zhiguai bestiary of the Six Realms` | 向心力源头。`zhiguai`（志怪）＋`bestiary` 把模型从"欧洲地牢"挪到"东方神怪谱"；`Six Realms` 是全批统一的世界观锚 |
| 材质段 | `weathered cloth and bone textures` | `weathered hemp cloth, aged paper, lacquered wood and bleached bone textures` | 四个材质词就是本批的视觉基因：麻布／纸（纸扎·纸钱）／漆木／骨白。`cloth`→`hemp cloth` 去掉粗棉麻布的西式感；新增 `aged paper` 是给 `faerie`（纸蝶）与人间道那两只的真材料 |

⚠️ **一处如实告知的风险**：`roguelike` 这个词本来还兼任「单体居中、平涂、参考表质感」的一部分权重。换掉后这个功能由保留下来的五句承担（`single subject` / `bold readable silhouette` / `flat muted colors` / `limited palette` / `game sprite reference sheet`）。**若重跑后普遍出现厚涂渐变**，处置是**整族再加一句** `flat shading, gouma print texture`（属框架级改动＝再一次整族重跑），⛔ 不许单张救。

### 3.2 `HEAD_PERSON` 现行真源（覆盖追加件一 §4.3）

```
character concept art for a Chinese folk zhiguai bestiary of the Six Realms, single subject, full body standing upright and centered with feet on the bottom margin, plain pure white background, no cast shadow, bold readable silhouette, flat muted colors, limited palette, slightly desaturated, weathered hemp cloth, lacquered wood and tarnished brass textures, front three-quarter view, game sprite reference sheet, no text, no border
```

受控差异：①`dark folk roguelike`→同一句新锚（与怪物族**逐字相同**，跨族不发散的主锚不能分叉）；②材质段 `weathered cloth, aged wood and tarnished metal`→`weathered hemp cloth, lacquered wood and tarnished brass`（`aged wood` 太泛、`tarnished metal` 太泛，正是它们让商人出成中东铜匠）。镜头／背景／剪影／配色／渲染五句**逐字未动**。

### 3.3 `HEAD_PROP` 现行真源（覆盖追加件一 §4.4）

```
game prop asset concept art for a Chinese folk zhiguai bestiary of the Six Realms, single object only, standing on the ground with its base on the bottom margin, plain pure white background, no cast shadow, bold readable silhouette, flat muted colors, limited palette, slightly desaturated, weathered timber plank, aged stone, frayed rope and tarnished brass textures, three-quarter side view, game sprite reference sheet, no text, no border
```

受控差异：①同一句新锚；②材质段 `weathered wood, aged stone, frayed rope and tarnished brass`→`weathered timber plank, aged stone, frayed rope and tarnished brass`。`wood`→`timber plank`（木板）是为了压住 `prop_barrel` 那一类"箍木桶"联想——板筑/板箱才是本批的木作语言，⛔ 别用 `barrel/stave/hoop` 这类词（见 §5）。姿态段与朝向段逐字未动。

### 3.4 三句共用的卫生条款（继承，不改）

- 背景措辞仍统一 `plain pure white background`（追加件一 §4.1 ⚠ 段的裁定原样有效，抠底仍用同一个 `key_background()`）。
- 三族共用 NEG 追加串**不变**，仍是追加件一 §4.2b 末块那一串：

```
, pedestal, display platform, product stand, ground plane, contact shadow, floating object, detached floating limbs
```

- 各族专属 NEG 追加串的**原有内容一项不删**，只做末尾追加（§6）。

### 3.5 `GRIDS`（执令顶满）与本件的关系（🔴 编程侧必读，别按旧写法跑）

`spr34_gen.py:95 GRIDS = {"skeleton_king","demon","dragon"}` 会在运行时给这三条追加 `, massive, fills the frame, towering presence`。本件**不改 `GRIDS`**（它不是词汇层），但把 `dragon` 的 SUBJECT 本体尾部也写了 `fills the frame`——这是**有意的冗余**（顶满语义在词表层再钉一次），落地后的完整 prompt 会出现两次该短语。裁定：**保留冗余，⛔ 不要为此删 `GRIDS`**（删它＝改构图纪律＝又一遍整族重跑）。若作者嫌重复，处置是把 `dragon` SUBJECT 尾部的 `fills the frame` 删掉并重跑该只，属单张级改动，不违反纪律 1（纪律 1 管的是框架句，不管 SUBJECT 细节）。
🔴 机检注意：§10.0 的 `count==1` 断言判的是 **SUBJECT 常量字符串本身**，不判拼接结果；`GRIDS` 那串追加短语不在真源比对范围内，⛔ 为它加断言。

---

## 4. 怪物族 SUBJECT 新表（20 条，按道分组）

> 🔴 id 键名一律不改（主稿 §10.1，联动清单见 §9b）。显示名列抄主稿既裁口径（U4 三字口语带因果）。每条格式：`id` → SUBJECT 逐字（英文一句）｜中文一行（归哪一道 + 取的是哪个母题 + 标「取设定」或「新造」）。
> 家族归属沿用主稿 §6 的五家族＋六独立，本件**没有**重开家族方案。

### 4.1 畜生道（身体失控 / 兽形，共 6 条：`orc` `minotaur` `plant` `slime` `dragon` `mush`；第 7 只 `wolf` 因排版放在 §4.1c）

`orc` → `broad square-shoulded brute in a coarse hemp skirt dragging a wooden ramming mallet, bowed head, mud-caked feet, low charging stance`
　｜畜生道·取设定（`D:\大纲\统一大纲\角色资料库\20_六道卷结构与人类实力境界.txt`：畜生道＝身体失控一侧的异常）。夯杵＝打夯的农具/工地具，不是武器；`mud-caked feet` 替掉欧洲蛮兵的靴子。⛔ 删除旧句里没有但模型会自己补的护甲片。

`minotaur` → `bull-headed battering beast yoked to a logging sled, horns worn bright at the tips, forequarters lowered in charge line, rope harness across the chest`
　｜畜生道·取设定。「牛头」在本土语汇里是**牛首人身的好脚力/拉纤畜役**，不是希腊迷宫怪物。加 `yoked to a logging sled`＋`rope harness` 把它钉成"套着套的拉木头的畜役"，一眼与米诺陶分家；`horned helmet` 那类迷宫梗一个词都不给。

`plant` → `low wide-mouthed bog flower rooted in a mud cake, thick stalk, serrated maw, pale fishbone veins on the petal rim`
　｜畜生道·取设定（沼泽瘴气／毒巢层）。`mud cake` 保留旧句（本就中性）；新增 `fishbone veins` 是唯一一处形态学记号，替代热带艳色（主稿 §5.1 风险栏：禁热带艳色，靠口器剪影）。

`slime` → `glossy bloated tar mound with a deep splitting seam, debris suspended inside, one sunken coin visible through the skin`
　｜畜生道·新造（形象层）。旧句 `slime mound` 直接招来 D&D 史莱姆味；`tar mound`（沥青洼）保住 split 记号（裂缝必须贯通轮廓，主稿 §5.1）同时把质感挪到工地上能看见的东西。`sunken coin`＝肚里吞过东西，给分裂体一点"它吃过"的信息，是「皆代价」的物质化写法。

`dragon` → `wingless serpent-dragon coiled like a hill ridge, stacked segment scales brightening toward the crest, blunt stone-gall crown, mossy back, no horns, fills the frame`
　｜畜生道·取设定。执令级顶满画幅（主稿 §4.4）。`wingless serpent-dragon` 旧句已有，本条把它做实：`blunt stone-gall crown`（钝石瘤冠＝脊端石瘤，主稿既裁顶饰；英文用 `stone-gall`＝结石/石瘤，⛔ 别写中文"瘤"字混进 prompt——那是给模型喂乱码）、`mossy back`（背生苔＝山丘误认）、`no horns`（不给西龙角冠，也不给东龙的鹿角焰珠，避免落进任一现成龙样）。尾部 `fills the frame` 是**执令顶满的 SUBJECT 位写法**，见 §3.5。

`mush` → `stout fungus-capped earth-sprite under a broad draped-cap, tiny spore-buds budding at its hem, stubby hands, sprouting grain at its feet`
　｜畜生道·取设定（孢子侏＝菌与谷同源的"地气所生"）。**两处改动**：①`mushroom-dwarf`→`fungus-capped earth-sprite`——旧词把欧洲童话 garden gnome 的形（尖帽＋红伞菇）整个拽进来，审查表上那张矮人味就是从 `dwarf` 来的；②新增 `sprouting grain at its feet`（脚边冒谷芽），一是替掉菇伞的西方标识，二是给"谷物/收成"这层本土含义，它也是 `summon` 记号（幼芽 ≥3）的补充。**幼芽是记号不是装饰**这条判据不变（主稿 §5.1）；`mini`（幼体）在 8 虫轨，⛔ 别混画。

### 4.1c 畜生道补录（第 7 只，排版续 §4.1）

`wolf` → `lean four-legged hound-beast crouched mid-pounce, haunches raised, neck extended low, cropped ears, rope collar with a small brass bell`
　｜畜生道·取设定（疾爪＝乡野细狗，不是林狼）。旧句本身没有欧洲词，但出图偏灰林狼——因为 `wolf` 这个词的训练分布就是北美灰狼。改成 `hound-beast`（猎犬种）并加两个土著标识：`cropped ears`（剪耳，中华细狗的传统处理）＋`rope collar with a small brass bell`（绳圈项带铜铃，接项目在册的「残响悬铃」意象，跨族母题钉）。`leap` 记号仍由后腿蹬地压缩态承载。⚠️ 铃铛在 32px 上必须读得出，否则退回无铃版。

### 4.2 饿鬼道（3 条：匮乏、贪食、空器）

`goblin` → `gaunt hunched scavener clutching a cracked earthenware jar, overlong knuckles, tattered sackcloth, ribs showing through the skin, full-body silhouette`
　｜饿鬼道·取设定（饿鬼＝匮乏之身）。`jar`→`earthenware jar`（粗陶罐）是关键一改：旧句的 `cracked jar` 会被画成玻璃瓶或陶双耳瓶。`ribs showing`＝"腹大咽细"的饿鬼相用剪影说，不用宗教造像说。

`imp` → `moth-thin imp with jagged folded wings, errant darting pose, ash-grey body, single candle-flame trapped in a hollow chest cavity`
　｜饿鬼道·取设定（趋火不得饮）。旧句 `candle-flame motif on chest` 的 `motif` 是抽象词，模型给了个纹章；换成 `trapped in a hollow chest cavity`（胸腔是空的，里面困着一豆火），既是灯蛾的战术提示（ erratic＋会扑火），也是饿鬼的形状。⛔ 严禁羊角蝠翼小恶魔（NEG 已加，§6.1）。

`vampire` → `leech-bellied slender humanoid mid-lunge, trailing umbilical sac, gaunt limbs, flat featureless head, hairline suture seams across the neck`
　｜饿鬼道·取设定（虫族边缘种，主稿 §5.1 边界写法）。`drain` 记号靠脐囊亮边（不变）；新增 `hairline suture seams across the neck` 把"吸血"从贵族怪谈改成**被缝起来的东西**，同时喂给 HEAD 的 `aged paper/hemp` 材质轨。⛔ 尖牙披风古堡腔（主稿原文禁令，本件加 NEG `gothic` 兜底）。

### 4.3 地狱道（4 条：刑罚、苦工、炉火）

`skeleton` → `bleached rope-lashed skeleton, stiff upright posture, no face, plain round skull, straw-and-mud residue at the joints`
　｜地狱道·取设定（被驱使的苦役）。`rope-lashed` 是骨架家系的家族徽章（主稿 §6），保留；新增 `straw-and-mud residue`（草筋泥）是本土修缮材料，替掉欧洲骷髅的坟土味，也接住 HEAD 的 `aged paper/hemp`。

`skeleton_king` → `towering skeleton overseer with a rag banner staff dragging behind, antler-like rib-crown, rope lashings, ink-brushed name talismans pinned to its ribs`
　｜地狱道·取设定（提骨＝管名册的那个）。执令级顶满画幅。`bone banner`→`rag banner`（破布幡：引魂幡的形状，⛔ 不许出现十字/纹章）；新增 `ink-brushed name talismans`＝**朱砂墨笔的名条**，直接对上项目已有的「纳名」轨（`D:\大纲\统一大纲\剧情文件\02_畜生道·剧情分化.md` 第一卷「纳名路线确立」）。⚠️ 名条是**空白或模糊笔画**，一旦出字就违反 §6.4，故同时在 NEG 加 `readable characters`。

`flameskull` → `skull embedded in a small standing brick furnace mouth, jaw propped on ground, ember glow inside only, soot-glazed rim`
　｜地狱道·取设定（守炉头＝灶/炉口的哑骨）。`furnace`→`brick furnace`（砖砌炉口）：旧句的裸 furnace 出成铸铁美式壁炉。它是全批唯一"亮部在体内"的设计（天然抗 tint，主稿 §5.1），`soot-glazed rim`（烟釉边）给这团亮一个物理理由。

`demon` → `hoofed cinder-bodied colossus wearing a crown of guttering candles, cracked coal-hide, embers shedding, blackened iron shackles on the ankles`
　｜地狱道·取设定（踏炭＝炭壳聚合体，归虫族）。执令级顶满画幅。⛔ 羊角红皮基督教恶魔（主稿原文禁令）。新增 `blackened iron shackles`＝锁链刑具，是地狱道的形状而非恶魔学的形状；`crown of guttering candles` 保留（烛冠=召崽记号，绑 `summon: imp`）。

### 4.4 阿修罗道（2 条：好战、斗器、墙与甲）

`knight` → `faceless armored sentinel with a tall lacquered wood shield taller than its body, dense lamellar plates laced with cord, narrow eye slit only, spear butt resting on the ground`
　｜阿修罗道·取设定（铁面＝甲士）。**本条是全批最要害的一处修正**：旧句 `tower shield larger than its body` 里 `tower shield` 是中世纪盾牌专有名词，`dense plate lamination` 是板甲工艺词——两个词一起决定了那张审查表的骑士味。换成 `lacquered wood shield`＋`lamellar plates laced with cord`（札甲以绳编缀）＋`spear butt resting on the ground`（长枪拄地），甲的战术语义（armor 0.7 ⇒ 绕后）与"盾大于身"的剪影都保住，工艺词整体换轨。

`ogre` → `towering bulk wrapped head to toe in layered quilted padding and lacquer scales, every seam covered, no visible skin, shoulder pole braced across the back`
　｜阿修罗道·取设定（裹城＝无死角缠裹的重障）。与铁面的区分照主稿：铁面有方向性（盾+面甲），裹城没有。新增 `quilted padding`（棉絮叠甲，中式绵甲）＋`lacquer scales`（漆甲片）替掉旧句的 `hide armor`（欧洲皮甲）；`shoulder pole braced across the back` 给它一个"扛"的剪影特征，也接住跨族杆秤母题。

### 4.5 人间道（2 条：当代民间规矩与纸活 —— 本批刻意「非古风」的两只）

`zombie` → `bloated slow shambling corpse-mound in a rain-soaked padded jacket, arms hanging, sodden wadded cloth, rounded heavy silhouette, muddy boots`
　｜人间道·取设定（沉疴＝拖在身上的病与雨）。**这是本件唯一明确做出"当代"的怪**：人间道卷是当代中文规则怪谈（`D:\大纲\统一大纲\剧情文件\01_人间道·剧情分化.md` 卷定位），所以这只穿 `rain-soaked padded jacket`（湿棉袄）而不是欧洲农民破衫。`muddy boots` 保留胶鞋味。⚠️ 与 shardbearer 的 canvas coat 撞型风险见 §8 W2。

`faerie` → `torn joss-paper butterfly sprite, angular folded paper wings, drifting low flight, faded printed edges, bamboo rib showing through the tear`
　｜人间道·取设定（纸钱蝶＝随风、易燃、不值钱三面，主稿 §5.1 的民俗口径原样有效）。新增 `folded paper wings`（折纸翅，纸扎手艺的形状语言）＋`bamboo rib`（竹篾骨架——纸扎的骨架就是竹篾，见 `D:\大纲\统一大纲\角色资料库\37_阿婆（纸扎婆·问事人）.txt` 的手艺描述）。这条是「纸活」进本批视觉基因的钉子户。

### 4.6 天道（2 条：规则本身——眼、镜、秤、文书、静）

`wraith` → `hooded wraith with two long dripping sleeves, no feet, translucent pale mist body, void face, a damp funeral band tied across the hood`
　｜天道（雾区／静默层）·取设定（湿袖＝滴袖意象，主稿最想反哺的一只）。`void face` 保住 float 记号；新增 `damp funeral band tied across the hood`（一条湿白带系在兜帽上）——**白三角/白孝的剪影等价物**，是人间道「三块白三角」母题的**抽象化转写**（只取颜色与"系着"这个动作，⛔ 不落事件与台词）。⚠️ 这条带子必须在 32px 上读得出，否则退回旧句。

`beholder` → `floating spherical sac studded with many open eye sockets of varying sizes, pale veined shell, a bronze mirror disc set into its crown`
　｜天道（星区）·取设定（百目胎＝观测/映照）。⛔ 与任何原作眼魔零关联（主稿 §5.1 红线原样有效）。旧句本身没有欧洲词，本条只加一枚 `bronze mirror disc`（铜镜盘，嵌在顶上）——**镜＝天道之眼**，与项目在册文案 `bosses/prism_warden`「守望者。**天道之眼**」（`scripts/data.gd:368`）对上；眼窝数 ≥5 的弹幕判据不变。

### 4.7 覆盖清点（🔴 权威计数，与 §4.1–§4.6 各小节标题里的"几条"若冲突，以本节为准）

畜生道 **6**（`orc` `minotaur` `plant` `slime` `dragon` `mush`）＋ `wolf`＝疾爪同属畜生道 → **畜生道共 7 只**；饿鬼道 **3**（`goblin` `imp` `vampire`）；地狱道 **4**（`skeleton` `skeleton_king` `flameskull` `demon`）；阿修罗道 **2**（`knight` `ogre`）；人间道 **2**（`zombie` `faerie`）；天道 **2**（`wraith` `beholder`）。
合计 7＋3＋4＋2＋2＋2 ＝ **20 条**，与 `spr34_gen.py:SUBJECTS["monster"]` 的 20 个键逐一对应（`shadow`/echo 不在生成队列，主稿 §5.3/U5）。执令三只（`skeleton_king`／`demon`／`dragon`）分别在 hell／hell／畜生，与 `BOSS_BY_FLOOR` 的 floor2/floor3 对应关系不变。
🔴 **道数不等不是缺陷**：道是题材分组，出怪映射属机制面（§2b 规矩 1）。若将来要做「某层只出某道」，那是另一批的单子。

---

## 5. 道具族 SUBJECT 新表（16 条）

> 🔴 成对差分件（`chest_closed`/`chest_open`、`door_closed`/`door_open`、`prop_barrel`/`prop_barrel_hit`）的**配对判据原样继承**：两图 bbox 左上角差 ≤1px、宽高差 ≤1px（追加件一 §4.5.5 边界态 3）。手法仍是"同一段主体描述＋只改状态从句"（`same ...` 开头），⛔ 不许在成对件里改器物种类。
> 画幅与路线列不动（追加件一 §3.2b 真源表），本件只换措辞。

| id | 画幅 | SUBJECT 逐字（新） | 中式对应物一句话 |
|---|---|---|---|
| `chest_closed` | 20×16 | `low timber-plank storage chest with a raised lid bound by two iron bands, closed hasp with a blank paper tally seal pasted across it, rope lashings crossing the top` | 木板匣＋**封纸**（白纸浆封条＝"没人开过"的可读证据，比挂个牌更贴） |
| `chest_open` | 20×16 | `same low timber-plank storage chest with the lid thrown open, empty interior shown as one flat dark band, torn paper tally seal still on the rim, contents suggested by a single rim highlight` | 同一件，封纸**被撕破但仍粘在沿上**（开合只差状态，外形尺度逐字同源） |
| `door_closed` | 32×28 | `plank door set in a timber frame, cross braces, a brass ring pull, seams sealed with daub, threshold stone at the foot, no handle ornament` | 门板上加**门槛石**（`threshold stone`）——进门这件事在规则怪谈里是边界，门槛是最省字的边界记号 |
| `door_open` | 32×28 | `same plank door swung inward revealing a black rectangular void behind it, identical frame, hinge positions and threshold stone` | 同一件，门槛留在句尾（防成对件里门槛忽有忽无造成 bbox 抖动） |
| `stairs` | 32×32 | `rough-cut stair mouth descending into solid black, one handrail of tied timbers, a red paper notice pasted beside the top step` | 顶阶那盏西式吊灯换成**贴在墙上的红纸告示**（施工/禁止通行的红纸＝当代山里最常见的"这里有规矩"信号）。跨族母题钉从"矿灯"改挂到"红纸"，与 §7 的 `secret_wall` 成套 |
| `pedestal` | 16×22 | `short stone counter block with a worn top slab, chisel marks, a blank wooden price tablet standing on the top edge` | 空白铜牌 → **立在沿上的空白木牌**（柜台挂牌是铺子的读法；`blank` 保留，防出字） |
| `secret_wall` | 32×32 | `wall panel of stacked brick whose mortar joints are drawn slightly fresher and lighter than the surrounding course, a half-burned red paper scrap pasted at the lower corner, one loose stone` | 砖墙＋**烧剩半张的红纸**（祭祀痕迹当"这里被人动过"的线索）。🔴 仍须先对 `瓦片.png` 取样再定砖纹（追加件一 §7.1） |
| `prop_barrel` | 32×32 | `square-section timber water vat with four hooped bands and a fitted lid, standing upright, grain drawn as hard planks` | 箍木**圆桶** → 方材拼的**水缸/水桶**（`square-section ... planks` 强制板构，⛔ 不许出现 staves/cask/hoops 那套酒桶词，见 §6.2） |
| `prop_barrel_hit` | 32×32 | `same square-section timber water vat split along one plank seam, a wedge chip knocked out, splinter edges drawn as hard steps, water staining the foot` | 同一件，裂一条板缝＋渗水渍（破损只改状态） |
| `prop_pillar` | 32×32 | `squat undressed stone pillar with a plain square plinth and a chamfered top, hairline crack running one course, no carved capital` | 罗马柱 → **素面石柱**：`undressed`（未雕饰）＋`square plinth`（方础）＋`chamfered top`（斜切顶），句尾再明写 `no carved capital` 把柱头堵死 |
| `prop_spike` | 32×16 | `row of short forged iron spikes lying flat in a timber track, tips all pointing the same way, blunt wear on each point` | 保留横条刺（`prop.gd:38` 的 position 账不变），只把 `floor track` 换成 `timber track`（木槽），免得它出成欧式地刺栅栏 |
| `prop_totem` | 32×32 | `carved waymarker post on a stone base, three stacked carved bands, a red cloth strip tied near the top, a small offering bowl lashed below it, planted firmly on the ground` | 圣爵+石柱 → **路标木柱**：加 `red cloth strip tied`（系红布条＝做记号），供碗从"杯/爵"形制降级成一只粗碗。⛔ 基督教圣爵味（`chalice/goblet` 全进 NEG） |
| `wpn_rifle` | 32×16 | `a long lean shoulder gun with a wooden stock, single barrel, bead-sight at the muzzle, laid horizontally muzzle-right` | `ring-sight`→`bead-sight`（准星）；`hand-cannon`（手持炮）虽是中国-origin 词但训练分布里出成欧洲手铳插图，`shoulder gun`（抬枪/火绳杆枪的直译）更稳 |
| `wpn_shotgun` | 32×16 | `a stubby wide-mouthed breaker gun with a ribbed double-thick muzzle, laid horizontally muzzle-right` | 原句保留（`breaker gun`＝土制砸枪，无欧洲包袱，且审查表上这张没跑偏） |
| `wpn_railgun` | 32×16 | `a long twin-railed magnetic lance with two parallel guide bars and a bare coil section, laid horizontally muzzle-right` | 原句保留（纯机构描述，主稿追加件一 §10 已自查过：不指涉任何具名武器） |
| `wpn_launcher` | 32×16 | `a fat short shoulder mortar with an oversize bell muzzle and a drum of charges behind it, laid horizontally muzzle-right` | 原句保留（`mortar`＝迫击炮，近现代兵器，与"当代人间道"同轨，不算欧美中世纪符号） |

🔴 `laid horizontally muzzle-right` 四件武器的**族内强制项**原样有效（追加件一 §7.3）。

---

## 6. 负面词（进 `NEG_SHARED` 还是族内 `NEG_EXTRA`）

### 6.1 三族共用（🔴 追加到 `NEG_SHARED` 末尾，一次到位）

```
, medieval knight, plate armour, tower shield, crusader templar heraldry, european heraldic crest, coat of arms, greek column, roman column, classical capital, Doric order, Ionic order, Corinthian capital, wine barrel, wooden cask, chalice, goblet, gothic, celtic, norse vikings, rune stones, winged dragon, western demon, devil horns, pitchfork, imps with bat wings, hooded monk robe, latin script, alphabet letters, readable characters, chinese imperial palace, dragon robe, terracotta warrior, unicode placeholder glyphs
```

放共用位的理由：**这三句框架现在都含 `Six Realms`／`Chinese`**，加了地域锚之后，新的失败模式恰好是三族共同的两种——①掉进**西方奇幻**（前面那串），②矫枉过正掉进**清宫戏/兵马俑式中国刻板**（最后四条）。第二种只有"已经决定做中国风"的 prompt 才会犯，所以它属于共用位，不属于某一族。⚠️ `unicode placeholder glyphs` 是卫生项：本仓文档曾出现过中英混排 token（如把"石瘤"直写进英文 prompt）被模型烤成乱码字形的情况，本件已统一改为纯英文构词（`stone-gall crown`），这一条负面词防的是**复发**。

### 6.2 道具族追加（`NEG_EXTRA["prop"]` 末尾）

```
, glass bottle, ceramic amphora, iron nail exposed, padlock, modern plastic container, rusted chain fence, wrought iron gate, cobweb
```

理由逐条：`glass bottle`/`ceramic amphora`＝`chest`/`vat` 句里"容器"语义最容易滑过去的两种西方器形；`iron nail exposed`/`padlock`＝宝箱最容易自己长出西式挂锁与外露钉帽（我们用的是封纸与扣襻）；`modern plastic container`＝道具族出现塑料件就是时代穿帮；`rusted chain fence`/`wrought iron gate`＝防 `prop_spike` 出成欧式铁栅栏；`cobweb`＝防"废弃"语义被画成哥特地窖。原有四项（`human figure, creature, animal, hands, room interior, floor tiles, wall, glowing runes`）**一项不删**。

### 6.3 怪物族追加（`NEG_EXTRA["monster"]` 由空串改为下面这串）

```
, humanoid with animal head maze myth, minotaur of legend, beholder dnd, slime jelly monster cartoon, vampire castle noble, werewolf, elf ears, dwarf miner beard, angel wings halo, samurai kimono geisha, ninja mask, indian deity multiple arms, slavic folklore spirit, fungal zombie spore cloud, muscle fantasy barbarian armor, bikini armor, fur loincloth savage
```

理由：怪物族的失败模式是**具体的他作/他乡形象**，与道具族的"器物"不同类，塞进共用位会让道具/人物每次多背 17 个无关 token（CLIP 77 token 预算有限，谁用谁挤掉自己的有效词）。逐项堵的是：`minotaur of legend`（§4.1 牛头）、`beholder dnd`（§4.6 眼魔，主稿红线）、`slime jelly cartoon`（§4.1 分瘴）、`vampire castle noble`（§4.2 引血蛭）、`samurai kimono geisha`/`ninja mask`（**日式**是中式锚最容易顺带拽出来的邻居，必须单独排除——本批要的是中国民俗志怪，不是和风）、`indian deity multiple arms`/`slavic folklore spirit`（六道/轮回视觉语汇在训练分布里高度绑定印度与斯拉夫，两个都得堵）、`bikini armor`/`fur loincloth savage`（奇幻男性向默认姿势）。`werewolf`/`elf ears`/`dwarf miner beard` 是残响清理。

### 6.4 文字漏出的加码（🔴 结论：**要加，且三层一起加**）

`chest_open` 出 "LOW CULT" 证明现有 `no text, no border` + NEG 首位 `text, letters, watermark, signature, logo` **不足以拦住"看起来像标签"的东西**——因为我们的道具句里主动要求了 `tally tag`/`price plaque`/`notice` 这类**承载信息的表面**。三层处置：

1. **NEG 层**：共用串已加 `latin script, alphabet letters, readable characters`（§6.1）。
2. **HEAD 层**：⛔ 本批**不**往三句框架里再加文字相关句（框架每改一次＝整族重跑；§6.1 的负面词已覆盖，先用便宜的一层试）。
3. **SUBJECT 层（真正的修法）**：凡需要"标记"的表面，措辞一律写成**空白或不可读**——本件已逐条落实：`blank paper tally seal`（匣）、`blank wooden price tablet`（柜台）、`half-burned red paper scrap`（密室墙，烧剩的纸读不出字）、`ink-brushed name talismans`（提骨，笔画而非字）、`red cloth strip`（路标，纯色布无文）。⛔ 今后任何新条目不许出现 `label/sign/inscription/word` 类词。
4. **机检层**：文字属**人工目视闸**，不进 D-E（色集合判据抓不到字）。入库前每张过一遍"有无任何可辨字符"，发现即返工并在台账记 id。

---

## 7. 人物族（`merchant_0/1/2`）

**他们是谁**（设计口径，不是 prompt）：三位都是**客栈/山货路上的行商**，做的是"记账的买卖"——不卖英雄装备，卖你今晚用得上的东西，并且每一笔都留痕。这与项目在册的「拾痕者／记录员／台账」母题同源（`scripts/player.gd:1497`「人间拾痕」；追加件一 §4.3 无名记录员口径），也与小说侧「秦老板坐镇客栈、以规矩换生存」的气质相接（`D:\大纲\统一大纲\角色资料库\13_秦老板（秦拙）.txt`，**只取"守规矩的生意人"这一属性，⛔ 不取事件与台词**）。三档递进仍走追加件一 V2 既裁的**配件递进**（杆秤恒定 → 背篓 → 扁担双筐 → 被货笼压弯），⛔ 不分民族志服饰、⛔ 不分体型。

| id | 显示名 | SUBJECT 逐字（新） | 相对旧句的关键改动 |
|---|---|---|---|
| `merchant_0` | 秤伯 | `hunched ledger pedlar in layered indigo-dyed cotton wraps, a wide conical bamboo hood shading an absent face, spring balance scale with two empty pans held forward, a folded account book strapped to the back, cloth shoes` | `oiled canvas`→`indigo-dyed cotton`（蓝染粗布）；`conical hood`→`conical bamboo hood`（笠）；`ledger board`→`folded account book`（**折页账本**，"记"的道具终于成型）；补 `cloth shoes`（布鞋）——旧句光脚/靴都可能 |
| `merchant_1` | 担兄 | `standing hawker with a shoulder pole and two hanging woven bamboo basket crates, coiled rope at the belt, folded cloth cap over a featureless head, crouched ready posture` | `crate baskets`→`woven bamboo basket crates`（**竹筐**）——旧句的 `crate` 出成欧洲板条箱，这是那张"中东行商"味的另一半来源 |
| `merchant_2` | 背市 | `bulk pedlar crushed under a lashed-together cargo cage of woven bamboo and plank on the back, plank spine brace, one arm raised holding a brass weigh-tag, no face inside the hood` | `cargo cage`→`cargo cage of woven bamboo and plank`（竹木货笼）；`brass weigh-tag` 保留（牙牌/砝码牌，本就是本土件，审查表上没跑偏） |

人物族 NEG 追加（`NEG_EXTRA["character"]` 末尾）：

```
, middle eastern merchant arab trader, turban, fezz, toga, renaissance doublet, leather apron, cowboy hat, top hat, military uniform, epaulettes, backpack straps modern
```

理由：`pedlar/hawker` 这两个词在训练分布里指向中东—欧洲集市行商（正是审查表上那三位）。⛔ 光加"中式"锚不够，必须把这三位原来的词义邻居点名排除。`military uniform, epaulettes` 顺带堵住 §3.1 那个 `sentinel` 类军装腔外溢到人物族。原有八项（`visible face … chrome shine`）一项不删。

---

## 8. 判断栏（交作者裁定，我不拍）

### W 组：两套视觉语言怎么共存（作者那句话真正的问题）

现状：程序化**克制抽象几何**轨（`shardbearer.png` 拾痕者 160×288、`wraithswarm.png` 8 虫 96×192、全套 16×16 图标，spr25 十色，屏上面最大、每房都在）vs 本批 SDXL **中式民俗志怪具象**轨（39 张）。两者在**造型密度**与**材质叙事**上根本不同：前者靠几何与留白，后者靠剪影与器物细节。

| 选项 | 做法 | 工时 | 风险等级 | 能否回滚 |
|---|---|---|---|---|
| **W1 分区共存**（本件默认写法） | 本批 39 张走中式具象；`shardbearer`/`wraithswarm`/图标/浮游炮/瓦片**一律不动**。只在色表（D-E）与占比（追加件一 §4.5.5）层面强制成套 | 本批既定量（39 张 ≈ 13–16 min GPU ＋ 后处理） | 🟡 **中**：屏幕上会出现"抽象几何的玩家＋具象民俗的怪"，违和感可见但可控；玩家第一眼读的是剪影与明度，未必读成"两种画风" | ✅ **完全可回滚**：本件只改 `_tools/*.py` 里的字符串常量，PNG 未入库前一切可退；已入库则同名覆盖回旧 PNG 即可（id/路径不变） |
| **W2 全面具象化** | W1 ＋ 追加一批：`shardbearer` 图集九行重画、`wraithswarm` 8 虫重画、浮游炮重画 | 图集扩容与 region 硬编码属**机制面**（追加件一 §2③、§8.1；主稿 §3 同款爆炸半径），需另开美术批＋验证口径 | 🔴 **高**：①`w_rect()`/九个 row 常量/`TURRET_FRAME_A` 全动；②E1 指纹与 churn 大面积漂移；③拾痕者是项目辨识度最高的一张脸（虽然没脸），改了等于改正典 | ⚠️ **半可回滚**：PNG 可回，但 `.gd` 常量与冻结表 md5 一旦变，回滚要走一次完整门控回归 |
| **W3 反向收敛（推荐尝试的低成本折中）** | 39 张仍重跑，但**把"具象度"往下压一档**：SUBJECT 里删掉所有装饰性细节从句（如 `straw-and-mud residue`、`fishbone veins`、`water staining the foot`），只留「一类物＋一个剪影特征＋一个记号」，让新图向 spr25 的几何语言靠拢 | 与 W1 同量（同一次重跑，只是 prompt 更瘦） | 🟢 **低**：不碰任何机制面；风格离散度反而下降（细节越少，量化到 10 色后损失越小，D-C/D-E 更好过） | ✅ **完全可回滚**：与 W1 同一开关——改回字符串即可 |
| **W4 彻底抽象化** | ⛔ 放弃 SDXL 具象路线，39 张全部改程序化绘制（回到 spr25 范式手写像素） | 39 张 × 手写＋自检，估计数个工作日人力（GPU 时间归零） | 🟢 风格统一度**最高**；🔴 但设计产能成为瓶颈，且扩散模型的结构暗示红利（尤其 §5 那 4 件 32×16 武器）全部拿不到 | ✅ 可回滚（本批未入库） |

🔴 **我对 W 组的立场（供参考，不替你定）**：W3 > W1 > W4 > W2。理由是 §4.3 的 D-C/D-E 判据一直在跟"细节太多"打架——**跑偏的解法和糊化的解法是同一个解法**（都指向"少画点"）。W2 我明确不建议在本批做。

### N 组：新造形象要不要反哺小说

本件 §4 标了「新造」的有 2 条（`slime`→沥青洼吞钱、`zombie`→湿棉袄），加上主稿 §7 的 4 只（失名/还债灯/拓凶/香尽童子）共 6 条候选。

| 选项 | 做法 | 风险 | 回滚 |
|---|---|---|---|
| **N1 不回采** | 游戏侧自娱，小说正典零变动 | 🟢 零风险；🔴 浪费作者已给的"可反哺"授权 | ✅ 无副作用 |
| **N2 列备忘，作者自愿取用**（本件默认） | 我把 6 条整理成一份《设定反哺备忘》落在 `test-1/production/sprint-34/`，**不写 `D:\大纲` 一个字**，作者要取自己搬过去走小说侧工序 | 🟡 备忘可能与作者后续设定打架（届时以小说侧为准，本件文档标注"游戏侧提案"） | ✅ 完全可回滚（纯文档） |
| **N3 要求作者回采** | 把新形象升格为六道正典的一部分 | 🔴 我在素材侧是外人，无权推动那边台账/备份制；且情节未定稿期把游戏形象固化进正典，等于替作者定稿 | ⚠️ 难回滚（一旦入正典，两侧都要改） |

### Q 组：人间道到底要不要"当代"

§4.5 的 `zombie`（湿棉袄）与 `stairs`（红纸告示）是本批仅有的两处**当代/非古装**信号，来自小说侧「人间道＝当代中文规则怪谈」的定位。

| 选项 | 做法 | 风险 | 回滚 |
|---|---|---|---|
| **Q1 保持全古代民俗** | 把这两条改回 `sodden wrapping cloth` / `hanging lamp bracket`（旧句） | 🟡 世界观上与文案层「往生脉/人间拾痕」并不矛盾（游戏从未明写时代），但会丢掉"规矩怪谈"的时代感；且 `faerie` 的纸钱、`skeleton_king` 的名条仍是民俗件，整体不会更统一 | ✅ 改回字符串重跑一族 |
| **Q2 承认时代混杂**（本件默认） | 保留当代信号，并在手记层不解释、不圆 | 🟡 玩家可能觉得"一会儿古代一会儿现代"——但本作本来就是"异常"题材，时代错位可以是特征；🔴 若作者认为这是 bug 而非特征，需要收回 | ✅ 同 Q1 |
| **Q3 显式设定为「时代不祥」** | 在游戏内一句话把混杂写成规则（例：层里什么都可能是哪个年代的，取决于它被记住的方式） | 🟡 纯文案面（T3/T4 通道，`data.gd` 会变 md5，如实上报）；但它是一条**新世界观断言**，会约束以后所有文案与美术 | ⚠️ 文案可回滚，但一旦玩家接受这条设定，后续撤回有认知成本 |

**另有两处顺手点头/摇头**：①§6.1 那串共用负面词是否同意整体进 `NEG_SHARED`（不同意就退回族内，代价是三族各背一份、易漏配）；②§4.6 `wraith` 那条"白孝带"要不要保留（它是最容易读出丧事含义的一处，也可能显得不敬——保守做法是删掉这六个词）。

---

## 9b. 🔴 改名联动清单（本件结论：**只换图与显示名，绝不换内部 id**）

**结论**：本批 **20 个怪物 id、16 个道具 id、3 个人物 id 一个都不改**（主稿 §10.1 原样有效）。理由与联动面如下——

| 环节 | 位置 | 若改 id 会怎样 |
|---|---|---|
| ① PNG 本体 | `resources/texture/monsters/<id>.png`（怪物 21 张）／`resources/texture/generated/<id>.png`（道具/人物/武器） | 文件名即 id，改名＝新增文件，旧文件变孤儿或被误删 |
| ② 装载名单 | `scripts/assets.gd:102 MONSTER_NAMES`（21 项）／`:109 GEN_NAMES`（含 prop/merchant/wpn/icon 全系） | 🔴 **静默白框零报错**：`monster_frames()` 在 `tex == null` 时回落 `white_tex`（`assets.gd:169-171`），名单漏项不会报错，只会画出一块白。这正是 `GEN_NAMES` 注释里那条历史教训（`assets.gd:124`「PNG 已生成，未登记 = Assets.g() 返回 null → 静默白框」） |
| ③ 引用点 | `scripts/data.gd ENEMIES[*].tex`（`:26-85`）＋ `SQUADS` 成员键 ＋ `BOSS_BY_FLOOR` ＋ `FLAVOR["enemies/<id>"]` 键 ＋ `CODEX_*` 图鉴登记 ＋ `validate.gd`/`menu.gd`/`player.gd`/`slug.gd`/`game_main.gd` | 主稿 §2 事实 D 实测约 **106 处引用**。任一处漏改＝图鉴空、掉落错、探针红 |
| ④ 门控 | 34 文件冻结表（`data.gd`/`assets.gd` 在内）＋ E1 指纹 + churn | 改 id 会让大量断言行位移，churn 对比失去意义，等于把一次换皮批变成一次重构批 |

**因此本批落地只有四类**（主稿 §4.1 T1–T4，白名单）：同名覆盖 PNG、`ENEMIES[*].name`、`ENEMIES[*].desc`、`FLAVOR["enemies/<id>"]`。⛔ 内部 id、数值、AI、scale、tint、出怪映射、rng、存档通道一律不碰。
**显示名与 prompt 的关系**要说清：显示名走主稿 §5 的中文新名（抢剩/骨役/沉疴/夯户/灯蛾/湿袖/守炉头/洼气花/孢子侏/纸钱蝶/引血蛭/分瘴/疾爪/铁面/裹城/拱墙/百目胎/提骨/踏炭/盘山），**英文 prompt 里的词不是显示名**，它只服务生图，永远不上屏——所以 §4.1 里我可以放心用 `minotaur of legend` 这种"排除用"的词进 NEG，而 SUBJECT 里绝不出现任何他作专名。

---

## 10. 真源索引（覆盖追加件一 §9b；编程侧只认这张表）

### 10.0 🔴🔴 先读这条：`--check-doc` 今天会**假绿**，本批必须先修它

我实跑了一遍基线并把判定逻辑拆开算过，结论比"改 prompt"更靠前：

- **现状实测**：`python _tools/spr34_gen.py --check-doc` → `OK：框架 3 句＋SUBJECT 39 条＋负面追加 2 条＋共用串 1 条 全部逐字命中实稿`（exit 0）。
- **但它判的是三份文档的并集**（`spr34_gen.py:181` 把 `DOCS` 里所有文件读成 `anydoc`，再逐条 `subj in anydoc`）。我把本件加进并集后重算：**旧 3 句 HEAD ＋ 旧 39 条 SUBJECT 仍然 100% 命中**（它们本来就抄自旧两份实稿，我没删旧文档一个字）。也就是说——**你照本件把常量全换了，`--check-doc` 照样 OK**。这是最坏的一种绿：机检声称"常量与实稿一致"，实际只证明"某个历史版本的实稿里出现过这串字"。
- 更细的一层：旧 39 条里有 **10 条在并集中出现 ≥2 次**（`skeleton`/`wraith`/`plant`/`vampire`/`beholder`/`demon`/`dragon` 七条怪物 ＋ `wpn_shotgun`/`wpn_railgun`/`wpn_launcher` 三条武器），因为主稿 §5 的表格列和追加件一 §6/§7 的表格列各抄了一份。子串判据对重复本来就不敏感。

**裁定（属主理人裁定，不是建议）**：`check_doc()` 改为**按族指定单一真源文档 + 独占性断言**——

```
DOCS = {
    "monster":   "production/sprint-34/SPR34_设计实稿_词汇层重写_六道卷正名.md",
    "character": "production/sprint-34/SPR34_设计实稿_词汇层重写_六道卷正名.md",
    "prop":      "production/sprint-34/SPR34_设计实稿_词汇层重写_六道卷正名.md",
}
# 判据由「∈ 并集」升级为「∈ 该族的单一真源文档」，且对每条常量额外断言 count == 1
```

配套两条：①旧两份实稿**不删不改**（它们是历史记录与本件的比对基准，主稿 §4.2 那种"历史对照件"的写法就是为此存在的）；②若某条新常量在新文档里出现 >1 次（成对差分件有这种风险），FAIL 并报 id，不许静默取第一次命中。
🔴 **硬前置顺序**：先落地这个 `check_doc()` 改造并确认它对**旧常量集报 FAIL**（这才证明它真的在判新真源），再把 §3–§7 的新常量抄进去转绿。反过来做等于跳过机检。

🔴 **本件已按这套升级判据自跑过一遍**（不靠肉眼，脚本从文档里抽串再回测）：`HEAD` 3 句 ＋ `SUBJECT` 39 条（怪物 20／人物 3／道具 16，逐 id 齐）＋ `NEG_SHARED` 两段 ＋ `NEG_EXTRA` 三族串——**每条在该文档内命中且仅命中 1 次、全部纯 ASCII**；同时三条旧 HEAD 在新文档里 **0 命中**（说明换成单一真源后旧值必然报红，假绿已被堵住）。

⚠️ **一条我实测出来的连带缺陷，比 §10.0 主结论更容易踩（编程侧必读）**：新版 `check_doc()` 若只把 `DOCS` 收窄到"每族一份真源文档"而**不改判定逻辑**，它抓不到"某条常量根本没换过"这件事——因为旧值与新值若是同一个字符串，收窄后照样命中。我实测的分布是：**39 条里只有 3 条完全没换**，另有 8 条旧串作为新串的**前缀子串**仍留在本件文本里（无害，但值得知道）。

```
完全未改的 3 条：wpn_shotgun / wpn_railgun / wpn_launcher   （审查表上这三张没跑偏，见 §5 表右列"原句保留"）
旧串仍是新串前缀的 8 条：monster/skeleton, plant, vampire, wolf, wraith, beholder, demon, dragon
```

为了让"真源切换"可验证，裁定加一步**代际排他**断言：

```
# 升级版 check_doc() 必须再加一步：现行常量不得与旧两份实稿的值逐字相同
LEGACY_DOC_TEXT = 主稿 + 追加件一 的并集
for fam, table in SUBJECTS.items():
    for name, subj in table.items():
        if (fam, name) not in LEGACY_OK and subj in LEGACY_DOC_TEXT:
            fails.append("SUBJECT[%s/%s] 与旧实稿逐字相同 = 该条未换" % (fam, name))
```

🔴 上面那 3 条武器会让这条断言直接报红，所以处置二选一（我不替你定，但必须选一个才不留悬案）：**(a)** 承认"未改"是合法状态 → 加白名单 `LEGACY_OK = {("prop","wpn_shotgun"), ("prop","wpn_railgun"), ("prop","wpn_launcher")}`；**(b)** 为通过断言给它们各加一个无害从句（如 `, laid on plain cloth`）→ 边际成本为零（这一族本来就要整族重跑）。**我的立场：选 (a)**——(b) 是"为了机检好看而改 prompt"，方向反了；白名单是显式声明，比悄悄改词诚实。
另：三条 HEAD 在新文档里 **0 命中**、且旧文档里的旧 HEAD 与本件的新 HEAD 互不相等，所以框架句这一层的真源切换**天然可验证**，不需要白名单。

### 10.1 真源表

| 东西 | 唯一真源位置 | 生成器落点 |
|---|---|---|
| 怪物族框架句 | **本件 §3.1**（追加件一 §4.2b 作废，主稿 §5 的 prompt 列作废） | `spr34_gen.py:HEAD_MONSTER` |
| 人物族框架句 | **本件 §3.2**（覆盖追加件一 §4.3） | `spr34_gen.py:HEAD_PERSON` |
| 道具族框架句 | **本件 §3.3**（覆盖追加件一 §4.4） | `spr34_gen.py:HEAD_PROP` |
| 三族共用 NEG 追加串 | 追加件一 §4.2b 末块（**不变**）＋ 本件 §6.1 新增串 | `spr34_gen.py:NEG_SHARED`（两段拼接后整体须逐字命中两份文档） |
| 怪物族 NEG 追加 | **本件 §6.3**（旧值空串作废） | `NEG_EXTRA["monster"]` |
| 人物族 NEG 追加 | 追加件一 §4.3 八项 ＋ **本件 §7 新增串** | `NEG_EXTRA["character"]` |
| 道具族 NEG 追加 | 追加件一 §4.4 八项 ＋ **本件 §6.2 新增串** | `NEG_EXTRA["prop"]` |
| 怪物 SUBJECT 20 条 | **本件 §4.1–§4.6** | `SUBJECTS["monster"]` |
| 人物 SUBJECT 3 条 | **本件 §7 表** | `SUBJECTS["character"]` |
| 道具 SUBJECT 16 条 | **本件 §5 表** | `SUBJECTS["prop"]` |
| 逐张目标画幅 | 追加件一 **§3.2b**（本件未改） | `TARGET_SIZE` |
| 按族占比／地平线／悬空名单／机检区间 | 追加件一 **§4.5.2 / §4.5.4 / §4.5.5**（本件未改） | `FRAC_BY_FAMILY` / `GAP_BY_FAMILY` / `FLOATING` |
| 全局基准色表 ＋ D-E | 追加件一 **§5.1 / §5.2**（本件未改，⛔ 一族一色表仍违规） | `BASE_PALETTE` / `verify()` |
| 灰度/双 tint/色数/Boss 密度 | 主稿 **§4.3 D-A～D-D**（本件未改） | 验证口径据此立条 |
| 归道口径 | **本件 §2b** | 图鉴分组展示层（下批实施单再谈 UI） |

🔴 **`--check-doc` 的两条实现注意（不写清就会假绿/假红）**：
1. **假绿**见 §10.0，判据必须换成"按族单一真源文档 ＋ count==1"。
2. **别改全文等值匹配**：本件把同一段器物描述故意写在两行里（成对差分件各自一条，其中 `chest_open`/`door_open`/`prop_barrel_hit` 的行内含闭合行的完整子串）。若把判据升级成"整段文本 == 常量"，这三条 `same ...` 开头的成对句会全部 FAIL。正确做法仍是：**常量求值后的运行时字符串做子串命中**，只是命中的范围收窄到该族的单一真源文档。
3. 混合 token 卫生：本件所有 SUBJECT/HEAD/NEG 串**纯 ASCII**（中文只出现在说明行），请保持这一点——将来若有人往 prompt 里塞汉字，`unicode placeholder glyphs` 那条负面词救不了它，只有机检能救（可按"prompt 常量必须全 ASCII"再加一条断言，成本低）。

---

### 10.2 三条实现卫生条款

1. **判据仍是子串命中，⛔ 改成全文等值**。本件成对差分件（`chest_open`/`door_open`/`prop_barrel_hit`）的行内含闭合行的完整子串，若升级成"整段 == 常量"，这三条 `same ...` 开头的句子会全部 FAIL。正确做法只是把命中范围从"三份文档并集"收窄到"该族的单一真源文档"。
2. **`count==1` 只判 SUBJECT/HEAD/NEG 常量的字面串本身**，不判运行时拼接结果（`GRIDS` 的追加短语不在比对范围，见 §3.5）。
3. **prompt 常量必须全 ASCII**：本件 39＋3＋所有负面串已实测纯 ASCII（中文只出现在说明行）。建议直接把这条写成断言 `subj.isascii()`——将来有人往 prompt 里塞汉字（例如把"石瘤"直译成 `stone瘤`），只有这条机检能救，负面词表里的 `unicode placeholder glyphs` 救不了它。
## 11. 素材取用声明（章程 §二 体例）

- **取材（属性层／母题层，非情节层）**，均为只读、未改动、未在其侧运行任何脚本：
  - 六道框架与卷结构、V 字战力曲线、至高意志（天道）位阶：`D:\大纲\统一大纲\角色资料库\20_六道卷结构与人类实力境界.txt`；`D:\大纲\统一大纲\剧情文件\_读我.md`（六道卷目录与用途）。
  - 「天道＝观测/规则」气质（用于 §4.6 归道定义与 `beholder` 铜镜）：`D:\大纲\统一大纲\角色资料库\19_漏洞体质与至高意志（天道）谱系.txt`。
  - 「纳名／名条」母题（用于 `skeleton_king`）：`D:\大纲\统一大纲\剧情文件\02_畜生道·剧情分化.md` 第一卷「纳名路线确立」（**只取"名"这件物，不取其事件顺序与结果**）。
  - 纸扎手艺与白事行当（用于 `faerie` 竹篾、`wraith` 白带、`prop_totem` 红布）：`D:\大纲\统一大纲\角色资料库\37_阿婆（纸扎婆·问事人）.txt`（**只取手艺人属性与材质，⛔ 其童谣原文与师门忌的具体事件一律不取**）。
  - 「守规矩的生意人」气质（用于 §7 三商人行当）：`D:\大纲\统一大纲\角色资料库\13_秦老板（秦拙）.txt`、`17_势力与组织.txt` 惊魂客栈节。
  - 人间道＝当代中文规则怪谈的时代定位（用于 §4.5 与 Q 组）：`D:\大纲\统一大纲\剧情文件\01_人间道·剧情分化.md` 卷定位。
- **未取**：任何具体情节事件、章节事件顺序、台词原文、章名、尚未定稿的走向；⛔ `D:\大纲\库\05_代价与污染\` 他人原作全文零引用；⛔ 他作专有名词与独特比喻（本件 SUBJECT 里出现的 `minotaur of legend` / `beholder dnd` 等**只存在于负面词位**，作用是排除，不构成挪用；正面描述里一个都没出现）。
- **写入范围**：对 `D:\大纲` **零写入、零脚本、零台账变动**。§8 N2 的反哺备忘（若作者选它）也只落 `test-1/production/sprint-34/`。
- **原创命名合规**：本件落进游戏的可见文本零新增专名；显示名沿用主稿既裁的三字口语；`<SUBJECT>` 词汇全为材质/形态/机制描述词，无徽章、无制服、无角色特征。高危三处已自查：`minotaur`（改为套索拉木畜役）、`beholder`（改为多眼囊＋铜镜，与他作器官形象零关联）、`dragon`（无翼蛇形＋石瘤，不复现任何现成龙样）。

---

## 12. 本件明确不做

1. 不改任何图片宽高（追加件一 §3.2b 真源表原样有效）；不改目标画幅；不改色表（⛔ 一族一色表仍是红线）。
2. 不改任何 `.gd` 逻辑行，包括 `MONSTER_NAMES`/`GEN_NAMES` 的成员（§9b 结论：不换 id）。
3. 不改出怪映射、池子、rng、`_calamity`、`SQUADS`、`BOSS_BY_FLOOR`、`scale`、`tint`。
4. 不重画 `shardbearer.png` / `wraithswarm.png` / 浮游炮 / 瓦片 / 特效 / 应用图标（W2 若被裁采纳，另批另单）。
5. 不把 SDXL 原始产物入库；39 张同样过主稿 §4.5 原创性闸口。
6. 不引用小说未定稿情节/台词/章名，不挪用他作专名。
7. 不 commit、不 push、不刷冻结表 md5。
8. 本件仍**不写验证口径与实施单**——等 §8 的 W/N/Q 三组与主稿 U1–U5、追加件一 V1–V4 一并裁完再点单。

---

## 13. 修订记录

| # | 事项 |
|---|---|
| R1 | 2026-11-18 首稿（追加件二）。起因：作者质疑「图片都是中世纪欧美风」；编程侧实证病因在 prompt 词汇层。本件覆盖主稿 §5 的 prompt 列与追加件一 §4.2b/§4.3/§4.4/§6/§7 的框架句与 SUBJECT 列，其余条款不动。 |
| R2 | 待办（作者裁完之后才做）：①按裁定结果把 §3–§7 常量落进 `spr34_gen.py` 并跑 `--check-doc`；②整族重跑 39 张；③新开一份《美术合规与原创规格》把"过程帧/图集仍走程序化、Comfy 只用于静态大画幅与概念层"这条章程 §五 的分工写死，防止后来人拿扩散产物直接进 32px 网格图集。 |
| R3 | 同稿补三处（我自查出来的，不是编程侧报的）：①**§10.0**——实测出 `check_doc()` 现有"三份文档并集 + 子串命中"判据会**假绿**（旧 3 句 HEAD ＋ 旧 39 条 SUBJECT 在新文档加入后仍 100% 命中），裁定改为"每族单一真源文档 + count==1 + 代际排他"；②**§2c B 表**——把作者看到的 14 项欧美符号逐条对到病源词与本件改法，便于目视复核；③**§3.5**——说清 `GRIDS` 顶满追加与新写的 `dragon` SUBJECT 尾部 `fills the frame` 是有意冗余，⛔ 不要为此删 `GRIDS`。 |
| R4 | 计数勘误：§4.1 小节标题一度写"5 条"，实际畜生道 7 只（含 `dragon`/`wolf`）。**权威清点在 §4.7**（7＋3＋4＋2＋2＋2＝20），各小节标题若与 §4.7 冲突以 §4.7 为准。另修正一处英文笔误 `sprouting grain grains`→`sprouting grain at its feet`，并把混合 token `stone瘤` 全部改为纯 ASCII 的 `stone-gall crown`（prompt 常量必须全 ASCII，见 §10.2 第 3 条）。 |
