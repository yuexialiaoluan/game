# Gathering / Harvesting 系统

## 支持
矿石、木材、草药、食材、怪物材料、特殊资源。

## 资源点
- 可重生。
- 可根据时间、天气、世界状态变化。

## 设计
- `ResourceNodeDefinition`：类型、产出表、刷新规则、条件。
- 采集动作走 Interaction（Harvest）+ Condition/Effect。
- Talent 可影响采集。

## 依赖
Condition/Effect、RNG、Time/Weather、WorldState、Item、Event、Save。
