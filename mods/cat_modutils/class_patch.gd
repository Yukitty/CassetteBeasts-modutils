extends Reference

var processed_code: Dictionary = {}


func _init() -> void:
	# Run super-early callback for class patcher
	# This is basically a mid-execution pre-emption of the DLC singleton
	# and I hate it.

	# Fetch ALL mod metadata resources
	# except for our own, which is currently being initialized
	var dir := Directory.new()
	var err: int = dir.open("res://mods/")
	assert(err == OK)
	dir.list_dir_begin(true, true)
	assert(err == OK)
	var mods: Array = []
	while true:
		var file = dir.get_next()
		if file.empty():
			break
		if file == "cat_modutils":
			continue
		file = "res://mods/%s/metadata.tres" % file
		if dir.file_exists(file):
			var meta: ContentInfo = load(file) as ContentInfo
			if meta:
				mods.push_back(meta)
	dir.list_dir_end()

	# Iterate all mod metadata
	# and apply patches from the MODUTILS global const, if present.
	for meta in mods:
		if "MODUTILS" in meta and meta.MODUTILS is Dictionary and "class_patch" in meta.MODUTILS:
			assert(meta.MODUTILS.class_patch is Array and not meta.MODUTILS.class_patch.empty())
			for def in meta.MODUTILS.class_patch:
				assert(def is Dictionary and not def.empty())
				assert("patch" in def and def.patch is String and not def.patch.empty())
				assert("target" in def and def.target is String and not def.target.empty())
				patch(def.patch, def.target)

	# Now that we've initialized all of the mods that weren't loaded yet,
	# we need to hold the references until DLC is finished taking them.
	# This will prevent headaches from repeated _init calls.
	# A simple yield should do nicely here.
	assert(not SceneManager.preloader.singleton_setup_complete)
	yield(SceneManager.preloader, "singleton_setup_completed")


func get_class_script(script: GDScript) -> String:
	# First, check if plain text source_code is already available.
	# That would be a sign someone else has edited the file already.
	var source_code: String = ""

	if script.has_source_code():
		source_code = script.source_code

	# If we don't have source code, try loading it from the res:// file.
	else:
		var f := File.new()
		# This assert fails if you didn't export the decompiled script with your mod.
		assert(f.file_exists(script.resource_path))
		f.open(script.resource_path, File.READ)
		source_code = f.get_as_text()
		f.close()

	# We have to remove class_name from the source code for Godot to load it.
	var s: int = source_code.find("class_name")
	var e: int
	if s != -1:
		e = source_code.find("\n", s)
		source_code.erase(s, e - s + 1)

	return source_code


func set_class_script(script: GDScript, source_code: String) -> void:
	script.source_code = source_code
	script.reload()


func patch_process_code(path: String, code: String) -> void:
	var currentfunc: String = "global"
	var line: String
	processed_code[path] = {}

	for x in code.split("\n"):
		line = x
		line += "\n"
		if line.begins_with("func"):
			currentfunc = line.substr(5, line.find('(') - 5)

		if processed_code[path].has(currentfunc):
			var templine = processed_code[path][currentfunc]
			processed_code[path][currentfunc] = templine + line
		else:
			processed_code[path][currentfunc] = line


func patch(patch_path: String, target_path: String, toprint: bool = false) -> void:
	# As a first step, we grab the file that is to replace, and decompile its variables and functions
	var source_code: String =  get_class_script(load(target_path))
	patch_process_code(target_path, source_code)

	var patch_code: PoolStringArray = get_class_script(load(patch_path)).split("\n")
	var currentfunc: String = "global"
	for x in patch_code.size():
		var line = patch_code[x].dedent()
		# Always update currentfunc
		if line.begins_with("func"):
			currentfunc = line.substr(5, line.find('(') - 5)

		# If this isn't a # PATCH: line, skip
		if line.begins_with("# PATCH: ") == false:
			continue

		# We know there is something after # PATCH:, so we get the command name
		line = line.split("# PATCH: ")[1]

		# We first check for IFs
		while line.begins_with("IF"):
			if line.begins_with("IF MOD"):
				var mod = line.split("\"")

				if DLC.has_dlc(mod):
					# We continue one line to the next command
					x += 1
				else:
					# We skip over two lines to skip a command underneath
					x += 2
			if line.begins_with("IF NOT MOD"):
				var mod = line.split("\"")

				if !DLC.has_dlc(mod):
					# We continue one line to the next command
					x += 1
				else:
					# We skip over two lines to skip a command underneath
					x += 2
			line = patch_code[x].dedent().split("# PATCH: ")[1]

		# We check which command it is, and execute the function appropriate to it
		# Always look for the # PATCH: STOP that will come next
		# If there is a command other than STOP, will make the system shut down
		if line.begins_with("REMOVE LINES"):
			var what = ""

			while true:
				x += 1
				line = patch_code[x].dedent()

				if line == "# PATCH: STOP":
					break
				else:
					assert(!line.begins_with("# PATCH: "))

				line = patch_code[x]

				if (line.find("#>") != -1):
					line.erase(line.find("#>"), 2)

				what += line + "\n"

			patch_removelines(what, currentfunc, target_path)

		if line.begins_with("REMOVE FUNC"):
			var what = patch_code[x].split("\"")[1]
			patch_removefunc(what, target_path)

		if line.begins_with("ADD LINES"):
				if line.ends_with("BEFORE") or line.ends_with("AFTER"):
					var what = ""
					var before = line.ends_with("BEFORE")
					while true:
						x += 1
						line = patch_code[x].dedent()

						if line == "# PATCH: STOP":
							break
						else:
							assert(!line.begins_with("# PATCH: "))

						line = patch_code[x]

						if (line.find("#>") != -1):
							line.erase(line.find("#>"), 2)

						what += line + "\n"

					patch_addlines(what, before, currentfunc, target_path)
				if line.ends_with("HERE"):
					var what = ""
					var where = patch_code[x-1]
					while true:
						x += 1
						line = patch_code[x].dedent()

						if line == "# PATCH: STOP":
							break
						else:
							assert(!line.begins_with("# PATCH: "))

						line = patch_code[x]

						if (line.begins_with("#>")):
							line.erase(0, 2)

						what += line + "\n"
					patch_addlineshere(what, where, currentfunc, target_path)

		if line.begins_with("ADD FUNC"):
			var what = ""
			line = patch_code[x+1].dedent()
			currentfunc = line.substr(5, line.find('(') - 5)
			while true:
				x += 1
				line = patch_code[x].dedent()

				if line == "# PATCH: STOP":
					break
				else:
					assert(!line.begins_with("# PATCH: "))

				line = patch_code[x]

				if (line.find("#>") != -1):
					line.erase(line.find("#>"), 2)

				what += line + "\n"

			patch_addfunc(what, currentfunc, target_path)

		if line.begins_with("REPLACE LINES"):
			var strings = ["", ""]
			var curr = 0
			while true:
				x += 1
				line = patch_code[x].dedent()

				if line == "# PATCH: STOP":
					break
				elif line == "# PATCH: INTO":
					curr = 1
				else:
					assert(!line.begins_with("# PATCH: "))
					line = patch_code[x]
					if (line.find("#>") != -1):
						line.erase(line.find("#>"), 2)
					strings[curr] += line + "\n"

			patch_replacelines(strings[0], strings[1], currentfunc, target_path)

		if line.begins_with("REPLACE TEXT"):
			line = patch_code[x].dedent()
			line = line.split("# PATCH: REPLACE TEXT ")[1]
			line = line.split(" #INTO# ")
			var what = line[0]
			var forwhat = line[1]
			var where = patch_code[x+1]
			patch_replacetext(what, forwhat, where, currentfunc, target_path)

	var finalcode = ""
	for k in processed_code[target_path].keys():
		finalcode += processed_code[target_path][k]

	if toprint:
		print(finalcode)
	set_class_script(load(target_path), finalcode)


func patch_removelines(what: String, function: String, code: String) -> void:
	var string: String = processed_code[code][function]
	var pos: int = processed_code[code][function].find(what)

	if pos != -1:
		string.erase(pos, what.length())

	processed_code[code][function] = string


func patch_removefunc(what: String, code: String) -> void:
	processed_code[code].erase(what)


func patch_addlines(what: String, before: bool, function: String, code: String) -> void:
	var string: String = processed_code[code][function]
	var firstline: String = string.get_slice("\n", 0)

	if before == true:
		string.erase(string.find(firstline), firstline.length())
		processed_code[code][function] = firstline + "\n" + what + "\n" + string
	else:
		processed_code[code][function] = string + "\n" + what


func patch_addlineshere(what: String, where: String, function: String, code: String) -> void:
	var string: String = processed_code[code][function]
	var pos: int = processed_code[code][function].find(where)

	if pos != -1:
		processed_code[code][function] = string.replace(where, where + "\n" + what)


func patch_addfunc(what: String, function: String, code: String) -> void:
	processed_code[code][function] = what


func patch_replacelines(what: String, forwhat: String, function: String, code: String) -> void:
	var string: String = processed_code[code][function]
	processed_code[code][function] = string.replace(what, forwhat)


func patch_replacetext(what: String, forwhat: String, where: String, function: String, code: String) -> void:
	var string: String = processed_code[code][function]
	var line: String = string.substr(string.find(where), where.length())

	line = line.replace(what, forwhat)
	string = string.replace(where, line)
	processed_code[code][function] = string
