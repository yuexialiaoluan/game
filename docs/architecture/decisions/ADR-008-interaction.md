# ADR-008：统一交互

- 问题：NPC/宝箱/门/采集点/钓鱼点/工作台等交互是否各自实现。
- 候选方案：每种物体一套交互逻辑；继承 Interactable 的类族；统一 Interactable + Interaction Options。
- 最终方案：统一 `Interactable → Interaction Options`，选项由数据 + Condition/Effect 驱动。
- 选择原因：避免系统爆炸，复用偷窃/开锁/采集/钓鱼/制作等 Action。
- 优缺点：优点是扩展统一；缺点是需要抽象好选项与上下文。
- 未来影响：偷窃/开锁/采集/钓鱼/制作/对话等通过 Interaction 接入。
