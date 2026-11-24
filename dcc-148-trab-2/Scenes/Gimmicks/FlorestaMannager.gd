extends Node

signal graph_changed

var used := {}        # círculos ativados: "a", "b", "c"
var arrival := ""

var salas := {
	"e": "res://Scenes/Maps/f3/e.tscn", "a": "res://Scenes/Maps/f3/a.tscn",
	"b": "res://Scenes/Maps/f3/b.tscn", "c": "res://Scenes/Maps/f3/c.tscn",
	"s": "res://Scenes/Maps/f3/s.tscn", "l": "res://Scenes/Maps/f3/l.tscn",
}

const BASE := {
	"e:1": "a", "e:2": "e",
	"a:1": "e", "a:2": "c", "a:3": "a",
	"c:1": "a", "c:2": "s", "c:3": "e",
	"s:1": "b", "s:2": "e", "s:3": "c",
	"b:1": "s", "b:2": "c", "b:3": "b",
}

# "" = porta selada
const OVERRIDES := {
	"a": {"a:1": "b", "a:2": "e", "a:3": ""},
	"c": {"c:1": "l", "c:2": "s", "c:3": ""},
	"b": {"b:1": "s", "b:2": "a", "b:3": "",
		  "s:1": "c", "s:2": "b", "s:3": ""},
}


func get_links(used_set: Dictionary = used) -> Dictionary:
	var links := BASE.duplicate()
	for circle in used_set:
		links.merge(OVERRIDES[circle], true)
	if used_set.size() < 3:
		for k in links.keys():
			if links[k] == "l":
				links[k] = ""   # livro só abre com os 3 círculos
	for k in links.keys():
		if links[k] == "":
			links.erase(k)
	return links


func door_active(key: String) -> bool:
	return get_links().has(key)


func activate(circle: String) -> void:
	used[circle] = true
	graph_changed.emit()


func travel(key: String) -> void:
	var links := get_links()
	if not links.has(key):
		return
	var dest: String = links[key]
	arrival = "entrada"
	get_tree().change_scene_to_file(salas[dest])


func reset() -> void:   # chame ao iniciar um novo jogo
	used.clear()
	arrival = ""
