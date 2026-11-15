#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""BGM 频段分布测量（纯标准库 FFT）。配套 `spr26_bgm_synth.py`。

【用途】把「好不好听」里可客观化的那部分测出来：频谱重心、各频段能量占比。
它不能替代人耳（人耳验收见 `SPR26_音频验收_用户实测.md`），但能挡住
「一层低频嗡嗡」这类结构性失衡——v1 就是这么查出来的。

【用法】
    python spr26_bgm_probe.py --selftest          # 先验证分析器本身对不对
    python spr26_bgm_probe.py <wav目录或单个wav>   # 测量

【判读基准（S26 三首实测）】
    主世界 重心 437Hz / 中400-1.2k -6.7dB / 中高1.2-4k -15.9dB
    亡命徒 重心 144Hz / -11.1dB / -20.6dB
    守关   重心 172Hz /  -9.8dB / -18.8dB
中频比低频低 7–11dB 属正常音乐区间；若又退回「低 12dB 以上 + 重心 <220Hz」，就是混音失衡。

🔴 立体声必须降混。按单声道解读交错采样会让时长翻倍、频段全错（踩过一次，结果作废重测）。
"""
import wave, math, struct, os, sys

def load(path, decim=4):
    w = wave.open(path, "rb")
    nch = w.getnchannels()
    raw = w.readframes(w.getnframes()); w.close()
    d = struct.unpack("<%dh" % (len(raw)//2), raw)
    if nch > 1:                       # 立体声先降混，否则交错采样会把长度翻倍
        mono = []
        for i in range(0, len(d), nch):
            mono.append(sum(d[i:i+nch]) / nch)
        d = mono
    out = []; acc = 0; s = 0
    for v in d:
        acc += v; s += 1
        if s == decim:
            out.append(acc/decim); acc = 0; s = 0
    return [v/32768.0 for v in out], 44100//decim

def fft(re, im):
    n = len(re); j = 0
    for i in range(1, n):
        bit = n >> 1
        while j & bit: j ^= bit; bit >>= 1
        j |= bit
        if i < j:
            re[i], re[j] = re[j], re[i]; im[i], im[j] = im[j], im[i]
    ln = 2
    while ln <= n:
        a = -2*math.pi/ln; wr = math.cos(a); wi = math.sin(a)
        for i in range(0, n, ln):
            cr = 1.0; ci = 0.0; h = ln >> 1
            for k in range(h):
                ur = re[i+k]; ui = im[i+k]
                vr = re[i+k+h]*cr - im[i+k+h]*ci; vi = re[i+k+h]*ci + im[i+k+h]*cr
                re[i+k] = ur+vr; im[i+k] = ui+vi
                re[i+k+h] = ur-vr; im[i+k+h] = ui-vi
                nc = cr*wr - ci*wi; ci = cr*wi + ci*wr; cr = nc
        ln <<= 1

BANDS = [(0, 40, "次低<40"), (40, 150, "低40-150"), (150, 400, "中低150-400"),
         (400, 1200, "中400-1.2k"), (1200, 4000, "中高1.2-4k"), (4000, 6000, "高>4k")]

def measure(path, N=2048, HOP=1024):
    x, sr = load(path)
    win = [0.5 - 0.5*math.cos(2*math.pi*i/(N-1)) for i in range(N)]
    acc = {b[2]: 0.0 for b in BANDS}; cent = []; i = 0
    while i + N <= len(x):
        seg = x[i:i+N]
        re = [seg[k]*win[k] for k in range(N)]; im = [0.0]*N
        fft(re, im)
        m = [math.hypot(re[k], im[k]) for k in range(N//2)]
        for lo, hi, name in BANDS:
            s = 0.0
            for k in range(1, N//2):
                f = k*sr/N
                if lo <= f < hi: s += m[k]*m[k]
            acc[name] += s
        num = sum(k*sr/N*m[k] for k in range(1, N//2)); den = sum(m[k] for k in range(1, N//2))
        if den > 1e-9: cent.append(num/den)
        i += HOP
    tot = sum(acc.values()) or 1e-12
    cent.sort()
    return acc, tot, (cent[len(cent)//2] if cent else 0), len(x)/sr

def show(path, label):
    acc, tot, c, dur = measure(path)
    print("=== %s  (%.2fs) ===" % (label, dur))
    for lo, hi, name in BANDS:
        r = max(acc[name], 1e-14)/tot
        print("   %-12s %7.1f dB" % (name, 10*math.log10(r) if r > 0 else -999))
    print("   频谱重心中位数 %.0f Hz" % c)

def selftest():
    """440Hz 正弦必须落在「中 400-1.2k」≈0.0 dB、重心 ≈441Hz。不过就别拿测量结果下结论。"""
    import tempfile
    p = os.path.join(tempfile.gettempdir(), "_bgm_probe_selftest.wav")
    w = wave.open(p, "wb"); w.setnchannels(1); w.setsampwidth(2); w.setframerate(44100)
    n = 44100*2
    w.writeframes(b"".join(struct.pack("<h", int(16000*math.sin(2*math.pi*440*t/44100))) for t in range(n)))
    w.close()
    acc, tot, c, _ = measure(p)
    print("[自检] 440Hz 正弦：")
    ok = True
    for lo, hi, name in BANDS:
        r = max(acc[name], 1e-14)/tot
        v = 10*math.log10(r) if r > 0 else -999
        print("   %-12s %7.1f dB" % (name, v))
        if lo == 400 and v < -3: ok = False
        if hi <= 400 and v > -30: ok = False
    print("   重心 %.0f Hz" % c)
    ok = ok and 430 <= c <= 452
    print("   判定：%s" % ("PASS" if ok else "FAIL —— 分析器不可信，勿据此下结论"))
    os.remove(p)
    return 0 if ok else 1

if __name__ == "__main__":
    if len(sys.argv) < 2 or sys.argv[1] == "--selftest":
        sys.exit(selftest())
    tgt = sys.argv[1]
    if os.path.isfile(tgt):
        show(tgt, os.path.basename(tgt))
    else:
        for fn, label in [("spr26_overworld.wav", "主世界"), ("spr26_outlaw.wav", "亡命徒"), ("spr26_final.wav", "守关/终局")]:
            p = os.path.join(tgt, fn)
            if os.path.exists(p): show(p, label)
