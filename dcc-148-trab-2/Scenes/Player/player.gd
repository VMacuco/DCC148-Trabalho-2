extends CharacterBody2D


@export var SPEED := 300.0
@export var JUMP_VELOCITY := -400.0
@export var DASH_SPEED := 500.0
@export var DASH_TIME := 0.2
@export var DASH_COOLDOWN := 0.3
@export var WALL_FRICTION := 1500.0
@export var WALL_SPEED := 100.0
@export var WALL_STICK_TIME := 0.25
@export var WALL_JUMP_PUSH:= 350.0

var is_jumping:= false
var is_dashing:= false
var dash_blocked:= false
var is_wall_sliding:=false
var wall_stick_timer:=0.0
var dash_delay:=0.0
var facing:= 1.0
var dash_dir
@onready var ColisionBox := $Colision
@onready var Colision_dash := $Colison_dash


func _ready() -> void:
	Colision_dash.disabled = true

func _physics_process(delta: float) -> void:
	var direction = Input.get_axis("esquerda","direita")
	if direction:
		facing = sign(direction)
	
	#dash
	if is_dashing:
		velocity.x = dash_dir * DASH_SPEED
		velocity.y = 0.0
		move_and_slide()
		return
	
	#Gravidade
	if not is_on_floor():
		velocity += get_gravity() * delta
		is_jumping = true
	else:
		is_jumping = false
		dash_blocked = false
	
	#pulo
	if Input.is_action_just_pressed("pulo") and is_on_floor():
		velocity.y = JUMP_VELOCITY

	if Input.is_action_just_released("pulo") and is_jumping and velocity.y < 0:
		velocity.y *= 0.5
	
	#movimento
	if direction:
		velocity.x = direction * SPEED
	else:
		velocity.x = move_toward(velocity.x, 0, SPEED)
	
	#wall_slide
	handle_wall_slide(direction,delta)
	
	#acionar dash
	if Input.is_action_just_pressed("dash") and not dash_blocked:
		is_dashing = true
		is_wall_sliding = false
		start_dash()
	
	move_and_slide()
	
func start_dash()->void:
	is_dashing = true
	dash_blocked = true
	dash_dir = facing
	
	
	await get_tree().create_timer(DASH_TIME).timeout
	
	is_dashing = false
	ColisionBox.set_deferred("disabled", false)
	Colision_dash.set_deferred("disabled", true)
	velocity.x = 0

func handle_wall_slide(direction:float, delta:float)->void:
	var wall_pressing := false
	if is_on_wall():
		wall_pressing = direction != 0 and sign(direction) == -sign(get_wall_normal().x)
	is_wall_sliding = not is_on_floor() and is_on_wall() and velocity.y >= 0 and wall_pressing
	if not is_wall_sliding:
		wall_stick_timer = WALL_STICK_TIME
		return
	if wall_stick_timer > 0:
		wall_stick_timer -= delta
		velocity.y = 0.0
	else:
		velocity.y = move_toward(velocity.y, WALL_SPEED, WALL_FRICTION * delta)
 
