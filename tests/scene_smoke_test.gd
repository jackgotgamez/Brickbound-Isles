extends RefCounted

const REQUIRED_ACTIONS := [
	"move_forward",
	"move_back",
	"move_left",
	"move_right",
	"jump",
	"interact",
	"hit_resource",
]

func run(_state: Variant) -> Array[String]:
	var errors: Array[String] = []
	_expect(ResourceLoader.exists("res://scenes/main.tscn"), "main scene should exist", errors)
	_expect(ResourceLoader.exists("res://scripts/player_controller.gd"), "player controller should exist", errors)
	if ResourceLoader.exists("res://scenes/main.tscn"):
		var packed: PackedScene = load("res://scenes/main.tscn")
		var main: Node = packed.instantiate()
		_expect(main is Node3D, "main scene root should be Node3D", errors)
		var player: Node = main.get_node_or_null("Player")
		_expect(player is CharacterBody3D, "player should use CharacterBody3D", errors)
		if player != null:
			_expect(player.get_node_or_null("CollisionShape3D") is CollisionShape3D, "player should have a collision shape", errors)
			_expect(player.get_node_or_null("CameraPivot/Camera3D") is Camera3D, "player should have a third-person camera", errors)
			_expect(player.get_node_or_null("Avatar") != null, "player should have a visible toy avatar", errors)
		main.free()

	for action: String in REQUIRED_ACTIONS:
		_expect(InputMap.has_action(action), "input action should be defined: %s" % action, errors)
	return errors

func _expect(condition: bool, message: String, errors: Array[String]) -> void:
	if not condition:
		errors.append(message)
