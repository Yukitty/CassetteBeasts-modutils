extends DecoratorAction
# FortuneCookieNPCBehavior

# DEPRECIATED: Prefer to use Translation Plus variants for messages instead, if you can.

# Makes the NPC choose a new random dialog line
# every time the scene is visited.

export (Texture) var portrait: Texture
export (AudioStream) var voice_audio: AudioStream
export (String) var title: String = ""
export (Array, String) var dialogue: Array = []


func _ready() -> void:
	call_deferred("update_dialog")


func update_dialog() -> void:
	var cutscene := Cutscene.new()
	add_child(cutscene)
	var message := MessageDialogAction.new()
	message.portrait = portrait
	message.audio = voice_audio
	message.title = title
	message.messages = [dialogue[randi() % dialogue.size()]]
	cutscene.add_child(message)
