# ADR-007：外观系统

- 问题：装备/染色/头盔隐藏头发等外观如何组织，且不把外观写死在装备逻辑。
- 候选方案：装备直接改 Sprite；每件装备挂独立外观脚本；Appearance Resolver + 分层数据。
- 最终方案：Gameplay Data 与 Appearance Data 分离，Appearance Resolver 计算最终分层结果。
- 选择原因：支持 Layer/Override/Hide/Replace/Color/Dye，扩展新装备无需改逻辑。
- 优缺点：优点是灵活、数据驱动；缺点是 Resolver 规则需清晰定义。
- 未来影响：服装店/理发店/染色店/幻化等复用同一 Customization + Appearance。
