# Crafting 系统

## 支持
武器制作、防具制作、药水、食物、材料加工。

## 原则
配方数据驱动；不把“铁剑需要 3 铁矿”写进 Crafting 代码。

## 数据
- `RecipeDefinition`：材料（Item ID + 数量）、产物、数量、条件（等级/技能/地点/时间）、消耗、成功/失败效果。
- 材料与产物引用 ItemDefinition。

## 流程
`CraftAction` → 校验 Condition → 扣除材料 → 产出物品 → 触发事件/经验/成就。

## 依赖
Condition/Effect、Item、RNG（随机结果/品质）、Event、Save。
