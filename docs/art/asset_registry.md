# Asset Registry（资源注册表）

## 职责
把稳定 Asset ID 映射到实际资源，供表现层统一加载。

## 概念
- Asset ID：稳定字符串，如 `character_iva`、`portrait_iva`、`sprite_human_male_01`、`armor_iron`、`weapon_iron_sword`、`tile_grass`、`prop_barrel`、`vfx_fire`、`sfx_sword_hit`。
- Registry：维护 ID → Resource 路径的映射，支持替换与重载。
- 加载接口：`AssetRegistry.load_texture(id)`、`load_audio(id)`、`resolve_path(id)` 等（概念层）。

## 约束
- 核心 Gameplay 系统不得直接写 `res://assets/...` 路径。
- 换素材只改 Registry 映射或数据，不改逻辑代码。
- Registry 与逻辑层 Content Database 分离：前者管表现资源，后者管玩法内容。

## 稳定引用
- 角色立绘与地图 Sprite 通过稳定 Character ID 或 Portrait ID 关联，见 `portrait_style.md`。
- 未来删除/替换资源走 Registry 的弃用流程。
