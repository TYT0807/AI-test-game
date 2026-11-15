# Sprint 27 批一 · 主理人独立核验（主题 × 灾祸复合）

> 核验对象：`34f06c5`（A 组 6 常数格）+ `0b45338`（B 组 2 时变格）。核验时 HEAD `0b45338`，工作树干净。
> 方法：全部自跑，不采信自报。含**独立双刀变异**（两把刀打两个不同的失败面）。
> 结论：**final PASS**，附 3 项如实标注（1 项我方基线误记、1 项我方变异期望写错、1 项文案名义值入册）。

---

## 一 改动面

| 项 | 实测 |
|---|---|
| `scripts/` 下改动文件 | **仅 `game_main.gd`**（+626，其中探针约 570 行） |
| 其他改动 | 冻结快照 1 行（`game_main.gd` 的 md5）+ 5 份文档 |
| `.png` / `.mp3` / `.import` | **0** |
| 冻结校验 | `md5sum -c SPR21-FROZEN.md5` → **34/34 OK**，无 FAILED |

---

## 二 静态门（三条，自跑）

1. `grep -rn "FLOOR_THEMES\.get(" scripts/` → **仅 `data.gd:495`** 一条（`theme_for_floor` 内部），与基线一致，无新增直查。
2. `theme_for_floor` 计数：`aba6ccb` = **3** → HEAD = **4**，新增恰 1 处（`:581`，apply 开头快照）。
   🔴 **基线订正（我方错）**：实施单 §六原写「期望 2（原 1 + 新增 1）」，实际原有 3 处（`start_run` 段 `:403`、层签 `:1458`、局末/复盘 `:1776`）。编程侧报「原 3、合规 4」是对的；实施单已改，并把教训写进条文。
3. `Game.rng` 行数 38 → 41，**Δ3 全为 `.state` 属性读取**：`:143` 声明 `rng_state0`、`:379` 断言 `state == rng_state0`、`:378` 为注释文本。
   → 红线 #1「零新增 rng **抽取调用**」守住；零消费由 §五 E1 实证，不靠计数推断。

---

## 三 机制层读码（逐条对实施单 §四）

| 项 | 结论 |
|---|---|
| 字段 2 个 | `_calamity_theme_rule` / `_calamity_frail_ratio` 均加在 `_calamity_saved_mag_cap_mult` 之后 ✓ |
| apply 快照位置 | `:581`，在 `match _calamity` **之前**，且经 `Data.theme_for_floor()` 派生（未绕过）✓ |
| frail | `_frail_ratio()` → 0.1(vein) / 0.4(silent) / 0.2(default)；`maxi(1, round(old*ratio))` 与 `maxi(2, old-cut)` 钳制**一字未动**，`cut` 仍回写实际差值 ✓ |
| frenzy | swamp 1.45 / ice 1.4 / default 1.25 ✓ |
| scarce_ammo | magma 0.7 / vines 0.65 / default 0.5，`mag_changed.emit` 保留 ✓ |
| scarce_ore | 分支**未动**（`minf(...,0.7)`）✓ |
| clear 还原分支 | `:625-636` 三个分支**零改动** ✓ |
| clear 复位 | `:641-642` 在 `if _calamity != "":` 内补 2 行（rule 置空 / ratio 复位）；**未现查 `floor_num`，未读 `_theme_rule`** ✓ |
| B 组 tick | `:1556` 开头、`is_instance_valid` 之后、SMOKE 分支之前；`maxf(下限, snappedf(v−step, 0.001))`，下限 0.3 / 0.5 ✓ |
| `_calamity_name` | 四灾祸均按实值取百分比，族名首词逐字保留（`虚弱`/`狂乱`/`弹药荒`/`残响枯竭`）✓ |
| 变体身份 | 二元组 `(_calamity_theme_rule, _calamity)`，无 `"frail@magma"` 式字符串编码 ✓ |
| 探针现场还原 | 收尾 `Game.floor_num = save_floor` / `_calamity = save_calamity` + 四通道复位 + `update_floor_sign()`，不污染后续探针 ✓ |

---

## 四 探针门（自跑，非采信）

| 项 | 实测 |
|---|---|
| 断言行 `grep -c "^\[SMOKE-CAL-THEME\] #"` | **76** |
| `[ERR] cal_theme` | **0** |
| `done checked=… declared=…` | **checked=76 declared=76**（自校验成立） |
| `scan` 行（禁用 `#` 前缀分流） | **24**（B 组完成后口径 24 格，与实施单 §5.6 一致） |
| 全日志其他 `[ERR]` | **0**；`validate: 34/34 通过`、problems=0 |
| 换层构造 | `_ct_floor_advance(f3+1)` 复刻 `next_floor` 顺序；增量 4→5 / 7→8 / 8→9 / 9→10 / 10→11 / 11→12，**每格都改变 rule**，未用 4→12 ✓ |

---

## 五 E1 确定性（自跑，基线对照）

同 seed `424242`，`SMOKE_META_FINGERPRINT=1`：

- HEAD 两跑指纹哈希相同（`bb30d887…`）
- **HEAD vs 基线 `aba6ccb`**：`[SMOKE-META] fingerprint` + 5 条 `[SMOKE-SUPER] floor=…` + `[SMOKE] seed=` 共 8 行**逐字 diff 无差异**

诚实标注：本轮 E1 的指纹只覆盖 **floor=1**（headless 不推进楼层）；多楼层维度由 5 条 `[SMOKE-SUPER]` 生成记录补足，仍不等于「全楼层指纹」。B 组动了生产 tick 路径（`_theme_damage_tick`），此路径不抽 rng，且 E1 为零差异。

---

## 六 独立双刀变异（核验侧自做，不采信自报）

两把刀打两个**不同的失败面**，缺一不可。

### 刀一：`_frail_ratio()` 的 vein 0.1 → 0.2（把变体 #1 改回基线）

结果 **3 红**：

```
③f4×frail 段1 施加=变体   measured=2.0 expect=1.0
③f4×frail 段3 再施加幂等  measured=2.0 expect=1.0
⑤7 层签含变体实值（f4=-10%/f7=-40%）measured=["f4: 层签 · 往生脉◆ …
```

→ 证明 ③ 数值断言与 ⑤7 文案断言**都活着**，76 绿不是装饰。

### 刀二：把 clear 的复位行 `_calamity_theme_rule = ""` 换成现查 `Data.theme_for_floor(Game.floor_num)`

结果 **2 红**：

```
⑥2 换层 clear 后快照清空  measured=silent   expect=空串
⑥3 净化 clear 后快照清空  measured=pressure expect=空串
```

🔴 **measured=silent 正是陷阱 1 的实录**：旧灾祸施加在 7 层（silent），换层后 `floor_num` 已是 8，现查就把「新层主题」当成变体身份。

⚠️ 这一刀**只红 2 条**，③/④ 数值面全绿——因为 apply 的快照还健在，还原仍正确。**这恰好证明 ⑥2/⑥3 不可省**：它们是「复位行不许现查」这个失败面上的**唯一**守卫，数值断言结构上抓不到。反过来，编程侧那把「apply 不再快照、只在 clear 现查」的完整错版才能打红数值面（自报 32 红）。两把刀合起来才覆盖全部失败面。

两把刀均已 `git checkout HEAD -- scripts/game_main.gd` 复原，复跑 **76/76、ERR 0**，树干净。

---

## 七 三项如实标注

1. **实施单基线误记（我方错）**：`theme_for_floor` 原写「原 1」，实为 3。编程侧订正为 4 正确，已改入实施单 §六。
2. **实施单变异期望写错（我方错）**：原写「④ 换层 4 条一起红」，实测 2/4。原因是结构性不可红——frail 走 `_calamity_frail_cut` 差值还原、frenzy 走 `:596` 无条件 `1.0`，两者都不读 `saved`，snapshot 错了也打不着。**不是探针漏验**。已把正确的两刀形状写进实施单。
3. **文案是「名义比例」而非「实际削减」（入册不修）**：
   - `barren` 因子把 `diamond_mult` 压到 0.7 后，若再抽到 `scarce_ore`，`saved=0.7` → 文案显示「残响枯竭（残响掉落 **-0%**）」。语义诚实（确实没削减）但观感像 bug。
   - `max_hp` 触 `maxi(2,…)` 钳制时 `cut` 可能为 0，文案仍显示 -10%/-40%。
   - 属既有同族问题（旧版同样显示 -20% 而实际可为 0），本批不引入新机制，入册随下次文案收敛批处理。

---

## 八 结论

**final PASS。** 五门（静态 / 机制读码 / 探针 / E1 / 冻结）全部自跑通过，双刀变异证明断言体系非装饰且分层正确（数值面 vs 标志面）。三项标注不影响结论，其中两项是我方文档笔误、一项是既有文案族的延续。

推送不归核验侧。编程侧可推。
