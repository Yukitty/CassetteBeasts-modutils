extends NPC

export var wired_door: NodePath

var behavior: Cutscene


func _ready() -> void:
	# Preserved scene shenanigans, ugh
	SceneManager.current_scene.connect("transitioned_into", self, "_refresh_nodes")


func _refresh_nodes() -> void:
	behavior = $InteractionBehavior

	if not wired_door.is_empty():
		var door: WireBase = get_node(wired_door)
		assert(door != null)
		door.state = false
		behavior.blackboard["travel_door"] = door
