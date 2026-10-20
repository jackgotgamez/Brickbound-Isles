class_name TreeResource
extends StaticBody3D

const PICKUP_SCENE: PackedScene = preload("res://scenes/pickup.tscn")
const PICKUP_OFFSETS: Array[Vector3] = [
	Vector3(-0.8, 0.15, -0.65),
	Vector3(0.8, 0.15, -0.65),
	Vector3(-0.8, 0.15, 0.65),
	Vector3(0.8, 0.15, 0.65),
	Vector3(0.0, 0.15, 0.0),
]

var hit_count := 0
var is_broken := false

@onready var trunk: MeshInstance3D = $Trunk
@onready var crown: MeshInstance3D = $Crown
@onready var trunk_collision: CollisionShape3D = $TrunkCollision
@onready var break_prompt: Label3D = $BreakPrompt

func _ready() -> void:
	add_to_group("resources")

func hit() -> void:
	if is_broken:
		return
	hit_count += 1
	GameState.notification_requested.emit("Timber tree: %d/3 hits" % hit_count)
	if hit_count < 3:
		return
	is_broken = true
	remove_from_group("resources")
	trunk.visible = false
	crown.visible = false
	trunk_collision.set_deferred("disabled", true)
	break_prompt.visible = false
	GameState.notification_requested.emit("Tree broken. Collect the timber!")
	GameState.unlock_achievement("first_tree")
	for offset: Vector3 in PICKUP_OFFSETS:
		var pickup: Pickup = PICKUP_SCENE.instantiate()
		pickup.position = offset
		add_child(pickup)

func set_prompt_visible(visible: bool) -> void:
	if not is_broken:
		break_prompt.visible = visible
