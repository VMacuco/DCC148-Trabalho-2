extends CanvasLayer

@export var Heart_full : Texture2D
@export var Heart_half : Texture2D
@export var Heart_empty : Texture2D

@export var Heart_size:= Vector2(32,32)

@onready var container := $MarginContainer/HBoxContainer

var hearts : Array[TextureRect] = []

func _ready() -> void:
	GameMannager.Health_change.connect(update_hud)
	update_hud(GameMannager.HP, GameMannager.maxHP)

func update_hud(hp: int, maxHP: int) -> void:
	var total_hearts = ceili(maxHP/2)
	create_hearts(total_hearts)
	
	for i in total_hearts:
		var current = hp - i * 2
		if current >= 2:
			hearts[i].texture = Heart_full
		elif current == 1:
			hearts[i].texture = Heart_half
		else:
			hearts[i].texture = Heart_empty

func create_hearts (n: int) -> void:
	while hearts.size() < n:
		var heart := TextureRect.new()
		heart.custom_minimum_size = Heart_size
		heart.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		heart.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		heart.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
		container.add_child(heart)
		hearts.append(heart)
