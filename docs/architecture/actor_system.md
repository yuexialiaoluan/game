# Actor 统一架构

## 目标
用单一 `Actor` 实体承载玩家、NPC、敌人、怪物、同伴，避免五套互不兼容的角色系统。

## 组成
- `Actor`：稳定身份（GUID）、生命周期、组件容器。
- 组件化能力：属性、成长、技能、专长、天赋、状态效果、装备、背包、外观、阵营、关系、AI、位置。

## Disposition（立场状态）
Actor 的“角色身份”是可变状态，不是不可逆类型：
`Neutral → Friendly → Hostile → Enemy → Surrendered → Captured → Recruitable → Companion → PartyMember`

示例：一个哥布林可以从敌人 → 投降 → 被说服 → 加入队伍 → 正式队友；成为队友后仍使用同一套 Character/Class/Skill/Feat/Talent/Equipment/Inventory/Progression/Relationship。

## 规则
- 禁止用不可逆类型判断限制转换。
- 状态变化通过 `Condition + Effect` 或服务方法触发，记录到 Actor 状态。
- 玩家只是“带 PlayerComponent 的 Actor”；NPC/Enemy/Companion 同理，只配置不同组件与数据。

## 组件清单（概念）
- `Identity`：显示名、种族、性别、年龄、背景。
- `Attributes`：基础/成长/临时属性。
- `Progression`：等级、经验、职业槽。
- `Skills/Feats/Talents`：能力集合。
- `StatusEffects`：Buff/Debuff。
- `Equipment`、`Inventory`。
- `Appearance`：外观描述符。
- `Faction`、`Relationship`、`Reputation`。
- `AI`：行为状态、日程、目标。
- `Location`：当前地点。

## 依赖
- 依赖 Data Model、Condition/Effect、Event、Save。
- 不依赖地图、剧情、UI。
