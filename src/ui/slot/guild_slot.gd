extends Control
## 길드 슬롯 머신 미니게임

const WORLD_MAP_PATH := "res://src/world/world_map.tscn"
const SPIN_COST: int = 5

# 심볼: 0=검, 1=방패, 2=동전, 3=별, 4=7
const SYMBOL_NAMES: Array[String] = ["⚔", "🛡", "🪙", "⭐", "7"]
# 3개 일치 보상
const PAYTABLE_3: Dictionary = {0: 25, 1: 30, 2: 20, 3: 40, 4: 50}
# 2개 일치 보상
const PAYTABLE_2: Dictionary = {0: 8, 1: 10, 2: 5, 3: 12, 4: 15}

var reels: Array = [0, 0, 0]  # [a, b, c]

@onready var reel1_label: Label = $VBox/GameArea/Margin/HBox/Reel1
@onready var reel2_label: Label = $VBox/GameArea/Margin/HBox/Reel2
@onready var reel3_label: Label = $VBox/GameArea/Margin/HBox/Reel3
@onready var gold_label: Label = $VBox/GameArea/Margin/GoldLabel
@onready var result_label: Label = $VBox/GameArea/Margin/ResultLabel
@onready var spin_button: Button = $VBox/Buttons/SpinButton
@onready var back_button: Button = $VBox/Buttons/BackButton
@onready var help_button: Button = $VBox/Buttons/HelpButton
@onready var help_panel: PanelContainer = $HelpPanel
@onready var help_label: Label = $HelpPanel/Margin/VBox/HelpLabel
@onready var help_close_btn: Button = $HelpPanel/Margin/VBox/CloseBtn

func _ready() -> void:
	add_to_group("i18n")
	help_panel.visible = false
	spin_button.pressed.connect(_on_spin_pressed)
	back_button.pressed.connect(_on_back_pressed)
	help_button.pressed.connect(_on_help_pressed)
	help_close_btn.pressed.connect(_on_help_close)
	_set_buttons_focus_none()
	refresh_text()
	_update_ui()

func _set_buttons_focus_none() -> void:
	for btn in [spin_button, back_button, help_button, help_close_btn]:
		btn.focus_mode = Control.FOCUS_NONE

func refresh_text() -> void:
	spin_button.text = tr("SLOT_SPIN")
	back_button.text = tr("BTN_BACK")
	help_button.text = tr("BTN_HELP")
	help_close_btn.text = tr("BTN_CLOSE")
	help_label.text = tr("HELP_SLOT")

func _update_ui() -> void:
	gold_label.text = "%s: %d" % [tr("HUD_GOLD"), GameState.gold]
	reel1_label.text = SYMBOL_NAMES[reels[0]]
	reel2_label.text = SYMBOL_NAMES[reels[1]]
	reel3_label.text = SYMBOL_NAMES[reels[2]]
	spin_button.disabled = GameState.gold < SPIN_COST

func _calc_payout() -> int:
	var a: int = reels[0]
	var b: int = reels[1]
	var c: int = reels[2]
	# 7,7,7 = 잭팟 1000 골드
	if a == 4 and b == 4 and c == 4:
		return 1000
	if a == b and b == c:
		return PAYTABLE_3.get(a, 20)
	if a == b:
		return PAYTABLE_2.get(a, 5)
	if b == c:
		return PAYTABLE_2.get(b, 5)
	if a == c:
		return PAYTABLE_2.get(a, 5)
	return 0

func _on_spin_pressed() -> void:
	if GameState.gold < SPIN_COST:
		result_label.text = tr("SLOT_NO_GOLD")
		return
	GameState.gold -= SPIN_COST
	reels[0] = randi() % 5
	reels[1] = randi() % 5
	reels[2] = randi() % 5
	var payout: int = _calc_payout()
	GameState.gold += payout
	SaveManager.save_game()
	_update_ui()
	if payout >= 1000:
		result_label.text = tr("SLOT_JACKPOT")
	elif payout > 0:
		result_label.text = tr("SLOT_WIN") % payout
	else:
		result_label.text = tr("SLOT_LOSE")

func _on_help_pressed() -> void:
	help_panel.visible = true

func _on_help_close() -> void:
	help_panel.visible = false

func _on_back_pressed() -> void:
	SaveManager.save_game()
	SceneRouter.goto(WORLD_MAP_PATH)
