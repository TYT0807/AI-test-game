# Sprint 11 交付：A 反应式遗物词缀 + C 地窖印记种子契约

> 日期：2026-11-07｜依据 `SPR11_规划草案.md` §三/§四（design-strategist 实稿）｜分工：编程侧
> 改动文件：`scripts/data.gd`、`scripts/game_state.gd`、`scripts/game_main.gd`、`scripts/player.gd`、`scripts/toxic_cloud.gd`、`scripts/bullet.gd`、`scripts/pickup.gd`、`scripts/hud.gd`、`scripts/menu.gd`、`scripts/validate.gd`、`resources/texture/generated/icon_suffix.png`（新）、`_tools/gen_assets.py`

## 一、C 地窖印记——种子契约（首批前置，已闭环）

1. **`data.gd`**：`SIGILS` 表 3 条（vigor +1 生命上限 / arsenal 副手预装霰弹枪 / purse 开局 15 源石）
2. **`game_state.gd`** 印记持久层：
   - 独立存档 `user://sigils.cfg`（**与 rng 流隔离**；SMOKE 走 `_smoke_sigils.cfg` 隔离档，同 meta 模式）
   - `shards` 货币 + `settle_shards(cleared) = floor(cleared × META_RATE=2.0)`——**纯确定性、无 rng**（§四.2 契约）
   - `unlock_sigil`（扣 shards 永久解锁）/ `equip_sigil`（每局 1 枚）/ `load_sigils`（负 shards 钳制、未知 id 忽略）
   - 结算钩：`_settle_meta` 内 `settle_shards(Game.max_floor)`（与结晶同 SMOKE 门控）
   - **`SMOKE_META_PERSIST=1` 自测探针**：写→读→越界钳制→未知 id 忽略 四断言全过
3. **`game_main.gd`**：`_apply_sigil_contract()` 在 `start_run` **任何 Game.rng 绘制之前**调用（注释明示契约）；三种印记绝对置位注入（幂等，重复 start_run 不叠加）；实测 vigor：`player.max_hp=4` ✓
4. **`menu.gd`**：主菜单新增「印记」页——shards 余额 / 3 印记解锁（扣碎片）/ 携带·卸下（每局 1 枚）

**契约声明**：印记注入只改起始状态、不改 rng 消耗顺序 → 同 seed + 同印记 = 整局可复现，E1 零漂移（§四.4 达成）。

## 二、A 反应式遗物词缀（本批主菜）

1. **`data.gd`**：`RELIC_SUFFIXES` 8 条（每触发点 2 条）：
   - ON_SHIELD_BREAK：霜爆（主题危害云）/ 回响（+1hp）
   - ON_DASH_START：踏影（主题危害云）/ 小壁垒（+1 护盾层，复用既有 shield_charges）
   - ON_VOLLEY_FIRE：燃帷（主题危害云）/ 凝滞矢（全场减速 50% 2s）
   - ON_POISON_TICK：瘴波（主题危害云）/ 蚀养（+1hp）
   - 危害云 = **复用 F4 主题机制**：friendly toxic_cloud（70px/2s/减速0.6+DoT0.5），色调取当前楼层主题 tint（数据驱动，禁硬编码色值——art 纪律 ✓）
2. **`player.gd`**：
   - `relic_suffixes`（relic→suffix，每遗物 1 条）+ `_suffix_cds`（**E6 固定步递减**）
   - 统一触发入口 `_fire_relic_suffixes(relic_id, trigger, pos)`：trigger 匹配 → 冷却检查 → effect 分派（theme_hazard/heal/slow_all/brief_shield）
   - **4 触发钩落位**：环盾摧毁敌弹（ON_SHIELD_BREAK，pos=弹丸位置）/ 冲刺开始（ON_DASH_START）/ 齐射后（ON_VOLLEY_FIRE）/ 毒云每跳（ON_POISON_TICK，经 toxic_cloud 回调）
3. **`toxic_cloud.gd`**：`triggerless` 标志——**词缀生成的危害云不再触发 ON_POISON_TICK（防瘴波无限连锁）**；puff 色可按主题改写
4. **掉落**：精英/Boss 必掉、普通怪 6%（抽取走 Game.rng 掉落循环——**绘制顺序变化为规划 §3.4 明示的预期代价，E1 基线随本批重定**）；pickup `kind="suffix"`（不磁吸不过期）
5. **HUD**：武器槽下词缀行「词缀·霜爆(环绕护盾) · …」附着后显示
6. **`SMOKE_SUFFIX=1` 探针**：附着 → 触发生效 → 冷却拦截 → trigger 不匹配空效果 → 小壁垒护盾，5 断言全过

## 三、验证（全部实跑）

| 项 | 结果 |
|-|-|
| C 存档往返自测（SMOKE_META_PERSIST） | 4 断言过；**探针自己抓出 1 个真 bug 并修复**（非法 equipped 回退不生效——读档先归零再校验回填） |
| C 注入实测（cfg 预置 vigor → 窗口/无头运行） | `vigor injected: player.max_hp=4` + `applied contract (before any rng draw)` ✓ |
| A 链路自测（SMOKE_SUFFIX） | 触发生效 / 冷却拦截 / trigger 不匹配 / 护盾授予，全过 |
| A 实战掉落（floor-3 长跑 4500 帧） | 2 次掉落→附着实证（s_frostburst→orb_shield、s_bulwark→dash_dodge） |
| 组合回归（SMOKE+V8+REBIND+RELIC+SUFFIX+PERSIST，3000 帧） | **0 报错**，六探针全过 |
| 冻结清单 | 重定 29/29 OK |

## 四、踩坑记录（如实）

1. **Dev.check 断言式**：通过时静默——曾把「无输出」当全过，后补 `[ERR]` grep 才发现 friendly 云回退真失败；教训：断言探针必须配负向用例（本批已内置越界/未知 id 负向断言）
2. **GDScript 解析歧义**：`x == ["a"] as Array` 把整个表达式推断为 Array → `check()` 报类型错并级联编译失败（1200 条 Nil 报错）——比较一律先显式标类型
3. **SMOKE 隔离档双路径**：sigils 走 `_smoke_sigils.cfg`——测试 patch 正式档 `sigils.cfg` 对 SMOKE 运行无效（同 meta 模式）；测试必须 patch 隔离档
4. **读档回退要先归零**：`load_sigils` 原实现对非法 equipped「跳过赋值」→ 内存旧值穿透；先归零再校验回填

## 五、还剩什么

- Sprint 11 剩余：**B 主题相位 Boss**（L 级，规划 §五已就位，等规划侧排期）
- 非阻塞：地窖背景板 1 张（art 预留，未做）；印记结算进死亡结算面板（当前静默入账+日志）；B 伴生小怪「回响」待定
- E1：词缀掉落引入的 rng 绘制已按 §3.4 记录为预期代价，E1 基线随本批重定（坑 45 口径）
