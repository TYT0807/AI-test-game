# Sprint 26 批二 · 六道卷语义深绑实施单（转编程侧）

> 主理人（创造层）出稿，依据 `SPR26_设计实稿.md` + 主理人三项裁定（全 A）+ 实读探针机制。
> 性质：**逐字 value 对照 + 红线 + 验证门**。实际 `.gd` 改动由编程侧执行；主理人读码核验后统一提交。

## 〇 主理人裁定（三项全 A，不再拍板）

| # | 决策 | 裁定 | 依据 |
|---|---|---|---|
| 1 | 八主题命名深度 | **A**：8 个 `FLOOR_THEMES[*].name` 全留，只改 FLAVOR themes value | name 层 S25 已定稿；改 name 会红 `player.gd:1492` 主行全等断言 |
| 2 | 敌人异常化范围 | **A**：只改 29 条 FLAVOR enemies value，`ENEMIES[*].name` 不动 | 显示名本就是中性虫类词；改 name 图鉴名+手记首词双位移、探针面大 |
| 3 | Boss 显示名 | **A**：三名保留，只改 FLAVOR bosses value | 三名是原创中性名；改显示名要动 `boss*.gd`+`CODEX_BOSS_NAMES`+3 探针 |

## 一 核心改写策略（务必遵守，这是零 churn 的关键）

**只改 value 首词之后的插入语，首词逐字保留。** 实读依据：

- `game_main.gd:1173-1175` 层签第二行 = FLAVOR themes value **全文**上屏；`menu.gd:534-540` 图鉴手记行 = value **全文**。
- 探针全部 `contains` 匹配，锚点都是首词：`player.gd:1485` 含「往生脉」、`:1558` 含「矿工手记 · 岩浆层」、`:1125`/`:1163` 含「血祭」。
- 唯一全等断言 `player.gd:1492` `main4 == "层签 · 往生脉◆ ｜ 灾祸：无"` 只见 `FLOOR_THEMES[4].name+mark`，与 FLAVOR value 无关。

→ 因此：**首词不动 = 探针零同步 = E1 零重定 = 格式串零改**。每条形如 `「原首词。<插入六道语义>，<原机制应对照抄>」`。

## 二 改动范围（54 条 value）

- **必改**：themes 8 + bosses 7 + shrine 10 = 25 条（六道轮回 / 守关者 / 皆代价母题）
- **改**：enemies 29 条（异常共存母题，加「异常·族」归族前缀）
- **不动**：relics 12 + suffixes 8 = 20 条（非母题载体，改则放大认知负荷无收益）

## 三 逐字对照表

### 3.1 themes 8（六道轮转；地狱/饿鬼各复用 1 次，不扩表）

| key | 现状 value | 改后 value |
|---|---|---|
| themes/vein | 往生脉。多捡点，反射值钱。 | 往生脉。人间拾痕，多捡点，反射值钱。 |
| themes/toxic | 毒巢。云别硬踩，绕着走。 | 毒巢。饿鬼食毒，云别硬踩，绕着走。 |
| themes/pressure | 高压层。子弹会拐弯，贴墙打。 | 高压层。修罗斗诤，子弹会拐弯，贴墙打。 |
| themes/silent | 静默层。听不见脚步，多看小地图。 | 静默层。天道静虑，听不见脚步，多看小地图。 |
| themes/magma | 岩浆层。地板本身就是敌人。 | 岩浆层。地狱热狱，地板本身就是敌人。 |
| themes/ice | 冰面。刹车提前半秒。 | 冰面。地狱寒狱，刹车提前半秒。 |
| themes/swamp | 毒沼。慢是慢了点，稳当。 | 毒沼。饿鬼腐沼，慢是慢了点，稳当。 |
| themes/vines | 藤蔓。烧掉，或者绕路。 | 藤蔓。畜生缠缚，烧掉，或者绕路。 |

### 3.2 bosses 7（守关者；天道看见 / 阿修罗代价 / 地狱记住）

| key | 现状 value | 改后 value |
|---|---|---|
| bosses/prism_warden | 守望者。别站在光缝里，砸它的核。 | 守望者。天道之眼，别站在光缝里，砸它的核。 |
| bosses/pyrothalassian | 熔潮。弹匣留一半，给它变红的时候用。 | 熔潮。修罗嗔火，弹匣留一半，给它变红的时候用。 |
| bosses/third_boss | 玄渊之主。深处的老住户，比熔潮慢半拍，比守望者狠。 | 玄渊之主。地狱旧客，比熔潮慢半拍，比守望者狠。 |
| bosses/boss | 巨岩虫之王，拿下。掉宝最肥的一次。 | 巨岩虫之王，拿下。异常之主，掉宝最肥的一次。 |
| bosses/skeleton_king | 骷髅王，拿下。骨头堆了半屋子。 | 骷髅王，拿下。白骨留痕，骨头堆了半屋子。 |
| bosses/dragon | 黑龙，拿下。地精散了，矿窟安静一半。 | 黑龙，拿下。鳞甲留痕，地精散了，矿窟安静一半。 |
| bosses/demon | 炎魔，拿下。火苗灭了，加钱。 | 炎魔，拿下。业火留痕，火苗灭了，加钱。 |

### 3.3 shrine 10（皆代价；只说破「以 X 换 Y」，机制字段零改）

| key | 现状 value | 改后 value |
|---|---|---|
| shrine/blood_relic | 血祭。地窖里最不缺的就是血。 | 血祭。以血换遗物，地窖里最不缺的就是血。 |
| shrine/ore_upgrade | 残响淬炼。矿里人管这叫喂石头。 | 残响淬炼。以残响换一次选择，矿里人管这叫喂石头。 |
| shrine/purify | 净化。这层的脏，散得掉。 | 净化。以代价换清净，这层的脏，散得掉。 |
| shrine/ward_boon | 护盾祝福。挡一下，就散了。 | 护盾祝福。以残响买一挡，挡一下，就散了。 |
| shrine/heal | 修复。缝两针，血就回来了。 | 修复。以积分换血，缝两针，血就回来了。 |
| shrine/relic_suffix | 铭刻。刻上去的，抠不下来。 | 铭刻。以血换一刻，刻上去的，抠不下来。 |
| shrine/greed_pact | 贪欲契约。血换石头，老规矩了。 | 贪欲契约。以血换残响，老规矩了。 |
| shrine/wind_dance | 风之舞。腿快了，坑还是那些坑。 | 风之舞。以积分换疾行，腿快了，坑还是那些坑。 |
| shrine/shard_pact | 共鸣契约。地窖的账，只记碎片。 | 共鸣契约。以残响换碎片，地窖的账，只记碎片。 |
| shrine/power_surge | 力量激涌。手重了，人也就薄了。 | 力量激涌。以血换力，手重了，人也就薄了。 |

### 3.4 enemies 29（异常共存；首词后插「异常·族」，原机制应对逐字照抄）

归族：虫 = 虫类/节肢；灵 = 亡灵/怨灵/幽；妖 = 兽/精/魔/植物/异形。

| key | 归族 | 改后 value |
|---|---|---|
| enemies/rusher | 虫 | 红虫。异常·虫，成群来，先打跑得最快的。 |
| enemies/brute | 虫 | 黑甲虫。异常·虫，大一号的虫，没什么花样，比输出。 |
| enemies/spitter | 虫 | 紫酸虫。异常·虫，酸弹被墙挡，贴柱换血。 |
| enemies/bomber | 虫 | 自爆虫。异常·虫，贴身就炸，保持距离。 |
| enemies/elite | 虫 | 巨岩虫。异常·虫，精英壳，硬啃不划算。 |
| enemies/boss | 虫 | 巨岩虫之王。异常·虫，满场小弟，本体掉宝最肥。 |
| enemies/splitter | 虫 | 分裂虫。异常·虫，打死会裂，留个大的最后杀。 |
| enemies/mini | 虫 | 幼体。异常·虫，一踩就碎，别浪费子弹。 |
| enemies/skeleton | 灵 | 骷髅兵。异常·灵，散骨一只，聚群难缠。 |
| enemies/zombie | 灵 | 腐尸。异常·灵，慢，但会把你围住。 |
| enemies/wraith | 灵 | 怨灵。异常·灵，会走位的远程，别蹲坑，风筝优先。 |
| enemies/flameskull | 灵 | 火骷髅。异常·灵，站桩吐火球，先手拆掉。 |
| enemies/vampire | 妖 | 吸血鬼。异常·妖，扑脸还吸血，跳之前有预备动作。 |
| enemies/skeleton_king | 灵 | 骷髅王。异常·灵，召骷髅兵，先杀王再清场。 |
| enemies/echo | 灵 | 回响。异常·灵，走你走过的路，换个走法它就瞎。 |
| enemies/goblin | 妖 | 地精。异常·妖，直冲，站桩点掉。 |
| enemies/orc | 妖 | 兽人。异常·妖，皮糙，撤着打。 |
| enemies/imp | 妖 | 小鬼。异常·妖，走位发疯，预瞄半个身位。 |
| enemies/faerie | 妖 | 妖精。异常·妖，飘忽，别追，等它过来。 |
| enemies/plant | 妖 | 食人花。异常·妖，守株待兔，卡住射程点掉。 |
| enemies/mush | 妖 | 蘑菇人。异常·妖，会叫帮手，先杀召唤师。 |
| enemies/slime | 妖 | 史莱姆。异常·妖，打死会裂，跟分裂虫一个路数。 |
| enemies/wolf | 妖 | 狼。异常·妖，会扑，横向躲。 |
| enemies/knight | 妖 | 盾骑士。异常·妖，减伤七成，用毒和炸的。 |
| enemies/ogre | 妖 | 食人魔。异常·妖，减伤更多，别跟它对射。 |
| enemies/minotaur | 妖 | 牛头人。异常·妖，冲撞很痛，贴边让它撞墙。 |
| enemies/beholder | 妖 | 眼魔。异常·妖，盯得死，掩体换位打。 |
| enemies/demon | 妖 | 炎魔。异常·妖，召小鬼，别让场上堆太多。 |
| enemies/dragon | 妖 | 黑龙。异常·妖，召地精，本体才是大头。 |

> 注：`enemies/vampire` 归「妖」（扑脸吸血属兽性），原表顺序打乱但 key 集合不变；编程侧按 key 定位，勿按行号顺序套。

## 四 冻结红线（硬门，越任一即停批）

| 项 | 约束 |
|---|---|
| FLAVOR | 74 条 key 前缀与条数**绝对不动**，只改上表 value；覆盖门 `validate.gd:250-260` 按 `/` 前缀分桶只数条数 |
| FLOOR_THEMES | 8 项 name / rule / pool / elite / boss / tint / mark 全不动；8→12 永不接 |
| 播报格式串 | `矿工手记 · ` / `图鉴新发现 ×%d` / `本局誓约 · ` / `连绩 · ` / `发现度 · %d/%d 档` 全不动（`game_state.gd:354,356`、`menu.gd:394,401,425,440`） |
| 白名单 | `FLAVOR_BROADCAST_KINDS` / `CODEX_KINDS` 六类 / 图鉴 id / `ACTION_DEFS` 18 / `Meta.STATS_KEYS` / `UNLOCKS` / `CODEX_BOONS` 四档全不动 |
| 机制字段 | `SHRINE_OFFERS` / `OATH_CONDITIONS` / `SIGILS` 的 cost_kind/cost/min_floor/watched/need 全不动 |
| 探针 | **现有**断言期望值零改（保留首词策略已保证其仍绿）；若现有断言转红 = 首词被误改，立即回查。**新增**断言见 §五.4（验六道新词逐字上屏），属 SMOKE 表外探针、不进 E1 指纹 |
| E1/E6 | 零新增 `Game.rng`、零 raw delta、零新增实体/资源/动作；FLAVOR 是局外静态表不入指纹，E1 应零重定 |

## 五 验证门（编程侧自验后才报完成）

1. **改动量**：`git diff -- scripts/data.gd` 只含 FLAVOR value 行（54 条）；其它文件零 diff。
2. **覆盖门**：headless `SMOKE=1 SMOKE_SEED=12345 SMOKE_META_FINGERPRINT=1`，`--quit-after 1800`，0 报错、validate problems=0（godot 用绝对路径 `D:\SteamLibrary\steamapps\common\Godot Engine\godot.windows.opt.tools.64.exe`）。
3. **E1**：只比 `[SMOKE-META] fingerprint` 行、禁 `SMOKE_DAILY`，批前基线 + 批后两跑逐字 IDENTICAL。
4. **真·渲染断言**（验 value 逐字上屏，非只验「表里有键」）：
   - 层签第二行：`update_floor_sign()` 后 `hud._floor_sign_sub_label.text` 含「人间拾痕」且 `floor=4` 主行仍 `层签 · 往生脉◆ ｜ 灾祸：无`
   - toast：`mark_codex("themes","magma")`+flush 后 `_toast.text` 含「矿工手记 · 岩浆层。地狱热狱」
   - 图鉴手记行：`menu._build_codex()` 后 `_rows` 某 Label 含「　手记：」+「饿鬼食毒」
   - 圣所灰字：`shrine_panel.open()` 后某 `_flavors[i].text` 含「以血换遗物」
5. **冻结快照**：`md5sum -c production/sprint-21/SPR21-FROZEN.md5` → 34 OK / 0 FAILED（data.gd md5 会变，需在提交前同步刷新本批快照；历史 SPR7 归档零写入）。

## 六 收口

- 编程侧**不 commit**；回报：改动行数、四门控实测输出、任一断言转红记录。
- 主理人统一读码核验 + 刷新快照 + 提交 + 推送。
- 本批只碰 `.gd` 一处（`data.gd`）；批一资产（art/audio）另行独立提交，两批不混。
