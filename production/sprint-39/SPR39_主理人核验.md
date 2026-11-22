# SPR39 主理人核验（独立于编程侧自报）

批次：Sprint 39
核验时间：2026-11-20（**改前**基线核验；W-1 尚未落地，故本文件是"发单前的自查"，不是收官结论）
方法：自己实读磁盘、自己跑扫描器、自己算数。⛔ 引用编程侧任何自报数。

---

## 1. 我核了什么，结果如何

| # | 核对项 | 我的实测 | 判定 |
|---|---|---|---|
| N-1 | `data.gd` FLAVOR 条数与键集 | 括号配平＋字符串态机解析得 **74** 条；对照表 **74** 行；键集全等 | ✅ 一致 |
| N-2 | 五条错位是否真实存在（不采信转述） | 逐条按**函数名**现场坐实，见 §2 | ✅ 四条成立、一条为范本 |
| N-3 | 对照表锚点真实性 | **99 条 anchors**，剥掉整行注释后在指定文件命中 ≥1 的 **99/99**，零 miss | ✅ |
| N-4 | 扫描器是否为活门（变异刀义务） | `--selftest` → `[OK ] K1 / [OK ] K2 / [OK ] K3`，`SELFTEST OK: 3/3`，exit 0 | ✅ |
| N-5 | 门的改前基线 | 正式门 exit **1**，失败 **15** 项 = G-3×4 ＋ G-4×7 ＋ G-5×4，且**全部落在本批四行上**，无误伤他行 | ✅ 门确实在盯这四句 |
| N-6 | 改完后能否变绿（不落盘预演） | 内存里把四行换成目标值再跑：**failures=0**，counts `g1=74 g2=99 g3=74 g4=10 g5=5 g6=74` | ✅ 单子可执行，无隐藏红灯 |
| N-7 | 长度/格式约束 | 新四句 len = 23 / 22 / 21 / 24，全部 ≤ `meta.max_text_len`=25；均以 `。` 收尾；全 74 条 G-6 模拟零失败（唯一超限候选 `shrine/purify`=31 走 per-row override，未被本批触碰） | ✅ |
| N-8 | 是否越界碰机制 | 我只写了 `production/sprint-39/` 下 6 个文件；`.gd` 一字未改（四行现值仍是旧文案，见 N-5 输出） | ✅ |
| N-9 | 素材取用是否越判据 | 本批未引入任何 `D:\大纲` 的具体情节／台词／章名；用的只有既有六道分位调性词（天道静虑／修罗斗诤／嗔火），且都是盘上已有口径 | ✅ |
| N-10 | 游戏内文本硬边界 | `forbidden_global` 含 `索拉尔`／`太阳骑士`／`苏瑾`；全 74 条 value 扫描零命中 | ✅ |

---

## 2. 五条错位的独立复现（行号仅为我本轮 grep 所得，⛔ 落进任何断言）

| 条目 | 我的实测证据 | 结论 |
|---|---|---|
| ① `bosses/third_boss` | `boss.gd` `const BOSS_SKILL_INTERVAL := 3.0` / `var skill_interval := 3.0`；`boss2.gd` `skill_interval = 2.2`；`boss3.gd` `skill_interval = 2.6` ⇒ 「慢半拍」方向对（2.6 > 2.2）。`max_hp` 基数 `boss.gd` `320.0 * (1.0 + (floor_num - 4) * 0.12) * Game.main.abyss_hp_mult`、`boss2/boss3` `360.0 * …` 缩放式三处逐字一致 ⇒ 「狠」可比 | ✅ **唯一诚实句**，保留并升为范本，G-5 加逐字保护 |
| ② `bosses/prism_warden` | `boss.gd _ready()` 只构造 **1** 个 `CollisionShape2D`（`CircleShape2D.radius = 16.0`），`core = Sprite2D.new()` 是纯视觉节点；`take_damage()` 体内 `hp -= amount` 出现 **1** 次、无部位/倍率分支；`_pulse_theme(rule,k)` 的 match 集合＝`{magma, ice, vines, "toxic"/"swamp", vein, pressure, silent}`，⛔ seam/light 支 | ⛔ 「光缝」「砸它的核」均为空承诺 ⇒ 改写；真身拆成 M-A/M-B 两票 HOLD |
| ③ `themes/pressure` | `homing` 在 `weapons.gd DEFS` 里**只**出现在 `mw_swarm`；`bullet.gd` `var homing := false` 且仅 `if homing and friendly:` 生效。而 `_apply_floor_theme()` 的 `"pressure"` 支实际做 `enemy_speed_mult = maxf(enemy_speed_mult, 1.3)` 与 `diamond_mult = maxf(diamond_mult, 1.5)` | ⛔ 主语错位（值钱的没说、说的不存在）⇒ 改成两句乘子的白话 |
| ④ `bosses/pyrothalassian` | 全仓扫「弹匣留一半」的实现：无。`player._start_reload()` 早退条件 `if _reload_t > 0.0 or mag() >= mag_cap(): return` 是**现状副产物**，与 S35 `hungry` 的惩罚式规矩不同物；S36 §6.3 `bw_slack_half` 又把它当许可式引用 ⇒ 一句玩家规矩三处引用两个实现 | ⛔ 删承诺 ＋ 措辞归属划给 `bw_slack_half`（`reserved_phrases`，G-4 拦回流） |
| ⑤ `themes/silent` | `game_main._apply_floor_theme()` 末尾 `hud.set_minimap_hidden(_theme_rule == "silent")`（该函数内此调用共 **2** 次：早退支 `false` ＋ 末尾支） | ⛔ **反向建议**——文案让玩家去看一个被实现关掉的界面元素 ⇒ 改为陈述它会没 |

### 2.1 我在核验中**推翻了自己前一版的两处措辞**（如实记，别当成漏改）

- 曾拟 `themes/pressure`「…虫快，残响足，气浪会把人推开」⇒ **否**。`apply_blast_push` 在 `boss.gd _pulse_theme` 的 pressure 支里，只有该层撞上守望者才成立；层签说的是整层性质，写成通性是半空承诺。定稿去掉该句。
- 曾拟 `themes/silent`「…小地图整块没了，虫也少」⇒ **否**。`FLOOR_THEMES[7].pool = 2` 是 `FLOOR_POOLS` 的**权重表编号**（池 2 有 8 种怪：rusher/goblin/orc/skeleton/imp/wraith/flameskull/slime），不是数量；八主题的 pool 值分布为 `{vein:4, toxic:3, pressure:4, silent:2, magma:4, ice:2, swamp:3, vines:2}`，无一处是密度。写「少」没有锚点，正是本批要消灭的那类句子。定稿改为「只能靠自己看」（建议，非机制断言）。
- 教训已写进 `SPR39_文案候选.json` 的 `risks`：**每个短句必须能指到一行真代码**，否则宁可删掉那半句。

---

## 3. 现在还不能下的结论（⛔ 让编程侧的绿冒充我的绿）

| 项 | 状态 | 等什么 |
|---|---|---|
| V-A1…A10（四行是否真改了） | **UNEXECUTED** | W-1 落地 |
| V-C1…C6（门绿） | **UNEXECUTED**（当前必红 15 项，属预期） | W-1 落地 |
| V-D-a…d（层签/toast/图鉴三通道上屏 ＋ 四旧串零命中） | **UNEXECUTED** | 需 Godot 实跑，我没有替它跑 |
| V-D 七件套回归 | **UNEXECUTED** | 同上 |
| 冻结面 | 未刷（照例由我收官时手工刷 `SPR21-FROZEN.md5`） | 批内允许若干 FAILED |

## 4. 一处需要作者点头的东西（不是待裁，是排期）

M-A（部位伤害）／M-B（光缝危害）两张票要不要开、开哪张、排在 S36 之后何处——**设计侧已给完代价与判断**（若只批一张，批 M-B，便宜一个数量级）。这是作者的排期权，不是设计歧义，故不入待裁栏。
另：S36 §6.3 三个 `bw_*` 的出处注释现在引的是已被删掉的手记句（`SPR36_设计实稿` 第 251/252/262 行仍写着「光缝（手记 data.gd:368『别站在光缝里』）」这类引用）。**本批不动 S36 的文件**，只在实施单 §6 登记了口径；S36 收官前须把那三行改成引机制票或不依赖部位的表述，否则 S36 会带着一条腐烂指针入库。
