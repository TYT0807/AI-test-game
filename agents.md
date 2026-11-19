# AGENTS.md — 《六道卷》改编 Roguelike · AI 协作规程

> 任何接手本仓库的 AI（含 Qoder 侧编程助手）进场先读这份。
> 本文是把 WorkBuddy 那套积累（`sprint15-handoff` 团队包、`production/sprint-15/handoff/*`、跨项目长期记忆）
> 与编程侧后续各轮实测**汇总去重**后的单一规程入口；已过期口径在 §10 逐条标明，不要照抄旧文档。

## 0. 先读什么（指路，别把本文当唯一来源）

| 要什么 | 去哪 |
|---|---|
| 玩法是什么、工程约定、已知限制 | `README.md`（权威，本文不复制其内容）＋ `玩法说明.md` |
| 某批的设计口径 / 验收靶 / 实施细节 | `production/sprint-NN/`，四文件体例：`设计实稿` · `验证口径` · `实施单_编程侧` · `主理人核验` |
| 零上下文接手的最细操作手册 | `production/sprint-15/handoff/HANDOFF_技术接手包.md`、`HANDOFF_QA接手包.md`（除行号外仍有效） |
| 主理人的设计与核验结论 | `production/` 根目录的核验报告 ＝ **人工交接**；常驻协作走 §1 的 `主理人` 智能体 |

## 1. 角色分工 —— 必须调用助手，不要一个人干完

**这是硬规矩：作者明确要求「经常调用助手」。** 凡是设计构思、口径撰写、独立核验，一律派 `主理人` 智能体；
广域代码检索派 `Explore`。编程侧自己只干：写/改 `.gd`、跑门禁、跑变异刀、提交。

| 角色 | 谁 | 边界 |
|---|---|---|
| 作者 | 用户 | 唯一裁定权：方向、数值口径、放行/发布、冻结重定、红线变更。**⛔ 不是默认问答对象**——只有 §1.1 那五类保留域才可发问，且必须异步、给推荐项、问完继续跑 |
| 主理人 | 智能体 `六道卷游戏 · 主理人`（定义 `C:\Users\TangUser\.qoder\agents\六道卷游戏 · 主理人.md`） | 只编排、只写 `production/sprint-NN/`、只核验，**不写任何 `.gd`**、不 commit、不刷 md5。**编程侧的默认对话对象；其裁定＝终局** |
| 编程侧 | 本会话 AI | 按实施单动 `.gd`；**不自行扩范围**、不自刷冻结、推送须逐次授权 |

批次链固定，不回头补：**实施 → 门禁 → 冻结重定（归主理人/收官）→ 交付文档 → 单独提交 → 主理人读码核验**。

### 1.1 提问路由（作者 2026-11-17 硬规矩：别打断思考任务）

| 问题类型 | 走哪里 |
|---|---|
| 创意侧／设定口径／数值方向（实施单里的 `W*`／`Q*` 待裁项） | **先问 `主理人`**，⛔ 不打包成清单甩给作者 |
| 主理人也无法判断、且**绝对**绕不开的创意题 | 落 `D:\大纲` **判断栏**（异步问，不占对话回合、不等回话就继续跑别的） |
| 代码事实、门禁红、可自查的东西 | 自己实测，谁都不问 |

- 🔴 作者原话（2026-11-18，「主理人才是主要的，不要老是问我」）：**默认对话对象是主理人，不是作者**。
  编程侧遇到任何「这一步该怎么走」的题，先派主理人拿结论；主理人给了结论（含 X1–X7 这类已裁条目）
  就是**终局**，⛔ 拿去问作者第二遍——那等于把主理人的编排权架空。
- 🔴 作者的保留域**只有这五类**，不在其中的一个都不许问：①方向级变更 ②数值口径本身 ③放行/发布
  ④冻结重定 ⑤§9.3 美术硬指标（换图集／换风格这类会动盘上素材血统的）。
  「要不要继续／我先做完再等您点头／这份稿您先过目行不行／这两个方案选哪个」——**都不是**这五类，一律不问。
- 🔴 发问前自检一句话（写不进交付报告就别问）：**「主理人有没有能力裁这条？」** 有 ⇒ 派主理人；
  没有且属上述五类 ⇒ 进判断栏、给推荐项、当场继续跑未阻塞条目。
- 作者原话：「如果遇到创意侧问题，绝对无法判断的就请使用判断栏问我，否则询问创意侧主理人，**不要一直打断思考任务**。」
- 🔴 推论：**没有「等裁定」这个状态**。待裁项挂着的批次里，可即刻开工的条目照开工，跑完再一并交回；
  把「待裁清单」当交付物的一部分可以，当停工理由不行。
- 🔴 作者 2026-11-18 再钉（「不准在最后等我点头这种东西存在」）：交付正文**结尾不得出现「等你点头／要不要我动／
  是否开工／请排期」这类停等问句**。需要作者拍的题**当场用判断栏问**（`AskUserQuestion`，批量、推荐放第一位、
  每个选项写风险等级与可否回滚、⛔ 代答），问完立刻继续跑未阻塞项，不等回话。
  ⇒ 「主理人的稿出来后先给我过目」＝**异步供阅**（作者想看时看），⛔ 解释成施工前置闸门；
  唯一仍须逐次授权的只有 **push**（§10）。

## 2. 一分钟启动 + 当前基线

```bash
cd "D:/Create/Game/test-1"
GODOT="D:/SteamLibrary/steamapps/common/Godot Engine/godot.windows.opt.tools.64.exe"
git log --oneline -1 && git status --short          # 起点与未提交物
ls scripts/*.gd | wc -l                             # 34（冻结分母）
md5sum -c production/sprint-21/SPR21-FROZEN.md5     # 见下
```

- 引擎 Godot 4.7.2 / GDScript；主场景唯一 `scene/game.tscn`；`scripts/` 是**唯一**产品代码目录。
- autoload：`Assets` / `Game`(game_state.gd) / `Data` / `Dev` / `Validate` ＋ 插件 `PhantomCameraManager`。
- **冻结权威是 `production/sprint-21/SPR21-FROZEN.md5`**（34 行，文件级字节快照）。
  `production/sprint-7/SPR7-FROZEN-*.md5` 已退役，旧文档里 `md5sum -c ... SPR7-FROZEN-4.md5` 的命令**作废**。
- 现状（2026-11-18 R25b 实读，工作树未提交态）：**24 OK / 10 FAILED** —— 这 10 个 FAILED **恰等于** S33–S38
  未提交批被改的 10 个 `.gd`（与 `git status --porcelain scripts` 的 M 集两向相同），属**待重定不是回归**。
  新值已由 `production/sprint-38/SPR38_主理人裁定_R10_冻结重定.md` 定好，转录须作者逐项放行。
  历史陈述保留：`4dafdaf` 时曾为 32 OK / 2 FAILED（`game_main.gd`、`shrine_panel.gd`）。
  **冻结行数随批变动，任何文档里的数字都只当线索，每轮以 `md5sum -c` 现读为准。**
  **编程侧永远不自己刷 md5**，也别为了「绿」去改清单。

## 3. 门禁七件套（改动后必须全绿，缺一不交）

| # | 判据 | 取法 |
|---|---|---|
| 1 | `validate problems=0` | `[SMOKE] validate problems=0` |
| 2 | 每个探针落地 | `[SMOKE-XXX] done checked=N declared=N`，两数必须相等 |
| 3 | `[ERR]` = 0 | `cat *.log \| grep -a -c '\[ERR\]'`（**见 §7 计数坑**） |
| 4 | `ok=false` = 0 | 同上 |
| 5 | E1 指纹一致（**两问两答，缺一不算答**） | `SMOKE_META_FINGERPRINT=1`，跑 12345/777/42 三档。①**漂移问**＝每档 `[SMOKE-META] fingerprint` 的 `rooms=`/`kinds=` **逐字等于 `production/sprint-32/SPR32_验证口径.md` §5.4 它自己那一行**（机检 `_tools/spr38_fp_vs_5_4.py` → `VERDICT=ALL_MATCH`；本体见 `SPR38_验证口径.md:80` V-E4「与**改动前**逐字相同」）；②**种子生效问**＝三档指纹**互不相同**（distinct=3；地图走 `run_seed` 派生，§4.2）。🔴 ⛔ 断言「三档彼此逐字相等」＝恒不成立的判据；也 ⛔ 只拿 distinct=3 单独当 E1 通过依据。同 seed 只比 fingerprint 行，⛔ 整体日志 `cmp` |
| 6 | churn 比对 | 先钉 `SMOKE_SEED`；只比**白名单断言行**（探针自己打的 `[SMOKE-*]`／`[S38-*]`／`[VH*]`／`[MG-*]`／`[SW-*]`），⛔ 整行逐字比——`[SMOKE-STANCE]` 一行同载真断言字段（`done checked=N declared=N`）与每帧重算量（`shots/window/moving_window/blocks/released`），零改动代码上整行比仍报漂移＝假红；抖动族（下面那一族）按**字段级**掩除，口径与逐面行数以 `_tools/spr40_b/s20_churn_whitelist_verify.py`＋其证件为准。`151` 已作废（`BLACKLIST-151 VOID-WITHDRAWN provenance=column-sum-ok reproducible=no`），后续引用一律走白名单件＋口径名，⛔ 复活该数（S40-R48 §D） |
| 7 | 冻结状态如实报 | 不为了 PASS 而刷清单 |

- 实时抖动族**不入** churn 判定：`[SMOKE-NAV]` `[SMOKE-CAM]` `[SMOKE-E]` `[SMOKE-LOOP]` `[SMOKE-STALL]` ＋时间戳。
- 退出期 `ObjectDB instances were leaked` 是 `--quit-after` 强杀提示，基线同样有，**不计判据**。
- 跑前清隔离档（会跨 run 累积、污染可比性）：
  `rm -f "/c/Users/TangUser/AppData/Roaming/Godot/app_userdata/test_1"/_smoke_*.cfg*`
- `SMOKE_SAVE` 探针要 `--quit-after 3200` 才落地。

## 4. 红线（本轮实读复核，标 ⚠️ 的是易踩点）

1. **E6 计时**：新增计时/DoT/冷却一律 `Game.FIXED_DT`，禁 raw `delta`。⚠️ 既有豁免只有两条，别顺手「统一」：
   `player.gd` `_tick_buffs()` 里的 `_buffs[id].t -= delta`（函数起点现读 `:2240`；行号会腐烂，定位一律用 `grep -n "func _tick_buffs" scripts/player.gd`）、
   `toxic_cloud.gd` 敌方云。物理位移用 delta 正常。
2. **E1 确定性**：核心循环**零新增 `Game.rng` 消费**；地图 rng 走独立 `_floor_rng()`。新键一律
   `"%d_%d_%d" % [Game.run_seed, Game.floor_num, coord.x*1000+coord.y]` 派生 ＋ `stable_hash`。
   ⚠️ `FORCE_*` / `JUMP_FLOOR` / `SMOKE_CALAMITY` 会改随机流，E1 双跑必须挂干净 env。
3. **`assets.gd` `ACTION_DEFS` 不加新 action**（实读计数 = **18**）；新资源经 `Assets.g()` 必须登记 `GEN_NAMES`，
   漏了是**静默白框、零报错**。
4. **`meta.gd UNLOCKS` = 冻结规格 v2.11 不可改**（v2.10→v2.11 升档经 S36 T-A 已裁条目授权，程序行见 S36 `实稿 §8.1:326`，接入冻结重定见 `SPR38_主理人裁定_R10_冻结重定.md`）。四件不可动：⛔ 删节点／改 target；⛔ 动 cost（须正整数，`validate.gd:712-713` 守着，「无限制」⛔ 用 cost=0 表达）；⛔ 绕过已裁条目新增 `kind:"weapon"` 收费节点（W3=A）；局外新内容一律平行只读派生。可改仅 `default`/`requires` 显示态，且每次须有已裁条目背书＋收官重刷 md5。值守硬边界：⛔ 无已裁条目授权而改动 UNLOCKS——增删节点／改 target／改 cost 一律越界。
5. **登记三件套**：新 id/资源/记录点 ＝ ①写入 ②注册表·白名单·分母·显示名 ③可见效果断言，逐项打勾。
6. **boon 自激 P0**：`CODEX_BOONS[*].kind` 不得为 `suffixes`（启动期遍历断言守着，放开须重做该门）。
7. **`FLOOR_THEMES` 8→12 永不接**：`data.theme_for_floor()` 用 `FLOOR_THEMES.size()` 动态取模，
   而 Boss 阶段/守关层判定硬编码 `%8`/`%16` —— 四处周期来源不一致。
8. **主题 Boss 契约**：`variant="boss"` 承载宝箱/词缀必掉/震屏，严禁占用；图鉴登记一律走 `codex_id`
   （曾因占用 variant 把「巨岩虫之王」误登记）。
9. **dash 位移保持 196–210px**：这是**实测区间不是代码常量**（`grep 196 player.gd` 无命中）。
   改前用 `SMOKE_DASH_TRACE=1` 复跑取实测，超区间即回退。

## 5. 断言有效性四类（本项目连续多轮踩坑的根因）

根因：**把「断言绿」当成「效果已验证」**。凡标 ✓ 必须附**本轮实读**证据 ＋ 一条反证。

| 类别 | 识别 | 处置 |
|---|---|---|
| 验效果型 | 两侧来自不同时点/来源，中间过被测函数，观测实值 | 唯一可作 PASS 证据 |
| 前提守卫型恒过 | 当前数据使条件恒真（`_check_shrine()` B4、`_check_codex()` P0） | 必须注释＋文档标明性质，不得冒充验效果型 |
| 常量自比较 | 两侧同源/恒等 | 删掉或改写，**不计入断言数** |
| 只验标志不验数值 | 只验 `has()`/`size()`/布尔置位 | 补 `is_equal_approx` 实值断言，否则等于没测 |

**变异刀**：临时把被测分支改坏 → 断言必须变红 → 还原。变不红即 `INCOMPLETE`，不是 PASS。
⚠️ 探针侧两个已知假绿源：**同一门禁在多处重复**（改一处其余仍绿）、**冻结基线串只在某一状态下采集**
（例：S32 的 D3 逐字串采自 `_calamity == ""`，有灾祸分支从未被覆盖）。新批次要覆盖新分支就**另立新断言**。

## 6. 探针 env（代码实读 76 个，别从旧文档抄名单）

```bash
grep -rhoE 'get_environment\("[A-Z0-9_]+"' scripts/ | sed 's/.*("//;s/"//' | sort -u
```

取值类型易错点（**都吃值不是布尔**）：`SMOKE_SEED`=整数（churn 必钉）· `SMOKE_JUMP_FLOOR`=**层号** ·
`SMOKE_FORCE_SQUAD`=**编队 id**（如 `echo_pack`）· `SMOKE_RELIC_PROBE`=**遗物 id** ·
`SMOKE_META_SETTLE=1` 才开结算（全量回归刻意不设）· `SMOKE_BOSS`=火力提速不是 Boss 开关 ·
`SMOKE_DAILY` 会用日期覆盖 `SMOKE_SEED`，**跨批对照禁用** · 无 `SMOKE_BOSS2`/`SMOKE_ECHO`（靠 `FORCE_SOVEREIGN`＋`JUMP_FLOOR`／`FORCE_SQUAD` 覆盖）。
S27 以后新增：`SMOKE_CAL_THEME` `SMOKE_OATH_GRANT` `SMOKE_PURIFY_COST` `SMOKE_START_BUFFER` `SMOKE_S32_SHRINE` `SMOKE_FLAVOR` `SMOKE_FLOOR_SIGN`。

**SceneTree 驱动（`-s` 跑临时走查件）四条坑**：`-s` 编译早于 autoload 注册 → 取 `root.get_node("Game")`，
不写裸标识符；没有 `SceneTree.get_main_scene()`；`Image.crop(x,y)` 不存在 → 用 `get_region(Rect2i)`；
`blit_rect` 要求 RGBA8；`_initialize` 里调协程必须 `await`。新工作树先
`--headless --path <dir> --import`。临时件一律落 `_tools/`（已 gitignore），不进版本库。

## 7. Windows / 工具链坑

- **计数坑**：`grep -c` 配绝对 Windows 路径再 `awk -F:`，盘符冒号会把计数打成 0（**假绿**）。
  正解：`cat 文件… | grep -a -c '模式'`。
- `printf "%s\n" "--x"` 会报 `invalid option`；含 `--` 的参数放 `--` 分隔符后或换写法。
- 控制台是 **GBK(936)** 不是 UTF-8：输出里的中文乱码先量 `GetConsoleOutputCP()` 再判；含 U+FFFD 的损坏不可逆。
  ⚠️ WorkBuddy 记的「`python` 是静默存根须用 `py -3`」在 Qoder 的 Git Bash 下**不成立**（实测 `python` = 3.15.1 可用），别照抄。
- 自写 `.ps1` 必须**纯 ASCII**（无 BOM UTF-8 会被 5.1 当 GBK 解析 → 退出码 0 但静默不执行）；
  PowerShell 工具 stdout 可能被吞，改落盘再 Read。
- 事件日志按 **EventId** 过滤，不要按 `'running'` 这类 locale 字符串（中文系统是「正在运行」）。
- **取证件命名坑**（R29 实测，S38 R14 裁定）：整份引用链终端行的自证／测试副本，**文件名必须含 `CHAIN_EXCLUDE` 五子串之一**
  （`verify`／`selftest`／`audit`／`falsify`／`mnow`／`md5all`）。否则 `spr38_r8_verify.py` 的
  `is_chain_artifact()`／`latest_chain()`（判据＝头部有链标记＋任一行以 `RUN-` 开头＋mtime 最新）会把它认成
  **盘上最新链原件**，污染只读对面 → 面5 假红。反证已实证：`_r29_fz_term.txt` 令 C9d／C9e RED、`only_a=3`；
  改名（`mv`，字节不变）为 `_r29_falsify_*` 后回 GREEN、`only_a=1`。🔴 ⛔ 为这条去改 `spr38_r8_verify.py`
  的选件判据（属 PROTECT／责任窗所有）；⛔ 删除盘上既有证据件，处置只有改名。

## 8. Git / 推送 / 冻结纪律

- 提交：`git add` **只列本批文件的具体路径**（不用 `-A`/`.`），一次 commit 注明批次，不混入主理人侧文档。
- 备份范式：`mkdir -p _backup/sprNN_<主题> && cp -a scripts _backup/sprNN_<主题>/ && md5sum scripts/*.gd > .../before.md5`。
- 回滚：还原 `_backup` →（有新 PNG 时）`--headless --import` → 重跑 `md5sum -c` → 重跑基线确认回到冻结态。
- **推送归编程侧，但每次都要作者单独点头**；主理人永不 push。
  ⚠️ 本项目实测：**默认 HTTP/2 会 `Recv failure: Connection was reset`，加 `-c http.version=HTTP/1.1` 一次就通**。
  ⚠️ **别信 HTTP 状态码**（中间盒会伪造 200），只认 `git push` 自己的握手输出；
  保护分支用 `--force-with-lease=refs/heads/main:<期望 tip>`；推完 `git fetch` 对齐 ref 再看 `ahead`，
  否则 `ahead` 会虚高。网络断了**不要拿旧 lease 重推**，先实读远端 tip。
  最后兜底（push 通道单独不通时才用）：WorkBuddy 的 `github-publish-via-api` 手法 —— 逐提交 `git cat-file`
  重建 blob/tree/commit 走 `PATCH /git/refs/heads/{branch}`。⚠️ **API 重建出的 sha 必与本地不同**，
  必须维护「本地 sha → 远端 sha」映射，本地对齐只能 `git fetch && git reset --hard origin/main`。
- 令牌：只从会话记录里取、只在一次性推送 URL 内联使用、输出永远 `sed` 脱敏、
  不写进 `.git/config`/remote/文件/凭据管理器，用完审计「确认未落盘」。

## 9. 素材与版权

- 世界观/人物/道具取自作者自有《六道卷》，原始资料 `D:\大纲\`（**只读**，各子目录地位见 §9.0）。
- ⛔ 不用具体剧情、章节顺序、对白、章名（作者本人尚未定稿）；可用人物、世界设定、道具体系与母题。
- ⛔ `D:\大纲\库\05_代价与污染\` 等目录含**他人原作全文**，不得引用其专名、独特比喻、原文。
- 像素美术走**程序化生成**（`_tools/spr25_art_gen.py` 范式：纯 stdlib 写 PNG、10 色索引含透明、硬边无抗锯齿、
  网格图集、自校 IHDR）；**过程帧必须是程序化的**，ComfyUI 只用于静态概念图且需作者点头
  （作者 2026-11-17 已就「人物／怪物静态图」点头开 Comfy 线，过程帧仍走程序化，不放宽）。

### 9.0 六道卷小说工作区 = `D:\大纲`（作者 2026-11-17 钉死：设定只在这里找）

- **两个工作区分清楚**：小说正典／素材／纪要在 `D:\大纲`；游戏代码与设计稿在 `D:\Create\Game\test-1`。
  问「这个设定收没收录」＝在 `D:\大纲` 里 grep，⛔ 不要去 `~/.qoder` 会话存储、别的项目目录、别的助手缓存里翻
  （作者原话：「别老是跑其他地方去」；翻了十几次都是空命中，纯烧时间）。
- 各子目录的**地位不同**，引用前先认清：
  | 路径 | 地位 |
  |---|---|
  | `统一大纲/角色资料库/` | ✅ 正典（人物／谱系／境界），如 `19_漏洞体质与至高意志（天道）谱系.txt` |
  | `统一大纲/剧情文件/` | ✅ 正典剧情 |
  | `统一大纲/新构思与伏笔纪要.txt` | 🟡 未定稿的构思与伏笔台账，可查不可当已裁事实 |
  | `统一大纲/素材（只读·未并入终稿）/` | 🟡 作者投喂的外部素材转写体，**未并入正典** |
  | `.workbuddy/memory/` | 🟡 另一个助手（WorkBuddy）的长期记忆，吸收中间态，⛔ 不作正典引用 |
  | `库/` | ⛔ **他人原作全文**（含 `08_规则副本与无限流/轮回乐园*`），只可参考结构，不得取其专名／独特比喻／原文 |
  | `notes/`、`_backup_*` | 🟡 笔记与备份，真源以上面几栏为准 |
- 「有没有收录」的判据＝**是否落在 `统一大纲/` 正典栏**；只存在于 `素材（只读…）／` 或 `.workbuddy/memory/` 的叫
  「已吸收未并入」，属待裁事项，交主理人／作者裁定，编程侧不自作主张升成正典。
- ✅ **魂系素材是收录了的**（编程侧 2026-11-17 一度误判成「只在 workbuddy 记忆里」，更正）：
  `统一大纲/剧情大纲/人间道重制剧情安排_04_锁定设定与写作红线.txt` **§27 八项（2026-09-26 作者全采）＋ §28 四项（09-27 全采）**
  ＝12 条魂系支线结构登记（索拉尔式／小偷式／隆道尔式／希里斯式／拜尔金沃斯式／亚历山大式／穆尔式／帕奇式／
  巨人树式／水母姐妹式／死亡管理者谱系／癫火式），口径是**只借鉴结构与意象、不落原文**。
- 🔴 **主角口径（作者 2026-11-17 裁定，别再当冲突提）**：「源头」有两义——**世界第一位漏洞体质者 ≠ 苏瑾**，
  苏瑾只是**小说开写处的那个源头**。游戏主角取**人间道第一个漏洞体质者**＝§27 A 索拉尔式（`:137`，
  追寻注定消逝的理想、最后被自己找到的"答案"寄生而疯），**他不在小说正文出场**，在小说里只以苏瑾于
  **藏经阁丙区**（先贤游记／特殊体质轶闻、真伪自甄）读到的形式存在 ⇒ 「游戏主角不是小说角色」不构成冲突，
  `19_漏洞体质与至高意志（天道）谱系.txt:10` 的「源头」是**叙事起点义**，与 §27 A 无时间轴张力。

### 9.1 敌人视觉的两条轨（2026-11-17 实读）

- **原创轨**：`rusher/brute/spitter/bomber/elite/boss/splitter/mini` 共 8 种走 `atlas:"slug"` →
  `resources/texture/wraithswarm.png`（96×192，S26 原创「游魂聚合体」）；Boss 骨架 `PrismWarden` → `shardbearer.png`（160×288）。
- **烂大街轨**：其余约 20 种走 `tex:"<名>"` → `resources/texture/monsters/*.png`，**21 张 32×32、0.3–0.4KB 的 CC0
  Tiny Creatures 通用奇幻 bestiary**（goblin / orc / ogre / minotaur / beholder / skeleton_king / demon / dragon /
  vampire / slime…），内部 id 与显示名同为通用奇幻名——与《六道卷》调性无关，是「小怪太烂大街」的实体所在。
- 三处联动改（漏一处得到处是 `GEN_NAMES` 那类静默空图）：PNG 本体 → `assets.gd MONSTER_NAMES`（装载名单）→
  `data.gd ENEMIES[*].tex`（谁用哪张）。**换皮可以，改名单/改名必须同步这三处。**

### 9.2 ComfyUI MCP 现状与硬前置（实测，别假设它开箱能用）

- workspace `D:\Software\ComfyUI_windows_portable\ComfyUI`（comfy-cli 1.25.0，manager 未装）。
- 🔴 **所有权重目录为空**：`models/checkpoints`、`diffusion_models`、`unet`、`vae`、`text_encoders`、`clip`、
  `loras`、`upscale_models` 一个文件都没有 ⇒ **不下载模型就一张图也生不出来**。
- Comfy Cloud（`cloud.comfy.org`）**未登录**（`auth_status.signed_in=false`），走云要作者自己授权与计费。
- 硬件：RTX 4060 Laptop **8GB VRAM** / 24GB RAM ⇒ SDXL 级可跑，Flux 全精度不建议（量化版另计）。
- 本机 `mcp__comfy__launch_comfyui` 直接返回 `Error executing tool`（无详情），comfy-cli `outdated` 连 15s 都超时
  ⇒ **别把时间花在 comfy-cli 上**，优先用便携包根目录的 `comfyui-server.cmd` / `comfyui-start.vbs` 起服务，
  起没起来以 `mcp__comfy__server_info` 的 `server.running` 为准。
- 交付纪律：生成物先落 `resources/texture/` 以外的暂存区给作者过目，作者选中后才进游戏并补 `.import`；
  ⛔ 批量覆盖 21 张现用图未经逐张过目不许动手（同 S26「原创覆盖」是一批一批过的，不是批量替换）。

### 9.3 风格统一（作者 2026-11-17 硬指标：怪物、主角／人物、道具三族各自成一套）

- **三族分别成组**，不跨族混风格：①怪物／执令（`monsters/*.png` 21 张）；②人物（`merchant_0/1/2`）；
  ③道具／物件／图标（`chest_*`/`door_*`/`stairs`/`pedestal`/`secret_wall`/`prop_*`/`relic_*`/`wpn_*`/`icon_*`，
  **浮游炮 `浮游炮.png` 归这一族**、本批不换）。同族共一套，族间靠同一光照与同一基准色表保持血缘。
  ⛔ `shardbearer.png`（玩家图集）本批不换图——它已是基准表出产物，换它才是引入发散。
- **概念稿侧统一**：同族共用**一句框架 prompt**（视角、机位、姿态、材质、光照、留白口径逐字相同，
  只替换 `<SUBJECT>` 一个槽位），共用**同一 checkpoint、同一负面词、同一族基种子＋族内派生号**；
  要调构图必须**整族一起调**，单改一张就是破坏统一（`spr34_gen.py --check-doc` 拦文本漂移，`--selftest` 拦机检假绿）。
- **落盘侧的决定性统一手段是「全项目一张固定基准色表」**（主理人 2026-11-17 改判）：以 `spr25_art_gen.py:31-41`
  那十色（INK/GREY/BROWN/STONE/BONE/RUST/RUST_DIM/LIT/CYAN/COPPER）为基准表，所有新族**量化到这张表**；
  ⛔ 不做「一族一 median-cut」——屏上面积最大的 `shardbearer.png`／`wraithswarm.png` 本批不动且已出自这十色，
  族级色表会让新两族互相统一、却跟玩家和 8 虫各自为政，观感反而更花。median-cut 只用来**提议**新色，
  提案须逐色登记并说明十色为何不够才允许进表。机检 **D-E：每张新图的不透明色集合 ⊆ 基准表**（比「≤10 色」强）。
- **构图口径按族取值并在终态像素上量**（实稿 §4.5.2／§4.5.5）：`fill_h` 区间、`fill_w` 上限、`bottom_gap` 三条，
  悬空主体改判上下留白对称；成对差分件（宝箱开合／门开合／桶破损）追加 bbox 左上角与宽高差 ≤1px 的配对判据。
  目标画幅照抄实稿 §3.2b 表，⛔ 运行时猜尺寸；⛔ 改宽高（尺寸写在 `.gd` 的 scale/position 里，属机制面禁改区）。
- **框架句与实稿逐字对账**：`spr34_gen.py` 的 `HEAD_*`／`SUBJECTS`／`NEG*` 常量必须命中实稿原文，
  跑图前先 `python _tools/spr34_gen.py --check-doc`（红了不许开工）。**改框架＝整族重跑**。
- **验收以母表为准**：每族一张**母版接触表**（同族并排 + 暖／冷／灰三档）交作者过目，作者点头才算「成套」；
  探针只做阴性/阳性自证（`--selftest` 三条负例必须红），不替作者判定风格。16×16／12×12 小图不从 SDXL 缩
  （64× 降采样＝抽样不是缩小），改为**程序化从基准表绘制**（§9 `spr25_art_gen.py` 范式）。


## 10. 已过期口径（旧文档里会看到，以左列为准）

| 旧文档说 | 现状 |
|---|---|
| `md5sum -c SPR7-FROZEN-4.md5` | 用 `production/sprint-21/SPR21-FROZEN.md5` |
| 冻结 34/34 OK、`HEAD dbdb938`、行号 | 冻结随批变动，每轮实读报数；行号只当线索，索引一律用函数名 |
| S15「主理人是 WorkBuddy 里的 team-lead 智能体」 | 已迁到 Qoder：智能体 `六道卷游戏 · 主理人`；WorkBuddy 的 `teams/sprint15-handoff`（27 成员）只是历史存档 |
| 看板项 `SPR26-AUDIO-01` BGM 六道卷化 = in_progress | **实际已完成**（`README.md` S26 批一：3 首 BGM 重写），不要重开 |

## 11. 作者偏好（跨项目硬规矩，源自 WorkBuddy 长期记忆）

- **武器族不止弹幕武器**（作者 2026-11-18 口径，逐字：「可以借鉴元气骑士或者重生细胞，武器不仅仅只有弹幕武器」
  ＋「其实还有特殊武器啥的，比如激光炮，特殊路径的投斧，死亡笔记这种娱乐性武器，还有各种类型的，合理即可」）：
  `weapons.gd DEFS` 现有 7 条**全部**走 `player._fire() → spawn_player_bullet()` 这一条弹道路径，近战／投掷／盾／法杖
  一类「非弹幕」形态目前**一条都没有**（`grep 近战|melee|swing|blade` 全仓零武器命中，只有敌方的
  `knight 盾骑士 ai:"chase"` 与我方主动遗物「环盾」）。⇒ 设计新武器族时**不要默认 DEFS＝枪械表**；
  这条口径同时约束 S36 那 14 把 Boss 专武的构成（是否全是枪，归创意侧主理人裁定）。
- 三条**技术死线**（编程侧实读，写规格前先认）：①⛔ `bullet.gd setup()` 现值 **17 个行为参位**（`scripts/bullet.gd:25-28` 实读），**不许再加新位**
  （加了牵动 `spawn_player_bullet` 与 `player._fire` 全部调用点），所以激光（hitscan）、回旋/特殊路径投斧这类
  「不走直线子弹」的形态**必须另立弹体节点脚本**，不能塞进现有 `Bullet`；②🔴 E1 确定性——`Game.rng` 在开火路径上的消耗点共三处（现场 grep 坐实：弹幕 `_fire()` 段 `player.gd:672` 每发恒 1 次暴击抽取（`:670` 的单发散布抖动是分支条件抽取，非恒消耗）；近战 `_swing()` 段 `:701`；volley 技能 `:838` 每发 1 次）。任何**新增开火／挥击通路**（近战/光束/投掷/盾击）都必须满足两条：(a) 每次**有效执行**恒消费 `Game.rng.randf()` 恰 1 次——0 次＝整条随机流前移一格、2 次＝后移两格，指纹与全部冻结串漂；(b) 消耗量与该通路的分支结果**无关**：⛔ 抽进命中循环（命中几个抽几个）、⛔ 抽进 `if hits > 0` 之后（空挥不抽）、⛔ 整局只凑一次。既有范式参照 `player.gd:689-691` HP-2 注释与 V-E1d 两把变异刀。⚠️ 旧文「`player.gd:410` 每发子弹消耗一次」已废：`:410` 实为 `if _stance_probe:`，且旧表述会被误读成「只有开枪那条路耗 rng」；③「死亡笔记」这类**他作 IP 专名不得进游戏内文本**（AGENTS §9＋S36 HP-7），
  取型可以——「按名字裁定死亡」这个母题我们自己的地狱道（阎王审判／纳名／姜尚收魂）本来就有现成载体。
- **绝不反复提醒「更换/撤销密钥」**（已明确说这严重影响阅读成本）。清理动作照做，撤销由作者自理，不播报、不列链接。
- **不发起名字/称呼/身份类问答**；需要指代时直接说「你」。
- **不擅自碰系统底层**（电源计划、驱动、服务启动类型、注册表、计划任务、BIOS）：先讲清「是什么/干什么/风险/能否还原」再问。
  判断栏每个选项都要写**风险等级与可否回滚**，不能只写「推荐」。
- 讨厌绕弯子与无关提问；**「记得××」这类附带要求当硬指标完成**。
- 涉及**删除**：即使已有笼统授权，也要先列**具体清单**再确认一次；
  区分「已卸载残留」与「作者在用的软件」，后者只列不删、不用「流氓」定性；
  作者主动装的东西不当垃圾。清 C 盘空间时别拿「删 D 盘」充数。
  ⚠️ 本机删除**会进回收站**（`NukeOnDelete=0`），要真正释放空间得「删 ＋ 清回收站」两步。
- 认可**诚实披露缺陷**：报告局限比只报优点更被接受；跑失败的探针要写明 `UNEXECUTED`，不默认忽略、不记 PASS。

## 12. 创新、借鉴、视觉与远端仓库（作者 2026-11-18 追加，判断栏已答）

- **招牌要有，而且一句话讲得清**：对标＝《重生细胞》的下坠爽感、《元气骑士》的空手手刀。本项目的答案（作者选定）＝
  **正签《留痕》＋先行试点《借一刀》**，实稿见 `production/sprint-40/SPR40_特色创新候选清单.md`。
  ⇒ 每批机制动手前先问「它给招牌贡献什么」，⛔ 为凑机制新开平行系统；答不上来的先不上桌。
- **遇到难题鼓励上网查成熟游戏的公开设计经验**（只狼的格挡／架势、重生细胞的手感、元气骑士的近战消弹幕等），
  查到的结论**带来源**落在实稿里，⛔ 落进正文当自己想的。**借鉴只取机制与体验层**：⛔ 抄美术素材、⛔ 抄 IP 专名、
  ⛔ 抄原文文本（§9 版权纪律；「死亡笔记」那类他作专名的老教训同此）。
- **武器不做火药枪**（作者看图实测后裁定）：起始武器＝**一支朱砂笔**，`rifle/shotgun/railgun/launcher` 这一支
  **id 一并换**（不是只换显示名——「名字是朱砂笔、id 还叫 rifle」是两层皮）。优先中式冷兵器／玄幻法器／符纸；
  数值字段照实稿（⛔ 编程侧自己改数值）。⇒ 牵动 `META_WEAPON_POOL_BASELINE` 与冻结清单的**那一次冻结基线重登**
  仍归作者，串只能逐字转录，⛔ 自刷（§4／§8）。
- **概念稿返修按「被点名」为单位**：作者判定中式风格线**基本过关**，被点名的只有枪那一类（`wpn_rifle`／`wpn_shotgun`／
  `wpn_railgun`）。单件质感问题**只返修那几张**，⛔ 顺手整族重跑；只有**改框架句**才必须整族一起重跑（§9.3）。
- **GitHub 当仓库（分支＋主体＋备份都放远端）**，作者给的授权线：**备份／主题分支可自主 push**；
  `main`、发版、打 tag **逐次授权**。⛔ force push、⛔ 改写已推送历史、⛔ 把没绿门禁的提交推上去。
  每次 push 前把「推了什么、几个 commit、门禁哪条绿」写在报告里，⛔ 只报一句「已推送」。

