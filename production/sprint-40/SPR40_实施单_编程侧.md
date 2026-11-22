# SPR40 实施单 · 编程侧

批次：Sprint 40
日期：2026-11-18
发出方：主理人（设计侧）
配套实稿：`SPR40_设计实稿_武器族去火药枪化.md`、`SPR40_设计实稿_弹幕交互与盾反.md`、`SPR40_特色创新候选清单.md`
验收条款：**独立成文于 `SPR40_验证口径.md`**（本文只写「怎么改」，判对错看那份）

---

## 0. 本轮的三句话

1. **先做 A 组（近战清扫漂浮弹幕）**：零裁定依赖、零新状态、零 rng 风险，作者立刻能摸到。
2. **B 组（四把基础枪去火药化）等 D2 答复**——甲案（id 也换）要走一次冻结基线重登，⛔ 你自行改串变绿。
3. **C 组（盾/盾反）停在 RAISE/BLOCK 两层**，PARRY 与返还表等我回 C1~C6。

🔴 **通用硬前置（HP-0）**：任何一条开工前，先跑一次**改前基线**并把 `[SMOKE-META] fingerprint`、validate `problems`、各探针 `checked/declared` 抄进交付报告。**没有改前基数的交付我一律不核**（历史教训：帧数不足的假绿、行号腐烂、括号推论冒充原文）。

---

## 1. A 组 · 近战清扫漂浮弹幕（可立即执行）

| # | 落点 | 动作 | 约束 |
|---|---|---|---|
| A1 | `scripts/bullet.gd` | 新增纯 getter `func is_sweepable() -> bool`：`not friendly and pierce == 0 and explosive == 0.0 and bounce == 0 and frost == 0.0 and not homing and arc == 0 and cluster == 0` | 🔴 **单一真源**：生产侧与探针 oracle 必须同引此函数。⛔ 读私有 `_life`（setup 里有 `life_v if life_v > 0 else 1.4` 兜底，未回填实际值）。⛔ 任何副作用。⛔ 动 `setup()` 的参数位（第 8 参位占用是红线） |
| A2 | `scripts/player.gd:_swing()` | 在既有 `for e in get_tree().get_nodes_in_group("enemies")` 扫描**之后**、`Game.main._melee_pierce_armor = false` 那行附近**之后**，加第二条独立扫描：遍历 `enemy_bullets` 组，`is_instance_valid(b) and b.is_sweepable()` ∧ `distance_to(global_position) <= reach` ∧ `absf(angle_difference((b.global_position - global_position).angle(), _aim.angle())) <= half` → `b.queue_free()` ＋ 迸星 ＋ 计数 | 🔴 ⛔ Area2D、⛔ 新碰撞层/掩码（HP-5，会与 layer 8/mask 1\|4\|64 打架）。几何**复用同一个 `reach`/`half` 变量**，⛔ 另算一套清扫半径（数值待裁 A1 之前不许出现第二个常数） |
| A3 | 同上 | 早退路径核对：`if not skill_active() and mag() <= 0: _start_reload(); return` 这条 return **必须在清扫之前**（现状如此），⇒ 配额见底那一拍零清除。请写断言而不是靠读代码相信它 | — |
| A4 | `scripts/player.gd` | 新增两个计数器：`bullets_swept`（累计）、`last_sweep_count`（最近一次有效挥击清掉几颗）。整型 static 或实例字段自便，但⛔ 进存档、⛔ 进 E1 指纹串 | 🔴 探针要能现读；命名照 `melee_swings`/`melee_rng_draws` 的风格 |
| A5 | 视觉 | 迸星：`ExplosionScript` 的 `"spark"` 档即可（照 `bullet.gd:_impact()` 的写法），角度取 `-b.vel.normalized()` 决定的确定性参数 | 🔴 ⛔ `Game.rng`。要随机观感只准用 `Game.fx_rng`（`game_state.gd:41`，随局 `reset_fx_rng()` 播种）；首选确定性、无随机 |
| A6 | 词缀 | **不触发任何 trigger**。⛔ 蹭 `ON_SHIELD_BREAK`（那是环盾的，`player.gd:900`） | 若产品要求触发，回来找我裁 A3，别自己加 |

### A 组的 rng 纪律（🔴 逐字执行）

- `Game.rng` 消费相对改前**恒为 0**。三种禁止形态（详见弹幕实稿 §2.3）：命中分支里再抽、把已有抽取改成条件抽、用主流决定表现。
- 「每次有效挥击恒 1 次 `Game.rng.randf()`」这一行代码（`_swing()` 里 `var crit := Game.rng.randf() < crit_chance` 及其后的 `melee_rng_draws += 1`）**位置与次数一字不动**。
- 计时若需要（本组其实不需要）一律 `Game.FIXED_DT` 递减，⛔ raw delta、⛔ `Engine.time_scale`、⛔ `create_timer()`。

### A 组必须跑的门控

```
SMOKE=1 SMOKE_SEED=<钉死一个整数> SMOKE_META_FINGERPRINT=1 \
  godot --headless --path "D:/Create/Game/test-1" --quit-after 3200
```
- 🔴 `SMOKE_SEED` **必钉**（不钉会出现上百行假差异，这个坑已踩过）。
- 🔴 E1 指纹开关是 `SMOKE_META_FINGERPRINT=1`，**不是** `SMOKE_META`。
- 🔴 保存类冒烟要 `--quit-after 3200`，帧数不够会假绿。
- 残留原始日志里 `[SMOKE-NAV]/[SMOKE-CAM]/[SMOKE-E]/[SMOKE-LOOP]/[SMOKE-STALL]` 与时间戳属实时抖动，**不比对这些行**；汇总计数⛔ 用 `awk -F:` 配绝对路径（盘符冒号切错字段，恒得 0）。
- 新 worktree 先 `--headless --path <dir> --import`。

---

## 2. B 组 · 四把基础法器（等 D2）

### B0（现在就能做，纯只读）

| # | 动作 |
|---|---|
| B0-a | `grep -n '"rifle"\|"shotgun"\|"railgun"\|"launcher"' scripts/*.gd` 全量贴回，并**额外**手工确认第四处之后的隐藏点：`weapons.gd` 的 `icon()` 回退、`random_unlocked()` 空池 `return "rifle"`、`player.gd:give_weapon()` 回退、`game_main.gd:5337` 的 `_ml_equip("rifle", 30)`、`game_main.gd:2791-2792` 印记实现、`game_main.gd:42-51` 基线串。结论写成一张「位置 → 现文本 → 拟改后文本」的表交回，⛔ 动手 |
| B0-b | 把 DEFS 四条的 11 个数值字段（`dmg/interval/count/spread/speed/mag/reload/pierce/life/explosive/tint`）打印成快照存进 `production/sprint-40/`，作 §验证口径 V-W1 的对账基准 |

### B1~B11（仅在收到甲案授权后执行）

对应实稿 §4.1 的 M1~M11，逐条搬。要点重申：

- 🔴 **原子性**：DEFS 键名、四处回退链、`DROP_POOL`、初始槽与 `slot_mags` 初值、印记实现、印记文案、`GEN_NAMES` 四个键、基线串、探针装备 id —— **同一批落地**。漏 `GEN_NAMES`＝`Assets.g()` 返回 null＝屏上白框且**零报错**（AGENTS §4.3）。
- 🔴 **数值守恒**：除 `name/desc/icon` 外，任何字段变化都算越权，直接红。
- 🔴 **基线串**：`META_WEAPON_POOL_BASELINE` 改完，把新的集合内容原样交回主理人登记；⛔ 就地改串当作已完成。
- ⛔ 不改 `mw_cluster` 的中文名「集束榴弹」（`meta.gd:68`）——那是待裁 D4。
- ⛔ 不做全局「切枪」「补枪」语汇清理——那是待裁 D5（本批只清 `data.gd:217` 与 `data.gd:455` 两处）。
- ⛔ 删旧 PNG、⛔ 覆盖旧 PNG：`wpn_rifle/wpn_shotgun/wpn_railgun/wpn_launcher` 从 `GEN_NAMES` 摘掉即可，文件留盘。

### B12 · 四枚新图标（程序化绘制）

- 尺寸 **32×16 RGBA8**（🔴 ⛔ 16×16、⛔ 32×32；理由见武器实稿 §3.1：`pickup.gd:60` 的 1.1 倍缩放换算表按 32×16 建立）。
- 规格骨架：柄左锋右、主体沿水平轴、占宽 ≥26px、纯透明底、硬边像素、⛔ 抗锯齿/羽化、索引色 ≤10 色（含透明）。范式对齐 `_tools/spr25_art_gen.py` 文件头。
- 🔴 **新建脚本**放 `_tools/`（建议 `_tools/spr40_wpn_icons.py`），⛔ 修改 `spr25_art_gen.py` / `spr34_gen.py` 的共享逻辑与框架 prompt（后者一动就是整族重跑，那是 S34 R2 的事，未点头）。
- 自检走 `verify()` 范式：逐字段核 IHDR（宽高/位深/色彩类型），失败即非零退出。
- 绘制细节见武器实稿 §3.1 表格（笔／杵／尺／匣四张剪影必须互不相同）。

---

## 3. C 组 · 盾（RAISE/BLOCK 可做，PARRY 停手）

| # | 落点 | 动作 | 门 |
|---|---|---|---|
| C1 | `scripts/slug.gd`（＋ `boss.gd` 镜像处） | 新增 `apply_stun(dur: float)`：置 `_stun_t`，`> 0` 期间 AI 决策不推进、主动位移归零；`variant == "boss"` 直接 return | 🔴 ⛔ 冻结 `_knock`（与 dash 位移区间纠缠那条禁令同源）；⛔ 影响受伤公式/增伤；⛔ 改 `take_damage` 签名；计时走 `FIXED_DT` |
| C2 | `scripts/player.gd` | RAISE 态 ＝ `WeaponsClass.is_melee_kind(String(cur_def()["kind"])) and String(cur_def()["kind"]) == "shieldbash" and _stance_t > 0.0`；BLOCK ＝ RAISE 且不在 PARRY 窗口 | 🔴 **共用 `_stance_t`**（B2a 那个入口），⛔ 另起第二套并行窗口计时。⛔ 新增 action（`ACTION_DEFS` 18 条不动） |
| C3 | `scripts/player.gd` | 扫描时机排在 `_update_aim_and_fire` **之后**（同帧「刚挥的盾 vs 刚到的弹」必须有确定答案）；⛔ 改动四个输入更新的调用顺序（`_update_anim→fire→bomb→skill→relic`） | — |
| C4 | BLOCK 结算 | 伤害 ×`BLOCK_MULT`（**数值待裁 C6**；先用占位常量并在交付报告里点名它是占位）；与 `relic_shield_t` 同时生效时按环盾吃掉这颗弹计，⛔ 双计 | 🔴 优先级顺序照弹幕实稿 §3.2 步骤 3 |
| C5 | 计数 | `parry_count` / `block_count` / `shield_absorbed_dmg` 三个**分开**记，⛔ 只记总数 | 只有总数的断言查不出「所有攻击返同一种东西」 |
| ⛔ | PARRY 窗口、返还表、`RETURN_MULT`、`T_*` 分类映射 | **停手等我回 C1~C6** | 返还弹一律 `crit=false`、零 `Game.rng` 抽取（见弹幕实稿 §4.2） |

---

## 4. D 组 · 三项顺带实测（只测只报，⛔ 修）

| # | 事项 |
|---|---|
| D1 | `bullet.gd:_split_cluster()` 在主叙事流上抽 3 次（`Game.rng.randf() * 0.4` 在 `for i in 3` 内）。实测：同 seed 下 `mw_cluster` **命中** vs **未命中** 两条路径，后续 `[SMOKE-META] fingerprint` 是否漂移。漂移就把两串逐字贴回来 |
| D2 | `_fire()` 在 `n==1 且 not autopilot` 时额外抽一次 `randf_range(-1.5, 1.5)` ⇒ 弹幕侧抽取本就随 count 变化。确认这条**不影响**近战侧「恒 1 次」口径的表述（只回答，不改代码） |
| D3 | `validate.gd:416` 那条 dps 门「一律从 `Weapons.DEFS` 与 `Data.BOSS_PULSE_BASE` 现算」：贴出现算式，确认它统计的是玩家主动开火路径，不会被我方将来的「盾反返还借用 DEFS 模板」污染 |

---

## 5. 概念稿返修（仅在 D6 得到「跑」的答复后执行）

- 只 3 张：`wpn_rifle`/`wpn_shotgun`/`wpn_railgun` 对应的 `<SUBJECT>` 槽（新句子见武器实稿 §7）。
- 🔴 框架 prompt 一句一字不动（一族一句 ⇒ 改框架＝整族重跑，那是 S34 R2 未点头的事）。
- 🔴 产物落**新目录** `_tools/_artgen/concepts_spr40/`，⛔ 覆盖 `concepts/` 里的旧件（对照证据要留着）。
- 🔴 ⛔ 任何产物直接入库为游戏资产；新 4 枚游戏内图标走 B12 的程序化路线。
- ⛔ 顺手把其余 36 张一起重跑。

---

## 6. 禁止事项（编号，违反任一条我打回）

1. ⛔ 修改 `scripts/*.gd` 中任何与本单无关的行——34 个 `.gd` 全冻结是整文件字节快照，改一行注释也会变 md5。
2. ⛔ 新增/修改 `ACTION_DEFS` 条目（现值 18 条）。
3. ⛔ 触碰 `bullet.gd setup()` 的第 8 参位。
4. ⛔ 修改 `meta.gd` 的 `UNLOCKS`。
5. ⛔ 更换 `shardbearer.png`。
6. ⛔ 让任何新计时使用 raw `delta` / `Engine.time_scale` / `create_timer()`；一律 `Game.FIXED_DT`。
7. ⛔ 破坏「每次有效挥击恒 1 次 `Game.rng.randf()`」；⛔ 在清扫/盾反路径新增主流抽取（要用随机走 `Game.fx_rng`）。
8. ⛔ 自行修改任何断言或冻结串以让门变红转绿（含 `META_WEAPON_POOL_BASELINE`）；发现口径漏洞**如实报给我**，由我裁是改口径、改断言还是改实现。
9. ⛔ 新增持久状态字段而不申报（持久状态＝E1 指纹风险源）。
10. ⛔ 把清扫/盾反的词缀触发蹭到既有 trigger（如 `ON_SHIELD_BREAK`）上。
11. ⛔ 修改 `_tools/AUTORUN_值守报告.md`、`_tools/AUTORUN_LEDGER.md` 等共享台账（本轮主理人也不碰）。
12. ⛔ 动 `D:\大纲` 任何文件（那边有自己的纪律，我是外人）。
13. ⛔ 在未获 D2 答复前执行 B1~B11；⛔ 在未获 C1~C6 答复前实现 PARRY 与返还表。
14. ⛔ 交付报告里省略改前基线（HP-0）。

---

## 7. 交付格式（照 S38 惯例）

一份 `production/sprint-40/SPR40_交付_<项号>.md`，至少含：
1. 改前基线（fingerprint 逐字串、validate problems、各探针 checked/declared、`[ERR]` 计数、`ok=false` 计数）；
2. 改后同五项；
3. churn：只比断言行，且 `SMOKE_SEED` 已钉；
4. 变异刀清单（每条写明「删掉哪一行/改哪个常数 → 应该红的那条断言」，附实测红条数）；
5. 偏差申报：与本单不符之处逐条列，⛔ 沉默处理；
6. D 组三项实测的原始输出片段（贴句子，别只贴结论）。
