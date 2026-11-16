extends Node
## 数据注册表：敌人数值、楼层刷怪池、精英/Boss 分配、词缀、房间元信息、障碍物。
## 新增内容只改这里 + 一张贴图，避免散落的魔法数。

## atlas="slug" 用游魂聚合体图集（row 行号）；tex= 用 resources/texture/monsters/ 下的贴图
const ENEMIES := {
	# ---------- 游魂聚合体（保留本体） ----------
	"rusher": {"name": "红虫", "atlas": "slug", "row": 0, "ai": "chase",
		"hp": 3.0, "speed": 55.0, "dmg": 1, "xp": 1, "score": 10, "scale": 1.0},
	"brute": {"name": "黑甲虫", "atlas": "slug", "row": 1, "ai": "chase",
		"hp": 14.0, "speed": 34.0, "dmg": 2, "xp": 3, "score": 30, "scale": 1.15},
	"spitter": {"name": "紫酸虫", "atlas": "slug", "row": 2, "ai": "spitter",
		"hp": 5.0, "speed": 42.0, "dmg": 1, "xp": 2, "score": 20, "scale": 1.0},
	"bomber": {"name": "自爆虫", "atlas": "slug", "row": 4, "ai": "bomber",
		"hp": 4.0, "speed": 80.0, "dmg": 0, "xp": 2, "score": 25, "scale": 0.95},
	"elite": {"name": "巨岩虫", "atlas": "slug", "row": 3, "ai": "chase",
		"hp": 46.0, "speed": 27.0, "dmg": 3, "xp": 8, "score": 120, "scale": 1.5},
	"boss": {"name": "巨岩虫之王", "atlas": "slug", "row": 3, "ai": "boss",
		"hp": 240.0, "speed": 26.0, "dmg": 3, "xp": 20, "score": 1000, "scale": 2.4},
	"splitter": {"name": "分裂虫", "atlas": "slug", "row": 0, "ai": "chase", "split": "mini",
		"hp": 6.0, "speed": 48.0, "dmg": 1, "xp": 3, "score": 40, "scale": 1.1},
	"mini": {"name": "幼体", "atlas": "slug", "row": 0, "ai": "chase",
		"hp": 1.2, "speed": 78.0, "dmg": 1, "xp": 1, "score": 5, "scale": 0.6},

	# ---------- 公共素材怪物（Tiny Creatures，CC0） ----------
	"goblin": {"name": "地精", "tex": "goblin", "ai": "chase",
		"hp": 3.5, "speed": 62.0, "dmg": 1, "xp": 1, "score": 12, "scale": 0.95,
		"desc": "又快又脆，成堆出现"},
	"skeleton": {"name": "骷髅兵", "tex": "skeleton", "ai": "chase",
		"hp": 5.0, "speed": 48.0, "dmg": 1, "xp": 2, "score": 16, "scale": 1.0,
		"desc": "标准杂兵"},
	"zombie": {"name": "腐尸", "tex": "zombie", "ai": "chase",
		"hp": 11.0, "speed": 26.0, "dmg": 2, "xp": 3, "score": 28, "scale": 1.05,
		"desc": "慢，但很耐打"},
	"orc": {"name": "兽人", "tex": "orc", "ai": "chase",
		"hp": 15.0, "speed": 36.0, "dmg": 2, "xp": 3, "score": 34, "scale": 1.1},
	"imp": {"name": "小鬼", "tex": "imp", "ai": "erratic",
		"hp": 3.0, "speed": 70.0, "dmg": 1, "xp": 1, "score": 14, "scale": 0.85,
		"desc": "走位飘忽"},
	"wraith": {"name": "怨灵", "tex": "wraith", "ai": "spitter", "float": true,
		"hp": 7.0, "speed": 40.0, "dmg": 1, "xp": 2, "score": 22, "scale": 1.0,
		"desc": "穿箱飘行，远程吐息"},
	"flameskull": {"name": "火骷髅", "tex": "flameskull", "ai": "turret",
		"hp": 6.0, "speed": 0.0, "dmg": 1, "xp": 2, "score": 20, "scale": 1.0,
		"desc": "原地喷火，先拆"},
	"faerie": {"name": "妖精", "tex": "faerie", "ai": "erratic", "float": true,
		"hp": 3.5, "speed": 76.0, "dmg": 1, "xp": 2, "score": 18, "scale": 0.8},
	"vampire": {"name": "吸血鬼", "tex": "vampire", "ai": "leap", "drain": true,
		"hp": 10.0, "speed": 44.0, "dmg": 2, "xp": 4, "score": 40, "scale": 1.05,
		"desc": "突进并回血"},
	"plant": {"name": "食人花", "tex": "plant", "ai": "turret",
		"hp": 12.0, "speed": 0.0, "dmg": 2, "xp": 4, "score": 38, "scale": 1.1,
		"desc": "扎根不动，喷酸"},
	"mush": {"name": "蘑菇人", "tex": "mush", "ai": "summon",
		"hp": 9.0, "speed": 24.0, "dmg": 1, "xp": 4, "score": 44, "scale": 1.0,
		"desc": "不断放孢子幼体"},
	"slime": {"name": "史莱姆", "tex": "slime", "ai": "chase", "split": "mini",
		"hp": 7.0, "speed": 32.0, "dmg": 1, "xp": 2, "score": 18, "scale": 0.95,
		"desc": "死亡分裂"},
	"wolf": {"name": "狼", "tex": "wolf", "ai": "leap",
		"hp": 5.0, "speed": 52.0, "dmg": 1, "xp": 2, "score": 20, "scale": 1.0,
		"desc": "蓄力扑咬"},

	# ---------- 精英 ----------
	"knight": {"name": "盾骑士", "tex": "knight", "ai": "chase", "armor": 0.7,
		"hp": 20.0, "speed": 34.0, "dmg": 3, "xp": 7, "score": 110, "scale": 1.35,
		"desc": "正面减伤，绕后打"},
	"ogre": {"name": "食人魔", "tex": "ogre", "ai": "chase", "armor": 0.85,
		"hp": 52.0, "speed": 26.0, "dmg": 4, "xp": 10, "score": 150, "scale": 1.5,
		"desc": "厚甲近战"},
	"minotaur": {"name": "牛头人", "tex": "minotaur", "ai": "leap",
		"hp": 44.0, "speed": 32.0, "dmg": 3, "xp": 10, "score": 150, "scale": 1.45,
		"desc": "冲锋撞飞"},
	"beholder": {"name": "眼魔", "tex": "beholder", "ai": "spitter",
		"hp": 36.0, "speed": 18.0, "dmg": 2, "xp": 9, "score": 140, "scale": 1.28,
		"desc": "弹幕压制"},

	# ---------- Boss ----------
	"skeleton_king": {"name": "骷髅王", "tex": "skeleton_king", "ai": "boss", "summon": "skeleton",
		"hp": 220.0, "speed": 24.0, "dmg": 3, "xp": 20, "score": 900, "scale": 2.0},
	"demon": {"name": "炎魔", "tex": "demon", "ai": "boss", "summon": "imp",
		"hp": 300.0, "speed": 30.0, "dmg": 4, "xp": 24, "score": 1400, "scale": 2.1},
	"dragon": {"name": "黑龙", "tex": "dragon", "ai": "boss", "summon": "goblin",
		"hp": 380.0, "speed": 28.0, "dmg": 5, "xp": 28, "score": 1800, "scale": 2.3},
	"echo": {"name": "回响", "tex": "shadow", "ai": "echo",
		"hp": 8.0, "speed": 90.0, "dmg": 1, "xp": 6, "score": 80, "scale": 1.0},
}

## 每层刷怪池（权重）
const FLOOR_POOLS := {
	1: {"rusher": 6, "goblin": 5, "skeleton": 3, "wolf": 2, "zombie": 1},
	2: {"rusher": 3, "goblin": 3, "orc": 3, "skeleton": 2, "imp": 3,
		"wraith": 2, "flameskull": 2, "slime": 2},
	3: {"zombie": 3, "orc": 3, "vampire": 2, "plant": 2, "mush": 2,
		"faerie": 2, "wolf": 2, "wraith": 2, "imp": 2},
	4: {"wraith": 3, "flameskull": 3, "vampire": 3, "mush": 3, "plant": 2,
		"beholder": 1, "knight": 1, "minotaur": 1},
}

## 楼层主题：4 层起按 4→5→6→7 循环，各带一条环境规则 + 专属池/精英/Boss。
## mark=色盲友好符号标记（Sprint 13 E：与 tint 并列展示，颜色不是唯一编码通道）
const FLOOR_THEMES := {
	4: {"name": "往生脉", "rule": "vein", "pool": 4, "elite": "knight",
		"boss": "skeleton_king", "tint": Color(0.95, 0.85, 0.6), "mark": "◆"},
	5: {"name": "毒巢", "rule": "toxic", "pool": 3, "elite": "ogre",
		"boss": "demon", "tint": Color(0.62, 0.85, 0.55), "mark": "●"},
	6: {"name": "高压层", "rule": "pressure", "pool": 4, "elite": "beholder",
		"boss": "dragon", "tint": Color(0.95, 0.58, 0.5), "mark": "▲"},
	7: {"name": "静默层", "rule": "silent", "pool": 2, "elite": "minotaur",
		"boss": "boss", "tint": Color(0.58, 0.6, 0.85), "mark": "□"},
	8: {"name": "岩浆灼烧", "rule": "magma", "pool": 4, "elite": "minotaur",
		"boss": "demon", "tint": Color(1.0, 0.62, 0.42), "mark": "★"},
	9: {"name": "冰面打滑", "rule": "ice", "pool": 2, "elite": "knight",
		"boss": "skeleton_king", "tint": Color(0.72, 0.86, 1.0), "mark": "◇"},
	10: {"name": "毒沼减速", "rule": "swamp", "pool": 3, "elite": "ogre",
		"boss": "demon", "tint": Color(0.68, 0.92, 0.62), "mark": "▽"},
	11: {"name": "藤蔓阻挡", "rule": "vines", "pool": 2, "elite": "beholder",
		"boss": "dragon", "tint": Color(0.52, 0.85, 0.56), "mark": "■"},
}
const FLOOR_POOL_FALLBACK := {
	"rusher": 3, "goblin": 3, "skeleton": 2, "zombie": 2, "orc": 3, "imp": 2,
	"wraith": 2, "flameskull": 1, "faerie": 1, "vampire": 2, "plant": 1,
	"mush": 1, "slime": 2, "wolf": 2, "knight": 1,
}

const ELITE_BY_FLOOR := {1: "ogre", 2: "knight", 3: "minotaur"}
const ELITE_FALLBACK := "beholder"
const BOSS_BY_FLOOR := {1: "boss", 2: "skeleton_king", 3: "demon"}
const BOSS_FALLBACK := "dragon"

## 精英词缀
const AFFIXES := {
	"swift": {"name": "迅捷", "speed": 1.38, "tint": Color(0.7, 1.25, 1.3), "icon": "affix_swift"},
	"armored": {"name": "甲壳", "taken": 0.62, "tint": Color(1.15, 1.15, 1.3), "icon": "affix_armor"},
	"volatile": {"name": "爆裂", "death_boom": 46.0, "tint": Color(1.35, 0.95, 0.8), "icon": "affix_boom"},
	"death": {"name": "亡语", "split": 2, "tint": Color(0.95, 0.8, 1.15), "icon": "affix_death"},
	"ranged": {"name": "远程", "shoot_cd": 2.2, "tint": Color(1.2, 1.1, 0.75), "icon": "affix_ranged"},
	"shielded": {"name": "护盾", "shield": 1, "tint": Color(0.8, 1.1, 1.3), "icon": "affix_shield"},
	"mender": {"name": "治疗", "heal": 2.0, "heal_range": 90.0, "heal_cd": 4.0,
		"tint": Color(0.75, 1.2, 0.85), "icon": "affix_mender"},
}

## 敌人编队模板（F3）：combat 房按概率整组生成，取代当房随机池。
## members：id=敌人 id（须在 ENEMIES）；count 数量；affix 可选词缀（须在 AFFIXES）；
## front=true 近玩家点位（否则远点）；defuser=true 拆弹单位（追近并拆除玩家炸弹）。
## min_floor 起始层；weight 抽取权重。组合打印走 [SMOKE-SQUAD] 表外探针，不入 E1 指纹（坑 45）。
const SQUADS := {
	"shield_summon": {"name": "护盾+召唤", "min_floor": 4, "weight": 10, "members": [
		{"id": "orc", "count": 1, "affix": "shielded", "front": true},
		{"id": "mush", "count": 1, "front": false},
		{"id": "goblin", "count": 2, "front": true},
	]},
	"heal_charge": {"name": "治疗+冲锋", "min_floor": 5, "weight": 10, "members": [
		{"id": "zombie", "count": 1, "affix": "mender", "front": false},
		{"id": "wolf", "count": 2, "front": true},
	]},
	"sniper_defuser": {"name": "狙击+拆弹", "min_floor": 6, "weight": 8, "members": [
		{"id": "flameskull", "count": 2, "front": false},
		{"id": "imp", "count": 1, "defuser": true, "front": true},
	]},
	"tide": {"name": "潮涌", "min_floor": 3, "weight": 12, "members": [
		{"id": "rusher", "count": 4, "front": true},
		{"id": "goblin", "count": 3, "front": true},
		{"id": "imp", "count": 3, "front": false},
	]},
	"hunt": {"name": "围猎", "min_floor": 5, "weight": 9, "members": [
		{"id": "wolf", "count": 2, "front": true},
		{"id": "flameskull", "count": 1, "front": false},
	]},
	"alchemy": {"name": "炼金", "min_floor": 6, "weight": 8, "members": [
		{"id": "mush", "count": 1, "front": false},
		{"id": "imp", "count": 2, "front": true},
		{"id": "flameskull", "count": 1, "front": false},
	]},
	"echo_pack": {"name": "回响编队", "min_floor": 7, "weight": 7, "members": [
		{"id": "echo", "count": 1, "front": true},
		{"id": "rusher", "count": 2, "front": true},
	]},
}

## 反应式遗物词缀（F2/Sprint 11 §三）：附着到对应主动遗物，触发点命中时附加二次效果。
## trigger 枚举：ON_SHIELD_BREAK / ON_DASH_START / ON_VOLLEY_FIRE / ON_POISON_TICK。
## effect：theme_hazard（触发位生成当前楼层主题危害云）/ heal / slow_all / brief_shield。
## 全部效果由状态确定（每帧零新 rng）；词缀自身冷却走 E6 固定步。
const RELIC_SUFFIXES := {
	"s_frostburst": {"name": "霜爆", "trigger": "ON_SHIELD_BREAK", "relic": "orb_shield",
		"effect": "theme_hazard", "cd": 2.0,
		"desc": "环盾摧毁敌弹时，原地释放当前楼层主题危害云"},
	"s_echoheal": {"name": "回响", "trigger": "ON_SHIELD_BREAK", "relic": "orb_shield",
		"effect": "heal", "cd": 6.0, "amount": 1,
		"desc": "环盾摧毁敌弹时回复 1 生命"},
	"s_blinkstep": {"name": "踏影", "trigger": "ON_DASH_START", "relic": "dash_dodge",
		"effect": "theme_hazard", "cd": 3.0,
		"desc": "冲刺起点释放当前楼层主题危害云"},
	"s_bulwark": {"name": "小壁垒", "trigger": "ON_DASH_START", "relic": "dash_dodge",
		"effect": "brief_shield", "cd": 8.0,
		"desc": "冲刺时获得 1 层护盾"},
	"s_cinderveil": {"name": "燃帷", "trigger": "ON_VOLLEY_FIRE", "relic": "volley_burst",
		"effect": "theme_hazard", "cd": 4.0,
		"desc": "齐射时周身燃起当前楼层主题危害云"},
	"s_frostveil": {"name": "凝滞矢", "trigger": "ON_VOLLEY_FIRE", "relic": "volley_burst",
		"effect": "slow_all", "cd": 5.0, "slow": 0.5, "slow_dur": 2.0,
		"desc": "齐射使全场敌人减速 50%，持续 2 秒"},
	"s_miasma": {"name": "瘴波", "trigger": "ON_POISON_TICK", "relic": "toxic_freeze",
		"effect": "theme_hazard", "cd": 3.0,
		"desc": "毒云每跳扩散一圈当前楼层主题危害云"},
	"s_leech": {"name": "蚀养", "trigger": "ON_POISON_TICK", "relic": "toxic_freeze",
		"effect": "heal", "cd": 2.0, "amount": 1,
		"desc": "毒云每跳回复 1 生命"},
}

## 地窖印记（C/§四）：局外持久层——shards 货币结算纯确定性（cleared_floors × META_RATE，
## 无 rng）；印记在 run 开始前选定，run 初始化时、任何 Game.rng 绘制之前注入起始状态
## （E1 零漂移契约，见 game_main._apply_sigil_contract）。
const SIGILS := {
	"vigor": {"name": "刚韧印记", "desc": "开局生命上限 +1", "cost": 30},
	"arsenal": {"name": "武备印记", "desc": "开局副手预装霰弹枪", "cost": 40},
	"purse": {"name": "钱囊印记", "desc": "开局携带 15 残响", "cost": 25},
	"kindred": {"name": "协战印记", "desc": "开局召唤 1 个协战水晶（30 秒）", "cost": 50},
	"bulwark": {"name": "壁垒印记", "desc": "开局获得 1 层环盾护盾（2.5 秒）", "cost": 35},
	"sprinter": {"name": "疾行印记", "desc": "冲刺距离与无敌帧 +30%", "cost": 40},
	"harvester": {"name": "丰收印记", "desc": "击杀额外掉落 1 残响", "cost": 45},
	"ward": {"name": "守护印记", "desc": "Boss 房受到伤害 -20%", "cost": 60},
	"scholar": {"name": "博学印记", "desc": "每层首次清场额外 +2 地窖碎片", "cost": 40},
}

## 主动遗物（F2/Sprint 10 §十一）：开局可用、各带独立按键与冷却，不进三抽卡。
## 全部计时走 Game.FIXED_DT（E6）。duration=0 表示瞬发。
## effect_kind: shield（环盾摧毁敌弹+豁免接触）/ dash（冲刺+无敌帧）/
##              volley（八向弹）/ toxic（友方毒云：减速+微量 DoT）
const ACTIVE_RELICS := {
	"orb_shield": {"name": "环绕护盾", "cd": 9.0, "duration": 2.5,
		"effect_kind": "shield", "key_action": "relic_shield"},
	"dash_dodge": {"name": "冲刺闪避", "cd": 6.0, "duration": 0.4,
		"effect_kind": "dash", "key_action": "relic_dash"},
	"volley_burst": {"name": "齐射爆发", "cd": 12.0, "duration": 0.0,
		"effect_kind": "volley", "key_action": "relic_volley"},
	"toxic_freeze": {"name": "毒云冻结弹", "cd": 10.0, "duration": 4.0,
		"effect_kind": "toxic", "key_action": "relic_toxic"},
}

## 挑战因子：每局开局随机 1 个，一利一弊；none = 标准规则
## AI 行为参数覆盖表：按敌人 id 覆盖 AI 手感（键不存在时用 slug.gd 里的缺省值）。
## 目的是让 28 个敌人共用 8 个 AI 函数时手感仍能拉开；以后加怪只改这张表，不碰 AI 代码。
const AI_OVERRIDES := {
	"spitter": {"ai_keep": 100.0, "ai_range": 220.0, "ai_cd": 2.2, "ai_burst": 1,
		"ai_spread": 0.25, "ai_bullet_speed": 95.0},
	"wraith": {"ai_keep": 160.0, "ai_range": 300.0, "ai_cd": 1.6, "ai_burst": 2,
		"ai_spread": 0.18, "ai_bullet_speed": 110.0},
	"plant": {"ai_range": 300.0, "ai_cd": 2.6, "ai_burst": 2, "ai_spread": 0.08,
		"ai_bullet_speed": 80.0},
	"flameskull": {"ai_range": 260.0, "ai_cd": 2.0, "ai_burst": 3, "ai_spread": 0.16,
		"ai_bullet_speed": 95.0},
	"beholder": {"ai_range": 340.0, "ai_cd": 2.4, "ai_burst": 4, "ai_spread": 0.22,
		"ai_bullet_speed": 115.0},
	"vampire": {"ai_dash": 320.0, "ai_dash_time": 0.24, "ai_cd": 2.8, "ai_range": 240.0},
	"wolf": {"ai_dash": 280.0, "ai_dash_time": 0.30, "ai_cd": 3.0, "ai_range": 220.0},
	"minotaur": {"ai_dash": 300.0, "ai_dash_time": 0.30, "ai_cd": 3.0},
	"mush": {"ai_keep": 200.0, "ai_cd": 5.0, "ai_n": 3, "ai_range": 200.0},
	"imp": {"ai_sway": 4.5, "ai_sway_amp": 1.0},
	"faerie": {"ai_sway": 2.6, "ai_sway_amp": 0.6},
	"bomber": {"ai_range": 45.0},
	"skeleton_king": {"ai_dash": 260.0, "ai_dash_time": 0.44, "ai_cd": 3.6, "ai_burst": 4,
		"ai_spread": 0.22, "ai_bullet_speed": 150.0},
	"demon": {"ai_dash": 270.0, "ai_cd": 3.4, "ai_burst": 5, "ai_spread": 0.26,
		"ai_bullet_speed": 160.0},
	"dragon": {"ai_dash": 260.0, "ai_dash_time": 0.42, "ai_cd": 3.8, "ai_burst": 4,
		"ai_spread": 0.19, "ai_bullet_speed": 150.0, "ai_bullet_dmg": 2.0},
}

const MODIFIERS := {
	"none": {"name": "静默", "icon": "mod_silent", "desc": "标准规则"},
	"rage": {"name": "狂暴", "icon": "mod_rage", "desc": "敌人移速 +25%，血量 -15%"},
	"barren": {"name": "贫瘠", "icon": "mod_barren", "desc": "残响掉落 -30%，开局 +10 残响"},
	"overload": {"name": "超载", "icon": "mod_overload", "desc": "技能冷却 -40%，生命上限 -1"},
	"glass": {"name": "玻璃", "icon": "mod_glass", "desc": "暴击率 +20%，移速 -10%"},
	"swarm": {"name": "虫潮", "icon": "mod_swarm", "desc": "每房敌人 +2，残响掉落 +50%"},
}
const MODIFIER_WEIGHTS := {"none": 4, "rage": 2, "barren": 2, "overload": 2, "glass": 2, "swarm": 2}

## 里程碑提示：每局每条只播报一次（复用 toast 通道，零额外 UI 成本）
const MILESTONES := {
	"combo20": {"text": "连杀 20 —— 势不可挡"},
	"first_elite": {"text": "首杀精英"},
	"first_boss": {"text": "首杀 Boss"},
	"first_cursed": {"text": "诅咒房：血是代价"},
	"first_super": {"text": "超级秘密房 —— 稀有奖励"},
	"first_relic": {"text": "第一件遗物"},
	"resonance_burst": {"text": "残响共鸣 · 爆发"},
	"floor3": {"text": "第 3 层 —— 敌人在变强"},
	"first_shrine": {"text": "首入圣所 —— 抉择即构筑"},
}

## 房间类型元信息：加新房型 = 这里一条 + game_main 生成/清场各一个分支。
## bgm=进房曲目索引（Assets.MUSIC 下标）；mark=小地图字母（空=不标）
const ROOM_META := {
	"start": {"name": "起点", "color": Color(0.7, 0.7, 0.7), "bgm": 0, "mark": ""},
	"combat": {"name": "战斗", "color": Color(0.85, 0.85, 0.85), "bgm": 0, "mark": ""},
	"elite": {"name": "精英", "color": Color(1.0, 0.6, 0.25), "bgm": 1, "mark": ""},
	"treasure": {"name": "宝箱", "color": Color(1.0, 0.85, 0.35), "bgm": 0, "mark": "T"},
	"shop": {"name": "商店", "color": Color(0.45, 1.0, 0.65), "bgm": 0, "mark": "S"},
	"boss": {"name": "BOSS", "color": Color(1.0, 0.35, 0.35), "bgm": 2, "mark": "B"},
	"secret": {"name": "秘密", "color": Color(0.65, 0.55, 1.0), "bgm": 0, "mark": "?"},
	"super_secret": {"name": "超级秘密", "color": Color(1.0, 0.78, 0.3), "bgm": 0, "mark": "*"},
	"challenge": {"name": "无伤挑战", "color": Color(1.0, 0.5, 0.85), "bgm": 0, "mark": "!"},
	"cursed": {"name": "诅咒", "color": Color(0.85, 0.25, 0.35), "bgm": 0, "mark": ""},
	"shrine": {"name": "圣所", "color": Color(0.62, 0.9, 1.0), "bgm": 0, "mark": "+"},
}

## Sprint 13 A 抉择圣所：三选一「状态交换」表（零赌局零概率——纯 swap，§4.1）。
## cost_kind: ""（无资源代价）/ diamonds / max_hp / score；min_floor=出现门槛（房型本身 floor>=3）。
## effect 在 game_main._shrine_execute 分派；选项集由 stable_hash 纯派生（§4.5 零 Game.rng）
const SHRINE_OFFERS := {
	"blood_relic": {"name": "血祭", "desc": "生命上限 -1，掉落 1 件遗物", "cost_kind": "max_hp", "cost": 1, "min_floor": 3},
	"ore_upgrade": {"name": "残响淬炼", "desc": "残响 -8，触发一次升级三选一", "cost_kind": "diamonds", "cost": 8, "min_floor": 3},
	"purify": {"name": "净化", "desc": "解除本层灾祸；本局 ×1.5 结算加成作废", "cost_kind": "", "cost": 0, "min_floor": 3},
	"ward_boon": {"name": "护盾祝福", "desc": "残响 -5，获得 1 层护盾", "cost_kind": "diamonds", "cost": 5, "min_floor": 3},
	"heal": {"name": "修复", "desc": "积分 -60，回复 2 点生命", "cost_kind": "score", "cost": 60, "min_floor": 3},
	"relic_suffix": {"name": "铭刻", "desc": "生命上限 -1，为主动遗物附 1 条词缀", "cost_kind": "max_hp", "cost": 1, "min_floor": 5},
	# Sprint 15 D：池扩容 6→10（按 min_floor 分层——低层温和、高层高代价高收益；全部纯状态交换零赌局）
	"greed_pact": {"name": "贪欲契约", "desc": "生命上限 -1，残响 +10", "cost_kind": "max_hp", "cost": 1, "min_floor": 3},
	"wind_dance": {"name": "风之舞", "desc": "积分 -80，本局移速 +25%（120 秒）", "cost_kind": "score", "cost": 80, "min_floor": 5},
	"shard_pact": {"name": "共鸣契约", "desc": "残响 -12，地窖碎片 +6", "cost_kind": "diamonds", "cost": 12, "min_floor": 5},
	"power_surge": {"name": "力量激涌", "desc": "生命上限 -1，伤害 +30%（90 秒）", "cost_kind": "max_hp", "cost": 1, "min_floor": 7},
}

## Sprint 13 E：回响数值 data 驱动（原硬编码提常量，零逻辑改动——调数值只改这里）。
## mirror_time=玩家轨迹镜像时长 / cycle=游走周期 / chase_mult=镜像期速比 /
## dash_mult+creep_mult=游走期突进/蠕行速比 / buff_mult+buff_time=击败后攻速增益
const ECHO_TUNING := {"mirror_time": 2.5, "cycle": 3.0, "chase_mult": 1.5,
	"dash_mult": 1.8, "creep_mult": 0.5, "buff_mult": 1.35, "buff_time": 2.0}

## Sprint 14 A：两个主题 Boss 的图鉴专用 id（不在 ENEMIES 表——避免与「巨岩虫之王」的
## variant="boss" 撞名误登记，§3.2）。登记三件套的数据层单源：
## 白名单（game_state._codex_id_valid）/ UI 分母（codex_bosses_total）/ 显示名都从这里派生
const CODEX_BOSS_NAMES := {"prism_warden": "棱镜守望者", "pyrothalassian": "熔潮主宰",
	"third_boss": "玄渊之主"}

## Sprint 14 C：图鉴发现度 → 开局被动（data 驱动阈值与数值，调优只改这里）。
## 载体硬约束（草案 §5.4）：只允许一次性起始状态——shield/diamonds/max_hp/suffix；
## 禁用 diamond_mult/mag_cap_mult/calamity_speed_mult 等全局倍率载体
## （_roll_modifier/_roll_calamity/换层 clear 会重置——Sprint 12 #2 实害教训）
const CODEX_BOONS := {
	"enemies_5": {"kind": "enemies", "need": 5, "effect": "shield", "value": 1},
	"relics_4": {"kind": "relics", "need": 4, "effect": "diamonds", "value": 3},
	"themes_3": {"kind": "themes", "need": 3, "effect": "max_hp", "value": 1},
	"bosses_2": {"kind": "bosses", "need": 2, "effect": "suffix", "value": 1},
}

## Sprint 16 A：地窖誓约（9 条，一一对应 SIGILS 键——装备印记即誓约锚点）。
## 只读既有事件计数（watched 键由 player/game_main 既有分支登记），不定义新事件、
## 不调 mark_codex（P0 自激红线）、不设周期性主题 Boss 为必要条件；多条件全达标才兑现
const OATH_CONDITIONS := {
	"vigor": {"name": "流血不退", "desc": "在伤害下仍前进：受击 3 次", "watched": ["hits_taken"], "need": 3},
	"arsenal": {"name": "双持共鸣", "desc": "让遗物词缀共鸣 2 次", "watched": ["suffix_fires"], "need": 2},
	"purse": {"name": "圣所常客", "desc": "寻宝直觉带你两次走进圣所", "watched": ["shrine_visits"], "need": 2},
	"kindred": {"name": "并肩清扫", "desc": "清扫 30 只敌人", "watched": ["kills"], "need": 30},
	"bulwark": {"name": "盾未破身", "desc": "让环盾替你挡下一次伤害", "watched": ["shield_blocks"], "need": 1},
	"sprinter": {"name": "残影连闪", "desc": "冲刺 15 次", "watched": ["dashes"], "need": 15},
	"harvester": {"name": "满载而归", "desc": "获得 40 颗残响", "watched": ["diamonds_picked"], "need": 40},
	"ward": {"name": "净化誓约", "desc": "在圣所净化一次灾祸", "watched": ["purify_used"], "need": 1},
	"scholar": {"name": "兼修并蓄", "desc": "既进圣所，又让词缀共鸣 1 次", "watched": ["shrine_visits", "suffix_fires"], "need": 1},
}

## Sprint 16 D：地窖低语文案表（键 "kind/id"；基调=六道卷的克制实用主义——见痕者的功能性手记，
## 不臆造设定，只覆盖已存在条目）。首发现播报用，重复登记天然不播；不入任何分母/白名单
const FLAVOR := {
	"bosses/prism_warden": "守望者。天道之眼，别站在光缝里，砸它的核。",
	"bosses/pyrothalassian": "熔潮。修罗嗔火，弹匣留一半，给它变红的时候用。",
	"bosses/third_boss": "玄渊之主。地狱旧客，比熔潮慢半拍，比守望者狠。",
	"themes/vein": "往生脉。人间拾痕，多捡点，反射值钱。",
	"themes/toxic": "毒巢。饿鬼食毒，云别硬踩，绕着走。",
	"themes/pressure": "高压层。修罗斗诤，子弹会拐弯，贴墙打。",
	"themes/silent": "静默层。天道静虑，听不见脚步，多看小地图。",
	"themes/magma": "岩浆层。地狱热狱，地板本身就是敌人。",
	"themes/ice": "冰面。地狱寒狱，刹车提前半秒。",
	"themes/swamp": "毒沼。饿鬼腐沼，慢是慢了点，稳当。",
	"themes/vines": "藤蔓。畜生缠缚，烧掉，或者绕路。",
	# Sprint 18 阶段二 D 写入 / Sprint 19 阶段一续用：圣所熟客呼应 10 条（键 shrine/<offer_id>）。
	# 同时供两路直查：shrine_panel 三卡灰字（恒显、不读发现状态），以及 Sprint 19 起
	# `mark_codex("shrine", id)` 的首发现播报（mark_codex 拼键 kind + "/" + id 命中本表）。
	# 显示条件仍为**恒显**（不读发现状态），内容随三卡派生而变；灰字层与发现集彼此独立、互不耦合。
	"shrine/blood_relic": "血祭。以血换遗物，地窖里最不缺的就是血。",
	"shrine/ore_upgrade": "残响淬炼。以残响换一次选择，旧例里管这叫喂石头。",
	"shrine/purify": "净化。以代价换清净，这层的脏，散得掉。",
	"shrine/ward_boon": "护盾祝福。以残响买一挡，挡一下，就散了。",
	"shrine/heal": "修复。以积分换血，缝两针，血就回来了。",
	"shrine/relic_suffix": "铭刻。以血换一刻，刻上去的，抠不下来。",
	"shrine/greed_pact": "贪欲契约。以血换残响，老规矩了。",
	"shrine/wind_dance": "风之舞。以积分换疾行，腿快了，坑还是那些坑。",
	"shrine/shard_pact": "共鸣契约。以残响换碎片，地窖的账，只记碎片。",
	"shrine/power_surge": "力量激涌。以血换力，手重了，人也就薄了。",
	# Sprint 20 A：手记扩容到全六类——每条写实际机制的应对（ai 行为 / 遗物 desc / 词缀触发点），
	# 基调不变；enemies/relics/suffixes 首发现不播 toast（见 FLAVOR_BROADCAST_KINDS 白名单）
	"enemies/rusher": "红虫。异常·虫，成群来，先打跑得最快的。",
	"enemies/brute": "黑甲虫。异常·虫，大一号的虫，没什么花样，比输出。",
	"enemies/spitter": "紫酸虫。异常·虫，酸弹被墙挡，贴柱换血。",
	"enemies/bomber": "自爆虫。异常·虫，贴身就炸，保持距离。",
	"enemies/elite": "巨岩虫。异常·虫，精英壳，硬啃不划算。",
	"enemies/boss": "巨岩虫之王。异常·虫，满场小弟，本体掉宝最肥。",
	"enemies/splitter": "分裂虫。异常·虫，打死会裂，留个大的最后杀。",
	"enemies/mini": "幼体。异常·虫，一踩就碎，别浪费子弹。",
	"enemies/goblin": "地精。异常·妖，直冲，站桩点掉。",
	"enemies/skeleton": "骷髅兵。异常·灵，散骨一只，聚群难缠。",
	"enemies/zombie": "腐尸。异常·灵，慢，但会把你围住。",
	"enemies/orc": "兽人。异常·妖，皮糙，撤着打。",
	"enemies/imp": "小鬼。异常·妖，走位发疯，预瞄半个身位。",
	"enemies/wraith": "怨灵。异常·灵，会走位的远程，别蹲坑，风筝优先。",
	"enemies/flameskull": "火骷髅。异常·灵，站桩吐火球，先手拆掉。",
	"enemies/faerie": "妖精。异常·妖，飘忽，别追，等它过来。",
	"enemies/vampire": "吸血鬼。异常·妖，扑脸还吸血，跳之前有预备动作。",
	"enemies/plant": "食人花。异常·妖，守株待兔，卡住射程点掉。",
	"enemies/mush": "蘑菇人。异常·妖，会叫帮手，先杀召唤师。",
	"enemies/slime": "史莱姆。异常·妖，打死会裂，跟分裂虫一个路数。",
	"enemies/wolf": "狼。异常·妖，会扑，横向躲。",
	"enemies/knight": "盾骑士。异常·妖，减伤七成，用毒和炸的。",
	"enemies/ogre": "食人魔。异常·妖，减伤更多，别跟它对射。",
	"enemies/minotaur": "牛头人。异常·妖，冲撞很痛，贴边让它撞墙。",
	"enemies/beholder": "眼魔。异常·妖，盯得死，掩体换位打。",
	"enemies/skeleton_king": "骷髅王。异常·灵，召骷髅兵，先杀王再清场。",
	"enemies/demon": "炎魔。异常·妖，召小鬼，别让场上堆太多。",
	"enemies/dragon": "黑龙。异常·妖，召地精，本体才是大头。",
	"enemies/echo": "回响。异常·灵，走你走过的路，换个走法它就瞎。",
	"relics/fang": "吸血獠牙。杀敌偶尔回血，稳赚。",
	"relics/thorn": "荆棘装甲。让撞你的虫子付出代价。",
	"relics/bounce": "弹射弹壳。墙角也是武器。",
	"relics/frost": "冰霜涂层。命中带减速，命中率高就常驻。",
	"relics/bigbullet": "巨型弹头。又粗又痛。",
	"relics/mag": "加长弹匣。少换一次弹，多活一秒。",
	"relics/eye": "猎手印记。暴击看天，装了看常。",
	"relics/radar": "六感警报。无敌更长，走位更滑。",
	"relics/drone": "双浮游炮。多一个帮手。",
	"relics/heart": "黄金心脏。上限加一还回满，见到就拿。",
	"relics/mr_resoshield": "谐振护盾。共鸣爆发送盾，盾在毒不侵。",
	"relics/mr_kinetic": "动能转换器。挨打跑得快，疼也值。",
	"suffixes/s_frostburst": "霜爆。环盾碎敌弹时放危害云，别白挡。",
	"suffixes/s_echoheal": "回响（词缀）。环盾碎弹回一血，挡得值。",
	"suffixes/s_blinkstep": "踏影。冲刺起点放云，冲刺也是攻击。",
	"suffixes/s_bulwark": "小壁垒。冲刺送一层盾，冲进人堆前先想。",
	"suffixes/s_cinderveil": "燃帷。齐射放云，射得多烧得多。",
	"suffixes/s_frostveil": "凝滞矢。齐射全场减速，先齐射再补枪。",
	"suffixes/s_miasma": "瘴波。毒云每跳扩散，铺场用。",
	"suffixes/s_leech": "蚀养。毒云每跳回血，站云里养伤。",
	"bosses/boss": "巨岩虫之王，拿下。异常之主，掉宝最肥的一次。",
	"bosses/skeleton_king": "骷髅王，拿下。白骨留痕，骨头堆了半屋子。",
	"bosses/dragon": "黑龙，拿下。鳞甲留痕，地精散了，这一层安静一半。",
	"bosses/demon": "炎魔，拿下。业火留痕，火苗灭了，加钱。",
}

## Sprint 20 A：播报白名单——这些分类的首发现才播 toast；enemies/relics/suffixes 首发现
## 只入图鉴（floor 1 就可能连遇 3-5 种敌人，全播会刷屏；S16 D 原播报口径不变）
const FLAVOR_BROADCAST_KINDS := ["themes", "bosses", "shrine"]


## 图鉴 bosses 分母：ENEMIES 内真 Boss 数 + 主题 Boss 专用 id 数（菜单与探针同源，防 6/4 错位）
func codex_bosses_total() -> int:
	var n := 0
	for eid in ENEMIES:
		if String(ENEMIES[eid].get("ai", "")) == "boss":
			n += 1
	return n + CODEX_BOSS_NAMES.size()


## Sprint 21 C · 深渊难度档：纯乘算因子阶梯（tier → 三围乘子）。
## 仅缩放既有敌人属性，零新增 rng / 零机制 / 零实体。tier 0 = 关闭（全 1.0）。
## 自检：validate._check_abyss 校验单调 / 乘子>0 / 无 NaN / 尺寸==ABYSS_MAX_TIER。
const ABYSS_MAX_TIER := 10
const ABYSS_TIERS := {
	1:  {"hp": 1.10, "speed": 1.05, "dmg": 1.07},
	2:  {"hp": 1.20, "speed": 1.10, "dmg": 1.14},
	3:  {"hp": 1.30, "speed": 1.15, "dmg": 1.21},
	4:  {"hp": 1.40, "speed": 1.20, "dmg": 1.28},
	5:  {"hp": 1.50, "speed": 1.25, "dmg": 1.35},
	6:  {"hp": 1.60, "speed": 1.30, "dmg": 1.42},
	7:  {"hp": 1.70, "speed": 1.35, "dmg": 1.49},
	8:  {"hp": 1.80, "speed": 1.40, "dmg": 1.56},
	9:  {"hp": 1.90, "speed": 1.45, "dmg": 1.63},
	10: {"hp": 2.00, "speed": 1.50, "dmg": 1.70},
}

const OBSTACLES := {
	"pillar": {"hp": -1, "solid": true},
	"barrel": {"hp": 1, "explode": 58.0},
	"totem": {"hp": 3, "buff": true},
	"spike": {"hp": -1, "contact": 1},
	"vine": {"hp": 2, "solid": true},
}


## 楼层主题：4 层起按 4→5→6→7 循环；1–3 层无主题
func theme_for_floor(n: int) -> Dictionary:
	if n < 4:
		return {}
	var key: int = 4 + ((n - 4) % FLOOR_THEMES.size())
	return FLOOR_THEMES.get(key, {})


func pool_for_floor(floor_num: int) -> Dictionary:
	var th := theme_for_floor(floor_num)
	if th.has("pool"):
		var p: int = int(th["pool"])
		if FLOOR_POOLS.has(p):
			return FLOOR_POOLS[p]
	return FLOOR_POOLS.get(floor_num, FLOOR_POOL_FALLBACK)


func enemy(id: String) -> Dictionary:
	if not ENEMIES.has(id):
		Dev.err("data", "未知敌人 id：%s" % id)
		return ENEMIES["rusher"]
	return ENEMIES[id]


func elite_for_floor(floor_num: int) -> String:
	var th := theme_for_floor(floor_num)
	if th.has("elite"):
		return String(th["elite"])
	return ELITE_BY_FLOOR.get(floor_num, ELITE_FALLBACK)


func boss_for_floor(floor_num: int) -> String:
	var th := theme_for_floor(floor_num)
	if th.has("boss"):
		return String(th["boss"])
	return BOSS_BY_FLOOR.get(floor_num, BOSS_FALLBACK)


func roll_enemy(floor_num: int, allow_affix := true) -> Array:
	"""返回 [id, affix_or_empty]"""
	var pool := pool_for_floor(floor_num)
	var total := 0
	for k in pool:
		total += int(pool[k])
	var r := Game.rng.randi_range(0, maxi(total - 1, 0))
	var picked := "goblin"
	for k in pool:
		r -= int(pool[k])
		if r < 0:
			picked = k
			break
	var affix := ""
	if allow_affix and Game.rng.randf() < minf(0.06 + floor_num * 0.03, 0.22):
		var keys: Array = AFFIXES.keys()
		affix = keys[Game.rng.randi_range(0, keys.size() - 1)]
	return [picked, affix]


func room_name(kind: String) -> String:
	return String(ROOM_META.get(kind, {}).get("name", kind))


func room_color(kind: String) -> Color:
	return ROOM_META.get(kind, {}).get("color", Color.WHITE)


## 抽 1 个挑战因子（权重见 MODIFIER_WEIGHTS）
func roll_modifier() -> String:
	var total := 0
	for k in MODIFIER_WEIGHTS:
		total += int(MODIFIER_WEIGHTS[k])
	var r := Game.rng.randi_range(0, maxi(total - 1, 0))
	for k in MODIFIER_WEIGHTS:
		r -= int(MODIFIER_WEIGHTS[k])
		if r < 0:
			return k
	return "none"
