# 数据模型与内容表示

## 数据分层
- 内容定义（静态）：种族、职业、技能、物品、配方、外观模板、掉落表、对话、任务、商店。
- 运行时状态（动态）：Actor 状态、世界状态、任务进度、关系、库存、时间天气。
- 配置（全局）：数值曲线、默认规则、输入映射、UI 主题参数。

## 数据形式选型
| 形式 | 适用 | 理由 |
| --- | --- | --- |
| Godot Resource（`.tres`，自定义 Resource 类） | 结构化、需编辑器可视化编辑的内容定义 | 类型安全、可在 Inspector 编辑、支持引用与继承 |
| JSON | 本地化文本、批量/表格化数据、存档 | 易生成、易 diff、语言无关、适合迁移 |
| 配置文件/CSV | 数值表、曲线、枚举字典 | 便于策划编辑与批量导入 |
| GDScript 常量字典 | 仅少量内部常量 | 内容数据不硬编码在脚本 |

## 建议
- 主体内容用自定义 `Resource` 类，存放于 `data/`，由 Content Database 统一加载。
- 本地化与存档用 JSON（或带 schema 的稳定格式）。
- 不做“全部 JSON”：复杂引用与编辑器体验会变差。

## ID 与 GUID
- 内容 ID：`type.subtype.name` 或稳定字符串，如 `weapon.iron_sword`。
- 运行时实例：生成 GUID（`ResourceUID` 或字符串 GUID），存档引用 GUID。

## 内容数据库
见 `content_database.md`。原则：按 ID 索引、惰性加载、启动/编辑器时校验、支持开发期热重载。

## 本地化
- 所有面向玩家的文本使用 key，如 `quest.001.title`。
- 逻辑只引用 key，由 LocalizationService 在表现层解析。

## Save Data 表示
- 存档使用显式 `SaveGameData` DTO + 版本化 JSON（见 `save_system.md`）。
- 运行时对象（Actor/Node）通过 `to_save_data()`/`apply_save_data()` 转为纯字典。
- 内容引用使用稳定 ID；运行时实例使用 Actor ID/Character ID。
- RNG 保存 `rng_state`；外观只保存 ID 与自定义参数，不保存渲染结果。
