extends NPC

export var wired_door: NodePath

var behavior: Cutscene
var destination_menu: MenuDialogAction


func _ready() -> void:
	# Preserved scene shenanigans, ugh
	SceneManager.current_scene.connect("transitioned_into", self, "_refresh_nodes")


func _refresh_nodes() -> void:
	behavior = $InteractionBehavior
	destination_menu = behavior.find_node("DestinationMenu", true, false)
	assert(destination_menu != null)

	if not wired_door.is_empty():
		var door: WireBase = get_node(wired_door)
		assert(door != null)
		door.state = false
		behavior.blackboard["travel_door"] = door


func _on_Interaction_interacted(_player) -> void:
	# Clear previous destinations menu
	for action in destination_menu.get_children():
		action.queue_free()
	destination_menu.menu_options = []
	behavior.blackboard.erase("no_destinations")

	# Build current destinations menu
	var lib: Reference = DLC.mods_by_id.cat_modutils.world
	for dest in lib._modclub_destinations:
		var has_flag = dest.flags.empty()
		for flag in dest.flags:
			if SaveState.has_flag(flag):
				has_flag = true
				break

		if not Debug.dev_mode and not has_flag:
			continue
		if SceneManager.current_scene.filename == dest.warp_target_scene:
			continue

		destination_menu.menu_options.push_back(dest.name)
		var set_dest = SetBlackboardValues.new()
		set_dest.bb_values = dest
		destination_menu.add_child(set_dest)

	# Mark the behavior if there's no valid destinations and abort
	if destination_menu.menu_options.empty():
		behavior.blackboard["no_destinations"] = true
		return

	# Add Cancel option and make it the default
	destination_menu.default_option = destination_menu.menu_options.size()
	destination_menu.menu_options.push_back("UI_BUTTON_CANCEL")


func _on_WarpAction_warping(_scene, _chunk, _target) -> void:
	var lib: Reference = DLC.mods_by_id.cat_modutils.world
	lib.modclub_return_button_active = true
