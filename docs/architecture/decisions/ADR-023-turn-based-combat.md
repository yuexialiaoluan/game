# ADR-023：战棋回合制战斗

- 问题：如何建立最小可运行战棋战斗。
- 候选方案：实时战斗；数据驱动回合制；复杂战棋。
- 最终方案：CombatInstance + Grid + Turn + Damage + Skill/Status + AI，复用 Actor/Condition/Effect/RNG/Time/Surrender/Escape/Encounter。
- 选择原因：满足定位、可测试、可扩展。
- 优缺点：优点是复用与清晰；缺点是首版简化。
- 未来影响：Combat UI、Camera、Boss AI、技能系统都基于此。
