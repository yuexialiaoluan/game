# ADR-022：Navigation / Stealth / Detection / Crime / Encounter

- 问题：战斗前如何建立“发现/接近/潜行/逃跑/犯罪/遭遇”基础。
- 候选方案：各系统独立实现；统一服务 + Condition/Effect/Event + Modifier。
- 最终方案：Navigation/Stealth/Detection/Noise/Crime/Escape/Encounter 服务化，复用现有系统。
- 选择原因：解耦、可扩展、可保存，未来接 Combat。
- 优缺点：优点是统一入口；缺点是初版逻辑为简化实现。
- 未来影响：开放世界探索、潜行、犯罪与战斗遭遇都基于此。
