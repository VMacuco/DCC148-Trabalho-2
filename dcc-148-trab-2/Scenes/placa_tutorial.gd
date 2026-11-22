@tool
class_name Placa
extends Area2D

@export_multiline var texto := "Aperte [pulo] para pular.":
	set(value):
		texto = value
		if is_node_ready():
			label.text = texto

@export var balao_offset_y := -40.0   # distância acima do centro da zona
@export var fade_time := 0.2

@onready var balao: PanelContainer = $"Balão"
@onready var label: Label = $"Balão/MarginContainer/Texto"

var tween: Tween


func _ready() -> void:
	label.text = texto

	if Engine.is_editor_hint():
		return

	balao.modulate.a = 0.0
	balao.visible = false
	body_entered.connect(_on_body_entered)
	body_exited.connect(_on_body_exited)


func _on_body_entered(body: Node2D) -> void:
	if body is Player:
		_mostrar(true)


func _on_body_exited(body: Node2D) -> void:
	if body is Player:
		_mostrar(false)


func _mostrar(visivel: bool) -> void:
	if visivel:
		balao.visible = true
		await get_tree().process_frame   # espera o container calcular o tamanho
		_posicionar()

	if tween:
		tween.kill()
	tween = create_tween()

	if visivel:
		tween.tween_property(balao, "modulate:a", 1.0, fade_time)
	else:
		tween.tween_property(balao, "modulate:a", 0.0, fade_time)
		tween.tween_callback(func(): balao.visible = false)


func _posicionar() -> void:
	balao.position = Vector2(-balao.size.x / 2.0, balao_offset_y - balao.size.y)
