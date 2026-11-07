# Sprint 13 阶段二（C 地窖图鉴 / 局末复盘）主理人核验报告

> 日期：2026-11-07｜复核对象：`df626ec`（阶段一终审附章，单独提交）+ `7ea947b`（阶段二 C 交付）
> 方法：逐行实读落点 + 提交序列/冻结实校 + 调用链反向追踪 + 断言有效性反查；**不采信交付文档自述**
> 角色边界：主理人**未改任何 `.gd`**

## 一、结论

**功能门主体 PASS，但判 CONCERNS（单点 🟡）—— Sprint 13 收官前置一条。**

C 的双档、校验器、五记录点、只读平行页、结算复盘、E1/E6/坑 5 边界全部真闭环，无功能缺陷。唯一阻断收官的是 **图标 `icon_codex` 已生成入库但未登记进 `GEN_NAMES`，运行时按钮不显示图标**（详见 §三 #1），属「交付声明与可见效果不符」，与 Sprint 12 #6 同类。补一行 + 一条启动期断言后即 **final PASS 收官**，无需重跑 6000 帧全量。

## 二、复核范围与四门控实校

| 门 | 本轮实校 |
|---|---|
| git | `git status --short` 空（工作树干净）；`df626ec` = 1 文件 / +70 行（仅阶段一终审附章）；`7ea947b` = 10 文件 / +330 −8（6 个 `.gd` + 交付文档 48 行 + 冻结清单 + `icon_codex.png`/`.import`） |
| 冻结 | `md5sum -c production/sprint-7/SPR7-FROZEN-4.md5` → **exit 0 / 33 OK / 0 FAILED**；清单 33 行、`scripts/*.gd` 33 个；本批重定 6 条 `.gd` 哈希，行数不变 |
| E1 | 全批新增行零 `Game.rng` / `fx_rng` 消费（`drop_pickup:1698` 的位置抖动是既有调用，本批只在其后加登记）；`SMOKE_*` 表外不进指纹（坑 45）；DAILY seed 全程稳定互证 |
| 坑 5 / 冻结规格 | `assets.gd` `ACTION_DEFS` 与 `meta.gd UNLOCKS` **均未改动**（`git show --name-only` 确认）；图鉴页纯按钮导航，零新 action |
| E6 | 新增行零 `delta` / 计时 / 动效 |

## 三、C 逐项实读判定

| 块 | 实读落点 | 判定 |
|---|---|---|
| 双档 | `game_state.gd:280–286` `codex_path()` 与 `sigil_path():237–243` **逐行同构**（`SMOKE_CODEX_PATH` > `SMOKE` → `_smoke_codex.cfg` > 主档）；`_ready:97` 在 `load_sigils()` 后调 `load_codex()`；`reset():123–143` **不清 codex** → 只增不减成立 | **PASS** |
| 校验器 | `_codex_id_valid():290–306` 与表结构对齐：ENEMIES / RELIC_SUFFIXES 字典 `.has()`、`RelicsRef.POOL` 数组遍历 `r["id"]`、`FLOOR_THEMES` 字典遍历 `[k]["rule"]`；登记与读档共用同一张表 → 「两头忽略未知 id」成立 | **PASS** |
| mark / set / load / save | `mark_codex():310–319` 未知 kind/id 忽略、重复幂等、**新增即落盘**；`set_codex_last_run():323–329` 与 `load_codex():346–352` **双向**负数钳制；`load_codex` 未知 id 过滤 + `save_codex():355–360` 全量写回 | **PASS** |
| 记录点 1 themes | `game_main.gd:710`，在 `th.is_empty()` 早退（`:704–708`）之后、`_theme_rule` 赋值之后；无主题层不产生空串登记 | **PASS** |
| 记录点 2 enemies | `game_main.gd:1684`，`slug.setup(variant, …)` 之后；variant 即 `Data.ENEMIES` 键 | **PASS** |
| 记录点 3 relics | `game_main.gd:1700–1701`，`kind=="relic" and payload != ""` 双条件 | **PASS** |
| 记录点 4 bosses | `game_main.gd:1707–1708`，外层 `Data.enemy(slug.variant).ai == "boss"` 已判；`skeleton_king` 等 4 个键均在 ENEMIES 内，校验器不会静默吞掉 | **PASS** |
| 记录点 5 last_run | `game_main.gd:2199–2200`，在 SMOKE 跳过门 `:2189` **之后**、`meta_settle_run` 之前；`_run_stats():2129–2133` 五项均在 `META.STATS_KEYS` 内，未新增统计源 | **PASS** |
| 附点 suffixes | `player.gd:606`，`attach_suffix` 绑定成功后登记；未知 sid 在 `:601–603` 早退不登记 | **PASS** |
| UI 页 | `menu.gd:153` 按钮 + `show_page():242–245` 统一清容器 + `:298–301` 分发 + `_build_codex():308–343` 只读 `Game.codex` / `Data` / `RelicsRef`；`boss_total:323–326` 只数 ENEMIES 中 `ai=="boss"`，分母自洽、可集齐 | **PASS** |
| 结算复盘 | `hud.gd` `_stats_label` 追加「本局复盘 · 最深 N 层 · 源石 X」，取 `Game.max_floor` / `run_diamonds_earned`，与 `last_run.diamonds` 口径一致 | **PASS** |
| 启动自检 / 探针 | `validate._check_codex():220–235` 正反两向断言 + 词缀取表内真实首 id（不猜 id）；`SMOKE_CODEX:865–899` 隔离档 / 未知 id 两次忽略 / 存盘→清内存→读回逐分类比对 / 钳制 | **PASS** |

## 四、🔴→🟡 缺陷 #1：`icon_codex` 未登记，按钮运行时无图标

**完整调用链（已逐跳实读）**：

```
menu.gd:153  _add_main_button(..., "icon_codex", ...)
  → menu.gd:213  var t := meta_icon("icon_codex")
  → menu.gd:630–636  meta_icon: ICON_RECTS.has(k)? → Assets.g(k) → Assets.g("icon_"+k)
  → assets.gd:177  Assets.g(name) = gen.get(name)
  → assets.gd:147–148  gen 仅在 _init 里按 GEN_NAMES 逐个 load(".../generated/%s.png")
  → assets.gd:109–130  GEN_NAMES 无 "icon_codex"；ICON_RECTS(:58+) 亦无
  ⇒ t == null → menu.gd:214 的 if t != null 跳过 → b.icon 永不赋值
```

**佐证**：全仓 `.gd` 中 `icon_codex` 仅 `menu.gd:153` 一处引用；`gen[` 仅 `:148` 一处赋值；`assets.gd` 在 `7ea947b` 中未改动。`assets.gd:124` 的既有注释写得很清楚：「PNG 已生成，未登记 = `Assets.g()` 返回 null → 静默白框」——本批正好踩中同一个坑。

**影响**：`icon_codex.png`(180 B) 与 `.png.import` 均已入库，但主菜单「图鉴」按钮**退化为纯文字、无图标**；功能不受影响，故定级 🟡 而非功能缺陷。

**声明口径**：交付文档 `:4` / `:29` 称「icon_codex 新像素图标，gen_assets 确定性生成」「图标导入完成」——文件层面成立、**可见效果不成立**。按 Sprint 12 #6 的同一把尺子（声明失实不挂着收官），列为本批唯一收官前置项。

**最小修法（建议编程侧）**：
1. `scripts/assets.gd` 的 `GEN_NAMES`（`:109–130`）追加 `"icon_codex",`（建议放 `:127 "icon_suffix",` 同组）——**只动 `GEN_NAMES`，不动 `ACTION_DEFS`（`:328–348` 坑 5 区）**。
2. `validate._check_codex()` 补一条启动期断言：`Assets.g("icon_codex") != null`，把「生成了但没登记」变成当场报错，而不是靠人眼复查（沿用「工具设计上对，不靠运气」）。
3. 冻结清单重定 `assets.gd` 单条（33 行不变、无新脚本）；跑启动自检 + `md5sum -c` + **单独提交**即可 final PASS，无需重跑 6000 帧全量。

## 五、低优先观察（不阻断，登记在册）

1. **`bosses` 校验器未收窄**：`_codex_id_valid("bosses", id)` 只用 `Data.ENEMIES.has(id)`，理论上任意小怪 id 也能登记进 Boss 分区。当前唯一调用点 `on_slug_killed` 外层已判 `ai=="boss"`，无实害；建议后续收窄为 `ENEMIES.has(id) and ENEMIES[id].ai == "boss"`。
2. **钳制断言只覆盖 `set` 路径**：`SMOKE_CODEX:896–898` 测的是 `set_codex_last_run()`；`load_codex():351` 的读档钳制属「实现保证、断言未覆盖」。按上一轮新纪律「凡标 ✓ 必附证据」，建议补一条「手工写负数到 cfg → load → 0」。
3. **`relics` 登记时机**：挂在 `drop_pickup`（掉落时）而非拾取时，图鉴口径实为「已见即发现」。与草案 §五「记录点 `drop_pickup`」一致，不算偏离规格；若产品预期是「已获得」，需另议改挂拾取路径。
4. **`last_run` 无键白名单**：`set_codex_last_run` 接受任意键，当前唯一来源 `_run_stats()` 五项在册，无实害。

## 六、规格范围注记裁定（编程侧如实披露，记 PASS）

「图鉴 Boss 类只覆盖 slug 型 Boss（巨岩虫之王 / 骷髅王 / 炎魔 / 黑龙），不含 PrismWarden / 熔潮主宰」——**接受为在册遗留，不追加本批范围**。理由：

- UI 分母 `boss_total` 只数 `Data.ENEMIES` 中 `ai=="boss"` 的 4 项，X/Y **可集齐到 4/4**，不会出现「永远差 2」的误导计数；
- 草案 §五只授权了五个记录点，两个主题 Boss 是非 slug 实体、不走 `on_slug_killed`。编程侧**如实披露、未自作主张扩展**，这点符合范围纪律。

后续若要纳入：单列一小批在 boss/boss2 死亡路径挂 `mark_codex("bosses", id)`，并**同步**扩 `boss_total` 分母与 `_codex_id_valid` 的 bosses 白名单（否则登记会被校验器静默忽略）——属规格扩展，不在 Sprint 13。顺带建议把 UI 标题「已击败 Boss」微调为「已击败层主」，避免玩家把两个主题 Boss 算进去。

## 七、收尾状态

- **阶段二功能门主体 PASS；收官前置 #1 一行**。补完并重定冻结后，Sprint 13 锁定范围 **A+C+E** 即 final PASS 收官。
- 阶段一终审附章已由 `df626ec` 按流程单独提交 ✓，阶段一正式收官无异议。
- 三条非阻塞前瞻（阶段一在册）仍随文档登记，不返工。
- 本报告为新建文档、**尚未提交**，按批次流程待授权后单独提交。主理人本轮**未改任何 `.gd`**，仅新建本报告 + 更新工作日志与长期记忆。
