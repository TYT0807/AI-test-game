# Sprint 13 规划草案（主理人 / 规划侧合成）

> 来源：主理人综合，沿用 Sprint 10–12 已沉淀的非编程专家口径（design-strategist 玩法 / art-director 美术 / audio-director 音频 / quality-lead 验收）；本批为规划侧直接合成，**未逐项 spawn**，故不标注四专家实稿。
> 本文为**自包含规格**，编程侧据锁定范围实现；主理人侧不写任何 `.gd`（只读核验 + 文档维护）。
> 基线：Sprint 12 **已正式收官**（功能门 final PASS）。git 九个提交在册，最新 `953ab61`；冻结 `SPR7-FROZEN-4.md5` **32/32 OK**（`md5sum -c` 实校）；32 个 `.gd` / 单场景 `scene/game.tscn`。
> 已冻结可复用的系统：`SIGILS` 9 枚 / `SQUADS` 7 模板 / `RELIC_SUFFIXES` 8 条 / `ACTIVE_RELICS` 4 条 / `FLOOR_THEMES` 8 主题 / `PrismWarden`+`boss2` 继承骨架 / 每日挑战 `stable_hash`（标准 FNV-1a 32 位）/ 灾祸层条件还原 / 回响 + 协战实体 / `ROOM_META` 10 房型。

---

## 〇、跨批铁律（任何新内容必须遵守）

1. **E6 固定步**：所有新增计时走 `Game.FIXED_DT`，禁 raw `delta`（Sprint 10 起铁律）。
2. **E1 确定性指纹**：核心循环不无故新增 `Game.rng` 消费；表外验证探针 `SMOKE_*` 不进 E1 diff（坑 45）；动 rng 前先想清是否漂移基线，预期代价须登记 + 随批重定。
3. **复用优先**：新内容挂既有表/接口/实体，不另起炉灶。本批尤其吃 `ROOM_META` 与 `upgrade_panel.gd` 的现成红利。
4. **坑 5 护栏**：`assets.gd` `ACTION_DEFS`（:328–348，动作总表）**不加新 action**。本批三选一交互复用已注册的 `card_1` / `card_2` / `card_3`（KEY_1/2/3，可重绑），零新键。
5. **冻结规格不可改**：`Sprint7_解锁树规格.md` v2.10 冻结 → `meta.gd UNLOCKS` 表**不动**；新局外内容一律做平行页。
6. **批次流程**：实施 → 三层验证 → 冻结重定 → 交付文档 → **单独提交**（每阶段一个 commit，不回头补）。

---

## 一、候选方向（A–G）

| 方向 | 规模 | 内容 | 风险 / 裁定 |
|---|---|---|---|
| **A. 抉择圣所 / Choice Shrine** | M | 新增第 11 种房型 `shrine`：进房 3 选 1 的**状态交换**决策（血换遗物 / 源石换升级 / 净化灾祸 / 护盾补给 …），把「清房→开门」的单调层循环插入一个构筑决策点 | 中低。**挂接点已被 `ROOM_META` 注释明示**；复用三卡面板 + 1/2/3 键 → **推荐核心项** |
| **B. 武器淬炼 / 词条** | M | 复用 `weapons.gd` / `upgrades.gd`，给武器挂词条（穿透/暴击/溅射） | 中：直接改伤害计算路径，易引 raw delta / E1 漂移 → **备选** |
| **C. 地窖图鉴 / 局末复盘** | M | 局外只读页：记录已遇敌人 / 遗物 / 主题 / Boss / 最高层 / 每日最佳 + 本局复盘摘要；独立 `user://codex.cfg` 双档 | 低：纯局外、零 rng、不碰 `UNLOCKS` → **推荐沉淀项** |
| **D. 每日挑战深化** | M | 种子分享码 + 每日固定词缀组合 + 本地榜扩展 | 低，但与 Sprint 12 D 重复度高、边际递减 → **备选** |
| **E. 表现层打磨批** | S | 清零在册三条遗留：回响数值 data 驱动 / 地窖背景板（art 预留）/ audio 事件表 + HUD 可访问性 | 极低，走 `fx_rng` 零 E1 影响 → **推荐顺手清** |
| **F. 第三 Boss / 主题扩容** | L | 再来一个 Boss，或 `FLOOR_THEMES` 8→12 | **不接**：8→12 会改 `phase_theme_index` 的 `%8` 与 Boss 三阶段主题序列 → E1 全面重定；第三 Boss 边际递减 |
| **G. 局末统计页** | S–M | 伤害来源 / 路线 / Build 摘要 | 与 C 重叠 → **并入 C** |

## 二、优先级裁定（主理人推荐，用户可自带微调）

- **本批建议全锁 A + C + E**；**F 明确不接**；B / D 列为备选（若你要加进来，规格见 §七，可原样并入阶段二）。
- **分两阶段交付**：
  - **阶段一（先交）**：**A 抉择圣所 + E 打磨批** —— 一个核心玩法增量 + 一次把在册遗留清零，接口已锁、风险最低。
  - **阶段二（紧随）**：**C 地窖图鉴 / 局末复盘** —— 局外沉淀，与阶段一零耦合。
- 设计裁定项 **dash option b 保持现状**（196–210px，120 直驱 + 碰撞挤出作为手感特性），本批不改造、不阻塞；若后续要纯传送语义请单列一批。

## 三、锁定批次组合

| 阶段 | 方向 | 交付物 |
|---|---|---|
| 一 | A（M）+ E（S） | `shrine` 房型 + 三选一抉择 + 打磨批（回响数值/背景板/音频/HUD） |
| 二 | C（M） | `codex.cfg` + 图鉴页 + 本局复盘 |

---

## 四、方向 A 完整落地规格（抉择圣所 / Choice Shrine）

### 4.1 数据表
- `data.gd` `ROOM_META`（:294–305）**追加一条**：`"shrine": {"name": "圣所", "color": Color(...), "bgm": 0, "mark": "+"}`。注释已明示「加新房型 = 这里一条 + game_main 生成/清场各一个分支」。
- `data.gd` 新增 `const SHRINE_OFFERS := {...}`（6–8 条，schema：`id / name / desc / cost_kind / cost / effect / min_floor`）。初版建议：
  | id | 效果（全部复用既有接口） | 代价 |
  |---|---|---|
  | `blood_relic` | 掉 1 件遗物（`drop_pickup(..., "relic", 1, id)`） | `player.take_damage(1, ...)` 或 `max_hp -1`（保底 1） |
  | `ore_upgrade` | 触发一次升级三选一（复用 `upgrade_panel.gd` 既有路径） | `Game.diamonds -= 8` |
  | `purify` | 清除本层灾祸（`_calamity=""` + `_clear_calamity_effects()`） | 本层 shards ×1.5 倍率作废（`calamity_floors` 剔除当层） |
  | `ward_boon` | `player.shield_charges += 1` | `Game.diamonds -= 5` |
  | `heal` | `player.heal(2)` | `Game.add_score(-100)` 或 `max_hp -1` |
  | `relic_suffix` | 随机附 1 条词缀到已有主动遗物（复用 `attach_suffix`） | `player.take_damage(1, ...)` |
- **不做赌局 / 不做概率奖励**：所有选项为纯状态交换，零新增 rng（理由见 4.5）。

### 4.2 房间生成（`dungeon.gd`）
- 在 `generate()` 的死端分配段（:91–99，现把 `dead_ends[0]` 设 treasure、`[1]` 设 shop）之后，**每层从非死端 combat 房中挑 1 个改为 `shrine`**；`min_floor >= 3` 才出现（低层不打扰新手）。
- 房间坐标与总数**不变**（只改 `kind`），避免地图布局结构变动；但 `_smoke_fingerprint` 输出会变 → **E1 指纹随本批重定，属预期代价，须登记**。
- 复用既有 `info["cleared"]` / `skip_loot` 防重入标记范式（参照 :1119–1126 宝箱/商店写法），保证离房再进不重复发选项、不重复扣代价。

### 4.3 `_enter_room` 两分支（`game_main.gd`）
- `:1055 match kind` 的**已清房组**（现 `"start","treasure","shop","secret","super_secret"`）追加 `"shrine"` → 进房即 `room_state="cleared"`、门不锁，保持「可自由离开」的非战斗房语义。
- `:1116 match kind` 追加 `"shrine":` 生成分支：调 `_open_shrine(coord)` → 三选一面板 + 一条 banner + `_milestone("first_shrine")`（`MILESTONES` :281–290 加一条）。
- **`on_slug_killed` / `_room_cleared` 不动**：圣所无敌人，不参与清场结算。

### 4.4 交互与 UI（坑 5 零新 action）
- **复用 `upgrade_panel.gd`**（276 行，已实现三卡布局 + `card_1/2/3` 键位门控 + 暂停/遮罩）参数化为三选一抉择面板：传入 3 个 `SHRINE_OFFERS` 条目、回调执行 `effect`；具体接口由编程侧读码确认后做最小参数化，**不新写一套 UI**。
- 若该面板耦合升级池过深，退路是复用其**键位门控 + 卡片渲染**，新增一个薄 `shrine_panel` 分支；两条都**不加 `ACTION_DEFS` 条目**。
- 选择后：`info["cleared"] = true` + 关面板 + 一次性扣代价/发效果 + 打印表外探针。

### 4.5 E1 零漂移（关键约束）
- **三张卡的选项集合**由纯函数派生：`idx = Game.stable_hash("%d_%d_%d" % [Game.run_seed, Game.floor_num, coord.x*1000+coord.y]) % SHRINE_OFFERS.size()`，取 3 个不重复索引（复用 Sprint 12 收官批已实装的标准 FNV-1a 32 位 `stable_hash`）。
- **零 `Game.rng` 消费**：同 seed + 同层 + 同房坐标 = 同三选一，跨「解锁档 / 默认档」一致。
- 奖励执行复用既有接口（`drop_pickup` / `Upgrades` / `Game.add_diamonds` / `player.take_damage`）；若某效果走既有 rng 路径（如升级三选一抽卡），属**玩家驱动的既有路径消费**，不新建 rng 流，登记即可。
- **验收口径**：`SMOKE_SHRINE` 表外探针打印三卡 id + 派生 key，两次同 seed 逐字一致；`SMOKE_*` 不进 E1 diff（坑 45）。

### 4.6 E6 / 其它
- 抉择**不做限时**（避免引入计时）；若加动效/渐隐，一律 `Game.FIXED_DT` 或 `create_tween`（表现层，不计入玩法计时）。
- 代价扣减前校验余额/血量，不足则该卡置灰不可选（防负数、防 `take_damage` 打死玩家）；`purify` 在无灾祸层不出现（生成时过滤）。
- 美术：圣所贴图复用既有 `prop` / `totem` / `icon_suffix` 资源，零新美术依赖；音效复用 `Game.sfx("secret")` 或 E 批补的别名。

## 五、方向 C 完整落地规格（地窖图鉴 / 局末复盘）

- **持久**：新增 `user://codex.cfg`，沿用 `sigils.cfg` / `daily.cfg` 的 ConfigFile 双档范式（`CODEX_PATH` + `CODEX_SMOKE_PATH`，经 `SMOKE_CODEX_PATH` 环境变量切隔离档）；`load/save` 加 **未知 id 过滤 + 负数钳制**（参照 `load_sigils` :238–255 的防穿透写法）。
- **记录点（纯读取，零 rng）**：`spawn_slug`（敌人 id）、`drop_pickup("relic"/"suffix")`（遗物/词缀）、`_apply_floor_theme`（主题 rule）、`on_slug_killed`（Boss variant，含 `"boss"`）、`_settle_meta`（最高层 / 分数 / 用时）。统一走轻量 `Game.mark_codex(kind, id)`，不改上述函数的返回契约。
- **主菜单**：复用 `menu.gd` `_build_sigils` 的**遍历渲染范式**加「图鉴」页（分类 Tab + 已发现/未发现计数）；只读、无购买逻辑 → **不碰 `meta.gd UNLOCKS`**（冻结规格 v2.10）。
- **局末复盘**：复用 `_run_stats()`（`meta.gd STATS_KEYS` 已登记 `diamonds/kills/max_floor/time/score`）扩展一层「本局摘要」展示，不新增 STATS_KEYS 之外的统计源。
- **E1**：完全局外、零 rng、零 E1 影响；`SMOKE_CODEX` 表外探针验「记录 → 存盘 → 读回一致 / 未知 id 被忽略 / 隔离档不污染主档」。

## 六、方向 E 完整落地规格（打磨批 / 在册遗留清零）

| 遗留 | 落地 | 风险 |
|---|---|---|
| 「回响」数值调优 | 镜像 2.5s、击败增益 1.35×2s 等提为 `Data.ECHO_TUNING` 常量（data 驱动），**零逻辑改动** | 零 |
| 地窖背景板（art 预留） | 地窖/主菜单背景层，纯表现层资源，走 `fx_rng`（若需随机纹理偏移） | 零 E1 |
| audio 事件表补全 | 复用 `assets.gd` 的 SFX 别名注册，给圣所 / 图鉴 / 灾祸补事件（与 A/C 同批） | 零 |
| HUD 可访问性 | 主题色旁加符号标记（色盲友好）、字号选项复用 `apply_ui_settings` | 低 |
| dash option b | **保持 196–210px**，本批不动（设计裁定，非缺陷） | — |

## 七、备选 / 不接方向口径

- **B 武器淬炼**：若并入，须先把伤害计算路径的 rng 消费列全、所有新计时走 FIXED_DT，且预期 E1 重定；建议单独成批，不与 A 同批。
- **D 每日深化**：可直接复用 `daily_seed` / `stable_hash` / `calamity`，但若加入「每日固定词缀」会改变 `start_run` 的 rng 消费顺序 → 需基线重定；性价比低于 C。
- **F 第三 Boss / 主题扩容**：**明确不接**（§一）；尤其 `FLOOR_THEMES` 扩容会破坏 `phase_theme_index` 的 `%8` 与两个 Boss 的三阶段主题序列。

## 八、验收四门控（quality-lead 口径，复用 Sprint 12）

1. **回归纪律**：`SMOKE+V8+REBIND+RELIC+SUFFIX+META+PERSIST+BOSS+BOSS2+ECHO+DAILY+CALAMITY+SHRINE+CODEX` 跑 6000 帧 **0 报错**；冻结清单随本批重定（N/N，含新脚本/扩表），E1 指纹因新房型重定须登记。
2. **E6 合规**：grep 确认 A 面板动效、C 无计时、E 表现层新计时全 `Game.FIXED_DT`，无 raw delta。
3. **E1 非污染**：SHRINE 三卡由 `stable_hash` 派生、**零 `Game.rng` 消费**（同 seed 逐字一致）；C 局外零 rng；`SMOKE_*` 表外不进 diff（坑 45）；`ACTION_DEFS` 零新增（坑 5）。
4. **探针设计**：新增 `SMOKE_SHRINE`（三卡确定性 / 各 6 效果各跑一遍 / 代价不足置灰 / 重入不重复扣）、`SMOKE_CODEX`（记录往返 / 未知 id 忽略 / 隔离档不串），均表外；沿用 `SMOKE_SIGIL_COVERAGE` 的「断言 + [ERR] + done 落地」门控范式（Sprint 12 已证明它能当场拦下 Variant 推断解析错）。

## 九、两阶段落地顺序（编程侧）

**阶段一（A + E）**
1. `ROOM_META` 一条 + `SHRINE_OFFERS` 表 + `dungeon.gd` 房型分配。
2. `_enter_room` 两分支 + 参数化三卡面板（`card_1/2/3` 复用、零新 action）+ `_open_shrine`。
3. E 打磨批四项（回响常量 / 背景板 / 音频别名 / HUD 可访问性）。
4. 跑四门控 + 冻结重定 + 交付文档 + **单独提交**。

**阶段二（C）**
5. `codex.cfg` 双档 + `mark_codex` 记录点 + 主菜单图鉴页 + 本局复盘。
6. 跑四门控 + 单独提交。

## 十、主理人备注（不进转发文本）

- 本批定位 = **从「内容堆叠」转向「决策深度 + 局外沉淀」**：Sprint 10–12 已把内容量堆足（9 印记 / 7 编队 / 2 Boss / 8 主题 / 每日 / 灾祸），再堆同类内容边际递减；A 给每层一个非战斗决策点，C 给长期目标，E 清在册遗留。
- **A 的最大红利是坑 5 安全**：`card_1/2/3` 已注册且可重绑，三选一 UI 有 `upgrade_panel.gd` 现成骨架，房型有 `ROOM_META` 明示三处挂点 —— 复用彻底、风险可控。
- **A 的最大风险是 E1**：新房型会改 `_smoke_fingerprint`；故 4.5 强制选项集合走 `stable_hash` 纯派生、零 `Game.rng`，把漂移面压到「房型本身」这一项并登记重定。
- `meta.gd UNLOCKS` 属冻结解锁树规格 v2.10，**任何方向都不得改**；C 做平行只读页即为此。
- 文档为推荐锁定组合，用户可自带微调（加 B/D 或改阶段划分）；主理人侧不写 `.gd`，落地后按流程读码核验。
