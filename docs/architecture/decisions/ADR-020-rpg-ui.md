# ADR-020：RPG UI 与服务层

- 问题：Character/Party/Inventory/Equipment 如何游戏化并呈现，且 UI 与 Gameplay 解耦。
- 候选方案：UI 直接改数据；UI 经 Service + EventBus。
- 最终方案：CharacterService/PartyService/InventoryService/EquipmentService + RPGUI 只读/发意图。
- 选择原因：复用现有 Condition/Effect/Event/Save/Appearance，UI 不复制逻辑。
- 优缺点：优点是解耦与可测试；缺点是初期服务层较多。
- 未来影响：正式 UI、背包、角色面板、战斗编队都基于这些服务。
