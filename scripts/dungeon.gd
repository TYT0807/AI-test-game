class_name Dungeon
extends RefCounted
## 以撒式地牢：网格随机游走生成，门在共用墙正中，特殊房挂死端。

const DIRS := [Vector2i(0, -1), Vector2i(0, 1), Vector2i(-1, 0), Vector2i(1, 0)]  # 上 下 左 右
const NO_CELL := Vector2i(999, 999)  # 找不到候选格子时的哨兵

var floor_num := 1
var rooms := {}  # Vector2i -> {"kind": String, "cleared": bool, "visited": bool}
var current := Vector2i.ZERO


func has_room(c: Vector2i) -> bool:
	return rooms.has(c)


func room(c: Vector2i) -> Dictionary:
	return rooms.get(c, {})


func neighbors(c: Vector2i) -> Array[Vector2i]:
	var out: Array[Vector2i] = []
	for d in DIRS:
		if has_room(c + d):
			out.append(c + d)
	return out


## 随机游走：从起点走出 count 个房间；最远者为 Boss；死端放宝箱/商店。
static func generate(floor_num: int, rng: RandomNumberGenerator, count: int) -> Dungeon:
	var d := Dungeon.new()
	d.floor_num = floor_num
	d.rooms[Vector2i.ZERO] = {"kind": "start", "cleared": true, "visited": true}
	var frontier: Array[Vector2i] = [Vector2i.ZERO]
	var guard := 0
	while d.rooms.size() < count and guard < 500:
		guard += 1
		var base: Vector2i = frontier[rng.randi_range(0, frontier.size() - 1)]
		var dir: Vector2i = DIRS[rng.randi_range(0, 3)]
		var next := base + dir
		if d.has_room(next):
			continue
		# 约束：不允许形成 2x2 密铺（以撒式留白）
		if _makes_block(d, next):
			continue
		var roll := rng.randf()
		var kind := "combat" if roll < 0.62 else "elite"
		d.rooms[next] = {"kind": kind, "cleared": false, "visited": false}
		frontier.append(next)
		if frontier.size() > 6:
			frontier.remove_at(0)

	# 距离场：最远 → Boss
	var dist := _bfs_dist(d, Vector2i.ZERO)
	var boss := Vector2i.ZERO
	var best := -1
	for c in d.rooms:
		if c == Vector2i.ZERO:
			continue
		if dist[c] > best:
			best = dist[c]
			boss = c
	d.rooms[boss]["kind"] = "boss"

	# 死端（恰好 1 个邻居，非起点/Boss）→ 宝箱房、商店房
	var dead_ends: Array[Vector2i] = []
	for c in d.rooms:
		if c == Vector2i.ZERO or c == boss:
			continue
		if d.neighbors(c).size() == 1:
			dead_ends.append(c)
	dead_ends.sort()
	var tries := 0
	while dead_ends.size() < 2 and tries < 200:
		tries += 1
		# 死端不足：造一个（从随机房向空位延伸一格）
		var base: Vector2i = d.rooms.keys()[rng.randi_range(0, d.rooms.size() - 1)]
		if base == Vector2i.ZERO or base == boss:
			continue
		var dir: Vector2i = DIRS[rng.randi_range(0, 3)]
		var next := base + dir
		if d.has_room(next) or _makes_block(d, next):
			continue
		d.rooms[next] = {"kind": "combat", "cleared": false, "visited": false}
		if d.neighbors(next).size() == 1:
			dead_ends.append(next)
	# 兜底：实在造不出死端就征用普通/精英房（不致卡流程）
	while dead_ends.size() < 2:
		var picked := false
		for c in d.rooms:
			if c != Vector2i.ZERO and d.rooms[c]["kind"] in ["combat", "elite"] and not dead_ends.has(c):
				dead_ends.append(c)
				picked = true
				break
		if not picked:
			break
	d.rooms[dead_ends[0]]["kind"] = "treasure"
	d.rooms[dead_ends[1]]["kind"] = "shop"

	# ---- 秘密房：夹在两间房之间的空格，用炸弹炸开 ----
	var secret := _find_secret_cell(d)
	if secret != NO_CELL:
		d.rooms[secret] = {"kind": "secret", "cleared": true, "visited": false, "revealed": false}

	# ---- 超级秘密房：只挂 1 间普通房、稀有掉落；仍只吃炸弹，揭示后由 _build_arena 重建 ----
	var super_secret := _find_super_secret_cell(d)
	if super_secret != NO_CELL:
		d.rooms[super_secret] = {"kind": "super_secret", "cleared": true,
			"visited": false, "revealed": false}
		Dev.check(d.neighbors(super_secret).size() == 1, "dungeon", "超级秘密房邻居数不为 1")
		if OS.get_environment("SMOKE") != "":
			print("[SMOKE-SUPER] floor=%d cell=%s neighbors=%d" % [
				floor_num, super_secret, d.neighbors(super_secret).size()])

	# ---- 诅咒房：进房扣 1 血，必掉遗物 + 大宝箱 + 源石（以撒诅咒房思路）----
	var cursed_pool: Array[Vector2i] = []
	for c in d.rooms:
		if c == Vector2i.ZERO or d.rooms[c]["kind"] != "combat":
			continue
		cursed_pool.append(c)
	if cursed_pool.size() >= 3 and rng.randf() < 0.5:
		var pick_c: Vector2i = cursed_pool[rng.randi_range(0, cursed_pool.size() - 1)]
		d.rooms[pick_c]["kind"] = "cursed"

	# ---- 无伤挑战房：随机把一间战斗房改造 ----
	var combat_rooms: Array[Vector2i] = []
	for c in d.rooms:
		if d.rooms[c]["kind"] == "combat" and c != Vector2i.ZERO:
			combat_rooms.append(c)
	if combat_rooms.size() >= 3 and rng.randf() < 0.8:
		var pick: Vector2i = combat_rooms[rng.randi_range(0, combat_rooms.size() - 1)]
		d.rooms[pick]["kind"] = "challenge"

	# ---- 抉择圣所（Sprint 13 A）：每层从剩余战斗房确定性挑 1 间（floor>=3）----
	# 零 rng 消费：按坐标序取首个——同 seed 同布局同圣所位（E1 §4.5，不新增 rng 流）；
	# 只改 kind，房间坐标与总数不变；_smoke_fingerprint 因 kind 变化重定（预期代价，已登记）
	if floor_num >= 3:
		var shrine_pool: Array[Vector2i] = []
		for c in d.rooms:
			if c != Vector2i.ZERO and d.rooms[c]["kind"] == "combat" \
					and d.neighbors(c).size() > 1:
				shrine_pool.append(c)
		if not shrine_pool.is_empty():
			shrine_pool.sort_custom(func(a: Vector2i, b: Vector2i) -> bool:
				return a.x * 1000 + a.y < b.x * 1000 + b.y)
			d.rooms[shrine_pool[0]]["kind"] = "shrine"
	return d


## 找秘密房格子：空的、至少 2 个相邻房间、不贴 Boss
static func _find_secret_cell(d: Dungeon) -> Vector2i:
	for c in d.rooms.keys():
		for dir in DIRS:
			var n: Vector2i = c + dir
			if d.has_room(n) or n == Vector2i.ZERO:
				continue
			var cnt := 0
			var touches_boss := false
			for dd in DIRS:
				var m: Vector2i = n + dd
				if d.has_room(m):
					cnt += 1
					if d.rooms[m]["kind"] == "boss":
						touches_boss = true
			if cnt >= 2 and not touches_boss:
				return n
	return NO_CELL


## 超级秘密房格子（P1/Q）：唯一邻房排除宝箱/商店/Boss 及另一间隐藏房，其余正常可达房（含起点）可挂。
## 起点不是死端特殊房，允许挂靠可让超秘靠近起点，避免新增叶子房引发 SMOKE 自动驾驶多房乒乓。
## 与普通秘密房一致不做 2x2 校验（§3.3：cnt==1 本来也成不了 2x2）；确定性取首个候选、不消耗 rng。
static func _find_super_secret_cell(d: Dungeon) -> Vector2i:
	for c in d.rooms.keys():
		var ck: String = String(d.rooms[c]["kind"])
		if _is_special_room(ck):
			continue
		for dir in DIRS:
			var n: Vector2i = c + dir
			if d.has_room(n) or n == Vector2i.ZERO:
				continue
			var cnt := 0
			var bad := false
			for dd in DIRS:
				var m: Vector2i = n + dd
				if not d.has_room(m):
					continue
				cnt += 1
				var mk: String = String(d.rooms[m]["kind"])
				if _is_special_room(mk):
					bad = true
			if cnt == 1 and not bad:
				return n
	return NO_CELL


static func _is_special_room(kind: String) -> bool:
	return kind == "treasure" or kind == "shop" or kind == "boss" \
			or kind == "secret" or kind == "super_secret"


## 放下 c 后是否会形成 2x2 密铺块（c 本身尚未放置，只查三个相关邻居）
static func _makes_block(d: Dungeon, c: Vector2i) -> bool:
	for dx in [-1, 1]:
		for dy in [-1, 1]:
			if d.has_room(c + Vector2i(dx, 0)) and d.has_room(c + Vector2i(0, dy)) \
					and d.has_room(c + Vector2i(dx, dy)):
				return true
	return false


static func _bfs_dist(d: Dungeon, from: Vector2i) -> Dictionary:
	var dist := {from: 0}
	var queue: Array[Vector2i] = [from]
	while not queue.is_empty():
		var c: Vector2i = queue.pop_front()
		for n in d.neighbors(c):
			if not dist.has(n):
				dist[n] = dist[c] + 1
				queue.append(n)
	return dist
