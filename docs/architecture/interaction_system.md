# World Interaction 系统

## 原则
不为每种物体写独立交互系统，统一为 `Interactable → Interaction Options`。

## Interactable
地图物体可挂 `Interactable` 组件/数据，包括：NPC、宝箱、门、柜子、书架、桌子、床、椅子、火堆、采集点、钓鱼点、工作台、炼金台、告示牌、门锁、隐藏机关、宝藏、陷阱、环境物品。

## Interaction Options
可能选项：Talk、Open、Loot、Steal、Unlock、Read、Harvest、Fish、Craft、Sleep、Rest、Push、Pull、Use、Inspect。
- 具体选项由数据 + Condition 决定。
- 每个选项绑定一个或多个 Effect。

## 关联系统
- `Steal` → Stealing 系统。
- `Unlock` → Lockpicking 系统。
- `Harvest` → Gathering。
- `Fish` → Fishing。
- `Craft` → Crafting。
- `Talk` → Dialogue。
- `Use` → 环境事件/Effect。

## 依赖
Condition/Effect、Event、Content Database、Save（对象状态）、Actor（交互发起者）。
