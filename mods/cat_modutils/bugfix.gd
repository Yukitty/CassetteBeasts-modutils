extends Reference

func _init(modutils: ContentInfo) -> void:
	preload("bugfix/WarpRegion.gd").take_over_path("res://nodes/warp_region/WarpRegion.gd")
	modutils.callbacks.connect_scene_ready("res://sprites/monsters/world/magikrab.json", self, "_on_MagikrabSprite_ready")


func _on_MagikrabSprite_ready(sprite: Spatial) -> void:
	var player: AnimationPlayer = sprite.get_node("AnimationPlayer")
	player.remove_animation("idle_up")
	player.add_animation("idle_up", preload("bugfix/magikrab_idle_up.tres"))
