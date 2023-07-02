 extends Reference


signal updates_downloaded

var modutils: ContentInfo


func _init(parent: ContentInfo) -> void:
	modutils = parent

	# Add a callback for when we reach the title screen
	SceneManager.connect("scene_changed", self, "_on_SceneManager_scene_changed")

	# Don't check for updates if disabled
	if not modutils.setting_check_updates:
		return

	# Finish init later
	assert(not SceneManager.preloader.singleton_setup_complete)
	yield(SceneManager.preloader, "singleton_setup_completed")

	# Check for updates from all mods providing a MODUTILS table
	var update_data: Dictionary = {}
	for mod in DLC.mods:
		if "MODUTILS" in mod and mod.MODUTILS is Dictionary and "updates" in mod.MODUTILS:
			assert(mod.MODUTILS.updates is String)
			_check_updates(mod, mod.MODUTILS.updates, update_data)

	# We intentionally don't wait for each individual _check_updates to finish,
	# so they should run concurrently using multiple HTTPRequest nodes.
	# Instead, we now emit a signal after ALL of them are finished,
	# which is pretty easy since we don't care about all of their return values, lol.
	for k in update_data.keys():
		if update_data[k] is GDScriptFunctionState:
			yield(update_data[k], "completed")
	emit_signal("updates_downloaded")


func _validate_url(updates_url: String) -> bool:
	assert(not updates_url.empty())

	# Please just use a whitelisted service domain as listed below.
	var DOMAIN_WHITELIST: Array = [
		"*.github.io",
		"pastebin.com",
		"gist.githubusercontent.com",
	]

	# You MUST use HTTPS.
	assert(updates_url.begins_with("https://"))
	if not updates_url.begins_with("https://"):
		return false

	# You MUST include a trailing / after the domain name.
	var domain_sep: int = updates_url.find('/', 8)
	assert(domain_sep >= 0)
	if domain_sep < 0:
		return false
	var updates_domain: String = updates_url.substr(8, domain_sep - 8)
	assert(not updates_domain.empty())
	if updates_domain.empty():
		return false

	# You MUST use the domain of a whitelisted service.
	for domain in DOMAIN_WHITELIST:
		if updates_domain.match(domain):
			return true
	return false

func _check_updates(mod: ContentInfo, updates_url: String, update_data: Dictionary) -> void:
	# No funny business.
	assert(not updates_url.empty())
	if updates_url.empty():
		mod.set_meta("modutils_update", FAILED)
		return

	# We're busy.
	mod.set_meta("modutils_update", ERR_BUSY)

	var update_co

	# Wait for other coroutine to download
	if updates_url in update_data:
		update_co = update_data[updates_url]
		if update_co is GDScriptFunctionState:
			yield(update_co, "completed")
			update_co = update_data[updates_url]
	else:
		# Validate the URL
		if not _validate_url(updates_url):
			push_error("Mod Utils: Invalid updates URL for %s" % mod.name)
			mod.set_meta("modutils_update", FAILED)
			return
		# Start a download
		update_co = _download_updates(updates_url)
		if update_co is GDScriptFunctionState:
			update_data[updates_url] = update_co # This is for other download threads to wait on
			update_co = yield(update_co, "completed")
		update_data[updates_url] = update_co

	# Update data should be available now.
	assert(update_co is Dictionary)
	var update_defs: Dictionary = update_co
	if not update_defs or update_defs.empty():
		push_error("Mod Utils: Failed to download/parse update data for %s" % mod.name)
		mod.set_meta("modutils_update", FAILED)
		return

	if not mod.id in update_defs:
		push_error("Mod Utils: Invalid update data for %s" % mod.name)
		mod.set_meta("modutils_update", FAILED)
		return

	assert(update_defs[mod.id] is Dictionary)
	if not update_defs[mod.id] is Dictionary:
		push_error("Mod Utils: Invalid update data for %s" % mod.name)
		mod.set_meta("modutils_update", FAILED)
		return

	# OK, we have a table for this specific mod, let's check it.
	var mod_updates: Dictionary = update_defs[mod.id]
	assert("version_code" in mod_updates)
	if not "version_code" in mod_updates:
		push_error("Mod Utils: Invalid update data for %s" % mod.name)
		mod.set_meta("modutils_update", FAILED)
		return

	# Mod is up to date, all done!
	if mod.version_code >= mod_updates.version_code:
		mod.set_meta("modutils_update", OK)
		return

	# An update is available, so mark it.
#	Console.writeLine("An update is available for %s" % mod.name)
	var use_mod_page: bool = "mod_page" in mod_updates and mod_updates.mod_page is String
	if use_mod_page and not mod_updates.mod_page.begins_with("https://") and not mod_updates.mod_page.begins_with("http://"):
		use_mod_page = false
	if use_mod_page:
		mod.set_meta("modutils_update", mod_updates.mod_page)
	else:
		mod.set_meta("modutils_update", "")


func _download_updates(updates_url: String) -> Dictionary:
#	Console.writeLine("Downloading update data from %s" % updates_url)

	# We're using pretty strict limits here because
	# we expect only the smallest amount of data,
	# from a fast and reliable source.
	var http := HTTPRequest.new()
	http.body_size_limit = 2048
	http.max_redirects = 2
	http.timeout = 10.0
	DLC.add_child(http)

	var e := http.request(updates_url)
	if e != OK:
		http.queue_free()
		return {}
	var v: Array = yield(http, "request_completed")
	http.queue_free()
	return callv("_parse_dict_from_http", v)


func _parse_dict_from_http(result: int, response_code: int, _headers: PoolStringArray, body: PoolByteArray) -> Dictionary:
	if result != HTTPRequest.RESULT_SUCCESS:
		return {}
	if response_code != 200 and response_code != 203:
		return {}
	var contents: String = body.get_string_from_utf8()
	if not contents or contents.empty():
		return {}
	var json: JSONParseResult = JSON.parse(contents)
	if json.error != OK:
		return {}
	if not json.result is Dictionary:
		return {}
	return json.result


func _on_SceneManager_scene_changed() -> void:
	# Modify the title screen to show update data
	if SceneManager.current_scene.filename != "res://menus/title/TitleMenu.tscn":
		return

	# Don't edit TitleMenu if disabled
	if not modutils.setting_check_updates:
		return

	# Abort and leave the title screen alone if no mod update information is available.
	var updates_used: bool = false
	for mod in DLC.mods:
		if mod.has_meta("modutils_update"):
			updates_used = true
			break
	if not updates_used:
		return

	# Grab scroll container and hide the vanilla label
	var scroll_container: ScrollContainer = SceneManager.current_scene.get_node("LogoContainer/VBoxContainer/PanelContainer/ScrollContainer")
	scroll_container.get_child(0).hide()

	# Add custom list of labels instead
	scroll_container.add_child(load("res://mods/cat_modutils/updates/ModUtilsVersionStrings.tscn").instance())
