# Surrender / Escape / Captured

## 职责
`SurrenderService` 按数据条件（如 HP 百分比）执行投降，Hostile → Surrendered；Escape/Fleeing、Captured 通过 Disposition 预留。

## Encounter
Encounter 中 Surrender 复用本服务与 Recruitment。
