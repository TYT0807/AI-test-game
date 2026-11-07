# Sprint 13 阶段二交付：C 地窖图鉴 / 局末复盘

> 日期：2026-11-07｜依据 `SPR13_规划草案.md` §五 + 主理人开工令（阶段一 PASS 后放行）｜分工：编程侧
> 改动文件：`game_state.gd` / `game_main.gd` / `player.gd` / `hud.gd` / `menu.gd` / `validate.gd` / `resources/texture/generated/icon_codex.png`（新）
> 记录点行号以当前 `game_main.gd` 实读为准（阶段一修复批已改动灾祸/换层路径，未沿用旧报告行号）

## codex.cfg 双档（game_state.gd）

- `CODEX_PATH` / `CODEX_SMOKE_PATH` + `codex_path()`：完全镜像 `sigil_path()` 范式——`SMOKE_CODEX_PATH` 环境变量自定义隔离档 > `SMOKE` 环境变量 → `_smoke_codex.cfg` > 主档
- 数据模型：`codex = {enemies/relics/suffixes/themes/bosses: Array, last_run: Dictionary}`——五类发现集 + 上局复盘快照；只增不减
- `mark_codex(kind, id)`：未知 kind/id **两头忽略**（登记与读档共用 `_codex_id_valid`——enemies/bosses 对 `Data.ENEMIES`、relics 对 `RelicsRef.POOL`、suffixes 对 `Data.RELIC_SUFFIXES`、themes 对 `FLOOR_THEMES.rule`）；重复幂等；**新增即落盘**（发现不因中途退出丢失）
- `load_codex()`：未知 id 过滤（参照 load_sigils 防穿透写法）+ last_run **负数钳制**（maxi 0）
- `set_codex_last_run(stats)`：`_run_stats()` 五项快照（STATS_KEYS 内，不新增统计源），写入即存盘
- 零 rng、零 E1 影响（纯登记读写，无任何 Game.rng/fx_rng 消费）

## 五记录点挂接（规格 §C 口径，当前实读行号）

| 记录点 | 落点 | 登记 |
|---|---|---|
| `spawn_slug` | `slug.setup(...)` 之后 | enemies（每只生成的敌人 variant） |
| `drop_pickup` | `entities.add_child(pk)` 之后，kind=="relic" 且 payload 非空 | relics |
| `_apply_floor_theme` | `_theme_rule` 赋值后 | themes |
| `on_slug_killed` | `register_kill` 之后，`ai=="boss"` 时 | bosses（**规格范围注记**：PrismWarden/boss2 非 slug 实体，不走本记录点，图鉴 Boss 类按 §C 只覆盖 slug 型 Boss variant） |
| `_settle_meta` | `stats := _run_stats()` 之后（SMOKE 默认跳过结算 → 隔离档不被刷爆，与 meta 同口径） | last_run 快照 |
| `attach_suffix`（player.gd） | 绑定成功后 | suffixes |

## UI

- 主菜单 +「图鉴」按钮（icon_codex 新像素图标，gen_assets 确定性生成）+ `codex` 页：**上局复盘**行（最深/击杀/源石/用时/得分）+ 五个分区（已遇敌人/已击败 Boss/已发现遗物/已获词缀/已历主题，X/Y 计数 + 发现名单、空态灰字）——**只读平行页，不读不写 `meta.gd UNLOCKS`**（冻结规格 v2.10）

## 核验修复批（主理人 🟡：图标未登记 → 按钮静默白框）

- **根因**：`icon_codex.png` 已生成入库，但 `assets.gd GEN_NAMES` 漏登记 → `Assets.g("icon_codex")` 返回 null → `meta_icon()` 兜底落空 → 主菜单图鉴按钮退化为纯文字（`assets.gd:124` 既有注释正是此坑；Sprint 12 #6 同款「生成了没登记」）
- **修复**：`GEN_NAMES` 追加 `"icon_codex"`（仅此一行，`ACTION_DEFS` 未动）；`validate._check_codex` 补启动期断言 `Assets.g("icon_codex") != null`——「生成与登记必须成对」从此当场报错不靠人眼
- **回归**：启动自检 0 problems（断言绿）、SMOKE_CODEX 探针 done、冻结重定 `md5sum -c` **33/33 OK**（assets.gd/validate.gd 两条目重算，无新脚本）
- 四条低优先观察在册不返工（bosses 校验器未收窄 / load_codex 钳制断言未覆盖 / relics 口径待产品确认 / last_run 无键白名单）；Boss 覆盖范围注记已裁定接受
- 结算覆盖层（hud.game_over）：_stats_label 追加「本局复盘 · 最深 N 层 · 源石 X」行（STATS_KEYS 内数据）

## 验证（全部实跑）

| 项 | 结果 |
|-|-|
| SMOKE_CODEX 定向 1500 帧 | 隔离档路径断言 + 未知 id 两次登记忽略 + 记录→存盘→清内存→读回一致（含 last_run 快照逐分类比对）+ 负数钳制 → 0——全过、0 [ERR] |
| 启动自检 | **0 problems**；新增 `_check_codex`（kinds 齐 / last_run 在 / 校验器对合法 id 不误拒、对未知 id 不放行，词缀抽样取表内真实首 id） |
| 全量回归（SMOKE+V8+REBIND+RELIC+SUFFIX+PERSIST+COV+SHRINE+CODEX+CALAMITY+DAILY+FORCE_SQUAD=echo_pack+FORCE_SOVEREIGN+JUMP11+BOSS，6000 帧） | **0 报错**；5 个 done 标记（CODEX/REBIND/SHRINE/SIGIL-COV/SUFFIX）；BOSS2 floor=11 / 回响击败增益 / DAILY seed 1410307864 全证据 |
| E1 | 零 rng（代码级：mark/load/save 无任何 rng 消费）；DAILY seed 全程稳定互证；SMOKE_* 表外不进 diff（坑 45） |
| 坑 5 | `ACTION_DEFS` 零新增（图鉴页纯按钮导航） |
| E6 | 无任何计时/动效新增 |
| 冻结重定 | `md5sum -c` **33/33 OK**（本批零新脚本，33 .gd 不变） |

## 还剩什么

- Sprint 13 全部锁定范围（A+C+E）已交付完毕；备选 B/D 未接（草案 §七口径）
- 图鉴 Boss 类不含 PrismWarden/熔潮主宰（非 slug 实体，规格 §C 记录点未覆盖）——如需纳入，后续单列一小批在 boss 死亡路径挂登记（属规格扩展，不在本批自作主张）
- 非阻塞前瞻三条（主理人在册，不返工）：_enter_room 早于 _roll_calamity 的起点房瞬间 / Array.erase 首个匹配 / clear 末尾 saved 无条件重置
