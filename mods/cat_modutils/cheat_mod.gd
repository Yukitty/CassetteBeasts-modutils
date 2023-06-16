extends Reference


var _file_button: PackedScene


func _init() -> void:
	# Finish init later
	assert(not SceneManager.preloader.singleton_setup_complete)
	yield(SceneManager.preloader, "singleton_setup_completed")

	# Index all mods looking for a `MODUTILS.cheat_mod` flag
	var enabled: bool = false
	for mod in DLC.mods:
		if "MODUTILS" in mod and mod.MODUTILS.has("cheat_mod") and mod.MODUTILS.cheat_mod:
			enabled = true

	# No cheat mods? We're done.
	if not enabled:
		return

	# Enable the warning and all that.
	_file_button = load("res://mods/cat_modutils/cheat_mod/FileButton.gd")
	_file_button.take_over_path("res://menus/title/FileButton.gd")
	SaveSystem.connect("file_loaded", self, "_on_SaveSystem_file_loaded")


func _on_SaveSystem_file_loaded() -> void:
	SaveState.has_cheated = true
