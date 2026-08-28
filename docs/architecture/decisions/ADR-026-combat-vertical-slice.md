# ADR-026：Combat Vertical Slice

- 问题：如何交付第一份可玩战斗切片。
- 候选方案：继续抽象；做一个最小可玩 4v4。
- 最终方案：10×10 场景 + Raycast/Input + 3 技能 + Burn + AI Profile + Loot/XP + 三种结束返回 World。
- 选择原因：验证完整战斗闭环。
- 优缺点：优点是闭环可玩；缺点是美术/动画为占位。
- 未来影响：正式战斗、技能、Boss、AI 在此基础上扩展。
