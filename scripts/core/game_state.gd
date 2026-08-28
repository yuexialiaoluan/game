class_name GameState
extends RefCounted

## 运行时游戏状态根对象，子状态结构化保存。
var story_flags: StoryFlagStore
var world: WorldState
var player_state: Dictionary = {}
var party_state: Dictionary = {}
var quest_state: Dictionary = {}
var dialogue_state: Dictionary = {}
var relationship_state: Dictionary = {}
var faction_state: Dictionary = {}
var economy_state: Dictionary = {}
var time_state: Dictionary = {}
var weather_state: Dictionary = {}
var npc_state: Dictionary = {}
var crime_state: Dictionary = {}
var stealth_state: Dictionary = {}
var suspicion_state: Dictionary = {}
var encounter_state: Dictionary = {}
var event_state: Dictionary = {}
var settings_state: Dictionary = {}

func _init() -> void:
	story_flags = StoryFlagStore.new()
	world = WorldState.new()

func to_dict() -> Dictionary:
	return {
		"story_flags": story_flags.to_dict(),
		"world": world.to_dict(),
		"player_state": player_state.duplicate(),
		"party_state": party_state.duplicate(),
		"quest_state": quest_state.duplicate(),
		"dialogue_state": dialogue_state.duplicate(),
		"relationship_state": relationship_state.duplicate(),
		"faction_state": faction_state.duplicate(),
		"economy_state": economy_state.duplicate(),
		"time_state": time_state.duplicate(),
		"weather_state": weather_state.duplicate(),
		"npc_state": npc_state.duplicate(),
		"crime_state": crime_state.duplicate(),
		"stealth_state": stealth_state.duplicate(),
		"suspicion_state": suspicion_state.duplicate(),
		"encounter_state": encounter_state.duplicate(),
		"event_state": event_state.duplicate(),
		"settings_state": settings_state.duplicate(),
	}

func from_dict(d: Dictionary) -> void:
	story_flags.from_dict(d.get("story_flags", {}) as Dictionary)
	world.from_dict(d.get("world", {}) as Dictionary)
	player_state = (d.get("player_state", {}) as Dictionary).duplicate()
	party_state = (d.get("party_state", {}) as Dictionary).duplicate()
	quest_state = (d.get("quest_state", {}) as Dictionary).duplicate()
	dialogue_state = (d.get("dialogue_state", {}) as Dictionary).duplicate()
	relationship_state = (d.get("relationship_state", {}) as Dictionary).duplicate()
	faction_state = (d.get("faction_state", {}) as Dictionary).duplicate()
	economy_state = (d.get("economy_state", {}) as Dictionary).duplicate()
	time_state = (d.get("time_state", {}) as Dictionary).duplicate()
	weather_state = (d.get("weather_state", {}) as Dictionary).duplicate()
	npc_state = (d.get("npc_state", {}) as Dictionary).duplicate()
	crime_state = (d.get("crime_state", {}) as Dictionary).duplicate()
	stealth_state = (d.get("stealth_state", {}) as Dictionary).duplicate()
	suspicion_state = (d.get("suspicion_state", {}) as Dictionary).duplicate()
	encounter_state = (d.get("encounter_state", {}) as Dictionary).duplicate()
	event_state = (d.get("event_state", {}) as Dictionary).duplicate()
	settings_state = (d.get("settings_state", {}) as Dictionary).duplicate()



