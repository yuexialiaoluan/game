class_name NavigationService
extends RefCounted

## 逻辑导航抽象：点/障碍/路径状态，适配 NavigationAgent 后可替换实现。
var points: Dictionary = {}
var obstacles: Array = []
var positions: Dictionary = {}
var targets: Dictionary = {}

func add_point(id: String, pos: Vector3) -> void:
	points[id] = pos

func add_obstacle(center: Vector3, radius: float) -> void:
	obstacles.append({ "center": center, "radius": radius })

func set_position(actor_id: String, pos: Vector3) -> void:
	positions[actor_id] = pos

func request(actor_id: String, target_id: String) -> String:
	if not points.has(target_id):
		return "Failed"
	var from: Vector3 = positions.get(actor_id, Vector3.ZERO)
	var to: Vector3 = points[target_id]
	if from.distance_to(to) < 0.05:
		return "Arrived"
	if _line_blocked(from, to):
		return "Blocked"
	targets[actor_id] = target_id
	return "Moving"

func step(actor_id: String, delta: float) -> String:
	var target_id: String = str(targets.get(actor_id, ""))
	if target_id == "" or not points.has(target_id):
		return "Idle"
	var from: Vector3 = positions.get(actor_id, Vector3.ZERO)
	var to: Vector3 = points[target_id]
	var speed := 3.0
	if from.distance_to(to) <= speed * delta:
		positions[actor_id] = to
		return "Arrived"
	var dir := (to - from).normalized()
	positions[actor_id] = from + dir * speed * delta
	return "Moving"

func _line_blocked(from: Vector3, to: Vector3) -> bool:
	var seg := to - from
	var len := seg.length()
	if len < 0.001:
		return false
	var dir := seg / len
	for obs in obstacles:
		var center: Vector3 = obs.get("center", Vector3.ZERO)
		var radius := float(obs.get("radius", 1.0))
		var rel := center - from
		var t := clampf(rel.dot(dir), 0.0, len)
		var closest := from + dir * t
		if closest.distance_to(center) < radius:
			return true
	return false
