# Recruitment 系统

## 原则
招募统一使用 `Condition + Effect`，不在各系统里写散落的招募逻辑。

## 招募方式
金币雇佣、好感度、完成任务、提交物品、说服、威吓、救援、战斗后招募、投降后招募、驯服、特殊剧情、阵营声望、特殊条件。

## 数据字段（概念）
- `can_recruit`：是否可招募。
- 招募条件：Condition 列表。
- 招募代价/效果：Effect 列表。
- 招募后状态：Companion / PartyMember / Reserve。

## 流程
1. 交互/对话触发 `RecruitAction`。
2. 评估 Condition（好感、任务、物品、声望等）。
3. 执行 Effect（扣金币、改关系、加入队伍等）。
4. 由 Party 系统接管位置分配（出战 4 + 备用 4）。

## 约束
- 特殊 NPC 可固定不可招募；普通 NPC、部分敌人与怪物默认可配置招募可能。
- 不因“是敌人”就永久禁止招募；由 Disposition 与 Condition 决定。

## 依赖
Condition/Effect、Actor、Party、Relationship/Faction、Event、Save。
