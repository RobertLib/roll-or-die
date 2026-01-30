extends Node3D


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	$Cap/Area3D.body_entered.connect(_on_body_entered)


func _on_body_entered(body: Node3D) -> void:
	$AnimationPlayer.play("CapAction")

	if body.name == "Player":
		var player := body as Player
		var direction := (player.global_position - global_position).normalized()
		direction.y = 0.0
		player.apply_central_impulse(direction * 20.0)
