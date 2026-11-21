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


@onready var pendulum_zone:= $Pendulum_zone
@onready var zone_shape:= $Pendulum_zone/CollisionShape2D


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	$Sprite2D.texture = texture
	$Sprite2D.scale = Vector2(0.5,0.5)
	_apply_type()

	if Engine.is_editor_hint():
		return
	
	pendulum_zone.body_entered.connect(_on_zone_entered)
	pendulum_zone.body_exited.connect(_on_zone_exited)


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

func _on_zone_entered(body: Node2D) -> void:
	if body is Player:
		#print("Player entrou na zona")
		body.pendulum_zone_target = self


func _on_zone_exited(body: Node2D) -> void:
	if body is Player and body.pendulum_zone_target == self:
		body.pendulum_zone_target = null
