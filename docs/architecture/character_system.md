# Character 系统

## 定位
`Character` = Actor 上的成长/角色数据能力，是所有可成长单位的统一模型。

## 支持能力
等级、经验、属性、种族、职业（含多职业/兼职/切换/遗忘）、技能、专长、天赋、状态效果、装备、背包、外观、阵营、关系、声望、AI 状态、位置。

## 升级
- 升级奖励由数据表驱动：属性点、技能、专长。
- 部分技能/专长可通过任务、地下城、敌人、NPC、探索、特殊条件获得，不写死。

## 职业体系
- 采用“类似传统桌面 RPG 职业体系”的原创设计，不复刻任何受版权保护的具体规则。
- 职业是数据（`ClassDefinition`），支持切换、遗忘、兼职。
- 职业影响可用技能/专长/成长曲线，但不硬编码技能逻辑。

## 种族
- 种族是数据（`RaceDefinition`），不与 Character 代码耦合。
- 新增种族只加数据，不改核心系统。

## 与 Actor 关系
- Character 数据描述“是什么/会什么”，Actor 提供运行时身份与状态。
- 存档只保存 Actor 的运行时状态，内容数据由 Content Database 按 ID 解析。

## 依赖
Data Model、Progression、Skills/Feats/Talents、StatusEffects、Equipment/Inventory、Appearance、Faction/Relationship/Reputation、Save。
