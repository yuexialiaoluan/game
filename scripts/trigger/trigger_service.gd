class_name TriggerService
extends RefCounted

var registry: EventRegistry

func setup(trigger_defs: Array) -> void:
	registry = EventRegistry.new()
	registry.events = trigger_defs

func dispatch(trigger: String, ctx: EvaluatorContext) -> int:
	return registry.dispatch(trigger, ctx)
