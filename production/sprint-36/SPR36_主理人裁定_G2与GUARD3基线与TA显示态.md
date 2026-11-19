# SPR36 主理人裁定 · G2／GUARD-3 基线串／T-A 显示态（口径缺口三补）

批次：Sprint 36
裁定人：主理人（创意侧），2026-11-18
配套：`SPR36_实施单_编程侧.md`（rev2，PARTIAL）／`SPR36_设计实稿_BOSS专武与无限制口径.md`（rev2）
性质：**本文件即书面放行 + GUARD-3 基线正典 + T-A 显示态靶**。编程侧按本文落断言，⛔ 不再自定基线、不再越级问作者。
行号纪律：本文所有行号为 **2026-11-18 主理人在当前工作树 `grep -n`/Read 现场坐实**；引用优先给句子，落地前照例重 grep。

---

## R-1｜G2 裁定：**有条件放行**——T-A 现在可开工

**结论**：S35 不算收官，但 **不阻塞 T-A**。放行范围到 T-C 数据侧为止，条件如下：

| # | 条件 | 性质 |
|---|---|---|
| C1 | 🔴 **S35 返修实例不得合入 `scripts/`**。T-A 及以后各步的基线＝**当前工作树**（HEAD=`4dafdaf`＋未提交微批）。若 S35 返修后落地牵动 `game_main.gd` / `data.gd` / `validate.gd`，T-A 的「改前」指纹必须**在新基线上重采一遍**再动手 | 顺序约束 |
| C2 | T-A 单独提交、自带 §2 T-A 红块的 E1 三档实测义务，一条不减 | 原单照办 |
| C3 | S35 正式收官（核验＋刷冻结表）**先于 S36 收官**；两批的门控日志分开采集、分开归档，⛔ 不许拿 S35 某轮日志当 S36 的「改前」对照 | 归档约束 |

**放行理由（三条实证）**：

1. **S35 的交付面本来就是文档**：`production/sprint-35/` 磁盘上只有《设计实稿》与《验证口径》两份（返修稿在编程侧会话里，尚未落盘），零 `.gd` 改动。它「没收官」收不掉任何代码前置。
2. **解锁态的全部读取点都在 `meta.gd` 及其调用方，S35 没有一行碰过它们**（本轮 grep 穷举）：
   - `Meta.is_unlocked`（`meta.gd:141`）消费方：`game_state.gd:963/:973`、`menu.gd:884/:887`、`upgrades.gd:93`、`game_main.gd:2527/:2599`
   - `Meta.content_available` ← `game_state.gd:998 meta_content_unlocked()`：消费方 `weapons.gd:79/:89`、`upgrades.gd:54`、`relics.gd:41`、`game_main.gd:2483/2487/2491/2502/2506/2510/2530`
   - `Weapons.unlocked_ids()`（`weapons.gd:76`）**全仓零生产消费方**（含 `random_unlocked()` 在内没人调它——别被名字骗了）
   S35 的 T1–T5（道派生／改名／规矩／出卡／AI 表）与这组函数无交集 ⇒ 「等 S35」换不来任何确定性，只换等待。
3. **G2 要防的风险已经被 §2 T-A 红块自己覆盖**：那行的真实位置是 `game_main.gd:3012`（旧引 3005 已漂 7 行）——Boss 房掉落走 `_random_weapon()`（`:3037`）→ `Weapons.random_unlocked()`，后者**只遍历 `DROP_POOL`**（`weapons.gd:88` 起循环体首行 `for id in DROP_POOL:`），mw_* 进不进可用集都不改它的过滤结果。残余风险只剩「其它系统在 Boss 房之前消费 rng 且分支数依赖解锁内容」——这正是三档指纹实测要抓的，不需要 S35 状态来兜。

**边界提醒（不是闸）**：T-B3 把 `:3012` 改成定向掉落、绕开 `_random_weapon()`，那是 T-A 之后的第二刀，E1 靶沿用实稿 F 项「恒消耗 1 次」契约（`weapons.gd:93` 注释原文），与本放行无关。

---

## R-2｜GUARD-3 默认态武器池基线串（两条，逐字）

### 先钉住一个语义陷阱（🔴 断言必须写清读的是哪条路径）

- **打印行** `[SMOKE-META] weapon pool: [...]`（`game_main.gd:2439`）来自 `_meta_pool_ids("weapon")`（`:2497`），它对 **`Weapons.DEFS` 全表**做 `meta_content_unlocked` 过滤（`:2509`）⇒ 含 rifle、含 mw_*，**不含**任何池外 id。
- **抽卡路径** `Weapons.random_unlocked()` 只过滤 **`DROP_POOL`**（`weapons.gd:88`）⇒ 永远最多 3 个 id。
  两者不同源。⛔ 拿下面任一串去断言 `random_unlocked()` 的候选集，必假红。

### B 串（T-A 之前 · 当前盘上真值）

```text
[SMOKE-META] weapon pool: [rifle, shotgun, railgun, launcher]
```

- **来源**：主理人 2026-11-18 本机 headless 实跑，非抄文档。命令与环境：`SMOKE=1 SMOKE_SEED=12345 SMOKE_META_POOL=1 SMOKE_META_POOLASSERT=1 --quit-after 3200`，干净 env（未挂 FORCE_*/JUMP_FLOOR/SMOKE_CALAMITY），跑前删净 `user://_smoke_meta*.cfg`。日志留档：`test-1/_tools/spr36_guard3_baseline.log`。
- 同轮实测旁证：upgrade pool 14 条、relic pool 10 条、`pool assert=OK pool=14`——三条 print 都只在各自开关下出现，断言取**内容**时按 `SMOKE_META_POOL=1` 采集。
- ⚠️ 顺带如实报告（不是本批缺陷）：`game_main.gd:2445` 的 `pool assert=OK pool=%d` 打的是 **upgrade** 的可用数（`_meta_usable("upgrade")`），不是 weapon 的——旧认知「pool=7」系误记，别把它当武器断言的旁证。

### A 串（T-A 之后 · default:true、requires 清空）

```text
[SMOKE-META] weapon pool: [rifle, shotgun, railgun, launcher, mw_swarm, mw_arc, mw_cluster]
```

- **推导依据（静态门，本轮全部实读坐实）**：
  1. 顺序＝`DEFS` 声明序（`weapons.gd:11` 起：rifle→shotgun→railgun→launcher→mw_swarm→mw_arc→mw_cluster），Godot Dictionary 保序；
  2. `Meta._ensure_index()`（`meta.gd:99`）会把 `default:true` 节点收进 `_defaults`（`:111-112`），`is_unlocked`（`:141`）经 `_defaults.has(id)`（`:147`）返回 true ⇒ 三个 mw_* 无条件可用；
  3. `validate.gd _meta_default_usable`（`:656`）对 gated+default 同样计数（`:662` 那行 `elif bool(META.node(gid).get("default", false)):`）⇒ 默认可用武器 4→7，阈值 `MIN_DEFAULT_USABLE.weapon = 2`（`meta.gd:88`）仍绿。
- **诚实披露**：A 串是**静态推导靶**，主理人未跑改后运行时（`.gd` 冻结，我不可能不违约地实测）。⇒ **T-A 合入当天，编程侧贴出的该 print 行必须与 A 串逐字一致；不一致＝先查、上报、⛔ 不许改本串迁就实现。**

### 断言形态要求（内容集，⛔ 有序字符串相等）

新增断言建议命名 `MG-PW1`（meta-guard weapon pool），置于 POOLASSERT 块内（现有 `Dev.check(have >= need, ...)` 在 `game_main.gd:2444`，内容集断言在它旁边加，不复用它）：

1. **集合相等**：`_meta_pool_ids("weapon")` 与当前档位基线（改前比 B、改后比 A）互为子集（size 相等 ∧ 每个元素命中），⛔ 不比 join 后的整串顺序；
2. **前提守卫如实标注**：B 串成立的前提是「本次运行读的是默认解锁态」。探针会写隔离档 `user://_smoke_meta.cfg`（往返测试还原后落盘），跨 run 残留可污染 owned 集 ⇒ 采集前删档（七件套第 0 步已有此条）。若将来支持自定义档，此断言须显式声明只在默认档生效；
3. **冻结串卫生**（上一批教训延续）：这两串是**新立断言**，⛔ 塞进既有 19 条任何一条的比对面；
4. T-B1 追加 14 把 `bw_*` 后池会变（17 条），届时**另立第三串**并重跑本条推导，⛔ 就地改 A 串。

---

## R-3｜T-A 军械页显示态靶（补进实稿 §6.1 与 §7，本批生效）

### 先纠正一个前提：今天不存在「已购买×已拥有」重叠态

实读 `menu.gd _add_unlock_row`（`:850`）：状态标签只有一个来源——`var owned := Game.meta_is_unlocked(id)`（`:884`），而 `Meta.is_unlocked` 对 `_defaults` 命中即 true（`meta.gd:147`）。所以 T-A 后三行直接显示「已解锁」，**没有第二态可叠**。实稿 §6.1 P-改语义格子里那句「需 UI 处理」按本节裁定收口。

### D1–D5 靶值（headless 可判，环境 `SMOKE=1 SMOKE_META=1`，默认档）

| # | 判据 | 基准值 | 边界态 |
|---|---|---|---|
| D1 | 三行状态标签文本（`u_mw_swarm/u_mw_arc/u_mw_cluster`） | 逐字 `已解锁`，绿色 `Color(0.55, 0.95, 0.6)`（`menu.gd:892-894` 现有分支，⛔ 新增第四态文案） | 旧档已购 u_mw_arc：同文案；其 requires 已被清空 ⇒ 不得闪现「前置未满足」 |
| D2 | 按钮 | `text="已解锁"`、`disabled=true`（`:907-908` 现逻辑天然覆盖，零改动） | 点击无效；⛔ 不得出现「解锁 · 100 结晶」字样 |
| D3 | 🔴 **cost 在 owned 分支不可见** | 三行渲染文本中均不含各自的 `40/60/100` | 余额任意（0 或 100000 都一样）——这是「无限制」的表层落点：还在列表里是收藏志，不是价目牌（实稿 §5.4） |
| D4 | 页面行数与图标门 | `unlock page rows=8`（print 在 `menu.gd:823`）；`unlock icons resolved=8/8`（`:825`）；白框断言（`:827`）不红 | ⛔ 从 UNLOCKS 移除节点来「藏掉」已拥有的免费收藏——行必须还在 |
| D5 | 购买语义封闭性 | `can_unlock`（`meta.gd:151`）在 `:154` 对 is_unlocked 直接 false ⇒ `Game.meta_unlock`（`game_state.gd:972`）拒绝：余额不变、`unlocked` 数组不长、**boost 键不写**（`:984` 仅 kind==upgrade，双保险） | 反复尝试购买无副作用累积 |

### D6（本裁定的连带后果，必须写进口径）：mw_* 永久 ×1.5

`upgrades.gd _weight`（`:86`）在 `:93` 读 `Game.meta_is_unlocked(node_id)` → mult=1.5；`:96` 的 ×6 引导乘子只对 upgrade 节点存在（boost 只在 `meta_unlock` 成功时写入，kind==upgrade 才写）。T-A 后三个 mw_* 节点**永远** is_unlocked=true ⇒ 这三张卡**永久享受 ×1.5 可见度补偿，且永远不会过期**。

- **裁定：接受，不改 `_weight`**。理由：这正是实稿 §7.2「解锁可见度补偿」机制对「本来就拥有」内容的自洽表达；改它＝动抽取权重面＝牵 E1，超出 T-A 授权。
- **机检义务**：churn 对比时这三张卡的出现率位移属**预期差异**，如实记录，⛔ 当 bug 修。

### D7 边界态（归 T-B3，不在 T-A 断言面）

专武 id 走 `drop_pickup(..., "weapon", 1, id)`（payload 形参见 `game_main.gd:3707`）→ `pickup.gd:139 give_player_weapon(payload)` → `game_main.gd:4350` → `player.gd:202` 双槽。HUD 只查 `DEFS`（`hud.gd:591 Weapons.icon(id)`），与 Meta 解锁态**完全无关**——「拿上手就能用」零新码。商店货架（`game_main.gd:3243`）与 `shop_stand.gd:39/:81` 同理按 payload 直读 DEFS。

---

## R-4｜事实回报受理 + 一处指针订正

**GUARD-1 改造：收下，符合 HP-1 与 §4 判据 2**（`declared` 数变化如实报，⛔ 不为凑旧数删断言）。两点补充：

1. **行为位 ⊄ 反超位，互不遮蔽**：实稿 §6.3 的 14 把 `bw_*` 用的是 `pierce/explosive/count/spread/mag/life/frost/tint/dmg/interval`——没有一个落在 `homing/arc/cluster` 上。⇒ GUARD-1 的遍历即使加了 T-B1 也**仍只圈 mw_\* 三把**；「declared 会变」在 T-B1 之后大概率**不会发生**，别把它当成验收信号。真正被 14 把牵动的断言面是 **C3 的 DPS 比值表**（`dmg/interval ≥ dps_boss × 1.25`，每组恰好 2 把）。
2. **「哑位」段请保留并升格为独立性质**：mw_* 之外任何条目声明 homing/arc/cluster 却全为零都会红——这条正好反向锁死 §6.3 名单「14 把不得用这三个键」（用了就必须给非零值，否则当场红）。变异刀结果照旧两向贴（改坏→红、还原→绿）。

**指针订正（落文档前请替换）**：实施单 §2 T-A 与实稿 §6.1 引用的「Boss 房清场掉武器那一行 `game_main.gd:3005`」在当前工作树实为 **`:3012`**（同一句 `drop_pickup(_arena_center() + Vector2(-34, -10), "weapon", 1, _random_weapon())`，本轮 grep 坐实）；`_random_weapon()` 由 `:3030-3031` 漂至 **`:3037`**。T-B3 施工面认句子不认行号。

---

## 遗留闸口状态（本次裁定后）

- G2：✅ 已按 R-1 书面放行（附 C1–C3 三条件）。
- GUARD-3：✅ 基线已由本文给定（B 串实测、A 串推导待 T-A 日实测闭合）。
- T-A 显示态：✅ 靶已补（D1–D7），同时构成实稿 §6.1/§7 的 rev3 补丁——下次修订实稿时并入，本文件先行生效。
- W7（图鉴第七类）：🔲 仍在判断栏，T-D 继续按 C 备而不做。
- 本文件不新增任何 `.gd` 改动授权；冻结表 5 处 FAILED（`data/game_main/game_state/shrine_panel/validate`）维持 §0 G3 原样，收官由主理人刷。
