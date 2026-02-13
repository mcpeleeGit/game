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
	"ruins": Vector2(240, 60),
	"pond": Vector2(180, 100),  # 유적 아래 왼쪽
	"beach": Vector2(180, 140),  # 연못 아래
	"lighthouse": Vector2(300, 220),  # 해변 아래 오른쪽 등대
	"tavern": Vector2(-80, 55),  # 성 왼쪽 아래 건물
	"guild": Vector2(-200, 40),  # 선술집 왼쪽 더 큰 건물
	"library": Vector2(-310, 15),  # 길드 왼쪽 위 건물
	"castle": Vector2(0, 0),
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

func _ready() -> void:
	add_to_group("i18n")
	_setup_map_texture()
	var forest: Area2D = $ForestHotspot
	forest.input_event.connect(_on_hotspot_input.bind("forest"))
	forest.mouse_entered.connect(_on_forest_mouse_entered)
	forest.mouse_exited.connect(_on_forest_mouse_exited)
	if forest.has_node("DebugLabel"):
		forest.get_node("DebugLabel").mouse_filter = Control.MOUSE_FILTER_IGNORE
	if forest.has_node("ForestClearedBadge"):
		forest.get_node("ForestClearedBadge").visible = GameState.forest_cleared_once
	var ruins: Area2D = $RuinsHotspot
	ruins.input_event.connect(_on_hotspot_input.bind("ruins"))
	ruins.mouse_entered.connect(_on_ruins_mouse_entered)
	ruins.mouse_exited.connect(_on_ruins_mouse_exited)
	if ruins.has_node("DebugLabel"):
		ruins.get_node("DebugLabel").mouse_filter = Control.MOUSE_FILTER_IGNORE
	if ruins.has_node("RuinsClearedBadge"):
		ruins.get_node("RuinsClearedBadge").visible = GameState.ruins_cleared_once
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

func refresh_text() -> void:
	goal_label.text = tr("MAP_GOAL")
	hint_label.text = tr("MAP_HINT")
	persistent_hint.text = tr("MAP_CLICK_HINT")
	forest_debug_label.text = tr("MAP_FOREST")
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

func _on_ruins_mouse_entered() -> void:
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
		var reason_key: String = data.get("locked_reason_key", "LOCKED_DEFAULT")
		_toast_locked(tr(reason_key))
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
