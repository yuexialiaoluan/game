class_name ShopService
extends RefCounted

var catalog: Dictionary = {}
var bus: EventBus = null

func setup(p_bus: EventBus = null) -> void:
	bus = p_bus
	catalog = {
		"healing_potion": 20,
		"iron_ore": 5,
		"wood": 3,
		"fish_common": 8,
		"fish_rare": 48,
		"goblin_tooth": 12,
		"mana_dust": 18,
		"weapon_wood_sword_01": 30,
		"shield_wood_01": 36,
		"armor_leather_01": 75
	}

func buy(actor: Actor, item_id: String, ctx: EvaluatorContext) -> bool:
	var price := int(catalog.get(item_id, 0))
	if price <= 0:
		return false
	var gold := float(ctx.game_state.economy_state.get("gold", 0.0))
	if gold < price:
		return false
	ctx.game_state.economy_state["gold"] = gold - price
	actor.add_item(item_id, 1)
	if bus != null:
		bus.emit("shop_purchased", { "item": item_id, "price": price })
	return true

func sell(actor: Actor, item_id: String, qty: int, ctx: EvaluatorContext) -> bool:
	if int(actor.inventory.get(item_id, 0)) < qty:
		return false
	actor.remove_item(item_id, qty)
	var price := int(catalog.get(item_id, 0))
	ctx.game_state.economy_state["gold"] = float(ctx.game_state.economy_state.get("gold", 0.0)) + price * qty * 0.5
	return true
