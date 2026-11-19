# SPR39 验证口径 · 手记↔机制对照

批次：Sprint 39
日期：2026-11-20
配套：`SPR39_设计实稿_手记只说玩家观测得到的事.md`（机制本体与处置）／`SPR39_实施单_编程侧.md`（落地清单）／`SPR39_对照表.json`＋`SPR39_flavor_contract.py`（机检件）／`SPR39_主理人核验.md`（独立核验）
性质：**不看代码实现即可判对错**。每条给「可观测判据 + 基准值 + 边界态」。编程侧门控必须能被主理人独立复现。

约定：
- **基准档**＝`SMOKE=1 SMOKE_SEED=12345`（churn 对比必钉，不钉会产生上百行假差异）。
- 残留原始日志行 `[SMOKE-NAV]/[SMOKE-CAM]/[SMOKE-E]/[SMOKE-LOOP]/[SMOKE-STALL]` 与时间戳**不比对**。
- 凡本口径标 `UNEXECUTED` 的条目，**不得计入 PASS**。
- 🔴 本口径所有"锚点"用**函数名/字段名**，⛔ 行号（行号会腐烂；本轮已现场 `grep -n` 坐实过一次，但不落文档）。

---

## V-A 五条错位的处置是否落地（文案面）

| 编号 | 判据（可观测） | 基准值 | 边界态 |
|---|---|---|---|
| V-A1 | `data.gd` FLAVOR `bosses/prism_warden` 的 value 中，子串 `光缝` 与 `核` 的命中数 | 各 = **0** | ≥1 ⇒ 空承诺仍在货里，整条红 |
| V-A2 | 同上 key 的 value 含子串 `碎片变色` | 命中 = 1 | 0 ⇒ 改到了别的句子 |
| V-A3 | FLAVOR **全部 74 个 value** 拼接后扫 `弹匣留一半` | 命中 = **0** | ≥1 ⇒ §1④ 措辞归属未生效 |
| V-A4 | FLAVOR 全部 value 拼接后扫 `子弹会拐弯` | 命中 = **0** | — |
| V-A5 | `themes/silent` 的 value == `静默层。天道静虑，小地图整块没了，只能靠自己看。`，且含 `小地图` ＋ `没了`／`消失` 之一（语义须是「看不到」而非「去看」） | 成立 | 若写成 `多看小地图` ⇒ **反向建议复发，必红**；若含 `虫也少` ⇒ 无锚点断言，本批不授权（见 V-B9 说明） |
| V-A6 | `themes/pressure` 的 value == `高压层。修罗斗诤，虫更快，拾到的残响也多。`，含 `残响` | 命中 = 1 | 0 ⇒ 值钱那条仍没说；若含 `气浪会把人推开` ⇒ 把 Boss 专属危害写成整层性质，必红 |
| V-A7 | `bosses/third_boss` 的 value **逐字未变**（范本保护） | == `玄渊之主。地狱旧客，比熔潮慢半拍，比守望者狠。` | 改动一个字符即红 |
| V-A8 | `themes/magma`／`themes/toxic`／`themes/vein` 三条 value **逐字未变**（被 `contains` 断言锁着） | magma 前缀 `岩浆层。地狱热狱`；toxic 前缀 `毒巢。饿鬼食毒`；vein 含 `人间拾痕` | 任一变动 ⇒ `player._floor_sign_probe()` 当场红，属预期联动，不许改断言掩盖 |
| V-A9 | FLAVOR 总条数 | == **74** | ≠74 ⇒ `_floor_sign_probe()` 死数断言红；本批不授权改这个数 |
| V-A10 | 四条改写后的 value 均以 `。` 收尾，且 `len()`（含标点）≤ **25** | 实测 23 / 22 / 21 / 24，4/4 通过 | 无句号 ⇒ 图鉴多条目 `"　".join` 黏行（`menu._build_codex` 注释里的既有教训）；超长由门 G-6 拦 |

---

## V-B 锚点真实性（这些是本口径的"事实源"，主理人已实读，编程侧须复现）

| 编号 | 判据 | 基准值（磁盘现值） | 用途 |
|---|---|---|---|
| V-B1 | `boss.gd` 成员 `skill_interval` 初值 / `boss2.setup()` 赋值 / `boss3.setup()` 赋值 | `3.0` / `2.2` / `2.6` | 支撑 ①「慢半拍」与 ④新文案「脉冲比守望者密」 |
| V-B2 | 三文件 `setup()` 内 `max_hp` 基数 | `320.0` / `360.0` / `360.0`，缩放式 `(1.0 + (floor_num - 4) * 0.12) * Game.main.abyss_hp_mult` 三处一致 | 支撑 ①「狠」与新文案「壳厚一档」 |
| V-B3 | `game_main._apply_floor_theme()` 的 `match _theme_rule` 分支集合 | 恰 `{pressure, ice, swamp}` 三支；`pressure` 支内含 `enemy_speed_mult = maxf(enemy_speed_mult, 1.3)` 与 `diamond_mult = maxf(diamond_mult, 1.5)` | 支撑 ③ 新文案两个可测项 |
| V-B4 | `game_main._apply_floor_theme()` 内 `hud.set_minimap_hidden(...)` 调用次数与参数 | 恰 **2** 次：早退支 `set_minimap_hidden(false)`；末尾支 `set_minimap_hidden(_theme_rule == "silent")` | 支撑 ⑤（反向建议的证据本体） |
| V-B5 | `boss.gd _pulse_theme(rule, k)` 的 match 分支 rule 集合 | 恰 `{magma, ice, vines, "toxic"/"swamp", vein, pressure, silent}`；⛔ `prism`／`seam`／`light` | 支撑 ②「光缝不存在」 |
| V-B6 | `boss.gd _ready()` 内碰撞体外形的构造次数 | 恰 **1** 个 `CollisionShape2D`（`CircleShape2D.radius = 16.0`）；`core` 是 `Sprite2D.new()`，⛔ 独立 hitbox | 支撑 ②「核不可分」与 M-A 代价第 1 条 |
| V-B7 | `boss.gd take_damage(...)` 体内 `hp -=` 出现次数 | 恰 **1**；函数体内 ⛔ 部位/倍率分支 | 同上 |
| V-B8 | `weapons.gd DEFS` 中含 `homing` 键的条目 id 集合 | 恰 `{mw_swarm}` | 支撑 ③「拐弯只在玩家武器上」 |
| V-B9 | `FLOOR_THEMES` 第 7 项 `pool` 的值 ＋ `pool_for_floor()`→`FLOOR_POOLS[p]` 的解析链 | `pool: 2`，而 `FLOOR_POOLS[2]` 有 **8** 种敌人 ⇒ **pool 是权重表编号，不是密度** | 🔴 反证用：证明「虫也少」这类数量断言**没有**锚点，故 ⑤ 的新文案⛔ 含它。（八主题 pool 分布 `{vein:4, toxic:3, pressure:4, silent:2, magma:4, ice:2, swamp:3, vines:2}`） |
| V-B10 | `player._start_reload()` 早退条件原文 | `if _reload_t > 0.0 or mag() >= mag_cap(): return` | 证明「满弹不许换弹」是现状副产物、与 S35 `hungry` 的惩罚式规矩不同物 |

🔴 **V-B 的性质声明**：V-B1–B10 是**验效果型的事实核对**（两侧来自磁盘实读），不是常量自比较——它们的价值是给 V-A/V-C 提供基准，本身不构成"机制已验证"。

---

## V-C 对照表与静态门（机检面）

| 编号 | 判据 | 基准值 | 边界态 |
|---|---|---|---|
| V-C1 | `python production/sprint-39/SPR39_flavor_contract.py` 退出码 | **0**，且末行打印 `flavor contract: ok rows=74` | 非 0 ⇒ 不得交付 |
| V-C2 | 表行数与 `Data.FLAVOR.size()` 相等 | 74 == 74 | 不等 ⇒ G-1 红 |
| V-C3 | 每个 `anchors[].needle` 在指定文件的**非注释行**命中 ≥1 | 全通过 | 任一 needle 零命中 ⇒ G-2 红并打印 `key + needle` |
| V-C4 | `text` 与 `data.gd` 该 key 的 value 逐字相同 | 74/74 | 漂移 ⇒ G-3 红（这次五连错的成因正是没人做这一步） |
| V-C5 | `forbidden_substrings` 全局扫描 | 零命中；其中 `弹匣留一半` 登记 `reserved_for: bw_slack_half` | 命中 ⇒ G-4 红 |
| V-C6 | 表结构自核（主理人已实测） | `rows` = **74** 且与 FLAVOR 键集全等；`anchors` 合计 **99** 条、剥注释后命中率 **99/99**；四行改写行的 `text` 与 `prev_text` 不等、其余 70 行相等 | 出现 `pending_gate` 或行数 ≠74 ⇒ 门没跑或表被截断，记 UNEXECUTED。（机制票在 `mechanism_votes` 顶层字段里，⛔ 塞进 `status`——那会让 G-1 的键集比较失真） |
| V-C7 | 🔴 **变异刀 K1**：表内 `themes/silent` 的 needle 由 `set_minimap_hidden` 改为 `set_minimap_visible` | 门**必须红**（G-2） | 不变红 ⇒ 门是假的，`INCOMPLETE` |
| V-C8 | 🔴 **变异刀 K2**：`data.gd` 的 `themes/pressure` value 临时改回含 `子弹会拐弯` | 门**必须红**（G-3；若同时命中 G-4 亦如实报） | 同上 |
| V-C9 | 🔴 **变异刀 K3**：任一 FLAVOR value 临时塞入 `光缝` | 门**必须红**（G-4） | 同上 |
| V-C10 | 三把刀还原后再跑 | 退出码 0、`rows=74` | 还原不干净（diff 非空）⇒ 返工 |

⚠️ 刀的临时改动**只允许在工作树**，跑完立即还原，⛔ commit、⛔ 借"跑刀"名义留下 `.gd` 变更。

---

## V-D 七件套回归（本批不得让任何一门变红）

| # | 判据 | 本批特别含义 |
|---|---|---|
| 1 | `validate problems=0` | 含既有 FLAVOR 覆盖门（`_check_codex()` 里按 `/` 前缀分桶计数）与 `CODEX_BOSS_NAMES` 三条 Boss 手记存在性门 |
| 2 | 每探针 `done checked=N declared=N` | `flavor` / `floor_sign` 两族探针的 **N 必须与本批基线完全相同**（本批不改条数、不改结构） |
| 3 | `[ERR]`=0 | 计数用 `cat *.log \| grep -a -c '\[ERR\]'`（⛔ `awk -F:` 配绝对 Windows 路径会把盘符冒号切错、恒得 0） |
| 4 | `ok=false`=0 | 同上 |
| 5 | E1 指纹逐字不漂移 | `SMOKE_META_FINGERPRINT=1` × seed {12345, 777, 42} 三档；**本批理论上不可能漂**（文案不在 rng 路径）——一旦漂，先怀疑有人顺手改了逻辑，不要重定基线 |
| 6 | churn 只比断言行 | 钉 `SMOKE_SEED=12345`；断言行差异**只允许出现在含被改四个 value 的行**（`floor_sign` 第二行拼装、`见痕手记 ·` toast、图鉴手记行渲染三类） |
| 7 | 冻结状态如实报 | 收官由**主理人**手工刷 `SPR21-FROZEN.md5`；本批预期新增 FAILED 面：`scripts/data.gd`（今天已在 FAILED 列表内，故**FAILED 总数不应变化**） |

### V-D 特别条款：文案上屏三通道都要实测（不能只验表）

| 编号 | 判据 | 基准值 |
|---|---|---|
| V-D-a | 层签第二行：`Game.floor_num = 7` 后调 `update_floor_sign()`，`hud._floor_sign_sub_label.text` 含 `themes/silent` 的**新 value 全文** | 含，且 `visible == true` |
| V-D-b | toast：清 `codex["themes"]` 里的 `pressure` → `mark_codex("themes","pressure")` → `_flush_flavor_toast()`，`hud._toast.text` 以 `见痕手记 · ` 开头并含新 value 全文 | 成立 |
| V-D-c | 图鉴：`menu._build_codex()` 后遍历 `menu._rows` 的 Label，存在一行同时含 `　手记：` 与新 `bosses/prism_warden` value 全文 | 成立 |
| V-D-d | 🔴 **反向检查（本批新增，专抓"表绿了但屏幕没变"）**：上述三通道里，⛔ 任一处仍能扫到旧串 `别站在光缝里`／`多看小地图`／`子弹会拐弯`／`弹匣留一半` | 四旧串在三通道命中数全 = 0 |

> V-D-a…d 是**验效果型**（观测点在界面拼装末端，与被测字符串之间过了真实函数）。只做 V-C 不做 V-D，就是 AGENTS §5 警告的「只验标志不验数值」。

---

## V-E 门禁清单（本批交付必须附实测原文）

```bash
cd "D:/Create/Game/test-1"
GODOT="D:/SteamLibrary/steamapps/common/Godot Engine/godot.windows.opt.tools.64.exe"
rm -f "/c/Users/TangUser/AppData/Roaming/Godot/app_userdata/test_1"/_smoke_*.cfg*

# 8）本批新门（先跑它，红了不用往下走）
python production/sprint-39/SPR39_flavor_contract.py          # 期望 exit 0 + flavor contract: ok rows=74

# 基线（干净 env，勿挂 FORCE_* / JUMP_FLOOR / SMOKE_CALAMITY —— 它们会改随机流）
SMOKE=1 SMOKE_SEED=12345 "$GODOT" --headless --path . --quit-after 3200 > _tools/spr39_base.log 2>&1
# E1 指纹三档（开关是 META_FINGERPRINT，不是 SMOKE_META）
for s in 12345 777 42; do SMOKE=1 SMOKE_SEED=$s SMOKE_META_FINGERPRINT=1 "$GODOT" --headless --path . --quit-after 3200 > _tools/spr39_fp_$s.log 2>&1; done
# 文案上屏三通道（V-D）
SMOKE=1 SMOKE_SEED=12345 SMOKE_FLAVOR=1 SMOKE_FLOOR_SIGN=1 "$GODOT" --headless --path . --quit-after 3200 > _tools/spr39_flavor.log 2>&1
# 静默层语境（V-D-a 需要 floor=7）
SMOKE=1 SMOKE_SEED=12345 SMOKE_JUMP_FLOOR=7 SMOKE_FLOOR_SIGN=1 "$GODOT" --headless --path . --quit-after 3200 > _tools/spr39_f7.log 2>&1
```

⚠️ `SMOKE_SAVE` 探针要 `--quit-after 3200` 才落地（不足会报出帧数不够的假绿）。`SMOKE_DAILY` 会用日期覆盖 `SMOKE_SEED`，跨批对照禁用。
⚠️ `SMOKE_JUMP_FLOOR` 吃的是**层号**不是布尔；`SMOKE_FORCE_THIRD_BOSS` 等 `FORCE_*` 会改随机流，E1 双跑⛔ 挂。

---

## V-F 反哺 S36 的两条口径（不新增工作，只登记依赖）

| 编号 | 判据 | 结论 |
|---|---|---|
| V-F1 | S36 §6.3 `bw_core_hammer`「敲核槌」的出处注释若引用「砸它的核」这句 FLAVOR | 本批改写后该引用**失效**；S36 侧须改为引用机制票 M-A，或在 M-A 落地前把该把的"抢的是哪一下"改写为不依赖部位的表述 |
| V-F2 | S36 §6.3 `bw_slack_half` 的 `desc` | ⛔ 含 `留一半` 三字（G-4 的 `reserved_for` 只保证 FLAVOR 面不撞车，武器 desc 面由 S36 自己的 T-C 门看守；此处仅登记口径，不替 S36 改） |
