extends PrismWarden
## Sprint 12 C：第二主题 Boss「熔潮主宰 / Pyrothalassian」（§6.1）。
## 复用 PrismWarden 状态机骨架（INTRO→ACTIVE→PHASE_2→PHASE_3→DYING、全 FIXED_DT）；
## 差异化（§6.1）：主题序列偏移 +4（另一组三阶段组合）、脉冲更密（2.2s）、
## 外观数据驱动（core tint = 阶段一主题 tint）。

var _theme_offset := 4


func _init() -> void:
	# Sprint 15 A 补强：默认值在 setup 之前就正确（.new() 即生效，防 setup 异常落回基类默认）
	codex_id = "pyrothalassian"


func setup(floor_num: int) -> void:
	# 核验 #5 修复：身份补齐（此前 DUMP/结算残留守望者字段）
	boss_name = "熔潮主宰"
	variant = "boss"   # 击杀走 Boss 掉落路径（宝箱），stairs 由 _room_cleared 发放
	codex_id = "pyrothalassian"   # Sprint 14 A：图鉴登记与掉落契约解耦（variant 不动——曾把「巨岩虫之王」误登记）
	_floor_num = floor_num
	_phase_rules = []
	_phase_tints = []
	for k in 3:
		# 主题序列偏移 +4：与守望者错开组合（§6.1 ①）
		var key := phase_theme_index(floor_num + _theme_offset, k)
		_phase_rules.append(String(Data.FLOOR_THEMES[key]["rule"]))
		_phase_tints.append(Data.FLOOR_THEMES[key]["tint"])
	max_hp = 360.0 * (1.0 + (floor_num - 4) * 0.12)
	hp = max_hp
	skill_interval = 2.2   # DoT/压迫更密（§6.1 ②）
	if core != null:
		core.modulate = _phase_tints[0]   # 外观数据驱动（§6.1 ③）


func _enter_phase(k: int) -> void:
	super._enter_phase(k)
	if core != null:
		core.modulate = _phase_tints[k]
