extends ContentInfo

# Signals
signal post_init

# Constants
const MOD_STRINGS: Array = [
	preload("mod_strings.en.translation"),
]

# Submodules
var callbacks: Reference
var trans_patch: Reference
var settings: Reference
var class_patch: Reference
var cheat_mod: Reference

func _init() -> void:
	# Add translation strings
	for translation in MOD_STRINGS:
		TranslationServer.add_translation(translation)

	# Load submodules
	callbacks = preload("callbacks.gd").new()
	trans_patch = preload("trans_patch.gd").new(self)
	settings = preload("settings.gd").new(self)
	class_patch = preload("class_patch.gd").new()
	cheat_mod = preload("cheat_mod.gd").new(self)

	# Run post_init next frame, to work around init_content oversight in v1.1.2
	DLC.get_tree().connect("idle_frame", self, "_on_post_init", [], CONNECT_ONESHOT)

func _on_post_init() -> void:
	emit_signal("post_init")
	for mod in DLC.mods:
		if mod.has_method("modutils_post_init"):
			mod.modutils_post_init(self)
