class_name PlayerFramesBuilder
extends RefCounted
## Idle/Walk/Attack (down + up + side) 스프라이트 시트 → SpriteFrames
## Down: 64×64. Up/Side: 시트별 프레임 크기 다름 (idle_up 512×341, walk 128×341×4, attack_up 256×341×2)

const FRAME_SIZE := 64
const IDLE_PATH := "res://assets/images/characters/player.png"
const WALK_DOWN_PATH := "res://assets/images/characters/player_walk_down.png"
const ATTACK_DOWN_PATH := "res://assets/images/characters/player_attack_down.png"
const WALK_UP_PATH := "res://assets/images/characters/player_walk_up.png"
const IDLE_UP_PATH := "res://assets/images/characters/player_idle_up.png"
const IDLE_UP_2F_PATH := "res://assets/images/characters/player_idle_up_2f.png"
const WALK_SIDE_PATH := "res://assets/images/characters/player_walk_side.png"
const WALK_LEFT_PATH := "res://assets/images/characters/player_walk_left.png"
const ATTACK_UP_PATH := "res://assets/images/characters/player_attack_up.png"

static func build() -> SpriteFrames:
	var sf := SpriteFrames.new()
	var idle_tex := load(IDLE_PATH) as Texture2D
	if not idle_tex:
		return sf

	# --- Down (64×64) ---
	sf.add_animation("idle_down")
	sf.add_frame("idle_down", idle_tex, 1.0)
	sf.set_animation_loop("idle_down", true)
	sf.set_animation_speed("idle_down", 5)

	# walk_down: 새 시트 512×341, 4프레임 → 128×341
	var walk_tex := load(WALK_DOWN_PATH) as Texture2D
	sf.add_animation("walk_down")
	if walk_tex:
		for i in 4:
			var at := AtlasTexture.new()
			at.atlas = walk_tex
			at.region = Rect2(i * 128, 0, 128, 341)
			sf.add_frame("walk_down", at, 1.0)
	else:
		sf.add_frame("walk_down", idle_tex, 1.0)
	sf.set_animation_loop("walk_down", true)
	sf.set_animation_speed("walk_down", 9)

	# attack_down: 새 시트 512×341, 1프레임
	var attack_tex := load(ATTACK_DOWN_PATH) as Texture2D
	sf.add_animation("attack_down")
	if attack_tex:
		sf.add_frame("attack_down", attack_tex, 1.0)
	else:
		sf.add_frame("attack_down", idle_tex, 1.0)
	sf.set_animation_loop("attack_down", false)
	sf.set_animation_speed("attack_down", 11)

	# --- Up: walk_up 3프레임, idle_up 2프레임 또는 1프레임 ---
	var walk_up_tex := load(WALK_UP_PATH) as Texture2D
	if walk_up_tex:
		sf.add_animation("walk_up")
		var w3 := [170, 170, 172]
		for i in 3:
			var at := AtlasTexture.new()
			at.atlas = walk_up_tex
			var x := 0
			for j in i:
				x += w3[j]
			at.region = Rect2(x, 0, w3[i], 341)
			sf.add_frame("walk_up", at, 1.0)
		sf.set_animation_loop("walk_up", true)
		sf.set_animation_speed("walk_up", 9)

	var idle_up_2f := load(IDLE_UP_2F_PATH) as Texture2D
	var idle_up_1f := load(IDLE_UP_PATH) as Texture2D
	if idle_up_2f or idle_up_1f:
		sf.add_animation("idle_up")
		if idle_up_2f:
			for i in 2:
				var at := AtlasTexture.new()
				at.atlas = idle_up_2f
				at.region = Rect2(i * 256, 0, 256, 341)
				sf.add_frame("idle_up", at, 1.0)
		else:
			sf.add_frame("idle_up", idle_up_1f, 1.0)
		sf.set_animation_loop("idle_up", true)
		sf.set_animation_speed("idle_up", 5)

	var attack_up_tex := load(ATTACK_UP_PATH) as Texture2D
	if attack_up_tex:
		sf.add_animation("attack_up")
		for i in 2:
			var at := AtlasTexture.new()
			at.atlas = attack_up_tex
			at.region = Rect2(i * 256, 0, 256, 341)
			sf.add_frame("attack_up", at, 1.0)
		sf.set_animation_loop("attack_up", false)
		sf.set_animation_speed("attack_up", 11)

	# --- Side: walk_side 4프레임 (128×341), walk_left 4프레임 ---
	var walk_side_tex := load(WALK_SIDE_PATH) as Texture2D
	if walk_side_tex:
		sf.add_animation("walk_side")
		for i in 4:
			var at := AtlasTexture.new()
			at.atlas = walk_side_tex
			at.region = Rect2(i * 128, 0, 128, 341)
			sf.add_frame("walk_side", at, 1.0)
		sf.set_animation_loop("walk_side", true)
		sf.set_animation_speed("walk_side", 9)

	var walk_left_tex := load(WALK_LEFT_PATH) as Texture2D
	if walk_left_tex:
		sf.add_animation("walk_left")
		for i in 4:
			var at := AtlasTexture.new()
			at.atlas = walk_left_tex
			at.region = Rect2(i * 128, 0, 128, 341)
			sf.add_frame("walk_left", at, 1.0)
		sf.set_animation_loop("walk_left", true)
		sf.set_animation_speed("walk_left", 9)

	return sf
