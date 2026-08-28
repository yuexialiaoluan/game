# RNG 系统

## 定位
统一随机系统，支持可复现。

## 使用域
NPC 生成、Talent、Loot、Fishing、Resource、Random Event、Dungeon、Combat。

## 设计
- `RNGService` 持有种子与随机流。
- 按领域拆分 stream（如 `npc`、`loot`、`fishing`、`combat`），避免相互干扰。
- 同一 Seed 尽可能复现一致结果。
- 提供 `next_int`、`next_float`、`pick_weighted`、`shuffle` 等接口。

## 依赖
Save（种子与流状态可选保存）、其他系统调用。
