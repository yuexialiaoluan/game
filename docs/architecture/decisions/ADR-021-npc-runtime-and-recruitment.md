# ADR-021：NPC Runtime 与 Recruitment

- 问题：NPC 如何成为有日程/关系/招募/投降的动态 Actor，且不按类型写死。
- 候选方案：HostileNPC/NeutralNPC/CompanionNPC 多套；统一 Actor + NPCRuntime + Disposition。
- 最终方案：Actor 存通用角色数据；NPCRuntime 存行为状态；Disposition 可变；Recruitment/Surrender 用 Condition+Effect。
- 选择原因：复用现有 Actor/Condition/Effect/Party/Save，支持状态转换。
- 优缺点：优点是统一与可扩展；缺点是需维护 NPC 状态与 Save。
- 未来影响：战斗/城镇/阵营/怪物招募都基于此。
