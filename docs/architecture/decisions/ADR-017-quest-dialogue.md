# ADR-017：Quest / Dialogue / NPC Background

- 问题：任务、对话与 NPC 背景如何建立，并与 Condition/Effect/Event/Save 解耦复用。
- 候选方案：各系统各自实现逻辑；统一数据 + Condition/Effect + EventBus。
- 最终方案：Quest/Dialogue/Background 均为数据驱动，复用 ConditionEvaluator、EffectExecutor、EventBus、Time/Weather、Save。
- 选择原因：低耦合、可扩展、文本与逻辑分离、随机可重现。
- 优缺点：优点是复用与可维护；缺点是初期需要定义数据 schema。
- 未来影响：Quest/Dialogue 内容、NPC 招募、个人任务都基于此扩展。
