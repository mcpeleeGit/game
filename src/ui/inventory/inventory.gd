extends Control
## 인벤토리: 보유 아이템 목록 표시, 선택 → 사용 (HP 회복 등)

const CASTLE_PATH := "res://src/regions/region_castle.tscn"
const TOAST_DURATION := 1.2

@onready var title_label: Label = $VBox/Title
@onready var hp_label: Label = $VBox/HPLabel
@onready var item_list: VBoxContainer = $VBox/HBox/ItemList
@onready var name_label: Label = $VBox/HBox/DetailPanel/Margin/DetailVBox/NameLabel
@onready var desc_label: Label = $VBox/HBox/DetailPanel/Margin/DetailVBox/DescLabel
@onready var count_label: Label = $VBox/HBox/DetailPanel/Margin/DetailVBox/CountLabel
@onready var use_button: Button = $VBox/HBox/DetailPanel/Margin/DetailVBox/UseButton
@onready var back_button: Button = $VBox/BackButton
@onready var toast_label: Label = $Toast

var selected_id: String = ""

func _ready() -> void:
	add_to_group("i18n")
	refresh_text()
	_build_item_list()
	_update_hp()
	_select_item("")
	back_button.pressed.connect(_on_back_pressed)
	use_button.pressed.connect(_on_use_pressed)

func refresh_text() -> void:
	title_label.text = tr("INVENTORY_TITLE")
	_update_hp()
	name_label.text = "-"
	desc_label.text = tr("INVENTORY_SELECT_HINT")
	count_label.text = ""
	use_button.text = tr("INVENTORY_USE")
	back_button.text = tr("BTN_BACK")

func _update_hp() -> void:
	hp_label.text = "%s: %d/%d" % [tr("HUD_HP"), GameState.player_hp, GameState.player_max_hp]

func _build_item_list() -> void:
	for child in item_list.get_children():
		child.queue_free()
	for item_id in ShopData.list_ids():
		var count: int = GameState.inventory.get(item_id, 0)
		if count <= 0:
			continue
		var btn := Button.new()
		var data: Dictionary = ShopData.get_item(item_id)
		btn.text = tr(data.get("name_key", item_id)) + " x" + str(count)
		btn.pressed.connect(_on_item_selected.bind(item_id))
		item_list.add_child(btn)

func _on_item_selected(item_id: String) -> void:
	selected_id = item_id
	_select_item(item_id)

func _select_item(item_id: String) -> void:
	selected_id = item_id
	if item_id.is_empty():
		name_label.text = "-"
		desc_label.text = tr("INVENTORY_SELECT_HINT")
		count_label.text = ""
		use_button.visible = false
		return
	var data: Dictionary = ShopData.get_item(item_id)
	name_label.text = tr(data.get("name_key", item_id))
	desc_label.text = tr(data.get("desc_key", ""))
	var count: int = GameState.inventory.get(item_id, 0)
	count_label.text = tr("INVENTORY_COUNT") % count
	use_button.visible = true
	use_button.disabled = count <= 0

func _on_use_pressed() -> void:
	if selected_id.is_empty():
		return
	_use_item(selected_id)

func _use_item(item_id: String) -> void:
	var count: int = GameState.inventory.get(item_id, 0)
	if count <= 0:
		return
	var data: Dictionary = ShopData.get_item(item_id)
	if data.is_empty():
		return
	match item_id:
		"potion_small":
			var heal: int = 20
			GameState.player_hp = mini(GameState.player_hp + heal, GameState.player_max_hp)
			GameState.inventory[item_id] = count - 1
			if GameState.inventory[item_id] <= 0:
				GameState.inventory.erase(item_id)
			SaveManager.save_game()
			_update_hp()
			_build_item_list()
			_select_item("")
			_show_toast(tr("INVENTORY_USE_SUCCESS") % [tr(data.get("name_key", item_id)), str(heal)])
		"potion_medium":
			var heal: int = 50
			GameState.player_hp = mini(GameState.player_hp + heal, GameState.player_max_hp)
			GameState.inventory[item_id] = count - 1
			if GameState.inventory[item_id] <= 0:
				GameState.inventory.erase(item_id)
			SaveManager.save_game()
			_update_hp()
			_build_item_list()
			_select_item("")
			_show_toast(tr("INVENTORY_USE_SUCCESS") % [tr(data.get("name_key", item_id)), str(heal)])
		"antidote":
			# TODO: 독 제거 로직 (현재는 사용만)
			GameState.inventory[item_id] = count - 1
			if GameState.inventory[item_id] <= 0:
				GameState.inventory.erase(item_id)
			SaveManager.save_game()
			_build_item_list()
			_select_item("")
			_show_toast(tr("INVENTORY_USE_SUCCESS_ANTIDOTE") % tr(data.get("name_key", item_id)))

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
