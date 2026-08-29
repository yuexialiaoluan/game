class_name PartyService
extends RefCounted

const ACTIVE_MAX := 4
const RESERVE_MAX := 4

var active: Array = []
var reserve: Array = []
var bus: EventBus = null
var shared_inventory_owner: Actor = null

func setup(p_bus: EventBus = null) -> void:
	bus = p_bus

func set_shared_inventory_owner(actor: Actor) -> void:
	shared_inventory_owner = actor

func get_shared_inventory_owner(fallback: Actor = null) -> Actor:
	return shared_inventory_owner if shared_inventory_owner != null else fallback

func get_shared_inventory(fallback: Actor = null) -> Dictionary:
	var owner := get_shared_inventory_owner(fallback)
	return owner.inventory if owner != null else {}

func has_shared_item(item_id: String, fallback: Actor = null) -> bool:
	var owner := get_shared_inventory_owner(fallback)
	return owner != null and owner.has_item(item_id)

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
