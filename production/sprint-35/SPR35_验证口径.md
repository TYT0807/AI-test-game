# SPR35 验证口径 · 六道成层与局内规矩

批次：Sprint 35
日期：2026-11-18
配套：`SPR35_设计实稿_六道成层与局内规矩.md`（机制本体）／`SPR35_实施单_编程侧.md`（落地清单）／`SPR35_主理人核验.md`（独立核验）
性质：**不看代码实现即可判对错**。每条给「可观测判据 + 基准值 + 边界态」。编程侧门控必须能被主理人独立复现。

约定：
- **基准档**＝`SMOKE=1 SMOKE_SEED=12345`（churn 对比必钉，不钉会产生上百行假差异）。
- 残留原始日志行 `[SMOKE-NAV]/[SMOKE-CAM]/[SMOKE-E]/[SMOKE-LOOP]/[SMOKE-STALL]` 与时间戳**不比对**。
- 凡本口径标 `UNEXECUTED` 的条目，**不得计入 PASS**。

---

## V-A 道派生（T1）

| 编号 | 判据（可观测） | 基准值 | 边界态 |
|---|---|---|---|
| V-A1 | `Data.dao_for_floor(n)` 对同一 `n` 连续调用 200 次，返回字典三字段逐字相同；且全程 `Game.rng.seed`/`Game.rng.state` 不动 | 恒等、零 rng | n<4 返回 `{}`（空字典，不是 `{id:""}`） |
| V-A2 | n=4..27 共 24 行的 `(主题 rule, 道 id)` 序列 | 实稿 §4.2 死值表逐行一致（该表由 `DAO_SHIFT`+`DAO_ORDER` 机械推出，不接受手写第二份） | 任一格不符即整条红，不许「多数相符」 |
| V-A3 | 前 24 层道分布计数 | `人间4 畜生4 饿鬼4 地狱4 阿修罗4 天道4`（**恰为 4/4/4/4/4/4，不是「都出现过」**） | 缺一或多一皆红 |
| V-A4 | **奇偶退化探针**（本轮新增，专抓旧设计的病）：按新公式展开 24 层，统计「道的奇偶」取值的种数 | = 2（既出偶数位也出奇数位） | = 1 ⇒ 道退化成主题的奇偶别名，**必红** |
| V-A5 | 同主题在 24 层内出现 3 次，三次道 id 互不相同（8 个主题各自验） | 8/8 通过 | 任一主题三次里有两次同道即红 |
| V-A6 | 第 4 / 12 / 20 层同为 `vein`，道 id 两两不同 | `human / hungry / asura` | 与主题名解耦证明 |
| V-A7 | 周期：`dao_for_floor(n) == dao_for_floor(n+24)` 对 n=4..60 成立；`!= dao_for_floor(n+12)` 至少一处成立 | 周期恰 24 | 周期退化为 8 ⇒ 道成了主题的别名 |
| V-A8 | 🔴 **非目标声明**（写进断言注释，防后人误加）：固定主题遍历 n **不要求**取到全 6 道——gcd(6,8)=2 使每个主题只落 3 道，这是设计接受的结构性后果 | 见实稿 §4.2 性质 2′ | ⛔ 谁把它改成「每主题 6 道」的断言，等于改设计，须回主理人 |

---

## V-B 层名改名（T2）

| 编号 | 判据 | 基准值 | 边界态 |
|---|---|---|---|
| V-B1 | `FLOOR_THEMES[k]["name"]` 四字面值 | k=8 `焦土`／k=9 `凝渊`／k=10 `腐泽`／k=11 `缠林` | — |
| V-B2 | 同键的 `rule/pool/elite/boss/tint/mark` 六字段改名前后逐字节相同 | 完全相同 | 动到 `rule` 即整批作废（红线 §4.7） |
| V-B3 | 全仓 `scripts/*.gd` 扫描：`岩浆灼烧`/`冰面打滑`/`毒沼减速`/`藤蔓阻挡` 四个旧串命中数 | 各 = 0 | `_backup/`、`production/` 不在扫描面 |
| V-B4 | `validate.gd _check_themes()` 与 FLAVOR 覆盖门仍 `problems=0` | problems=0 | 表长不变（8 条），FLAVOR 不改 value |

---

## V-C 四条规矩（T3）

统一前置：规矩只在 `dao ∈ {beast, hungry, hell, asura}` 的层生效；`human/deva` 层任何动作**不得**记账。

| 编号 | 判据 | 基准值 | 边界态 |
|---|---|---|---|
| V-C1 | beast·连冲：首冲只记时刻不违例；第二次 dash 起手距上次 `< 0.90s` 才违例 | 违例时 `_invuln_t` 读数比基线 **+0.20s** | 间隔恰 = 0.90s ⇒ **不违例**（严格小于）；跨层首次 dash 不携上层层内计时（换层清零） |
| V-C2 | beast 红利只延无敌帧，**不改位移**：`SMOKE_DASH_TRACE` 采样区间 | 位移仍在 **196–210px** | 越界即红（红线 §4.9） |
| V-C3 | hungry·满弹：只有在「未在换弹中 且 `mag() >= mag_cap()`」时按下 R 才违例 | 违例当场 `Game.diamonds` **+4**，且 `run_diamonds_earned`/`diamonds_picked`/`_reso_pickups` **三个计数器 Δ 全 = 0** | 空仓或换弹中按 R ⇒ 走正常换弹、**不违例**；`scarce_ammo` 把 `mag_cap_mult` 压到 0.5 后，判据用压缩后的 `mag_cap()`，不用武器基础弹容量 |
| V-C4 | hell·站云：玩家位于 `side=="enemy"` 或 `fixed_step==true` 的毒云半径内**连续**累计 ≥ 0.50s 才违例 | 违例置一次性免除标记；下一次主题 tick 玩家 hp 不变，标记随即清空 | 离开云再进 ⇒ 累计器归零；一次 tick 只免一次；友方 `toxic_freeze` 云不算危害源；无 tick 可免时标记跨层失效 |
| V-C5 | asura·齐射收尾：房间清场瞬间，距最近一次 `ON_VOLLEY_FIRE` > 4.00s 或本房从未齐射 ⇒ 违例 | 违例 `Game.score` **+25** | 未装 `volley_burst` 遗物的房必然违例（这是设计，不是缺陷）；非战斗房（宝箱/商店/圣所）不判 |
| V-C6 | 时序硬序：四条红利一律**先落地、后记账**，中间不得插入任何 `return` | 证据行里红利读数与 `_rule_breaches` 增量同帧出现 | 反序即红（红利变惩罚） |
| V-C7 | 违规 toast 文案 | `违例 · <道名>规矩（已记一笔）` 逐字 | 道名取 `DAO_FOR` 表，不硬编码 |
| V-C8 | 归零：`start_run()` 后 `_rule_breaches` 为空、四层局部计时器为初值 | 空/初值 | 漏归零 ⇒ 跨局污染，必红 |

---

## V-D 账本与结算（T3 后半）

| 编号 | 判据 | 基准值 | 边界态 |
|---|---|---|---|
| V-D1 | B = 本局违例总笔数（`_rule_breaches` 各道之和） | `mult(B)=1.0−0.25·B/(B+1)`，整数落点：B=0→×1.000；B=1→×0.875；B=3→×0.8125；B=7→×0.750 | B→∞ 渐近 0.75，**永不低于 0.75** |
| V-D2 | 「不作数」开关读**赎回账**而非布尔 | `Game.redeemed_floors.size() > 0` ⇒ 显示 `规矩 N 笔 · 不作数` 且 mult=1.0 | 🔴 判据里**禁止**出现 `Game.purified_run`（该字段今天只剩写入方与探针方，重新当事实源＝复活降级字段） |
| V-D3 | `settle_shards()` 函数体一字未改 | 与 S33 冻结版逐字节同 | 改动即红 |
| V-D4 | F01/F02 静态门仍 `1/1` 与 `true` | 写入点仍恰 2 处 | 新账若写成 `calamity_floors.append`/`redeemed_floors.append` 字面即红 |
| V-D5 | 结算行展示 | `规矩 违 3 笔 · 折算 ×0.81` | B=0 时该行不显示 |

---

## V-E E1 确定性（全局硬门前置）

| 编号 | 判据 | 基准值 |
|---|---|---|
| V-E1 | `SMOKE_META_FINGERPRINT=1` 下 `[SMOKE-META] fingerprint floor= rooms= kinds=` 全部行，改前/改后**逐字相同**（同 seed 双跑） | 漂移 0 行。**这就是口径 V-E1 的靶** |
| V-E2 | 出卡路径零 rng：五态 × 1681 网格调用 `_shrine_offers_for` 后 `Game.rng.seed`/`state` 逐字不动 | 全不变（SC8 同型） |
| V-E3 | 规矩检测路径（dash/reload/tick/cleared 四个钩子）零 `Game.rng` 消费 | seed/state 双不变（不只比 state） |
| V-E4 | 道派生如需逐局变化，只允许 `"%d_%d_%s" % [Game.run_seed, Game.floor_num, coord.x*1000+coord.y]` + `stable_hash` 形式；本批 T1 实际**不使用** run_seed（纯函数），故任何新增 `Game.rng.rand*` 调用点即红 | 命中数 0 |

---

## V-F 规矩压低出卡（T4）

| 编号 | 判据 | 基准值 | 边界态 |
|---|---|---|---|
| V-F1 | 无违例（B=0）时：八坐标出卡三元组与 S33 冻结串**逐字相同** | 见 `_SCL_FROZEN_F3C` 同型基准串 | 不等 ⇒ 本批破坏了既有冻结面 |
| V-F2 | `breach>=2` 才生效；映射死值 `beast→wind_dance / hungry→ore_upgrade / hell→heal / asura→power_surge` | breach=1 ⇒ 与 V-F1 基准逐字相同；breach=2 ⇒ 至少一个坐标 slot1/slot2 变 | 阈值两侧都要验，防止「恒生效」与「恒不生效」两类假绿 |
| V-F3 | 并入方式：只并进 `dn`，pool 构造与顺序、派生 key、`#0/#1/#2` 三后缀、c2 判定式逐字不动 | SC1 四式计数仍 `1/1/1/1` | 新开池子逻辑即红 |
| V-F4 | **反证基准存在性（静态）**：`game_main.gd` 内同时存在三个 helper——生产 `_shrine_offers_for`、`_scl_offers_unwidened`（只撤 cal_dn）、`_scl_offers_rule_unpulled`（只撤 rule_dn） | 三者各自 `func` 头恰 1 处 | 少第三条 ⇒ M-10/M-11 无从判红 |
| V-F5 | **M-10/M-11 变异刀**（详见实施单 §C）：故意把 rule_dn 并段删掉／把阈值改成 `>=1`，探针必须**变红** | 两把刀各命中 ≥1 条 SC/SR 断言 | 刀下去仍全绿＝假绿，本批不放行 |
| V-F6 | oracle 复刻面自证：`_scl_offers_rule_unpulled` 与生产的唯一差异是「dn 恒 = td[1] ∪ cal_dn」（不许包生产函数） | 源码切片比对 | 包装式实现让 M-10 变成自我比较、永不红 |

---

## V-G AI 手感（T5）

| 编号 | 判据 | 基准值 |
|---|---|---|
| V-G1 | `AI_OVERRIDES` 表长 | 15 → **29**（`ENEMIES` 全集，缺项名单见实施单 T5） |
| V-G2 | 键合法性：所有键 ∈ `validate.AI_PARAM_KEYS`（12 键），所有值为正数值 | `problems=0` |
| V-G3 | **行为等价护栏**：`boss` 与 `echo` 两条 override 必须是**全字段恒等值**（`ai_range=1e9 / ai_cd=1e-6 / ai_dash=0.0 …`），使覆写后的读数与覆写前逐字相同 | 逐字段等值断言 |
| V-G4 | 强度面零污染：`hp/speed/dmg/score/xp` 29 条逐字节不变 | 与改前快照同 |
| V-G5 | 12 只 `chase` 怪现在各有不同的 `.get(k, 默认)` 读数；`wolf/vampire/minotaur` 等已在表内的 15 条**未被覆盖或重复写入** | 名单逐条比对 |

---

## V-H 图鉴平行字段 `dao_seen`（T1 附属）

| 编号 | 判据 | 基准值 | 边界态 |
|---|---|---|---|
| V-H1 | `codex.cfg` 出现 `[dao_seen]` 相邻键，值为道 id 数组 | 只增不减：历局并集 | 旧档缺键 ⇒ 空数组，不报错、不迁移 |
| V-H2 | 分母来源：`menu.gd` 底部行 `已历六道 · N/6` 的 N 取 `dao_seen.size()`，常量 6 取 `Data.DAO_ORDER.size()` | 6 | 🔴 **不得**落入 `CODEX_KINDS`／`_codex_id_valid`／`fexpect["themes"]`／`Data.FLOOR_THEMES.size()` 任何一条通道 |
| V-H3 | `validate.gd:256` 与 `menu.gd:488` 两处 `themes` 分母表达式**逐字符不变** | 与 S34 收盘快照同 | 变了＝动了冻结面 |
| V-H4 | 道首发现**不播** `见痕手记 ·` toast（`FLAVOR_BROADCAST_KINDS` 不含 dao） | 命中 0 | 一旦接入 `mark_codex` 会撞 FLAVOR 前缀覆盖门 |
| V-H5 | 写盘时机：`dao_seen` 随 `_write_codex_replay()` 那一次 `save_codex()` 落盘，不新增第二次写盘 | 写盘次数不变 | 中途退出靠进层时的即时 `save_codex()` 兜住 |

---

## 判据卫生（写给两边自己）

1. 本文所有行号均为 **2026-11-18 磁盘实测**（`grep -n` 坐实），引用优先给句子；后续批次复用前必须现场重 grep。
2. 静态门里回显的「行号」是腐烂引用，不作为判定依据；判定只看 `problems=` / `checked=N declared=N` / `[ERR]=` / `ok=false=` 四类计数与指纹行。
3. 主理人未亲自跑过的条目一律标 `UNEXECUTED`，⛔ 不计入 PASS。
