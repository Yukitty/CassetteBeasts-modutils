extends Reference

const MergeTranslation: GDScript = preload("trans_patch/MergeTranslation.gd")

var _merge_translations: Dictionary

func _init(modutils: Reference) -> void:
	# Patch TranslationServer
	var locales: Array = TranslationServer.get_loaded_locales()
	for l in locales:
		var merge_translation: Translation = MergeTranslation.new()
		merge_translation.locale = l
		merge_translation.init_locale()
		TranslationServer.add_translation(merge_translation)
		_merge_translations[l] = merge_translation

	modutils.connect("post_init", self, "_on_post_init")

func _on_post_init() -> void:
	for mod in DLC.mods:
		if mod.has_method("add_mod_translations"):
			mod.add_mod_translations(self)

func add_translation(tr: Translation) -> void:
	assert(_merge_translations.has(tr.locale))
	_merge_translations[tr.locale].add_translation(tr)

func add_translation_callback(object: Object, function: String, binds: Array = [], locale: String = "en") -> void:
	assert(_merge_translations.has(locale))
	_merge_translations[locale].add_translation_callback(object, function, binds)
