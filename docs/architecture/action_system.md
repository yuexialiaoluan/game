# Action 系统

## 职责
统一 Action 定义与解析：Request → Conditions → Target Validation → RNG → Outcome → Effects → Time → Event。

## 数据
- `data/actions/actions.json`：action_id、display_name、icon、conditions、effects、time_cost、animation、sfx、vfx、target_type、risk、success_mode、modifiers。

## Instant vs Time
- Instant Action：打开菜单/检查等，不推进时间。
- Time Action：钓鱼/采集/制作/睡眠等，复用 `TimeService`。

## Resolution
`ActionService.resolve(action_id, source, target, ctx, rng)` 返回 `{outcome, chance, roll, time_cost_minutes}`，并派发 `action_completed`。

## UI
InteractionUI 显示 Action 与反馈并调用 ActionService，不直接改状态。

## Surrender
Surrender 结果改变 Disposition，供后续 Recruit/Release。

## Stealth/Crime
Sneak/Steal 经 ActionService，结果走 Crime/Detection 事件。
