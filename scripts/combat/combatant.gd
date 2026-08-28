class_name Combatant
extends RefCounted

var actor: Actor
var team: String = ""
var position: Vector2i = Vector2i.ZERO
var movement_remaining: int = 3
var actions_remaining: int = 1
var initiative: int = 0
var alive: bool = true
