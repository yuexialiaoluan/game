class_name TimeData
extends RefCounted

const CALENDAR_PATH := "res://data/time/calendar.json"
const ACTIONS_PATH := "res://data/time/action_time_costs.json"
const WEATHER_PATH := "res://data/weather/weather_defs.json"

var calendar: Dictionary = {}
var action_costs: Dictionary = {}
var weather: Dictionary = {}

func _init() -> void:
	calendar = _load(CALENDAR_PATH)
	action_costs = _load(ACTIONS_PATH)
	weather = _load(WEATHER_PATH)

func _load(path: String) -> Dictionary:
	if not FileAccess.file_exists(path):
		push_error("TimeData: missing " + path)
		return {}
	var text := FileAccess.get_file_as_string(path)
	var data = JSON.parse_string(text)
	if data is Dictionary:
		return data
	return {}

func get_action(id: String) -> Dictionary:
	return action_costs.get(id, {}) as Dictionary
