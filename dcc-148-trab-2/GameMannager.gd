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
signal Health_change
signal Player_Death
var current_level : int
var final_level := 4

func _ready() -> void:
	HP = maxHP
	Health_change.emit(HP, maxHP)

func set_SavePoint(pos: Vector2, scene_path: String)->void:
	SavePoint = pos
	SavePoint_Scene = scene_path
	has_save_poit = true
	print("Ponto de salvamento")

func take_damage(damage: float = 1.0) -> void:
	if is_player_dead or LevelMannager.changing:
		return
	HP -= damage
	Health_change.emit(HP, maxHP)
	if HP <= 0.0:
		death_sequence()
	else:
		respawn_player.emit()

func death_sequence()->void:
	is_player_dead = true
	Player_Death.emit()
	await Death_Transition.close()
	
	HP = maxHP
	Health_change.emit(HP, maxHP)
	
	var change = false
	if has_save_poit:
		Checkpoint = SavePoint
		if SavePoint_Scene != get_tree().current_scene.scene_file_path:
			pending_spawn = true
			change = true
			get_tree().change_scene_to_file(SavePoint_Scene)
			await get_tree().process_frame
			await get_tree().process_frame 
	if not change:
		respawn_player.emit()
	is_player_dead = false
	await Death_Transition.open()

func _respawn()->void: # não está sendo mais usada
	if is_player_dead:
		Player_Death.emit()
		is_player_dead = false
		if has_save_poit:
			Checkpoint = SavePoint
			var current := get_tree().current_scene.scene_file_path
			if SavePoint_Scene != current:
				pending_spawn = true
				get_tree().change_scene_to_file(SavePoint_Scene)
				return
	respawn_player.emit()

func _change_level() -> void:
	current_level += 1
	LevelMannager.change_level(current_level)

func start_game() -> void:
	current_level = 1
	LevelMannager.change_level(current_level)
	Hud.show()
