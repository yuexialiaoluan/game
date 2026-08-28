# ADR-005：Condition/Effect

- 问题：大量玩法（对话、任务、招募、交互、战斗、事件）的前置与后果如何统一。
- 候选方案：各系统各自实现；共享条件/效果库；事件驱动。
- 最终方案：统一 Condition/Effect 引擎 + Event 总线。
- 选择原因：组合式自由度，内容可配置，降低系统耦合。
- 优缺点：优点是扩展性与复用；缺点是需要设计好上下文与序列化。
- 未来影响：Interaction/Quest/Dialogue/Recruitment/Combat/Crafting 等全部基于它。
