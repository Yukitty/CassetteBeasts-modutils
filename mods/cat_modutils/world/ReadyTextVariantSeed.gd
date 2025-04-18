extends Node


export var behavior: NodePath


func _ready() -> void:
	if behavior and has_node(behavior):
		var behavior_base := get_node(behavior) as ActionBase
		behavior_base.set_bb("text_variant_seed", randi())
