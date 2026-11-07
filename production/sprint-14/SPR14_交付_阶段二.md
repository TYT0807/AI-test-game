# Sprint 14 阶段二交付：C 图鉴发现度被动 / Codex Boon

> 日期：2026-11-08｜依据 `SPR14_规划草案.md` §五（锁定 A+B+C；本批 = 阶段二 C）｜分工：编程侧
> 改动文件：`data.gd` / `game_state.gd` / `game_main.gd` / `player.gd`（探针）

## 数据与派生（§5.2）

- `data.gd` 新增 `CODEX_BOONS` 4 档（data 驱动，调优只改表）：
  | id | 分类 | 阈值 | 效果 |
  |---|---|---|---|
  | `enemies_5` | enemies | 5 | 开局护盾 +1 |
  | `relics_4` | relics | 4 | 开局源石 +3 |
  | `themes_3` | themes | 3 | 生命上限 +1 |
  | `bosses_2` | bosses | 2 | 附 1 条词缀（`attach_suffix` 复用） |
- `game_state.codex_boons()`：纯只读派生（遍历表按 `codex[kind].size() >= need` 判定），**零写入、零 rng**
- 词缀选取 `_codex_boon_suffix()`：由图鉴五类发现集拼 key 走 `stable_hash`——**同档同词缀**，零 rng

## 注入点与 E1（§5.3）

- 挂 `start_run` 的 `_apply_sigil_contract()` **同段之后**、`Game.run_seed`/rng 首抽之前——与 Sprint 11 C 同口径：只改起始状态、不改 rng 消耗顺序 → **E1 零漂移**
- **实跑指纹证据**：`SMOKE_SEED=12345` 双跑 fingerprint md5 逐字一致（`3125e2b2…`，与 Sprint 13 收官指纹同值——注入零影响）
- **登记口径**：图鉴档是局外输入——档不同 → 起始状态不同；同档 + 同 seed 双跑仍逐字一致。回归基线跨档不可比（局外变量），同档可比

## 载体硬约束落实（§5.4）

- 四类效果只走一次性起始状态：`shield_charges +=` / `Game.add_diamonds(+)` / `max_hp +=`（hp 同步 +1，镜像 vigor 契约的 emit 口径）/ `attach_suffix`
- **禁用** `diamond_mult` / `mag_cap_mult` / `calamity_speed_mult`——探针断言 apply 前后三倍率逐字不变（防 §5.4 回归）
- 未碰 `meta.gd UNLOCKS` / `STATS_KEYS`（冻结规格 v2.10，平行只读派生）

## 验证（全部实跑）

| 项 | 结果 |
|-|-|
| SMOKE_CODEX_BOON 定向 1500 帧 | 阈值边界（4/5 不生效、5/5 生效）+ 全四档生效 + 派生确定性 + **起始状态四项数值落地**（shield/diamonds/max_hp/suffix 各自断言实值，不只验返回字典）+ §5.4 载体零命中——全过、0 [ERR] |
| 指纹双跑 | `SMOKE_SEED=12345` ×2 fingerprint md5 逐字一致 |
| 全量回归（17 钩子含 CODEX_BOON，6000 帧） | **0 报错**；6 done 标记；**真实开局注入证据** `[SMOKE-CODEX-BOON] applied: [enemies_5, relics_4, themes_3, bosses_2]`（smoke 档发现度累积 → 四档全触发）；BOSS2 floor=11 / first_shrine 证据齐 |
| E1 / E6 / 坑 5 | 零 rng / 零计时 / `ACTION_DEFS` 与 `GEN_NAMES` 零新增 |
| 冻结重定 | `md5sum -c` **33/33 OK**（无新脚本） |

## 过程如实记录

1. **SUFFIX 探针基线过期（全量回归抓出）**：smoke 档发现度累积后 enemies_5 boon 开局给盾 → s_bulwark 断言 `==1` 实得 2。根因是探针基线假设过期、非代码缺陷——探针改 `shield_charges = 0` 自控基线（断言只验词缀自身效果）。这条同时是 boon 真实生效的旁证
2. 阶段一首跑抓出的两处解析/运行时错（探针未定义 `gm`、`String(null)` 构造）已记录于阶段一交付文档

## 还剩什么

- Sprint 14 锁定范围 **A+B+C 全部交付完毕**；D/E 备选未接、F 永不接（草案 §六口径）
- 旧档残留 `"boss"` 记录如实披露（阶段一 §3.4），不隐式迁移；显式重置入口需单独授权，未做
- `玩法说明.md`（主理人校准）与 `SPR14_规划草案.md` 待授权随文档整理批入库
