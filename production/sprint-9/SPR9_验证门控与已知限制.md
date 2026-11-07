# Sprint 9 验证门控与已知限制（预置标准）

> 来源：`SPR9-DIAG-02`（quality-lead 只读草案 + 守卫⑥修正段落），主理人 Phase 8 汇编登记，**未改写成员专业判断**。
> 状态：用户裁定路线 A「收口为已知限制」→ **本门控本次不启用**，转为未来重启整局确定性工作时的预置标准；其中 CRLF 规范化 / 剔除自证 / 退出码绑定 / 禁止剔除玩法行四条守卫，仍作为短帧门禁的自证标准保留。

## 一、E7/V16 转正门控

同 seed / 同构建 / 同帧数，**三次独立进程**日志两两 `cmp -s` 全空；1200 / 3000 / 9000 三档全过才转正。9 份日志 = 9 个独立引擎进程（非同进程续跑）；超时或未读日志记 `UNEXECUTED`，不记 PASS。

```bash
cd /d/Create/Game/test-1; G="D:/SteamLibrary/steamapps/common/Godot Engine/godot.windows.opt.tools.64.exe"; set -e
for N in 1200 3000 9000; do for R in 1 2 3; do
  rm -f /c/Users/TangUser/AppData/Roaming/Godot/app_userdata/test_1/_smoke_meta_*.cfg{,.bak}
  timeout 300000 env SMOKE=1 SMOKE_SEED=2 "$G" --headless --path . --quit-after $N > _tools/e7_${N}_${R}.log 2>&1
  tr -d '\r' < _tools/e7_${N}_${R}.log | grep -vE '^(ERROR: [0-9]+ resources still in use at exit|WARNING: [0-9]+ ObjectDB instances were leaked at exit)' > _tools/e7_${N}_${R}.norm
done; for P in "1 2" "1 3" "2 3"; do set -- $P; cmp -s _tools/e7_${N}_$1.norm _tools/e7_${N}_$2.norm && echo "PASS $N $1v$2" || echo "FAIL $N $1v$2"; done; done
```
（上方为草案原骨架；**实际执行必须以守卫⑥的分支脚本为准**，不能无条件剔行。）

## 二、允许剔除 / 禁止剔除

| 允许剔除（**仅**退出期，上界 2 行/份） | 精确前缀 | 前置自证 |
|-|-|-|
| ObjectDB 泄漏提示 | `^WARNING: [0-9]+ ObjectDB instances were leaked at exit` | 与待验证命令**同帧数 / 同 env / 同 seed** 的改前基线里 W=1 |
| 资源占用提示 | `^ERROR: [0-9]+ resources still in use at exit` | 同上 E=1；且须证明改前基线同样存在 |

实测：绝大多数最终日志每份恰好 2 行，顺序固定 **WARNING 在前、ERROR 在后**；数字逐次波动（9/13、3/4）不作判据。Sprint7 历史基线同样 2 行。`spr8_final_default.log`（600 帧全探针）噪声 = 0。

| 禁止剔除（命中即该轮无效） | 理由 |
|-|-|
| `[SMOKE-STALL]`、`[SMOKE-NAV]`、`[SMOKE] t=`、`spawned`、`kills`、`fingerprint`、`settle`、`run start`、`rng count`、`[SMOKE-LOOP]` | 全是玩法状态；坑 55「过滤 STALL 再判 PASS 是自欺」 |

## 三、守卫①–⑧

| # | 守卫 | 可执行判据 |
|-|-|-|
| ① | 补丁落地自证（坑 52/53/54） | 改前 `cp` 备份；改后 `md5sum scripts/*.gd` ≠ 备份；`grep -nF` 目标片段命中；`0 SCRIPT ERROR` **不作**通过证据 |
| ② | 退出码绑定（坑 53） | `set -e`；`patch.py && 跑游戏 && 比对` 串联，禁用换行分隔；`cmp -s` 退出码直接定 PASS/FAIL |
| ③ | 隔离档每轮清理（坑 50） | 每进程前 `rm -f <POSIX 路径>`；清理后 `ls .../_smoke_meta_*.cfg*` 无输出，否则该轮作废 |
| ④ | 日志干净态标注 | 每份标 `build=<md5前8> frames=N run=R seed=S`；逐份记 `SCRIPT ERROR`/`Parse Error`=0 与 `problems=0`=1；跑中 mtime 未变 |
| ⑤ | 反全量 diff 假 FAIL（坑 45） | E7 是同档同帧三比，不涉及楼层差；E1 回归仍按 floor 取交集，禁全量 diff |
| ⑥ | **剔除自证（修正版）** | 基线须同帧数 / 同 env / 同 seed，三档各自独立取，禁复用 600 帧全探针日志。`B = W + E`：`B==0` → **不剔除任何行**、直接对原始日志 `cmp -s`（三份同为 CRLF，更严），报告写「本轮未剔除，噪声 0」；`B==2` 且 `W==1,E==1` → 走统一 `tr -d '\r'` → `grep -vE` 流水线，`wc -l` 差值 == 2、玩法行 `grep -c` 在 `.norm` 中不减少；其它 B 值 → 守卫⑥失守，本轮数据无效须重跑 |
| ⑦ | 进程独立性 | 9 份日志 `path=` 行与 mtime 各异 |
| ⑧ | 超时 | 9000 帧 `timeout 300000`；超时不记 PASS |

守卫⑥分支脚本：
```bash
BL=_tools/e7_baseline_${N}.log
W=$(grep -cE '^WARNING: [0-9]+ ObjectDB instances were leaked at exit' "$BL" || true); E=$(grep -cE '^ERROR: [0-9]+ resources still in use at exit' "$BL" || true); B=$((W+E))
if [ "$B" -eq 0 ]; then MODE=raw; else [ "$W" -eq 1 ] && [ "$E" -eq 1 ] || { echo "GUARD6 VIOLATION W=$W E=$E"; exit 1; }; MODE=norm; fi
for R in 1 2 3; do if [ "$MODE" = norm ]; then tr -d '\r' < _tools/e7_${N}_${R}.log | grep -vE '^(WARNING: [0-9]+ ObjectDB instances were leaked at exit|ERROR: [0-9]+ resources still in use at exit)' > _tools/e7_${N}_${R}.norm; D=$(( $(wc -l < _tools/e7_${N}_${R}.log) - $(wc -l < _tools/e7_${N}_${R}.norm) )); [ "$D" -eq 2 ] || { echo "GUARD6 DROP=$D R=$R"; exit 1; }; fi; done
```

主理人实读核验：守卫⑥分支在现有日志上 5 份走 `norm`（W=1/E=1/B=2）、1 份走 `raw`（B=0），**无 VIOLATION**；CRLF 断言 `spr8_final_all.log` 59/59、`spr8_final_default.log` 55/55、`spr8_e1f_default.log` 304/304 全部成立。

## 四、回归包最小集（未来重启时用）

| 级别 | 项 | 判据 |
|-|-|-|
| 必跑 | 0 报错 + 两条 `%d` 格式串 | 判**源码** `validate.gd:46/48` 的 `%d` 字面串逐字不变（非日志填数行）；`SCRIPT ERROR`/`Parse Error`=0、`problems=0` |
| 必跑 | E1 共同楼层 | 两档 `SMOKE_META_FINGERPRINT=1` ± `SMOKE_META_UNLOCK=all`，按 floor 取交集，`E1_COMMON_PASS=True` |
| 必跑 | E8′/E8″ | 三入口 `randi() % maxi(n,1)`、空池无 `break`；两档 `rng count upgrades=60 relics=40 weapons=20` |
| 必跑 | 六种子 × 1200 帧 | 6/6 0 报错 + `problems=0` |
| 必跑 | 带窗口五页截图 | 去掉 `--headless`（headless 下 `get_viewport().get_texture()` 为 null）；5/5 PNG 非空 + 逐张实看 |
| 必跑 | 坏档 4 模式 | 各独立进程 + 各独立 `SMOKE_META_PATH`；各自专属 WARN + `corrupt fallback=OK` + 五件套 |
| 必跑 | 结算 / boost | `settle payout=28 balance=28` **仅带 override 时成立**；`boost remaining=3 → 2` |
| 必跑 | G8 / G9 / A3 | `SMOKE_MENU=1 SMOKE_MENU_PAGE=unlocks SMOKE_UI_CONFIRM=1`（坑 51 必带 page）+ 结算屏 / 升级面板截图实看 |
| 必跑 | 三条自检格式串 | `SMOKE_CONTRACT=1 SMOKE_REG=1 SMOKE_APPLY=1`；前缀逐字，数字由 `size()` 推导不作判据 |
| 必跑 | V11 零污染 | 玩家 `meta.cfg` 及 `.bak` 跑前跑后均不存在 |
| 可选 | 9000 帧六种子矩阵、死亡链路 / RG-6 / RG-7 / 局内存档往返、V8 空池显式用例、A3 2/3 预置档 | 与本改动无耦合，不计入放行阻塞 |

## 五、基线重定表模板（留空，不预填）

| 项 | 口径 | 改前 | 改后 | 允许变 |
|-|-|-|-|-|
| 三档 × 三对逐字 diff 行数、首个分叉行号 + 原文 | `cmp -s` | __ | __ | **必须全 0 / 填「无」** |
| `[SMOKE] t=` · `repro frame=150 time=` · 两档 `rng count` · 两条 `%d` 格式串 · 三条自检前缀 · E1 共同楼层 · 六种子 0 报错 · V11 | §14.4 / §8.3 / §14.5 | __ | __ | **不得变** |
| `settle payout/balance`（仅 override） | §14.4 | __ | __ | 不得变 |
| 退出期噪声行数字 N | 本就剔除 | __ | __ | 允许变 |
| 六种子日志具体内容 · `fingerprint rooms/kinds` · `Game.time` 派生量 | §14.4 E5 随机流前移 | __ | __ | **允许变，须重记新值** |

⚠️ 前置成本：三档「同帧数 / 同 env / 同 seed」的改前基线日志目前**一份都没有**，须先补 9 份基线 + 9 份验证日志。

## 六、质量门判定与「不误导四禁令」

| 判定 | 条件 | 用户表述 |
|-|-|-|
| PASS | 必跑全过 + 三档 9 对 diff 全空 + 守卫①–⑧全自证 | 「E7/V16 转正：1200/3000/9000 三档 × 三次独立进程整局逐字复现成立」 |
| CONCERNS | 必跑全过但仅部分档/部分对为空，或某守卫仅凭推断未实读 | 「E7/V16 仍为信息性：仅 X 档 Y 对为空；其余首个分叉第 N 行 <原文>，未达转正」；禁写「已复现 / 基本通过 / 约 90% 收敛」 |
| FAIL | 任一必跑挂，或守卫①②③⑥失守，或三档全非空 | 「E7/V16 未转正（不影响其余交付放行）」+ 列阻塞项 |

**不误导四禁令**：① 信息性 ≠ 通过，逐对给实测 diff 行数 + 首个分叉原文，不给百分比；② 剔除后为空 ≠ 整局可复现，须同时写「剔了什么 + 改前基线同样存在」的证明；③ 不引 `--fixed-fps` 作证据（坑 55/56）；④ 不用 `TOTAL_ERRORS=0` 代替逐字判据（坑 54）。

**本次结论**：按用户裁定路线 A，本门控**不启用**；E7/V16 在 QA v4.7 §14.3 / §14.7 正式长期降级为「已知限制，不设逐字门禁」。
