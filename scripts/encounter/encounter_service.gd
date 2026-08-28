class_name EncounterService
extends RefCounted

var bus: EventBus = null

func setup(p_bus: EventBus = null) -> void:
	bus = p_bus

func resolve(actor: Actor, ctx: EvaluatorContext, choice: String) -> String:
	var outcome := "Avoided"
	match choice:
		"attack":
			outcome = "CombatStarted"
		"persuade", "intimidate", "bribe":
			outcome = "Negotiated"
		"escape":
			outcome = "Escaped"
		"talk":
			outcome = "Avoided"
	if actor.state == "Surrendered":
		outcome = "Surrendered"
	if bus != null:
		bus.emit("encounter_resolved", { "actor": actor.id, "outcome": outcome })
	return outcome
