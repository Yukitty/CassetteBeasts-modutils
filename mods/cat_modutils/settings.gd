extends Reference

# Constants
const ModsTab: PackedScene = preload("settings/ModsTab.tscn")
const CFG_PATH: String = "user://mod_settings.cfg"

# State
var mods_tab_disabled: bool = true
var _mod_settings: Array


func _init(modutils: Reference) -> void:
	modutils.connect("post_init", self, "_on_post_init")
	modutils.callbacks.connect_scene_ready("res://menus/settings/SettingsMenu.tscn", self, "_on_SettingsMenu_ready")


func _on_SettingsMenu_ready(scene: Control) -> void:
	# Only add mods panel if a mod is using it.
	var modutils: ContentInfo = DLC.mods_by_id["cat_modutils"]
	if modutils.settings.mods_tab_disabled:
		return

	var tab: Control = ModsTab.instance()
	scene.content_container.add_child(tab)
	tab.visible = false
	scene.tabs.insert(3, {
		"name": "UI_SETTINGS_MODS",
		"node": tab,
	})


func _on_post_init() -> void:
	# Index all mods looking for a `MODUTILS.settings` Array of Dictionary.
	for mod in DLC.mods:
		if "MODUTILS" in mod and mod.MODUTILS.has("settings") and mod.MODUTILS.settings is Array and mod.MODUTILS.settings.size() > 0 and mod.MODUTILS.settings[0] is Dictionary:
			_mod_settings.push_back(mod)
	_mod_settings.sort_custom(self, "_sort_mods")
	mods_tab_disabled = _mod_settings.size() == 0

	# Restore saved cfg values for loaded mods.
	var cfg := ConfigFile.new()
	cfg.load(CFG_PATH)
	for mod in _mod_settings:
		for widget in mod.MODUTILS.settings:
			mod.set(widget.property, cfg.get_value(
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
