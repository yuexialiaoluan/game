# Item / Equipment / Inventory 系统

## Item 类型
Weapon、Armor、Accessory、Clothing、Consumable、Material、Quest Item、Key Item。

## 装备属性
属性、重量、品质、稀有度、耐久度（可选）、外观、特殊效果、标签。
- 装备数据分 `Gameplay Data` 与 `Appearance Data`。

## Inventory
- 玩家背包、队伍共享背包、角色个人装备、快捷栏、堆叠、重量/容量、金币、材料。
- 未来扩展：队友个人背包、马车、仓库、城镇仓库（预留接口，不现在实现）。

## 数据
- `ItemDefinition` 由数据驱动；实例（带数量、耐久、随机属性）由 `ItemInstance` 表达。
- 货币可作为特殊账本或特殊物品处理。

## 依赖
Content Database、Appearance（装备外观）、Crafting、Economy/Shop、Loot、Save。
