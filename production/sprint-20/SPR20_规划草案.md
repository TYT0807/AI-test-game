# Sprint 20 规划草案 · A 手记扩容到全六类

> 状态：**方向已由用户裁定**（走编程侧建议：S 级「加关系不加实体」轴收尾，单批）。
> 基线实测：HEAD `ed4bf06`（S19 文档批），冻结 34/34 OK，工作树干净。
> 本文为自包含规格；实施 → 子代理交叉审查 → 四门控 → 冻结重定（34/34，无新脚本）→ 单独提交。

## 一、范围

`Data.FLAVOR` 从 20 条（themes 8 / bosses 3 / shrine 9——S18 D 实际漏写 shard_pact 一条，覆盖门首跑抓出）扩到 **74 条**，覆盖全部六个发现集：

| 分类 | 新增 | 现有 | 合计 | 池大小 |
|---|---|---|---|---|
| enemies | 29 | 0 | 29 | ENEMIES.size() = 29 |
| relics | 12 | 0 | 12 | RelicsRef.POOL.size() = **12**（含 2 件解锁遗物） |
| suffixes | 8 | 0 | 8 | RELIC_SUFFIXES.size() = 8 |
| bosses | 4（常规层主击败） | 3（主题 Boss） | 7 | codex_bosses_total() = 7 |
| themes / shrine | 0 | 8 / 10 | 8 / 10 | 8 / 10 |

文案口径沿用既定基调：**废弃矿窟的实用主义**——每条写该实体**实际机制**的应对（ai 行为 / 词缀效果 / 遗物 desc），不臆造设定；每条自带句号。10 条 shrine 与 3 条主题 Boss 文案一字不改。

## 二、播报白名单（关键裁定）

新增 `data.gd FLAVOR_BROADCAST_KINDS := ["themes", "bosses", "shrine"]`：

- 这三类首发现**维持 toast 播报**（现状不变）
- **enemies / relics / suffixes 首发现只入图鉴、不播 toast**——floor 1 就可能连遇 3-5 种敌人，全播会刷屏淹没玩家；图鉴「手记」行是它们的呈现通道。这与 Sprint 16 D 原设计一致（原播报清单本就只有主题 / Boss / 圣所）
- `mark_codex` 播报前查白名单；**负向断言**：新增敌人首发现 toast 文本不变

## 三、validate 覆盖门（防「表写了没接上」）

`_check_codex` 新增：按 `/` 前缀统计 `FLAVOR` 每类条数，与各类池大小逐一比对（enemies=29 / relics=10 / suffixes=8 / themes=8 / bosses=codex_bosses_total()=7 / shrine=10）——缺一条即报错。手记**不入任何分母 / 白名单**（不变）。

## 四、探针（SMOKE_FLAVOR 扩）

1. **播报白名单负向**：撤销一个敌人发现 → `mark_codex` → `_toast.text` 不变（enemies 静默）；themes 正向已在 S16 探针覆盖
2. **覆盖计数**：`Data.FLAVOR.size() == 72`
3. **图鉴渲染**：enemies 分区手记行含敌人手记特征句（如「成群来」）
4. 沿用 S19 断言（shrine 负向 ①-⑤、boon 派生三态）不回退

## 五、零动与红线

零 rng / 零 fx_rng / 零计时 / 零新 action / 零新资源 / 零新 kinds（第六类 shrine 已在）；`UNLOCKS` / `STATS_KEYS` / `CODEX_BOONS` / `SHRINE_OFFERS` 不碰；`mark_codex` 通用函数体只加白名单判断；指纹不变、冻结 34/34。

## 六、验收

headless 6000 帧 0 报错；`md5sum -c` 34/34（data.gd / game_state.gd / validate.gd / player.gd 重算）；子代理交叉审查对照本草案逐项核验；单独提交。
