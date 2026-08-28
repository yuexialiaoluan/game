# Testing

## 类型
Unit Test、Integration Test、Data Validation、Save/Load Test、Combat Test、Condition Test、Effect Test。

## 重点
Condition、Effect、Save、RNG、NPC、Recruitment。

## 方式
- 用 headless 运行 Godot 项目执行测试。
- 数据校验在启动/CI 执行（Content Database 校验）。
- 存档测试：保存 → 载入 → 状态一致。
- RNG 测试：同种子可复现。
- 招募测试：Condition/Effect 流程与 Party 容量。

## 目录
- 测试代码放 `tests/`。
- 与 AGENTS.md 中“每完成主要功能必须运行测试”保持一致。

## 依赖
Content Database、Condition/Effect、Save、RNG、Actor、Party。
