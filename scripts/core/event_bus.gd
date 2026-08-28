class_name EventBus
extends RefCounted

## 统一事件派发：系统之间通过事件名解耦。
var _listeners: Dictionary = {}

func subscribe(event_name: String, cb: Callable) -> void:
	if not _listeners.has(event_name):
		_listeners[event_name] = []
	_listeners[event_name].append(cb)

func unsubscribe(event_name: String, cb: Callable) -> void:
	var list = _listeners.get(event_name, [])
	if list.has(cb):
		list.erase(cb)

func emit(event_name: String, payload = null) -> void:
	for cb in _listeners.get(event_name, []):
		cb.call(payload)
