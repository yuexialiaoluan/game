class_name NPCBackgroundFactory

static func from_def(def: Dictionary) -> NPCBackground:
	var b := NPCBackground.new()
	b.from_def(def)
	return b

static func generate(templates: Dictionary, rng: RNGService, seed: int = 0) -> NPCBackground:
	if seed != 0:
		rng.set_seed(seed)
	var b := NPCBackground.new()
	b.id = "random_" + str(rng.next_int(100000))
	b.is_named = false
	b.origin = _pick(templates.get("origin", []), rng)
	b.occupation = _pick(templates.get("occupation", []), rng)
	b.personality = _pick(templates.get("personality", []), rng)
	b.motivation = _pick(templates.get("motivation", []), rng)
	b.short_description = "来自" + b.origin + "的" + b.occupation + "，" + b.personality + "，希望" + b.motivation + "。"
	return b

static func _pick(arr: Array, rng: RNGService) -> String:
	if arr.is_empty():
		return ""
	return str(arr[rng.next_int(arr.size())])
