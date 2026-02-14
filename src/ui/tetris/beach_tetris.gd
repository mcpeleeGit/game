extends Control
## 해변 컨셉 테트리스 미니게임

const WORLD_MAP_PATH := "res://src/world/world_map.tscn"
const COLS: int = 10
const ROWS: int = 20
const CELL_SIZE: int = 28

# 해변 테마 컬러: 모래, 바다, 조개, 산호, 유리, 하늘, 야자
const BEACH_COLORS: Array[Color] = [
	Color(0.91, 0.84, 0.72),   # 모래
	Color(0.29, 0.56, 0.85),   # 바다
	Color(0.96, 0.65, 0.65),   # 조개
	Color(0.91, 0.35, 0.35),   # 산호
	Color(0.35, 0.71, 0.66),   # 유리
	Color(0.53, 0.81, 0.92),   # 하늘
	Color(0.18, 0.35, 0.15),   # 야자
]

# 표준 테트로미노 (각 4칸)
# [row][col] 4x4에서 1인 곳
const SHAPES: Array = [
	[[0,0,0,0], [1,1,1,1], [0,0,0,0], [0,0,0,0]],  # I
	[[1,1,0,0], [1,1,0,0], [0,0,0,0], [0,0,0,0]],  # O
	[[0,1,0,0], [1,1,1,0], [0,0,0,0], [0,0,0,0]],  # T
	[[0,1,1,0], [1,1,0,0], [0,0,0,0], [0,0,0,0]],  # S
	[[1,1,0,0], [0,1,1,0], [0,0,0,0], [0,0,0,0]],  # Z
	[[1,0,0,0], [1,1,1,0], [0,0,0,0], [0,0,0,0]],  # J
	[[0,0,1,0], [1,1,1,0], [0,0,0,0], [0,0,0,0]],  # L
]

var grid: Array = []  # [row][col] = color index (0=empty)
var current_piece: int = 0
var current_rot: int = 0
var current_x: int = 0
var current_y: int = 0
var next_piece: int = 0
var score: int = 0
var level: int = 1
var lines_cleared: int = 0
var game_over: bool = false
var playing: bool = false
var fall_timer: float = 0.0
var fall_interval: float = 0.8

@onready var board: Control = $VBox/HBox/BoardContainer
@onready var next_display: Control = $VBox/HBox/NextContainer
@onready var score_label: Label = $VBox/HBox/InfoVBox/ScoreLabel
@onready var level_label: Label = $VBox/HBox/InfoVBox/LevelLabel
@onready var lines_label: Label = $VBox/HBox/InfoVBox/LinesLabel
@onready var game_over_panel: PanelContainer = $GameOverPanel
@onready var final_score_label: Label = $GameOverPanel/Margin/VBox/FinalScoreLabel
@onready var start_button: Button = $VBox/Buttons/StartButton
@onready var back_button: Button = $VBox/Buttons/BackButton
@onready var restart_button: Button = $GameOverPanel/Margin/VBox/RestartButton
@onready var help_button: Button = $VBox/Buttons/HelpButton
@onready var help_panel: PanelContainer = $HelpPanel
@onready var help_label: Label = $HelpPanel/Margin/VBox/HelpLabel
@onready var help_close_btn: Button = $HelpPanel/Margin/VBox/CloseBtn

func _ready() -> void:
	add_to_group("i18n")
	game_over_panel.visible = false
	_init_grid()
	_build_board_cells()
	_build_next_cells()
	start_button.pressed.connect(_on_start_pressed)
	back_button.pressed.connect(_on_back_pressed)
	restart_button.pressed.connect(_on_restart_pressed)
	help_button.pressed.connect(_on_help_pressed)
	help_close_btn.pressed.connect(_on_help_close)
	help_panel.visible = false
	_set_buttons_focus_none()
	refresh_text()

func refresh_text() -> void:
	start_button.text = tr("TETRIS_START")
	back_button.text = tr("BTN_BACK")
	restart_button.text = tr("TETRIS_RESTART")
	help_button.text = tr("BTN_HELP")
	help_close_btn.text = tr("BTN_CLOSE")
	help_label.text = tr("HELP_TETRIS")

func _init_grid() -> void:
	grid.clear()
	for r in ROWS:
		var row: Array = []
		for c in COLS:
			row.append(-1)
		grid.append(row)

func _build_board_cells() -> void:
	for c in board.get_children():
		c.queue_free()
	for r in ROWS:
		for c in COLS:
			var cell := ColorRect.new()
			cell.custom_minimum_size = Vector2(CELL_SIZE - 1, CELL_SIZE - 1)
			cell.size = Vector2(CELL_SIZE - 1, CELL_SIZE - 1)
			cell.position = Vector2(c * CELL_SIZE, r * CELL_SIZE)
			cell.color = Color(0.15, 0.2, 0.25, 1)
			cell.name = "Cell_%d_%d" % [r, c]
			board.add_child(cell)
	board.custom_minimum_size = Vector2(COLS * CELL_SIZE, ROWS * CELL_SIZE)

func _build_next_cells() -> void:
	for c in next_display.get_children():
		c.queue_free()
	for r in 4:
		for c in 4:
			var cell := ColorRect.new()
			cell.custom_minimum_size = Vector2(20, 20)
			cell.size = Vector2(20, 20)
			cell.position = Vector2(c * 22, r * 22)
			cell.color = Color(0.2, 0.25, 0.3, 1)
			cell.name = "Next_%d_%d" % [r, c]
			next_display.add_child(cell)
	next_display.custom_minimum_size = Vector2(88, 88)

func _on_start_pressed() -> void:
	if playing and not game_over:
		return
	_start_game()

func _start_game() -> void:
	_init_grid()
	score = 0
	level = 1
	lines_cleared = 0
	game_over = false
	playing = true
	fall_interval = 0.8
	fall_timer = 0.0
	game_over_panel.visible = false
	next_piece = randi() % 7
	_spawn_piece()
	_update_ui()
	_update_display()

func _spawn_piece() -> bool:
	current_piece = next_piece
	next_piece = randi() % 7
	current_rot = 0
	current_x = COLS / 2 - 2
	current_y = 0
	if not _check_collision(current_piece, current_rot, current_x, current_y):
		game_over = true
		_game_over()
		return false
	return true

func _get_shape(p: int, rot: int) -> Array:
	var s: Array = SHAPES[p].duplicate(true)
	for _i in rot:
		var next_arr: Array = []
		for c in 4:
			var row: Array = []
			for r in range(3, -1, -1):
				row.append(s[r][c])
			next_arr.append(row)
		s = next_arr
	return s

func _check_collision(p: int, rot: int, ox: int, oy: int) -> bool:
	var shape: Array = _get_shape(p, rot)
	for r in 4:
		for c in 4:
			if shape[r][c] == 1:
				var gx: int = ox + c
				var gy: int = oy + r
				if gx < 0 or gx >= COLS or gy >= ROWS:
					return false
				if gy >= 0 and grid[gy][gx] >= 0:
					return false
	return true

func _lock_piece() -> void:
	var shape: Array = _get_shape(current_piece, current_rot)
	var color_idx: int = current_piece % BEACH_COLORS.size()
	for r in 4:
		for c in 4:
			if shape[r][c] == 1:
				var gy: int = current_y + r
				var gx: int = current_x + c
				if gy >= 0 and gy < ROWS and gx >= 0 and gx < COLS:
					grid[gy][gx] = color_idx
	var cleared: int = _clear_lines()
	lines_cleared += cleared
	if cleared == 1:
		score += 100 * level
	elif cleared == 2:
		score += 300 * level
	elif cleared == 3:
		score += 500 * level
	elif cleared == 4:
		score += 800 * level
	score += 10  # piece placed
	if lines_cleared >= level * 10:
		level += 1
		fall_interval = maxf(0.1, 0.8 - (level - 1) * 0.05)
	if not _spawn_piece():
		return
	_update_ui()
	_update_display()

func _clear_lines() -> int:
	var to_clear: Array[int] = []
	for r in range(ROWS - 1, -1, -1):
		var full: bool = true
		for c in COLS:
			if grid[r][c] < 0:
				full = false
				break
		if full:
			to_clear.append(r)
	for r in to_clear:
		grid.remove_at(r)
		grid.push_front([])
		for c in COLS:
			grid[0].append(-1)
	return to_clear.size()

func _move_left() -> void:
	if not playing or game_over:
		return
	if _check_collision(current_piece, current_rot, current_x - 1, current_y):
		current_x -= 1
		_update_display()

func _move_right() -> void:
	if not playing or game_over:
		return
	if _check_collision(current_piece, current_rot, current_x + 1, current_y):
		current_x += 1
		_update_display()

func _move_down() -> void:
	if not playing or game_over:
		return
	if _check_collision(current_piece, current_rot, current_x, current_y + 1):
		current_y += 1
		score += 2
		_update_display()
	else:
		_lock_piece()

func _rotate() -> void:
	if not playing or game_over:
		return
	var nr: int = (current_rot + 1) % 4
	if _check_collision(current_piece, nr, current_x, current_y):
		current_rot = nr
		_update_display()

func _hard_drop() -> void:
	if not playing or game_over:
		return
	while _check_collision(current_piece, current_rot, current_x, current_y + 1):
		current_y += 1
		score += 4
	_lock_piece()

func _update_display() -> void:
	for r in ROWS:
		for c in COLS:
			var cell: ColorRect = board.get_node_or_null("Cell_%d_%d" % [r, c])
			if not cell:
				continue
			var idx: int = grid[r][c]
			cell.color = BEACH_COLORS[idx] if idx >= 0 else Color(0.12, 0.18, 0.22, 1)
	var shape: Array = _get_shape(current_piece, current_rot)
	var color_idx: int = current_piece % BEACH_COLORS.size()
	for r in 4:
		for c in 4:
			if shape[r][c] == 1:
				var gy: int = current_y + r
				var gx: int = current_x + c
				if gy >= 0 and gy < ROWS and gx >= 0 and gx < COLS:
					var cell: ColorRect = board.get_node_or_null("Cell_%d_%d" % [gy, gx])
					if cell:
						cell.color = BEACH_COLORS[color_idx]
	_update_next_display()

func _update_next_display() -> void:
	for r in 4:
		for c in 4:
			var cell: ColorRect = next_display.get_node_or_null("Next_%d_%d" % [r, c])
			if not cell:
				continue
			cell.color = Color(0.2, 0.25, 0.3, 1)
	var shape: Array = _get_shape(next_piece, 0)
	var color_idx: int = next_piece % BEACH_COLORS.size()
	var ox: int = 1
	var oy: int = 0
	for r in 4:
		for c in 4:
			if shape[r][c] == 1 and oy + r >= 0 and oy + r < 4 and ox + c >= 0 and ox + c < 4:
				var cell: ColorRect = next_display.get_node_or_null("Next_%d_%d" % [oy + r, ox + c])
				if cell:
					cell.color = BEACH_COLORS[color_idx]

func _update_ui() -> void:
	score_label.text = tr("TETRIS_SCORE") % score
	level_label.text = tr("TETRIS_LEVEL") % level
	lines_label.text = tr("TETRIS_LINES") % lines_cleared

func _game_over() -> void:
	playing = false
	game_over_panel.visible = true
	final_score_label.text = tr("TETRIS_GAME_OVER") % score

func _on_restart_pressed() -> void:
	_start_game()

func _set_buttons_focus_none() -> void:
	for btn in [start_button, back_button, restart_button, help_button, help_close_btn]:
		btn.focus_mode = Control.FOCUS_NONE

func _on_help_pressed() -> void:
	help_panel.visible = true

func _on_help_close() -> void:
	help_panel.visible = false

func _on_back_pressed() -> void:
	SaveManager.save_game()
	SceneRouter.goto(WORLD_MAP_PATH)

func _process(delta: float) -> void:
	if not playing or game_over:
		return
	fall_timer += delta
	if fall_timer >= fall_interval:
		fall_timer = 0.0
		_move_down()

func _unhandled_input(event: InputEvent) -> void:
	if event.is_echo():
		return
	if event.is_action_pressed("ui_left"):
		_move_left()
		get_viewport().set_input_as_handled()
	elif event.is_action_pressed("ui_right"):
		_move_right()
		get_viewport().set_input_as_handled()
	elif event.is_action_pressed("ui_down"):
		_move_down()
		get_viewport().set_input_as_handled()
	elif event.is_action_pressed("ui_accept") or event.is_action_pressed("ui_up"):
		_rotate()
		get_viewport().set_input_as_handled()
	elif event.is_action_pressed("ui_page_up") or event.is_action_pressed("ui_select"):
		_hard_drop()
		get_viewport().set_input_as_handled()
