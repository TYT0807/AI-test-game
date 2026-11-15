# SPR25 音频合规清单（只读评估稿）

- 任务 `SPR25-AUDIO-01`｜audio-director｜基线 `4b96035`（本地=远端，仓库 public）｜Godot 4.7.2 / GDScript｜范围：`resources/audio/` 全部 26 文件 + `assets.gd` 注册表 + 全仓 `Game.sfx(` 68 处调用点 + 运行时音频代码
- 纪律：**只读**。未改任何仓库文件、未下载/引用外部音频、未生成音频、未写 `.gd`、未 commit；本稿为唯一产出
- 依据仅限：文件名 / 内嵌元数据（MP3 ID3v2、WAV LIST-INFO 与 ID3，均只读探测）/ 文档自述 / 项目内注释。**不下法律结论、不臆造许可证**，判定权留给使用者

## 0. 结论速览

- **三类计数**：源音频 13 个（3 MP3 + 10 WAV）＝ **A 13 / B 0 / C 0**；`.import` 边车 13 个＝ **C 13**；合计 26 文件＝ **A 13 / B 0 / C 13**。13 个源音频中可确认干净者 = 0
- **疑似清单**：3 首 `1-2x Journey of the Prairie King (*).mp3` + 10 个 `Cowboy_*.wav`（逐文件见 §2.1）；**「换文件不改注册表」有条件成立**（详见 §3.3）；**待拍板** 3 组 A/B 见 §6

## 1. 判定口径

- **A**＝文件名或内嵌元数据高度疑似指向第三方商用作品；**B**＝来源不明/需单独核实；**C**＝可确认不含第三方音频内容（项目自生成）。作品识别（由文件名+元数据推断，**待用户/权利方复核**）：`Journey of the Prairie King` 是《星露谷物语》(*Stardew Valley*) 内置街机小游戏，`Cowboy_*` 与其音效命名同源；MP3 的 ID3 明确写着专辑 `Stardew Valley Original Soundtrack`、作者/厂牌 `ConcernedApe`、版权 `Fangamer`、年份 2018、曲目号 27/28/29、来源 `Deezer`；WAV 全部内嵌 `LIST/INFO/INAM` 与 ID3 `TIT2`，值形如 `Wave Bank#NNN (Cowboy_xxx)`（`Wave Bank#` 为 XACT 波库术语，与「从游戏音频波库抽取」一致）。以上均为**文件内事实记录**，非许可判定

## 2. 逐文件来源判定（26 个文件全列）

### 2.1 源音频 13 个 —— 全部 A 类

| # | 源文件 | 实测编码 / 时长 | 内嵌元数据依据 | 类 |
|---|---|---|---|---|
| 1 | `1-27 Journey of the Prairie King (Overworld).mp3` | MP3 VBR≈173kbps / 44.1kHz / stereo / **104.0s** / 2.47MB | ID3v2.4：`TIT2`=…(Overworld)；`TALB`=Stardew Valley Original Soundtrack；`TPE1/TCOM/LABEL/ARTISTS`=ConcernedApe；`TCOP`=Fangamer；`TDRC`=2018；`TRCK`=27/70；`TXXX SOURCE`=Deezer+SOURCEID；`ISRC`=TCACS1600142；`BARCODE`；`TSSE`=Lavf56.40.101（转码痕迹） | A |
| 2 | `1-28 Journey of the Prairie King (The Outlaw).mp3` | VBR≈207kbps / 44.1kHz / stereo / **66.9s** / 1.95MB | 同上，`TIT2`=…(The Outlaw)，`TRCK`=28，`ISRC`=TCACS1600143 | A |
| 3 | `1-29 Journey of the Prairie King (Final Boss & Ending).mp3` | VBR≈193kbps / 44.1kHz / stereo / **83.6s** / 2.24MB | 同上，`TIT2`=…(Final Boss & Ending)，`TRCK`=29，`ISRC`=TCACS1600144 | A |
| 4 | `Cowboy_gunshot.wav` | PCM 16-bit / 44028Hz / stereo / **0.125s** | `INAM`/`TIT2` = `Wave Bank#267 (Cowboy_gunshot)` | A |
| 5 | `cowboy_gunload.wav` | PCM 16-bit / 44048Hz / stereo / **0.674s** | `Wave Bank#273 (cowboy_gunload)` | A |
| 6 | `cowboy_explosion.wav` | PCM 16-bit / 44071Hz / stereo / **1.449s** | `Wave Bank#277 (cowboy_explosion)` | A |
| 7 | `cowboy_monsterhit.wav` | PCM 16-bit / 44032Hz / stereo / **0.250s** | `Wave Bank#275 (cowboy_monsterhit)` | A |
| 8 | `cowboy_monsterdie.wav` | PCM 16-bit / 44122Hz / stereo / **0.459s** | ⚠ `INAM`/`TIT2` = **`Wave Bank#269 (cowboy_dead)`**（与文件名不符）；另有 `DISP` + `_PMX` Adobe XMP 块（6539B）；mtime `2026-03-04` 异于同批 `2019-12-15` → 疑似本地二次加工/重导出 | A（附待核实 §2.3） |
| 9 | `cowboy_dead.wav` | PCM 16-bit / 44122Hz / stereo / **2.347s** | `Wave Bank#269 (cowboy_dead)` | A |
| 10 | `cowboy_gopher.wav` | PCM 16-bit / 44032Hz / stereo / **0.500s** | `Wave Bank#276 (cowboy_gopher)` | A |
| 11 | `cowboy_powerup.wav` | PCM 16-bit / 44031Hz / stereo / **0.875s** | `Wave Bank#272 (cowboy_powerup)` | A |
| 12 | `Cowboy_Secret.wav` | PCM 16-bit / 44130Hz / stereo / **1.566s** | `Wave Bank#264 (Cowboy_Secret)` | A |
| 13 | `Cowboy_Footstep.wav` | PCM 16-bit / 44032Hz / stereo / **0.250s** | `Wave Bank#270 (Cowboy_Footstep)`；**全仓 0 引用**（孤立资产） | A |

### 2.2 `.import` 边车 13 个 —— 全部 C 类

`1-27 Journey of the Prairie King (Overworld).mp3.import`、`1-28 Journey of the Prairie King (The Outlaw).mp3.import`、`1-29 Journey of the Prairie King (Final Boss & Ending).mp3.import`、`Cowboy_gunshot.wav.import`、`cowboy_gunload.wav.import`、`cowboy_explosion.wav.import`、`cowboy_monsterhit.wav.import`、`cowboy_monsterdie.wav.import`、`cowboy_dead.wav.import`、`cowboy_gopher.wav.import`、`cowboy_powerup.wav.import`、`Cowboy_Secret.wav.import`、`Cowboy_Footstep.wav.import` —— 均为 Godot `[remap]` 导入配置（mp3：`loop=false/loop_offset=0/bpm=0`；wav：`compress/mode=2`、`normalize=false`、`loop_mode=0`），**不含音频数据**；`source_file`/`dest_files` 里仍带第三方命名，改名后由 Godot 重新生成，无需单独处置

### 2.3 待核实事项（非文件，B 类文件计数 0）

1. `玩法说明.md:136` 自述「BGM/音效（项目自带）」**未标来源与许可证**，同段视觉侧 Tiny Creatures 却明确写了「Clint Bellanger / CC0 1.0 / 出处链接」，音频侧缺同等记录；2. `cowboy_monsterdie.wav` 元数据与文件名不一致 + Adobe XMP + 异于同批 mtime（§2.1 #8），需确认是否二次加工/引入额外来源（**仍按同源 A 类待替换**）；3. 孤立引用 `player.gd:673 Game.sfx("suffix", …)` 别名未注册 → `game_state.gd:649` 静默 return 永远无声；4. 孤立资产 `Cowboy_Footstep.wav` 有 `.import` 但零引用

## 3. 实际用途与替换约束

### 3.1 引擎/运行时事实（只读实读）

| 项 | 事实 | 出处 |
|---|---|---|
| 中间件 / 总线 / 音量链 | 无 Wwise/FMOD，全部内置 `AudioStreamPlayer`；**无自定义 audio bus**（Sprint 6 口径「避免手写 bus 布局出错」），主音量 `AudioServer.set_bus_volume_db(0,…)`；`Game.sfx()` = `volume_db + linear_to_db(sfx)`（默认 0.9 → ≈ -0.9dB），**运行时不做逐事件响度校准** | `game_state.gd:651,672-674,1016`、`Sprint6_交付报告.md:43` |
| SFX 池 | 8 个 `AudioStreamPlayer`，`bus="Master"`，无优先级/无距离衰减/无总线分层；池满抢占 `_sfx_pool[0]` | `game_state.gd:86,100-104,648-663` |
| BGM | 2 个 `AudioStreamPlayer` 交叉淡入 `dur=1.0s`（首帧 0.2s）；目标音量 `-6.0 + linear_to_db(bgm)`，默认 0.8 → ≈ **-7.9dB** | `game_main.gd:152-157,2066-2086` |
| 循环 / 变体 | `assets.gd::_ready()` 对 3 首 MUSIC 强制 `m.loop = true`，但 `.import` 为 `loop=false/loop_offset=0` → 从 0 循环到文件尾；无多文件变体，仅 `pitch_scale` **0.5–1.7** 与 `volume_db` **-14…0** 做随机分层 | `assets.gd:147-148`、3 个 mp3.import、全仓 68 处调用点 |
| 注册表 / 房型 / 预算 | `SFX` 14 别名 → 9 个唯一 wav；`MUSIC` 3 首；`bgm=0` 覆盖 9/11 房型（start/combat/treasure/shop/secret/super_secret/challenge/cursed/shrine），`bgm=1`=elite，`bgm=2`=boss；WAV 1.51MB + MP3 6.66MB + .import 6.6KB = **8.17MB**，同发语音 8(SFX)+2(BGM)=10 | `assets.gd:14-37`、`data.gd:297-307`、`game_main.gd:1436`、目录实测 |

### 3.2 逐 wav 用途与替换硬约束（9 个被引用 + 1 个孤立）

| wav（时长） | 注册别名（调用点数） | 主要触发事件 | pitch / dB 范围 | 替换硬约束 |
|---|---|---|---|---|
| `Cowboy_gunshot.wav` (0.125s) | `shoot` (6) | 玩家射击、虫群远程/散射、浮游炮开火 | 0.5–1.5 / -4…-12 | **最高频**（每发一次），须 ≤0.15s；8 声部池下长尾会糊/被抢占 |
| `cowboy_gunload.wav` (0.674s) | `reload` (6) + `boss_skill` (2) | 换弹、炸弹投掷、Boss 技能、商店购买、拾取 | 0.65–1.4 / -3…-10 | 兼「机械装填」与「Boss 技能」，只能取中性音；0.5 倍速可达 1.35s |
| `cowboy_explosion.wav` (1.449s) | `boom` (1) + `calamity` (1) | 炸弹爆炸、灾祸事件 | 0.9–1.0 / -6…0 | 两语义共用，勿做「爆炸+警报」双段；尾部须收敛静音 |
| `cowboy_monsterhit.wav` (0.250s) | `hit` (4) | 命中/受击反馈 | **0.7–1.7** / -2…-14 | pitch 上限最高，新素材高频不能刺；动态范围大须留峰余量 |
| `cowboy_monsterdie.wav` (0.459s) | `die` (3) | 敌人死亡、木箱/道具破坏 | 0.8–1.15 / -6…-8 | 元数据异常见 §2.3；兼「击杀」与「物件破坏」 |
| `cowboy_dead.wav` (2.347s) | `player_die` (2) | 玩家阵亡 | 1.0 / 0 | **全场最长 SFX**，低频触发，须保证不被 8 声部池抢占腰斩 |
| `cowboy_gopher.wav` (0.500s) | `pickup` (4) | 拾取、购买、菜单点击 | 0.7–1.7 / -6…-14 | 兼作 UI 音，须短促无尾音 |
| `cowboy_powerup.wav` (0.875s) | `powerup` (18) + `boss_phase` (2) | 升级/遗物/增益/商店/菜单、Boss 阶段切换 | 0.6–1.6 / -12…0 | **调用点最多(20)**；「奖励」与「Boss 升压」语义冲突最大，须最克制 |
| `Cowboy_Secret.wav` (1.566s) | `secret` (16) + `boss_intro` (1) + `shrine` (1) | 秘密房/隐藏墙/超级秘密、Boss 登场、圣所、里程碑 | 0.8–1.2 / -6…0 | **3 别名共用**：三种情绪压成同一音色；1.566s 偏长，高频 secret 易叠加 |
| `Cowboy_Footstep.wav` (0.250s) | 无 (0) | 无 | — | 孤立资产，覆盖与否不影响运行；建议同批处置 |

> **别名复用链**：`Cowboy_Secret.wav`→`secret`/`boss_intro`/`shrine`（3 语义共一音）；`cowboy_powerup.wav`→`powerup`/`boss_phase`；`cowboy_gunload.wav`→`reload`/`boss_skill`；`cowboy_explosion.wav`→`boom`/`calamity`。另有 `Game.sfx("suffix")` 未注册 → 静默无声。

### 3.3 「换文件不改注册表」结论

**成立，但有硬前提**：① 新文件沿用 13 个源文件的**完全同名同路径**（覆盖式替换，注意 `Cowboy_gunshot`/`Cowboy_Secret`/`Cowboy_Footstep` 大写 C 与其余小写 c 混杂，勿统一）；② **保持格式类型**——WAV→`AudioStreamWAV`、MP3→`AudioStreamMP3`；尤其 BGM **必须保留 `.mp3`**，因 `assets.gd:148` 的 `m.loop = true` 依赖 `AudioStreamMP3.loop`（换 `.wav` 无该属性会运行时报错，换 `.ogg` 需改 `preload()` 路径）；③ 替换后须让 Godot **重导入**（重开编辑器或清 `.godot/imported/` 对应缓存），否则运行时仍是旧流。满足则 `assets.gd` 零 diff、14 别名与 68 处调用点全部不动。
**代价/副作用**：a) 文件名仍含 `Cowboy_*` / `Journey of the Prairie King` 字样，public 仓库下仍可被检索，长期需二次改名；b) 4 个 wav 被 5 个额外别名复用，替换后每个文件仍须「一音多用」，只能取中性最大公约数音色，Boss/圣所/灾祸无法各自定制；c) **拆成多个新文件 = 新增 preload 条目 = 必改 `assets.gd`**，约束即破；d) MP3 循环接缝（编码器延迟 + `loop_offset=0`）无法靠换文件彻底消除，除非只改 `.import` 的 `loop_offset`（允许、不动 assets.gd，但重导入可能覆盖）或换 OGG（需改 assets.gd）。**不可替代性**：无功能性不可替代——无节拍同步、无动画标记绑定，全部为一次性 SFX + 循环 BGM；结构性不可拆分的是「别名复用」；工作量最大的是 3 首 BGM（合计 254.5s，需循环点对齐 + 1.0s 交叉淡入兼容）。

## 4. 原创音频方向（承接「废弃矿窟 + 克制、不煽情」）

**调色板**：干、近、短混响（岩壁早期反射）；低频矿层隆隆 + 金属/岩石摩擦 + 稀疏钝击。**不用**铜管、上行旋律、大动态弦乐、长音高持续与明显终止式；动态范围窄（≤6dB），留白多于音符。> 注：仓库内未找到 art-bible / 叙事情绪文档（已检索全仓 md 与 `production/`）；本基调取自主理人任务书，建议经主理人与美术/叙事侧确认后定稿。

### 4.1 音效 9 类规格（对应 9 个被引用 wav）

| 类 | 音色建议 | 时长上限 | 固有响度 | 别名复用备注 |
|---|---|---|---|---|
| 射击 `shoot` | 干燥短促「气爆 + 金属击发」，无拖尾混响 | ≤0.15s | peak ≤ -1 dBTP，RMS ≈ -18 dBFS | 最高频；pitch 0.5–1.5 |
| 装填 `reload` | 两段式机械卡榫（短「咔+嗒」），不写实枪械 | ≤0.7s | 同上 | 兼 `boss_skill`，须中性 |
| 爆炸 `boom`/`calamity` | 低频「闷爆 + 碎石落」，去掉明亮爆破高频 | ≤1.5s，尾部收敛 | 同上，峰值留 3dB 余量 | 兼灾祸，勿做双段 |
| 命中 `hit` | 极短「石面钝击」，无明确音高 | ≤0.25s | 同上 | pitch 可达 1.7，避高频刺耳 |
| 击杀 `die` | 短「碎裂/塌落」，一次性 | ≤0.5s | 同上 | 兼木箱破坏 |
| 阵亡 `player_die` | 低频下沉 + 稍长岩层余响，**不煽情** | ≤2.3s | 比其它低 2–3dB | 全场最长，防池抢占 |
| 拾取 `pickup` | 压暗的「叮」（木/石感），无尾音 | ≤0.3s | 同上 | 兼 UI 点击 |
| 增益 `powerup`/`boss_phase` | 极短「两音」但幅度极小、不明亮 | ≤0.6s | 同上 | 调用点最多(20)，须最克制 |
| 揭示 `secret`/`boss_intro`/`shrine` | 中性「低频脉冲 + 空间开启感」，不悬疑、不凯旋 | ≤1.2s | 同上 | 3 别名共用，语义冲突最大 |

### 4.2 BGM 3 首情绪曲线与循环点

| 索引 / 现名 | 房型 | 情绪曲线 | 循环点 / 长度建议 |
|---|---|---|---|
| `MUSIC[0]` / 1-27 Overworld / `bgm=0` | 9/11 房型（常驻） | 恒定低平、几乎无旋律推进；稀疏低频脉冲 + 远处岩层摩擦，动态 ±2dB，无起承转合 | 60–90s 长循环，head/tail 等功率对齐；避免短循环产生可辨识重复感 |
| `MUSIC[1]` / 1-28 The Outlaw / `bgm=1` | elite | 张力升一档但**不加速、不燃**：加固定周期钝击，保持同 tempo / 同调性 | 与 Track0 同长度量级、同调，保证 1.0s 交叉淡入不撞调 |
| `MUSIC[2]` / 1-29 Final Boss & Ending / `bgm=2` | boss | 最高张力但收敛：低频持续 + 金属共振，无胜利式上行、**无终止式** | 开放结尾可无限循环（运行时强制 `m.loop=true` 回到 0，原曲「Ending」终止感必须去掉）；head/tail 对齐 |

通用：三首同调（建议 D 小调或无调性 drone）、同响度（三首间 ≤1 LU）、同长度量级；目标 **-20 LUFS-I**（比 SFX 低约 6–8dB，对齐运行时固定 -6dB 链），峰值 ≤ -1 dBTP。

### 4.3 可执行获取路径（署名 / 许可证影响）

| 路径 | 是否需署名 | 是否引入新许可证 | 适用与代价 |
|---|---|---|---|
| **自合成**（DAW / 合成器 / 实地岩石金属 foley 录制） | 否 | 否（归项目自有） | 9 类短 SFX 最可控，能精确命中 0.125–2.3s；3 首 BGM 人力成本最高；零外部依赖。**推荐主路径** |
| **开源 CC0 库并标出处**（Kenney.nl 音频包 CC0 / OpenGameArt 音频区 / Freesound 逐条筛 CC0） | CC0：否；**CC-BY：是**（须保留作者+链接+许可） | CC0：否；CC-BY 引入「署名义务」（不改项目整体许可，但须留档） | 快、音色现成；**必须逐文件核对标签并截图留档**，并在 `玩法说明.md` 补与 Tiny Creatures 同规格的「作者/许可证/链接」段（现状 §2.3） |
| **生成式音频** | 取决于服务条款（部分要求标注 AI 生成） | 不引入开源许可证，但引入**服务条款约束**（商用授权、训练数据相似性） | 时长/循环点/响度仍需人工后期；**存疑，需用户先确认 ToS**，本稿不推荐直接用于 public 仓库 |

## 5. 替换规格与顺序

**规格**：沿用 13 个原文件名与 `res://resources/audio/` 路径（覆盖式）；SFX = RIFF PCM WAV 16-bit / 44100Hz / stereo，BGM = MP3 MPEG1 Layer III / 44100Hz / stereo（建议 ≤192kbps）；沿用 `.import` 参数（`compress/mode=2`/`normalize=false`/`loop_mode=0`/`force/max_rate_hz=44100`）；**不内嵌 ID3/LIST/INAM/APIC 元数据**。响度口径：SFX 峰值 ≤ -1 dBTP、RMS ≈ -18 dBFS（统一基准），BGM 目标 -20 LUFS-I、三首间 ≤1 LU，首尾 5–10ms 淡变、去 DC、尾部收敛，SFX 一律不循环，BGM 末 50ms 与首 50ms 等功率交叉后导出、loop 从 0 开始。预算：现 8.17MB，192kbps 约增至 13–19MB 需确认平台内存；同发语音 8+2=10 不变，新音效**不得显著加长**（尤其 `shoot`/`hit`/`powerup`）。原创命名只在「决定改 `assets.gd`」时启用。

| 批次 | 文件 | 验收方式 |
|---|---|---|
| **0 先行（非替换）** | 冻结 13 个源文件 hash 基线；`玩法说明.md:136` 补「来源/许可证/链接」段；原文件备份到仓库外（不 commit） | `git status` 干净、`4b96035` 未动；文档 diff 单独可审 |
| **1 高频 SFX（4）** | `Cowboy_gunshot` / `cowboy_monsterhit` / `cowboy_powerup` / `cowboy_gopher`（6+4+18+4=32 调用点） | 重导入无报错；连射 10s 无糊/无池抢占腰斩；pitch 0.5 与 1.7 两端试听；`assets.gd` 零 diff |
| **2 中低频 SFX（6）** | `cowboy_gunload` / `cowboy_explosion` / `cowboy_monsterdie` / `cowboy_dead` / `Cowboy_Secret` / `Cowboy_Footstep` | Boss 三别名（intro/phase/skill）听感可辨但同源；`boom`/`calamity` 时长吻合；`player_die` 2.3s 不被抢占；孤立 Footstep 处置确认 |
| **3 BGM（3）** | 3 首 MP3 | `m.loop=true` 仍生效（assets.gd 无报错）；**循环接缝无空隙/咔哒**；切房 1.0s 交叉淡入无撞调；三首响度一致 |
| **每批通用门** | — | `git status` 仅含被替换文件、`assets.gd` 零 diff、无硬编码音频路径、现有 SMOKE/validate 不回归；建议 QA 侧做一次「听感 + 无报错」复核 |

**止损口径（约束被打破）**：触发＝任一必需改名 / BGM 必须换 OGG 求无缝 / 需把 4 个复用 wav 拆成独立文件以区分语义。步骤：① 立即停后续批次，回到 `4b96035` 可用态；② `assets.gd` 的改动**单独一个 commit**（只改 `SFX`/`MUSIC` 的 preload 路径与 `_ready()` 循环设置，不夹带音频文件）；③ 同步 14 个别名 key + `.import` 重生成 + 补 `suffix` 孤立引用；④ QA 跑 validate + 全 SMOKE；⑤ 文档记录「约束已破 + 原因 + 新别名映射表」，交主理人裁定是否回退。用户当前口径「先出评估，不立项」，故本稿不推荐主动打破。

## 6. 待拍板项（3 组 A/B）

| # | A 案 | B 案 | 代价对照 |
|---|---|---|---|
| **1 替换策略** | **A1 同名覆盖**（换文件不改 `assets.gd`）：零代码改动、可逆、风险最低 | **A2 原创命名 + 同步改 `assets.gd`**：命名与来源彻底脱钩 | A1 代价：public 仓库下文件名仍含 `Cowboy_*`/`Journey of the Prairie King`，仍可被检索，需二次改名。A2 代价：触碰冻结的 34 个 `.gd` 之一、需单独 commit、14 别名 + `.import` 重生成 + QA 回归；且 MP3→OGG 会连带破坏 `m.loop=true` |
| **2 获取路径** | **B1 全自合成**：9 类 SFX + 3 首 BGM 全自制 | **B2 自合成 + CC0 库补底**：短 SFX 自制，BGM/环境层用 CC0 素材 | B1 代价：3 首 BGM 人力/时间成本最高；收益是无署名义务、无新许可证、来源链最干净。B2 代价：必须逐文件核对许可标签、截图留档、补 `玩法说明.md` 出处段；若误取 CC-BY 会引入署名义务（生成式音频另列存疑，不作推荐） |
| **3 BGM 循环** | **C1 保持 MP3 + head/tail 对齐**（不改 `assets.gd`），必要时只调 `.import` 的 `loop_offset` | **C2 改 OGG Vorbis + 原生 loop point**：真正无缝 | C1 代价：MP3 编码器延迟可能残留微缝，需实测试听；`.import` 改动可能被重导入覆盖。C2 代价：**必须改 `assets.gd` 的 preload 路径与循环设置**，与第 1 组 B 案联动，等于立项 |

## 7. 存疑与边界

- 项目无 `CLAUDE.md`；技术基准取自 `production/sprint-15/handoff/HANDOFF_技术接手包.md`（Godot 4.7.2 / autoload `Assets`·`Game`·`Data`·`Dev`·`Validate` / 无自定义 bus）；无 art-bible / 叙事情绪文档，§4 基调待主理人与美术/叙事侧确认
- 判定仅基于文件名与内嵌元数据，**未作法律结论**；`TCOP=Fangamer`、`LABEL=ConcernedApe`、`SOURCE=Deezer` 等仅为文件内事实记录，不等于许可状态；`cowboy_monsterdie.wav` 元数据异常（§2.1 #8）需单独核实
- **引擎相关风险**：只读审计未运行 Godot，无法实测 `AudioStreamMP3.loop` / `loop_offset` 在 4.7.2 的行为、重导入后 `uid` 是否保持、以及 MP3 循环接缝的实际听感 → 建议经主理人转程基岩核对后再进入实施；本稿为评估稿：不立项、不动仓库、不下载/生成音频，孤立引用 `suffix` 与孤立资产 `Cowboy_Footstep.wav` 建议同批记录，不在本次处置范围内
