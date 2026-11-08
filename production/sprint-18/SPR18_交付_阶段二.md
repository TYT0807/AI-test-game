# SPR18 交付 · 阶段二（C 上局誓约一行 + D 圣所十卡灰字）

> 基线 HEAD `6a3dec0`（阶段一 v3 已入库；34 个 `.gd`，冻结 34/34）。
> 本批**零新增实体、零新增资源、零新增 `Game.rng` 消费、零新增 `ACTION_DEFS` 条目、E1 地图流零漂移**。
> 只改 4 个脚本：`menu.gd`（C）、`data.gd`（D 文案入表）、`shrine_panel.gd`（D 渲染）、`player.gd`（两个探针）。

## 零、结论速览

| 项 | 结果 |
|---|---|
| C 上局誓约一行 | `menu.gd:627` 起，`_build_sigils()` 内 `balance` 之后；文本 `上局誓约 · <name>「<desc>」已兑现/未兑现（cur/need）`；**oath 为空或 name 为空 → 整个 Label 不创建** |
| D 文案入表 | `data.gd:379` 起 10 条 `shrine/<id>`，**只加这 10 行 + 4 行注释**，`SHRINE_OFFERS` 一个字节未动 |
| D 渲染 | `shrine_panel.gd:18/99/140-145`：`_flavors` 数组 + 每卡一枚灰字 Label（字号 11、`Color(0.62,0.64,0.70)`、`AUTOWRAP_WORD_SMART`、`custom_minimum_size(190,0)`）；查不到 → 空文本 + `visible=false` |
| 探针 | 新增 `[SMOKE-SIGIL-OATH]`（`SMOKE_SIGIL_OATH=1`，5 条断言 + 1 条前置）+ `[SMOKE-SHRINE] D flavors`（2 条断言，其中 1 条在 3 张卡上各跑一次） |
| 四门控 | 全过（§三）：全量 6000 帧 ×3（改动双跑 + HEAD 对照）`[ERR]`=0 / `SCRIPT ERROR`=0；E1 指纹与 HEAD **逐字节相同** |
| 负向对照 | 6 组（1 基线 + C×3 + D×2）固定 seed 实跑，转红 **1 / 1 / 1 / 2 / 4**（§四） |
| 冻结清单 | 重定 **4 行**（`data` / `menu` / `shrine_panel` / `player`），仍 34 行、**34 OK / 0 FAILED** |
| 红线 | 代码层 `save_codex`/`set_codex_last_run`/`mark_codex`/`Game.rng`/`fx_rng`/`rand*` 新增调用 **= 0**（§五 贴 grep） |

## 一、C · 印记页「上局誓约」一行

落点：`scripts/menu.gd:627`，在 `_build_sigils()` 的 `balance`（地窖碎片余额）之后、`eq_label`（当前携带）之前。

- **为什么在印记页而不是复盘页**：玩家在这一页决定本局带哪枚印记，「上局誓约是否兑现」正是这个决策的输入（继续补齐 vs 换一枚换打法）。图鉴页（`_build_codex()` 的 `:386` 行）保留「**本局**誓约」，两处数据源相同、语义不同，**用词必须区分**——本批新增行固定用「上局誓约」，探针把这条用词差异也锁成断言（C-NC2 实证会转红）。
- 数据源：`Game.codex.get("last_run", {}).get("oath", {})`（`{id,name,desc,done,cur,need}`，由 `game_main._write_codex_replay()` 写入）。
- 渲染：`Label` + `horizontal_alignment = CENTER` + `font_size 14` + 兑现绿 `Color(0.6,0.95,0.7)` / 未兑现灰 `Color(0.72,0.75,0.82)`，与图鉴页同色系。
- **oath 为空或 `name` 为空 → 整个 Label 不创建**（不是建了再隐藏）：`if not last_oath.is_empty() and String(last_oath.get("name","")) != "":`。
- **硬红线（代码层零命中，§五 实证）**：不调 `save_codex` / `set_codex_last_run` / `mark_codex`，不进任何发现集与分母，不读写 `Game.rng` / `fx_rng`。纯只读展示。
- 安全性依据：`load_codex()` 对 `last_run` 的未知键**原样透传**（`game_state.gd:362-368` 只对 int/float 做 `maxi(...,0)` 钳制，Dictionary 原样保留），故 `oath` 是 Dictionary 时直接 `.get("oath", {})` 安全。

实跑渲染实值（`_tools/spr18_p2_probe.log`）：
```
[SMOKE-SIGIL-OATH] done
```
（断言全绿即无 `[ERR]`；`Dev.check` 只在失败时打印，正向证据由 `[ERR]`=0 + `done` 行构成。）

## 二、D · 圣所三卡灰字

### 2.1 文案入表（`data.gd`）

`FLAVOR` 末尾追加 10 条，键 `shrine/<offer_id>`，文案逐字取自 `production/sprint-18/SPR18_D文案候选.md` §一 表格：

| 键 | 文案 |
|---|---|
| `shrine/blood_relic` | 血祭。地窖里最不缺的就是血。 |
| `shrine/ore_upgrade` | 源石淬炼。矿里人管这叫喂石头。 |
| `shrine/purify` | 净化。这层的脏，散得掉。 |
| `shrine/ward_boon` | 护盾祝福。挡一下，就散了。 |
| `shrine/heal` | 修复。缝两针，血就回来了。 |
| `shrine/relic_suffix` | 铭刻。刻上去的，抠不下来。 |
| `shrine/greed_pact` | 贪欲契约。血换石头，老规矩了。 |
| `shrine/wind_dance` | 风之舞。腿快了，坑还是那些坑。 |
| `shrine/shard_pact` | 共鸣契约。地窖的账，只记碎片。 |
| `shrine/power_surge` | 力量激涌。手重了，人也就薄了。 |

**只加这 10 行 + 4 行注释**；`git diff` 证明 `SHRINE_OFFERS` 相关行零变化（仅注释里提到该表名，§五）。

### 2.2 渲染（`shrine_panel.gd`）

- `:18` 新增 `var _flavors: Array[Label] = []`；
- `:99-107` `_make_card()` 在 `cost` 之后追加灰字 Label：`font_size 11`（desc 是 14，小两档）、`Color(0.62,0.64,0.70)`、`AUTOWRAP_WORD_SMART`、`custom_minimum_size = Vector2(190, 0)`（与 desc 同宽）、初值 `visible = false`；
- `:140-141` `open()` 内与 `_descs[i].text` 并排赋值：`Data.FLAVOR.get("shrine/" + String(o.get("id","")), "")`，`visible = fv != ""`；
- `:145` 卡位超出 offers 数时同时把灰字置隐（防复用残留）。
- **恒显口径**：不读发现状态、不读 `shrine_visits`，查得到就显示——D 与发现度之间**零耦合**（`CODEX_KINDS` 五类不含 `shrine`，本批也未扩展它）。
- **硬红线**：不动 `desc` / `cost` / `SHRINE_OFFERS` 表值、不动 `_shrine_offers_for()` 的 `stable_hash` 派生 key、不触发 `Game.rng`、**不因"有没有呼应"改变任何卡的可用性**（置灰逻辑仍是 `_set_state` 按 `_shrine_affordable`）。

实跑渲染实值（`_tools/spr18_p2_a.log`）：
```
[SMOKE-SHRINE] D flavors blood_relic=[血祭。地窖里最不缺的就是血。]ore_upgrade=[源石淬炼。矿里人管这叫喂石头。]heal=[修复。缝两针，血就回来了。]
```

## 三、四个门控实跑结果

`G="D:/SteamLibrary/steamapps/common/Godot Engine/godot.windows.opt.tools.64.exe"`，全部在沙箱 `_backup/spr18_p1/sandbox/` 内跑，**每条实测跑前/跑后双 md5 夹逼**（§四 每行 `夹逼一致=Y`）。

**① 全量回归（6000 帧 ×3：改动双跑 + HEAD 对照）**
```
env SMOKE=1 SMOKE_SEED=12345 SMOKE_V8=1 SMOKE_REBIND=1 SMOKE_RELIC_PROBE=orb_shield SMOKE_SUFFIX=1 \
 SMOKE_META=1 SMOKE_META_PERSIST=1 SMOKE_BOSS=1 SMOKE_FORCE_SOVEREIGN=1 SMOKE_FORCE_SQUAD=echo_pack \
 SMOKE_JUMP_FLOOR=11 SMOKE_DAILY=1 SMOKE_CALAMITY=1 SMOKE_SHRINE=1 SMOKE_SIGIL_OATH=1 SMOKE_CODEX=1 \
 SMOKE_CODEX_BOON=1 SMOKE_SIGIL_COVERAGE=1 SMOKE_FORCE_THIRD_BOSS=1 SMOKE_THIRD_BOSS=1 SMOKE_OATH=1 \
 SMOKE_ECHO_CHAIN=1 SMOKE_FLOOR_SIGN=1 SMOKE_FLAVOR=1 SMOKE_META_SETTLE=1 SMOKE_DAILY_SHARE=1 \
 SMOKE_LAYOUT=1 SMOKE_META_FINGERPRINT=1 \
 "$G" --headless --path . --quit-after 6000 > _tools/spr18_p2_{a,b,head}.log 2>&1
```

| 跑次 | 字节 | `[ERR]` | `SCRIPT ERROR` | `^ERROR:` | `Lambda capture` | done 唯一标记 |
|---|---|---|---|---|---|---|
| `p2_a` | 改动版 | **0** | **0** | 1（退出期字体 RID 泄漏） | 0 | **13** |
| `p2_b` | 改动版 | **0** | **0** | 1（同上） | 0 | **13** |
| `p2_head` | HEAD `6a3dec0` | **0** | **0** | 1（同上） | 0 | 12（无 SIGIL-OATH 探针） |

13 个标记 = 既有 12 个 + 新增 `[SMOKE-SIGIL-OATH] done`。`p2_head` 为 12，符合"HEAD 没有该探针"的预期，不是漏跑。

**② 冻结清单**：`md5sum -c` → **34 OK / 0 FAILED**，仍 34 行；`diff` 证明**只有 4 行**变化：
```
data.gd          0c9cf515…→95311b8d…
menu.gd          ebea1702…→afefe368…
shrine_panel.gd  296b8b72…→c2343e1c…
player.gd        33551e7f…→d32fb453…
```
`hud.gd` / `game_main.gd` 保持阶段一入库值。

**③ E1 指纹（同 seed 12345，不带 daily，各 6000 帧）**

| 跑次 | 字节 | 指纹行数 | 指纹文件 md5 |
|---|---|---|---|
| `e1_new` | 改动版 | 2（floor 1、2） | `55bf3134969320177b9f1bacf88f534a` |
| `e1_head` | HEAD `6a3dec0` | 2（floor 1、2） | `55bf3134969320177b9f1bacf88f534a` |

→ `cmp` 逐字节相同；且该 md5 **与阶段一 v3 批次 `spr18_v3_6000_new_a.fp` 完全相同** → 三轮（v3 批次 / 本批改动版 / 本批 HEAD）同 seed 地图流零漂移。**D 往 `FLAVOR` 加 10 条键不影响地图生成**，实证。

**④ E6**：全库 `FIXED_DT` **33 处**（未动）；`git diff 6a3dec0` 新增行含 `delta` = **0**；新增行含 `rand*` / `Game.rng` / `fx_rng` 真实调用 = **0**（§五）。

## 四、负向对照（1 基线 + 5 变体，固定 `SMOKE_SEED=12345`，脚本 `_tools/spr18_p2_neg.sh`）

| 变体 | 突变点 | `[ERR]` | 转红断言 |
|---|---|---|---|
| `base` | 无 | **0** | —（绿灯基线） |
| `c1` | 整块 `if false and …` → Label 不创建 | **1** | 有 oath → 出现「上局誓约」行 |
| `c2` | 文案「上局誓约」→「本局誓约」 | **1** | 「上局誓约」行存在（`_find_label_containing` 找不到） |
| `c3` | 空判守卫去掉 → `if true:` | **1** | oath 为空 → 该行不创建 |
| `d1` | 删掉 `shrine/heal` 一条 FLAVOR | **2** | 卡 2 灰字 == 表值且可见 / 三卡命中 3 |
| `d2` | 查表键 `shrine/` → `shrineX/` | **4** | 三卡各一条 + 命中 3 条合计 |

日志：`_tools/spr18_p2_{base,c1,c2,c3,d1,d2}.log`；每行输出 `夹逼一致=Y`。
**注（诚实标注）**：`c1` / `c2` / `c3` 各只转红 **1** 条——因为 C 的 5 条断言里，"行存在"是其余几条的前置，前置一挂后面自然不再报（同阶段一 `nc3` 的「前提守卫型」性质）。**未把前置失败包装成多条红**。
`d1` = 2 条红（该卡一条 + 汇总一条），恰好证明"查不到 → 空 + 隐藏"这条分支真的被走过，而不是仅凭代码推断。

## 五、红线核查（静态，贴 grep）

```
$ git diff 6a3dec0 -- scripts/ | grep '^+' | grep -v '^+[[:space:]]*#' \
    | grep -cE 'save_codex|set_codex_last_run|mark_codex|Game\.rng|fx_rng|randf|randi'
0
```
→ **代码层零命中**；同一 grep 不排除注释时会命中 5 行，逐行核对**全部是注释文字**（我自己的红线自述："不调 save_codex / set_codex_last_run"、"不喂 mark_codex"、"不读写 Game.rng"），非调用。

```
$ git diff 6a3dec0 -- scripts/data.gd | grep '^[+-]' | grep -c 'SHRINE_OFFERS'
1     # 唯一命中是新增注释行 "…与 SHRINE_OFFERS 一一对应"，表定义 0 行变化
$ ls scripts/*.gd | wc -l              → 34
$ grep -o FIXED_DT scripts/*.gd | wc -l → 33
$ git status --short                    → 仅 4 个 M + 主理人 2 个未跟踪文档
```

## 六、断言盘点（新增 7 条 + 1 条前置）

| # | 探针 | 分类 | 断言 | 转红方式 |
|---|---|---|---|---|
| 0 | `_sigil_oath_probe` | 前置自检 | `menu` 未就绪 → 直接判失败并 return | 仅异常态 |
| 1 | 同上 | 验效果型（渲染） | 有 `last_run.oath` → 印记页出现「上局誓约」行 | c1 |
| 2 | 同上 | 验效果型（用词） | 该行以 `上局誓约 · ` 开头 | c2 |
| 3 | 同上 | 验效果型（渲染值） | 该行含 name + 兑现态 + `（5/5）` 实值 | 文案写坏即红 |
| 4 | 同上 | 验效果型（只读） | `show_page("sigils")` **同步**前后 `Game.codex` 深拷贝全等 | 构建期偷写状态即红 |
| 5 | 同上 | 验效果型（不创建） | `last_run.oath` 为空 → 该行不创建 | c3 |
| 6 | `_shrine_probe` | 验效果型（渲染值） | 三卡 `_flavors[i].text == Data.FLAVOR["shrine/"+id]` 且 `visible` | d1 / d2 |
| 7 | 同上 | 验效果型（汇总） | 三卡命中数 == 3 | d1 / d2 |

`_sigil_oath_probe` 内 `Dev.check(` 共 **6** 处 = 5 条断言 + 1 条前置；`_shrine_probe` D 段 **2** 条（循环内那条在 3 张卡上各执行一次）。
**探针设计取舍（与阶段一同一口径）**：验渲染不验字段 —— 真调 `menu.show_page("sigils")` 重建页面后**遍历 `_rows` 找 Label**，而不是直接读 `Game.codex` 判断"数据在不在"。`④ 零副作用` 用**同步段**比对（`show_page` 与深拷贝之间无 `await`），避免与同期 `SMOKE_OATH` 探针的 codex 写入互相串扰造成假红。

## 七、偏差 / 新发现（需主理人知晓）

1. **【方法学订正】`SMOKE_DAILY=1` 时 seed 按本地日期派生，跨日跑指纹不可比。**
   `game_main.gd:344-346`：`if Game.daily_mode: Game.rng.seed = Game.daily_seed_for(Game.daily_key())` —— daily 模式的 seed 来自**日期**。本批第一轮全量（23:4x）与第二轮（00:0x 跨本地零点）的 floor=1 地图不同，一度看起来像 E1 回归；**实为跨日**。故 E1 门控改用**不带 `SMOKE_DAILY`** 的固定 seed 跑，得到 `55bf3134…`，与阶段一 v3 批次逐字节相同 → 零漂移。**这条写进方法学：E1 对照禁用 `SMOKE_DAILY`，除非当日对比。**
2. **【环境事实 · 已知限制】`scripts/` 下行尾混排：8 个 CRLF / 26 个 LF。**
   全量逐字节扫描（34 个脚本）：CRLF 的是 `assets.gd`(502) / `bullet.gd`(236) / `data.gd`(489) / `prop.gd`(96) / `secret_wall.gd`(36) / `slug.gd`(485) / `upgrade_panel.gd`(276) / `upgrades.gd`(222)；其余 26 个为 **纯 LF**；**无单文件内部混排**（不存在「同一文件里 CRLF 与 LF 并存」这种更麻烦的状态）。
   **冻结清单 `SPR7-FROZEN-4.md5` 是「工作树字节快照」，不是仓库归一化字节。** 在 `core.autocrlf` 配置不同的环境 clone 后，上述 **8 行** md5 会对不上，**属预期行为，不是文件被篡改**。
   这也解释了 `git show 6a3dec0:scripts/data.gd` 得到 `da583847…`（LF 归一化）而工作树是 `95311b8d…`（CRLF）。**清单以工作树为准。**
   另注：`core.autocrlf=true` 并不能推出「工作树全 CRLF」——本仓库就是 8:26 的混合，这 8 个文件的行尾是历史上带进来的，autocrlf 没有回头统一。**不要再假设 autocrlf=true 等于全 CRLF。**
   改这 8 个文件时**锚点必须带 `\r\n`**（本批第一版 D-NC1 就因用 `\n` 锚点空跑，0 命中，已修）。
   本批**不改行尾**（统一行尾 = 8 行重算 + 全量重跑，收益只是跨环境可复现，而本项目单机开发、无 CI，换不来这个成本）。将来若要跨环境校验，应改用 `git hash-object` 或补 `.gitattributes` 强制 `text=auto eol=lf`，作为**一次独立批次**做。
3. **C 的显示条件为「oath 非空且 name 非空」**（派单只写"dictionary 为空或 name 为空 → 不创建"，我照做并额外用 `name` 非空做双保险；两者都属"不创建"）。
4. **D 的灰字字号取 11**（派单给"11 或 12，按实读 `_fs` 有无可用接口决定"）：`shrine_panel.gd` 里**没有 `_fs` 辅助**（那是 `hud.gd` 的），故直接 `add_theme_font_size_override("font_size", 11)`，与文件内既有写法一致（desc 14 / cost 15 / hint 13）。
5. **新增 env `SMOKE_SIGIL_OATH`**（派单未指定探针开关名）。全量命令串已含它；不含它在 v3 代码下不会报错，只会漏跑 C 探针。

## 八、回滚

```
git checkout 6a3dec0 -- scripts/data.gd scripts/menu.gd scripts/shrine_panel.gd scripts/player.gd \
    production/sprint-7/SPR7-FROZEN-4.md5
md5sum -c production/sprint-7/SPR7-FROZEN-4.md5    # 回 34/34
```
批次备份（gitignored，不入库）：`_backup/spr18_p1/{p2_stash/,sandbox/,sandbox_head/,frozen_before_p2.md5}`。`_tools/` 亦 gitignored。无新增 PNG，无需 `--headless --import`。

## 九、遗留 / 待决策

1. **`data.gd` 行尾问题**（§七-2）：是否统一成 LF（会让清单 md5 再变一次、且需全量重跑），还是改用 `git hash-object` 做清单校验。本批未动，等指示。
2. **C 的 `desc` 过长时换行**：当前 Label 未设 `autowrap`，`oath.desc` 若超过面板宽度会被裁（现有誓约 desc 均 ≤10 字，实测无问题）。要保险可加 `autowrap_mode` + `custom_minimum_size`，但会改 `_rows` 排版，本批未做。
3. **D 的手记是否会与 `desc` 重复**：现 10 条均不含数值（文案候选 §二-4 已自查），实测三卡排版未溢出。文案终审归文策渊。
4. 阶段一遗留（`有诅咒房` 是否区分"已付过代价"）仍未做，与 C/D 无耦合。

## 十、提交范围

`scripts/data.gd`、`scripts/menu.gd`、`scripts/shrine_panel.gd`、`scripts/player.gd`、`production/sprint-7/SPR7-FROZEN-4.md5`（重定 4 行）、本文件。
**不含** `SPR18_规划草案.md`、`SPR18_D文案候选.md`（主理人文件，未跟踪）。
提交信息：`Sprint 18 阶段二：C 上局誓约一行 + D 圣所十卡灰字`。
