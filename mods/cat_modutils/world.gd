extends Reference

# Functions and variables prefixed with _ are meant to be private.
# Please do not call / modify them externally.

# This enum may be subject to change in future versions.
# Please reference it by name instead of number.
enum NPCMode {
	ANY_IDLE, # Standing, sitting, or walking
	STANDING, # Standing around
	BENCH, # Sitting on a bench
	WALKING, # Not implemented yet, DO NOT USE.
	SHOP, # Running a randomly selected market stall
	SHOP_FULL, # Running a custom market stall included in the NPC scene
};

const _OVERWORLD_METADATA: MapMetadata = preload("res://data/map_metadata/overworld.tres")

# Public state
var modclub_populated: bool setget ,is_modclub_populated

# Private state
var _chunk_init: bool = false
var _modclub_population: Array

func _init() -> void:
	# Possess Magikrab
	preload("world/Magikrab.tscn").take_over_path("res://world/recurring_npcs/Magikrab.tscn")

	# Add feature to overworld chunk metadata
	_init_modclub_chunk_feature()

# Adds fast travel waypoint to an overworld chunk for Mod Club Station
func _init_modclub_chunk_feature() -> void:
	# Only if Mod Club Station has been unlocked already!
	# (Prevents seeing hidden feature that can't be unlocked.)
	if _chunk_init or not SaveState.has_flag("modutils_modclub_unlocked"):
		return
	var chunk_metadata: Datatable = Datatables.load(_OVERWORLD_METADATA.chunk_metadata_path)
	var chunk: MapChunkMetadata = chunk_metadata.table["overworld_3_0"]
	chunk.features.push_back(preload("world/feature_modclub.tres"))
	_chunk_init = true

# Call this with your NPC scene to add it to Mod Club Station
# mode should be one of NPCMode
func add_modclub_npc(scene: PackedScene, mode: int = NPCMode.ANY_IDLE) -> void:
	assert(scene != null)
	_modclub_population.push_back({
		"scene": scene,
		"mode": mode,
	})

# Should return true if ANY Mod Club Station features
# have been utilized by other mods.
func is_modclub_populated() -> bool:
	if _modclub_population.size() > 0:
		return true
	return false
