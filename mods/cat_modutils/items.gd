extends Reference


func _init() -> void:
	var dt: Dictionary = Datatables.load("res://data/items/").table
	var item: BaseItem = load("res://mods/cat_modutils/items/modutils_glass.tres")
	dt[Datatables.get_db_key(item)] = item

	# Finish init later
	assert(not SceneManager.preloader.singleton_setup_complete)
	yield(SceneManager.preloader, "singleton_setup_completed")

	var item_desc: Translation
	var locale: String = TranslationServer.get_locale()
	for l in TranslationServer.get_loaded_locales():
		item_desc = Translation.new()
		item_desc.locale = l
		item_desc.add_message("MODUTILS_ITEM_GLASS_DESCRIPTION",
			tr("MODUTILS_ITEM_DESCRIPTION_FOOTER") % tr("ITEM_PLASTIC_DESCRIPTION"))
		TranslationServer.add_translation(item_desc)
	TranslationServer.set_locale(locale)
