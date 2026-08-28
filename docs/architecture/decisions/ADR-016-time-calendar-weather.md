# ADR-016：Time / Calendar / Weather 与行动推进时间

- 问题：游戏时间如何推进，天气如何变化，并与 Condition/Effect/Save 集成。
- 候选方案：实时世界时间；仅地图移动推进时间；行动推进时间 + 事件驱动。
- 最终方案：Gameplay Action 推进时间；Calendar 为游戏自历法；Weather 按游戏时间持续并按区域用 RNG 切换。
- 选择原因：符合单机 RPG 节奏，避免挂机/走路刷时间；数据驱动、事件解耦、可保存。
- 优缺点：优点是可预测、可设计、可保存；缺点是需为每个玩法配置 time cost。
- 未来影响：NPC 日程/商店/钓鱼/潜行/任务/世界事件都基于 Time/Weather 事件驱动。
