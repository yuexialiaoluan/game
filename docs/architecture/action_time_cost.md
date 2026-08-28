# Action Time Cost

## 目标
统一的行动时间消耗：`Gameplay Action → Time Cost → TimeService.advance() → EventBus`。

## 数据结构（data/time/action_time_costs.json）
- `action_id`、`name`、`cost_type`（fixed/random）、`base_minutes`、`random_min/random_max`、`modifiers`。

## 计算
- `ActionTimeCost.compute(def, ctx, rng)`：
  - fixed 用 base；random 用 RNG 在 min/max 取。
  - modifiers 为 percent 或 add，条件用 ConditionEvaluator 判断。
  - final = base × (1 + sum_percent/100) + sum_add。

## 未来扩展
Fishing/Crafting/Travel/Dungeon/Stealth/Crime/Training/Sleep 统一使用。
