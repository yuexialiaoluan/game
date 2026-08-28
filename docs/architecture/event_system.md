# Event 系统

## 定位
统一事件机制，解耦触发源与响应者。

## 事件类型
World Event、Story Event、NPC Event、Combat Event、Quest Event、Random Event、Location Event。

## 结构
- `EventDefinition`：Trigger + Condition + Effects + 可选监听过滤。
- 运行时 `EventBus`：发布/订阅。
- 模式：`玩家进入地点 → Trigger → Condition → Event → Effect`。

## 用途
剧情推进、世界状态变更、任务更新、随机事件、战斗/经济/天气联动。

## 约束
- 事件处理器不直接操作 UI；只修改状态或发布更细粒度事件。
- 表现层订阅事件刷新显示。

## 依赖
Condition/Effect、RNG、Content Database、Save。
