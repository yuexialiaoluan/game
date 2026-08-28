class_name InventoryService
extends RefCounted

var db: GameplayDB
var bus: EventBus = null

func setup(p_db: GameplayDB, p_bus: EventBus = null) -> void:
	db = p_db
	bus = p_bus

func add_item(owner: Actor, item_id: String, qty: int) -> void:
	owner.add_item(item_id, qty)
	_emit(owner)

func remove_item(owner: Actor, item_id: String, qty: int) -> bool:
	return owner.remove_item(item_id, qty)

func use_item(owner: Actor, item_id: String, ctx: EvaluatorContext) -> bool:
	if int(owner.inventory.get(item_id, 0)) <= 0:
		return false
	var def := db.get_item(item_id)
	if def.is_empty():
		return false
	for eff in def.get("effects", []):
		EffectExecutor.execute(eff, ctx)
	owner.remove_item(item_id, 1)
	if bus != null:
		bus.emit("item_used", { "item_id": item_id, "owner": owner.id })
	return true

func _emit(owner: Actor) -> void:
	if bus != null:
		bus.emit("inventory_changed", { "owner": owner.id })
