extends Reference

var _scripts: Dictionary

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

func set_class_script(script: GDScript, source_code: String):
	script.source_code = source_code
	script.reload()
