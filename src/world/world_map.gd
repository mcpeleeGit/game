extends Node2D
## 월드맵: 지도 + 지역 핫스팟 클릭 → 지역 카드 → 지역 씬
## 첫 진입: 페이드 + 목표 한 줄 (2초 후 사라짐)
## 첫 클릭: 1회성 토스트 → 지역 카드 → 진입 (is_transitioning으로 중복 클릭 방지)

const MAP_PATHS := ["res://assets/world_map.png", "res://assets/images/backgrounds/world_forest.png"]
const FADE_DURATION := 0.4
const GOAL_DISPLAY_TIME := 2.0
const REGION_CARD_TIME := 1.0
const TOAST_TIME := 1.0

## MapSprite 중심(0,0) 기준 로컬 좌표. Hotspot.position = MapSprite.position + 이 값
const REGION_POSITIONS: Dictionary = {
	"forest": Vector2(240, -80),
	"sokoban": Vector2(240, -180),  # 숲 위
	"tree_castle": Vector2(360, -80),  # 숲 오른쪽 나무성
	"ruins": Vector2(240, 60),
	"pond": Vector2(180, 100),  # 유적 아래 왼쪽
	"beach": Vector2(180, 180),  # 연못 아래
	"lighthouse": Vector2(300, 220),  # 해변 아래 오른쪽 등대
	"tavern": Vector2(-80, 55),  # 성 왼쪽 아래 건물
	"guild": Vector2(-200, 40),  # 선술집 왼쪽 더 큰 건물
	"library": Vector2(-310, 15),  # 길드 왼쪽 위 건물
	"castle": Vector2(0, -35),  # 성 버튼 위로
	"volcano": Vector2(-40, -160),
	"snow": Vector2(-300, -180),
}

## region_id → { name_key, level, flavor_key, scene, toast_key, requires?, locked_reason_key? }
const REGIONS: Dictionary = {
	"forest": {
		"name_key": "MAP_FOREST",
		"level": 1,
		"flavor_key": "FLAVOR_FOREST",
		"scene": "res://src/regions/region_forest.tscn",
		"toast_key": "TOAST_FOREST",
	},
	"tree_castle": {
		"name_key": "MAP_TREE_CASTLE",
		"level": 2,
		"flavor_key": "FLAVOR_TREE_CASTLE",
		"scene": "res://src/regions/region_tree_castle.tscn",
		"toast_key": "TOAST_TREE_CASTLE",
	},
	"ruins": {
		"name_key": "MAP_RUINS",
		"level": 3,
		"flavor_key": "FLAVOR_RUINS",
		"scene": "res://src/regions/region_forest.tscn",
		"toast_key": "TOAST_RUINS",
		"requires": "forest_cleared_once",
		"locked_reason_key": "LOCKED_REASON_FOREST",
	},
	"castle": {
		"name_key": "MAP_CASTLE",
		"level": 0,
		"flavor_key": "FLAVOR_CASTLE",
		"scene": "res://src/regions/region_castle.tscn",
		"toast_key": "TOAST_CASTLE",
	},
	"volcano": {
		"name_key": "MAP_VOLCANO",
		"level": 6,
		"flavor_key": "FLAVOR_VOLCANO",
		"scene": "res://src/regions/region_forest.tscn",
		"toast_key": "TOAST_VOLCANO",
	},
}

var is_transitioning := false

@onready var ui: CanvasLayer = $UI
@onready var sound_fx: Node = get_node_or_null("/root/SoundFx")
@onready var fade_rect: ColorRect = $UI/Fade
@onready var goal_box: VBoxContainer = $UI/GoalBox
@onready var toast_label: Label = $UI/Toast
@onready var region_card: PanelContainer = $UI/RegionCard
@onready var region_name_label: Label = $UI/RegionCard/Margin/VBox/RegionName
@onready var region_level_label: Label = $UI/RegionCard/Margin/VBox/LevelLabel
@onready var region_flavor_label: Label = $UI/RegionCard/Margin/VBox/FlavorLabel
@onready var hp_label: Label = $UI/HUD/HPLabel
@onready var gold_label: Label = $UI/HUD/GoldLabel
@onready var goal_label: Label = $UI/GoalBox/GoalLabel
@onready var hint_label: Label = $UI/GoalBox/HintLabel
@onready var persistent_hint: Label = $UI/PersistentHint
@onready var forest_debug_label: Label = $ForestHotspot/DebugLabel
@onready var ruins_debug_label: Label = $RuinsHotspot/DebugLabel
var locked_info_panel: PanelContainer = null

func _ready() -> void:
	add_to_group("i18n")
	_setup_map_texture()
	# 겹치는 Area2D 중 z_index가 높은 것만 클릭되도록 (유적이 연못보다 우선)
	var vp := get_viewport()
	vp.physics_object_picking_first_only = true
	vp.physics_object_picking_sort = true
	var forest: Area2D = $ForestHotspot
	forest.input_event.connect(_on_hotspot_input.bind("forest"))
	forest.mouse_entered.connect(_on_forest_mouse_entered)
	forest.mouse_exited.connect(_on_forest_mouse_exited)
	if forest.has_node("DebugLabel"):
		forest.get_node("DebugLabel").mouse_filter = Control.MOUSE_FILTER_IGNORE
	if forest.has_node("ForestClearedBadge"):
		forest.get_node("ForestClearedBadge").visible = GameState.forest_cleared_once
	var tree_castle: Area2D = $TreeCastleHotspot
	tree_castle.input_event.connect(_on_hotspot_input.bind("tree_castle"))
	tree_castle.mouse_entered.connect(_on_tree_castle_mouse_entered)
	tree_castle.mouse_exited.connect(_on_tree_castle_mouse_exited)
	if tree_castle.has_node("DebugLabel"):
		tree_castle.get_node("DebugLabel").mouse_filter = Control.MOUSE_FILTER_IGNORE
	var sokoban: Area2D = $SokobanHotspot
	sokoban.input_event.connect(_on_sokoban_input)
	sokoban.mouse_entered.connect(_on_sokoban_mouse_entered)
	sokoban.mouse_exited.connect(_on_sokoban_mouse_exited)
	if sokoban.has_node("DebugLabel"):
		sokoban.get_node("DebugLabel").mouse_filter = Control.MOUSE_FILTER_IGNORE
	var ruins: Area2D = $RuinsHotspot
	ruins.input_event.connect(_on_hotspot_input.bind("ruins"))
	ruins.mouse_entered.connect(_on_ruins_mouse_entered)
	ruins.mouse_exited.connect(_on_ruins_mouse_exited)
	if ruins.has_node("DebugLabel"):
		ruins.get_node("DebugLabel").mouse_filter = Control.MOUSE_FILTER_IGNORE
	if ruins.has_node("RuinsClearedBadge"):
		ruins.get_node("RuinsClearedBadge").visible = GameState.ruins_cleared_once
	_update_ruins_locked_state()
	var castle: Area2D = $CastleHotspot
	castle.input_event.connect(_on_hotspot_input.bind("castle"))
	castle.mouse_entered.connect(_on_castle_mouse_entered)
	castle.mouse_exited.connect(_on_castle_mouse_exited)
	if castle.has_node("DebugLabel"):
		castle.get_node("DebugLabel").mouse_filter = Control.MOUSE_FILTER_IGNORE
	var pond: Area2D = $PondHotspot
	pond.input_event.connect(_on_pond_input)
	pond.mouse_entered.connect(_on_pond_mouse_entered)
	pond.mouse_exited.connect(_on_pond_mouse_exited)
	if pond.has_node("DebugLabel"):
		pond.get_node("DebugLabel").mouse_filter = Control.MOUSE_FILTER_IGNORE
	var beach: Area2D = $BeachHotspot
	beach.input_event.connect(_on_beach_input)
	beach.mouse_entered.connect(_on_beach_mouse_entered)
	beach.mouse_exited.connect(_on_beach_mouse_exited)
	if beach.has_node("DebugLabel"):
		beach.get_node("DebugLabel").mouse_filter = Control.MOUSE_FILTER_IGNORE
	var lighthouse: Area2D = $LighthouseHotspot
	lighthouse.input_event.connect(_on_lighthouse_input)
	lighthouse.mouse_entered.connect(_on_lighthouse_mouse_entered)
	lighthouse.mouse_exited.connect(_on_lighthouse_mouse_exited)
	if lighthouse.has_node("DebugLabel"):
		lighthouse.get_node("DebugLabel").mouse_filter = Control.MOUSE_FILTER_IGNORE
	var tavern: Area2D = $TavernHotspot
	tavern.input_event.connect(_on_tavern_input)
	tavern.mouse_entered.connect(_on_tavern_mouse_entered)
	tavern.mouse_exited.connect(_on_tavern_mouse_exited)
	if tavern.has_node("DebugLabel"):
		tavern.get_node("DebugLabel").mouse_filter = Control.MOUSE_FILTER_IGNORE
	var guild: Area2D = $GuildHotspot
	guild.input_event.connect(_on_guild_input)
	guild.mouse_entered.connect(_on_guild_mouse_entered)
	guild.mouse_exited.connect(_on_guild_mouse_exited)
	if guild.has_node("DebugLabel"):
		guild.get_node("DebugLabel").mouse_filter = Control.MOUSE_FILTER_IGNORE
	var library: Area2D = $LibraryHotspot
	library.input_event.connect(_on_library_input)
	library.mouse_entered.connect(_on_library_mouse_entered)
	library.mouse_exited.connect(_on_library_mouse_exited)
	if library.has_node("DebugLabel"):
		library.get_node("DebugLabel").mouse_filter = Control.MOUSE_FILTER_IGNORE
	refresh_text()
	_animate_gold_if_changed()
	_run_entry_sequence()
	_setup_debug_panel()
	_setup_debug_hotspot_colors()

func refresh_text() -> void:
	goal_label.text = tr("MAP_GOAL")
	hint_label.text = tr("MAP_HINT")
	persistent_hint.text = tr("MAP_CLICK_HINT")
	forest_debug_label.text = tr("MAP_FOREST")
	if has_node("TreeCastleHotspot/DebugLabel"):
		$TreeCastleHotspot/DebugLabel.text = tr("MAP_TREE_CASTLE")
	if has_node("SokobanHotspot/DebugLabel"):
		$SokobanHotspot/DebugLabel.text = tr("MAP_SOKOBAN")
	ruins_debug_label.text = tr("MAP_RUINS")
	if has_node("CastleHotspot/DebugLabel"):
		$CastleHotspot/DebugLabel.text = tr("MAP_CASTLE")
	if has_node("PondHotspot/DebugLabel"):
		$PondHotspot/DebugLabel.text = tr("MAP_POND")
	if has_node("BeachHotspot/DebugLabel"):
		$BeachHotspot/DebugLabel.text = tr("MAP_BEACH")
	if has_node("LighthouseHotspot/DebugLabel"):
		$LighthouseHotspot/DebugLabel.text = tr("MAP_LIGHTHOUSE")
	if has_node("TavernHotspot/DebugLabel"):
		$TavernHotspot/DebugLabel.text = tr("MAP_TAVERN")
	if has_node("GuildHotspot/DebugLabel"):
		$GuildHotspot/DebugLabel.text = tr("MAP_GUILD")
	if has_node("LibraryHotspot/DebugLabel"):
		$LibraryHotspot/DebugLabel.text = tr("MAP_LIBRARY")
	_update_hud()

func _update_hud() -> void:
	hp_label.text = "%s: %d/%d" % [tr("HUD_HP"), GameState.player_hp, GameState.player_max_hp]
	gold_label.text = "%s: %d" % [tr("HUD_GOLD"), GameState.gold]
	if GameState.player_max_hp > 0 and GameState.player_hp < GameState.player_max_hp * 0.3:
		hp_label.add_theme_color_override("font_color", Color(1, 0.4, 0.4))
	else:
		hp_label.add_theme_color_override("font_color", Color(1, 1, 1))

func _animate_gold_if_changed() -> void:
	var from_gold: int = GameState.world_map_last_gold if GameState.world_map_last_gold >= 0 else GameState.gold
	GameState.world_map_last_gold = GameState.gold
	if from_gold >= GameState.gold:
		return
	gold_label.text = "%s: %d" % [tr("HUD_GOLD"), from_gold]
	var tw := create_tween()
	tw.tween_method(
		func(v: float) -> void: gold_label.text = "%s: %d" % [tr("HUD_GOLD"), int(v)],
		float(from_gold),
		float(GameState.gold),
		0.3
	)

func _exit_tree() -> void:
	GameState.world_map_last_gold = GameState.gold
	SaveManager.save_game()

func _setup_map_texture() -> void:
	if not $MapSprite.texture:
		for path in MAP_PATHS:
			var tex := load(path) as Texture2D
			if tex:
				$MapSprite.texture = tex
				break
	if $MapSprite.texture:
		var tex_size: Vector2 = ($MapSprite.texture as Texture2D).get_size()
		var view: Vector2 = get_viewport_rect().size
		var scale_x: float = view.x / tex_size.x
		var scale_y: float = view.y / tex_size.y
		var s: float = minf(scale_x, scale_y)
		$MapSprite.scale = Vector2(s, s)
		$MapSprite.position = view / 2.0
		$ForestHotspot.position = $MapSprite.position + REGION_POSITIONS["forest"]
		$SokobanHotspot.position = $MapSprite.position + REGION_POSITIONS["sokoban"]
		$TreeCastleHotspot.position = $MapSprite.position + REGION_POSITIONS["tree_castle"]
		$RuinsHotspot.position = $MapSprite.position + REGION_POSITIONS["ruins"]
		$CastleHotspot.position = $MapSprite.position + REGION_POSITIONS["castle"]
		$PondHotspot.position = $MapSprite.position + REGION_POSITIONS["pond"]
		$BeachHotspot.position = $MapSprite.position + REGION_POSITIONS["beach"]
		$LighthouseHotspot.position = $MapSprite.position + REGION_POSITIONS["lighthouse"]
		$TavernHotspot.position = $MapSprite.position + REGION_POSITIONS["tavern"]
		$GuildHotspot.position = $MapSprite.position + REGION_POSITIONS["guild"]
		$LibraryHotspot.position = $MapSprite.position + REGION_POSITIONS["library"]

func _run_entry_sequence() -> void:
	_fade_alpha(fade_rect, 1.0, 0.0, FADE_DURATION)
	var t := create_tween()
	t.tween_interval(GOAL_DISPLAY_TIME)
	t.tween_callback(func() -> void: _fade_alpha(goal_box, goal_box.modulate.a, 0.0, 0.3))

func _on_forest_mouse_entered() -> void:
	$ForestHotspot.scale = Vector2(1.2, 1.2)

func _on_forest_mouse_exited() -> void:
	$ForestHotspot.scale = Vector2.ONE

func _on_tree_castle_mouse_entered() -> void:
	$TreeCastleHotspot.scale = Vector2(1.2, 1.2)

func _on_tree_castle_mouse_exited() -> void:
	$TreeCastleHotspot.scale = Vector2.ONE

func _on_ruins_mouse_entered() -> void:
	if _is_ruins_locked():
		$RuinsHotspot.scale = Vector2(1.05, 1.05)
	else:
		$RuinsHotspot.scale = Vector2(1.2, 1.2)

func _on_ruins_mouse_exited() -> void:
	$RuinsHotspot.scale = Vector2.ONE

func _on_castle_mouse_entered() -> void:
	$CastleHotspot.scale = Vector2(1.2, 1.2)

func _on_castle_mouse_exited() -> void:
	$CastleHotspot.scale = Vector2.ONE

func _on_pond_mouse_entered() -> void:
	$PondHotspot.scale = Vector2(1.2, 1.2)

func _on_pond_mouse_exited() -> void:
	$PondHotspot.scale = Vector2.ONE

func _on_beach_mouse_entered() -> void:
	$BeachHotspot.scale = Vector2(1.2, 1.2)

func _on_beach_mouse_exited() -> void:
	$BeachHotspot.scale = Vector2.ONE

func _on_lighthouse_mouse_entered() -> void:
	$LighthouseHotspot.scale = Vector2(1.2, 1.2)

func _on_lighthouse_mouse_exited() -> void:
	$LighthouseHotspot.scale = Vector2.ONE

func _on_lighthouse_input(_viewport: Node, event: InputEvent, _shape_idx: int) -> void:
	if is_transitioning:
		return
	if not (event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT):
		return
	is_transitioning = true
	if sound_fx:
		sound_fx.play_ui_click()
	SceneRouter.goto("res://src/ui/typing/lighthouse_typing.tscn")

func _on_tavern_mouse_entered() -> void:
	$TavernHotspot.scale = Vector2(1.2, 1.2)

func _on_tavern_mouse_exited() -> void:
	$TavernHotspot.scale = Vector2.ONE

func _on_guild_mouse_entered() -> void:
	$GuildHotspot.scale = Vector2(1.2, 1.2)

func _on_guild_mouse_exited() -> void:
	$GuildHotspot.scale = Vector2.ONE

func _on_library_mouse_entered() -> void:
	$LibraryHotspot.scale = Vector2(1.2, 1.2)

func _on_library_mouse_exited() -> void:
	$LibraryHotspot.scale = Vector2.ONE

func _on_library_input(_viewport: Node, event: InputEvent, _shape_idx: int) -> void:
	if is_transitioning:
		return
	if not (event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT):
		return
	is_transitioning = true
	if sound_fx:
		sound_fx.play_ui_click()
	SceneRouter.goto("res://src/ui/memory/library_memory.tscn")

func _on_guild_input(_viewport: Node, event: InputEvent, _shape_idx: int) -> void:
	if is_transitioning:
		return
	if not (event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT):
		return
	is_transitioning = true
	if sound_fx:
		sound_fx.play_ui_click()
	SceneRouter.goto("res://src/ui/slot/guild_slot.tscn")

func _on_tavern_input(_viewport: Node, event: InputEvent, _shape_idx: int) -> void:
	if is_transitioning:
		return
	if not (event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT):
		return
	is_transitioning = true
	if sound_fx:
		sound_fx.play_ui_click()
	SceneRouter.goto("res://src/ui/puzzle/tavern_2048.tscn")

func _on_beach_input(_viewport: Node, event: InputEvent, _shape_idx: int) -> void:
	if is_transitioning:
		return
	if not (event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT):
		return
	is_transitioning = true
	if sound_fx:
		sound_fx.play_ui_click()
	SceneRouter.goto("res://src/ui/tetris/beach_tetris.tscn")

func _on_sokoban_mouse_entered() -> void:
	$SokobanHotspot.scale = Vector2(1.2, 1.2)

func _on_sokoban_mouse_exited() -> void:
	$SokobanHotspot.scale = Vector2.ONE

func _on_sokoban_input(_viewport: Node, event: InputEvent, _shape_idx: int) -> void:
	if is_transitioning:
		return
	if not (event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT):
		return
	is_transitioning = true
	if sound_fx:
		sound_fx.play_ui_click()
	SceneRouter.goto("res://src/ui/sokoban/forest_sokoban.tscn")

func _on_pond_input(_viewport: Node, event: InputEvent, _shape_idx: int) -> void:
	if is_transitioning:
		return
	if not (event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT):
		return
	is_transitioning = true
	if sound_fx:
		sound_fx.play_ui_click()
	SceneRouter.goto("res://src/ui/fishing/fishing.tscn")

func _on_hotspot_input(_viewport: Node, event: InputEvent, _shape_idx: int, region_id: String) -> void:
	if is_transitioning:
		return
	if not (event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT):
		return
	if region_id not in REGIONS:
		return
	var data: Dictionary = REGIONS[region_id]
	if _is_region_locked(data):
		_show_locked_panel(region_id, data)
		return
	is_transitioning = true
	GameState.current_region_id = region_id
	if sound_fx:
		sound_fx.play_ui_click()
	if not GameState.world_map_first_click_done:
		GameState.world_map_first_click_done = true
		_toast_then_show_region_card(region_id)
	else:
		_show_region_card_then_go(region_id)

func _is_region_locked(data: Dictionary) -> bool:
	if not data.get("requires", ""):
		return false
	var key: String = data["requires"]
	if key == "forest_cleared_once":
		return not GameState.forest_cleared_once
	return true

func _is_ruins_locked() -> bool:
	return _is_region_locked(REGIONS["ruins"])

func _update_ruins_locked_state() -> void:
	var locked := _is_ruins_locked()
	var ruins: Node2D = $RuinsHotspot
	if locked:
		ruins.modulate = Color(0.55, 0.55, 0.6)
		if ruins.has_node("RuinsLockedBadge"):
			ruins.get_node("RuinsLockedBadge").visible = true
	else:
		ruins.modulate = Color(1, 1, 1)
		if ruins.has_node("RuinsLockedBadge"):
			ruins.get_node("RuinsLockedBadge").visible = false

var _locked_panel_title: Label
var _locked_panel_message: Label

func _setup_locked_info_panel() -> void:
	if locked_info_panel:
		return
	locked_info_panel = PanelContainer.new()
	locked_info_panel.name = "LockedInfoPanel"
	locked_info_panel.visible = false
	var margin := MarginContainer.new()
	margin.name = "Margin"
	margin.add_theme_constant_override("margin_left", 24)
	margin.add_theme_constant_override("margin_top", 20)
	margin.add_theme_constant_override("margin_right", 24)
	margin.add_theme_constant_override("margin_bottom", 20)
	locked_info_panel.add_child(margin)
	var vbox := VBoxContainer.new()
	vbox.name = "VBox"
	vbox.add_theme_constant_override("separation", 12)
	margin.add_child(vbox)
	_locked_panel_title = Label.new()
	_locked_panel_title.name = "Title"
	_locked_panel_title.add_theme_font_size_override("font_size", 22)
	_locked_panel_title.add_theme_color_override("font_color", Color(0.9, 0.5, 0.5))
	_locked_panel_title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	vbox.add_child(_locked_panel_title)
	_locked_panel_message = Label.new()
	_locked_panel_message.name = "Message"
	_locked_panel_message.add_theme_font_size_override("font_size", 16)
	_locked_panel_message.add_theme_color_override("font_color", Color(0.85, 0.8, 0.75))
	_locked_panel_message.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_locked_panel_message.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	vbox.add_child(_locked_panel_message)
	var btn := Button.new()
	btn.text = tr("BTN_CONFIRM")
	btn.pressed.connect(_on_locked_panel_confirmed)
	vbox.add_child(btn)
	btn.focus_mode = Control.FOCUS_NONE
	locked_info_panel.set_anchors_preset(Control.PRESET_CENTER_TOP)
	locked_info_panel.anchor_top = 0.5
	locked_info_panel.anchor_bottom = 0.5
	locked_info_panel.offset_left = -180
	locked_info_panel.offset_top = -100
	locked_info_panel.offset_right = 180
	locked_info_panel.offset_bottom = 100
	ui.add_child(locked_info_panel)
	locked_info_panel.z_index = 150

func _show_locked_panel(region_id: String, data: Dictionary) -> void:
	_setup_locked_info_panel()
	var name_key: String = data.get("name_key", "MAP_RUINS")
	var reason_key: String = data.get("locked_reason_key", "LOCKED_DEFAULT")
	_locked_panel_title.text = tr(name_key) + " · " + tr("LOCKED_PANEL_TITLE")
	_locked_panel_message.text = tr(reason_key) + "\n\n" + tr("LOCKED_HINT_FOREST")
	locked_info_panel.visible = true
	if sound_fx:
		sound_fx.play_ui_click()

func _on_locked_panel_confirmed() -> void:
	if locked_info_panel:
		locked_info_panel.visible = false

func _toast_locked(message: String) -> void:
	toast_label.text = message
	toast_label.visible = true
	toast_label.modulate.a = 1.0
	var t := create_tween()
	t.tween_interval(TOAST_TIME)
	t.tween_property(toast_label, "modulate:a", 0.0, 0.2)
	t.tween_callback(func() -> void: toast_label.visible = false)

func _toast_then_show_region_card(region_id: String) -> void:
	var data: Dictionary = REGIONS[region_id]
	var toast_key: String = data.get("toast_key", "")
	toast_label.text = tr(toast_key) if toast_key else ""
	toast_label.visible = true
	toast_label.modulate.a = 1.0
	var t := create_tween()
	t.tween_interval(TOAST_TIME)
	t.tween_property(toast_label, "modulate:a", 0.0, 0.2)
	t.tween_callback(func() -> void:
		toast_label.visible = false
		_show_region_card_then_go(region_id)
	)

func _show_region_card_then_go(region_id: String) -> void:
	var data: Dictionary = REGIONS[region_id]
	region_name_label.text = tr(data.get("name_key", ""))
	var level: int = data.get("level", 1)
	region_level_label.visible = level > 0
	region_level_label.text = tr("CARD_LEVEL") % level
	region_flavor_label.text = tr(data.get("flavor_key", ""))
	region_card.visible = true
	region_card.modulate.a = 1.0

	var scene_path: String = data.get("scene", "")
	var tween := create_tween()
	tween.tween_interval(REGION_CARD_TIME)
	tween.tween_callback(func() -> void:
		if sound_fx:
			sound_fx.play_transition()
		_fade_alpha(fade_rect, 0.0, 1.0, FADE_DURATION)
	)
	tween.tween_interval(FADE_DURATION)
	tween.tween_callback(func() -> void: SceneRouter.goto(scene_path))

func _fade_alpha(target: CanvasItem, from_a: float, to_a: float, duration: float) -> void:
	target.modulate = Color(1, 1, 1, from_a)
	var t := create_tween()
	t.tween_property(target, "modulate", Color(1, 1, 1, to_a), duration)

## 개발자 디버깅: 핫스팟 영역 시각화 (디버그/에디터에서만 표시)
## 별도 노드에 그려서 핫스팟 입력에 영향 없음. DEV 패널에서 ON/OFF 토글 가능
func _setup_debug_hotspot_colors() -> void:
	if not (OS.is_debug_build() or OS.has_feature("editor")):
		return
	var overlay: Node2D = get_node_or_null("DebugHotspotOverlay")
	if overlay:
		overlay.queue_free()
	overlay = Node2D.new()
	overlay.name = "DebugHotspotOverlay"
	overlay.z_index = 50
	overlay.visible = false
	add_child(overlay)
	var hotspot_names: Array[String] = [
		"ForestHotspot", "TreeCastleHotspot", "SokobanHotspot", "RuinsHotspot",
		"CastleHotspot", "PondHotspot", "BeachHotspot", "LighthouseHotspot",
		"TavernHotspot", "GuildHotspot", "LibraryHotspot"
	]
	for name in hotspot_names:
		var hotspot: Node2D = get_node_or_null(name) as Node2D
		if not hotspot:
			continue
		var collision: CollisionShape2D = hotspot.get_node_or_null("CollisionShape2D")
		if not collision or not collision.shape:
			continue
		var circle: CircleShape2D = collision.shape as CircleShape2D
		if not circle:
			continue
		var r: float = circle.radius
		var points: PackedVector2Array = []
		var n: int = 24
		for i in n:
			var angle: float = i * TAU / n
			points.append(Vector2(cos(angle) * r, sin(angle) * r))
		var poly: Polygon2D = Polygon2D.new()
		poly.name = name + "_DebugFill"
		poly.polygon = points
		poly.color = Color(1, 0.85, 0.4, 0.32)
		poly.position = hotspot.global_position
		overlay.add_child(poly)

func _setup_debug_panel() -> void:
	if not (OS.is_debug_build() or OS.has_feature("editor")):
		return
	var panel := PanelContainer.new()
	panel.name = "DebugPanel"
	panel.visible = true
	var margin := MarginContainer.new()
	margin.add_theme_constant_override("margin_left", 8)
	margin.add_theme_constant_override("margin_top", 8)
	margin.add_theme_constant_override("margin_right", 8)
	margin.add_theme_constant_override("margin_bottom", 8)
	panel.add_child(margin)
	var vbox := VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 4)
	margin.add_child(vbox)
	var title := Label.new()
	title.text = "[DEV]"
	title.add_theme_font_size_override("font_size", 12)
	title.add_theme_color_override("font_color", Color(0.7, 0.7, 0.7, 1))
	vbox.add_child(title)
	var gold_100 := Button.new()
	gold_100.text = "+100 골드"
	gold_100.pressed.connect(_debug_add_gold.bind(100))
	vbox.add_child(gold_100)
	var gold_500 := Button.new()
	gold_500.text = "+500 골드"
	gold_500.pressed.connect(_debug_add_gold.bind(500))
	vbox.add_child(gold_500)
	var hp_50 := Button.new()
	hp_50.text = "+50 HP"
	hp_50.pressed.connect(_debug_add_hp.bind(50))
	vbox.add_child(hp_50)
	var full_heal := Button.new()
	full_heal.text = "HP 풀회복"
	full_heal.pressed.connect(_debug_full_heal)
	vbox.add_child(full_heal)
	var area_toggle := CheckButton.new()
	area_toggle.text = "영역 표시 ON/OFF"
	area_toggle.button_pressed = false
	area_toggle.toggled.connect(_on_debug_area_toggle)
	vbox.add_child(area_toggle)
	area_toggle.focus_mode = Control.FOCUS_NONE
	panel.set_anchors_preset(Control.PRESET_TOP_RIGHT)
	panel.offset_left = -160
	panel.offset_top = 0
	panel.offset_right = 0
	panel.offset_bottom = 220
	for btn in [gold_100, gold_500, hp_50, full_heal]:
		btn.focus_mode = Control.FOCUS_NONE
	ui.add_child(panel)
	panel.z_index = 100

func _on_debug_area_toggle(toggled_on: bool) -> void:
	var overlay: Node2D = get_node_or_null("DebugHotspotOverlay")
	if overlay:
		overlay.visible = toggled_on

func _debug_add_gold(amount: int) -> void:
	GameState.gold += amount
	_update_hud()
	SaveManager.save_game()

func _debug_add_hp(amount: int) -> void:
	GameState.player_hp = mini(GameState.player_hp + amount, GameState.player_max_hp)
	_update_hud()
	SaveManager.save_game()

func _debug_full_heal() -> void:
	GameState.player_hp = GameState.player_max_hp
	_update_hud()
	SaveManager.save_game()
