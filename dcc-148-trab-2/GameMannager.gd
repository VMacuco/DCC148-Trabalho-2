extends Node

var maxHP : int = 10
var HP : int = 10
var SavePoint := Vector2.ZERO
var SavePoint_Scene := " "
var Checkpoint := Vector2.ZERO
signal respawn_player
var is_player_dead: bool = false
var has_save_poit: bool = false
var has_check_poin: bool = false
var pending_spawn: bool = false

func _ready() -> void:
	HP = maxHP

func set_SavePoint(pos: Vector2, scene_path: String)->void:
	SavePoint = pos
	SavePoint_Scene = scene_path
	has_save_poit = true
	print("Ponto de salvamento")

func take_damage(damage: float = 1.0) -> void:
	HP -= damage
	if HP <= 0.0:
		HP = maxHP
		print("morreu")
		is_player_dead = true
	_respawn()

func _respawn()->void:
	if is_player_dead:
		is_player_dead = false
		if has_save_poit:
			Checkpoint = SavePoint
			var current := get_tree().current_scene.scene_file_path
			if SavePoint_Scene != current:
				pending_spawn = true
				get_tree().change_scene_to_file(SavePoint_Scene)
				return
	respawn_player.emit()
			
			
			
			
			
