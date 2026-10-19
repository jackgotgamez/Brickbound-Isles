extends SceneTree

func _initialize() -> void:
	call_deferred("_run")

func _run() -> void:
	var state: Node = root.get_node_or_null("GameState")
	if state == null:
		push_error("GameState autoload is missing")
		quit(1)
		return

	var errors: Array[String] = preload("res://tests/game_state_test.gd").new().run(state)
	if errors.is_empty():
		print("PASS game_state_test")
		quit(0)
		return

	for message: String in errors:
		push_error(message)
	quit(1)
