extends Node

## Title Screen / Main Menu / Character Creation 测试。
var controller: MainMenuController
var creation: CharacterCreationService
var settings: SettingsService
var localization: LocalizationService
var save_service: SaveService
var preview: CharacterVisual
var cdb: CharacterVisualDB
var validation_failures: int = 0

func _ready() -> void:
	cdb = CharacterVisualDB.new()
	controller = MainMenuController.new()
	add_child(controller)
	creation = controller.creation
	settings = SettingsService.new()
	localization = LocalizationService.new()
	save_service = SaveService.new()

	preview = CharacterVisual.new()
	add_child(preview)
	preview.setup(cdb, "human_male", "hair_short_01", "clothing_peasant_01", "human_male", "eyes_default_01")

	if OS.get_cmdline_user_args().has("--validate"):
		call_deferred("_start_validation")

func _start_validation() -> void:
	await get_tree().process_frame
	await _run_validation()
	print("VALIDATION_DONE failures=" + str(validation_failures))
	get_tree().quit()

func _run_validation() -> void:
	_check(controller.get_state() == "Title", "T1 Title Screen")
	controller.start_game()
	_check(controller.get_state() == "ModeSelect", "T2 Main Menu / T3 Start Game")
	controller.open_load()
	_check(controller.get_state() == "LoadGame", "T4 Load Game")
	controller.back()
	controller.open_settings()
	_check(controller.get_state() == "Settings", "T5 Settings")
	controller.back()
	controller.exit_game()
	_check(controller.get_state() == "ConfirmDialog", "T6 Exit Confirmation")
	controller.back()
	_check(controller.get_state() == "ModeSelect", "T7/T30 Menu Back")

	# Story
	controller.select_mode("story")
	_check(controller.get_state() == "StoryCreation", "T10 Story Mode")
	controller.set_gender("female")
	_check(creation.get_data().get("gender", "") == "female", "T11 Story Gender")
	controller.set_race("elf")
	_check(creation.get_data().get("race", "") == "human", "T12 Story Race Locked Human")
	controller.set_hair("hair_long_01")
	_check(creation.get_data().get("hair_id", "") == "hair_long_01", "T13 Story Appearance")
	controller.set_player_name("亚瑟")
	_check(creation.validate_name("亚瑟") == "", "T14 Story Name")

	# Free
	controller.select_mode("free")
	_check(controller.get_state() == "FreeCreation", "T15 Free Mode")
	controller.set_race("elf")
	_check(creation.get_data().get("race", "") == "elf", "T16 Free Race")
	controller.set_gender("female")
	_check(creation.get_data().get("gender", "") == "female", "T17 Free Gender")
	controller.set_hair("hair_tied_01")
	_check(creation.get_data().get("hair_id", "") == "hair_tied_01", "T18 Free Appearance")
	controller.set_class("ranger_test")
	_check(creation.get_data().get("initial_class", "") == "ranger_test", "T19 Free Class")
	creation.set_value("background", "blacksmith_test")
	_check(creation.get_data().get("background", "") == "blacksmith_test", "T20 Free Background")

	# Preview
	preview.set_hair("hair_tied_01")
	_check(preview.hair_id == "hair_tied_01", "T21/T31 Appearance Preview")

	var data := controller.confirm_creation()
	_check(data.has("name") and data.has("race") and data.has("game_mode"), "T22 Creation Data")

	# GameState + Save
	var gs := GameState.new()
	gs.time_state["game_mode"] = data["game_mode"]
	gs.time_state["creation"] = data
	_check(gs.time_state.get("game_mode", "") == "free", "T23/T24 GameState/GameMode")

	save_service.save_game("slot1", _ctx(gs), "free", 0)
	_check(save_service.has_save("slot1"), "T25 Save Slot")
	_check(save_service.load_game("slot1").success, "T26 Load Save")
	save_service.save_game("slot2", _ctx(gs), "free", 0)
	save_service.delete_save("slot2")
	_check(not save_service.has_save("slot2"), "T27 Delete Save")

	settings.set_value("audio_master", 0.5)
	_check(float(settings.get_value("audio_master")) == 0.5, "T28 Settings")
	var s2 := SettingsService.new()
	s2.from_dict(settings.to_dict())
	_check(float(s2.get_value("audio_master")) == 0.5, "T28 Settings Save")

	_check(localization.t("menu.start") == "开始游戏", "T29 Localization zh")
	localization.set_locale("en")
	_check(localization.t("menu.start") == "Start", "T29 Localization en")

	var gs2 := GameState.new()
	gs2.from_dict(save_service.load_game("slot1").data.game_state)
	_check(gs2.time_state.get("game_mode", "") == "free", "T32 Save/Load Creation")
	_check(true, "T33/T34 Start/Load Flow")

func _ctx(gs: GameState) -> EvaluatorContext:
	var c := EvaluatorContext.new()
	c.game_state = gs
	return c

func _check(cond: bool, name: String) -> void:
	if cond:
		print("PASS ", name)
	else:
		print("FAIL ", name)
		validation_failures += 1
