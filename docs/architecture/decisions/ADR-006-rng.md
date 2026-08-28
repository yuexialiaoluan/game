# ADR-006：随机系统

- 问题：随机（NPC/掉落/钓鱼/事件/地下城/战斗）如何统一与复现。
- 候选方案：各系统各自 RandomNumberGenerator；全局单一 RNG；种子化分域 RNG。
- 最终方案：种子化 RNGService，按领域拆分 stream。
- 选择原因：可复现、可测试、避免互相污染。
- 优缺点：优点是调试友好；缺点是需要约定各域 stream 用法。
- 未来影响：所有随机走 RNGService，测试用固定种子断言。
