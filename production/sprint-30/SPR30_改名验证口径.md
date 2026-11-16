# SPR30 · 改名验证口径（资产文件名原创化 · 零内容改动）

> 任务 **SPR30-RENAME-QA-01**｜角色：验收接手方（QA）｜**只产出本文件**：不改 `.gd`、不改资产、不 commit、不联系其它成员。
> 上游：`production/sprint-30/SPR30_改名实施单_编程侧.md`（**唯一权威**；§三 精确映射 / §五 七门 / §六 变异刀）。本文只把七门翻成可判断言 + 判红命令，不发明新名字。
> 基准：HEAD `a0c06ba`，本地=origin 0/0，树干净；`scripts/` 34 个 `.gd`；冻结 `SPR21-FROZEN.md5` 34/34 OK。本文行号、md5、E1 指纹全部实读/实跑于该树（QA 当天）。
> 性质：纯改名。资产内容一字节不动、机制一条不改；`assets.gd` 的冻结 md5 行会变（**实施方不自刷**，收官侧统一刷）。

## 〇 先读五条（否则整份口径会用错）

| # | 事实 | 后果 |
|---|---|---|
| 1 | **跑法必须带 `SMOKE=1`**：`game_main.gd:134` 才置 `_smoke=true`，否则探针整段不执行、日志空 = 假绿 | 所有引擎命令首段一律 `SMOKE=1` |
| 2 | **改名文件 15 个**（2 图 + 10 wav + 3 mp3），其中 **14 个被 preload**；`Cowboy_Footstep.wav→sfx_footstep.wav` 未 preload 但一并改 | 任务书「14 个资产」指 preload 数；**G1 字节门按 15 个判**，少一个即红 |
| 3 | **SFX 实读 14 个 key**（非 15），复用 **9 个 wav**；`player.gd:673` 调 `Game.sfx("suffix")`，但字典无该 key → `game_state.gd:651-652` 静默 return | **本批不许顺手补 suffix key**（那是机制改动）。若实施树出现第 15 键，判据仍取「改前后集合逐字相等」 |
| 4 | 🔴 **G2 字面「全仓（排除 `_backup/`）0 命中」不可满足**：`production/sprint-25/26/30`、`_tools/`、`tests/`、`_backup/` 均留有旧名历史记录 | 判据限定**运行时 + 发货面**（§一.3）；历史档案不计。此范围收口需主理人确认——QA 给判定，放行由用户定 |
| 5 | **两种探针判红格式不同，绝不混用**：批二式 `_og_assert`/`_pc_assert`/`_sb_assert`（`game_main.gd:3699/4203/4447`）打 `ok=` → 看 `ok=false`；批三式 `_ct_assert()`（`:688`）**无 `ok=`** → 看 `[ERR]` | 本批**不新增探针**，只跑既有 8 个；拿 `ok=false` 去判批三式恒 0 红 = 假判（S27 实测踩坑） |

## 一 范围与映射（名字一律引用实施单 §三，本文不自造）

### 1.1 改名清单 15 个（旧 → 新／主理人实施单 §3.1–3.3）

| 类 | 旧 → 新 | 数 |
|---|---|---|
| 图 | `W.png`→`shardbearer.png`；`源石虫.png`→`wraithswarm.png` | 2 |
| wav | `Cowboy_gunshot`→`sfx_shoot`；`cowboy_gunload`→`sfx_reload`；`cowboy_explosion`→`sfx_boom`；`cowboy_monsterhit`→`sfx_hit`；`cowboy_monsterdie`→`sfx_enemy_die`；`cowboy_dead`→`sfx_player_die`；`cowboy_gopher`→`sfx_pickup`；`cowboy_powerup`→`sfx_powerup`；`Cowboy_Secret`→`sfx_secret`；`Cowboy_Footstep`→`sfx_footstep` | 10 |
| mp3 | `1-27 Journey of the Prairie King (Overworld)`→`bgm_overworld`；`1-28 … (The Outlaw)`→`bgm_outlaw`；`1-29 … (Final Boss & Ending)`→`bgm_finale` | 3 |

### 1.2 明确不改（越界即 FAIL）

| 项 | 依据 |
|---|---|
| `浮游炮.png` / `T_TURRET` | 实施单 §3.1 注：通用装备名，非原作专名，本批不扩范围 |
| `_backup/**` | 实施单 §一.4：归档，含旧 `assets.gd`，零改动 |
| 冻结快照 `SPR21-FROZEN.md5` | 实施单 §一.5：核验侧收官统一刷，实施方不自刷 |
| 玩法/机制/数值 | 零新增 `Game.rng` 消费；E1 零重定 |

### 1.3 G2 判据的扫描面（🔴 与实施单 §五 G2 字面有范围差，见 〇.4）

| 计入（运行时 + 发货面） | 不计（历史档案） |
|---|---|
| `scripts/**/*.gd`、`resources/**/*.import` 及资源文件名、`project.godot`、`玩法说明.md`、`README.md` | `_backup/`、`production/sprint-*/`、`_tools/`、`tests/`、`__pycache__/`、`.git/`、`.godot/` |

> 🔴 **实施单 §四漏列一个运行时文件**：`scripts/data.gd:5`「原版源石虫图集」、`:7`「原版源石虫（保留本体）」两处注释含 `源石虫`。它是 `.gd`（计入 G2 面），但 §四只列了 `assets.gd`/`玩法说明.md`/README 三个文件。**不清理它，G2 必然红**——已落为断言 B04，请主理人确认把 §四 扩为 4 个文件。

## 二 断言规格（编号冻结；验效果型＝有专属变异刀能打红）

**分类定义**：验效果型＝有专属刀；前提守卫型恒过＝正确实现下必然成立，**不构成覆盖**；只验标志＝只验发生/没发生；走查守卫＝无专属刀，**不构成行为覆盖**。
**门型**：`shell`＝grep/md5sum/diff 文本门；`engine`＝Godot 引擎门（validate / 探针日志）。

| 编号 | 断言内容 | measured | expect | 分类 | 门型 | 抓哪个错误实现 |
|---|---|---|---|---|---|---|
| A01 | 15 个资产改名前（HEAD）后（新路径）md5 逐字相同 | `git show HEAD:<旧> \| md5sum` vs `md5sum <新>` 的 15 对值 | 15/15 相等 | **验效果型** | shell | 刀一（只改名但换内容） |
| A02 | 15 个新路径存在、15 个旧路径不存在 | `test -f` 存在性计数 | 新 15 / 旧 0 | 验效果型 | shell | 刀二（漏 `git mv`） |
| B01 | 扫描面内旧名 token `W.png｜源石虫｜Cowboy_｜cowboy_｜Journey of the Prairie King` 命中 | `grep -rInE` 命中行数 | **0** | 验效果型 | shell | 刀二（漏改 preload）、刀四（注释残留） |
| B02 | 常量 token `T_W｜W_CELL｜W_ROW_` 在 `scripts/*.gd` 命中（含 `W_ROW_DIE` `:46/:225`） | `grep -rInE` 命中行数 | **0** | 验效果型 | shell | 刀四（改路径未改常量） |
| B03 | `_backup/**` 逐字节未动 | `git status --short _backup/` | 空 | 走查守卫·**不构成行为覆盖** | shell | 无专属刀（本批红线自证） |
| B04 | `scripts/data.gd` 旧名注释清零（`:5`、`:7`） | `grep -nE '源石虫\|Cowboy\|Prairie\|W\.png' scripts/data.gd` | **0 行** | 验效果型 | shell | 刀八（实施单 §四漏列 data.gd） |
| C01 | validate 34/34、`problems=0`、`[ERR]`=0 | `[INFO] validate: 脚本编译扫描 34/34 通过` + `[SMOKE] validate problems=N` | `34/34`、`N=0`、`[ERR]` 0 | 验效果型 | engine | 刀二（悬空 preload → 编译失败）、刀三（import 断链） |
| C02 | 8 个既有 SMOKE 探针全跑、既有断言行无 churn、`[ERR]`=0 | 各日志 `ok=false` / `[ERR]` / `\#NN` 集合与改前 diff | diff 空、`[ERR]` 0 | 前提守卫型恒过·**不构成覆盖** | engine | 无专属刀（纯改名不该动玩法，churn 守卫） |
| C03 | 冻结 34 行：仅 `assets.gd` 一行变，其余 33 行 OK，且未自刷 | `md5sum -c SPR21-FROZEN.md5` 输出 | 1 FAILED（`assets.gd`）+ 33 OK；快照文件 md5 未变 | 走查守卫·**不构成行为覆盖** | shell | 无专属刀（授权漂移的台账） |
| D01 | `Assets.SFX` key 集合逐字不变（实读 14 keys，复用 9 wav） | 探针/静态解析 key 序列 | 改前后序列相等 | 验效果型 | shell | 刀五（拆文件/加 key/删 key） |
| D02 | 每个 key → 实际音频 md5 的映射逐字不变（复用关系不拆） | 按 key 取 preload 路径 → `md5sum`，比对改前后 14 组 | 14/14 相等 | 验效果型 | shell+engine | 刀五（把 `boss_intro` 从 `sfx_secret` 错指 `sfx_powerup`） |
| E01 | 3 首 BGM 新名后缀仍为 `.mp3` | `ls resources/audio/bgm_*.mp3` | 3 个 | 验效果型 | shell | 刀六（换 OGG → `AudioStreamMP3.loop` 失效） |
| E02 | `assets.gd:147-148` `for m in MUSIC: m.loop = true` 两行逐字在原位 | `grep -n 'm.loop = true'` | 1 处，函数体未变 | 走查守卫·**不构成行为覆盖** | shell | 无运行期刀（静态只验源码两行在，不验听感循环） |
| E03–E05 | E1 三 seed（12345/777/42）`rooms=`/`kinds=` 与基线逐字一致 | `[SMOKE-META] fingerprint` 两字段串 | §五.2 三行逐字 | 前提守卫型恒过·**不构成覆盖** | engine | 无专属刀（指纹只打 rooms/kinds，改名结构性不进图） |
| F01 | 15 个 `.import` 的 `uid://` 改前改后逐字相同 | `grep '^uid='` 新旧对比 | 15/15 相等 | 验效果型 | shell | 刀七（误刷新 uid → 引用漂移） |
| F02 | 15 个 `.import` 的 `path`/`source_file`/`dest_files` 指向新名，md5 段不变 | 三行按旧名→新名替换后 diff | diff 空（uid 不参与替换） | 验效果型 | shell | 刀三（漏改 `source_file`）、刀二（漏改 `.import`） |
| G01 | 玩法说明旧名清零，**`:53` 标题 + `:136` 正文两处都要改** | `grep -nE '源石虫\|原版素材：W\|Cowboy\|Prairie' 玩法说明.md` | **0 行**；`游魂聚合体（游戏本体）` 1 行 | 验效果型 | shell | 刀九（只改 `:136` 漏 `:53`） |

**分类小计（17 编号 / 19 条原子断言）**：验效果型 **12**（A01 A02 B01 B02 B04 C01 D01 D02 E01 F01 F02 G01）· 前提守卫型恒过 **4 原子 / 2 编号**（C02 + E03–E05 三合一）· 走查守卫 **3**（B03 C03 E02）· 只验标志 **0**。12+4+3=19 ✓
> 🔴 对外报数只报「**有效覆盖 12 条**」；C02 / E1 三跑 / B03 / C03 / E02 计 PASS 但**不计覆盖**。E1 与字节门测的是不同面——前者防「顺手改了地图」，后者防「顺手换了字节」。

## 三 判红判据（shell 门 / 引擎门分列）

### 3.1 shell 门（G1/G2/G6/G7 + 玩法说明）

```bash
GODOT="D:/SteamLibrary/steamapps/common/Godot Engine/godot.windows.opt.tools.64.exe"
# /tmp/s30_map.tsv 每行 = 旧相对路径<TAB>新相对路径（15 行，照实施单 §三）
# G1 字节不变（A01）+ G6 uid 保真（F01）
while read -r old new; do
  a=$(git show "HEAD:$old" | md5sum | cut -d' ' -f1); b=$(md5sum "$new" | cut -d' ' -f1)
  [ "$a" = "$b" ] || echo "RED-A01 $old $a/$b"
  u1=$(git show "HEAD:$old.import" | grep '^uid='); u2=$(grep '^uid=' "$new.import")
  [ "$u1" = "$u2" ] || echo "RED-F01 $old $u1/$u2"
done < /tmp/s30_map.tsv
# G2 零悬空（B01/B02/B04/G01）——只扫 §1.3 运行时+发货面
grep -rInE 'W\.png|源石虫|Cowboy_|cowboy_|Journey of the Prairie King|T_W|W_CELL|W_ROW_' \
  scripts/ --include='*.gd'
grep -rInE 'W\.png|源石虫|Cowboy_|cowboy_|Journey of the Prairie King' \
  resources/ --include='*.import'
grep -nE '源石虫|原版素材：W|Cowboy|Prairie' 玩法说明.md
# F02 路径字段：HEAD 版三行做旧→新替换后应与改后逐字相等
git show "HEAD:$old.import" | grep -E '^(path|source_file|dest_files)=' | sed "s|$old|$new|g"
grep -E '^(path|source_file|dest_files)=' "$new.import"
```
**判红**：任何 `RED-*` 行、任何 `grep` 有输出即红；`grep` 无输出 = shell 门绿。**注意**：`W.png` 要写成 `W\.png`（点转义），否则 `Wxpng` 之类误命中；`T_W` 用词边界避免撞 `T_WHATEVER`（本仓暂无，防将来）。

### 3.2 引擎门（G3/G4/G5）

```bash
# G3 validate（C01）——首屏两行必须同时出现
SMOKE=1 "$GODOT" --headless --path . --quit-after 300 2>&1 | tee base_validate.log
grep -F 'validate: 脚本编译扫描 34/34 通过' base_validate.log   # 1 行
grep -F '[SMOKE] validate problems=0' base_validate.log        # 1 行
grep -c '\[ERR\]' base_validate.log                             # 0

# G4 八探针回归（C02）——改前/改后各跑一次存 base_*.log / new_*.log
SMOKE=1 SMOKE_CAL_THEME=1     "$GODOT" --headless --path . --quit-after 300  > base_cal.log 2>&1
SMOKE=1 SMOKE_OATH_GRANT=1    "$GODOT" --headless --path . --quit-after 900  > base_oath.log 2>&1
SMOKE=1 SMOKE_PURIFY_COST=1   "$GODOT" --headless --path . --quit-after 900  > base_purify.log 2>&1
SMOKE=1 SMOKE_START_BUFFER=1  "$GODOT" --headless --path . --quit-after 900  > base_sb.log 2>&1
SMOKE=1 SMOKE_META=1          "$GODOT" --headless --path . --quit-after 300  > base_meta.log 2>&1
SMOKE=1 SMOKE_ABYSS=3         "$GODOT" --headless --path . --quit-after 300  > base_abyss.log 2>&1
SMOKE=1 SMOKE_RG7=1           "$GODOT" --headless --path . --quit-after 300  > base_rg7.log 2>&1
SMOKE=1 SMOKE_SAVE=1          "$GODOT" --headless --path . --quit-after 3200 > base_save.log 2>&1
```
**判红按格式分，不混**：

| 探针 | 格式（`game_main.gd` 行号） | 主判红门 | 辅门 |
|---|---|---|---|
| `SMOKE_OATH_GRANT` / `SMOKE_PURIFY_COST` / `SMOKE_START_BUFFER` | 批二式 `:3699/:4203/:4447`，打 `ok=` | `grep -c 'ok=false'` → 0 | `grep -c '\[ERR\] oath_grant\|purify_cost\|start_buffer'` → 0 |
| `SMOKE_CAL_THEME` / `SMOKE_ABYSS` | 批三式 `_ct_assert():688` / `Dev.err("abyss")` **无 `ok=`** | `grep -c '\[ERR\]'` → 0 | `grep '#[0-9][0-9]'` 断言行数与改前相同 |
| `SMOKE_META` / `SMOKE_RG7` / `SMOKE_SAVE` | 无断言，只打输出行 | 断言行 diff 空 + `[ERR]` 0 | 预期前缀行存在（`[SMOKE-META]` / `[SMOKE] seed=` / 存盘行） |

> 🔴 **`SMOKE_SAVE` 必须 `--quit-after` ≥3001**：`game_main.gd:274` 的存盘探针挂在 `_smoke_frame == 3000`。用标准 300 帧跑它**根本不执行**，日志空被误读为「通过」＝假绿。本口径用 3200。
> 既有探针行号 churn：若输出含源码行号，按「十进制数字串归一化后 diff 空 + ok 字段集合不变 + 总 `[ERR]`=0」判（S29 §8.3 裁定），不许改基线文件凑绿。

### 3.3 G5 E1 三跑（不得与任何探针 env 同开）

```bash
for s in 12345 777 42; do
  SMOKE=1 SMOKE_SEED=$s SMOKE_META_FINGERPRINT=1 "$GODOT" --headless --path . --quit-after 300 2>&1 \
    | grep -c '\[SMOKE-META\] fingerprint'   # 每次必须 == 1
done
```
三次 `rooms=`/`kinds=` 与 §五.2 逐字相同；任一漂移 = 有人把改名塞进 rng/地图路径，按越界 FAIL。

## 四 变异刀表（8 把；**替换目标行、不新增行**）

| 刀 | 改法（改哪一行） | 预测红编号 | 独占面 |
|---|---|---|---|
| 一 | 改名后把 `bgm_overworld.mp3` 内容换成旧字节（只换字节，文件名不动） | **A01** | 证明「字节不变」不是装饰；C01 仍绿（mp3 能加载） |
| 二 | 漏改 `assets.gd:34` 一处 preload（仍指 `1-27 … (Overworld).mp3`） | **B01 C01 F02**（旧 .import 未改名时） | 文本门 + 引擎门双红；单靠 validate 也能抓 |
| 三 | `.import` 只 `git mv`，`source_file` 仍写旧名 | **F02 C01** | uid 仍绿、A01 仍绿——只打路径字段这一个面 |
| 四 | preload 全改，但 `T_W`/`W_CELL`/`W_ROW_*` 常量名与「W 图集」注释没改 | **B01 B02** | 专门打常量/注释盲区；`W_ROW_DIE`（`:46/:225`）必查 |
| 五 | `boss_intro` 的 preload 从 `sfx_secret.wav` 错指 `sfx_powerup.wav`（文件都在、字节都对） | **D02**（D01 绿） | 唯一证明「14 别名复用关系」被验，而非只验文件存在 |
| 六 | 把 `bgm_finale.mp3` 改成 `.ogg` 并同步路径 | **E01**（C01 可能红） | 证明「必须留 mp3」有门，不是口号 |
| 七 | 把 `wraithswarm.png.import` 的 `uid://` 换成新值 | **F01** | 证明 uid 保真不是复制粘贴的副产品 |
| 八 | 只改 `assets.gd`/`玩法说明.md`，漏 `scripts/data.gd:5/7` | **B04** | 打实施单 §四漏列面（QA 实读发现） |
| 九 | 玩法说明只改 `:136`，漏 `:53` 标题 | **G01** | 专打「只改一眼能看到的那一处」 |

**纪律**：① 每刀前 `git checkout -- scripts/ resources/ 玩法说明.md` 复原，**不许叠刀**；② 替换前 `grep -c` 确认目标串唯一；③ **注释里不许写符号字面**（`+=`、`T_W` 等）——文本级静态门会凭空多红（S27 实测）；④ 某刀把探针打断（`checked<declared`）则结果作废重跑，不算红；⑤ 九刀逐刀见红且复原后全绿，才叫「刀有牙」。

## 五 实跑基线（QA 当天 @ HEAD `a0c06ba`，非抄旧稿）

| # | 项 | 实测 |
|---|---|---|
| 1 | validate | `[INFO] validate: 脚本编译扫描 34/34 通过`；`[SMOKE] validate problems=0`；`[ERR]` 0 |
| 2 | E1 seed 12345 | `rooms=(-1, 0),(-1, 1),(0, -1),(0, 0),(0, 1),(0, 2),(0, 3),(1, 1),(2, 1)` / `kinds=secret,treasure,shop,start,combat,elite,super_secret,elite,boss` |
| 3 | E1 seed 777 | `rooms=(-1, -1),(-1, 0),(-2, 0),(0, -1),(0, 0),(0, 1),(0, 2),(1, 1),(2, -1),(2, 0),(2, 1)` / `kinds=treasure,cursed,super_secret,secret,start,elite,shop,elite,boss,combat,combat` |
| 4 | E1 seed 42 | `rooms=(-1, -1),(-1, 0),(0, -1),(0, -2),(0, -3),(0, 0),(0, 1),(1, -1),(1, -3),(2, -1),(2, 0)` / `kinds=treasure,secret,combat,combat,elite,start,super_secret,challenge,boss,combat,shop` |
| 5 | 导入面计数 | `.import` 总 102 = 图 88（顶层 8 + generated 59 + monsters 21）+ 音频 13 + 字体 1；本批改 15 个 |
| 6 | 冻结 | `SPR21-FROZEN.md5` 34 行；`assets.gd` 现 md5 `c2f53a7abeaed6fa5a9cf52d8ce6900e`（改后应仅此行变） |

## 六 PASS 判定与执行顺序

1. 改前跑 G3/G4/G5 存基线 → 改后同命令、同 env、同 seed 再跑；shell 门（§3.1）与引擎门（§3.2/3.3）分列报数，不合并成一句「测试通过」。
2. **PASS 五条同时成立**：① A01 15/15 字节相同；② B01/B02/B04/G01 文本门 0 命中；③ C01 validate 34/34 + problems=0 + 全 `[ERR]`=0；④ C02 八探针 diff 空 + 判红门 0；⑤ F01/F02 uid 与路径字段逐字正确 + E1 三 seed 逐字一致。
3. **FAIL 即未达 QA**：任一红先定位是哪把刀的形状；报主理人附「编号 + measured + expect + 命令 + 日志行」，不许改期望值凑绿。
4. 九刀逐刀见红、复原后复跑全绿，才在交付里写「已实证」；否则只写「走查守卫」。
5. 质量门是 **advisory**：QA 给判定，最终放行由用户决定。

## 七 本口径不覆盖什么（诚实清单）

1. **人眼听感 / 视觉**：E01/E02 只验 `.mp3` 后缀与 `m.loop=true` 源码两行在，**不实际听三首循环是否无缝、不比对图集帧区像素**；这类只能人工 Playtest。
2. **`.godot/imported/` 缓存重建**：仓库零文件入库；改名后首次打开需 Godot 重导入。本口径只验 `.import` 声明文本，**不验缓存文件落盘正确性与重导入耗时**。
3. **public 仓库历史**：历史 commit / tag / fork / 搜索缓存里的旧名**无法靠本批清除**；G2 只覆盖当前工作树的运行时 + 发货面（§1.3），不覆盖历史叙述。
4. **历史档案与构建脚本**：`_backup/`、`production/sprint-*/`、`_tools/`（含生成脚本）、`tests/` 中的旧名按范围外处理；其中 `_tools/spr25_*` 若被重跑仍可能再造旧名文件——本批不验、不修。
5. **README 可选补注**：实施单 §4.3 明写「无合适位置可不改」，本口径**不判、不红**；未补只在交付文档记一句。

---

**口径结论**：本批唯一硬净增量证据 = **12 条验效果型断言 + 九刀红矩阵**；validate / 八探针回归 / E1 三跑 / 冻结台账均属前提守卫或走查守卫，**计 PASS 不计覆盖**。判红严格分 shell 门（`grep`/`md5sum` 输出）与引擎门（批二式看 `ok=false`、批三式看 `[ERR]`），**绝不用 `ok=false` 去判 `_ct_assert()` 式探针**。
