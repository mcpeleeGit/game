extends Control
## 나무성 타워 디펜스 - 웨이브 방어, 타워 배치

const WORLD_MAP_PATH := "res://src/world/world_map.tscn"
const REGION_TREE_CASTLE_PATH := "res://src/regions/region_tree_castle.tscn"
const ENEMY_TEXTURE_PATH := "res://assets/images/characters/enemy_goblin.png"
const TD_BG_PATH := "res://assets/images/backgrounds/tree_castle_td_bg.png"
const TOWER_ARCHER_PATH := "res://assets/images/tower_defense/tower_archer.png"
const TOWER_CANNON_PATH := "res://assets/images/tower_defense/tower_cannon.png"
const TOWER_HEAVY_CANNON_PATH := "res://assets/images/tower_defense/tower_heavy_cannon.png"
const TOWER_SLOW_PATH := "res://assets/images/tower_defense/tower_slow.png"

## 타워: type_id, cost, range, damage, fire_rate, aoe_radius(0=단일), slow_pct(0=해제)
const TOWER_ARCHER := 0
const TOWER_CANNON := 1
const TOWER_SLOW := 2
const TOWER_HEAVY_CANNON := 3

const TOWER_CONFIG: Dictionary = {
	TOWER_ARCHER: {"cost": 20, "range": 120.0, "damage": 12, "fire_rate": 1.0, "aoe": 0.0, "slow": 0.0, "color": Color(0.6, 0.8, 0.5), "tex_path": TOWER_ARCHER_PATH},
	TOWER_CANNON: {"cost": 35, "range": 80.0, "damage": 20, "fire_rate": 1.5, "aoe": 50.0, "slow": 0.0, "color": Color(0.7, 0.5, 0.4), "tex_path": TOWER_CANNON_PATH},
	TOWER_SLOW: {"cost": 30, "range": 100.0, "damage": 0, "fire_rate": 2.0, "aoe": 0.0, "slow": 0.4, "color": Color(0.5, 0.6, 0.9), "tex_path": TOWER_SLOW_PATH},
	TOWER_HEAVY_CANNON: {"cost": 65, "range": 90.0, "damage": 45, "fire_rate": 2.2, "aoe": 65.0, "slow": 0.0, "color": Color(0.5, 0.35, 0.3), "tex_path": TOWER_HEAVY_CANNON_PATH},
}

## Normal: 5 waves, reward 30. Hard: 7 waves, reward 45. 골드는 GameState.gold 사용
const DIFFICULTY: Dictionary = {
	"normal": {"max_waves": 5, "reward": 30, "enemy_hp_base": 25, "enemy_count_base": 4},
	"hard": {"max_waves": 7, "reward": 45, "enemy_hp_base": 35, "enemy_count_base": 5},
}
var lives: int = 10
var current_wave: int = 0
var max_waves: int = 5
var reward_amount: int = 30
var playing: bool = false
var wave_in_progress: bool = false
var selected_tower: int = -1
var difficulty: String = "normal"

## 슬롯 위치 (GameArea 로컬), 슬롯 idx -> tower_type (-1=empty)
var slot_positions: Array[Vector2] = []
var towers: Dictionary = {}  # slot_idx -> tower_type
var enemies: Array = []  # [{node, hp, max_hp, path_t, speed, slowed_until}]
var projectiles: Array = []  # [{node, from_pos, to_pos, progress, duration, data}]
var path_points: PackedVector2Array = PackedVector2Array()
const PROJECTILE_SPEED: float = 450.0  # 픽셀/초
var enemy_spawn_queue: Array = []
var spawn_timer: float = 0.0
const SPAWN_INTERVAL: float = 0.6
var tower_cooldowns: Dictionary = {}  # slot_idx -> remaining time
const KILL_GOLD: int = 5
const ENEMY_SPEED: float = 55.0

@onready var game_area: Control = $VBox/MainHBox/GameArea
@onready var gold_label: Label = $VBox/HUD/GoldLabel
@onready var wave_label: Label = $VBox/HUD/WaveLabel
@onready var lives_label: Label = $VBox/HUD/LivesLabel
@onready var arrow_btn: Button = $VBox/MainHBox/TowerButtons/ArrowTowerBtn
@onready var cannon_btn: Button = $VBox/MainHBox/TowerButtons/CannonTowerBtn
@onready var heavy_cannon_btn: Button = $VBox/MainHBox/TowerButtons/HeavyCannonTowerBtn
@onready var slow_btn: Button = $VBox/MainHBox/TowerButtons/SlowTowerBtn
@onready var start_wave_btn: Button = $VBox/Buttons/StartWaveButton
@onready var back_btn: Button = $VBox/Buttons/BackButton
@onready var help_btn: Button = $VBox/Buttons/HelpButton
@onready var result_panel: PanelContainer = $ResultPanel
@onready var result_label: Label = $ResultPanel/Margin/VBox/ResultLabel
@onready var reward_label: Label = $ResultPanel/Margin/VBox/RewardLabel
@onready var restart_btn: Button = $ResultPanel/Margin/VBox/RestartButton
@onready var back_result_btn: Button = $ResultPanel/Margin/VBox/BackFromResultButton
@onready var help_panel: PanelContainer = $HelpPanel
@onready var help_label: Label = $HelpPanel/Margin/VBox/HelpLabel
@onready var close_help_btn: Button = $HelpPanel/Margin/VBox/CloseHelpBtn

func _ready() -> void:
	add_to_group("i18n")
	game_area.gui_input.connect(_on_game_area_input)
	result_panel.visible = false
	help_panel.visible = false
	difficulty = GameState.td_difficulty if GameState.td_difficulty in DIFFICULTY else "normal"
	var diff_data: Dictionary = DIFFICULTY[difficulty]
	max_waves = diff_data["max_waves"]
	reward_amount = diff_data["reward"]
	call_deferred("_deferred_setup")
	arrow_btn.pressed.connect(_select_tower.bind(TOWER_ARCHER))
	cannon_btn.pressed.connect(_select_tower.bind(TOWER_CANNON))
	heavy_cannon_btn.pressed.connect(_select_tower.bind(TOWER_HEAVY_CANNON))
	slow_btn.pressed.connect(_select_tower.bind(TOWER_SLOW))
	start_wave_btn.pressed.connect(_on_start_wave)
	back_btn.pressed.connect(_on_back)
	help_btn.pressed.connect(_on_help)
	restart_btn.pressed.connect(_on_restart)
	back_result_btn.pressed.connect(_on_back_from_result)
	close_help_btn.pressed.connect(_on_close_help)
	_set_buttons_focus_none()
	_setup_tower_button_icons()
	refresh_text()
	_update_ui()

func _deferred_setup() -> void:
	_setup_path_and_slots()
	_setup_td_background()
	_draw_path()
	_build_tower_visuals()
	playing = true

func _setup_path_and_slots() -> void:
	var w: float = game_area.size.x
	var h: float = game_area.size.y
	if w < 100:
		w = 600.0
	if h < 100:
		h = 380.0
	path_points.clear()
	path_points.append(Vector2(30, h * 0.5))
	path_points.append(Vector2(w * 0.25, h * 0.5))
	path_points.append(Vector2(w * 0.5, h * 0.25))
	path_points.append(Vector2(w * 0.75, h * 0.5))
	path_points.append(Vector2(w - 30, h * 0.5))
	slot_positions.clear()
	slot_positions.append(Vector2(w * 0.15, h * 0.35))
	slot_positions.append(Vector2(w * 0.2, h * 0.65))
	slot_positions.append(Vector2(w * 0.35, h * 0.2))
	slot_positions.append(Vector2(w * 0.4, h * 0.55))
	slot_positions.append(Vector2(w * 0.55, h * 0.35))
	slot_positions.append(Vector2(w * 0.6, h * 0.7))
	slot_positions.append(Vector2(w * 0.75, h * 0.45))
	slot_positions.append(Vector2(w * 0.8, h * 0.25))
	for i in slot_positions.size():
		towers[i] = -1

func _setup_td_background() -> void:
	for c in game_area.get_children():
		if c.name == "TDBackground":
			c.queue_free()
			break
	var bg := TextureRect.new()
	bg.name = "TDBackground"
	var tex := load(TD_BG_PATH) as Texture2D
	if tex and tex.get_width() * tex.get_height() >= 100:
		bg.texture = tex
		bg.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
		bg.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	bg.set_anchors_preset(Control.PRESET_FULL_RECT)
	bg.offset_left = 0
	bg.offset_top = 0
	bg.offset_right = 0
	bg.offset_bottom = 0
	bg.z_index = -2
	bg.mouse_filter = Control.MOUSE_FILTER_IGNORE
	game_area.add_child(bg)
	game_area.move_child(bg, 0)

func _draw_path() -> void:
	for c in game_area.get_children():
		if c.name == "PathLine":
			c.queue_free()
			break
	var line := Line2D.new()
	line.name = "PathLine"
	line.width = 12.0
	line.default_color = Color(0.35, 0.28, 0.2, 0.8)
	for p in path_points:
		line.add_point(p)
	game_area.add_child(line)
	line.z_index = -1

func _build_tower_visuals() -> void:
	for c in game_area.get_children():
		if c.name.begins_with("Slot_"):
			c.queue_free()
	for i in slot_positions.size():
		var slot := Control.new()
		slot.name = "Slot_%d" % i
		slot.position = slot_positions[i] - Vector2(18, 18)
		slot.size = Vector2(36, 36)
		slot.mouse_filter = Control.MOUSE_FILTER_IGNORE
		var bg := ColorRect.new()
		bg.name = "SlotBg"
		bg.set_anchors_preset(Control.PRESET_FULL_RECT)
		bg.offset_left = 0
		bg.offset_top = 0
		bg.offset_right = 0
		bg.offset_bottom = 0
		bg.color = Color(0.25, 0.3, 0.22, 0.9)
		bg.mouse_filter = Control.MOUSE_FILTER_IGNORE
		slot.add_child(bg)
		game_area.add_child(slot)

func _draw_tower_at_slot(slot_idx: int, tower_type: int) -> void:
	var slot_node: Control = game_area.get_node_or_null("Slot_%d" % slot_idx)
	if not slot_node:
		return
	var cfg: Dictionary = TOWER_CONFIG[tower_type]
	var bg: ColorRect = slot_node.get_node_or_null("SlotBg")
	var tower_icon: TextureRect = slot_node.get_node_or_null("TowerIcon")
	if tower_icon:
		tower_icon.queue_free()
	var tex_path: String = cfg.get("tex_path", "")
	var tex := load(tex_path) as Texture2D
	if (not tex or tex.get_width() * tex.get_height() < 100) and tex_path == TOWER_HEAVY_CANNON_PATH:
		tex = load(TOWER_CANNON_PATH) as Texture2D
	if tex and tex.get_width() * tex.get_height() >= 100:
		var img: Image = tex.get_image()
		if img:
			img.resize(32, 32)
			tex = ImageTexture.create_from_image(img)
		tower_icon = TextureRect.new()
		tower_icon.name = "TowerIcon"
		tower_icon.texture = tex
		tower_icon.custom_minimum_size = Vector2(32, 32)
		tower_icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		tower_icon.size = Vector2(32, 32)
		tower_icon.position = Vector2(2, 2)
		tower_icon.mouse_filter = Control.MOUSE_FILTER_IGNORE
		slot_node.add_child(tower_icon)
	if bg:
		bg.color = cfg["color"]

func _select_tower(tower_type: int) -> void:
	selected_tower = tower_type if selected_tower != tower_type else -1

func _on_game_area_input(event: InputEvent) -> void:
	if not playing:
		return
	if not (event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT):
		return
	if selected_tower < 0:
		return
	var cfg: Dictionary = TOWER_CONFIG[selected_tower]
	if GameState.gold < cfg["cost"]:
		return
	var pos: Vector2 = game_area.get_local_mouse_position()
	var best_idx: int = -1
	var best_dist: float = 99999.0
	for i in slot_positions.size():
		if towers[i] >= 0:
			continue
		var d: float = pos.distance_to(slot_positions[i])
		if d < best_dist and d < 40.0:
			best_dist = d
			best_idx = i
	if best_idx >= 0:
		towers[best_idx] = selected_tower
		GameState.gold -= cfg["cost"]
		_draw_tower_at_slot(best_idx, selected_tower)
		_update_ui()

func _get_wave_data(wave: int) -> Dictionary:
	var diff_data: Dictionary = DIFFICULTY[difficulty]
	var count: int = diff_data["enemy_count_base"] + wave * 2
	var hp: int = diff_data["enemy_hp_base"] + wave * 8
	return {"count": count, "hp": hp}

func _on_start_wave() -> void:
	if not playing:
		playing = true
	if wave_in_progress:
		return
	if current_wave >= max_waves:
		return
	current_wave += 1
	wave_in_progress = true
	var wave_data: Dictionary = _get_wave_data(current_wave)
	for _i in wave_data["count"]:
		enemy_spawn_queue.append({"hp": wave_data["hp"], "max_hp": wave_data["hp"]})
	spawn_timer = 0.0
	start_wave_btn.disabled = true
	_update_ui()

func _spawn_projectile(from_pos: Vector2, to_pos: Vector2, target_enemy: Dictionary, cfg: Dictionary) -> void:
	var dist: float = from_pos.distance_to(to_pos)
	var duration: float = dist / PROJECTILE_SPEED
	if duration < 0.05:
		duration = 0.05
	var proj_color: Color
	var proj_size: Vector2
	var tower_type: int = -1
	for k in TOWER_CONFIG:
		if TOWER_CONFIG[k] == cfg:
			tower_type = k
			break
	if tower_type == TOWER_ARCHER:
		proj_color = Color(0.95, 0.85, 0.2, 1.0)
		proj_size = Vector2(12, 4)
	elif tower_type == TOWER_CANNON:
		proj_color = Color(0.35, 0.3, 0.25, 1.0)
		proj_size = Vector2(14, 14)
	elif tower_type == TOWER_HEAVY_CANNON:
		proj_color = Color(0.25, 0.2, 0.18, 1.0)
		proj_size = Vector2(18, 18)
	else:
		proj_color = Color(0.3, 0.65, 1.0, 0.95)
		proj_size = Vector2(10, 10)
	var node := ColorRect.new()
	node.size = proj_size
	node.position = from_pos - proj_size / 2
	node.color = proj_color
	node.mouse_filter = Control.MOUSE_FILTER_IGNORE
	node.z_index = 10
	game_area.add_child(node)
	projectiles.append({
		"node": node,
		"from_pos": from_pos,
		"to_pos": to_pos,
		"progress": 0.0,
		"duration": duration,
		"target_enemy": target_enemy,
		"cfg": cfg
	})

func _spawn_enemy(hp: int, max_hp: int) -> void:
	var tex := load(ENEMY_TEXTURE_PATH) as Texture2D
	var spr: TextureRect = TextureRect.new()
	spr.texture = tex
	spr.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	spr.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	spr.custom_minimum_size = Vector2(40, 40)
	spr.size = Vector2(40, 40)
	spr.position = path_points[0] - Vector2(20, 20)
	spr.mouse_filter = Control.MOUSE_FILTER_IGNORE
	game_area.add_child(spr)
	enemies.append({
		"node": spr,
		"hp": hp,
		"max_hp": max_hp,
		"path_t": 0.0,
		"speed": ENEMY_SPEED,
		"slowed_until": 0.0
	})

func _process(delta: float) -> void:
	if not playing:
		return
	if not game_area.size.x > 50:
		return
	## 스폰
	if enemy_spawn_queue.size() > 0:
		spawn_timer += delta
		if spawn_timer >= SPAWN_INTERVAL:
			spawn_timer = 0.0
			var e: Dictionary = enemy_spawn_queue.pop_front()
			_spawn_enemy(e["hp"], e["max_hp"])
	## 타워 공격
	for slot_idx in tower_cooldowns.keys():
		tower_cooldowns[slot_idx] -= delta
		if tower_cooldowns[slot_idx] <= 0.0:
			tower_cooldowns.erase(slot_idx)
	for slot_idx in towers:
		if towers[slot_idx] < 0:
			continue
		var cfg: Dictionary = TOWER_CONFIG[towers[slot_idx]]
		var cd: float = tower_cooldowns.get(slot_idx, 0.0)
		if cd > 0.0:
			continue
		var slot_pos: Vector2 = slot_positions[slot_idx]
		var best_enemy: Variant = null
		var best_dist: float = cfg["range"]
		for e in enemies:
			var ep: Vector2 = _enemy_position(e)
			var d: float = slot_pos.distance_to(ep)
			if d < best_dist:
				best_dist = d
				best_enemy = e
		if best_enemy != null:
			tower_cooldowns[slot_idx] = cfg["fire_rate"]
			var target_pos: Vector2 = _enemy_position(best_enemy)
			_spawn_projectile(slot_pos, target_pos, best_enemy, cfg)
	## 발사체 이동
	var to_remove_proj: Array = []
	for p in projectiles:
		p["progress"] += delta / p["duration"]
		var t: float = clampf(p["progress"], 0.0, 1.0)
		var pos: Vector2 = p["from_pos"].lerp(p["to_pos"], t)
		var proj_node: ColorRect = p["node"]
		proj_node.position = pos - proj_node.size / 2
		if p["progress"] >= 1.0:
			var cfg: Dictionary = p["cfg"]
			var target_enemy: Dictionary = p["target_enemy"]
			if target_enemy in enemies:
				if cfg["aoe"] > 0.0:
					var center: Vector2 = _enemy_position(target_enemy)
					for e in enemies:
						if _enemy_position(e).distance_to(center) <= cfg["aoe"]:
							e["hp"] -= cfg["damage"]
				elif cfg["slow"] > 0.0:
					target_enemy["slowed_until"] = Time.get_ticks_msec() / 1000.0 + 2.0
				else:
					target_enemy["hp"] -= cfg["damage"]
			proj_node.queue_free()
			to_remove_proj.append(p)
	for p in to_remove_proj:
		projectiles.erase(p)
	## 적 이동
	var to_remove: Array = []
	for e in enemies:
		var spd: float = e["speed"] * (0.6 if e["slowed_until"] > Time.get_ticks_msec() / 1000.0 else 1.0)
		e["path_t"] += spd * delta / _path_length()
		if e["path_t"] >= 1.0:
			lives -= 1
			to_remove.append(e)
			e["node"].queue_free()
			continue
		var pos: Vector2 = _path_point_at(e["path_t"])
		e["node"].position = pos - Vector2(20, 20)
		if e["hp"] <= 0:
			e["hp"] = 0
			GameState.gold += KILL_GOLD
			to_remove.append(e)
			e["node"].queue_free()
	for e in to_remove:
		enemies.erase(e)
	if lives <= 0:
		_defeat()
		return
	if enemy_spawn_queue.size() == 0 and enemies.size() == 0 and wave_in_progress:
		wave_in_progress = false
		start_wave_btn.disabled = false
		_update_ui()
		if current_wave >= max_waves:
			_victory()

func _path_length() -> float:
	var len: float = 0.0
	for i in path_points.size() - 1:
		len += path_points[i].distance_to(path_points[i + 1])
	return len

func _path_point_at(t: float) -> Vector2:
	t = clampf(t, 0.0, 1.0)
	var total: float = _path_length()
	var acc: float = 0.0
	for i in path_points.size() - 1:
		var seg: float = path_points[i].distance_to(path_points[i + 1])
		if acc + seg >= t * total:
			var local: float = (t * total - acc) / seg
			return path_points[i].lerp(path_points[i + 1], local)
		acc += seg
	return path_points[path_points.size() - 1]

func _enemy_position(e: Dictionary) -> Vector2:
	return _path_point_at(e["path_t"])

func _victory() -> void:
	playing = false
	GameState.gold += reward_amount
	SaveManager.save_game()
	result_panel.visible = true
	result_label.text = tr("TD_VICTORY")
	result_label.add_theme_color_override("font_color", Color(0.4, 0.9, 0.4))
	reward_label.text = "+%d %s" % [reward_amount, tr("HUD_GOLD")]

func _defeat() -> void:
	playing = false
	result_panel.visible = true
	result_label.text = tr("TD_DEFEAT")
	result_label.add_theme_color_override("font_color", Color(0.95, 0.4, 0.4))
	reward_label.text = ""

func _on_restart() -> void:
	result_panel.visible = false
	for e in enemies:
		if e["node"].is_inside_tree():
			e["node"].queue_free()
	enemies.clear()
	for p in projectiles:
		if p["node"].is_inside_tree():
			p["node"].queue_free()
	projectiles.clear()
	enemy_spawn_queue.clear()
	tower_cooldowns.clear()
	lives = 10
	current_wave = 0
	playing = true
	wave_in_progress = false
	for i in towers.keys():
		towers[i] = -1
	_build_tower_visuals()
	start_wave_btn.disabled = false
	_update_ui()

func _on_back_from_result() -> void:
	SaveManager.save_game()
	SceneRouter.goto(REGION_TREE_CASTLE_PATH)

func _on_back() -> void:
	SaveManager.save_game()
	SceneRouter.goto(REGION_TREE_CASTLE_PATH)

func _on_help() -> void:
	help_panel.visible = true

func _on_close_help() -> void:
	help_panel.visible = false

const BUTTON_ICON_SIZE: int = 24

func _setup_tower_button_icons() -> void:
	var paths: Array[String] = [TOWER_ARCHER_PATH, TOWER_CANNON_PATH, TOWER_HEAVY_CANNON_PATH, TOWER_SLOW_PATH]
	var fallbacks: Array[String] = ["", "", TOWER_CANNON_PATH, ""]  # 중대포: 아이콘 없으면 대포 재사용
	var btns: Array[Button] = [arrow_btn, cannon_btn, heavy_cannon_btn, slow_btn]
	for i in btns.size():
		var tex := load(paths[i]) as Texture2D
		if not tex or tex.get_width() * tex.get_height() < 100:
			if fallbacks[i] != "":
				tex = load(fallbacks[i]) as Texture2D
		if tex and tex.get_width() * tex.get_height() >= 100:
			var img: Image = tex.get_image()
			if img:
				img.resize(BUTTON_ICON_SIZE, BUTTON_ICON_SIZE)
				var small_tex := ImageTexture.create_from_image(img)
				btns[i].icon = small_tex

func _set_buttons_focus_none() -> void:
	for btn in [arrow_btn, cannon_btn, heavy_cannon_btn, slow_btn, start_wave_btn, back_btn, help_btn, restart_btn, back_result_btn, close_help_btn]:
		btn.focus_mode = Control.FOCUS_NONE

func refresh_text() -> void:
	arrow_btn.text = tr("TD_TOWER_ARCHER") + " (20G)"
	cannon_btn.text = tr("TD_TOWER_CANNON") + " (35G)"
	heavy_cannon_btn.text = tr("TD_TOWER_HEAVY_CANNON") + " (65G)"
	slow_btn.text = tr("TD_TOWER_SLOW") + " (30G)"
	start_wave_btn.text = tr("TD_START_WAVE")
	back_btn.text = tr("BTN_BACK")
	help_btn.text = tr("BTN_HELP")
	restart_btn.text = tr("TETRIS_RESTART")
	back_result_btn.text = tr("BTN_BACK")
	close_help_btn.text = tr("BTN_CLOSE")
	help_label.text = tr("HELP_TD")

func _update_ui() -> void:
	gold_label.text = tr("TD_GOLD") % GameState.gold
	wave_label.text = tr("TD_WAVE") % [current_wave, max_waves]
	lives_label.text = tr("TD_LIVES") % lives
