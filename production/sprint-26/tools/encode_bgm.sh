#!/usr/bin/env bash
# Sprint 26 BGM 编码脚本：WAV -> CBR160k MP3，并对齐 -20 LUFS + 回读校验。
#
# 【为什么需要这个脚本】编码有两个必踩的坑，靠记忆保不住：
#   1. 剪映内置 FFmpeg 没有 libmp3lame，只有 mp3_mf（MediaFoundation）。
#   2. mp3_mf 默认写 Xing 头，会写成**损坏的帧数**，ffprobe 探测时长错成实际的 1/3.5
#      （30s 被测成 8.46s），但解码数据是完整的 —— 极易误判为文件损坏。
#      必须加 -write_xing 0 -write_id3v1 0 -id3v2_version 0，得裸 fffb 帧。
#   3. 游戏侧 assets.gd 依赖 AudioStreamMP3.loop，所以**必须是 .mp3**，不能换 ogg/wav。
#
# 用法：bash encode_bgm.sh <wav目录> <目标audio目录>
#   bash encode_bgm.sh /tmp/out resources/audio
set -u

FF="${FFMPEG:-C:/Users/TangUser/AppData/Local/JianyingPro/Apps/11.4.1.14443/ffmpeg.exe}"
SRC="${1:?需要 wav 目录}"
DST="${2:?需要目标音频目录}"
TARGET_LUFS=-20.0

declare -A MAP=(
  [spr26_overworld]="1-27 Journey of the Prairie King (Overworld).mp3"
  [spr26_outlaw]="1-28 Journey of the Prairie King (The Outlaw).mp3"
  [spr26_final]="1-29 Journey of the Prairie King (Final Boss & Ending).mp3"
)

fail=0
for key in spr26_overworld spr26_outlaw spr26_final; do
  wav="$SRC/$key.wav"
  out="$DST/${MAP[$key]}"
  [ -f "$wav" ] || { echo "[FAIL] 缺 $wav"; fail=1; continue; }

  lufs=$("$FF" -hide_banner -nostats -i "$wav" -af ebur128=peak=true -f null - 2>&1 \
         | awk '/^\s+I:/ {print $2}' | tail -1)
  gain=$(awk -v t="$TARGET_LUFS" -v c="$lufs" 'BEGIN{printf "%.1f", t-c}')

  "$FF" -hide_banner -v error -y -i "$wav" -af "volume=${gain}dB" \
        -c:a mp3_mf -b:a 160k -ar 44100 -ac 2 \
        -write_xing 0 -write_id3v1 0 -id3v2_version 0 "$out" || { echo "[FAIL] 编码 $key"; fail=1; continue; }

  hdr=$(od -An -tx1 -N4 "$out" | tr -d ' \n')
  xing=$(grep -c "Xing" "$out" 2>/dev/null || true)
  lufs2=$("$FF" -hide_banner -nostats -i "$out" -af ebur128=peak=true -f null - 2>&1 \
          | awk '/^\s+I:/ {print $2}' | tail -1)
  peak=$("$FF" -hide_banner -nostats -i "$out" -af ebur128=peak=true -f null - 2>&1 \
         | awk '/^\s+Peak:/ {print $2}' | tail -1)
  dur=$("$FF" -hide_banner -i "$out" 2>&1 | awk '/Duration/ {print $2}' | tr -d ',')

  echo "[$key] 输入 ${lufs} LUFS -> 增益 ${gain}dB"
  echo "        输出 ${lufs2} LUFS / TP ${peak} dBFS / ${dur} / 首帧 ${hdr} / Xing命中 ${xing}"

  [ "${hdr:0:4}" = "fffb" ] || { echo "        [FAIL] 首帧不是 fffb 裸帧（实为 ${hdr}）"; fail=1; }
  [ "$xing" = "0" ] || { echo "        [FAIL] 含 Xing/Info 头"; fail=1; }
  awk -v a="$lufs2" -v t="$TARGET_LUFS" 'BEGIN{d=a-t; if(d<0)d=-d; exit (d>0.5)}' \
      || { echo "        [FAIL] 响度偏离 ${TARGET_LUFS} 超过 0.5dB"; fail=1; }
done

echo "---"
[ "$fail" = "0" ] && echo "ALL PASS" || echo "有失败项，见上"
exit "$fail"
