# Sprint 19 规划草案（主理人 / 规划侧）· 汇编定稿版

> 状态：**方向已由用户拍板（A · `shrine` 第六类发现集）**；设计侧 `SPR19-DESIGN-01` 已回传并实读核验；工程侧 `SPR19-SURVEY-01` 因网络 502 掉线未产出，其勘察范围由主理人以**读码核验**补齐（§八），不冒充工程侧结论。
> 用户裁定「定了我出草案并派单，中途不再逐项打断」—— §九 四条裁定由主理人拍板，不再回问。
> 基线实测（2026-11-10）：HEAD `cb22513` = `origin/main`，工作树干净，`md5sum -c` 34 OK / 0 FAILED，34 个 `.gd`。

## 〇、定位与措辞归属

Sprint 18 D 原设计是「三卡中已发现的条目才显示手记」，但 `CODEX_KINDS` 五类不含 `shrine`，条件对 `SHRINE_OFFERS` 恒假，只能改恒显；D 的价值主张因此从「发现度回报」**降级为「场所的持续性在场」**。

**S19 补回圣所交换这件事的发现度回报，但回报由新增的第六类发现集承担，不记到 S18 D 灰字层头上。** 正确表述（采纳设计侧 §3.1）：

> S19 新增 `shrine` 第六类发现集，补回圣所交换这件事的发现度回报；S18 D 灰字恒显仍是独立叙事层，两者共用同一批 `FLAVOR` 文案但互不耦合。

⚠️ **措辞红线**：不得写「D 升级回发现度回报」「D 接上了发现度闭环」。核验若照这句去 `shrine_panel.gd` 找发现判定，那里根本没有 —— 立刻构成文档与实现不一致（S18 刚踩过同型坑）。

红线不变：零新增房型 / 敌人 / 资源 / 输入动作，零新增 `Game.rng` 消费，零 E1 指纹重定，`ACTION_DEFS` 零新增，`FLOOR_THEMES` 不动。

## 一、阶段诊断（主理人实读，行号为本轮实测）

| 锚点 | 实读结论 |
|---|---|
| `game_state.gd:279` | `CODEX_KINDS` 五类，不含 `shrine` |
| `game_state.gd:280` / `:349` | `codex` 初始字典**两处硬编码**，扩类必须两处同改，漏一处则 `validate` 报「缺少分类」、`save_codex` 取 `codex[kind]` 空指针 |
| `game_state.gd:293-314` | `_codex_id_valid()` 的 `match kind` 需加 `shrine` 分支 → `Data.SHRINE_OFFERS.has(id)`（与 `suffixes:308` 同型） |
| `game_state.gd:318-332` | `mark_codex()` 先 `codex.has(kind)` 守卫(:319)，再验 id，再 append + `save_codex()`；播报取 `Data.FLAVOR.get(kind + "/" + id, "")`(:330) |
| `game_state.gd:353` / `:373` | `load_codex` / `save_codex` 遍历 `CODEX_KINDS`，扩类后**自动覆盖**读写，函数体无需改 |
| `game_state.gd:381-387` | `codex_boons()` 按 `CODEX_BOONS[*].kind + need` 逐条判定、**不按总发现度比例**；`data.gd:344-347` 四条 kind = enemies/relics/themes/bosses → 扩第六类不改变 boon 判定 |
| **`game_main.gd:2245-2251`** | ⚠️ `_codex_boon_suffix()` 把**全部 `CODEX_KINDS` 拼进 key** 走 `stable_hash` 派生开局铭刻词缀 → **扩类后 key 静默变长，派生结果漂移**，详见 §八-1 |
| `menu.gd:429-474` | `_codex_section(kind,title,total,name_of)` 通用渲染：标题分母、ProgressBar、已发现名单、未发现占位、手记行(:463-468)全自动派生 → 第六类只需在 `_build_codex():367` 末尾加一次调用 |
| `game_main.gd:2136-2150` | `_on_shrine_chosen()`：`_shrine_affordable()` 双保险(:2140) → `_shrine_execute()`(:2142) → 清房(:2143) → `_echo_choices.append`(:2145) |
| `shrine_panel.gd:188-196` | `_pick(i)` **单选** emit；`open():121` 显示 3 张但只选 1 张 → 单次只登记一条 |
| `data.gd:313-325` | `SHRINE_OFFERS` 10 条含 `name`，`min_floor` 分层 3/5/7；10 个 name 与 `FLAVOR` 手记首短句逐字一致 |
| `data.gd:379-392` | S18 D 已写入 10 条 `shrine/<id>` 手记；上方 4 行注释写着「**不喂 mark_codex**」，扩类后与实现冲突（A1 必改） |

`CODEX_KINDS` 全库引用实测 **8 处**：`game_main.gd:2249`、`game_state.gd:353/373`、`player.gd:1012/1022/1092/1228/1243`、`validate.gd:229`。

## 二、两处前置 · 最终裁定（采纳 design-s16 实稿）

### 前置 1 · 发现口径 = 「玩家实际交换过」

挂点精确为 `_on_shrine_chosen()` 内 **`_shrine_execute(offer)` 成功返回之后**、与 `_echo_choices.append()` 相邻行。两道守卫缺一不可：`_shrine_affordable()` 拦置灰卡（不能因「看过」登记），`_shrine_execute()` 拦执行链早退（不能因「试过」登记）。

设计侧补的最强论据是**跨 GDD 一致性**：既有五类登记的全是「事件结果」（已遇 / 掉落即发现 / 已获 / 已历 / 已击败），没有一类是「系统把选项摆给我看过」；「三卡显示过」登记的是 rng 发过什么牌，属异类。另两条：稀缺性（每层 1 间、一次 1 张、`min_floor` 3/5/7 分层 → 全收集需跨多局刻意选不同卡）、零实现代价（与 S16 抉择链同源同序）。

SDT 落点按设计侧订正：主补**胜任**（10 种都做过 = 可累积阅历），附带自主；不写成「补自主」。MDA 新决策情境是「为集齐而选没试过的卡」与「永远选当期最优卡」的张力。

**卡面「首见 vs 已见过」→ 不变，写进红线**：改了就是把局外发现度回注局内决策界面，同时踩认知过载与主导策略，且推翻 S18 D 定性。**回报只走「局外图鉴页 + 瞬时 toast」两个通道，不碰卡面。**

### 前置 2 · 播报 / 标题 / 显示名

- **kind 逐字 `shrine`（单数）**：写成 `shrines` 则 `mark_codex` 拼出的键查不到 10 条手记、**静默失败不报错**（icon_codex 同型坑）。负向断言锁死，另加**正向断言**：toast 文本确实含对应手记句。
- **图鉴标题「已行抉择」**（否掉「已识圣所」：一「识」= 见过，与「实际交换过」矛盾；二分母是 10 条交换条款、不是圣所房间数，写「圣所」会误导）。「行」对应做过，「抉择」是项目既有术语。
- **显示名单源**：`Data.SHRINE_OFFERS[id].get("name", id)`，分母 `Data.SHRINE_OFFERS.size()` 单源不硬编码 10，`.get` 兜底防英文 id 直出。登记观察：`name` 字段与手记首句是**双源**，未来改 name 手记不自动跟随。
- **首发现播报沿用 S18 那 10 句，不另写**：取键规则与 `shrine/<id>` 天然对齐，扩类后自动点亮，零新表 / 零改通用函数。「恒显 + 首发现复读」是 S18 B（themes 手记层签恒显 + 首发现播报同句）已接受的既定形态。实稿 §四 那 10 条备选文案**不采用**。

## 三、范围清单（登记三件套）

**必改**
1. `game_state.gd`：`CODEX_KINDS` 加 `"shrine"`；`codex` 初始字典两处（`:280` / `:349`）同步；`_codex_id_valid()` 加 `shrine` 分支；`:277` 注释补「/ 已行圣所抉择」。
2. `game_main.gd`：`_on_shrine_chosen()` 内、`_shrine_execute()` 返回之后调 `Game.mark_codex("shrine", String(offer["id"]))`；**`_codex_boon_suffix()` 保护派生**（§九-1）。
3. `menu.gd`：`_build_codex()` 末尾加 `_codex_section("shrine", "已行抉择", Data.SHRINE_OFFERS.size(), <显示名 Callable>)`。
4. `data.gd:379-382`：A1 注释改写为「同时供灰字直查与 `mark_codex` 首发现播报」，保留「灰字恒显」那句；10 条文案一字不改。
5. `validate.gd`：**新增 P0 启动期断言**（§九-2）；`_check_codex():229` 循环自动覆盖。
6. `player.gd`：新增断言与负向对照（§四）；6 处「五类」措辞订正为「六类」（`:1084/1090/1095/1226/1246` 及注释），改的是字符串不改逻辑。
7. 交付文档 / `玩法说明.md` / `README.md` 随批增补（§九-4 清单）。

**零动**：`meta.gd UNLOCKS`、`Meta.STATS_KEYS`、`CODEX_BOONS`、`SHRINE_OFFERS` 表本体、`_shrine_offers_for()` 派生 key、`ACTION_DEFS`、`FLOOR_THEMES`、`GEN_NAMES`、`_roll_calamity()`、任何 rng / 计时路径、`shrine_panel.gd` 灰字恒显逻辑、`mark_codex()` 通用函数体。

**登记三件套③（本批重点）**：必须真调 `menu._build_codex()` 验渲染文本含「已行抉择」与 `n / 10`，并验 `mark_codex` 播报文本含 `FLAVOR["shrine/<id>"]`；**只验 `codex["shrine"].size()` 不算**（S14 icon_codex 教训）。

## 四、门控（沿用 S17–18 口径）

1. headless 6000 帧 **0 报错**。
2. `md5sum -c SPR7-FROZEN-4.md5` → **34 OK / 0 FAILED**；按实际改动文件逐行重定，`diff` 证明变更行数 = 改动文件数，其余行一字节不动。
3. **E1 只比对 `[SMOKE-META] fingerprint` 行**，禁整体日志 `cmp`；**跨批对照禁用 `SMOKE_DAILY`**（`game_main.gd:344-346` 用当日日期覆盖 `SMOKE_SEED`）。
4. E6 grep 零 raw `delta`；零新增 `Game.rng` 消费（`mark_codex` 纯局外登记，不进指纹）。
5. **负向对照**：① 未知 `shrine` id 被拒 ② 重复登记幂等且不重复播报 ③ kind 若写成复数则播报键查不到 ④ 旧 `codex.cfg` 无 `shrine` 键时 `load_codex()` 给空数组且不报错 ⑤ 显示名单不直出英文 id。
6. **正向断言**：toast 文本含手记句；图鉴渲染含新标题与 `n / 10`；`_codex_boon_suffix()` 三态一致（§九-1）。
7. 断言按四类标注性质，后两类须补强或注明。

## 五、阶段划分（每阶段一个 commit，不回头补）

| 阶段 | 内容 | 交付 |
|---|---|---|
| 一 · 核心登记 | 必改 1–4、门控 1–4、阶段一交付文档 | `SPR19_交付_阶段一.md`，单独 commit |
| 二 · 断言与收口 | 必改 5–7、断言/负向对照、玩法说明 / README / S18 增补注记、文档批 | `SPR19_交付_阶段二.md` + 文档批，各一个 commit |

流程：**实施 → 四门控 → 冻结重定 → 交付文档 → 单独提交 → 主理人读码核验**。

## 六、预期不变项

34 个 `.gd`；`FIXED_DT` 33 处；`ACTION_DEFS` 18 条；`SHRINE_OFFERS` 10 条；`FLAVOR` 10 条 `shrine/<id>` 文案一字不改；`codex_boons()` 四条判定结果不变；**`_codex_boon_suffix()` 对同一档的派生结果逐字不变**（§九-1）；E1 指纹逐字一致；提交后工作树干净。

## 七、设计侧产出

`production/sprint-19/SPR19_设计口径实稿.md`（128 行，design-s16）。两处前置裁定、标题/显示名/文案口径、A/B/C 三类待订正清单、P0 防线建议、手记拼接放大项。已由主理人实读核验，除 §九 四条裁定外全部采纳。

## 八、主理人读码核验补遗（代工程侧勘察，待 engineering-lead 复核）

> 工程侧 `SPR19-SURVEY-01` 因 `502 ENETUNREACH` 掉线，未产出 `SPR19_技术勘察.md`。以下 8 处引用由主理人逐条实读补齐，属**读码核验**而非工程侧专业结论；实施前 eng 须复核。

| 引用 | 扩类后行为 | 判定 |
|---|---|---|
| `game_state.gd:353` `load_codex` | 自动多读一轮；老档无 `shrine` 键 → `get_value` 默认 `[]` → `clean=[]` → `codex["shrine"]=[]` | ✔ 自动覆盖，旧档安全 |
| `game_state.gd:373` `save_codex` | 自动多写一轮；`codex[kind]` 须存在 → 依赖两处初始字典同改 | ⚠️ 漏改一处即空指针 |
| `validate.gd:229` `_check_codex` | 自动多验一轮 `codex.has("shrine")` | ✔ 自动覆盖；漏改字典会红（正是想要的门） |
| `player.gd:1012` 清空 → `load` → 断言 | 自动多清一轮 | ✔ 自动覆盖 |
| `player.gd:1022` 逐类比对 `snap` | 自动多比一轮；`snap = codex.duplicate(true)` 含新键 | ✔ 自动覆盖 |
| `player.gd:1092` P0-3.2 现场恢复 | 自动多比一轮；**断言文案写死「五类」**(:1095) | ⚠️ 逻辑自动，措辞过期 |
| `player.gd:1228` / `:1243` 落盘前后快照比对 | 自动多比一轮；**:1246 文案写死「五类」** | ⚠️ 逻辑自动，措辞过期 |
| **`game_main.gd:2249` `_codex_boon_suffix`** | **key 静默变长 → 派生词缀漂移，现有断言不红** | 🔴 **必须显式处理，见 §九-1** |

调用链实读：`start_run:354 _apply_codex_boons()` → `:2223` 遍历 boons → `:2238 "suffix"` 分支 → `:2239 player.attach_suffix(_codex_boon_suffix())` → `:2245-2251` 拼 key。`player.gd:1149` 只验 `relic_suffixes.size() == 1`（验数量不验 id），`player.gd:1127` 是常量自比较、`player.gd:1144` 是前提守卫型恒过 —— **三条都不覆盖「跨版本派生一致性」，属假绿**。

其它实读：`codex_path()`(`game_state.gd:283-289`) 三级路径（`SMOKE_CODEX_PATH` / `CODEX_SMOKE_PATH` / 默认）不受影响；`shrine_panel.open():148-155` autopilot 每 0.5s 选第一张可支付卡，新增登记在 `game_main` 侧、不改面板，SMOKE 自动驾驶路径不受影响；`[SMOKE-SHRINE] chose=` 日志行(`game_main.gd:2150`) 不变。

## 九、主理人裁定（四条，不回问用户）

### 1 · 🔴 保护 `_codex_boon_suffix()` 派生，禁止静默漂移

`game_main.gd:2249` 的循环里**跳过 `shrine`**（或改为显式五类常量），使同一 `codex.cfg` 在 S19 前后派生出**逐字相同**的词缀 id。

理由：① 本批是「加关系」，不该改变既有 boon 的派生结果；② 老档无 `shrine` 键时 key 平白多 `shrine=|`，属无意回归；③ `CODEX_BOONS` 没有 shrine 阈值，让 shrine 发现度影响 boon **不是**设计意图，只是实现副作用；④ 成本极低。

配套**验效果型**断言：同一档在 `codex["shrine"]` 为 `[]` / 含 1 条 / 含 10 条三态下，`_codex_boon_suffix()` 返回值逐字相等（真差值断言，正好补上 S17 盘点里「常量自比较」的缺陷）。交付文档须如实登记：该漂移**不是 E1 违规**（图鉴档是局外输入，既有口径「档不同 → 起始状态不同」），属**跨版本基线漂移**，已主动切断。

### 2 · 采纳 P0 防线断言

`validate.gd` 启动期遍历 `Data.CODEX_BOONS`，命中 `kind == "shrine"` 即 `problems.append`，与 S15「kind 不得为 suffixes」同型。防未来扩表把 shrine 加进阈值后形成「交换 → 加 boon → 更易交换」正反馈。

### 3 · 图鉴手记无分隔符 → 本批不改，登记为在册观察

实读 `menu.gd:463-468`：`flavor += FLAVOR[kind+"/"+id2]` 无分隔符，但有 `AUTOWRAP_WORD_SMART` + 560 宽 + 字号 12（会自动换行），且每条文案**自带句号**可断句；既有 `themes` 8 条约 105 字已是同形态，shrine 满格 10 条约 150 字，属同量级放大而非质变。改 `_codex_section()` 是通用渲染，会同时改变另外 5 类 → 范围蔓延，且需 UI 复核。**独立批次统一处理**，交付文档登记「既有形态被放大，非本批引入」，核验时不得误判为新排版 bug。

### 4 · 价值主张不升级；待订正清单按 A/B/C 三类执行

- **A 类（必须订正）**：`data.gd:379-382` 注释 4 行；`game_state.gd:277` 注释；`player.gd` 6 处「五类」措辞；`README.md` 概况与状态表（**增补 S19 一行，不改写 D 行历史描述**）；`玩法说明.md`「圣所熟客手记」段补一句「Sprint 19 起，实际交换过的选项另记为第六类图鉴发现」；若出现「五类发现集」数量改「六类」。
- **B 类（只加 S19 增补注记、不改正文）**：`SPR18_D文案候选.md` §三/§四、`SPR18_交付_阶段二.md` §2.2、`SPR18_规划草案.md`、`SPR18_设计候选实稿.md`。这些句子在 S18 当时是真话，「灰字零耦合」在 S19 后依然成立，只有「五类不含 shrine」这个**依据**过期。把历史正文改成「六类」会让交付文档与当时提交的代码不符，制造新失真。
- **C 类（明确不改）**：S18 §四 的 D 定性（特指灰字层）、措辞红线、`CODEX_BOONS` 零改动结论。

## 十、实施单派发

`SPR19-IMPL-01` 发给 `eng-handoff`（engineering-lead），以本草案 §三 / §四 / §八 / §九 为规格，阶段一先落；每阶段单独 commit，**提交前须经用户许可**（本会话尚未授权提交）。设计侧口径以 `SPR19_设计口径实稿.md` 为准，主理人不擅自改写专业结论。
