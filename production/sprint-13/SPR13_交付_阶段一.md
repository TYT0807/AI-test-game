# Sprint 13 阶段一交付：A 抉择圣所 + E 打磨批

> 日期：2026-11-07｜依据 `SPR13_规划草案.md`（阶段一 = A + E；F 不接）｜分工：编程侧
> 改动文件：`data.gd` / `dungeon.gd` / `game_main.gd` / `game_state.gd` / `shrine_panel.gd`（新）/ `slug.gd` / `assets.gd` / `hud.gd` / `menu.gd` / `player.gd` / `validate.gd` / `resources/texture/generated/cellar_bg.png`（新）

## A 抉择圣所（第 11 房型 shrine）

- 数据：`ROOM_META` +1（圣所，mark "+"）；`SHRINE_OFFERS` 6 条——blood_relic 血祭（上限换遗物）/ ore_upgrade 源石淬炼（-8 源石触发升级三选一）/ purify 净化（代价=本层 ×1.5 作废）/ ward_boon 护盾祝福 / heal 修复（积分回血）/ relic_suffix 铭刻（上限换词缀）；`MILESTONES` +first_shrine
- 生成（dungeon.gd）：floor>=3 每层从剩余战斗房**确定性**挑 1 间（坐标排序取首，**零 rng 消费**——同 seed 同布局同圣所位）；只改 kind，房间坐标与总数不变；floor<3 无（min_floor 门槛）
- 挂接（game_main）：`_enter_room` 已清组 + shrine（门不锁、可自由离开，未选重进重开面板）；loot 分支出面板；选定 → `cleared=true` → 重进 skip_loot 不重复扣/发（宝箱/商店同范式）
- UI（shrine_panel.gd 新建薄面板）：card_1/2/3 复用已注册键位（**坑 5 零新 action**）+ 点击；代价不足置灰不可选（面板层 + `_on_shrine_chosen` 双保险）；SMOKE autopilot 自动选第一张可支付卡
- E1（草案 §4.5 口径）：三卡由 `stable_hash("%d_%d_%d" % [run_seed, floor, coord])` 纯派生（同 seed+层+坐标=同三选一，**零 Game.rng 消费**）；铭刻词缀同源派生（`_shrine_suffix_pick`）；奖励执行复用既有接口（Relics.roll / Upgrades.roll 属玩家驱动的既有 rng 路径，登记）；`_smoke_fingerprint` 因房型 kind 变化重定（预期代价）
- 防呆：空池护栏（floor<3 / 过滤后不足 3 张返回 []，`open()` 早退）；max_hp 代价保底 1（防扣死）；purify 无灾祸层不出现（生成过滤）

## E 打磨批（在册遗留清零）

| 项 | 落地 |
|---|---|
| 回响数值 data 驱动 | `Data.ECHO_TUNING` 7 常量（mirror/cycle/chase/dash/creep/buff_mult/buff_time），slug._ai_echo + 击败增益改读表——**零逻辑改动** |
| 地窖背景板（art 预留） | gen_assets.py `cellar_bg()`（320×180 砖拱墙+矿灯+源石晶体，确定性算式无 random）→ 主菜单背景层（遮罩之上、内容之下、mouse IGNORE） |
| audio 事件表 | SFX 别名 +2：shrine / calamity（复用既有 wav，audio-director 口径同 Sprint 11 B）；`_roll_calamity` / `_open_shrine` 挂调用 |
| HUD 可访问性 | FLOOR_THEMES +mark 8 符号（◆●▲□★◇▽■）与主题名并列展示（颜色非唯一编码）；设置页 +「HUD 字号」档（小/标准/大，hud 25 处字号经 `_fs()` 折算，下局生效） |
| dash option b | 保持 196–210px（设计裁定，本批不动） |

## 验证（全部实跑）

| 项 | 结果 |
|-|-|
| SMOKE_SHRINE 定向 1500 帧 | 确定性（同 key 逐字一致 / 跨坐标不同集）+ 六效果代价逐条 + 置灰三条 + 实开面板全链（打开→autopick→关闭→cleared 回写）+ 空池护栏——0 报错 |
| 启动自检（validate） | **0 problems**；新增圣所表自洽 + 5 层分配抽查（floor<3 零间 / floor>=3 恰 1 间，本地固定 rng 零 E1 影响）+ 编译扫描 33 .gd |
| 全量回归（SMOKE+V8+REBIND+RELIC+SUFFIX+PERSIST+COV+SHRINE+CALAMITY+DAILY+FORCE_SQUAD=echo_pack+FORCE_SOVEREIGN+JUMP11+BOSS，6000 帧） | **0 报错**；BOSS2 floor=11 / echo_pack 编队 + 回响击败增益 / 圣所实选 relic_suffix / first_shrine 里程碑 / DAILY seed 1410307864 全证据 |
| 灾祸真实流程 | jump2→boss→floor3 强制触发 frenzy ✓（_roll_calamity 的 calamity sfx 行随批落地） |
| E1 指纹自洽 | SMOKE_SEED=12345 双跑指纹 md5 逐字一致；漂移面=房型 kind 一项（登记重定） |
| E6 | shrine_panel 无 _process 无计时；新动效零 raw delta（grep 0 命中） |
| 冻结重定 | `md5sum -c` **33/33 OK**（+shrine_panel.gd） |

## 踩坑记录（如实）

1. **offer 缺 id 字段**：SHRINE_OFFERS 按 id 键存（同 RELIC_SUFFIXES 范式），内层字典无 id——面板/执行/探针的 `o["id"]` 全崩（SMOKE_SHRINE 首跑 12 条 SCRIPT ERROR 当场拦下）。修：`_shrine_entry()` 统一富化，流动 offer 一律带 id
2. **size 断言被前置探针污染**：全量回归含 SMOKE_SUFFIX（8 词缀绑满）→ 铭刻是同值覆盖，`size()` 断言误报。修：改断言**绑定值**（`relic_suffixes[relic] == sid`），顺手把词缀选取提取为 `_shrine_suffix_pick()` 纯函数
3. **函数截断**：提取纯函数时 `_shrine_execute` 的代价 match 块掉进新函数作用域（Parse Error: offer not declared ×4）。修：结构还原——探针门控再次当场拦截
4. **灾祸证据与 boss 击杀节奏**：跳层后的楼层不 roll（roll 只在 start_run 的 floor1 与 next_floor）是探针钩子既有形态非缺陷；6000 帧能否见到第 2 层随种子布局波动，定向证据经 jump2→boss→floor3 取得

## 还剩什么

- **阶段二（C 地窖图鉴 / 局末复盘）**：`codex.cfg` 双档 + `mark_codex` 记录点（spawn_slug / drop_pickup / _apply_floor_theme / on_slug_killed / _settle_meta）+ 主菜单图鉴页（只读，不碰 UNLOCKS）+ 本局复盘 + SMOKE_CODEX + codex sfx 别名
- 备选未接：B 武器淬炼 / D 每日深化（草案 §七口径）
- E1 指纹重定已登记（房型 kind 变化；同 seed 自洽已验）
