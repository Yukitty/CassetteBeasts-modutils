extends ContentInfo

# Signals
signal post_init

# Constants
const MOD_STRINGS: Array = [
	preload("mod_strings.en.translation"),
]

const MODUTILS = {
	"updates": "https://gist.githubusercontent.com/Yukitty/f113b1e2c11faad763a47ebc0a867643/raw/updates.json",
	"settings": [
		{
			"property": "setting_check_updates",
			"type": "toggle",
			"label": "UI_SETTINGS_CAT_MODUTILS_CHECK_UPDATES",
		},
		{
			"property": "setting_randomize_dog_bootleg",
			"type": "toggle",
			"label": "UI_SETTINGS_CAT_MODUTILS_RANDOMIZE_DOG_BOOTLEG",
		},
	],
}

# Settings
var setting_check_updates: bool = true
var setting_randomize_dog_bootleg: bool = false

# Submodules
var callbacks: Reference
var trans_patch: Reference
var settings: Reference
var class_patch: Reference
var cheat_mod: Reference
var world: Reference
var items: Reference
var updates: Reference

# Modified Resource references
var _save_state_party: Resource


func _init() -> void:
	# Load submodules ASAP so we're ready for other mods
	callbacks = preload("callbacks.gd").new()
	trans_patch = preload("trans_patch.gd").new()
	settings = preload("settings.gd").new(self)
	class_patch = preload("class_patch.gd").new()
	cheat_mod = preload("cheat_mod.gd").new()
	world = preload("world.gd").new(self)
	items = preload("items.gd").new()
	updates = preload("updates.gd").new(self)


func init_content() -> void:
	# Add translation strings
	for translation in MOD_STRINGS:
		TranslationServer.add_translation(translation)

	# Extend SaveState.party (bugfixes)
	_save_state_party = load("res://mods/cat_modutils/bugfix/Party.gd")
	_save_state_party.take_over_path("res://global/save_state/Party.gd")

	# Call post_init deferred, to work around init_content oversight in
	# Cassette Beasts v1.1.2 and earlier
	call_deferred("_on_post_init")


func _on_post_init() -> void:
	emit_signal("post_init")

	# DEPRECIATED: Use init_content in Cassette Beasts v1.1.3 and later
	for mod in DLC.mods:
		if mod.has_method("modutils_post_init"):
			mod.modutils_post_init(self)
