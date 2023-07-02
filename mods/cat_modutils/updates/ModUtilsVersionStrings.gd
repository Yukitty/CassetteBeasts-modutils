extends VBoxContainer


var LineLabel: Label
var ReadyLabel: Label
var BusyLabel: Label
var UpdateButton: Button
var ErrorButton: Button


func _ready() -> void:
	# Make ourselves deferred
	yield(Co.pass(), "completed")

	# Grab our Nodes and hold them.
	LineLabel = get_child(0)
	ReadyLabel = get_child(1)
	BusyLabel = get_child(2)
	UpdateButton = get_child(3)
	ErrorButton = get_child(4)
	remove_child(ReadyLabel)
	remove_child(BusyLabel)
	remove_child(UpdateButton)
	remove_child(ErrorButton)

	# Shrink the icons in memory instead of duplicating them in the mod data
#	UpdateButton.icon = _shrink_texture(UpdateButton.icon)
	ErrorButton.icon = _shrink_texture(ErrorButton.icon)

	_update_version_table()
	UserSettings.connect("locale_changed", self, "_update_version_table")
	DLC.mods_by_id.cat_modutils.updates.connect("updates_downloaded", self, "_update_version_table")


func _notification(what: int) -> void:
	match what:
		NOTIFICATION_PREDELETE:
			ReadyLabel.free()
			BusyLabel.free()
			UpdateButton.free()
			ErrorButton.free()


func _update_version_table() -> void:
	# Clear previous contents (if any)
	for node in get_children():
		if node != LineLabel:
			node.queue_free()

	# Start building initial version string
	var main_label: String = load("res://version.tres").get_full_string()

	# Collect DLC names
	var dlc_names: Array = []
	if Platform.has_dlc("cosplay") and not DLC.has_dlc("cosplay"):
		dlc_names.push_back("DLC_00_COSPLAY_NAME")
	for dlc in DLC.dlcs:
		dlc_names.push_back(dlc.name)

	# Add DLC display strings to main label (no version checking, obviously)
	for content_name in dlc_names:
		main_label = main_label + '\n' + Loc.trf("TITLE_SCREEN_CONTENT_LIST_DLC", {
			"content_name": content_name,
		})

	# This will be the main label
	LineLabel.text = main_label

	# Collect mod display strings
	var string: String
	for mod in DLC.mods:
		string = Loc.trf("TITLE_SCREEN_CONTENT_LIST_MOD" if mod.author.empty() else "TITLE_SCREEN_CONTENT_LIST_MOD_WITH_AUTHOR",
		{
			"content_name": mod.name,
			"content_version": mod.version_string,
			"content_author": mod.author,
		})
		add_child(_instance_mod_node(mod, string))

func _instance_mod_node(mod: ContentInfo, text: String) -> Node:
	var node: Node

	if not mod.has_meta("modutils_update"):
		node = LineLabel.duplicate()
		node.text = text
		node.name = mod.id
		return node

	match mod.get_meta("modutils_update"):
		OK:
			node = ReadyLabel.duplicate()
			node.text = text
		FAILED:
			node = ErrorButton.duplicate()
			node.text = text.trim_prefix("+ ")
			node.connect("pressed", self, "_on_Error_pressed", [mod])
		ERR_BUSY:
			node = BusyLabel.duplicate()
			node.text = text
		_:
			node = UpdateButton.duplicate()
			node.text = text.trim_prefix("+ ")
			node.connect("pressed", self, "_on_Update_pressed", [mod])

	node.name = mod.id
	return node


func _on_Update_pressed(mod: ContentInfo) -> void:
	var subs: Dictionary = {
		"content_name": mod.name,
		"content_address": mod.get_meta("modutils_update", "") as String,
	}

	GlobalMessageDialog.clear_state()
	if subs.content_address.empty():
		yield(GlobalMessageDialog.show_message(Loc.trf("MODUTILS_TITLE_MOD_UPDATE", subs)), "completed")
		return

	yield(GlobalMessageDialog.show_message(Loc.trf("MODUTILS_TITLE_MOD_UPDATE_WITH_URL1", subs), false), "completed")
	if not yield(MenuHelper.confirm(Loc.trf("MODUTILS_TITLE_MOD_UPDATE_WITH_URL2", subs)), "completed"):
		return

	OS.shell_open(subs.content_address)


func _on_Error_pressed(mod: ContentInfo) -> void:
	var subs: Dictionary = {
		"content_name": mod.name,
	}
	GlobalMessageDialog.clear_state()
	yield(GlobalMessageDialog.show_message(Loc.trf("MODUTILS_TITLE_MOD_ERROR1", subs), false), "completed")
	yield(GlobalMessageDialog.show_message(Loc.trf("MODUTILS_TITLE_MOD_ERROR2", subs)), "completed")


func _shrink_texture(texture: Texture, flags: int = ImageTexture.FLAG_FILTER) -> Texture:
	var image: Image = texture.get_data()
	assert(image != texture.get_data()) # Make sure we don't need to duplicate
	image.shrink_x2()
	var new_texture := ImageTexture.new()
	new_texture.create_from_image(image, flags)
	return new_texture
