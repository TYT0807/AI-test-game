# Sprint 30 · 实施单（编程侧）——资产文件名原创化（大换血收尾）

> 本文是 S30 **唯一权威**。上游：`SPR25_美术合规与原创规格.md` / `SPR25_音频合规清单.md`（A2 方案 + 止损口径）+ 主理人 2026-11-16 实读 + 用户「继续大换血任务」开口。
> 基准 HEAD `a0c06ba`，本地=origin 0/0，树干净，`scripts/` 34 个 `.gd`，冻结 `production/sprint-21/SPR21-FROZEN.md5` 34/34 OK。
> **性质：纯改名，资产内容一个字节不许动、机制一条不许改。** 只改文件名 + preload 路径 + `.import` 的路径字段 + 文档文案。
> **推送不归你。**

---

## 一 背景与红线

S25（`5388808`）覆盖 11 音频 + 3 图集、S26（`be00c80` + `406f6e4`）再重写 3 图 + 3 BGM，**第三方资产内容已从仓库消失**（mp3 字节数按 160kbps 反推时长与返工报告逐字吻合）。但文件名与 `assets.gd` 常量名仍挂着原作痕迹（`W` / `源石虫` / `Cowboy_*` / `Journey of the Prairie King`）——public 仓库的暴露面。本批就是 S25 音频合规清单 §132 的 **A2 方案：原创命名 + 同步改 `assets.gd`**。

1. 🔴 **资产内容零改动**：14 个文件改名前后的 md5 必须逐字相同。不许重编码、不许重新生成、不许「顺手优化」。
2. 🔴 **保持 14 别名复用关系**：`SFX` 字典的 key 集合一字不动，一个 wav 服务多个 key 的现状保持（`boss_intro`/`shrine` 都用 `Cowboy_Secret` 等）。不许拆文件、不许加 key。
3. 🔴 **BGM 必须留 `.mp3`**：`assets.gd:148 m.loop=true` 依赖 `AudioStreamMP3.loop`，换 OGG 会破坏循环。
4. 🔴 **`_backup/` 目录零改动**：里面 `spr18_p1/sandbox*/scripts/assets.gd` 有旧路径，是归档，不许碰。
5. 🔴 **冻结不自刷**：本批会动 `assets.gd`，它的 md5 行会变，核验侧收官统一刷，实施方不许改快照。
6. 零新增 `Game.rng` 消费；E1 指纹零重定（纯改名不进 rooms/kinds）。

---

## 二 命名原则

**文件名只承载「用途 + 六道卷语义」，不承载任何原作角色名 / 曲名 / 装备名。**

- 图集沿用 S26 已定的三个语义：拾痕者（玩家）/ 游魂聚合体（敌人）/ 残响悬铃（炮台）。
- 音效按**用途**命名（shoot/hit/boom…），不再带 `Cowboy` 前缀。
- BGM 按**场景 + 六道卷调性**命名（主世界 / 亡命徒 / 终局），不再带 `Journey of the Prairie King` 曲名。
- 英文名优先（避免中文文件名在 Godot 导入链上的潜在编码问题），语义词用英文对应：`shardbearer` / `wraithswarm` / `echochime`。

---

## 三 精确改名映射（逐字照做）

### 3.1 图集 2 个

| 旧路径 | 新路径 | 语义 |
|---|---|---|
| `resources/texture/W.png` | `resources/texture/shardbearer.png` | 拾痕者（玩家） |
| `resources/texture/源石虫.png` | `resources/texture/wraithswarm.png` | 游魂聚合体（敌人） |

🔴 `浮游炮.png` **不改文件名**——它是通用装备描述、非原作专有名词，且 S25 美术合规稿已把它归「换图不改代码」范畴；但 `assets.gd` 里 `T_TURRET` 常量与注释保持原样即可。若核验发现它仍属暴露面，另批处置，本批不扩范围。

### 3.2 音效 10 个 wav

| 旧文件名 | 新文件名 | 用途 |
|---|---|---|
| `Cowboy_gunshot.wav` | `sfx_shoot.wav` | 射击 |
| `cowboy_gunload.wav` | `sfx_reload.wav` | 换弹 |
| `cowboy_explosion.wav` | `sfx_boom.wav` | 爆炸 |
| `cowboy_monsterhit.wav` | `sfx_hit.wav` | 命中 |
| `cowboy_monsterdie.wav` | `sfx_enemy_die.wav` | 敌人死亡 |
| `cowboy_dead.wav` | `sfx_player_die.wav` | 玩家死亡 |
| `cowboy_gopher.wav` | `sfx_pickup.wav` | 拾取 |
| `cowboy_powerup.wav` | `sfx_powerup.wav` | 强化 |
| `Cowboy_Secret.wav` | `sfx_secret.wav` | 秘密/Boss/圣所（复用） |
| `Cowboy_Footstep.wav` | `sfx_footstep.wav` | 脚步（未被 preload，一并改） |

### 3.3 BGM 3 个 mp3

| 旧文件名 | 新文件名 | 语义 |
|---|---|---|
| `1-27 Journey of the Prairie King (Overworld).mp3` | `bgm_overworld.mp3` | 主世界 |
| `1-28 Journey of the Prairie King (The Outlaw).mp3` | `bgm_outlaw.mp3` | 亡命徒 |
| `1-29 Journey of the Prairie King (Final Boss & Ending).mp3` | `bgm_finale.mp3` | 终局 |

### 3.4 `.import` 文件同步改名

上述 15 个文件（2 图 + 10 wav + 3 mp3）的 `.import` 用 `git mv` **一起改名**，然后只改文件内两处字段：

- `[remap] path="res://.godot/imported/<旧文件名>-<md5>.<ext>"` → 换成新文件名，md5 段保持不变
- `[deps] source_file="res://resources/.../<旧文件名>"` → 换新文件名
- `[deps] dest_files=[...]` 里的文件名 → 换新文件名
- 🔴 **`uid="uid://..."` 一字不动**（保引用，防漂移）

---

## 四 代码与文档改动（3 个文件）

### 4.1 `scripts/assets.gd`：preload 路径 + 常量名 + 注释

**(a)** `:5-6` 两行 preload 路径按 §3.1 换新名。

**(b)** `:15-30` SFX 字典 14 个 preload 路径按 §3.2 换新名。**key 名一个字不动**（`"shoot"` / `"boss_intro"` 等），复用关系原样保留。

**(c)** `:34-36` MUSIC 数组 3 个路径按 §3.3 换新名。

**(d)** 🔴 **常量与注释层的 `W` 痕迹一并清掉**（这是上一轮 grep 出的盲区）：
- `T_W` → `T_SHARDBEARER`
- `W_CELL` / `W_ROW_IDLE` / `W_ROW_WALK_DOWN` / `W_ROW_WALK_UP` / `W_ROW_SIDE` / `W_ROW_ATTACK` / **`W_ROW_DIE`**（`:46` 定义 / `:225` 调用，别漏）→ `SHARDBEARER_CELL` / `SHARDBEARER_ROW_*`（逐字替换，共 7 个常量、14 处引用）
- 所有注释里的「W 图集」→「拾痕者图集」
- 🔴 这些常量在 `assets.gd` 之外被引用（帧区计算），必须**全仓 `grep -rn "T_W\|W_CELL\|W_ROW_"` 确认调用点并同步改**；改完再 grep 一次必须 0 命中（排除 `_backup/`）。

### 4.2 `玩法说明.md`：2 处旧名

- `:53`「### 原生源石虫（游戏本体）」→「### 游魂聚合体（游戏本体）」
- `:136`「- 原版素材：W、源石虫、浮游炮、爆炸、瓦片、道具 UI、BGM/音效（项目自带）」→ 改成不含第三方名的原创素材声明（例如「- 美术与音频：全部为本项目原创生成（拾痕者 / 游魂聚合体 / 残响悬铃 + 原创 BGM/音效）」）

### 4.3 `scripts/data.gd`：2 处注释（🔴 QA 抓出的缺口，别漏）

- `:5`「## atlas="slug" 用原版源石虫图集（row 行号）」→ 改成「用游魂聚合体图集」
- `:7`「# ---------- 原版源石虫（保留本体） ----------」→ 改成「游魂聚合体（保留本体）」

🔴 这两处是 `data.gd` 注释，不进冻结的机制字段（只改注释、`atlas` 键名与数据一字不动），但**计入 G2 零悬空扫描面**。不改则 G2 必然红。

### 4.4 README

README:19/31-32 的「3 张图集与 13 个音频原创覆盖」表述属实（内容层），**不回改历史 Sprint 叙述**。只在「当前资产」相关段落补一句「资产文件名已于 S30 完成原创化，内容未改」——若 README 无合适位置，可不改，在交付文档里记一句即可。

### 4.5 🔴 G2 扫描面边界（QA 收口，主理人确认）

G2「零悬空」只扫**运行时 + 发货面**：`scripts/`、`resources/**/*.import`、`project.godot`、`玩法说明.md`、`README.md`。
**不扫** `production/`（S25/26/30 历史叙述必须保留旧名作证据）、`_tools/`、`tests/`、`_backup/`（归档）。
理由：历史文档里的旧名是「当时的事实」，回改等于篡改记录；发货面才是暴露面。

---

## 五 验证门（全部要自跑并报数）

| 门 | 期望 |
|---|---|
| G1 字节不变 | 15 个资产 `git show HEAD:<旧路径> \| md5sum` 与工作树新路径 md5 逐字相同 |
| G2 零悬空 | 全仓（排除 `_backup/`）grep `W.png` / `源石虫` / `Cowboy_` / `cowboy_` / `Journey of the Prairie King` / `T_W` / `W_CELL` / `W_ROW_` → **0 命中** |
| G3 validate | 34/34、`problems=0`、`[ERR]`=0 |
| G4 探针回归 | `SMOKE_CAL_THEME` / `SMOKE_OATH_GRANT` / `SMOKE_PURIFY_COST` / `SMOKE_START_BUFFER` / `SMOKE_META` / `SMOKE_ABYSS` / `SMOKE_RG7` / `SMOKE_SAVE` 全跑，`[ERR]`=0。🔴 **`SMOKE_SAVE` 必须 `--quit-after 3200`**——它挂在 `game_main.gd:274` 的 `_smoke_frame == 3000`，用 300 帧跑日志全空 = **假绿**（QA 抓出的陷阱）。其余探针 300 帧足够 |
| G5 E1 | seed 12345/777/42 指纹逐字一致 |
| G6 .import uid | 15 个 `.import` 的 `uid://` 改前改后逐字相同 |
| G7 冻结 | 除 `assets.gd` 外 33 行 OK，**不自刷** |

判红口径见 `SPR30_改名验证口径.md`（shell 门 + 引擎门分列）。

---

## 六 变异刀（≥4 把，核验侧独立复现）

| 刀 | 改法 | 预测红 |
|---|---|---|
| 刀一 | 改名后偷偷替换 mp3 内容（用旧版字节） | G1 字节不变红 |
| 刀二 | 漏改一处 preload 路径 | G2 零悬空红 + G3 validate 红 |
| 刀三 | `.import` 的 `source_file` 未改 | G6 + G3 红 |
| 刀四 | `assets.gd` 改了 preload 但 `T_W`/`W_ROW_*` 常量名没改 | G2 红 |
| 刀五 | `data.gd:5/7` 的「源石虫」注释没改 | G2 红（**QA 补的缺口**，实施单原版会自己打红自己） |
| 刀六 | `SMOKE_SAVE` 用 300 帧跑（而非 3200） | 假绿——不是变异刀，是**门控陷阱**，写在此防复踩 |
| 刀七 | 顺手补 `SFX["suffix"]` key（`player.gd:673` 在调但字典无此键） | 越界：机制改动，本批严禁；G4 会红（key 集合变了） |

🔴 变异纪律：替换目标行、不新增行；注释里不写符号字面。

---

## 七 完成定义

七门全过 + 四刀逐刀见红 + 复原后复跑全绿 + 资产内容零字节改动 + 冻结除授权文件外零漂移。
报交付时附：commit hash、七门实测数、四刀红表、改名前后 md5 对照、任何偏差的如实记录。**不 commit 文档、不推送。**
