# Sprint 15 规划草案（主理人 / 规划侧合成）

> 来源：主理人实读挂接点后合成，沿用 Sprint 10–14 已沉淀的非编程专家口径（design-strategist 玩法 / art-director 美术 / audio-director 音频 / quality-lead 验收）；本批为规划侧直接合成，**未逐项 spawn**，故不标注四专家实稿。
> 本文为**自包含规格**，编程侧据锁定范围实现；主理人侧**不写任何 `.gd`**（只读核验 + 文档维护）。
> 基线（本轮实校）：Sprint 14 **final PASS 正式收官**，最新 `03cccd4`；`md5sum -c` **33/33 OK**（exit 0）、**33 个 `.gd`**、单场景 `scene/game.tscn`；`git status` 仅两份待授权文档（`玩法说明.md` 已改 / `production/sprint-14/SPR14_规划草案.md` 未跟踪）。
> **本批状态**：规划已开启、**锁定范围已裁定**。**F2 第三 Boss 已由用户裁定「解绑为候选」**（不再与 F1 一起封存）；**F1 主题扩容 8→12 维持永不接**。
> **锁定范围（用户 2026-11-08 裁定）**：**P0 + B + C + D / A** —— 阶段一 P0+B+C+D、阶段二 A；E 与文档整理批由主理人并行。F/G 备选未接、F1 永不接。
> 已冻结可复用系统：`ROOM_META` 11 房型 / `SHRINE_OFFERS` 6 条 / `SIGILS` 9 枚 / `SQUADS` 7 模板 / `RELIC_SUFFIXES` 8 条 / `ACTIVE_RELICS` 4 条 / `FLOOR_THEMES` 8 主题 / `PrismWarden` + `boss2` 继承骨架 / `CODEX_BOSS_NAMES` 单源 / `CODEX_BOONS` 4 档 / `codex.cfg` 双档 / `stable_hash` FNV-1a / `_smoke_fingerprint`（只含房间坐标 + kinds）。

---

## 〇、跨批铁律

1. **E6 固定步**：新增计时走 `Game.FIXED_DT`，禁 raw `delta`。
2. **E1 确定性指纹**：核心循环不无故新增 `Game.rng` 消费；`SMOKE_*` 表外不进 E1 diff（坑 45）；动 rng 前先想清漂移面，预期代价须登记 + 随批重定。
3. **复用优先**：挂既有表 / 接口 / 实体，不另起炉灶。
4. **坑 5 护栏**：`assets.gd` `ACTION_DEFS`（`:333–`）不加新 action；新资源走 `Assets.g()` 必须同时登记 `GEN_NAMES`（`:109–132`）。
5. **冻结规格不可改**：`Sprint7_解锁树规格.md` v2.10 → `meta.gd UNLOCKS` 不动；局外内容一律平行只读派生。
6. **批次流程**：实施 → 四门控 → 冻结重定 → 交付文档 → **单独提交**（每阶段一个 commit）。
7. **登记三件套**（Sprint 14 成文）：新增 id / 资源 / 记录点必须同时核对 ① 写入 ② 注册表 / 白名单 / UI 分母 / 显示名 ③ 可见效果断言。
8. **🆕 boon 扩表前置红线**（用户 2026-11-08 裁定）：**任何 `CODEX_BOONS` 扩表之前，必须先切断**「送词缀 → `attach_suffix` → `mark_codex` → 发现度上升 → 更多 boon」正反馈链。本批 P0 第一项即为此，不得延后到核验阶段。

---

## 一、候选方向

| 方向 | 规模 | 内容 | 风险 / 裁定 |
|---|---|---|---|
| **P0 前置门槛批** | S | boon 自激切断 / B2 探针覆写 / 玩法说明补行 / 待授权文档入库 | **必做**：任何扩表前先落 → 推荐阶段一 |
| **A. F2 第三 Boss（解绑候选）** | M | 继承 `PrismWarden` 骨架 + 生成优先链第三层 + 图鉴 `codex_id` | 中：零新状态机、地图指纹不变；Boss 战 rng 消耗变化需登记 → **推荐阶段二核心增量** |
| **B. 图鉴发现口径裁定** | S | `relics` 掉落即「发现」vs 拾取才算 | 产品裁定，推荐零代码方案 → 推荐 |
| **C. 图鉴页进度可视化** | S | 未发现灰位 / 进度条 | 纯 UI、零 E1 → 推荐顺手 |
| **D. 圣所选项池扩容** | S–M | `SHRINE_OFFERS` 6 → 10，按 `min_floor` 分层 | 纯状态交换、零 rng、指纹不变 → 推荐 |
| **E. 断言有效性盘点** | S | 标注「前提守卫型恒过」「常量自比较」两类断言性质 | 纯文档 / 注释，不改逻辑 → 推荐并行 |
| **F. 房间事件池** | M | 第 12 房型，复用 `shrine_panel` 三卡骨架 | 中：改 room kinds → **指纹重定** → 备选 |
| **G. D 武器淬炼 / E 每日深化** | M | 备选转正 | 高：动伤害路径 / `start_run` rng 顺序，E1 重定 → **备选，不同批** |
| **红线 F1 主题扩容 8→12** | L | — | **永不接**（§六） |

## 二、锁定组合（用户已裁定：P0 + B + C + D / A）

| 阶段 | 方向 | 交付物 |
|---|---|---|
| 一 | **P0 + B + C + D** | 门槛批 + 三项零 E1 收敛，风险最低，先交 |
| 二 | **A（F2 第三 Boss）** | 唯一玩法增量，与阶段一零耦合（只共用图鉴单源表） |
| 并行 | **E + 文档整理批** | 主理人侧；待授权文档入库需单独授权 |

- **dash option b 保持 196–210px**；终审附章入库提议**继续休眠**；`relics` 口径本批只出裁定、不擅自改挂点。
- F/G 备选未接；F1 维持封存。

---

## 三、P0 前置门槛批完整规格

### 3.1 boon 自激切断（用户点名红线，最高优先）

**现状链路（实读）**：`game_main.gd:2052–2069 _apply_codex_boons()` 的 `"suffix"` 分支 → `player.gd:601 attach_suffix()` → `:606 Game.mark_codex("suffixes", sid)` → `save_codex()`。当前 `CODEX_BOONS`（`data.gd:337–342`）四档的 `kind` 为 enemies / relics / themes / bosses，**不含 suffixes**，故现在无自激；但一旦扩表加入 suffixes 阈值，就会形成正反馈。

**推荐切法（最省事、零链路改动）**：**数据层约束 + 启动期断言**——规定 `CODEX_BOONS` 的 `kind` 不得为 `"suffixes"`，并在 `validate.gd:225 _check_codex()` 末尾加断言遍历 `Data.CODEX_BOONS`，命中即 `problems.append(...)`。理由：只要没有 suffixes 阈值，回写就不会影响任何 boon 判定，正反馈链在**判据端**被切断，比在写入端做特例更稳、也不破坏「已获词缀」图鉴的记录语义。

**备选切法**（用户原话，若产品要求 suffixes 也能做阈值）：`_apply_codex_boons()` 的 suffix 分支改调一个**不回写图鉴**的内部绑定路径（如 `attach_suffix_silent()`），只写 `relic_suffixes` 不调 `mark_codex`。此方案需新函数 + 探针，成本更高，且图鉴会少记一条「确实获得过」的词缀。

**验收**：`validate` 断言落地；`SMOKE_CODEX_BOON` 补一条「boon 送词缀后 `codex_boons()` 输出逐字不变」（真差值断言，防回归）。

**顺带登记（产品裁定项）**：boon 开局白送词缀仍会写进「已获词缀」图鉴，玩家没在局内捡到也算发现。语义可接受但需在交付文档写明，或随 B 方向一并裁定口径。

### 3.2 B2 探针覆写隔离档

`player.gd:951–953` 新建 `ConfigFile` 只 `set_value("codex","last_run",{负数})` 就 `save(codex_path())`，会把 cfg 里五类发现集抹掉；随后 `load_codex()` 读成空数组。SMOKE 隔离档下无害，但非隔离环境跑会清掉玩家图鉴。

**修法（一行）**：`cfgf.set_value(...)` 之前加 `cfgf.load(Game.codex_path())` 先读回原档；或断言后 `Game.save_codex()` 恢复现场。**验收**：B2 断言后五类发现集与探针执行前逐类一致（补一条 `Dev.check`）。

### 3.3 文档项（主理人侧）

- `玩法说明.md` 补 Sprint 14 一行：C 图鉴发现度被动 / 双主题 Boss 收录 / bosses 分母 6。
- 两份待授权文档（`玩法说明.md`、`SPR14_规划草案.md`）随文档整理批入库；本草案为第三份，**均需用户授权后提交**，编程侧不混入代码提交。

---

## 四、方向 A 完整规格：F2 第三 Boss（解绑候选）

### 4.1 口径变更

Sprint 13–14 的「F 永不接」把两件事打包了。本批由用户裁定**拆分**：

- **F1 主题扩容 8→12**：维持封存（§六，真技术红线）。
- **F2 第三 Boss**：**解绑为候选**。实读确认它没有硬编码周期依赖——`boss2.gd` 已证明「`extends PrismWarden` + 覆写 `setup()`」是低成本路径，`game_main.gd:1091–1114` 的 Boss 生成优先链再加一层即可。当年判「永不接」的理由是「边际递减」，属范围取舍而非技术阻断。

> 解绑 = 进候选池，**不等于本批必锁**；是否纳入阶段二仍由用户裁定。

### 4.2 层判定数学（关键，须验算）

现有（实读 `game_main.gd:969–975`）：

```
_is_warden_floor(n)    = n > 4 and (n - 4) % 8  == 7
_is_sovereign_floor(n) = n > 4 and (n - 4) % 16 == 15
```

Sprint 12 已自纠：sovereign 是 warden 的**子集**，不是「错开」，靠优先分支兜住。

**新增判定（建议）**：

```
_is_third_floor(n) = n > 4 and (n - 4) % 32 == 23
```

验算：n=27 → `(27-4)%32 = 23` ✓；`23 % 8 = 7` → 是 warden 层；`23 % 16 = 7` ≠ 15 → **不是** sovereign 层。即每 32 层一次、落在首领层且避开主权层，契合「周期收尾」语义。下一命中 n=59。

**优先链改为**：`third > sovereign > warden > 常规`（新分支放在 `:1091` 的 `if` 最前，其余分支不动）。三层判定都是纯函数、**零 rng**。

### 4.3 实现骨架（复用，不复制状态机）

- 新 `scripts/boss3.gd`：`extends PrismWarden`，覆写 `setup(floor_num)`，与 `boss2.gd` 同型。
- 差异化参数（数值由设计侧定，规划侧只给约束，避开现有两个）：
  - `_theme_offset` 取 **2**（warden=0 / boss2=4 / 新=2），三阶段仍走 `phase_theme_index(floor_num + offset, k)` 的 `%8`，**不改周期函数**；
  - `skill_interval` 建议 **2.6**（介于 warden 3.0 与 boss2 2.2 之间）；
  - `max_hp` 沿用 `360.0 * (1 + (floor-4)*0.12)` 或另定；
  - `boss_name` / 外观 tint 数据驱动（沿用 `boss2.gd:25–26` 范式）。
- **身份铁律（Sprint 14 A 教训）**：`variant = "boss"` 继续复用宝箱 / 词缀必掉 / 震屏三条掉落契约，**必须同时设 `codex_id`**（如 `"third_boss"`），否则会重演「熔潮主宰把巨岩虫之王误登记」。`on_slug_killed:1716–1720` 无需改动（codex_id 优先 + variant 回退已通用）。

### 4.4 图鉴三件套（Sprint 14 单源红利）

只需三处，白名单 / 分母 / 显示名**自动同步**：

| # | 落点 | 动作 |
|---|---|---|
| ① 写入 | `boss3.gd setup()` | 设 `codex_id` |
| ② 表 | `data.gd:331 CODEX_BOSS_NAMES` | 加一条 `"third_boss": "中文名"` → `_codex_id_valid`（`game_state.gd:294–298`）、`codex_bosses_total()`（分母 6→7）、`menu.gd:329–330` 显示名全部同源派生 |
| ③ 断言 | `SMOKE_CODEX` / 新探针 | 分母 == 7、击杀登记新 id、无 `"boss"` 假阳性 |

> Sprint 14 把「四处核对」压成了「三处」，本方向是这项改造的第一个红利场景；交付文档须逐项打勾（跨批铁律 7）。

### 4.5 E1 / E6 / 坑 5

- **地图指纹不变**：`_smoke_fingerprint:313–328` 只打印 `rooms` 坐标与 `kinds`，F2 不改房型 → 指纹逐字一致。
- **但须登记预期代价**：Boss 战增援 / 死亡碎片走 `Game.rng`（`boss.gd:328–331`、状态机增援），`skill_interval` 不同 → 同时间窗 rng 消耗次数不同 → **后续掉落 / 编队抽取序列漂移**。地图由 `_floor_rng(n)` 独立派生不受影响。沿用 Sprint 11 B / 12 C 口径：登记「Boss 战 rng 消耗变化」+ 随批重定基线。
- 层判定纯函数零 rng；全计时沿用基类 `Game.FIXED_DT`（E6）；`ACTION_DEFS` / `GEN_NAMES` 零新增（坑 5）；`meta.gd UNLOCKS` 不碰。
- 冻结清单：新增 `boss3.gd` → **33 → 34**，随批重定。

### 4.6 探针与验收

- `SMOKE_JUMP_FLOOR=27`（或新增 `SMOKE_FORCE_THIRD_BOSS=1` 显式钩子）取真实击杀证据；注意跳层钩子吃**层号数值**，不是布尔开关（Sprint 12 收官批踩过）。
- 清档后查 `_smoke_codex.cfg` 的 `bosses` 含新 `codex_id`、不含误写入的 `"boss"`。
- 优先链断言：n=27 只生成第三 Boss，`_room_budget == 1`，不同时生成 warden / boss2。
- 同 seed 双跑指纹逐字一致（验 §4.5 的「地图不变」）。

---

## 五、B / C / D / E 规格

| 方向 | 实读挂点 | 落地 |
|---|---|---|
| **B 图鉴口径裁定** | `game_main.gd:1706–1707` `drop_pickup` 掉落即 `mark_codex("relics", payload)` | **推荐零代码方案**：保持挂点，UI 文案由「已发现遗物」改为「已见遗物」，与「掉落即见」对齐。备选方案是改挂拾取消费路径（需另找 pickup 入口）。**本批只出裁定，不擅自改挂点** |
| **C 图鉴页可视化** | `menu.gd:308–345 _build_codex()` / `:347 _codex_section()` | 每分区加未发现灰位与进度条；`body.autowrap_mode` 已有，纯 UI、零 rng、零 E1 |
| **D 圣所扩容** | `data.gd:313–320 SHRINE_OFFERS` 6 条 / `game_main.gd:1977–2004 _shrine_execute()` | 6 → 10 条，按 `min_floor` 分层（低层给温和交换、高层给高代价高收益）；全部纯状态交换、零赌局；复用 `_shrine_affordable` 置灰与 `stable_hash` 三卡派生。**池变大后同 seed 三卡内容会变，但不消费 `Game.rng`、不改 kinds → 指纹不变、E1 零漂移**；只需更新 `SMOKE_SHRINE` 期望值 |
| **E 断言盘点** | `validate.gd:219–221`（前提守卫型，当前恒过）/ `player.gd:919–920`（显示名常量自比较） | 纯注释 / 文档标注两类断言的**性质与意图**，避免被误判为「假断言」；不改断言逻辑。按「凡标 ✓ 必附本轮实读行号」纪律，盘点结果写进交付文档 |

---

## 六、F1 红线维持（主题扩容 8→12）

实读四处周期来源（`SPR14_规划草案.md` §一 F 条文的细化）：

| 消费点 | 周期来源 |
|---|---|
| `data.gd:366 theme_for_floor()` | `FLOOR_THEMES.size()` **动态** |
| `boss.gd:56 phase_theme_index()` | `% 8` 硬编码 |
| `game_main.gd:970 _is_warden_floor()` | `% 8` 硬编码 |
| `game_main.gd:975 _is_sovereign_floor()` | `% 16` 硬编码 |

扩到 12 会让动态侧按 12 轮转、三条静态侧仍按 8/16 → 同层地形主题与 Boss 阶段主题错位、主权层不再是周期收尾；主题又决定 `pool_for_floor()` 刷怪池 → 敌人编组 / 掉落 / E1 全量重定。

真要解封，前提是**先把四处周期来源统一成一个常量**（如 `THEME_CYCLE`）并接受 E1 全量重定——属重构级工作量，换 4 个新主题性价比过低。**维持永不接**。

---

## 七、备选 / 不接口径

- **F 房间事件池**：第 12 房型会改 room kinds → `_smoke_fingerprint` 重定；复用 `shrine_panel.gd` 三卡 + `stable_hash` 可做到零 `Game.rng`，但房型生成与两处 `_enter_room` 分支（`:1071` / `:1146`）都要动，规模 M，建议单列。
- **G-D 武器淬炼**：`weapons.gd:11 DEFS` 参数即弹道，`player.gd:392/394/425/492` 开火路径 rng 密集，且 `weapons.gd:79/89` 有 `meta_content_unlocked` 门控 → 单独成批。
- **G-E 每日深化**：`daily_seed` 注入在 `start_run:340–344` 早于首抽（现状零漂移）；若加「每日固定词缀」会改 `:347` 之后的 rng 顺序 → 基线重定。
- **F1**：永不接（§六）。

---

## 八、验收四门控

1. **回归纪律**：`SMOKE+V8+REBIND+RELIC+SUFFIX+META+PERSIST+BOSS+BOSS2+ECHO+DAILY+CALAMITY+SHRINE+CODEX+CODEX_BOON+THIRD_BOSS` 跑 6000 帧 **0 报错**；冻结清单随批重定（阶段二含 `boss3.gd` → 34/34）；Boss 战 rng 漂移须在交付文档登记。
2. **E6 合规**：grep 零新增 raw delta / 计时；新 Boss 全计时走基类 `Game.FIXED_DT`。
3. **E1 非污染**：P0 / B / C / D / E 零 rng；A 层判定零 rng、地图指纹双跑逐字一致；`SMOKE_*` 表外不进 diff（坑 45）；`ACTION_DEFS` / `GEN_NAMES` 零新增；`meta.gd UNLOCKS` 不碰。
4. **🆕 P0 红线门**：`validate` 的 `CODEX_BOONS` kind 断言 + `SMOKE_CODEX_BOON` 的「送词缀后派生不变」断言**双绿**才算过；B2 探针现场恢复断言落地。
5. **登记三件套逐项打勾**：A 的 ① `codex_id` ② `CODEX_BOSS_NAMES` ③ 分母 / 显示名 / 击杀断言，列表核对；只验中间状态不算过。
6. **探针**：`SMOKE_CODEX_BOON`（扩）、`SMOKE_THIRD_BOSS`（新）或 `SMOKE_JUMP_FLOOR=27`，沿用「断言 + [ERR] + done 落地」门控范式。

---

## 九、两阶段落地顺序（编程侧）

**阶段一（P0 + B + C + D）**
1. 先落 **P0-3.1 boon 自激切断**（任何 `CODEX_BOONS` 扩表之前），再 P0-3.2 B2 探针。
2. B 口径裁定（若选零代码方案只改 UI 文案）、C 进度可视化、D 圣所扩表 + `_shrine_execute` 分支 + `SMOKE_SHRINE` 期望值更新。
3. 四门控 → 冻结重定（33/33）→ 交付文档 → **单独提交**。

**阶段二（A）**
4. `boss3.gd` 继承骨架 + 层判定 + 优先链 + `CODEX_BOSS_NAMES` 一条 + `codex_id`。
5. `SMOKE_THIRD_BOSS` / 跳 27 层证据 → 四门控 → 冻结重定（**34/34**）→ **单独提交**。

**并行（主理人）**：E 断言盘点 + 文档整理批（含三份待授权文档入库，需授权）。

---

## 十、主理人备注（规划侧内部，编程侧可略）

- **F2 解绑的实质是口径纠偏，不是放宽风险**：技术红线从来只在 F1 的周期常量上；把「边际递减」写成「永不接」会把可复用的继承骨架一并封死。本草案把它降为「候选」，锁定权仍在用户。
- **P0 被排在任何扩表之前**，是用户 11-08 台账里唯一带未来红线的观察；我推荐的「禁 suffixes 作阈值 + 启动期断言」比改绑定路径更省，且保住图鉴记录语义，但**若产品确实要 suffixes 阈值**，须改用备选切法并重做这一门。
- **A 方向最大的红利是 Sprint 14 的三件套单源**：换作 Sprint 13 时期，加一个 Boss 要同步改白名单 / 分母 / 显示名 / name_of 四处；现在只需表加一条 + 设 `codex_id` + 断言。
- **F2 的 E1 口径要如实拆开讲**：地图指纹不变（只含 kinds），但掉落 / 编队序列会漂移。别用「指纹一致」一句话掩盖后者，这正是前几轮反复吃亏的地方。
- 锁定范围已由用户裁定为 **P0 + B + C + D / A**（阶段一 P0+B+C+D、阶段二 A，E 与文档整理批主理人并行）；F/G 备选未接、F1 永不接。主理人侧不写 `.gd`，落地后按流程读码核验。
