extends Spatial


onready var mug: Spatial = $Mug


func _ready() -> void:
	# Shift the mug around randomly for every table.
	if randf() < 0.5:
		mug.queue_free()
		return
	var move_angle: float = randf() * TAU
	var move: float = randf() * 1.10
	mug.translate(Vector3(cos(move_angle) * move, 0.0, sin(move_angle) * move))
	mug.rotate_y(randf() * TAU)
