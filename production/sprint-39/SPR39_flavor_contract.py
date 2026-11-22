#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""SPR39 手记↔机制静态门（一张表 + 一个扫描器）

AGENTS §4「别为文案建复杂系统」的守线版：不建解析框架、不做运行时校验、不加 action、
不新增探针类别。范式是盘上既有做法的第三次复用——
  validate.gd _check_daily()     ：FileAccess.get_file_as_string + 源码字符串锁定
  validate.gd _check_apply_ids() ：池 id ↔ apply 分支交叉校验
本件把同一手法对准 FLAVOR（本作唯一成体系的「玩家可读到承诺」文本层）。

用法：
    python production/sprint-39/SPR39_flavor_contract.py            # 跑五道门，期望 exit 0
    python production/sprint-39/SPR39_flavor_contract.py --selftest # 三把变异刀，期望每把都让门变红

口径来源：SPR39_设计实稿_手记只说玩家观测得到的事.md §5；验收靶：SPR39_验证口径.md V-C。
纯标准库、零依赖、零写盘（--selftest 只在内存副本上弯刀，⛔ 改磁盘）。
"""

import copy
import io
import json
import os
import re
import sys

HERE = os.path.dirname(os.path.abspath(__file__))
ROOT = os.path.normpath(os.path.join(HERE, "..", ".."))
DATA_GD = os.path.join(ROOT, "scripts", "data.gd")
TABLE = os.path.join(HERE, "SPR39_对照表.json")

QUOTE = chr(34)
ENTRY_RE = None  # set below


def _entry_pattern():
    return QUOTE + r"([a-z]+/[A-Za-z0-9_]+)" + QUOTE + r"\s*:\s*" + QUOTE + r"([^" + QUOTE + r"]*)" + QUOTE


def read_text(path):
    with io.open(path, "r", encoding="utf-8") as f:
        return f.read()


def parse_flavor(src):
    """从 data.gd 抠出 FLAVOR 字面量（括号配平 + 字符串态机），返回 [(key, value)] 有序表。"""
    m = re.search(r"const FLAVOR := \{", src)
    if not m:
        raise SystemExit("G-0 致命：data.gd 找不到 `const FLAVOR := {`（表被改名或挪走）")
    start = m.end()
    depth = 1
    i = start
    in_str = False
    esc = False
    while i < len(src):
        ch = src[i]
        if in_str:
            if esc:
                esc = False
            elif ch == "\\":
                esc = True
            elif ch == QUOTE:
                in_str = False
        else:
            if ch == QUOTE:
                in_str = True
            elif ch == "{":
                depth += 1
            elif ch == "}":
                depth -= 1
                if depth == 0:
                    break
        i += 1
    block = src[start:i]
    return re.findall(_entry_pattern(), block)


def strip_comment_lines(text):
    """整行注释剔除：needle 只认真代码。否则注释里残留的旧词（例：`# 原写「弹匣留一半」`）
    会把 G-2 喂饱——那就是本项目吃过的「前提守卫型恒过」在文案面上的翻版。"""
    return "\n".join(l for l in text.splitlines() if not l.strip().startswith("#"))


class Gate(object):

    def __init__(self):
        self.failures = []
        self.counts = {"g1": 0, "g2": 0, "g3": 0, "g4": 0, "g5": 0, "g6": 0}

    def fail(self, code, msg):
        self.failures.append("%s | %s" % (code, msg))

    def run(self, pairs, table, sources, expect_count):
        by_key = {}
        for k, v in pairs:
            by_key[k] = v
        rows = table["rows"]
        table_keys = set(r["key"] for r in rows)
        disk_keys = set(by_key.keys())

        # ---------- G-1 条数与键集（防「加了没登记 / 删了没同步」）----------
        if len(pairs) != expect_count:
            self.fail("G-1", "FLAVOR 条数 %d != 基准 %d（改条数须回主理人——player._floor_sign_probe 有同数死断言）"
                      % (len(pairs), expect_count))
        for k in sorted(disk_keys - table_keys):
            self.fail("G-1", "手记 %s 未登记进对照表＝吹出去没人验" % k)
        for k in sorted(table_keys - disk_keys):
            self.fail("G-1", "对照表有 %s 但 data.gd 没有＝表比正文长，删了没同步" % k)
        self.counts["g1"] = len(rows)

        # ---------- G-2 anchors 必须在非注释行命中（空承诺的直接证伪）----------
        for r in rows:
            for a in r.get("anchors", []):
                f = a["file"]
                needle = a["needle"]
                body = sources.get(f)
                if body is None:
                    self.fail("G-2", "%s 的锚点文件读不到：%s" % (r["key"], f))
                    continue
                hits = strip_comment_lines(body).count(needle)
                self.counts["g2"] += 1
                need = int(a.get("min_hits", 1))
                if hits < need:
                    self.fail("G-2", "%s 承诺了磁盘上不存在的东西：needle `%s` 在 %s 的非注释行命中 %d（要求 >=%d）"
                              % (r["key"], needle, f, hits, need))

        # ---------- G-3 text 逐字对账（本轮五连错的成因就是没人做这步）----------
        for r in rows:
            k = r["key"]
            if k not in by_key:
                continue
            self.counts["g3"] += 1
            if r["text"] != by_key[k]:
                self.fail("G-3", "%s 文案漂移：表里[%s] / data.gd[%s]" % (k, r["text"], by_key[k]))

        # ---------- G-4 禁用串全局扫（不只该行——撞车都是跨行发生的）----------
        joined = "\n".join(v for _, v in pairs)
        subs = set(table.get("forbidden_global", []))
        for r in rows:
            for s in r.get("forbidden_substrings", []):
                subs.add(s)
        for s in sorted(subs):
            self.counts["g4"] += 1
            n = joined.count(s)
            if n > 0:
                self.fail("G-4", "禁用串 `%s` 仍出现在 %d 处手记 value 里（空承诺回流／专名泄漏）" % (s, n))
        for phrase, owner in table.get("reserved_phrases", {}).items():
            self.counts["g4"] += 1
            if joined.count(phrase) > 0:
                self.fail("G-4", "保留措辞 `%s` 专属 %s，却出现在手记里——同一句玩家规矩被三方引用两个实现的老病根"
                          % (phrase, owner))

        # ---------- G-5 改写后的句子必须含可观测落点（V-A2/A5/A6/V-A7 范本保护）----------
        for mc in table.get("must_contain", []):
            v = by_key.get(mc["key"], "")
            self.counts["g5"] += 1
            if v == "":
                continue
            ok_all = all(s in v for s in mc.get("all", []))
            ok_any = (any(s in v for s in mc["any"]) if mc.get("any") else True)
            if not (ok_all and ok_any):
                self.fail("G-5", "%s 的新文案缺可观测落点：要求 all=%s any=%s，实得[%s]"
                          % (mc["key"], mc.get("all"), mc.get("any", "-"), v))

        # ---------- G-6 格式硬约束（menu.gd 用全角空格 join 同一行，句号是唯一断句手段）----------
        # 🔴 长度上限**只压本批改写的行**：现存最长 `shrine/purify`＝31 字（两个句号的分句体），
        #    为凑一个统一数字去缩它，等于在本批里顺手改一条没毛病的文案——churn 面扩大、
        #    且它被 S26 那批的逐字上屏断言链着。故按行 override，不放宽全局上限。
        cap = int(table.get("meta", {}).get("max_text_len", 0))
        for r in rows:
            v = by_key.get(r["key"], "")
            if not v:
                continue
            self.counts["g6"] += 1
            if not v.endswith(u"。"):
                self.fail("G-6", "%s 不以句号收尾——图鉴多条目并排时会黏成一坨" % r["key"])
            row_cap = int(r.get("max_len_override", cap))
            if row_cap and len(v) > row_cap:
                self.fail("G-6", "%s 长度 %d 超上限 %d（灰字两行、满格 10 条时长句挤掉后续条目）"
                          % (r["key"], len(v), row_cap))
        return self


def load_sources(table, data_src):
    files = set()
    for r in table["rows"]:
        for a in r.get("anchors", []):
            files.add(a["file"])
    out = {"scripts/data.gd": data_src}
    for f in sorted(files):
        p = os.path.join(ROOT, f.replace("/", os.sep))
        out[f] = read_text(p) if os.path.exists(p) else None
    return out


def evaluate(pairs, table, sources, expect_count):
    return Gate().run(pairs, table, sources, expect_count)


# ---------------- 三把变异刀（--selftest）----------------
def bend_k1(table):
    """silent 的锚点指向一个磁盘上不存在的函数名 → G-2 必须红。"""
    hit = False
    for r in table["rows"]:
        if r["key"] == "themes/silent":
            for a in r["anchors"]:
                if a["needle"] == "set_minimap_hidden":
                    a["needle"] = "set_minimap_visible"
                    hit = True
    return hit


def bend_k2(pairs):
    """pressure 漂回旧句「子弹会拐弯」→ G-3 必须红（同时该串在 forbidden 里，G-4 也应红）。"""
    hit = False
    for idx, (k, v) in enumerate(pairs):
        if k == "themes/pressure":
            pairs[idx] = (k, u"高压层。修罗斗诤，子弹会拐弯，贴墙打。")
            hit = True
    return hit


def bend_k3(pairs):
    """往 prism_warden 塞回「光缝」→ G-4 必须红。"""
    hit = False
    for idx, (k, v) in enumerate(pairs):
        if k == "bosses/prism_warden":
            pairs[idx] = (k, u"守望者。天道之眼，别站在光缝里。")
            hit = True
    return hit


KNIVES = [
    ("K1 锚点改成不存在的实现（themes/silent）", bend_k1, "g2", lambda t, p, s: bend_k1(t)),
    ("K2 文案漂回旧句（themes/pressure 含『子弹会拐弯』）", bend_k2, "g3", lambda t, p, s: bend_k2(p)),
    ("K3 禁用串回流（bosses/prism_warden 塞『光缝』）", bend_k3, "g4", lambda t, p, s: bend_k3(p)),
]


def selftest(table, pairs, sources, expect_count):
    print("== SPR39 flavor contract selftest（三把刀都必须让门变红）==")
    dead = 0
    for name, _bender, _expect_code, apply_bend in KNIVES:
        t2 = copy.deepcopy(table)
        p2 = list(pairs)
        if not apply_bend(t2, p2, sources):
            print("[DEAD] %s —— 刀没落上（目标行不存在），判 INCOMPLETE" % name)
            dead += 1
            continue
        g = evaluate(p2, t2, sources, expect_count)
        codes = sorted(set(f.split(" |")[0] for f in g.failures))
        if g.failures:
            print("[OK ] %s -> failures=%d codes=%s" % (name, len(g.failures), ",".join(codes)))
        else:
            print("[DEAD] %s -> failures=0 门是假的！" % name)
            dead += 1
    if dead:
        print("SELFTEST FAIL: %d/3 把刀没变红 —— INCOMPLETE，不许当 PASS 报" % dead)
        return 1
    print("SELFTEST OK: 3/3 把刀都变红（还原后请再跑一次正式门确认绿）")
    return 0


def main():
    data_src = read_text(DATA_GD)
    pairs = parse_flavor(data_src)
    table = json.loads(read_text(TABLE))
    meta = table.get("meta", {})
    expect_count = int(meta.get("expected_flavor_count", 74))
    sources = load_sources(table, data_src)

    if "--selftest" in sys.argv:
        return selftest(table, pairs, sources, expect_count)

    g = evaluate(pairs, table, sources, expect_count)
    if g.failures:
        print("========== 手记↔机制对照门失败（%d 项）==========" % len(g.failures))
        for f in g.failures:
            print("  x " + f)
        print("==============================================")
        return 1
    c = g.counts
    print("flavor contract: ok rows=%d g1=%d g2=%d g3=%d g4=%d g5=%d g6=%d"
          % (len(table["rows"]), c["g1"], c["g2"], c["g3"], c["g4"], c["g5"], c["g6"]))
    return 0


if __name__ == "__main__":
    sys.exit(main())
