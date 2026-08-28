# ADR-018：Interaction / Action / Outcome

- 问题：高自由度行为（交谈/开锁/偷窃/采集/钓鱼/说服/睡眠等）如何统一。
- 候选方案：每种玩法独立脚本；统一 Action 数据 + Condition/Effect/RNG/Time/Event。
- 最终方案：Interaction 生成可用 Action；ActionService 统一解析；统一 ActionOutcome。
- 选择原因：复用已有基础设施，低耦合，可扩展，可保存。
- 优缺点：优点是统一与可维护；缺点是需约束 Action 数据 schema。
- 未来影响：Quest/Dialogue/Stealth/Crime/Fishing/Gathering 都通过 Action 入口。
