# Sprint 12 交付：两阶段全量（A 元进度 / B 编队+回响 / C 第二 Boss / D 每日挑战 / E 灾祸层）

> 日期：2026-11-07｜依据 `SPR12_规划草案.md`（全锁 A+B+C+D+E，F 第五遗物按坑 5 不接）｜分工：编程侧
> 改动文件：`scripts/data.gd`、`scripts/game_state.gd`、`scripts/game_main.gd`、`scripts/player.gd`、`scripts/slug.gd`、`scripts/boss2.gd`（新）、`scripts/ally.gd`（新）、`scripts/menu.gd`、`scripts/validate.gd`、`resources/texture/generated/icon_suffix.png`（新）

## 阶段一（commit d2807b8）

### A 元进度扩容
- `SIGILS` 3→9：新增 kindred（协战水晶 30s，追击最近敌人接触伤害 2，`ally.gd` 新实体——layer 0 不被任何弹/接触命中，友方判定显式）/ bulwark（开局环盾 2.5s，`relic_shield_t` 置初值）/ sprinter（冲刺距离与无敌帧 ×1.3）/ harvester（击杀 +1 源石）/ ward（Boss 房受伤 round(×0.8)）/ scholar（每层首次清场 +2 地窖碎片）
- 注入走 `_apply_sigil_contract`（rng 前，幂等绝对置位）；`AllyScript` 由 game_main 持引用、每局重生成
- 菜单印记页自动渲染新印记（遍历 SIGILS，无需改 UI 循环——规划 §4.3 预判正确）

### B 编队扩容 + 回响
- `SQUADS` 4→7：hunt（狼×2+火骷髅）/ alchemy（蘑菇人+小鬼×2+火骷髅）/ echo_pack（回响+红虫×2）
- **回响实体**（art 预留兑现）：`Data.ENEMIES` 新原型，tex 复用 `shadow`（**零新美术**——art 预留的影子系恰好未用）、ai="echo" 新 AI：前 2.5s 沿玩家轨迹缓冲（0.1s 采样×30）**倒放镜像玩家走位**，之后 3s 周期游走+突进；被击败 → 2s 攻速 ×1.35 增益（buff 路径）
- validate `KNOWN_AI` += "echo"

## 阶段二（commit d70b6c5）

### C 第二主题 Boss「熔潮主宰」
- `boss2.gd` **继承 PrismWarden**（非复制）：主题序列偏移 +4（`phase_theme_index(floor+4, k)`）、脉冲更密（skill_interval 2.2s）、core tint = 阶段一主题 tint（数据驱动）
- 接入谓词 `_is_sovereign_floor(n) = n>4 and (n-4)%16==15`（每 16 层，与守望者每 8 层错开；同层双命中时 sovereign 优先）
- PrismWarden 参数化：`skill_interval` var 化（原 const）
- `SMOKE_BOSS2` 探针 + `SMOKE_FORCE_SOVEREIGN` 验证钩

### D 每日挑战
- `daily_seed = hash(YYYYMMDD) 派生`，start_run 在 **rng 首抽前**覆盖 `Game.rng.seed`（E1 零漂移：同日期派生同 seed，run_seed 随之一致）
- 菜单「每日挑战」按钮（daily_mode=true→start_game）；「开始游戏」显式 daily_mode=false
- 本地榜 `user://daily.cfg`：`daily_best[yyyymmdd] = {layers, time}`（层数优先、同层比时间）；主菜单显示今日最佳
- 结算钩：`record_daily_best(max_floor, time)`（与 shards 同 SMOKE 门控）

### E 灾祸层
- 每层首次进入 15% 触发（走既有 Game.rng 流；`SMOKE_CALAMITY=1` 强制），**本层生效换层清除**：frail（max_hp ×0.8，保存值精确还原）/ frenzy（敌速 ×1.25，Game.calamity_speed_mult）/ scarce_ammo（弹匣 ×0.5）/ scarce_ore（源石 ×0.7）
- shards 结算 ×1.5（`calamity_floors` 非空时）——风险回报
- 触发横幅 + toast；第 1 层保底无灾祸

## 验证（全部实跑）

| 项 | 结果 |
|-|-|
| 阶段一实战：kindred 契约 + echo_pack 编队 + 回响击败增益 ×5 | ✓ 0 报错 |
| C 主权层接入（SMOKE_FORCE_SOVEREIGN + 跳层 11） | boss2 取代 ✓ 三阶段 ✓ |
| C 全链（13000 帧） | Boss 死亡→楼梯→**12 层新周期** ✓ |
| D 每日确定性 | 双 run 同 seed 打印一致 ✓ |
| E 灾祸 | floor-2 scarce_ammo 触发 ✓ 0 报错（_clear 路径修复后无 Invalid assignment） |
| 全量组合回归（八探针 4000 帧） | **0 报错** |
| 冻结清单 | 重定 **32/32 OK**（30 脚本 + boss2/ally .uid 计入） |

## 踩坑记录（如实）

1. **验证钩时序**：daily_mode/calamity_forced 曾在 start_run 之后设置 → floor-1 灾祸与 daily 种子覆盖双双失效。修正：钩子移到 start_run 之前（这类似「验证钩时序」类 BUG-001，钩子必须先于被测路径）
2. **GDScript 变量遮蔽链**：`forced` 在 _roll_calamity 是 bool、在 _roll_squad 是 String——同名不同型，`forced != ""` 在 bool 上下文报 Invalid operands；重命名/收敛作用域后消除
3. **Game.X vs Game.main.X 作用域混淆**：diamond_mult 是 game_main 成员，误写 Game.diamond_mult（game_state 无此字段）→ Invalid assignment；calamity apply/clear 两处已修正 + main 空护栏
4. **新资源必须先 --import**：prop_vine/icon_suffix/icon_affix_mender 均需 import 后才可见（ally.gd 首版漏 speed 声明也由编译扫描抓出）

## 还剩什么

- 全部非阻塞遗留清零（哑弹钳制 ✓ 环盾 HUD ✅（E6 计时+显示随 Sprint 11 落地）✓ E1 基线 ✓ 随本批重定）
- 规划侧下一批发散（Sprint 13）；「回响」镜像时长/击败增益数值可调（data 驱动）
- git 提交待授权（已建库，阶段一/二各自成提交 d2807b8/d70b6c5，后续每批一个 commit）

## 修复批：主理人核验 7 项 → 编程侧修复（全部闭环）

> 主理人读码核验（HOLD）发现 1 处功能缺失 + 2 处运行时缺陷 + 4 项小项；本批全部修复并回归。

| # | 修复 | 落点 |
|---|------|------|
| 1 | 🔴 bulwark 印记零实现 → match 补分支 `relic_shield_t = maxf(cur, 2.5)`（根因：阶段一只逐枚测了 kindred） | game_main `_apply_sigil_contract` |
| 2 | 🔴 换层清灾祸抹掉 modifier 掉率倍率（swarm 1.5→1.0 永久失效）→ apply 时保存 `diamond_mult`/`mag_cap_mult`，clear 还原**保存值** | game_main `_apply/_clear_calamity_effects` |
| 3 | 🟠 frail 吞层内 max_hp 成长 → clear 改 `maxi(max_hp, saved)`（保成长） | 同上 |
| 4 | 🟠 SMOKE 隐式强制灾祸污染回归可比性 → 强制开关只认 `SMOKE_CALAMITY` 显式 env | game_main `_roll_calamity` |
| 5 | 🟡 boss2 身份残留 → setup 补 `boss_name="熔潮主宰"` + `variant="boss"`（DUMP/掉落归位） | boss2.gd |
| 6 | 🟡 daily seed 依赖内建 hash() → `Game.stable_hash()`（FNV-1a）跨版本确定性 | game_state |
| 7 | 🟡 文档两处口径（.uid 表述 / 草案「错开」数学）→ .uid 表述改纯 .gd；草案 §6.1 规划侧自纠 | 文档 |

**逐枚覆盖断言**（新增 `SMOKE_SIGIL_COVERAGE=1`）：9 枚印记逐枚 apply + 可观察断言 + #2/#3 单测（frail 削减/maxi 保成长、scarce_ore 削减/diamond 还原）——实测 9 断言 + 4 单测全过、0 [ERR]。

**修复后回归**：全量十探针（SMOKE+V8+REBIND+RELIC+SUFFIX+PERSIST+COV+CALAMITY+DAILY+BOSS）4000+ 帧 → **0 报错**；冻结重定 32/32（表述勘误：清单为纯 .gd，无 .uid）。
