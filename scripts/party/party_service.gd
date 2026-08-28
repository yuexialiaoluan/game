class_name PartyService
extends RefCounted

const ACTIVE_MAX := 4
const RESERVE_MAX := 4

var active: Array = []
var reserve: Array = []
var bus: EventBus = null

func setup(p_bus: EventBus = null) -> void:
	bus = p_bus

func add(actor: Actor) -> bool:
	if active.size() < ACTIVE_MAX:
		active.append(actor)
	elif reserve.size() < RESERVE_MAX:
		reserve.append(actor)
	else:
		return false
	_emit()
	return true

func remove(actor: Actor) -> void:
	active.erase(actor)
	reserve.erase(actor)
	_emit()

func swap(active_index: int, reserve_index: int) -> bool:
	if active_index < 0 or active_index >= active.size():
		return false
	if reserve_index < 0 or reserve_index >= reserve.size():
		return false
	var a = active[active_index]
	active[active_index] = reserve[reserve_index]
	reserve[reserve_index] = a
	_emit()
	return true

func total() -> int:
	return active.size() + reserve.size()

func is_full() -> bool:
	return active.size() == ACTIVE_MAX and reserve.size() == RESERVE_MAX

func _emit() -> void:
	if bus != null:
		bus.emit("party_changed", { "active": active.size(), "reserve": reserve.size() })
