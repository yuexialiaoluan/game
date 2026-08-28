# Asset Pipeline（美术生产流程）

## 流程
概念设计 → 原始素材 → 清理 → 尺寸/规格检查 → 命名 → 导入 Godot → Asset Registry → Godot Resource → 游戏使用

## 双管线
- 3D 环境管线：网格（低模）、材质、纹理、碰撞、LOD、光照贴图。导入为 Mesh/材质/场景资源。
- 2D 角色管线：Sprite Part、骨架定义、动画、Portrait。导入为 2D 纹理与动画资源。
- 2D VFX：精灵序列/粒子/shader，与 3D 灯光协调。

## 关注点
- Asset ID：稳定 ID，见 `asset_registry.md`。
- 文件命名：见 `asset_naming.md`。
- 资源版本、替换、删除、依赖、缩放、过滤、Import 设置均按本文件统一管理。
- 3D 纹理与 2D 像素纹理需分别配置过滤；2D 使用 Nearest/无 mipmap。

## 与逻辑解耦
游戏逻辑通过稳定 ID 引用资源；不在脚本里硬编码 `res://assets/...` 路径。

## 统一性
- 3D 环境与 2D 角色共享统一调色板与像素密度基准，确保融合自然。
