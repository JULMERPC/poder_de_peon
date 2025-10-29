extends Control

signal mode_selected(mode: String)

@onready var title_label: Label = $VBoxContainer/TitleLabel
@onready var classic_button: Button = $VBoxContainer/MenuButtons/ClassicButton
@onready var survival_button: Button = $VBoxContainer/MenuButtons/SurvivalButton
@onready var challenge_button: Button = $VBoxContainer/MenuButtons/ChallengeButton
@onready var settings_button: Button = $VBoxContainer/MenuButtons/SettingsButton
@onready var quit_button: Button = $VBoxContainer/MenuButtons/QuitButton
@onready var version_label: Label = $VersionLabel

@onready var animation_player: AnimationPlayer = $AnimationPlayer

func _ready():
	# Conectar botones
	classic_button.pressed.connect(_on_classic_pressed)
	survival_button.pressed.connect(_on_survival_pressed)
	challenge_button.pressed.connect(_on_challenge_pressed)
	settings_button.pressed.connect(_on_settings_pressed)
	quit_button.pressed.connect(_on_quit_pressed)
	
	# Animación de entrada
	if animation_player:
		animation_player.play("fade_in")
	
	# Configurar versión
	#version_label.text = "v0.1 Alpha - Godot 4.x"
	#
	# Efecto hover en botones
	setup_button_hover_effects()

func setup_button_hover_effects():
	var buttons = [classic_button, survival_button, challenge_button, settings_button, quit_button]
	
	for button in buttons:
		button.mouse_entered.connect(_on_button_hover.bind(button))
		button.mouse_exited.connect(_on_button_unhover.bind(button))

func _on_button_hover(button: Button):
	var tween = create_tween()
	tween.tween_property(button, "scale", Vector2(1.05, 1.05), 0.1)
	# TODO: Reproducir sonido hover

func _on_button_unhover(button: Button):
	var tween = create_tween()
	tween.tween_property(button, "scale", Vector2(1.0, 1.0), 0.1)

func _on_classic_pressed():
	play_click_sound()
	mode_selected.emit("classic")
	transition_to_scene("res://scenes/modes/ClassicMode.tscn")

func _on_survival_pressed():
	play_click_sound()
	mode_selected.emit("survival")
	transition_to_scene("res://scenes/modes/SurvivalMode.tscn")

func _on_challenge_pressed():
	play_click_sound()
	mode_selected.emit("challenge")
	transition_to_scene("res://scenes/modes/ChallengeMode.tscn")

func _on_settings_pressed():
	play_click_sound()
	# Abrir menú de configuración
	var settings = preload("res://scenes/ui/SettingsMenu.tscn").instantiate()
	add_child(settings)

func _on_quit_pressed():
	play_click_sound()
	# Animación de salida antes de cerrar
	if animation_player:
		animation_player.play("fade_out")
		await animation_player.animation_finished
	
	get_tree().quit()

func transition_to_scene(scene_path: String):
	if animation_player:
		animation_player.play("fade_out")
		await animation_player.animation_finished
	
	get_tree().change_scene_to_file(scene_path)

func play_click_sound():
	# TODO: Reproducir sonido de click
	pass
