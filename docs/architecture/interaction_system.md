# Interaction 系统

## 职责
统一 `Actor → Interactable → Available Actions`，对象只声明“它是什么”，具体执行走 Action。

## 数据
- `data/interactions/interactions.json`：对象类型 → 可用 Action 列表。
- `InteractionService`：注册对象、发现目标、按 Condition 生成可用 Actions。

## 对象
`InteractableObject`：id / object_type / state / data；状态进入 WorldState，不保存 Scene Node。

## World Bridge
3D Interactable3D 通过 egister_to() 桥接到 InteractableObject，见 world_interaction_bridge.md。

## NPC
Talk/Recruit/Persuade/Release 等经 ActionService，不写死 NPC 脚本。

## Encounter
敌对 NPC 不立即战斗，Talk/Persuade/Intimidate/Escape 由 Action 生成。
