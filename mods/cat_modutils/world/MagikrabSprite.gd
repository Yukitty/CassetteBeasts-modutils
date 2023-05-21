extends Spatial

# BUGFIX: Replace Magikrab's default idle_up with an appropriate sprite
func _ready() -> void:
	var player: AnimationPlayer = $AnimationPlayer
	player.remove_animation("idle_up")
	player.add_animation("idle_up", preload("magikrab_idle_up.tres"))
