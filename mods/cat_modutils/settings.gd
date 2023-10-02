extends Reference

# Constants
const ModsTab: PackedScene = preload("settings/ModsTab.tscn")
const CFG_PATH: String = "user://mod_settings.cfg"

# State
var mods_tab_disabled: bool = true
var _mod_settings: Array


func _init(modutils: Reference) -> void:
	modutils.callbacks.connect_scene_ready("res://menus/settings/SettingsMenu.tscn", self, "_on_SettingsMenu_ready")

	# Finish init later
	assert(not SceneManager.preloader.singleton_setup_complete)
	yield(SceneManager.preloader, "singleton_setup_completed")

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
			if widget.type == "action":
				_init_action(mod, widget, cfg.get_value(mod.id, widget.action, ""))
			else:
				mod.set(widget.property, cfg.get_value(
					mod.id, widget.property, mod.get(widget.property)
				))


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


func _sort_mods(a: ContentInfo, b: ContentInfo) -> bool:
	# Sort Mod Utils itself to the top
	if a.id == "cat_modutils":
		return true
	elif b.id == "cat_modutils":
		return false

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


func _init_action(_mod: ContentInfo, widget: Dictionary, saved_keys: String) -> void:
	assert("action" in widget)
	if not "action" in widget:
		return

	InputMap.add_action(widget.action)

	# Add gamepad input
	if "button" in widget:
		var button := InputEventJoypadButton.new()
		button.button_index = widget.button
		button.pressed = true
		InputMap.action_add_event(widget.action, button)

	# Restore cfg
	if not saved_keys.empty():
		var parse_result: JSONParseResult = JSON.parse(saved_keys)
		if not parse_result.result is Array:
			push_error("Mod Utils: Corrupt saved keybinds for mod action %s" % widget.action)
			return
		var keys: Array = parse_result.result
		for scancode in keys:
			var keybind := InputEventKey.new()
			if "physical" in widget and widget.physical is bool and widget.physical:
				keybind.physical_scancode = int(scancode)
			else:
				keybind.scancode = int(scancode)
			keybind.pressed = true
			InputMap.action_add_event(widget.action, keybind)
		return

	# Default keybind
	if "scancode" in widget:
		var keybind := InputEventKey.new()
		if "physical" in widget and widget.physical is bool and widget.physical:
			keybind.physical_scancode = widget.scancode
		else:
			keybind.scancode = widget.scancode
		keybind.pressed = true
		InputMap.action_add_event(widget.action, keybind)
