extends Piece
class_name Rook

func _ready():
	super._ready()
	piece_type = PieceType.ROOK

func get_basic_moves(board: BoardManager) -> Array[Vector2i]:
	var moves: Array[Vector2i] = []
	
	# Movimientos en líneas rectas (horizontal y vertical)
	var directions = [
		Vector2i(1, 0),   # Derecha
		Vector2i(-1, 0),  # Izquierda
		Vector2i(0, 1),   # Abajo
		Vector2i(0, -1)   # Arriba
	]
	
	for direction in directions:
		moves.append_array(get_line_moves(board, direction))
	
	return moves
