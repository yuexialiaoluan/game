# 角色像素风格规范

## 视觉层
Body、Face、Hair、Hair Color、Skin、Eyes、Clothing、Armor、Helmet、Gloves、Boots、Weapon、Shield、Cape、Accessory、VFX。
角色由多层组成，不是单张 Sprite。

## 比例与密度
- 统一角色像素密度与基础比例（以 2.5D 视角斜向呈现）。
- 头部、身体、四肢保持一致的像素颗粒，禁止高清图混入像素风。

## 可读性
- 轮廓清晰，主要特征在缩小尺寸下仍可辨识。
- 配色分区明确，避免杂乱高频噪声。

## 分层
- 每层独立资源，由 Appearance Resolver 组合（见 `skeleton_spec.md`、`equipment_visual_spec.md`）。
- 同种族共用骨架与比例，不同种族可拥有不同骨架/比例。

## 调色板
- 每套角色/装备使用统一 palette；颜色变化用 Dye/Color 规则，不逐件乱调。
