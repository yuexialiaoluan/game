# ADR-024：Combat Presentation

- 问题：如何把纯逻辑 Combat 变成可操作的 3D 战斗。
- 候选方案：逻辑与表现混合；Combat Gameplay / Presentation / Input 分层。
- 最终方案：Grid3D/UnitView/Camera/UI/Input 分层，复用 CombatInstance。
- 选择原因：解耦、可测试、可替换表现。
- 优缺点：优点是清晰；缺点是首版 UI 简化。
- 未来影响：正式战斗 UI/动画/Camera 基于此。
