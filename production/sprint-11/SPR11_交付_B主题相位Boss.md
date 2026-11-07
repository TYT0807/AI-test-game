# Sprint 11 交付（收官批）：B 主题相位 Boss「棱镜守望者」

> 日期：2026-11-07｜依据 `SPR11_B主题相位Boss_细化规格.md`（design-strategist 状态机规格）｜分工：编程侧
> 改动文件：`scripts/boss.gd`（新，PrismWarden 状态机）、`scripts/game_main.gd`（首领层接入/编队门/探针增强）、`scripts/player.gd`（apply_slow/relic_suppress_t）、`scripts/assets.gd`（3 贴图 + 3 SFX 别名）、`resources/texture/generated/boss_prism_*.png`（3 新）、`_tools/gen_assets.py`

## 一、改了什么

1. **`scripts/boss.gd`（新）**：`PrismWarden` 状态机（规格 §四 逐条落地）
   - 状态枚举 INTRO→ACTIVE→PHASE_2→PHASE_3→DYING；HP 阈值 66%/33% **只下不回退**，每固定步在 `_tick(Game.FIXED_DT)` 检测
   - **三阶段主题纯函数**（规格 §三）：`static phase_theme_index(floor_num, k) = 4 + ((floor_num-4)+k) % 8`——零 rng；实测 floor-11 = vines→vein→toxic 与公式一致
   - **签名脉冲复用 F4 机制**（规格 §五 铁律：Boss 只作触发源，不重写）：
     - magma → 8 个敌方毒雾云围成 DoT 环（复用 ToxicCloud enemy 模式）
     - ice → 玩家 apply_slow(0.55, 3s) + 环上冰花闪点
     - vines → 4× prop_vine 全向阻挡（复用既有 prop 生成路径）
     - toxic/swamp → Boss 脚下+两翼敌方毒雾 ×3
     - vein → 环位散落源石 ×5（既有磁吸/经验路径）
     - pressure → 环内玩家 apply_blast_push 击退 + 震屏
     - silent → 遗物输入压制 2s + 微减速（F4 silent 仅影响生成 → 按规格降级）
   - 阶段增援：切换时既有 Game.rng 流加权选一支 Data.SQUADS，经既有 `spawn_slug` 路径落地（含词缀/拆弹透传）；**不经 _telegraph/_room_spawned**——增援独立于房间刷怪预算（规格 §六）
   - 碎片颜色 = 各阶段主题 tint（数据驱动）；INTRO 登场无敌；DYING 死亡碎裂 VFX（death_shard ×6 + 主题 tint）
   - 血量 320×(1+(floor-4)×0.12)；接触伤害走 take_damage_from（player 侧豁免判定）；血条走既有 boss_hp_changed
2. **`game_main.gd`**
   - `_is_warden_floor(n)`：`n > 4 and (n-4) % 8 == 7`（规格 §二 谓词，可独立修改）
   - Boss 房分支：首领层 → PrismWarden 取代常规 Boss + `_room_budget = 1`（无杂兵 trickle）；常规层不变
   - `_roll_squad()` 门：首领层**暂停常规 SQUADS 抽取**（避免双重召唤，规格 §二）
   - `SMOKE_BOSS` 验证钩：SMOKE 火力 ×5（Headless 预算内走完 Boss 房全链）
3. **`player.gd`**：`apply_slow(mult, dur)`（Boss 冰面/静默脉冲的玩家侧减速，E6 计时）+ `relic_suppress_t`（静默期压制遗物输入）
4. **`assets.gd`**：3 贴图入 GEN_NAMES；SFX 注册表新增 `boss_intro/boss_phase/boss_skill` 别名（复用既有 wav——audio-director 口径）

## 二、验证了什么（全部实跑）

| 项 | 结果 |
|-|-|
| 首领层接入（floor-11 Boss 房） | `warden floor boss replaced` ✓，常规层 Boss 不受影响 ✓ |
| 三阶段切换 | `phase enter k=0/1/2` = **vines→vein→toxic**，与纯函数 `4+((11-4)+k)%8` 推算逐字一致 ✓ |
| Boss 死亡→楼梯→下一周期 | floor-12 主题 = 源石矿脉（新周期起点）✓ |
| 首领层编队门 | 首领层 0 次 SQUADS 抽取（门生效）✓ |
| 全量组合回归（七探针 4000 帧） | **0 报错**，RELIC/SUFFIX/PERSIST/BOSS 探针全过 |
| 冻结清单 | 重定 **30/30 OK**（含 boss.gd 新文件，规格 §七 预告的 +1） |

## 三、踩坑记录（如实）

1. `Game.main.clamp_to_arena` 返回值未标类型 → `var pos :=` 推断失败（Varian 级联）——跨对象调用显式标 `: Vector2`
2. boss.gd 首版 `_hit_cd` 递减写成 `- 0.0`、`_hit_flash` 未声明——新文件写完必须过一遍成员清单
3. **验证节奏教训**：Floor-11 敌人坦度 ×7，默认 SMOKE 火力走不完地图 → `SMOKE_BOSS` 联动火力 ×5（验证钩与被测逻辑分离，不影响正式玩法数值）

## 四、Sprint 11 收官状态

- 三项全交付：**A 反应词缀 ✓ + C 种子契约 ✓ + B 主题相位 Boss ✓**（均过冻结重定）
- E1 基线随本批重定（A 词缀掉落 + B Boss 战 rng 消费，规格 §七 预告）——30/30 新基线
- 非阻塞遗留（下 QA 窗口）：拆弹哑弹落点钳制 ✅（本批已修）、环盾期 HUD 冷却显示 ✅（本批已修）、~~E1 重定基线~~ ✅（随 B 重定）、B 伴生小怪「回响」（art 预留，待定）
- **dash 幅度决策点**：实测 196-210px（120 直驱 + 碰撞挤出）——规划侧若要严格 ~120px 纯传送语义走 option b，当前不阻塞

## 五、主理人核验三项非阻塞遗留 → 已修复（本文件追加）

主理人读码发现三项，均已修并回归：

1. **`_hit_cd` 双重递减**：`_tick`（:115）与 `_tick_combat`（:160）各递减一次 → 接触冷却 0.8s 实际 ~0.4s 节奏。修复：递减统一收敛在 `_tick`（单一真相源），`_tick_combat` 只判定不递减（注释明示）。
2. **magma 脉冲色彩/E6**：Boss 生成的敌方毒雾云改用**阶段主题 tint**（岩浆橙/毒沼绿等，替代默认绿——碎片与危害云色觉统一）+ `fixed_step` 标志（E6 固定步；grandfather 敌云维持 raw delta 不动）。ToxicCloud 相应加 `puff_tint`（敌方默认绿不变）与 `fixed_step` 两字段，均为加法不破坏既有生成方。
3. **`ring_t` 死变量**：删除（成员 + 两处引用）——规格 §六 标注其为可选（扩张环未实现），将来做扩张环时按规格重立。

**回归**：七探针 + 跳层 11（6000 帧）→ 0 报错；冻结重定 30/30 OK。
