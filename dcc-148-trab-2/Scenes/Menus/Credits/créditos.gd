extends Control


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	Hud.hide()
	
func _on_sair_pressed() -> void:
	get_tree().quit()

func _on_main_menu_pressed() -> void:
	get_tree().change_scene_to_file("res://Scenes/Menus/MainMenu/MainMenu.tscn")
