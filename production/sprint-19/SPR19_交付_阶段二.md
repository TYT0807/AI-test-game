# Sprint 19 阶段二交付：断言与收口 + 范围外缺陷修复

> 日期：2026-11-10｜依据 `SPR19_规划草案.md` 汇编定稿 §三(5-7)/§四/§九（本批 = 阶段二；阶段一 `7e002a4` 已入库）｜分工：编程侧（接替 502 掉线的 eng-handoff）
> 改动文件：`validate.gd` / `player.gd` / `boss.gd`（范围外缺陷修复）+ 文档批（README / 玩法说明 / S18 增补注记 ×4，各一个 commit）

## 必改 5：validate P0 防线（§九-2）

- `CODEX_BOONS.kind == "shrine"` 启动期断言，与 suffixes 禁令同型——防「交换 → 加 boon → 更易交换」正反馈
- 【断言性质：前提守卫型恒过】已标注（沿用 S17 盘点口径）
- 白名单正反两向：`_codex_id_valid("shrine", "blood_relic")` 通过 / `"no_such_offer"` 被拒

## 必改 6：player 探针断言与措辞

- **负向对照 ①-⑤**（`_codex_probe` 内，全部有可观察差值）：①未知圣所 id 拒绝（白名单=SHRINE_OFFERS 键集）②重复登记幂等且 toast 不重复播报 ③FLAVOR 键为单数 `shrine`（复数键必查不到——icon_codex 同型静默坑的负向对照）④旧 cfg 无 shrine 键 → `load_codex` 空数组且不报错（快照全部分类，测后恢复）⑤渲染「已行抉择 n / 10」+ 中文名不直出英文 id
- **正向**：toast 文本含手记句（`FLAVOR shrine/blood_relic`「血祭。…」直读 `_toast.text` 验证）
- **「五类」→「六类」**：player.gd 5 处措辞订正（1084/1090/1095/1243/1263，纯字符串）
- §九-1 配套已在阶段一落位：`_codex_boon_suffix()` shrine 三态（0/1/10 条）派生逐字相等的验效果型断言（player.gd:1201-1217，含非恒定输入守卫）

## 范围外缺陷修复（全量回归发现，如实登记）

- **缺陷**：PrismWarden 基类从未定义 `apply_slow`——慢速弹（`bullet.gd:124`）与友方云（`toxic_cloud.gd:80`）命中 Boss 时每 tick 报错且减速静默失效。**既有缺陷**：boss.gd 从未定义该方法（grep 实证），触发与本批 diff 无关——本轮全量回归因 smoke 档 boon 派生词缀恰好落在减速类而显形（cfg 状态依赖）
- **修复**：`boss.gd` 镜像 `Slug.apply_slow` 语义（`_slow_mult`/`_slow_t`，计时走 `_tick` 的 FIXED_DT——E6），战斗移动速度乘 `_slow_mult`；三个主题 Boss（继承）全覆盖
- **性质**：零 rng；Boss 可被减速属行为变化（修复前是「报错+减速无效」的坏行为），交付文档如实登记为范围外缺陷修复，非本批设计意图

## 独立审查（子代理，只读）

按主理人要求派独立只读审查员对照草案全量核验：**§三必改 1-7 / §三零动清单（硬证：冻结 32 OK / 2 FAILED 恰为阶段二在飞两文件）/ §九-1 三态断言 / §九-2 P0 门 / §四①-⑤+正向 / bug 排查（状态恢复完整性、GDScript 赋值合法性、erase→mark 两态、rng/delta 零新增、断言可达性）/ 措辞清零——7 项全 PASS，未发现新问题**。三条低危观察（④ 不恢复 last_run——与 B2 既有契约一致；`_build_codex` `_rows` 累积——既有形态；blood_relic 持久写入 smoke 档——erase-first 设计下无断言风险）登记在册。

## 验证（全部实跑）

| 项 | 结果 |
|-|-|
| SMOKE_CODEX + SMOKE_CODEX_BOON 定向 2000 帧 | S19①-⑤ + 正向断言 + 三态断言全过、0 [ERR] |
| 全量回归（20 钩子，6000 帧） | 修复前 20 条 `apply_slow` 报错 → **修复后 0 报错**、9 done 标记 |
| E1 | `SMOKE_SEED=12345` fingerprint md5 = `3125e2b2…`（与 Sprint 13 起基线同值，零重定）；mark_codex 纯局外登记不进指纹 |
| E6 / 坑 5 | 零 raw delta（boss 慢速计时走 _tick FIXED_DT）/ `ACTION_DEFS` `GEN_NAMES` 零新增 |
| 冻结重定 | `md5sum -c` **34/34 OK**（boss.gd/player.gd/validate.gd 三条目重算，无新脚本） |

## 还剩什么

- 文档批（随本批单独 commit）：README S19 行 / 玩法说明「已行抉择」句 / S18 四份 B 类增补注记
- 在册观察（不返工）：图鉴手记无分隔符（S19 §九-3 裁定独立批次）；`_build_codex` `_rows` 多探针累积（既有形态）；④ 不恢复 last_run（与 B2 契约一致，未来加消费方时注意）
- 待主理人读码核验 → Sprint 19 final PASS
