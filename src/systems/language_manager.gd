extends Node
## Autoload: CSV 기반 다국어. 적용 시 locale 설정 + 세이브.

const CSV_PATH := "res://i18n/strings.csv"
const LOCALES := ["ko", "en", "ja", "zh_CN"]

func _ready() -> void:
	_load_translations_from_csv()

func _load_translations_from_csv() -> void:
	if not FileAccess.file_exists(CSV_PATH):
		return
	var file := FileAccess.open(CSV_PATH, FileAccess.READ)
	if not file:
		return
	var csv_text: String = file.get_as_text()
	file.close()
	var lines: PackedStringArray = csv_text.split("\n")
	if lines.size() < 2:
		return
	var header: PackedStringArray = lines[0].split(",")
	var key_idx: int = 0
	var locale_indices: Dictionary = {}
	for i in header.size():
		var h: String = header[i].strip_edges()
		if h == "key":
			key_idx = i
		elif h in LOCALES:
			locale_indices[h] = i
	for locale in LOCALES:
		var trans := Translation.new()
		trans.locale = locale
		for j in range(1, lines.size()):
			var line: String = lines[j]
			if line.is_empty():
				continue
			var cells: PackedStringArray = line.split(",")
			if cells.size() <= key_idx:
				continue
			var key: String = cells[key_idx].strip_edges()
			if key.is_empty():
				continue
			var value: String = ""
			if locale_indices.has(locale) and locale_indices[locale] < cells.size():
				value = cells[locale_indices[locale]].strip_edges()
			trans.add_message(key, value)
		TranslationServer.add_translation(trans)

static func apply(lang: String) -> void:
	TranslationServer.set_locale(lang)
	GameState.language = lang
	SaveManager.save_game()
	if Engine.get_main_loop():
		(Engine.get_main_loop() as SceneTree).call_group("i18n", "refresh_text")
