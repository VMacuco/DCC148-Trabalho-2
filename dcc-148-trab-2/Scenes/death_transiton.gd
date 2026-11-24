extends CanvasLayer

const OPEN_RADIUS := 2.5
const CLOSED_RADIUS := -0.05

@export var close_time := 1.0
@export var open_time := 0.6

@onready var mat: ShaderMaterial = $ColorRect.material
@onready var rect:= $ColorRect



func _ready() -> void:
	rect.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
	mat.set_shader_parameter("radius", OPEN_RADIUS)

func _get_focus_screen() -> Vector2:
	var player := get_tree().get_first_node_in_group("Player") as Node2D
	if player == null:
		return Vector2(0.5, 0.5)
	var focus := player.get_node_or_null("TransitionFocus") as Node2D
	var world_pos := focus.global_position if focus else player.global_position
	var size := get_viewport().get_visible_rect().size
	var screen_pos := get_viewport().get_canvas_transform() * world_pos
	return screen_pos / size


func _set_radius(value: float) -> void:
	mat.set_shader_parameter("center", _get_focus_screen())
	mat.set_shader_parameter("radius", value)


func close() -> void:
	var t := create_tween().set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN_OUT)
	t.tween_method(_set_radius, OPEN_RADIUS, CLOSED_RADIUS, close_time)
	await t.finished


func open() -> void:
	var t := create_tween().set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN_OUT)
	t.tween_method(_set_radius, CLOSED_RADIUS, OPEN_RADIUS, open_time)
	await t.finished
