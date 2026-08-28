# ADR-011：装备视觉与属性分离

- 问题：装备外观如何绑定骨骼，且支持幻化/染色。
- 候选方案：装备逻辑直接改 Sprite；装备脚本各自挂外观；Gameplay/Visual 数据分离 + Resolver。
- 最终方案：装备拆为 Gameplay Data 与 Visual Data，由 Appearance Resolver 统一解析。
- 选择原因：支持 Transmog、挂点/隐藏/覆盖/染色，扩展装备不改逻辑。
- 优缺点：优点是解耦与灵活；缺点是 Resolver 规则需集中维护。
- 未来影响：服装店/幻化/染色店复用同一 Customization + Appearance。
