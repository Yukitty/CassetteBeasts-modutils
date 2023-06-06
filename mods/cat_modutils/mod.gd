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
var world: Reference

func init_content() -> void:
	# Add translation strings
	for translation in MOD_STRINGS:
		TranslationServer.add_translation(translation)

	# Load submodules
	callbacks = preload("callbacks.gd").new()
	trans_patch = preload("trans_patch.gd").new(self)
	settings = preload("settings.gd").new(self)
	class_patch = preload("class_patch.gd").new()
	cheat_mod = preload("cheat_mod.gd").new(self)
	world = preload("world.gd").new(self)

	# Call post_init deferred, to work around init_content oversight in v1.1.2
	call_deferred("_on_post_init")

func _on_post_init() -> void:
	emit_signal("post_init")

	# DEPRECIATED
	for mod in DLC.mods:
		if mod.has_method("modutils_post_init"):
			mod.modutils_post_init(self)
