# 游戏模式（故事模式 / 自由模式）

## 原则
故事模式与自由模式共享底层系统，不复制两套 Character/World/Combat。

## 故事模式
- 男/女、自定义姓名、捏脸、部分外观。
- 不能选种族（固定人类）。
- 主角：王国边境艾尔村 17 岁少年/少女。

## 自由模式
- 种族、性别、姓名、捏脸、外观、初始职业、初始背景、初始构筑均可自定义。

## 设计
- 用 `GameMode Rules / Configuration` 限制选项与规则。
- 两个模式只是不同配置，共用同一套 Actor/Character/World/Combat/Customization。

## 依赖
Character Customization、Actor、World、Content Database、Save。
