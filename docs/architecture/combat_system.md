# Combat 系统（战棋式回合制）

## 支持
Grid、Movement、Turn、Action、Attack、Skill、Range、Target、Damage、Healing、Buff、Debuff、Terrain、Status、Death、Surrender、Escape、Combat AI、Battle Result。

## 结构（概念）
- `CombatSession`：一场战斗的容器。
- `CombatUnit`：Actor 的战斗侧数据（位置、行动点/回合、状态）。
- `TurnManager`：回合顺序。
- `ActionResolver`：解析与执行战斗动作。
- `CombatAI`：敌方回合决策，读取目标/状态/技能数据。

## 原则
- Combat 不硬编码具体职业、技能、敌人。
- 技能/效果引用数据定义，由 Condition/Effect 组合执行。
- 投降/逃跑/求饶/谈判/被俘由数据字段控制：`can_surrender`、`can_escape`、`can_negotiate`、`can_recruit`。
- 玩家也可逃离/投降/被俘；“战斗失败不一定 Game Over”在架构上成立。

## 依赖
Actor、Condition/Effect、Item/Skill、RNG、Event、Party（编队与位置）、Save（战斗结果/进行中状态）。
