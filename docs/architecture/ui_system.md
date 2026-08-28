# UI 系统

## 原则
UI 与游戏逻辑分离：UI 只读取状态、发送意图、订阅事件。

## 屏幕清单
主菜单、故事模式、自由模式、角色创建、捏脸、HUD、对话、角色面板、Party、Inventory、Equipment、Skill、Feat、Talent、Quest、Map、Shop、Recruitment、Guild、Combat、Dungeon、Settings。

## 视觉方向
- 世界/角色：2.5D 像素风。
- UI：现代、半透明、玻璃质感、科技感 HUD。
- 只参考“现代科幻 HUD 的设计理念”，不复制任何商业游戏的 UI、素材或具体设计。

## 结构
- `ui/scenes/`：UI 场景。
- `ui/themes/`：Theme 与样式。
- UI 组件通过事件/服务刷新，避免轮询与逻辑耦合。

## 依赖
Localization、Event、各系统服务接口、Camera（HUD 对齐）。

## RPG UI
RPGUI 只读服务结果；UI → Service → Gameplay State → EventBus → UI 刷新。
