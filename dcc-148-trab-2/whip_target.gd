@tool
class_name Whip_Target
extends Area2D

enum Type {GRAPPLE, PENDULUM}

const layer_target := 3
const layer_player := 2

@export var type := Type.GRAPPLE:
	set(value):
		type = value
		if is_node_ready():
			_apply_type()

@export var texture: Texture2D:
	set(value):
		texture = value
		if is_node_ready():
			$Sprite2D.texture = texture

@export var zone_radius := 150.0:
	set(value):
		zone_radius = value
		if is_node_ready():
			_apply_type()

@export_group("Rotação (GRAPPLE)")
@export var sprite_angle_offset := PI/2
@export var turn_speed := 12.0
@export var track_range := 0.0


@onready var pendulum_zone := $Pendulum_zone
@onready var zone_shape := $Pendulum_zone/CollisionShape2D
@onready var sprite: Sprite2D = $Sprite2D

var player: Node2D
var base_scale := Vector2(0.5, 0.5)


func _ready() -> void:
	sprite.texture = texture
	sprite.scale = base_scale
	_apply_type()

	if Engine.is_editor_hint():
		return

	pendulum_zone.body_entered.connect(_on_zone_entered)
	pendulum_zone.body_exited.connect(_on_zone_exited)


func _process(delta: float) -> void:
	if Engine.is_editor_hint() or type != Type.GRAPPLE:
		return

	if not is_instance_valid(player):
		player = get_tree().get_first_node_in_group("Player") as Node2D
		if player == null:
			return

	var dir := global_position - player.global_position  # jogador -> alvo
	if dir.length() > track_range:
		return

	var target_angle := dir.angle() + sprite_angle_offset
	sprite.global_rotation = lerp_angle(sprite.global_rotation, target_angle, turn_speed * delta)


func _apply_type() -> void:
	if zone_shape.shape is CircleShape2D:
		zone_shape.shape.radius = zone_radius

	match type:
		Type.GRAPPLE:
			set_collision_layer_value(layer_target, true)
			pendulum_zone.monitoring = false
			zone_shape.set_deferred("disabled", true)
		Type.PENDULUM:
			set_collision_layer_value(layer_target, false)
			pendulum_zone.collision_layer = 0
			pendulum_zone.collision_mask = 0
			pendulum_zone.set_collision_mask_value(layer_player, true)
			pendulum_zone.monitoring = true
			zone_shape.set_deferred("disabled", false)
			sprite.rotation = 0.0  # PENDULUM não gira


func on_hooked() -> void:
	var t := create_tween()
	t.tween_property(sprite, "scale", base_scale * 1.3, 0.08)
	t.tween_property(sprite, "scale", base_scale, 0.12)


func _on_zone_entered(body: Node2D) -> void:
	if body is Player:
		body.pendulum_zone_target = self


func _on_zone_exited(body: Node2D) -> void:
	if body is Player and body.pendulum_zone_target == self:
		body.pendulum_zone_target = null
