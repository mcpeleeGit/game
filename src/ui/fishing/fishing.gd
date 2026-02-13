extends Control
## 낚시 게임: 타이밍 게임 (진행 바가 움직이고 타겟 구간에서 클릭)

const WORLD_MAP_PATH := "res://src/world/world_map.tscn"

@onready var hint_label: Label = $VBox/GameArea/Margin/VBoxGame/HintLabel
@onready var bar_container: Control = $VBox/GameArea/Margin/VBoxGame/BarContainer
@onready var bar_indicator: ColorRect = $VBox/GameArea/Margin/VBoxGame/BarContainer/BarIndicator
@onready var target_zone: ColorRect = $VBox/GameArea/Margin/VBoxGame/BarContainer/TargetZone
@onready var status_label: Label = $VBox/GameArea/Margin/VBoxGame/StatusLabel
@onready var result_label: Label = $VBox/GameArea/Margin/VBoxGame/ResultLabel
@onready var result_sprite: TextureRect = $VBox/GameArea/Margin/VBoxGame/ResultSprite
@onready var start_button: Button = $VBox/Buttons/StartButton
@onready var catch_button: Button = $VBox/Buttons/CatchButton
@onready var back_button: Button = $VBox/Buttons/BackButton
@onready var help_button: Button = $VBox/Buttons/HelpButton
@onready var help_panel: PanelContainer = $HelpPanel
@onready var help_label: Label = $HelpPanel/Margin/VBox/HelpLabel
@onready var help_close_btn: Button = $HelpPanel/Margin/VBox/CloseBtn

var is_fishing: bool = false
var bar_position: float = 0.0  # 0.0 ~ 1.0
var bar_direction: float = 1.0  # 1.0 = 오른쪽, -1.0 = 왼쪽
var bar_speed: float = 0.02
var target_start: float = 0.4  # 타겟 구간 시작 (0.0~1.0)
var target_end: float = 0.6  # 타겟 구간 끝
var can_catch: bool = false
var fish_timer: float = 0.0
const FISH_TIMEOUT: float = 5.0  # 5초 안에 안 누르면 실패

func _ready() -> void:
	add_to_group("i18n")
	refresh_text()
	result_sprite.visible = false
	catch_button.visible = false
	start_button.pressed.connect(_on_start_pressed)
	catch_button.pressed.connect(_on_catch_pressed)
	back_button.pressed.connect(_on_back_pressed)
	bar_container.gui_input.connect(_on_bar_input)
	help_button.pressed.connect(_on_help_pressed)
	help_close_btn.pressed.connect(_on_help_close)
	help_panel.visible = false
	_set_buttons_focus_none()

func _set_buttons_focus_none() -> void:
	for btn in [start_button, catch_button, back_button, help_button, help_close_btn]:
		btn.focus_mode = Control.FOCUS_NONE

func refresh_text() -> void:
	hint_label.text = tr("FISHING_HINT")
	status_label.text = tr("FISHING_READY")
	result_label.text = ""
	start_button.text = tr("FISHING_START")
	catch_button.text = tr("FISHING_CATCH")
	back_button.text = tr("BTN_BACK")
	help_button.text = tr("BTN_HELP")
	help_close_btn.text = tr("BTN_CLOSE")
	help_label.text = tr("HELP_FISHING")

func _process(delta: float) -> void:
	if not is_fishing:
		return
	fish_timer += delta
	if fish_timer >= FISH_TIMEOUT:
		_try_catch(true)  # 시간 초과 → 실패
		return
	bar_position += bar_direction * bar_speed
	if bar_position >= 1.0:
		bar_position = 1.0
		bar_direction = -1.0
	elif bar_position <= 0.0:
		bar_position = 0.0
		bar_direction = 1.0
	var bar_width: float = bar_container.size.x
	if bar_width > 0:
		bar_indicator.position.x = bar_position * bar_width - bar_indicator.size.x / 2.0
		var target_zone_width: float = (target_end - target_start) * bar_width
		target_zone.size.x = target_zone_width
		target_zone.position.x = target_start * bar_width - target_zone_width / 2.0
	can_catch = bar_position >= target_start and bar_position <= target_end
	if can_catch:
		target_zone.modulate = Color(0.3, 1.0, 0.4, 0.6)
	else:
		target_zone.modulate = Color(0.2, 0.8, 0.3, 0.4)

func _on_start_pressed() -> void:
	if is_fishing:
		return
	is_fishing = true
	fish_timer = 0.0
	start_button.disabled = true
	catch_button.visible = true
	catch_button.disabled = false
	result_sprite.visible = false
	status_label.text = tr("FISHING_IN_PROGRESS")
	result_label.text = ""
	hint_label.text = tr("FISHING_HINT")
	bar_position = 0.0
	bar_direction = 1.0
	can_catch = false

func _on_catch_pressed() -> void:
	if not is_fishing:
		return
	_try_catch()

func _on_bar_input(event: InputEvent) -> void:
	if not is_fishing:
		return
	if not (event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT):
		return
	_try_catch()

func _try_catch(force_fail: bool = false) -> void:
	if not is_fishing:
		return
	is_fishing = false
	can_catch = false if force_fail else can_catch
	start_button.disabled = false
	catch_button.visible = false
	result_sprite.visible = true
	if can_catch:
		var gold_reward: int = randi_range(5, 15)
		var item_chance: int = randi_range(1, 100)
		var got_item: bool = item_chance <= 30  # 30% 확률로 포션
		if got_item:
			GameState.inventory["potion_small"] = GameState.inventory.get("potion_small", 0) + 1
		GameState.gold += gold_reward
		SaveManager.save_game()
		status_label.text = tr("FISHING_SUCCESS")
		if got_item:
			result_label.text = tr("FISHING_REWARD_ITEM") % [gold_reward, tr("ITEM_POTION_SMALL")]
		else:
			result_label.text = tr("FISHING_REWARD") % gold_reward
		hint_label.text = tr("FISHING_SUCCESS_HINT")
		var tex := load("res://assets/images/fishing/fish_success.png") as Texture2D
		result_sprite.texture = tex if tex else null
	else:
		status_label.text = tr("FISHING_FAIL")
		result_label.text = ""
		hint_label.text = tr("FISHING_FAIL_HINT")
		var tex := load("res://assets/images/fishing/fish_fail.png") as Texture2D
		result_sprite.texture = tex if tex else null

func _on_help_pressed() -> void:
	help_panel.visible = true

func _on_help_close() -> void:
	help_panel.visible = false

func _on_back_pressed() -> void:
	SaveManager.save_game()
	SceneRouter.goto(WORLD_MAP_PATH)
