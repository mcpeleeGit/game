extends Control
## 아이템 상점: 목록 선택 → 상세 → 골드로 구매, 인벤토리 반영·저장

const WORLD_MAP_PATH := "res://src/world/world_map.tscn"
const CASTLE_PATH := "res://src/regions/region_castle.tscn"
const TOAST_DURATION := 1.2

@onready var title_label: Label = $VBox/Title
@onready var gold_label: Label = $VBox/GoldLabel
@onready var item_list: VBoxContainer = $VBox/HBox/ItemList
@onready var name_label: Label = $VBox/HBox/DetailPanel/Margin/DetailVBox/NameLabel
@onready var desc_label: Label = $VBox/HBox/DetailPanel/Margin/DetailVBox/DescLabel
@onready var price_label: Label = $VBox/HBox/DetailPanel/Margin/DetailVBox/PriceLabel
@onready var buy_button: Button = $VBox/HBox/DetailPanel/Margin/DetailVBox/BuyButton
@onready var back_button: Button = $VBox/BackButton
@onready var toast_label: Label = $Toast

var selected_id: String = ""

func _ready() -> void:
	add_to_group("i18n")
	refresh_text()
	_build_item_list()
	_refresh_gold()
	_select_item("")
	back_button.pressed.connect(_on_back_pressed)
	buy_button.pressed.connect(_on_buy_pressed)

func refresh_text() -> void:
	title_label.text = tr("SHOP_TITLE")
	gold_label.text = tr("SHOP_GOLD") % GameState.gold
	price_label.text = ""
	name_label.text = "-"
	desc_label.text = tr("SHOP_SELECT_HINT")
	buy_button.text = tr("SHOP_BUY")
	back_button.text = tr("BTN_BACK")

func _build_item_list() -> void:
	for child in item_list.get_children():
		child.queue_free()
	for item_id in ShopData.list_ids():
		var btn := Button.new()
		var data: Dictionary = ShopData.get_item(item_id)
		btn.text = tr(data.get("name_key", item_id))
		btn.pressed.connect(_on_item_selected.bind(item_id))
		item_list.add_child(btn)

func _on_item_selected(item_id: String) -> void:
	selected_id = item_id
	_select_item(item_id)

func _select_item(item_id: String) -> void:
	selected_id = item_id
	if item_id.is_empty():
		name_label.text = "-"
		desc_label.text = tr("SHOP_SELECT_HINT")
		price_label.text = ""
		buy_button.visible = false
		return
	var data: Dictionary = ShopData.get_item(item_id)
	name_label.text = tr(data.get("name_key", item_id))
	desc_label.text = tr(data.get("desc_key", ""))
	var price: int = data.get("price", 0)
	price_label.text = tr("SHOP_PRICE") + ": " + str(price) + " G"
	buy_button.visible = true
	buy_button.disabled = GameState.gold < price

func _refresh_gold() -> void:
	gold_label.text = tr("SHOP_GOLD") % GameState.gold
	if selected_id != "":
		var data: Dictionary = ShopData.get_item(selected_id)
		buy_button.disabled = GameState.gold < data.get("price", 0)

func _on_buy_pressed() -> void:
	if selected_id.is_empty():
		return
	_try_buy(selected_id)

func _try_buy(item_id: String) -> void:
	var data: Dictionary = ShopData.get_item(item_id)
	if data.is_empty():
		return
	var price: int = data.get("price", 0)
	if GameState.gold < price:
		_show_toast(tr("SHOP_NOT_ENOUGH_GOLD"))
		return
	GameState.gold -= price
	GameState.inventory[item_id] = int(GameState.inventory.get(item_id, 0)) + 1
	SaveManager.save_game()
	_refresh_gold()
	_show_toast(tr("SHOP_BUY_SUCCESS") % tr(data.get("name_key", item_id)))
	# 상세 패널 갱신 (골드 부족 시 구매 버튼 비활성)
	_select_item(selected_id)

func _show_toast(message: String) -> void:
	toast_label.text = message
	toast_label.visible = true
	toast_label.modulate.a = 1.0
	var t := create_tween()
	t.tween_interval(TOAST_DURATION)
	t.tween_property(toast_label, "modulate:a", 0.0, 0.2)
	t.tween_callback(func() -> void: toast_label.visible = false)

func _on_back_pressed() -> void:
	SaveManager.save_game()
	SceneRouter.goto(CASTLE_PATH)
