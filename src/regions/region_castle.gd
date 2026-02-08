extends Node2D
## 성 인트로: 성 안 구성(상점 등) 안내 후 상점 선택 → 상점 씬

const WORLD_MAP_PATH := "res://src/world/world_map.tscn"
const SHOP_PATH := "res://src/ui/shop/shop.tscn"

@onready var title_label: Label = $UI/Title
@onready var intro_message: Label = $UI/IntroMessage
@onready var shop_button: Button = $UI/ShopButton
@onready var back_button: Button = $UI/BackButton

func _ready() -> void:
	add_to_group("i18n")
	refresh_text()
	shop_button.pressed.connect(_on_shop_pressed)
	back_button.pressed.connect(_on_back_pressed)

func refresh_text() -> void:
	title_label.text = tr("MAP_CASTLE")
	intro_message.text = tr("CASTLE_INTRO")
	shop_button.text = tr("BTN_SHOP")
	back_button.text = tr("BTN_BACK")

func _on_shop_pressed() -> void:
	SceneRouter.goto(SHOP_PATH)

func _on_back_pressed() -> void:
	SaveManager.save_game()
	SceneRouter.goto(WORLD_MAP_PATH)
