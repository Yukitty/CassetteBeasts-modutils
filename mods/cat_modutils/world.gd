extends Reference

# Functions and variables prefixed with _ are meant to be private.
# Please do not call / modify them externally.

# This enum may be subject to change in future versions.
# Please reference it by names instead of number.
enum NPCMode {
	ANY_IDLE, # Standing, sitting, or walking
	STANDING, # Standing around
	BENCH, # Sitting on a bench
	WALKING, # Not implemented yet, DO NOT USE.
	SHOP, # Running a randomly selected market stall
	SHOP_FULL, # Running a custom market stall included in the NPC scene
}

const _OVERWORLD_METADATA: MapMetadata = preload("res://data/map_metadata/overworld.tres")
const _MODCLUB_BLACKLIST: PoolStringArray = PoolStringArray([
	"res://mods/cat_modutils/world/Station.tscn",
	"res://world/maps/interiors/GramophoneInterior.tscn",
	"res://world/maps/Overworld.tscn",
])


## Public state

# Check if Mod Club Station should be open
var modclub_populated: bool setget ,is_modclub_populated

# Toggle this to enable/disable a
# "Return to Mod Club Station" button
# in the pause/map menu
var modclub_return_button_active: bool = false setget _set_modclub_return_button_active

# Private state
var _chunk_init: bool = false
var _modclub_population: Array
var _modclub_destinations: Array
var _magikrab_extra_behaviors: PackedScene
var _magikrab_dest_modclub: PackedScene


func _init(modutils: ContentInfo) -> void:
	# Default NPC population (flavor text)
	# The flags prevent these NPCs from unlocking Mod Club Station by themselves.
	_modclub_population = [
		{
			"scene": "res://mods/cat_modutils/world/Passenger1.tscn",
			"mode": "any idle",
			"chance": 1/3.0,
			"flags": ["modutils_modclub_unlocked"],
		},
		{
			"scene": "res://mods/cat_modutils/world/Passenger2.tscn",
			"mode": "standing",
			"chance": 1/10.0,
			"flags": ["modutils_modclub_unlocked"],
		},
	]

	# Add Mod Club Station itself to Mod Club Redkrab's destination menu,
	# just in case another mod spawns it for some reason.
	# The flags prevent this destination from unlocking Mod Club Station by itself.
	_modclub_destinations = [
		{
			"name": "REGION_NAME_MODUTILS",
			"warp_target_scene": "res://mods/cat_modutils/world/Station.tscn",
			"warp_target_name": "PlatformD",
			"flags": ["modutils_modclub_unlocked"],
		}
	]

	# Finish init later
	assert(not SceneManager.preloader.singleton_setup_complete)
	yield(SceneManager.preloader, "singleton_setup_completed")

	# Add extra behaviors to Magikrab
	modutils.callbacks.connect_scene_ready("res://world/recurring_npcs/Magikrab.tscn", self, "_on_Magikrab_ready")

	# Don't preserve Mod Club Station
	# I highly recommend your mod do the same, for dungeons.
	SceneManager.PRESERVABLE_SCENE_BLACKLIST.push_back("res://mods/cat_modutils/")

	# Add "Mod Club Station" to overworld fast travel map if discovered
	SaveSystem.connect("file_loaded", self, "_init_modclub_chunk_feature")

	# Add "Return to Mod Club Station" button to menu
	_init_modclub_return_button()
	SceneManager.connect("scene_changed", self, "_on_scene_changed")

	# Read data from all mods providing a MODUTILS table
	for mod in DLC.mods:
		if "MODUTILS" in mod and mod.MODUTILS is Dictionary and "world" in mod.MODUTILS:
			assert(mod.MODUTILS.world is Dictionary)
			_init_data(mod.MODUTILS.world)

	# Verify the results are as expected
	for def in _modclub_population:
		assert("scene" in def and def.scene is String)
		assert(not "mode" in def or def.mode is String)
		assert(not "flags" in def or def.flags is Array)
		assert(not "chance" in def or (def.chance is float and def.chance > 0.0))

	for def in _modclub_destinations:
		assert("name" in def and def.name is String)
		assert("warp_target_scene" in def and def.warp_target_scene is String)
		assert(not "flags" in def or def.flags is Array)


func _init_data(world_defs: Dictionary) -> void:
	if "modclub_population" in world_defs:
		assert(world_defs.modclub_population is Array)
		_modclub_population.append_array(world_defs.modclub_population)
	if "modclub_destinations" in world_defs:
		assert(world_defs.modclub_destinations is Array)
		_modclub_destinations.append_array(world_defs.modclub_destinations)


# Edit Magikrab for Mod Club Station
func _on_Magikrab_ready(scene: Spatial) -> void:
	assert(scene != null)
	assert("behavior" in scene and scene.behavior is Cutscene)

	# Don't even touch Magikrab unless Mod Club Station should open
	if not is_modclub_populated() and not SaveState.has_flag("modutils_modclub_unlocked"):
		return

	# Only edit Magikrab once!
	# We need to do this because Magikrab sets request_ready every time.
	if scene.has_meta("modutils_modclub"):
		return
	scene.set_meta("modutils_modclub", true)

	# Load behavior scenes from file if needed
	if not _magikrab_extra_behaviors or not _magikrab_dest_modclub:
		_magikrab_extra_behaviors = load("res://mods/cat_modutils/world/behaviors/Magikrab.tscn")
		_magikrab_dest_modclub = load("res://mods/cat_modutils/world/behaviors/MagikrabDest_ModClub.tscn")

	# Set blackboard values
	scene.behavior.blackboard["modutils_world"] = self

	# Unpack extra behaviors from scene
	var extra_behaviors: Node = _magikrab_extra_behaviors.instance()
	var news_modsavailable: Action = extra_behaviors.get_child(0)
	var mainmenu_platformd: Action = extra_behaviors.get_child(1)
	extra_behaviors.remove_child(news_modsavailable)
	extra_behaviors.remove_child(mainmenu_platformd)
	extra_behaviors.free()

	# Add Mod Club Station opening news
	var news: Selector = scene.behavior.get_node("Selector/Sequence/Selector")
	news.add_child(news_modsavailable)
	news.move_child(news_modsavailable, news.get_child_count() - 2)

	# Add Platform D to bottom of main menu
	var mainmenu: MenuDialogAction = scene.behavior.get_node("Selector/Sequence/Repeater/MessageDialogAction/MenuDialogAction")
	mainmenu.menu_options = mainmenu.menu_options.duplicate()
	mainmenu.menu_options.insert(mainmenu.menu_options.size() - 1, "MAGIKRAB_MENU_OPTION_MODUTILS_PLATFORMD")
	mainmenu.default_option = mainmenu.menu_options.size() - 1
	mainmenu.add_child(mainmenu_platformd)
	mainmenu.move_child(mainmenu_platformd, mainmenu.default_option - 1)

	# Connect interacted signal because the destination menu is silly
	# and completely refreshes every single time you interact,
	# instead of just using a static tree of CheckConditionAction
	# like everywhere else in the game.
	scene.get_node("NPC/Interaction").connect("interacted", self, "_on_Magikrab_interacted", [scene], CONNECT_DEFERRED)


func _on_Magikrab_interacted(_player: NPC, scene: Spatial) -> void:
	# Add Mod Club Station to second in destinations menu
	# The first option is always Gramophone Cafe, so this is a guaranteed spot.
	var destmenu_modclub: Action = _magikrab_dest_modclub.instance()
	scene.destination_menu.menu_options.insert(1, "MAGIKRAB_TRAVEL_OPTION_MODUTILS")
	scene.destination_menu.default_option = scene.destination_menu.menu_options.size() - 1
	scene.destination_menu.add_child(destmenu_modclub)
	scene.destination_menu.move_child(destmenu_modclub, 1)


# Tests if Mod Club Station should be accessible.
func is_modclub_populated() -> bool:
	if Debug.dev_mode:
		return true
	for def in _modclub_population:
		if not "flags" in def:
			return true
		for flag in def.flags:
			if SaveState.has_flag(flag):
				return true
	for def in _modclub_destinations:
		if not "flags" in def:
			return true
		for flag in def.flags:
			if SaveState.has_flag(flag):
				return true
	return false

# Adds fast travel waypoint to an overworld chunk for Mod Club Station
func _init_modclub_chunk_feature(force: bool = false) -> void:
	if _chunk_init:
		return
	# Only if Mod Club Station has been unlocked already!
	# (Prevents seeing hidden feature that can't be unlocked.)
	if not force and not SaveState.has_flag("modutils_modclub_unlocked"):
		return
	var chunk_metadata: Datatable = Datatables.load(_OVERWORLD_METADATA.chunk_metadata_path)
	var chunk: MapChunkMetadata = chunk_metadata.table["overworld_3_0"]
	chunk.features.push_back(preload("world/feature_modclub.tres"))
	_chunk_init = true


func _init_modclub_return_button() -> void:
	var lib: ContentInfo = DLC.mods_by_id.cat_modutils
	lib.callbacks.connect_scene_ready("res://menus/map_pause/MapPauseMenu.tscn", self, "_on_MapPauseMenu_ready")


func _on_scene_changed() -> void:
	if SceneManager.current_scene.filename in _MODCLUB_BLACKLIST:
		modclub_return_button_active = false


# DEPRECIATED: Prefer static data tables as documented on the Mod Utils wiki instead.
# Call this with your NPC scene to add it to Mod Club Station
# mode should be one of NPCMode
func add_modclub_npc(scene: PackedScene, mode: int = NPCMode.ANY_IDLE, flags: Array = [], chance: float = 1.0) -> void:
	assert(scene != null)
#	assert(NPCMode.values().has(mode)) # Use a valid enum!
	assert(chance > 0.0) # Integer division safeguard, lol
	_modclub_population.push_back({
		"scene": scene.resource_path,
		"mode": mode,
		"flags": flags,
		"chance": chance,
	})


# DEPRECIATED: Prefer static data tables as documented on the Mod Utils wiki instead.
# Call this with your world scene to add it to Mod Club Station's
# list of "adventure" destinations
func add_modclub_destination(name: String, warp_target_scene: String, warp_target_name: String = "Start", warp_target_chunk: Vector2 = Vector2.ZERO, flags: Array = []) -> void:
	assert(name != null and not name.empty())
	assert(warp_target_scene != null and not warp_target_scene.empty())
	_modclub_destinations.push_back({
		"name": name,
		"warp_target_scene": warp_target_scene,
		"warp_target_chunk": warp_target_chunk,
		"warp_target_name": warp_target_name,
		"flags": flags,
	})


# Call this to recursively add the nodes from `merge` into `root`,
# travelling down branches of nodes with matching names so only
# "new" nodes are added as children.
func merge_tree(root: Node, merge: Node) -> void:
	assert(root.name == merge.name)
	for child in merge.get_children():
		if root.has_node(child.name):
			merge_tree(root.get_node(child.name), child)
			continue
		merge.remove_child(child)
		root.add_child(child)


func _on_MapPauseMenu_ready(scene: Control) -> void:
	if not modclub_return_button_active:
		return
#	var btn := Button.new()
#	btn.text = "UI_PAUSE_MODUTILS_RETURN_BTN"
#	btn.rect_min_size.y = 72
#	btn.add_font_override("font", load("res://ui/fonts/regular/regular_36.tres"))
#	btn.add_stylebox_override("hover", load("res://menus/map_pause/pause_menu_button_hover_styleboxflat.tres"))
#	btn.add_stylebox_override("pressed", load("res://menus/map_pause/pause_menu_button_hover_styleboxflat.tres"))
#	btn.add_stylebox_override("focus", load("res://menus/map_pause/pause_menu_button_hover_styleboxflat.tres"))
#	btn.add_stylebox_override("disabled", load("res://menus/map_pause/pause_menu_button_styleboxflat.tres"))
#	btn.add_stylebox_override("normal", load("res://menus/map_pause/pause_menu_button_styleboxflat.tres"))
	var btn: Button = load("res://mods/cat_modutils/world/ui/ReturnToModClubButton.tscn").instance()
	btn.connect("pressed", self, "_on_ReturnToModClub_pressed", [scene])
	scene.buttons.add_child_below_node(scene.bestiary_button, btn)
	scene.buttons.setup_focus()


func _on_ReturnToModClub_pressed(menu: Control) -> void:
	menu.cancel()
	modclub_return_button_active = false
	SceneManager.transition = SceneManager.TransitionKind.TRANSITION_FADE
	SceneManager.loading_audio.stream = load("res://mods/cat_modutils/world/ui/stage_coach.ogg")
	SceneManager.loading_graphic = load("res://mods/cat_modutils/world/ui/stage_coach.png")
	WorldSystem.warp(
		"res://mods/cat_modutils/world/Station.tscn",
		Vector2(0, 0),
		"PlatformD")


func _set_modclub_return_button_active(value: bool) -> void:
	modclub_return_button_active = is_modclub_populated() and value
