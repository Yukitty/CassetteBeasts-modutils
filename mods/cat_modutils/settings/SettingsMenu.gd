extends "res://menus/settings/SettingsMenu.gd"

const ModsTab: PackedScene = preload("ModsTab.tscn")

func _ready() -> void:
	# Only add mods panel if a mod is using it.
	var modutils: ContentInfo = DLC.mods_by_id["cat_modutils"]
	if modutils.settings.mods_tab_disabled:
		return

	var tab: Control = ModsTab.instance()
	content_container.add_child(tab)
	tab.visible = false
	tabs.insert(3, {
		"name": "UI_SETTINGS_MODS",
		"node": tab,
	})
