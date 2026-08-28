class_name NPCBackground
extends RefCounted

var id: String = ""
var is_named: bool = false
var short_description: String = ""
var origin: String = ""
var occupation: String = ""
var personality: String = ""
var motivation: String = ""
var personal_goal: String = ""
var rumor: String = ""
var hidden_info: String = ""

func from_def(def: Dictionary) -> void:
	id = str(def.get("id", ""))
	is_named = bool(def.get("is_named", false))
	short_description = str(def.get("short_description", ""))
	origin = str(def.get("origin", ""))
	occupation = str(def.get("occupation", ""))
	personality = str(def.get("personality", ""))
	motivation = str(def.get("motivation", ""))
	personal_goal = str(def.get("personal_goal", ""))
	rumor = str(def.get("rumor", ""))
	hidden_info = str(def.get("hidden_info", ""))

func summary() -> String:
	var parts: Array = []
	if origin != "":
		parts.append("来自" + origin)
	if occupation != "":
		parts.append("职业" + occupation)
	if personality != "":
		parts.append("性格" + personality)
	if motivation != "":
		parts.append("动机" + motivation)
	if parts.is_empty():
		return short_description
	return " ".join(parts)
