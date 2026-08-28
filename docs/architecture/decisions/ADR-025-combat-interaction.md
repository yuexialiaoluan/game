# ADR-025：Combat Interaction

- 问题：如何让玩家用鼠标/键盘完整操作战斗，且不破坏 Combat 逻辑。
- 候选方案：UI 直接调用 CombatService；InputController + Selection 状态机。
- 最终方案：CombatInputController + Selection State + Range/Target/Log 分离。
- 选择原因：输入/表现/逻辑解耦，可测试。
- 优缺点：优点是清晰可扩展；缺点是初版交互简化。
- 未来影响：正式战斗 UI/AoE/技能目标都基于此。
