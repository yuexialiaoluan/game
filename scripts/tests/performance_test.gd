extends Node3D

## 性能基础验证：生成 1/10/25/50/100 个 2D 角色 billboard，统计帧时间与 SubViewport 数量。
var db: CharacterVisualDB
var spawned: Array[CharacterBillboard3D] = []

func _ready() -> void:
	db = CharacterVisualDB.new()
	if OS.get_cmdline_user_args().has("--validate"):
		call_deferred("_run")

func _run() -> void:
	await get_tree().process_frame
	for n in [1, 10, 25, 50, 100]:
		_spawn(n)
		await get_tree().process_frame
		await get_tree().process_frame
		var start := Time.get_ticks_msec()
		var frames := 30
		for i in range(frames):
			await get_tree().process_frame
		var elapsed := Time.get_ticks_msec() - start
		var avg := elapsed / float(frames)
		print("PERF N=%d avg_frame_ms=%.2f subviewports=%d" % [n, avg, _count_subviewports()])
		_clear()
	print("VALIDATION_DONE failures=0")
	get_tree().quit()

func _spawn(n: int) -> void:
	_clear()
	var cols := 10
	for i in range(n):
		var b := CharacterBillboard3D.new()
		b.name = "Char%d" % i
		var col := i % cols
		var row := int(i / float(cols))
		b.position = Vector3((col - cols / 2.0) * 2.0, 0, row * 2.0)
		add_child(b)
		b.setup(db, "human_male", "hair_short_01", "clothing_peasant_01", "human_male", "eyes_default_01")
		spawned.append(b)

func _clear() -> void:
	for b in spawned:
		if is_instance_valid(b):
			b.queue_free()
	spawned.clear()

func _count_subviewports() -> int:
	return find_children("*", "SubViewport", true, false).size()
