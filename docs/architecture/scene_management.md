# Scene / World Streaming（3D 世界）

## 目标
为 3D 开放世界预留区域加载/卸载能力；当前只设计架构，不实现开放世界加载。

## 职责
- 3D 区域加载/卸载与过渡。
- 室内/室外切换：建筑内部、城市、村庄、地下城。
- 高低差、桥梁、台阶、坡地的空间组织。
- 背景/前景遮挡层管理。

## 设计
- `SceneManager` 管理当前区域与过渡。
- 区域由 `LocationDefinition` 驱动，包含 3D 环境资源与 2D 角色站位。
- 2D 角色以 billboard 放入 3D 场景，随区域加载/卸载。
- 室内/地下城作为子区域流，切换时保存/恢复状态。

## 遮挡与深度
- 角色进入建筑后遮挡、前景物体遮挡由 3D 深度缓冲处理。
- 必要时使用深度偏移/Y-sort 处理同屏排序。

## 约束
- 业务状态存 GameState/WorldState，不依赖 Scene Tree。
- 表现层可整体销毁重建，状态不丢失。

## 依赖
World、Location、Camera、Save、Event。

## Combat Scene
World 暂停 → Combat Scene → 结束销毁 → World 恢复。
