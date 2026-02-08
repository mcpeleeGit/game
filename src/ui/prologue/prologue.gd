extends Control
## 프롤로그 컷씬: 오프닝 이미지 + 짧은 텍스트 → 월드맵

@onready var background_rect: TextureRect = $Background
@onready var fade_rect: ColorRect = $Fade
@onready var text_label: Label = $TextBox/Margin/Label
@onready var skip_hint: Label = $SkipHint

const BG_PATH := "res://assets/images/backgrounds/title_opening.png"
const WORLD_MAP_PATH := "res://src/world/world_map.tscn"
const FADE_DURATION := 0.5
const TEXT_DISPLAY_TIME := 3.0

var _skipped := false

func _ready() -> void:
	var tex := load(BG_PATH) as Texture2D
	if tex:
		background_rect.texture = tex
	text_label.text = tr("PROLOGUE_TEXT")
	skip_hint.text = tr("PROLOGUE_SKIP")
	text_label.modulate.a = 0.0
	fade_rect.modulate = Color(1, 1, 1, 1)
	_run_sequence()

func _input(event: InputEvent) -> void:
	if _skipped:
		return
	if event is InputEventMouseButton and event.pressed:
		_skip()
	elif event is InputEventKey and event.pressed:
		_skip()

func _skip() -> void:
	_skipped = true
	var tween := create_tween()
	tween.tween_property(fade_rect, "modulate", Color(1, 1, 1, 1), FADE_DURATION * 0.5)
	tween.tween_callback(func() -> void: SceneRouter.goto(WORLD_MAP_PATH))

func _run_sequence() -> void:
	# Fade in (화면이 서서히 보임)
	var tween := create_tween()
	tween.tween_property(fade_rect, "modulate", Color(1, 1, 1, 0), FADE_DURATION)
	tween.tween_callback(_show_text)
	tween.tween_interval(TEXT_DISPLAY_TIME)
	tween.tween_callback(_fade_out_and_go)

func _show_text() -> void:
	var t := create_tween()
	t.tween_property(text_label, "modulate:a", 1.0, 0.4)

func _fade_out_and_go() -> void:
	if _skipped:
		return
	var tween := create_tween()
	tween.tween_property(fade_rect, "modulate", Color(1, 1, 1, 1), FADE_DURATION)
	tween.tween_callback(func() -> void: SceneRouter.goto(WORLD_MAP_PATH))
