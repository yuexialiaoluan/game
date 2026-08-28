# Enemy / Creature 架构

## 原则
Enemy 与 Creature 都是 Actor 的配置化实例，不建独立角色系统。

## 数据
- `CreatureDefinition`：种族、基础属性、技能、掉落表、AI 配置。
- `EnemyDefinition`：可战斗单位配置（阵营、是否可投降/逃跑/谈判/招募、战斗 AI 风格）。
- 模板支持随机生成，统一走 RNG。

## 状态转换
敌人可进入投降、逃跑、求饶、谈判、被俘、招募等状态，由数据与 Condition/Effect 驱动。

## 依赖
Actor、Character、Combat、AI、Loot、RNG、Recruitment、Save。
