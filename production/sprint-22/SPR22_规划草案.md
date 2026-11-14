# Sprint 22 规划草案 · D flash_toast 同帧覆盖（合并语义）

> 状态：**方向已由用户裁定**（D 采纳、语义=合并、上游聚合；B 否决 / E 挂起）。规模 S。
> 基线：HEAD 为 Sprint 21 订正批（双清单口径生效），工作树干净。

## 一、缺陷与裁定

在册观察②：同帧多条首发现各调一次 `hud.flash_toast` → 单例 2.2s tween 互相覆盖，玩家只见最后一条。裁定：**合并，不排队**——排队会重新引入刷屏（`FLAVOR_BROADCAST_KINDS` 白名单本就为防刷屏而设）；玩家要知道的是「本帧有 N 条新记录」，细节在图鉴页可查。

## 二、实现口径（§上游聚合）

- 聚合点在 **`game_state.gd mark_codex()` 的白名单播报处**（上游），**不改 `hud.flash_toast()` 通用语义**——它还承接护盾抵挡、博学印记、挑战保底等提示，无条件合并会串味。
- 白名单类（themes/bosses/shrine）首发现 → 入聚合缓冲 + `call_deferred` 帧末冲洗（**零 delta 计时**，不用 ≤0.15s 窗口方案）；同帧 N 条 → 一条 `flash_toast("图鉴新发现 ×N")`。
- **单条（N=1）维持原格式**「矿工手记 · …」（既有探针与玩家认知兼容）。
- 单例 2.2s tween 复用，不加队列状态、不加逐条计时；跨帧的首发现各自成 toast（既有行为，接受）。
- 非白名单类（enemies/relics/suffixes）不进缓冲（行为不变，S20 口径）。

## 三、登记三件套

① 缓冲写入（mark_codex 白名单分支）② 渲染文案（单条原格式 / 多条「图鉴新发现 ×N」）③ **验渲染断言**：同帧 3 条白名单首发现 + 1 条非白名单对照 → `_toast.text` 逐字等于「图鉴新发现 ×3」（非白名单不计入）+ `_toast.modulate.a == 1.0`（可见）；单条回归「矿工手记 ·」原格式。**只验标志/计数不算过。**

## 四、红线与门控

- 零新增 `Game.rng` / `fx_rng`；帧聚合走 `call_deferred`（禁 delta 计时）；不碰六类 / `FLAVOR` 表 / `ACTION_DEFS` / `FLOOR_THEMES`；零新实体/资源/action；`hud.flash_toast` 函数体不动。
- 既有探针适配：S16/S19 的 toast 断言改为「清 pending → mark → 直调冲洗 → 断言」确定性模式（不赌帧边界，与 call_deferred 同一入口——子代理审查确认行为等价或更优）。
- 门控沿用双清单：本批快照重算 34 OK / 0 FAILED；历史归档勿覆盖（23 OK / 11 FAILED 预期）。
- 文档批顺手项：`SPR21_交付_阶段二.md` §七 的 `_tools/spr21_correct.log` 引用标注「本地日志、未入库」（_tools 被 .gitignore 忽略），关键三行已贴于 §七。

## 五、验收

headless 6000 帧 0 报错；`md5sum -c` 双清单按口径；子代理交叉审查对照本草案；单独提交。
