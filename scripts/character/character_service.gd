class_name CharacterService
extends RefCounted

var bus: EventBus = null

func setup(p_bus: EventBus = null) -> void:
	bus = p_bus

func allocate_attribute(actor: Actor, stat: String) -> bool:
	if actor.progression.attribute_points <= 0:
		return false
	actor.progression.attribute_points -= 1
	actor.set_base(stat, actor.get_base_stat(stat) + 1.0)
	actor.recalculate()
	_emit(actor)
	return true

func _emit(actor: Actor) -> void:
	if bus != null:
		bus.emit("character_changed", { "actor": actor.id })
