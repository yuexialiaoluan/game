# AGENTS.md — 《灰烬之上的勇者》 Ashes of the Brave 开发规范

本文件是本项目的协作与开发规范，适用于本目录树内的所有代码、场景、数据、资源与文档。
任何开发者或 AI 助手在本项目中工作时，必须先阅读并遵守本文件。正式架构设计以 `docs/architecture/` 为准；美术资源规范以 `docs/art/` 为准。

## 1. 项目技术栈
- 引擎：Godot 4.x（当前基线 4.7.2 stable）
- 语言：GDScript
- 编辑器：VS Code（建议安装 `geequlim.godot-tools`）
- 版本控制：Git
- 目标平台：Windows PC 原生桌面（非网页）
- 画面风格：2.5D 像素风 RPG
- 禁止：使用 HTML/CSS/React 作为游戏主体

## 2. 文件组织规范
- `assets/`：美术资源，结构见 `docs/art/`（characters/equipment/environment/vfx/audio/ui/fonts）。
- `assets/audio/`：音频素材，按 `bgm/`、`sfx/`、`ambient/`、`voice/`、`ui/` 分类。
- `data/`：数据驱动内容，按 `characters/`、`races/`、`classes/`、`skills/`、`feats/`、`talents/`、`npcs/`、`enemies/`、`creatures/`、`items/`、`weapons/`、`armors/`、`materials/`、`quests/`、`dialogues/`、`factions/`、`locations/`、`dungeons/`、`events/`、`recipes/`、`shops/`、`appearances/`、`interactions/` 分类；表示方式见 `docs/architecture/data_model.md`。
- `docs/`：设计与架构文档；架构决策见 `docs/architecture/`。
- `scenes/`：场景文件，按功能分子目录。
- `scripts/`：GDScript 脚本，按 `main/`、`autoload/`、`systems/` 分类。
- `ui/`：UI 场景与主题，按 `scenes/`、`themes/` 分类。
- `shaders/`：着色器。
- `tests/`：自动化测试。
- `tools/`：编辑器工具脚本。
- `builds/`：导出产物，不进入版本控制。
- `addons/`：经评审的第三方插件。

## 3. 命名规范
- 文件与目录：`snake_case`，例如 `player_controller.gd`、`main_menu.tscn`。
- 场景节点：`PascalCase`，例如 `Player`、`InventoryUI`。
- 变量、函数、信号：`snake_case`。
- 常量与枚举成员：`SCREAMING_SNAKE_CASE`。
- 类名与类型：`PascalCase`。
- 私有成员：以下划线开头，例如 `_health`。
- 数据 ID：`snake_case` 字符串，内容系统统一通过 ID 引用。

## 4. GDScript 编码规范
- 使用 Godot 4 语法，并尽可能使用静态类型标注。
- 缩进使用 Tab。
- 函数职责单一，避免过长函数。
- 可在编辑器中配置的属性使用 `@export`。
- 错误通过 `push_error()` / `push_warning()` 上报，不得静默吞掉异常。
- 只在关键逻辑处写注释，避免无意义注释。
- 遵循 Godot 官方 GDScript 风格指南。

## 5. 场景组织规范
- 每个场景只承担一个明确职责。
- 场景文件放 `scenes/`，脚本放 `scripts/`，两者分离存放。
- 优先组合而非深层继承。
- 全局服务使用 autoload，autoload 中不放具体内容数据。
- 保持场景树层级清晰，避免深层嵌套。

## 6. 数据驱动原则
- 数值、文案、掉落、成长曲线等内容一律放在 `data/`。
- 优先使用 JSON 或 `.tres` 资源描述数据。
- 同类内容必须使用统一的数据结构（schema）。

## 7. 内容系统隔离（硬性要求）
- NPC、装备、技能、任务等内容不得硬编码进核心系统。
- 内容只能以数据形式存在，核心系统通过 ID 读取数据。
- 新增内容应只需添加数据，而不修改核心逻辑代码。

## 8. 变更管理（硬性要求）
- 不得随意删除已有功能。
- 修改已有系统前必须检查其依赖关系。
- 每完成一个主要功能必须运行测试。
- 修复 Bug 后必须再次运行测试。
- 不允许为了通过测试而关闭或绕过任何功能。
- 所有重要系统必须保持模块化。

## 9. 美术与逻辑分离
- 美术素材与逻辑代码严格分离。
- 素材放入 `assets/`，逻辑放入 `scripts/`。
- 不得在素材导入或资源中嵌入业务逻辑。

## 10. 第三方依赖
- 不下载或引入未经确认的大型第三方框架。
- 任何插件都需评审后放入 `addons/`。

## 11. 测试
- 自动化测试统一放在 `tests/`。
- 当前基线运行方式：`godot --headless --path . --quit-after 3`。
- 后续引入测试框架时，需在本文档补充统一命令。

## 12. 构建与发布
- 目标平台为 Windows PC 原生桌面，不制作网页版本。
- 导出产物放入 `builds/`，不提交到版本控制。

## 13. 美术资源规范
- 美术生产流程、命名、Asset ID 与目录规范见 docs/art/。
- 游戏逻辑通过 Asset Registry / 稳定 ID 引用资源，不得在脚本里硬编码 es://assets/... 路径。

