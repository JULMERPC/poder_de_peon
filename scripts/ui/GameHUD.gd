extends CanvasLayer
class_name GameHUD

signal pause_requested
signal menu_requested
signal power_activated(power_type: String)

# Referencias a nodos UI
@onready var turn_label: Label = $TopBar/TurnLabel
@onready var timer_label: Label = $TopBar/TimerLabel
@onready var score_label: Label = $TopBar/ScoreLabel

@onready var white_captures: HBoxContainer = $SidePanel/WhiteCaptures
@onready var black_captures: HBoxContainer = $SidePanel/BlackCaptures

@onready var selected_piece_info: PanelContainer = $BottomPanel/SelectedPieceInfo
@onready var piece_name_label: Label = $BottomPanel/SelectedPieceInfo/VBox/PieceNameLabel
@onready var piece_health: ProgressBar = $BottomPanel/SelectedPieceInfo/VBox/HealthBar
@onready var piece_sprite: TextureRect = $BottomPanel/SelectedPieceInfo/VBox/PieceSprite

@onready var powers_panel: HBoxContainer = $BottomPanel/PowersPanel
@onready var special_power_button: Button = $BottomPanel/PowersPanel/SpecialPowerButton
@onready var power_cooldown_label: Label = $BottomPanel/PowersPanel/CooldownLabel

@onready var pause_button: Button = $TopBar/PauseButton
@onready var menu_button: Button = $TopBar/MenuButton

# Variables de estado
var current_turn: Piece.PieceColor = Piece.PieceColor.WHITE
var game_time: float = 0.0
var score: int = 0
var selected_piece: Piece = null

var captured_white_pieces: Array = []
var captured_black_pieces: Array = []

func _ready():
	# Conectar botones
	pause_button.pressed.connect(_on_pause_pressed)
	menu_button.pressed.connect(_on_menu_pressed)
	special_power_button.pressed.connect(_on_power_pressed)
	
	# Ocultar panel de pieza seleccionada por defecto
	selected_piece_info.visible = false
	
	# Inicializar UI
	update_turn_display()
	update_score(0)

func _process(delta):
	# Actualizar timer
	game_time += delta
	update_timer_display()

func update_turn_display():
	var turn_text = "TURNO: BLANCAS" if current_turn == Piece.PieceColor.WHITE else "TURNO: NEGRAS"
	turn_label.text = turn_text
	
	# Cambiar color del texto
	if current_turn == Piece.PieceColor.WHITE:
		turn_label.add_theme_color_override("font_color", Color.WHITE)
	else:
		turn_label.add_theme_color_override("font_color", Color(0.3, 0.3, 0.3))

func update_timer_display():
	var minutes = int(game_time) / 60
	var seconds = int(game_time) % 60
	timer_label.text = "%02d:%02d" % [minutes, seconds]

func update_score(new_score: int):
	score = new_score
	score_label.text = "Puntuación: %d" % score

func set_turn(turn: Piece.PieceColor):
	current_turn = turn
	update_turn_display()

func show_selected_piece(piece: Piece):
	selected_piece = piece
	
	if not piece:
		selected_piece_info.visible = false
		return
	
	selected_piece_info.visible = true
	piece_name_label.text = piece.get_piece_name()
	
	# Actualizar barra de salud
	if piece.max_health > 1:
		piece_health.visible = true
		piece_health.max_value = piece.max_health
		piece_health.value = piece.current_health
	else:
		piece_health.visible = false
	
	# Actualizar sprite de la pieza
	if piece.sprite and piece.sprite.texture:
		piece_sprite.texture = piece.sprite.texture
		piece_sprite.visible = true
	else:
		piece_sprite.visible = false
	
	# Actualizar estado del poder especial
	update_power_button(piece)

func update_power_button(piece: Piece):
	if not piece:
		special_power_button.disabled = true
		power_cooldown_label.text = ""
		return
	
	if piece.special_power_ready:
		special_power_button.disabled = false
		special_power_button.text = "⚡ PODER ESPECIAL"
		power_cooldown_label.text = "¡Listo!"
		power_cooldown_label.add_theme_color_override("font_color", Color.GREEN)
	else:
		special_power_button.disabled = true
		special_power_button.text = "⏳ Enfriamiento"
		power_cooldown_label.text = "Cooldown: %d turnos" % piece.special_power_cooldown
		power_cooldown_label.add_theme_color_override("font_color", Color.RED)

func add_captured_piece(piece: Piece):
	var piece_icon = create_piece_icon(piece)
	
	if piece.piece_color == Piece.PieceColor.WHITE:
		black_captures.add_child(piece_icon)
		captured_white_pieces.append(piece)
	else:
		white_captures.add_child(piece_icon)
		captured_black_pieces.append(piece)
	
	# Actualizar puntuación
	update_score(score + piece.get_piece_value())

func create_piece_icon(piece: Piece) -> TextureRect:
	var icon = TextureRect.new()
	icon.custom_minimum_size = Vector2(32, 32)
	icon.expand_mode = TextureRect.EXPAND_FIT_WIDTH_PROPORTIONAL
	icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	
	if piece.sprite and piece.sprite.texture:
		icon.texture = piece.sprite.texture
	
	return icon

func show_notification(message: String, duration: float = 2.0):
	var notification = Label.new()
	notification.text = message
	notification.add_theme_font_size_override("font_size", 24)
	notification.add_theme_color_override("font_color", Color.YELLOW)
	notification.position = Vector2(get_viewport().size.x / 2 - 100, 100)
	add_child(notification)
	
	# Animación
	var tween = create_tween()
	tween.tween_property(notification, "modulate:a", 0.0, duration)
	tween.tween_callback(notification.queue_free)

func show_check_warning():
	show_notification("¡JAQUE!", 3.0)
	# TODO: Añadir efecto sonoro y visual

func show_checkmate(winner: Piece.PieceColor):
	var winner_text = "BLANCAS" if winner == Piece.PieceColor.WHITE else "NEGRAS"
	show_notification("¡JAQUE MATE! Ganan las %s" % winner_text, 5.0)

func show_victory_screen():
	var victory_panel = preload("res://scenes/ui/VictoryScreen.tscn").instantiate()
	add_child(victory_panel)

func show_defeat_screen():
	var defeat_panel = preload("res://scenes/ui/DefeatScreen.tscn").instantiate()
	add_child(defeat_panel)

func _on_pause_pressed():
	get_tree().paused = true
	var pause_menu = preload("res://scenes/ui/PauseMenu.tscn").instantiate()
	add_child(pause_menu)
	pause_menu.resumed.connect(_on_pause_resumed)
	pause_requested.emit()

func _on_pause_resumed():
	get_tree().paused = false

func _on_menu_pressed():
	menu_requested.emit()

func _on_power_pressed():
	if selected_piece and selected_piece.special_power_ready:
		power_activated.emit(get_power_type(selected_piece))

func get_power_type(piece: Piece) -> String:
	match piece.piece_type:
		Piece.PieceType.PAWN:
			return "evolution"
		Piece.PieceType.ROOK:
			return "shield"
		Piece.PieceType.BISHOP:
			return "heal"
		Piece.PieceType.KNIGHT:
			return "charge"
		Piece.PieceType.QUEEN:
			return "storm"
		Piece.PieceType.KING:
			return "command"
	return ""

# Método para actualizar el HUD desde el GameManager
func update_from_board(board: BoardManager):
	set_turn(board.current_turn)
	
	if board.selected_piece:
		show_selected_piece(board.selected_piece)
	else:
		show_selected_piece(null)
