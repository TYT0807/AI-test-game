# Sprint 26 批三 · 编程侧实施单（显示层「矿」字清零 + 六道卷口吻收口）

> 本单自包含，可直接整段复制给编程侧执行。
> 出单人：主理人（创造层）。性质：纯显示层文案替换，**零机制改动**。

## 一 项目坐标与基线

- 仓库：`D:\Create\Game\test-1`（Git Bash 路径 `/d/Create/Game/test-1`）
- 引擎：Godot 4.7.2 / GDScript，`scripts/` 下 34 个 `.gd`
- 当前基线：HEAD `1ab1ca7`，工作树干净
- 冻结清单：`production/sprint-21/SPR21-FROZEN.md5`（当前 34 OK / 0 FAILED）

## 二 背景（不要重做已完成部分）

Sprint 26 前两批已入库，**不需要重复**：

| 批次 | 内容 | 提交 |
|---|---|---|
| 批一 | 3 张图集（W / 源石虫 / 浮游炮）六道卷调性覆盖 + 3 首 BGM 重写（30/19/25 秒，-20 LUFS，无 ID3） | `be00c80` |
| 批二 | `FLAVOR` 54 条手记 value 六道卷化（themes 8 / bosses 7 / shrine 10 / enemies 29，首词保留）+ `player.gd` 4 条真渲染断言 | `1ab1ca7` |

**本批（批三）只做一件事**：S25 当年只清了「源石」，**「矿」字仍在显示层残留**——主菜单副标题、播报前缀、灾祸名、两条手记后半段。这些是玩家高频看到的位置，不换掉则「六道卷」只在名字层，读起来仍是矿窟。

## 三 改动清单（逐字对照，照抄勿改）

### 3.1 播报前缀（`scripts/game_state.gd:354`）

```gdscript
旧：			main.hud.flash_toast("矿工手记 · " + String(_flavor_pending[0]))
新：			main.hud.flash_toast("见痕手记 · " + String(_flavor_pending[0]))
```

**断言同步（`scripts/player.gd`，3 处，必须同改，否则探针转红）**：

| 行 | 旧 | 新 |
|---|---|---|
| :1514 | `.contains("矿工手记")` | `.contains("见痕手记")` |
| :1569 | `.contains("矿工手记 · 岩浆层")` | `.contains("见痕手记 · 岩浆层")` |
| :1572 | `.contains("矿工手记 · 岩浆层。地狱热狱")` | `.contains("见痕手记 · 岩浆层。地狱热狱")` |

### 3.2 主菜单副标题（`scripts/menu.gd:126`）

```gdscript
旧：	tag.text = "深入矿脉   ·   清剿虫群   ·   带回归途"
新：	tag.text = "入六道   ·   清异常   ·   记归途"
```

（三段分隔符 `   ·   ` 保持原样；无断言依赖）

### 3.3 灾祸名（`scripts/game_main.gd:552`）

```gdscript
旧：		"scarce_ore": return "贫矿（残响掉落 -30%）"
新：		"scarce_ore": return "残响枯竭（残响掉落 -30%）"
```

（无断言依赖）

### 3.4 手记两条的后半段（`scripts/data.gd`，仅改 value 后半，**首词必须保留**）

| 行 | key | 旧 value | 新 value |
|---|---|---|---|
| :384 | `shrine/ore_upgrade` | 残响淬炼。以残响换一次选择，矿里人管这叫喂石头。 | 残响淬炼。以残响换一次选择，**旧例里**管这叫喂石头。 |
| :446 | `bosses/dragon` | 黑龙，拿下。鳞甲留痕，地精散了，矿窟安静一半。 | 黑龙，拿下。鳞甲留痕，地精散了，**这一层**安静一半。 |

> 首词「残响淬炼」「黑龙」逐字保留——批二已建立的探针锚点，改了会红。

### 3.5 注释同步（不影响运行，但求代码干净；可一并改）

| 文件:行 | 旧 | 新 |
|---|---|---|
| `data.gd:365` | `基调=废弃矿窟的实用主义——克制、功能性矿工手记` | `基调=六道卷的克制实用主义——见痕者的功能性手记` |
| `game_state.gd:345` | `单条（N=1）维持「矿工手记 ·」原格式` | `单条（N=1）维持「见痕手记 ·」原格式` |
| `game_main.gd:2320` | `（废弃矿窟的实用主义口吻）` | `（六道卷的克制口吻）` |
| `boss.gd:275` | `# 矿脉富集：环位散落残响` | `# 往生脉富集：环位散落残响` |
| `menu.gd:529` | `已发现条目附矿工手记` | `已发现条目附见痕手记` |
| `player.gd:1564` | `单条首发现维持「矿工手记 ·」原格式` | `单条首发现维持「见痕手记 ·」原格式` |
| `player.gd:1571` | `（「矿工手记 · 」格式串不变，只扩 value 内容）` | `（「见痕手记 · 」格式串不变，只扩 value 内容）` |

### 3.6 文档同步（必须与代码同批改，否则文档超前于实现）

**`玩法说明.md`**
- 第 32 行：`**贫矿**（残响掉落 -30%）` → `**残响枯竭**（残响掉落 -30%）`
- 第 301 行：`播报一句矿工手记` → `播报一句见痕手记`；`文案走「废弃矿窟的实用主义」口吻` → `文案走「六道卷的克制实用主义」口吻`
- 第 320 行：`该层主题的一句矿工手记` → `该层主题的一句见痕手记`
- 第 334 行：`是矿工对这项交换的一句实用主义手记` → `是见痕者对这项交换的一句克制手记`

**`README.md`**
- 第 24 行：`附该层主题的矿工手记` → `附该层主题的见痕手记`
- 第 26 行：`各显示一句矿工手记` → `各显示一句见痕手记`

> 注意：`README.md:19` 的「把这批资产的调性从『矿窟』升级为『六道卷』」是描述批一历史的句子，**保留不改**。

## 四 冻结红线（越任一立即停批）

- `FLAVOR` 74 条 key 前缀与条数绝对不动，只改上表 2 条 value 的后半段；**首词逐字保留**。
- `FLOOR_THEMES` 8 项、`CODEX_KINDS` 六类、图鉴条目 id、`ACTION_DEFS` 18、播报格式串结构（`见痕手记 · ` 前缀本身属允许修改项，`图鉴新发现 ×%d` 不动）、`Meta.STATS_KEYS` / `UNLOCKS` / `CODEX_BOONS` 四档——全不动。
- `SHRINE_OFFERS` / `OATH_CONDITIONS` / `SIGILS` 的 name/desc 与机制字段（`cost_kind`/`cost`/`min_floor`/`watched`/`need`）全不动——它们本就不含「矿」字，属中性措辞，不在本批范围。
- 零新增 `Game.rng`、零 raw delta、零新增实体 / 资源 / 输入动作。
- 不改任何 `.png` / `.mp3` / `.import`（批一资产已定稿）。

## 五 验证门（四项全过才算完成）

### G1 改动范围

```bash
cd /d/Create/Game/test-1
git status --short
```
预期：仅 `scripts/data.gd`、`scripts/game_state.gd`、`scripts/game_main.gd`、`scripts/menu.gd`、`scripts/boss.gd`、`scripts/player.gd`、`玩法说明.md`、`README.md` 为 M；**无 `.png` / `.mp3` / `.import` 改动**。

### G2 覆盖门 + 启动自检

```bash
cd /d/Create/Game/test-1
SMOKE=1 SMOKE_SEED=12345 SMOKE_META_FINGERPRINT=1 "D:\SteamLibrary\steamapps\common\Godot Engine\godot.windows.opt.tools.64.exe" --headless --path . --quit-after 1800
```
预期：退出码 0、`[ERR]` 0 条、`[INFO] validate: 自检通过：敌人 29 / 房间 11 / 地图池 4 层`、`[SMOKE] validate problems=0`。

### G3 E1 确定性（改前基线 + 改后两跑，三跑指纹逐字一致）

```bash
# 改前基线（先 stash 你的改动）
git stash -q
SMOKE=1 SMOKE_SEED=12345 SMOKE_META_FINGERPRINT=1 "D:\SteamLibrary\steamapps\common\Godot Engine\godot.windows.opt.tools.64.exe" --headless --path . --quit-after 1800 2>&1 | grep "\[SMOKE-META\] fingerprint"
git stash pop -q
# 改后两跑
SMOKE=1 SMOKE_SEED=12345 SMOKE_META_FINGERPRINT=1 "D:\SteamLibrary\steamapps\common\Godot Engine\godot.windows.opt.tools.64.exe" --headless --path . --quit-after 1800 2>&1 | grep "\[SMOKE-META\] fingerprint"
```
预期三跑输出**逐字相同**（指纹只含房间坐标 + kinds，文案不进指纹，必须零重定）：
```
[SMOKE-META] fingerprint floor=1 rooms=(-1, 0),(-1, 1),(0, -1),(0, 0),(0, 1),(0, 2),(0, 3),(1, 1),(2, 1) kinds=secret,treasure,shop,start,combat,elite,super_secret,elite,boss
```
**禁用 `SMOKE_DAILY`**（它会用当日日期派生 seed 覆盖 `SMOKE_SEED`）。

### G4 播报前缀真渲染断言（新改的前缀必须被断言覆盖）

```bash
cd /d/Create/Game/test-1
SMOKE=1 SMOKE_SEED=12345 SMOKE_SHRINE=1 SMOKE_FLOOR_SIGN=1 "D:\SteamLibrary\steamapps\common\Godot Engine\godot.windows.opt.tools.64.exe" --headless --path . --quit-after 1800
```
预期：退出码 0、`[ERR]` 0 条、`[SMOKE-FLOOR-SIGN] done` 与 `[SMOKE-SHRINE] done` 齐。
（3.1 已把断言期望值同步为「见痕手记」，此项验的就是新前缀真的上屏。）

### G5 冻结快照刷新

本批改 6 个 `.gd`，快照必然变化。提交前刷新对应行：

```bash
cd /d/Create/Game/test-1
for f in data game_state game_main menu boss player; do
  new=$(md5sum scripts/$f.gd | awk '{print $1}')
  sed -i "s|^[a-f0-9]* \*scripts/$f.gd$|$new *scripts/$f.gd|" production/sprint-21/SPR21-FROZEN.md5
done
md5sum -c production/sprint-21/SPR21-FROZEN.md5 2>&1 | grep -v ": OK" || echo "ALL 34 OK"
```
预期：`ALL 34 OK`（34 行全 OK，0 FAILED）。

## 六 提交要求

- 提交前 `git diff` 全文自查：确认只动了上表 9 类位置，无越界。
- 提交信息建议：
  ```
  Sprint 26 批三：显示层「矿」字清零（见痕手记 / 入六道·清异常·记归途 / 残响枯竭 + 文档同步）
  ```
- 不要推送（由负责人员统一推）。
- 回报：改动行数、G1–G5 实测输出、冻结快照 OK 计数。

## 七 附：本批不做什么（防止误扩）

- **不改**圣所 10 选项 / 誓约 9 条 / 印记 9 枚的 name 与 desc——它们本就中性（血祭 / 净化 / 铭刻 / 流血不退 / 兼修并蓄），无「矿」字，改了只会伤可读性。
- **不改**图鉴六个段标题（已遇敌人 / 已击败 Boss / 已见遗物 / 已获词缀 / 已历主题 / 已行抉择）——功能性标题，玩家靠它定位，不矿。
- **不改** `FLOOR_THEMES` 的 name（往生脉等 S25 已定稿）。
- **不加**任何新机制、新实体、新资源、新输入动作。
