# Equipment Visual 规范

## 数据分离
装备拆分为：
- Gameplay Data：Attack、Defense、Weight、Resistance、Special Effect。
- Visual Data：Sprite、Skeleton Attachment、Bone、Layer、Offset、Scale、Rotation、Hide Rule、Override Rule。

## 约束
装备逻辑不直接修改 Sprite；只提供 Visual Data，由 Appearance Resolver 统一解析。

## 挂点与规则
- Helmet：`hide_hair = true`。
- Heavy Armor：`hide_clothing = true`。
- Cape：`hide_by_heavy_armor = true`。
- 规则集中在 Resolver，不分散到各装备脚本。

## 幻化/Transmog
- Actual Equipment 决定属性/重量/技能效果。
- Visual Equipment 决定外观/服装/装甲/武器模型/配色。
- 支持“一套属性 + 另一套外观”，如 Dragon Armor 属性 + Royal Coat 外观。

## 存储
- `assets/equipment/` 下按 weapons/armor/clothing/shields/accessories 分类。
