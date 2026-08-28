# Quest Objective

## 数据驱动目标
- 每个 objective：`id`、`type`、`item/target/location` 等、`target`、`progress`。
- `QuestService.progress_objective(quest_id, objective_id, amount, ctx)` 累加进度，达到 target 即完成该目标。

## 类型
Talk、Kill、Collect、Deliver、Explore、Discover、Harvest、Fish、Steal、Escort、Rescue、Recruit、Survive、Investigate、Travel、Craft、Use Item、Reach Location。

## 扩展
新增 Objective 类型不修改已有任务，只需在 QuestService/Effect 层注册。
