# VFX 规范

## 类型
Magic、Fire、Water、Ice、Lightning、Hit、Heal、Buff、Debuff、Smoke、Dust、Weather、Environment。

## 原则
- VFX 使用稳定 Asset ID，通过 Asset Registry 访问。
- VFX 与逻辑解耦：系统只请求 `play_vfx(id)`。

## 渲染
- 像素 VFX 与场景密度一致；必要时用帧动画或 shader，风格统一。

## 命名
- `vfx_fire_001`、`vfx_heal_001`、`vfx_buff_001`。

## 存储
- `assets/vfx/` 按类型分子目录。
