# 核心系统清单、分类与依赖

## 系统分类
| 分类 | 系统 |
| --- | --- |
| 核心框架 | Condition/Effect、Event、Action/Interaction、RNG、Content Database、Save |
| Actor 层 | Actor、Character、NPC、Enemy/Creature、Appearance、Recruitment、Relationship、Faction/Reputation |
| 世界层 | World/WorldState、Location、Time/Calendar/Weather、NPC AI、Scene Management |
| 玩法层 | Combat、Party、Item/Equipment/Inventory、Crafting、Fishing、Gathering、Stealth/Crime（接口）、Dungeon、Economy/Shop、Quest、Dialogue、Loot |
| 表现层 | UI、Input、Camera、Audio、Localization |
| 支撑层 | Testing、Debug/Developer Console |

## 依赖方向
- 表现层 → 逻辑层 → 数据层。
- 玩法系统依赖核心框架，不互相深度依赖。
- 系统间优先通过事件与接口协作。

## 关键依赖
- Actor 被 Character/NPC/Enemy/Recruitment/Party/Combat 共享。
- Condition/Effect 被 Interaction、Quest、Dialogue、Recruitment、Event、Combat、Crafting 等使用。
- RNG 被 NPC 生成、掉落、钓鱼、资源、随机事件、地下城、战斗使用。
- Save 负责持久化 GameState/WorldState，其余系统只提供可序列化状态。
- Content Database 是内容加载的唯一入口。

## 生命周期
- 启动：Load Project Config → 初始化 EventBus/RNG/Save/Content Database → 注册服务 → 加载 GameState。
- 运行：服务按事件驱动处理状态，表现层订阅渲染。
- 退出/存档：GameState → SaveService 序列化。
