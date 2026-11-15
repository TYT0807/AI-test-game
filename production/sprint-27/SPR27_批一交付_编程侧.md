# Sprint 27 批一交付 · 主题×灾祸复合（A 组 + B 组）

> 日期：2026-11-15｜依据 `SPR27_批一实施单_编程侧.md`（唯一权威）｜编程侧实施
> 两笔提交：A 组 `34f06c5`（6 常数格 + 探针 66 条）→ B 组（本文档随附，2 时变格 + 探针 76 条）。
> 改动文件：**仅 `scripts/game_main.gd`** + 冻结快照 1 行刷新 + 本交付文档。分类按主理人口径：内容行数（机制/探针/注释分列）+ md5 单列。

## 一、机制改动（照实施单 §四 逐条）

| 落点 | 内容 |
|---|---|
| 字段 ×2（:121 后） | `_calamity_theme_rule`（施加瞬间快照，clear 只读）/ `_calamity_frail_ratio`（实值比例） |
| `_apply_calamity()` | 开头 3 行快照（saved ×2 + rule 快照，经 `Data.theme_for_floor()`）；`frail` 改 `_frail_ratio()` 变体比例（vein 0.1 / silent 0.4 / 基线 0.2，`maxi(2,…)` 钳制逻辑一字未动）；`frenzy` 三分支（swamp 1.45 / ice 1.4 / 基线 1.25）；`scarce_ammo` 三分支（magma 0.7 / vines 0.65 / 基线 0.5）；`scarce_ore` 不变（`minf(…,0.7)`） |
| `_frail_ratio()`（新增纯函数） | 只读快照，禁现查 floor_num |
| `_clear_calamity_effects()` | 还原分支一字未改；if-block 补 2 行（rule 清空 + ratio 复位） |
| `_theme_damage_tick()`（B 组） | 插在 `is_instance_valid` 之后、SMOKE 分支之前：toxic×ammo 每 tick −0.1 下限 0.3；magma×ore 每 tick −0.05 下限 0.5；`snappedf(…,0.001)` 收敛浮点 |
| `_calamity_name()` | 百分比实值化（族名首词逐字保留：虚弱/狂乱/弹药荒/残响枯竭）；三个调用点零改动 |

**变体身份** = `(_calamity_theme_rule, _calamity)` 二元组，无 `"frail@magma"` 式字符串 ✓。方向配比：轻 3（vein×frail 0.10 / magma×ammo 0.7 / vines×ammo 0.65）+ 重 5（silent×frail 0.40 / swamp×frenzy 1.45 / ice×frenzy 1.40 / toxic×ammo tick / magma×ore tick）✓。

## 二、探针（SMOKE_CAL_THEME，76 条死数）

- 三强制打印（实施单 §5.1）：入口无条件 / 每断言 `#NN … measured= expect=` / 末尾 `done checked=N declared=N` + `Dev.check(checked==declared)` 自校验。断言经 `_ct_assert()` 助手统一走线，编号自动连排。
- 分组实测：①4 + ②12 + ③28（A 18 + B 10）+ ④9（换层 4 / 幂等 4 / 扫描 1）+ ⑤13 + ⑥6 + ⑦4 = **76** ✓（A 阶段曾以 66 过门）。
- 三段式：段1 施加 → 段2 换层精确还原（`_ct_floor_advance` 复刻 next_floor :1505-1509 顺序）→ 段3 再施加幂等；B 组 5 段（施加/递减单调/下限钳制/还原/再施加）。
- 零分支扫描：B 阶段 **24 格**（32 − 8 变体格），scan 前缀分流不污染 #NN；13 号格走真实路径 `_apply_floor_theme()`→1.5→apply 0.7→clear 1.5（相对承诺 −53%，⑦#76 文案 `-53%` 同证）。
- 换层构造禁用 4→12（回卷假绿）；⑥6 单独打 12 层回卷靶（apply 后 rule=="vein"，跑完还原 floor_num）。

## 三、门控实测（§六，全部实跑）

| 门 | 结果 |
|---|---|
| 静态 ×3 | `theme_for_floor` 计数 **4**（基线订正：原有 3 处 ：403/:1376/:1684，实施单写「原 1」系基线误记；新增恰 1 处快照）；`FLOOR_THEMES.get(` 全仓仅 `data.gd:495` ✓；`Game.rng|_floor_rng` 行 41→**44**，Δ3 全为 ⑤5 的 `.state` **属性读取**（非抽取调用，红线 #1「零新增调用」守住），零消费由 E1 实证 |
| validate（游戏内 SMOKE 自检路径） | 34/34 编译、problems=0、`[ERR]` 0。实施单 `-s scripts/validate.gd` 独立模式无法加载 autoload（`Dev` 未注册，与已记录的 `--check-only` 限制同族），改用同证据的游戏内路径 |
| E1 确定性 | A 组后、B 组后各三跑（stash 基线 + 2 跑）指纹**逐字一致**，未用 SMOKE_DAILY。B 组动生产 tick 路径仍零重定 |
| 探针 | A：#66 / ERR 0 / checked=66=declared；B：#76 / ERR 0 / checked=76=declared / 扫描 24 格 |
| **变异测试**（交付前自做） | 错版=快照三行移入 clear 现查（saved 捕捉已施加值 + rule 按新层复位）。**32 红**：⑥1-⑥6 全红（⑥2 measured=`silent`＝陷阱 1 的「用新层还原旧变体」实录；⑥1 got 链 toxic→vein→silent→magma 呈差一层模式）、④ammo/ore 红、④c 扫描红、②③⑤⑦ 面状红。复原后 66/66/0 全绿 ✓ |
| 冻结 | 每笔提交前刷新 `game_main.gd` 行，34/34 OK |

## 四、如实记录（三件事）

1. **变异第一版形状有个假绿**：rule 现查行放 clear 顶部、被 if-block 的复位行「再盖回空串」——现查成死代码，⑥2/⑥3 曾假绿。修正形状（现查行替换复位行）后 ⑥ 组才全红。教训：**变异必须替换目标行而非新增行**，否则死代码让靶子空放——此教训与「Dev.check 只在失败时打印」同等级，已入交付。
2. **扫描循环首版漏 `Game.floor_num = f`**：26 格全落在残留楼层 5 上施加，13 号格的 `_apply_floor_theme()` 跑成 toxic → 还原 1.0 ≠ 1.5 被 ④c 抓红。探针自校验体系按设计工作了。
3. **④「换层 4 条一起红」实测为 2/4**：frail（差值还原）/frenzy（无条件还原）不吃 saved，变异打不着——结构性不可红，非探针漏验；ammo/ore 两条红 + ⑥ 组全红补足证据。

## 五、不做清单遵守

陷阱 3 倍率泄漏未修 / `SMOKE_JUMP_FLOOR` 顺序未动 / `boss.gd:61` C-style `%` 未动 / 无第五灾祸 / 15% 触发率未动 / **本批未推送**（等主理人核验）。
