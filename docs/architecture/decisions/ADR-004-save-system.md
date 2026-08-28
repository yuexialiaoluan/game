# ADR-004：存档

- 问题：如何持久化大型世界状态。
- 候选方案：序列化 Scene Tree；Godot Resource 直接保存；显式 SaveData DTO + 版本化 JSON。
- 最终方案：显式 SaveData DTO + SaveVersion + 迁移，用稳定 ID/GUID。
- 选择原因：避免 Scene Tree 依赖，便于迁移与调试，长期兼容。
- 优缺点：优点是稳定、可迁移；缺点是需要维护序列化映射。
- 未来影响：所有系统提供可序列化状态接口；新增字段走版本迁移。
