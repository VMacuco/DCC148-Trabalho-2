class_name Player
extends CharacterBody2D

@export var SPEED := 300.0
@export var JUMP_VELOCITY := -400.0
@export var DASH_SPEED := 500.0
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


func _ready() -> void:
	Colision_dash.disabled = true

func _physics_process(delta: float) -> void:
	var direction := Input.get_axis("esquerda", "direita")
	if direction:
		facing = sign(direction)

	# Dash
	if is_dashing:
		velocity.x = dash_dir * DASH_SPEED
		velocity.y = 0.0
		move_and_slide()
		return

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

	# Dash
	if Input.is_action_just_pressed("dash") and not dash_blocked:
		start_dash()

	move_and_slide()


func start_dash() -> void:
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
