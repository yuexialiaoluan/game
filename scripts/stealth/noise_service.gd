class_name NoiseService
extends RefCounted

var bus: EventBus = null
var last_noise: Dictionary = {}

func setup(p_bus: EventBus = null) -> void:
	bus = p_bus

func emit_noise(source: String, pos: Vector3, radius: float, intensity: float, type: String) -> void:
	last_noise = { "source": source, "position": pos, "radius": radius, "intensity": intensity, "type": type }
	if bus != null:
		bus.emit("noise", last_noise)
