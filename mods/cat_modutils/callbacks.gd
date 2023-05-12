extends Reference

# State
var _class_ready: Dictionary
var _scene_ready: Dictionary

func _init() -> void:
	DLC.get_tree().connect("node_added", self, "_on_node_added")

func _on_node_added(node: Node) -> void:
	var script: Script = node.get_script()
	var path: String = node.filename

	if _class_ready.has(script):
		for callback in _class_ready[script]:
			if not node.is_connected("ready", callback.owner, callback.function):
				node.connect("ready", callback.owner, callback.function, [node] + callback.binds, CONNECT_DEFERRED)

	if _scene_ready.has(path):
		for callback in _scene_ready[path]:
			if not node.is_connected("ready", callback.owner, callback.function):
				node.connect("ready", callback.owner, callback.function, [node] + callback.binds, CONNECT_DEFERRED)

# class callbacks can be used to mass-edit many scenes that share a common ancestor
func connect_class_ready(script: Script, callback_owner: Object, callback_function: String, callback_binds: Array = []) -> void:
	if not _class_ready.has(script):
		_class_ready[script] = []
	_class_ready[script].push_back({
		"owner": callback_owner,
		"function": callback_function,
		"binds": callback_binds,
		})

# Scene instance callbacks shouldn't be necessary,
# but it's here in case you find it useful.
func connect_scene_ready(scene: String, callback_owner: Object, callback_function: String, callback_binds: Array = []) -> void:
	if not _scene_ready.has(scene):
		_scene_ready[scene] = []
	_scene_ready[scene].push_back({
		"owner": callback_owner,
		"function": callback_function,
		"binds": callback_binds,
		})
