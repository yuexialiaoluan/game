class_name InteractableObject
extends RefCounted

## 统一可交互对象（Gameplay 层），对象只声明“它是什么”，具体执行走 Action。
var id: String = ""
var object_type: String = ""
var state: String = "Closed"
var data: Dictionary = {}
