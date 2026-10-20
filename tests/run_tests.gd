extends SceneTree

func _initialize() -> void:
	call_deferred("_run")

func _run() -> void:
	var state: Node = root.get_node_or_null("GameState")
	if state == null:
		push_error("GameState autoload is missing")
		quit(1)
		return

	var all_errors: Array[String] = []
	for test_path: String in [
		"res://tests/game_state_test.gd",
		"res://tests/scene_smoke_test.gd",
	]:
		var test_script: Script = load(test_path)
		if test_script == null:
			all_errors.append("Test script is missing: %s" % test_path)
			continue
		var test_errors: Array[String] = test_script.new().run(state)
		if test_errors.is_empty():
			print("PASS %s" % test_path.get_file().get_basename())
		else:
			all_errors.append_array(test_errors)

	for message: String in all_errors:
		push_error(message)
	quit(1 if not all_errors.is_empty() else 0)
