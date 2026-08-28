# Quest 与 Dialogue 系统

## Quest
- 类型：主线、支线、NPC 个人任务、公会任务、阵营任务、隐藏任务、动态任务、随机任务。
- `QuestDefinition`：阶段、目标、条件、奖励。
- 目标类型：对话、杀敌、探索、收集、采集、钓鱼、偷窃、护送、救援、招募、逃跑、调查、潜入、交易。
- 任务文本与任务逻辑分离；文本走本地化 key。

## Quest 状态
- `QuestState`：未接取、进行中、已完成、失败、已放弃，以及各目标进度。
- 进度由事件推进，不硬编码。

## Dialogue
- `DialogueDefinition`：节点、选项、分支。
- 每个选项带 Condition 与 Effect。
- 支持普通对话、威吓、说服、欺骗、谈判。
- 示例：“把东西交出来” 的 Condition=Intimidation>=10，Effect=NPC 交出物品。
- 文本与逻辑分离。

## 依赖
Condition/Effect、Event、Localization、Faction/Relationship、WorldState、Save。
