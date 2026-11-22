class_name Player
extends CharacterBody2D

enum WhipState { NONE, FIRING, PULLING, SWINGING }

@export_group("Chicote")
@export var WHIP_SPEED := 1800.0
@export var WHIP_RANGE := 100.0         
@export var PULL_SPEED := 900.0         
@export var LAUNCH_SPEED := 500.0       
@export var LAUNCH_LOCK_TIME := 0.25   
@export var SWING_KICK := 150.0         
@export var SWING_RELEASE_LOCK := 0.2   
@export_flags_2d_physics var WHIP_MASK := 5  # layers 1 (mundo) + 3 (alvos)

var whip_state := WhipState.NONE
var whip_dir := Vector2.RIGHT
var whip_length := 0.0
var whip_target: Whip_Target = null
var pendulum_zone_target: Whip_Target = null
var pull_dir := Vector2.ZERO
var swing_angle := 0.0
var swing_omega := 0.0
var swing_length := 0.0
var swing_sign := 1.0

@onready var whip_line: Line2D = $WhipLine

@export var SPEED := 220.0
@export var JUMP_VELOCITY := -400.0
@export var DASH_SPEED := 480.0
@export var DASH_TIME := 0.2
@export var WALL_FRICTION := 600.0
@export var WALL_SPEED := 100.0
@export var WALL_STICK_TIME := 0.25
@export var WALL_JUMP_PUSH := 400.0
@export var WALL_JUMP_LOCK_TIME := 0.2
@export var COYOTE_TIME := 0.1
@export var WALL_COYOTE_TIME := 0.12

var is_jumping := false
var is_dashing := false
var dash_blocked := false
var is_wall_sliding := false
var wall_stick_timer := 0.0
var facing := 1.0
var wall_jump_lock := 0.0
var dash_dir := 1.0
var coyote_timer := 0.0
var wall_coyote_timer := 0.0
var last_wall_normal_x := 0.0

@onready var ColisionBox := $Colision
@onready var Colision_dash := $Colison_dash
@onready var Hurtbox := $Hurtbox/CollisionShape2D


func _ready() -> void:
	Colision_dash.disabled = true
	GameMannager.respawn_player.connect(_respawn_player)
	
	if GameMannager.pending_spawn:
		GameMannager.pending_spawn = false
		global_position = GameMannager.SavePoint
	GameMannager.Checkpoint = global_position

func _physics_process(delta: float) -> void:
	if GameMannager.is_player_dead:
		end_whip()
		velocity = Vector2.ZERO
		return
	
	var direction := Input.get_axis("esquerda", "direita")
	if direction:
		facing = sign(direction)

	# Dash
	if is_dashing:
		velocity.x = dash_dir * DASH_SPEED
		velocity.y = 0.0
		move_and_slide()
		return
		
	#Chicote
	match whip_state:
		WhipState.PULLING:
			process_pull(delta)
			return
		WhipState.SWINGING:
			process_swing(delta)
			return
		WhipState.FIRING:
			updade_whip_shoot(delta)

	# Gravidade
	if not is_on_floor():
		velocity += get_gravity() * delta
		is_jumping = true
	else:
		is_jumping = false
		dash_blocked = false

	# Timers de coyote
	if is_on_floor():
		coyote_timer = COYOTE_TIME
	else:
		coyote_timer -= delta

	if is_on_wall_only():
		wall_coyote_timer = WALL_COYOTE_TIME
		last_wall_normal_x = get_wall_normal().x
	else:
		wall_coyote_timer -= delta

	# Pulo
	if Input.is_action_just_pressed("pulo"):
		if coyote_timer > 0.0:
			velocity.y = JUMP_VELOCITY
			coyote_timer = 0.0
		elif wall_coyote_timer > 0.0:
			wall_jump()

	if Input.is_action_just_released("pulo") and is_jumping and velocity.y < 0:
		velocity.y *= 0.5

	# Movimento lateral (bloqueado após wall jump)
	if wall_jump_lock > 0.0:
		wall_jump_lock -= delta
	elif direction:
		velocity.x = direction * SPEED
	else:
		velocity.x = move_toward(velocity.x, 0, SPEED)

	# Wall slide
	handle_wall_slide(direction, delta)

	#Disparar Chicote
	if Input.is_action_just_pressed("chicote") and whip_state == WhipState.NONE:
		if pendulum_zone_target:
			start_swing(pendulum_zone_target)
		else:
			start_whip_shoot()

	# Dash
	if Input.is_action_just_pressed("dash") and not dash_blocked:
		start_dash()

	move_and_slide()


func start_dash() -> void:
	end_whip()
	is_dashing = true
	is_wall_sliding = false
	dash_blocked = true
	dash_dir = facing
	wall_jump_lock = 0.0
	ColisionBox.set_deferred("disabled", true)
	Colision_dash.set_deferred("disabled", false)

	await get_tree().create_timer(DASH_TIME).timeout

	is_dashing = false
	ColisionBox.set_deferred("disabled", false)
	Colision_dash.set_deferred("disabled", true)
	velocity.x = 0.0


func handle_wall_slide(direction: float, delta: float) -> void:
	var pressing_wall: bool = is_on_wall() and direction != 0.0 \
		and signf(direction) == -signf(get_wall_normal().x)

	is_wall_sliding = pressing_wall and not is_on_floor() \
		and velocity.y >= 0.0 and wall_jump_lock <= 0.0

	if not is_wall_sliding:
		wall_stick_timer = WALL_STICK_TIME
		return

	if wall_stick_timer > 0.0:
		wall_stick_timer -= delta
		velocity.y = 0.0
	else:
		velocity.y = move_toward(velocity.y, WALL_SPEED, WALL_FRICTION * delta)


func wall_jump() -> void:
	velocity.y = JUMP_VELOCITY
	velocity.x = last_wall_normal_x * WALL_JUMP_PUSH  # normal aponta para longe da parede
	wall_jump_lock = WALL_JUMP_LOCK_TIME
	wall_coyote_timer = 0.0
	coyote_timer = 0.0
	is_wall_sliding = false
	wall_stick_timer = WALL_STICK_TIME
	

func _respawn_player()->void:
	velocity = Vector2.ZERO
	end_whip()
	global_position = GameMannager.Checkpoint



#-----------Funções do Chicote --------------------------------------------------

#disparo
func start_whip_shoot()->void:
	var aim := Input.get_vector("esquerda","direita","cima","baixo").normalized()
	whip_dir = aim if aim != Vector2.ZERO else Vector2(facing,0.0)
	whip_length = 0.0
	whip_state = WhipState.FIRING

func updade_whip_shoot(delta:float)->void:
	if not Input.is_action_pressed("chicote"):
		end_whip()
		return
	
	whip_length += WHIP_SPEED * delta
	var from := global_position
	var to:= from + whip_dir * minf(whip_length, WHIP_RANGE)
	
	var query := PhysicsRayQueryParameters2D.create(from, to, WHIP_MASK)
	query.collide_with_areas = true
	query.exclude = [get_rid()]
	var hit := get_world_2d().direct_space_state.intersect_ray(query)
	
	if hit:
		var c = hit.collider
		if c is Whip_Target and c.type == Whip_Target.Type.GRAPPLE:
			whip_target = c
			whip_state = WhipState.PULLING
			return
		end_whip()
		return
	if whip_length >= WHIP_RANGE:
		end_whip()
		return
	update_whip_line(to)

#Puxão
func process_pull(delta: float) -> void:
	if not Input.is_action_pressed("chicote"):
		end_whip()
		return

	var to_target := whip_target.global_position - global_position
	var dist := to_target.length()

	if dist <= maxf(20.0, PULL_SPEED * delta):
		# chegou: arremessa na direção do movimento
		velocity = pull_dir * LAUNCH_SPEED
		wall_jump_lock = LAUNCH_LOCK_TIME
		end_whip()
		return

	pull_dir = to_target.normalized()
	velocity = pull_dir * PULL_SPEED
	move_and_slide()

	if get_slide_collision_count() > 0:
		end_whip()  # bateu em algo no caminho
		return

	update_whip_line(whip_target.global_position)

# pendulo
func start_swing(target: Whip_Target) -> void:
	var r: Vector2 = global_position - target.global_position
	if r.y <= 0.0:
		return  # jogador acima do pivô: não há pêndulo possível

	whip_target = target
	swing_length = maxf(r.length(), 30.0)
	swing_angle = atan2(r.x, r.y)  # 0 = embaixo do pivô

	if absf(swing_angle) > 0.15:
		# fora do centro: balança na direção natural, atravessando o ponto mais baixo
		swing_sign = -signf(swing_angle)
	else:
		# quase embaixo: usa a mira
		var aim := Input.get_vector("esquerda", "direita", "cima", "baixo")
		swing_sign = signf(aim.x) if aim.x != 0.0 else facing

	swing_omega = swing_sign * SWING_KICK / swing_length
	is_wall_sliding = false
	whip_state = WhipState.SWINGING


func process_swing(delta: float) -> void:
	if not Input.is_action_pressed("chicote"):
		end_swing()
		return

	var g := get_gravity().length()
	swing_omega += -(g / swing_length) * sin(swing_angle) * delta

	# velocidade angular inverteu: chegou na extremidade
	if swing_omega * swing_sign <= 0.0:
		end_swing()
		return

	swing_angle += swing_omega * delta
	var pivot := whip_target.global_position
	var new_pos := pivot + Vector2(sin(swing_angle), cos(swing_angle)) * swing_length

	var motion := new_pos - global_position
	velocity = motion / delta
	move_and_slide()

	# só encerra se bater de frente contra algo (chão rente não conta)
	var dir := motion.normalized()
	for i in get_slide_collision_count():
		if get_slide_collision(i).get_normal().dot(dir) < -0.5:
			end_swing()
			return

	update_whip_line(pivot)
	
func end_swing() -> void:
	wall_jump_lock = SWING_RELEASE_LOCK  # preserva o embalo
	end_whip()
	
#Comum
func end_whip() -> void:
	whip_state = WhipState.NONE
	whip_target = null
	whip_line.clear_points()


func update_whip_line(world_end: Vector2) -> void:
	whip_line.clear_points()
	whip_line.add_point(Vector2.ZERO)
	whip_line.add_point(to_local(world_end))
	
	
