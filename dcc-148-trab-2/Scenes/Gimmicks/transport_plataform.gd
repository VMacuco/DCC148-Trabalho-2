@tool
extends Node2D

enum Estado { PARADA, ATIVANDO, INDO, VOLTANDO }

@export var deslocamento: Vector2 = Vector2(160, 0):
	set(valor):
		deslocamento = valor
		if is_inside_tree():
			atualizar_trilho()

@export var velocidade: float = 200.0 # Velocidade de ida em pixels por segundo
@export var velocidade_retorno: float = 60.0 # Velocidade de retorno em pixels por segundo
@export var pausa_no_inicio: float = 0.2 # Pequena pausa antes de arrancar (0.0 para sair na hora)
@export var pausa_no_final: float = 0.2 # Pequena pausa antes de começar a voltar (0.0 para voltar na hora)

@onready var plataforma: AnimatableBody2D = $Plataform

var estado_atual: Estado = Estado.PARADA
var jogador_encostando: bool = false
var timer_pausa: float = 0.0

func _ready() -> void:
	atualizar_trilho()

func atualizar_trilho() -> void:
	var inicio := get_node_or_null("Inicio") as Node2D
	var final := get_node_or_null("Final") as Node2D
	var trilho := get_node_or_null("Trilho") as Line2D
	
	if not inicio or not final or not trilho:
		return
		
	inicio.position = Vector2.ZERO
	final.position = deslocamento
	trilho.points = PackedVector2Array([Vector2.ZERO, deslocamento])

func _physics_process(delta: float) -> void:
	if Engine.is_editor_hint():
		return
		
	match estado_atual:
		Estado.PARADA:
			# Se o jogador já estiver encostando quando ela terminar de voltar, inicia a contagem para disparar
			if jogador_encostando:
				iniciar_ativacao()
				
		Estado.ATIVANDO:
			if timer_pausa > 0.0:
				timer_pausa -= delta
				return
			estado_atual = Estado.INDO
				
		Estado.INDO:
			plataforma.position = plataforma.position.move_toward(deslocamento, velocidade * delta)
			if plataforma.position.is_equal_approx(deslocamento):
				plataforma.position = deslocamento
				timer_pausa = pausa_no_final
				estado_atual = Estado.VOLTANDO
				
		Estado.VOLTANDO:
			if timer_pausa > 0.0:
				timer_pausa -= delta
				return
				
			plataforma.position = plataforma.position.move_toward(Vector2.ZERO, velocidade_retorno * delta)
			if plataforma.position.is_equal_approx(Vector2.ZERO):
				plataforma.position = Vector2.ZERO
				estado_atual = Estado.PARADA

func iniciar_ativacao() -> void:
	timer_pausa = pausa_no_inicio
	estado_atual = Estado.ATIVANDO

func _on_trigger_body_entered(body: Node2D) -> void:
	if body is Player or body.is_in_group("player"):
		jogador_encostando = true
		if estado_atual == Estado.PARADA:
			iniciar_ativacao()

func _on_trigger_body_exited(body: Node2D) -> void:
	if body is Player or body.is_in_group("player"):
		jogador_encostando = false
