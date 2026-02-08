extends Node2D
## 숲 지역: 진입 메시지 → (첫 방문 시) 4초 후 강제 첫 전투 → 이후 전투 시작 버튼

const BG_PATH := "res://assets/images/backgrounds/forest_intro.png"
const PLAYER_SCENE := "res://src/player/player.tscn"
const BATTLE_PATH := "res://src/battle/battle.tscn"
const WORLD_MAP_PATH := "res://src/world/world_map.tscn"
const INTRO_MESSAGE_TIME := 3.0
const FIRST_BATTLE_DELAY := 5.0

@onready var region_title: Label = $UI/Label
@onready var intro_message: Label = $UI/IntroMessage
@onready var region_hint: Label = $UI/RegionHint
@onready var fight_button: Button = $UI/FightButton
@onready var back_button: Button = $UI/BackButton

func _ready() -> void:
	add_to_group("i18n")
	refresh_text()
	_apply_texture($BgSprite, BG_PATH, true)
	var player := load(PLAYER_SCENE) as PackedScene
	if player:
		var p := player.instantiate()
		p.global_position = $PlayerSpawn.global_position
		p.scale = Vector2(0.5, 0.5)
		add_child(p)
	fight_button.pressed.connect(_start_battle)
	back_button.pressed.connect(_go_back)
	if GameState.first_battle_done:
		intro_message.visible = false
		region_hint.visible = true
		fight_button.visible = true
		back_button.visible = true
	else:
		fight_button.visible = false
		back_button.visible = false
		intro_message.visible = true
		intro_message.modulate.a = 1.0
		var t := create_tween()
		t.tween_interval(INTRO_MESSAGE_TIME)
		t.tween_property(intro_message, "modulate:a", 0.0, 0.5)
		t.tween_callback(func() -> void: intro_message.visible = false)
		t.tween_interval(maxf(0.0, FIRST_BATTLE_DELAY - INTRO_MESSAGE_TIME - 0.5))
		t.tween_callback(_trigger_first_battle)

func refresh_text() -> void:
	if GameState.current_region_id == "ruins":
		region_title.text = tr("MAP_RUINS")
		intro_message.text = tr("REGION_INTRO_RUINS")
		region_hint.text = tr("HINT_RUINS")
		fight_button.text = tr("BTN_INVESTIGATE_RUINS")
	else:
		region_title.text = tr("MAP_FOREST")
		intro_message.text = tr("REGION_INTRO")
		region_hint.text = tr("HINT_FOREST_CLEAR")
		fight_button.text = tr("BTN_FIGHT")
	back_button.text = tr("BTN_BACK")

func _trigger_first_battle() -> void:
	if GameState.first_battle_done:
		return
	GameState.is_first_battle = true
	SceneRouter.goto(BATTLE_PATH)

func _apply_texture(sprite: Sprite2D, path: String, scale_to_viewport: bool) -> void:
	var tex := load(path) as Texture2D
	if not tex:
		return
	sprite.texture = tex
	if scale_to_viewport:
		var view: Vector2 = get_viewport_rect().size
		var ts: Vector2 = (tex as Texture2D).get_size()
		var s: float = maxf(view.x / ts.x, view.y / ts.y)
		sprite.scale = Vector2(s, s)

func _start_battle() -> void:
	GameState.is_first_battle = false
	SceneRouter.goto(BATTLE_PATH)

func _go_back() -> void:
	SaveManager.save_game()
	SceneRouter.goto(WORLD_MAP_PATH)
