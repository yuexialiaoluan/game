# World 系统

## 组成
- 大陆、国家、城市、村庄、道路、森林、山脉、河流、地下城、危险区域、特殊地点。
- `LocationDefinition`：地点静态数据（ID、类型、区域、可进入条件、入口/出口、初始状态）。
- `WorldState`：动态状态（村庄被毁、NPC 死亡、城市被占领、道路封锁、商店关闭、阵营战争、地下城被探索等）。
- `GameState`：玩家与世界状态的根对象，可整体存档。

## 原则
- 所有重要世界状态进入 GameState/WorldState 并可保存。
- 世界状态变化通过 Event/Effect 驱动，而不是散落在场景里。
- 地点与内容解耦，未来可流式加载。

## 场景流式加载
见 `scene_management.md`。当前阶段只定义接口，不实现开放世界加载。

## 依赖
Location、Event、Condition/Effect、Save、Scene Management、Time/Weather。

## Interaction 状态
Interactable 对象状态写入 WorldState，不保存 Scene Node。

## Stealth
Visibility/光照/天气经 WorldState 与 Time/Weather 服务影响检测。
