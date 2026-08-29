class_name SettingsService
extends RefCounted

var data: Dictionary = {}

const DEFAULTS := {
	"audio_master": 0.8,
	"audio_music": 0.8,
	"audio_sfx": 0.8,
	"video_fullscreen": false,
	"video_vsync": true,
	"language": "zh"
}

func _init() -> void:
	reset()

func get_value(key: String):
	return data.get(key, DEFAULTS.get(key))

func set_value(key: String, value) -> void:
	data[key] = value

func reset() -> void:
	data = DEFAULTS.duplicate()

func to_dict() -> Dictionary:
	return data.duplicate()

func from_dict(d: Dictionary) -> void:
	data = DEFAULTS.duplicate()
	for key in d:
		data[key] = d[key]
