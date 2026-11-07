# Sprint 14 阶段一交付：A 图鉴扩容 + 双主题 Boss 收录 + B QA 加固批

> 日期：2026-11-08｜依据 `SPR14_规划草案.md`（锁定 A+B+C；本批 = 阶段一 A+B）｜分工：编程侧
> 改动文件：`boss.gd` / `boss2.gd` / `data.gd` / `game_state.gd` / `game_main.gd` / `menu.gd` / `player.gd`（探针）/ `validate.gd` + `SPR13_交付_阶段二.md`（B7 文档排版，纯文档）
> 草案与 `玩法说明.md` 按主理人口径待授权随下批文档整理入库，未混入本提交

## A：双主题 Boss 收录 + 隐性误登记修复（§3.1–§3.3）

- **§3.1 确认**：`boss.gd _die()` 末尾一直调 `on_slug_killed(self)`——收官时的「两个主题 Boss 都不进图鉴」注记不成立；实况是守望者 `variant="warden"` 零登记（假阴性）、熔潮主宰 `variant="boss"` 把「巨岩虫之王」误登记（假阳性）
- **修法（不动 variant）**：`boss.gd` 基类加 `codex_id := "prism_warden"`，`boss2.setup()` 覆写 `"pyrothalassian"`；`on_slug_killed` 登记改 **codex_id 优先、variant 回退**（普通 slug 的 `get("codex_id")` 返回 null，`String(null)` 构造不存在——用 `"codex_id" in slug` 守卫，首跑当场抓出）
- **登记三件套数据层单源**：`data.gd` 新增 `CODEX_BOSS_NAMES`（两 id 中文名）+ `codex_bosses_total()`（分母 = ENEMIES 真 Boss 数 + 专用 id 数）——
  - ① 写入：`on_slug_killed` 分支改写（上述）
  - ② 白名单：`_codex_id_valid("bosses")` 收窄为「主题 Boss 专用 id ∪ ENEMIES 内 ai==boss」——非 Boss 敌人 id 被拒（B1）；旧档遗留的 `"boss"` 仍是合法键，**不做隐式迁移**（§3.4）
  - ② 分母 + 显示名：`menu.gd` `boss_total := Data.codex_bosses_total()`（4→6 同源防错位）、bosses 显示名 `CODEX_BOSS_NAMES` 优先（防英文 id 直出）
  - ③ 断言：`SMOKE_CODEX` 新增登记 / 白名单拒收 / 分母 / 显示名四条

### 击杀路径实证（清档 → 跑 → 查 `_smoke_codex.cfg`，探针登记后即撤销以区分「探针写」与「击杀写」）

| 场景 | cfg bosses 结果 | 判定 |
|---|---|---|
| 全量回归（sovereign 强制，boss2 死亡；探针已撤销登记） | `["dragon", "pyrothalassian"]` | boss2→专用 id ✓；slug Boss（dragon）→ variant 回退 ✓；**"boss" 假阳性消失** ✓ |
| 跳 11 层无 sovereign（守望者击杀） | `["prism_warden"]` | 守望者→专用 id ✓（假阴性修复） |
| 无跳层 6000 帧（1 层 boss 房为常规巨岩虫之王） | `["boss"]` | 合法击杀登记 ✓（旧档兼容口径一致） |

## B：QA 加固批（B1–B7）

| # | 落地 |
|---|---|
| B1 | 并入 A 白名单收窄（上表）——探针断言 `rusher` 被拒 |
| B2 | `SMOKE_CODEX` 补**读档路径**钳制断言（手工写负数 cfg → `load_codex()` → 归 0）——「实现保证」升级为「断言覆盖」 |
| B3 | `set_codex_last_run` 收 `META.STATS_KEYS` 白名单——越界键（含 `_run_stats` 的 SMOKE 覆盖键）直接忽略；探针断言 `bogus_key` 不入快照 |
| B4 | **不改** `_enter_room`↔`_roll_calamity` 时序；`validate._check_shrine` 抽查补启动期断言「shrine 恒非 Vector2i.ZERO」+ purify 过滤旁注明前提——零 E1 漂移 |
| B5 | `_roll_calamity` 加「同层不重复 append」守卫；探针断言同层双 roll 仅登记一次 |
| B6 | clear 末尾三 saved 值重置移进 `if _calamity != ""`——纯语义收拢；探针断言空 clear 保留 saved（0.42 探针值不变） |
| B7 | `SPR13_交付_阶段二.md` 排版修复（「结算覆盖层」bullet 移回 §UI）+ 两条纪律条文归拢（「登记三件套」/「凡标 ✓ 必附本轮实读行号」） |

## 验证（全部实跑）

| 项 | 结果 |
|-|-|
| SMOKE_CODEX 定向 1500 帧 | A 四断言 + B2/B3/B5/B6 全过、0 [ERR]；首跑抓出两处：探针未定义 `gm`（解析错）与 `String(null)`（slug 无 codex_id 属性）——门控当场拦截 |
| 全量回归（16 钩子，6000 帧） | **0 报错**；5 done 标记；BOSS2 floor=11 / DAILY seed 1410307864 证据齐 |
| 击杀路径三场景 | 上表三行，清档后验 cfg，路径级实证 |
| E1 / E6 / 坑 5 | 零 rng（纯状态字段与映射）/ 零计时 / `ACTION_DEFS` 与 `GEN_NAMES` 零新增 |
| 冻结重定 | `md5sum -c` **33/33 OK**（无新脚本） |

## 还剩什么

- **阶段二 C**：`CODEX_BOONS` 表 + `codex_boons()` 派生 + `:347` 契约同段注入（一次性起始状态，禁用全局倍率载体 §5.4）+ `SMOKE_CODEX_BOON`（阈值边界 / 起始状态落地 / 指纹双跑 / 载体零命中）
- 交付文档须登记：图鉴档不同 → 起始状态不同（局外输入），同 seed 双跑仍逐字一致
- 旧档残留 `"boss"` 记录如实披露（§3.4），不隐式迁移；显式重置入口需单独授权，本批未做
