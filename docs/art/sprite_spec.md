# Sprite 与像素渲染规范

## 统一标准（角色系统统一遵守）
- World Sprite 画布：`80 x 96` px（透明背景）。
- Foot Pivot（脚底锚点）：`(40, 80)`，即底部中央、距底边 16px 余量。
- Pixel Density：`PPU = 32`（32 像素 = 1 个世界单位）。
- 3D billboard `pixel_size`：`1 / 32 = 0.03125`。
- Texture Filter：`Nearest`。
- Pixel Snap：开启。
- Mipmap：关闭。
- 缩放：整数倍优先，禁止非整数缩放。
- Animation Frame Size：与 World Sprite 画布一致 `80 x 96`。
- 角色逻辑位置 = Foot Pivot 对应的脚底接触点，不随换装/动画改变。

## 三种 Sprite 分类
- World Sprite：3D 世界中的 2D billboard。
- Battle Sprite：战斗表现，可独立资源。
- Portrait：UI/对话立绘，与 World Sprite 完全分离。

## 分层
Body、Face、Eyes、Hair、Clothing、Armor、Helmet、Gloves、Boots、MainHand、OffHand、Cape、Accessory。
角色由多个视觉层组成，不合成单张 Sprite。

## 命名
按 `docs/art/asset_naming.md`，如 `character_body_human_male_01`、`hair_long_01`、`weapon_iron_sword_01`。

## 存储
- World/Battle Sprite：`assets/characters/sprites/`。
- Portrait：`assets/characters/portraits/`。
