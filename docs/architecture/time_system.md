# Time 系统

## 核心机制
本游戏采用“Gameplay Action 推进时间”，不是实时世界时间。只有有意义的行动（睡觉/钓鱼/制作/采集/旅行等）才推进游戏时间。

## 职责
- 当前日期/时间、推进、暂停/恢复、查询、时间变化事件。
- `advance_minutes()`、`advance_hours()`、`advance_days()`。
- `get_current_time/date/day/weekday/season/day_phase`。

## Action Time Cost
- 统一 `ActionTimeCost.compute(def, ctx, rng)`：`base + modifiers -> final minutes`。
- 支持 fixed / random，以及 percent/add 修正（Talent/队伍/天气/世界状态）。
- `TimeService.advance_action(action_id, td, ctx, rng)`：Gameplay Action → Time Cost → advance → EventBus。

## 暂停
- 主菜单/背包/角色面板/地图/普通 UI/对话选择默认不推进时间。
- `set_paused()` / `is_paused()`。

## 事件
- `time_changed`、`day_changed`、`month_changed`、`season_changed`、`day_phase_changed`、`time_advance_completed`。

## Action 接入
Time Action 通过 ActionService 使用 TimeService 推进时间。
