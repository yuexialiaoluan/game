# NPC AI / Behavior 系统

## 原则
NPC AI 读取 World Time、Location、Quest、Faction、Relationship、World State，而不是写死。

## 组成
- `Schedule`：日程（起床 → 工作 → 吃饭 → 酒馆 → 回家 → 睡觉）。
- `Goal`：当前目标。
- `BehaviorState`：行为状态（巡逻、工作、交易、战斗、逃跑、投降、对话等）。
- `Perception`（未来）：用于潜行/视野/噪音/警觉。

## 实现建议
- 用轻量行为树/状态机组织，状态与转移可数据化。
- AI 决策请求通过服务接口，不直接改世界状态。

## 与 Stealth/Crime 接口
AI 可输出警觉度、追捕、呼叫守卫等事件，供未来 Stealth/Crime 使用（当前仅架构）。

## 依赖
Time、Location、Quest、Faction/Relationship、WorldState、Actor、Combat（战斗 AI 见 `combat_system.md`）。
