# Animation 规范

## 状态
Idle、Moving、Attacking、Casting、Hurt、Dead、Interacting、Fishing、Stealth 等。
动画控制器根据状态切换。

## 动作列表（可扩展）
Idle、Walk、Run、Attack、Skill、Cast、Hit、Hurt、Death、Victory、Interact、Fish、Steal、Sneak、Lockpick。

## 与 Gameplay 解耦
- Gameplay 只发意图（如 `play_attack_animation`），不直接操作 Sprite/Animation 节点。
- Player/NPC/Combat 共用同一动画系统。

## 3D 世界中的呈现
- 角色动画仍是 2D 部件动画（骨骼局部变换 + Sprite Part 帧动画）。
- 角色整体作为 billboard 在 3D 世界移动与旋转。
- Battle/Portrait 可使用各自动画资源，逻辑状态保持一致。

## Retargeting 预留
- Human Skeleton → Human Attack；Elf/Orc Skeleton → Retarget。
- 当前不实现完整 Retargeting，只确保骨架差异不会导致动画系统重写。

## 存储
- 动画资源放 `assets/characters/animations/`。
