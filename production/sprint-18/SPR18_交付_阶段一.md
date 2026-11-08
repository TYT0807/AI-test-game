# SPR18 交付 · 阶段一（A 层签形势层 + B 层签双行）

> 基线 HEAD `e16d39a`（34 个 `.gd`，冻结 34/34，工作树仅 `SPR18_规划草案.md` 未跟踪）。
> 本批**零新增实体、零新增资源、零新增 `Game.rng` 消费、E1 指纹零重定、`ACTION_DEFS` 零新增**。
> 只改 3 个脚本：`game_main.gd` / `hud.gd` / `player.gd`。

## 零、结论速览

| 项 | 结果 |
|---|---|
| A `floor_situation()` v2 | 落 `game_main.gd:1015`；1–12 层派生实值与主理人预期**逐行全等**（见 §三） |
| B 层签双行 | `hud.gd:596` `set_floor_sign(text, sub := "")` + `hud.gd:61/504-511` `_floor_sign_sub_label`；`game_main.gd:1073` 拼装第二行，**主行一字未改** |
| 探针 | 新增 `[SMOKE-SITUATION]`（10 条断言）+ `_floor_sign_probe` 扩 4 条双行断言（合计新增 14 条） |
| 四门控 | 全过（§四），全量 6000 帧 **0 报错** |
| 负向对照 | 7 组实跑落盘（§五），其中 1 组按设计为 **0 红** 并如实标注为「前提守卫型恒过」实证 |
| 冻结清单 | 重定 3 行、仍 34 行、34 OK / 0 FAILED；`data.gd` 保持原值 `0c9cf515…` |

## 一、A · `floor_situation()` 纯只读静态派生（v2 布尔口径）

落点：`scripts/game_main.gd:1015`（`update_floor_sign()` 之前，符合规格要求）。

- 只读 `Data.SQUADS` **静态表定义**；**不读** `_squad_id` / `_squad_queue`、**不写**任何状态、**零 rng / 零 fx_rng / 零计时 / 零权重** → 与 `_roll_squad()` 的真实抽取先后顺序完全解耦。
- 门槛与 `_roll_squad()` 的 `floor_num < 3` 早退（`game_main.gd:932`）同步。
- 特征布尔判据（每个进入候选的编队各算一次，取全层并集）：`回响`（有 `id=="echo"` 成员）/ `拆弹`（`defuser==true`）/ `治疗`（`affix=="mender"`）/ `护盾`（`affix=="shielded"`）/ `远射`（`front==false` 的 `count` 和 `>= 2`）/ `冲锋`（`front==true` 的 `count` 和 `>` 其余）/ `成群`（成员 `count` 总和 `>= 8`）。
- 固定优先级 `回响 > 拆弹 > 治疗 > 护盾 > 远射 > 冲锋 > 成群`，取前 3，`" · "` 连接；空集返回 `""`。
- **文案/顺序的唯一落点**：`game_main.gd:1063` 的数组字面量（文策渊终审若只改措辞或顺序，替换这一行即可，派生结构不动；探针中另有 4 处字面量需同步，见 §九）。
- 红线：输出只描述性质，**不含** 建议/推荐/优先/带（探针⑦逐词扫描，见 §五 V6 之外的 ⑦ 条）。

## 二、B · 层签改双行

- `hud.gd:596` `set_floor_sign(text: String, sub: String = "")`：加**默认参数**，`sub` 空则第二行隐藏 → 既有调用零改动。实读全库确认：`set_floor_sign(` 仅 1 个调用方（`game_main.update_floor_sign()`），无第三方调用者，故无隐藏破坏面。
- `hud.gd:61` 声明 + `hud.gd:504-511` 构建 `_floor_sign_sub_label`（`_floor_sign_label` 之后、同容器 `vb`；`_fs(11)`、常灰 `Color(0.72,0.72,0.76)`、outline `Color(0.1,0.06,0.08)` / `outline_size 4`）。
- `game_main.gd:1073 update_floor_sign()`：主行文本 **一字未改**（`"层签 · %s ｜ 灾祸：%s"`）；第二行 = `"形势 · " + sit` 与 `FLAVOR["themes/"+rule]` 的**非空项**用 `" ｜ "` 连接，两者皆空则 `""`。
- **双播红线**：只走层签常驻行，**未调用 `flash_toast()`**（首发现播报仍独归 `mark_codex()`，`_floor_sign_probe` 里 toast 文本断言仍绿）。
- 实跑渲染实值（floor=4）：主行 `层签 · 源石矿脉◆ ｜ 灾祸：无`；第二行 `形势 · 护盾 · 远射 · 冲锋 ｜ 矿脉层。多捡点，反射值钱。`

## 三、派生实值：独立复算 vs 主理人预期

用 Python 按 v2 规则**独立重算**（不复用 GDScript 实现），结果与主理人给的预期**逐行全等**：

| 层 | 实值 | 主理人预期 |
|---|---|---|
| 1–2 | `""` | `""` |
| 3 | `远射 · 冲锋 · 成群` | 同 |
| 4 | `护盾 · 远射 · 冲锋` | 同 |
| 5 | `治疗 · 护盾 · 远射` | 同 |
| 6 | `拆弹 · 治疗 · 护盾` | 同 |
| 7 | `回响 · 拆弹 · 治疗` | 同 |
| 8–12 | `回响 · 拆弹 · 治疗` | 8 层起同 7 层（候选集恒定） |

（v1 权重口径的历史结论留档：3–7 层主倾向恒为「近战冲锋」、`拆弹` 永不浮现——这正是 v2 换轴的依据。）

## 四、四个门控实跑结果

`G="D:/SteamLibrary/steamapps/common/Godot Engine/godot.windows.opt.tools.64.exe"`

**① 全量回归（6000 帧）**
```
env SMOKE=1 SMOKE_SEED=12345 SMOKE_V8=1 SMOKE_REBIND=1 SMOKE_RELIC_PROBE=orb_shield SMOKE_SUFFIX=1 \
 SMOKE_META=1 SMOKE_META_PERSIST=1 SMOKE_BOSS=1 SMOKE_FORCE_SOVEREIGN=1 SMOKE_FORCE_SQUAD=echo_pack \
 SMOKE_JUMP_FLOOR=11 SMOKE_DAILY=1 SMOKE_CALAMITY=1 SMOKE_SHRINE=1 SMOKE_CODEX=1 SMOKE_CODEX_BOON=1 \
 SMOKE_SIGIL_COVERAGE=1 SMOKE_FORCE_THIRD_BOSS=1 SMOKE_THIRD_BOSS=1 SMOKE_OATH=1 SMOKE_ECHO_CHAIN=1 \
 SMOKE_FLOOR_SIGN=1 SMOKE_FLAVOR=1 SMOKE_META_SETTLE=1 SMOKE_DAILY_SHARE=1 SMOKE_SITUATION=1 \
 "$G" --headless --path . --quit-after 6000 > _tools/spr18_p1_full.log 2>&1
```
→ exit 0；`SCRIPT ERROR|Parse Error|[ERR]|启动自检失败` = **0**；`validate problems=0` = 1；`脚本编译扫描 34/34 通过` = 1；**12 行 `[SMOKE-*] done` / 12 个唯一标记**（SPR17 基线 11 个全在 + 新增 `[SMOKE-SITUATION] done`）。
关键证据行：`[SMOKE-SITUATION] done s3=远射 · 冲锋 · 成群 s4=护盾 · 远射 · 冲锋 s6=拆弹 · 治疗 · 护盾 s7=回响 · 拆弹 · 治疗 s8=回响 · 拆弹 · 治疗`；`[SMOKE-FLOOR-SIGN] B: sub1=<hidden> sub4=形势 · 护盾 · 远射 · 冲锋 ｜ 矿脉层。多捡点，反射值钱。 main4=层签 · 源石矿脉◆ ｜ 灾祸：无`；A1 跳层证据仍在：`[SMOKE-FLOOR-SIGN] A1: floor=11 … rng_same=true fx_same=true`。

**② 冻结清单**：`md5sum -c production/sprint-7/SPR7-FROZEN-4.md5` → **34 OK / 0 FAILED**，仍 34 行；`diff` 证明**只有 3 行**变化（`player.gd` / `hud.gd` / `game_main.gd`），`data.gd` 保持 `0c9cf5154b8474a778db68a9cc5e34cc`（未改）。
**③ E1 双跑**：同 seed 1800 帧 ×2 → `_tools/spr18_p1_e1_{1,2}.log`；`cmp` 两指纹文件 **byte-identical**（md5 均 `0fc7391ca770964489340c350f53b53e`）；`rooms=(−1,0),(−1,1),(0,−1),(0,0),(0,1),(0,2),(0,3),(1,1),(2,1) kinds=secret,treasure,shop,start,combat,elite,super_secret,elite,boss` —— **零重定**。
**④ E6**：`git diff` 新增行中 `delta` **零命中**（全库 33 处 `FIXED_DT` 未动；现存 `delta` 用法均为既有 `_process` 链路，本批未触碰）。

## 五、负向对照（7 组，全部实跑落盘）

| 变体 | 突变点 | `[ERR]` | 转红断言 |
|---|---|---|---|
| `v1_threshold` | 门槛 `floor_num < 3` → `< 5` | **2** | floor=3 全等 / floor=4 含护盾 |
| `v1b_noguard` | 整条守卫 → `if false:` | **0** | 无（见下注） |
| `v2_notrunc` | 删 `parts.size() < 3` 截断 | **1** | 派生至多 3 项（实测 7 项） |
| `v3_rng` | 派生内注入 `Game.rng.randf()` | **1** | 零 Game.rng / fx_rng 消费 |
| `v4_nosub` | `set_floor_sign` 忽略 `sub` | **2** | 第二行显示且含形势 / 含主题手记实值 |
| `v5_mainline` | 主行 `"层签 · "` → `"层 "` | **1** | 主行文本一字未改（全等锁） |
| `v6_noprefix` | 第二行丢 `"形势 · "` 前缀 | **1** | 第二行含形势 |

日志：`_tools/spr18_neg_{v1_threshold,v1b_noguard,v2_notrunc,v3_rng,v4_nosub,v5_mainline,v6_noprefix}.log`。
**注（诚实标注）**：`v1b_noguard` 按设计 **0 红**——floor 1/2 本无 `min_floor<=floor` 的候选编队，`min_floor` 过滤已足以返回 `""`，故门槛只是防御性早退。这证明探针 ①/② **属「前提守卫型恒过」**，不能当作有效绿灯；有效门槛验证由 `v1_threshold` 承担。该结论已写进 `_situation_probe` 的分类注释，不粉饰。

## 六、断言盘点（新增 14 条）

| # | 分类 | 断言 | 转红方式 |
|---|---|---|---|
| 1 | 前提守卫型恒过 | floor=1 `""` | 不转红（v1b 实证） |
| 2 | 前提守卫型恒过 | floor=2 `""` | 不转红（v1b 实证） |
| 3 | 验效果型（全等） | floor=3 == `远射 · 冲锋 · 成群` | v1_threshold |
| 4 | 验效果型 | floor=4 含 `护盾` | v1_threshold / v4 |
| 5 | 验效果型 | floor=6 含 `拆弹` | — |
| 6 | 验效果型 | floor=7 含 `回响` | — |
| 7 | 恒等型 | floor=8 == floor=7（候选集恒定，兼锁幂等） | 状态泄漏即可转红 |
| 8 | 验效果型（截断） | floor=7 输出 ≤ 3 项 | v2_notrunc |
| 9 | 验效果型（红线） | 不含 建议/推荐/优先/带 | 文案加推荐语即转红 |
| 10 | 验效果型 | 调用前后 `Game.rng.state`、`fx_rng.state` 相等 | v3_rng |
| 11 | 验效果型 | floor=1 第二行为空且隐藏 | v4 |
| 12 | 验效果型 | floor=4 第二行显示且含 `形势` | v4 / v6 |
| 13 | 验效果型 | floor=4 第二行含 `矿脉层`（`FLAVOR["themes/vein"]` 实值） | v4 |
| 14 | 验效果型（回归锁） | floor=4 主行 == `层签 · 源石矿脉◆ ｜ 灾祸：无` | v5_mainline |

## 七、偏差清单

1. **【主理人已批准】冻结清单重定 3 行**。派单/草案原写「本批预计 34/34 零重定；出现 FAILED 一律回滚」，与 A+B 落地位算术冲突（3 个在册文件必然改）。经主理人更正：原意是 **E1 指纹零重定**，冻结清单**允许多行重定、脚本数与清单行数恒为 34**。本批据此重定 3 行（旧→新）：`player.gd e66793bf…→dbcb8f5e…`、`hud.gd 712f3358…→86f38f9f…`、`game_main.gd 9f639501…→1288d675…`；其余 31 行一字节未动；`data.gd` 保持 `0c9cf515…`。
2. **A 规则由 v1（权重主倾向）换成 v2（布尔特征 + 固定优先级）**，主理人指定。v1 的问题：`tide` 权重 12 且 `min_floor=3`，在 3–7 层恒为最大权重项，任何权重占比派生都输出同一句话。（v1 实现已完成并实跑绿，随后被 v2 整体替换，未留残码。）
3. **【需主理人知晓】`game_main.gd` 的 A 段当前文本不是我写入的版本**。我按 v2 落地后，主理人并发写入了自己的 v2 实现（含 `## … （主理人 2026-11-08 v2 口径）` 注释行）。两份实现语义等价（我按 §三 独立复算，输出与主理人给的全部预期值逐行全等），我**采用主理人版本**、未回退；差异仅：我原版把优先级放成模块级 `const SITUATION_TAGS`，现版内联在 `game_main.gd:1063`。**工作流风险**：同一 `.gd` 并发写入会互相覆盖，本批已实际发生一次（我一次负向对照因锚点被覆盖而失败，白跑一轮）。建议后续派单约定「一个批次一个写入方」。
4. **负向对照 V1 由「删守卫」改为「门槛 3→5」**：删守卫在本表下无行为差异（见 §五注），故改阈值才是有效突变；另保留 `v1b_noguard` 作为「恒过」实证。
5. **探针断言比派单要求多 3 条**：⑥ 恒等（8 层==7 层）、⑥b 截断（≤3 项）、floor=3 全等（派单要求精确相等，已照做）。加 ⑥b 的原因：原 ⑥ 单独不能抓截断（去掉截断后 8 层仍等于 7 层），故单独补一条真锁。
6. **floor=4 第二行有两个 `·` 分隔符**（`形势 · 护盾 · 远射 · 冲锋 ｜ …`）。这是规格「`形势 · <sit>`」与 sit 自身 `" · "` 连接的叠加结果，我未擅自改文案；可读性终审留给文策渊。
7. **未改 `data.gd`**：v2 纯布尔口径不需要动 `SQUADS` 权重（派单亦明确不改）。

## 八、回滚

```
cp -a _backup/spr18_p1/{game_main.gd,hud.gd,player.gd} scripts/
cp    _backup/spr18_p1/SPR7-FROZEN-4.before.md5 production/sprint-7/SPR7-FROZEN-4.md5
rm -f production/sprint-18/SPR18_交付_阶段一.md
md5sum -c production/sprint-7/SPR7-FROZEN-4.md5    # 回 34/34
```
`_backup/` 与 `_tools/` 均 gitignored，不入库。本批无新增 PNG，无需 `--headless --import`。

## 九、遗留 / 待决策

1. **文案终审**：7 个标签（回响/拆弹/治疗/护盾/远射/冲锋/成群）与其优先级顺序待文策渊复审。若只改措辞/顺序 → 改 `game_main.gd:1063` 一行 **+ 探针 4 处字面量**（floor=3 全等串、`护盾`/`拆弹`/`回响` 三条 contains、以及 `SMOKE-SITUATION` 打印），派生结构不动。
2. **8 层以后形势不再变化**（候选集恒定）——事实，已由探针 ⑦ 锁住；若后续想让后期层有区分度，需新增 `min_floor >= 9` 的编队（会动 `data.gd`，本批禁区）。
3. 阶段二（C 誓约连绩退化版 + D 圣所熟客呼应 10 条）未开工，等派单。

## 十、提交范围

`scripts/game_main.gd`、`scripts/hud.gd`、`scripts/player.gd`、`production/sprint-7/SPR7-FROZEN-4.md5`（重定 3 行）、本文件。
**不含** `production/sprint-18/SPR18_规划草案.md`（主理人文件，未跟踪）与 `SPR18_设计候选实稿.md`（已在 `bbd70fb` 入库）。
