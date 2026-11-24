extends Control


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	Hud.hide()

func _on_iniciar_pressed() -> void:
	GameMannager.start_game()

func _on_sair_pressed() -> void:
	get_tree().quit()
