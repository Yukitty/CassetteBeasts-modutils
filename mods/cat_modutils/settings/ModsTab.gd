extends Control

const ArrowOptionList: PackedScene = preload("res://nodes/menus/ArrowOptionList.tscn")
const ArrowSlider: PackedScene = preload("res://nodes/menus/ArrowSlider.tscn")
const ArrowSlider_Percent: PackedScene = preload("res://nodes/menus/ArrowSlider_Percent.tscn")
const ArrowSlider_CustomFormat: GDScript = preload("ArrowSlider_CustomFormat.gd")

onready var inputs: GridContainer = find_node("Inputs")

var submod: Reference
var _widgets: Array

func _ready() -> void:
	submod = DLC.mods_by_id["cat_modutils"].settings

	for mod in submod._mod_settings:
		assert("MODUTILS" in mod and mod.MODUTILS.has("settings"))
		_add_heading(mod.name)
		for widget in mod.MODUTILS.settings:
			match widget.type:
				"toggle":
					add_toggle(mod, widget.property, widget.label)
				"slider":
					var min_value: float = widget.min_value if widget.has("min_value") else 0.0
					var max_value: float = widget.max_value if widget.has("max_value") else 1.0
					var step: float = widget.step if widget.has("step") else 0.01
					var format: String = widget.format if widget.has("format") else ""
					add_slider(mod, widget.property, widget.label, min_value, max_value, step, format)
				"percent_slider":
					var step: float = widget.step if widget.has("step") else 0.05
					add_percent_slider(mod, widget.property, widget.label, step)
				"options":
					add_options(mod, widget.property, widget.label, widget.values, widget.value_labels)
				"label", _:
					add_label(widget.label)

	reset()

func is_dirty() -> bool:
	for widget in _widgets:
		var mod: ContentInfo = widget.get_meta("owner")
		var property: String = widget.get_meta("property")
		if mod.get(property) != widget.selected_value:
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
	cfg.save(submod.CFG_PATH)

func reset() -> void:
	for widget in _widgets:
		var mod: ContentInfo = widget.get_meta("owner")
		var property: String = widget.get_meta("property")
		widget.selected_value = mod.get(property)

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
	label.text = text
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
	label.text = text
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
	label.text = text
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
