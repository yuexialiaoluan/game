# Dungeon 系统

## 支持
固定地下城、随机地下城（未来）、房间、敌人、宝箱、陷阱、Boss、随机事件、战斗、探索、奖励。

## 数据
- `DungeonDefinition`：房间图、入口、敌人配置、宝箱/掉落表、陷阱、事件、Boss、奖励。
- 固定地下城手工配置；随机地下城由生成器 + 模板（未来）。

## 与 Combat/Quest 关系
- 进入地下城触发 `DungeonEvent`。
- 探索/战斗结果通过 Event 更新 Quest 与 WorldState。

## 依赖
Condition/Effect、Combat、Loot、RNG、Event、Scene Management、Save。
