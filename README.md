# 《灰烬之上的勇者》 Ashes of the Brave

2.5D 像素风 Windows PC 单机 RPG。

- 项目名：Ashes of the Brave
- 显示名：《灰烬之上的勇者》
- 引擎：Godot 4.x（GDScript）
- 平台：Windows PC（非网页）
- 编辑器：VS Code + `geequlim.godot-tools`

## 快速开始
1. 使用 Godot 4.x 打开本目录下的 `project.godot`。
2. 按 F5 运行，窗口标题应显示《灰烬之上的勇者》。
3. 在 VS Code 中打开本目录进行脚本开发。

## 目录结构
- `assets/`：美术资源（见 `docs/art/`）
- `assets/audio/`：音频素材
- `data/`：数据驱动内容
- `docs/`：文档（架构见 `docs/architecture/`，美术见 `docs/art/`）
- `scenes/`：场景
- `scripts/`：GDScript 脚本
- `ui/`：UI 场景与主题
- `shaders/`：着色器
- `tests/`：测试
- `tools/`：工具脚本
- `builds/`：导出产物（不入库）

## 开发规范
详见 `AGENTS.md`。

## 当前状态
当前阶段：Playable Prototype 0.3（可玩村庄垂直切片）。

当前 EXE 已具备以下可操作流程：

- 标题菜单进入原型村庄，支持 WASD 移动、镜头缩放、交互和室内进出。
- 与 NPC 进行对话、接取任务、招募队友、管理队伍与共享背包。
- 使用背包、装备栏、商店、酒馆、铁匠强化和可重复挑战的临时副本。
- 完成基础战斗、经验、金币、装备掉落与随机装备词条验证。
- 使用本地 SaveService 保存和读取运行时状态。

这仍是技术与内容验证用原型，而非正式主线内容。已知限制、验证方式与下一步范围见：

- `docs/HANDOVER.md`
- `docs/development/2026-08-29-playable-prototype-0.3.md`
- `docs/art/asset_audit.md`

