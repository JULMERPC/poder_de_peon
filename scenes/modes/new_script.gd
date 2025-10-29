extends Node2D

@onready var board: BoardManager = $Board
@onready var hud: GameHUD = $GameHUD

func _ready():
	# Conectar señales del tablero al HUD
	board.piece_moved.connect(_on_piece_moved)
	board.piece_captured.connect(_on_piece_captured)
	board.tile_selected.connect(_on_tile_selected)
	board.check_detected.connect(_on_check_detected)
	board.checkmate_detected.connect(_on_checkmate)
	
	# Conectar señales del HUD
	hud.pause_requested.connect(_on_pause_requested)
	hud.menu_requested.connect(_on_menu_requested)
	hud.power_activated.connect(_on_power_activated)
	
	# Configurar partida
	board.setup_standard_game()

func _on_piece_moved(from_tile, to_tile, piece):
	# Actualizar HUD
	hud.update_from_board(board)

func _on_piece_captured(captured, capturer):
	hud.add_captured_piece(captured)

func _on_tile_selected(tile):
	if tile.has_piece():
		hud.show_selected_piece(tile.occupied_piece)
	else:
		hud.show_selected_piece(null)

func _on_check_detected(king):
	hud.show_check_warning()

func _on_checkmate(winner_color):
	hud.show_checkmate(winner_color)
	
	# Esperar y mostrar pantalla de victoria/derrota
	await get_tree().create_timer(2.0).timeout
	if winner_color == Piece.PieceColor.WHITE:
		hud.show_victory_screen()
	else:
		hud.show_defeat_screen()

func _on_pause_requested():
	# Ya se maneja en GameHUD
	pass

func _on_menu_requested():
	get_tree().change_scene_to_file("res://scenes/MainMenu.tscn")

func _on_power_activated(power_type: String):
	if board.selected_piece:
		board.selected_piece.use_special_power(board)
