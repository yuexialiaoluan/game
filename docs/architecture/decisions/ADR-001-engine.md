# ADR-001：引擎与语言

- 问题：长期 Windows PC 单机 RPG 用什么引擎与语言。
- 候选方案：Godot 4.x + GDScript；Unity + C#；Unreal + C++/BP；自研。
- 最终方案：Godot 4.x + GDScript。
- 选择原因：开源免费、Windows 原生导出、2D/2.5D 友好、迭代快、GDScript 与引擎集成度高、适合小团队长期维护。
- 优缺点：优点是轻量、可控、无授权负担；缺点是生态比 Unity 小、大型开放世界需自己控制流式加载与性能。
- 未来影响：技术栈锁定 GDScript；目录、命名、测试、CI 围绕 Godot 建立。
