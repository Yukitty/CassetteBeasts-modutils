extends "res://nodes/menus/ArrowSlider.gd"

export var format_string: String

func format_value_label(value:float)->String:
	return format_string.format({"value": str(value)})
