# Sprint 16 规划草案（主理人 / 规划侧合成）

> 来源：主理人实读挂接点后合成；设计成员 `design-strategist` 的候选实稿**并行在途**（目标 `production/sprint-16/SPR16_设计候选实稿.md`），回传后作为附录并入、可能调整候选评级，**不阻塞本草案的锁定与转发**。
> 本文为**自包含规格**；主理人侧**不写任何 `.gd`**（只读核验 + 文档维护）。
> 基线（本轮实校）：`git log -1` = `38535f3`；`git status --short` 空；`md5sum -c` **exit 0 / 34 OK / 0 FAILED**；**34 个 `.gd`**；单场景 `scene/game.tscn`。Sprint 15 收口批 `0724aad` 与版本注订正 `38535f3` 已完成，**可做项清零**。
> **锁定范围（用户 2026-11-08 裁定「全部」）**：**A + B + C + D + E + F 全锁**，分**三阶段**交付（见 §二）。⚠️「全部」指候选方向 A–F，**不含 §〇 的技术红线**：`FLOOR_THEMES` 8→12 永不接、`CODEX_BOONS.kind` 禁 `suffixes`、主题 Boss `variant="boss"` 不可改、`meta.gd UNLOCKS` v2.10 不动、`ACTION_DEFS` 零新 action、`_tick_buffs` / `toxic_cloud` 既有豁免别动。红线不因全锁放开。
> 已冻结可复用系统：`ROOM_META` 11 房型 / `SHRINE_OFFERS` 10 条 / `SIGILS` 9 枚 / `SQUADS` 7 模板 / `RELIC_SUFFIXES` 8 条 / `ACTIVE_RELICS` 4 条 / `FLOOR_THEMES` 8 主题 / 三主题 Boss / 灾祸层 / 每日挑战 / `codex.cfg` 五类发现集 + `last_run` / `CODEX_BOONS` 4 档 / 三卡面板 `shrine_panel.gd` / `stable_hash` FNV-1a。

---

## 〇、跨批铁律（沿用 Sprint 15，任何新内容必须遵守）

1. **E6 固定步**：计时 / DoT / 冷却走 `Game.FIXED_DT`，禁 raw `delta`。⚠️ `player._tick_buffs(delta)` 与 `toxic_cloud` 敌方云是**既有在册豁免**（`HANDOFF_技术接手包.md` §3），顺手统一会改 E1 基线，**别动**。
2. **E1 确定性**：核心循环零新增 `Game.rng` 消费；`SMOKE_*` 表外不进指纹（坑 45）；`_smoke_fingerprint` 只含 rooms 坐标 + kinds —— **新增房型必然改指纹，须登记为预期代价并随批重定**。
3. **复用优先**：挂既有表 / 接口 / 实体，不另起炉灶。
4. **坑 5**：`assets.gd` `ACTION_DEFS`（`:333–`）不加新 action；新资源走 `Assets.g()` 必须同步登记 `GEN_NAMES`（`:109–132`）。三选一交互复用已注册的 `card_1/2/3`。
5. **冻结规格 v2.10**：`meta.gd UNLOCKS` 不动；局外内容一律平行只读派生。
6. **批次流程**：实施 → 四门控 → 冻结重定 → 交付文档 → **单独提交** → 主理人读码核验。每批一个 commit。
7. **登记三件套**：新增 id / 资源 / 记录点须同时核对 ① 写入 ② 注册表·白名单·UI 分母·显示名 ③ 可见效果断言（**验数值，不能只验标志**）。
8. **boon 红线**：`CODEX_BOONS[*].kind` 不得为 `suffixes`；若产品确需 suffixes 阈值，须改用「不回写图鉴的内部绑定路径」并重做 `validate` P0 门。
9. **其它既定红线**：`FLOOR_THEMES` 8→12 **永不接**（四处周期来源不一致）；主题 Boss `variant="boss"` 严禁改（图鉴登记一律走 `codex_id`）；dash 保持 196–210px；终审附章休眠。
10. **纪律**：凡标 ✓ 必附**本轮实读**证据；commit 号与行号一律以 `git log` / 文件实读为准，**不采信文档里的快照**（Sprint 15 汇编已踩过基线漂移）。

---

## 一、候选方向（A–F）

| 方向 | 规模 | 内容 | 风险 / 裁定 |
|---|---|---|---|
| **A. 遭遇事件房 `event`** | M | 第 12 房型：进房三选一的「**风险换信息 / 路线**」决策（预告本层主题、揭示秘密房方位、交换房奖、以代价换地窖碎片等），与 `shrine` 的「代价换资源」形成互补 | 中：复用三卡面板与 `stable_hash` 零 rng，但**改 room kinds → 指纹重定** → **推荐阶段一核心增量** |
| **B. 图鉴里程碑 / Codex Milestones** | S–M | **联动型增量**：把已有的图鉴五类发现集、boon 四档、只读页串成一层「局外目标」——发现度阈值在图鉴页亮起徽章、结算页加一行进度；纯只读派生，不写 `UNLOCKS`、不新增 rng | 低：零 E1、纯展示 → **推荐阶段二** |
| **C. 在册遗留收口** | S | `_third_boss_probe` 直调 `on_slug_killed` 的副作用隔离（+2000 分 / 掉 8 次源石 / 消费一次 rng）；SMOKE 钩子清单文档化；断言性质标注抽查 | 零风险 → **推荐阶段一顺手清** |
| **D. 武器淬炼**（备选转正） | M–L | `weapons.gd:11 DEFS` 加词条层 | **高**：`player.gd` 开火路径 rng 密集（`:392/394/425/492`），E1 基线重定 → **备选，不同批** |
| **E. 每日深化**（备选转正） | M | 种子分享码 / 本地榜（纯局外低风险）；**「每日固定词缀」会改 `start_run:340–345` 的 rng 顺序** → 基线重定 | 中：只做分享码/榜可零 E1 → **备选** |
| **F. 发现口径翻案** | S | 把 `relics` 登记从 `drop_pickup` 掉落时（`game_main.gd:1706–1707`）改挂 `pickup.gd:108 _apply` 拾取时 | Sprint 15 已裁定「已见遗物」零代码方案，**不建议翻案** → 备选 |

> **明确不做**：① `FLOOR_THEMES` 扩容与第三 Boss 之外的第四 Boss（边际递减 + 周期红线）② 给 `CODEX_BOONS` 加 `suffixes` 阈值（自激红线，除非重做 P0 门）③ 顺手统一 `_tick_buffs` 到 FIXED_DT（既有豁免，会改 E1 基线）。

## 二、锁定组合（用户已裁定：A–F 全锁，三阶段）

| 阶段 | 方向 | 交付物 | 基线代价 |
|---|---|---|---|
| 一 | **A（M）+ C（S）** | 第 12 房型 `event` + 在册遗留收口 | **重定 #1**：新 `kind` 改 `_smoke_fingerprint`；若新增 `event_panel.gd` 则 34→35 |
| 二 | **B（S–M）+ F（S）** | 图鉴里程碑 + 发现口径改挂拾取路径 | 零 E1（纯只读 / 纯登记挂点迁移），冻结分母不变 |
| 三 | **D（M–L）+ E（M）** | 武器淬炼 + 每日深化 | **重定 #2**：D 改伤害路径 rng 消费、E 改 `start_run` rng 顺序；**两者各自单独提交**，不混批 |

**全锁代价（须在交付文档逐批登记）**：
1. 共三阶段、**至少两次基线重定**，每阶段单独 commit，不回头补；
2. D 与 E 虽同为阶段三，但**必须拆成两个 commit**——两类 E1 漂移混在一起会无法定位；
3. F 是口径翻案（Sprint 15 曾裁定「已见遗物」零代码方案），须同步改 UI 文案、移除 `drop_pickup` 登记、在 `pickup.gd` 新增登记，并走完整三件套；
4. 冻结分母可能 34 → 35（`event_panel.gd`）→ 36（若 D 新增脚本），每批随批重定；
5. 设计成员 `design-strategist` 实稿回传后并入附录；若其候选优于现有某方向，**由用户裁定是否替换**，主理人不擅自改锁定范围。

---

## 三、方向 A 完整规格：遭遇事件房 `event`

### 3.1 挂接点（本轮实读，行号基于 `38535f3`）

| # | 落点 | 动作 |
|---|---|---|
| ① 表 | `data.gd:296 ROOM_META`（现 11 条，`:307` 是 `shrine`） | 追加 `"event": {"name":"遭遇", "color":..., "bgm":0, "mark":"?"}` —— 注意 `mark` 避开已用的 `?`（`secret`），建议 `"E"` |
| ② 生成 | `dungeon.gd:138–146` 现有 `shrine_pool` 分配段 | 从**剩余**非起点 `combat` 房中确定性挑 1 间改 `event`；`floor_num >= 3` 门槛沿用；只改 `kind`，不动坐标与总数；**零 `Game.rng` 消费**（同 `shrine` 范式） |
| ③ 已清组 | `game_main.gd:1078` 现 `"start","treasure","shop","secret","super_secret","shrine"` | 追加 `"event"` → 进房即 `room_state="cleared"`、门不锁，非战斗房语义 |
| ④ loot 分支 | `game_main.gd:1149 match kind` / `:1164 "shrine":` | 追加 `"event":` 分支：`if not skip_loot: _open_event(coord)`；选后写 `info["cleared"]=true`，重进不重复发（宝箱/商店/圣所同范式） |
| ⑤ 校验 | `validate.gd:36 _check_rooms` / `:53 _check_shrine` | `KNOWN_ROOM_KINDS` 追加 `"event"`；参照 `_check_shrine` 加 5 层抽样断言：`floor<3` 零间、`floor>=3` 恰 1 间、且**恒非 `Vector2i.ZERO`**（B4 前提守卫） |
| ⑥ UI | `shrine_panel.gd:7 signal chosen` / `:109 open(offers)` / `:171 _pick` | **薄封装复用**：新建 `event_panel.gd` 或给 `shrine_panel` 加一个 `mode` 参数；复用 `card_1/2/3` 键位门控与置灰，`ACTION_DEFS` **零新增** |

### 3.2 数据表与语义

- `data.gd` 新增 `const EVENT_OFFERS`（6–8 条），schema 复用 `SHRINE_OFFERS`：`id / name / desc / cost_kind / cost / min_floor`。
- **与圣所的区分（设计要点）**：圣所 = 用确定代价换确定资源；遭遇 = 用**信息或路线自由度**做决策。建议初版：
  | id | 效果 | 代价 |
  |---|---|---|
  | `omen` | 预告本层 Boss 与主题（纯 HUD 提示，零 rng） | 积分 -40 |
  | `seek` | 在小地图揭示秘密房方位（纯表现层） | 生命上限 -1 |
  | `reroute` | 交换本层两间未清房的奖励类型（只改 `kind` / `cleared` 标记） | 源石 -6 |
  | `shard_pact` | 地窖碎片 +4（复用 `Game.add_shards`） | 当前生命 -1 |
  | `insight` | 图鉴登记一条本层主题（复用 `mark_codex`，走三件套） | 积分 -30 |
- **全部纯状态交换 / 纯只读提示，零赌局、零新增 rng**。三卡由 `Game.stable_hash("%d_%d_%d" % [run_seed, floor, coord])` 派生（与圣所同 key 会撞，须加前缀如 `"event_"`）。
- 代价不足置灰（面板 `open()` 内置 `_shrine_affordable` 同款校验 + 主侧双保险）；`purify` 类依赖灾祸状态的选项不要放进事件池。

### 3.3 E1 / E6 / 坑 5 / 冻结

- **E1 预期代价（必须登记）**：新房型改变 `dungeon.rooms[*].kind` → `_smoke_fingerprint` 输出变化 → **随批重定基线**；但选项集 `stable_hash` 纯派生、零 `Game.rng`，漂移面压到「房型本身」这一项（Sprint 13 A 同款口径）。
- 零计时（E6 无涉）；`ACTION_DEFS` / `GEN_NAMES` 零新增（坑 5）；`meta.gd UNLOCKS` 不碰。
- 冻结：若新增 `event_panel.gd`，**34 → 35**，随批重定；若采用薄参数化复用则不增脚本，仍 34/34。

### 3.4 探针 `SMOKE_EVENT`（表外）

- 三卡确定性（同 seed 同层同坐标逐字一致、不同坐标不同集）；
- 六效果逐条验**数值**（积分 / 生命上限 / 源石 / 碎片 / 图鉴集合实际变化，不只验标志）；
- 代价不足置灰；重入不重复扣/发；`floor<3` 不出现、每层恰 1 间、恒非起点房；
- 同 seed 双跑指纹逐字一致（重定后的基线）。

---

## 四、方向 B 完整规格：图鉴里程碑（联动型）

### 4.1 设计意图

图鉴已有五类发现集 + `codex_boons()` 只读派生 + 只读页 + 局末复盘，但**玩家看不到「还差多少、下一个目标是什么」**。B 不新增系统、不新增存档，只把已有数据投影成里程碑，把「收集」从被动记录变成有目标的长期动机（自我决定论：胜任感）。

### 4.2 挂接点（本轮实读）

| 落点 | 动作 |
|---|---|
| `data.gd` 新增 `const CODEX_MILESTONES` | 阈值表：`{kind, need, text}`，纯数据 |
| `game_state.gd:373 codex_boons()` 同款 | 加 `func codex_milestones() -> Dictionary`：**纯只读**派生，遍历表比对 `codex[kind].size()`，不写盘、不消费 rng |
| `menu.gd:308 _build_codex()` / `:347 _codex_section()` | 每分区在进度条下加「下一里程碑：还差 N」与已达成徽章（纯 Label，零新 PNG） |
| `menu.gd:236 show_page` | 可选：加一个只读「里程碑」页；不建议新页，先做分区内嵌，避免范围蔓延 |
| `hud.gd` 结算覆盖层 | 追加一行「图鉴进度 · 下一目标 …」（复用现有 `_stats_label` 范式） |
| `validate.gd:54 _check_codex()` | 加启动期断言：里程碑表的 `kind` 必须在 `CODEX_KINDS` 内（防三件套缺项） |

### 4.3 硬约束

- **与 boon 明确区分**：boon 是局内起始加成，里程碑**纯展示、不给任何数值**，避免玩家误以为解锁了什么；文案须写「记录」而非「解锁」。
- **不碰 `meta.gd UNLOCKS`**（冻结 v2.10），不新增 `STATS_KEYS`，不改 `codex.cfg` 结构。
- 零 `Game.rng`、零计时、零 `ACTION_DEFS`；**E1 零影响，指纹不变**。
- 三件套：① 阈值表 ② `CODEX_KINDS` 校验 + 菜单渲染 ③ `SMOKE_CODEX_MILESTONE` 断言（阈值边界 `need-1` 不亮 / `need` 亮 + 展示文案实值）。
- 冻结：无新脚本则仍 34/34（若 A 阶段一新增 `event_panel.gd` 则为 35/35）。

---

## 五、方向 C / D / E / F 完整规格（全锁后补全）

### 5.1 C 在册遗留收口（阶段一）

- `player.gd:1053–1059 _third_boss_probe` 直调 `on_slug_killed(b3)` 会 `+2000` 分、掉 8 次源石、消费一次 `Game.rng`。改为**只验登记路径**（把登记逻辑提取成纯函数，或探针末尾显式还原 `score` / `diamonds` / 实体数）；表外探针不进 E1 diff，但不能污染同 run 统计。
- SMOKE 钩子清单以 `HANDOFF_技术接手包.md` §2 为准，同步进 `玩法说明.md` 工程节。
- 抽查收口批 `0724aad` 的断言性质标注是否覆盖全部「前提守卫型 / 常量自比较」落点。
- **验收**：四门控全绿、冻结分母不变；`SMOKE_THIRD_BOSS` 前后 `score` / `diamonds` 逐字一致（补一条 `Dev.check`）。

### 5.2 D 武器淬炼（阶段三 · 单独 commit）

| 项 | 规格 |
|---|---|
| 挂接点 | `weapons.gd:11 DEFS`（4 把枪，字段 `dmg/interval/count/spread/speed/mag/reload/pierce/life/explosive`）；`player.gd:392–404` 开火路径（`:392` 散布 rng、`:394` 暴击 rng、`:399` 伤害计算）；`game_main.gd:2083 give_player_weapon` |
| 数据表 | `data.gd` 新增 `WEAPON_TRAITS`（4–6 条：淬毒 / 贯穿 / 爆裂 / 连射…），schema `id/name/desc/stat/value`；局内 `Game.weapon_traits` 字典，**不新增持久化档** |
| 效果落地 | 在开火计算处乘算；**词条来源禁止新增 `Game.rng` 抽取** —— 走 `stable_hash("%s_%d_%s" % [run_seed, floor, weapon_id])` 纯派生，或复用既有掉落 rng 路径并登记 |
| E1 | 伤害路径 rng 密集，**任何新增抽取都会让后续掉落 / 编队序列漂移**。交付文档须列出改动前后 rng 消费对照表，并**随批重定基线** |
| 三件套 | ① 词条表 + 局内字典 ② HUD 词条显示 + `validate` 启动期表校验 ③ `SMOKE_WEAPON_TRAIT` 验数值（`dmg` / 弹数 / 穿透实值，不只验标志） |
| 冻结 | 若新增脚本则分母 +1，随批重定 |

### 5.3 E 每日深化（阶段三 · 单独 commit）

| 项 | 规格 |
|---|---|
| 挂接点 | `game_state.gd:400–439`（`DAILY_PATH:404` / `daily_seed_for:421` / `record_daily_best:426` / `daily_best_today:439`）；`game_main.gd:340–345` seed 注入、`:2271` 结算记录；`menu.gd` 主菜单「每日挑战」按钮 |
| 本批做 | ① **种子分享码**：`daily_key()` 文本 + `stable_hash` 校验位，主菜单可复制/粘贴 ② **本地榜**：扩展 `daily.cfg` 存最近 N 天成绩，纯局外只读展示。两者**零 `Game.rng`、零 E1** |
| 本批不做 | **「每日固定词缀」会改 `start_run:340–345` 的 rng 顺序** → 基线重定，且与 Sprint 12 D 重复度高；若日后要做，须在 `_apply_sigil_contract()` / `_apply_codex_boons()` 同段注入并单列一批 |
| 验收 | `SMOKE_DAILY` 双跑同 seed（沿用现有 `1410307864` 口径）、分享码往返一致、榜单读写往返、坏档降级不崩 |
| 冻结 | 无新脚本则分母不变 |

### 5.4 F 发现口径翻案（阶段二 · 全锁后由用户裁定生效）

| 项 | 规格 |
|---|---|
| 现状 | `game_main.gd:1706–1707 drop_pickup` 在 `kind=="relic" and payload!=""` 时 `mark_codex("relics", payload)` —— **掉落即登记** |
| 改挂 | 移除上述登记；在 `pickup.gd:108 _apply` 的 `"relic"` 分支新增 `Game.mark_codex("relics", payload)`（**改前实读该分支现状**） |
| 同步 | `menu.gd:332` 文案「已见遗物」→「已获得遗物」；交付文档口径；`玩法说明.md` 的「已见」表述 |
| 三件套 | ① 新挂点写入 ② **旧挂点必须移除**（防双登记）③ `SMOKE_CODEX` 断言「掉落未拾取不登记 / 拾取后登记」 |
| E1 / 语义 | 零 rng；但发现集增长变慢会影响 `codex_boons()` 的 `relics_4` 阈值达成节奏 → **属玩法口径变更，须在交付文档登记，不改 boon 表数值** |
| 旧档 | 历史档里的「已见」记录**不隐式迁移**（同 Sprint 14 A 的旧档处理口径），只保证新流程一致 |

---

## 六、验收四门控（quality-lead 口径）

1. **回归纪律**：`SMOKE + 全量钩子 + SMOKE_EVENT + SMOKE_CODEX_MILESTONE` 6000 帧 **0 报错**；冻结清单随批重定（含新脚本则 35/35）；**A 的指纹重定须在交付文档登记**。
2. **E6 合规**：grep 零新增 raw `delta` / 计时；`_tick_buffs` 与 `toxic_cloud` 既有豁免不动。
3. **E1 非污染**：A 选项集 `stable_hash` 零 `Game.rng`、B/C/E/F 零 rng；`SMOKE_*` 表外不进 diff；`ACTION_DEFS` / `GEN_NAMES` 零新增；`UNLOCKS` 不碰；**A 重定后**同 seed 双跑指纹逐字一致。**D 须附改动前后 rng 消费对照表**（伤害路径 `:392/:394` 等），**D/E 各自重定后**再跑双跑逐字一致；两次重定分别登记在各自交付文档，不合并成一次。
4. **登记三件套逐项打勾**：A 的 ① `ROOM_META`+`EVENT_OFFERS` ② `_check_rooms`/`KNOWN_ROOM_KINDS`/小地图 mark ③ `SMOKE_EVENT` 数值断言；B 的 ① `CODEX_MILESTONES` ② `CODEX_KINDS` 校验 + 菜单渲染 ③ `SMOKE_CODEX_MILESTONE`。**只验中间状态不算过**。
5. **P0 红线门保持**：`validate` 的 `CODEX_BOONS.kind` 断言继续绿；任何扩表前不得放开 `suffixes`。

---

## 七、三阶段落地顺序（编程侧，A–F 全锁）

**阶段一（A + C）**
1. `ROOM_META` 一条 + `EVENT_OFFERS` 表 + `dungeon.gd` 分配（零 rng、只改 kind）。
2. `_enter_room` 两分支 + 三卡面板薄复用（`card_1/2/3`，零新 action）+ `_open_event` / `_on_event_chosen` + `cleared` 防重入。
3. C 三项收口。
4. 四门控 → **指纹与冻结重定 #1** → 交付文档 → **单独提交**。

**阶段二（B + F）**
5. `CODEX_MILESTONES` + `codex_milestones()` 纯只读派生 + 图鉴页 / 结算页展示 + 启动期校验。
6. F：移除 `game_main.gd:1706–1707` 的掉落登记 → 在 `pickup.gd:108 _apply` 的 relic 分支新增登记（改前实读该分支）→ UI「已见遗物」改「已获得遗物」→ `SMOKE_CODEX` 补「未拾取不登记 / 拾取后登记」断言。
7. `SMOKE_CODEX_MILESTONE` + F 断言 → 四门控（零 E1、指纹不变）→ **单独提交**。

**阶段三（D 与 E 各一个 commit，不混批）**
8. D `WEAPON_TRAITS` + 开火计算乘算 + HUD/validate + `SMOKE_WEAPON_TRAIT`；附**改动前后 rng 消费对照表** → **基线重定 #2** → 单独提交。
9. E 种子分享码 + 本地榜（**不碰** `start_run` rng 顺序）→ `SMOKE_DAILY` 往返 → 单独提交。

---

## 八、主理人备注（规划侧内部，编程侧可略）

- **为什么是 A+B 而不是「再加一把枪」**：Sprint 10–12 已把内容量堆足，Sprint 13 起转向决策深度 + 局外沉淀。A 补的是「信息 / 路线」这一维度的决策（现有圣所只覆盖资源交换），B 把已有的图鉴数据从「被动记录」变成「有目标的长期动机」，两者都不新增随机系统、不碰 `UNLOCKS`。
- **A 的最大代价是 E1 指纹重定**，不是实现难度：房型变化会改 `kinds`，但选项集走 `stable_hash` 可把漂移面压到房型本身，Sprint 13 A 已验证这条路径。
- **B 的最大风险是语义混淆**：里程碑必须与 boon 明确区分（纯展示、零数值），否则玩家会以为是第二套解锁，反而碰了冻结规格的边界。
- `design-strategist` 实稿**已回传**（`SPR16_设计候选实稿.md`），其「明确不建议做」清单与当前全锁裁定在 A / D 两处直接冲突，详见 **§九**；按工作室铁律，主理人不擅自改写成员判断、**不擅自改锁定范围**，提交用户复核。
- 锁定范围已由用户裁定为 **A–F 全锁、三阶段**（2026-11-08）；§〇 技术红线不因全锁放开。主理人侧不写 `.gd`，落地后按流程读码核验。

---

## 九、⚠️ 设计成员实稿与全锁裁定的冲突（主理人一致性检查 · 待用户复核）

> 来源：`production/sprint-16/SPR16_设计候选实稿.md`（`design-strategist` / 文策渊，77 行，已实读核验落盘）。
> 按工作室铁律「**专业产出以成员结论为准，主理人只做编排、一致性检查与汇编**」，本节**不改写成员判断**，只如实列出冲突与可选路线，**锁定权仍在用户**。

### 9.1 实稿核心结论：「必须换轴」

Sprint 16 应做**系统之间的关系**，不再加内容。推荐阶段一 = **A 地窖誓约**（联动型核心增量：跨局回响的抉择契约，严格零 E1 / E6 / 坑 5 / 冻结影响）+ **B 抉择回声**（S 级数据地基，同往 `last_run` 写平行只读字段）；阶段二 = **C 层签**（随机性可读化）+ **D 地窖低语**（叙事钩子）。理由：内容已过饱和、认知负荷接近上限；加「关系」不新增实体，却让 N 个孤岛互相读取，产生新决策情境；且是**唯一不付重定代价**就能拿到系统增量的路径。

### 9.2 与当前全锁裁定的冲突（三处）

| 全锁方向 | 实稿判定 | 实稿理由 |
|---|---|---|
| **A 第 12 房型 `event`** | **明确不建议做** | 改 kinds → 指纹须重定；与 `shrine` 三选一骨架**高度同构，属同类内容堆叠**；Sprint 13/15 已两度列为备选未接，不建议第三次翻案 |
| **D 武器淬炼** | **明确不建议做** | `weapons.gd` 开火路径 rng 密集 + `meta_content_unlocked` 门控，属重构级 E1 风险，与「局外沉淀」支柱无关 |
| **E 每日固定词缀** | 明确不建议做 | 改 `start_run` rng 顺序 → 基线重定。**注**：本草案 §5.3 已把固定词缀排除、只留分享码与本地榜，**此处与实稿一致**，无冲突 |

**主理人一致性检查结论**：实稿的批评有实码依据 —— `shrine_panel.gd:109 open()` / `:171 _pick()` 三卡骨架、`stable_hash` 派生、`ROOM_META` 三挂点、`dungeon.gd:138–146` 确定性分配确实会被 `event` 完整复用；其「零重定批次（指纹不变、34/34 不变、`assets.gd`/`meta.gd`/`.tscn` 零改动）」的优势也成立。**冲突真实存在，不是措辞差异。**

### 9.3 三条可选路线（主理人不擅自选）

| 路线 | 内容 | 代价 |
|---|---|---|
| ① **维持全锁 A–F** | 按 §二 / §七 三阶段执行（当前裁定） | 两次基线重定、同类内容堆叠、与设计诊断冲突 |
| ② **按实稿换轴** | 撤 A / D，改做「地窖誓约 + 抉择回声 + 层签 / 低语」，保留 B/C/E/F 中零 E1 部分 | **零重定、34/34 不变**；但需重写 §三 / §五 规格，并重新裁定阶段划分 |
| ③ **混合** | A 换成「地窖誓约」、D 撤下，保留 B/C/E/F | 折中，仍需一次规格重写，但保住全锁的大部分范围 |

### 9.4 实稿待拍板项（原文 §八，一并提交用户）

- 「地窖誓约」的兑现度**是否允许写 `last_run` 平行只读字段** —— 决定它是 M 还是退化为 S。
- 「层签」预告随机性是否符合期望手感（不预告＝临场紧张 / 预告＝可规划）。
- 「地窖低语」世界观基调三选一；无基调则不启动。
- 两处时序须**实现前重新实读挂接点**：`_settle_meta` 后追加只读字段的位置、进层「所有 roll 完成」的位置。实稿明确不臆造 API。

