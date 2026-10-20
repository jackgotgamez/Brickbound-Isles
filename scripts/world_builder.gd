class_name WorldBuilder
extends Node3D

const TERRAIN_SEGMENTS := 56
const ISLAND_RADIUS := 52.0
const TREE_SCENE: PackedScene = preload("res://scenes/tree.tscn")
const QUEST_GIVER_SCENE: PackedScene = preload("res://scenes/quest_giver.tscn")

var _built := false

func _ready() -> void:
	build(self)

func build(parent: Node3D) -> void:
	if _built:
		return
	_built = true
	_add_terrain(parent)
	_add_water(parent)
	_add_village_paths(parent)
	_add_village(parent)
	_add_forest(parent)
	_add_quest_giver(parent)
	_add_landmark(parent)
	_add_rock_clusters(parent)

func _add_terrain(parent: Node3D) -> void:
	var surface := SurfaceTool.new()
	surface.begin(Mesh.PRIMITIVE_TRIANGLES)
	var step := (ISLAND_RADIUS * 2.0) / float(TERRAIN_SEGMENTS)
	for z_index: int in range(TERRAIN_SEGMENTS):
		for x_index: int in range(TERRAIN_SEGMENTS):
			var x0 := -ISLAND_RADIUS + float(x_index) * step
			var x1 := x0 + step
			var z0 := -ISLAND_RADIUS + float(z_index) * step
			var z1 := z0 + step
			var a := Vector2(x0, z0)
			var b := Vector2(x1, z0)
			var c := Vector2(x0, z1)
			var d := Vector2(x1, z1)
			_add_terrain_vertex(surface, Vector3(a.x, _height_at(a), a.y), a)
			_add_terrain_vertex(surface, Vector3(c.x, _height_at(c), c.y), c)
			_add_terrain_vertex(surface, Vector3(b.x, _height_at(b), b.y), b)
			_add_terrain_vertex(surface, Vector3(b.x, _height_at(b), b.y), b)
			_add_terrain_vertex(surface, Vector3(c.x, _height_at(c), c.y), c)
			_add_terrain_vertex(surface, Vector3(d.x, _height_at(d), d.y), d)
	surface.generate_normals()
	var terrain_mesh: ArrayMesh = surface.commit()
	terrain_mesh.surface_set_material(0, _terrain_material())

	var land := StaticBody3D.new()
	land.name = "IslandLand"
	land.collision_layer = 1
	land.collision_mask = 1
	var visual := MeshInstance3D.new()
	visual.name = "TerrainMesh"
	visual.mesh = terrain_mesh
	land.add_child(visual)
	var collider := CollisionShape3D.new()
	collider.name = "TerrainCollision"
	var heightmap := HeightMapShape3D.new()
	heightmap.map_width = TERRAIN_SEGMENTS + 1
	heightmap.map_depth = TERRAIN_SEGMENTS + 1
	var height_data := PackedFloat32Array()
	for z_index: int in range(TERRAIN_SEGMENTS + 1):
		for x_index: int in range(TERRAIN_SEGMENTS + 1):
			var x := -ISLAND_RADIUS + float(x_index) * step
			var z := -ISLAND_RADIUS + float(z_index) * step
			height_data.append(_height_at(Vector2(x, z)) / step)
	heightmap.map_data = height_data
	collider.shape = heightmap
	collider.scale = Vector3.ONE * step
	land.add_child(collider)
	parent.add_child(land)

func _add_terrain_vertex(surface: SurfaceTool, position: Vector3, point: Vector2) -> void:
	var radius_ratio := point.length() / ISLAND_RADIUS
	if radius_ratio < 0.82:
		surface.set_color(Color(0.3, 0.66, 0.29, 1))
	elif radius_ratio < 0.95:
		surface.set_color(Color(0.84, 0.75, 0.48, 1))
	else:
		surface.set_color(Color(0.41, 0.49, 0.43, 1))
	surface.add_vertex(position)

func _terrain_material() -> StandardMaterial3D:
	var material := StandardMaterial3D.new()
	material.vertex_color_use_as_albedo = true
	material.roughness = 0.96
	return material

func _height_at(point: Vector2) -> float:
	if point.length() < 14.0:
		return 0.65 + sin(point.x * 0.1) * cos(point.y * 0.1) * 0.035
	var radius_ratio := point.length() / ISLAND_RADIUS
	if radius_ratio < 0.82:
		return 0.55 + sin(point.x * 0.12) * 0.28 + cos(point.y * 0.1) * 0.22 + sin((point.x + point.y) * 0.06) * 0.18
	if radius_ratio < 0.95:
		var beach_progress := smoothstep(0.82, 0.95, radius_ratio)
		return lerpf(0.38, -0.25, beach_progress)
	var cliff_progress := smoothstep(0.95, 1.0, minf(radius_ratio, 1.0))
	return lerpf(-0.25, -3.2, cliff_progress)

func _add_water(parent: Node3D) -> void:
	var water := MeshInstance3D.new()
	water.name = "ShallowSea"
	var mesh := BoxMesh.new()
	mesh.size = Vector3(150.0, 0.14, 150.0)
	water.mesh = mesh
	water.position = Vector3(0, -0.31, 0)
	var material := StandardMaterial3D.new()
	material.albedo_color = Color(0.11, 0.55, 0.76, 1)
	material.roughness = 0.28
	material.metallic = 0.05
	mesh.material = material
	parent.add_child(water)

func _add_village_paths(parent: Node3D) -> void:
	var path_material := _material(Color(0.78, 0.68, 0.48, 1))
	_add_box(parent, "VillageSquare", Vector3(0, 0.74, 0), Vector3(16, 0.11, 12), path_material)
	_add_box(parent, "NorthPath", Vector3(0, 0.7, -11), Vector3(2.5, 0.1, 12), path_material)
	_add_box(parent, "ForestPath", Vector3(-4, 0.7, -18), Vector3(11, 0.1, 2.4), path_material)
	_add_box(parent, "EastPath", Vector3(12, 0.7, -3), Vector3(11, 0.1, 2.4), path_material)
	_add_box(parent, "SouthPath", Vector3(0, 0.7, 10), Vector3(2.3, 0.1, 10), path_material)

func _add_village(parent: Node3D) -> void:
	_add_house(parent, "CoralHouse", Vector3(-7.2, 0.65, 3.2), Color(0.96, 0.55, 0.34, 1))
	_add_house(parent, "SkyHouse", Vector3(7.3, 0.65, 3.0), Color(0.93, 0.78, 0.34, 1))
	_add_house(parent, "MintHouse", Vector3(-6.7, 0.65, -5.0), Color(0.46, 0.73, 0.61, 1))
	_add_house(parent, "LilacHouse", Vector3(7.0, 0.65, -5.2), Color(0.67, 0.59, 0.82, 1))
	var sign_material := _material(Color(0.17, 0.37, 0.51, 1))
	_add_box(parent, "WelcomeSignPost", Vector3(0, 1.72, -5.7), Vector3(0.25, 2.1, 0.25), _material(Color(0.39, 0.25, 0.12, 1)))
	_add_box(parent, "WelcomeSign", Vector3(0, 2.65, -5.7), Vector3(2.4, 0.75, 0.18), sign_material)

func _add_house(parent: Node3D, house_name: String, position: Vector3, wall_color: Color) -> void:
	var house := Node3D.new()
	house.name = house_name
	house.position = position
	parent.add_child(house)
	_add_box(house, "Walls", Vector3(0, 1.25, 0), Vector3(4.3, 2.5, 3.6), _material(wall_color))
	var roof_material := _material(Color(0.48, 0.22, 0.15, 1))
	_add_box(house, "RoofLeft", Vector3(-1.05, 2.75, 0), Vector3(2.5, 0.25, 4.0), roof_material, Vector3(0, 0, deg_to_rad(-34)))
	_add_box(house, "RoofRight", Vector3(1.05, 2.75, 0), Vector3(2.5, 0.25, 4.0), roof_material, Vector3(0, 0, deg_to_rad(34)))
	_add_box(house, "Door", Vector3(0, 0.72, -1.84), Vector3(0.85, 1.45, 0.08), _material(Color(0.32, 0.19, 0.11, 1)))
	var glass := _material(Color(0.47, 0.77, 0.88, 1), 0.18)
	_add_box(house, "WindowLeft", Vector3(-1.35, 1.65, -1.86), Vector3(0.72, 0.64, 0.1), glass)
	_add_box(house, "WindowRight", Vector3(1.35, 1.65, -1.86), Vector3(0.72, 0.64, 0.1), glass)

func _add_forest(parent: Node3D) -> void:
	for index: int in range(29):
		var angle := TAU * float(index) / 29.0
		var radius := 24.0 + float(index % 5) * 2.3
		var point := Vector2(cos(angle) * radius, sin(angle) * radius)
		var tree: TreeResource = TREE_SCENE.instantiate()
		tree.name = "PineTree_%02d" % index
		tree.position = Vector3(point.x, _height_at(point), point.y)
		tree.rotation.y = angle * 0.4
		var tree_scale := 0.82 + float(index % 4) * 0.08
		tree.scale = Vector3.ONE * tree_scale
		parent.add_child(tree)

func _add_quest_giver(parent: Node3D) -> void:
	var giver: QuestGiver = QUEST_GIVER_SCENE.instantiate()
	giver.name = "Mira"
	var point := Vector2(2.1, 1.6)
	giver.position = Vector3(point.x, _height_at(point), point.y)
	giver.rotation.y = deg_to_rad(145.0)
	parent.add_child(giver)

func _add_landmark(parent: Node3D) -> void:
	var tower := Node3D.new()
	tower.name = "BeaconTower"
	tower.position = Vector3(18.0, _height_at(Vector2(18.0, -12.0)), -12.0)
	parent.add_child(tower)
	var base_mesh := CylinderMesh.new()
	base_mesh.top_radius = 0.9
	base_mesh.bottom_radius = 1.1
	base_mesh.height = 5.2
	base_mesh.radial_segments = 12
	base_mesh.material = _material(Color(0.65, 0.68, 0.61, 1))
	var base := MeshInstance3D.new()
	base.name = "StoneBeacon"
	base.position.y = 2.6
	base.mesh = base_mesh
	tower.add_child(base)
	var beacon_mesh := SphereMesh.new()
	beacon_mesh.radius = 0.95
	beacon_mesh.height = 1.9
	beacon_mesh.radial_segments = 12
	beacon_mesh.rings = 6
	var beacon_material := _material(Color(1.0, 0.76, 0.25, 1), 0.2)
	beacon_material.emission_enabled = true
	beacon_material.emission = Color(1.0, 0.54, 0.12, 1)
	beacon_material.emission_energy_multiplier = 1.4
	beacon_mesh.material = beacon_material
	var beacon := MeshInstance3D.new()
	beacon.name = "Lantern"
	beacon.position.y = 5.35
	beacon.mesh = beacon_mesh
	tower.add_child(beacon)

func _add_rock_clusters(parent: Node3D) -> void:
	for index: int in range(18):
		var angle := TAU * (float(index) + 0.5) / 18.0
		var radius := 33.0 + float(index % 3) * 1.7
		var point := Vector2(cos(angle) * radius, sin(angle) * radius)
		var rock := MeshInstance3D.new()
		rock.name = "TideRock_%02d" % index
		var mesh := SphereMesh.new()
		mesh.radius = 0.8 + float(index % 4) * 0.16
		mesh.height = mesh.radius * 1.15
		mesh.radial_segments = 7
		mesh.rings = 4
		mesh.material = _material(Color(0.4, 0.49, 0.5, 1))
		rock.mesh = mesh
		rock.position = Vector3(point.x, _height_at(point) + 0.32, point.y)
		rock.rotation = Vector3(float(index % 5) * 0.1, angle, float(index % 4) * 0.06)
		parent.add_child(rock)

func _add_box(parent: Node3D, box_name: String, position: Vector3, size: Vector3, material: Material, rotation: Vector3 = Vector3.ZERO) -> MeshInstance3D:
	var box := MeshInstance3D.new()
	box.name = box_name
	box.position = position
	box.rotation = rotation
	var mesh := BoxMesh.new()
	mesh.size = size
	mesh.material = material
	box.mesh = mesh
	parent.add_child(box)
	return box

func _material(color: Color, roughness: float = 0.84) -> StandardMaterial3D:
	var material := StandardMaterial3D.new()
	material.albedo_color = color
	material.roughness = roughness
	return material
