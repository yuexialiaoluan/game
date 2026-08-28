# Stealth / Crime / Law 架构（接口）

## Stealth
- 考虑：潜行、视野、光照、噪音、隐蔽、NPC 警觉度、搜索、发现、追捕。
- 被偷窃、潜入、战斗、地下城、任务、NPC AI 共同使用。
- 当前只设计接口，不实现完整潜行。

## Crime / Law
- 未来支持：偷窃、伤害 NPC、杀人、破坏、闯入、逃犯、通缉、罚款、监禁、守卫追捕。
- 设计 `CrimeRecord`、`CrimeDefinition`、`LawService` 接口。
- 当前不实现完整法律系统，只保留扩展点。

## 与 Lockpicking
- Lock + Lockpicking Action：普通/高级/魔法/特殊锁。
- 失败效果：消耗工具、触发陷阱、提高警觉、锁定。
- 由 Condition/Effect 驱动。

## 依赖
Condition/Effect、AI（警觉）、Faction/Reputation、Event、WorldState、Save。
