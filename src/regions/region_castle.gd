extends Node2D
## 성 인트로: 성 안 구성(상점 등) 안내 후 상점 선택 → 상점 씬

const WORLD_MAP_PATH := "res://src/world/world_map.tscn"
const SHOP_PATH := "res://src/ui/shop/shop.tscn"
const INVENTORY_PATH := "res://src/ui/inventory/inventory.tscn"
const BG_PATH := "res://assets/images/backgrounds/castle_intro.png"

@onready var title_label: Label = $UI/Title
@onready var intro_message: Label = $UI/IntroMessage
@onready var shop_button: Button = $UI/ShopButton
@onready var inventory_button: Button = $UI/InventoryButton
@onready var back_button: Button = $UI/BackButton

func _ready() -> void:
	add_to_group("i18n")
	refresh_text()
	_apply_texture($BgSprite, BG_PATH, true)
	shop_button.pressed.connect(_on_shop_pressed)
	inventory_button.pressed.connect(_on_inventory_pressed)
	back_button.pressed.connect(_on_back_pressed)

func refresh_text() -> void:
	title_label.text = tr("MAP_CASTLE")
	intro_message.text = tr("CASTLE_INTRO")
	shop_button.text = tr("BTN_SHOP")
	inventory_button.text = tr("BTN_INVENTORY")
	back_button.text = tr("BTN_BACK")

func _on_shop_pressed() -> void:
	SceneRouter.goto(SHOP_PATH)

func _on_inventory_pressed() -> void:
	SceneRouter.goto(INVENTORY_PATH)

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

func _on_back_pressed() -> void:
	SaveManager.save_game()
	SceneRouter.goto(WORLD_MAP_PATH)
