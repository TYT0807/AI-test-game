# Sprint 28 批一 · 实施单（编程侧）——圣所「净化」代价修复

> 本文是批一**唯一权威**。上游：`production/sprint-28/SPR28_批一设计实稿_净化代价.md`（164 行，主理人已拍方案 B）。
> 基准 HEAD `2ebdc38`，本地=远端，工作树干净，`scripts/` 34 个 `.gd`，冻结快照 `production/sprint-21/SPR21-FROZEN.md5` 34/34 OK。
> **只改 `.gd`**；文档由主理人写；**推送不归你**。

---

## 一 一句话

圣所「净化」目前的代价靠 `calamity_floors.size() > 0` 这个**整局存在性布尔**决定，只要本局还有别的灾祸层，净化就**零代价**（按设计稿 §2，`M=10` 时白拿率 **73%**）。本批改成：**只要本局净化过，结算确定放弃 ×1.5**。不加资源代价、不动 `cost_kind`、不动图鉴代价桶。

---

## 二 硬红线（越任一即 FAIL）

1. 🔴 **`Data.SHRINE_OFFERS` 的字段集零新增**。只准改 `purify` 那一条的 `desc` **值**；`cost_kind` / `cost` / `min_floor` / `name` **一个字都不许动**。
2. 🔴 **零新增 `Game.rng` 消费**（E1）。E1 对照用 seed `12345` / `777` / `42`，`[SMOKE-META] fingerprint` 必须逐字一致。
3. 🔴 **不动 `_echo_costs` 的桶**。`cost_kind` 必须仍是 `""`，否则图鉴复盘「实用流」标签（`game_main.gd:3190-3202`）变不可达、三处已上线口径作废。
4. 🔴 **不动 `oath_count("purify_used")`**：守护印记（`data.gd:361`, `watched: ["purify_used"]`）零回归。
5. 🔴 **`calamity_floors.erase(Game.floor_num)` 保留**，不许因为「新机制已经承担代价」而删掉它——`player.gd:892` 有断言，且记录如实是数据模型的一部分。
6. 计时一律 `Game.FIXED_DT`；本批无计时改动。
7. 冻结清单：除了本单授权改动的文件，其余 32 个 `.gd` 零字节漂移。**不要自行刷新快照行**（快照由核验侧收官时统一刷）。

---

## 三 生产代码改动（4 处，逐字）

### 3.1 `scripts/game_state.gd` —— 新增按局布尔

**(a)** 紧邻 `:588` 的 `var calamity_floors: Array = []`，新增一行：

```gdscript
var purified_run := false   # S28 批一：本局是否净化过——净化代价的单一来源（按局归零，见 reset()）
```

**(b)** `reset()` 内 `:143` 的 `calamity_floors.clear()` **下一行**新增：

```gdscript
	calamity_floors.clear()
	purified_run = false
```

🔴 必须放在 `reset()` 内。放错位置（例如 `start_run()` 末尾、或只在探针里清）会让跨局污染，C 组断言专抓。

**(c)** `settle_shards()` `:417-423` 的判定行改成：

```gdscript
func settle_shards(cleared_floors: int) -> int:
	var n := int(maxi(cleared_floors, 0) * META_RATE)
	if calamity_floors.size() > 0 and not purified_run:
		n = int(n * 1.5)
	sigils["shards"] = int(sigils["shards"]) + n
	save_sigils()
	return n
```

即**只加 `and not purified_run`**，其余一字不动。`META_RATE` 与 `floor()` 行为不变。

### 3.2 `scripts/game_main.gd` —— 净化分支记账

`:3086-3092` 的 `"purify":` 分支，在 `Game.calamity_floors.erase(Game.floor_num)` **之前**加一行：

```gdscript
		"purify":
			_clear_calamity_effects()
			_calamity = ""
			Game.purified_run = true   # S28 批一：代价的单一来源——本局确定放弃 ×1.5
			Game.calamity_floors.erase(Game.floor_num)   # 记录如实；本行不再承担代价（代价见 Game.purified_run）
			oath_count("purify_used")
```

🔴 两件事：`purified_run = true` 是**代价的单一来源**；`erase` **保留但降级为「记录如实」**，注释按上面逐字改（旧注释「若为唯一灾祸层」会误导后来人只改一半）。

### 3.3 `scripts/data.gd` —— 只改 `desc` 值

`:316` 那一行，只把 `desc` 的字符串换成下面这个，其余字段逐字不动：

```gdscript
	"purify": {"name": "净化", "desc": "解除本层灾祸；本局 ×1.5 结算加成作废", "cost_kind": "", "cost": 0, "min_floor": 3},
```

### 3.4 `scripts/shrine_panel.gd` —— 只改默认分支返回值

`:166`：

```gdscript
	return "代价：本局 ×1.5 加成作废"
```

🔴 **该默认分支全表只有 `purify` 会走到**（其余 9 项 `cost_kind` 非空），零误伤。不要改 `:159-165` 的三个已有分支。

---

## 四 探针（新增 23 条，写在既有探针块末尾，编号 `SPR28B1` 前缀）

挂载入口：`game_main.gd` 的 `_ready()` 里，仿照现有 `SMOKE_CAL_THEME` / `SMOKE_OATH_GRANT` 加一个 `SMOKE_PURIFY_COST=1` 分支，调用新函数 `_test_purify_cost()`。**不改既有探针的任何断言或期望值。**

判红口径：沿用批二探针的 `ok=` 字段格式（自带 `ok=true/false`），门控三条：`#NN == 23` / `[ERR] purify_cost == 0` / `ok=false == 0`。

| 组 | 编号 | 断言行 | 抓哪个错误 |
|---|---|---|---|
| A 状态 | A01 | 新局开局 `Game.purified_run == false` | 字段初值错 |
| | A02 | `Game.reset()` 后 `purified_run == false` | reset 漏清 |
| | A03 | 净化分支执行后 `purified_run == true` | 记账漏写 / 写错字段 |
| | A04 | 净化后 `calamity_floors.has(本层) == false` | 把 `erase` 当冗余删掉 |
| | A05 | `Data.SHRINE_OFFERS["purify"]` 的 `cost_kind == ""` 且 `cost == 0` | 擅改字段集 |
| B 结算 | B01 | 无灾祸、未净化 → `settle_shards(M) == floor(M*META_RATE)` | 无端乘 1.5 |
| | B02 | 单灾祸、未净化 → `== floor(M*META_RATE*1.5)` | 把 1.5 一起删掉 |
| | B03 | 多灾祸（≥2）、未净化 → 仍 `×1.5` | 把判定改成按层累加（方案 C 误入） |
| | B04 | 单灾祸、净化 → 不乘（**与今天一致**） | 回归基线 |
| | B05 | **多灾祸、净化 → 不乘**（`M=10` 应收 20 而非 30） | **本批靶心**，今天会乘 |
| | B06 | 净化后手工往 `calamity_floors` 塞一个别的层号 → 仍不乘 | 证明作废由 `purified_run` 决定，不是靠 `size()` |
| C 跨局 | C01 | 净化后立即 `Game.reset()` → 新局未净化有灾祸仍拿到 ×1.5 | 跨局污染 |
| | C02 | 「净化局 → 未净化局」交替 3 轮，每轮返回值按预期交替 | 状态只增不清 |
| | C03 | 连续两次净化不叠加（返回值与一次净化相同） | 布尔被写成计数 |
| D 零漂移 | D01 | 净化局的 `_echo_costs` 仍含 `""` 键 | 擅迁桶 |
| | D02 | `_echo_tag()` 对 `{ "": 1 }` 仍返回「实用流」 | 分支被改死 |
| | D03 | 净化后 `_oath_counters["purify_used"] == 1` | 誓约计数丢失 |
| | D04 | 净化前后 `Game.rng.seed` / `.state` 逐字不变 | 新增 rng 消费 |
| E 文案 | E01 | `desc` 含「本局 ×1.5 结算加成作废」 | 只改代码不改文案 |
| | E02 | `_cost_text({"cost_kind": ""})` == 「代价：本局 ×1.5 加成作废」 | 面板仍说「或失效」 |
| | E03 | 其余 9 项 `cost_kind` 均非空（默认分支仅净化可达） | 误伤别的卡 |
| F 静态 | F01 | 全仓 `Game.purified_run = true` 词边界恰 **1** 处 | 多处记账 |
| | F02 | `settle_shards` 判定行含 `and not purified_run` | 判定被改回存在性布尔 |

🔴 B 组构造注意：`settle_shards()` 会写 `sigils["shards"]` 并 `save_sigils()`。每次调用前必须把 `Game.sigils["shards"]` 还原到入口快照（用 `Game.sigils["shards"] = 快照` 直接赋值，**不要走 `add_shards`**），否则 D 组与后续断言全被污染。探针收尾同样要还原，避免污染同进程其它探针。

🔴 D04 判据：`Game.rng.seed` 与 `Game.rng.state` **两个都要比**——只比 `.state` 不够（`reset`/`daily` 路径会读 `.seed`）。这是 S27 批二 C07 的既有教训。

---

## 五 验证门（全部要自跑并报数）

| 门 | 期望 |
|---|---|
| G1 `validate` | `34/34 通过`、`problems=0` |
| G2 新探针 | `#NN == 23` / `[ERR] purify_cost == 0` / `ok=false == 0` |
| G3 E1 | seed `12345` / `777` / `42`，`[SMOKE-META] fingerprint` 对基线 `2ebdc38` 逐字一致；`run start diamonds=` 三 seed 分别 3 / 13 / 3 |
| G4 全探针回归 | `SMOKE_CAL_THEME`（103）+ `SMOKE_OATH_GRANT`（43）+ `SMOKE_META*` + `SMOKE_RG7` + `SMOKE_SAVE` + `SMOKE_OATH` + `SMOKE_ECHO_CHAIN` 同进程跑，`[ERR] == 0` |
| G5 冻结 | `md5sum -c SPR21-FROZEN.md5`：除本单授权的 `game_main.gd` / `game_state.gd` / `data.gd` / `shrine_panel.gd` 四行外，其余 30 行 OK。**不要自己刷快照** |

跑法（已实证）：`SMOKE=1` 必须带，否则 `_smoke` 为假、探针整段不执行。Godot 绝对路径 `D:/SteamLibrary/steamapps/common/Godot Engine/godot.windows.opt.tools.64.exe`，`--headless --quit-after 300`。

---

## 六 变异刀表（8 把，核验侧会独立复现，你先自跑）

| 刀 | 改法 | 预测红 |
|---|---|---|
| 刀一 | `settle_shards` 判定删掉 `and not purified_run` | B04 / B05 / B06 |
| 刀二 | `purified_run = true` 挪到 `Game.reset()` 之前 | C01 / C02 / A02 |
| 刀三 | 把记账挪到 `_shrine_execute()` 通用入口（任何圣所选择都记） | A03（用非净化 offer 构造）+ D03 之外的 C 组 |
| 刀四 | 删掉 `Game.calamity_floors.erase(Game.floor_num)` | **仅 A04**（证明它是这条面的唯一守卫，`erase` 对结算已无影响） |
| 刀五 | `cost_kind` 改成 `"diamonds"`、`cost: 8` | A05 / D01 / D02 + G5 冻结越界 |
| 刀六 | `reset()` 里漏清 `purified_run` | A02 / C01 / C02 |
| 刀七 | 卡面 `desc` 改回旧文案 | E01 |
| 刀八 | 代价行改回「或失效」 | E02 |

🔴 **变异纪律**：替换目标行，不许新增行；注释里**不许写符号字面**（静态门是文本级计数，S27 实测注释含 `_oath_grant()` 会凭空多红）。`replace_all` 前先 `grep -c` 确认目标串全仓出现次数。

---

## 七 两处口径说明（别踩）

1. **设计稿 §2 有两张概率表，分母不同，不要混用**：`37% / 40% / 23%` 那张是「M=10 时恰好 1 层 / ≥2 层 / 0 层灾祸」的**无条件频率**；`62% / 73% / 80% / 90%` 那张是「**给定玩家在第 k 层净化**」的条件概率（白拿 = 除 k 外全无灾祸）。两者都算得通，但别拿 37% 去反驳 73%。
2. **S27 批三验证口径 §16 有一条走查守卫**，靶子是 `game_main.gd` 那句旧注释「若为唯一灾祸层 ×1.5 结算作废」。本批按要求改写该注释后，那条走查项的目标消失——它本来就标为 (d) 走查、无运行时效果，不构成覆盖损失。别为了保它而不改注释。

---

## 八 入册不修（本批不碰）

- R1 深局代价线性上涨（`M=20` 净化 = 20 碎片），主理人已裁定不设上限。
- R2 净化成为唯一恒可支付的卡 → 由本批的面板文案承担，不加资源门槛；视觉强化（标红/加粗）留待用户。
- R4 存读档不含 `calamity_floors` / `purified_run`：B **不新增也不修复**这条不对称；`from_dict` 全仓唯一调用点是 `game_main.gd:1488-1490 _test_save_roundtrip()`，目前无面向玩家的局内读档。独立另册。
- 双 `enemy_speed_mult`（`Game.` vs `Game.main.`）、第 12 层零行为覆盖（**批二处理**）、`barren` + `scarce_ore` 文案 -0%（**批二处理**）——都不在本批范围。

---

## 九 完成定义

四门全过 + 八刀逐刀见红且编号对齐 + 复原后复跑全绿 + 工作树只含本单授权的 4 个 `.gd` 改动与探针块。
报交付时附：commit hash、五门实测数、八刀红表、以及任何偏差的如实记录。**不 commit 文档、不推送。**
