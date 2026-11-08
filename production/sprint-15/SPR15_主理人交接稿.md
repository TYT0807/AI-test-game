# Sprint 15 收官期 · 主理人交接稿（自包含，供接手方零上下文启动）

> 生成原因：用户告知「另一路编程 AI 余额不足，可能随时需要接手未做完的部分」。本文把项目坐标、状态、未完成清单、红线、挂接点、验证命令一次性固化，**接手方读完即可开工**，无需回翻历史对话。
> 主理人角色：只读核验 + 规划 + 文档；**不写任何 `.gd` 产品代码**（用户长期钉死的边界）。本文亦未改任何 `.gd`。

---

## 一、项目坐标与基线（2026-11-08 实校）

| 项 | 值 |
|---|---|
| 项目根 | `D:\Create\Game\test-1` |
| 引擎 / 语言 | Godot 4.7.2 / GDScript，单场景 `scene/game.tscn` |
| git | 分支 `main`，最新提交 `dbdb938`；工作树仅有**待授权文档**（见 §三） |
| 冻结清单 | `production/sprint-7/SPR7-FROZEN-4.md5`，`md5sum -c` **exit 0 / 34 OK / 0 FAILED** |
| 脚本数 | **34 个 `.gd`**（Sprint 15 新增 `boss3.gd`） |
| 最近五提交 | `dbdb938`(S15 阶段二) / `ef97df9`(S15 阶段一) / `03cccd4`(S14 二) / `9752dab`(S14 一) / `6a0940c`(S13 报告) |

**已收官**：Sprint 10–15 全部 final PASS。Sprint 15 锁定范围 = P0 + B + C + D / A，两阶段各自单独提交。

## 二、协作模型（务必先懂）

- 本会话 = **主理人 / 规划侧**：出规划草案、实读挂接点、读码核验（PASS/CONCERNS/final PASS）、维护文档与工作日志，**不写 `.gd`**。
- 另一路 AI = **编程实现侧**：按主理人产出的自包含规格改 `.gd`、跑验证、写交付文档、提交 git。
- 用户把主理人产出**整段复制转发**给编程侧；两边不实时联动。
- 批次流程（固化）：**实施 → 四门控 → 冻结重定 → 交付文档 → 单独提交 → 主理人读码核验**。每批一个 commit，不回头补。
- 提交、发布、删除等高影响动作**须用户显式授权**。

## 三、当前未完成清单（接手方优先看这里）

| # | 事项 | 性质 | 阻塞 |
|---|---|---|---|
| 1 | **E 断言盘点**（草案 §五）：把 `validate.gd:219–221`「前提守卫型恒过」、`player.gd:1048–1049` 等「常量自比较」断言的性质与意图标注清楚 | 需改 `.gd` **注释** | 无授权不动 `.gd`；也可改产出独立 `.md` 盘点稿 |
| 2 | **文档整理批**：四份待授权文档入库 —— `玩法说明.md`(已改) / `production/sprint-14/SPR14_规划草案.md` / `production/sprint-15/SPR15_规划草案.md` / 本交接稿 | 纯文档 + git 提交 | **需用户授权提交** |
| 3 | `玩法说明.md` 补行：Sprint 14（C 图鉴被动 / 双主题 Boss 收录 / 分母 6）+ Sprint 15（玄渊之主 / 分母 7 / 圣所 10 条 / P0 红线） | 文档 | 随 #2 同批 |
| 4 | 本轮核验观察 5 条（§五）：尤其 **#1 交付文档措辞订正**、**#2 D buff 断言补强** | 低优先，建议下批 QA 窗口 | 不返工 |
| 5 | Sprint 16 在册：F 房间事件池 / G 武器淬炼·每日深化 / B 口径备选（改挂拾取路径）/ boon suffixes 阈值（若产品要，须换备选切法并重做 P0 门） | 规划待用户开启 | 未开工 |

## 四、红线与口径速查（任何改动前先过一遍）

1. **E6 固定步**：计时 / DoT / 冷却走 `Game.FIXED_DT := 1.0/60.0`，禁 raw `delta`。⚠️ 例外见 §五 #3（既有 `_tick_buffs` 通道）。
2. **E1 确定性**：核心循环不无故新增 `Game.rng` 消费；`SMOKE_*` 表外探针不进 E1 diff（坑 45）；`_smoke_fingerprint` 只含 rooms 坐标 + kinds。
3. **坑 5**：`assets.gd` `ACTION_DEFS`（`:333–`）不加新 action；新资源走 `Assets.g()` 必须同步登记 `GEN_NAMES`（`:109–132`）——`icon_codex` 曾因漏登记静默白框（Sprint 13 阶段二）。
4. **冻结规格 v2.10**：`meta.gd UNLOCKS` 不动；局外内容一律平行只读派生。
5. **登记三件套**：新增 id / 资源 / 记录点须同时核对 ① 写入 ② 注册表·白名单·UI 分母·显示名 ③ 可见效果断言。
6. **boon 红线（P0）**：任何 `CODEX_BOONS` 扩表前，必须保持「`kind` 不得为 `suffixes`」的判据端切链（`validate.gd:244–249`）。若产品确需 suffixes 阈值，改用「不回写图鉴的内部绑定路径」并重做此门。
7. **F1 主题扩容 8→12 永不接**：四处周期来源不一致（`data.gd:366` 用 `FLOOR_THEMES.size()` 动态；`boss.gd:56`、`game_main.gd:970` 硬编码 `%8`、`:976` 硬编码 `%16`）→ 扩容会双轨错位 + E1 全量重定。
8. **dash option b 保持 196–210px**（手感特性，非缺陷）；**终审附章入库提议休眠**；**Boss 的 `variant="boss"` 承载宝箱/词缀必掉/震屏，严禁改**（图鉴登记一律走 `codex_id`）。
9. **纪律**：凡标 ✓ 必须附**本轮实读行号**，不得沿用上一轮印象；范围注记同样要实读（`boss.gd:338 on_slug_killed` 的教训）。

## 五、Sprint 15 读码核验结论（2026-11-08，功能门 **final PASS**）

两阶段功能全部真闭环：`ef97df9`（P0 双红线门 / B 口径 / C 进度条 / D 圣所 6→10）、`dbdb938`（`boss3.gd` 玄渊之主 / `_is_third_floor` / 优先链 / posmod / `_init()` 补强 / 三件套单源）。实校 `md5sum -c` 34/34、两批零 `assets.gd`/`meta.gd`/`.tscn` 改动、新增行零 `Game.rng`/`fx_rng`/`delta`。

**在册观察 5 条（不阻断、不返工，建议下批 QA 窗口顺手清）**：

1. 🟡 **P0「真差值断言」名实不符**：交付文档 `SPR15_交付_阶段一.md:10` 称 `SMOKE_CODEX_BOON` 的新断言「不是恒过型」；实读 `player.gd:1021–1025` 是「`_apply_codex_boons()` 前后 `codex_boons()` 相等」。当前 `CODEX_BOONS` 四档 kind 均非 suffixes，`codex_boons()` 根本不读 suffixes → **前后必然相等**。真正有效的防线是 `validate.gd:244–249` 的启动期遍历断言（**前提守卫型**，当前亦恒过但能拦未来扩表）。建议：订正交付文档措辞为「前提守卫型 + validate 启动期门」，或补一条真差值构造（临时注入 suffixes 阈值后验 validate 报错）。属 Sprint 12 #6 同款「声明与效果不符」，非功能缺陷。
2. 🟡 **D 两条限时 buff 断言只验标志**：`player.gd:827` / `:829` 只验 `_buffs.has("boots")` / `has("book")`，未验 `speed_mult` / `damage_mult` 实际生效。实现实读无误（`player.gd:1228–1234` 的 `match id`：`boots,kinetic→speed_mult`、`book→damage_mult`、`echo_rate→rate_buff_mult`），但断言覆盖是「只验标志不验数值」同款根因。建议补 `is_equal_approx(speed_mult, speed_base*1.25)` / `damage_mult == 1.3`。
3. 🟡 **`_tick_buffs` 用 raw delta**：既有通道 `player.gd:1216–1236`，`:1224 _buffs[id].t -= delta`，调用点 `:252 _tick_buffs(delta)`。本批零新增计时逻辑属实（只是复用 `buff()` 传 120s / 90s），交付文档「零计时」严格讲应为「零**新增**计时逻辑，复用既有通道」。长时 buff 把该通道使用面从 2s 扩到 120s，建议后续统一为 `Game.FIXED_DT` 或明确登记为既有豁免。
4. 🟡 `_third_boss_probe` 单元路径（`player.gd:1053–1059`）直调 `on_slug_killed(b3)` 有真实副作用（+2000 分、掉 8 次源石、消费一次 `Game.rng`）。表外探针可接受，建议登记。
5. 🟡 `validate` P0 门与 `B4`（`validate.gd:219–221`）当前都恒过，属**前提守卫型**（防未来放宽时静默失效），不是假断言；但按「凡标 ✓ 必附证据」纪律，交付文档应标注性质，避免被误读为「验效果型」。

## 六、挂接点速查（行号基于 `dbdb938`，改动前请重新实读）

| 主题 | 落点 |
|---|---|
| 数据表 | `data.gd` `ROOM_META:296` / `SHRINE_OFFERS:313` / `CODEX_BOSS_NAMES:336` / `CODEX_BOONS:343` / `FLOOR_THEMES:102` / `SIGILS:215` / `SQUADS:147` / `RELIC_SUFFIXES:185` / `ACTIVE_RELICS:231` / `MILESTONES:282` |
| Boss | `boss.gd:56 phase_theme_index` / `:30 codex_id` / `:338 on_slug_killed`；`boss2.gd:10 _init`、`boss3.gd:12 _init`；`game_main.gd:969 warden`、`:974 sovereign`、`:981 third`、`:1095–1124 优先链` |
| 图鉴 | `game_state.gd:290 _codex_id_valid` / `:315 mark_codex` / `:328 set_codex_last_run` / `:340 load_codex` / `:373 codex_boons`；`game_main.gd:2052 _apply_codex_boons` / `:1731 on_slug_killed 登记`；`menu.gd:308 _build_codex` / `:347 _codex_section` |
| 圣所 | `game_main.gd:1954 _shrine_entry` / `:1961 _shrine_offers_for` / `:1977 _shrine_execute` / `shrine_panel.gd:171 _pick` |
| 灾祸 | `game_main.gd:383 _roll_calamity` / `:437 _clear_calamity_effects` / `:1275 next_floor` |
| 验证 | `validate.gd:54 _check_codex 调用` / `:185 _check_shrine` / `:225 _check_codex` / `:244 P0 红线门`；`player.gd:869 _codex_probe` / `:988 _codex_boon_probe` / `:1039 _third_boss_probe` / `:658 _suffix_probe` / `:761 _shrine_probe` |
| 资源 | `assets.gd:109 GEN_NAMES` / `:333 ACTION_DEFS` / `:177 g()`；`menu.gd:630 meta_icon` |

## 七、验证命令与探针清单

```bash
cd "D:/Create/Game/test-1"
git status --short
md5sum -c production/sprint-7/SPR7-FROZEN-4.md5     # 期望 exit 0 / 34 OK / 0 FAILED
ls scripts/*.gd | wc -l                              # 期望 34
git log --oneline -5
```

全量回归钩子（`SMOKE=1` 主钩 + 表外探针，6000 帧 0 报错为门）：`V8 / REBIND / RELIC / SUFFIX / META / PERSIST / BOSS / BOSS2 / ECHO / DAILY / CALAMITY / SHRINE / CODEX / CODEX_BOON / SIGIL-COV / FORCE_SQUAD / FORCE_SOVEREIGN / JUMP_FLOOR / FORCE_THIRD_BOSS / THIRD_BOSS`。
注意：`SMOKE_JUMP_FLOOR` 吃**层号数值**不是布尔；`FORCE_SQUAD` 吃编队 id；`SMOKE_META_SETTLE=1` 才开结算；`SMOKE_BOSS` 是火力提速钩。

四门控：① 6000 帧 0 报错 + 冻结重定 ② E6 grep 零 raw delta ③ E1 双跑指纹逐字一致 + `ACTION_DEFS` 零新增 ④ 探针「断言 + [ERR] + done 落地」，且**断言必须验数值不能只验标志**。

## 八、给接手方的启动指令

1. 先读 `production/sprint-15/SPR15_规划草案.md` → `SPR15_交付_阶段一.md` → `SPR15_交付_阶段二.md` → 本交接稿。
2. 再读 §四红线、§六挂接点，**对每个要动的落点重新实读行号**（本稿行号基于 `dbdb938`）。
3. 从 §三 未完成清单里挑一项，先给「方案 + 影响面 + 回滚手段」待用户确认，再动手；改前备份、小步可回滚。
4. 任何写入 `.gd` 或 git 提交前**须用户许可**；交付文档与冻结清单随批更新；每批单独提交。
5. 完成后交还主理人读码核验（PASS / CONCERNS / final PASS）。

**已知风险与缓解**：① 编程侧可能中断 → 本稿 + 草案 + 两份交付文档 + git 历史已构成完整证据链，新接手方无需对话上下文；② 四份文档未入库 → 断电/换机前建议先授权提交；③ 观察 #1 的声明偏差不影响功能，但下批文档整理时一并订正，避免累积成口径分叉。
