extends Piece
class_name Knight

var charge_active: bool = false

func _ready():
	super._ready()
	piece_type = PieceType.KNIGHT

func get_basic_moves(board: BoardManager) -> Array[Vector2i]:
	var moves: Array[Vector2i] = []
	var current_pos = current_tile.grid_position
	
	# Movimientos en L del caballo
	var knight_moves = [
		Vector2i(2, 1),   Vector2i(2, -1),
		Vector2i(-2, 1),  Vector2i(-2, -1),
		Vector2i(1, 2),   Vector2i(1, -2),
		Vector2i(-1, 2),  Vector2i(-1, -2)
	]
	
	# Si el poder de carga está activo, añadir movimientos extendidos
	if charge_active:
		knight_moves.append_array([
			Vector2i(3, 1),   Vector2i(3, -1),
			Vector2i(-3, 1),  Vector2i(-3, -1),
			Vector2i(1, 3),   Vector2i(1, -3),
			Vector2i(-1, 3),  Vector2i(-1, -3)
		])
	
	for move in knight_moves:
		var target_pos = current_pos + move
		
		if not board.is_valid_position(target_pos):
			continue
		
		var target_tile = board.get_tile(target_pos)
		
		# El caballo puede saltar sobre otras piezas
		if not target_tile.has_piece():
			moves.append(target_pos)
		elif can_capture_at(board, target_pos):
			moves.append(target_pos)
	
	return moves

# Poder especial: Carga (mueve +1 casilla)
func special_charge():
	charge_active = true
	# El efecto dura un turno
