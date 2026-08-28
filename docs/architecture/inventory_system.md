# Inventory 系统

## 职责
`InventoryService`：添加/移除/查询/使用物品；物品数据在 `data/items/items.json`（含 type/rarity/weight/value/description/effects）。

## 使用流程
`Inventory UI → InventoryService.use_item() → EffectExecutor → 状态变化 → Inventory -1 → EventBus`。
