extends Node

# === CONFIGURACIÓN DE AUDIO ===
var master_volume: float = 0.8
var music_volume: float = 0.7
var sfx_volume: float = 0.9

# === CONFIGURACIÓN DE PANTALLA ===
var fullscreen: bool = false
var vsync: bool = true
var target_fps: int = 60

# === CONFIGURACIÓN DE JUEGO ===
var difficulty_level: int = 1  # 0=Fácil, 1=Normal, 2=Difícil, 3=Experto
var show_hints: bool = true
var enable_animations: bool = true
var show_legal_moves: bool = true

# === PROGRESIÓN DEL JUGADOR ===
var player_level: int = 1
var player_xp: int = 0
var player_xp_to_next_level: int = 100
var total_wins: int = 0
var total_losses: int = 0
var total_games_played: int = 0

# === ESTADÍSTICAS ===
var classic_wins: int = 0
var survival_high_score: int = 0
var survival_max_round: int = 0
var challenges_completed: Array[String] = []

# === MONEDAS Y DESBLOQUEOS ===
var coins: int = 0
var unlocked_skins: Array[String] = ["default"]
var unlocked_boards: Array[String] = ["classic"]
var current_skin: String = "default"
var current_board: String = "classic"

# === PODERES Y HABILIDADES ===
var unlocked_powers: Dictionary = {
	"pawn_evolution": false,
	"rook_shield": false,
	"bishop_heal": false,
	"knight_charge": false,
	"queen_storm": false,
	"king_command": false
}

# === LOGROS ===
var achievements: Dictionary = {
	"first_win": false,
	"invincible_king": false,
	"pawn_ascension": false,
	"perfect_game": false,
	"speedrun": false,
	"survivor": false
}

# === PATHS ===
const SAVE_PATH = "user://poder_de_peon_save.dat"

func _ready():
	# Configurar FPS objetivo
	Engine.max_fps = target_fps
	
	# Cargar configuración guardada
	load_settings()
	
	# Aplicar configuración
	apply_settings()

func apply_settings():
	# Audio
	var master_bus = AudioServer.get_bus_index("Master")
	var music_bus = AudioServer.get_bus_index("Music")
	var sfx_bus = AudioServer.get_bus_index("SFX")
	
	if master_bus >= 0:
		AudioServer.set_bus_volume_db(master_bus, linear_to_db(master_volume))
	if music_bus >= 0:
		AudioServer.set_bus_volume_db(music_bus, linear_to_db(music_volume))
	if sfx_bus >= 0:
		AudioServer.set_bus_volume_db(sfx_bus, linear_to_db(sfx_volume))
	
	# Pantalla
	if fullscreen:
		DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_FULLSCREEN)
	
	if vsync:
		DisplayServer.window_set_vsync_mode(DisplayServer.VSYNC_ENABLED)
	else:
		DisplayServer.window_set_vsync_mode(DisplayServer.VSYNC_DISABLED)

# === SISTEMA DE GUARDADO ===
func save_settings():
	var save_data = {
		"master_volume": master_volume,
		"music_volume": music_volume,
		"sfx_volume": sfx_volume,
		"fullscreen": fullscreen,
		"vsync": vsync,
		"difficulty_level": difficulty_level,
		"show_hints": show_hints,
		"enable_animations": enable_animations,
		"show_legal_moves": show_legal_moves,
		"player_level": player_level,
		"player_xp": player_xp,
		"total_wins": total_wins,
		"total_losses": total_losses,
		"total_games_played": total_games_played,
		"classic_wins": classic_wins,
		"survival_high_score": survival_high_score,
		"survival_max_round": survival_max_round,
		"challenges_completed": challenges_completed,
		"coins": coins,
		"unlocked_skins": unlocked_skins,
		"unlocked_boards": unlocked_boards,
		"current_skin": current_skin,
		"current_board": current_board,
		"unlocked_powers": unlocked_powers,
		"achievements": achievements
	}
	
	var file = FileAccess.open(SAVE_PATH, FileAccess.WRITE)
	if file:
		file.store_var(save_data)
		file.close()
		print("Configuración guardada exitosamente")
	else:
		push_error("No se pudo guardar la configuración")

func load_settings():
	if not FileAccess.file_exists(SAVE_PATH):
		print("No existe archivo de guardado, usando valores por defecto")
		return
	
	var file = FileAccess.open(SAVE_PATH, FileAccess.READ)
	if file:
		var save_data = file.get_var()
		file.close()
		
		# Cargar todos los valores
		if save_data.has("master_volume"):
			master_volume = save_data.master_volume
		if save_data.has("music_volume"):
			music_volume = save_data.music_volume
		if save_data.has("sfx_volume"):
			sfx_volume = save_data.sfx_volume
		if save_data.has("fullscreen"):
			fullscreen = save_data.fullscreen
		if save_data.has("vsync"):
			vsync = save_data.vsync
		if save_data.has("difficulty_level"):
			difficulty_level = save_data.difficulty_level
		if save_data.has("show_hints"):
			show_hints = save_data.show_hints
		if save_data.has("enable_animations"):
			enable_animations = save_data.enable_animations
		if save_data.has("show_legal_moves"):
			show_legal_moves = save_data.show_legal_moves
		if save_data.has("player_level"):
			player_level = save_data.player_level
		if save_data.has("player_xp"):
			player_xp = save_data.player_xp
		if save_data.has("total_wins"):
			total_wins = save_data.total_wins
		if save_data.has("total_losses"):
			total_losses = save_data.total_losses
		if save_data.has("total_games_played"):
			total_games_played = save_data.total_games_played
		if save_data.has("classic_wins"):
			classic_wins = save_data.classic_wins
		if save_data.has("survival_high_score"):
			survival_high_score = save_data.survival_high_score
		if save_data.has("survival_max_round"):
			survival_max_round = save_data.survival_max_round
		if save_data.has("challenges_completed"):
			challenges_completed = save_data.challenges_completed
		if save_data.has("coins"):
			coins = save_data.coins
		if save_data.has("unlocked_skins"):
			unlocked_skins = save_data.unlocked_skins
		if save_data.has("unlocked_boards"):
			unlocked_boards = save_data.unlocked_boards
		if save_data.has("current_skin"):
			current_skin = save_data.current_skin
		if save_data.has("current_board"):
			current_board = save_data.current_board
		if save_data.has("unlocked_powers"):
			unlocked_powers = save_data.unlocked_powers
		if save_data.has("achievements"):
			achievements = save_data.achievements
		
		print("Configuración cargada exitosamente")
	else:
		push_error("No se pudo cargar la configuración")

# === SISTEMA DE XP Y NIVEL ===
func add_xp(amount: int):
	player_xp += amount
	
	# Subir de nivel si es necesario
	while player_xp >= player_xp_to_next_level:
		level_up()

func level_up():
	player_level += 1
	player_xp -= player_xp_to_next_level
	player_xp_to_next_level = int(player_xp_to_next_level * 1.5)
	
	# Recompensas por subir de nivel
	add_coins(50 * player_level)
	
	print("¡Nivel %d alcanzado!" % player_level)

# === SISTEMA DE MONEDAS ===
func add_coins(amount: int):
	coins += amount
	save_settings()

func spend_coins(amount: int) -> bool:
	if coins >= amount:
		coins -= amount
		save_settings()
		return true
	return false

# === SISTEMA DE LOGROS ===
func unlock_achievement(achievement_id: String):
	if not achievements.has(achievement_id):
		return
	
	if not achievements[achievement_id]:
		achievements[achievement_id] = true
		# Recompensa por logro
		add_coins(100)
		add_xp(50)
		save_settings()
		print("¡Logro desbloqueado: %s!" % achievement_id)

# === ESTADÍSTICAS ===
func record_win(mode: String):
	total_wins += 1
	total_games_played += 1
	
	match mode:
		"classic":
			classic_wins += 1
	
	save_settings()

func record_loss():
	total_losses += 1
	total_games_played += 1
	save_settings()

func record_survival_score(round: int, score: int):
	if score > survival_high_score:
		survival_high_score = score
	if round > survival_max_round:
		survival_max_round = round
	save_settings()

# === UTILIDADES ===
func get_win_rate() -> float:
	if total_games_played == 0:
		return 0.0
	return float(total_wins) / float(total_games_played) * 100.0

func reset_progress():
	# Resetear todo excepto configuración
	player_level = 1
	player_xp = 0
	total_wins = 0
	total_losses = 0
	total_games_played = 0
	classic_wins = 0
	survival_high_score = 0
	survival_max_round = 0
	challenges_completed.clear()
	coins = 0
	unlocked_skins = ["default"]
	unlocked_boards = ["classic"]
	current_skin = "default"
	current_board = "classic"
	
	for key in unlocked_powers:
		unlocked_powers[key] = false
	
	for key in achievements:
		achievements[key] = false
	
	save_settings()
	print("Progreso reseteado")
