# Input 系统

## 原则
建立统一 Input Action 层，不让 Player 脚本直接绑定大量按键。

## 支持
键鼠、手柄、重绑定、UI 输入、战斗输入、世界输入。

## 设计
- 抽象动作（如 `move`、`interact`、`confirm`、`cancel`）。
- 按上下文路由：World / UI / Combat / Dialogue。
- 重绑定写入配置，运行时可切换。

## 依赖
配置/数据、Event（输入事件广播）。
