extends Node
## Autoload: CSV 기반 다국어. 적용 시 locale 설정 + 세이브.
## Godot가 CSV를 .translation으로 변환하므로, 배포 빌드에서도 동작하도록 .translation 파일 로드.

const LOCALES := ["ko", "en", "ja", "zh_CN"]

func _ready() -> void:
	_load_translations()

func _load_translations() -> void:
	for locale in LOCALES:
		var path: String = "res://i18n/strings.%s.translation" % locale
		var trans = load(path) as Translation
		if trans:
			TranslationServer.add_translation(trans)

static func apply(lang: String) -> void:
	TranslationServer.set_locale(lang)
	GameState.language = lang
	SaveManager.save_game()
	if Engine.get_main_loop():
		(Engine.get_main_loop() as SceneTree).call_group("i18n", "refresh_text")
