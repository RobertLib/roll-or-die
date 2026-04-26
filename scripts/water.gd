@tool
extends Area3D

## Width and depth of the water surface in world units.
## Change this instead of using Node Scale to avoid physics warnings.
@export var size: Vector2 = Vector2(4.0, 4.0):
	set(v):
		size = v
		_apply_size()

## How much buoyancy relative to gravity (1.0 = neutrally buoyant, >1 floats up).
@export var buoyancy_force: float = 1.5

## How quickly water slows down movement (higher = more drag).
@export var water_drag: float = 4.0

var _mat: ShaderMaterial
var _ripple_time: float = -1.0
var _bodies_in_water: Array[Node3D] = []

@onready var _splash: GPUParticles3D = $SplashParticles


func _ready() -> void:
	if Engine.is_editor_hint():
		_apply_size()
		return

	# Duplicate both the mesh and its material so each water instance is independent
	var mesh_node := $WaterMesh as MeshInstance3D
	var unique_mesh := mesh_node.mesh.duplicate() as PlaneMesh
	_mat = (unique_mesh.material as ShaderMaterial).duplicate()
	unique_mesh.material = _mat
	mesh_node.mesh = unique_mesh

	var col_node := $CollisionShape3D as CollisionShape3D
	col_node.shape = col_node.shape.duplicate()

	_apply_size()
	body_entered.connect(_on_body_entered)
	body_exited.connect(_on_body_exited)


func _physics_process(delta: float) -> void:
	if Engine.is_editor_hint():
		return
	var gravity_strength: float = ProjectSettings.get_setting("physics/3d/default_gravity", 9.8)
	var water_y := global_position.y
	for body in _bodies_in_water:
		if not is_instance_valid(body) or not body is RigidBody3D:
			continue
		var rb := body as RigidBody3D
		# Submerge factor: 0 when center is 0.5 above surface, 1 when 0.5 below
		var depth := water_y - rb.global_position.y
		var submerge := clampf(depth / 0.5 + 0.5, 0.0, 1.0)
		rb.apply_central_force(Vector3.UP * gravity_strength * rb.mass * submerge * buoyancy_force)
		# Water drag dampens movement for a floating feel
		rb.linear_velocity *= maxf(0.0, 1.0 - water_drag * delta)


func _process(delta: float) -> void:
	if Engine.is_editor_hint() or _mat == null:
		return
	if _ripple_time >= 0.0:
		_ripple_time += delta
		_mat.set_shader_parameter("ripple_time", _ripple_time)
		if _ripple_time > 3.0:
			_ripple_time = -1.0
			_mat.set_shader_parameter("ripple_time", -1.0)


func _apply_size() -> void:
	if not is_node_ready():
		return
	var mesh_node := get_node_or_null("WaterMesh") as MeshInstance3D
	var col_node := get_node_or_null("CollisionShape3D") as CollisionShape3D
	if mesh_node and mesh_node.mesh is PlaneMesh:
		(mesh_node.mesh as PlaneMesh).size = size
	if col_node and col_node.shape is BoxShape3D:
		# Keep detection area deep so the body doesn't exit from below
		(col_node.shape as BoxShape3D).size = Vector3(size.x, 4.0, size.y)


func _on_body_entered(body: Node3D) -> void:
	if body in _bodies_in_water:
		return
	_bodies_in_water.append(body)

	# Place splash particles at the entry point on the water surface
	var entry_pos := body.global_position
	entry_pos.y = global_position.y
	_splash.global_position = entry_pos
	_splash.restart()

	# Trigger ripple at the entry position in local XZ space
	if _mat != null:
		var local_pos := to_local(entry_pos)
		_mat.set_shader_parameter("ripple_origin", Vector2(local_pos.x, local_pos.z))
		_ripple_time = 0.0


func _on_body_exited(body: Node3D) -> void:
	_bodies_in_water.erase(body)
