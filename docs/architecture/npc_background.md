# NPC Background

## 职责
NPC/Character 背景数据：普通与命名 NPC 背景、随机背景生成、个人目标、招募关联。

## 结构
- `data/npc_backgrounds/npc_backgrounds.json`：templates（origin/occupation/personality/motivation）、common、named。

## 字段
Background ID、Short Description、Origin、Occupation、Personality、Motivation、Personal Goal、Rumor、Hidden Info。

## 随机
- `NPCBackgroundFactory.generate(templates, rng, seed)`，用 RNGService，可重现。

## 关联
- `Actor.background_id` 关联背景；背景的 Occupation/Personality/Motivation/Goal 可影响未来 Recruitment。
