extends Sprite3D
## Selects a random sprite from an array of textures every time the scene is loaded.


export (Array, Texture) var textures: Array


func _ready() -> void:
	texture = textures[randi() % textures.size()]
	if texture:
		offset.x = -int(texture.get_width() / 2)
	else:
		hide()
