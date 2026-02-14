extends Control
## 숲 소코반 - 상자를 목표에 밀어넣는 퍼즐 게임

const WORLD_MAP_PATH := "res://src/world/world_map.tscn"
const TILE_SIZE: int = 48
const REWARD_PER_LEVEL: int = 10

const WALL_PATH := "res://assets/images/sokoban/sokoban_wall.png"
const FLOOR_PATH := "res://assets/images/sokoban/sokoban_floor.png"
const PLAYER_PATH := "res://assets/images/sokoban/sokoban_player.png"
const BOX_PATH := "res://assets/images/sokoban/sokoban_box.png"
const GOAL_PATH := "res://assets/images/sokoban/sokoban_goal.png"

enum Cell { EMPTY, WALL, PLAYER, BOX, GOAL, BOX_ON_GOAL }

## 레벨 데이터: [row][col]. 0=빈칸, 1=벽, 2=플레이어, 3=상자, 4=목표, 5=상자+목표
const LEVELS: Array = [
	[
		[1,1,1,1,1,1,1],
		[1,4,0,0,0,0,1],
		[1,0,0,3,0,0,1],
		[1,0,0,2,0,0,1],
		[1,0,0,0,0,0,1],
		[1,1,1,1,1,1,1],
	],
	[
		[1,1,1,1,1,1,1,1],
		[1,4,0,0,0,0,4,1],
		[1,0,3,0,0,3,0,1],
		[1,0,0,2,0,0,0,1],
		[1,0,0,0,0,0,0,1],
		[1,1,1,1,1,1,1,1],
	],
	[
		[1,1,1,1,1,1,1,1,1],
		[1,4,0,0,1,0,0,4,1],
		[1,0,3,0,1,0,3,0,1],
		[1,0,0,0,0,0,0,0,1],
		[1,0,0,0,2,0,0,0,1],
		[1,0,0,0,0,0,0,0,1],
		[1,1,1,1,1,1,1,1,1],
	],
]

var level_data: Array = []
var player_pos: Vector2i = Vector2i.ZERO
var moves: int = 0
var current_level: int = 0
var playing: bool = false
var level_cleared: Array[bool] = [false, false, false]

@onready var game_area: Control = $VBox/GameArea
@onready var level_label: Label = $VBox/HBox/LevelLabel
@onready var moves_label: Label = $VBox/HBox/MovesLabel
@onready var reward_label: Label = $VBox/HBox/RewardLabel
@onready var start_btn: Button = $VBox/Buttons/StartButton
@onready var prev_level_btn: Button = $VBox/Buttons/PrevLevelBtn
@onready var next_level_btn: Button = $VBox/Buttons/NextLevelBtn
@onready var back_btn: Button = $VBox/Buttons/BackButton
@onready var help_btn: Button = $VBox/Buttons/HelpButton
@onready var result_panel: PanelContainer = $ResultPanel
@onready var result_label: Label = $ResultPanel/Margin/VBox/ResultLabel
@onready var reward_result_label: Label = $ResultPanel/Margin/VBox/RewardResultLabel
@onready var continue_btn: Button = $ResultPanel/Margin/VBox/ContinueBtn
@onready var help_panel: PanelContainer = $HelpPanel
@onready var help_label: Label = $HelpPanel/Margin/VBox/HelpLabel
@onready var close_help_btn: Button = $HelpPanel/Margin/VBox/CloseBtn

func _ready() -> void:
	add_to_group("i18n")
	refresh_text()
	result_panel.visible = false
	help_panel.visible = false
	start_btn.pressed.connect(_on_start)
	prev_level_btn.pressed.connect(_on_prev_level)
	next_level_btn.pressed.connect(_on_next_level)
	back_btn.pressed.connect(_on_back)
	help_btn.pressed.connect(_on_help)
	continue_btn.pressed.connect(_on_continue)
	close_help_btn.pressed.connect(_on_close_help)
	_set_buttons_focus_none()
	_load_level(current_level)
	_draw_grid()

func _set_buttons_focus_none() -> void:
	for btn in [start_btn, prev_level_btn, next_level_btn, back_btn, help_btn, continue_btn, close_help_btn]:
		btn.focus_mode = Control.FOCUS_NONE

func refresh_text() -> void:
	start_btn.text = tr("SOKOBAN_START")
	prev_level_btn.text = tr("SOKOBAN_PREV")
	next_level_btn.text = tr("SOKOBAN_NEXT")
	back_btn.text = tr("BTN_BACK")
	help_btn.text = tr("BTN_HELP")
	continue_btn.text = tr("BTN_CONTINUE")
	close_help_btn.text = tr("BTN_CLOSE")
	help_label.text = tr("HELP_SOKOBAN")

func _load_level(idx: int) -> void:
	if idx < 0 or idx >= LEVELS.size():
		return
	current_level = idx
	level_data.clear()
	for row in LEVELS[idx]:
		level_data.append(row.duplicate())
	for r in level_data.size():
		for c in level_data[r].size():
			if level_data[r][c] == Cell.PLAYER:
				player_pos = Vector2i(c, r)
				break
	moves = 0
	_update_labels()
	prev_level_btn.disabled = idx <= 0
	next_level_btn.disabled = idx >= LEVELS.size() - 1

func _update_labels() -> void:
	level_label.text = tr("SOKOBAN_LEVEL") % (current_level + 1)
	moves_label.text = tr("SOKOBAN_MOVES") % moves
	reward_label.text = tr("SOKOBAN_REWARD") % REWARD_PER_LEVEL

func _draw_grid() -> void:
	for c in game_area.get_children():
		c.queue_free()
	if level_data.is_empty():
		return
	var rows: int = level_data.size()
	var cols: int = level_data[0].size()
	for r in rows:
		for c in cols:
			var cell_val: int = level_data[r][c]
			var node: Control
			var color: Color
			var tex_path: String = ""
			match cell_val:
				Cell.WALL:
					tex_path = WALL_PATH
					color = Color(0.3, 0.25, 0.2, 1)
				Cell.EMPTY, Cell.PLAYER:
					tex_path = FLOOR_PATH
					color = Color(0.4, 0.35, 0.28, 1)
				Cell.BOX:
					tex_path = BOX_PATH
					color = Color(0.6, 0.4, 0.2, 1)
				Cell.GOAL:
					tex_path = GOAL_PATH
					color = Color(0.3, 0.6, 0.4, 0.8)
				Cell.BOX_ON_GOAL:
					tex_path = BOX_PATH
					color = Color(0.5, 0.7, 0.4, 1)
			var tex := load(tex_path) as Texture2D
			if tex and tex.get_width() * tex.get_height() >= 100:
				var img: Image = tex.get_image()
				if img:
					img.resize(TILE_SIZE - 2, TILE_SIZE - 2)
					tex = ImageTexture.create_from_image(img)
				var tr_rect := TextureRect.new()
				tr_rect.texture = tex
				tr_rect.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
				tr_rect.custom_minimum_size = Vector2(TILE_SIZE - 2, TILE_SIZE - 2)
				tr_rect.size = Vector2(TILE_SIZE - 2, TILE_SIZE - 2)
				node = tr_rect
			else:
				var cr := ColorRect.new()
				cr.color = color
				cr.custom_minimum_size = Vector2(TILE_SIZE - 2, TILE_SIZE - 2)
				cr.size = Vector2(TILE_SIZE - 2, TILE_SIZE - 2)
				node = cr
			node.position = Vector2(c * TILE_SIZE, r * TILE_SIZE)
			node.mouse_filter = Control.MOUSE_FILTER_IGNORE
			node.name = "Tile_%d_%d" % [r, c]
			game_area.add_child(node)
			if cell_val == Cell.PLAYER:
				var player_tex := load(PLAYER_PATH) as Texture2D
				if player_tex and player_tex.get_width() * player_tex.get_height() >= 100:
					var pimg: Image = player_tex.get_image()
					if pimg:
						pimg.resize(TILE_SIZE - 4, TILE_SIZE - 4)
						player_tex = ImageTexture.create_from_image(pimg)
					var pl := TextureRect.new()
					pl.texture = player_tex
					pl.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
					pl.custom_minimum_size = Vector2(TILE_SIZE - 4, TILE_SIZE - 4)
					pl.size = Vector2(TILE_SIZE - 4, TILE_SIZE - 4)
					pl.position = Vector2(c * TILE_SIZE + 2, r * TILE_SIZE + 2)
					pl.mouse_filter = Control.MOUSE_FILTER_IGNORE
					pl.z_index = 1
					game_area.add_child(pl)
	game_area.custom_minimum_size = Vector2(cols * TILE_SIZE, rows * TILE_SIZE)

func _unhandled_input(event: InputEvent) -> void:
	if not playing or result_panel.visible:
		return
	var dir := Vector2i.ZERO
	if event.is_action_pressed("ui_left"):
		dir = Vector2i(-1, 0)
	elif event.is_action_pressed("ui_right"):
		dir = Vector2i(1, 0)
	elif event.is_action_pressed("ui_up"):
		dir = Vector2i(0, -1)
	elif event.is_action_pressed("ui_down"):
		dir = Vector2i(0, 1)
	if dir != Vector2i.ZERO:
		_try_move(dir)
		get_viewport().set_input_as_handled()

func _try_move(dir: Vector2i) -> void:
	var next := player_pos + dir
	if _out_of_bounds(next):
		return
	var next_val: int = _get_cell(next)
	if next_val == Cell.WALL:
		return
	if next_val == Cell.BOX or next_val == Cell.BOX_ON_GOAL:
		var beyond := next + dir
		if _out_of_bounds(beyond):
			return
		var beyond_val: int = _get_cell(beyond)
		if beyond_val == Cell.WALL or beyond_val == Cell.BOX or beyond_val == Cell.BOX_ON_GOAL:
			return
		var was_goal: bool = next_val == Cell.BOX_ON_GOAL
		var beyond_goal: bool = beyond_val == Cell.GOAL
		_set_cell(next, Cell.GOAL if was_goal else Cell.EMPTY)
		_set_cell(beyond, Cell.BOX_ON_GOAL if beyond_goal else Cell.BOX)
		player_pos = next
		_set_cell(player_pos - dir, Cell.EMPTY)
		_set_cell(player_pos, Cell.PLAYER)
		moves += 1
		var sfx := get_node_or_null("/root/SoundFx")
		if sfx:
			sfx.play_sokoban_push()
	else:
		_set_cell(player_pos, Cell.EMPTY)
		player_pos = next
		_set_cell(player_pos, Cell.PLAYER)
		moves += 1
		var sfx := get_node_or_null("/root/SoundFx")
		if sfx:
			sfx.play_sokoban_step()
	_update_labels()
	_draw_grid()
	if _check_win():
		_on_level_clear()

func _out_of_bounds(p: Vector2i) -> bool:
	return p.y < 0 or p.y >= level_data.size() or p.x < 0 or p.x >= level_data[0].size()

func _get_cell(p: Vector2i) -> int:
	return level_data[p.y][p.x]

func _set_cell(p: Vector2i, val: int) -> void:
	level_data[p.y][p.x] = val

func _check_win() -> bool:
	for row in level_data:
		for v in row:
			if v == Cell.BOX:
				return false
	return true

func _on_level_clear() -> void:
	playing = false
	if current_level < level_cleared.size():
		level_cleared[current_level] = true
	GameState.gold += REWARD_PER_LEVEL
	SaveManager.save_game()
	var sfx := get_node_or_null("/root/SoundFx")
	if sfx:
		sfx.play_sokoban_win()
	result_label.text = tr("SOKOBAN_CLEAR")
	result_label.add_theme_color_override("font_color", Color(0.4, 0.9, 0.4))
	reward_result_label.text = "+%d %s" % [REWARD_PER_LEVEL, tr("HUD_GOLD")]
	result_panel.visible = true

func _on_start() -> void:
	_load_level(current_level)
	_draw_grid()
	playing = true
	start_btn.disabled = true

func _on_prev_level() -> void:
	_load_level(current_level - 1)
	_draw_grid()
	start_btn.disabled = false

func _on_next_level() -> void:
	_load_level(current_level + 1)
	_draw_grid()
	start_btn.disabled = false

func _on_back() -> void:
	SaveManager.save_game()
	SceneRouter.goto(WORLD_MAP_PATH)

func _on_help() -> void:
	help_panel.visible = true

func _on_close_help() -> void:
	help_panel.visible = false

func _on_continue() -> void:
	result_panel.visible = false
	if current_level < LEVELS.size() - 1:
		_load_level(current_level + 1)
		_draw_grid()
		start_btn.disabled = false
	else:
		start_btn.disabled = false
