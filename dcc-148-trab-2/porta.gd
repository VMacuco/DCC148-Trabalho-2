class_name Porta
extends Area2D

@export var sala_id := ""
@export var porta_id := ""
@export var pedra_subida := 24.0
@export var tempo := 0.6

@onready var pedra: Sprite2D = $Pedra
@onready var prompt: Label = $Label

var key := ""
var pedra_y := 0.0
var player_inside := false
var usada := false
var tween: Tween
var prompt_tween: Tween


func _ready() -> void:
	key = "%s:%s" % [sala_id, porta_id]
	pedra_y = pedra.position.y

	if not LevelGraph.BASE.has(key):
		push_warning("Porta sem ligação: %s" % key)

	prompt.modulate.a = 0.0
	prompt.visible = false

	LevelGraph.graph_changed.connect(_on_graph_changed)
	body_entered.connect(_on_body_entered)
	body_exited.connect(_on_body_exited)

	_atualizar(true)


func _on_graph_changed() -> void:
	_atualizar(false)


func _on_body_entered(body: Node2D) -> void:
	if body is Player:
		player_inside = true
		if LevelGraph.door_active(key):
			_mostrar_prompt(true)


func _on_body_exited(body: Node2D) -> void:
	if body is Player:
		player_inside = false
		_mostrar_prompt(false)


func _unhandled_input(event: InputEvent) -> void:
	if usada or not player_inside:
		return
	if not LevelGraph.door_active(key):
		return
	if event.is_action_pressed("Interagir"):
		usada = true
		_mostrar_prompt(false)
		LevelGraph.travel(key)


func _atualizar(instantaneo: bool) -> void:
	var aberta := LevelGraph.door_active(key)

	var alvo_y := pedra_y - pedra_subida if aberta else pedra_y
	var alvo_a := 0.0 if aberta else 1.0

	# se o estado mudou com o jogador dentro, o prompt acompanha
	if player_inside:
		_mostrar_prompt(aberta)
	elif not aberta:
		_mostrar_prompt(false)

	if tween:
		tween.kill()

	if instantaneo:
		pedra.position.y = alvo_y
		pedra.modulate.a = alvo_a
		return

	tween = create_tween()
	tween.set_parallel(true)
	tween.set_trans(Tween.TRANS_QUAD)
	tween.set_ease(Tween.EASE_OUT)
	tween.tween_property(pedra, "position:y", alvo_y, tempo)
	tween.tween_property(pedra, "modulate:a", alvo_a, tempo)


func _mostrar_prompt(mostrar: bool) -> void:
	if prompt_tween:
		prompt_tween.kill()
	prompt_tween = create_tween()
	if mostrar:
		prompt.visible = true
		prompt_tween.tween_property(prompt, "modulate:a", 1.0, 0.15)
	else:
		prompt_tween.tween_property(prompt, "modulate:a", 0.0, 0.15)
		prompt_tween.tween_callback(_esconder_prompt)


func _esconder_prompt() -> void:
	prompt.visible = false
