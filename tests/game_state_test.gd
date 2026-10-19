extends RefCounted

func run(state: Variant) -> Array[String]:
	var errors: Array[String] = []
	_expect(state.points == 0, "points should start at zero", errors)
	_expect(state.imagination_tokens == 0, "Imagination Tokens should start at zero", errors)
	_expect(state.quest_stage == "not_started", "quest should start unaccepted", errors)
	_expect(state.inventory.is_empty(), "inventory should start empty", errors)
	_expect(state.achievements.is_empty(), "achievements should start empty", errors)

	_expect(state.start_timber_quest(), "first quest interaction should start the mission", errors)
	_expect(not state.start_timber_quest(), "starting an active quest twice should be rejected", errors)
	for _index: int in range(4):
		state.collect_item("timber")
	_expect(not state.try_complete_timber_quest(), "quest should refuse completion below five timber", errors)
	_expect(state.points == 0 and state.imagination_tokens == 0, "rejected completion must not award currency", errors)

	state.collect_item("timber")
	_expect(state.try_complete_timber_quest(), "five timber should complete the quest", errors)
	_expect(state.quest_stage == "completed", "successful completion should mark the quest complete", errors)
	_expect(state.inventory.get("timber", 0) == 0, "quest completion should consume five timber", errors)
	_expect(state.points == 100, "timber quest should award exactly 100 points", errors)
	_expect(state.imagination_tokens == 10, "timber quest should award exactly 10 Imagination Tokens", errors)
	_expect(not state.try_complete_timber_quest(), "completed quest should not pay out twice", errors)
	_expect(state.points == 100 and state.imagination_tokens == 10, "duplicate completion must not change rewards", errors)

	state.unlock_achievement("first_pickup")
	state.unlock_achievement("first_pickup")
	_expect(state.achievements.count("first_pickup") == 1, "achievement should unlock only once", errors)

	var saved_position := Vector3(12.5, 2.0, -8.25)
	state.update_player_position(saved_position)
	_expect(state.player_position == saved_position, "player position should update", errors)
	var save_path := "user://game_state_test.json"
	_expect(state.save_progress(save_path), "progress should save to a local JSON file", errors)
	var restored: Variant = load("res://scripts/game_state.gd").new()
	_expect(restored.load_progress(save_path), "saved progress should load", errors)
	_expect(restored.player_position == saved_position, "saved player position should round-trip", errors)
	_expect(restored.points == 100 and restored.imagination_tokens == 10, "saved rewards should round-trip", errors)
	_expect(restored.achievements.count("first_pickup") == 1, "saved achievements should round-trip once", errors)
	restored.free()
	DirAccess.remove_absolute(ProjectSettings.globalize_path(save_path))
	return errors

func _expect(condition: bool, message: String, errors: Array[String]) -> void:
	if not condition:
		errors.append(message)
