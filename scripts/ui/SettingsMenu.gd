extends Control

signal settings_changed

@onready var master_volume_slider: HSlider = $Panel/VBoxContainer/Audio/MasterVolumeSlider
@onready var music_volume_slider: HSlider = $Panel/VBoxContainer/Audio/MusicVolumeSlider
@onready var sfx_volume_slider: HSlider = $Panel/VBoxContainer/Audio/SFXVolumeSlider

@onready var master_value_label: Label = $Panel/VBoxContainer/Audio/MasterValueLabel
@onready var music_value_label: Label = $Panel/VBoxContainer/Audio/MusicValueLabel
@onready var sfx_value_label: Label = $Panel/VBoxContainer/Audio/SFXValueLabel

@onready var fullscreen_check: CheckBox = $Panel/VBoxContainer/Display/FullscreenCheck
@onready var vsync_check: CheckBox = $Panel/VBoxContainer/Display/VsyncCheck

@onready var difficulty_option: OptionButton = $Panel/VBoxContainer/Gameplay/DifficultyOption
@onready var show_hints_check: CheckBox = $Panel/VBoxContainer/Gameplay/ShowHintsCheck
@onready var animations_check: CheckBox = $Panel/VBoxContainer/Gameplay/AnimationsCheck

@onready var close_button: Button = $Panel/VBoxContainer/CloseButton

func _ready():
	# Conectar señales
	master_volume_slider.value_changed.connect(_on_master_volume_changed)
	music_volume_slider.value_changed.connect(_on_music_volume_changed)
	sfx_volume_slider.value_changed.connect(_on_sfx_volume_changed)
	
	fullscreen_check.toggled.connect(_on_fullscreen_toggled)
	vsync_check.toggled.connect(_on_vsync_toggled)
	
	difficulty_option.item_selected.connect(_on_difficulty_selected)
	show_hints_check.toggled.connect(_on_hints_toggled)
	animations_check.toggled.connect(_on_animations_toggled)
	
	close_button.pressed.connect(_on_close_pressed)
	
	# Cargar configuración actual
	load_settings()
	
	# Configurar opciones de dificultad
	difficulty_option.add_item("Fácil")
	difficulty_option.add_item("Normal")
	difficulty_option.add_item("Difícil")
	difficulty_option.add_item("Experto")

func load_settings():
	# Cargar desde Global o SaveSystem
	if Global.has("master_volume"):
		master_volume_slider.value = Global.master_volume
		music_volume_slider.value = Global.music_volume
		sfx_volume_slider.value = Global.sfx_volume
		
		fullscreen_check.button_pressed = Global.fullscreen
		vsync_check.button_pressed = Global.vsync
		
		show_hints_check.button_pressed = Global.show_hints
		animations_check.button_pressed = Global.enable_animations
		
		difficulty_option.selected = Global.difficulty_level
	
	update_volume_labels()

func save_settings():
	# Guardar en Global
	Global.master_volume = master_volume_slider.value
	Global.music_volume = music_volume_slider.value
	Global.sfx_volume = sfx_volume_slider.value
	
	Global.fullscreen = fullscreen_check.button_pressed
	Global.vsync = vsync_check.button_pressed
	
	Global.show_hints = show_hints_check.button_pressed
	Global.enable_animations = animations_check.button_pressed
	
	Global.difficulty_level = difficulty_option.selected
	
	# Guardar en disco
	Global.save_settings()
	
	settings_changed.emit()

func _on_master_volume_changed(value: float):
	update_volume_labels()
	apply_volume_settings()

func _on_music_volume_changed(value: float):
	update_volume_labels()
	apply_volume_settings()

func _on_sfx_volume_changed(value: float):
	update_volume_labels()
	apply_volume_settings()

func update_volume_labels():
	master_value_label.text = "%d%%" % (master_volume_slider.value * 100)
	music_value_label.text = "%d%%" % (music_volume_slider.value * 100)
	sfx_value_label.text = "%d%%" % (sfx_volume_slider.value * 100)

func apply_volume_settings():
	# Aplicar a los buses de audio
	var master_bus = AudioServer.get_bus_index("Master")
	var music_bus = AudioServer.get_bus_index("Music")
	var sfx_bus = AudioServer.get_bus_index("SFX")
	
	if master_bus >= 0:
		AudioServer.set_bus_volume_db(master_bus, linear_to_db(master_volume_slider.value))
	if music_bus >= 0:
		AudioServer.set_bus_volume_db(music_bus, linear_to_db(music_volume_slider.value))
	if sfx_bus >= 0:
		AudioServer.set_bus_volume_db(sfx_bus, linear_to_db(sfx_volume_slider.value))

func _on_fullscreen_toggled(enabled: bool):
	if enabled:
		DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_FULLSCREEN)
	else:
		DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_WINDOWED)

func _on_vsync_toggled(enabled: bool):
	if enabled:
		DisplayServer.window_set_vsync_mode(DisplayServer.VSYNC_ENABLED)
	else:
		DisplayServer.window_set_vsync_mode(DisplayServer.VSYNC_DISABLED)

func _on_difficulty_selected(index: int):
	pass  # Se guardará al cerrar

func _on_hints_toggled(enabled: bool):
	pass  # Se guardará al cerrar

func _on_animations_toggled(enabled: bool):
	pass  # Se guardará al cerrar

func _on_close_pressed():
	save_settings()
	
	var tween = create_tween()
	tween.tween_property(self, "modulate:a", 0.0, 0.2)
	await tween.finished
	
	queue_free()
