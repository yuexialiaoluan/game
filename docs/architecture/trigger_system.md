# Trigger 系统

## 职责
统一触发：Trigger → Condition → Event → Effect，不各系统重复实现。

## 触发方式
Talk/EnterLocation/LeaveLocation/Interact/Time/Date/Weather/QuestState/StoryFlag/CombatResult/ItemObtained/ItemUsed/EnemyDefeated/NPCStateChanged。

## 实现
- `TriggerService` 复用 `EventRegistry`，加载 `data/triggers/triggers.json`。
- `dispatch(trigger, ctx)` 评估 Condition 后执行 Effect。
