# Party 系统

## 容量
- 出战：最多 4 人。
- 备用：最多 4 人。
- 总计：8 人。

## 能力
加入、离队、招募、解雇、替换、编队、装备、技能配置、战斗位置、队友关系。

## 设计
- Party 是 Actor 的成员状态集合，不复制 Character 数据。
- `PartySystem` 管理 active/reserve 列表与顺序。
- 编队与战斗位置由 Combat 读取。

## 依赖
Actor、Recruitment、Condition/Effect、Equipment/Skills、Combat、Save。

## 服务
PartyService 管理 Active<=4 / Reserve<=4 / 总<=8，支持 swap。

## Recruitment
招募成功后由 PartyService 管理 Active/Reserve。
