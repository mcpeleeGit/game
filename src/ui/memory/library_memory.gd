extends Control
## 도서관 카드 짝 맞추기 (메모리) 게임

const WORLD_MAP_PATH := "res://src/world/world_map.tscn"
const COLS: int = 4
const ROWS: int = 4
const PAIRS: int = 8
const CARD_SIZE: int = 64
const CARD_GAP: int = 8

# 도서관 테마 심볼 (8쌍)
const SYMBOLS: Array[String] = ["📖", "📚", "✏️", "📝", "🎓", "🔮", "📜", "🌙"]

var board: Array = []  # [0..15] = symbol index (0..7), -1 = hidden
var flipped: Array = []  # [idx] = true if face up
var first_idx: int = -1
var second_idx: int = -1
var moves: int = 0
var matched: int = 0
var can_flip: bool = true

@onready var grid: Control = $VBox/GameArea/Margin/GridContainer
@onready var moves_label: Label = $VBox/Info/MovesLabel
@onready var result_label: Label = $VBox/Info/ResultLabel
@onready var start_button: Button = $VBox/Buttons/StartButton
@onready var back_button: Button = $VBox/Buttons/BackButton
@onready var help_button: Button = $VBox/Buttons/HelpButton
@onready var help_panel: PanelContainer = $HelpPanel
@onready var help_label: Label = $HelpPanel/Margin/VBox/HelpLabel
@onready var help_close_btn: Button = $HelpPanel/Margin/VBox/CloseBtn

func _ready() -> void:
	add_to_group("i18n")
	help_panel.visible = false
	start_button.pressed.connect(_on_start_pressed)
	back_button.pressed.connect(_on_back_pressed)
	help_button.pressed.connect(_on_help_pressed)
	help_close_btn.pressed.connect(_on_help_close)
	_set_buttons_focus_none()
	refresh_text()
	_new_game()

func _set_buttons_focus_none() -> void:
	for btn in [start_button, back_button, help_button, help_close_btn]:
		btn.focus_mode = Control.FOCUS_NONE

func refresh_text() -> void:
	start_button.text = tr("TETRIS_START")
	back_button.text = tr("BTN_BACK")
	help_button.text = tr("BTN_HELP")
	help_close_btn.text = tr("BTN_CLOSE")
	help_label.text = tr("HELP_MEMORY")

func _new_game() -> void:
	var pool: Array = []
	for i in PAIRS:
		pool.append(i)
		pool.append(i)
	pool.shuffle()
	board = pool.duplicate()
	flipped = []
	for i in COLS * ROWS:
		flipped.append(false)
	first_idx = -1
	second_idx = -1
	moves = 0
	matched = 0
	can_flip = true
	_build_cards()
	_update_ui()

func _build_cards() -> void:
	for c in grid.get_children():
		c.queue_free()
	for i in COLS * ROWS:
		var card := Button.new()
		card.custom_minimum_size = Vector2(CARD_SIZE, CARD_SIZE)
		card.size = Vector2(CARD_SIZE, CARD_SIZE)
		var row: int = i / COLS
		var col: int = i % COLS
		card.position = Vector2(col * (CARD_SIZE + CARD_GAP), row * (CARD_SIZE + CARD_GAP))
		card.name = "Card_%d" % i
		card.focus_mode = Control.FOCUS_NONE
		card.pressed.connect(_on_card_pressed.bind(i))
		card.text = "?"
		grid.add_child(card)
	grid.custom_minimum_size = Vector2(COLS * (CARD_SIZE + CARD_GAP) - CARD_GAP, ROWS * (CARD_SIZE + CARD_GAP) - CARD_GAP)

func _update_cards() -> void:
	for i in COLS * ROWS:
		var card: Button = grid.get_node_or_null("Card_%d" % i)
		if not card:
			continue
		if flipped[i]:
			card.text = SYMBOLS[board[i]]
			card.disabled = true
		else:
			card.text = "?"
			card.disabled = not can_flip

func _update_ui() -> void:
	moves_label.text = tr("MEMORY_MOVES") % moves
	_update_cards()
	if matched >= PAIRS:
		result_label.text = tr("MEMORY_COMPLETE") % moves

func _on_card_pressed(idx: int) -> void:
	if not can_flip or flipped[idx]:
		return
	flipped[idx] = true
	if first_idx < 0:
		first_idx = idx
		_update_cards()
		return
	second_idx = idx
	moves += 1
	can_flip = false
	_update_cards()
	await get_tree().create_timer(0.6).timeout
	if board[first_idx] == board[second_idx]:
		matched += 1
		first_idx = -1
		second_idx = -1
		can_flip = true
		if matched >= PAIRS:
			result_label.text = tr("MEMORY_COMPLETE") % moves
		_update_ui()
		return
	else:
		flipped[first_idx] = false
		flipped[second_idx] = false
	first_idx = -1
	second_idx = -1
	can_flip = true
	_update_ui()

func _on_start_pressed() -> void:
	_new_game()
	result_label.text = ""

func _on_help_pressed() -> void:
	help_panel.visible = true

func _on_help_close() -> void:
	help_panel.visible = false

func _on_back_pressed() -> void:
	SaveManager.save_game()
	SceneRouter.goto(WORLD_MAP_PATH)
