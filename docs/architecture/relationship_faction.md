# Relationship / Faction / Reputation

## Relationship
- 维度：好感度、信任、恐惧、尊敬、敌意、友好、爱慕（未来）。
- 影响：对话、招募、任务、价格、战斗、背叛、离队、NPC 行为。
- 不写死在 NPC 类；作为 Actor 的可序列化关系数据。

## Faction
- 国家、公会、教会、魔族、强盗、地方势力、其他组织。
- `FactionDefinition` 数据定义。

## Reputation
- 玩家与 Faction 的关系值。
- 影响：商店、NPC、任务、招募、地图、战斗、城市进入、价格、特殊事件。

## 依赖
Actor、Condition/Effect、Event、Save、Economy/Shop、Quest/Dialogue。
