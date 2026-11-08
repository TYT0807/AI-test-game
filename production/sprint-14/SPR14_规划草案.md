# Sprint 14 规划草案（主理人 / 规划侧合成）

> 来源：主理人实读挂接点后合成，沿用 Sprint 10–13 已沉淀的非编程专家口径（design-strategist 玩法 / art-director 美术 / audio-director 音频 / quality-lead 验收）；本批为规划侧直接合成，**未逐项 spawn**，故不标注四专家实稿。
> 本文为**自包含规格**，编程侧据锁定范围实现；主理人侧**不写任何 `.gd`**（只读核验 + 文档维护）。
> **锁定范围（用户 2026-11-07 裁定）**：**A + B + C** —— 阶段一 A+B、阶段二 C；G 由主理人并行完成。D/E 备选未接、F 永不接。
> 基线（本轮实校）：Sprint 13 **final PASS 正式收官**；`git status` 干净、六提交在册（最新 `6a0940c`）；冻结 `SPR7-FROZEN-4.md5` **33/33 OK**（`md5sum -c` exit 0）；**33 个 `.gd`** / 单场景 `scene/game.tscn`。
> 已冻结可复用系统：`ROOM_META` **11 房型**（含 `shrine`）/ `SHRINE_OFFERS` 6 条 / `SIGILS` 9 枚 / `SQUADS` 7 模板 / `RELIC_SUFFIXES` 8 条 / `ACTIVE_RELICS` 4 条 / `FLOOR_THEMES` 8 主题 / `PrismWarden` + `boss2` 继承骨架 / 每日挑战 `stable_hash`（标准 FNV-1a 32 位）/ 灾祸层条件还原 / 回响 + 协战实体 / `codex.cfg` 双档只读图鉴 / `MILESTONES` 9 条。

---

## 〇、跨批铁律（任何新内容必须遵守）

1. **E6 固定步**：所有新增计时走 `Game.FIXED_DT`，禁 raw `delta`（Sprint 10 起铁律）。
2. **E1 确定性指纹**：核心循环不无故新增 `Game.rng` 消费；表外验证探针 `SMOKE_*` 不进 E1 diff（坑 45）；动 rng 前先想清是否漂移基线，预期代价须登记 + 随批重定。
3. **复用优先**：新内容挂既有表 / 接口 / 实体，不另起炉灶。
4. **坑 5 护栏**：`assets.gd` `ACTION_DEFS`（`:328–352`，动作总表）**不加新 action**；已注册 `card_1/2/3`（KEY_1/2/3）、`buy`(E)、F/Z/X/C 遗物键够用。任何新资源若走 `Assets.g()`，**必须同时登记 `GEN_NAMES`（`:109–132`）**。
5. **冻结规格不可改**：`Sprint7_解锁树规格.md` v2.10 → `meta.gd UNLOCKS` 表**不动**；新局外内容一律做平行只读派生。
6. **批次流程**：实施 → 三层验证 / 四门控 → 冻结重定 → 交付文档 → **单独提交**（每阶段一个 commit，不回头补）。
7. **🆕 登记三件套（本批新增纪律，五轮同族缺陷归纳）**：任何「新增一个 id / 资源 / 记录点」必须同时核对三处，缺任一项视为未完成——
   **① 生成或写入 → ② 注册表 / 白名单 / UI 分母 → ③ 可见效果的断言**。
   反例：`icon_codex`（PNG 生成了但 `GEN_NAMES` 漏登记 → 静默白框）、`bulwark`（表里有了但 `match` 漏分支 → 零效果）、`frenzy`（断言只验状态标志、不验数值还原 → 跨层固化整局四轮未发现）。
   **本批 A 方向的三件套清单见 §3.3，验收门控须逐项打勾。**

---

## 一、候选方向（A–G）

| 方向 | 规模 | 内容 | 风险 / 裁定 |
|---|---|---|---|
| **A. 图鉴扩容 + 双主题 Boss 收录** | M | 把 `PrismWarden` / 熔潮主宰纳入图鉴 bosses，并修复本轮实读发现的**隐性误登记**（§3.1） | 中低：挂点已实读、零 rng；三件套同步扩是硬约束 → **推荐核心** |
| **B. QA 加固批（在册清零）** | M | `bosses` 校验器收窄 / `load_codex` 钳制补读档断言 / `last_run` 键白名单 / 阶段一三条前瞻 / 文档 `:37` 排版 | 低：纯收敛、零玩法改动 → **推荐** |
| **C. 图鉴发现度被动 / Codex Boon** | M | 把局外图鉴沉淀接回局内：发现度达阈值 → 开局小幅起始加成（平行只读派生，不碰 `UNLOCKS`） | 中低：注入点已实读且零 rng；**禁用全局倍率载体**（§5.4） → **推荐玩法增量** |
| **D. 武器淬炼（备选 B 转正）** | M | `weapons.gd` 四把枪挂词条 | **中高**：伤害路径 rng 密集（`player.gd:392/394/425/492`），易引 E1 漂移与 raw delta → **备选，不建议同批** |
| **E. 每日深化（备选 D 转正）** | M | 种子分享码 / 每日固定词缀 / 本地榜扩展 | **中**：加「每日固定词缀」会改 `start_run:340–358` 的 rng 顺序 → 基线重定；与 Sprint 12 D 重复度高 → **备选** |
| **F. 第三 Boss / `FLOOR_THEMES` 8→12** | L | — | **永不接**（既定口径）：8→12 会破坏 `phase_theme_index` 的 `%8` 与两个 Boss 三阶段主题序列 → E1 全面重定 |
| **G. `玩法说明.md` 校准** | S | 顶层唯一玩家向文档 183 行，末次改动停在 `706a8c3`；「圣所 / 灾祸 / 每日 / 守望者 / 熔潮 / 编队 / 字号」**七关键词全 0 命中**，已滞后四个 Sprint | 零风险，**主理人可直接做、不占编程侧车道** → 建议顺手 |

## 二、锁定组合（用户已裁定：A + B + C）

| 阶段 | 方向 | 交付物 |
|---|---|---|
| 一 | **A（M）+ B（M）** | 双主题 Boss 收录 + 隐性误登记修复 + 在册遗留清零（零 E1 风险，先交） |
| 二 | **C（M）** | 图鉴发现度被动，与阶段一零耦合但读 `Game.codex`，建议阶段一后接 |
| 并行 | **G（S）** | 主理人补 `玩法说明.md`，随下批文档整理一并提交（需提交授权） |

- **dash option b 保持现状**（196–210px，120 直驱 + 碰撞挤出作为手感特性），本批不改造、不阻塞。
- 「终审附章入库」提议**休眠**，本批不唤醒（用户收官答问已裁定）。
- `relics`「已见即发现」口径：本批**只登记待产品裁定**，不改挂点（当前与 Sprint 13 §五规格一致，非缺陷）。

---

## 三、阶段一 · 方向 A 完整规格（图鉴扩容 + 双主题 Boss 收录）

### 3.1 ⚠️ 先认这条隐性路径（本轮实读，与 Sprint 13 范围注记不同）

Sprint 13 交付文档 / 核验报告写的是「PrismWarden/boss2 非 slug 实体，**不走** `on_slug_killed`，故两个都不登记」。实读结果**不成立**：

| 证据 | 内容 |
|---|---|
| `boss.gd:335` | `_die()` 末尾有 `Game.main.on_slug_killed(self)` → 两个主题 Boss **确实**走该回调（且 `boss.gd:25–26` 提供了 `xp_value` / `score_value`，回调能跑通） |
| `boss.gd:27` | `var variant := "warden"` → `Data.enemy("warden")` 为空 → `on_slug_killed:1707` 的 `ai=="boss"` 判定为假 → **守望者零登记（假阴性）** |
| `boss2.gd:13` | `setup()` 里 `variant = "boss"`（Sprint 12 为复用宝箱 / 词缀必掉 / 震屏而设）→ `Data.enemy("boss").ai == "boss"` 为真 → `mark_codex("bosses", "boss")` **命中** → 图鉴把 `ENEMIES["boss"]`「巨岩虫之王」误记为已击败（**假阳性**） |
| `game_main.gd:1727/1740` | `suffix_chance=1.0`（`variant in ["elite","boss"]`）、宝箱掉落、`add_shake(0.8)` 三条既有路径**都依赖 `variant=="boss"`** |

**结论**：现状是「**一个不登记、一个错登记**」，不是「两个都不登记」。这不是编程侧自作主张扩展，而是既有掉落契约与 Sprint 13 新增登记点叠加的副作用；Sprint 13 的范围注记需在交付文档中据本段订正（不重写历史，追加说明即可）。

> 🚫 **严禁改 `boss2.variant`**（`:13` 注释明示其承担三条既有掉落路径）。修法必须绕开 `variant`。

### 3.2 修法（最小、隔离）

- 给 `boss.gd` 基类加一个**专用图鉴 id 字段**（如 `var codex_id := "prism_warden"`），`boss2.setup()` 覆写为 `"pyrothalassian"`；**不动 `variant` / `boss_name` / 掉落路径**。
- `on_slug_killed` 的 bosses 登记分支改为：实体带 `codex_id` 就用它，否则回退 `slug.variant`（普通 slug Boss 行为不变）。
- 两个新 id **不复用 `Data.ENEMIES` 键**，避免再次撞上「巨岩虫之王」这类同名歧义。
- 效果：守望者死亡 → 登记 `prism_warden`；熔潮主宰死亡 → 登记 `pyrothalassian`；**两者都不再产生 `"boss"` 登记**。

### 3.3 登记三件套（缺一即「登记了但生效不了」，icon_codex 同款）

| # | 落点（本轮实读行号） | 必须同步 |
|---|---|---|
| ① 写入 | `game_main.gd:1707–1708` | 改取 `codex_id`（§3.2） |
| ② 白名单 | `game_state.gd:290–306` `_codex_id_valid("bosses", …)` | 现为「任意 `Data.ENEMIES` 键」→ **收窄为真 Boss**，并加入两个新 id；否则新 id 被校验器静默忽略 |
| ② 分母 | `menu.gd:323–326` `boss_total` | 4 → **6**，否则 X/Y 出现 `6/4` |
| ② 显示名 | `menu.gd:329–330` 的 `name_of` Callable | 现为 `Data.ENEMIES[id].get("name", id)` → 两个新 id 不在 ENEMIES，会显示英文 id；需补中文名映射 |
| ③ 断言 | `SMOKE_CODEX`（`player.gd:865–899`） | 见 §3.6 |

> 用户收官答问已点名这条纪律：「`boss_total` 分母与 `_codex_id_valid` bosses 白名单**必须同步扩**」。本表把它扩成完整的三件套，并额外补上「显示名」这一处（实读发现的新第四处）。

### 3.4 旧档兼容（诚实权衡，不做隐式迁移）

旧 `codex.cfg` 里可能已有由熔潮主宰误写入的 `"boss"`。收窄白名单后 `"boss"` **仍是合法 ENEMIES 键**（巨岩虫之王），旧记录不会自动消失；且无法区分玩家是否真的击败过巨岩虫之王。

**裁定：不动旧档**，只保证新流程不再产生误登记，并在交付文档写明「历史档可能残留一条 `"boss"` 记录，不影响功能」。若用户要求清理，另提供显式一次性重置入口（**需单独授权**，禁止在 `load_codex` 里做隐式删除）。

### 3.5 E1 / E6 / 坑 5 / 冻结规格

零 `Game.rng` 消费（纯状态字段与映射）、零计时、`ACTION_DEFS` 与 `GEN_NAMES` 零新增、`meta.gd UNLOCKS` 不碰。本批改动落在 `boss.gd` / `boss2.gd` / `game_main.gd` / `game_state.gd` / `menu.gd` / `player.gd`（探针），冻结清单随批重定 **33/33**（无新脚本）。

### 3.6 探针（`SMOKE_CODEX` 扩三条，表外）

- 击杀 `PrismWarden` → `codex["bosses"]` 含 `prism_warden`；击杀 `boss2` → 含 `pyrothalassian`；
- **两者都不新增 `"boss"`**（防假阳性回归）；
- `boss_total == 6` 且两个新 id 的显示名为中文（防三件套缺项）。
- 取真实击杀证据可复用既有钩子：`SMOKE_FORCE_SOVEREIGN=1` 强制出熔潮主宰、`SMOKE_JUMP_FLOOR=11` 跳首领层（Sprint 12 收官批已实证口径；**注意跳层钩子吃层号数值，不是布尔开关**）。

---

## 四、阶段一 · 方向 B 完整规格（QA 加固批 / 在册清零）

| # | 在册项 | 修法 | 验收 |
|---|---|---|---|
| B1 | `bosses` 校验器未收窄 | 并入 §3.3 ②（不重复实施） | 非 Boss 敌人 id 登记被拒 |
| B2 | `load_codex` 钳制「实现保证、断言未覆盖」 | `SMOKE_CODEX` 补「手工写负数到 cfg → `load_codex()` → 值 `0`」；现 `:896–898` 只测 `set_codex_last_run` 路径 | 读档路径断言落地（新纪律「凡标 ✓ 必附证据」） |
| B3 | `last_run` 无键白名单 | `set_codex_last_run()` 只接受 `META.STATS_KEYS` 五项（`diamonds/kills/max_floor/time/score`），其余键忽略 | 注入越界键 → 快照不含 |
| B4 | `_enter_room` 早于 `_roll_calamity` 的起点房瞬间 | **推荐不动顺序**（挪 roll 会改 rng 时序，E1 有风险）；改为在 `validate` 加启动期断言「生成的 `shrine` 恒非 `Vector2i.ZERO`」+ 在 `_shrine_offers_for:1929` 的 purify 过滤旁补注释 | 零 E1 漂移，未来放宽房型时当场报错 |
| B5 | `Array.erase` 只删首个匹配 | `_roll_calamity:390` 加「同层不重复 append」守卫（或改 `while has: erase`） | 同层重复 roll 后 `calamity_floors` 无残留 |
| B6 | clear 末尾三 saved 值无条件重置 | `game_main.gd:449–451` 的重置移进 `if _calamity != ""` 内（零行为变化，纯语义收拢） | 空灾祸层 clear 前后 saved 保持不变 |
| B7 | 交付文档 `:37` 排版 | 把「结算覆盖层」bullet 移回 `SPR13_交付_阶段二.md:29` 之后；顺带把两条纪律条文归拢进交付文档（现只在主理人核验报告 `:68`/`:79`） | 纯文档，随下批提交 |

> B4 的取舍理由：`next_floor:1288–1291` 是 `_enter_room` → `_roll_calamity`，挪序会改 rng 消费顺序；而当前 `dungeon.gd` 保证 `shrine` 不落起点房，`purify` 过滤实际不受影响。**用断言锁住前提，比改时序更安全。**

---

## 五、阶段二 · 方向 C 完整规格（图鉴发现度被动 / Codex Boon）

### 5.1 设计意图

Sprint 13 的图鉴是纯局外沉淀，与局内循环没有反馈。C 把「发现度」变成**只读派生的开局加成**：收集越多，下一局起点略好。延续 Sprint 13 备注里「从内容堆叠转向决策深度 + 局外沉淀」的方向，且不新增任何 UI / action / rng。

### 5.2 数据表（`data.gd` 新增 `const CODEX_BOONS`）

| id | 分类 | 阈值 | 效果（一次性起始状态） | 建议数值 |
|---|---|---|---|---|
| `enemies_5` | enemies | 5 | 开局护盾 +1 | 1 |
| `relics_4` | relics | 4 | 开局源石 +3 | 3 |
| `themes_3` | themes | 3 | 生命上限 +1 | 1 |
| `bosses_2` | bosses | 2 | 附 1 条随机词缀（复用 `attach_suffix` + `stable_hash` 派生，零 rng） | — |

- `Game.codex_boons()` 纯只读函数：遍历 `CODEX_BOONS`，按 `Game.codex[kind].size()` 判定阈值，返回生效加成字典。**零写入、零 rng**。
- 阈值与数值全部 data 驱动，便于后续调优（沿用 Sprint 13 E 的 `ECHO_TUNING` 范式）。

### 5.3 注入点与 E1（实读）

- 挂 `game_main.gd:347 _apply_sigil_contract()` **同段之后**、`Game.rng` 任何绘制之前（`:350` `run_seed` 之前）。Sprint 11 C 已验证该位置「只改起始状态、不改 rng 消耗顺序」→ **E1 零漂移**。
- `Game.codex` 在 `game_state.gd:97 _ready` 已 `load_codex()`，注入时数据就绪。
- `_smoke_fingerprint` 不含起始状态 → 指纹不变；但**须在交付文档登记**：图鉴档不同会改变起始状态（局外输入），同 seed 双跑仍逐字一致。

### 5.4 ⚠️ 效果载体硬约束（Sprint 12 #2 教训）

**禁用** `diamond_mult` / `mag_cap_mult` / `calamity_speed_mult` 等全局倍率作为 boon 载体——`_roll_modifier()`（`:355`）、`_roll_calamity()`（`:358`）与 `_clear_calamity_effects()` 会重置或覆盖它们，Sprint 12 #2 正是「换层无条件 `diamond_mult=1.0` 抹掉整局倍率」的实害缺陷。

**只允许一次性起始状态增量**：`shield_charges` / `player.max_hp` / `Game.diamonds` / `attach_suffix`。全部复用既有接口，不新写计算路径、不新增计时（E6 无涉）。

### 5.5 冻结规格边界

平行**只读派生**：不写 `meta.gd`、不进 `UNLOCKS` 表、不做解锁判定、不改 `STATS_KEYS`。图鉴档与解锁档互不引用。

### 5.6 探针 `SMOKE_CODEX_BOON`（表外）

- 构造三档发现度 → 断言加成字典确定性、阈值边界（`need-1` 不生效 / `need` 生效）；
- 断言**起始状态实际落地**（读 `shield_charges` / `max_hp` / `diamonds`，不只验返回的字典 —— 沿用「必须验数值、不能只验标志」）；
- 断言同 seed 双跑 `_smoke_fingerprint` 逐字一致（零 rng 消费）；
- 断言全局倍率类载体零命中（防 §5.4 回归）。

---

## 六、备选 / 不接口径

- **D 武器淬炼**：`weapons.gd:11 const DEFS` 参数即弹道，`player.gd:392/394/425/492` 开火路径 rng 密集，且 `weapons.gd:79/89` 有 `meta_content_unlocked` 门控。若并入须先列全伤害路径 rng 消费、预期 E1 重定 → **单独成批**。
- **E 每日深化**：`daily_seed` 注入在 `start_run:340–342`、早于首抽（现状零漂移）；若加「每日固定词缀」会改 `:347` 之后的 rng 顺序 → 基线重定。复用度高但边际递减 → **备选**。
- **F 第三 Boss / 主题扩容**：**明确不接**，理由见 §一。
- **G `玩法说明.md`**：主理人职权，不占编程侧车道；补到 Sprint 13 收官状态（圣所三选一 / 图鉴复盘 / 灾祸层 / 每日挑战 / 双主题 Boss / 9 印记 / 7 编队 / HUD 字号档 / 主题色盲标记）。

---

## 七、验收四门控（quality-lead 口径）

1. **回归纪律**：`SMOKE+V8+REBIND+RELIC+SUFFIX+META+PERSIST+BOSS+BOSS2+ECHO+DAILY+CALAMITY+SHRINE+CODEX+CODEX_BOON` 跑 6000 帧 **0 报错**；冻结清单随批重定 **N/N**；E1 指纹双跑逐字一致。
2. **E6 合规**：grep 确认零新增 raw delta / 计时；A、B、C 三方向均无 `_process` 新增。
3. **E1 非污染**：A 零 rng、B 零 rng、C 注入在首抽前且零 rng；`SMOKE_*` 表外不进 diff（坑 45）；`ACTION_DEFS` 零新增、`GEN_NAMES` 若有新资源须同步登记（坑 5）。
4. **🆕 登记三件套逐项打勾**：A 的 ① 写入 / ② 白名单 + 分母 + 显示名 / ③ 三条探针断言，在交付文档中列表核对；C 的「数据表 → 注入函数 → 起始状态断言」同样列表核对。**只验中间状态不算过**。
5. **探针**：`SMOKE_CODEX`（扩）、`SMOKE_CODEX_BOON`（新），均表外；沿用「断言 + [ERR] + done 落地」门控范式（Sprint 12/13 已四次当场拦下解析错与假断言）。

---

## 八、两阶段落地顺序（编程侧）

**阶段一（A + B）**
1. 先读 §3.1 确认隐性路径，落 `codex_id` 字段与 `on_slug_killed` 分支改写（不动 `variant`）。
2. 按 §3.3 同步扩白名单 / 分母 / 显示名 / 断言（三件套一次做齐）。
3. B2–B6 六条加固 + B7 文档排版。
4. 四门控 → 冻结重定 → 交付文档 → **单独提交**。

**阶段二（C）**
5. `CODEX_BOONS` 表 + `Game.codex_boons()` + `:347` 同段注入 + 起始状态落地。
6. `SMOKE_CODEX_BOON` → 四门控 → **单独提交**。

**并行（主理人）**：G `玩法说明.md` **已校准落盘**（标题 / 主菜单按钮 / 设置项 / 8 主题 / 灾祸层 / 共鸣口径就地订正 + 文末「Sprint 10–13 增补」），与本草案同为未跟踪文件，待授权随下批文档整理提交。

---

## 九、主理人备注（规划侧内部，编程侧可略）

- **本批最大价值不在加内容，而在 §3.1 这条隐性路径**：Sprint 13 收官时双方都接受「两个主题 Boss 不走 `on_slug_killed`」，但 `boss.gd:335` 一直有这个调用，`boss2.variant="boss"` 让登记**已经在悄悄发生**。若按原注记直接「加个挂点」，会变成重复登记 + 假阳性残留。这也再次印证新纪律：**范围注记同样要附实读行号**。
- **C 方向把局外沉淀接回局内**，是 Sprint 13 之后唯一不靠「再堆一个系统」就能提升长期动机的路径；且注入点、载体约束、E1 口径全部来自已实读的既有代码，风险可控。
- **用户收官答问里点名的两条纪律已落进本草案**：三件套（§〇.7 / §3.3）比原口径多补了「显示名」与「可见断言」两处；读档钳制断言落在 B2。
- 锁定范围已由用户裁定为 **A + B + C**（阶段一 A+B、阶段二 C，G 主理人并行已完成）；D/E 备选未接、F 永不接。主理人侧不写 `.gd`，落地后按流程读码核验。
