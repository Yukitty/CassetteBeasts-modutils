extends Translation

const default_translation_paths = [
	"res://translation/strings_demo.",
	"res://translation/strings_release.",
	"res://translation/dialogue_demo.",
	"res://translation/dialogue_release.",
	"res://translation/1.1_demo.",
]

var translations: Array
var callbacks: Array

func init_locale() -> void:
	var tr: Translation
	for path in default_translation_paths:
		tr = load(path + locale + ".translation")
		translations.push_back(tr)
		TranslationServer.remove_translation(tr)

func add_translation(tr: Translation) -> void:
	assert(tr != null)
	translations.push_front(tr)

func add_translation_callback(object: Object, function: String, binds: Array = []) -> void:
	assert(object != null and function != null)
	assert(object.has_method(function))
	callbacks.push_back({
		object = object,
		function = function,
		binds = binds,
	})

func _get_message(src_message: String) -> String:
	var message: String = ""
	for tr in translations:
		message = tr.get_message(src_message)
		if message != "":
			break

	var modified: String = ""
	for callback in callbacks:
		var args: Array = [src_message, message]
		args.append_array(callback.binds)
		modified = callback.object.callv(callback.function, args)
		assert(modified is String)
		if modified != "":
			message = modified

	return message
