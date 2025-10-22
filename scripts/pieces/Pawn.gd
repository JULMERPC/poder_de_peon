extends Piece
class_name Pawn

var enemies_defeated: int = 0
var can_evolve: bool = false

func _ready():
	super._ready()
	piece_type = PieceType.PAWN

func get_basic_moves(board: BoardManager) -> Array[Vector2i]:
	var moves: Array[Vector2i] = []
	var current_pos = current_tile.grid_position
	
	# Dirección según color (blancas suben, negras bajan)
	var forward = -1 if piece_color == PieceColor.WHITE else 1
	
	# Movimiento simple hacia adelante
	var one_forward = current_pos + Vector2i(0, forward)
	if board.is_valid_position(one_forward) and is_empty_at(board, one_forward):
		moves.append(one_forward)
		
		# Movimiento doble desde posición inicial
		if not has_moved:
			var two_forward = current_pos + Vector2i(0, forward * 2)
			if board.is_valid_position(two_forward) and is_empty_at(board, two_forward):
				moves.append(two_forward)
	
	# Captura diagonal
	var diagonals = [
		current_pos + Vector2i(-1, forward),
		current_pos + Vector2i(1, forward)
	]
	
	for diagonal in diagonals:
		if board.is_valid_position(diagonal):
			if can_capture_at(board, diagonal):
				moves.append(diagonal)
			# TODO: Implementar en passant
	
	return moves

# Promoción del peón
func check_promotion(board: BoardManager):
	var target_row = 0 if piece_color == PieceColor.WHITE else 7
	
	if current_tile.grid_position.y == target_row:
		promote_to_queen(board)

func promote_to_queen(board: BoardManager):
	# Crear una nueva reina en la posición actual
	var queen = preload("res://scripts/pieces/Queen.gd").new()
	queen.initialize(PieceType.QUEEN, piece_color, board)
	queen.position = position
	queen.current_tile = current_tile
	
	# Reemplazar en el tablero
	current_tile.occupied_piece = queen
	get_parent().add_child(queen)
	
	# Eliminar peón
	queue_free()

# Poder especial: Evolución temprana
func special_pawn_evolution():
	enemies_defeated += 1
	if enemies_defeated >= 2:
		can_evolve = true

func on_capture_enemy():
	enemies_defeated += 1
	if enemies_defeated >= 2 and not has_moved:
		can_evolve = true
