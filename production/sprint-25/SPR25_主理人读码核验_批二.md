# Sprint 25 批二 · 主理人读码核验报告

- 核验对象：提交 `0716096`（父 `5388808`），21 文件 +169/−113
- 核验方式：主理人独立实读，不采信编程侧汇报口径；每行结论附本轮实读命令/输出
- 结论：**final PASS（附如实标注 2 项，均非缺陷、不阻断）**

## 一、提交结构与工作树

| 项 | 实读结果 |
|---|---|
| HEAD / 父 | `0716096` / `5388808`（`git log --oneline -4`） |
| 工作树 | `git status --short` 空，干净 |
| 提交集 | 21 文件 = 16 `.gd` + README + 交付文档 + 玩法说明 + 冻结快照（`show --stat`） |
| `.gd` 数 | 34（`ls scripts/*.gd \| wc -l`） |

## 二、命名替换逐行核验（`.gd` 全量 diff 已实读）

`git show --format= --unified=0 0716096 -- 'scripts/*.gd'` 全量逐行读完，**全部为显示串/注释替换**，无一处逻辑行：

- 显示串：`源石→残响`（货币/代价/掉落描述）、`源石共鸣→残响共鸣`、`源石淬炼→残响淬炼`、`源石矿脉→往生脉`、`结晶源石→结算结晶`、主标题`源石虫清剿战→见痕`、副标题`→六道拾痕录`。
- 探针期望值**同步**：`player.gd:1485` `矿脉层→往生脉`、`:1492` `层签 · 源石矿脉◆→层签 · 往生脉◆`；`hud`/`menu`/`shop_stand`/`upgrade_panel` 显示串同步。
- **内部标识符零改动**（逐字比对 diff）：`diamonds`、`cost_kind:"diamonds"`、`watched:["diamonds_picked"]`、`mx_resocore`、`run_diamonds_earned`、`Game.diamonds`（英文探针键 `game_main.gd:383`）、表键 `vein`/`ore_upgrade`/`themes/vein`、`id` 全部未动。
- `FLOOR_THEMES[4]` `data.gd:103` 仅 `name` 值变，键 `vein`/`pool`/`elite` 与表长 8 不动；`FLAVOR themes/vein` 仅 value 变、key 与 74 条条数不动；`SHRINE_OFFERS`/`OATH_CONDITIONS` 键与 `need`/`cost` 数值不动。

## 三、残余清点（三种口径分层）

| 口径 | 实测 | 判定 |
|---|---|---|
| 运行时文件（`scripts/*.gd`+`玩法说明.md`+`README.md`）`源石` 排除 `源石虫` | **0 行** | PASS |
| `scripts/` 内 `源石虫` | 6 处，全为贴图路径 `源石虫.png` + 图集注释（`assets.gd:6/48/161/234`、`data.gd:5/7`） | PASS（内部引用，批一零动纪律） |
| 全库 `源石`（排除虫）141 行 | 138 在 `production/` 历史归档、3 在 `tests/` 旧 QA 文档 | PASS（既定"历史 sprint 归档不回填"口径，S24 已裁） |
| 全库 `矿脉层` 5 行 | 4 在 `production/sprint-18/` 归档、1 在本批交付文档（记录该残留已修） | PASS |

**"敌人显示名 ×7"映射行复核**（编程侧主动回报）：敌人实际显示名为红虫/黑甲虫/紫酸虫等，不含「源石虫」前缀；`scripts/` 内 6 处 `源石虫` 全是内部引用 → 该行无显示层靶点，编程侧未自创新名，处置正确。

## 四、CRLF 快照漂移（如实标注，非缺陷）

冻结快照 `SPR21-FROZEN.md5` 本批刷新 21 行，其中 17 对内容改动 `.gd`，另 4 对 `bullet/prop/secret_wall/slug.gd` —— 这 4 个**内容零改动**（`git diff 5388808 0716096 -- <4文件>` = 0 行），git blob 逐字相同（实读 `aa687ff…` 三个来源一致）。

根因：本机 `core.autocrlf=true` + `eol:lf`，这 4 个是本批改动 8 个 CRLF 文件之外、仍以 CRLF 字节驻留的文件；快照记录的是工作树字节 md5，行尾归一化为 LF 后 md5 变，快照须同步刷新才能保持校验。属项目已知 CRLF 限制（长期记忆在册），非内容越界、非功能影响。

## 五、门控实跑（本轮独立复跑）

| 门 | 命令/证据 | 结果 |
|---|---|---|
| 冻结快照 | `md5sum -c SPR21-FROZEN.md5` | **34 OK / 0 FAILED** |
| 归档零写入 | `git diff 5388808 0716096 -- production/sprint-7/` = 0 行；两版快照 md5 同值 `8d1e11a2…` | PASS（未覆盖历史归档） |
| validate | Godot headless `SMOKE=1` | `validate problems=0`、`脚本编译扫描 34/34 通过` |
| E1 双跑 | 同 seed 12345、`SMOKE_META_FINGERPRINT=1`、**未用 SMOKE_DAILY**（env 实测 none） | 双跑 fingerprint 行 **逐字一致**，且与 S16/批一基线行同值：`rooms=(-1,0),(-1,1),(0,-1),(0,0),(0,1),(0,2),(0,3),(1,1),(2,1) kinds=secret,treasure,shop,start,combat,elite,super_secret,elite,boss` |
| 报错 | 双跑 `\[ERR\]` / `SCRIPT ERROR\|Parse Error` | 0 / 0 |

**hash 简写口径**：历史文档沿用 `3125e2b2…` 作为 fingerprint md5 标记；本轮以**逐字行比对**为准（更强证据，符合"E1 只比 fingerprint 行、禁整体日志 cmp"口径）。本轮试 md5/FNV 四口径未复现该 8 位简写算法，如实标注，不虚构复现；不影响"双跑逐字一致 + 与历史基线行同值"结论。

## 六、世界归属声明与交付文档

- `README.md:3`、`玩法说明.md:3` 各一句「世界观设定取自《六道卷》系列（自有）」——交接件 §3.2-5/6 兑现。
- 交付文档 `SPR25_交付_批二.md`（56 行）在库，含命名对照、残余清点、验证门、过程记录、`源石虫` 复核结论，完整。

## 七、冻结规格红线复核（未触及）

`ACTION_DEFS` / `FLOOR_THEMES` 表长与键 / `CODEX_KINDS` 六类 / `FLAVOR` 74 条与键前缀 / 图鉴 id / 播报格式串 / `Meta.STATS_KEYS` / `UNLOCKS` / `CODEX_BOONS` 四档 / `assets.gd T_*` 常量名与文件名 / `project.godot config/name` —— 本批 diff 未见任何触碰。E6 零 raw delta、零新增 rng / 实体 / 资源 / 动作。

## 八、结论与遗留

**final PASS**。编程侧交付符合交接件 §3.1 对照表与冻结规格，`源石虫` 无靶点处置正确、CRLF 漂移已如实登记。

不阻断遗留（承接交接件 §二，收口时处理，不单独开批）：
1. `_tools/` 三个生成脚本被 gitignore，换环境无法重生成资产；
2. `boss3.gd.uid` 游离 uid（引擎副产物，删除安全）；
3. 音频 MP3 循环接缝未真机试听。

推送：本地领先远端 2 提交（`5388808` + `0716096`），`origin/main` 仍在 `4b96035`，待授权。
