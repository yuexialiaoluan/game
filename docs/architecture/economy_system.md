# Economy / Shop 系统

## Economy
- 价格 = 基础价 × 地区系数 × 阵营/声望系数 × NPC Talent 系数 × 事件修正。
- 商店库存、供需（未来）、特殊事件影响。

## Shop
- 类型：普通商店、武器店、防具店、服装店、药店、材料店、酒馆、公会、理发店、其他服务。
- 统一 `ShopDefinition`：商品列表、库存、价格规则、刷新规则、购买/出售接口。

## 原则
- 商店与价格逻辑不写死在场景。
- 服装/理发等外观服务复用 Shop + Currency + Customization + Appearance。

## 依赖
Item、Faction/Reputation、NPC Talent、Time/Event、Condition/Effect、Save。
