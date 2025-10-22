extends Piece
class_name Bishop

func _ready():
	super._ready()
	piece_type = PieceType.BISHOP

func get_basic_moves(board: BoardManager) -> Array[Vector2i]:
	var moves: Array[Vector2i] = []
	
	# Movimientos en diagonales
	var directions = [
		Vector2i(1, 1),    # Diagonal superior derecha
		Vector2i(1, -1),   # Diagonal inferior derecha
		Vector2i(-1, 1),   # Diagonal superior izquierda
		Vector2i(-1, -1)   # Diagonal inferior izquierda
	]
	
	for direction in directions:
		moves.append_array(get_line_moves(board, direction))
	
	return moves

# El alfil tiene acceso directo al poder de curación
func get_healing_targets(board: BoardManager) -> Array[Vector2i]:
	var targets: Array[Vector2i] = []
	var current_pos = current_tile.grid_position
	
	var directions = [
		Vector2i(1, 1), Vector2i(1, -1),
		Vector2i(-1, 1), Vector2i(-1, -1)
	]
	
	for direction in directions:
		for i in range(1, 9):
			var target_pos = current_pos + (direction * i)
			
			if not board.is_valid_position(target_pos):
				break
			
			var tile = board.get_tile(target_pos)
			
			if tile.has_piece():
				if tile.occupied_piece.piece_color == piece_color:
					targets.append(target_pos)
				break
	
	return targets
