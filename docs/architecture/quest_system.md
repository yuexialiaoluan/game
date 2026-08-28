# Quest 系统

## 职责
Quest Runtime + Quest Data：任务状态、目标进度、接受/完成/失败/放弃、奖励、日志。

## 数据
- `data/quests/quests.json`：quest 定义（type、accept_conditions、objectives、time/weather_conditions、rewards）。

## 状态
Inactive / Available / Accepted / Active / Completed / Failed / Abandoned / Expired。

## Objective
Talk/Kill/Collect/Deliver/Explore/Discover/Harvest/Fish/Steal/Escort/Rescue/Recruit/Survive/Investigate/Travel/Craft/UseItem/ReachLocation，数据驱动。

## 奖励
复用 EffectExecutor（XP/Gold/Item/Equipment/Material/Skill/Feat/Talent/Relationship/Reputation/Faction/StoryFlag/UnlockLocation）。

## 集成
- 触发/接受/完成用 Condition + Effect。
- `QuestService` 状态通过 `EvaluatorContext.quest_service` 供 Condition 读取。
- Quest Effect 通过 EffectExecutor 的 accept_quest/progress_quest/complete_quest/fail_quest 执行。
- Save 时写入 `GameState.quest_state`。

## Action 接入
Quest Objective 可监听 ction_completed 事件，不复制行动逻辑。

## World Action
Harvest 等 Action 通过 ction_completed 事件推进 Quest Objective。
