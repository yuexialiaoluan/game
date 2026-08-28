# Save 系统

## 职责
本地单机存档的保存、读取、删除、槽位管理、校验、版本迁移与原子写入。

## 数据模型
`SaveGameData`（见 `scripts/save/save_game_data.gd`）：
- 元数据：`save_version`、`game_version`、`timestamp`、`game_mode`、`player_id`。
- 状态：`game_state`（含 story_flags/world/economy/time 等子状态）、`actors`、`party`、`reserve_party`、`time_state`、`weather`、`rng_state`。

## Runtime 与 Save Data 分离
- 不序列化 Scene Tree、Node、Sprite、Camera、Animation 节点。
- `Actor` 通过 `to_save_data()` / `apply_save_data()` 输出/恢复纯字典。
- 表现层（Appearance/Equipment 视觉）只保存 ID 与自定义参数，读取后由 Appearance Resolver 重建。

## Actor 保存
- 保存：ID、Identity、Race、Classes、Skills、Feats、Talents、Base Attributes、Progression、Equipment（slot→item_id）、Inventory、Relationships、Faction/Reputation、State、Appearance。
- NPC 建议：模板 + 持久变化；本阶段先保存完整 Actor 状态字典，后续再优化为差分。

## Appearance 保存
- 保存 `body_id / face_id / hair_id / clothing_id / eyes_id`，不保存最终 Sprite。
- 读取流程：Save Data → Actor.appearance → CharacterVisual → Appearance Resolver → 重建视觉。

## RNG 保存
- `RNGService` 提供 `get_state()/set_state()`，保存 `rng_state`，读取后恢复以保证随机序列一致。

## 原子写入
- 临时文件 `.tmp` → `flush` → 重命名为正式文件，避免写入中途崩溃损坏存档。

## 错误处理
- `SaveResult` 区分：`file_not_found`、`corrupted`、`unsupported_version`、`missing_fields`、`type_error`、`write_failed`、`migration_failed`。

## 版本与迁移
- `SaveGameData.CURRENT_SAVE_VERSION = 1`。
- `SaveService.migrations` 定义 from→to 迁移步骤；未来新增 V2→V3 等按链迁移。

## 接口
- `save_game(slot_id, ctx, game_mode, rng_state) -> SaveResult`
- `load_game(slot_id) -> SaveResult`
- `delete_save(slot_id)`、`list_saves()`、`has_save(slot_id)`、`validate_save(d)`。

## Interaction 状态
Interactable 状态进入 WorldState，随 GameState 保存。

## Object State
Interactable 状态存 WorldState，Save/Load 后恢复。

## RPG 状态
Character/Party/Inventory/Equipment/Appearance 经 Actor 与 GameState 保存恢复。

## NPC State
NPC Runtime 状态写入 GameState.npc_state。

## Crime/Stealth
Crime Record、Suspicion、Stealth、Encounter 状态入 GameState 保存。

## Combat
战斗中不自动保存，战斗结束由上层决定。
