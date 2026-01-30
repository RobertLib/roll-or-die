extends RigidBody3D

# Movement parameters
@export var move_force: float = 20.0 # Movement force
@export var max_speed: float = 10.0 # Maximum speed

var _spawn_position: Vector3


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	_spawn_position = global_position
	contact_monitor = true
	max_contacts_reported = 1
	body_entered.connect(_on_body_entered)


func _on_body_entered(body: Node) -> void:
	if body.name == "Ground":
		global_position = _spawn_position
		linear_velocity = Vector3.ZERO
		angular_velocity = Vector3.ZERO


# Called every physics frame
func _physics_process(_delta: float) -> void:
	# Get keyboard input (arrow keys)
	var input_dir = Input.get_vector("ui_left", "ui_right", "ui_up", "ui_down")

	# Create movement direction vector (X and Z axis for horizontal movement)
	var direction = Vector3(input_dir.x, 0, input_dir.y)

	# Apply force if there is any input
	if direction.length() > 0:
		# Limit speed
		var current_speed = linear_velocity.length()
		if current_speed < max_speed:
			apply_central_force(direction.normalized() * move_force)

	# Optional: damping for realistic stopping
	# linear_damp should be set in the inspector (e.g. 1.0)
