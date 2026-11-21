extends AnimatedSprite2D

enum State { IDLE, WALK, JUMP, FALL_BEGIN, FALLING, SLIDE, WALL_SLIDE }

# Animações desenhadas olhando pra DIREITA (as outras olham pra esquerda)
# Idle e Wall_slide olham pra direita, isso veio no asset. Todas as outras imgs vieram olhando pra esquerda
const FACES_RIGHT := ["Idle"]

# x = deslocamento lateral NA DIREÇÃO que o personagem olha (espelha com o flip)
# y = altura
const OFFSETS := {
	#Gambiarra pois os sprites sao apenas sheet e estao com dimensoes diferentes tanto em x quanto em y
	"Idle": Vector2(10, 10),
	"Wall_slide": Vector2(0, 10),
}

@onready var player: Player = get_parent()

var state: State = State.IDLE


func _ready() -> void:
	animation_finished.connect(_on_animation_finished)
	play("Idle")
	GameMannager.Player_Death.connect(_process_player_death)
	GameMannager.respawn_player.connect(func(): play("Idle"))


func _process(_delta: float) -> void:
	_update_flip()
	var new_state := _get_state()
	if new_state != state:
		state = new_state
		_play_state()


func _get_state() -> State:
	# Dash tem prioridade sobre tudo
	if player.is_dashing:
		return State.SLIDE

	# Wall slide vem antes do "no ar", senão cairia em Falling
	if player.is_wall_sliding:
		return State.WALL_SLIDE

	if not player.is_on_floor():
		if player.velocity.y < 0.0:
			return State.JUMP
		# Começou a cair: toca Falling_begin e depois Falling
		if state == State.JUMP or state == State.SLIDE or state == State.IDLE or state == State.WALK or state == State.WALL_SLIDE:
			return State.FALL_BEGIN
		if state == State.FALL_BEGIN:
			return State.FALL_BEGIN  # deixa terminar a animação
		return State.FALLING

	if absf(player.velocity.x) > 10.0:
		return State.WALK
	return State.IDLE


func _play_state() -> void:
	var anim := ""
	match state:
		State.IDLE:       anim = "Idle"
		State.WALK:       anim = "Walk"
		State.JUMP:       anim = "Jump"
		State.FALL_BEGIN: anim = "Falling_begin"
		State.FALLING:    anim = "Falling"
		State.SLIDE:      anim = "Slide"
		State.WALL_SLIDE: anim = "Wall_slide"

	play(anim)
	_update_flip()  # reaplica flip e offset já com a animação nova


func _update_flip() -> void:
	var dir: float = player.dash_dir if player.is_dashing else player.facing
	var flip := dir > 0.0          # padrão: sprites que olham pra esquerda
	if animation in FACES_RIGHT:
		flip = not flip            # Idle olha pra direita, então inverte
	flip_h = flip

	# Offset: x segue o lado que o personagem olha, y é fixo
	var off: Vector2 = OFFSETS.get(animation, Vector2.ZERO)
	off.x *= dir
	offset = off

func _process_player_death()->void:
	play("damage")


func _on_animation_finished() -> void:
	# Falling_begin -> Falling
	if state == State.FALL_BEGIN:
		state = State.FALLING
		play("Falling")
