# ADR-003：统一 Actor

- 问题：Player/NPC/Enemy/Monster/Companion 是否各自独立实现。
- 候选方案：五套独立角色类；继承链 Actor→Character→…；统一 Actor + 组件。
- 最终方案：统一 Actor + 组件 + 可变 Disposition 状态。
- 选择原因：支持“敌人→投降→招募→队友”等转换，避免不可逆类型判断；减少重复系统。
- 优缺点：优点是复用与扩展好；缺点是需要组件管理纪律，避免 Actor 变成 God Object。
- 未来影响：Character/NPC/Enemy/Recruitment/Party/Combat 都围绕 Actor 组件展开。
