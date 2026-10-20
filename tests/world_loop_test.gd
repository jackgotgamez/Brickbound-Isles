extends RefCounted

func run(state: Variant) -> Array[String]:
	var errors: Array[String] = []
	for path: String in [
		"res://scenes/tree.tscn",
		"res://scenes/pickup.tscn",
		"res://scenes/quest_giver.tscn",
	]:
		_expect(ResourceLoader.exists(path), "world-loop scene should exist: %s" % path, errors)
	if not errors.is_empty():
		return errors

	state.inventory.clear()
	state.quest_stage = "not_started"
	state.points = 0
	state.imagination_tokens = 0
	state.achievements.clear()

	var test_world := Node3D.new()
	var scene_tree := Engine.get_main_loop() as SceneTree
	scene_tree.root.add_child(test_world)
	var tree_scene: PackedScene = load("res://scenes/tree.tscn")
	var tree: Node3D = tree_scene.instantiate()
	test_world.add_child(tree)
	_expect(tree.is_in_group("resources"), "tree should be a hittable world resource", errors)
	tree.call("hit")
	tree.call("hit")
	_expect(not tree.get("is_broken"), "tree should withstand two hits", errors)
	tree.call("hit")
	_expect(tree.get("is_broken"), "tree should break on the third hit", errors)
	_expect(_pickup_count(tree) == 5, "breaking a tree should spawn exactly five timber pickups", errors)
	tree.call("hit")
	_expect(_pickup_count(tree) == 5, "a broken tree should not spawn duplicate pickups", errors)

	var player := Node3D.new()
	player.add_to_group("player")
	test_world.add_child(player)
	var pickup: Node
	for child: Node in tree.get_children():
		if child.is_in_group("pickups"):
			pickup = child
			break
	_expect(pickup != null, "broken tree should contain collectible timber", errors)
	if pickup == null:
		test_world.free()
		return errors
	pickup.call("collect_for", player)
	pickup.call("collect_for", player)
	_expect(state.inventory.get("timber", 0) == 1, "a pickup should grant timber only once", errors)

	var quest_scene: PackedScene = load("res://scenes/quest_giver.tscn")
	var quest_giver: Node = quest_scene.instantiate()
	test_world.add_child(quest_giver)
	quest_giver.call("interact")
	_expect(state.quest_stage == "active", "first NPC interaction should start the timber mission", errors)
	quest_giver.call("interact")
	_expect(state.quest_stage == "active", "mission should remain active below five timber", errors)
	state.collect_item("timber", 3)
	quest_giver.call("interact")
	_expect(state.quest_stage == "active", "mission should not complete with only four timber", errors)
	state.collect_item("timber", 1)
	quest_giver.call("interact")
	_expect(state.quest_stage == "completed", "NPC should complete mission with five timber", errors)
	_expect(state.points == 100, "mission should award exactly 100 points", errors)
	_expect(state.imagination_tokens == 10, "mission should award exactly 10 Imagination Tokens", errors)
	quest_giver.call("interact")
	_expect(state.points == 100 and state.imagination_tokens == 10, "mission reward should be one-time", errors)
	test_world.free()
	return errors

func _expect(condition: bool, message: String, errors: Array[String]) -> void:
	if not condition:
		errors.append(message)

func _pickup_count(parent: Node) -> int:
	var count := 0
	for child: Node in parent.get_children():
		if child.is_in_group("pickups"):
			count += 1
	return count
