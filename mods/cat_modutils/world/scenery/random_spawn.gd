extends "res://mods/cat_modutils/world/scenery/warpable_object.gd"


export var scenes: Array

onready var spawn_point: Spatial = $SpawnPoint


func _ready() -> void:
	call_deferred("_spawn")


func _spawn() -> void:
	var scene := scenes[randi() % scenes.size()] as PackedScene
	if scene:
		var spawn: Spatial = scene.instance()
		spawn.transform = spawn_point.transform
		add_child(spawn)
