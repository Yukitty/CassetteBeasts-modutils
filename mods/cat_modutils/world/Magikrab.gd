extends "res://world/recurring_npcs/Magikrab.gd"

const MODUTILS_DEST: Dictionary = {
	name = "MAGIKRAB_TRAVEL_OPTION_MODUTILS",
	warp_target_scene = "res://mods/cat_modutils/world/Station.tscn",
	warp_target_name = "PlatformA",
}

func _on_Interaction_interacted(_player) -> void:
	._on_Interaction_interacted(_player)

	# Open Mod Club Station if populated
	var lib: Reference = DLC.mods_by_id.cat_modutils.world
	if lib.modclub_populated:
		behavior.blackboard["modutils_modclub"] = true

	# If Mod Club Station has been discovered previously, add it to destinations
	if SaveState.has_flag("modutils_modclub_unlocked"):
		_enable_modutils()

func _enable_modutils() -> void:
	# Skip if we're currently in Mod Club Station
	if SceneManager.current_scene.filename == MODUTILS_DEST.warp_target_scene:
		return

	# Add Mod Club Station destination
	destination_menu.menu_options.insert(1, MODUTILS_DEST.name)
	var set_dest = SetBlackboardValues.new()
	set_dest.bb_values = MODUTILS_DEST
	destination_menu.add_child_below_node(destination_menu.get_child(0), set_dest)
	destination_menu.default_option = destination_menu.menu_options.size() - 1

	# Add Mod Club Station to metadata
	var lib: Reference = DLC.mods_by_id.cat_modutils.world
	lib._init_modclub_chunk_feature()
