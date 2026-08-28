# NPC Appearance 规范

## 模板
普通 NPC 通过 Appearance Template 生成，如：
`Human_Male_01`、`Human_Male_02`、`Human_Female_01`、`Elf_Male_01`、`Elf_Female_01`、`Dwarf_01`、`Goblin_01`。

## 随机字段
Face、Hair、Hair Color、Skin、Body、Clothing、Equipment、Accessories。

## 影响因子
Race、Class、Occupation、Faction、Location、Wealth、Culture、Weather、World State。
- 这些只作为数据标签/权重，不写死在 NPC 脚本。

## 职业服装映射（数据）
Farmer→Farmer Clothes、Blacksmith→Smith Apron、Soldier→Military Uniform、Mage→Robe、Merchant→Merchant Clothing、Noble→Formal Clothing。
- 通过 Occupation / Faction / Appearance Tag / Equipment Template 数据实现。

## 存储
- `assets/characters/` 下的 bodies/hair/faces/accessories 等。
