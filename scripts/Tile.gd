extends Area2D
class_name Tile

signal tile_clicked(tile: Tile)
signal tile_hovered(tile: Tile)

@export var tile_size: Vector2 = Vector2(64, 64)
@export var color_light: Color = Color(0.93, 0.85, 0.71)  # Beige claro
@export var color_dark: Color = Color(0.55, 0.45, 0.37)   # Marrón oscuro

var grid_position: Vector2i
var is_light: bool
var occupied_piece = null
var is_highlighted: bool = false
var is_selected: bool = false
var is_valid_move: bool = false

@onready var sprite: Sprite2D = $Sprite2D
@onready var highlight: Sprite2D = $Highlight
@onready var move_indicator: Sprite2D = $MoveIndicator
@onready var collision: CollisionShape2D = $CollisionShape2D

func _ready():
	# Conectar señales de input
	input_event.connect(_on_input_event)
	mouse_entered.connect(_on_mouse_entered)
	mouse_exited.connect(_on_mouse_exited)
	
	# Configurar visuales iniciales
	_setup_visuals()

func _setup_visuals():
	# Crear sprite para la casilla si no existe
	if not sprite:
		sprite = Sprite2D.new()
		add_child(sprite)
		sprite.name = "Sprite2D"
	
	# Crear textura básica (cuadrado)
	var texture = create_tile_texture()
	sprite.texture = texture
	
	# Configurar highlight
	if not highlight:
		highlight = Sprite2D.new()
		add_child(highlight)
		highlight.name = "Highlight"
		highlight.modulate = Color(0.343, 0.553, 1.0, 0.302)  # Amarillo transparente
		highlight.texture = texture
		highlight.visible = false
	
	# Configurar indicador de movimiento válido
	if not move_indicator:
		move_indicator = Sprite2D.new()
		add_child(move_indicator)
		move_indicator.name = "MoveIndicator"
		move_indicator.modulate = Color(0, 1, 0, 0.5)  # Verde transparente
		move_indicator.texture = texture
		move_indicator.scale = Vector2(0.8, 0.8)
		move_indicator.visible = false
	
	# Configurar colisión
	if not collision:
		collision = CollisionShape2D.new()
		add_child(collision)
		collision.name = "CollisionShape2D"
		var shape = RectangleShape2D.new()
		shape.size = tile_size
		collision.shape = shape

func create_tile_texture() -> ImageTexture:
	var image = Image.create(int(tile_size.x), int(tile_size.y), false, Image.FORMAT_RGBA8)
	var color = color_light if is_light else color_dark
	image.fill(color)
	return ImageTexture.create_from_image(image)

func initialize(grid_pos: Vector2i, light: bool):
	grid_position = grid_pos
	is_light = light
	name = "Tile_%d_%d" % [grid_pos.x, grid_pos.y]
	_setup_visuals()

func set_piece(piece):
	occupied_piece = piece
	if piece:
		piece.current_tile = self

func remove_piece():
	var piece = occupied_piece
	occupied_piece = null
	return piece

func has_piece() -> bool:
	return occupied_piece != null

func highlight_tile(enabled: bool):
	is_highlighted = enabled
	if highlight:
		highlight.visible = enabled

func select_tile(selected: bool):
	is_selected = selected
	if highlight:
		if selected:
			highlight.modulate = Color(1, 1, 0, 0.5)  # Amarillo más opaco
			highlight.visible = true
		else:
			highlight.modulate = Color(1, 1, 0, 0.3)
			highlight.visible = is_highlighted
#func highlight_tile(enabled: bool):
	#is_highlighted = enabled
	#if highlight:
		#if enabled and not is_selected:
			#highlight.visible = true
			#highlight.modulate = Color(1, 0.6, 0, 0.4)  # Naranja suave al pasar el mouse
		#elif not is_selected:
			#highlight.visible = false
#
#func select_tile(selected: bool):
	#is_selected = selected
	#if highlight:
		#if selected:
			#highlight.visible = true
			#highlight.modulate = Color(0.2, 0.5, 1.0, 0.5)  # Azul brillante al seleccionar
		#else:
			## Volver al color anterior del hover si corresponde
			#if is_highlighted:
				#highlight.modulate = Color(1, 0.6, 0, 0.4)
				#highlight.visible = true
			#else:
				#highlight.visible = false
#


func show_valid_move(enabled: bool):
	is_valid_move = enabled
	if move_indicator:
		move_indicator.visible = enabled

func _on_input_event(_viewport, event, _shape_idx):
	if event is InputEventMouseButton:
		if event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
			tile_clicked.emit(self)

func _on_mouse_entered():
	if not is_selected:
		highlight_tile(true)
	tile_hovered.emit(self)

func _on_mouse_exited():
	if not is_selected and not is_valid_move:
		highlight_tile(false)

# Método para efecto especial de casilla
func apply_special_effect(effect_type: String):
	match effect_type:
		"lava":
			sprite.modulate = Color(1, 0.3, 0.2)
		"ice":
			sprite.modulate = Color(0.7, 0.9, 1)
		"healing":
			sprite.modulate = Color(0.7, 1, 0.7)
		_:
			sprite.modulate = Color.WHITE

func get_world_position() -> Vector2:
	return global_position
