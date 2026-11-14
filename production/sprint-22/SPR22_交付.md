# Sprint 22 交付：D flash_toast 同帧覆盖（合并语义）

> 日期：2026-11-11｜依据 `SPR22_规划草案.md`（用户裁定 D 采纳、合并语义、上游聚合）｜分工：编程侧
> 改动文件：`game_state.gd`（缓冲 + 冲洗）/ `player.gd`（探针适配 + S22 验渲染节）+ `SPR21_交付_阶段二.md`（日志注记，§四 顺手项）+ `SPR22_规划草案.md`（措辞与实现对齐）

## 缺陷与修复（§一/§二）

- **缺陷**（在册观察②）：同帧多条首发现各调一次 `hud.flash_toast` → 单例 2.2s tween 互相覆盖，玩家只见最后一条
- **修法（上游聚合）**：`mark_codex` 白名单分支改为 `_flavor_pending.append(fv)` + `call_deferred("_flush_flavor_toast")`——同帧 N 条首发现帧末合并为一条 `flash_toast("图鉴新发现 ×N")`；单条（N=1）维持「矿工手记 ·」原格式（既有探针与玩家认知兼容）
- **`hud.flash_toast` 函数体零改动**（git diff 硬证：hud.gd 无任何 +/- 行，SPR21-FROZEN 哈希未变）——护盾抵挡、博学印记、挑战保底、灾祸横幅等十余个直发调用方路径不受影响
- **非白名单类**（enemies/relics/suffixes）不进缓冲——行为与 S20 完全一致（S20 负向探针原样通过）
- 帧聚合走 `call_deferred`（**零 delta 计时**，红线遵守）；单例 2.2s tween 复用，不加队列状态、不加逐条计时

## 登记三件套（③验渲染——S21 教训对齐）

- ① 写入：缓冲 + 白名单门（game_state.gd:337-341）
- ② 渲染文案：单条原格式 / 多条「图鉴新发现 ×N」
- ③ **验渲染断言**（player.gd S22 节）：同帧 3 条白名单首发现 + 1 条非白名单对照 → `_toast.text` **逐字等于**「图鉴新发现 ×3」（非白名单不计入）+ `_toast.modulate.a == 1.0`（可见）；单条回归「矿工手记 · 岩浆层」原格式——**验实际渲染文本，非验标志或计数**

## 验证（全部实跑）

| 项 | 结果 |
|-|-|
| SMOKE_FLAVOR / FLOOR_SIGN / CODEX / CODEX_BOON 定向 2500 帧 | S22 验渲染 4 断言 + 全部既有断言（S19①-⑤ / S20 白名单负向 / S16 播报）全过、0 [ERR] |
| 全量回归（22 钩子，6000 帧） | **0 报错**、10 done 标记 |
| E1 / E6 / 坑 5 | 新增代码零 rng / 零 delta（冲洗走 call_deferred，flash_toast 复用既有 tween）/ `ACTION_DEFS` `GEN_NAMES` 零新增 |
| 冻结双清单 | 本批快照 `SPR21-FROZEN.md5` 重算 **34 OK / 0 FAILED**；历史归档 `SPR7-FROZEN-4.md5` 勿覆盖（对当前树 11 FAILED = 11 项内容差异，预期值） |

## 独立审查（子代理，只读）

7 项全 PASS、未发现新问题：同帧幂等性（N 次 call_deferred 排队 → 函数级 N 次调用、效果级一次冲洗）、flash_toast 全部直发调用方核对（12+ 处均不经缓冲）、探针时序陷阱（无遗漏依赖、无中途 await 窗口）、零动清单全量 diff 核对。三条信息级登记：聚合 toast 帧末优先级（last-wins 既有行为，deferred 改变谁 last——已裁定可接受）；smoke 档测试 id 留档（幂等不累积）；fresh 档首跑两条首发现 toast 被探针 clear 静默吞掉（smoke-only）。

## 过程如实记录

1. **×9 诊断**：首跑探针报「图鉴新发现 ×9」——加缓冲/冲洗双侧时间线打印实测：call_deferred 冲洗在**探针恢复帧**成批执行（n=9/3/1 @frames 21/22/23），多探针同帧 mark 互相聚合。修法 = 探针改「清 pending → mark → 直调冲洗」确定性模式（诊断打印已移除）
2. **sed 误删**：清理诊断打印时 `sed /flush n=/d` 误删函数体内两行 → 解析错 35 条（`--check-only` 对 menu.gd 的报错为脱离 autoload 的假阳性——validate.gd 有 documented 注记）→ 逐处还原，真伤仅 game_state.gd 两行
3. 草案措辞与实现不一致一处（子代理发现）——已按「直调冲洗」订正

## 还剩什么

- Sprint 22 锁定范围 **D 全部交付完毕**（B 否决 / E 挂起延续；跳层后层签未重刷、`oath_fulfillment cur:=999`、本地榜去重 → Sprint 23 技术收敛批）
- `SPR22_规划草案.md` 未跟踪，待授权入库（随下批文档整理）
- P2（origin/main 推送，需一次性 PAT）留发布侧待指令
