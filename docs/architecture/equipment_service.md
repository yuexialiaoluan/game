# Equipment Service

## 职责
`EquipmentService`：装备/卸下/更换，校验 requirements（用 ConditionEvaluator），通过 `Actor.equip()` 同步 Gameplay + AppearanceResolver。

## 流程
`UI → EquipmentService.equip() → Condition 校验 → Actor 状态 → AppearanceResolver → CharacterVisual → Event`。
