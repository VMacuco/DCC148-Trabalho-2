@tool
class_name Circulo
extends Area2D

@export_enum("a", "b", "c") var id := "a"

@export var texture: Texture2D:
	set(value):
		texture = value
		if is_node_ready():
			sprite.texture = texture

@export var fade_time := 0.8
@export var pulse_scale := 1.4

@onready var sprite: Sprite2D = $Sprite2D
@onready var prompt: Label = $Label

var player_inside := false
var prompt_tween: Tween


func _ready() -> void:
	if texture:
		sprite.texture = texture

	if Engine.is_editor_hint():
		return

	prompt.modulate.a = 0.0
	prompt.visible = false

	# já foi ativado antes (a sala foi recarregada): começa escondido e inativo
	if LevelGraph.used.has(id):
		visible = false
		set_deferred("monitoring", false)
		return

	body_entered.connect(_on_body_entered)
	body_exited.connect(_on_body_exited)


func _on_body_entered(body: Node2D) -> void:
	if body is Player:
		player_inside = true
		_mostrar_prompt(true)


func _on_body_exited(body: Node2D) -> void:
	if body is Player:
		player_inside = false
		_mostrar_prompt(false)


func _unhandled_input(event: InputEvent) -> void:
	if Engine.is_editor_hint():
		return
	if player_inside and not LevelGraph.used.has(id) and event.is_action_pressed("Interagir"):
		_ativar()


func _ativar() -> void:
	player_inside = false
	set_deferred("monitoring", false)
	_mostrar_prompt(false)

	LevelGraph.activate(id)

	var t := create_tween()
	t.set_parallel(true)
	t.set_trans(Tween.TRANS_QUAD)
	t.set_ease(Tween.EASE_OUT)
	t.tween_property(sprite, "modulate:a", 0.0, fade_time)
	t.tween_property(sprite, "scale", sprite.scale * pulse_scale, fade_time)
	t.chain().tween_callback(_esconder)


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


func _esconder() -> void:
	visible = false


func _esconder_prompt() -> void:
	prompt.visible = false
