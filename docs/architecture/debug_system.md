# Debug / Developer Console

## 目标
设计开发者控制台架构，当前不实现完整命令。

## 命令注册
- 统一 `CommandRegistry`，命令通过服务/事件执行。
- 未来命令：`give_gold`、`give_item`、`set_level`、`set_relationship`、`complete_quest`、`set_flag`、`teleport`、`spawn_enemy`、`set_time`、`set_weather`、`set_reputation`。

## 原则
- 调试命令走正式服务接口，不改内部实现。
- 生产构建默认禁用或受开关控制。

## 依赖
所有可调试的服务接口。
