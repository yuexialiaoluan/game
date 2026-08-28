# Weather 系统

## 职责
- 按区域管理天气：World → Region → Location → Weather。
- 天气变化由“游戏时间推进”驱动，而非现实秒。

## 数据
- `data/weather/weather_defs.json`：天气类型（clear/cloudy/rain/storm/fog/snow）、持续时长范围、区域转移权重。

## API
- `get_weather(region)`、`set_weather(region, id)`、`force_weather(region, id, duration)`、`advance_minutes(minutes)`。

## RNG
- 天气随机统一使用 `RNGService`，支持种子可复现；`rng_state` 随 Save 保存。

## 事件
- `weather_changed`。
