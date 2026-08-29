# World Building 规范

- 世界单位：1 unit = 1 米；Tile 模块：1×1 unit。
- 道路宽度：3 unit；建筑比例：单层高约 3 unit；角色高约 2 unit。
- 相机：正交投影，俯仰约 45°，默认 Zoom 12，边界可配置。
- PPU：32；Pixel Density 与角色一致；Texture Filter Nearest，无 mipmap，Pixel Snap。
- 光照：主方向光俯仰 -50°、方位 -30°，阴影开启；Daylight/Evening/Night 由 TimeService 驱动环境色。
- 遮挡：前景/中景/背景分层；建筑与前景物用 3D 深度遮挡。
- 可行走区域与 NavigationRegion 对应；Collision 使用 StaticBody3D + 简化 Shape。
- 资产统一 Asset ID，进入 Asset Registry，禁止散落路径。
