# Asset Audit — 素材审计

审计时间：2026-08-29
范围：`assets/`（重点 `assets/123/`）
原则：只读审计，未移动/删除/覆盖任何原始素材；未修改 Gameplay 逻辑。

## 总体统计
- 文件总数：1657
- PNG：1370，PSD：64，GIF：62，Aseprite：37，字体：多格式，音频：6（wav/mp3/ogg 各 2），其他（txt/license/DStore/css 等）
- 总大小：约 126.6 MB

## 主要素材包分类

| 包 | 类型 | 主要尺寸 | 兼容性 | License |
| --- | --- | --- | --- | --- |
| Village_NPC_Vol1 | NPC Full Character（8方向 Idle+Walk） | 帧 96x96，sheet 768x192 | 需缩放至 PPU32；非模块化 | 商用允许，禁止再分发 |
| Human Male Model | character_parts / 模型部件 | 宽幅 sheet（512–3328 px） | 疑似模块化，需拆分 | UNKNOWN |
| The Male adventurer - Free | character_parts / modular | 48x64 及 384 大图 | 疑似模块化 | UNKNOWN |
| GandalfHardcore Archer | character_parts / 弓箭手 | sheet 704x320 | 疑似模块化 | 商用允许，禁止再分发/AI/NFT |
| Orcs | monsters | 576x384 sheet | 疑似可拆分 | 商用允许，禁止再分发 |
| EleonoreAndJoanna | npcs / 小角色 | 32x32、64x64 | 偏 2D，PPU 需对齐 | 商用允许，禁止再分发 |
| Portraits_v1 | portraits | 48x48、96x96、128x128 | 适合 UI/Dialogue 立绘 | UNKNOWN |
| Free-Cursed-Land Tileset | tilesets（16x16 top-down） | 16x16 tiles | 2D tiles，与 3D 环境不符 | Craftpix（需核对页面） |
| Rasaks_Fantasy_Tileset | tilesets / environment | 多种大图 | 2D，参考用 | UNKNOWN |
| RF_Catacombs_v1.0 | tilesets / dungeon | 256x256 等 | 2D | Public/商用，禁止再分发 |
| RPGW_Caves_v2.1 | tilesets / dungeon | 1632x1536 等 | 2D | 商用允许，禁止再分发 |
| top-down-collection-pack | environment / 场景 | 多规格 | 2D top-down | 商用允许，可再分发 |
| FL_Houses_Demo_v1.0 | buildings | 1824x320 等 | 2D 建筑 | 商用允许，禁止再分发 |
| Pixel Lands Village Demo | buildings / village | 256x256、512x512 | 2D | 商用允许，禁止再分发 |
| Modern_Interiors_Free_v2.2 | interiors | 多规格 | 2D | **仅非商业**（风险） |
| tavern | interiors / isometric 32x16 | 32x16 | 等距视角，与正交 2.5D 不符 | README 无明确许可 |
| Fence & Barrier Pack | environment / props | 32x32 | 2D | UNKNOWN |
| 16x16 Assorted RPG Icons | icons | 16x16 图标 | UI 图标，可缩放 | UNKNOWN |
| 16x16 Weapons RPG Icons | icons / items | 16x16 图标 | UI 图标 | UNKNOWN |
| Cryo's Mini GUI（含 Controller/Social） | ui | 128x… 等多规格 | UI 面板/按钮 | UNKNOWN |
| Pixel UI pack 3 / (1) | ui | 240x144 等 | UI | UNKNOWN |
| UIBundleFree | ui | 256x… | UI | UNKNOWN |
| MegaPackFree | ui / icons / 杂项 | 多规格 | 参考 | UNKNOWN |
| webfontkit-BoldPixels | fonts | TTF/WOFF/… | 字体 | CC BY-SA 4.0（需署名） |
| 音频 | audio/music | wav/mp3/ogg 共 6 | 可接入 AudioService | UNKNOWN |

## License 风险
- 可商用、禁止再分发：Village_NPC、GandalfHardcore、Orcs、EleonoreAndJoanna、RF_Catacombs、RPGW_Caves、FL_Houses、Pixel Lands、top-down-collection。
- **高风险**：Modern_Interiors_Free_v2.2（仅非商业）。
- **需核对**：Craftpix（Free-Cursed-Land）、tavern（无明确许可）。
- **UNKNOWN**：Rasaks、16x16 Icons、Cryo GUI、Pixel UI、UIBundleFree、MegaPackFree、Portraits、Human Male Model、The Male adventurer、Fence、音频。
- CC BY-SA：BoldPixels 字体（可使用，需署名，改字体需同协议）。

## 与现有架构兼容性
- 3D 环境 + 2D 角色：tilesets/building 素材为 2D，不直接适配，建议作为参考或后续 2D 战斗/UI 复用。
- 角色：优先使用“可拆分层”的 modular 包；Full Character 需额外拆分/缩放。
- PPU32：96px 帧、16px tile 等需统一缩放；48/64 像素角色更接近现有规模。
- UI：Pixel UI/Cryo/UIBundle 可直接用于 HUD/菜单。
- 字体：BoldPixels 可直接用于像素风格 UI（需署名）。

## 推荐接入列表
- P0（Demo 立即用）：Portraits_v1、Pixel UI pack、Cryo's Mini GUI、UIBundleFree、16x16 Icons、BoldPixels 字体。
- P1（第二阶段）：Village_NPC（缩放/拆分）、The Male adventurer、Archer、Orcs、EleonoreAndJoanna、RF_Catacombs、RPGW_Caves、FL_Houses、Pixel Lands。
- P2（暂时不用）：Rasaks、Free-Cursed-Land、top-down-collection、Fence、MegaPackFree。
- INCOMPATIBLE：Modern_Interiors（仅非商业）、tavern（等距 32x16 与正交 2.5D 冲突）。

## 对现有系统的接入建议
- CharacterVisual / AppearanceResolver / CharacterSkeleton / CharacterAnimator：优先接入可拆分的 modular 角色，建立 96px→PPU32 缩放与骨骼挂点映射。
- CharacterBillboard3D：World Sprite 使用 48/64px 或缩放后的 96px 帧。
- NPC：Village_NPC / EleonoreAndJoanna 做 NPC 外观模板。
- Equipment / Inventory：16x16 Weapons/Icons 做图标。
- Shop / Dialogue / Quest / Battle UI：Pixel UI + Cryo GUI + UIBundleFree。
- Combat Unit View / VFX：Archer、Orcs、Male adventurer 做战斗单位；VFX 暂无匹配包，需自建或另寻。
- World Exploration：建筑/环境 2D 素材暂不接入 3D 世界，仅作参考。

## 备注
- 素材包内混入 `.DS_Store`、`__MACOSX`、`Contact/Links` 等，接入前应清理。
- 未确认授权的包一律标记 UNKNOWN，不假设可商用。
