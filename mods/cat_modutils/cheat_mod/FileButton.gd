extends "res://menus/title/FileButton.gd"

var has_cheated: bool

func set_state(state: int, data) -> void:
	# Call parent function first
	.set_state(state, data)

	# Fetch cheat state
	if state == State.LOADED and data:
		has_cheated = data.get("has_cheated", false) == true

func load_file() -> void:
	# Display "cheats enabled" warning if this save file was clean
	if not has_cheated:
		release_focus()
		GlobalMessageDialog.clear_state()
		yield (GlobalMessageDialog.show_message("CONFIRM_LOAD_SAVE_WITH_CHEAT_MODS1", false), "completed")
		if not yield (MenuHelper.confirm("CONFIRM_LOAD_SAVE_WITH_NEW_MODS2", 1, 1), "completed"):
			grab_focus()
			return

	# Continue as normal
	.load_file()
