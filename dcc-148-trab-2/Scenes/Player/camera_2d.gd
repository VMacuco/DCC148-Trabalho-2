extends Camera2D

@export var tile_size := 16.0
@export var max_tiles := 3
@export var camera_speed := 200.0
@export var return_speed := 300.0
@export var return_on_realease = true

var base_offset = Vector2.ZERO

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	base_offset = offset


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	var dir = Input.get_vector("camera_esq","camera_dir","camera_cima","camera_baixo").normalized()
	var limit = tile_size * max_tiles
	var extra = offset - base_offset
	
	if dir != Vector2.ZERO:
		extra += dir * camera_speed * delta
		extra.x = clampf(extra.x, -limit, limit)
		extra.y = clampf(extra.y, -limit, limit)
	elif return_on_realease:
		extra = extra.move_toward(Vector2.ZERO, return_speed * delta)
	offset = base_offset + extra
		
	
