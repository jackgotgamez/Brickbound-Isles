class_name Pickup
extends Area3D

@export var item_id := "timber"
@export var amount := 1

var collected := false

func _ready() -> void:
	add_to_group("pickups")
	body_entered.connect(_on_body_entered)

func _on_body_entered(body: Node3D) -> void:
	collect_for(body)

func collect_for(body: Node) -> void:
	if collected or not body.is_in_group("player"):
		return
	collected = true
	GameState.collect_item(item_id, amount)
	queue_free()
