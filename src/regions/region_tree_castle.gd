extends Node2D
## 나무성 허브: 방어전 시작 (난이도 선택) → TD 게임

const WORLD_MAP_PATH := "res://src/world/world_map.tscn"
const TD_PATH := "res://src/ui/tower_defense/tree_castle_td.tscn"
const BG_PATH := "res://assets/images/backgrounds/tree_castle_intro.png"
const BG_FALLBACK := "res://assets/images/backgrounds/forest_intro.png"

@onready var title_label: Label = $UI/Title
@onready var intro_message: Label = $UI/IntroMessage
@onready var start_normal_button: Button = $UI/StartNormalButton
@onready var start_hard_button: Button = $UI/StartHardButton
@onready var back_button: Button = $UI/BackButton

func _ready() -> void:
	add_to_group("i18n")
	refresh_text()
	_apply_texture($BgSprite, BG_PATH, true)
	start_normal_button.pressed.connect(_on_start_normal_pressed)
	start_hard_button.pressed.connect(_on_start_hard_pressed)
	back_button.pressed.connect(_on_back_pressed)

func refresh_text() -> void:
	title_label.text = tr("MAP_TREE_CASTLE")
	intro_message.text = tr("FLAVOR_TREE_CASTLE")
	start_normal_button.text = tr("BTN_START_DEFENSE") + " (" + tr("TD_NORMAL") + ")"
	start_hard_button.text = tr("BTN_START_DEFENSE") + " (" + tr("TD_HARD") + ")"
	back_button.text = tr("BTN_BACK")

func _on_start_normal_pressed() -> void:
	GameState.td_difficulty = "normal"
	SceneRouter.goto(TD_PATH)

func _on_start_hard_pressed() -> void:
	GameState.td_difficulty = "hard"
	SceneRouter.goto(TD_PATH)

func _apply_texture(sprite: Sprite2D, path: String, scale_to_viewport: bool) -> void:
	var tex := load(path) as Texture2D
	if not tex:
		tex = load(BG_FALLBACK) as Texture2D
	if tex and tex.get_width() * tex.get_height() < 100:
		tex = load(BG_FALLBACK) as Texture2D
	if not tex:
		return
	sprite.texture = tex
	if scale_to_viewport:
		var view: Vector2 = get_viewport_rect().size
		var ts: Vector2 = (tex as Texture2D).get_size()
		var s: float = maxf(view.x / ts.x, view.y / ts.y)
		sprite.scale = Vector2(s, s)

func _on_back_pressed() -> void:
	SaveManager.save_game()
	SceneRouter.goto(WORLD_MAP_PATH)
