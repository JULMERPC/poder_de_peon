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

















func is_checkmate(king: Piece) -> bool:
	# TODO: Implementar detección completa de jaque mate
	# Verificar si el rey puede moverse o si alguna pieza puede bloquear/capturar
	return false



















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
