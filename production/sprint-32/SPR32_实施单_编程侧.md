# Sprint 32 · 实施单（编程侧）——圣所随地形改写

> 本文是 S32 **唯一权威**。上游：`production/sprint-32/SPR32_设计实稿_圣所随地形改写.md`（148 行，四条已裁定）+ `SPR32_验证口径.md`（171 行，23 编号 / 17 验效果型 / 11 刀）。
> 基准 HEAD `cc3afd0`，领先 origin 5 笔，树干净，`scripts/` 34 个 `.gd`，冻结 34/34。
> **只改 `.gd`**；文档由主理人写；**推送不归你**；**不许自刷冻结快照**。

---

## 一 一句话

`_shrine_offers_for()` 现在对池做**均匀 3 子集**抽取，每张卡命中率恒 `3/N`，与本层地形无关——岩浆层和冰面层卖的东西分布一模一样。本批让圣所按本层主题改写**卖哪三张**：每主题给 1–2 张「更常」+ 至多 1 张「更少」。**不改价格、不改效果、不改门槛、不改派生 key、不动 `data.gd` 一个字节。**

---

## 二 硬红线

1. 🔴 **`scripts/data.gd` 一个字节都不许动。** 它在冻结清单里（`SPR21-FROZEN.md5:9`）。所以偏向**不走给 `FLOOR_THEMES` 加字段**，走 `match` 字面量落在 `game_main.gd`（清单 `:15`，本批反正要改，刷一行是既定动作）。
2. 🔴 **`stable_hash` 的 key 表达式逐字不动**：`"%d_%d_%d" % [Game.run_seed, Game.floor_num, coord.x * 1000 + coord.y]`。三个 hash 串 `"%s#0"/"%s#1"/"%s#2"` 与现行 `"%s#%d" % [key, i]` **逐字相同**，变的只有被取模的池。
3. 🔴 **零新增 `Game.rng` 消费**。三段全由 `stable_hash` 派生，不许引入任何 `randi`。
4. 🔴 **不改** `_shrine_execute()` / `_shrine_affordable()` / `_shrine_suffix_pick()` / `purify` 的过滤门槛（`:3291-3292`）/ `min_floor` 过滤（`:3289`）/ 空池护栏（`:3294-3295` 的 `return []`）。
5. 🔴 **不许读 `_theme_rule` live**。它只在 `_apply_floor_theme()` 与读档还原处赋值，而探针直接改 `Game.floor_num`、不同步 live → 读 live 会让探针与真实楼层不自洽（刀十一专门打这个）。
6. 🔴 **不许为可测性给 `_shrine_offers_for` 加参数**。`|pool|=3` 经 floor/calamity 不可达（实测最小 5），恒可解只能作前提守卫。

---

## 三 生产改动（仅 `scripts/game_main.gd`）

### 3.1 新增 `_shrine_theme_pref()`（放 `_shrine_entry()` 之前）

```gdscript
## S32：本层主题的圣所偏好 —— 返回 [[更常…], [更少…]]（id 列表；「更少」允许为空）
## 🔴 载体必须经 Data.theme_for_floor() 派生，禁读 _theme_rule live（探针只改 floor_num、不同步 live）
## 🔴 方向来自主题自己的杠杆（成本相对性 / 伤害的时间形状 / 兑现前提），不是「难就卖强的」
func _shrine_theme_pref() -> Array:
	match String(Data.theme_for_floor(Game.floor_num).get("rule", "")):
		"vein":     return [["ore_upgrade", "ward_boon"], ["greed_pact"]]
		"toxic":    return [["heal"], ["ward_boon"]]
		"pressure": return [["wind_dance"], ["power_surge"]]
		"silent":   return [["purify"], []]
		"magma":    return [["power_surge"], ["heal"]]
		"ice":      return [["ward_boon"], ["wind_dance"]]
		"swamp":    return [["wind_dance"], ["blood_relic"]]
		"vines":    return [["heal"], []]
	return [[], []]
```

### 3.2 `_shrine_offers_for()` 改造

`pool` 过滤（`:3287-3293`）、空池护栏（`:3294-3295`）、`key`（`:3296`）**逐字不动**。在 `key` 之后插入：

```gdscript
	var td: Array = _shrine_theme_pref()
	var pr: Array = []
	for o in pool:
		if td[0].has(String(o["id"])):
			pr.append(o)
	if pr.is_empty():
		# 无偏好（1–3 层 / 偏好被门槛滤掉 / silent 无灾祸）→ 逐字走现行三段抽取
		<把现行 :3299-3304 的 for 循环逐字搬进来，不改一个字符>
	else:
		var dn: Array = td[1]
		var p0: Dictionary = pr[Game.stable_hash("%s#0" % key) % pr.size()]
		var c1: Array = []
		for o in pool:
			if String(o["id"]) != String(p0["id"]) and not dn.has(String(o["id"])):
				c1.append(o)
		var p1: Dictionary = c1[Game.stable_hash("%s#1" % key) % c1.size()]
		var c2: Array = []
		for o in pool:
			if String(o["id"]) != String(p0["id"]) and String(o["id"]) != String(p1["id"]):
				c2.append(o)
		var p2: Dictionary = c2[Game.stable_hash("%s#2" % key) % c2.size()]
		return [p0, p1, p2]
```

要点：
- **候选序 = `pool` 原始声明序**（`SHRINE_OFFERS` 的键序，经 `:3289/:3291-3292` 过滤后）。这是**硬前置**，不是实现自由——顺序不同则分布不变但落卡变，D4 会红。若你出于任何理由换了顺序，**报主理人裁定，不要自行判 FAIL**。
- `p0` 取自 `pr`（偏好卡在池内的子集），`p1`/`p2` 取自 `pool` 保序过滤后的子集。
- `dn` 只影响 `c1`；`c2` 只排除 `p0`/`p1`，**不排除 `dn`** ——「更少」靠「不进第二槽」获得结构性压低，不是永不出现（实测约 0.11–0.13 vs 中性 0.25–0.31）。
- `pref` 与 `down` 在八主题下**互不相交**，所以 `c1` 不会把 `p0` 一起排掉。

---

## 四 权威偏向表（照抄，不要自行调整）

| rule（首现层） | 更常 | 更少 |
|---|---|---|
| `vein`（4） | `ore_upgrade`、`ward_boon` | `greed_pact` |
| `toxic`（5） | `heal` | `ward_boon` |
| `pressure`（6） | `wind_dance` | `power_surge` |
| `silent`（7） | `purify` | —（空，刻意） |
| `magma`（8） | `power_surge` | `heal` |
| `ice`（9） | `ward_boon` | `wind_dance` |
| `swamp`（10） | `wind_dance` | `blood_relic` |
| `vines`（11） | `heal` | —（空，刻意） |

---

## 五 探针块（落 `game_main.gd`，23 编号）

- **前缀 `[SMOKE-S32-SHRINE]`**，计数 `_s32_checked`，`const _S32_DECLARED := 23`。
- 🔴 **严禁任何以 `[SMOKE-SHRINE` 起头的打印**——`player.gd:864` 已有 `[SMOKE-SHRINE] det`，新前缀若是它的严格超集，松散 churn diff 会在正确实现上多收行＝**假 churn**（S31 刚踩过）。
- **双门同布尔**：一个 `ok: bool` 同时驱动 `print("… ok=%s")` 与 `Dev.check(ok, "s32_shrine", msg)`。**不许两门各算一遍**。判红：`ok=false` 与 `[ERR]` 必须同时出现。
- 报文：`[SMOKE-S32-SHRINE] #NN <名> measured=<…> expect=<…> ok=<bool>`；收尾 `done checked=%d declared=%d`。
- 统计行（`rate=` / `slot0=` / `down@slot1=`）**恒打印、不判红**；判红只认编号行与 `[ERR]`。
- 造局：`Game.floor_num` 与 `_calamity` 直改，**每条收尾还原**（层号回真实值、`_calamity` 回 `""`），否则污染同帧后续探针。
- 网格 `x,y ∈ [-20,20]` 共 1681 点（`coord.x*1000+coord.y` 唯一，`|y|≪1000`）。
- 挂载点与 `_test_purify_cost()` 同区（`_ready` 内 `:256` 附近），env 开关 `SMOKE_S32_SHRINE`。

**断言编号与分类照口径 §二 逐条实现，不自创、不合并、不少写。** 23 = S1–S5（5）+ M1–M9（9）+ D1–D4（4）+ P1–P5（5）。其中：
- **P2/P3/P4/P5 是门外回归/走查项**，不在探针块内 = 不需要写代码，只在你交付时报实测。探针块内实际写 **19 条**（S1–S5、M1–M9、D1–D4、P1）。
- `M8` 与 `D3` 需要**探针内基线复算**：用现行三段抽取在同 key 上现算一遍再比对（不许写死串后又拿它自己比）。

---

## 六 门（G1–G7，见口径 §五）

| 门 | 判据 |
|---|---|
| G1 新探针 | `[ERR]`=0、`ok=false`=0、`done checked=19 declared=19`（口径写 23 是把门外 4 条计入分母；**探针块内 19**，此处以本单为准） |
| G2 既有圣所 | `SMOKE_SHRINE=1`：`[ERR]`=0、`[SMOKE-SHRINE]` 恰 4 行。**允许** `det offers=` 与 `floor=… offers=` 两行文本变（f=5 起首槽为偏好卡），`chose=` 行若变须逐条说明 |
| G3 净化代价 | `SMOKE_PURIFY_COST=1`：`[SMOKE-PURIFY-COST] #` 恰 **24** 行、`[ERR]`=0 |
| G4 誓约 | `SMOKE_OATH_GRANT=1`：`[SMOKE-OATH-GRANT]` 恰 **60** 行、`[ERR]`=0 |
| G5 E1 | `SMOKE_META_FINGERPRINT=1`（**不是 `SMOKE_META`**），seed 12345/777/42，三行 `[SMOKE-META] fingerprint` 逐字等于口径 §5.4 |
| G6 validate | `34/34 通过` + `problems=0` + `[ERR]`=0 |
| G7 冻结 | `data.gd` 必须 **OK**；`game_main.gd` FAILED 属预期；OK 计数 **33**。**不自刷** |

🔴 每条引擎命令首段必带 `SMOKE=1`。`SMOKE_SAVE` 类挂 `_smoke_frame==3000`，若回归要跑必须 `--quit-after 3200`（300 是假绿）。

---

## 七 变异刀（11 把，口径 §三/§四）

逐刀：替换目标行、**不新增行**；变异时**注释里不写符号字面**（文本级静态门会凭空多红）；每刀跑完 `cp` 复原并 `md5sum` 复验回到原值。

| 刀 | 改法 | 预测红 |
|---|---|---|
| 一 | `_shrine_theme_pref()` 八个分支全返回 `[[], []]` | S1 S2 S3 S4 M1 M2 M4 M5 M6 M7 M8 M9 D4 |
| 二 | `dn` 恒为空（`c1` 不排除 down） | S2 S3 S4 M2 M6 |
| 三 | 两个返回值互换（pref↔down） | S1 S2 S3 S4 M1 M2 M4 M6 D4 |
| 四 | 三段退回 `[pool[0],pool[1],pool[2]]` | S2 S3 S4 M1 M4 M6 M9 D4（**S1 仍绿**） |
| 五 | 排除落 `c2` 而非 `c1` | **M2 独占**（统计面全绿） |
| 六 | 案 A 加权重复槽位（pref×3/中性×2/down×1） | M3 M1 S1 |
| 七 | `p0` 改 `pref[Game.rng.randi_range(...)]` | D1 D2 |
| 八 | `"%s#0"` → `"%s#9"` | **D4 独占**（统计与机制全绿） |
| 九 | 删 `pr.is_empty()` 分支 | D3 M8 |
| 十 | 把 offer id 追加进 `_smoke_fingerprint`（`:347`） | P3 |
| 十一 | `_shrine_theme_pref()` 改读 `_theme_rule` live | S1 S2 S3 S4 M1 M4 M6 M7 M9 |

🔴 **按造局算 measured、不按断言名推刀表**（S29 按名字推错三把）。**刀四、刀五、刀八都只有机制/公式面能抓**——只跑统计的核验会得 0 红、把正确实现判成变异无效。

---

## 八 已裁定事项（别重开）

1. **首槽 100% 保留。** 可用性 ≠ 获得性：`heal` 要 `score -60`、`wind_dance` 要 `score -80`、`power_surge` 要 `max_hp -1`、`ward_boon` 要残响 -5。100% 让地形可读，代价让取舍活着。
   **未来唯一调节钮**：若实机判定过强，只许把 `pref` 放宽为「偏好卡 ∪ 1 张中性卡」（1.0→0.5），机制一行不改。**禁止第二套权重规则**（那就是案 A 的死法）。
2. **`silent` / `vines` 的 `down` 刻意为空**，不是漏写。静默层关掉小地图后玩家靠**走**找出口、藤蔓层绕 `solid` 让绝对路程更长——移速在这两层兑现渠道变多，推不出「更少」。**`down` 为空时跳过第二槽的结构断言，不许为凑断言给它编一个 down。**
3. **`pressure` 第 6 层只有上行**：`power_surge` `min_floor 7`，首轮 `down` 为空集，第 14 层起才双向。刻意保留，不补齐。
4. **`silent` 无灾祸整层无偏向**：`purify` 只在 `_calamity != ""` 入池。按「等于现行基线」验，**不算缺陷**。
5. **中性卡命中率天然离散，这是已知性质、不是 bug。** 实测 N=8 时中性卡从 `relic_suffix 0.1648` 到 `greed_pact 0.4182`（公平值约 0.306），N=9 从 0.2356 到 0.2921。原因是三段池用单次取模、`#1/#2` 两次派生同源相关；主理人已试过「全池索引 + 探查」替代变体，**结果更差**（`relic_suffix` 涨到 0.624，探查质量全堆在 `heal` 的声明序邻居上），故**维持三段池**。expect 一律取口径 §四 实测值/区间，**不许改成理论 `1/N` 或 `3/N`**。
6. **`|pool|=3` 不可达**（实测最小 5）→ 只作前提守卫 P1，**不许给函数加 pool 参数**。
7. 不做 UI（不加「本层倾向」提示/高亮），不改 `FLAVOR` 的 `shrine/<id>` 灰字。

---

## 九 完成定义

六门全过 + 11 刀逐刀见红且红集 ⊇ 口径 §四 + 复原后复跑全绿 + 工作树只含 `game_main.gd` 一处生产改动与新探针块。
报交付附：commit hash、七门实测数、11 刀红表、**各靶 17 条验效果型的 `measured=` 原样行**、任何偏差如实记录。**不 commit 文档、不推送、不自刷冻结。**
