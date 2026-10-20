class_name PlayerController
extends CharacterBody3D

const WALK_SPEED := 6.0
const GROUND_ACCELERATION := 24.0
const AIR_ACCELERATION := 9.0
const JUMP_SPEED := 6.4
const TURN_SPEED := 12.0
const MOUSE_SENSITIVITY := 0.0025
const INTERACTION_DISTANCE := 3.6

@onready var camera_pivot: Node3D = $CameraPivot

var camera_pitch := deg_to_rad(-13.0)
var _position_update_time := 0.0
var _prompt_target: Node3D

func _ready() -> void:
	add_to_group("player")
	camera_pivot.rotation.x = camera_pitch
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED

func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventMouseMotion:
		camera_pivot.rotation.y -= event.relative.x * MOUSE_SENSITIVITY
		camera_pitch = clampf(camera_pitch - event.relative.y * MOUSE_SENSITIVITY, deg_to_rad(-38.0), deg_to_rad(18.0))
		camera_pivot.rotation.x = camera_pitch
	elif event is InputEventKey and event.pressed and event.keycode == KEY_ESCAPE:
		Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	elif event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT and Input.mouse_mode != Input.MOUSE_MODE_CAPTURED:
		Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
	elif event.is_action_pressed("interact"):
		_try_interact()
	elif event.is_action_pressed("hit_resource"):
		_try_hit_resource()

func _physics_process(delta: float) -> void:
	var gravity := float(ProjectSettings.get_setting("physics/3d/default_gravity"))
	if not is_on_floor():
		velocity.y -= gravity * delta
	elif velocity.y < 0.0:
		velocity.y = 0.0

	if Input.is_action_just_pressed("jump") and is_on_floor():
		jump()

	var move_input := Input.get_vector("move_left", "move_right", "move_forward", "move_back")
	var direction := camera_pivot.global_basis * Vector3(move_input.x, 0.0, move_input.y)
	direction.y = 0.0
	direction = direction.normalized()
	var acceleration := GROUND_ACCELERATION if is_on_floor() else AIR_ACCELERATION
	velocity.x = move_toward(velocity.x, direction.x * WALK_SPEED, acceleration * delta)
	velocity.z = move_toward(velocity.z, direction.z * WALK_SPEED, acceleration * delta)
	if direction.length_squared() > 0.01:
		_face_direction(direction, delta)
	move_and_slide()
	_update_interaction_prompt()

	_position_update_time += delta
	if _position_update_time >= 0.5:
		GameState.update_player_position(global_position)
		_position_update_time = 0.0

func _face_direction(direction: Vector3, delta: float) -> void:
	var world_camera_yaw := camera_pivot.global_rotation.y
	var target_yaw := atan2(-direction.x, -direction.z)
	rotation.y = lerp_angle(rotation.y, target_yaw, minf(TURN_SPEED * delta, 1.0))
	camera_pivot.rotation.y = wrapf(world_camera_yaw - rotation.y, -PI, PI)

func jump() -> void:
	if is_on_floor():
		velocity.y = JUMP_SPEED

func _try_interact() -> void:
	var target := _nearest_node_in_group("interactables")
	if target != null and target.has_method("interact"):
		target.call("interact")

func _try_hit_resource() -> void:
	var target := _nearest_node_in_group("resources")
	if target != null and target.has_method("hit"):
		target.call("hit")

func _nearest_node_in_group(group_name: String) -> Node3D:
	var nearest: Node3D
	var nearest_distance := INTERACTION_DISTANCE
	for candidate: Node in get_tree().get_nodes_in_group(group_name):
		if not candidate is Node3D:
			continue
		var target := candidate as Node3D
		var distance := global_position.distance_to(target.global_position)
		if distance <= nearest_distance:
			nearest = target
			nearest_distance = distance
	return nearest

func _update_interaction_prompt() -> void:
	var resource := _nearest_node_in_group("resources")
	var interactable := _nearest_node_in_group("interactables")
	var nearest := resource
	if nearest == null or (interactable != null and global_position.distance_to(interactable.global_position) < global_position.distance_to(nearest.global_position)):
		nearest = interactable
	if nearest == _prompt_target:
		return
	if _prompt_target != null and is_instance_valid(_prompt_target) and _prompt_target.has_method("set_prompt_visible"):
		_prompt_target.call("set_prompt_visible", false)
	_prompt_target = nearest
	if _prompt_target != null and _prompt_target.has_method("set_prompt_visible"):
		_prompt_target.call("set_prompt_visible", true)
