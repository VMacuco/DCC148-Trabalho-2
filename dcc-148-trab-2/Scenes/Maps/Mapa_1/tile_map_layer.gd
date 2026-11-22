extends TileMapLayer

@export_flags_2d_physics var layer_dano: int = 64 # 64 = Layer 7 (Mask da Hurtbox do Player)
@export var indice_physics_layer_espinho: int = 1 # Element 1 do TileSet

func _ready() -> void:
	var area_espinhos := Area2D.new()
	area_espinhos.name = "AreaEspinhos"
	area_espinhos.collision_layer = layer_dano
	area_espinhos.collision_mask = 0
	add_child(area_espinhos)
	
	for celula in get_used_cells():
		var dados := get_cell_tile_data(celula)
		if not dados:
			continue
			
		var qtd_poligonos := dados.get_collision_polygons_count(indice_physics_layer_espinho)
		if qtd_poligonos == 0:
			continue
			
		# Respeita espelhamento (flip_h / flip_v) e rotação feitos na pintura do mapa
		var rot_flip := Transform2D.IDENTITY
		if is_cell_flipped_h(celula):
			rot_flip = rot_flip.scaled(Vector2(-1, 1))
		if is_cell_flipped_v(celula):
			rot_flip = rot_flip.scaled(Vector2(1, -1))
		if is_cell_transposed(celula):
			rot_flip = Transform2D(Vector2(0, 1), Vector2(1, 0), Vector2.ZERO) * rot_flip
			
		for i in qtd_poligonos:
			var pontos := dados.get_collision_polygon_points(indice_physics_layer_espinho, i)
			var col_poly := CollisionPolygon2D.new()
			col_poly.polygon = pontos
			col_poly.transform = Transform2D(0.0, map_to_local(celula)) * rot_flip
			area_espinhos.add_child(col_poly)
