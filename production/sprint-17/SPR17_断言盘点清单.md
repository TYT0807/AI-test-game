# Sprint 17 阶段一 · B 断言盘点清单

> 基线：功能码 `2a04d4e` / 文档批 `9b6568b`；冻结 34/34；34 个 `.gd`。
> 口径来源：`SPR17_规划草案.md` §3.5。本文**只做分类标注与清单**，不改任何断言逻辑、不新增恒过断言冒充验效果型。
> 落点一律用「文件名 + 函数名 / 断言标签」索引，**不写死行号**，复核时以实读为准。
> 本批在 `validate.gd`、`player.gd`、`game_main.gd` 的相关断言旁补了 `【Sprint 17 B ...】` 分类注释，与下表一一对应。

---

## 一、四类口径

| 类别 | 性质 | 判定方式 | 处理 |
|---|---|---|---|
| 验效果型 | 有真实差值 / 验数值或验渲染，能抓回归 | 故意改坏实现应转红 | 保持 |
| 前提守卫型恒过 | 当前数据下必然成立，价值在「前提被破坏时报错」 | 当前恒绿，非每日回归信号 | **标注性质 + 意图**，不算假断言，不冒充验效果型 |
| 常量自比较 | 自己定义自己读（表值 == 字面量 / 纯派生连读两次） | 只能防错字与表被改，不验行为 | **标注**；能补渲染/数值断言则下批补 |
| 只验标志不验数值 | 只查 `has(...)` / bool，实现坏了也绿 | 属易漏缺陷 | **必须补强**；本批只登记，不越权改逻辑 |

---

## 二、盘点明细（分类 / 落点 / 是否需补强 / 理由）

| # | 分类 | 落点 | 需补强 | 理由 |
|---|---|---|---|---|
| 1 | 验效果型 | `validate.gd` `_check_scripts_compile()` 全脚本编译扫描 | 否 | `load()` 真编译，解析错当场点名文件；本批实跑 34/34 |
| 2 | 验效果型 | `validate.gd` `_check_codex()` 的 `Assets.g("icon_codex") == null` 门、`_codex_id_valid` 双向校验 | 否 | 真实 null 检查 / 白名单校验，漏登记会红 |
| 3 | 验效果型 | `validate.gd` `_v8_probe()` 空池负向注入 | 否 | 构造坏数据验 `_check_pool_dict` 拦截，并能恢复无误报 |
| 4 | 验效果型 | `validate.gd` `_check_registration` / `_check_apply_ids` / `_check_contracts`（`SMOKE_REG` / `SMOKE_APPLY` / `SMOKE_CONTRACT` 门控） | 否 | 源码回读 + 契约键交叉校验，能抓「加了却没生效」 |
| 5 | 验效果型 | `validate.gd` `_check_meta` / `_check_shrine` 圣所分配抽查 / `_check_suffixes` / `_check_active_relics` 等 `_check_*` | 否 | 表自洽与引用存在性，真约束 |
| 6 | 验效果型 | `player.gd` `_shrine_probe` 两条限时 buff | 否（已补强） | Sprint 15 收口批已由「只验标志」升级为 `mult=1.25/1.3` + `t>0` + 分数数值验证 |
| 7 | 验效果型 | `player.gd` `_shrine_probe` 其余（三卡确定性 / 代价数值 / 置灰 / 面板可见 / cleared 回写 / 暂停态） | 否 | 逐条数值与可见状态 |
| 8 | 验效果型 | `player.gd` `_suffix_probe` 触发返回字典 / 冷却拦截 / trigger 不匹配空返回 / 护盾层数 | 否 | 真效果与数值，无标志位绿灯 |
| 9 | 验效果型 | `player.gd` `_sigil_coverage_probe` 9 枚印记（max_hp / diamond_mult / mag_cap_mult / frail 削减还原） | 否 | 每枚验可观察数值差值，结束恢复存档现场 |
| 10 | 验效果型 | `player.gd` `_codex_probe` 未知 id 忽略 / 记录→存盘→读回 / 负数钳制 0 / B3 越界键 / B5 同层幂等 / B6 空 clear / P0-3.2 现场恢复 | 否 | 构造 + 读回真差值 |
| 11 | 验效果型 | `player.gd` `_codex_boon_probe` 阈值 4/5→5/5、起始四项落地（shield/diamonds/max_hp/suffix）、§5.4 倍率零命中 | 否 | 数值断言 |
| 12 | 验效果型 | `player.gd` `_third_boss_probe` 层判定 / 分母 / `codex_id` / `on_slug_killed` 登记 / 无 `"boss"` 假阳性 | 否 | 真路径单元证据 |
| 13 | 验效果型 | `player.gd` `_oath_probe` 计数器增量 / 阈值 2→3 / 多条件取最小 / 落盘读回逐字段 / 复盘页渲染扫描 | 否 | 真差值 + 渲染扫描 |
| 14 | 验效果型（负向构造） | `player.gd` `_oath_probe` **A2 空 watched**（本批新增） | 否 | 直接构造 `watched=[]` 的 def 验早退返回 `{}`；**删除守卫即转红**（见 §三负向对照） |
| 15 | 验效果型 | `player.gd` `_floor_sign_probe` 层签文本包含 / `rng.state`、`fx_rng.state` 前后相等 / toast 文本 / 重复登记不变 / 分母 / 图鉴渲染 | 否 | 文本 + 状态 + 渲染 |
| 16 | 验效果型 | `game_main.gd` `start_run` 跳层块 **A1 层签断言**（本批新增，`SMOKE_FLOOR_SIGN` 门控） | 否 | 验渲染文本含跳层主题名 + `rng.state`/`fx_rng.state` 前后相等；**删除 `update_floor_sign()` 即转红** |
| 17 | 验效果型 | `game_state.gd` 各 `SMOKE_META_*` 存读往返 / 坏档降级探针 | 否 | 真往返与降级 |
| 18 | 前提守卫型恒过 | `validate.gd` `_check_shrine()` **B4**「shrine 恒非起点房」 | 否（已标注，本批复核） | 锁 `_enter_room` 早于 `_roll_calamity` 的时序前提；生成规则不变则恒过，价值在未来放宽时当场报错 |
| 19 | 前提守卫型恒过 | `validate.gd` `_check_codex()` **P0** `CODEX_BOONS.kind` 遍历门（本批补标注） | 否 | 当前四档 kind 均非 `suffixes` → 恒过；真防线是本门（判据端切链），拦未来扩表自激 |
| 20 | 前提守卫型恒过 | `player.gd` `_codex_boon_probe` **P0「送词缀后派生不变」**（本批订正标注） | 否 | `codex_boons()` 不读 suffixes → 前后必然相等；**订正 Sprint 15 交付文档「真差值断言」措辞**，真防线是 #19 启动期门 |
| 21 | 常量自比较 | `player.gd` `_codex_probe` `CODEX_BOSS_NAMES[...] == "棱镜守望者"/"熔潮主宰"`（本批补标注） | **是（下批）** | 表值自我读取，防错字/表被改但非行为断言；建议补「菜单图鉴页显示名渲染扫描」 |
| 22 | 常量自比较 | `player.gd` `_third_boss_probe` `CODEX_BOSS_NAMES["third_boss"] == "玄渊之主"`（Sprint 15 已标注，本批复核） | **是（下批）** | 同上；后半 `_codex_id_valid` 是真校验门，前半建议补渲染断言 |
| 23 | 常量自比较 | `player.gd` `_codex_boon_probe` `codex_boons() == codex_boons()`（本批补标注） | **是（下批）** | 同档连读两次纯派生必然相等；建议改为「改档前后差值」或删除 |
| 24 | 表一致性门（常量比对但有效） | `player.gd` `_codex_probe` / `_third_boss_probe` / `_floor_sign_probe` `Data.codex_bosses_total() == 7` | 否 | 虽与字面量比，但 `ENEMIES` / `CODEX_BOSS_NAMES` 扩表漂移会转红，属有效守门，不归入需补强 |
| 25 | 只验标志不验数值 | 全量扫描 `player.gd` / `validate.gd` 各 `Dev.check` | 否（现存 0 条） | 历史两条 buff 断言已在 Sprint 15 收口批升级；本批未发现仅验 flag 的生效断言 |

---

## 三、本批新增断言的定性（附负向对照证据）

两条新增断言都按「必须验数值或验渲染」设计，并做了**删除实现即转红**的负向对照，证明不是恒过假断言：

| 断言 | 正向证据 | 负向对照（临时移除实现后实跑） |
|---|---|---|
| A1 跳层层签 | `[SMOKE-FLOOR-SIGN] A1: floor=11 sign=层签 · 藤蔓阻挡■ ｜ 灾祸：无 theme=藤蔓阻挡 rng_same=true fx_same=true` | 移除跳层块的 `update_floor_sign()` → `[ERR] floor_sign: A1: 跳层后层签含第 11 层主题名（层签 · 无主题 ｜ 灾祸：无）` |
| A2 空 watched | `[SMOKE-OATH] A2: empty_watched result_empty=true` | 移除空 watched 早退守卫 → `[ERR] oath: A2: 空 watched 返回空字典` |

负向对照只临时替换 `game_main.gd` 一份副本（A1 调用 + A2 守卫各删一处），跑完立即从 `_backup/spr17_p1/gm_positive.gd` 还原，`md5sum` 前后一致；**负向变体未入库、未提交**。

A1 另设防假绿灯：主题为空的层（`<4`，`Data.theme_for_floor()` 返回 `{}`）跳过文本比对，避免 `contains("")` 恒成立；`rng.state` / `fx_rng.state` 只对 `.state` 做**读取**（不调用 `randf` / `randi_range`），属零消费，由前后相等自证。

---

## 四、边界声明

- 本批**未改任何既有断言逻辑**：所有改动为注释、A1 一处 `update_floor_sign()` 调用、A2 一处早退守卫与一个默认参数测试缝、两条新增断言。
- `oath_fulfillment(def_override := {})` 的默认参数仅为 A2 负向断言提供可测入口：`Data.OATH_CONDITIONS` 是 `const`，Godot 4.7.2 实测其**内嵌 Array 亦为运行时只读**，探针无法靠改表注入空 `watched`；既有全部调用（`_write_codex_replay` / `_oath_probe`）零参数调用，行为不变。
- A3「FLAVOR 播报走 `hud.flash_toast()` 单例 2.2s，同帧多首发现互相覆盖」**本批不改代码**，登记为产品裁定项：改队列/去重会引入表现层计时（E6 风险），最小方案是「同帧只播最后一条 + 交付文档注明」，留待单列小批。
- 标「是（下批）」的 #21–#23 只登记不实施，避免在本批越权改断言逻辑；由 `quality-lead` 复核后另派窗口。
