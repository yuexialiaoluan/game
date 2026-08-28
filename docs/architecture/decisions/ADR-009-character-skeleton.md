# ADR-009：角色骨骼与挂点

- 问题：角色如何支持多层外观、装备绑定与不同种族骨架。
- 候选方案：单张 Sprite 全量绘制；每角色自定义节点；统一 Skeleton + Bone + Attachment。
- 最终方案：统一 Skeleton/Bone/Attachment，基础节点可扩展，装备绑定到挂点。
- 选择原因：支持分层组合、装备绑定、种族骨架差异与未来 Retargeting。
- 优缺点：优点是复用与扩展；缺点是需维护骨架定义与挂点约定。
- 未来影响：Appearance Resolver 与 Animation 围绕 Skeleton 展开；不同种族无需重写核心。
