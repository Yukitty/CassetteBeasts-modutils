extends Control

const ArrowOptionList: PackedScene = preload("res://nodes/menus/ArrowOptionList.tscn")
const ArrowSlider: PackedScene = preload("res://nodes/menus/ArrowSlider.tscn")
const ArrowSlider_Percent: PackedScene = preload("res://nodes/menus/ArrowSlider_Percent.tscn")
const ArrowSlider_CustomFormat: GDScript = preload("ArrowSlider_CustomFormat.gd")
const KBControlButtonScene: PackedScene = preload("res://menus/settings/KBControlButton.tscn")
const KBControlButton: GDScript = preload("res://menus/settings/KBControlButton.gd")
const KBControlRebindPopup: PackedScene = preload("res://menus/settings/KBControlRebindPopup.tscn")

onready var inputs: GridContainer = find_node("Inputs")

var submod: Reference
var _widgets: Array
var _actions: Array


func _ready() -> void:
	submod = DLC.mods_by_id.cat_modutils.settings

	for mod in submod._mod_settings:
		assert("MODUTILS" in mod and "settings" in mod.MODUTILS)
		_add_heading(mod.name)
		for widget in mod.MODUTILS.settings:
			var label: String = widget.label if "label" in widget else ""
			match widget.type:
				"toggle":
					add_toggle(mod, widget.property, label)
				"slider":
					var min_value: float = widget.min_value if "min_value" in widget else 0.0
					var max_value: float = widget.max_value if "max_value" in widget else 1.0
					var step: float = widget.step if "step" in widget else 0.01
					var format: String = widget.format if "format" in widget else ""
					add_slider(mod, widget.property, label, min_value, max_value, step, format)
				"percent_slider":
					var step: float = widget.step if "step" in widget else 0.05
					add_percent_slider(mod, widget.property, label, step)
				"options":
					add_options(mod, widget.property, label, widget.values, widget.value_labels)
				"action":
					add_action(mod, widget.action, label)
				"label", _:
					add_label(label)

	reset()


func is_dirty() -> bool:
	for widget in _widgets:
		var mod: ContentInfo = widget.get_meta("owner")
		var property: String = widget.get_meta("property")
		if mod.get(property) != widget.selected_value:
			return true

	for input in _actions:
		var keys: Array = input.keys.duplicate()
		for event in InputMap.get_action_list(input.action):
			if not event is InputEventKey:
				continue
			if event.physical_scancode and event.physical_scancode in keys:
				keys.erase(event.physical_scancode)
			elif event.scancode and event.scancode in keys:
				keys.erase(event.scancode)
			else: # InputEventKey not found in keys (key deleted?)
				return true
		if not keys.empty(): # keys not found in InputMap (key added?)
			return true

	return false


func apply() -> void:
	var cfg := ConfigFile.new()
	cfg.load(submod.CFG_PATH)

	for widget in _widgets:
		var mod: ContentInfo = widget.get_meta("owner")
		var property: String = widget.get_meta("property")
		mod.set(property, widget.selected_value)
		cfg.set_value(mod.id, property, widget.selected_value)

	for input in _actions:
		var mod: ContentInfo = input.get_meta("owner")
		# Update InputMap
		var use_physical: bool = false
		for event in InputMap.get_action_list(input.action):
			if not event is InputEventKey:
				continue
			elif event.physical_scancode:
				use_physical = true
			InputMap.action_erase_event(input.action, event)
		for key in input.keys:
			var event := InputEventKey.new()
			if use_physical:
				event.physical_scancode = key
			else:
				event.scancode = key
			event.pressed = true
			InputMap.action_add_event(input.action, event)
		# Save keys to cfg
		cfg.set_value(mod.id, input.action, JSON.print(input.keys))

	cfg.save(submod.CFG_PATH)


func reset() -> void:
	for widget in _widgets:
		var mod: ContentInfo = widget.get_meta("owner")
		var property: String = widget.get_meta("property")
		widget.selected_value = mod.get(property)

	for input in _actions:
		var keys: Array = []
		for event in InputMap.get_action_list(input.action):
			if not event is InputEventKey:
				continue
			if event.physical_scancode:
				keys.push_back(event.physical_scancode)
			elif event.scancode:
				keys.push_back(event.scancode)
		# Must assign the final Array value directly for KBControlButton.set_keys to be called.
		input.keys = keys

	inputs.setup_focus()


func grab_focus() -> void:
	inputs.grab_focus()


func _add_heading(text: String) -> void:
	var margin := MarginContainer.new()
	margin.add_constant_override("margin_top", 20)
	inputs.add_child(margin)

	var label := Label.new()
	label.text = text
	label.add_color_override("font_color", Color.black)
	label.add_font_override("font", preload("res://ui/fonts/regular/regular_50.tres"))
	margin.add_child(label)

	var spacer := Control.new()
	inputs.add_child(spacer)


func add_label(text: String) -> void:
	var label := Label.new()
	label.text = text
	label.add_color_override("font_color", Color.black)
	label.size_flags_horizontal |= Control.SIZE_EXPAND_FILL
	inputs.add_child(label)

	var spacer := Control.new()
	inputs.add_child(spacer)


func add_toggle(mod: ContentInfo, property: String, text: String) -> Control:
	return add_options(mod, property, text, [true, false], ["UI_SETTINGS_VALUE_ON", "UI_SETTINGS_VALUE_OFF"])


func add_slider(mod: ContentInfo, property: String, text: String, min_value: float = 0, max_value: float = 1, step: float = 0.05, format_string: String = "") -> Control:
	var label := Label.new()
	label.text = "UI_SETTINGS_" + mod.id + "_" + property if text.empty() else text
	label.add_color_override("font_color", Color.black)
	label.size_flags_horizontal |= Control.SIZE_EXPAND_FILL
	inputs.add_child(label)

	var slider: Control = ArrowSlider.instance()
	if format_string != "":
		slider.set_script(ArrowSlider_CustomFormat)
		slider.format_string = format_string
	slider.min_value = min_value
	slider.max_value = max_value
	slider.step = step
	slider.rect_min_size.x = 450
	slider.size_flags_horizontal |= Control.SIZE_EXPAND_FILL
	inputs.add_child(slider)

	slider.set_meta("owner", mod)
	slider.set_meta("property", property)
	_widgets.push_back(slider)
	return slider


func add_percent_slider(mod: ContentInfo, property: String, text: String, step: float = 0.05) -> Control:
	var label := Label.new()
	label.text = "UI_SETTINGS_" + mod.id + "_" + property if text.empty() else text
	label.add_color_override("font_color", Color.black)
	label.size_flags_horizontal |= Control.SIZE_EXPAND_FILL
	inputs.add_child(label)
	
	var slider: Control = ArrowSlider_Percent.instance()
	slider.step = step
	slider.rect_min_size.x = 450
	slider.size_flags_horizontal |= Control.SIZE_EXPAND_FILL
	inputs.add_child(slider)

	slider.set_meta("owner", mod)
	slider.set_meta("property", property)
	_widgets.push_back(slider)
	return slider


func add_options(mod: ContentInfo, property: String, text: String, values: Array, value_labels: Array) -> Control:
	var label := Label.new()
	label.text = "UI_SETTINGS_" + mod.id + "_" + property if text.empty() else text
	label.add_color_override("font_color", Color.black)
	label.size_flags_horizontal |= Control.SIZE_EXPAND_FILL
	inputs.add_child(label)

	var option: Control = ArrowOptionList.instance()
	option.values = values
	option.value_labels = value_labels
	option.size_flags_horizontal |= Control.SIZE_EXPAND_FILL
	inputs.add_child(option)

	option.set_meta("owner", mod)
	option.set_meta("property", property)
	_widgets.push_back(option)
	return option


func add_action(mod: ContentInfo, action: String, text: String = "") -> Control:
	var label = Label.new()
	label.text = "UI_SETTINGS_MODUTILS_BIND_" + action if text.empty() else text
	label.add_color_override("font_color", Color.black)
	label.size_flags_horizontal |= Control.SIZE_EXPAND_FILL
	inputs.add_child(label)

	var input: Control = KBControlButtonScene.instance()
	input.action = action
	input.size_flags_horizontal |= Control.SIZE_EXPAND_FILL
	inputs.add_child(input)

	input.set_meta("owner", mod)
	input.connect("pressed", self, "rebind_keyboard_action")
	_actions.push_back(input)
	return input


func rebind_keyboard_action() -> void:
	var focus_owner = get_focus_owner()
	if not focus_owner is KBControlButton:
		return
	var action = focus_owner.action

	var rebind_popup = KBControlRebindPopup.instance()
	MenuHelper.add_child(rebind_popup)

	var choice = yield(rebind_popup.run_popup(action), "completed")
	if choice != null:
		focus_owner.keys = choice

	rebind_popup.queue_free()

	if focus_owner:
		focus_owner.grab_focus()
