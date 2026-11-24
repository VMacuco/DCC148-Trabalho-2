@tool
class_name Grimoaire
extends Area2D

signal Level_Complete
@onready var sprite: Sprite2D = $Sprite2D
@onready var promptlabel := $Label
@onready var pickup_sound := $AudioStreamPlayer2D

@export var texture : Texture2D:
	set(value):
		texture = value
		if is_node_ready():
			sprite.texture = texture

@export var float_height := 6.0
@export var float_time := 1.2

var player_inside := false

var float_tween : Tween
var prompt_tween : Tween

func _ready() -> void:
	sprite.texture = texture
	if Engine.is_editor_hint():
		return
	
	Level_Complete.connect(LevelMannager.complete_level)
	
	promptlabel.modulate.a = 0.0
	promptlabel.visible = false

	await get_tree().create_timer(randf_range(0.0, float_time)).timeout
	_start_float()

func _start_float() -> void:
	var base_y := sprite.position.y
	float_tween = create_tween().set_loops()
	float_tween.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	float_tween.tween_property(sprite, "position:y", base_y - float_height, float_time)
	float_tween.tween_property(sprite, "position:y", base_y + float_height, float_time)



func _on_body_entered(body: Node2D) -> void:
	if body is Player:
		("entrou")
		player_inside = true
		show_prompt(true)


func _on_body_exited(body: Node2D) -> void:
	if body is Player:
		print("saiu")
		player_inside = false
		show_prompt(false)
		

func _unhandled_input(event: InputEvent) -> void:
	if Engine.is_editor_hint():
		return
	if player_inside and event.is_action_pressed("Interagir"):
		player_inside = false
		show_prompt(false)
		pickup_sound.play()
		Level_Complete.emit()
		
		

func show_prompt(show_it : bool) -> void:
	if prompt_tween:
		prompt_tween.kill()  # evita tweens brigando se o jogador entra e sai rápido

	prompt_tween = create_tween()
	if show_it:
		promptlabel.visible = true
		prompt_tween.tween_property(promptlabel, "modulate:a", 1.0, 0.15)
	else:
		prompt_tween.tween_property(promptlabel, "modulate:a", 0.0, 0.15)
		prompt_tween.tween_callback(func(): promptlabel.visible = false)
