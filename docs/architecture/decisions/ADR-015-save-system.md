# ADR-015：Save 系统

- 问题：如何可靠地保存/恢复单机 RPG 运行状态，并支持版本迁移与多槽位。
- 候选方案：序列化 Scene Tree；直接保存 Godot Resource；显式 SaveGameData DTO + 版本化 JSON。
- 最终方案：显式 SaveGameData DTO + JSON + SaveVersion + 原子写入 + 迁移链。
- 选择原因：避免 Scene Tree 依赖、可迁移、易校验、可 diff、稳定。
- 优缺点：优点是稳定与可维护；缺点是需为每个系统维护序列化映射。
- 未来影响：Actor/GameState/WorldState/StoryFlag 均通过 DTO 保存；新增字段走版本迁移；NPC 后续可用 Template+Seed+差分优化。
