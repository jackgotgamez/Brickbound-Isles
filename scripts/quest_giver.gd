class_name QuestGiver
extends Node3D

var _prompt: Label3D

func _ready() -> void:
	add_to_group("interactables")
	_build_minifig()
	_prompt = Label3D.new()
	_prompt.name = "QuestPrompt"
	_prompt.text = "E  Talk to Mira"
	_prompt.position = Vector3(0.0, 3.45, 0.0)
	_prompt.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	_prompt.font_size = 40
	_prompt.pixel_size = 0.008
	_prompt.modulate = Color(1.0, 0.93, 0.52, 1.0)
	_prompt.visible = false
	add_child(_prompt)

func interact() -> void:
	if GameState.quest_stage == "not_started":
		GameState.start_timber_quest()
	elif GameState.quest_stage == "active":
		if not GameState.try_complete_timber_quest():
			var timber_count: int = GameState.inventory.get("timber", 0)
			GameState.notification_requested.emit("Mira needs %d more timber." % maxi(0, GameState.TIMBER_QUEST_REQUIREMENT - timber_count))
	else:
		GameState.notification_requested.emit("Thanks for rebuilding the forest trail!")

func set_prompt_visible(visible: bool) -> void:
	if _prompt != null:
		_prompt.visible = visible

func _build_minifig() -> void:
	var legs_material := _material(Color(0.16, 0.36, 0.58, 1.0))
	var torso_material := _material(Color(0.19, 0.59, 0.44, 1.0))
	var skin_material := _material(Color(0.98, 0.73, 0.31, 1.0))
	var hair_material := _material(Color(0.28, 0.18, 0.12, 1.0))
	_add_box("Legs", Vector3(0.0, 0.42, 0.0), Vector3(0.72, 0.78, 0.42), legs_material)
	_add_box("Torso", Vector3(0.0, 1.28, 0.0), Vector3(0.9, 0.92, 0.48), torso_material)
	_add_cylinder("Head", Vector3(0.0, 2.05, 0.0), 0.43, 0.7, skin_material)
	_add_box("Hair", Vector3(0.0, 2.37, 0.0), Vector3(0.74, 0.24, 0.72), hair_material)
	_add_box("ArmLeft", Vector3(-0.57, 1.27, 0.0), Vector3(0.24, 0.74, 0.28), torso_material, Vector3(0.0, 0.0, deg_to_rad(-10.0)))
	_add_box("ArmRight", Vector3(0.57, 1.27, 0.0), Vector3(0.24, 0.74, 0.28), torso_material, Vector3(0.0, 0.0, deg_to_rad(10.0)))
	_add_box("EyeLeft", Vector3(-0.15, 2.1, -0.39), Vector3(0.065, 0.08, 0.035), _material(Color(0.13, 0.18, 0.2, 1.0)))
	_add_box("EyeRight", Vector3(0.15, 2.1, -0.39), Vector3(0.065, 0.08, 0.035), _material(Color(0.13, 0.18, 0.2, 1.0)))

func _add_box(node_name: String, position: Vector3, size: Vector3, material: Material, rotation: Vector3 = Vector3.ZERO) -> void:
	var mesh_instance := MeshInstance3D.new()
	mesh_instance.name = node_name
	mesh_instance.position = position
	mesh_instance.rotation = rotation
	var mesh := BoxMesh.new()
	mesh.size = size
	mesh.material = material
	mesh_instance.mesh = mesh
	add_child(mesh_instance)

func _add_cylinder(node_name: String, position: Vector3, radius: float, height: float, material: Material) -> void:
	var mesh_instance := MeshInstance3D.new()
	mesh_instance.name = node_name
	mesh_instance.position = position
	var mesh := CylinderMesh.new()
	mesh.top_radius = radius
	mesh.bottom_radius = radius
	mesh.height = height
	mesh.radial_segments = 16
	mesh.material = material
	mesh_instance.mesh = mesh
	add_child(mesh_instance)

func _material(color: Color) -> StandardMaterial3D:
	var material := StandardMaterial3D.new()
	material.albedo_color = color
	material.roughness = 0.55
	return material
