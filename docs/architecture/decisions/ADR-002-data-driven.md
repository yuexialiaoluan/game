# ADR-002：数据驱动

- 问题：大量内容（NPC/技能/装备/任务/对话）如何组织，避免硬编码。
- 候选方案：全部 JSON；全部 GDScript 常量；全部自定义 Resource；混合。
- 最终方案：内容主体用自定义 Resource，本地化/批量表格/存档用 JSON，少量内部常量用脚本。
- 选择原因：Resource 类型安全、可 Inspector 编辑、支持引用；JSON 易生成/易 diff/易迁移；避免过度 JSON 化。
- 优缺点：优点是开发体验与可维护性平衡；缺点是自定义 Resource 需维护序列化字段与迁移。
- 未来影响：Content Database 成为唯一加载入口，数据校验与迁移围绕 ID 建立。
