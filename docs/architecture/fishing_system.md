# Fishing 系统

## 定位
独立玩法系统，不与 Combat 绑定。

## 组成
- 钓鱼点（FishingSpot）。
- 鱼竿（Rod）与鱼饵（Bait）。
- 鱼类（FishDefinition）：普通、稀有、特殊、任务鱼、隐藏鱼。
- 不同地点有不同鱼类与概率。

## 流程
找到钓鱼点 → 使用鱼竿/鱼饵 → 判定 → 获得鱼/材料 → 可能触发特殊事件。

## 数值
- 概率由数据表驱动，统一走 RNGService。
- NPC Talent 可影响：如 `Fishing +10%`、`Rare Fish Chance +5%`。

## 依赖
Condition/Effect、Item、RNG、Event、Time/Weather/Location（影响鱼群）、Save。
