extends RefCounted

func run(state: Variant) -> Array[String]:
	var errors: Array[String] = []
	state.inventory.clear()
	state.quest_stage = "not_started"
	state.player_position = Vector3(2.5, 1.2, -7.0)
	state.points = 0
	state.imagination_tokens = 0
	state.achievements.clear()
	_remove_user_file("user://brickbound_missing_test.json")

	var scene_tree := Engine.get_main_loop() as SceneTree
	var test_world := Node3D.new()
	scene_tree.root.add_child(test_world)
	var player := Node3D.new()
	player.add_to_group("player")
	test_world.add_child(player)

	var pickup: Pickup = load("res://scenes/pickup.tscn").instantiate()
	test_world.add_child(pickup)
	pickup.collect_for(player)
	_expect(state.achievements.has("first_pickup"), "first pickup should unlock its achievement", errors)
	_expect(state.achievements.count("first_pickup") == 1, "first pickup achievement should unlock once", errors)

	var tree: TreeResource = load("res://scenes/tree.tscn").instantiate()
	test_world.add_child(tree)
	tree.hit()
	tree.hit()
	tree.hit()
	_expect(state.achievements.has("first_tree"), "first tree should unlock its achievement", errors)

	var giver: QuestGiver = load("res://scenes/quest_giver.tscn").instantiate()
	test_world.add_child(giver)
	giver.interact()
	state.collect_item("timber", 5)
	giver.interact()
	_expect(state.achievements.has("first_quest"), "first completed mission should unlock its achievement", errors)
	_expect(state.points == 100 and state.imagination_tokens == 10, "quest reward should remain 100 points and 10 tokens", errors)
	_expect(state.save_progress("user://brickbound_progress_test.json"), "progress should save to a test path", errors)

	state.inventory.clear()
	state.quest_stage = "not_started"
	state.player_position = Vector3.ZERO
	state.points = 0
	state.imagination_tokens = 0
	state.achievements.clear()
	_expect(state.load_progress("user://brickbound_progress_test.json"), "saved progress should load", errors)
	_expect(state.inventory.get("timber", 0) == 1, "completed quest should consume five timber", errors)
	_expect(state.player_position.is_equal_approx(Vector3(2.5, 1.2, -7.0)), "player position should survive a round trip", errors)
	_expect(state.points == 100 and state.imagination_tokens == 10, "quest rewards should survive a round trip", errors)
	for achievement: String in ["first_pickup", "first_tree", "first_quest"]:
		_expect(state.achievements.has(achievement), "%s should survive a round trip" % achievement, errors)

	state.points = 5
	_expect(not state.load_progress("user://brickbound_missing_test.json"), "missing save should report defaults", errors)
	_expect(state.points == 0 and state.achievements.is_empty(), "missing save should restore safe defaults", errors)

	var malformed := FileAccess.open("user://brickbound_malformed_test.json", FileAccess.WRITE)
	if malformed == null:
		errors.append("malformed-save fixture should be writable")
	else:
		malformed.store_string("{ malformed")
		malformed.close()
		state.points = 9
		_expect(not state.load_progress("user://brickbound_malformed_test.json"), "malformed save should report defaults", errors)
		_expect(state.points == 0 and state.inventory.is_empty(), "malformed save should restore safe defaults", errors)

	test_world.free()
	for path: String in ["user://brickbound_progress_test.json", "user://brickbound_malformed_test.json"]:
		if FileAccess.file_exists(path):
			DirAccess.remove_absolute(ProjectSettings.globalize_path(path))
	return errors

func _expect(condition: bool, message: String, errors: Array[String]) -> void:
	if not condition:
		errors.append(message)

func _remove_user_file(path: String) -> void:
	if FileAccess.file_exists(path):
		DirAccess.remove_absolute(ProjectSettings.globalize_path(path))
