extends DecoratorAction
# FortuneCookieNPCBehavior

# Makes the NPC choose a new random dialog line
# every time the scene is visited.

export (Texture) var portrait: Texture
export (AudioStream) var voice_audio: AudioStream
export (String) var title: String = ""
export (Array, String) var dialogue: Array = []

var cutscene: Cutscene

func _init() -> void:
	cutscene = Cutscene.new()
	add_child(cutscene)

func _ready() -> void:
	call_deferred("update_dialog")
	SceneManager.current_scene.connect("transitioned_into", self, "update_dialog")

func update_dialog() -> void:
	for child in cutscene.get_children():
		child.queue_free()

	var message := MessageDialogAction.new()
	message.portrait = portrait
	message.audio = voice_audio
	message.title = title
	message.messages = [dialogue[randi() % dialogue.size()]]
	cutscene.add_child(message)
