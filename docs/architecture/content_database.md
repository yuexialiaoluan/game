# Content Database

## 职责
按 ID 加载、索引、缓存、校验所有内容定义。

## 数据目录
`data/` 下按 `characters/`、`races/`、`classes/`、`skills/`、`feats/`、`talents/`、`npcs/`、`enemies/`、`creatures/`、`items/`、`weapons/`、`armors/`、`materials/`、`quests/`、`dialogues/`、`factions/`、`locations/`、`dungeons/`、`events/`、`recipes/`、`shops/`、`appearances/`、`interactions/` 组织。

## 加载策略
- Resource 内容惰性加载并缓存。
- JSON/CSV 在启动或变更时解析。
- 开发期热重载；启动/测试期执行数据校验。

## 校验
- 引用完整性（ID 存在、类型匹配）。
- schema 合法性（必填字段、枚举）。
- 唯一 ID 检查。

## 依赖
Data Model、Localization、Testing（数据校验）、RNG（随机内容解析）。

## 新增内容
data/actions、data/interactions、data/resources、data/fishing 由 ContentDB 加载。
