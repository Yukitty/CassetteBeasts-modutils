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
	# and make the layout appear more random
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
	var scene: PackedScene
	var node: Spatial
	var stall: Spatial
	var mode: int
	var ANY_IDLE: Array = [
		lib.NPCMode.STANDING,
		lib.NPCMode.BENCH,
	]
	for def in population:
		# Some NPCs require a flag
		if "flags" in def and def.flags is Array:
			var has_flag: bool = def.flags.empty()
			for flag in def.flags:
				if SaveState.has_flag(flag):
					has_flag = true
					break
			if not Debug.dev_mode and not has_flag:
				continue

		# Some NPCs aren't guaranteed.
		if "chance" in def and def.chance < 1.0 and def.chance < randf():
			continue

		scene = load(def.scene)
		assert(scene is PackedScene)
		mode = lib.NPCMode.ANY_IDLE

		# Process mode string into enum
		if "mode" in def:
			var mode_str: String = def.mode.to_upper().replace(" ", "_")
			assert(mode_str in lib.NPCMode)
			mode = lib.NPCMode[mode_str]

		# Randomize mode if needed
		if mode == lib.NPCMode.ANY_IDLE:
			mode = ANY_IDLE[randi() % ANY_IDLE.size()]

		match mode:
			lib.NPCMode.STANDING:
				if standing_spots.empty():
					continue
				node = _spawn_npc(scene)
				if not node:
					continue
				WarpTarget.warp(standing_spots[0], [node])
				standing_spots.pop_front()

			lib.NPCMode.BENCH:
				if bench_spots.empty():
					continue
				node = _spawn_npc(scene, "Sitting")
				if not node:
					continue
				WarpTarget.warp(bench_spots[0], [node])
				bench_spots.pop_front()

			lib.NPCMode.SHOP:
				if shop_spots.empty():
					continue
				node = _spawn_npc(scene)
				if not node:
					continue
				stall = _spawn_npc(MARKET_STALL[randi() % MARKET_STALL.size()])
				WarpTarget.warp(shop_spots[0], [node, stall])
				shop_spots.pop_front()

			lib.NPCMode.SHOP_FULL:
				if shop_spots.empty():
					continue
				node = _spawn_npc(scene)
				if not node:
					continue
				WarpTarget.warp(shop_spots[0], [node])
				shop_spots.pop_front()

# Helper for creating temporary NPC nodes
func _spawn_npc(scene: PackedScene, default_state_override: String = "") -> Spatial:
	var node: Spatial = scene.instance()

	# Test and hack all ConditionalLayers
	# This is dirty, but necessary to prevent memory leaks.
	if node is BaseConditionalLayer:
		var root := Spatial.new()
		root.add_child(node)
		_process_out_conditionals(root)
		match root.get_child_count():
			0: # Conditionals failed, no NPC
				root.free()
				return null
			1: # Conditionals succeeded, new root found
				node = root.get_child(0)
				root.remove_child(node)
				root.free()
			_: # Multiple nodes were buried in the conditional,
				# so we leave the Spatial as the new root
				node = root

	node.add_to_group("dynamic_content")
	if not default_state_override.empty() and "default_state_override" in node:
		node.default_state_override = default_state_override
	owner.add_child(node)

	return node

func _process_out_conditionals(node: Spatial) -> void:
	for child in node.get_children():
		if child is BaseConditionalLayer:
			if child._check_conditions() == false:
				child.free()
#				child.propagate_call("_on_freeing_scene")
#				node.remove_child(child)
#				child.queue_free()
				continue
			_process_out_conditionals(child)
			child.remove_and_skip()
			child.free()
		elif child is Spatial:
			_process_out_conditionals(child)
