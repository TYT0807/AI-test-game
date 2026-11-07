# Sprint 10 交付（首批）：分辨率选项

> 日期：2026-11-07｜依据 `SPR10_规划草案.md` §四｜分工：编程侧（规划侧只读）
> 改动文件：`scripts/game_state.gd`、`scripts/menu.gd`

## 一、改了什么

1. **`game_state.gd`**
   - settings 新增 `"resolution"`（"宽x高" 字符串，仅窗口模式生效）与 `"window_mode"`（0 窗口 / 1 全屏·独占 / 2 无边框全屏）两键，复用既有 `user://settings.cfg` ConfigFile（未另起炉灶，遵守锚点纠正）
   - 新增 `RESOLUTION_PRESETS`（1280x720 / 1600x900 / 1920x1080 / 2560x1440）与 `WINDOW_MODES`（窗口/全屏/无边框全屏）常量
   - `apply_settings()` 拆出 `_apply_window_settings()`：模式切换（WINDOWED / EXCLUSIVE_FULLSCREEN / FULLSCREEN）+ 窗口尺寸调整 + 屏幕居中；**headless 下直接跳过**（DisplayServer 为 dummy）；`[SMOKE-WIN]` 探针输出实际 OS 窗口尺寸
2. **`menu.gd`**
   - 新增 `_add_option(label, key, values, labels)` 下拉辅助（OptionButton，切换即 `_set_setting` 应用+保存）
   - 设置页新增「分辨率」「窗口模式」两行下拉，存储值不在预设内时回退首项

**架构说明（UI 自适应）**：项目本就是 `canvas_items` 拉伸 + `keep` 比例——逻辑分辨率恒 1280x720，改 OS 窗口尺寸只是等比缩放内容，全部 UI（HUD/菜单/小地图）本就锚点化，无需逐控件改造。已按规格第 3 点做实测确认而非改造。

## 二、验证了什么（全部实跑）

| 项 | 结果 |
|-|-|
| 语法/自检/编译扫描（headless 300 帧） | 0 报错；29/29 扫描通过；自检通过 |
| **真实窗口尺寸**（窗口运行，cfg 预置 1600x900） | `[SMOKE-WIN] mode=0 resolution=1600x900 os_size=(1600, 900)` ✓ |
| 1600x900 下 UI 布局截图 | `D:\Create\Game\_tools\dungeon_shot_0.png`（绝对路径，存在性 2026-11-07 实查）：HUD/小地图/技能条/提示行无错位 |
| 底部提示行 | 动态生成路径与重绑联动正常（显示完整动作标签） |
| 组合回归（SMOKE+V8+REBIND，3000 帧） | 0 报错；V8/REBIND/自检 全过 |
| 冻结清单 | 重定 29/29 OK（`_backup/pre_res/settings.cfg.pre_test` 存测试前设置档） |
| 测试残留 | 验证用 settings.cfg 已恢复默认 1280x720 |

## 三、设计取舍记录

- 「全屏」用 `EXCLUSIVE_FULLSCREEN`（真独占），「无边框全屏」用 `FULLSCREEN`（Godot 4 的 FULLSCREEN 本身即无边框）——两者语义不同，都给了
- 分辨率只影响 OS 窗口尺寸，不触碰逻辑分辨率与 E1 指纹/E6 固定步（规划侧预判正确，零随机流纠缠）
- 窗口改尺寸后自动居中到当前屏幕

## 四、独立复核指引（针对「实施侧自证」项）

窗口尺寸探针 `(1600,900)` 来自**窗口运行**（headless 下 `_apply_window_settings` 在 guard 处 return，该探针根本不会打印）——因此任何**带显示器的会话**都能一条命令复现，不依赖实施侧自证：

```bash
# ① 预置分辨率（写 user://settings.cfg，路径 C:\Users\<用户>\AppData\Roaming\Godot\app_userdata\test_1\）
CFG="$APPDATA/Godot/app_userdata/test_1/settings.cfg"
sed -i 's/^resolution=.*/resolution="1600x900"/' "$CFG"   # 首次无此行则 sed 后手动插入 [settings] 段下
# ② 窗口运行（关键：不能加 --headless），看 [SMOKE-WIN] 行
SMOKE=1 "D:\SteamLibrary\steamapps\common\Godot Engine\godot.windows.opt.tools.64.exe" --path . res://scene/game.tscn --quit-after 240
# 期望：[SMOKE-WIN] mode=0 resolution=1600x900 os_size=(1600, 900)
# ③ 恢复默认
sed -i 's/^resolution=.*/resolution="1280x720"/' "$CFG"
```

headless 会话（如某些子会话）无法复现此项属预期——dummy DisplayServer 连窗口都不存在；此时该项维持「实施侧窗口运行自证」状态，不降级不升级。

**证据路径争议——最终勘误（第三版，替换前两版互相矛盾的结论）**：两轮交叉核验各执一词的根因已实查清楚——**项目里有两棵 `_tools` 树**：

| 树 | 归属 | 内容 |
|-|-|-|
| `D:\Create\Game\_tools\` | 编程侧（本会话，项目外） | `dungeon_shot_0.png`（1600x900 布局证据）、`dungeon_shot_upgrade_1/2.png`（A3 证据）——**均真实存在** |
| `D:\Create\Game\test-1\_tools\shots_*\`（10 组） | 运行/复核会话（项目树内） | 各 22 帧的 `dungeon_shot_N.png` 系列 + `.import`（另一会话自己的截图探针产物） |

复核侧 10:33/10:39 的 `find` 与编程侧的 `ls` **各自都对**——前者搜索根覆盖项目树、后者覆盖项目外的 `Game/_tools`；双方错在把「自己的树里没有/有」泛化成全局结论。1600x900 的布局证据在**编程侧树**，`shots_*` 系列是**复核侧树**里另一会话自己的产物，两者不是同一批文件。

**结构性修复（本轮已落）**：
1. `test-1/_tools/` 加入 `.gdignore`——该项目树目录此前被 Godot 导入（`.godot/imported` 已积累 342 条 dungeon_shot 缓存），入 .gdignore 后不再导入，截图证据原地保留
2. **证据路径规范（即时生效）**：交付/交接文档引用证据一律写**绝对路径**；树归属见上表
3. 后续新截图探针统一写 `D:\Create\Game\_tools\`（项目外），杜绝再进 res://

## 五、还剩什么

- Sprint 10 后续（待规划侧排期）：F4 主题地形（小字段）→ F3 敌人编队（指纹隔离）→ F2 主动遗物（需输入表定稿）
- 已知边界：全屏模式下分辨率下拉不生效（由系统接管）——UI 上两行相邻，行为符合预期
