extends Node
## 分类日志：自研代码的告警/错误统一走这里。
## F3 面板读 snapshot()，出事时能直接看到「哪个系统、哪一句」。

const MAX_ENTRIES := 80

var entries: Array = []
var errors := 0
var warnings := 0


func info(tag: String, msg: String) -> void:
	_push(0, tag, msg)


func warn(tag: String, msg: String) -> void:
	warnings += 1
	_push(1, tag, msg)
	push_warning("[%s] %s" % [tag, msg])


func err(tag: String, msg: String) -> void:
	errors += 1
	_push(2, tag, msg)
	push_error("[%s] %s" % [tag, msg])


## 断言式检查：不成立时记一条错误并返回 false（不中断游戏，便于一次看全所有问题）
func check(cond: bool, tag: String, msg: String) -> bool:
	if not cond:
		err(tag, msg)
	return cond


func _push(lvl: int, tag: String, msg: String) -> void:
	entries.append({"sec": Time.get_ticks_msec() / 1000.0, "lvl": lvl, "tag": tag, "msg": msg})
	if entries.size() > MAX_ENTRIES:
		entries.pop_front()
	if OS.get_environment("SMOKE") != "":
		var lv: String = ["INFO", "WARN", "ERR"][lvl]
		print("[%s] %s: %s" % [lv, tag, msg])


func snapshot(n := 10) -> Array:
	var out: Array = []
	var start := maxi(0, entries.size() - n)
	for i in range(start, entries.size()):
		out.append(entries[i])
	return out


func clear() -> void:
	entries.clear()
	errors = 0
	warnings = 0
