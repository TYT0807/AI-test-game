extends SceneTree
## SPR3-T2 阶段 B：RG-7 负向探针（独立，不改 scripts/，不依赖 autoload）
## 请求不存在的图标 key，必须返回白色占位图且打印 [assets] 图标缺失，不得抛异常。

func _initialize() -> void:
	var a: Node = preload("res://scripts/assets.gd").new()
	root.add_child(a)
	if a.white_tex == null:
		a._ready()
	var t: Texture2D = a.xicon("__spr3_qa_missing_key__")
	print("[PROBE] white_tex_ready=", a.white_tex != null)
	print("[PROBE] missing-key -> ", "WHITE" if t != null and t == a.white_tex else "OTHER", \
		" size=", t.get_size() if t != null else Vector2.ZERO)
	var known: Texture2D = a.xicon("guard")
	print("[PROBE] known-key(guard) -> ", \
		"OK" if known != null and known != a.white_tex else "NULL_OR_WHITE")
	quit()
