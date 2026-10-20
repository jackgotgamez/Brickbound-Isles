extends Node3D

@export var save_path := "user://brickbound_save.json"
@onready var player: PlayerController = $Player

func _ready() -> void:
	GameState.load_progress(save_path)
	if GameState.player_position != Vector3.ZERO:
		player.global_position = GameState.player_position
	GameState.progress_changed.connect(_on_progress_changed)

func _notification(what: int) -> void:
	if what == NOTIFICATION_WM_CLOSE_REQUEST:
		var current_player := get_node_or_null("Player") as CharacterBody3D
		if current_player != null and current_player.is_inside_tree():
			GameState.update_player_position(current_player.global_position)
		GameState.save_progress(save_path)

func _on_progress_changed() -> void:
	GameState.save_progress(save_path)
