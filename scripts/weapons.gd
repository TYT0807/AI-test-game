class_name Weapons
extends RefCounted
## 武器定义表：四把基础法器，参数即弹道。

## E8″ 运行时计数探针：本入口累计消耗的随机数个数（仅供 SMOKE 校验消耗守恒）
static var rng_draws := 0

## 可掉落 / 可上架的武器池（不含起始武器 zhushan）
const DROP_POOL := ["liechi","guanglei","fushe","ml_frostbite"]  # 「[S41-R99-D] DROP_POOL 3→4：+ml_frostbite；wd_cinnifuse 不入池、不走 BOSS_WEAPON（R99a §E 改道：_boss_weapon_drop 的 floor==8 确定性早退，零 rng）。size 变⇒全层 stable_hash%size 重排＝设计接受（S33 事实 A 同源），基线以本车改后 DEFS 快照重建⛔ 拿旧池出卡快照当回归。」

## S38 T-M M2：非弹幕形态的必填字段清单——校验（validate M3）与分派（player N2）**共用这一份**，
## ⛔ 把字段名散写在 if 里（散写＝校验查 a 三个、分派读 b 两个，缺哪个都没人红）。
const MELEE_FIELDS := ["dmg", "interval", "reach", "arc_deg", "mag", "reload"]
## 形态集合（实稿 §3.8 表 ＋ §3.3/§3.6 两条裁定）：
## · throw / wand 不是新命中真身，它们就是弹道路径的参数变体 ⇒ 与 projectile 同走 `_fire()`；
## · melee / spear / shieldbash 才是口径 V-A2 说的「真·非弹幕」，一条都不许碰 spawn_player_bullet。
const KIND_PROJECTILE := ["projectile", "throw", "wand"]
const KIND_MELEE := ["melee", "spear", "shieldbash"]


static func kind(id: String) -> String:
	if not DEFS.has(id):
		return ""
	return String(DEFS[id].get("kind", ""))


static func is_melee_kind(k: String) -> bool:
	return KIND_MELEE.has(k)

const DEFS := {
	"zhushan": {
		"kind": "projectile",
		"name": "朱砂笔", "desc": "一笔一划，点到为止",
		"dmg": 1.0, "interval": 0.30, "count": 1, "spread": 4.0,
		"speed": 250.0, "mag": 8, "reload": 0.9, "pierce": 0,
		"life": 0.0, "explosive": 0.0,
		"tint": Color(1.0, 0.62, 0.25), "icon": "wpn_zhushan",
	},
	"liechi": {
		"kind": "projectile",
		"name": "裂髓杵", "desc": "一杵砸开，碎屑横飞",
		"dmg": 0.7, "interval": 0.72, "count": 5, "spread": 22.0,
		"speed": 225.0, "mag": 4, "reload": 1.1, "pierce": 0,
		"life": 0.40, "explosive": 0.0,
		"tint": Color(1.0, 0.82, 0.5), "icon": "wpn_liechi",
	},
	"guanglei": {
		"kind": "projectile",
		"name": "光雷尺", "desc": "一道直线，量穿三关",
		"dmg": 3.5, "interval": 0.9, "count": 1, "spread": 0.0,
		"speed": 430.0, "mag": 3, "reload": 1.3, "pierce": 3,
		"life": 0.0, "explosive": 0.0,
		"tint": Color(0.5, 0.9, 1.0), "icon": "wpn_guanglei",
	},
	"fushe": {
		"kind": "projectile",
		"name": "焚舍符匣", "desc": "焚符掷火，烧出一片",
		"dmg": 1.6, "interval": 0.85, "count": 1, "spread": 2.0,
		"speed": 180.0, "mag": 3, "reload": 1.4, "pierce": 0,
		"life": 0.0, "explosive": 1.0,
		"tint": Color(0.6, 1.0, 0.55), "icon": "wpn_fushe",
	},
	# ---- SPR7：局外解锁内容（增量：未解锁不进池，解锁后进池）----
	"mw_swarm": {
		"kind": "projectile",
		"name": "逐臭蜂", "desc": "光霰自动追踪最近的敌人",
		"dmg": 0.8, "interval": 0.16, "count": 1, "spread": 0.0,
		"speed": 300.0, "mag": 14, "reload": 1.0, "pierce": 0,
		"life": 1.6, "explosive": 0.0,
		"tint": Color(0.70, 1.0, 0.55), "icon": "wpn_swarm",
		"homing": true, "meta": "u_mw_swarm",
	},
	"mw_arc": {
		"kind": "projectile",
		"name": "引雷幡", "desc": "光霰命中时向附近敌人放电，可连锁 3 次",
		"dmg": 0.6, "interval": 0.45, "count": 1, "spread": 0.0,
		"speed": 260.0, "mag": 10, "reload": 1.2, "pierce": 0,
		"life": 0.0, "explosive": 0.0,
		"tint": Color(0.50, 0.80, 1.0), "icon": "wpn_arc",
		"arc": 3, "meta": "u_mw_arc",
	},
	"mw_cluster": {
		"kind": "projectile",
		"name": "集束榴弹", "desc": "命中爆炸后分裂出 3 枚小弹",
		"dmg": 1.6, "interval": 0.85, "count": 1, "spread": 2.0,
		"speed": 180.0, "mag": 3, "reload": 1.4, "pierce": 0,
		"life": 0.0, "explosive": 1.0,
		"tint": Color(1.0, 0.75, 0.35), "icon": "wpn_fushe",
		"cluster": 3, "meta": "u_mw_cluster",
	},
	# ---- SPR36 T-B1：Boss 专武 14 把（名单逐字照 SPR36 实稿 §6.3）----
	# 硬约束：① 无 `meta` 键 ⇒ 不建 UNLOCKS 节点（W3=A：建了就把「无限制」重新变成收费）；
	#        ② 行为位只用既有 homing/arc/cluster，⛔ 新参位（bullet.gd:25-28 的 7 个参位是冻结构造）；
	#        ③ dps = dmg/interval 按实稿 §7.2 死值口径配平：每只 Boss 恰好 2 把 ≥ dps_boss*1.25，
	#           其余全部 ≤ dps_boss（不留「差一点就反超」的灰区），比较在 abyss_tier==0 取表值。
	# 🔴 §6.3 里「frost 式减速」「条件增伤」「延迟齐射」三个行为位在现行 DEFS/bullet 参位下**无法表达**，
	#    已降级为可表达的近义词（短 life／纯数值／多弹丸齐射），desc 随之写实、⛔ 吹未做到的效果。
	"bw_prism_latch": {
		"kind": "projectile",
		"name": "定相闩", "desc": "锁相贯穿四目",
		"dmg": 5.0, "interval": 1.10, "count": 1, "spread": 0.0,
		"speed": 400.0, "mag": 4, "reload": 1.50, "pierce": 4,
		"life": 0.0, "explosive": 0.0,
		"tint": Color(0.62, 0.86, 1.0), "icon": "wpn_bw_latch",
	},
	"bw_seam_light": {
		"kind": "projectile",
		"name": "缝光尺", "desc": "沿缝跳两下",
		"dmg": 1.0, "interval": 1.00, "count": 1, "spread": 0.0,
		"speed": 300.0, "mag": 6, "reload": 1.20, "pierce": 0,
		"life": 0.0, "explosive": 0.0,
		"tint": Color(0.72, 0.92, 1.0), "icon": "wpn_bw_seam",
		"arc": 2,
	},
	"bw_core_hammer": {
		"kind": "projectile",
		"name": "敲核槌", "desc": "砸核开花",
		"dmg": 1.5, "interval": 2.40, "count": 1, "spread": 2.0,
		"speed": 190.0, "mag": 3, "reload": 1.60, "pierce": 0,
		"life": 0.0, "explosive": 1.0,
		"tint": Color(0.90, 0.70, 0.40), "icon": "wpn_bw_hammer",
	},
	"bw_sixfold_ring": {
		"kind": "projectile",
		"name": "六相轮", "desc": "六面齐开",
		"dmg": 0.35, "interval": 0.62, "count": 6, "spread": 14.0,
		"speed": 240.0, "mag": 6, "reload": 1.30, "pierce": 0,
		"life": 0.0, "explosive": 0.0,
		"tint": Color(0.66, 0.88, 0.98), "icon": "wpn_bw_ring",
	},
	"bw_quiet_gauge": {
		"kind": "projectile",
		"name": "静默计量表", "desc": "短程压制",
		"dmg": 0.50, "interval": 0.80, "count": 1, "spread": 3.0,
		"speed": 320.0, "mag": 10, "reload": 1.00, "pierce": 0,
		"life": 0.18, "explosive": 0.0,
		"tint": Color(0.58, 0.62, 0.70), "icon": "wpn_bw_quiet",
	},
	"bw_tide_gauge": {
		"kind": "projectile",
		"name": "涨潮表", "desc": "密不透风",
		"dmg": 0.55, "interval": 0.35, "count": 1, "spread": 3.0,
		"speed": 280.0, "mag": 16, "reload": 1.50, "pierce": 0,
		"life": 0.0, "explosive": 0.0,
		"tint": Color(1.0, 0.66, 0.36), "icon": "wpn_bw_tide",
	},
	"bw_clinkant_fang": {
		"kind": "projectile",
		"name": "嗔火钤", "desc": "命中引爆",
		"dmg": 2.0, "interval": 1.40, "count": 1, "spread": 2.0,
		"speed": 210.0, "mag": 4, "reload": 1.50, "pierce": 0,
		"life": 0.0, "explosive": 1.2,
		"tint": Color(1.0, 0.55, 0.25), "icon": "wpn_bw_fang",
	},
	"bw_slack_half": {
		"kind": "projectile",
		"name": "半 slack 铳", "desc": "两发一装",
		"dmg": 0.90, "interval": 1.10, "count": 1, "spread": 2.0,
		"speed": 300.0, "mag": 2, "reload": 1.70, "pierce": 0,
		"life": 0.0, "explosive": 0.0,
		"tint": Color(0.94, 0.72, 0.44), "icon": "wpn_bw_slack",
	},
	"bw_cinder_rake": {
		"kind": "projectile",
		"name": "燼齿耙", "desc": "爆后裂两枚",
		"dmg": 0.70, "interval": 0.85, "count": 1, "spread": 2.0,
		"speed": 190.0, "mag": 3, "reload": 1.40, "pierce": 0,
		"life": 0.0, "explosive": 0.8,
		"tint": Color(0.86, 0.52, 0.30), "icon": "wpn_bw_rake",
		"cluster": 2,
	},
	"bw_red_dial": {
		"kind": "projectile",
		"name": "红盘指针", "desc": "单发稳打",
		"dmg": 0.85, "interval": 1.00, "count": 1, "spread": 1.0,
		"speed": 260.0, "mag": 8, "reload": 1.10, "pierce": 0,
		"life": 0.0, "explosive": 0.0,
		"tint": Color(1.0, 0.38, 0.30), "icon": "wpn_bw_dial",
	},
	"bw_abyss_ledger": {
		"kind": "projectile",
		"name": "渊簿", "desc": "一笔重账",
		"dmg": 4.5, "interval": 1.30, "count": 1, "spread": 0.0,
		"speed": 360.0, "mag": 4, "reload": 1.60, "pierce": 1,
		"life": 0.0, "explosive": 0.0,
		"tint": Color(0.48, 0.52, 0.66), "icon": "wpn_bw_ledger",
	},
	"bw_half_beat": {
		"kind": "projectile",
		"name": "半拍椎", "desc": "三发齐进",
		"dmg": 0.90, "interval": 0.90, "count": 3, "spread": 10.0,
		"speed": 260.0, "mag": 6, "reload": 1.40, "pierce": 0,
		"life": 0.0, "explosive": 0.0,
		"tint": Color(0.56, 0.60, 0.72), "icon": "wpn_bw_beat",
	},
	"bw_black_silt": {
		"kind": "projectile",
		"name": "黑泥栓", "desc": "射程短促",
		"dmg": 0.60, "interval": 0.90, "count": 1, "spread": 4.0,
		"speed": 180.0, "mag": 8, "reload": 1.20, "pierce": 0,
		"life": 0.30, "explosive": 0.0,
		"tint": Color(0.42, 0.44, 0.48), "icon": "wpn_bw_silt",
	},
	"bw_third_key": {
		"kind": "projectile",
		"name": "第三钥", "desc": "贯穿两目",
		"dmg": 0.65, "interval": 1.00, "count": 1, "spread": 0.0,
		"speed": 420.0, "mag": 5, "reload": 1.30, "pierce": 2,
		"life": 0.0, "explosive": 0.0,
		"tint": Color(0.74, 0.68, 0.50), "icon": "wpn_bw_key",
	},
	# ---- SPR38 T-O：非弹幕形态族 6 条（数值取实稿 §3.2–§3.6 基准表，名字取 §3.8 原创命名表）----
	# 🔴 HP-6：B1 **只给数据、不给获取途径**——⛔ 不进 DROP_POOL、⛔ 不进 SHRINE_OFFERS、
	#    ⛔ 不被任何 drop_pickup(..., "weapon", ...) 指向，也⛔ 带 `meta` 键（不建 UNLOCKS 节点，
	#    与 S36 W3=A 同轨）。解禁条件是口径 V-G2（B2a 窗口守卫）绿，投放是 B3 的事（V-F 一节）。
	# 🔴 真·非弹幕三条（melee/spear/shieldbash）⛔ count/spread/speed/life/pierce/explosive：
	#    那六个是弹道参位，写进去等于宣告「这其实是一把枪」。V-A3 判「出现即点名、不判红」，
	#    点名行在 validate 的 [S38-A3]。
	# ⚠️ 实稿只钉了 reach/arc_deg/interval/mag/reload 与盾的 dmg，**没钉三把近战的 dmg**：
	#    这里按 S36 §7.2 的死值口径取 `dmg = interval × 步枪 dps(3.33)` 的配平值，
	#    密针按「低 dmg」下浮，数值归属与替换空间已在交付报告里点名给主理人复核。
	"ml_cleaver": {
		"kind": "melee",
		"name": "断水阔刃", "desc": "贴身横扫",
		"dmg": 1.80, "interval": 0.55, "reach": 46, "arc_deg": 110,
		"mag": 4, "reload": 0.9,
		"tint": Color(0.98, 0.70, 0.40), "icon": "wpn_ml_cleaver",
	},
	"ml_needler": {
		"kind": "melee",
		"name": "密针", "desc": "近身连刺",
		"dmg": 0.65, "interval": 0.26, "reach": 34, "arc_deg": 60,
		"mag": 7, "reload": 0.8,
		"tint": Color(0.72, 0.86, 0.92), "icon": "wpn_ml_needle",
	},
	"sp_thorn": {
		"kind": "spear",
		"name": "荆刺", "desc": "直刺破甲",
		"dmg": 2.40, "interval": 0.72, "reach": 78, "arc_deg": 42,
		"mag": 3, "reload": 1.1,
		"tint": Color(0.86, 0.62, 0.34), "icon": "wpn_sp_thorn",
	},
	"sh_bulwark": {
		"kind": "shieldbash",
		"name": "稳壁", "desc": "贴身撞缓",
		"dmg": 1.20, "interval": 0.90, "reach": 34, "arc_deg": 150,
		"mag": 3, "reload": 1.3,
		"tint": Color(0.62, 0.66, 0.74), "icon": "wpn_sh_bulwark",
	},
	# throw／wand 走的是 `_fire()` 那条弹道路（实稿 §3.3/§3.6 裁定：它们是参数变体，不是新命中真身），
	# 所以保留弹道参位；投掷的「射程受限靠 life 而不是速度衰减」、准头差靠 spread 表达。
	"th_kunai": {
		"kind": "throw",
		"name": "三枚锥", "desc": "慢手近掷",
		"dmg": 2.20, "interval": 0.90, "count": 1, "spread": 3.0,
		"speed": 150.0, "mag": 2, "reload": 1.6, "pierce": 0,
		"life": 0.55, "explosive": 0.0,
		"tint": Color(0.80, 0.74, 0.58), "icon": "wpn_th_kunai",
	},
	"wd_whisper": {
		"kind": "wand",
		"name": "低语法杖", "desc": "两枚低语追踪",
		"dmg": 0.45, "interval": 0.90, "count": 2, "spread": 6.0,
		"speed": 210.0, "mag": 6, "reload": 1.2, "pierce": 0,
		"life": 1.40, "explosive": 0.0,
		"homing": true,
		"tint": Color(0.66, 0.78, 1.00), "icon": "wpn_wd_whisper",
	},
	# 「[S41-R99-W] 近战增量两支：寒髓杵·霜枝（ml_frostbite・melee・knock=55・slow_on_hit={0.5,1.0}）⇄燃符匣（wd_cinnifuse・wand・phase_boom={3,42.0,0.6}・dmg=2.60/interval=0.78 按 §C-8 校准式闭合）。icon 别名复用（wpn_ml_cleaver⇄wpn_fushe，先例 mw_cluster）。⛔ 六弹道字段入 melee 项（[S38-A3]）⛔ knock/slow_on_hit/phase_boom 进 MELEE_FIELDS required。」
	"ml_frostbite": {
		"kind": "melee",
		"name": "寒髓杵·霜枝", "desc": "一杵沉重，撞得骨飞",
		"dmg": 1.95, "interval": 0.585, "reach": 44, "arc_deg": 96,
		"mag": 4, "reload": 0.95,
		"knock": 55.0, "slow_on_hit": {"mult": 0.5, "dur": 1.0},
		"tint": Color(0.66, 0.84, 0.94), "icon": "wpn_ml_cleaver",
	},
	"wd_cinnifuse": {
		"kind": "wand",
		"name": "燃符匣", "desc": "八层朱砂，一发顶三发",
		"dmg": 2.60, "interval": 0.78, "count": 1, "spread": 2.0,
		"speed": 190.0, "mag": 5, "reload": 1.15, "pierce": 0,
		"life": 1.10, "explosive": 0.0,
		"homing": false,
		"phase_boom": {"n": 3, "radius": 42.0, "mult": 0.6},
		# [S41-R99-E] 定向掉落走 floor==8 守关 Boss 房早退（R99a §E-4），不入 BOSS_WEAPON⇒validate 反超闸与图鉴 surpass_note 均只遍历归属表，本把天然不在其作用域内；dmg/interval 维持 §C-8 校准式闭合（0.78×3.33≈2.60）。
		"tint": Color(0.95, 0.55, 0.30), "icon": "wpn_fushe",
	},
}


## S36 T-B2：专武归属（weapon id → Boss 的 codex id）。**只读表**：
## ⛔ 不得被 unlocked_ids()/random_unlocked() 读取（那两处的行为是既有契约，
##    掺进来就等于把专武塞回随机掉落池，与 W3=A 的定向掉落相反）。
## key 三值以 data.gd:336-337 CODEX_BOSS_NAMES 为准；棱镜 5＋熔潮 5＋玄渊 4 ＝ 14。
const BOSS_WEAPON := {
	"bw_prism_latch": "prism_warden",
	"bw_seam_light": "prism_warden",
	"bw_core_hammer": "prism_warden",
	"bw_sixfold_ring": "prism_warden",
	"bw_quiet_gauge": "prism_warden",
	"bw_tide_gauge": "pyrothalassian",
	"bw_clinkant_fang": "pyrothalassian",
	"bw_slack_half": "pyrothalassian",
	"bw_cinder_rake": "pyrothalassian",
	"bw_red_dial": "pyrothalassian",
	"bw_abyss_ledger": "third_boss",
	"bw_half_beat": "third_boss",
	"bw_black_silt": "third_boss",
	"bw_third_key": "third_boss",
}


## T-C2：反超小字**由常数派生**（实稿 §7.2 / 实施单 C2「⛔ 手写百分比数字」）。
## 返回 "" 表示这把没反超；反超句里的倍数是 dmg/interval 与 Boss 脉冲 dps 的实算值。
static func surpass_note(id: String) -> String:
	if not BOSS_WEAPON.has(id):
		return ""
	var bid := String(BOSS_WEAPON[id])
	if not Data.BOSS_PULSE_BASE.has(bid):
		return ""
	var p: Dictionary = Data.BOSS_PULSE_BASE[bid]
	var dps_boss: float = float(p["dmg"]) / float(p["interval"])
	var w: Dictionary = DEFS[id]
	var dps_w: float = float(w["dmg"]) / float(w["interval"])
	if dps_w < dps_boss * Data.WEAPON_SURPASS_RATIO:
		return ""
	return "比它自己更疼（%.2f 倍）" % (dps_w / dps_boss)


## 某只 Boss 的专武子集（按 DEFS 声明序，定向掉落用；零 rng）
## 🔴 非三键（含空串）一律返回空表。`BOSS_WEAPON.get(id, "")` 的默认值就是 ""，不挡这一刀，
##    boss_id 取空时「没登记归属的武器」（四把基础枪＋三把 mw_*）会整批被当成这只 Boss 的子集，
##    常规 Boss 房于是从「退回随机三选一」静默变成「零 rng 七选一」——掉落来源换了、还牵进商店专用件。
static func boss_weapon_ids(boss_id: String) -> Array:
	var out := []
	if not Data.CODEX_BOSS_NAMES.has(boss_id):
		return out
	for id in DEFS:
		if BOSS_WEAPON.get(id, "") == boss_id:
			out.append(String(id))
	return out


static func icon(id: String) -> Texture2D:
	if not DEFS.has(id):
		Dev.err("weapon", "未知武器 id：%s（回退朱砂笔图标）" % id)
		id = "zhushan"
	return Assets.g(DEFS[id]["icon"])


## 已解锁的武器 id（按 DEFS 顺序；zhushan 永远可用）
static func unlocked_ids() -> Array:
	var out := []
	for id in DEFS:
		if Game.meta_content_unlocked("weapon", {"id": String(id)}):
			out.append(String(id))
	return out


## 随机一把已解锁的武器（掉落 / 商店货架共用这一个入口）
## 一把都没解锁时回退 rifle（起始武器），保证不崩、不出现空 id
static func random_unlocked() -> String:
	var ids := []
	for id in DROP_POOL:
		if Game.meta_content_unlocked("weapon", {"id": id}):
			ids.append(id)
	# 恒消耗 1 次随机数：Godot 4.7 的 randi_range(0, 0) 不消耗随机流，
	# 空池 / 单元素池会少消耗 → 解锁状态改变随机流位置。randi() 恒消耗，% 保证下标合法。
	var r: int = Game.rng.randi() % maxi(ids.size(), 1)
	rng_draws += 1
	if ids.is_empty():
		return "zhushan"
	return String(ids[r])
