class_name UIAudio
extends RefCounted

## UI 音效接口预留层。
## 当前没有已确认授权的音频资产，因此只定义稳定 SFX ID，不播放实际音频。
const SFX := {
	"button_hover": "",
	"button_click": "",
	"dialogue_next": "",
	"dialogue_choice": "",
	"menu_open": "",
	"menu_close": "",
	"error": ""
}

func play(sfx_id: String) -> void:
	# 后续 AudioManager 完成后，在这里路由到正式音频总线。
	if not SFX.has(sfx_id):
		return
