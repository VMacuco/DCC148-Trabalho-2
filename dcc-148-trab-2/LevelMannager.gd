extends Node

signal level_changed(index: int)

const LEVELS := {
	1: "res://Scenes/Maps/Mapa_Tutorial.tscn",
	2: "res://Scenes/Maps/Mapa_1/mapa_1.tscn",
	3: "res://Scenes/Maps/F3/e.tscn",
	4: "res://Scenes/Maps/mapa4.tscn"
}
const END_SCENE := "Cena dos créditos" 

var current_level := 1
var changing := false


func complete_level() -> void:
	change_level(current_level + 1)


func change_level(index: int) -> void:
	if changing:
		return   

	var path: String = LEVELS.get(index, "")
	if path == "":
		if index > LEVELS.size():
			path = END_SCENE
		else:
			push_warning("Fase %d não existe em LEVELS" % index)
			return

	changing = true
	await Death_Transition.close()

	current_level = index
	_reset_level_state()

	get_tree().change_scene_to_file(path)
	await get_tree().process_frame
	await get_tree().process_frame 

	level_changed.emit(index)
	await Death_Transition.open()
	changing = false


func _reset_level_state() -> void:
	GameMannager.has_save_poit = false
	GameMannager.SavePoint = Vector2.ZERO
	GameMannager.SavePoint_Scene = ""
	GameMannager.pending_spawn = false
	GameMannager.HP = GameMannager.maxHP
	GameMannager.Health_change.emit(GameMannager.HP, GameMannager.maxHP)
	LevelGraph.reset()
