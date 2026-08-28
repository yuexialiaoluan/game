# Condition / Effect 系统

## 定位
全项目最重要的基础系统之一，大量玩法由此组合。

## Condition 支持域
Level、Attribute、Class、Race、Skill、Feat、Talent、Item、Currency、Quest、Story Flag、Relationship、Reputation、Faction、Location、Time、Date、Weather、World State、Combat State、HP、Status Effect、NPC State、Equipment、Inventory、Crime、Stealth。

## 运算
- 组合：AND / OR / NOT。
- 比较：`==`、`!=`、`>`、`>=`、`<`、`<=`。
- 范围：`between`、`in_set`。
- 数据结构可序列化，便于在 Resource/JSON 中配置。

## Effect 支持域
获得经验/金币/物品、消耗物品、学习技能、获得 Feat、修改属性、修改关系、修改 Faction Reputation、加入/离开 Party、修改 Quest、修改 Story Flag、修改 World State、传送、修改时间/天气、触发 Dialogue/Event、解锁地点、修改 NPC 状态、修改商店、触发/结束战斗、逃跑、投降。

## 执行模型
- `ConditionEvaluator.evaluate(condition, context) -> bool`
- `EffectExecutor.execute(effect, context)`
- context 提供“执行者、目标、世界状态、RNG、事件总线”等。

## 约束
- 系统只认识通用条件/效果类型，不包含具体内容。
- 具体条件/效果按类型注册，新增类型不改核心调度。

## 依赖
Event、RNG（随机效果）、Content Database、Save（状态写入）。
