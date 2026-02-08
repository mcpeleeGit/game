extends Node
## 사운드 연출 (Autoload: SoundFx)
## assets/sounds/ 에 ui_click.wav, transition.wav 넣으면 자동 재생 (없으면 무시)

const UI_CLICK_PATH := "res://assets/sounds/ui_click.wav"
const TRANSITION_PATH := "res://assets/sounds/transition.wav"
## 인디/모바일 기준: 약간 작다 싶을 정도가 적당
const UI_CLICK_DB := -8.0
const TRANSITION_DB := -10.0

var _player: AudioStreamPlayer

func _ready() -> void:
	_player = AudioStreamPlayer.new()
	add_child(_player)

func play_ui_click() -> void:
	_try_play(UI_CLICK_PATH, UI_CLICK_DB)

func play_transition() -> void:
	_try_play(TRANSITION_PATH, TRANSITION_DB)

func _try_play(path: String, volume_db: float = 0.0) -> void:
	var stream := load(path) as AudioStream
	if stream:
		_player.stream = stream
		_player.volume_db = volume_db
		_player.play()
