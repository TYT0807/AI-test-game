# Sprint 28 批二 · 验证口径——第 12 层行为覆盖 + 灾祸文案实际值

> 基准 HEAD `2ebdc38`，工作树干净，`scripts/` 34 个 `.gd`，冻结 34/34 OK。
> 本口径由主理人补写（QA 侧 worker 因限流中断，未落盘）。读者：编程侧照此写探针，核验侧照此判 PASS/FAIL。
> **只产出断言规格；不改任何既有断言或期望值。**

---

## 零 跑法与判据（先读，判错会把正确实现判成 FAIL）

```
cd "D:/Create/Game/test-1"
GODOT="D:/SteamLibrary/steamapps/common/Godot Engine/godot.windows.opt.tools.64.exe"
SMOKE=1 SMOKE_CAL_THEME=1 "$GODOT" --headless --quit-after 300 2>&1 | tee /tmp/s28b.log
```

- `SMOKE=1` **必须带**：`_smoke` 为假时 `game_main.gd:250-251` 的探针挂载整段不执行。
- 🔴 **判红口径**：`_ct_assert()`（`game_main.gd:677`）只打印 `measured=/expect=`，**不带 `ok=` 字段**；成败走 `Dev.check()`，而 `Dev.check()` 只在失败时打印 `[ERR] cal_theme: ...`。
  → 本批判红用 `grep -c "\[ERR\]"`。**不许用 `grep "ok=false"`**——那是批二 `SMOKE_OATH_GRANT` 的格式。S27 实测踩过：用错判据得到 0 红，把正确实现判成「变异无效」。
- 本批沿用批三 `_ct_assert()`，编号接在现有 103 条之后，**新声明数 `103 + N`**，`done checked=declared` 自校验必须成立。

---

## 一 债务一：第 12 层的零行为覆盖

### 1.1 现状（实读）

| 位置 | 事实 |
|---|---|
| `scripts/data.gd:491-495` | `theme_for_floor(n)`：`n<4` 返回 `{}`；否则 `key = 4 + ((n-4) % FLOOR_THEMES.size())`；`FLOOR_THEMES` 8 条 key 4..11 |
| `data.gd:103` | key 4 = 往生脉，`rule = "vein"` |
| 回卷 | `n=12` → `4 + (8 % 8) = 4` → **vein**。第 13 层同理回到 key 5 |
| `game_main.gd:581 _apply_calamity()` | 开头快照 `_calamity_theme_rule`，注释已写明：「必须经 `Data.theme_for_floor()` 派生；floor_num 直下标在 12 层拿空字典 → 变体静默失效」 |
| 探针覆盖 | `_ct_floor_advance(...)` 实测调用只在 **3 / 6 / 7 / 9**；③ 段换层构造跑 4→11。层签断言 ⑤7 只覆盖 f4/f7 |
| ⑥6 | 只断言 `Data.theme_for_floor(12)["rule"] == "vein"`，即**只验函数返回值** |

**空洞**：把 `_apply_calamity()` 里的派生改成 `FLOOR_THEMES.get(Game.floor_num, {})`（12 层拿空字典 → rule 变空串 → S27 变体静默失效），⑥6 仍绿。**这是「断言全绿但代码路径从没跑过」的空洞，本批补掉。**

### 1.2 目标错误实现（这一组断言存在的唯一理由）

```gdscript
# 错误实现：绕过派生函数直查表
_calamity_theme_rule = String(Data.FLOOR_THEMES.get(Game.floor_num, {}).get("rule", ""))
```

在 floor 12 上它得到 `""`，正确的 `Data.theme_for_floor(12)` 得到 `"vein"`。下游差异：

| 灾祸 | 正确（vein 变体） | 错误（无 rule → default） |
|---|---|---|
| `frail` | `_frail_ratio() = 0.1`（`game_main.gd:559`） | `0.2` |
| `frenzy` | `Game.calamity_speed_mult = 1.25` | `1.45`（swamp 变体）或 `1.25` default —— 需实读 `:581-624` 确认 default 后再定 expect |

🔴 **编程侧先实读 `_frail_ratio()` 与 `_apply_calamity()` 的 4 个 match 分支**，把上面两行的期望值换成现值；**不要照抄我这里的数字**，我只保证结构、不保证变体表没在 S27 之后被改过。

### 1.3 断言规格（G 组，建议 8 条）

| 编号 | 断言 | measured | expect | 分类 | 抓什么 |
|---|---|---|---|---|---|
| G01 | floor 12 派生返回 rule | `Data.theme_for_floor(12).get("rule","")` | `"vein"` | 前提守卫（**恒过**，⑥6 同型） | 只证明函数没被改；**不构成本批覆盖**，保留作前提 |
| G02 | **floor 12 上 apply 后变体身份** | `_calamity_theme_rule` | `"vein"` | **验效果** | **直查表的错误实现在这里红**（靶心） |
| G03 | floor 12 + `frail`，`_frail_ratio()` | `_calamity_frail_ratio` | vein 的实值（实读） | **验效果** | 同一错误实现的数值面，与 G02 分层 |
| G04 | floor 12 apply 后 `max_hp` 实降 | `old_hp - player.max_hp` | `maxi(1, round(old_hp × vein比例))` | **验效果** | 只改快照不改实际 apply 的错误 |
| G05 | floor 12 clear 后变体身份清空 | `_calamity_theme_rule` | `""` | **验效果** | clear 里「现查 floor 12 主题」的错误（会拿到 vein 而非空串） |
| G06 | floor 12 clear 后通道还原 | `player.max_hp` / `diamond_mult` / `Game.calamity_speed_mult` / `player.mag_cap_mult` | 入口快照逐字 | **验效果** | apply 正确但 clear 漏还原 |
| G07 | floor 13 也回卷到 key 5 | `Data.theme_for_floor(13).get("rule","")` | key 5 的 rule（实读） | 前提守卫（恒过） | 证明回卷是模运算而非 12 特判；**不构成覆盖** |
| G08 | **把 `_apply_calamity()` 里的派生字面替换成直查表**后，G02/G03/G04 必须红 | 变异测试，不算运行期断言 | — | 见 §三 刀一 | 证明 G02 不是装饰 |

🔴 **读数时点（S27 踩过的坑）**：`_ct_floor_advance(12)` 会触发 `_apply_floor_theme()`，它会**无条件**把 `enemy_speed_mult` / `diamond_mult` 回落到 `_mod_*`。所以 G06 里凡是读倍率的，必须在**换层后、主题重建前**读，或先把 `_mod_*` 归一到入口快照再读；**出口从入口快照还原，不许还原成 1.0**（barren/swarm 局约 28.6% 会误红）。

🔴 **现场还原**：G 组收尾必须还原 `Game.floor_num` / `_calamity` / 四通道 / `_calamity_theme_rule` / `_calamity_frail_ratio` 到入口快照，并 `update_floor_sign()`，否则污染后续断言。

🔴 **诚实边界**：本组补的是「floor 12 上 apply + clear 真跑过」。**floor 13 以上仍无行为覆盖**；G07 只验 Data 返回值，标死「前提守卫，不构成覆盖」。

---

## 二 债务二：文案名义值 vs 实际值

### 2.1 现状（实读 `game_main.gd:566-578`）

| 灾祸 | 现值 | 病在哪 |
|---|---|---|
| `frail` | `int(round(_calamity_frail_ratio * 100.0))` | 读的是**名义比例**。但 `_apply_calamity()` 里 `player.max_hp = maxi(2, old_hp - cut)` 会钳制，钳制后 `cut` 重算为实际值（可为 0）。生命上限已到 2 时显示「-10%」而实际没掉 |
| `scarce_ore` | `base = maxf(_calamity_saved_diamond_mult, 0.001)`；`int(round((1.0 - 0.7/base)*100.0))` | `barren` 局 `base = 0.7` → `1 - 1 = 0` → 显示「残响掉落 **-0%**」，观感像 bug |

🔴 **首词是探针锚点**（`虚弱` / `狂乱` / `弹药荒` / `残响枯竭`），历史断言全是 `contains` 首词。**改百分比不许动首词一个字**，否则连带打红大量既有断言。

### 2.2 主理人已定的语义（照此实现，不要另立方向）

文案报**实际削减**，不是名义比例；实际削减为 0 时不许显示「-0%」。本口径定死两处措辞（可微调后半句，但「0 不显示 0%」与首词不可破）：

| 灾祸 | 实际削减 > 0 | 实际削减 == 0 |
|---|---|---|
| `frail` | `虚弱（生命上限 -%d%%）`，`%d` = 实际削减 / 原上限 | `虚弱（生命上限不再削减）` |
| `scarce_ore` | `残响枯竭（残响掉落 -%d%%）`，`%d` = 实际削减比例 | `残响枯竭（残响不再削减）` |

`frenzy` / `scarce_ammo` 的同类名义值问题**不在本批范围**（见 §四）。

### 2.3 断言规格（H 组，建议 7 条）

| 编号 | 断言 | measured | expect | 分类 | 抓什么 |
|---|---|---|---|---|---|
| H01 | frail 常规局文案含实际百分比 | `_calamity_name("frail")` | 含 `-{实际}%` 且含首词「虚弱」 | 验效果 | 仍读名义比例（构造两者不同的局） |
| H02 | frail 钳制局（`max_hp=2`）不显示 -0% | 同上 | 含「不再削减」且不含 `-0%` | **验效果** | 钳制后仍读名义值 |
| H03 | H02 局 `player.max_hp` 确为 2 | `player.max_hp` | `2` | 前提守卫（恒过） | 证明 H02 构造真的到了钳制分支 |
| H04 | scarce_ore 常规局实际百分比 | `_calamity_name("scarce_ore")` | 含 `-30%`（按实读比例） | 验效果 | 分母错 |
| H05 | **`barren` 局 scarce_ore 不显示 -0%** | 同上 | 含「不再削减」且不含 `-0%` | **验效果** | 本批靶心，`base=0.7` 特例 |
| H06 | H05 局 `_calamity_saved_diamond_mult == 0.7` | 该字段 | `0.7` | 前提守卫（恒过） | 证明构造真的在 barren |
| H07 | 四条文案首词逐字保留 | 4 条 `contains` | `["虚弱","狂乱","弹药荒","残响枯竭"]` | 验效果（**跨批回归守卫**） | 改文案时手滑改了首词 |

🔴 H01 / H04 必须**构造名义值与实际值不相等**的局，否则恒过、不算覆盖。H02 / H05 是各自唯一的靶心守门员。

🔴 H03 / H06 是前提守卫， MUST 标注「恒过、不构成覆盖」，不许在交付报告里写成行为断言。

---

## 三 变异刀表（核验侧会独立复现）

| 刀 | 改法 | 预测红 |
|---|---|---|
| 刀一 | `_apply_calamity()` 的派生改成 `Data.FLOOR_THEMES.get(Game.floor_num, {})` | **G02 / G03 / G04**（G01 / G07 必绿——这正是它们「不构成覆盖」的实证） |
| 刀二 | clear 里把 `_calamity_theme_rule = ""` 换成现查 `theme_for_floor(floor_num)` | **仅 G05**；G02/G03/G04 全绿 → 证明位置面与数值面分层 |
| 刀三 | frail 文案改回读 `_calamity_frail_ratio` | H01 / H02 |
| 刀四 | scarce_ore 文案改回原式（`0.7/base`） | H05 |
| 刀五 | 任一文案首词改字（如「虚弱」→「虚弱症」） | H07 + 既有跨批断言 |

🔴 变异必须**替换目标行、不许新增行**；注释里**不许写符号字面**（S27 实测注释含符号会让文本级静态门凭空多红）。

---

## 四 本口径不覆盖什么（诚实清单）

1. **floor 13 以上零行为覆盖**：G07 只验 Data 函数返回值，不验代码路径。要补它是 S29 量级。
2. **`frenzy` / `scarce_ammo` 的名义值问题**：本批只收敛 frail / scarce_ore 两条。`frenzy` 文案读 `Game.calamity_speed_mult - 1.0`，`scarce_ammo` 读 `1.0 - player.mag_cap_mult`，两者理论上同族；是否一起收敛留 S29。
3. **文案措辞的玩家可读性**：本口径只机检「首词保留 + 0 不写 0%」，不验读起来自然。人眼验收由主理人做。
4. **第 12 层的 Boss / 池 / 色调**：本批只覆盖主题 rule 在 apply/clear 路径上的行为，不验 floor 12 的 elite/boss/tint 是否正确回卷。
5. **文案是名义/实际比例的经济影响**：把 frail 改成实际值后，玩家到 2 血时看到的数字变小，但机制没变；本批不评估这是否影响决策，只保证显示与行为一致。

---

## 五 完成定义

新断言全绿 + `[ERR] == 0` + `done checked=declared` + 五把刀逐刀见红且编号对齐 + 复原后复跑全绿 + 既有 103 条批三断言零 churn + 冻结除授权文件外零漂移。

任何标「前提守卫（恒过）」的断言不得在报告里计入「有效覆盖」；分母按总条数报、分子按验效果条数报。
