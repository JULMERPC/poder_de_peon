extends Node
class_name PieceFactory

# Precargar todas las clases de piezas
const PIECE_SCRIPTS = {
	Piece.PieceType.PAWN: preload("res://scripts/pieces/Pawn.gd"),
	Piece.PieceType.ROOK: preload("res://scripts/pieces/Rook.gd"),
	Piece.PieceType.KNIGHT: preload("res://scripts/pieces/Knight.gd"),
	Piece.PieceType.BISHOP: preload("res://scripts/pieces/Bishop.gd"),
	Piece.PieceType.QUEEN: preload("res://scripts/pieces/Queen.gd"),
	Piece.PieceType.KING: preload("res://scripts/pieces/King.gd")
}

# Sprites por defecto (reemplazar con tus sprites reales)
const PIECE_SPRITES = {
	"white_pawn": "res://assets/sprites/pieces/white_pawn.png",
	"white_rook": "res://assets/sprites/pieces/white_rook.png",
	"white_knight": "res://assets/sprites/pieces/white_knight.png",
	"white_bishop": "res://assets/sprites/pieces/white_bishop.png",
	"white_queen": "res://assets/sprites/pieces/white_queen.png",
	"white_king": "res://assets/sprites/pieces/white_king.png",
	"black_pawn": "res://assets/sprites/pieces/black_pawn.png",
	"black_rook": "res://assets/sprites/pieces/black_rook.png",
	"black_knight": "res://assets/sprites/pieces/black_knight.png",
	"black_bishop": "res://assets/sprites/pieces/black_bishop.png",
	"black_queen": "res://assets/sprites/pieces/black_queen.png",
	"black_king": "res://assets/sprites/pieces/black_king.png"
}

static func create_piece(type: Piece.PieceType, color: Piece.PieceColor, board: BoardManager) -> Piece:
	var piece_script = PIECE_SCRIPTS.get(type)
	
	if not piece_script:
		push_error("No se encontró script para el tipo de pieza: %s" % type)
		return null
	
	# Crear instancia de la pieza
	var piece: Piece = piece_script.new()
	
	# Inicializar la pieza
	piece.initialize(type, color, board)
	
	# Configurar sprite
	setup_piece_sprite(piece, type, color)
	
	return piece

static func setup_piece_sprite(piece: Piece, type: Piece.PieceType, color: Piece.PieceColor):
	# Crear nodo Sprite2D si no existe
	if not piece.has_node("Sprite2D"):
		var sprite = Sprite2D.new()
		sprite.name = "Sprite2D"
		piece.add_child(sprite)
	
	# Crear HealthBar si no existe
	if not piece.has_node("HealthBar"):
		var health_bar = ProgressBar.new()
		health_bar.name = "HealthBar"
		health_bar.position = Vector2(-20, -35)
		health_bar.size = Vector2(40, 5)
		health_bar.visible = false
		piece.add_child(health_bar)
	
	var sprite = piece.get_node("Sprite2D")
	
	# Cargar sprite correspondiente
	var sprite_key = get_sprite_key(type, color)
	var sprite_path = PIECE_SPRITES.get(sprite_key)
	
	if sprite_path and ResourceLoader.exists(sprite_path):
		sprite.texture = load(sprite_path)
	else:
		# Si no existe el sprite, crear textura por defecto
		sprite.texture = create_default_piece_texture(type, color)
	
	# Centrar el sprite
	sprite.centered = true

static func get_sprite_key(type: Piece.PieceType, color: Piece.PieceColor) -> String:
	var color_str = "white" if color == Piece.PieceColor.WHITE else "black"
	var type_str = ""
	
	match type:
		Piece.PieceType.PAWN:
			type_str = "pawn"
		Piece.PieceType.ROOK:
			type_str = "rook"
		Piece.PieceType.KNIGHT:
			type_str = "knight"
		Piece.PieceType.BISHOP:
			type_str = "bishop"
		Piece.PieceType.QUEEN:
			type_str = "queen"
		Piece.PieceType.KING:
			type_str = "king"
	
	return "%s_%s" % [color_str, type_str]

static func create_default_piece_texture(type: Piece.PieceType, color: Piece.PieceColor) -> ImageTexture:
	# Crear una textura simple con el símbolo de la pieza
	var size = 48
	var image = Image.create(size, size, false, Image.FORMAT_RGBA8)
	
	# Color de fondo
	var bg_color = Color(0.9, 0.9, 0.9) if color == Piece.PieceColor.WHITE else Color(0.2, 0.2, 0.2)
	image.fill(bg_color)
	
	# Agregar borde
	var border_color = Color(0.1, 0.1, 0.1) if color == Piece.PieceColor.WHITE else Color(0.8, 0.8, 0.8)
	
	# Dibujar borde simple
	for i in range(size):
		image.set_pixel(i, 0, border_color)
		image.set_pixel(i, size - 1, border_color)
		image.set_pixel(0, i, border_color)
		image.set_pixel(size - 1, i, border_color)
	
	return ImageTexture.create_from_image(image)

# Configuración inicial estándar de ajedrez
static func setup_standard_chess_board(board: BoardManager) -> Dictionary:
	var pieces = {
		"white": [],
		"black": []
	}
	
	# Peones blancos (fila 6)
	for x in range(8):
		var pawn = create_piece(Piece.PieceType.PAWN, Piece.PieceColor.WHITE, board)
		place_piece_at(board, pawn, Vector2i(x, 6))
		pieces["white"].append(pawn)
	
	# Peones negros (fila 1)
	for x in range(8):
		var pawn = create_piece(Piece.PieceType.PAWN, Piece.PieceColor.BLACK, board)
		place_piece_at(board, pawn, Vector2i(x, 1))
		pieces["black"].append(pawn)
	
	# Piezas blancas (fila 7)
	var white_back_row = [
		Piece.PieceType.ROOK, Piece.PieceType.KNIGHT, Piece.PieceType.BISHOP, Piece.PieceType.QUEEN,
		Piece.PieceType.KING, Piece.PieceType.BISHOP, Piece.PieceType.KNIGHT, Piece.PieceType.ROOK
	]
	
	for x in range(8):
		var piece = create_piece(white_back_row[x], Piece.PieceColor.WHITE, board)
		place_piece_at(board, piece, Vector2i(x, 7))
		pieces["white"].append(piece)
	
	# Piezas negras (fila 0)
	var black_back_row = [
		Piece.PieceType.ROOK, Piece.PieceType.KNIGHT, Piece.PieceType.BISHOP, Piece.PieceType.QUEEN,
		Piece.PieceType.KING, Piece.PieceType.BISHOP, Piece.PieceType.KNIGHT, Piece.PieceType.ROOK
	]
	
	for x in range(8):
		var piece = create_piece(black_back_row[x], Piece.PieceColor.BLACK, board)
		place_piece_at(board, piece, Vector2i(x, 0))
		pieces["black"].append(piece)
	
	return pieces

static func place_piece_at(board: BoardManager, piece: Piece, grid_pos: Vector2i):
	var tile = board.get_tile(grid_pos)
	if not tile:
		push_error("No se pudo colocar pieza en posición inválida: %s" % grid_pos)
		return
	
	# Colocar pieza en el tablero
	tile.set_piece(piece)
	board.add_child(piece)
	piece.position = tile.position

# Crear configuración personalizada para modo supervivencia
static func setup_survival_mode(board: BoardManager, round: int) -> Dictionary:
	var pieces = {
		"player": [],
		"enemies": []
	}
	
	# Jugador empieza con piezas limitadas
	var player_pieces = [
		{"type": Piece.PieceType.KING, "pos": Vector2i(4, 7)},
		{"type": Piece.PieceType.PAWN, "pos": Vector2i(3, 6)},
		{"type": Piece.PieceType.PAWN, "pos": Vector2i(4, 6)},
		{"type": Piece.PieceType.PAWN, "pos": Vector2i(5, 6)}
	]
	
	# Añadir más piezas según el progreso
	if round >= 3:
		player_pieces.append({"type": Piece.PieceType.KNIGHT, "pos": Vector2i(2, 7)})
	if round >= 5:
		player_pieces.append({"type": Piece.PieceType.BISHOP, "pos": Vector2i(5, 7)})
	
	for piece_data in player_pieces:
		var piece = create_piece(piece_data["type"], Piece.PieceColor.WHITE, board)
		place_piece_at(board, piece, piece_data["pos"])
		pieces["player"].append(piece)
	
	# Generar enemigos según la ronda
	var enemy_count = 3 + round
	for i in range(enemy_count):
		var x = randi() % 8
		var y = randi() % 3  # Enemigos en las primeras 3 filas
		
		var enemy_type = Piece.PieceType.PAWN
		if randf() > 0.7:
			enemy_type = [Piece.PieceType.KNIGHT, Piece.PieceType.BISHOP, Piece.PieceType.ROOK].pick_random()
		
		var enemy = create_piece(enemy_type, Piece.PieceColor.BLACK, board)
		place_piece_at(board, enemy, Vector2i(x, y))
		pieces["enemies"].append(enemy)
	
	return pieces
