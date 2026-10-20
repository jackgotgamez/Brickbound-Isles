extends RefCounted

func run(scene_tree: SceneTree) -> Array[String]:
	var errors: Array[String] = []
	var runtime_save_path := "user://brickbound_runtime_test_save.json"
	_remove_user_file(runtime_save_path)
	GameState.inventory.clear()
	GameState.quest_stage = "not_started"
	GameState.player_position = Vector3.ZERO
	GameState.points = 0
	GameState.imagination_tokens = 0
	GameState.achievements.clear()
	var main_scene: PackedScene = load("res://scenes/main.tscn")
	var main: Node3D = main_scene.instantiate()
	main.set("save_path", runtime_save_path)
	scene_tree.root.add_child(main)
	await scene_tree.physics_frame
	await scene_tree.physics_frame

	var player := main.get_node("Player") as PlayerController
	var start_position := player.global_position
	Input.action_press("move_forward")
	for _frame: int in range(30):
		await scene_tree.physics_frame
	Input.action_release("move_forward")
	var end_position := player.global_position
	_expect(Vector2(end_position.x - start_position.x, end_position.z - start_position.z).length() > 0.5, "holding W should move the minifig across the ground", errors)

	var yaw_before := player.camera_pivot.rotation.y
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
	var mouse_motion := InputEventMouseMotion.new()
	mouse_motion.relative = Vector2(32.0, 0.0)
	player._unhandled_input(mouse_motion)
	_expect(not is_equal_approx(player.camera_pivot.rotation.y, yaw_before), "mouse movement should orbit the camera", errors)

	_expect(player.is_on_floor(), "heightmap terrain should keep the minifig grounded", errors)
	player.jump()
	_expect(player.velocity.y > 0.0, "Space should start a jump", errors)

	var giver := main.get_node("World/Mira") as QuestGiver
	player.global_position = giver.global_position + Vector3(0.0, 1.0, 1.4)
	player._update_interaction_prompt()
	_expect(giver.get_node("QuestPrompt").visible, "NPC prompt should show when the minifig is close", errors)
	player._try_interact()
	_expect(GameState.quest_stage == "active", "E should start the NPC mission", errors)
	var hud := main.get_node_or_null("HUD") as GameHUD
	_expect(hud != null, "main scene should include the game HUD", errors)
	if hud != null:
		var quest_label := hud.get_node_or_null("ProgressPanel/Margin/Content/QuestLabel") as Label
		_expect(quest_label != null, "HUD should include a mission label", errors)
		if quest_label != null:
			_expect(quest_label.text.contains("Bring Mira 5 timber"), "HUD should show the active mission", errors)
	_expect(FileAccess.file_exists(runtime_save_path), "mission progress should autosave", errors)
	var saved_data: Variant = JSON.parse_string(FileAccess.get_file_as_string(runtime_save_path))
	_expect(typeof(saved_data) == TYPE_DICTIONARY and saved_data.get("quest_stage") == "active", "autosave should contain the active mission", errors)

	var resources := scene_tree.get_nodes_in_group("resources")
	_expect(resources.size() >= 1, "island forest should contain gatherable trees", errors)
	if not resources.is_empty():
		var tree := resources[0] as TreeResource
		player.global_position = tree.global_position + Vector3(0.0, 1.0, 1.4)
		player._update_interaction_prompt()
		_expect(tree.get_node("BreakPrompt").visible, "tree prompt should show when the minifig is close", errors)
		player._try_hit_resource()
		player._try_hit_resource()
		player._try_hit_resource()
		_expect(tree.is_broken, "player attack input should break a nearby tree", errors)

	main.queue_free()
	await scene_tree.process_frame
	var relaunched_main: Node3D = main_scene.instantiate()
	relaunched_main.set("save_path", runtime_save_path)
	scene_tree.root.add_child(relaunched_main)
	await scene_tree.physics_frame
	_expect(GameState.quest_stage == "active", "relaunch should restore the active mission", errors)
	_expect(GameState.achievements.has("first_tree"), "relaunch should restore earned achievements", errors)
	var relaunched_hud := relaunched_main.get_node("HUD") as GameHUD
	var relaunched_quest_label := relaunched_hud.get_node("ProgressPanel/Margin/Content/QuestLabel") as Label
	_expect(relaunched_quest_label.text.contains("Bring Mira 5 timber"), "relaunch HUD should restore mission progress", errors)
	relaunched_main.queue_free()
	await scene_tree.process_frame
	_remove_user_file(runtime_save_path)
	return errors

func _expect(condition: bool, message: String, errors: Array[String]) -> void:
	if not condition:
		errors.append(message)

func _remove_user_file(path: String) -> void:
	if FileAccess.file_exists(path):
		DirAccess.remove_absolute(ProjectSettings.globalize_path(path))
