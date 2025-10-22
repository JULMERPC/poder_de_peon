extends Piece
class_name Queen

func _ready():
	super._ready()
	piece_type = PieceType.QUEEN

func get_basic_moves(board: BoardManager) -> Array[Vector2i]:
	var moves: Array[Vector2i] = []
	
	# La reina combina movimientos de torre y alfil
	var directions = [
		# Movimientos de torre (horizontal/vertical)
		Vector2i(1, 0),   Vector2i(-1, 0),
		Vector2i(0, 1),   Vector2i(0, -1),
		# Movimientos de alfil (diagonal)
		Vector2i(1, 1),   Vector2i(1, -1),
		Vector2i(-1, 1),  Vector2i(-1, -1)
	]
	
	for direction in directions:
		moves.append_array(get_line_moves(board, direction))
	
	return moves

# Poder especial: Tormenta mágica (ataca toda una línea)
func special_magic_storm(board: BoardManager):
	var current_pos = current_tile.grid_position
	
	# Elegir una dirección aleatoria o la más beneficiosa
	var directions = [
		Vector2i(1, 0), Vector2i(-1, 0),
		Vector2i(0, 1), Vector2i(0, -1),
		Vector2i(1, 1), Vector2i(1, -1),
		Vector2i(-1, 1), Vector2i(-1, -1)
	]
	
	# Atacar en todas las direcciones
	for direction in directions:
		for i in range(1, 9):
			var target_pos = current_pos + (direction * i)
			
			if not board.is_valid_position(target_pos):
				break
			
			var tile = board.get_tile(target_pos)
			
			if tile.has_piece():
				if tile.occupied_piece.piece_color != piece_color:
					tile.occupied_piece.take_damage(attack_power)
				break

func get_storm_affected_tiles(board: BoardManager) -> Array[Vector2i]:
	var affected: Array[Vector2i] = []
	var current_pos = current_tile.grid_position
	
	var directions = [
		Vector2i(1, 0), Vector2i(-1, 0),
		Vector2i(0, 1), Vector2i(0, -1),
		Vector2i(1, 1), Vector2i(1, -1),
		Vector2i(-1, 1), Vector2i(-1, -1)
	]
	
	for direction in directions:
		for i in range(1, 9):
			var target_pos = current_pos + (direction * i)
			
			if not board.is_valid_position(target_pos):
				break
			
			affected.append(target_pos)
			
			var tile = board.get_tile(target_pos)
			if tile.has_piece():
				break
	
	return affected
