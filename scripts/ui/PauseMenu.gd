extends Control

signal resumed
signal restarted
signal quit_to_menu

@onready var resume_button: Button = $Panel/VBoxContainer/ResumeButton
@onready var restart_button: Button = $Panel/VBoxContainer/RestartButton
@onready var settings_button: Button = $Panel/VBoxContainer/SettingsButton
@onready var menu_button: Button = $Panel/VBoxContainer/MenuButton
@onready var panel: Panel = $Panel

func _ready():
	# Conectar botones
	resume_button.pressed.connect(_on_resume_pressed)
	restart_button.pressed.connect(_on_restart_pressed)
	settings_button.pressed.connect(_on_settings_pressed)
	menu_button.pressed.connect(_on_menu_pressed)
	
	# Centrar panel
	panel.position = (get_viewport_rect().size - panel.size) / 2
	
	# Efecto de entrada
	modulate.a = 0
	var tween = create_tween()
	tween.tween_property(self, "modulate:a", 1.0, 0.3)

func _input(event):
	# Permitir cerrar con ESC
	if event.is_action_pressed("ui_cancel"):
		_on_resume_pressed()

func _on_resume_pressed():
	var tween = create_tween()
	tween.tween_property(self, "modulate:a", 0.0, 0.2)
	await tween.finished
	
	resumed.emit()
	queue_free()

func _on_restart_pressed():
	get_tree().paused = false
	restarted.emit()
	get_tree().reload_current_scene()

func _on_settings_pressed():
	var settings = preload("res://scenes/ui/SettingsMenu.tscn").instantiate()
	add_child(settings)

func _on_menu_pressed():
	get_tree().paused = false
	quit_to_menu.emit()
	get_tree().change_scene_to_file("res://scenes/MainMenu.tscn")
