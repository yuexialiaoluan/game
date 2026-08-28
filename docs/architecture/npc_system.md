# NPC 系统

## 原则
NPC 数据与行为逻辑分离；不把 NPC 数据写死在 NPC 脚本。

## 三要素
- `NPCDefinition`：唯一/特殊 NPC 的内容定义。
- `NPCTemplate`：随机 NPC 的生成模板。
- `NPCInstance`：运行时 Actor 实例（GUID + 状态）。

## NPC 数据字段（概念）
身份、种族、性别、年龄、外观、属性、职业、等级、技能、专长、天赋、性格、阵营、好感度、声望、当前地点、行为状态、招募条件、个人任务。

## 行为
NPC 可工作、休息、移动、交易、战斗、逃跑、投降、对话、偷窃/被偷窃、加入/离开队伍、死亡、被俘、改变阵营。行为由 AI 系统读取数据执行，不写死在 NPC 脚本。

## 随机 NPC
- 通过模板生成：随机姓名、外貌、职业、装备、性格、天赋、属性、背景。
- 每个 NPC 随机 1~3 个 Talent。
- Talent 可影响战斗、交易、制作、采集、钓鱼、偷窃、探索、对话、经济。
- 随机统一走 RNGService。

## 依赖
Actor、Appearance、Faction/Relationship、AI、Condition/Effect、Recruitment、Quest、RNG、Save。

## Runtime
行为状态见 
pc_runtime.md、
pc_schedule.md。
