# NPC Runtime

## 职责
`NPCRuntime` 管理 NPC 行为状态：Disposition / AI State / Activity / Location / Schedule / Recruitment State / is_dead，与 Actor 通用数据解耦。

## Navigation
Schedule -> AI Goal -> Navigation Request -> Navigation Service -> Movement。
