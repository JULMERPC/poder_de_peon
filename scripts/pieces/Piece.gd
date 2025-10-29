extends Node2D
class_name Piece

signal piece_selected(piece: Piece)
signal piece_died(piece: Piece)

enum PieceType {
	PAWN,
	ROOK,
	KNIGHT,
	BISHOP,
	QUEEN,
	KING
}

enum PieceColor {
	WHITE,
	BLACK
}

@export var piece_type: PieceType
@export var piece_color: PieceColor
@export var max_health: int = 1
@export var attack_power: int = 1

var current_health: int
var current_tile: Tile = null
var has_moved: bool = false
var is_alive: bool = true
var board_manager: BoardManager = null

# Para poderes especiales
var special_power_cooldown: int = 0
var special_power_ready: bool = true

@onready var sprite: Sprite2D = $Sprite2D
@onready var health_bar: ProgressBar = $HealthBar

func _ready():
	current_health = max_health
	update_visuals()

func initialize(type: PieceType, color: PieceColor, board: BoardManager):
	piece_type = type
	piece_color = color
	board_manager = board
	current_health = max_health
	update_visuals()

#func update_visuals():
	#if sprite:
		## Aquí cargarías los sprites reales
		## Por ahora usamos colores para diferenciar
		#match piece_color:
			#PieceColor.WHITE:
				#sprite.modulate = Color.WHITE
			#PieceColor.BLACK:
				#sprite.modulate = Color(0.3, 0.3, 0.3)
	#
	#if health_bar and max_health > 1:
		#health_bar.visible = true
		#health_bar.max_value = max_health
		#health_bar.value = current_health
	#elif health_bar:
		#health_bar.visible = false
func update_visuals():
	if sprite:
		# Escalar automáticamente al tamaño de la casilla
		if board_manager:
			var tile_size = board_manager.TILE_SIZE
			var tex_size = sprite.texture.get_size()
			var scale_factor = tile_size.x / tex_size.x
			sprite.scale = Vector2(scale_factor, scale_factor)
		
		# Colorear según el color
		match piece_color:
			PieceColor.WHITE:
				sprite.modulate = Color.WHITE
			PieceColor.BLACK:
				sprite.modulate = Color(0.82, 0.749, 0.0, 1.0)

# Método principal para calcular movimientos legales
func get_legal_moves(board: BoardManager) -> Array[Vector2i]:
	var moves: Array[Vector2i] = []
	
	if not current_tile or not is_alive:
		return moves
	
	# Obtener movimientos básicos según el tipo de pieza
	var basic_moves = get_basic_moves(board)
	
	# Filtrar movimientos que pondrían al rey en jaque
	for move in basic_moves:
		if is_move_legal(board, move):
			moves.append(move)
	
	return moves

# Método virtual - cada pieza lo sobrescribe
func get_basic_moves(board: BoardManager) -> Array[Vector2i]:
	var moves: Array[Vector2i] = []
	return moves

# Verificar si un movimiento es legal (no pone al rey en jaque)
func is_move_legal(board: BoardManager, target_pos: Vector2i) -> bool:
	# TODO: Implementar verificación de jaque
	# Por ahora, retorna true para todos los movimientos básicos
	return true

# Métodos de utilidad para calcular movimientos
func get_line_moves(board: BoardManager, direction: Vector2i, max_distance: int = 8) -> Array[Vector2i]:
	var moves: Array[Vector2i] = []
	var current_pos = current_tile.grid_position
	
	for i in range(1, max_distance + 1):
		var target_pos = current_pos + (direction * i)
		
		if not board.is_valid_position(target_pos):
			break
		
		var target_tile = board.get_tile(target_pos)
		
		if target_tile.has_piece():
			# Si es enemigo, podemos capturar
			if target_tile.occupied_piece.piece_color != piece_color:
				moves.append(target_pos)
			break
		else:
			moves.append(target_pos)
	
	return moves

func can_capture_at(board: BoardManager, pos: Vector2i) -> bool:
	if not board.is_valid_position(pos):
		return false
	
	var tile = board.get_tile(pos)
	if not tile.has_piece():
		return false
	
	return tile.occupied_piece.piece_color != piece_color

func is_enemy_at(board: BoardManager, pos: Vector2i) -> bool:
	return can_capture_at(board, pos)

func is_empty_at(board: BoardManager, pos: Vector2i) -> bool:
	if not board.is_valid_position(pos):
		return false
	
	var tile = board.get_tile(pos)
	return not tile.has_piece()

# Sistema de combate
func take_damage(damage: int):
	current_health -= damage
	update_visuals()
	
	if current_health <= 0:
		die()

func die():
	is_alive = false
	piece_died.emit(self)
	# Animación de muerte aquí
	queue_free()

func heal(amount: int):
	current_health = min(current_health + amount, max_health)
	update_visuals()

# Método para aplicar poder especial
func use_special_power(board: BoardManager, target_pos: Vector2i = Vector2i(-1, -1)):
	if not special_power_ready:
		return
	
	match piece_type:
		PieceType.PAWN:
			special_pawn_evolution()
		PieceType.ROOK:
			special_sacred_shield(board)
		PieceType.BISHOP:
			special_healing(board, target_pos)
		PieceType.KNIGHT:
			special_charge()
		PieceType.QUEEN:
			special_magic_storm(board)
		PieceType.KING:
			special_royal_command(board, target_pos)
	
	special_power_cooldown = 3
	special_power_ready = false

# Poderes especiales según el GDD
func special_pawn_evolution():
	# El peón evoluciona si derrota 2 enemigos
	pass

func special_sacred_shield(board: BoardManager):
	# Torre protege aliados adyacentes
	var adjacents = [
		Vector2i(1, 0), Vector2i(-1, 0),
		Vector2i(0, 1), Vector2i(0, -1)
	]
	
	for dir in adjacents:
		var pos = current_tile.grid_position + dir
		if board.is_valid_position(pos):
			var tile = board.get_tile(pos)
			if tile.has_piece() and tile.occupied_piece.piece_color == piece_color:
				tile.occupied_piece.max_health += 1
				tile.occupied_piece.heal(1)

func special_healing(board: BoardManager, target_pos: Vector2i):
	# Alfil restaura vida a pieza diagonal
	if board.is_valid_position(target_pos):
		var tile = board.get_tile(target_pos)
		if tile.has_piece() and tile.occupied_piece.piece_color == piece_color:
			tile.occupied_piece.heal(2)

func special_charge():
	# Caballo mueve +1 casilla (implementar en get_basic_moves)
	pass

func special_magic_storm(board: BoardManager):
	# Reina ataca toda una línea
	pass

func special_royal_command(board: BoardManager, target_pos: Vector2i):
	# Rey permite movimiento extra a un aliado
	pass

func get_piece_value() -> int:
	match piece_type:
		PieceType.PAWN:
			return 1
		PieceType.KNIGHT, PieceType.BISHOP:
			return 3
		PieceType.ROOK:
			return 5
		PieceType.QUEEN:
			return 9
		PieceType.KING:
			return 1000
	return 0

func get_piece_name() -> String:
	var color_name = "Blanca" if piece_color == PieceColor.WHITE else "Negra"
	var type_name = ""
	
	match piece_type:
		PieceType.PAWN:
			type_name = "Peón"
		PieceType.ROOK:
			type_name = "Torre"
		PieceType.KNIGHT:
			type_name = "Caballo"
		PieceType.BISHOP:
			type_name = "Alfil"
		PieceType.QUEEN:
			type_name = "Reina"
		PieceType.KING:
			type_name = "Rey"
	
	return "%s %s" % [type_name, color_name]



# En Piece.gd
func move_to_position(target_pos: Vector2):
	var tween = create_tween()
	tween.tween_property(self, "position", target_pos, 0.3)
	tween.set_ease(Tween.EASE_OUT)
	tween.set_trans(Tween.TRANS_CUBIC)
