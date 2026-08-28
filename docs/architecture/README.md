# 《灰烬之上的勇者》架构文档索引

项目：《灰烬之上的勇者》 Ashes of the Brave
阶段：2 核心架构设计（仅设计，不实现完整游戏）

## 分层模型
- 数据层（Data）：内容定义、配方、掉落表、对话/任务数据、外观模板。放在 `data/`。
- 逻辑层（Logic/Service）：规则与状态变更。放在 `scripts/`，以 Service/System/Component 组织。
- 表现层（Presentation）：场景、UI、音频、镜头、输入展示。放在 `scenes/`、`ui/`、`assets/`，只读取状态、不写业务规则。

## 系统分类
- 核心框架：Condition/Effect、Event、Action/Interaction、RNG、Content Database、Save。
- Actor 层：Actor、Character、NPC、Enemy/Creature、Appearance、Recruitment、Relationship/Faction。
- 世界层：World/WorldState、Time/Calendar/Weather、NPC AI、Scene Management、Location。
- 玩法层：Combat、Party、Item/Equipment/Inventory、Crafting、Fishing、Gathering、Stealth/Crime（接口）、Dungeon、Economy/Shop、Quest/Dialogue、Loot。
- 表现层：UI、Input、Camera、Audio、Localization。
- 支撑层：Testing、Debug/Developer Console、Game Modes。

## 文档索引
- 总览与原则：`overview.md`、`core_systems.md`、`data_model.md`。
- Actor 层：`actor_system.md`、`character_system.md`、`npc_system.md`、`enemy_creature.md`、`appearance_system.md`、`recruitment_system.md`、`relationship_faction.md`。
- 核心框架：`condition_effect.md`、`event_system.md`、`interaction_system.md`、`rng_system.md`、`save_system.md`、`content_database.md`。
- 世界层：`world_system.md`、`time_weather.md`、`ai_system.md`、`scene_management.md`。
- 玩法层：`quest_dialogue.md`、`party_system.md`、`item_equipment.md`、`crafting_system.md`、`fishing_system.md`、`gathering.md`、`loot.md`、`economy_system.md`、`combat_system.md`、`dungeon_system.md`、`stealth_crime.md`。
- 表现层：`ui_system.md`、`input_system.md`、`camera_system.md`、`audio_system.md`、`localization.md`。
- 模式与支撑：`game_modes.md`、`debug_system.md`、`testing.md`。
- 决策记录：`decisions/`。

## 依赖概览
- 所有玩法系统依赖 Condition/Effect、Event、RNG、Content Database、Save。
- Actor 层依赖 Data Model 与组件；不依赖具体地图或具体剧情。
- 表现层只依赖逻辑层接口与状态，不直接读写数据文件。

## 美术资源架构
- 表现层美术资源规范见 `../art/`（同仓库 `docs/art/`）。
- 涵盖 Asset Pipeline、命名、Asset Registry、Character Skeleton、Animation、Equipment Visual、NPC Appearance、Tileset、VFX、UI 视觉、像素渲染标准。
- 新增决策记录：`decisions/ADR-009` 到 `ADR-013`（Skeleton / Animation / Equipment Visual / Asset Pipeline / Pixel Standard）。

## 表现层方向修正（2.5D）
- 采用“3D 环境 + 2D 像素角色 + 2D 骨骼/分层 + 3D 光照”的方向，见 `decisions/ADR-014-3d-world-2d-characters.md`。
- 相关规范更新：`../art/art_direction.md`、`../art/sprite_spec.md`、`../art/skeleton_spec.md`、`../art/animation_spec.md`、`../art/environment_style.md`、`../art/asset_pipeline.md`。
- 架构同步：`appearance_system.md`、`scene_management.md`、`camera_system.md`。
