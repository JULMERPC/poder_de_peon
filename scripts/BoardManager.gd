extends Node2D
class_name BoardManager

signal tile_selected(tile: Tile)
signal piece_moved(from_tile: Tile, to_tile: Tile, piece: Piece)
signal piece_captured(piece: Piece, capturer: Piece)
signal invalid_move_attempted
signal check_detected(king: Piece)
signal checkmate_detected(winner_color: Piece.PieceColor)

const BOARD_SIZE = 8
const TILE_SIZE = Vector2(64, 64)
const PieceFactory = preload("res://scripts/pieces/PieceFactory.gd")


@export var board_offset: Vector2 = Vector2(100, 100)
@export var enable_piece_movement: bool = true

var tiles: Array[Array] = []
var selected_tile: Tile = null
var selected_piece: Piece = null
var valid_moves: Array[Tile] = []

var white_pieces: Array[Piece] = []
var black_pieces: Array[Piece] = []

var current_turn: Piece.PieceColor = Piece.PieceColor.WHITE
var move_history: Array = []

# Referencia a la escena de Tile
var tile_scene = preload("res://scenes/board/Tile.tscn")

func _ready():
	create_board()
	await get_tree().process_frame  # opcional pero recomendable para esperar a que el tablero se dibuje
	setup_standard_game()

func create_board():
	clear_board()
	
	tiles.resize(BOARD_SIZE)
	
	for x in range(BOARD_SIZE):
		tiles[x] = []
		tiles[x].resize(BOARD_SIZE)
		
		for y in range(BOARD_SIZE):
			var tile = create_tile(Vector2i(x, y))
			tiles[x][y] = tile
			add_child(tile)

func create_tile(grid_pos: Vector2i) -> Tile:
	var tile: Tile
	
	if tile_scene:
		tile = tile_scene.instantiate()
	else:
		tile = Tile.new()
	
	var is_light = (grid_pos.x + grid_pos.y) % 2 == 0
	tile.initialize(grid_pos, is_light)
	tile.position = board_offset + Vector2(grid_pos.x * TILE_SIZE.x, grid_pos.y * TILE_SIZE.y)
	
	tile.tile_clicked.connect(_on_tile_clicked)
	tile.tile_hovered.connect(_on_tile_hovered)
	
	return tile

func clear_board():
	# Limpiar piezas
	for piece in white_pieces + black_pieces:
		if is_instance_valid(piece):
			piece.queue_free()
	
	white_pieces.clear()
	black_pieces.clear()
	
	# Limpiar tiles
	for x in range(tiles.size()):
		if tiles[x]:
			for y in range(tiles[x].size()):
				if tiles[x][y]:
					tiles[x][y].queue_free()
	tiles.clear()

func get_tile(grid_pos: Vector2i) -> Tile:
	if is_valid_position(grid_pos):
		return tiles[grid_pos.x][grid_pos.y]
	return null

func is_valid_position(grid_pos: Vector2i) -> bool:
	return grid_pos.x >= 0 and grid_pos.x < BOARD_SIZE and grid_pos.y >= 0 and grid_pos.y < BOARD_SIZE

func _on_tile_clicked(tile: Tile):
	if not enable_piece_movement:
		return
	
	# Si hay una pieza seleccionada y clickeamos un movimiento válido
	if selected_piece and tile in valid_moves:
		execute_move(selected_tile, tile)
	# Si clickeamos una pieza del turno actual
	elif tile.has_piece() and tile.occupied_piece.piece_color == current_turn:
		select_piece(tile)
	# Si no, deseleccionar
	else:
		deselect_piece()

func _on_tile_hovered(tile: Tile):
	pass
	
	

func select_piece(tile: Tile):
	if not tile.has_piece():
		return
	
	var piece = tile.occupied_piece
	
	# Solo permitir seleccionar piezas del turno actual
	if piece.piece_color != current_turn:
		return
	
	# Deseleccionar anterior
	if selected_tile:
		deselect_piece()
	
	selected_tile = tile
	selected_piece = piece
	tile.select_tile(true)
	
	# Calcular y mostrar movimientos válidos
	calculate_valid_moves_for_piece(piece)
	show_valid_moves()
	
	tile_selected.emit(tile)

func deselect_piece():
	if selected_tile:
		selected_tile.select_tile(false)
		selected_tile = null
		selected_piece = null
	
	hide_valid_moves()
	valid_moves.clear()

func calculate_valid_moves_for_piece(piece: Piece):
	valid_moves.clear()
	
	if not piece or not piece.current_tile:
		return
	
	# Obtener movimientos legales de la pieza
	var legal_positions = piece.get_legal_moves(self)
	
	# Convertir posiciones a tiles
	for pos in legal_positions:
		var tile = get_tile(pos)
		if tile:
			valid_moves.append(tile)

func show_valid_moves():
	for tile in valid_moves:
		tile.show_valid_move(true)

func hide_valid_moves():
	for tile in valid_moves:
		tile.show_valid_move(false)

func execute_move(from_tile: Tile, to_tile: Tile):
	if not from_tile.has_piece():
		return
	
	var piece = from_tile.occupied_piece
	var captured_piece = null
	
	# Captura si hay pieza enemiga
	if to_tile.has_piece():
		captured_piece = to_tile.occupied_piece
		capture_piece(captured_piece, piece)
	
	# Mover la pieza
	from_tile.remove_piece()
	to_tile.set_piece(piece)
	piece.position = to_tile.position
	piece.has_moved = true
	
	# Guardar en historial
	move_history.append({
		"from": from_tile.grid_position,
		"to": to_tile.grid_position,
		"piece": piece,
		"captured": captured_piece,
		"turn": current_turn
	})
	
	# Emitir señal
	piece_moved.emit(from_tile, to_tile, piece)
	
	# Verificar promoción de peón
	if piece is Pawn:
		piece.check_promotion(self)
	
	# Verificar jaque/jaque mate
	check_for_check()
	
	# Cambiar turno
	switch_turn()
	
	# Deseleccionar
	deselect_piece()

func capture_piece(captured: Piece, capturer: Piece):
	# Remover de listas
	if captured.piece_color == Piece.PieceColor.WHITE:
		white_pieces.erase(captured)
	else:
		black_pieces.erase(captured)
	
	# Emitir señal
	piece_captured.emit(captured, capturer)
	
	# Eliminar pieza
	captured.die()

func switch_turn():
	current_turn = Piece.PieceColor.BLACK if current_turn == Piece.PieceColor.WHITE else Piece.PieceColor.WHITE

func check_for_check():
	# Encontrar los reyes
	var white_king = find_king(Piece.PieceColor.WHITE)
	var black_king = find_king(Piece.PieceColor.BLACK)
	
	if white_king and is_king_in_check(white_king):
		check_detected.emit(white_king)
		if is_checkmate(white_king):
			checkmate_detected.emit(Piece.PieceColor.BLACK)
	
	if black_king and is_king_in_check(black_king):
		check_detected.emit(black_king)
		if is_checkmate(black_king):
			checkmate_detected.emit(Piece.PieceColor.WHITE)

func find_king(color: Piece.PieceColor) -> Piece:
	var pieces = white_pieces if color == Piece.PieceColor.WHITE else black_pieces
	
	for piece in pieces:
		if piece.piece_type == Piece.PieceType.KING:
			return piece
	
	return null

func is_king_in_check(king: Piece) -> bool:
	if not king or not king.current_tile:
		return false
	
	var king_pos = king.current_tile.grid_position
	var enemy_pieces = black_pieces if king.piece_color == Piece.PieceColor.WHITE else white_pieces
	
	# Verificar si alguna pieza enemiga puede atacar al rey
	for enemy in enemy_pieces:
		if not enemy.is_alive or not enemy.current_tile:
			continue
		
		var enemy_moves = enemy.get_basic_moves(self)
		if king_pos in enemy_moves:
			return true
	
	return false

















# BoardManager.gd
func is_checkmate(king: Piece) -> bool:
	if not king.is_alive:
		return false
	
	# 1️⃣ Si el rey no está en jaque, no hay jaque mate
	if not is_in_check(king.piece_color):
		return false
	
	# 2️⃣ Verificar si el rey puede moverse a una casilla segura
	var legal_moves = king.get_basic_moves(self)
	for move in legal_moves:
		if not is_valid_position(move):
			continue
		
		var tile = get_tile(move)
		if tile.has_piece() and tile.occupied_piece.piece_color == king.piece_color:
			continue
		
		# Simular movimiento del rey
		var original_tile = king.current_tile
		var captured_piece = tile.occupied_piece if tile.has_piece() else null
		
		move_piece(king, move)
		var still_in_check = is_in_check(king.piece_color)
		
		# Revertir simulación
		move_piece(king, original_tile.grid_position)
		if captured_piece:
			place_piece_at(self, captured_piece, tile.grid_position)
		
		if not still_in_check:
			return false  # El rey puede escapar
	
	# 3️⃣ Si el rey no puede escapar, ver si alguna pieza aliada puede bloquear o capturar
	var attackers = get_attackers_of_king(king)
	if attackers.is_empty():
		return false
	
	# Solo se puede bloquear si hay un único atacante y no es un caballo
	if attackers.size() == 1:
		var attacker = attackers[0]
		
		# Obtener ruta entre atacante y rey
		var path = get_path_between(attacker.current_tile.grid_position, king.current_tile.grid_position)
		
		# Probar si alguna pieza aliada puede bloquear o capturar al atacante
		for piece in get_all_pieces_of_color(king.piece_color):
			if piece == king or not piece.is_alive:
				continue
			
			var moves = piece.get_basic_moves(self)
			for move in moves:
				# Puede capturar atacante directamente
				if move == attacker.current_tile.grid_position:
					if can_simulate_safe_move(piece, move, king.piece_color):
						return false
				
				# O puede bloquear la trayectoria (si aplica)
				if move in path:
					if can_simulate_safe_move(piece, move, king.piece_color):
						return false
	
	# 4️⃣ Si llegamos aquí, el rey no puede moverse ni ser defendido → JAQUE MATE
	return true







# Verifica si el color dado está en jaque
func is_in_check(color: Piece.PieceColor) -> bool:
	var king = get_king_of_color(color)
	if not king or not king.is_alive:
		return false
	
	for piece in get_all_pieces_of_color(opposite_color(color)):
		if not piece.is_alive:
			continue
		var moves = piece.get_basic_moves(self)
		if king.current_tile.grid_position in moves:
			return true
	return false


# Retorna todas las piezas que atacan al rey
func get_attackers_of_king(king: Piece) -> Array:
	var attackers: Array = []
	for piece in get_all_pieces_of_color(opposite_color(king.piece_color)):
		if not piece.is_alive:
			continue
		var moves = piece.get_basic_moves(self)
		if king.current_tile.grid_position in moves:
			attackers.append(piece)
	return attackers


# Simula un movimiento temporalmente y verifica si sigue en jaque
func can_simulate_safe_move(piece: Piece, target_pos: Vector2i, color: Piece.PieceColor) -> bool:
	var original_pos = piece.current_tile.grid_position
	var captured_piece = null
	var target_tile = get_tile(target_pos)
	if target_tile.has_piece():
		captured_piece = target_tile.occupied_piece
	
	move_piece(piece, target_pos)
	var still_in_check = is_in_check(color)
	move_piece(piece, original_pos)
	
	if captured_piece:
		place_piece_at(self, captured_piece, target_pos)
	
	return not still_in_check


# Retorna todos los cuadros entre dos posiciones (excluyendo ambos)
func get_path_between(start: Vector2i, end: Vector2i) -> Array:
	var path: Array = []
	var direction = (end - start).sign()
	var pos = start + direction
	while pos != end:
		path.append(pos)
		pos += direction
	return path


# Retorna el rey de un color
func get_king_of_color(color: Piece.PieceColor) -> Piece:
	for piece in get_all_pieces_of_color(color):
		if piece.piece_type == Piece.PieceType.KING and piece.is_alive:
			return piece
	return null


# Retorna todas las piezas de un color
func get_all_pieces_of_color(color: Piece.PieceColor) -> Array:
	var result: Array = []
	for child in get_children():
		if child is Piece and child.piece_color == color:
			result.append(child)
	return result


func opposite_color(color: Piece.PieceColor) -> Piece.PieceColor:
	return Piece.PieceColor.BLACK if color == Piece.PieceColor.WHITE else Piece.PieceColor.WHITE










func setup_standard_game():
	var pieces = PieceFactory.setup_standard_chess_board(self)
	var white_pieces = []
	var black_pieces = []

	current_turn = Piece.PieceColor.WHITE

func setup_survival_mode(round: int):
	var pieces = PieceFactory.setup_survival_mode(self, round)
	white_pieces = pieces["player"]
	black_pieces = pieces["enemies"]
	current_turn = Piece.PieceColor.WHITE

func get_board_center() -> Vector2:
	return board_offset + Vector2(BOARD_SIZE * TILE_SIZE.x / 2, BOARD_SIZE * TILE_SIZE.y / 2)

func apply_tile_effect(grid_pos: Vector2i, effect_type: String):
	var tile = get_tile(grid_pos)
	if tile:
		tile.apply_special_effect(effect_type)

func world_to_grid(world_pos: Vector2) -> Vector2i:
	var local_pos = world_pos - board_offset
	var grid_x = int(local_pos.x / TILE_SIZE.x)
	var grid_y = int(local_pos.y / TILE_SIZE.y)
	return Vector2i(grid_x, grid_y)

func grid_to_world(grid_pos: Vector2i) -> Vector2:
	return board_offset + Vector2(grid_pos.x * TILE_SIZE.x, grid_pos.y * TILE_SIZE.y)

func print_board_state():
	print("=== Estado del Tablero - Turno: %s ===" % ("Blancas" if current_turn == Piece.PieceColor.WHITE else "Negras"))
	for y in range(BOARD_SIZE):
		var row = ""
		for x in range(BOARD_SIZE):
			var tile = tiles[x][y]
			if tile.has_piece():
				var p = tile.occupied_piece
				var symbol = ""
				match p.piece_type:
					Piece.PieceType.PAWN:
						symbol = "P"
					Piece.PieceType.ROOK:
						symbol = "T"
					Piece.PieceType.KNIGHT:
						symbol = "C"
					Piece.PieceType.BISHOP:
						symbol = "A"
					Piece.PieceType.QUEEN:
						symbol = "D"
					Piece.PieceType.KING:
						symbol = "R"
				
				if p.piece_color == Piece.PieceColor.BLACK:
					symbol = symbol.to_lower()
				
				row += "[%s] " % symbol
			else:
				row += "[ ] "
		print(row)


# Mueve una pieza de una casilla a otra (actualiza la referencia del Tile)
func move_piece(piece: Piece, target_pos: Vector2i):
	if not is_valid_position(target_pos):
		push_warning("Intento de mover pieza a posición inválida: %s" % target_pos)
		return
	
	var origin_tile = piece.current_tile
	var target_tile = get_tile(target_pos)
	
	# Si hay una pieza enemiga, eliminarla (captura)
	if target_tile.has_piece():
		var captured_piece = target_tile.occupied_piece
		if captured_piece.piece_color != piece.piece_color:
			captured_piece.take_damage(captured_piece.current_health)
	
	# Actualizar referencias
	if origin_tile:
		origin_tile.clear_piece()
	
	target_tile.set_piece(piece)
	piece.current_tile = target_tile
	piece.position = target_tile.position


# Coloca una pieza en una posición del tablero (para restaurar simulaciones)
func place_piece_at(board: BoardManager, piece: Piece, grid_pos: Vector2i):
	var tile = board.get_tile(grid_pos)
	if not tile:
		push_error("No se pudo colocar pieza en posición inválida: %s" % grid_pos)
		return
	
	tile.set_piece(piece)
	piece.current_tile = tile
	piece.position = tile.position
