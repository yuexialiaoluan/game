# Audio 系统

## 职责
BGM、环境音、UI 音效、战斗音效、技能音效、脚步、地区音乐、剧情音乐。

## 设计
- `AudioService` 管理总线与播放。
- 其他系统通过事件请求播放，不直接操作 AudioStreamPlayer 散落各处。
- 地区/状态切换时按数据切换 BGM 与环境音。

## 依赖
Event、World/Region、Combat、UI、Save（音频设置）。
