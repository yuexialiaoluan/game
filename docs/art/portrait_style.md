# Portrait 规范

## 定位
Portrait 是 UI/对话立绘，不是 World Sprite。

## 类型
- Full Body：全身立绘。
- Half Body：半身立绘。
- Bust：胸像。
- Dialogue Portrait：对话头像。
- Character Panel Portrait：角色面板。
- Party Portrait：队伍头像。

## 关联
- 通过稳定 Character ID 或 Portrait ID 关联，如 `character_iva` / `portrait_iva`。
- 对话系统不得硬编码 PNG 路径，只引用 Portrait ID。

## 风格
- 与角色像素风格一致或作为高精度立绘（需在 `art_direction.md` 确定），但同一角色各类型必须保持辨识度一致。
- 背景透明或统一边框由 UI 处理。

## 存储
- 放 `assets/characters/portraits/`。
