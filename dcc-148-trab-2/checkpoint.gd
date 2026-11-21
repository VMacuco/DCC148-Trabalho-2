class_name Check_Point
extends Area2D

@export var SavePoint: bool = false
@export var spawnPoint: Marker2D


func _on_body_entered(body: Node2D) -> void:
	if body is Player:
		print("Player entrou na area de salvamento")
		var pos := spawnPoint.global_position if spawnPoint else global_position
		if SavePoint:
			var scene_path := get_tree().current_scene.scene_file_path
			GameMannager.set_SavePoint(pos, scene_path)
		GameMannager.Checkpoint = pos
