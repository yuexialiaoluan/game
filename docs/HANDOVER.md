# HANDOVER — 《灰烬之上的勇者》 Ashes of the Brave

本文档是阶段性开发交接文件。目标是让下一位开发者/AI 不依赖历史对话，仅凭项目本身和本文档就能准确接手。

## 项目一句话总结

《灰烬之上的勇者》是一款 Windows PC 单机、2.5D 像素风、3D 世界、西幻题材的开放世界 RPG，采用战棋式回合制战斗，强调 NPC 互动、角色招募、装备换装、任务/对话、探索、地下城与高自由度行为。

## 当前真实完成度

### Completed（已实现并通过自动化测试）

- Core：Actor、Attributes/Modifier、Progression、GameState、WorldState、StoryFlag、RNG、EventBus、EventRegistry、ConditionEvaluator、EffectExecutor。
- Content：GameplayDB、ContentDB、CharacterVisualDB，统一从 `data/` 读取 JSON。
- Character：CharacterVisual、CharacterSkeleton、AppearanceResolver、CharacterAnimator、CharacterBillboard3D、PlayerController3D、OrthoFollowCamera、CharacterService、Facing。
- Party / Inventory / Equipment：PartyService、InventoryService、EquipmentService；装备变化可同步到外观。
- Appearance / Animation：分层身体/头/发/眼/服装/盔甲/头盔/主手/副手，Idle/Walk/Attack 动画，武器随 Hand_R、盾牌随 Hand_L。
- Save：SaveService、SaveGameData、SaveResult、SaveValidator，原子写入，版本迁移骨架；Actor/Party/WorldState/NPC/Quest/RNG 状态进入存档。
- Time / Calendar / Weather：TimeService、CalendarService、WeatherService。
- Quest / Dialogue：QuestService、DialogueService；任务目标进度、对话条件与效果。
- Interaction / Action：InteractionService、InteractionDetector、Interactable3D、ActionService、ActionOutcome。
- NPC：NPCData、NPCRuntime、NPCStateService、NPCBackgroundFactory、RecruitmentService、RelationshipService、ScheduleService、SurrenderService。
- Stealth / Crime：StealthService、DetectionService、NoiseService、CrimeService。
- Encounter：EncounterService、EscapeService。
- Combat 基础：CombatService、CombatInstance、CombatGrid/CombatGrid3D、Combatant、回合、移动、攻击、伤害、技能、状态、简单 AI、逃跑/投降、Loot、XP、CombatInputController、CombatUnitView、CombatCamera、CombatLog、目标选择、范围查询。
- UI：GameUI（HUD/对话/Portrait/角色/队伍/背包/装备/任务/商店/酒馆/战斗面板）、RPGUI、CombatUI、InteractionUI、UITheme、PortraitView、UIAssetRegistry、UIAudio 接口。
- Title / Menu：MainMenuController、MenuNavigator、CharacterCreationService、LocalizationService、SettingsService。
- 工具：`tools/run_all_tests.ps1`、`tools/build_windows.ps1`、`export_presets.cfg`。

### 说明

“Completed”表示代码存在、且被当前自动化测试覆盖。它不一定表示“玩家已经能完整游玩”。

## Partial / Prototype（不要当作完成）

| 功能 | 实际状态 |
| --- | --- |
| Navigation | `NavigationService` 是自定义点/障碍/射线检查；World 中建了 `NavigationRegion3D`，但没有真正用 NavAgent 驱动 NPC/敌人寻路。Prototype。 |
| 鼠标世界交互 | InteractionDetector 使用距离最近目标 + E 键，不是鼠标点击选择。Prototype。 |
| Combat 完整表现 | 有 3D 网格、UnitView、Camera、InputController，但玩家实际完整鼠标操作链未打磨为可玩战斗。Prototype。 |
| Audio | `CombatAudio`、`UIAudio` 主要是空接口/占位，没有实际音频资源。Interface Only。 |
| VFX | `CombatVFX.play()` 是占位，无实际特效。Placeholder。 |
| Dialogue 视觉 | 已接入 GameUI，但只有默认/有限 Portrait，无表情切换、完整立绘流程。Prototype。 |
| Shop | Service + GameUI 面板存在，但 World 中没有稳定的商店 NPC 接线。Partial。 |
| Tavern | UI 有 Talk/Rest/Recruit 按钮，Recruit 未连接 RecruitmentService。Partial。 |
| Save UI | 没有正式的存档/读档 UI 面板，只有 Service 层测试。Partial。 |
| Character Creation UI | 主菜单有模式选择，但没有完整捏脸/外观编辑 UI。Partial。 |
| Quest Journal | GameUI 有列表和目标，但还没有 Active/Completed/Failed 标签页交互。Partial。 |
| NPC Schedule | 有 ScheduleService/NPCStateService，测试中更新状态，但 NPC 不会在世界中按时间表移动。Partial。 |
| Crime | 有犯罪/侦测/阵营惩罚，但没有完整的守卫逮捕流程。Partial。 |
| Fishing | 有交互点、数据和 Service，但没有完整钓鱼玩法。Partial。 |
| Crafting | 目录 `data/recipes/` 为空，暂无可用的制作服务。Not Implemented。 |
| AoE | 战斗中有范围查询接口，但还没有完整 AoE 技能流程。Prototype。 |
| AI | 只有 CombatAI 的 aggressive 简化行为；世界 NPC AI/敌人巡逻未实现。Prototype。 |

## Known Problems

### 技术与流程

- 自动化测试实际位于 `scenes/tests/` 与 `scripts/tests/`，根目录 `tests/` 为空。`tools/run_all_tests.ps1` 只扫描 `scenes/tests/`，因此 `world_exploration_test.gd` / `world_art_test.gd` 不在标准回归脚本中，需要手动运行对应 World 场景。
- `scenes/tests/game_start_placeholder.tscn` 不会自动退出，测试脚本已排除该场景。
- `README.md` 的“当前状态”仍写着“阶段 2，尚未实现具体游戏系统”，与实际代码不一致。
- `data_model.md` 描述 `.tres` / Resource 的长期方案，但当前实际数据全部是 JSON；文档与实现存在落差。
- Save 的 `SaveGameData.game_version` 为 `"0.1.0"`，但导出版本已经是 `0.2.0`，需要统一。
- `InputService` 在 autoload 中动态注册输入动作，缺少正式的 `.godot/input_map` 或项目级 Input Map 校验。

### Gameplay / UI

- 还没有一份真正“打开 EXE 就能玩”的 15–30 分钟闭环 Demo。
- GameUI 的战斗面板只是展示层；正式战斗仍使用原有 CombatUI。
- 背包图标没有映射到具体像素图标，Asset ID 中的 icon 项仍为空字符串。
- Save/Load UI、装备比较、任务标签页、Portrait 表情等尚未完成。
- 世界中的 NPC 是程序生成占位外观，不是正式 NPC 资产。

### 美术 / License

- `Portraits_v1` 为 UNKNOWN，只能作为 DEV_ONLY，不能当作 Release Asset。
- `BoldPixels` 为 CC BY-SA 4.0，使用必须署名，修改后需按同协议发布。
- 大量 UI、角色、图标包为 UNKNOWN，不能假定可商业使用。
- 导出预设 `export_filter="all_resources"` 会把整个 `assets/123/`（包括 UNKNOWN 素材和生成的 `.import`）打入 EXE，造成体积偏大且包含授权风险资源。

### 性能 / 导出

- 当前 EXE 约 144 MB，ZIP 约 71 MB，主要来自未筛选的原始素材与导入缓存。
- `update_hud()` 每帧更新文本/进度条，但 Party 头像只在队伍规模变化时重建，当前可接受；后续仍应改为事件驱动。

## 架构地图

```text
Game
├── Core                 # GameState / WorldState / StoryFlag / RNG / EventBus / Condition / Effect / EvaluatorContext
├── Actor                # Actor、Attributes、ModifierList、Progression、Identity、RelationshipState、StatModifier
├── Character            # CharacterVisual、CharacterSkeleton、AppearanceResolver、CharacterAnimator、CharacterBillboard3D、PlayerController3D、CharacterService
├── Party                # PartyService
├── NPC                  # NPCData、NPCRuntime、NPCStateService、NPCBackgroundFactory、RecruitmentService、RelationshipService、ScheduleService、SurrenderService
├── World                # WorldBuilder、InteriorArea、WorldCombatTransition、NavigationService
├── Interaction          # InteractionService、InteractionDetector、Interactable3D、InteractableObject
├── Action               # ActionService、ActionOutcome
├── Quest                # QuestService
├── Dialogue             # DialogueService
├── Combat               # CombatService、CombatInstance、CombatGrid、CombatGrid3D、Combatant、DamageService、LootService、CombatInputController、CombatUnitView 等
├── Appearance           # CharacterVisualDB、AssetRegistry、PortraitFactory、TextureFactory、VisualFactory、AppearanceResolver
├── Equipment            # EquipmentService
├── Inventory            # InventoryService
├── Save                 # SaveService、SaveGameData、SaveResult、SaveValidator
├── Time                 # TimeService、CalendarService、TimeData、ActionTimeCost
├── Weather              # WeatherService
├── Stealth              # StealthService、DetectionService、NoiseService
├── Crime                # CrimeService
└── UI                   # GameUI、RPGUI、CombatUI、InteractionUI、UITheme、PortraitView、UIAssetRegistry、UIAudio
```

- Data：`data/**/*.json`，由 GameplayDB / ContentDB / CharacterVisualDB / NPCData / TimeData 加载。
- Runtime：Actor、NPCRuntime、GameState、WorldState、QuestService 内部状态、CombatInstance 等。
- Service：无场景依赖的规则逻辑，多数是 RefCounted，通过 `setup()` 注入依赖。
- Presentation：CharacterVisual、CharacterBillboard3D、CombatUnitView、GameUI、PortraitView 等。

## 核心数据流

- Character：Actor → Identity/Attributes/Progression → Equipment → Actor.equip → CharacterVisual → AppearanceResolver → 分层 Sprite。
- Interaction：Player → InteractionDetector → InteractionService → ActionService → Condition → RNG → Outcome → Effect → Event。
- Quest：ContentDB/QuestService → Condition → accept/objective progress → Effect → QuestJournal。
- Dialogue：NPC → DialogueService → Choice → Condition → Action/Effect → Quest/Relationship/Event。
- Combat：EncounterService → CombatService → CombatInstance → Combatant → Grid → Turn → Action → DamageService → Event → Result → World。
- Save：Runtime Actor/GameState/Party/NPC/Quest/RNG → `SaveGameData.to_dict()` → JSON `.tmp` → rename → slot JSON；读取反向重建。

## 主要 Service 列表

“成熟度”含义：Playable = 可在实际场景中工作；Tested = 有自动化覆盖，但玩家体验不完整；Prototype = 只有基础实现；Interface Only = 主要是接口/占位。

- `ActionService` — `scripts/action/action_service.gd` — Action 执行、目标校验、状态变更与奖励。Playable/Tested。
- `DialogueService` — `scripts/dialogue/dialogue_service.gd` — 对话选项与效果执行。Playable/Tested。
- `QuestService` — `scripts/quest/quest_service.gd` — 任务状态、接受、目标进度、完成/失败、日志。Playable/Tested。
- `InteractionService` — `scripts/interaction/interaction_service.gd` — 交互对象注册与可用 Action 查询。Playable/Tested。
- `PartyService` — `scripts/party/party_service.gd` — 出战/后备队伍容量与交换。Playable/Tested。
- `InventoryService` — `scripts/inventory/inventory_service.gd` — 物品增减与使用。Playable/Tested。
- `EquipmentService` — `scripts/equipment/equipment_service.gd` — 装备条件、装卸、事件。Playable/Tested。
- `SaveService` — `scripts/save/save_service.gd` — 槽位保存/读取/删除/校验/迁移/原子写入。Playable/Tested。
- `TimeService` — `scripts/time/time_service.gd` — 时间推进、暂停、动作耗时。Playable/Tested。
- `WeatherService` — `scripts/time/weather_service.gd` — 区域天气与随机切换。Playable/Tested。
- `NPCStateService` — `scripts/npc/npc_state_service.gd` — NPC 运行时状态与时间表活动。Tested/Prototype。
- `RecruitmentService` — `scripts/npc/recruitment_service.gd` — 招募条件与入队。Tested。
- `RelationshipService` — `scripts/npc/relationship_service.gd` — 关系字段读取/修改。Tested。
- `ScheduleService` — `scripts/npc/schedule_service.gd` — 时间表查询。Tested/Prototype。
- `SurrenderService` — `scripts/npc/surrender_service.gd` — 投降条件与状态。Tested。
- `StealthService` — `scripts/stealth/stealth_service.gd` — 潜行状态与得分。Tested/Prototype。
- `DetectionService` — `scripts/stealth/detection_service.gd` — 侦测判定。Tested/Prototype。
- `NoiseService` — `scripts/stealth/noise_service.gd` — 噪音事件。Tested/Prototype。
- `CrimeService` — `scripts/crime/crime_service.gd` — 犯罪与阵营惩罚。Tested/Prototype。
- `EncounterService` — `scripts/encounter/encounter_service.gd` — 遭遇入口。Tested。
- `EscapeService` — `scripts/encounter/escape_service.gd` — 逃跑判定。Tested。
- `CombatService` — `scripts/combat/combat_service.gd` — 创建战斗实例与结果。Tested/Prototype。
- `CombatInstance` — `scripts/combat/combat_instance.gd` — 回合、移动、攻击、技能、状态、胜负。Tested/Prototype。
- `DamageService` — `scripts/combat/damage_service.gd` — 伤害结算。Tested。
- `LootService` — `scripts/combat/loot_service.gd` — 掉落生成。Tested。
- `NavigationService` — `scripts/navigation/navigation_service.gd` — 自定义点/障碍寻路接口。Interface Only/Prototype。
- `ShopService` — `scripts/world/shop_service.gd` — 买卖与金币。Tested/Partial。
- `CharacterService` — `scripts/character/character_service.gd` — 属性加点。Playable/Tested。
- `SettingsService` — `scripts/settings/settings_service.gd` — 设置存取。Playable/Tested。
- `LocalizationService` — `scripts/localization/localization_service.gd` — 中英文字符串解析。Playable/Tested。
- `CharacterCreationService` — `scripts/creation/character_creation_service.gd` — 创建数据收集。Tested/Prototype。

## 数据目录

当前共有 28 个 JSON 数据文件，实际使用情况如下：

### 已实际被代码加载

- `races/races.json`、`classes/classes.json`、`skills/skills.json`、`feats/feats.json`、`talents/talents.json`、`status_effects/status_effects.json`、`items/items.json`、`equipment/equipment.json`、`progression/level_table.json` — 由 `GameplayDB` 加载。
- `quests/quests.json`、`dialogues/dialogues.json`、`npc_backgrounds/npc_backgrounds.json`、`triggers/triggers.json`、`actions/actions.json`、`interactions/interactions.json`、`resources/resources.json`、`fishing/fishing.json` — 由 `ContentDB` 加载。
- `appearance/appearance_options.json`、`appearance/portraits.json`、`characters/npc_templates.json` — 由 `CharacterVisualDB` 加载。
- `npcs/recruitment.json`、`npcs/schedules.json`、`npcs/surrender.json` — 由 `NPCData` 加载。
- `time/calendar.json`、`time/action_time_costs.json` — 由 `TimeData` 加载。
- `weather/weather_defs.json` — 由 Weather 测试加载。
- `events/events.json` — 由 EventRegistry 测试加载。

### 只有 Schema / 空目录，未实际使用

- `appearances/`、`armors/`、`characters/`（除 npc_templates）、`creatures/`、`dialogues/` 目录占位文件、`dungeons/`、`enemies/`、`factions/`、`locations/`、`materials/`、`recipes/`、`shops/`、`weapons/` 等大部分是 `.gitkeep` 或仅有测试数据。
- `loot/loot.json` 存在，但需确认是否已被 LootService 实际引用（当前 `LootService` 生成逻辑仍偏测试）。

### 测试数据

- 多数 JSON 内容规模很小，属于验证数据结构的最小集，不是正式内容库。

## 美术资源总结

- Asset Audit 记录：约 1657 个源文件，约 126.6 MB。
- 当前文件系统因 Godot 生成 `.import` 缓存，文件总数更大（实际扫描约 3044 个文件，约 122 MB），但原始素材审计仍以 `docs/art/asset_audit.md` 为准。
- 推荐优先级：
  - P0：Portraits_v1、Pixel UI pack、Cryo's Mini GUI、UIBundleFree、16x16 Icons、BoldPixels 字体。
  - P1：Village_NPC、The Male adventurer、Archer、Orcs、EleonoreAndJoanna、RF_Catacombs、RPGW_Caves、FL_Houses、Pixel Lands。
  - P2：Rasaks、Free-Cursed-Land、top-down-collection、Fence、MegaPackFree。
  - INCOMPATIBLE：Modern_Interiors（仅非商业）、tavern（等距视角与当前正交 2.5D 冲突）。

## License / Asset Risk

- APPROVED（商用允许，禁止再分发）：Village_NPC、GandalfHardcore、Orcs、EleonoreAndJoanna、RF_Catacombs、RPGW_Caves、FL_Houses、Pixel Lands、top-down-collection。
- UNKNOWN（默认 DEV_ONLY）：Portraits_v1、Rasaks、16x16 Icons、Cryo GUI、Pixel UI、UIBundleFree、MegaPackFree、Human Male Model、The Male adventurer、Fence、音频等。
- INCOMPATIBLE：Modern_Interiors_Free_v2.2（仅非商业）。
- CC BY-SA 4.0：BoldPixels 字体；必须署名，修改后需同协议。

完整记录：`docs/art/asset_licenses.md`、`docs/art/asset_audit.md`。

## 2.5D 技术方案

当前实际实现是：

```text
3D Environment
+ 2D Pixel Character
+ SubViewport
+ Sprite3D Billboard
+ Orthographic Camera
```

- 角色：`CharacterVisual` + Node2D 骨骼层 + Sprite Parts。
- 装备：Bone Attachment，主手挂 Hand_R，副手挂 Hand_L，头盔挂 Head，重甲隐藏普通服装。
- 地图：3D 环境，用程序占位 Box/Plane 组成测试区域。
- 遮挡：依赖 3D Depth Buffer + Billboard 的 3D 位置，墙/树可遮挡角色。
- 摄像机：正交跟随，`OrthoFollowCamera` 独立于 Player 脚本。

## 角色素材规范

- World Sprite 画布：`80 x 96` px。
- Foot Pivot：`(40, 80)`，逻辑位置始终代表脚底。
- PPU：32；3D billboard `pixel_size = 1 / 32 = 0.03125`。
- Texture Filter：Nearest；Pixel Snap 开启；Mipmap 关闭；整数倍缩放。
- 分层：Body / Face / Eyes / Hair / Clothing / Armor / Helmet / Gloves / Boots / MainHand / OffHand / Cape / Accessory。
- World Sprite / Battle Sprite / Portrait 三者分离，共享 Character 数据，但允许不同资源。

详见 `docs/art/sprite_spec.md`、`docs/architecture/appearance_system.md`。

## Combat 当前真实状态

已完成并测试：

- CombatInstance、CombatGrid/CombatGrid3D、Combatant。
- 回合顺序、移动、攻击、伤害、技能、状态 tick。
- 简单 aggressive AI、逃跑/投降、Loot、XP。
- 3D Grid、Unit View、Camera、Selection、Targeting、Range Query、World Picker。

仍然缺少/未完整：

- 玩家实际鼠标完整操作链还没打磨成“可玩战斗”。
- 完整 Combat UI 使用 `CombatUI` 占位，`GameUI` 只有展示层。
- 战斗 VFX / 音频基本是占位。
- 完整技能选择、目标确认、结果结算 UI 流程尚未完全玩家可用。

结论：Combat 的底层规则有较多自动化覆盖，但战斗表现和玩家操作是 Prototype。

## World 当前真实状态

- 当前不是正式地图，是 Test Region / Prototype Region：`scenes/world/test_region.tscn`。
- 有：程序生成 3D 地面、道路、水面、高台、墙/树等占位碰撞体；测试 NPC、宝箱、门、资源点、钓鱼点、床、工作台、哥布林敌人；WorldHUD 与 GameUI。
- NPC、建筑、环境多为程序占位；正式素材尚未接入 3D 世界。
- 商店/酒馆/Interior 有基础对象和 Service，但没有稳定完整的 NPC/建筑接线。

## Title Screen 当前真实状态

- 已有：Title、Main Menu、Mode Select、Story/Free、Character Creation（极简）、Load、Settings、Exit Confirmation。
- 真正可用：菜单导航、模式选择、进入 Test Region。
- Placeholder：角色创建没有完整外观编辑；Load/Settings 面板为按钮占位，未完成完整 UI。

## Save 当前真实状态

- `CURRENT_SAVE_VERSION = 1`。
- `SaveGameData` 包含：save_version、game_version、timestamp、game_mode、player_id、game_state、actors、party、reserve_party、time_state、weather、weather_state、rng_state。
- Migration：当前只有 `0 -> 1` 的迁移骨架，未实现多版本迁移链。
- RNG：`rng_state` 被保存，读取后可恢复。
- Actor / Party / WorldState / NPCState / Quest / Crime / Stealth 状态写入 GameState 或 actors。
- 已验证：Save/Load 测试、错误文件隔离、重复循环、迁移入口；没有玩家可见的 Save UI。

注意：`SaveGameData.game_version` 仍是 `"0.1.0"`，需与 `0.2.0` 构建版本统一。

## 版本与 Git

- 当前 branch：`main`
- 当前 HEAD：`8666d2d8410903c2d7e706a0245d0fe9d378ae3c`
- 最近 commit：`8666d2d feat: complete gameplay and combat foundation`
- 上一基线：`4ec46c9 chore: establish initial stable project baseline`
- 工作区状态：**未提交修改较多**。包括 Stage 20 UI、World 场景、资源审计文档、构建脚本、`export_presets.cfg`、`assets/123/` 等。
- 未创建新 commit，也未修改 Git 历史。

## Build

- 当前 EXE：`E:\GameProjects\TheBrave\builds\windows\TheBrave.exe`
- 当前 Manifest：`E:\GameProjects\TheBrave\builds\windows\build_manifest.json`
  - version：`0.2.0`
  - platform：windows / x86_64
  - godot：`4.7.2.stable.official.ed1daf0bf`
- 当前 ZIP：
  - `builds\releases\TheBrave_0.2.0_UI_Windows.zip`
  - 旧包：`TheBrave_0.1.0_Windows.zip`、`TheBrave_0.2.0_Prototype_Windows.zip`
- 构建脚本：`tools/build_windows.ps1`
- 当前构建能生成并启动 EXE，但不能完整体现所有 Gameplay 系统；原因是还没有正式 Playable Demo 内容。

## 当前项目最大的三个问题

1. **没有统一的 Playable Demo**：大量底层系统已测试，但 Title → World → Dialogue → Quest → Combat → Save 没有串成一个“打开 EXE 即可游玩”的闭环。
2. **正式美术与授权素材接入不足**：世界/角色/NPC 多为程序占位，P0 UI 素材多数 UNKNOWN，`assets/123/` 原始包未整理接入。
3. **UI 与内容仍偏 Prototype**：战斗表现、Save UI、角色创建、商店/酒馆/任务标签页等只是接口或展示层，未达到玩家可用。

## 推荐下一阶段

目标不是继续铺架构，而是完成一个 **15–30 分钟可玩的 Playable Prototype**。

应包含：

- 一张小型测试地图：村庄/野外/洞穴入口即可。
- 3–5 个 NPC：至少一个给任务、一个商店、一个可招募。
- Dialogue + Portrait + Choice。
- 一个 Quest：接受 → 目标 → 交付 → 奖励。
- 一个 Shop：Buy/Sell。
- Party：招募与队伍切换。
- 一次 Combat：遭遇 → 回合制 → 胜利 → Loot/XP。
- Save/Load：可保存，退出后能读回。
- UI：HUD、背包、装备、任务日志、对话、战斗面板都可在 EXE 中操作。

验收标准：

> 玩家打开 EXE，不需要开发者说明，就能正常玩。

## 给下一位 AI 的开发原则

### DO

- 优先复用已有系统与接口。
- 优先复用已有素材，先做 Asset Audit 再接入。
- 先运行项目与测试，再修改。
- 先理解数据流，再写功能。
- 保持数据驱动；内容放 `data/`，逻辑放 `scripts/`。
- 每完成一个阶段运行全部测试。
- 必须人工试玩，不能用 headless 测试代替玩家体验。
- 把 Playable 作为完成标准。

### DON'T

- 不要反复创建重复 Service。
- 不要为了测试数量堆功能。
- 不要把 Placeholder 当成完成。
- 不要把测试代码当成玩家体验。
- 不要未经检查下载大量素材。
- 不要假定 UNKNOWN License 可商业使用。
- 不要随意重构已验证架构。
- 不要只增加接口却不接入实际游戏。
- 不要只用 headless 测试宣布 Gameplay 完成。

## 下一位接手后的第一步

1. 阅读 `docs/HANDOVER.md`。
2. 运行 `E:\GameProjects\TheBrave\builds\windows\TheBrave.exe`。
3. 实际试玩，记录无法操作或不可理解的地方。
4. 检查 `docs/art/asset_audit.md` 与 `docs/art/asset_licenses.md`。
5. 选择一个小而完整的 Playable 目标，不要重新搭架构。

## 文档与代码一致性

已核对 `docs/architecture/`、`docs/art/`、`README.md`、`AGENTS.md` 与当前代码，发现：

- `README.md` 当前状态过时，仍写“尚未实现具体游戏系统”。**Documented but not Fully Playable。**
- `docs/architecture/` 是较完整的长期设计，但部分系统（Dungeon、Crafting、完整 UI、Audio/VFX）仍是“Documented but not Fully Playable”。
- `docs/art/sprite_spec.md` 的 80x96 / PPU32 / Foot Pivot 与当前代码一致。
- `docs/architecture/save_system.md` 描述 CURRENT_SAVE_VERSION=1，与代码一致；`game_version` 不一致需修复。

## 最终验证结果

- 全量 headless 回归：21 个测试场景，`TOTAL_FAILS=0`，`TOTAL_STDERR=0`。
- 主场景启动：`res://scenes/ui/title_screen.tscn`，退出码 0，stderr 空。
- Windows EXE Smoke：`TheBrave.exe --quit-after 120`，退出码 0，stderr 空。
- Git：未提交任何新 commit，未修改历史。
