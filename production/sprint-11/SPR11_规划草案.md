# Sprint 11 规划草案（主理人合成 · 修订版，基于工作室四专家实稿）

> 修订说明：首版合成时 design-strategist 首稿丢失（stdout 为空、团队上下文退出），主理人曾以自身判断代笔；现已重新拉取 design-strategist 实稿并校正。本文件为最终**自包含需求规格**，编程侧据以实现；主理人侧不写代码。
> 来源：design-strategist（玩法）+ art-director（美术）+ audio-director（音频）+ quality-lead（验收）四专家提案，经主理人综合裁定。

## 〇、两条跨批铁律（任何新内容必须遵守）
1. **E6 固定步**：所有 DoT / 冷却 / 持续 / 计时一律用 `Game.FIXED_DT`（=1/60）累加，**禁止 raw `delta`**。新增任何计时机制必须显式标注走 FIXED_DT。
2. **E1 确定性指纹**：`Game.rng` 是玩法随机流。核心生成/掉落循环**不无故新增 rng 调用**；表外验证探针（`SMOKE_*`）**不得进入 E1 diff**（守坑 45，跨版本日志作废、基线重定）。

## 一、候选方向（design-strategist 实稿 3 条 + art 补充）
- **A. 反应式遗物词缀层「Reactive Suffixes」**（M）：在 F2 的 4 个主动遗物（F/Z/X/C）之上叠一层被动"反应词缀"，在既有触发点附加二次效果，零新增按键、零每帧 rng。
- **B. 主题相位 Boss「Shiftwarden / 迁律守望者」（美术名 棱镜守望者）**（L）：按 HP 66%/33% 三阶段，每阶段借用当前楼层主题机制 + 召唤 F3 SQUADS 增援；把 F4 的 8 主题差异转化为 Boss 可读性。
- **C. 元进度层「Vault Sigils / 地窖印记」**（M）：局外持久印记，run 开始前选定、run 初始化时（任何 Game.rng 绘制前）注入初始状态，对 E1 零漂移。
- （art 额外提了相位敌人「回响 / The Echo」作为视觉发挥点，可作为 B 的伴生小怪或独立 S 级扩展，非主候选。）

## 二、优先级裁定（主理人，与设计专家一致并补一条）
1. **先做 A（反应式词缀）**：复用 F2 遗物既有的 4 个触发点（环盾敌弹摧毁 / 冲刺无敌帧开始 / 齐射开火 / 毒云每跳），一张数据表 `Data.RELIC_SUFFIXES` 即放大构筑深度；几乎零新 rng、E1 风险最低、性价比最高。
2. **C 的种子契约本迭代前半段就锁定**：虽本体可后续实现，但印记注入点涉及 run 初始化的种子契约，越晚接越难不破 E1。
3. **B（主题 Boss）留最后**：L 规模 + 必须复用同一条 Game.rng 流以避免指纹漂移，工程与评审成本最高。
> 若预算仅够一批：只做 A（+ C 接口约定）。

## 三、方向 A 完整落地规格（Reactive Suffixes）
### 3.1 概念
在现有 4 主动遗物之上叠加被动"反应词缀"，当遗物触发特定条件时附加二次效果（如"环盾摧毁敌弹时释放小范围冰爆"），制造遗物×词缀的构筑多样性，不新增任何按键。
### 3.2 数据结构（data.gd）
- 新增 `const RELIC_SUFFIXES := {id: {trigger: enum, effect: ..., ...}}`（约 8–12 条），trigger 枚举：`ON_SHIELD_BREAK / ON_DASH_START / ON_VOLLEY_FIRE / ON_POISON_TICK`。
- 词缀只能附着到 trigger 匹配的遗物；effect 全部复用既有系统（在玩家位置生成当前楼层主题危害 / 施加减速 / 回血 / 短暂护盾）。
### 3.3 接入（player.gd，复用既有 4 遗物循环）
- 既有的环盾敌弹摧毁（player.gd:488-491）、冲刺无敌帧开始、齐射开火（:444-451）、毒云每跳（toxic_cloud `_tick_friendly`）四处触发点各加一个钩子 `on_relic_trigger(relic_key, trigger_enum)`；词缀效果从数据表解析，**每帧零新 rng 调用**。
- 词缀自身冷却/持续：一律 `suffix_cd_accum += Game.FIXED_DT`（E6）；触发的临时增益到期也 FIXED_DT 累加。
- HUD：在对应遗物槽位下方显示已附词缀（复用现有 HUD 槽）。
### 3.4 rng/指纹
- 词缀在掉落/拾取时的"抽取"发生在生成掉落循环，必须用 `Game.rng`（属单局确定性生成）；**会把新的绘制顺序写进文档**——它改变绝对指纹，但只要顺序稳定即可复现（属新内容层预期代价）。
- 每帧 update 的二次效果结算**严禁新增 rng**，完全由状态确定。
- 调试探针 `SMOKE_SUFFIX` 表外、不进 E1 diff。
### 3.5 美术/音频（art/audio 补充）
- 词缀不新增主题色相：触发特效复用对应楼层主题调色板参数驱动；新增贴图仅限词缀 HUD 小标（1 张，`icon_suffix_*`，入 generated 并 `--import`），其余改色复用。
- 新增 SFX `sfx("suffix", ...)`（词缀触发），走现有 sfx() 注册表，不硬编码路径。

## 四、方向 C 完整落地规格（Vault Sigils 元进度）
### 4.1 概念
跨局持久"印记"层：玩家用累积货币 shards 在局外解锁并携带 1 枚印记进入下一局，提供轻度开局增益，**不污染单局确定性**。
### 4.2 持久化与契约（关键）
- 独立 save 文件（与 rng 流隔离），保存已解锁印记与 shards；奖励公式 `shards += floor(cleared_floors * META_RATE)`（META_RATE 常数，无 rng）纯确定性。
- **种子契约**：印记在 run 开始前由玩家选定；run 初始化函数里、**任何 Game.rng 绘制之前**把印记修正注入玩家初始状态（如 +1 初始最大 HP / 开局预装 1 个基础遗物 / +X 起始金币 / 一次性主题免疫）。整局对 `(seed + 所选印记)` 完全可复现。
- 严禁把奖励做成运行期动态开关（会改写 rng 消费顺序）。
### 4.3 计时（若有开局时长 buff）
- 时长型开局增益：`buff_accum += Game.FIXED_DT`，到 TICK 数到期，绝不走 raw delta。
### 4.4 rng/指纹
- 印记选择玩家驱动、run 之前发生，**完全不触碰 Game.rng → E1 零漂移**（三方向里最安全）。
- 调试解锁 `SMOKE_META_PERSIST` 表外、不进 E1 diff。
### 4.5 美术/音频
- 局前配装界面复用 `icon_guard` 图标语言 + 现有 8 主题色做节点高亮（art 建议）；新增资产仅限"地窖"背景板 1 张。
- 音频：本方向无新增战斗 SFX，仅界面音可复用现有。

## 五、方向 B 完整落地规格（主题相位 Boss，下一批）
### 5.1 概念
一个读取当前楼层主题、按 HP 66%/33% 三阶段分别调用对应主题签名机制的相位 Boss；把 F4 的 8 主题差异直接转化为 Boss 战可读性。美术名「棱镜守望者」，视觉上墨黑棱柱核心 + 三枚绕转主题碎片（art 提案）。
### 5.2 机制
- 三阶段各自激活一个主题签名机制（magma 扩散 DoT 脉冲环 / ice 减加速斑块 / vines 全向阻挡 / 其余主题按楼层索引确定性选取）：**全部复用 F4 既有 theme handler，重新调用、不重写**。
- 每阶段同步召唤一个 `Data.SQUADS` 迷你模板增援（复用 mender 治疗词缀、defuser 拆弹）。
- 所有计时 FIXED_DT：`phase_dot_accum` / `boss_cd_accum` / `ring_t` / `phase_t` 均 `+= Game.FIXED_DT`。
### 5.3 rng/指纹
- 三阶段所选 3 主题必须由楼层索引（floor mod 8）确定性推导，**禁调 Game.rng**。
- Boss 战斗中的随机（召唤哪队、冲刺方向）必须路由进既有 `Game.rng` 流（敌人 AI 已用同一条），**不得新建第二条 rng**，保持绘制顺序一致。
- 冒烟探针 `SMOKE_BOSS` 表外、不进 E1 diff。
### 5.4 美术/音频（art/audio）
- 美术：三张新增贴图 `boss_prism_core`/`boss_prism_shard`/`boss_prism_death_shard` 入 generated 并 `--import`；三相颜色用现有主题调色板驱动，禁硬编码；VFX（生成/受击/技能/死亡）改色复用 toxic_cloud puff + 现有粒子，不新增粒子图（形状不同才新增）。
- 音频：Boss 登场/阶段切换/技能各 1 个 SFX（如 `sfx("boss_phase", ...)`），走 sfx() 注册表；音乐按当前主题分层叠加，可开关。

## 六、验收与回归（quality-lead，四道门控）
1. **回归纪律**：组合回归 `SMOKE+V8+REBIND+RELIC`（+本批 `SUFFIX`/`META`/`BOSS`）跑 3000 帧须 0 报错；冻结基线 `SPR7-FROZEN-4.md5` 重定 29/29（新增文件计入）。
2. **E6 合规**：grep 确认 A/C/B 所有新计时（suffix_cd_accum、buff_accum、phase_dot_accum、ring_t、phase_t…）走 `Game.FIXED_DT`，无 raw delta 累加。
3. **E1 非污染**：A 的词缀抽取并入 Game.rng 且绘制顺序写入文档；C 的 meta 在 rng 前注入、零额外 rng；B 主题选取纯函数零 rng、Boss 随机路由既有流；`SMOKE_SUFFIX`/`SMOKE_META_PERSIST`/`SMOKE_BOSS` 表外不进 E1 diff（坑 45）。
4. **探针设计**：`SMOKE_SUFFIX`（词缀触发验证）、`SMOKE_META_PERSIST`（存档读写/越界）、`SMOKE_BOSS`（阶段切换+主题选取确定性校验）。
5. **给编程 AI 一句话**：先 `--import` 任何新增贴图；E6 用 grep 自证；表外探针一律不进 E1 diff；动 rng 前先想清是否漂移 E1 基线。

## 七、落地顺序建议（编程侧）
1. 锁 C 的种子契约（改 run 初始化，最小面）。
2. 做 A：data.gd `RELIC_SUFFIXES` + player.gd 4 触发点钩子 + HUD/美术/音频新增资源。
3. 跑四道门控 + 冻结重定。
4. B（主题 Boss）留待 A 验证「主题复用范式」后下一批。

## 八、主理人备注（不进转发文本）
- A 是必做、C 接口必锁、B 下批。三者都建立在 Sprint 10 已冻结的 F2/F3/F4 之上，复用既有触发点 / theme handler / SQUADS，风险可控。
- 若编程侧只接一批：只做 A（+ C 接口约定）即闭环。
- 非阻塞：art 提的相位敌人「回响」可作为 B 的伴生小怪或独立 S 级扩展，待定。

## 九、验收状态（主理人交叉核验 · 2026-11-07）
### A 反应式词缀 + C 种子契约 —— **PASS**（2026-11-07）
- **核验口径**：读码（game_main / data / player / game_state / toxic_cloud / validate / hud / menu / pickup）＋ 读盘（E1 契约注入点、SIGIL 双档、settle_shards 无 rng），非凭交付描述验收（主理人 QA 铁律）。
- **关键锚点全命中**：
  - **E1 契约确证**：`game_main.start_run` :314 `_apply_sigil_contract()` 在 :317 `Game.rng.seed` 首抽**之前**调用，零 rng 消耗，(seed＋所选印记) 整局可复现。✓
  - **A 数据表**：`RELIC_SUFFIXES` 8 条（4 触发点 × 2），effect∈{theme_hazard / heal / slow_all / brief_shield}，与 §三 逐字吻合。✓
  - **C 数据表**：`SIGILS` 3 印记（vigor +1 生命上限/cost30、arsenal 副手预装霰弹/cost40、purse 开局 15 源石/cost25），`META_RATE=2.0`，`settle_shards` 纯 `floor(cleared×2)` 无 rng。✓
  - **E6 合规**：`_suffix_cds` 递减走 `Game.FIXED_DT`（player.gd:499）；词缀云分流 friendly→FIXED_DT（toxic_cloud）。✓
  - **triggerless 防连锁**：词缀云 `setup_friendly(..., true)` 不触发 `ON_POISON_TICK`，杜绝瘴波→毒云→瘴波无限扩散。✓
  - **validate 守卫**：`_check_suffixes` 守 trigger 枚举 / relic 引用 / effect 分支 / cd 合法。✓
  - **接入**：HUD 词缀行（hud:50/:363/:564）、菜单印记页（menu:126/:418）、pickup suffix（pickup:43-48/:142-153）、词缀掉落并入 `Game.rng`（game_main:1534-1541，属规划 §3.4 明示的预期 E1 代价）。✓
  - **印记持久层**：SIGIL 双档（SIGIL_PATH / SIGIL_SMOKE_PATH 隔离）＋ 读档先归零 `equipped` 再回填（防内存旧值穿透）。✓
- **质量门裁定**：**PASS**（代码侧 100% 吻合规划 §三/§四；组合回归 0 报错 + 29/29 冻结 = 实施侧自证，headless=dummy 未独立重跑，同既往批次口径）。
- **E1 基线重定（坑 45）**：本批词缀掉落并入 `Game.rng` 主流，绝对绘制顺序变化 → 旧 `SPR7-FROZEN-4` 基线失效，已重定为含 A＋C 新文件后的 29/29。
- **非阻塞遗留（同编程侧交付）**：拆弹哑弹落点场内钳制、环盾期 HUD 冷却显示、印记读档回退（已做先归零再回填修复，待边缘用例补验）。

### B 主题相位 Boss（L 级）—— **PASS**（2026-11-07 主理人读码核验）
- 规划 §五 + 细化规格 `SPR11_B主题相位Boss_细化规格.md` 已由编程侧落地（`scripts/boss.gd` 新 + game_main/player/assets 接线 + 3 贴图 + 3 SFX 别名）。主理人读码读盘复验全绿，非凭交付描述验收。
- **硬约束全命中**：
  - **E1 主题纯函数**：`phase_theme_index(floor_num,k)=4+(((floor-4)+k)%8)`（boss.gd:50-51）零 rng；floor-11 实测 vines→vein→toxic 与公式逐字一致；三阶段互不重复。
  - **状态机**：INTRO→ACTIVE→PHASE_2→PHASE_3→DYING（boss.gd:16/120-131），HP 66%/33% 阈值**只下不回退**、每固定步检测。
  - **E6**：Boss 全计时 `phase_t/ring_t/_hit_cd/_intro_shards_angle/_strafe_t/boss_cd_accum` 均走 `Game.FIXED_DT`（boss.gd:104-114/146/153/160）；player `apply_slow`/`relic_suppress_t` 递减 FIXED_DT（player.gd:507/511）。
  - **E1 rng 路由**：阶段内随机（游走 `_strafe_dir`/增援选取/增援落点/死亡 VFX）全走既有 `Game.rng` 流（boss.gd:149/196/215/322-325），无新建 rng；`SMOKE_BOSS` 表外探针不进 diff。
  - **§二 接入**：`_is_warden_floor` 首领层谓词（game_main:836）+ warden 取代常规 Boss + `_room_budget=1`（:947-956）；**首领层不调 `_roll_squad`**（boss 房本就不滚编队），warden 增援走独立 `spawn_slug` 路径（boss.gd:185-218），避免双重召唤。
  - **§五 机制复用**：magma/toxic/swamp→ToxicCloud、ice→apply_slow、vines→prop_vine×4、vein→diamond×5、pressure→apply_blast_push+shake、silent→relic_suppress_t+apply_slow，Boss 作触发源。
  - **美术音频**：3 贴图实存 `resources/texture/generated/` 且已 `.import`；碎片 tint 数据驱动（boss.gd:89/172-174/317）；`boss_intro/phase/skill` 别名注册（assets.gd:25-27）。
  - **E1 基线**：随 A 词缀掉落 + B Boss 战 rng 消费合并重定 30/30（含 boss.gd）；全量回归 0 报错 = 实施侧自证（headless 未独立重跑，同既往口径）。
- **质量门裁定**：**PASS**（代码侧 100% 吻合规划 §三–§十；3 项非阻塞小修已折入本批）。
- **非阻塞遗留（主理人读码发现 → 2026-11-07 清理批已清零）**：
  - **A. `_hit_cd` 双重递减** → 递减统一收敛 `_tick`（单一真相源），`_tick_combat` 只判定不递减（boss.gd:113 / :158-162，注释明示）。接触冷却恢复 0.8s 设计节奏。**已修 ✓**
  - **B. magma 色彩与 E6** → Boss 脉冲云改阶段主题 tint（岩浆橙等，碎片/危害色觉统一）+ `fixed_step=true`（E6 固定步）；ToxicCloud 加法增 `puff_tint`（敌方默认绿不变）/ `fixed_step`（grandfather 敌云维持 raw delta 零影响）。**已修 ✓**（注：规格 §五 字面"复用 prop_magma 分支"未严格实现，但以 ToxicCloud+tint+fixed_step 达成等效 DoT 环且色觉统一，视为等价达成）
  - **C. `ring_t` 死变量** → 成员 + 2 处引用全删（grep 零命中）；规格 §六 标注其为可选（扩张环未实现），将来做扩张环按规格重立。**已修 ✓**
  - 附带：上轮编辑事故（`_tick_combat` 函数头被误替换致结构损坏）同轮内整段重建，编译 + 探针验证干净。
- **仍开放的非阻塞项**：dash 幅度 option b（规划侧裁定）、「回响」伴生小怪（art 预留）。
- Sprint 11 进度：**A ✓ + C ✓ + B ✓ → Sprint 11 三项全部交付收官 + 三遗留清零**。git 仍仅落盘未提交，待授权。
