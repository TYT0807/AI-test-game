# Sprint 29 · 实施单（编程侧）——发现度改写深渊起点

> 本文是 S29 **唯一权威**。上游：`production/sprint-29/SPR29_方向评估.md`（84 行）+ `production/sprint-29/SPR29_设计实稿_发现度改写深渊起点.md`（132 行，六点已拍板）。
> 基准 HEAD `318ac8b`（领先 origin 1 笔系网络故障，与实施无关），树干净，`scripts/` 34 个 `.gd`，冻结 `production/sprint-21/SPR21-FROZEN.md5` 34/34 OK。
> **只改 `.gd`**；文档由主理人写；**推送不归你**。

---

## 一 一句话

深渊局（`abyss_tier > 0`）开局时，按玩家已兑现的图鉴发现档数 `n = Game.codex_boons().size()`（0..4）追加 `n` 层环盾。**只改 `player.shield_charges`**，不动 `abyss_*` 三乘子、不动 max_hp/diamonds、不动 `CODEX_BOONS` 四档定义。零新增 rng / 实体 / 表。

---

## 二 硬红线

1. 🔴 **不改 `Data.ABYSS_TIERS` 三乘子本体**（hp 1.10→2.00 / speed 1.05→1.50 / dmg 1.07→1.70 一字不动）。改它会牵动 S21 `SMOKE_ABYSS` 验伤映射与 `validate._check_abyss` 单源自检。
2. 🔴 **不改 `Data.CODEX_BOONS` 四档的 effect/value/need**，字段集冻结。
3. 🔴 不碰 `meta.gd UNLOCKS` / `Meta.STATS_KEYS` / `SHRINE_OFFERS`·`OATH_CONDITIONS`·`SIGILS` 机制字段 / `ACTION_DEFS` / `FLOOR_THEMES` 8→12。
4. 🔴 **零新增 `Game.rng` 消费**。落点必须在 `Game.run_seed = Game.rng.seed`（实读 `:374`）之前。
5. 🔴 **不新开 helper**——用户拍板复用 `_apply_codex_boons()` 内的条件分支。
6. 🔴 冻结清单除 `game_main.gd` 外零漂移。**不要自己刷新快照行**（核验侧收官统一刷）。

---

## 三 生产代码改动（仅 1 处函数、约 5 行）

`scripts/game_main.gd:3367 func _apply_codex_boons() -> void:`

### 3.1 落点（顺序敏感，逐字照做）

现函数结构（实读）：

```gdscript
func _apply_codex_boons() -> void:
	var boons: Dictionary = Game.codex_boons()
	if boons.is_empty():
		return                      # ← 早退
	for id in boons:
		...                         # enemies_5 的 shield +1 在这里落地
	if _smoke:
		print("[SMOKE-CODEX-BOON] applied: %s" % str(boons.keys()))
```

**改动**：在 `for` 循环**结束之后**、`if _smoke:` **之前**，插入下面这段：

```gdscript
	# S29：发现度改写深渊起点——档数 1:1 折射为开局环盾，仅深渊局生效。
	# 零 rng：codex_boons() 只读派生、tier 为菜单预置，落点在 run_seed 之前。
	if abyss_tier > 0:
		player.shield_charges += boons.size()
```

🔴 **为什么在 `for` 之后**：让 `enemies_5` 的 shield +1 先落地，满档深渊局 = 1（被动）+ 4（缓冲）= 5 层，与实稿 §八 R4 登记的正特性一致。放在循环前虽然加法可交换、结果同为 5，但**读数时序**与实稿不符，核验会按实稿判。
🔴 **为什么在 `if boons.is_empty(): return` 之后**：0 档时 `boons` 为空直接返回、`size()` 本来就是 0，行为等价；不把加盾提到早退前，避免碰「0 档不进函数」的既有语义。
🔴 **不要写 `if n > 0:`** 之类的额外守卫——`+= 0` 无害，多一层分支只会多一个失败面。

### 3.2 不改的东西（逐条确认）

- `_apply_codex_boons()` 的早退、for 循环、四个 match 分支、smoke print：**一字不动**。
- `_codex_boon_suffix()`（紧邻的下一个函数）：**一字不动**（`shrine` 跳过逻辑是 S19 既有口径，别顺手改）。
- `start_run()` 里的调用顺序（`:370 _apply_codex_boons()` → `:372 _oath_grant()` → `:374 run_seed` → `:381-388` 深渊档注入）：**一字不动**。
- `player.gd`：本批**零改动**（盾字段、消费、上限逻辑都沿用，实读已确认无全局上限）。

---

## 四 为什么这样改不会打红既有断言

- `shield_charges` 是数值字段，既有探针凡读它都在**自己段内先置 0**（`player.gd:689/894/941/1208`），不依赖 start_run 的残留值。
- 新增加盾只在 `abyss_tier > 0` 时触发。既有普通局探针 `abyss_tier` 默认 0（`game_main.gd:97`），加盾分支不执行 → 普通局基线零漂移。
- E1 指纹 `:343` 只打 `rooms=` + `kinds=`，不含起始盾 → 三 seed 指纹零重定（**不许借机改指纹口径**）。

---

## 五 验证门（全部要自跑并报数）

| 门 | 期望 |
|---|---|
| G1 `validate` | 34/34、`problems=0`、`[ERR]==0` |
| G2 新探针 | 按 QA 口径（`SPR29_验证口径.md`）的 declared 数；`done checked=declared`；判红命令按口径指定格式（**别用错 `ok=` / `[ERR]`**） |
| G3 E1 | seed 12345/777/42，`[SMOKE-META] fingerprint` 对基线 `318ac8b` 逐字一致；`run start diamonds=` 仍 3/13/3 |
| G4 既有零 churn | 既有全部探针断言逐字不变（对比方法见 QA 口径） |
| G5 冻结 | 除 `game_main.gd` 外 33 行 OK；**不自刷快照** |

🔴 新探针格式必须与 QA 口径一致：若用 `_ct_assert()` 式，**判红看 `[ERR]` 不看 `ok=false`**（S27 实测用错会把正确实现判成变异无效）。

---

## 六 变异刀（至少 5 把，核验侧独立复现）

| 刀 | 改法 | 预测红 |
|---|---|---|
| 刀一 | `+= boons.size()` 改成 `+= 1`（各档加同样盾） | 验数值断言（0/2/4 差分档）红 |
| 刀二 | gate 写反 `if abyss_tier == 0:` | tier>0 差分全红 + tier=0 反向守卫红 |
| 刀三 | 加盾分支挪到 `run_seed` 之后 | 零 rng 断言红（seed/state 漂移） |
| 刀四 | 载体改成 `player.max_hp += boons.size()` | 验 shield 数值断言红 |
| 刀五 | 把加盾提到 `if boons.is_empty(): return` 之前 + 用 `Game.codex_boons().size()` 现算 | 若仍等价则如实记「结构性不可捕」，不许包装成见红 |

🔴 变异纪律：**替换目标行、不新增行**；注释里**不许写符号字面**（文本级静态门会凭空多红，S27 实测）。`replace_all` 前先 `grep -c` 确认目标串出现次数。

---

## 七 完成定义

五门全过 + 五刀逐刀见红（或如实标注不可捕）+ 复原后复跑全绿 + 工作树只含 `game_main.gd` 一处生产改动与新探针块。
报交付时附：commit hash、五门实测数、五刀红表、任何偏差的如实记录。**不 commit 文档、不推送。**

### 在册项（本批不碰，别顺手改）

- 大换血文件名残留 → 另立合规批。
- `frenzy`/`scarce_ammo` 文案名义值 + 压力层 maxf → 同批收敛，不并入本批。
- 「只升不降」主干已由 S27 批三 C1 关闭，**不得当未修缺陷重开批**。
