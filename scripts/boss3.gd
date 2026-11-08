extends PrismWarden
## Sprint 15 A：第三主题 Boss「玄渊之主」（F2 解绑候选，§4.3）。
## 复用 PrismWarden 状态机骨架（INTRO→ACTIVE→PHASE_2→PHASE_3→DYING、全 FIXED_DT）；
## 差异化：主题序列偏移 +2（warden=0 / boss2=4 / 本=2，不改 %8 周期函数）、
## 脉冲 2.6s（介于 warden 3.0 与 boss2 2.2 之间）、外观数据驱动（阶段 tint）。
## 身份铁律（Sprint 14 A 教训）：variant="boss" 保住宝箱/词缀必掉/震屏三条掉落契约，
## 图鉴登记走 codex_id（"third_boss"）——防 variant 撞名误登记。

var _theme_offset := 2


func _init() -> void:
	# Sprint 15 A 补强：默认值在 setup 之前就正确（.new() 即生效——防 setup 中途异常时
	# 落回基类默认 "prism_warden" 造成跨 Boss 误登记；不能重声明成员，用 _init 覆写）
	codex_id = "third_boss"


func setup(floor_num: int) -> void:
	boss_name = "玄渊之主"
	variant = "boss"   # 击杀走 Boss 掉落路径（宝箱/词缀必掉/震屏），stairs 由 _room_cleared 发放
	codex_id = "third_boss"   # 图鉴专用 id：CODEX_BOSS_NAMES 单源派生白名单/分母/显示名
	_floor_num = floor_num
	_phase_rules = []
	_phase_tints = []
	for k in 3:
		# posmod 包正：SMOKE_FORCE_THIRD_BOSS 可在低层强制生成本 Boss，offset=2 时
		# (floor+2-4+k) 可为负，C-style % 会取负 → FLOOR_THEMES 键越界（首跑实证）；
		# 正常层（27+）两式等价，本改动零共享代码、零 E1 影响
		var key := 4 + posmod(floor_num - 4 + _theme_offset + k, 8)
		_phase_rules.append(String(Data.FLOOR_THEMES[key]["rule"]))
		_phase_tints.append(Data.FLOOR_THEMES[key]["tint"])
	max_hp = 360.0 * (1.0 + (floor_num - 4) * 0.12)
	hp = max_hp
	skill_interval = 2.6   # 脉冲密度介于守望者与熔潮之间（§4.3）
	if core != null:
		core.modulate = _phase_tints[0]


func _enter_phase(k: int) -> void:
	super._enter_phase(k)
	if core != null:
		core.modulate = _phase_tints[k]
