extends Control
## 등대 타자 연습 - 낙하 단어 맞추기

const WORLD_MAP_PATH := "res://src/world/world_map.tscn"

const WORD_POOLS: Array = [
	["sea", "sun", "ship", "sand", "wave", "light", "boat", "mist"],
	["beacon", "sailor", "coast", "tower", "storm", "anchor", "harbor", "cargo"],
	["lighthouse", "horizon", "navigate", "signal", "voyage", "mariner"],
	["mariner", "captain", "voyage", "rescue", "beacon", "sailor", "island"],
	["constellation", "illumination", "coastline", "navigation", "lighthouse"],
]

const FALL_SPEEDS: Array = [40.0, 55.0, 70.0, 90.0, 110.0]
const SPAWN_INTERVALS: Array = [3.0, 2.5, 2.0, 1.5, 1.2]
const LEVEL_UP_WORDS: int = 5

var level: int = 1
var score: int = 0
var lives: int = 3
var words_cleared: int = 0
var playing: bool = false
var game_over: bool = false
var spawn_timer: float = 0.0

var falling_words: Array = []  # [{ word, y, x, label }]

@onready var title_label: Label = $VBox/Title
@onready var game_area: Control = $VBox/GameArea
@onready var input_edit: LineEdit = $VBox/InputArea/LineEdit
@onready var score_label: Label = $VBox/Info/ScoreLabel
@onready var level_label: Label = $VBox/Info/LevelLabel
@onready var lives_label: Label = $VBox/Info/LivesLabel
@onready var result_label: Label = $VBox/Info/ResultLabel
@onready var game_over_panel: PanelContainer = $GameOverPanel
@onready var game_over_label: Label = $GameOverPanel/Margin/VBox/GameOverLabel
@onready var start_button: Button = $VBox/Buttons/StartButton
@onready var back_button: Button = $VBox/Buttons/BackButton
@onready var help_button: Button = $VBox/Buttons/HelpButton
@onready var help_panel: PanelContainer = $HelpPanel
@onready var help_label: Label = $HelpPanel/Margin/VBox/HelpLabel
@onready var help_close_btn: Button = $HelpPanel/Margin/VBox/CloseBtn
@onready var restart_button: Button = $GameOverPanel/Margin/VBox/RestartButton

func _ready() -> void:
	add_to_group("i18n")
	game_over_panel.visible = false
	help_panel.visible = false
	start_button.pressed.connect(_on_start_pressed)
	back_button.pressed.connect(_on_back_pressed)
	help_button.pressed.connect(_on_help_pressed)
	help_close_btn.pressed.connect(_on_help_close)
	restart_button.pressed.connect(_on_restart_pressed)
	input_edit.text_submitted.connect(_on_text_submitted)
	_set_buttons_focus_none()
	refresh_text()
	_update_ui()

func _set_buttons_focus_none() -> void:
	for btn in [start_button, back_button, help_button, help_close_btn, restart_button]:
		btn.focus_mode = Control.FOCUS_NONE

func refresh_text() -> void:
	title_label.text = tr("TYPING_TITLE")
	start_button.text = tr("TETRIS_START")
	back_button.text = tr("BTN_BACK")
	help_button.text = tr("BTN_HELP")
	help_close_btn.text = tr("BTN_CLOSE")
	restart_button.text = tr("TETRIS_RESTART")
	help_label.text = tr("HELP_TYPING")
	input_edit.placeholder_text = tr("TYPING_HINT")

func _update_ui() -> void:
	score_label.text = tr("TYPING_SCORE") % score
	level_label.text = tr("TYPING_LEVEL") % level
	lives_label.text = tr("TYPING_LIVES") % lives

func _get_word_for_level() -> String:
	var pool: Array = WORD_POOLS[clampi(level - 1, 0, 4)]
	return pool[randi() % pool.size()]

func _spawn_word() -> void:
	var word: String = _get_word_for_level()
	var lbl := Label.new()
	lbl.text = word
	lbl.add_theme_font_size_override("font_size", 20)
	lbl.add_theme_color_override("font_color", Color(0.95, 0.92, 0.8, 1))
	lbl.add_theme_color_override("font_outline_color", Color(0.15, 0.12, 0.1, 1))
	lbl.add_theme_constant_override("outline_size", 2)
	var area_width: float = game_area.size.x
	var x: float = randf_range(20, maxf(20, area_width - 100))
	lbl.position = Vector2(x, -30)
	game_area.add_child(lbl)
	falling_words.append({"word": word, "y": -30.0, "x": x, "label": lbl})

func _on_text_submitted(text: String) -> void:
	if not playing or game_over:
		return
	var t: String = text.strip_edges().to_lower()
	if t.is_empty():
		return
	input_edit.clear()
	input_edit.call_deferred("grab_focus")
	for i in range(falling_words.size() - 1, -1, -1):
		var fw: Dictionary = falling_words[i]
		if fw["word"].to_lower() == t:
			var lbl: Node = fw.get("label")
			if is_instance_valid(lbl):
				lbl.queue_free()
			falling_words.remove_at(i)
			score += 10 * level
			words_cleared += 1
			if words_cleared >= LEVEL_UP_WORDS and level < 5:
				words_cleared = 0
				level += 1
				result_label.text = tr("TYPING_LEVEL") % level
			_update_ui()
			return

func _on_start_pressed() -> void:
	_start_game()

func _start_game() -> void:
	level = 1
	score = 0
	lives = 3
	words_cleared = 0
	playing = true
	game_over = false
	spawn_timer = 0.0
	game_over_panel.visible = false
	result_label.text = ""
	for fw in falling_words:
		var lbl: Node = fw.get("label")
		if is_instance_valid(lbl) and lbl.is_inside_tree():
			lbl.queue_free()
	falling_words.clear()
	_update_ui()
	input_edit.grab_focus()

func _game_over() -> void:
	playing = false
	game_over = true
	game_over_panel.visible = true
	game_over_label.text = tr("TYPING_GAME_OVER") + " " + (tr("TYPING_SCORE") % score)

func _on_help_pressed() -> void:
	help_panel.visible = true

func _on_help_close() -> void:
	help_panel.visible = false

func _on_restart_pressed() -> void:
	_start_game()

func _on_back_pressed() -> void:
	SaveManager.save_game()
	SceneRouter.goto(WORLD_MAP_PATH)

func _process(delta: float) -> void:
	if not playing or game_over:
		return
	var fall_speed: float = FALL_SPEEDS[clampi(level - 1, 0, 4)]
	var bottom: float = game_area.size.y - 20
	spawn_timer += delta
	var interval: float = SPAWN_INTERVALS[clampi(level - 1, 0, 4)]
	if spawn_timer >= interval:
		spawn_timer = 0.0
		_spawn_word()
	var to_remove: Array = []
	for fw in falling_words:
		var lbl: Node = fw.get("label")
		if not is_instance_valid(lbl):
			to_remove.append(fw)
			continue
		fw["y"] += fall_speed * delta
		lbl.position.y = fw["y"]
		if fw["y"] > bottom:
			to_remove.append(fw)
			lbl.queue_free()
			lives -= 1
			if lives <= 0:
				_game_over()
				return
			_update_ui()
	for fw in to_remove:
		falling_words.erase(fw)
