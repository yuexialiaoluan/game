class_name EvaluatorContext
extends RefCounted

## Condition/Effect 求值上下文：从中取得 Player/Actor/Party/GameState 等。
var game_state: GameState
var actors: Dictionary = {}
var player: Actor = null
var party: Array = []
var event_bus = null

var location: String = ""
var time: float = 12.0
var date: int = 1
var season: String = "spring"
var weather: String = "clear"
var distance: float = 0.0
var combat_state: String = ""
var stealth_state: String = ""
var crime_state: String = ""
var surrender_state: String = ""
var captured_state: String = ""
