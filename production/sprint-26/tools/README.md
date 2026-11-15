# Sprint 26 音频工具链（入库版）

三首 BGM 是**自合成**的，不是外部素材。这里放可复现的生成链路，理由见 `SPR26_音频验收_用户实测.md` 的处置授权：音频问题优先走自合成，外部模板须过原创性合规检查、不过即退回自合成。**如果工具只躺在被 gitignore 的 `_tools/`，这条退路就是空的。**

## 三个文件

| 文件 | 作用 |
|---|---|
| `spr26_bgm_synth.py` | 合成器（纯标准库，无 numpy / 无采样素材）。五声音阶 + 钟磬 + drone + 气声 |
| `encode_bgm.sh` | 编码为 CBR160k MP3，自动对齐 -20 LUFS，并回读校验首帧/ID3/时长/TP |
| `spr26_bgm_probe.py` | 频段分布测量（FFT），带 `--selftest` 自检 |

## 跑法

```bash
python production/sprint-26/tools/spr26_bgm_probe.py --selftest   # 先证分析器可信
python production/sprint-26/tools/spr26_bgm_synth.py  /tmp/wav
bash   production/sprint-26/tools/encode_bgm.sh       /tmp/wav resources/audio
python production/sprint-26/tools/spr26_bgm_probe.py  /tmp/wav
```

## 可复现性已实证

2026-11-15 用本目录三个文件从零重跑，产出与仓库在库文件 **md5 逐字相同**：

```
c00665585195ae121d06f841fcf30fc0  1-27 Journey of the Prairie King (Overworld).mp3
6e10dbb0ce401ce9b120949d68220090  1-28 Journey of the Prairie King (The Outlaw).mp3
28c159d035528130019fc6a27b31fa87  1-29 Journey of the Prairie King (Final Boss & Ending).mp3
```

频谱也逐项复现（重心 437 / 144 / 172 Hz，中频 -6.7 / -11.1 / -9.8 dB）。
即：**确定性合成 + 确定性编码，改完可验证地回到已知状态。**

## 三条不能破的约束

1. **必须是 `.mp3`** —— `scripts/assets.gd` 靠 `AudioStreamMP3.loop` 做循环，换 ogg/wav 会掉循环。
2. **编码必须带 `-write_xing 0 -write_id3v1 0 -id3v2_version 0`** —— 剪映内置 FFmpeg 只有 `mp3_mf`，它默认写的 Xing 帧数头是坏的：ffprobe 会把 30s 测成 8.46s，但解码数据完整，极易误判为文件损坏。
3. **混音比例不要退回 v1** —— v1 三首频谱重心只有 98–216 Hz、中频比低频低 12–24 dB，实听是「一层低频嗡嗡」。v2 具体改了哪三处见合成器 docstring 顶部。
