extends Piece
class_name King

var is_in_check: bool = false

func _ready():
	super._ready()
	piece_type = PieceType.KING

func get_basic_moves(board: BoardManager) -> Array[Vector2i]:
	var moves: Array[Vector2i] = []
	var current_pos = current_tile.grid_position
	
	# El rey se mueve una casilla en cualquier dirección
	var directions = [
		Vector2i(1, 0),   Vector2i(-1, 0),
		Vector2i(0, 1),   Vector2i(0, -1),
		Vector2i(1, 1),   Vector2i(1, -1),
		Vector2i(-1, 1),  Vector2i(-1, -1)
	]
	
	for direction in directions:
		var target_pos = current_pos + direction
		
		if not board.is_valid_position(target_pos):
			continue
		
		var target_tile = board.get_tile(target_pos)
		
		if not target_tile.has_piece():
			moves.append(target_pos)
		elif can_capture_at(board, target_pos):
			moves.append(target_pos)
	
	# Enroque (castling)
	if not has_moved and not is_in_check:
		moves.append_array(get_castling_moves(board))
	
	return moves

func get_castling_moves(board: BoardManager) -> Array[Vector2i]:
	var castling_moves: Array[Vector2i] = []
	var current_pos = current_tile.grid_position
	
	# Enroque corto (lado del rey, derecha para blancas)
	var kingside_rook_pos = Vector2i(7, current_pos.y)
	if can_castle_kingside(board, kingside_rook_pos):
		castling_moves.append(Vector2i(current_pos.x + 2, current_pos.y))
	
	# Enroque largo (lado de la dama, izquierda para blancas)
	var queenside_rook_pos = Vector2i(0, current_pos.y)
	if can_castle_queenside(board, queenside_rook_pos):
		castling_moves.append(Vector2i(current_pos.x - 2, current_pos.y))
	
	return castling_moves

func can_castle_kingside(board: BoardManager, rook_pos: Vector2i) -> bool:
	if not board.is_valid_position(rook_pos):
		return false
	
	var rook_tile = board.get_tile(rook_pos)
	if not rook_tile.has_piece():
		return false
	
	var rook = rook_tile.occupied_piece
	if rook.piece_type != PieceType.ROOK or rook.has_moved:
		return false
	
	# Verificar que las casillas entre el rey y la torre estén vacías
	var current_pos = current_tile.grid_position
	for x in range(current_pos.x + 1, rook_pos.x):
		var tile = board.get_tile(Vector2i(x, current_pos.y))
		if tile.has_piece():
			return false
		# TODO: Verificar que no esté bajo ataque
	
	return true

func can_castle_queenside(board: BoardManager, rook_pos: Vector2i) -> bool:
	if not board.is_valid_position(rook_pos):
		return false
	
	var rook_tile = board.get_tile(rook_pos)
	if not rook_tile.has_piece():
		return false
	
	var rook = rook_tile.occupied_piece
	if rook.piece_type != PieceType.ROOK or rook.has_moved:
		return false
	
	# Verificar que las casillas entre el rey y la torre estén vacías
	var current_pos = current_tile.grid_position
	for x in range(rook_pos.x + 1, current_pos.x):
		var tile = board.get_tile(Vector2i(x, current_pos.y))
		if tile.has_piece():
			return false
		# TODO: Verificar que no esté bajo ataque
	
	return true

func perform_castling(board: BoardManager, target_pos: Vector2i):
	var current_pos = current_tile.grid_position
	var is_kingside = target_pos.x > current_pos.x
	
	# Mover torre
	var rook_pos = Vector2i(7 if is_kingside else 0, current_pos.y)
	var rook_target = Vector2i(target_pos.x - 1 if is_kingside else target_pos.x + 1, current_pos.y)
	
	var rook_tile = board.get_tile(rook_pos)
	var rook = rook_tile.remove_piece()
	
	var rook_target_tile = board.get_tile(rook_target)
	rook_target_tile.set_piece(rook)
	rook.position = rook_target_tile.position

# Poder especial: Comando Real (permite movimiento extra a un aliado)
func get_command_targets(board: BoardManager) -> Array[Piece]:
	var targets: Array[Piece] = []
	var current_pos = current_tile.grid_position
	
	# Buscar aliados en un radio de 2 casillas
	for x in range(-2, 3):
		for y in range(-2, 3):
			if x == 0 and y == 0:
				continue
			
			var target_pos = current_pos + Vector2i(x, y)
			if not board.is_valid_position(target_pos):
				continue
			
			var tile = board.get_tile(target_pos)
			if tile.has_piece() and tile.occupied_piece.piece_color == piece_color:
				targets.append(tile.occupied_piece)
	
	return targets

func check_if_in_check(board: BoardManager) -> bool:
	# TODO: Implementar detección de jaque
	# Verificar si alguna pieza enemiga puede atacar al rey
	return false
