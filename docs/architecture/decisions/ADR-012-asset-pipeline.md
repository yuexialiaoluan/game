# ADR-012：统一 Asset Pipeline 与 Registry

- 问题：资源如何长期生产、替换、扩展，且不污染 Gameplay 代码。
- 候选方案：脚本直接写 `res://assets/...`；各处路径常量；Asset Registry + 稳定 ID。
- 最终方案：Asset Registry + 稳定 ID + 统一生产流程与命名。
- 选择原因：换素材不改代码，支持替换/删除/版本与依赖检查。
- 优缺点：优点是稳定引用与可维护；缺点是需维护 Registry 映射。
- 未来影响：表现资源与逻辑 Content Database 分离，新增资源不重写系统。
