# Localization

## 目标
文本支持本地化，不把大量中文硬编码进 GDScript。

## 语言
至少：Chinese、English；未来可扩展。

## 设计
- 所有面向玩家的文本使用 key。
- `LocalizationService` 按语言解析 key。
- 逻辑引用 key，表现层解析显示。

## 数据
- 文本存 JSON/CSV/PO（见 `data_model.md`）。

## 依赖
Data Model、UI、Dialogue/Quest、Content Database。
