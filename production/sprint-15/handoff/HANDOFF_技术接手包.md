# Sprint 15 技术接手包（engineering-lead 承接 · 零上下文可启动）

> 生成：工作室 engineering-lead / 程基岩。用途：原编程侧断开后，承接 `scripts/*.gd` 的后续改动。
> **实读声明**：本文以「函数名 / 常量名」为索引，**不写死行号**；改动前对每个落点重新实读（主理人交接稿的行号基于 `dbdb938`，已过期）。
> 基线（本轮实跑）：`md5sum -c` exit 0 / 34 OK / 0 FAILED；`scripts/*.gd` 34 个；`git status --short` 空；headless 600 帧 exit 0。
> ⚠️ 交接稿称最新提交 `dbdb938`；`git log --oneline -5` 实读最新为 `927952e`（S15 文档整理批，纯文档），功能代码基线仍是 `dbdb938`。**以 git 实读为准**。

---

## 0. 一分钟启动

1. 读 `production/sprint-15/SPR15_主理人交接稿.md` → `SPR15_规划草案.md` → 两份 `SPR15_交付_阶段*.md` → 本包。
2. 跑 §2 四条基线命令，确认 34/34 OK、工作树干净、600 帧 0 报错。
3. 从 §4 / §6 选一项，先交「方案 + 影响面 + 回滚手段」待用户授权，再动 `.gd`。

## 1. 项目结构与 34 个脚本的分工

**坐标**：Godot 4.7.2 / GDScript；主场景唯一 `scene/game.tscn`；`project.godot` 的 autoload = `Assets`(assets.gd) / `Game`(game_state.gd) / `Data`(data.gd) / `Dev`(dev_log.gd) / `Validate`(validate.gd) + 插件 `PhantomCameraManager`。`scripts/` 是**唯一**产品代码目录（34 个 `.gd` = 冻结分母）；`tests/spr3_icon_probe.gd`、`addons/phantom_camera/**` 不计入；`resources/` 贴图音频字体 + `.import`；`production/` 各 sprint 文档；`_tools/` 运行日志；`_backup/` 历史备份。

| 层 | 脚本 | 职责（以实读为准） |
|---|---|---|
| 数据表 / 静态规则 | `data.gd` `meta.gd` `weapons.gd` `relics.gd` `upgrades.gd` `dungeon.gd` | `data.gd` 唯一大表：ENEMIES / FLOOR_POOLS / FLOOR_THEMES / ROOM_META / AFFIXES / SQUADS / RELIC_SUFFIXES / SIGILS / ACTIVE_RELICS / MILESTONES / SHRINE_OFFERS / CODEX_BOSS_NAMES / CODEX_BOONS + `theme_for_floor` / `pool_for_floor` / `roll_enemy`；`meta.gd` 冻结的 UNLOCKS / ECONOMY / payout；`weapons` / `relics` / `upgrades` 三类池与 `apply` 分支；`dungeon.gd` 的 `generate()` 地图生成（含秘密房/超秘） |
| 全局状态 / 持久化 | `game_state.gd` | `FIXED_DT` / `rng` / `fx_rng` / 分数连击；`user://` 五套 ConfigFile（meta / codex / sigils / daily / settings）存读与坏档降级；`_codex_id_valid` / `mark_codex` / `codex_boons()` 只读派生；`meta_settle_run` 结算。**SMOKE 下走 `_smoke_*` 隔离档，绝不写玩家档** |
| 主循环 | `game_main.gd` | 唯一场景主控：`_ready()` 调 `Validate.run()` → `start_run()`；房间/层/主题/灾祸/圣所/图鉴 boon；刷怪、掉落、`on_slug_killed` 图鉴登记、Boss 优先链；SMOKE autopilot、`_smoke_fingerprint()`（只含 rooms 坐标 + kinds）、`_settle_meta()`。改动面最广，先读它 |
| 玩家 / 战斗实体 | `player.gd` `bullet.gd` `bomb.gd` `explosion.gd` `toxic_cloud.gd` `ally.gd` `turret.gd` `pickup.gd` | `player.gd` = 移动/开火/装填/技能/主动遗物/反应词缀/`buff()`/`_tick_buffs()`/autopilot + 全部表外探针（`_codex_probe` / `_codex_boon_probe` / `_third_boss_probe` / `_suffix_probe` / `_shrine_probe` / `_sigil_coverage_probe`）；其余为子弹、炸弹、爆炸、毒云、无人机、炮台、拾取物 |
| 敌人 / Boss | `slug.gd` `boss.gd` `boss2.gd` `boss3.gd` | `slug.gd` 敌人实体 + AI 分支；`boss.gd` = `PrismWarden` 基类（`codex_id` / `phase_theme_index()` / 阶段机）；`boss2` / `boss3` = `extends PrismWarden`，`_init()` 覆写 `codex_id` 与 `variant="boss"` |
| 世界 / 房间对象 | `door.gd` `crate.gd` `prop.gd` `secret_wall.gd` `shop_stand.gd` `merchant.gd` `shrine_panel.gd` `upgrade_panel.gd` | 门 / 箱 / 场景道具 / 秘密墙 / 商店摊 / 商人 + 圣所选牌面板 / 升级卡面板（含 reroll、图标 resolver） |
| UI | `menu.gd` `hud.gd` `dev_overlay.gd` | `menu.gd` = 主菜单 + 图鉴只读平行页 + 设置/按键重绑/印记/解锁页；`hud.gd` = 状态栏/小地图/进度条/结算页；`dev_overlay.gd` = F3 日志面板 |
| 资源 / 校验 / 日志 | `assets.gd` `validate.gd` `dev_log.gd` | `assets.gd` = `GEN_NAMES` / `ACTION_DEFS` / `g()` / `icon()` / `xicon()` / 输入注册与重绑定；`validate.gd` = 启动期 20+ 类 `_check_*` + `_check_scripts_compile()` 全脚本编译扫描 + P0 红线门；`dev_log.gd` = `Dev.info/warn/err/check` 环形日志 |

上表 8 层合计 **34** 个脚本；归类为「大致分工」，具体函数一律以实读为准。

## 2. 运行与自检：确切命令与「怎么算跑通」

```bash
cd "D:/Create/Game/test-1"
GODOT="D:/SteamLibrary/steamapps/common/Godot Engine/godot.windows.opt.tools.64.exe"
git status --short                                        # 期望：空（或仅本批授权文件）
md5sum -c production/sprint-7/SPR7-FROZEN-4.md5          # 期望 exit 0 / 34 OK / 0 FAILED
ls scripts/*.gd | wc -l                                   # 期望 34
git log --oneline -5
# 单跑：headless 主钩（本轮实跑 600 帧：exit 0 / 0 SCRIPT ERROR / 0 Parse Error）
SMOKE=1 SMOKE_SEED=4 "$GODOT" --headless --path "D:/Create/Game/test-1" \
  res://scene/game.tscn --quit-after 600 > /tmp/smoke.log 2>&1
grep -E "validate problems|脚本编译扫描|自检通过|autopilot" /tmp/smoke.log
```

**主钩 + 表外探针**：`SMOKE=1` 是总开关（`game_main._ready()` 据此开 autopilot、`Engine.time_scale=2.0`、默认无敌）。钩子清单（交接稿 §七）：`V8 / REBIND / RELIC / SUFFIX / META / PERSIST / BOSS / BOSS2 / ECHO / DAILY / CALAMITY / SHRINE / CODEX / CODEX_BOON / SIGIL-COV / FORCE_SQUAD / FORCE_SOVEREIGN / JUMP_FLOOR / FORCE_THIRD_BOSS / THIRD_BOSS`；实际变量名一律 `SMOKE_` 前缀，**逐个以 `OS.get_environment(...)` 实读为准**（已实读示例：`SMOKE_V8`、`SMOKE_SEED`、`SMOKE_META_FINGERPRINT`、`SMOKE_META_UNLOCK`、`SMOKE_META_PATH`、`SMOKE_BOSS`、`SMOKE_FORCE_SQUAD`、`SMOKE_FORCE_THIRD_BOSS`、`SMOKE_JUMP_FLOOR`、`SMOKE_META_SETTLE`、`SMOKE_DASH_TRACE`）。注意：`SMOKE_JUMP_FLOOR` 吃**层号数值**不是布尔；`SMOKE_FORCE_SQUAD` 吃编队 id；`SMOKE_META_SETTLE=1` 才开结算；`SMOKE_BOSS` 是火力提速钩；全量回归为 6000 帧。

**E1 双跑指纹**（cwd 同上；去掉 `floor=N` 后按层交集逐字比对，勿 diff 全量日志）：

```bash
SMOKE=1 SMOKE_SEED=4 SMOKE_META_FINGERPRINT=1 "$GODOT" --headless --path . res://scene/game.tscn --quit-after 600 > /tmp/fp_a.log 2>&1
SMOKE=1 SMOKE_SEED=4 SMOKE_META_UNLOCK=all SMOKE_META_FINGERPRINT=1 "$GODOT" --headless --path . res://scene/game.tscn --quit-after 600 > /tmp/fp_b.log 2>&1
```

**怎么算跑通（四门控，全部满足才 PASS）**：① `exit 0`；日志中 `[SMOKE] validate problems=0`、`[INFO] validate: 脚本编译扫描 34/34 通过`、自检通过行齐；`SCRIPT ERROR` / `Parse Error` / `Invalid access to property or key` / `[ERR]` / `[SMOKE-LOOP]` 计数均为 0；全量 6000 帧各探针「断言 + done 落地」且**断言验数值不能只验标志**。② E6：新增行 grep 零 raw `delta` / 零新计时。③ E1：双跑 `[SMOKE-META] fingerprint` 逐字一致、`ACTION_DEFS` / `GEN_NAMES` 零新增、`meta.gd UNLOCKS` 不碰。④ `md5sum -c` 仍 exit 0 / 34 OK / 0 FAILED、脚本数仍 34、`git status` 仅本批预期文件。⚠️ 退出期 `ObjectDB instances were leaked` 属 `--quit-after` 强杀提示，改前基线同样存在，不计判据。

## 3. 改动前必查的九条红线

| # | 红线 | 实读锚点 / 违反后果 |
|---|---|---|
| 1 | **E6**：计时 / DoT / 冷却一律 `Game.FIXED_DT`（`1.0/60.0`），禁 raw `delta` | `game_state.gd` 常量；`boss` / `slug` / `ally` / 主题 DoT 均走固定步。既有豁免 `player._tick_buffs(delta)` 与 `toxic_cloud` 敌方云为在册豁免，别顺手「统一」→ 会改 E1 基线 |
| 2 | **E1 确定性**：核心循环零新增 `Game.rng` 消费；`SMOKE_*` 表外探针不进指纹 | `_smoke_fingerprint()` 只含 rooms 坐标 + kinds；新增 rng 会令掉落/编队序列漂移、双跑指纹分叉。地图 rng 走独立 `_floor_rng()` |
| 3 | **坑 5**：`assets.gd` 的 `ACTION_DEFS` 不加新 action；新资源经 `Assets.g()` 取用必须同步登记 `GEN_NAMES` | `validate._check_active_relics()` 依赖 `ACTION_DEFS` 查 `key_action`；`icon_codex` 曾因漏登记 `GEN_NAMES` 静默白框 |
| 4 | **冻结规格 v2.10**：`meta.gd UNLOCKS` 不可改 | 局外内容一律平行只读派生（`game_state` / `menu` 均有「不碰 UNLOCKS」注记）；改它 = 规格变更，须用户裁定 |
| 5 | **登记三件套**：新增 id / 资源 / 记录点必须 ①写入 ②注册表·白名单·UI 分母·显示名 ③可见效果断言，逐项打勾 | 锚点：`_codex_id_valid` / `CODEX_BOSS_NAMES` / `codex_bosses_total()` / `mark_codex`；只验中间状态不算过 |
| 6 | **boon 自激 P0**：`CODEX_BOONS[*].kind` 不得为 `suffixes` | `validate._check_codex()` 有启动期遍历断言（前提守卫型）。确需 suffixes 阈值 → 换「不回写图鉴的内部绑定路径」并重做此门，禁止直接放开 |
| 7 | **F1 `FLOOR_THEMES` 8→12 永不接** | `data.theme_for_floor()` 用 `FLOOR_THEMES.size()` 动态取模，而 `boss.phase_theme_index()` / `_is_warden_floor` / `_is_sovereign_floor` 硬编码 `%8` / `%16` → 四处周期来源不一致，扩容即双轨错位 + E1 全量重定 |
| 8 | **主题 Boss 契约**：`variant="boss"` 承载宝箱 / 词缀必掉 / 震屏，严禁改；图鉴登记一律走 `codex_id` | `boss2` / `boss3` 的 `_init()` 同时设置两者；`on_slug_killed` 用「`codex_id` 优先、variant 回退」。曾因占用 variant 导致「巨岩虫之王」误登记 |
| 9 | **dash 位移保持 196–210px** | 手感特性非缺陷。相关：`_dash_t` / `_dash_dir` / `dash_boost_mult` / `velocity = _dash_dir * 300.0`；改前用 `SMOKE_DASH_TRACE=1` 复跑取实测位移，超区间即回退 |

补充纪律：凡标 ✓ 必附**本轮实读**证据；范围注记与行号同样要实读（交接稿已出现过 `boss.gd` 行号串台的教训）。

## 4. 五类常见故障：症状 → 先查哪里 → 最小修法

| 故障 | 症状 | 先查哪里 | 最小修法 |
|---|---|---|---|
| ① 解析错 | `Parse Error`；`脚本编译扫描 N/N` 不通过；启动即点名文件 | `validate._check_scripts_compile()` 的 `bad` 列表；`project.godot [autoload]` 顺序；子类是否**重复声明**父类成员（`boss3` 用 `_init()` 覆写 `codex_id`，不能在子类再 `var codex_id`） | 只改点名文件 → 跑 600 帧 headless，确认 `脚本编译扫描 34/34 通过` 与 `validate problems=0` |
| ② 恒过假断言 | 断言恒绿，故意改坏实现也不报错 | `Dev.check` 两侧是否同值 / 常量自比较 / 只验 flag（如 `_buffs.has("boots")`）；`validate._check_shrine()` 的 B4 与 `_check_codex()` 的 P0 门属**前提守卫型**（当前恒过，用于拦未来放宽） | 补真差值构造（临时注入非法值，确认断言红一次）或改验数值（`is_equal_approx(speed_mult, ...)`）；文档标注性质，勿冒充「验效果型」 |
| ③ 声明与效果不符 | 文档说有、实读没有；图鉴分母错；按钮白框 | 三件套是否闭环；`Assets.g()` 是否返回 null；`_codex_id_valid` 白名单、`codex_bosses_total()` 分母、`CODEX_BOSS_NAMES` 显示名 | 补全登记 + 一条启动期 `== null` 断言（照 `icon_codex` 范例）；同步订正交付文档措辞，不采信自述结论 |
| ④ 跨层状态残留 | SMOKE 双跑指纹不一致；第二轮挂；结算值漂移；存档被污染 | `user://` 三套隔离档（`_smoke_meta.cfg` / `_smoke_codex.cfg` / `_smoke_sigils.cfg`）与 `load_meta()` 首读删档；`Game.reset()` 调用点；`[SMOKE-LOOP]`；`Engine.time_scale=2.0` 下 delta 波动 | 跨进程往返用 `SMOKE_META_PATH` 指向 ≠ 默认隔离档的路径；坏档 4 模式各用独立路径且各起独立进程；E1 只比指纹（按层交集、逐字），**不 diff 全量日志**；同种子跑 3 次取分布 |
| ⑤ 资源生成没登记 | 静默白框 / 图标不显示，零报错零 WARN | `assets.GEN_NAMES` 与 `Assets.g()`；`ICON_RECTS`；`validate._check_textures/_check_icons/_check_codex` | 把名字补进 `GEN_NAMES`（**不加** `ACTION_DEFS` 条目）→ 补启动期非空断言 → 跑 600 帧确认 0 problems；若涉及新 PNG，另需 `--headless --import` |

## 5. 小步改动：备份 → 验证 → 回滚

1. **先授权**：动 `.gd` 前交「方案 + 影响面 + 回滚手段」待用户确认；提交 / 发布 / 删除 / 规格变更须显式授权。
2. **备份**：`mkdir -p _backup/spr16_<主题> && cp -a scripts _backup/spr16_<主题>/ && md5sum scripts/*.gd > _backup/spr16_<主题>/before.md5`（沿用 `_backup/spr3..spr6` 范式）。
3. **小步**：一次只改一个落点；改完 `git diff` 逐行实读，并用 `md5sum` 对比 `before.md5` 证明补丁真落地（**报告 ≠ 磁盘状态**，坑 52/53/54）。
4. **四门控**：按 §2 跑 600 帧 + 全量 6000 帧 + E6 grep + E1 双跑 + 探针 done。
5. **冻结重定**：`md5sum scripts/*.gd > /tmp/new.md5` → 逐条替换 `production/sprint-7/SPR7-FROZEN-4.md5` 中对应行 → `md5sum -c` 必须 exit 0 / **34 OK**（行数不变、无新脚本；新增脚本须单独登记并重跑全量）。
6. **交付文档**：补记「断言性质 / E1 漂移 / 冻结重定 / 实读证据路径」，不采信自述。
7. **单独提交**：`git add` 仅本批文件，一次 commit，注明批次；**不混入**主理人侧待授权文档。
8. **回滚**：`cp -a _backup/spr16_<主题>/scripts/. scripts/` →（有新增 PNG 时）`"$GODOT" --headless --path . --import` → 重跑 `md5sum -c` 回到 34/34 → 需撤销提交时 `git revert <commit>`（须用户授权）。回滚后必须重跑 §2 基线，确认回到冻结态。

## 6. 能力边界声明（engineering-lead）

**可独立承接**：① 断言补强与注释性质标注（前提守卫型 / 常量自比较 / 只验 flag 补验数值）；② 表外 `SMOKE_*` 探针扩展与测试证据补齐；③ 数据表条目增补（严格走三件套）；④ 局部 bug 修复（不新增 `Game.rng` 消费、不引入 raw `delta`、不改 E1 指纹）；⑤ 可读性与性能重构（行为等价、指纹逐字一致）；⑥ 交付文档 / 交接稿的技术校订；⑦ 架构评审、ADR 与控制清单维护。

**必须回交用户裁定**：git commit / push / 发布上线；删除文件或脚本；冻结规格 v2.10 与九条红线口径变更（F1 主题扩容、boon suffixes 阈值、Boss `variant` 契约、dash 手感区间、`ACTION_DEFS` 新 action、`UNLOCKS` 改表）；新增/删除脚本导致冻结分母变化；重定 E1 基线；引擎版本升级或跨平台迁移。

**分工如何落地**：主理人（team-lead）**只编排、只核验、不建造** —— 出规划草案与自包含规格、实读挂接点、读码核验（PASS / CONCERNS / final PASS）、维护文档与工作日志，**不写任何 `.gd`**；engineering-lead 只按主理人产出的规格实现 `.gd` 并留测试证据，不自行扩范围；quality-lead（QA）只做验收与用例，不改产品代码。三方互不代写。批次链固定为：**实施 → 四门控 → 冻结重定 → 交付文档 → 单独提交 → 主理人读码核验**，每批一个 commit，不回头补。

## 7. 已知风险与知识缺口

- **行号**：本文不写死行号，函数名 / 常量名为索引，落点**以实读为准**；主理人交接稿行号基于 `dbdb938`，已过期。
- **基线漂移**：实读 `git log` 最新为 `927952e`（纯文档批），功能码仍 `dbdb938`；Sprint 15 在册观察 5 条（P0 断言名实不符 / D buff 只验标志 / `_tick_buffs` raw delta 既有豁免 / `_third_boss_probe` 直调有副作用 / B4 与 P0 门前提守卫型）建议下批 QA 窗口清。
- **知识缺口**：仓库内未检出 `docs/engine-reference/godot/VERSION.md` 与 `design/gdd/`；Godot 4.7.2 具体 API 若超出把握，标记缺口回问主理人补齐引擎参考，**不臆造 API**。
- **本文边界**：本包为新增文档，**未修改项目内任何现有文件**；所列命令均本轮实跑验证（`md5sum -c` 34/34、600 帧 headless exit 0）。
