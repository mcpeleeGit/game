extends Node2D
## 전투: Node2D 월드 + 적 배치, HP, 데미지 숫자, 히트 플래시, 카메라 흔들림

const BATTLE_BG_PATH := "res://assets/images/backgrounds/battle_forest.png"
const BATTLE_BG_RUINS_PATH := "res://assets/images/backgrounds/battle_ruins.png"
const BATTLE_GROUND_PATH := "res://assets/images/backgrounds/battle_ground.png"
const BATTLE_GROUND_RUINS_PATH := "res://assets/images/backgrounds/battle_ground_ruins.png"
const ENEMY_GOBLIN_PATH := "res://assets/images/characters/enemy_goblin.png"
const CHAR_SHADOW_PATH := "res://assets/images/characters/character_shadow.png"
const REGION_FOREST_PATH := "res://src/regions/region_forest.tscn"
const REWARD_GOLD_FIRST := 5
const REWARD_GOLD_NORMAL := 10
const REWARD_GOLD_RUINS := 15
const REWARD_POPUP_TIME := 0.8

@onready var player_anim: AnimatedSprite2D = $World/Player/PlayerAnim
@onready var enemy_anim: AnimatedSprite2D = $World/Enemy/EnemyAnim
@onready var player_hp_label: Label = $UI/HUD/PlayerHP
@onready var enemy_hp_label: Label = $UI/HUD/EnemyHP
@onready var attack_btn: Button = $UI/Buttons/AttackButton
@onready var run_btn: Button = $UI/Buttons/RunButton
@onready var damage_layer: Control = $UI/DamageLayer
@onready var reward_popup: Control = $UI/RewardPopup
@onready var reward_label: Label = $UI/RewardPopup/RewardLabel
@onready var cam: Camera2D = $Camera2D

var enemy_hp: int = 30
var enemy_max_hp: int = 30
var enemy_attack: int = 3
var enemy_defense: int = 0
var is_busy := false

func _ready() -> void:
	add_to_group("i18n")
	refresh_text()
	_setup_background()
	# 배치 (1280x720 기준)
	$World/Player.position = Vector2(940, 420)
	$World/Enemy.position = Vector2(340, 500)

	var sf := PlayerFramesBuilder.build()
	if sf.get_animation_names().size() > 0:
		player_anim.sprite_frames = sf
		player_anim.play("idle_down")
	_setup_enemy_goblin()
	_setup_shadows()

	attack_btn.pressed.connect(_on_attack)
	run_btn.pressed.connect(_on_run)
	_setup_battle_mode()
	_update_hud()

func _setup_background() -> void:
	var view: Vector2 = get_viewport_rect().size
	var bg := $World/Background
	var bg_path: String = BATTLE_BG_RUINS_PATH if GameState.current_region_id == "ruins" else BATTLE_BG_PATH
	var tex := load(bg_path) as Texture2D
	if not tex and GameState.current_region_id == "ruins":
		tex = load(BATTLE_BG_PATH) as Texture2D
	if tex:
		bg.texture = tex
		var ts: Vector2 = tex.get_size()
		var s: float = maxf(view.x / ts.x, view.y / ts.y)
		bg.scale = Vector2(s, s)
		bg.position = view / 2.0
		bg.modulate = Color(0.88, 0.88, 0.92) if GameState.current_region_id != "ruins" else Color(0.75, 0.78, 0.82)
	_setup_ground(view)

func _setup_ground(view: Vector2) -> void:
	var ground := $World/Ground
	var ground_path: String = BATTLE_GROUND_RUINS_PATH if GameState.current_region_id == "ruins" else BATTLE_GROUND_PATH
	var tex := load(ground_path) as Texture2D
	if not tex and GameState.current_region_id == "ruins":
		tex = load(BATTLE_GROUND_PATH) as Texture2D
	if not tex:
		ground.visible = false
		return
	ground.visible = true
	ground.texture = tex
	var ts: Vector2 = tex.get_size()
	# 하단 30~40% 커버 (가로 꽉 채움, 세로는 지면 느낌)
	var scale_x: float = (view.x + 80) / ts.x
	var scale_y: float = (view.y * 0.4) / ts.y
	ground.scale = Vector2(scale_x, scale_y)
	ground.position = Vector2(view.x / 2.0, view.y - view.y * 0.2)

func _setup_enemy_goblin() -> void:
	var tex := load(ENEMY_GOBLIN_PATH) as Texture2D
	if tex:
		var sf := SpriteFrames.new()
		sf.add_animation("idle")
		sf.add_frame("idle", tex, 1.0)
		sf.set_animation_loop("idle", true)
		enemy_anim.sprite_frames = sf
		enemy_anim.play("idle")
	enemy_anim.flip_h = false

func _setup_shadows() -> void:
	var player_shadow: Sprite2D = $World/Player/Shadow
	var enemy_shadow: Sprite2D = $World/Enemy/Shadow
	var tex := load(CHAR_SHADOW_PATH) as Texture2D
	if not tex:
		player_shadow.visible = false
		enemy_shadow.visible = false
		return
	player_shadow.texture = tex
	player_shadow.modulate = Color(1, 1, 1, 0.45)
	enemy_shadow.texture = tex
	enemy_shadow.modulate = Color(1, 1, 1, 0.45)

func _setup_battle_mode() -> void:
	if GameState.is_first_battle:
		run_btn.visible = false
		enemy_max_hp = 15
		enemy_hp = 15
		enemy_attack = 3
		enemy_defense = 0
	elif GameState.current_region_id == "ruins":
		run_btn.visible = true
		enemy_max_hp = 45
		enemy_hp = 45
		enemy_attack = 8
		enemy_defense = 2
	else:
		run_btn.visible = true
		enemy_max_hp = 30
		enemy_hp = 30
		enemy_attack = 3
		enemy_defense = 0

func _on_attack() -> void:
	if is_busy:
		return
	is_busy = true
	attack_btn.disabled = true
	run_btn.disabled = true

	var sound_fx: Node = get_node_or_null("/root/SoundFx")
	if sound_fx:
		sound_fx.play_ui_click()

	if player_anim.sprite_frames and player_anim.sprite_frames.has_animation("attack_down"):
		player_anim.play("attack_down")
		await player_anim.animation_finished
		player_anim.play("idle_down")

	var base_dmg: int = 15 if GameState.is_first_battle else 10
	var dmg_to_enemy: int = maxi(1, base_dmg - enemy_defense)
	enemy_hp = maxi(enemy_hp - dmg_to_enemy, 0)

	_hit_flash(enemy_anim, 0.12)
	_spawn_damage_number(dmg_to_enemy, $World/Enemy.global_position + Vector2(0, -60))
	_camera_shake(0.12, 6.0)
	_update_hud()

	if enemy_hp <= 0:
		await _victory_flow()
		return

	await get_tree().create_timer(0.2).timeout
	var enemy_dmg: int = enemy_attack
	if GameState.is_first_battle:
		GameState.player_hp = maxi(1, GameState.player_hp - enemy_dmg)
	else:
		GameState.player_hp -= enemy_dmg

	_hit_flash(player_anim, 0.12)
	_spawn_damage_number(enemy_dmg, $World/Player.global_position + Vector2(0, -60))
	_camera_shake(0.10, 4.0)
	_update_hud()

	if not GameState.is_first_battle and GameState.player_hp <= 0:
		player_hp_label.text = tr("BATTLE_DEFEAT")
		is_busy = false
		return

	is_busy = false
	attack_btn.disabled = false
	run_btn.disabled = false

func _on_run() -> void:
	if is_busy:
		return
	SceneRouter.goto(REGION_FOREST_PATH)

func _victory_flow() -> void:
	var gold_amount: int = REWARD_GOLD_FIRST if GameState.is_first_battle else (REWARD_GOLD_RUINS if GameState.current_region_id == "ruins" else REWARD_GOLD_NORMAL)
	GameState.gold += gold_amount
	var gained_fragment: bool = false
	if not GameState.is_first_battle and GameState.current_region_id == "ruins":
		GameState.ancient_fragments += 1
		gained_fragment = true
	if not GameState.is_first_battle and GameState.current_region_id == "forest":
		GameState.forest_cleared_once = true

	reward_label.text = (tr("REWARD_GOLD") % gold_amount) + ("\n" + tr("REWARD_FRAGMENT") if gained_fragment else "")
	reward_popup.visible = true
	await get_tree().create_timer(REWARD_POPUP_TIME).timeout
	reward_popup.visible = false

	if GameState.is_first_battle:
		await get_tree().create_timer(0.5).timeout
		GameState.first_battle_done = true
		GameState.is_first_battle = false
	SaveManager.save_game()
	SceneRouter.goto(REGION_FOREST_PATH)

func refresh_text() -> void:
	attack_btn.text = tr("BATTLE_ATTACK")
	run_btn.text = tr("BATTLE_RUN")

func _update_hud() -> void:
	player_hp_label.text = "%s: %d/%d" % [tr("HUD_HP"), GameState.player_hp, GameState.player_max_hp]
	enemy_hp_label.text = "%s: %d/%d" % [tr("BATTLE_ENEMY"), enemy_hp, enemy_max_hp]

func _spawn_damage_number(amount: int, world_pos: Vector2) -> void:
	var lbl := Label.new()
	lbl.text = str(amount)
	lbl.add_theme_font_size_override("font_size", 24)
	lbl.add_theme_color_override("font_color", Color(1, 0.9, 0.3))
	lbl.modulate.a = 1.0

	var screen_pos: Vector2 = get_viewport().get_canvas_transform() * world_pos
	lbl.position = screen_pos
	damage_layer.add_child(lbl)

	var tw := create_tween()
	tw.tween_property(lbl, "position", lbl.position + Vector2(0, -40), 0.45)
	tw.parallel().tween_property(lbl, "modulate:a", 0.0, 0.45)
	tw.finished.connect(func() -> void: lbl.queue_free())

func _hit_flash(sprite: CanvasItem, duration: float = 0.12) -> void:
	var original: Color = sprite.modulate
	sprite.modulate = Color(1.8, 1.8, 1.8, 1)
	var tw := create_tween()
	tw.tween_property(sprite, "modulate", original, duration)

func _camera_shake(duration: float = 0.12, strength: float = 6.0) -> void:
	if cam == null:
		return
	var base_pos: Vector2 = cam.position
	var elapsed: float = 0.0
	while elapsed < duration:
		elapsed += get_process_delta_time()
		cam.position = base_pos + Vector2(
			randf_range(-strength, strength),
			randf_range(-strength, strength)
		)
		await get_tree().process_frame
	cam.position = base_pos
