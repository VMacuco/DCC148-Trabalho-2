extends AnimatedSprite2D

@onready var menu = $"PauseMenu"
@onready var continuar = $"PauseMenu/ButtonSlot/Continuar"
var pausado = false

func _ready() -> void:
	get_viewport().size_changed.connect(_centralizar_livro)
	_centralizar_livro()

func _centralizar_livro() -> void:
	position = get_viewport_rect().size / 2
	
func _input(event):
	if event.is_action_pressed("ui_cancel"):
		if not pausado:
			abrir_pause()
		else:
			fechar_pause()

func abrir_pause():
	pausado = true
	get_tree().paused = true
	play("OpenGrimory")

func fechar_pause():
	pausado = false
	menu.hide()
	play("CloseGrimory")
	
func _on_animation_finished():
	if animation == "OpenGrimory":
		menu.show()

	elif animation == "CloseGrimory":
		get_tree().paused = false


func _on_continuar_pressed() -> void:
	fechar_pause()

func _on_sair_pressed() -> void:
	get_tree().quit()
	#ajustar
	
