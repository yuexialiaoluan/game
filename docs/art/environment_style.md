# 环境资源规范（3D 环境 + 2D 角色）

## 定位
世界场景使用 3D 空间；角色使用 2D 像素 Sprite。环境负责提供 3D 深度、遮挡、高低差与光照。

## 分类
Terrain、Building、Prop、Nature、Dungeon Assets、Interactive Objects、Background、Foreground。

## 3D 环境要求
- Terrain：Grass、Dirt、Stone、Sand、Snow、Water。
- Building：外墙、屋顶、室内结构，支持角色进入建筑后遮挡。
- Prop：Tree、Rock、Barrel、Crate、Fence、Lamp、Sign、Chair、Table、Campfire、Well、Grave。
- Nature：植被、树木、山体。
- Dungeon：地下城房间、墙体、机关。
- Background/Foreground：远景与近景遮挡层。

## 空间结构
- 高低差、桥梁、台阶、坡地使用 3D 几何或高度场表达。
- 角色进入建筑后由 3D 深度自然遮挡；前景物体可遮挡角色。

## 风格统一
- 3D 环境采用低多边形/风格化建模，贴图使用与像素角色一致的 palette 与 texel density。
- 光照、阴影、景深由 3D 场景统一处理。

## 存储
- `assets/environment/`（tiles、props、nature、dungeon、background、foreground）。
- 3D 网格与材质按 `asset_pipeline.md` 规范导入。
