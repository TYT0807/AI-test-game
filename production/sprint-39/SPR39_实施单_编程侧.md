# SPR39 实施单 · 编程侧

批次：Sprint 39（手记只说玩家观测得到的事）
日期：2026-11-20
出单人：主理人（设计侧）
配套：`SPR39_设计实稿_手记只说玩家观测得到的事.md`（处置与理由）／`SPR39_验证口径.md`（判据）／`SPR39_对照表.json`＋`SPR39_flavor_contract.py`（机检件）／`SPR39_文案候选.json`（措辞出处与被否项）

一句话：**本批只改 `data.gd` 里 4 个字符串字面值，外加跑一门七回归。** 机制票一张都不开工。

---

## 0. 🔴 硬前置（不满足就别动手）

1. **工作树须干净到只有 S35/S36/S37/S38 在飞的改动**。本批只碰 `scripts/data.gd` 的 FLAVOR 四行；若 `data.gd` 上有别的批未合改动，先打招呼再动，别把别人的 churn 混进本批日志。
2. **先跑门再改**：`python production/sprint-39/SPR39_flavor_contract.py` 现在**必须返回非 0、且失败项恰好是 15 条**（G-3×4 ＋ G-4×7 ＋ G-5×4）。这条是本批的"改前基线"——它红了才证明门在盯这四行。若数字不是 15，先报回来，不要改代码。
   （主理人已在内存副本里预演过 §1 的四行替换：失败数应归 **0**，counts 为 `g1=74 g2=99 g3=74 g4=10 g5=5 g6=74`。若你落地后拿不到这个数，是我们的表或你的改动有一边错了，停下来对一下。）
3. ⛔ 改任何 `.gd` 的逻辑行。本批授权面＝下面 4 个 value 的字面值，一个字符不多。

---

## 1. 落地项 W-1：改写四条 FLAVOR（可开工）

文件：`scripts/data.gd`，块锚 `const FLAVOR := {`（🔴 用 key 定位，⛔ 用行号——行号会腐烂）。

| # | key | 现值（逐字，用于搜索替换） | 目标值（逐字，含收尾句号） | len |
|---|---|---|---|---|
| W-1a | `bosses/prism_warden` | `守望者。天道之眼，别站在光缝里，砸它的核。` | `守望者。天道之眼，碎片变色就是要换招，离它远。` | 23 |
| W-1b | `bosses/pyrothalassian` | `熔潮。修罗嗔火，弹匣留一半，给它变红的时候用。` | `熔潮。修罗嗔火，脉冲比守望者密，壳也厚一档。` | 22 |
| W-1c | `themes/pressure` | `高压层。修罗斗诤，子弹会拐弯，贴墙打。` | `高压层。修罗斗诤，虫更快，拾到的残响也多。` | 21 |
| W-1d | `themes/silent` | `静默层。天道静虑，听不见脚步，多看小地图。` | `静默层。天道静虑，小地图整块没了，只能靠自己看。` | 24 |

🔴 逐字照抄，⛔ "顺手润色"：门 G-3 拿表与盘做**全等**比较，差一个标点即红。
🔴 ⛔ 动其余 70 条中任何一条。特别是这三条被 `player._floor_sign_probe()` 的 `contains` 链锁着：`themes/magma`（`岩浆层。地狱热狱`）、`themes/toxic`（`毒巢。饿鬼食毒`）、`themes/vein`（`人间拾痕`）。
🔴 ⛔ 动 `bosses/third_boss`。那句 `玄渊之主。地狱旧客，比熔潮慢半拍，比守望者狠。` 是全批唯一诚实范本，门 G-5 有专门的逐字保护。
🔴 FLAVOR 总条数保持 **74**（`_floor_sign_probe` 里有死数断言 `Data.FLAVOR.size() == 74`）。本批不增不减不改键名。

**为什么是这四句**（不用你判断，只让你知道自己守的是什么）：每句的新短语都在盘上有锚点——`碎片变色`→`boss.gd` 的 `modulate = _phase_tints[k]`；`脉冲比守望者密`→`skill_interval` 2.2 vs `BOSS_SKILL_INTERVAL` 3.0；`壳也厚一档`→`max_hp` 基数 360 vs 320；`虫更快 / 残响也多`→`_apply_floor_theme()` pressure 支两行 `maxf(..., 1.3)` / `maxf(..., 1.5)`；`小地图整块没了`→`hud.set_minimap_hidden(_theme_rule == "silent")`。详见 `SPR39_文案候选.json` 的 `anchors` 与 `risks`（里面有两句**被否掉**的候选，别把它们当成漏改项补回去）。

---

## 2. 门禁命令（按序跑，原文贴回报告）

```bash
cd "D:/Create/Game/test-1"
GODOT="D:/SteamLibrary/steamapps/common/Godot Engine/godot.windows.opt.tools.64.exe"
rm -f "/c/Users/TangUser/AppData/Roaming/Godot/app_userdata/test_1"/_smoke_*.cfg*

# 0) 本批新门（先跑它；红了不用往下走）
python production/sprint-39/SPR39_flavor_contract.py            # 期望 exit 0 + flavor contract: ok rows=74 ...
python production/sprint-39/SPR39_flavor_contract.py --selftest # 期望 SELFTEST OK: 3/3

# 1) validate
"$GODOT" --headless --path . --quit-after 400 > _tools/spr39_validate.log 2>&1   # problems=0

# 2) 基线 + 文案上屏三通道 + 静默层语境
SMOKE=1 SMOKE_SEED=12345 "$GODOT" --headless --path . --quit-after 3200 > _tools/spr39_base.log 2>&1
SMOKE=1 SMOKE_SEED=12345 SMOKE_FLAVOR=1 SMOKE_FLOOR_SIGN=1 "$GODOT" --headless --path . --quit-after 3200 > _tools/spr39_flavor.log 2>&1
SMOKE=1 SMOKE_SEED=12345 SMOKE_JUMP_FLOOR=7 SMOKE_FLOOR_SIGN=1 "$GODOT" --headless --path . --quit-after 3200 > _tools/spr39_f7.log 2>&1

# 3) E1 指纹三档（开关是 META_FINGERPRINT，不是 SMOKE_META）
for s in 12345 777 42; do SMOKE=1 SMOKE_SEED=$s SMOKE_META_FINGERPRINT=1 "$GODOT" --headless --path . --quit-after 3200 > _tools/spr39_fp_$s.log 2>&1; done
```

判定口径见 `SPR39_验证口径.md` V-C / V-D / V-E。三条容易踩的：
- churn 对比**必钉** `SMOKE_SEED=12345`，不钉会出上百行假差异；只比断言行，`[SMOKE-NAV]/[SMOKE-CAM]/[SMOKE-E]/[SMOKE-LOOP]/[SMOKE-STALL]` 与时间戳不比。
- `[ERR]`／`ok=false` 计数用 `grep -a -c`，⛔ `awk -F:` 配绝对 Windows 路径（盘符冒号切错，恒得 0＝假绿）。
- `SMOKE_SAVE` 相关要 `--quit-after 3200` 才落地；`SMOKE_DAILY` 会覆盖种子，跨批对照禁用。

---

## 3. 三条变异刀（V-C7～C9）——**已内置，不用你手工破坏文件**

`python production/sprint-39/SPR39_flavor_contract.py --selftest` 会在**内存副本**上弯刀并打印每把造成的失败数与命中门号。要求：三行全是 `[OK ]`，末行 `SELFTEST OK: 3/3`，exit 0。
出现 `[DEAD]` ⇒ 门是假的，**如实写 INCOMPLETE 上报**，⛔ 为了让它变绿去改门或改断言。
如果你另外想手工验一次，刀的临时改动只允许在工作树，跑完立即还原，⛔ commit。

---

## 4. HOLD（本批⛔ 开工）

| 编号 | 内容 | 状态 |
|---|---|---|
| M-A | 部位伤害（「砸它的核」的真身；作者 todo #8） | **HOLD** — 需作者排期，独立批次 S40+，排在 S36 专武之后。代价清单在设计实稿 §4 |
| M-B | 光缝危害实体 | **HOLD** — 可搭 M-A 同批；若作者只批一张票，批这张 |
| M-C | 给熔潮真做一个「弹匣留一半」机制 | **HOLD（主理人不建议）** — 措辞已划归 S36 `bw_slack_half`，为一句文案造机制违反 AGENTS §4 |
| — | S35 §6 `hungry`／S36 §6.3 三个 `bw_*` 专武 | **不属于本批**，⛔ 动它们的文件或断言。本批只给出措辞归属（见 §6） |

---

## 5. 禁止事项（照例，一条不少）

1. ⛔ `git commit`、⛔ `git push`、⛔ 刷新 `production/sprint-21/SPR21-FROZEN.md5`（收官由主理人手工刷）。
2. ⛔ 改 `scripts/*.gd` 的任何**逻辑**；本批唯一授权面＝§1 表格四个 value 的字面值。
3. ⛔ 改断言以掩盖红。若某条探针因新文案变红，先判它是"预期联动"还是"实现错了"，报回来由我裁；已知会被牵动的只有 `_floor_sign_probe` 里对**旧串**的引用（若有——本次自查未发现生产断言硬编码这四句旧文本，若你发现请当缺陷报，别改断言）。
4. ⛔ 把 FLAVOR 条数改成非 74；⛔ 新增/删除 key；⛔ 改键名前缀分桶（`validate._check_codex()` 按 `/` 前缀计数）。
5. ⛔ 新增 `Game.rng` 消费、⛔ 新增计时器不走 `Game.FIXED_DT`、⛔ 新增 `ACTION_DEFS`（本批纯文本，理论上零影响——一旦 E1 指纹漂了，说明有人顺手改了逻辑，立刻停手上报，⛔ 重定基线）。
6. ⛔ 往游戏内文本塞他作专名（禁例：索拉尔／太阳骑士）；⛔ 与「先贤」同框提苏瑾（S36 HP-7 三条硬边界，对本批同样生效）。
7. ⛔ 把 `SPR39_flavor_contract.py` 挪去 `_tools/`（那是 gitignored 的），⛔ 把它接成 `.gd` 启动门（本批裁为"提交前跑一次"的外部件）。

---

## 6. 顺带登记（零代码动作，只改文档用语）

- S36 §6.3 `bw_core_hammer`「敲核槌」若其出处注释引的是 `data.gd` 那句「砸它的核」⇒ 该引用自本批起**失效**，改引机制票 M-A；M-A 落地前那把的"抢的是哪一下"应写成不依赖部位的表述。**由 S36 侧自己处理，本批不动它。**
- S36 §6.3 `bw_slack_half` 的 `desc` ⛔ 含「留一半」三字；`弹匣留一半` 这个措辞现在**专属** `bw_slack_half`（对照表 `reserved_phrases`，门 G-4 拦 FLAVOR 面）。
- S35 §6 `hungry` 的口径词仍是「满弹匣不得换弹」，⛔ 用「弹匣留一半」描述它——两者语义相反（一个是惩罚、一个是许可），这是本轮三方撞车的病根。

---

## 7. 报告要交什么

1. §1 四行的**替换前后逐字**（贴 `grep -n '"bosses/prism_warden"' scripts/data.gd` 一类的实测输出，四行都要）。
2. §2 全部命令的实测原文：门 exit code ＋ `flavor contract: ok rows=74 g1=.. g2=.. g3=.. g4=.. g5=.. g6=..` 那一行、`--selftest` 四行、validate `problems=`、各探针 `done checked=N declared=N`、`[ERR]`/`ok=false` 计数、E1 指纹三档逐字、churn 差异行清单（应当只出现在含这四个 value 的断言行上）。
3. V-D-a…d 三通道实测：层签第二行、toast、图鉴手记行各贴一行真实渲染文本；并明确写「四旧串在三通道命中数 = 0」的实测方式与结果。
4. 冻结面：`scripts/data.gd` 的 md5 变化如实报（它今天已在 FAILED 列表内 ⇒ **FAILED 总数不应变化**）。
5. 任何你在落地中发现的**机检缺陷／假绿／口径漏洞**照实报，⛔ 自行改门或改断言。
