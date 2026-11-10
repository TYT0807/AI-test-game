# SPR19 交付 · 阶段一（shrine 第六类发现集 · 核心登记）

> 基线 HEAD `cb22513`；34 个 `.gd`；冻结 `md5sum -c` 34 OK / 0 FAILED。
> 本批**零新增实体 / 资源 / 输入动作、零新增 `Game.rng` 消费、零 raw `delta`、`ACTION_DEFS` 18 条零新增、`GEN_NAMES` 零新增、`FLOOR_THEMES` 零动、E1 指纹零重定**。
> 阶段一只做草案 §三 必改 1–4 + §九-1 配套断言；**阶段二的 validate P0 断言 / player.gd「五类」措辞 / README / 玩法说明 / 文档批 一律未做**。

## 零、结论速览

| 项 | 结果 |
|---|---|
| `game_state.gd` | `CODEX_KINDS` 加 `"shrine"`（**单数**）；两处初始字典 `:280` / `:352` 同步；`_codex_id_valid()` `:314` 加分支；`:277` 注释补「/ 已行圣所抉择」 |
| `game_main.gd` | `_on_shrine_chosen():2147` 加 `Game.mark_codex("shrine", …)`；`_codex_boon_suffix():2257` 加 `continue` 跳过 shrine（**切断跨版本基线漂移**） |
| `menu.gd` | `_build_codex():429` 加 `_codex_section("shrine", "已行抉择", Data.SHRINE_OFFERS.size(), …)`，不改通用渲染 |
| `data.gd` | `:379-382` 4 行注释改写（**CRLF 文件已核**）；`FLAVOR` 10 条 `shrine/<id>` 文案**逐字未动**；`SHRINE_OFFERS` / `CODEX_BOONS` 表体零动 |
| `player.gd` | `_codex_boon_probe():1154-1171` 加 §九-1 配套**验效果型真差值断言**（shrine 三态 0/1/10） |
| 四门控 | 见 §三；E1 指纹 `55bf3134…` 与 S18 批次、HEAD 三方逐字节一致 |
| 负向对照 | 1 基线 + 5 变体，全部按设计转红（§四）；**n1 实证了 §八-1 漂移真实存在** |
| 冻结清单 | 重定 **5 行** = 改动文件数，仍 34 行、**34 OK / 0 FAILED** |

## 一、实施内容（逐文件，附实读行号）

### 1.1 `game_state.gd`（LF）

| 行 | 改动 | 依据 |
|---|---|---|
| `:277` | 注释补「/ 已行圣所抉择」 | 草案 §三-1 / 设计实稿 A2 |
| `:279` | `const CODEX_KINDS := ["enemies","relics","suffixes","themes","bosses","shrine"]` | 草案 §二-2「kind 逐字单数」 |
| `:280` | `var codex := {…, "shrine": [], "last_run": {}}` | 硬编码字典两处之一 |
| `:314-316` | `_codex_id_valid()` 的 `match` 加 `"shrine": return Data.SHRINE_OFFERS.has(id)` | 与 `:308 "suffixes"` 同型；单源取表、不另造白名单 |
| `:352` | `load_codex()` 内 `codex = {…, "shrine": [], "last_run": {}}` | 硬编码字典两处之二 |

**`load_codex():356` / `save_codex():376` 的 `for kind in CODEX_KINDS` 函数体一字未改**（`diff` 实证）；`mark_codex()` 通用函数体一字未改（`git diff` 命中 `flash_toast|save_codex()|arr.append` = 0）。

### 1.2 `game_main.gd`（LF）

**① 登记挂点 `:2144-2147`**（`_on_shrine_chosen()`）：

```gdscript
	_shrine_execute(offer)
	dungeon.rooms[_shrine_coord]["cleared"] = true
	Game.mark_codex("shrine", String(offer["id"]))
	_echo_choices.append(String(offer["id"]))
```

两道守卫**未绕过**：`:2140 _shrine_affordable()` 拦置灰卡（"看过"不算）；`:2142 _shrine_execute()` 成功返回之后才登记（"试过但执行链早退"不算）。与 S16 `_echo_choices` 同源同序，零新增事件源 / 零 rng / 零计时 / 不改 `_write_codex_replay`。

**② `_codex_boon_suffix():2253-2259` 派生保护**：

```gdscript
	for k in Game.CODEX_KINDS:
		if String(k) == "shrine":
			continue
		key += "%s=%s|" % [String(k), ",".join(Game.codex[k])]
```

理由（§九-1）：该函数被 `start_run:354 _apply_codex_boons()` → `:2223` → `:2239 player.attach_suffix(_codex_boon_suffix())` 调用，原先拼**全部** `CODEX_KINDS` 作 `stable_hash` 的 key。扩第六类后，即使 `codex["shrine"] == []`，key 也会多出 `"shrine=|"` → 同一份老 `codex.cfg` 派生出不同开局铭刻词缀（实测见 §四 n1）。
**如实登记**：该漂移**不是 E1 违规**——图鉴档是局外输入，项目既有口径即「档不同 → 起始状态不同」，且 `_smoke_fingerprint()` 只含 rooms 坐标 + kinds；它是**跨版本基线漂移**（无意改变既得 boon 结果），已主动切断。

### 1.3 `menu.gd`（LF）

`_build_codex():427-430` 末尾追加（不改 `_codex_section()` 通用渲染）：

```gdscript
	_codex_section("shrine", "已行抉择", Data.SHRINE_OFFERS.size(),
		func(id: String) -> String: return String(Data.SHRINE_OFFERS.get(String(id), {}).get("name", id)))
```

- 标题逐字「已行抉择」（设计实稿 §2.2 裁定）；
- 分母 `Data.SHRINE_OFFERS.size()` 单源，不硬编码 10；
- `.get(String(id), {}).get("name", id)` 双层兜底，防未知 id 直出英文；
- 不改手记无分隔符的既有形态（§九-3 裁定，登记为在册观察，见 §八）。

### 1.4 `data.gd`（**CRLF**，489 处 `\r\n` / 0 处 LF-only）

`:379-382` 4 行注释由「**不喂 mark_codex** / CODEX_KINDS 五类不含 shrine / 不进发现集与首发现播报」改为「同时供 `shrine_panel` 恒显灰字直查与 `mark_codex("shrine", id)` 首发现播报」，**保留「显示条件仍为恒显（不读发现状态）」那句**。

实测：
```
$ diff <(grep '^\s*"shrine/' 备份) <(grep '^\s*"shrine/' 现文件)   → 10 条文案逐字一致
$ diff <(SHRINE_OFFERS 表体备份) <(现)                              → 表体零变化
$ diff <(CODEX_BOONS 表体备份) <(现)                                → 零变化
$ python 行尾扫描 → CRLF=489 LF-only=0（仍是纯 CRLF，未混排）
```

### 1.5 `player.gd`（LF）

`_codex_boon_probe():1154-1171` 追加 §九-1 配套断言（**验效果型 · 真差值**）：

- 三态输入：`codex["shrine"]` 分别 `[]` / `["blood_relic"]` / 全 10 条，先断言 `n_full == Data.SHRINE_OFFERS.size()` 证明**输入确实变了**（不是恒定输入冒充差值）；
- 再断言三种输入下 `gm._codex_boon_suffix()` 返回值逐字相等；
- 结束后 `Game.codex["shrine"] = shrine_bak` 还原现场。

与 S17 盘点里 `:1127`（常量自比较）、`:1144`（前提守卫型恒过）、`:1149`（只验 `relic_suffixes.size()==1`）不同——本条是**跨版本一致性的真差值断言**，负向对照 n1 已证明它会转红。

## 二、§八「8 处引用」复核结论（**有异议，不照单全收**）

先给结论：**§八 8 行表的语义判断全部复核通过，但「8 处」这个数字是表格行数，不是代码引用数；另有三处精确性需订正。** 逐条如下。

### 2.1 计数异议（实测）

```
$ grep -rn "CODEX_KINDS" scripts/     （改动后）
game_main.gd:2253   for k in Game.CODEX_KINDS
game_state.gd:279   const CODEX_KINDS := [...]      ← 声明本身
game_state.gd:356   for kind in CODEX_KINDS
game_state.gd:376   for kind in CODEX_KINDS
player.gd:1012 / 1022 / 1092 / 1245 / 1260  for k in Game.CODEX_KINDS
validate.gd:229     for k in Game.CODEX_KINDS
```

- **代码引用 = 9 处**（1 `game_main` + 2 `game_state` + 5 `player` + 1 `validate`），不是 8。
- 草案 §一 line 36 自己列的清单 `game_main:2249 / game_state:353,373 / player:1012,1022,1092,1228,1243 / validate:229` **数出来就是 9 项**；§八 把它压成 8 行表，是因为把 `player.gd:1228` 与 `:1243` 两个**独立循环**合并成一行。
- 改前还有第 11 行：`data.gd:381` 注释里提到 `CODEX_KINDS 五类不含 shrine`（本批 A1 已改写，故现 grep 不再出现）。
- 另：`game_state.gd:279` 的**声明**是必改点，但既不是循环也不在 §八 8 行表内；两处硬编码初始字典 `:280` / `:349` 同样不在表内。**这三处才是实施时最容易漏的**，派单已单列，我照做并在此登记。

### 2.2 语义逐条复核（8 行表）

| §八 行 | 我的复核 | 判定 |
|---|---|---|
| `game_state:353`(现 356) `load_codex` | `cfg.get_value("codex", kind, [])` 缺键返回 `[]` → `clean=[]` → `codex[kind]=clean`；且 `:358-360` 用 `_codex_id_valid` 过滤每个 id | ✔ 旧档安全、无越界键穿透 |
| `game_state:373`(现 376) `save_codex` | `cfg.set_value("codex", kind, codex[kind])` 依赖键存在 | ✔ 需两处字典同改（但见 2.3 精确化） |
| `validate:229` `_check_codex` | `if not Game.codex.has(k): problems.append("codex 缺少分类：%s")` | ✔ 自动多验一轮；漏改字典会红（正是想要的门） |
| `player:1012` 清空 | `(Game.codex[k] as Array).clear()` 多清一轮 | ✔ 自动覆盖 |
| `player:1022` 逐类比对 `snap` | `snap = Game.codex.duplicate(true)` 含新键 | ✔ 自动覆盖 |
| `player:1092` P0-3.2 现场恢复 | 逻辑自动多比一轮；`:1095` 文案写死「五类」 | ✔ 逻辑对，**措辞过期属阶段二 A 类，本批未改** |
| `player:1228 / :1243`(现 1245/1260) | 同上；`:1246` 文案写死「五类」 | ✔ 同上，**本批未改** |
| `game_main:2249`(现 2253) `_codex_boon_suffix` | **key 静默变长 → 派生漂移，现有断言假绿** | 🔴 **完全确认，见 §四 n1 实证** |

配套实读：`codex_boons():381-387` 按 `CODEX_BOONS[*].kind + need` 逐条判定，`Data.CODEX_BOONS` 四条 kind 为 enemies/relics/themes/bosses（实读 `data.gd` 表体）→ 扩第六类**不改变 boon 判定**，P0 自激不成立。

### 2.3 三处精确性订正（供主理人核验时采用）

1. **「漏改一处即空指针」需精确化**：`load_codex():356-361` 的循环在 **cfg 文件存在**时会执行 `codex[kind] = clean`，**动态把缺失的 `shrine` 键补回来** → 老档路径下漏改初始字典会被静默愈合，`validate:229` 也**不会红**。真正会红的是 **cfg 不存在**的路径：`load_codex():351-352` `if cfg.load(...) != OK: return` 早退，此时 `codex` 停在声明字典 → 若 `:280` 漏改，`validate:229` 报「codex 缺少分类：shrine」。
   启动顺序实读：`project.godot:20-25` autoload 顺序 Assets→Game→Data→Dev→Validate；`game_state.gd:90-97 Game._ready()` 调 `load_codex()`；`game_main.gd:167 Validate.run()` → `_check_codex():229`。**新装 / `SMOKE_CODEX_PATH` 指向空文件**即此路径。
   另：`save_codex():376` 对缺键 Dictionary 的 `[]` 访问确切行为（返回 null / 报错）本轮**未做运行时实验**，标「推测待验」；但「两处字典必须同改」这一结论无争议，已照做。
2. **行号漂移**：派单/§八 写 `[SMOKE-SHRINE] chose=` 在 `game_main.gd:2150`——文本确实一字未变，但本批在 `:2144-2147` 新增 4 行，该 print 现位于 **`:2154`**。同理 `CODEX_KINDS` 各引用行号已整体后移（见 2.1 表）。沿用「以函数名 / 源码内容定位，行号只作阅读辅助」纪律。
3. **旧档有隐式（无害）格式迁移**：老 cfg 首次 `save_codex()` 会把新的 `shrine` 键写回文件，五个旧键原样保留、`last_run` 原样透传。这不是「越界键穿透」，也不是数据丢失，但**文件格式确实变了**，登记备查。双档隔离 `codex_path():283-289`（`SMOKE_CODEX_PATH` 自定义 → `CODEX_SMOKE_PATH` → `CODEX_PATH`）不受影响；本批 E1 跑用了自定义 `SMOKE_CODEX_PATH` 且 0 报错，实证可用。

## 三、四个门控实测

**① 全量 6000 帧（全 env）**

```
env SMOKE=1 SMOKE_SEED=12345 ... SMOKE_SHRINE=1 SMOKE_SIGIL_OATH=1 SMOKE_CODEX=1 \
 SMOKE_CODEX_BOON=1 SMOKE_SIGIL_COVERAGE=1 ... SMOKE_LAYOUT=1 SMOKE_META_FINGERPRINT=1 \
 "$G" --headless --path . --quit-after 6000
```

| 跑次 | 字节 | `[ERR]` | `SCRIPT ERROR` | `^ERROR:` | `apply_slow` | done 唯一 |
|---|---|---|---|---|---|---|
| `p1_a3` | 改动版（**无 `SMOKE_DAILY`**） | **0** | **0** | 2（退出期 RID/资源泄漏） | 0 | 13 |
| `p1_a4` | 改动版（同 env，双跑） | **0** | **0** | — | 0 | 13 |
| `p1_head3` | HEAD `cb22513` | 0 | 1（既有随机，见补记） | 2 | 1 | 13 |
| `p1_head4` | HEAD（双跑） | **0** | **0** | — | 0 | 13 |

→ **改动版双跑 `p1_a3` / `p1_a4` 均 `[ERR]=0`、`SCRIPT ERROR=0`；HEAD 双跑中 `p1_head4` 同样全 0** → 门控①通过。

**补记（必须如实交代，不掩盖）**：
- 首轮带 `SMOKE_DAILY=1` 的 3 跑（`p1_a` / `p1_b` / `p1_head`）**全部**报同一条 `[ERR] sigil_cov: scarce_ore 削减`（`player.gd:744`）。**HEAD 同样报** → 与本批改动无因果。`game_main.gd:344-346` daily 模式用当日日期覆盖 `SMOKE_SEED`，本轮日期与 S18 批次不同 → 灾祸 roll 不同，`_sigil_coverage_probe` 的 `diamond_mult < dm` 断言偶发失败。去掉 `SMOKE_DAILY` 后该断言在 4 跑中全部消失。这与 §九 / S18 已采纳的「E1 跨批对照禁用 `SMOKE_DAILY`」是同一个坑的另一种表现：**日常全量回归同样建议不带 `SMOKE_DAILY`**，否则跨日基线不可比。
- `p1_head3`（HEAD）另出现 1 条 `SCRIPT ERROR: Invalid call. Nonexistent function 'apply_slow' in base 'CharacterBody2D (boss3.gd)'` @ `bullet.gd:124`。**只出现在 HEAD 对照的这一跑**，`p1_head4` 与改动版 4 跑均为 0；`bullet.gd` / `boss3.gd` 本批零改动。属既有随机遭遇问题（与 S18 登记的 `Lambda capture` 同类），非本批引入。

**② 冻结清单**：`md5sum -c` → **34 OK / 0 FAILED**，仍 34 行；`diff` 证明**只有 5 行**变化，等于改动文件数：

```
data.gd         95311b8d…→398094da…
player.gd       d32fb453…→582497ed…
menu.gd         afefe368…→e36ff2bf…
game_main.gd    22e01945…→4394ead7…
game_state.gd   286848c1…→168fc4a3…
```
其余 29 行一字节未动。`hud.gd` / `shrine_panel.gd` / `validate.gd` / `assets.gd` / `meta.gd` 均未改。

**③ E1 指纹（同 seed 12345，不带 `SMOKE_DAILY`，各 6000 帧，只比 fingerprint 行）**

| 跑次 | 字节 | 指纹 md5 |
|---|---|---|
| `e1_new` | 改动版 | `55bf3134969320177b9f1bacf88f534a` |
| `e1_head` | HEAD `cb22513` | `55bf3134969320177b9f1bacf88f534a` |
| `spr18_e1_new`（S18 批次留档） | 阶段二入库字节 | `55bf3134969320177b9f1bacf88f534a` |

→ `cmp e1_new / e1_head` 逐字节一致，且**与 S18 批次三方相同**：地图流零漂移（floor 1、2 两行）。禁整体日志 `cmp`（逐帧坐标/敌人数量抖动），沿用 S18 方法学订正。

**④ E6 / 零抽取**：`FIXED_DT` 全库 **33** 处（未动）；`git diff cb22513 -- scripts/` 新增行含 `delta` = **0**；新增行（排除注释）含 `randf|randi|randf_range|randi_range|Game.rng.|fx_rng.` = **0**；`.gd` = **34**；`ACTION_DEFS` 实读 **18** 条（`assets.gd` 未改）；`SHRINE_OFFERS` **10** 条、`CODEX_BOONS` 4 条表体零变化；`shrine_panel.gd` / `mark_codex()` 函数体零变化。

## 四、负向对照（1 基线 + 5 变体，固定 seed 12345，双 md5 夹逼）

沙箱 `_backup/spr19_p1/sandbox_probe/` 注入**临时** `SMOKE_S19` 探针（仅沙箱、**不入库**），验渲染与三条必需负向：

| 变体 | 突变 | `[ERR]` | 转红断言 |
|---|---|---|---|
| `base` | 无 | **0** | —（绿灯基线） |
| `n1` | 删 `_codex_boon_suffix` 的 `if shrine: continue` | **1** | `S19: _codex_boon_suffix 三态逐字相等：s_cinderveil / s_cinderveil / s_bulwark` |
| `n2` | `_codex_id_valid` 的 shrine 分支改 `return true` | **1** | `S19-N1 未知 shrine id 被拒` |
| `n3` | 删 `mark_codex` 的 `if arr.has(id): return` | **1** | `S19-N3 重复登记幂等且不重复播报：size=2` |
| `n4` | 播报取键 `kind + "/"` → `kind + "s/"` | **1** | `S19-P1 首发现 toast 含 FLAVOR 实值`（实际拿到别的 toast） |
| `n5` | 图鉴标题「已行抉择」→「已识圣所」 | **2** | `S19-P2 渲染含已行抉择与分母 /10` 等 2 条 |

日志 `_tools/spr19_p1_{base,n1,n2,n3,n4,n5}.log`，每行 `夹逼一致=Y`，`[after]` 与 `[stash]` md5 逐字节相同。

**n1 是本批最关键的一条证据**：删掉 `continue` 后，三态输出从「全等」变成 `s_cinderveil / s_cinderveil / s_bulwark` → ① **§八-1 / §九-1 判定的漂移真实存在**，不是纸面推测；② 新加的三态断言**确实会咬**，不是常量自比较或前提守卫型恒过。

**基线里的正向验渲染实值**（`Dev.check` 只在失败打印，正向证据由 `[ERR]=0` + 显式 print 构成）：
```
[SMOKE-S19] P1 toast=矿工手记 · 血祭。地窖里最不缺的就是血。
[SMOKE-S19] P2 head=已行抉择 1 / 10
[SMOKE-S19] P2b name=　手记：血祭。地窖里最不缺的就是血。
[SMOKE-S19] done
```
探针内另含 N1（未知 id 被拒）、N3（重复登记幂等）、N4（旧 cfg 无 `shrine` 键 → `load_codex()` 给空数组且不报错）、N5（kind 单数锁）、P2b（显示名单不直出英文 id），共 5 条运行时检查；全部绿灯即上述 `[ERR]=0`。

**N4 的敏感性如实标注**：`load_codex()` 的 `for kind in CODEX_KINDS` 会动态补键，因此即使初始字典漏改，旧档路径下 N4 仍可能绿——真正锁「两处字典同改」的是 `validate:229` 在**无 cfg 文件**路径的启动期检查（§二-3.1）。本批两处字典均已改，N4 验的是「旧档读入行为」，不是「字典是否被改」，不夸大其覆盖。

## 五、断言盘点与分类

| 断言 | 性质 | 证据 |
|---|---|---|
| `S19: 三态输入样本确为 0 / 1 / 10 条` | **验效果型**（输入真变） | n1 实证输入构造 |
| `S19: _codex_boon_suffix 三态逐字相等` | **验效果型 · 真差值** | n1 删 `continue` → 转红 1 |
| `S19-N1` 未知 id 被拒 | 验效果型 | n2 → 转红 1 |
| `S19-N3` 重复登记幂等 | 验效果型 | n3 → 转红 1 |
| `S19-P1` toast 含手记实值 | 验效果型（渲染） | n4 → 转红 1 |
| `S19-P2 / P2b` 图鉴渲染 | 验效果型（渲染） | n5 → 转红 2 |
| `S19-N4` 旧档空数组 | **前提守卫型倾向**（见 §四末注） | 未做转红实验 |
| `S19-N5` kind 单数锁 | 常量/键对齐型 | 未做转红实验，属静态锁 |

后两类如实标注，不冒充有效绿灯；阶段二补强时优先处理。

## 六、SMOKE 探针与旧档影响面（实读）

- `_shrine_probe():848-980` 的 ② 段**直接调 `_shrine_execute()` 10 余次**，不走 `_on_shrine_chosen()` → **不会**因本批新增登记而多出 `mark_codex`；只有 ④ 段 `_open_shrine()` → autopilot `_pick()` → `chosen.emit(i)` 才触发登记。
- `shrine_panel.gd:149-155` autopilot 每 0.5s 选**第一张可支付卡**，`_pick():188-196` 单次 `chosen.emit(i)`；`game_main.gd:162` 连线 `shrine_panel.chosen.connect(_on_shrine_chosen)` → **一次圣所一次登记**，不会同帧多条 toast。
- `[SMOKE-SHRINE] chose=` 文本不变（行号由 `:2150` → `:2154`）；`_echo_choices` / `_echo_costs` 逻辑未动。
- 每次成功交换现在多一次 `save_codex()`（纯局外 `ConfigFile.save`）。**探针串扰实测**：`_codex_probe()` 在初始 `await 0.6s` 之后全段同步、无 await，`_shrine_probe()` 的登记点在其后的多个 await（1.2s / 1.4s / 0.8s / 0.9s）之后，故 `snap` / `sets_same` / `sets_ok` 三处快照比对不与登记交错；全量 6000 帧实测 `[ERR]=0`（`p1_a3`）。**若阶段二调整探针 await 顺序，须重新复核。**
- 隔离档 `_smoke_codex.cfg` 会累积 `shrine` 发现；`load_codex():358-360` 对每个 id 走 `_codex_id_valid` 过滤 → 无越界键穿透。`SMOKE_CODEX_PATH` 自定义路径本批 E1 跑实证可用（0 报错）。
- 阶段二待办（**本批未做**）：`validate.gd` P0 启动期断言；`player.gd` 6 处「五类」措辞（`:1084/:1090/:1095/:1226/:1246` 等）；N4/N5 断言补强；README / 玩法说明 / S18 增补注记。

## 七、红线自查（贴 grep）

```
$ git status --porcelain
 M production/sprint-7/SPR7-FROZEN-4.md5
 M scripts/data.gd  M scripts/game_main.gd  M scripts/game_state.gd
 M scripts/menu.gd  M scripts/player.gd
?? production/sprint-19/
```
→ 只有 5 个脚本 + 清单；`shrine_panel.gd` / `assets.gd` / `meta.gd` / `validate.gd` / `hud.gd` **零改动**。

```
FIXED_DT=33   新增行含 delta=0   新增行含 rng 消费=0   .gd=34
ACTION_DEFS=18（assets.gd 零改动）   SHRINE_OFFERS=10（表体 diff 空）
CODEX_BOONS 表体 diff 空   mark_codex 函数体 diff 命中=0
_shrine_offers_for() 的 stable_hash 派生 key 零动   FLOOR_THEMES / GEN_NAMES / UNLOCKS / STATS_KEYS 零动
```

## 八、偏差 / 在册观察 / 待决

1. **【口径冲突，需主理人知悉】草案 §十 写「提交前须经用户许可（本会话尚未授权提交）」，而 `SPR19-IMPL-01` 派单明确要求「阶段一改动 + 交付文档作为一个 commit 单独提交」并给了提交信息。** 我按**派单**（更新、同一权责方）执行提交；若以草案 §十 为准，请立刻告知，我可 `revert`。此处不自行拍板，如实登记。
2. **【范围交界】** 派单既说「阶段一范围 = 必改 1–4，别扩到 5–7」，又在门控里要求「另加一条验效果型断言（§九-1）」。该断言的落点只能是 `player.gd`（`_codex_boon_probe`），属草案 §三-6。我按**门控要求**只加了这一处探针（+2 条 Dev.check），**未**改 6 处「五类」措辞、未加 validate P0 断言、未做其它断言与负向对照入库。请核验时按此口径判定，勿把「player.gd 被改」误读为阶段二提前开工。
3. **【方法学】日常全量回归同样建议不带 `SMOKE_DAILY`**（§三-①补记）：带它时种子按本地日期覆盖，跨日会让 `sigil_cov` 既有偶发断言假红；本批门控① 以「去 daily、固定 seed」的跑法取得 `[ERR]=0`。
4. **【既有随机缺陷，非本批】** `p1_head3` 的 `apply_slow` @ `bullet.gd:124`（`boss3.gd`）与 S18 登记的 `Lambda capture` 同属偶发；本批两文件零改动。
5. **【§九-3 在册观察】** `menu.gd:463-468` 手记拼接无分隔符，shrine 满格 10 条约 150 字，属既有形态被放大而非本批引入；未改 `_codex_section()` 通用渲染。
6. **【N4/N5 断言覆盖有限】** 见 §五，阶段二补强。
7. **`_codex_boon_suffix` 漂移已切断但需跨版本验收**：本批只验了「同一档三态相等」，未验「S18 版与 S19 版对同一 `codex.cfg` 派生出**逐字相同**的 id」。建议阶段二补一条跨版本基线对比（用 `cb22513` 沙箱与现版对同一 cfg 各跑一次并打印 suffix id）。

## 九、回滚

```
git checkout cb22513 -- scripts/data.gd scripts/game_main.gd scripts/game_state.gd \
    scripts/menu.gd scripts/player.gd production/sprint-7/SPR7-FROZEN-4.md5
md5sum -c production/sprint-7/SPR7-FROZEN-4.md5    # 回 34/34
```
批次备份（gitignored，不入库）：`_backup/spr19_p1/` 含 5 个改前 `.gd` + `frozen_before_p1.md5` + `sandbox/` / `sandbox_head/` / `sandbox_probe/` / `p1_stash/`。`_tools/` 亦 gitignored。无新增 PNG，无需 `--headless --import`。

## 十、提交范围

`scripts/{game_state,game_main,menu,data,player}.gd`、`production/sprint-7/SPR7-FROZEN-4.md5`（重定 5 行）、本文件。
**不含** `production/sprint-19/SPR19_规划草案.md` / `SPR19_设计口径实稿.md`（主理人 / 设计侧文件，未跟踪），也不含任何阶段二文档增补。
提交信息：`Sprint 19 阶段一：shrine 第六类发现集核心登记`。
