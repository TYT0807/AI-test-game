# Sprint 31 · 实施单（编程侧）——灾祸显示口径收敛

> 本文是 S31 **唯一权威**。上游：`production/sprint-31/SPR31_设计实稿_灾祸显示口径收敛.md`（145 行，三项已拍板）+ `production/sprint-31/SPR31_验证口径.md`（156 行，16 断言 / 7 刀）。
> 基准 HEAD `829d1fb`，本地=origin 0/0，树干净，34 个 `.gd`，冻结 `production/sprint-21/SPR21-FROZEN.md5` 34/34 OK。
> **只改 `.gd`**；文档由主理人写；**推送不归你**。

---

## 一 一句话

灾祸文案的 `frenzy` / `scarce_ammo` 两支正在读 **live 值**——施加瞬间数字对，但换层后 `update_floor_sign()` 走层签常驻显示时 live 已漂移，文案说谎。本批给两支各加一个**施加时快照字段**，文案只读快照。`scarce_ore` 的公式与 -53% 口径**一字不动**。

---

## 二 硬红线

1. 🔴 **族名首词逐字不动**：`虚弱` / `狂乱` / `弹药荒` / `残响枯竭`。历史断言全是 `contains` 首词锚点，改一个字打红一片。
2. 🔴 **`scarce_ore` 一支完全不动**：公式 `1.0 - 0.7/base` 保留、压力层 -53% 保留。主理人 D2/D3 已拍——那是合法主题杠杆的真实结果，不是缺陷。既有 ⑦ore 断言（`:1179`）写死 `-53%`，不许改期望。
3. 🔴 **不改压力层 `maxf`**：`_apply_floor_theme()` `:1812-1814` 的 `enemy_speed_mult=maxf(...,1.3)` / `diamond_mult=maxf(...,1.5)` 是合法主题杠杆，本批只修文案取值来源。
4. 🔴 **零新增 `Game.rng` 消费**；E1 指纹只打 rooms/kinds，纯显示改动零重定。
5. 🔴 **不动 `Data.FLOOR_THEMES` / `SHRINE_OFFERS` / `CODEX_BOONS` / `ACTION_DEFS` / 冻结机制字段**。
6. 冻结清单除 `game_main.gd` 外零漂移；**不自刷快照**（核验侧收官统一刷）。

---

## 三 生产代码改动（仅 `scripts/game_main.gd`，约 12 行）

### 3.1 新增两个字段（紧邻 `:124` 的 `_calamity_frail_ratio`）

```gdscript
var _calamity_speed_mult_applied := 1.0   # S31：frenzy 施加时实际倍率（文案只读快照，不读 live）
var _calamity_ammo_mult_applied := 1.0    # S31：scarce_ammo 施加时实际弹匣系数（同上）
```

### 3.2 施加点写快照（`_apply_calamity()` 内，各分支 match 赋值之后）

- `"frenzy"` 支：在该分支的三个 `Game.calamity_speed_mult = ...` 赋值**之后**（match 结束前）加 `_calamity_speed_mult_applied = Game.calamity_speed_mult`
- `"scarce_ammo"` 支：在 `player.mag_cap_mult = ...` 赋值**之后**、`player.mag_changed.emit(...)` **之前或之后均可**加 `_calamity_ammo_mult_applied = player.mag_cap_mult`

🔴 必须存**写进效果通道的那个数**，不要另算一遍映射——两处映射抄两份迟早分叉（这是否掉 A′ 方案的理由）。

### 3.3 clear 条件块同处复位（`_clear_calamity_effects()` 的 `if _calamity != "":` 块）

在现有四行复位（`_calamity_frail_cut` / `_calamity_saved_diamond_mult` / `_calamity_saved_mag_cap_mult` / `_calamity_theme_rule` / `_calamity_frail_ratio`）之后加：

```gdscript
		_calamity_speed_mult_applied = 1.0
		_calamity_ammo_mult_applied = 1.0
```

🔴 **不延后到清 id 时复位**。主理人已裁定：实读 `:1061-1063` 真实顺序是 clear → `_calamity=""` → `update_floor_sign()`，clear 与清 id 之间无读文案窗口；灾祸结束、快照即失效是正确语义。设计稿 §8.3 那条「暂不清 id 走 clear」的构造**已撤销、生产不可达**，不照它实现。

### 3.4 `_calamity_name()` 改读快照

`"frenzy"` 支改成：

```gdscript
		"frenzy":
			if _calamity_speed_mult_applied <= 1.0:
				return "狂乱（敌人不再加速）"
			return "狂乱（敌人加速 %d%%）" % int(round((_calamity_speed_mult_applied - 1.0) * 100.0))
```

`"scarce_ammo"` 支改成：

```gdscript
		"scarce_ammo":
			if _calamity_ammo_mult_applied >= 1.0:
				return "弹药荒（弹匣不再削减）"
			return "弹药荒（弹匣 -%d%%）" % int(round((1.0 - _calamity_ammo_mult_applied) * 100.0))
```

🔴 `frail` / `scarce_ore` 两支**一字不动**；`frenzy` 用「不再加速」不是「不再增量」（同动词否定，读起来像同一条文案的两个分支）。

---

## 四 验证门（见 `SPR31_验证口径.md` 全文）

| 门 | 期望 |
|---|---|
| G1 validate | 34/34、`problems=0`、`[ERR]`=0 |
| G2 新探针 | 按口径 declared（16 条含 A2t）；**有效覆盖 8 条**（F2/A2/A2t/O1/O2/O3/O4/W1），其余 8 条标恒过/走查不计覆盖 |
| G3 零 churn | 首词 H07 + ⑦四条 + H01/H02/H04/H05 全绿；既有 117 条 CAL-THEME 断言逐字不变（数字归一化后 diff 空） |
| G4 E1 | seed 12345/777/42 指纹逐字一致；零 rng |
| G5 回归 | 八探针含 SAVE **3200 帧**（挂 3000 帧，用 300 是假绿） |
| G6 冻结 | 除 `game_main.gd` 外 33 行 OK，**不自刷** |

🔴 **判红格式**：口径的探针是批二式（带 `ok=`）→ 看 `ok=false` + `[ERR]` 双门；若误用批三式 `_ct_assert()`（无 `ok=`），**必须改判 `[ERR]`**，用 `ok=false` 会得 0 红、把正确实现判成变异无效。

🔴 **假绿陷阱**：施加瞬间（`:554-555` toast/banner）live == 施加值，**现行错实现也绿**。断言必须在「施加后制造 live 漂移」之后取 measured——frenzy 手工改 `Game.calamity_speed_mult`，ammo 走 toxic tick `0.5→0.4→0.3` 或手工改 `player.mag_cap_mult`。只在施加瞬间验 = 没验。

---

## 五 变异刀（7 把，口径 §五完整表）

| 刀 | 改法 | 预测红 |
|---|---|---|
| 一 | frenzy 文案改回读 live | F2 / A2 / A2t |
| 二 | ammo 文案改回读 live | A2 / A2t |
| 三 | 删 0 分支 | F0 / A0（合成态；自然不可达，别当漏网） |
| 四 | ore 分母改 live | O1 / O2（**连带**；O3/O4 仍绿，别误判） |
| 五 | 基准写死 1.25/0.5 | 压力局全绿，只 O3/O4 红 |
| 六 | 改族名首词 | H07 + 既有断言 |
| 七 | base 改 `_mod_diamond_mult` | 压力局 O1/O2 红 -30%，正常局绿 |

🔴 按造局算 measured、不按断言名推刀表（S29 实测按名字推错三把刀）。替换目标行不新增行；注释不写符号字面。

---

## 六 完成定义

六门全过 + 七刀逐刀见红且编号对齐 + 复原后复跑全绿 + 工作树只含 `game_main.gd` 一处生产改动与新探针块。
报交付时附：commit hash、六门实测数、七刀红表、**施加后漂移构造的实测 measured**、任何偏差如实记录。**不 commit 文档、不推送。**

### 已裁定事项（别重开）

- 压力层 -53% 保留，不是缺陷（我原任务书写的 47% 是剩余比、是错的，已纠正）。
- `scarce_ore` 公式不顺手收口为 `cut = base - minf(base,0.7)`——那改 `base<0.7` 边界语义，另一件事。
- 设计稿 §8.3「暂不清 id 走 clear」已撤销、生产不可达，不照它实现。
