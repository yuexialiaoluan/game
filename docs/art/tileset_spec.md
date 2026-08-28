# Tileset / Tilemap 规范

## 定位修正
世界场景采用 3D 环境（见 `environment_style.md`），2D Tileset 不再作为世界地形主体，仅保留用于：
- 3D 表面上的贴花/道路标记。
- UI 地图标记与图标。
- 未来可选的小地图或工具层。

## 规范（保留）
- 如使用 2D 贴图：Nearest 过滤、无 mipmap、Pixel Snap、统一像素密度。
- 命名：`tile_grass_001`、`tile_dirt_001`、`tile_water_001`、`tile_road_001`。

## 存储
- 相关 2D tile 资源放 `assets/environment/tiles/`；3D 地形/建筑资源按 `asset_pipeline.md` 走 3D 管线。
