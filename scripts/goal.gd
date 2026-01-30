extends Area3D

const LEVELS = [
	"res://scenes/levels/level_01.tscn",
	"res://scenes/levels/level_02.tscn",
]

func _ready() -> void:
	body_entered.connect(_on_body_entered)

func _on_body_entered(body: Node3D) -> void:
	if not body is RigidBody3D:
		return
	var current_path = get_tree().current_scene.scene_file_path
	var current_index = LEVELS.find(current_path)
	var next_index = (current_index + 1) % LEVELS.size()
	get_tree().call_deferred("change_scene_to_file", LEVELS[next_index])
