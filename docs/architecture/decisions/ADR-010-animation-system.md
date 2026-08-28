# ADR-010：统一动画系统

- 问题：动画状态与播放由谁管理，如何与 Gameplay 解耦。
- 候选方案：Player/NPC/Combat 各自实现动画；共享动画控制器 + 意图接口。
- 最终方案：共享 AnimationController，Gameplay 只发意图（如 play_attack_animation）。
- 选择原因：避免重复实现，便于状态切换与扩展动作。
- 优缺点：优点是统一与解耦；缺点是需约定意图与状态映射。
- 未来影响：Retargeting 基于骨架，不因骨架差异重写动画系统。
