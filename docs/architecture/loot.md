# Loot 系统

## 支持
怪物掉落、宝箱、地下城奖励、任务奖励、随机掉落、稀有掉落。

## 原则
掉落表数据驱动。

## 数据
- `LootTableDefinition`：条目（Item ID、权重、数量范围、条件、稀有度）。
- 可嵌套/组合掉落表。

## 流程
`LootAction` → 根据 RNG 从掉落表抽取 → 生成 ItemInstance → 进入背包/容器。

## 依赖
RNG、Item、Condition/Effect、Event、Save。
