# Save 系统

## 必须保存
Player、Characters、Party、Reserve Party、NPC 状态、NPC 关系、招募状态、NPC 死亡状态、Quest、Dialogue 状态、Story Flag、World State、Faction、Reputation、Inventory、Equipment、Currency、Time、Weather、Shop、Dungeon、Appearance、Character Customization。

## 原则
- 不直接序列化 Scene Tree。
- 建立稳定的 `SaveData` DTO（纯数据结构）。
- 保存版本号 `SaveVersion` 与迁移函数。
- 实体用稳定 ID/GUID 引用；内容用内容 ID 引用。
- 存档兼容：旧版本经迁移升到当前版本。

## 建议格式
- 用 JSON 或带 schema 的稳定格式存储；GUID/ID 保持文本可读，便于调试与迁移。

## 依赖
所有系统的“可序列化状态”接口；SaveService 负责读写与版本迁移。
