#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""Sprint 26 三首 BGM 合成器（纯标准库，无 numpy / 无外部采样）。

【为什么入库】批一音频返工报告（`5d5547b`）与验收授权（`a095b5c`）共同约定：
音频问题优先走「自合成」链路，外部模板必须过原创性合规检查，不过即退回自合成。
**若本脚本只留在被 gitignore 的 `_tools/`，这条退路就是空的**——所以入库。

六道卷调性：禅意 / 轮回 / 克制。五声音阶 + 钟磬 + 低频 drone + 气声，稀疏留白，
去进行曲 / 铜管 / 煽情终止式。守关曲结尾悬留不解决到主音，运行时时强制循环。

【用法】
    python spr26_bgm_synth.py <输出目录>        # 产出 spr26_{overworld,outlaw,final}.wav
    bash encode_bgm.sh <wav目录> <目标audio目录>  # 编码为 CBR160k MP3 并回读校验

【v2 混音（2026-11-15 返工，勿回退）】v1 实测频谱重心仅 98–216Hz、中频比低频低 12–24dB，
实听是「一层低频嗡嗡」。三处改动：
  1. drone() 全局 ×0.62 —— 它全曲持续、能量累积天然压过瞬态钟声。
  2. bell() 泛音权重 1.0/0.45/0.28/0.12 → 0.80/0.55/0.40/0.22 且整体 ×1.55，让「磬」透出来。
  3. 🔴 守关曲 lowbells 原为 C3/G2/F2/E3（87–165Hz），与 C2/G2 drone **同频段互相掩蔽**，
     旋律根本听不见 → 整体上移八度（C4/G3/F3/E4），drone 不动。亡命徒低钟 D3→D4 同理。
返工后重心 144–437Hz，中频 +6~13dB、中高 +10~25dB。改任何一条都要重跑 spr26_bgm_probe.py 对照。
"""
import math
import random
import struct
import sys

SR = 44100
TWO_PI = 2.0 * math.pi

# 音符频率表（D 羽调式五声：D F G A C）
N = {
    "D1": 36.71, "D2": 73.42, "D3": 146.83, "D4": 293.66, "D5": 587.33,
    "F2": 87.31, "F3": 174.61, "F4": 349.23, "F5": 698.46,
    "G2": 98.00, "G3": 196.00, "G4": 392.00, "G5": 783.99,
    "A1": 55.00, "A2": 110.00, "A3": 220.00, "A4": 440.00, "A5": 880.00,
    "C2": 65.41, "C3": 130.81, "C4": 261.63, "C5": 523.25,
    "E3": 164.81, "E4": 329.63,
}


def _buf(dur):
    return [0.0] * int(dur * SR)


def add(dst, src, at, amp):
    """把 src 混入 dst 的 at 秒处。"""
    start = int(at * SR)
    for i, v in enumerate(src):
        j = start + i
        if 0 <= j < len(dst):
            dst[j] += v * amp


def bell(freq, dur):
    """钟磬：非谐波泛音 + 指数衰减。（v2 提亮：基频降权、高次泛音加权，让「磬」的清亮透出来）"""
    out = _buf(dur)
    partials = [(1.0, 0.80), (2.0, 0.55), (2.76, 0.40), (5.4, 0.22)]
    for i in range(len(out)):
        t = i / SR
        s = 0.0
        for r, a in partials:
            s += a * math.sin(TWO_PI * freq * r * t)
        out[i] = s * math.exp(-t * 2.2) * 1.55
    return out


def pluck(freq, dur):
    """拨弦：衰减谐波，起音快。"""
    out = _buf(dur)
    partials = [(1.0, 1.0), (2.0, 0.45), (3.0, 0.24), (4.0, 0.12), (6.0, 0.06)]
    for i in range(len(out)):
        t = i / SR
        s = 0.0
        for r, a in partials:
            s += a * math.sin(TWO_PI * freq * r * t)
        attack = min(1.0, t / 0.006)
        out[i] = s * attack * math.exp(-t * 5.5) * 1.35
    return out


def drone(freq, dur, fade_in=0.6, fade_out=0.6, vib=0.15):
    """持续低音：正弦 + 轻微颤音 + 二次谐波微染，首尾淡入淡出（护循环接缝）。
    v2 降权 0.62：原本压过旋律 12–24 dB，频谱重心只有 98–216 Hz，听感发闷。"""
    out = _buf(dur)
    n = len(out)
    for i in range(n):
        t = i / SR
        amod = 0.85 + 0.15 * math.sin(TWO_PI * vib * t)
        s = math.sin(TWO_PI * freq * t) + 0.16 * math.sin(TWO_PI * freq * 2 * t)
        env = 1.0
        if t < fade_in:
            env = t / fade_in
        elif t > dur - fade_out:
            env = max(0.0, (dur - t) / fade_out)
        out[i] = s * amod * env * 0.62
    return out


def breath(dur, seed=0):
    """气声：单极点低通白噪声（近、干、无金属噪）。v2 加权 1.7 补空气感。"""
    rnd = random.Random(seed)
    out = _buf(dur)
    y = 0.0
    a = 0.045
    for i in range(len(out)):
        y = y * (1.0 - a) + (rnd.uniform(-1.0, 1.0)) * a
        out[i] = y * 1.7
    return out


def to_stereo(l, r):
    """等长对齐。"""
    n = min(len(l), len(r))
    return l[:n], r[:n]


def write_wav(path, left, right):
    n = min(len(left), len(right))
    # 归一化到峰值 0.72，防削波
    peak = 1e-9
    for i in range(n):
        peak = max(peak, abs(left[i]), abs(right[i]))
    g = 0.72 / peak
    frames = bytearray()
    for i in range(n):
        li = max(-1.0, min(1.0, left[i] * g))
        ri = max(-1.0, min(1.0, right[i] * g))
        frames += struct.pack("<hh", int(li * 32767), int(ri * 32767))
    data_size = len(frames)
    with open(path, "wb") as f:
        f.write(b"RIFF")
        f.write(struct.pack("<I", 36 + data_size))
        f.write(b"WAVEfmt ")
        f.write(struct.pack("<IHHIIHH", 16, 1, 2, SR, SR * 4, 4, 16))
        f.write(b"data")
        f.write(struct.pack("<I", data_size))
        f.write(bytes(frames))
    return n / SR


def soft_clip(x):
    return math.tanh(x * 1.1) / math.tanh(1.1)


def build_track(name):
    """三首曲目：返回 (left, right)。"""
    if name == "overworld":
        # 人间拾痕：淡、静、有限旋律，长期循环不腻。~30s
        dur = 30.0
        L = _buf(dur)
        R = _buf(dur)
        # 低频 drone D2 + A2（纯五度，稳定不煽情）
        add(L, drone(N["D2"], dur, 0.8, 1.0), 0.0, 0.30)
        add(R, drone(N["D2"], dur, 0.8, 1.0), 0.0, 0.30)
        add(L, drone(N["A2"], dur, 1.0, 1.2, 0.11), 0.0, 0.16)
        add(R, drone(N["A2"], dur, 1.0, 1.2, 0.09), 0.0, 0.16)
        # 稀疏钟磬点（避开首尾 2s，护循环）
        bells = [(2.5, "D5", 0.55), (6.0, "A4", 0.42), (9.5, "F5", 0.38),
                 (13.0, "G4", 0.40), (16.5, "D5", 0.50), (20.0, "C5", 0.36),
                 (23.5, "A4", 0.40), (27.0, "G4", 0.34)]
        for at, note, amp in bells:
            b = bell(N[note], 3.2)
            add(L, b, at, amp)
            add(R, bell(N[note], 3.2), at + 0.012, amp * 0.92)
        # 极轻气声垫
        br = breath(dur, 11)
        add(L, br, 0.0, 0.05)
        add(R, breath(dur, 23), 0.0, 0.05)
        return to_stereo(L, R)

    if name == "outlaw":
        # 抉择相：略紧、低频推进，克制不燥。~19s
        dur = 19.0
        L = _buf(dur)
        R = _buf(dur)
        # 更低更实的 drone A1 + A2
        add(L, drone(N["A1"], dur, 0.5, 0.8, 0.2), 0.0, 0.22)
        add(R, drone(N["A1"], dur, 0.5, 0.8, 0.18), 0.0, 0.22)
        add(L, drone(N["E3"], dur, 0.8, 1.0, 0.24), 0.0, 0.15)
        add(R, drone(N["E3"], dur, 0.8, 1.0, 0.22), 0.0, 0.15)
        # 低频 pulse（心跳式推进，每 1.9s 一次，轻）
        t = 1.6
        while t < dur - 1.5:
            p = pluck(N["A2"], 0.9)
            add(L, p, t, 0.22)
            add(R, p, t + 0.008, 0.22)
            t += 1.9
        # 中频拨弦点，略密
        plucks = [(1.0, "F3"), (3.4, "A3"), (5.6, "G3"), (7.8, "F3"),
                  (10.0, "A3"), (12.3, "E4"), (14.6, "F3"), (16.8, "G3")]
        for at, note in plucks:
            add(L, pluck(N[note], 1.4), at, 0.34)
            add(R, pluck(N[note], 1.4), at + 0.010, 0.31)
        # 偶尔一记低钟，压出紧迫
        for at in (4.5, 11.5, 17.2):
            b = bell(N["D4"], 2.6)
            add(L, b, at, 0.28)
            add(R, b, at + 0.012, 0.26)
        return to_stereo(L, R)

    if name == "final":
        # 守关 / 往生：低沉、带小二度隐忧，必须去掉终止感（结尾悬留，不解决到主音）
        dur = 25.0
        L = _buf(dur)
        R = _buf(dur)
        # 双层低声 C2 + G2（五度）+ 一点点 C3 小二度摩擦（极轻，暗示危险）
        add(L, drone(N["C2"], dur, 1.0, 1.4, 0.1), 0.0, 0.27)
        add(R, drone(N["C2"], dur, 1.0, 1.4, 0.12), 0.0, 0.27)
        add(L, drone(N["G2"], dur, 1.2, 1.6, 0.08), 0.0, 0.16)
        add(R, drone(N["G2"], dur, 1.2, 1.6, 0.10), 0.0, 0.16)
        # 低钟：密集分布在首 2/3，末段渐疏但不停在主音 → 无终止感
        lowbells = [(2.0, "C4", 0.42), (5.0, "G3", 0.38), (8.0, "C4", 0.40),
                    (11.0, "F3", 0.34), (14.0, "G3", 0.38), (17.0, "C4", 0.36),
                    (20.0, "E4", 0.30)]
        for at, note, amp in lowbells:
            b = bell(N[note], 3.6)
            add(L, b, at, amp)
            add(R, bell(N[note], 3.6), at + 0.014, amp * 0.9)
        # 高音点缀只在前中段，末段留白（悬留收尾）
        highbells = [(3.5, "C5", 0.26), (9.5, "G4", 0.24), (15.5, "A4", 0.22)]
        for at, note, amp in highbells:
            add(L, bell(N[note], 2.8), at, amp)
            add(R, bell(N[note], 2.8), at + 0.010, amp * 0.9)
        # 结尾 21-24s 只有 drone 淡出，不补终止音 → 轮回感
        return to_stereo(L, R)

    raise ValueError("unknown track: " + name)


def main():
    out_dir = sys.argv[1] if len(sys.argv) > 1 else "."
    for name in ("overworld", "outlaw", "final"):
        L, R = build_track(name)
        # 轻软限幅，去数字硬削
        for i in range(len(L)):
            L[i] = soft_clip(L[i])
            R[i] = soft_clip(R[i])
        path = f"{out_dir}/spr26_{name}.wav"
        secs = write_wav(path, L, R)
        print(f"[OK] {name}: {secs:.2f}s -> {path}")


if __name__ == "__main__":
    main()
