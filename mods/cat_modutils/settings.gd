extends Reference

# Constants
const RESOURCES: Dictionary = {
	"res://menus/settings/SettingsMenu.gd":
		preload("settings/SettingsMenu.gd"),
}

# State
var mods_tab_disabled: bool = true
var _mod_settings: Array
var _cfg: ConfigFile

func _init(modutils: Reference) -> void:
	var res: Resource
	for k in RESOURCES:
		res = RESOURCES[k]
		res.take_over_path(k)

	_cfg = ConfigFile.new()
	_cfg.load("user://mod_settings.cfg")

	modutils.connect("post_init", self, "_on_post_init")

func _on_post_init() -> void:
	# Index all mods looking for a `MODUTILS.settings` Array of Dictionary.
	for mod in DLC.mods:
		if "MODUTILS" in mod and mod.MODUTILS.has("settings") and mod.MODUTILS.settings is Array and mod.MODUTILS.settings.size() > 0 and mod.MODUTILS.settings[0] is Dictionary:
			_mod_settings.push_back(mod)
	_mod_settings.sort_custom(self, "_sort_mods")
	mods_tab_disabled = _mod_settings.size() == 0

	# Restore saved cfg values for loaded mods.
	for mod in _mod_settings:
		for widget in mod.MODUTILS.settings:
			mod.set(widget.property, _cfg.get_value(
				mod.id, widget.property, mod.get(widget.property)
			))

func _sort_mods(a: ContentInfo, b: ContentInfo) -> bool:
	# Sort mods by localized name
	var a_name: String = Strings.strip_bbcode(tr(a.name))
	var b_name: String = Strings.strip_bbcode(tr(b.name))
	var name_cmp: int = a_name.naturalnocasecmp_to(b_name)
	if name_cmp < 0:
		return true
	if name_cmp > 0:
		return false

	# Okaaay, that's weird, two mods with the same name...
	# Sort by Mod IDs, then?
	a_name = Strings.strip_bbcode(tr(a.id))
	b_name = Strings.strip_bbcode(tr(b.id))
	name_cmp = a_name.naturalnocasecmp_to(b_name)
	if name_cmp < 0:
		return true
	if name_cmp > 0:
		return false

	# ???
	return false
