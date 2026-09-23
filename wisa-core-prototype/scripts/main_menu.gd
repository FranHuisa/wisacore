extends Control

## =========================================================
## WisaCore - Menú principal (Jugar / Ajustes / Salir)
## Centrado calculado a mano con el tamaño real de cada caja
## (más fiable que depender de presets de anclas anidados).
## =========================================================

const BG_COLOR := Color(0.082, 0.067, 0.102, 1.0)
const PANEL_COLOR := Color(0.169, 0.125, 0.220, 1.0)
const ACCENT_COLOR := Color(0.478, 0.125, 0.188, 1.0)
const TEXT_COLOR := Color(0.88, 0.85, 0.90, 1.0)
const OUTLINE_COLOR := Color(0.039, 0.031, 0.063, 1.0)

var menu_box: VBoxContainer
var settings_box: VBoxContainer
var volume_slider: HSlider
var fullscreen_check: CheckButton
var master_bus_index: int


func _ready() -> void:
	set_anchors_preset(Control.PRESET_FULL_RECT)
	master_bus_index = AudioServer.get_bus_index("Master")
	AudioServer.set_bus_volume_db(master_bus_index, linear_to_db(GameSave.get_master_volume()))
	AudioServer.set_bus_mute(master_bus_index, GameSave.get_master_muted())
	if GameSave.get_fullscreen():
		DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_FULLSCREEN)

	var bg := ColorRect.new()
	bg.color = BG_COLOR
	bg.set_anchors_preset(Control.PRESET_FULL_RECT)
	bg.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(bg)

	_build_menu()
	_build_settings()

	get_viewport().size_changed.connect(_center_boxes)
	call_deferred("_center_boxes")


func _center_boxes() -> void:
	var vp_size := get_viewport_rect().size
	if menu_box != null:
		menu_box.position = ((vp_size - menu_box.size) / 2.0).round()
	if settings_box != null:
		settings_box.position = ((vp_size - settings_box.size) / 2.0).round()


func _build_menu() -> void:
	menu_box = VBoxContainer.new()
	menu_box.add_theme_constant_override("separation", 18)
	add_child(menu_box)

	var title := Label.new()
	title.text = "WisaCore"
	title.add_theme_font_size_override("font_size", 56)
	title.add_theme_color_override("font_color", ACCENT_COLOR)
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	menu_box.add_child(title)

	var subtitle := Label.new()
	subtitle.text = "Prototipo"
	subtitle.add_theme_color_override("font_color", TEXT_COLOR)
	subtitle.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	subtitle.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	menu_box.add_child(subtitle)

	var spacer := Control.new()
	spacer.custom_minimum_size = Vector2(0, 16)
	menu_box.add_child(spacer)

	var play_button := _make_button("Jugar")
	play_button.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	play_button.pressed.connect(_on_play_pressed)
	menu_box.add_child(play_button)

	var settings_button := _make_button("Ajustes")
	settings_button.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	settings_button.pressed.connect(_on_settings_pressed)
	menu_box.add_child(settings_button)

	var quit_button := _make_button("Salir")
	quit_button.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	quit_button.pressed.connect(_on_quit_pressed)
	menu_box.add_child(quit_button)


func _build_settings() -> void:
	settings_box = VBoxContainer.new()
	settings_box.add_theme_constant_override("separation", 20)
	settings_box.custom_minimum_size = Vector2(300, 0)
	settings_box.visible = false
	add_child(settings_box)

	var settings_title := Label.new()
	settings_title.text = "Ajustes"
	settings_title.add_theme_color_override("font_color", ACCENT_COLOR)
	settings_title.add_theme_font_size_override("font_size", 28)
	settings_title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	settings_box.add_child(settings_title)

	var volume_label := Label.new()
	volume_label.text = "Volumen general"
	volume_label.add_theme_color_override("font_color", TEXT_COLOR)
	settings_box.add_child(volume_label)

	volume_slider = HSlider.new()
	volume_slider.min_value = 0.0
	volume_slider.max_value = 1.0
	volume_slider.step = 0.01
	# El volumen (y la pantalla completa, más abajo) ahora se guardan en
	# GameSave -- ver el mismo ajuste en el menú de pausa dentro de la
	# partida (main.gd) -- así que se parte de lo guardado en vez de leer
	# solo el estado actual del bus de audio.
	volume_slider.value = GameSave.get_master_volume()
	volume_slider.value_changed.connect(_on_volume_changed)
	settings_box.add_child(volume_slider)

	fullscreen_check = CheckButton.new()
	fullscreen_check.text = "Pantalla completa"
	fullscreen_check.add_theme_color_override("font_color", TEXT_COLOR)
	fullscreen_check.button_pressed = DisplayServer.window_get_mode() == DisplayServer.WINDOW_MODE_FULLSCREEN
	fullscreen_check.toggled.connect(_on_fullscreen_toggled)
	settings_box.add_child(fullscreen_check)

	var back_button := _make_button("Volver")
	back_button.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	back_button.pressed.connect(_on_back_pressed)
	settings_box.add_child(back_button)


func _make_button(text: String) -> Button:
	var button := Button.new()
	button.text = text
	button.custom_minimum_size = Vector2(220, 48)
	button.add_theme_color_override("font_color", TEXT_COLOR)
	button.add_theme_color_override("font_hover_color", TEXT_COLOR)

	var style := StyleBoxFlat.new()
	style.bg_color = PANEL_COLOR
	style.border_color = OUTLINE_COLOR
	style.set_border_width_all(3)
	style.set_corner_radius_all(2)
	button.add_theme_stylebox_override("normal", style)

	var hover_style: StyleBoxFlat = style.duplicate()
	hover_style.bg_color = ACCENT_COLOR
	button.add_theme_stylebox_override("hover", hover_style)
	button.add_theme_stylebox_override("pressed", hover_style)

	return button


func _on_play_pressed() -> void:
	get_tree().change_scene_to_file("res://scenes/Main.tscn")


func _on_settings_pressed() -> void:
	menu_box.visible = false
	settings_box.visible = true


func _on_back_pressed() -> void:
	settings_box.visible = false
	menu_box.visible = true


func _on_quit_pressed() -> void:
	get_tree().quit()


func _on_volume_changed(value: float) -> void:
	AudioServer.set_bus_volume_db(master_bus_index, linear_to_db(value))
	GameSave.set_master_volume(value)


func _on_fullscreen_toggled(pressed: bool) -> void:
	if pressed:
		DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_FULLSCREEN)
	else:
		DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_WINDOWED)
	GameSave.set_fullscreen(pressed)
