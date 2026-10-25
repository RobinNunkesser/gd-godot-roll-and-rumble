class_name Trophy3D
extends Node3D

## Prozeduraler 3D-Siegerpokal für Roll & Rumble 3D (Tournament Champion Ceremony)
## Verfügt über PBR-Goldmaterialien, sanftes Schweben/Drehen, Lichtschein und 3D-Billboard-Label.

var _anim_timer: float = 0.0
var _mesh_pivot: Node3D
var _billboard_label: Label3D
var _light: OmniLight3D

func _ready() -> void:
	_build_trophy()

func _build_trophy() -> void:
	_mesh_pivot = Node3D.new()
	_mesh_pivot.name = "TrophyPivot"
	add_child(_mesh_pivot)
	
	# PBR Gold-Material
	var gold_mat = StandardMaterial3D.new()
	gold_mat.albedo_color = Color(1.0, 0.82, 0.15)
	gold_mat.metallic = 0.98
	gold_mat.roughness = 0.14
	gold_mat.emission_enabled = true
	gold_mat.emission = Color(1.0, 0.75, 0.1)
	gold_mat.emission_energy_multiplier = 0.85
	
	var marble_base_mat = StandardMaterial3D.new()
	marble_base_mat.albedo_color = Color(0.12, 0.12, 0.15)
	marble_base_mat.roughness = 0.25
	marble_base_mat.metallic = 0.4
	
	# 1. Sockel (Marmor-Basis)
	var base_mesh = BoxMesh.new()
	base_mesh.size = Vector3(0.9, 0.35, 0.9)
	var base_inst = MeshInstance3D.new()
	base_inst.mesh = base_mesh
	base_inst.material_override = marble_base_mat
	base_inst.position = Vector3(0, 0.175, 0)
	_mesh_pivot.add_child(base_inst)
	
	# 2. Sockel-Plakette (Gold)
	var plaque_mesh = CylinderMesh.new()
	plaque_mesh.top_radius = 0.38
	plaque_mesh.bottom_radius = 0.44
	plaque_mesh.height = 0.15
	var plaque_inst = MeshInstance3D.new()
	plaque_inst.mesh = plaque_mesh
	plaque_inst.material_override = gold_mat
	plaque_inst.position = Vector3(0, 0.42, 0)
	_mesh_pivot.add_child(plaque_inst)
	
	# 3. Säule / Stiel
	var stem_mesh = CylinderMesh.new()
	stem_mesh.top_radius = 0.16
	stem_mesh.bottom_radius = 0.22
	stem_mesh.height = 0.55
	var stem_inst = MeshInstance3D.new()
	stem_inst.mesh = stem_mesh
	stem_inst.material_override = gold_mat
	stem_inst.position = Vector3(0, 0.75, 0)
	_mesh_pivot.add_child(stem_inst)
	
	# 4. Pokal-Kelch (Großer goldener Kegel/Zylinder)
	var cup_mesh = CylinderMesh.new()
	cup_mesh.top_radius = 0.65
	cup_mesh.bottom_radius = 0.25
	cup_mesh.height = 0.85
	var cup_inst = MeshInstance3D.new()
	cup_inst.mesh = cup_mesh
	cup_inst.material_override = gold_mat
	cup_inst.position = Vector3(0, 1.45, 0)
	_mesh_pivot.add_child(cup_inst)
	
	# 5. Henkel Links & Rechts
	var handle_l = BoxMesh.new()
	handle_l.size = Vector3(0.12, 0.5, 0.12)
	var handle_l_inst = MeshInstance3D.new()
	handle_l_inst.mesh = handle_l
	handle_l_inst.material_override = gold_mat
	handle_l_inst.position = Vector3(-0.68, 1.45, 0)
	handle_l_inst.rotation_degrees = Vector3(0, 0, 15)
	_mesh_pivot.add_child(handle_l_inst)
	
	var handle_r_inst = MeshInstance3D.new()
	handle_r_inst.mesh = handle_l
	handle_r_inst.material_override = gold_mat
	handle_r_inst.position = Vector3(0.68, 1.45, 0)
	handle_r_inst.rotation_degrees = Vector3(0, 0, -15)
	_mesh_pivot.add_child(handle_r_inst)
	
	# 6. Goldener Lichtschein (OmniLight3D)
	_light = OmniLight3D.new()
	_light.name = "OmniLight3D"
	_light.light_color = Color(1.0, 0.85, 0.3)
	_light.light_energy = 2.5
	_light.omni_range = 8.0
	_light.position = Vector3(0, 1.6, 0)
	add_child(_light)
	
	# 7. 3D Billboard Label
	_billboard_label = Label3D.new()
	_billboard_label.name = "Label3D"
	_billboard_label.text = "🏆 CHAMPION 🏆"
	_billboard_label.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	_billboard_label.font_size = 38
	_billboard_label.pixel_size = 0.009
	_billboard_label.position = Vector3(0, 2.25, 0)
	_billboard_label.modulate = Color(1.0, 0.9, 0.3)
	add_child(_billboard_label)

func _process(delta: float) -> void:
	_anim_timer += delta * 2.0
	if _mesh_pivot:
		_mesh_pivot.rotation.y += delta * 1.8
		_mesh_pivot.position.y = sin(_anim_timer) * 0.15
	if _billboard_label:
		_billboard_label.position.y = 2.25 + sin(_anim_timer) * 0.15
