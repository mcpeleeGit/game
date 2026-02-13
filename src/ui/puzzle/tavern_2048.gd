extends Control
## 선술집 2048 퍼즐 미니게임

const WORLD_MAP_PATH := "res://src/world/world_map.tscn"
const SIZE: int = 4
const CELL_SIZE: int = 72
const CELL_GAP: int = 8

# 선술집 테마: 맥주/호프/통나무 - 숫자별 색상 (2~2048 이상)
const TILE_COLORS: Dictionary = {
	0: Color(0.35, 0.28, 0.22, 1),
	2: Color(0.72, 0.55, 0.35, 1),
	4: Color(0.85, 0.65, 0.35, 1),
	8: Color(0.92, 0.72, 0.3, 1),
	16: Color(0.95, 0.6, 0.25, 1),
	32: Color(0.9, 0.5, 0.2, 1),
	64: Color(0.85, 0.4, 0.15, 1),
	128: Color(0.8, 0.35, 0.1, 1),
	256: Color(0.75, 0.3, 0.08, 1),
	512: Color(0.7, 0.25, 0.06, 1),
	1024: Color(0.65, 0.2, 0.05, 1),
	2048: Color(0.9, 0.75, 0.2, 1),
}

var grid: Array = []  # [row][col] = 0 or 2^n
var score: int = 0
var best_score: int = 0
var game_over: bool = false
var won: bool = false
var playing: bool = false

@onready var grid_container: Control = $VBox/HBox/GridContainer
@onready var score_label: Label = $VBox/HBox/InfoVBox/ScoreLabel
@onready var best_label: Label = $VBox/HBox/InfoVBox/BestLabel
@onready var hint_label: Label = $VBox/HintLabel
@onready var start_button: Button = $VBox/Buttons/StartButton
@onready var back_button: Button = $VBox/Buttons/BackButton
@onready var restart_button: Button = $VBox/Buttons/RestartButton
@onready var game_over_panel: PanelContainer = $GameOverPanel
@onready var game_over_label: Label = $GameOverPanel/Margin/VBox/GameOverLabel
@onready var game_over_restart: Button = $GameOverPanel/Margin/VBox/RestartBtn
@onready var win_panel: PanelContainer = $WinPanel
@onready var win_label: Label = $WinPanel/Margin/VBox/WinLabel
@onready var continue_button: Button = $WinPanel/Margin/VBox/ContinueButton
@onready var help_button: Button = $VBox/Buttons/HelpButton
@onready var help_panel: PanelContainer = $HelpPanel
@onready var help_label: Label = $HelpPanel/Margin/VBox/HelpLabel
@onready var help_close_btn: Button = $HelpPanel/Margin/VBox/CloseBtn
@onready var help_title: Label = $HelpPanel/Margin/VBox/HelpTitle

func _ready() -> void:
	add_to_group("i18n")
	game_over_panel.visible = false
	win_panel.visible = false
	_init_grid()
	_build_grid_cells()
	start_button.pressed.connect(_on_start_pressed)
	back_button.pressed.connect(_on_back_pressed)
	restart_button.pressed.connect(_on_restart_pressed)
	game_over_restart.pressed.connect(_on_restart_pressed)
	continue_button.pressed.connect(_on_continue_pressed)
	help_button.pressed.connect(_on_help_pressed)
	help_close_btn.pressed.connect(_on_help_close)
	help_panel.visible = false
	_set_buttons_focus_none()
	refresh_text()
	_update_display()
	_update_ui()

func refresh_text() -> void:
	start_button.text = tr("TETRIS_START")
	back_button.text = tr("BTN_BACK")
	restart_button.text = tr("TETRIS_RESTART")
	hint_label.text = tr("PUZZLE_HINT")
	continue_button.text = tr("PUZZLE_CONTINUE")
	game_over_restart.text = tr("PUZZLE_RESTART")
	help_button.text = tr("BTN_HELP")
	help_title.text = tr("BTN_HELP")
	help_close_btn.text = tr("BTN_CLOSE")
	help_label.text = tr("HELP_PUZZLE_2048")

func _build_grid_cells() -> void:
	for c in grid_container.get_children():
		c.queue_free()
	for r in SIZE:
		for c in SIZE:
			var cell := ColorRect.new()
			cell.custom_minimum_size = Vector2(CELL_SIZE, CELL_SIZE)
			cell.size = Vector2(CELL_SIZE, CELL_SIZE)
			cell.position = Vector2(c * (CELL_SIZE + CELL_GAP), r * (CELL_SIZE + CELL_GAP))
			cell.color = Color(0.35, 0.28, 0.22, 1)
			cell.name = "Cell_%d_%d" % [r, c]
			grid_container.add_child(cell)
			var label := Label.new()
			label.name = "ValueLabel"
			label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
			label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
			label.set_anchors_preset(Control.PRESET_FULL_RECT)
			label.offset_left = 4
			label.offset_top = 4
			label.offset_right = -4
			label.offset_bottom = -4
			label.add_theme_font_size_override("font_size", 24)
			label.add_theme_color_override("font_color", Color(0.15, 0.12, 0.08, 1))
			label.add_theme_color_override("font_outline_color", Color(1, 1, 1, 0.5))
			label.add_theme_constant_override("outline_size", 2)
			label.text = ""
			cell.add_child(label)
	grid_container.custom_minimum_size = Vector2(SIZE * (CELL_SIZE + CELL_GAP) - CELL_GAP, SIZE * (CELL_SIZE + CELL_GAP) - CELL_GAP)

func _init_grid() -> void:
	grid.clear()
	for r in SIZE:
		var row: Array = []
		for c in SIZE:
			row.append(0)
		grid.append(row)

func _get_empty_cells() -> Array:
	var empty: Array = []
	for r in SIZE:
		for c in SIZE:
			if grid[r][c] == 0:
				empty.append(Vector2i(r, c))
	return empty

func _spawn_tile() -> bool:
	var empty: Array = _get_empty_cells()
	if empty.is_empty():
		return false
	var idx: int = randi() % empty.size()
	var pos: Vector2i = empty[idx]
	grid[pos.x][pos.y] = 4 if randf() < 0.1 else 2
	return true

func _slide_line(line: Array, reverse: bool) -> Dictionary:
	var nonzero: Array = []
	for v in line:
		if v > 0:
			nonzero.append(v)
	var result: Array = []
	var merged: Array = []
	var i: int = 0
	while i < nonzero.size():
		if i + 1 < nonzero.size() and nonzero[i] == nonzero[i + 1]:
			var val: int = nonzero[i] * 2
			result.append(val)
			merged.append(val)
			i += 2
		else:
			result.append(nonzero[i])
			i += 1
	if reverse:
		result.reverse()
		while result.size() < SIZE:
			result.insert(0, 0)
	else:
		while result.size() < SIZE:
			result.append(0)
	var add: int = 0
	for v in merged:
		add += v
	return {"line": result, "score": add}

func _slide_left() -> bool:
	var moved: bool = false
	var add_score: int = 0
	for r in SIZE:
		var line: Array = []
		for c in SIZE:
			line.append(grid[r][c])
		var res: Dictionary = _slide_line(line, false)
		for c in SIZE:
			if grid[r][c] != res["line"][c]:
				moved = true
			grid[r][c] = res["line"][c]
		add_score += res["score"]
	if moved:
		score += add_score
		if score > best_score:
			best_score = score
	return moved

func _slide_right() -> bool:
	var moved: bool = false
	var add_score: int = 0
	for r in SIZE:
		var line: Array = []
		for c in range(SIZE - 1, -1, -1):
			line.append(grid[r][c])
		var res: Dictionary = _slide_line(line, true)
		for c in SIZE:
			var new_val: int = res["line"][c]
			if grid[r][c] != new_val:
				moved = true
			grid[r][c] = new_val
		add_score += res["score"]
	if moved:
		score += add_score
		if score > best_score:
			best_score = score
	return moved

func _slide_up() -> bool:
	var moved: bool = false
	var add_score: int = 0
	for c in SIZE:
		var line: Array = []
		for r in SIZE:
			line.append(grid[r][c])
		var res: Dictionary = _slide_line(line, false)
		for r in SIZE:
			if grid[r][c] != res["line"][r]:
				moved = true
			grid[r][c] = res["line"][r]
		add_score += res["score"]
	if moved:
		score += add_score
		if score > best_score:
			best_score = score
	return moved

func _slide_down() -> bool:
	var moved: bool = false
	var add_score: int = 0
	for c in SIZE:
		var line: Array = []
		for r in range(SIZE - 1, -1, -1):
			line.append(grid[r][c])
		var res: Dictionary = _slide_line(line, true)
		for r in SIZE:
			var new_val: int = res["line"][r]
			if grid[r][c] != new_val:
				moved = true
			grid[r][c] = new_val
		add_score += res["score"]
	if moved:
		score += add_score
		if score > best_score:
			best_score = score
	return moved

func _can_move() -> bool:
	for r in SIZE:
		for c in SIZE:
			if grid[r][c] == 0:
				return true
			if c + 1 < SIZE and grid[r][c] == grid[r][c + 1]:
				return true
			if r + 1 < SIZE and grid[r][c] == grid[r + 1][c]:
				return true
	return false

func _has_2048() -> bool:
	for r in SIZE:
		for c in SIZE:
			if grid[r][c] == 2048:
				return true
	return false

func _do_move(dir: int) -> void:
	if not playing or game_over:
		return
	var moved: bool = false
	match dir:
		0: moved = _slide_left()
		1: moved = _slide_right()
		2: moved = _slide_up()
		3: moved = _slide_down()
	if moved:
		_spawn_tile()
		_update_display()
		_update_ui()
		if score >= 2048 and not GameState.tavern_2048_upgraded:
			_apply_tavern_upgrade()
		if not won and _has_2048():
			won = true
			win_panel.visible = true
			var win_text: String = tr("PUZZLE_WIN")
			if GameState.tavern_2048_upgraded:
				win_text += "\n" + tr("PUZZLE_UPGRADE")
			win_label.text = win_text
		elif not _can_move():
			game_over = true
			game_over_panel.visible = true
			game_over_label.text = tr("PUZZLE_GAME_OVER")

func _update_display() -> void:
	for r in SIZE:
		for c in SIZE:
			var cell: ColorRect = grid_container.get_node_or_null("Cell_%d_%d" % [r, c])
			if not cell:
				continue
			var val: int = grid[r][c]
			var color_key: int = val
			if val > 2048:
				color_key = 2048
			cell.color = TILE_COLORS.get(color_key, TILE_COLORS[2048])
			var lbl: Label = cell.get_node_or_null("ValueLabel")
			if lbl:
				lbl.text = str(val) if val > 0 else ""
				if val >= 128:
					lbl.add_theme_font_size_override("font_size", 20)
					lbl.add_theme_color_override("font_color", Color(1, 0.98, 0.9, 1))
				elif val >= 64:
					lbl.add_theme_font_size_override("font_size", 22)
					lbl.add_theme_color_override("font_color", Color(0.98, 0.95, 0.85, 1))
				else:
					lbl.add_theme_font_size_override("font_size", 24)
					lbl.add_theme_color_override("font_color", Color(0.15, 0.12, 0.08, 1))

func _update_ui() -> void:
	score_label.text = tr("PUZZLE_SCORE") % score
	best_label.text = tr("PUZZLE_BEST") % best_score

func _on_start_pressed() -> void:
	if playing and not game_over:
		return
	_start_game()

func _start_game() -> void:
	_init_grid()
	score = 0
	game_over = false
	won = false
	playing = true
	game_over_panel.visible = false
	win_panel.visible = false
	_spawn_tile()
	_spawn_tile()
	_update_display()
	_update_ui()

func _game_over() -> void:
	game_over_panel.visible = true
	game_over_label.text = tr("PUZZLE_GAME_OVER")

func _on_restart_pressed() -> void:
	_start_game()

func _on_continue_pressed() -> void:
	win_panel.visible = false
	# 계속 플레이

func _set_buttons_focus_none() -> void:
	for btn in [start_button, back_button, restart_button, help_button, game_over_restart, continue_button, help_close_btn]:
		btn.focus_mode = Control.FOCUS_NONE

func _apply_tavern_upgrade() -> void:
	GameState.tavern_2048_upgraded = true
	GameState.player_hp = 2000
	GameState.player_max_hp = 2000
	SaveManager.save_game()

func _on_help_pressed() -> void:
	help_panel.visible = true

func _on_help_close() -> void:
	help_panel.visible = false

func _on_back_pressed() -> void:
	SaveManager.save_game()
	SceneRouter.goto(WORLD_MAP_PATH)

func _unhandled_input(event: InputEvent) -> void:
	if event.is_echo():
		return
	if event.is_action_pressed("ui_left"):
		_do_move(0)
		get_viewport().set_input_as_handled()
	elif event.is_action_pressed("ui_right"):
		_do_move(1)
		get_viewport().set_input_as_handled()
	elif event.is_action_pressed("ui_up"):
		_do_move(2)
		get_viewport().set_input_as_handled()
	elif event.is_action_pressed("ui_down"):
		_do_move(3)
		get_viewport().set_input_as_handled()
