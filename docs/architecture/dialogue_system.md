# Dialogue 系统

## 职责
Dialogue Data + Runtime：普通对话、多段对话、Choice、条件选项、效果、分支。

## 数据
- `data/dialogues/dialogues.json`：speaker、text、choices（text/conditions/effects）。

## 集成
- Choice 条件复用 ConditionEvaluator；效果复用 EffectExecutor。
- 文本使用 Localization ID，不硬编码。

## 分支
A → B → C；或 A → 条件判断 → B/C/D，由数据驱动。

## Action 接入
Dialogue Choice 可通过 un_action Effect 触发统一 Action。

## World NPC
NPC 的 Talk 通过 InteractionUI 进入 Dialogue，Choice 触发 Action。
