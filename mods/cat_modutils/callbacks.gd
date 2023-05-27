extends Reference

# State
var _class_ready: Dictionary
var _scene_ready: Dictionary
var _chunk_ready: Dictionary
var _level_streamer: LevelStreamer

func _init() -> void:
	DLC.get_tree().connect("node_added", self, "_on_node_added")
	connect_class_ready("res://addons/level_streamer/LevelStreamer.gd", self, "_on_LevelStreamer_ready")

func _on_LevelStreamer_ready(level_streamer: Node) -> void:
	_level_streamer = level_streamer

func _on_node_added(node: Node) -> void:
	var scene_path: String = node.filename
	var script_path: String

	if node.get_script():
		script_path = node.get_script().resource_path

	# Only connect callbacks once
	if node.get_meta("modutils_ready", false):
		return
	node.set_meta("modutils_ready", true)

	# Catch streaming chunks, if possible
	if is_instance_valid(_level_streamer) and script_path == "res://addons/level_streamer/Chunk.gd":
		scene_path = SceneManager.current_scene.filename
		var index: Vector2 = _level_streamer.chunk_for_pos_3d(node.transform.origin)
		if scene_path in _chunk_ready and index in _chunk_ready[scene_path]:
			for callback in _chunk_ready[scene_path][index]:
				node.connect("setup_completed", callback.owner, callback.function, [node] + callback.binds, CONNECT_DEFERRED)

	# Catch script nodes being instanced
	if not script_path.empty() and _class_ready.has(script_path):
		for callback in _class_ready[script_path]:
			node.connect("ready", callback.owner, callback.function, [node] + callback.binds, CONNECT_DEFERRED)

	# Catch specific scenes being instanced
	if _scene_ready.has(scene_path):
		for callback in _scene_ready[scene_path]:
			node.connect("ready", callback.owner, callback.function, [node] + callback.binds, CONNECT_DEFERRED)

# Class callbacks can be used to mass-edit many scenes that share a common ancestor
func connect_class_ready(script, callback_owner: Object, callback_function: String, callback_binds: Array = []) -> void:
	if script is Resource:
		script = script.resource_path
	assert(script is String)
	if not script in _class_ready:
		_class_ready[script] = []
	_class_ready[script].push_back({
		"owner": callback_owner,
		"function": callback_function,
		"binds": callback_binds,
		})

# Scene instance callbacks can be used to inject content into an existing scene
# when it spawns, even for sub-scenes that aren't typically the root.
func connect_scene_ready(scene: String, callback_owner: Object, callback_function: String, callback_binds: Array = []) -> void:
	if not scene in _scene_ready:
		_scene_ready[scene] = []
	_scene_ready[scene].push_back({
		"owner": callback_owner,
		"function": callback_function,
		"binds": callback_binds,
		})

# This is for chunked maps like the Overworld.
func connect_chunk_setup(scene: String, chunk_index: Vector2, callback_owner: Object, callback_function: String, callback_binds: Array = []) -> void:
	chunk_index = Vector2(floor(chunk_index.x), floor(chunk_index.y))
	if not scene in _chunk_ready:
		_chunk_ready[scene] = {}
	if not chunk_index in _chunk_ready[scene]:
		_chunk_ready[scene][chunk_index] = []
	_chunk_ready[scene][chunk_index].push_back({
		"owner": callback_owner,
		"function": callback_function,
		"binds": callback_binds,
		})
