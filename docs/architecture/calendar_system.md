# Calendar 系统

## 职责
游戏自己的历法：年/月/日/星期/季节，不套用现实 365 天。

## 数据
- `data/time/calendar.json`：每月天数、月份名、季节映射、星期、Day Phase。
- 当前为简单测试历法（12 个月 × 30 天）。

## API
- `set_date(year, month, day)`、`get_date()`、`get_current_day()`、`get_current_weekday()`、`get_current_season()`、`get_day_phase(hour)`、`advance_days(n)`。

## 事件
- 跨天/跨月/跨年/季节变化由 CalendarService 返回事件标记，TimeService 负责发事件。
