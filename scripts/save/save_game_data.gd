class_name SaveGameData
extends RefCounted

const CURRENT_SAVE_VERSION := 1

var save_version: int = CURRENT_SAVE_VERSION
var game_version: String = "0.1.0"
var timestamp: int = 0
var game_mode: String = "story"
var player_id: String = ""
var game_state: Dictionary = {}
var actors: Dictionary = {}
var party: Array = []
var reserve_party: Array = []
var time_state: Dictionary = {}
var weather: String = "clear"
var weather_state: Dictionary = {}
var rng_state: int = 0

func to_dict() -> Dictionary:
	return {
		"save_version": save_version,
		"game_version": game_version,
		"timestamp": timestamp,
		"game_mode": game_mode,
		"player_id": player_id,
		"game_state": game_state,
		"actors": actors,
		"party": party,
		"reserve_party": reserve_party,
		"time_state": time_state,
		"weather": weather,
		"weather_state": weather_state,
		"rng_state": rng_state,
	}

static func from_dict(d: Dictionary) -> SaveGameData:
	var data := SaveGameData.new()
	data.save_version = int(d.get("save_version", CURRENT_SAVE_VERSION))
	data.game_version = str(d.get("game_version", ""))
	data.timestamp = int(d.get("timestamp", 0))
	data.game_mode = str(d.get("game_mode", "story"))
	data.player_id = str(d.get("player_id", ""))
	data.game_state = d.get("game_state", {}) as Dictionary
	data.actors = d.get("actors", {}) as Dictionary
	data.party = d.get("party", []) as Array
	data.reserve_party = d.get("reserve_party", []) as Array
	data.time_state = d.get("time_state", {}) as Dictionary
	data.weather = str(d.get("weather", "clear"))
	data.weather_state = d.get("weather_state", {}) as Dictionary
	data.rng_state = int(d.get("rng_state", 0))
	return data

