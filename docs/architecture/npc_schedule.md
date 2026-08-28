# NPC Schedule

## 职责
数据驱动日程（data/npcs/schedules.json），按 TimeService 小时解析当前 activity/location；事件驱动更新，不逐帧轮询。

## Navigation
Location 目标交给 NavigationService，不用 NodePath 持久化。
