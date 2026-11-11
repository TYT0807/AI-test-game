# Sprint 21 设计实稿（C · 深渊难度档）

- 角色：design-s16（创意/系统设计，不写 `.gd`）
- 承接：`production/sprint-21/SPR21_规划草案.md`（方向已锁定）
- 实读依据：`meta.gd` / `data.gd` / `game_main.gd` / `slug.gd` / `player.gd` / `menu.gd` / `hud.gd` / `game_state.gd` / `validate.gd`
- 红线纪律：所引锚点以**函数名 / 源码内容**定位，行号仅作阅读辅助（落地前以函数名为准）。

---

## 〇 定位与一句话

只加「难度与进程的关系」，不加任何机制 / 实体 / 资源 / 输入动作。用**纯乘算因子**把「已通关」这件事接成一条长线重刷目标：越深的档位 = 越硬的数值，且零 rng 顺序变化、零指纹重定。

设计落点（自我决定论）：**胜任**——每清一档是 persistent 的 mastery 里程碑；**自主**——在已解锁档位内自选冲哪档；**关联**——矿窟之下还有矿窟，是个人的战绩遗产。

---

## 一 ABYSS_TIERS 难度阶梯

### 1.1 关键裁定：三乘子，非四乘子（避免双重计数红线）

规划草案 §二 列了「hp / damage / speed / 玩家受创」四项，但 §三 自己称「三围」。二者冲突，裁定如下：

- **「敌人 damage」与「玩家受创」是同一物理事件**（敌人打中玩家），不是两个独立旋钮。若同时建 `enemy_dmg_mult` 与 `player_incoming_mult` 并在同一次伤害上各乘一遍，就是**双重计数**——本设计的硬红线。
- 故锁定为 **3 个乘子**：`hp` / `speed` / `dmg`。`dmg` 在**唯一入口** `player.take_damage()`（player.gd:1751）一次性缩放，覆盖接触 / 敌弹 / Boss / AoE 全部来源。

### 1.2 既有可复用挂接点（不新造注入路径）

- 敌人 hp：`slug.gd` setup 已乘 `Game.main.enemy_hp_mult`（slug.gd:86）。
- 敌人 speed：`slug.gd` 已乘 `Game.main.enemy_speed_mult`（slug.gd:90/212/232），走 `FIXED_DT` 积分（E6 合规）。
- 玩家受创：新增 `Game.main.enemy_dmg_mult`，在 `player.take_damage()` 入口缩放。
- ⚠️ 注意 `player.damage_mult`（player.gd:93）是**玩家输出**倍率（子弹 409/509 处使用），**不可复用**——深渊「受创」是入向伤害，需独立全局。

### 1.3 曲线公式与数值草案

- **N = 10**（tier 1..10）。理由：10 档阶梯是清晰的 mastery 墙，有界、不无限膨胀；与「逐档解锁」回环匹配。
- 线性-in-tier（每升一档清晰变难但不过陡）：
  - `hp_mult(t)   = 1 + 0.10·t`
  - `speed_mult(t)= 1 + 0.05·t`
  - `dmg_mult(t)  = 1 + 0.07·t`
- 每档增量：hp +10% / speed +5% / dmg +7%——可感知的台阶，非悬崖。
- tier 10 总倍率 = hp×2.0 / speed×1.5 / dmg×1.7，构成有界「墙」。
- **严格单调递增**（validate 门强制要求，见 §六 6.7）。

| tier | hp   | speed | dmg  |
|------|------|-------|------|
| 1    | 1.10 | 1.05  | 1.07 |
| 2    | 1.20 | 1.10  | 1.14 |
| 3    | 1.30 | 1.15  | 1.21 |
| 4    | 1.40 | 1.20  | 1.28 |
| 5    | 1.50 | 1.25  | 1.35 |
| 6    | 1.60 | 1.30  | 1.42 |
| 7    | 1.70 | 1.35  | 1.49 |
| 8    | 1.80 | 1.40  | 1.56 |
| 9    | 1.90 | 1.45  | 1.63 |
| 10   | 2.00 | 1.50  | 1.70 |

- **tier 0 = 关闭**（普通模式）：三乘子全 1.0，无 HUD 指示，菜单不激活档位选择。
- 设计注记：深渊是**扁平全局旋钮**，刻意独立于既有「按层 ×(1+0.55·floor)」「按波 ×(1+0.12·wave)」的缩放，故叠加的是一层「恒定压力」，而非把既有曲线再复利放大。

---

## 二 「最高通关 tier」记录回环

### 2.1 解锁与记录落点（平行只读，不碰 STATS_KEYS / UNLOCKS）

- **解锁**：首次击败第三 Boss（任意模式）→ `Game.meta["abyss_unlocked"] = true`。
- **记录**：当 `abyss_tier > 0`（处于深渊模式）时，每次击败第三 Boss →
  `Game.meta["abyss_best_tier"] = maxi(int(Game.meta.get("abyss_best_tier", 0)), abyss_tier)`。
- **触发点**：`_room_cleared()` 的 `"boss"` 分支中，判定 `_is_third_floor(Game.floor_num)` 为真时（game_main.gd:1090 / 1004）。
- **落盘**：两字段是 `Game.meta` 字典（game_state.gd:78）的**平行键**，读档时 `_read_meta()` 给安全默认、写档时 `save_meta()`（game_state.gd:880 遍历所有键）自动持久化。**不进 `Meta.STATS_KEYS`**（否则被白名单静默丢弃），**不进 `meta.gd` 的 `UNLOCKS`**（不改冻结表）——完全平行于 `best_floor` / `total_kills` 既有写法（game_state.gd:981-985）。

### 2.2 选择门控（staircase，推荐）

- 菜单提供档位 `0`（关）.. `min(ABYSS_MAX_TIER, abyss_best_tier + 1)`。
- 默认 = 已解锁最高档（`best_tier + 1`；解锁后首档为 1；未解锁为 0）。
- 理由：阶梯保证「下一档永远刚好超出当前手艺」，**防劝退式跳档**（胜任感），同时在已解锁范围内保留自主。
- 变体（待主理人拍板）：亦可放开为 `1..MAX` 全开放自选——更自主，但新手可能一头撞 t10 翻车。本文推荐 staircase。

### 2.3 回环动机

清掉 t1 → 解锁 t2 选择 → 清掉 t2 → 解锁 t3……「最高通关 tier」就是这条长线重刷的刻度盘。普通模式通关只负责点亮深渊入口（unlock），真正往上爬的是 abyss 档位。

---

## 三 UI 形态

### 3.1 主菜单难度选项（menu.gd 右栏）

- 在 `right` 面板「每日挑战」之后（menu.gd:150 附近 `_add_main_button`）加「深渊档」按钮。
- 未解锁（`abyss_unlocked` 假）：按钮显示「深渊档 · 通关解锁」并 `disabled`，无档位选择。
- 已解锁：点击进入 `show_page("abyss", "main")`，列出 `0..min(MAX, best+1)` 各档为可选按钮（复用既有 page 框架）；按钮文案随 `Game.main.abyss_tier` 变化：「深渊档 · 关」/「深渊档 · t3」。

### 3.2 局内 HUD 指示（hud.gd）

- 新增**独立** `_abyss_tier_label`（Label），**不用 `banner()`**。
- 仅当 `abyss_tier > 0` 时显示「深渊 t3」，否则隐藏。与 `_floor_sign_label` / `_floor_sign_sub_label`（hud.gd:496-511）同容器但独立，避免耦合。

---

## 四 红线自检（逐条对账）

| 红线 | 结论 | 机制 / 依据 |
|------|------|------|
| 不新增机制/实体/资源/输入动作 | ✅ | 仅 3 乘子 + 2 meta 平行键 + 1 菜单按钮 + 1 HUD 标签 + 1 全局 |
| `ACTION_DEFS` 18 条不动 | ✅ | 无新动作 |
| `CODEX_KINDS` 六类不动 | ✅ | 深渊是 meta 层，非图鉴 kind（S19 已落 `shrine` 第六类，本批不加第七类） |
| 不碰 `FLAVOR` 覆盖门 | ✅ | 文案全是**字面 UI 字符串**，零 `FLAVOR` 写入；`validate.gd:249-259` 的 FLAVOR 覆盖门（6 前缀 `fexpect`）若存在第 7 前缀即报错，本设计零触碰因而安全 |
| 不碰 `FLOOR_THEMES`（8→12 永不接） | ✅ | 未引用 |
| 不碰 `CODEX_BOONS` 第五档 | ✅ | 未引用 |
| E1 零新增 rng / 顺序变化 | ✅ | 乘子在 `start_run` 按所选 tier **确定性**乘定；无 `Game.rng`/`fx_rng` 调用；指纹逐字一致（G2） |
| E6 走 `FIXED_DT` | ✅ | speed 乘子复用 `enemy_speed_mult` 路径（FIXED_DT 积分）；无新计时 / 无 raw `delta` |
| 平行只读 meta | ✅ | `abyss_unlocked`/`abyss_best_tier` 为 meta 字典平行键，不进 `STATS_KEYS`（game_state.gd:981-985 同范） |
| 登记三件套 | ✅ | ①写入（ABYSS_TIERS+meta 键+全局）②注册/分母/显示名（菜单按钮+HUD 标签为可见面、validate 门为一致性注册；深渊非可发现集故无 discoverable 分母）③可见效果断言（SMOKE_ABYSS 验数值） |

---

## 五 玩家向文案（废弃矿窟实用主义）

基调：矿工手记口吻、克制、功能性、不煽情、不给推荐语（防主导策略）。**全部为字面 UI 字符串，非 `FLAVOR` 条目**：

| 位置 | 文案 |
|------|------|
| 菜单按钮（未解锁） | `深渊档 · 通关解锁` |
| 菜单按钮（关） | `深渊档 · 关` |
| 菜单按钮（已选 t3） | `深渊档 · t3` |
| 档位页标题 | `深渊档` |
| 档位页副标 | `深渊档 · 逐档解锁` |
| 局内 HUD | `深渊 t3` |
| 菜单最佳行（可选，仿「今日最佳」） | `深渊最高 · t3` |
| 首次解锁 toast | `深渊档已解锁` |

注：均为**状态标签**而非攻略，不含「建议 / 优先 / 划算」等评价词。

---

## 六 eng-handoff 实施契约（照做即可）

### 6.1 `data.gd` —— 常量表
```gdscript
## Sprint 21 C · 深渊难度档：纯乘算因子阶梯（tier → 三围乘子）。
## 仅缩放既有敌人属性，零新增 rng / 零机制 / 零实体。tier 0 = 关闭（全 1.0）。
## 自检：validate._check_abyss 校验单调 / 乘子>0 / 无 NaN / 尺寸==ABYSS_MAX_TIER。
const ABYSS_MAX_TIER := 10
const ABYSS_TIERS := {
    1:  {"hp": 1.10, "speed": 1.05, "dmg": 1.07},
    2:  {"hp": 1.20, "speed": 1.10, "dmg": 1.14},
    3:  {"hp": 1.30, "speed": 1.15, "dmg": 1.21},
    4:  {"hp": 1.40, "speed": 1.20, "dmg": 1.28},
    5:  {"hp": 1.50, "speed": 1.25, "dmg": 1.35},
    6:  {"hp": 1.60, "speed": 1.30, "dmg": 1.42},
    7:  {"hp": 1.70, "speed": 1.35, "dmg": 1.49},
    8:  {"hp": 1.80, "speed": 1.40, "dmg": 1.56},
    9:  {"hp": 1.90, "speed": 1.45, "dmg": 1.63},
    10: {"hp": 2.00, "speed": 1.50, "dmg": 1.70},
}
```

### 6.2 `game_main.gd`
- 新增全局：`var enemy_dmg_mult := 1.0`（与 `enemy_hp_mult`/`enemy_speed_mult` 同处，~line 92-93）。
- 新增运行配置：`var abyss_tier := 0`（菜单在 `start_run` 前赋值；`start_run` 读取）。
- `start_run()` 内，`_roll_modifier()`（~line 362）之后、敌人生成前：
  ```gdscript
  if abyss_tier > 0 and Data.ABYSS_TIERS.has(abyss_tier):
      var at: Dictionary = Data.ABYSS_TIERS[abyss_tier]
      enemy_hp_mult   *= float(at["hp"])
      enemy_speed_mult *= float(at["speed"])
      enemy_dmg_mult   = float(at["dmg"])
  ```
  （在 modifier 倍率之上**再乘**，叠加意图明确；`enemy_hp_mult`/`enemy_speed_mult` 在 `_roll_modifier` 内已复位为 1.0，见 line 486-487。）
- `_room_cleared()` 的 `"boss"` 分支、且 `_is_third_floor(Game.floor_num)` 为真时：
  ```gdscript
  Game.meta["abyss_unlocked"] = true
  if abyss_tier > 0:
      Game.meta["abyss_best_tier"] = maxi(int(Game.meta.get("abyss_best_tier", 0)), abyss_tier)
  ```

### 6.3 `player.gd`
- `take_damage(dmg, from_pos, _from_node)`（line 1751）函数入口、**在 `dead/_invuln/_immortal` 守卫（1752-1755）之后、`sigil_ward` 分支（1756-1760）之前**插入：
  ```gdscript
  dmg = int(round(float(dmg) * Game.main.enemy_dmg_mult))
  ```
  - 唯一入口，覆盖接触/敌弹/Boss/AoE；护盾（1762）仍在缩放后正常抵挡。
  - ⚠️ **不要改动** `sigil_ward` 分支既有逻辑（含其早返回）——属范围外既有行为，本改动不触碰。

### 6.4 `game_state.gd`（meta 平行字段）
- `_read_meta()` 内、约 line 790 附近追加：
  ```gdscript
  meta["abyss_unlocked"]  = bool(cfg.get_value("meta", "abyss_unlocked", false))
  meta["abyss_best_tier"] = maxi(0, int(cfg.get_value("meta", "abyss_best_tier", 0)))
  ```
  - **不要**把这两键加入 line 753-754 的 `missing` 告警列表（避免旧档误告警）。
  - `save_meta()`（line 880 遍历所有键）无需改动，自动持久化。

### 6.5 `menu.gd`
- 右栏「每日挑战」之后（~line 150）加「深渊档」按钮：未解锁则 `disabled` 且文案「深渊档 · 通关解锁」；已解锁则进入 `show_page("abyss", "main")`，标签随 `Game.main.abyss_tier` 变化。
- 新增 `abyss` 页构造（仿 sigils/codex 页）：列出 `0..min(ABYSS_MAX_TIER, best+1)`，选中写 `Game.main.abyss_tier`，返回主菜单。

### 6.6 `hud.gd`
- 新增 `_abyss_tier_label`（Label），提供 `set_abyss_tier(t: int)`：`t > 0` 时显示「深渊 t%d」并 `visible=true`，否则 `visible=false`。由 `start_run` / HUD 刷新调用，**不用 `banner()`**。

### 6.7 `validate.gd`（启动期门）
- `run()` 内新增 `_check_abyss()`：
  - `Data.ABYSS_TIERS` 为 Dictionary，键数 == `ABYSS_MAX_TIER` 且为 1..N 连续整数。
  - 每档 `hp`/`speed`/`dmg` 均为有限浮点且 > 0，非 NaN/Inf。
  - 跨档对每个乘子**单调非减**（高阶永不难于低阶）。
  - `ABYSS_MAX_TIER == ABYSS_TIERS.size()`。

### 6.8 `SMOKE_ABYSS` 探针（G4）
- 正：设 `abyss_tier = t`，生成敌人，断言实际 hp == baseline_hp × `ABYSS_TIERS[t].hp`；断言玩家受创 == baseline_dmg × `ABYSS_TIERS[t].dmg`（**验数值**）。
- 负：`abyss_tier = 0` → 与基线逐字一致（前提守卫型，标注恒过）。
- 断言分类如实标注（验效果型 / 前提守卫型恒过）。

---

## 七 待主理人拍板项

1. **档位选择门控**：staircase（推荐，`best+1` 上限）vs 全开放 `1..MAX`。
2. **解锁 toast**：是否顺带补一条 `MILESTONES` 条目（允许，非 `FLAVOR`、非 codex kind）；或仅用字面 toast。
3. **HUD 标签位置/样式**：放角落独立标签即可，具体坐标由 eng 按现有 HUD 布局落。
4. **ABYSS_MAX_TIER = 10** 与每档 k 值（hp 0.10 / speed 0.05 / dmg 0.07）是否采纳，或需更陡/更缓。
