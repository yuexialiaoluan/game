# ADR-019：World Interaction Bridge

- 问题：Gameplay 交互对象与 3D 场景节点如何解耦绑定，并支持 Save/Load 与检测。
- 候选方案：场景节点直接保存状态；NodePath 引用；稳定 Object ID + Bridge + WorldState。
- 最终方案：`Interactable3D` 桥接到 `InteractableObject`，稳定 Object ID，状态存 WorldState，`InteractionDetector` 负责发现。
- 选择原因：解耦、可重载、可保存、可扩展，避免 NodePath 依赖。
- 优缺点：优点是稳定与可维护；缺点是需维护对象注册与状态恢复。
- 未来影响：NPC/Chest/Door/Resource/Fishing 等统一接入；Quest/Dialogue 通过事件/服务复用。
