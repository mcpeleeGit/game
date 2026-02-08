extends Control
## 타이틀 화면: 세계관 분위기 + 시작/설정/종료 (i18n)

@onready var logo_area: VBoxContainer = $LogoArea
@onready var game_title: Label = $LogoArea/GameTitle
@onready var subtitle: Label = $LogoArea/Subtitle
@onready var background_rect: TextureRect = $Background
@onready var overlay: ColorRect = $Overlay
@onready var start_btn: Button = $Menu/StartButton
@onready var continue_btn: Button = $Menu/ContinueButton
@onready var settings_btn: Button = $Menu/SettingsButton
@onready var quit_btn: Button = $Menu/QuitButton
@onready var footer: Label = $Footer
@onready var settings_panel: PanelContainer = $SettingsPanel
@onready var settings_title: Label = $SettingsPanel/Margin/VBox/SettingsTitle
@onready var language_label: Label = $SettingsPanel/Margin/VBox/LanguageLabel
@onready var language_option: OptionButton = $SettingsPanel/Margin/VBox/LanguageOption
@onready var settings_back_btn: Button = $SettingsPanel/Margin/VBox/BackButton

const BG_PATH := "res://assets/images/backgrounds/title_opening.png"
const FADE_DURATION := 0.6
const LANG_CODES := ["ko", "en", "ja", "zh_CN"]
const LANG_KEYS := ["LANG_KO", "LANG_EN", "LANG_JA", "LANG_ZH"]

func _ready() -> void:
	if SaveManager.has_save():
		SaveManager.load_game()
	LanguageManager.apply(GameState.language)
	var tex := load(BG_PATH) as Texture2D
	if tex:
		background_rect.texture = tex
	overlay.modulate = Color(1, 1, 1, 1)
	_start_fade_in()
	continue_btn.visible = SaveManager.has_save()
	_setup_language_option()
	refresh_text()
	start_btn.pressed.connect(_on_start_pressed)
	continue_btn.pressed.connect(_on_continue_pressed)
	settings_btn.pressed.connect(_on_settings_pressed)
	quit_btn.pressed.connect(_on_quit_pressed)
	settings_back_btn.pressed.connect(_on_settings_back)
	language_option.item_selected.connect(_on_language_selected)
	_bind_hover(start_btn)
	_bind_hover(continue_btn)
	_bind_hover(settings_btn)
	_bind_hover(quit_btn)

func _setup_language_option() -> void:
	language_option.clear()
	for k in LANG_KEYS:
		language_option.add_item(tr(k))
	var idx: int = LANG_CODES.find(GameState.language)
	if idx >= 0:
		language_option.select(idx)

func refresh_text() -> void:
	game_title.text = tr("TITLE_GAME")
	subtitle.text = tr("TITLE_SUBTITLE")
	start_btn.text = tr("TITLE_START")
	continue_btn.text = tr("TITLE_CONTINUE")
	settings_btn.text = tr("TITLE_SETTINGS")
	quit_btn.text = tr("TITLE_QUIT")
	footer.text = tr("TITLE_FOOTER")
	settings_title.text = tr("SETTINGS_TITLE")
	language_label.text = tr("SETTINGS_LANGUAGE")
	settings_back_btn.text = tr("BTN_BACK")
	for i in LANG_KEYS.size():
		language_option.set_item_text(i, tr(LANG_KEYS[i]))

func _process(_delta: float) -> void:
	# 타이틀 살짝 떠다니는 느낌
	if logo_area:
		logo_area.position.y = 180 + sin(Time.get_ticks_msec() * 0.002) * 4.0

func _start_fade_in() -> void:
	var tween := create_tween()
	tween.tween_property(overlay, "modulate", Color(1, 1, 1, 0), FADE_DURATION)

func _on_start_pressed() -> void:
	SaveManager.delete_save()
	SceneRouter.goto("res://src/ui/prologue/prologue.tscn")

func _on_continue_pressed() -> void:
	if SaveManager.load_game():
		SceneRouter.goto("res://src/world/world_map.tscn")

func _on_settings_pressed() -> void:
	settings_panel.visible = true

func _on_settings_back() -> void:
	settings_panel.visible = false

func _on_language_selected(index: int) -> void:
	if index >= 0 and index < LANG_CODES.size():
		LanguageManager.apply(LANG_CODES[index])

func _on_quit_pressed() -> void:
	get_tree().quit()

func _bind_hover(btn: Button) -> void:
	btn.mouse_entered.connect(_on_btn_hover.bind(btn, true))
	btn.mouse_exited.connect(_on_btn_hover.bind(btn, false))

func _on_btn_hover(btn: Button, entered: bool) -> void:
	btn.scale = Vector2(1.05, 1.05) if entered else Vector2.ONE
