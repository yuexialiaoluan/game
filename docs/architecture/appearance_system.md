# Appearance 系统与 Appearance Resolver

## 目标
角色外观可随装备变化，并支持分层、覆盖、隐藏、替换、染色；在 3D 世界中以 2D 像素角色呈现。

## 分层
Body、Head、Face、Hair、Hair Color、Eyes、Skin、Clothing、Armor、Helmet、Gloves、Boots、Weapon、Shield、Cape、Accessory、VFX。

## 数据分离
- 装备数据分为 `Gameplay Data` 与 `Appearance Data`。
- 装备逻辑不直接修改 Sprite；只提供外观数据，由 Resolver 计算。

## Appearance Resolver
输入：Race、Body、Face、Hair、Clothing、Equipment、Helmet、Cape、Accessory、Status、VFX。
输出：最终渲染规格（层列表 + 显示/隐藏/替换/颜色/骨骼挂点）。
规则示例：头盔隐藏头发、重甲隐藏普通服装、披风可被特定装备覆盖。

## 三种呈现资源
- World Sprite：3D 世界中的 billboard 分层表现。
- Battle Sprite：战斗表现。
- Portrait：UI/对话立绘。
三者共享 Character 数据，但允许使用不同资源；Resolver 只输出抽象层结果，由表现层映射到具体资源。

## 模板与随机
- `AppearanceTemplate`：如 `Human_Male_01`、`Elf_Female_01`、`Dwarf_01`、`Goblin_01`。
- 支持随机脸型、发型、发色、肤色、身体、服装、装备；职业/阵营/地区可影响外观。

## 服务设施
服装店、理发店、美容店、染色店、饰品店、幻化店、纹身店统一通过 Shop + Currency + Customization + Appearance 实现。

## 依赖
Content Database、Asset Registry（资源映射）、Save、Actor、UI（预览）。
