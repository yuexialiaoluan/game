# World Interaction Bridge

## 目标
把 Gameplay 层 `InteractableObject` 与表现层 `Interactable3D` 自动绑定。

## 机制
- `Interactable3D` 持有稳定 `object_id` / `object_type`，调用 `register_to(service, ctx)` 创建/注册 Gameplay `InteractableObject`。
- 场景重新加载后重新注册；状态从 `WorldState` 恢复，不使用 NodePath 作为持久化 ID。

## 检测
- `InteractionDetector`：注册表 + 距离过滤，不每帧遍历整个场景树；未来可换 Area3D/空间分区。

## UI
- `InteractionUI` 只显示 Action 与反馈，调用 `ActionService`；不直接修改 GameState/WorldState/TimeService。
