extends Spatial

onready var standing: Node = $Standing
onready var bench: Node = $Bench
onready var shops: Node = $Shops

func _ready() -> void:
	SceneManager.current_scene.connect("transitioned_into", self, "_populate")

func _populate() -> void:
	if not is_inside_tree():
		return

	for node in get_tree().get_nodes_in_group("dynamic_content"):
		node.queue_free()

	# Get the population
	var lib: Reference = DLC.mods_by_id.cat_modutils.world
	var population: Array = lib._modclub_population.duplicate()

	population.append_array(lib._BACKGROUND_PASSENGERS)
	population.shuffle()

	# Get all the spawn locations
	var standing_spots: Array = standing.get_children()
	var bench_spots: Array = bench.get_children()
	var shop_spots: Array = shops.get_children()

	# Shuffle the spawn locations
	standing_spots.shuffle()
	bench_spots.shuffle()
	shop_spots.shuffle()

	# Halve the available spawn locations for idle NPCs, to reduce overcrowding
	standing_spots.resize(standing_spots.size() >> 1)
	bench_spots.resize(bench_spots.size() >> 1)

	# Load vanilla market stalls in case they're needed
	# TODO: Move this and let other mods add custom stalls to the list?
	var MARKET_STALL: Array = [
		load("res://world/objects/static_physics/market_stall/market_stall_1.tscn"),
		load("res://world/objects/static_physics/market_stall/market_stall_2.tscn"),
		load("res://world/objects/static_physics/market_stall/market_stall_3.tscn"),
	]

	# Now read out the NPCs and spawn them in appropriate spots.
	var node: Spatial
	var stall: Spatial
	var mode: int
	var ANY_IDLE: Array = [
		lib.NPCMode.STANDING,
		lib.NPCMode.BENCH,
	]
	for def in population:
		# Some NPCs aren't guaranteed.
		if "chance" in def and def.chance < 1.0 and def.chance < randf():
			continue

		mode = def.mode

		# Randomize mode if needed
		if mode == lib.NPCMode.ANY_IDLE:
			mode = ANY_IDLE[randi() % ANY_IDLE.size()]

		match mode:
			lib.NPCMode.STANDING:
				if standing_spots.empty():
					break
				node = _spawn_npc(def.scene)
				WarpTarget.warp(standing_spots[0], [node])
				standing_spots.pop_front()

			lib.NPCMode.BENCH:
				if bench_spots.empty():
					break
				node = _spawn_npc(def.scene, "Sitting")
				WarpTarget.warp(bench_spots[0], [node])
				bench_spots.pop_front()

			lib.NPCMode.SHOP:
				if shop_spots.empty():
					break
				node = _spawn_npc(def.scene)
				stall = _spawn_npc(MARKET_STALL[randi() % MARKET_STALL.size()])
				WarpTarget.warp(shop_spots[0], [node, stall])
				shop_spots.pop_front()

			lib.NPCMode.SHOP_FULL:
				if shop_spots.empty():
					break
				node = _spawn_npc(def.scene)
				WarpTarget.warp(shop_spots[0], [node])
				shop_spots.pop_front()

# Helper for creating temporary NPC nodes
func _spawn_npc(scene: PackedScene, default_state_override: String = "") -> Spatial:
	var node: Spatial = scene.instance()
	node.add_to_group("dynamic_content")
	if not default_state_override.empty() and "default_state_override" in node:
		node.default_state_override = default_state_override
	owner.add_child(node)
	return node
