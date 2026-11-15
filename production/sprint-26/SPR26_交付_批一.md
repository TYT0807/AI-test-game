# Sprint 26 批一交付 · 视听大换血（贴图 + BGM 六道卷化）

> 主理人（创造层）交付，2026-11-15。S25 是「去第三方 + 换名字」，本批是「赋灵魂」第一步：把 S25 覆盖的矿窟调性资产，再升级为六道卷调性。
> 性质：**纯资产覆盖**，零 `.gd` / 零 `.import` 改动。

## 一 改动清单（6 文件）

| 类别 | 文件 | 尺寸/格式 | 调性 |
|---|---|---|---|
| 贴图 | `resources/texture/W.png` | 160×288 RGBA8 | 拾痕者：折角兜帽 + 执冷光灯 + 执笔留痕 + 身后残影 |
| 贴图 | `resources/texture/源石虫.png` | 96×192 RGBA8 | 残念/游魂聚合体：半透明幽影外晕 + 中性灰凝结核 |
| 贴图 | `resources/texture/浮游炮.png` | 384×32 RGBA8 | 残响悬铃/引魂片：锈铁悬片 + 一点冷光 + 下落残片 |
| BGM | `1-27 …(Overworld).mp3` | 30.04s MP3 159k | 人间拾痕：D 羽调五声、稀疏钟磬、去终止感 |
| BGM | `1-28 …(The Outlaw).mp3` | 19.04s MP3 159k | 抉择相：A 低频 drone + 轻 pulse 推进，克制不燥 |
| BGM | `1-29 …(Final Boss & Ending).mp3` | 25.05s MP3 159k | 守关/往生：C 低声层 + 末段留白悬留，无终止 |

## 二 贴图实测（主理人独立核验）

- IHDR 逐字段对 HEAD 原件：W `(160,288,8,6,0,0,0)` / 源石虫 `(96,192,8,6,0,0,0)` / 浮游炮 `(384,32,8,6,0,0,0)` —— 三张全 IDENTICAL。
- md5 before→after：W `181ebafb→cb16d44c` / 源石虫 `d4464597→9910b7c6` / 浮游炮 `07bc2169→3a0d2932`。
- 视觉实读（ViewImage）：W = 持灯持笔小人、末行逐帧崩解（越被记住越缺损）；源石虫 = 灰蓝幽影聚合体、无足无甲壳无复眼、第6行散落递减；浮游炮 = 悬吊锈片 + 一点冷光、无无人机无炮管。三张均无文字/logo、无明日方舟造型撞车。
- **一处口径变化（如实标注）**：源石虫为表现「幽影」引入 2 档固定 alpha（112/64）用于外晕，S25 的 alpha∈{0,255} 自检放宽为 `{0,64,112,255}`。仍为 RGBA8 / 纯透明底 / 硬边无抗锯齿 / ≤10 色。主理人裁定接受（幽影是「游魂」母题的视觉载体）。

## 三 BGM 实测（主理人亲自合成并核验）

- 合成方式：纯标准库 Python 生成 PCM（`_tools/spr26_bgm_synth.py`），ffmpeg MediaFoundation `mp3_mf` 编码。**未引入任何第三方音源/素材**。
- 关键修复：`mp3_mf` 默认写损坏的 Xing 头导致时长探测错（8.46s），加 `-write_xing 0 -id3v2_version 0` 后得到裸 `fffb a0` 帧、无 ID3、时长正确——与 S25 现存 BGM 同构。
- 格式：MPEG1 LayerIII CBR 160k / 44100Hz stereo / 无 ID3 / 起始 `fffb a040`。
- 响度：-20.3 / -21.0 / -20.6 LUFS-I，True Peak -9.8 dBTP（无削波），贴合 S25 口径 ≈-20。
- 保留 `.mp3` 格式：`assets.gd:148 m.loop=true` 依赖 `AudioStreamMP3.loop`。

## 四 四门控

| 门 | 结果 |
|---|---|
| 改动范围 | 恰 3 PNG + 3 MP3 + `?? production/sprint-26/`；`.gd` diff = 0、`.import` diff = 0 |
| 冻结快照 | `md5sum -c SPR21-FROZEN.md5` → **34 OK / 0 FAILED** |
| validate | headless `SMOKE=1 SMOKE_SEED=12345 SMOKE_META_FINGERPRINT=1 --quit-after 1800` → 自检通过（敌人 29 / 房间 11 / 地图池 4 层）、problems=0、错误行 0 |
| E1 | 同 seed 两跑 `[SMOKE-META] fingerprint` **逐字 IDENTICAL**（资产不进指纹，零重定） |

## 五 遗留 / 不阻断

- `_tools/spr26_bgm_synth.py` 受 `.gitignore:6` 忽略，未入版本库（换环境需重生成能力则另议）。
- BGM 真机试听由主理人在有音频设备环境确认；技术实测（时长/码率/响度/无 ID3）已全过。
- 批二（语义深绑）为独立批次：需改 `data.gd` FLAVOR value（`.gd`），实施单已就绪 `SPR26_批二实施单_编程侧.md`，待编程侧执行。
