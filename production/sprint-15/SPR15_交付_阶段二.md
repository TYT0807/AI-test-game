# Sprint 15 阶段二交付：A F2 第三主题 Boss「玄渊之主」

> 日期：2026-11-08｜依据 `SPR15_规划草案.md` §四（锁定 P0+B+C+D / A；本批 = 阶段二 A）｜分工：编程侧
> 改动文件：`boss3.gd`（新）/ `data.gd` / `game_main.gd` / `boss2.gd`（补强）/ `player.gd`（探针）

## 层判定与优先链（§4.2）

- `_is_third_floor(n) = n > 4 and (n - 4) % 32 == 23`（命中 27/59；验算 `23%8=7` 落首领层、`23%16=7≠15` 避开主权层）——纯函数零 rng
- 生成优先链 **third > sovereign > warden > 常规**（third 分支置于最前，其余不动）；`SMOKE_FORCE_THIRD_BOSS=1` 表外钩子
- 地图由 `_floor_rng(n)` 独立派生不受影响

## 实现骨架（§4.3，复用不复制）

- `boss3.gd extends PrismWarden`，与 boss2 同型：`_theme_offset = 2`（warden=0/boss2=4/本=2）、`skill_interval = 2.6`、`boss_name = "玄渊之主"`、外观数据驱动（阶段 tint）
- **posmod 包正**：offset=2 时低层（SMOKE 强制）`(floor+2-4+k)` 可为负，C-style `%` 取负 → `FLOOR_THEMES` 键越界（首跑实证 `boss3.gd:21` 崩溃）——`4 + posmod(floor-4+offset+k, 8)` 对 27+ 层正算术完全等价，零共享代码改动
- **身份铁律**：`variant = "boss"` 不动（三条掉落契约），`codex_id = "third_boss"` 隔离图鉴登记

## 登记三件套（§4.4，单源红利兑现）

| # | 落点 |
|---|---|
| ① 写入 | `boss3.gd` `codex_id = "third_boss"`——且用 **`_init()` 覆写**而非 setup 赋值（见「过程如实记录」②③） |
| ② 表 | `CODEX_BOSS_NAMES` 加 `"third_boss": "玄渊之主"`——白名单（`_codex_id_valid`）/ 分母（`codex_bosses_total()` 6→**7**）/ 菜单显示名**自动同源派生**，零额外改动 |
| ③ 断言 | `SMOKE_THIRD_BOSS`：层判定（27/59 命中、26/43/11 不命中）+ 优先链前提（27 是首领层且非主权层）+ 分母 7 + 中文名 + **on_slug_killed 单元路径登记 third_boss** + 无 `"boss"` 假阳性 |

## E1 拆开登记（§4.5，如实两条）

1. **地图指纹不变**：`SMOKE_SEED=12345` 双跑 fingerprint md5 `3125e2b2…` 逐字一致——与 Sprint 13/14 基线同值（`_smoke_fingerprint` 只含 rooms+kinds，F2 不改房型）
2. **Boss 战 rng 消耗漂移（预期代价，登记）**：boss3 `skill_interval=2.6` 不同于 warden 3.0 / boss2 2.2 → 同时间窗 `Game.rng` 消耗次数不同 → **后续掉落/编队抽取序列漂移**，基线随批重定。地图不受影响（`_floor_rng` 独立）

## 验证（全部实跑）

| 项 | 结果 |
|-|-|
| SMOKE_THIRD_BOSS 定向 1200 帧 | 9 断言全过、0 [ERR]、done 落地 |
| **真实击杀证据**（全量回归内，FORCE_THIRD_BOSS 生效） | 回归后 `_smoke_codex.cfg` → `bosses=["skeleton_king", "dragon", "third_boss"]`——**third_boss 经 codex_id 路径登记**（真实击杀）、slug Boss 回退正常（skeleton_king/dragon）、**无 "boss" 假阳性** |
| 全量回归（18 钩子含 THIRD_BOSS，6000 帧） | **0 报错**、7 done 标记 |
| E6 / 坑 5 / 冻结规格 | 全计时走基类 FIXED_DT / `ACTION_DEFS` `GEN_NAMES` 零新增 / `UNLOCKS` 不碰 |
| 冻结重定 | `md5sum -c` **34/34 OK**（+boss3.gd，33→34） |

## 过程如实记录（探针门控四连拦）

1. **P0-3.2 现场恢复断言红**：探针「登记后撤销」误删 smoke 档跨 run 累积的既有发现 → 改「只撤销本次新增」（阶段一已记）
2. **低层主题键越界**：offset=2 在 1 层 `(3-4+k)%8` 负模 → `FLOOR_THEMES[3]` 崩溃（kill2 首跑抓出）→ posmod 包正
3. **裸实例默认 id 错误**：探针直调 `on_slug_killed` 抓出 `boss3.new().codex_id == "prism_warden"`（codex_id 只在 setup 赋值）——若 setup 中途异常（kill2 实证会发生），死亡登记会落回基类默认造成跨 Boss 误登记 → 改 `_init()` 覆写（**不能重声明成员**——子类 `var codex_id` 触发 parse error，第二次门控拦截），boss2 同步补强
4. **自动驾驶导航运气**：小图布局下 autopilot 进 boss 房不稳定（kill3/4 未进入、kill2 进入但 45s 未击杀）——真实击杀证据最终由全量回归（更大地图 + 火力钩）取得，定向侧以 on_slug_killed 单元路径补位；两条证据口径都在交付文档如实分开

## 还剩什么

- Sprint 15 锁定范围 **P0+B+C+D+A 全部交付完毕**；E 断言盘点与文档整理批主理人并行（三份待授权文档）
- 玩法说明补行（C 被动 / 玄渊之主 / 分母 7）随文档整理批
- D/E/G 备选未接；F1 主题扩容永不接（§六四处周期来源口径已实读归档）
