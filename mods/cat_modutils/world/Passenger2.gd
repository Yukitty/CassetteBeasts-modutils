extends Node

func _ready() -> void:
	call_deferred("update_sprite")

func update_sprite() -> void:
	var sprite: Spatial = owner.get_node("Sprite/HumanSprite")
	sprite.set_part_names(SaveState.party.player.human_part_names.duplicate())
	for color_key in sprite.colors.keys():
		sprite.colors[color_key] = 12
	sprite.colors.eye_color = 0
	sprite.set_colors(sprite.colors)
	sprite.refresh()

func _on_PlayerDetector_detected(_detection) -> void:
	yield (Co.next_frame(), "completed")
	owner.kill()

#func _on_VisibilityNotifier_screen_entered() -> void:
#	Co.safe_wait(owner, 2.0)
#	owner.kill()
