extends Camera3D

# Target to follow
@export var target: NodePath
@export var enable_follow: bool = true

# Camera offset from target
@export_group("Offset")
@export var offset: Vector3 = Vector3(0, 8, 8) # Default isometric-style offset
@export var look_at_offset: Vector3 = Vector3(0, 0, 0) # Offset for look-at point

# Follow behavior
@export_group("Follow Settings")
@export var follow_speed: float = 5.0 # How fast camera catches up (higher = snappier)
@export var rotation_speed: float = 3.0 # How fast camera rotates to target
@export var min_follow_distance: float = 0.1 # Dead zone - don't move if closer than this

# Boundaries (optional - set to 0 to disable)
@export_group("Boundaries")
@export var use_boundaries: bool = false
@export var boundary_min: Vector3 = Vector3(-50, 0, -50)
@export var boundary_max: Vector3 = Vector3(50, 20, 50)

# Smoothing
@export_group("Advanced")
@export var use_smooth_rotation: bool = true
@export var camera_lag: float = 0.1 # Additional lag for more cinematic feel (0 = no lag)

var _target_node: Node3D


func _ready() -> void:
	if target:
		_target_node = get_node(target)


func _physics_process(delta: float) -> void:
	if not enable_follow or not _target_node:
		return

	# Calculate desired position
	var target_position = _target_node.global_position + offset

	# Apply boundaries if enabled
	if use_boundaries:
		target_position.x = clamp(target_position.x, boundary_min.x, boundary_max.x)
		target_position.y = clamp(target_position.y, boundary_min.y, boundary_max.y)
		target_position.z = clamp(target_position.z, boundary_min.z, boundary_max.z)

	# Check if we need to move (dead zone)
	var distance_to_target = global_position.distance_to(target_position)

	if distance_to_target > min_follow_distance:
		# Smooth follow with optional lag
		var interpolation_speed = follow_speed * (1.0 - camera_lag)
		global_position = global_position.lerp(target_position, interpolation_speed * delta)

	# Look at target with offset
	var look_at_point = _target_node.global_position + look_at_offset

	if use_smooth_rotation:
		# Smooth rotation
		var current_transform = global_transform
		var target_transform = global_transform.looking_at(look_at_point, Vector3.UP)
		global_transform = current_transform.interpolate_with(
			target_transform, rotation_speed * delta
		)
	else:
		# Instant rotation
		look_at(look_at_point, Vector3.UP)


# Helper function to shake camera (can be called from other scripts)
func shake(intensity: float = 0.5, duration: float = 0.3) -> void:
	var tween = create_tween()
	var original_offset = offset

	for i in range(int(duration * 60)): # Approximate frames
		var shake_offset = Vector3(
			randf_range(-intensity, intensity),
			randf_range(-intensity, intensity),
			randf_range(-intensity, intensity)
		)
		tween.tween_property(self , "offset", original_offset + shake_offset, 0.016)

	tween.tween_property(self , "offset", original_offset, 0.1)


# Helper function to set new target at runtime
func set_target_node(new_target: Node3D) -> void:
	_target_node = new_target
	enable_follow = true
