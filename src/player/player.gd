extends CharacterBody2D
## 탑다운 플레이어: 4방향 Idle / Walk / Attack

@export var speed := 250.0

@onready var anim: AnimatedSprite2D = $Anim

var is_attacking := false
var last_facing := "down"  # down / up / left / right

func _ready() -> void:
	var sf := PlayerFramesBuilder.build()
	if sf.get_animation_names().size() > 0:
		anim.sprite_frames = sf
		anim.play("idle_down")

func _physics_process(_delta: float) -> void:
	if is_attacking:
		return

	var dir := Vector2(
		Input.get_action_strength("ui_right") - Input.get_action_strength("ui_left"),
		Input.get_action_strength("ui_down") - Input.get_action_strength("ui_up")
	).normalized()

	velocity = dir * speed
	move_and_slide()

	if dir.length() > 0.0:
		if dir.x > 0.3:
			last_facing = "right"
		elif dir.x < -0.3:
			last_facing = "left"
		elif dir.y < -0.3:
			last_facing = "up"
		elif dir.y > 0.3:
			last_facing = "down"

	if anim.sprite_frames == null:
		return
	var walk_anim := _get_walk_anim()
	var idle_anim := _get_idle_anim()
	if dir.length() > 0.0:
		if anim.sprite_frames.has_animation(walk_anim) and anim.animation != walk_anim:
			anim.play(walk_anim)
	else:
		if anim.sprite_frames.has_animation(idle_anim) and anim.animation != idle_anim:
			anim.play(idle_anim)

func _get_walk_anim() -> String:
	match last_facing:
		"right": return "walk_side"
		"left": return "walk_left"
		"up": return "walk_up" if anim.sprite_frames.has_animation("walk_up") else "walk_down"
		_: return "walk_down"

func _get_idle_anim() -> String:
	match last_facing:
		"up": return "idle_up" if anim.sprite_frames.has_animation("idle_up") else "idle_down"
		_: return "idle_down"

func attack() -> void:
	if is_attacking:
		return
	var attack_anim := "attack_up" if last_facing == "up" and anim.sprite_frames.has_animation("attack_up") else "attack_down"
	if anim.sprite_frames == null or not anim.sprite_frames.has_animation(attack_anim):
		return
	is_attacking = true
	anim.play(attack_anim)
	await anim.animation_finished
	is_attacking = false
