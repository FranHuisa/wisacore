extends Node2D

## =========================================================
## WisaCore - Controlador principal de la escena de prueba
## Construye la UI por código (barra de vida, objetivo,
## habilidades) y la conecta a las señales del jugador.
## =========================================================

@onready var player: CharacterBody2D = $Player

var current_target_ref: Node2D = null

var player_health_bar: ProgressBar
var player_health_label: Label
var player_stamina_bar: ProgressBar
var target_panel: Control
var target_name_label: Label
var target_health_bar: ProgressBar
var power_cd_label: Label
var dodge_cd_label: Label

var inventory_panel: Control
var equipment_buttons: Dictionary = {}
var backpack_buttons: Array = []
var ui_canvas: CanvasLayer
var windows_layer: Control
var floating_windows: Array = []

var character_panel: Control
var character_value_labels: Dictionary = {}

var abilities_panel: Control
var ability_cooldown_labels: Dictionary = {}

@onready var crafting_station: CraftingStation = $CraftingStation
var near_crafting_station: bool = false
var craft_prompt_label: Label

var crafting_panel: Control
var crafting_list_box: VBoxContainer

var recipes_panel: Control
var recipes_list_box: VBoxContainer

var quests_panel: Control
var quests_active_box: VBoxContainer
var quests_completed_box: VBoxContainer

var pickup_prompt_label: Label
var gold_label: Label

var world_drop_zone: WorldDropZone
var drop_quantity_popup: PopupPanel

var skill_tree_panel: Control
var skill_points_label: Label
var skill_node_buttons: Dictionary = {}
var skill_tree_lines: Array = []

const SKILL_CELL_SIZE := Vector2(90, 90)
const SKILL_NODE_SIZE := Vector2(56, 56)
const SKILL_TREE_ORIGIN := Vector2(30, 30)

## --- Ventana pequeña de controles (antes era un texto siempre visible) ---
var controls_panel: Control
var controls_text_label: Label
var controls_hint_label: Label

## --- Menú de pausa (ESC) y Ajustes ---
var pause_dim: ColorRect
var pause_menu_panel: Control
var settings_panel: Control
var settings_tabs: TabContainer
var volume_slider: HSlider
var fullscreen_check: CheckButton
var mute_check: CheckButton
var master_bus_index: int = 0

## Rebind de teclas (solo las que abren ventanas, ver GameSave.DEFAULT_KEYBINDS).
var rebind_buttons: Dictionary = {}
var rebinding_action: String = ""

## --- Música (provisional) ---
## En el bus "Master" a propósito: así el slider/casilla de silencio de
## Ajustes > General (que ya controla ese bus) sirve para probarla sin
## tener que montar un bus de música aparte todavía.
const MUSIC_TRACK_PATH := "res://media/main_soundtrack.mp3"
var music_player: AudioStreamPlayer

const KEYBIND_LABELS := {
	"inventory": "Inventario",
	"character": "Personaje",
	"abilities": "Habilidades",
	"quests": "Misiones",
	"skills": "Árbol de habilidades",
	"recipes": "Recetario",
	"craft": "Interactuar / Craftear",
	"pickup": "Recoger objeto",
	"controls": "Ventana de controles",
}
const KEYBIND_ORDER := ["inventory", "character", "abilities", "quests", "skills", "recipes", "craft", "pickup", "controls"]


func _ready() -> void:
	_apply_saved_display_and_audio_settings()
	_build_ui()
	player.health_changed.connect(_on_player_health_changed)
	player.stamina_changed.connect(_on_player_stamina_changed)
	player.target_changed.connect(_on_target_changed)
	player.ability_cooldown_changed.connect(_on_ability_cooldown_changed)
	player.inventory_changed.connect(_refresh_inventory_ui)
	player.inventory_changed.connect(_refresh_character_ui)
	player.inventory_changed.connect(_refresh_quests_ui)
	player.gold_changed.connect(_on_gold_changed)
	player.quests_changed.connect(_refresh_quests_ui)
	player.pickup_target_changed.connect(_on_pickup_target_changed)
	player.skill_tree_changed.connect(_refresh_skill_tree_ui)
	_on_player_health_changed(player.current_health, player.max_health)
	_on_player_stamina_changed(player.current_stamina, player.max_stamina)
	_build_inventory_ui()
	_build_character_ui()
	_build_abilities_ui()
	_build_crafting_ui()
	_build_recipes_ui()
	_build_quests_ui()
	_build_skill_tree_ui()
	_build_controls_ui()
	_build_pause_menu_ui()
	_build_music()

	crafting_station.player_entered_range.connect(_on_crafting_range_entered)
	crafting_station.player_exited_range.connect(_on_crafting_range_exited)
	player.add_to_group("player")


func _input(event: InputEvent) -> void:
	if not (event is InputEventKey and event.pressed and not event.echo):
		return

	# --- Captura de tecla mientras se está reasignando un atajo desde
	# Ajustes > Controles. Tiene prioridad sobre todo lo demás: cualquier
	# tecla (menos ESC, que cancela) se guarda como la nueva tecla. ---
	if rebinding_action != "":
		if event.physical_keycode == KEY_ESCAPE:
			_cancel_rebind()
		else:
			_finish_rebind(event.physical_keycode)
		get_viewport().set_input_as_handled()
		return

	if event.physical_keycode == KEY_ESCAPE:
		if settings_panel.visible:
			_close_settings()
		elif pause_menu_panel.visible:
			_close_pause_menu()
		else:
			var closed_something := false
			for w in floating_windows:
				if w.visible:
					w.visible = false
					closed_something = true
			if not closed_something:
				_open_pause_menu()
		return

	# Con el menú de pausa o los ajustes abiertos, ningún otro atajo
	# (inventario, misiones...) debe reaccionar por debajo.
	if pause_menu_panel.visible or settings_panel.visible:
		return

	if event.physical_keycode == GameSave.get_keybind("inventory"):
		_toggle_window(inventory_panel, _refresh_inventory_ui)
	elif event.physical_keycode == GameSave.get_keybind("character"):
		_toggle_window(character_panel, _refresh_character_ui)
	elif event.physical_keycode == GameSave.get_keybind("abilities"):
		_toggle_window(abilities_panel, Callable())
	elif event.physical_keycode == GameSave.get_keybind("recipes"):
		_toggle_window(recipes_panel, _refresh_recipes_ui)
	elif event.physical_keycode == GameSave.get_keybind("quests"):
		_toggle_window(quests_panel, _refresh_quests_ui)
	elif event.physical_keycode == GameSave.get_keybind("skills"):
		_toggle_window(skill_tree_panel, _refresh_skill_tree_ui)
	elif event.physical_keycode == GameSave.get_keybind("controls"):
		_toggle_window(controls_panel, _refresh_controls_ui)
	elif event.physical_keycode == GameSave.get_keybind("craft"):
		if near_crafting_station:
			_toggle_window(crafting_panel, _refresh_crafting_ui)
	elif event.physical_keycode >= KEY_1 and event.physical_keycode <= KEY_5:
		# Atajos 1-5 reservados para un futuro sistema de equipamiento
		# rápido (p. ej. cambiar de arma o usar un objeto desde una
		# barra de accesos directos). Preparados y conectados, pero
		# sin acción todavía: solo llaman a este stub.
		var quick_index: int = event.physical_keycode - KEY_1
		_on_quick_equip_shortcut(quick_index)


func _toggle_window(panel: Control, on_open_refresh: Callable) -> void:
	if panel == null:
		return
	panel.visible = not panel.visible
	if panel.visible and on_open_refresh.is_valid():
		on_open_refresh.call()


func _on_crafting_range_entered() -> void:
	near_crafting_station = true
	craft_prompt_label.visible = true


func _on_crafting_range_exited() -> void:
	near_crafting_station = false
	craft_prompt_label.visible = false
	if crafting_panel != null:
		crafting_panel.visible = false


func _on_gold_changed(_amount: int) -> void:
	_refresh_inventory_ui()


func _on_pickup_target_changed(item_label: String) -> void:
	if pickup_prompt_label == null:
		return
	if item_label == "":
		pickup_prompt_label.visible = false
	else:
		pickup_prompt_label.text = "Pulsa F para recoger: %s" % item_label
		pickup_prompt_label.visible = true


func _on_quick_equip_shortcut(index: int) -> void:
	# TODO: cuando exista una barra de accesos rápidos, usar "index" (0-4)
	# para equipar/usar el objeto asignado a esa posición. De momento no
	# hace nada: el atajo de teclado ya está preparado para ese día.
	pass


func _build_ui() -> void:
	var canvas := CanvasLayer.new()
	add_child(canvas)
	ui_canvas = canvas

	var ui := Control.new()
	ui.set_anchors_preset(Control.PRESET_FULL_RECT)
	ui.mouse_filter = Control.MOUSE_FILTER_IGNORE
	canvas.add_child(ui)

	var vp_size := get_viewport().get_visible_rect().size

	# --- Barra de vida del jugador ---
	player_health_bar = ProgressBar.new()
	player_health_bar.position = Vector2(20, 20)
	player_health_bar.size = Vector2(300, 24)
	player_health_bar.show_percentage = false
	ui.add_child(player_health_bar)

	player_health_label = Label.new()
	player_health_label.position = Vector2(20, 46)
	ui.add_child(player_health_label)

	# --- Barra de aguante (estamina) del jugador ---
	player_stamina_bar = ProgressBar.new()
	player_stamina_bar.position = Vector2(20, 70)
	player_stamina_bar.size = Vector2(300, 14)
	player_stamina_bar.show_percentage = false
	ui.add_child(player_stamina_bar)

	# --- Panel de objetivo (tab-target), centrado arriba ---
	target_panel = Control.new()
	target_panel.position = Vector2(vp_size.x / 2.0 - 150.0, 20)
	target_panel.size = Vector2(300, 50)
	target_panel.visible = false
	ui.add_child(target_panel)

	target_name_label = Label.new()
	target_name_label.size = Vector2(300, 20)
	target_panel.add_child(target_name_label)

	target_health_bar = ProgressBar.new()
	target_health_bar.position = Vector2(0, 22)
	target_health_bar.size = Vector2(300, 20)
	target_health_bar.show_percentage = false
	target_panel.add_child(target_health_bar)

	# --- Barra de habilidades, centrada abajo ---
	var ability_bar := HBoxContainer.new()
	ability_bar.position = Vector2(vp_size.x / 2.0 - 120.0, vp_size.y - 90.0)
	ability_bar.add_theme_constant_override("separation", 12)
	ui.add_child(ability_bar)

	var basic_slot := _make_ability_slot("1\nGolpe")
	ability_bar.add_child(basic_slot)

	var power_slot := _make_ability_slot("2\nGolpe de\nPoder")
	power_cd_label = Label.new()
	power_cd_label.position = Vector2(4, 46)
	power_slot.add_child(power_cd_label)
	ability_bar.add_child(power_slot)

	var dodge_slot := _make_ability_slot("Espacio\nEsquivar")
	dodge_cd_label = Label.new()
	dodge_cd_label.position = Vector2(4, 46)
	dodge_slot.add_child(dodge_cd_label)
	ability_bar.add_child(dodge_slot)

	# --- Aviso pequeño de controles, anclado arriba a la derecha. La
	# lista completa (antes siempre visible y molesta) ahora vive en su
	# propia ventanita, ver _build_controls_ui(). ---
	controls_hint_label = Label.new()
	controls_hint_label.position = Vector2(vp_size.x - 200.0, 20)
	controls_hint_label.add_theme_color_override("font_color", Color(0.6, 0.58, 0.62))
	_refresh_controls_hint()
	ui.add_child(controls_hint_label)

	# --- Aviso de interacción con la estación de crafteo ---
	craft_prompt_label = Label.new()
	craft_prompt_label.text = "Pulsa E para craftear"
	craft_prompt_label.add_theme_font_size_override("font_size", 18)
	craft_prompt_label.add_theme_color_override("font_color", Color(0.95, 0.9, 0.6))
	craft_prompt_label.position = Vector2(vp_size.x / 2.0 - 90.0, vp_size.y - 140.0)
	craft_prompt_label.visible = false
	ui.add_child(craft_prompt_label)

	# --- Aviso de "recoger objeto del suelo" ---
	pickup_prompt_label = Label.new()
	pickup_prompt_label.text = ""
	pickup_prompt_label.add_theme_font_size_override("font_size", 18)
	pickup_prompt_label.add_theme_color_override("font_color", Color(0.95, 0.9, 0.6))
	pickup_prompt_label.position = Vector2(vp_size.x / 2.0 - 120.0, vp_size.y - 165.0)
	pickup_prompt_label.visible = false
	ui.add_child(pickup_prompt_label)

	# --- Zona invisible para soltar objetos de la mochila en el mundo ---
	# Se añade a "ui" (que se añadió antes que "windows_layer" a "canvas"),
	# así que queda por debajo de todas las ventanas flotantes y solo
	# recibe el drop cuando el jugador suelta fuera de ellas.
	world_drop_zone = WorldDropZone.new()
	world_drop_zone.set_anchors_preset(Control.PRESET_FULL_RECT)
	world_drop_zone.mouse_filter = Control.MOUSE_FILTER_PASS
	world_drop_zone.on_item_dropped = _on_backpack_item_dropped_to_world
	ui.add_child(world_drop_zone)


## --- Música (provisional) ---
##
## El .mp3 no viene marcado como "loop" desde el importador de Godot
## (habría que tocar main_soundtrack.mp3.import), así que el bucle se
## hace por código: al terminar, vuelve a sonar desde el principio.
func _build_music() -> void:
	if not ResourceLoader.exists(MUSIC_TRACK_PATH):
		return
	var stream: AudioStream = load(MUSIC_TRACK_PATH)
	if stream == null:
		return
	music_player = AudioStreamPlayer.new()
	music_player.stream = stream
	music_player.bus = "Master"
	add_child(music_player)
	music_player.finished.connect(func(): music_player.play())
	music_player.play()


func _make_ability_slot(label_text: String) -> Panel:
	var slot := Panel.new()
	slot.custom_minimum_size = Vector2(70, 70)
	var label := Label.new()
	label.position = Vector2(4, 4)
	label.text = label_text
	slot.add_child(label)
	return slot


func _on_player_health_changed(current: float, max_value: float) -> void:
	player_health_bar.max_value = max_value
	player_health_bar.value = current
	player_health_label.text = "%d / %d" % [int(current), int(max_value)]


func _on_player_stamina_changed(current: float, max_value: float) -> void:
	player_stamina_bar.max_value = max_value
	player_stamina_bar.value = current


func _on_target_changed(target: Node2D) -> void:
	if current_target_ref and is_instance_valid(current_target_ref):
		if current_target_ref.health_changed.is_connected(_on_target_health_changed):
			current_target_ref.health_changed.disconnect(_on_target_health_changed)
		if current_target_ref.died.is_connected(_on_target_died):
			current_target_ref.died.disconnect(_on_target_died)

	current_target_ref = target

	if target == null:
		target_panel.visible = false
		return

	target_panel.visible = true
	target_name_label.text = "Aberración"
	target.health_changed.connect(_on_target_health_changed)
	target.died.connect(_on_target_died)
	_on_target_health_changed(target.current_health, target.max_health)


func _on_target_health_changed(current: float, max_value: float) -> void:
	target_health_bar.max_value = max_value
	target_health_bar.value = current


func _on_target_died() -> void:
	target_panel.visible = false
	current_target_ref = null


func _get_windows_layer() -> Control:
	if windows_layer == null:
		windows_layer = Control.new()
		windows_layer.set_anchors_preset(Control.PRESET_FULL_RECT)
		windows_layer.mouse_filter = Control.MOUSE_FILTER_IGNORE
		ui_canvas.add_child(windows_layer)
	return windows_layer


## Crea una ventana flotante y arrastrable (barra de título + X).
## Devuelve {"panel": PanelContainer, "box": VBoxContainer} para que
## quien la llame añada su propio contenido dentro de "box".
func _make_window(title_text: String, initial_position: Vector2) -> Dictionary:
	var window_panel := PanelContainer.new()
	window_panel.position = initial_position
	window_panel.visible = false

	var window_style := StyleBoxFlat.new()
	window_style.bg_color = Color(0.11, 0.09, 0.14, 0.98)
	window_style.border_color = Color(0.039, 0.031, 0.063)
	window_style.set_border_width_all(3)
	window_style.set_content_margin_all(14)
	window_panel.add_theme_stylebox_override("panel", window_style)

	_get_windows_layer().add_child(window_panel)
	floating_windows.append(window_panel)

	var window_box := VBoxContainer.new()
	window_box.add_theme_constant_override("separation", 10)
	window_panel.add_child(window_box)

	# --- Barra de título: arrastrable, con botón de cerrar (X) ---
	var title_bar := HBoxContainer.new()
	title_bar.set_script(load("res://scripts/drag_handle.gd"))
	title_bar.target = window_panel
	title_bar.mouse_default_cursor_shape = Control.CURSOR_MOVE
	window_box.add_child(title_bar)

	var window_title := Label.new()
	window_title.text = title_text
	window_title.add_theme_color_override("font_color", Color(0.478, 0.125, 0.188))
	window_title.add_theme_font_size_override("font_size", 20)
	window_title.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	title_bar.add_child(window_title)

	var close_button := _make_slot_button("X")
	close_button.custom_minimum_size = Vector2(26, 26)
	close_button.pressed.connect(func(): window_panel.visible = false)
	title_bar.add_child(close_button)

	return {"panel": window_panel, "box": window_box}


func _build_inventory_ui() -> void:
	if ui_canvas == null:
		push_warning("No se pudo construir el inventario: falta el CanvasLayer.")
		return

	var vp_size := get_viewport().get_visible_rect().size
	var win := _make_window("Inventario", Vector2(vp_size.x - 380.0, 90.0))
	inventory_panel = win["panel"]
	var window_box: VBoxContainer = win["box"]

	# --- Oro persistente ---
	gold_label = Label.new()
	gold_label.text = "Oro: 0"
	gold_label.add_theme_color_override("font_color", Color(0.85, 0.65, 0.15))
	gold_label.add_theme_font_size_override("font_size", 15)
	window_box.add_child(gold_label)

	# --- Equipamiento como un "muñeco": silueta central + ranuras con icono ---
	var equip_title := Label.new()
	equip_title.text = "Equipo"
	equip_title.add_theme_color_override("font_color", Color(0.478, 0.125, 0.188))
	equip_title.add_theme_font_size_override("font_size", 16)
	window_box.add_child(equip_title)

	var paperdoll := Control.new()
	paperdoll.custom_minimum_size = Vector2(320, 380)
	paperdoll.clip_contents = true
	window_box.add_child(paperdoll)

	var silhouette := TextureRect.new()
	silhouette.texture = load("res://assets/ui/character_silhouette.png")
	silhouette.anchor_left = 0.30
	silhouette.anchor_right = 0.70
	silhouette.anchor_top = 0.06
	silhouette.anchor_bottom = 0.91
	silhouette.offset_left = 0
	silhouette.offset_right = 0
	silhouette.offset_top = 0
	silhouette.offset_bottom = 0
	silhouette.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	silhouette.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	silhouette.mouse_filter = Control.MOUSE_FILTER_IGNORE
	silhouette.modulate = Color(1, 1, 1, 0.35)
	paperdoll.add_child(silhouette)

	# Icono genérico que se ve en la ranura cuando está vacía (o cuando el
	# objeto equipado no trae su propio icon_path). El de ARMA usa la
	# espada como icono "por defecto"; si equipas un arco o un báculo,
	# su propio icono sustituye a este automáticamente.
	var slot_icons := {
		Equipment.Slot.CABEZA: "res://assets/ui/icons/helmet.png",
		Equipment.Slot.PECHO: "res://assets/ui/icons/chest.png",
		Equipment.Slot.MANOS: "res://assets/ui/icons/gloves.png",
		Equipment.Slot.PIERNAS: "res://assets/ui/icons/legs.png",
		Equipment.Slot.PIES: "res://assets/ui/icons/boots.png",
		Equipment.Slot.ACCESORIO_1: "res://assets/ui/icons/ring.png",
		Equipment.Slot.ACCESORIO_2: "res://assets/ui/icons/ring.png",
		Equipment.Slot.COLLAR: "res://assets/ui/icons/necklace.png",
		Equipment.Slot.CINTURON: "res://assets/ui/icons/belt.png",
		Equipment.Slot.BRAZALETE: "res://assets/ui/icons/bracelet.png",
		Equipment.Slot.ARMA: "res://assets/ui/icons/weapon_sword.png",
		Equipment.Slot.ARMA_SECUNDARIA: "res://assets/ui/icons/shield.png",
	}

	# Dos columnas de ranuras, una a cada lado de la silueta (contenedor
	# 320x380). Orden pedido:
	#   Casco - Colgante        Guantes - Cinturón
	#   Pechera - Anillo        Botas -
	#   Pantalón - Anillo       Arma - Escudo
	var slot_positions := {
		Equipment.Slot.CABEZA: Vector2(16, 6),
		Equipment.Slot.PECHO: Vector2(16, 68),
		Equipment.Slot.PIERNAS: Vector2(16, 130),
		Equipment.Slot.MANOS: Vector2(16, 192),
		Equipment.Slot.PIES: Vector2(16, 254),
		Equipment.Slot.ARMA: Vector2(16, 316),
		Equipment.Slot.COLLAR: Vector2(256, 6),
		Equipment.Slot.ACCESORIO_1: Vector2(256, 68),
		Equipment.Slot.ACCESORIO_2: Vector2(256, 130),
		Equipment.Slot.CINTURON: Vector2(256, 192),
		Equipment.Slot.BRAZALETE: Vector2(256, 254),
		Equipment.Slot.ARMA_SECUNDARIA: Vector2(256, 316),
	}

	for slot in slot_positions.keys():
		var button := _make_equip_slot_button(slot_icons.get(slot, ""))
		button.position = slot_positions[slot]
		button.custom_minimum_size = Vector2(48, 48)
		button.size = Vector2(48, 48)
		button.pressed.connect(_on_equipment_slot_pressed.bind(slot))
		button.slot_kind = "equip"
		button.equip_slot_id = slot
		button.on_drop = _handle_item_drop
		paperdoll.add_child(button)
		equipment_buttons[slot] = button

	# --- Mochila 5x5 ---
	var backpack_title := Label.new()
	backpack_title.text = "Mochila (5x5)"
	backpack_title.add_theme_color_override("font_color", Color(0.478, 0.125, 0.188))
	backpack_title.add_theme_font_size_override("font_size", 16)
	window_box.add_child(backpack_title)

	var grid := GridContainer.new()
	grid.columns = Inventory.COLUMNS
	grid.add_theme_constant_override("h_separation", 4)
	grid.add_theme_constant_override("v_separation", 4)
	window_box.add_child(grid)

	backpack_buttons.clear()
	for i in range(Inventory.SIZE):
		var button := _make_slot_button("")
		button.custom_minimum_size = Vector2(48, 44)
		button.pressed.connect(_on_backpack_slot_pressed.bind(i))
		button.slot_kind = "backpack"
		button.backpack_index = i
		button.on_drop = _handle_item_drop
		grid.add_child(button)
		backpack_buttons.append(button)


func _make_equip_slot_button(icon_path: String) -> ItemSlotButton:
	var button := ItemSlotButton.new()
	button.text = ""
	button.default_icon_path = icon_path
	if icon_path != "":
		button.icon = load(icon_path)
	button.expand_icon = true
	button.icon_alignment = HORIZONTAL_ALIGNMENT_CENTER
	button.vertical_icon_alignment = VERTICAL_ALIGNMENT_CENTER

	var style := StyleBoxFlat.new()
	style.bg_color = Color(0.169, 0.125, 0.220, 0.85)
	style.border_color = Color(0.039, 0.031, 0.063)
	style.set_border_width_all(2)
	style.set_corner_radius_all(6)
	style.set_content_margin_all(7)
	button.add_theme_stylebox_override("normal", style)

	var hover_style: StyleBoxFlat = style.duplicate()
	hover_style.bg_color = Color(0.3, 0.2, 0.3, 0.9)
	button.add_theme_stylebox_override("hover", hover_style)

	return button


func _make_slot_button(text: String) -> ItemSlotButton:
	var button := ItemSlotButton.new()
	button.text = text
	button.clip_text = true
	button.add_theme_font_size_override("font_size", 12)
	button.add_theme_color_override("font_color", Color(0.88, 0.85, 0.90))

	var style := StyleBoxFlat.new()
	style.bg_color = Color(0.169, 0.125, 0.220)
	style.border_color = Color(0.039, 0.031, 0.063)
	style.set_border_width_all(2)
	button.add_theme_stylebox_override("normal", style)

	var hover_style: StyleBoxFlat = style.duplicate()
	hover_style.bg_color = Color(0.3, 0.2, 0.3)
	button.add_theme_stylebox_override("hover", hover_style)

	return button


func _refresh_inventory_ui() -> void:
	if gold_label != null:
		gold_label.text = "Oro: %d" % player.gold

	for slot in equipment_buttons.keys():
		var button: ItemSlotButton = equipment_buttons[slot]
		var item: ItemData = player.equipment.slots[slot]
		var slot_name: String = Equipment.SLOT_NAMES[slot]
		var style: StyleBoxFlat = button.get_theme_stylebox("normal")
		button.tooltip_item = item
		button.tooltip_quantity = 1
		if item == null:
			style.bg_color = Color(0.169, 0.125, 0.220, 0.85)
			button.tooltip_empty_text = "%s (vacío)" % slot_name
			button.tooltip_text = slot_name
			if button.default_icon_path != "":
				button.icon = load(button.default_icon_path)
			button.add_theme_color_override("icon_normal_color", Color(0.55, 0.55, 0.58, 0.35))
		else:
			style.bg_color = item.color
			button.tooltip_text = item.item_name
			var icon_to_use: String = item.icon_path if item.icon_path != "" else button.default_icon_path
			if icon_to_use != "":
				button.icon = load(icon_to_use)
			button.add_theme_color_override("icon_normal_color", Color(1, 1, 1, 1))

	for i in range(Inventory.SIZE):
		var entry = player.inventory.get_at(i)
		var button: ItemSlotButton = backpack_buttons[i]
		if entry == null:
			button.text = ""
			button.tooltip_text = ""
			button.tooltip_item = null
			button.compare_item = null
		else:
			var item: ItemData = entry["item"]
			var quantity: int = entry["quantity"]
			button.tooltip_item = item
			button.tooltip_quantity = quantity
			if item.equip_slot != -1:
				button.compare_item = player.equipment.slots.get(item.equip_slot)
			else:
				button.compare_item = null
			if quantity > 1:
				button.text = "%s x%d" % [item.item_name, quantity]
				button.tooltip_text = "%s x%d" % [item.item_name, quantity]
			else:
				button.text = item.item_name
				button.tooltip_text = item.item_name


func _on_equipment_slot_pressed(slot: int) -> void:
	player.unequip_to_inventory(slot)


func _on_backpack_slot_pressed(index: int) -> void:
	player.equip_from_inventory(index)


func _handle_item_drop(data: Dictionary, target: ItemSlotButton) -> void:
	if target.slot_kind == "backpack":
		if data.get("kind") == "backpack":
			player.move_backpack_item(data["backpack_index"], target.backpack_index)
		elif data.get("kind") == "equip":
			player.unequip_to_index(data["equip_slot"], target.backpack_index)
	elif target.slot_kind == "equip":
		if data.get("kind") == "backpack":
			player.equip_from_inventory_to_slot(data["backpack_index"], target.equip_slot_id)
		elif data.get("kind") == "equip":
			player.swap_equipped(data["equip_slot"], target.equip_slot_id)
	_refresh_inventory_ui()


## Se llama desde WorldDropZone (world_drop_zone.gd) cuando se suelta un
## objeto de la mochila fuera de cualquier ventana: si el stack tiene
## más de 1 unidad se pregunta la cantidad con un popup; si solo hay 1,
## se suelta directamente sin fricción innecesaria.
func _on_backpack_item_dropped_to_world(data: Dictionary, _at_position: Vector2) -> void:
	if data.get("kind") != "backpack":
		return
	var index: int = data.get("backpack_index", -1)
	if index < 0:
		return
	var entry = player.inventory.get_at(index)
	if entry == null:
		return

	var quantity: int = entry["quantity"]
	if quantity <= 1:
		player.drop_item_from_backpack(index, 1)
		_refresh_inventory_ui()
	else:
		_open_drop_quantity_popup(index, quantity)


## Pequeña ventana emergente para elegir cuántas unidades de un stack
## soltar (reutiliza el mismo estilo visual que _make_window/_make_slot_button).
func _open_drop_quantity_popup(index: int, max_quantity: int) -> void:
	if drop_quantity_popup != null and is_instance_valid(drop_quantity_popup):
		drop_quantity_popup.queue_free()
		drop_quantity_popup = null

	var entry = player.inventory.get_at(index)
	if entry == null:
		return
	var item: ItemData = entry["item"]

	var popup := PopupPanel.new()
	var popup_style := StyleBoxFlat.new()
	popup_style.bg_color = Color(0.11, 0.09, 0.14, 0.98)
	popup_style.border_color = Color(0.039, 0.031, 0.063)
	popup_style.set_border_width_all(3)
	popup_style.set_content_margin_all(14)
	popup.add_theme_stylebox_override("panel", popup_style)
	_get_windows_layer().add_child(popup)
	drop_quantity_popup = popup

	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 8)
	popup.add_child(box)

	var title := Label.new()
	title.text = "Soltar %s" % item.item_name
	title.add_theme_color_override("font_color", Color(0.88, 0.85, 0.90))
	title.add_theme_font_size_override("font_size", 15)
	box.add_child(title)

	var spin := SpinBox.new()
	spin.min_value = 1
	spin.max_value = max_quantity
	spin.value = max_quantity
	spin.custom_minimum_size = Vector2(160, 0)
	box.add_child(spin)

	var buttons := HBoxContainer.new()
	buttons.add_theme_constant_override("separation", 8)
	box.add_child(buttons)

	var confirm_button := _make_slot_button("Soltar")
	confirm_button.pressed.connect(func() -> void:
		player.drop_item_from_backpack(index, int(spin.value))
		_refresh_inventory_ui()
		popup.hide()
		popup.queue_free()
	)
	buttons.add_child(confirm_button)

	var cancel_button := _make_slot_button("Cancelar")
	cancel_button.pressed.connect(func() -> void:
		popup.hide()
		popup.queue_free()
	)
	buttons.add_child(cancel_button)

	popup.popup_centered(Vector2(220, 130))


func _on_ability_cooldown_changed(ability_name: String, time_left: float, max_time: float) -> void:
	var label: Label = null
	if ability_name == "power_strike":
		label = power_cd_label
	elif ability_name == "dodge":
		label = dodge_cd_label

	if label != null:
		label.text = "%.1f" % time_left if time_left > 0.0 else ""

	if ability_cooldown_labels.has(ability_name):
		var window_label: Label = ability_cooldown_labels[ability_name]
		window_label.text = "Cooldown: %.1fs" % time_left if time_left > 0.0 else "Lista"


func _build_character_ui() -> void:
	if ui_canvas == null:
		return

	var win := _make_window("Mi personaje", Vector2(20.0, 100.0))
	character_panel = win["panel"]
	var box: VBoxContainer = win["box"]

	var attr_title := Label.new()
	attr_title.text = "Atributos"
	attr_title.add_theme_color_override("font_color", Color(0.478, 0.125, 0.188))
	attr_title.add_theme_font_size_override("font_size", 16)
	box.add_child(attr_title)

	var attr_keys := [
		["estabilidad", "Estabilidad"], ["agilidad", "Agilidad"],
		["destreza", "Destreza"], ["punteria", "Puntería"],
		["fuerza", "Fuerza"], ["voluntad", "Voluntad"],
		["canalizacion", "Canalización"], ["conexion_elemental", "Conexión Elemental"],
	]
	for pair in attr_keys:
		var row := HBoxContainer.new()
		box.add_child(row)
		var name_label := Label.new()
		name_label.text = pair[1]
		name_label.custom_minimum_size = Vector2(150, 0)
		name_label.add_theme_color_override("font_color", Color(0.88, 0.85, 0.90))
		row.add_child(name_label)
		var value_label := Label.new()
		value_label.add_theme_color_override("font_color", Color(0.88, 0.85, 0.90))
		row.add_child(value_label)
		character_value_labels[pair[0]] = value_label

	var res_title := Label.new()
	res_title.text = "Recursos y derivados"
	res_title.add_theme_color_override("font_color", Color(0.478, 0.125, 0.188))
	res_title.add_theme_font_size_override("font_size", 16)
	box.add_child(res_title)

	var derived_keys := [
		["max_health", "Vida máxima"], ["max_stamina", "Aguante máximo"],
		["max_mana", "Maná máximo"], ["move_speed", "Velocidad"],
		["melee_damage_multiplier", "Mult. daño cuerpo a cuerpo"],
	]
	for pair in derived_keys:
		var row := HBoxContainer.new()
		box.add_child(row)
		var name_label := Label.new()
		name_label.text = pair[1]
		name_label.custom_minimum_size = Vector2(180, 0)
		name_label.add_theme_color_override("font_color", Color(0.88, 0.85, 0.90))
		row.add_child(name_label)
		var value_label := Label.new()
		value_label.add_theme_color_override("font_color", Color(0.88, 0.85, 0.90))
		row.add_child(value_label)
		character_value_labels[pair[0]] = value_label

	_refresh_character_ui()


func _refresh_character_ui() -> void:
	if character_value_labels.is_empty():
		return

	var eff: StatBlock = player.effective_stats
	if eff == null:
		return

	character_value_labels["estabilidad"].text = "%.1f" % eff.estabilidad
	character_value_labels["agilidad"].text = "%.1f" % eff.agilidad
	character_value_labels["destreza"].text = "%.1f" % eff.destreza
	character_value_labels["punteria"].text = "%.1f" % eff.punteria
	character_value_labels["fuerza"].text = "%.1f" % eff.fuerza
	character_value_labels["voluntad"].text = "%.1f" % eff.voluntad
	character_value_labels["canalizacion"].text = "%.1f" % eff.canalizacion
	character_value_labels["conexion_elemental"].text = "%.1f" % eff.conexion_elemental

	character_value_labels["max_health"].text = "%.0f" % player.max_health
	character_value_labels["max_stamina"].text = "%.0f" % player.max_stamina
	character_value_labels["max_mana"].text = "%.0f" % player.max_mana
	character_value_labels["move_speed"].text = "%.0f" % player.move_speed
	character_value_labels["melee_damage_multiplier"].text = "x%.2f" % player.melee_damage_multiplier


func _build_abilities_ui() -> void:
	if ui_canvas == null:
		return

	var win := _make_window("Mis habilidades", Vector2(20.0, 420.0))
	abilities_panel = win["panel"]
	var box: VBoxContainer = win["box"]
	box.custom_minimum_size = Vector2(260, 0)

	var abilities := [
		["Ataque básico", "Clic izq. / 1", "Golpea de frente, sin necesitar objetivo.", ""],
		["Golpe de Poder", "2", "Golpe fuerte contra el objetivo bloqueado (Tab).", "power_strike"],
		["Esquivar", "Espacio", "Dash corto con invulnerabilidad breve. Cuesta Aguante.", "dodge"],
	]

	for ability in abilities:
		var card := VBoxContainer.new()
		card.add_theme_constant_override("separation", 2)
		box.add_child(card)

		var header := HBoxContainer.new()
		card.add_child(header)

		var name_label := Label.new()
		name_label.text = "%s  (%s)" % [ability[0], ability[1]]
		name_label.add_theme_color_override("font_color", Color(0.88, 0.85, 0.90))
		header.add_child(name_label)

		var desc_label := Label.new()
		desc_label.text = ability[2]
		desc_label.add_theme_color_override("font_color", Color(0.6, 0.58, 0.62))
		desc_label.add_theme_font_size_override("font_size", 12)
		desc_label.autowrap_mode = TextServer.AUTOWRAP_WORD
		desc_label.custom_minimum_size = Vector2(240, 0)
		card.add_child(desc_label)

		if ability[3] != "":
			var cd_label := Label.new()
			cd_label.text = "Lista"
			cd_label.add_theme_color_override("font_color", Color(0.478, 0.125, 0.188))
			cd_label.add_theme_font_size_override("font_size", 12)
			card.add_child(cd_label)
			ability_cooldown_labels[ability[3]] = cd_label

		var sep := HSeparator.new()
		card.add_child(sep)


func _build_crafting_ui() -> void:
	if ui_canvas == null:
		return

	var win := _make_window("Crafteo", Vector2(20.0, 100.0))
	crafting_panel = win["panel"]
	var box: VBoxContainer = win["box"]
	box.custom_minimum_size = Vector2(280, 0)

	var hint := Label.new()
	hint.text = "Recetas disponibles en esta estación:"
	hint.add_theme_font_size_override("font_size", 12)
	hint.add_theme_color_override("font_color", Color(0.6, 0.58, 0.62))
	box.add_child(hint)

	crafting_list_box = VBoxContainer.new()
	crafting_list_box.add_theme_constant_override("separation", 10)
	box.add_child(crafting_list_box)


func _refresh_crafting_ui() -> void:
	for child in crafting_list_box.get_children():
		child.queue_free()

	for recipe in player.known_recipes:
		if not recipe.unlocked:
			continue  # Las bloqueadas solo se consultan en el Recetario (R)
		crafting_list_box.add_child(_make_recipe_row(recipe, true))


func _build_recipes_ui() -> void:
	if ui_canvas == null:
		return

	var win := _make_window("Recetario", Vector2(420.0, 100.0))
	recipes_panel = win["panel"]
	var box: VBoxContainer = win["box"]
	box.custom_minimum_size = Vector2(280, 0)

	var hint := Label.new()
	hint.text = "Todas las recetas conocidas (desbloqueadas y bloqueadas):"
	hint.add_theme_font_size_override("font_size", 12)
	hint.add_theme_color_override("font_color", Color(0.6, 0.58, 0.62))
	hint.autowrap_mode = TextServer.AUTOWRAP_WORD
	hint.custom_minimum_size = Vector2(260, 0)
	box.add_child(hint)

	recipes_list_box = VBoxContainer.new()
	recipes_list_box.add_theme_constant_override("separation", 10)
	box.add_child(recipes_list_box)


func _refresh_recipes_ui() -> void:
	for child in recipes_list_box.get_children():
		child.queue_free()

	for recipe in player.known_recipes:
		recipes_list_box.add_child(_make_recipe_row(recipe, false))


## Construye la fila de una receta. Si "craftable_mode" es true incluye
## un botón "Craftear" (ventana de la estación); si es false, es de solo
## lectura y en su lugar muestra la etiqueta Desbloqueada/Bloqueada
## (ventana del Recetario).
func _make_recipe_row(recipe: Recipe, craftable_mode: bool) -> Control:
	var card := VBoxContainer.new()
	card.add_theme_constant_override("separation", 3)

	var header := HBoxContainer.new()
	header.add_theme_constant_override("separation", 8)
	card.add_child(header)

	var name_label := Label.new()
	name_label.text = recipe.recipe_name
	name_label.add_theme_color_override("font_color", Color(0.88, 0.85, 0.90))
	name_label.add_theme_font_size_override("font_size", 14)
	name_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	header.add_child(name_label)

	if not craftable_mode:
		var status_label := Label.new()
		status_label.add_theme_font_size_override("font_size", 12)
		if recipe.unlocked:
			status_label.text = "Desbloqueada"
			status_label.add_theme_color_override("font_color", Color(0.45, 0.80, 0.50))
		else:
			status_label.text = "Bloqueada"
			status_label.add_theme_color_override("font_color", Color(0.65, 0.62, 0.66))
		header.add_child(status_label)

	if recipe.description != "":
		var desc_label := Label.new()
		desc_label.text = recipe.description
		desc_label.add_theme_color_override("font_color", Color(0.6, 0.58, 0.62))
		desc_label.add_theme_font_size_override("font_size", 11)
		desc_label.autowrap_mode = TextServer.AUTOWRAP_WORD
		desc_label.custom_minimum_size = Vector2(250, 0)
		card.add_child(desc_label)

	for item_id in recipe.materials.keys():
		var needed: int = recipe.materials[item_id]
		var have: int = player.count_item(item_id)
		var mat_item: ItemData = ItemCatalog.get_item(item_id)

		var mat_label := Label.new()
		mat_label.text = "%s: %d / %d" % [mat_item.item_name, have, needed]
		mat_label.add_theme_font_size_override("font_size", 12)
		if have >= needed:
			mat_label.add_theme_color_override("font_color", Color(0.45, 0.80, 0.50))
		else:
			mat_label.add_theme_color_override("font_color", Color(0.90, 0.30, 0.30))
		card.add_child(mat_label)

	var result_item: ItemData = ItemCatalog.get_item(recipe.result_id)
	var result_label := Label.new()
	result_label.text = "Produce: %s x%d" % [result_item.item_name, recipe.result_quantity]
	result_label.add_theme_font_size_override("font_size", 12)
	result_label.add_theme_color_override("font_color", Color(0.6, 0.58, 0.62))
	card.add_child(result_label)

	if craftable_mode:
		var craft_button := _make_slot_button("Craftear")
		craft_button.disabled = not player.can_craft(recipe)
		craft_button.pressed.connect(_on_craft_pressed.bind(recipe))
		card.add_child(craft_button)

	card.add_child(HSeparator.new())
	return card


func _on_craft_pressed(recipe: Recipe) -> void:
	if player.craft(recipe):
		_refresh_crafting_ui()


## --- Ventana de Misiones (Q): activas con objetivos/progreso y completadas ---

func _build_quests_ui() -> void:
	if ui_canvas == null:
		return

	var win := _make_window("Misiones", Vector2(420.0, 420.0))
	quests_panel = win["panel"]
	var box: VBoxContainer = win["box"]
	box.custom_minimum_size = Vector2(300, 0)

	var active_title := Label.new()
	active_title.text = "Misiones activas"
	active_title.add_theme_color_override("font_color", Color(0.478, 0.125, 0.188))
	active_title.add_theme_font_size_override("font_size", 16)
	box.add_child(active_title)

	quests_active_box = VBoxContainer.new()
	quests_active_box.add_theme_constant_override("separation", 10)
	box.add_child(quests_active_box)

	box.add_child(HSeparator.new())

	var completed_title := Label.new()
	completed_title.text = "Misiones completadas"
	completed_title.add_theme_color_override("font_color", Color(0.478, 0.125, 0.188))
	completed_title.add_theme_font_size_override("font_size", 16)
	box.add_child(completed_title)

	quests_completed_box = VBoxContainer.new()
	quests_completed_box.add_theme_constant_override("separation", 6)
	box.add_child(quests_completed_box)

	_refresh_quests_ui()


func _refresh_quests_ui() -> void:
	if quests_active_box == null or quests_completed_box == null:
		return

	for child in quests_active_box.get_children():
		child.queue_free()
	for child in quests_completed_box.get_children():
		child.queue_free()

	if player.active_quests.is_empty():
		var none_active := Label.new()
		none_active.text = "(sin misiones activas)"
		none_active.add_theme_font_size_override("font_size", 12)
		none_active.add_theme_color_override("font_color", Color(0.6, 0.58, 0.62))
		quests_active_box.add_child(none_active)
	else:
		for quest in player.active_quests:
			quests_active_box.add_child(_make_quest_row(quest))

	if player.completed_quests.is_empty():
		var none_completed := Label.new()
		none_completed.text = "(ninguna todavía)"
		none_completed.add_theme_font_size_override("font_size", 12)
		none_completed.add_theme_color_override("font_color", Color(0.6, 0.58, 0.62))
		quests_completed_box.add_child(none_completed)
	else:
		for quest in player.completed_quests:
			quests_completed_box.add_child(_make_completed_quest_row(quest))


## Fila de una misión activa: nombre, descripción, objetivos con su
## progreso ("X / Y", en verde si está completo) y botón para reclamar
## la recompensa en cuanto todos los objetivos están cumplidos.
func _make_quest_row(quest: Quest) -> Control:
	var card := VBoxContainer.new()
	card.add_theme_constant_override("separation", 3)

	var name_label := Label.new()
	name_label.text = quest.quest_name
	name_label.add_theme_color_override("font_color", Color(0.88, 0.85, 0.90))
	name_label.add_theme_font_size_override("font_size", 14)
	card.add_child(name_label)

	if quest.description != "":
		var desc_label := Label.new()
		desc_label.text = quest.description
		desc_label.add_theme_color_override("font_color", Color(0.6, 0.58, 0.62))
		desc_label.add_theme_font_size_override("font_size", 11)
		desc_label.autowrap_mode = TextServer.AUTOWRAP_WORD
		desc_label.custom_minimum_size = Vector2(270, 0)
		card.add_child(desc_label)

	for objective in quest.objectives:
		_sync_objective_progress(objective)
		var obj_label := Label.new()
		obj_label.text = "%s: %d / %d" % [objective.description, objective.current_amount, objective.required_amount]
		obj_label.add_theme_font_size_override("font_size", 12)
		if objective.is_complete():
			obj_label.add_theme_color_override("font_color", Color(0.45, 0.80, 0.50))
		else:
			obj_label.add_theme_color_override("font_color", Color(0.90, 0.30, 0.30))
		card.add_child(obj_label)

	var reward_parts: Array = []
	if quest.reward_gold > 0:
		reward_parts.append("%d de oro" % quest.reward_gold)
	if quest.reward_item_id != "":
		var reward_item: ItemData = ItemCatalog.get_item(quest.reward_item_id)
		reward_parts.append("%s x%d" % [reward_item.item_name, quest.reward_item_quantity])

	var reward_label := Label.new()
	reward_label.text = "Recompensa: " + (", ".join(reward_parts) if not reward_parts.is_empty() else "ninguna")
	reward_label.add_theme_font_size_override("font_size", 11)
	reward_label.add_theme_color_override("font_color", Color(0.6, 0.58, 0.62))
	card.add_child(reward_label)

	if quest.is_complete():
		var claim_button := _make_slot_button("Reclamar recompensa")
		claim_button.pressed.connect(_on_claim_quest_pressed.bind(quest))
		card.add_child(claim_button)

	card.add_child(HSeparator.new())
	return card


func _make_completed_quest_row(quest: Quest) -> Control:
	var row := VBoxContainer.new()
	row.add_theme_constant_override("separation", 3)

	var name_label := Label.new()
	name_label.text = "%s (completada)" % quest.quest_name
	name_label.add_theme_color_override("font_color", Color(0.45, 0.80, 0.50))
	name_label.add_theme_font_size_override("font_size", 13)
	row.add_child(name_label)

	row.add_child(HSeparator.new())
	return row


## Los objetivos de tipo COLLECT_ITEM se recalculan en vivo a partir del
## inventario actual (igual que _make_recipe_row hace con
## player.count_item para comparar materiales). Los de tipo
## KILL_ENEMIES no se tocan aquí: su contador solo lo incrementa
## Player.register_enemy_kill().
func _sync_objective_progress(objective: QuestObjective) -> void:
	if objective.kind == QuestObjective.Kind.COLLECT_ITEM and objective.target_id != "":
		objective.current_amount = min(objective.required_amount, player.count_item(objective.target_id))


func _on_claim_quest_pressed(quest: Quest) -> void:
	if player.claim_quest_reward(quest):
		_refresh_quests_ui()
		_refresh_inventory_ui()


## --- Ventana de Árbol de Habilidades (T) ---
##
## BASE de partida: una pestaña por rama (SkillNode.branch), y dentro
## de cada pestaña los nodos se dibujan de ABAJO hacia ARRIBA (el nivel
## 0 de grid_position.y queda pegado al fondo del área, y sube según
## crece grid_position.y). Con 2 columnas por nivel y cada nodo
## exigiendo el de la columna OPUESTA del nivel de abajo (ver
## skill_tree_database.gd), las líneas de conexión se cruzan formando
## una X entre cada dos niveles. El contenido real (ramas, nombres,
## columnas, niveles, bonus, costes) se ajusta por completo en
## scripts/skill_tree_database.gd sin tocar nada de esta ventana.

func _build_skill_tree_ui() -> void:
	if ui_canvas == null:
		return

	var win := _make_window("Árbol de Habilidades", Vector2(420.0, 420.0))
	skill_tree_panel = win["panel"]
	var box: VBoxContainer = win["box"]

	skill_points_label = Label.new()
	skill_points_label.text = "Puntos disponibles: 0"
	skill_points_label.add_theme_color_override("font_color", Color(0.85, 0.65, 0.15))
	skill_points_label.add_theme_font_size_override("font_size", 15)
	box.add_child(skill_points_label)

	var hint := Label.new()
	hint.text = "Pasa el ratón sobre un nodo para ver su descripción. Clic para desbloquear."
	hint.add_theme_font_size_override("font_size", 11)
	hint.add_theme_color_override("font_color", Color(0.6, 0.58, 0.62))
	hint.autowrap_mode = TextServer.AUTOWRAP_WORD
	hint.custom_minimum_size = Vector2(280, 0)
	box.add_child(hint)

	# --- Agrupar los nodos por rama, conservando el orden en que
	# aparecen en SkillTreeDatabase (así las pestañas salen en ese
	# mismo orden: Combate, Resistencia, Agilidad...). ---
	var branch_order: Array = []
	var branch_nodes: Dictionary = {}
	for node in player.skill_tree_nodes:
		if not branch_nodes.has(node.branch):
			branch_nodes[node.branch] = []
			branch_order.append(node.branch)
		branch_nodes[node.branch].append(node)

	var tabs := TabContainer.new()
	# Con 5 columnas por rama el contenido de cada pestaña ya no cabe en
	# los 320x320 de antes (2 columnas); esto es solo un mínimo de
	# partida, el tab_area real de cada rama (más abajo) crece según
	# max_col/max_row y el TabContainer se ajusta a su hijo más grande.
	tabs.custom_minimum_size = Vector2(540, 340)
	var tabs_panel_style := StyleBoxFlat.new()
	tabs_panel_style.bg_color = Color(0.11, 0.09, 0.14, 0.98)
	tabs_panel_style.border_color = Color(0.039, 0.031, 0.063)
	tabs_panel_style.set_border_width_all(2)
	tabs.add_theme_stylebox_override("panel", tabs_panel_style)
	var tab_selected_style := StyleBoxFlat.new()
	tab_selected_style.bg_color = Color(0.169, 0.125, 0.220)
	tab_selected_style.set_content_margin_all(8)
	tabs.add_theme_stylebox_override("tab_selected", tab_selected_style)
	var tab_unselected_style := StyleBoxFlat.new()
	tab_unselected_style.bg_color = Color(0.11, 0.09, 0.14)
	tab_unselected_style.set_content_margin_all(8)
	tabs.add_theme_stylebox_override("tab_unselected", tab_unselected_style)
	tabs.add_theme_color_override("font_selected_color", Color(0.95, 0.65, 0.15))
	tabs.add_theme_color_override("font_unselected_color", Color(0.6, 0.58, 0.62))
	box.add_child(tabs)

	# Líneas primero (por rama), luego los nodos encima, igual que antes.
	skill_tree_lines.clear()
	skill_node_buttons.clear()
	var by_id: Dictionary = {}
	for node in player.skill_tree_nodes:
		by_id[node.skill_id] = node

	for branch in branch_order:
		var nodes_in_branch: Array = branch_nodes[branch]

		var max_col := 0
		var max_row := 0
		for node in nodes_in_branch:
			max_col = max(max_col, node.grid_position.x)
			max_row = max(max_row, node.grid_position.y)

		var tab_area := Control.new()
		tab_area.name = branch if branch != "" else "Habilidades"
		tab_area.custom_minimum_size = SKILL_TREE_ORIGIN * 2.0 + Vector2(max_col + 1, max_row + 1) * SKILL_CELL_SIZE
		tabs.add_child(tab_area)

		for node in nodes_in_branch:
			for required_id in node.requires:
				var parent_node: SkillNode = by_id.get(required_id)
				if parent_node == null:
					continue
				var line := Line2D.new()
				line.width = 3.0
				line.default_color = Color(0.35, 0.3, 0.4)
				line.points = PackedVector2Array([
					_skill_node_center(parent_node, max_row),
					_skill_node_center(node, max_row),
				])
				tab_area.add_child(line)
				skill_tree_lines.append({"line": line, "from": parent_node, "to": node})

		for node in nodes_in_branch:
			var button := _make_skill_node_button(node)
			button.position = _skill_node_top_left(node, max_row)
			button.custom_minimum_size = SKILL_NODE_SIZE
			button.size = SKILL_NODE_SIZE
			button.pressed.connect(_on_skill_node_pressed.bind(node))
			tab_area.add_child(button)
			skill_node_buttons[node.skill_id] = button

	_refresh_skill_tree_ui()


## "max_row" es el nivel más alto de ESA rama: al nivel 0 (grid_position.y
## = 0) le corresponde la fila de abajo del todo, y niveles mayores van
## subiendo -> el árbol crece de abajo hacia arriba.
func _skill_node_top_left(node: SkillNode, max_row: int) -> Vector2:
	var row_from_bottom := max_row - node.grid_position.y
	return SKILL_TREE_ORIGIN + Vector2(node.grid_position.x, row_from_bottom) * SKILL_CELL_SIZE


func _skill_node_center(node: SkillNode, max_row: int) -> Vector2:
	return _skill_node_top_left(node, max_row) + SKILL_NODE_SIZE / 2.0


func _make_skill_node_button(node: SkillNode) -> Button:
	var button := Button.new()
	# Inicial del nombre como "icono" provisional, en la línea del resto
	# del arte gray-box del prototipo (sin sprites propios todavía).
	button.text = node.skill_name.substr(0, 1)
	button.add_theme_font_size_override("font_size", 18)
	button.add_theme_color_override("font_color", Color(0.95, 0.93, 0.96))
	button.clip_text = true
	button.focus_mode = Control.FOCUS_NONE

	var style := StyleBoxFlat.new()
	style.border_color = Color(0.039, 0.031, 0.063)
	style.set_border_width_all(3)
	style.set_corner_radius_all(28)
	button.add_theme_stylebox_override("normal", style)
	button.add_theme_stylebox_override("hover", style.duplicate())
	button.add_theme_stylebox_override("pressed", style.duplicate())
	button.add_theme_stylebox_override("disabled", style.duplicate())

	return button


func _refresh_skill_tree_ui() -> void:
	if skill_points_label == null:
		return
	skill_points_label.text = "Puntos disponibles: %d" % player.skill_points

	for node in player.skill_tree_nodes:
		var button: Button = skill_node_buttons.get(node.skill_id)
		if button == null:
			continue

		var unlocked: bool = player.is_skill_unlocked(node)
		var can_unlock: bool = player.can_unlock_skill(node)

		var bg_color: Color
		if unlocked:
			bg_color = node.color
			button.disabled = true
			button.modulate = Color(1, 1, 1, 1)
		elif can_unlock:
			bg_color = node.color.darkened(0.35)
			button.disabled = false
			button.modulate = Color(1, 1, 1, 1)
		else:
			bg_color = Color(0.169, 0.125, 0.220, 0.85)
			button.disabled = true
			button.modulate = Color(1, 1, 1, 0.55)

		# El botón se pinta con la stylebox de "normal" o de "disabled"
		# según button.disabled, así que hay que mantener ambas iguales
		# para que el color se vea siempre, esté clicable o no.
		for state in ["normal", "hover", "pressed", "disabled"]:
			var state_style: StyleBoxFlat = button.get_theme_stylebox(state)
			state_style.bg_color = bg_color

		var status_text: String
		if unlocked:
			status_text = "Desbloqueada"
		elif can_unlock:
			status_text = "Disponible"
		else:
			status_text = "Bloqueada"
		button.tooltip_text = "%s (%s)\nCoste: %d punto(s)\n%s\n%s" % [
			node.skill_name, node.branch, node.cost, node.description, status_text
		]

	for entry in skill_tree_lines:
		var from_node: SkillNode = entry["from"]
		var to_node: SkillNode = entry["to"]
		var line: Line2D = entry["line"]
		if player.is_skill_unlocked(from_node) and player.is_skill_unlocked(to_node):
			line.default_color = Color(0.45, 0.80, 0.50)
		elif player.is_skill_unlocked(from_node):
			line.default_color = Color(0.75, 0.65, 0.35)
		else:
			line.default_color = Color(0.35, 0.3, 0.4)


func _on_skill_node_pressed(node: SkillNode) -> void:
	if player.unlock_skill(node):
		_refresh_skill_tree_ui()
		_refresh_character_ui()


## --- Ventana pequeña de "Controles" (N) ---
##
## Antes era un Label siempre visible arriba a la derecha con todos los
## atajos; ahora es una ventana más (mismo patrón _make_window que el
## resto) que se abre y cierra con una tecla, y se reconstruye cada vez
## que se abre para reflejar las teclas actuales (por si se han
## reasignado desde Ajustes > Controles).

func _build_controls_ui() -> void:
	if ui_canvas == null:
		return

	var win := _make_window("Controles", Vector2(500.0, 20.0))
	controls_panel = win["panel"]
	var box: VBoxContainer = win["box"]

	controls_text_label = Label.new()
	controls_text_label.add_theme_color_override("font_color", Color(0.88, 0.85, 0.90))
	controls_text_label.add_theme_font_size_override("font_size", 13)
	box.add_child(controls_text_label)

	_refresh_controls_ui()


func _refresh_controls_ui() -> void:
	if controls_text_label == null:
		return
	var lines := [
		"WASD: Moverse",
		"Tab: Seleccionar objetivo",
		"Clic izq / 1: Ataque básico",
		"2: Golpe de poder",
		"Espacio: Esquivar",
		"%s: Recoger objeto" % OS.get_keycode_string(GameSave.get_keybind("pickup")),
		"%s: Inventario" % OS.get_keycode_string(GameSave.get_keybind("inventory")),
		"%s: Personaje" % OS.get_keycode_string(GameSave.get_keybind("character")),
		"%s: Habilidades" % OS.get_keycode_string(GameSave.get_keybind("abilities")),
		"%s: Misiones" % OS.get_keycode_string(GameSave.get_keybind("quests")),
		"%s: Árbol de habilidades" % OS.get_keycode_string(GameSave.get_keybind("skills")),
		"%s: Recetario" % OS.get_keycode_string(GameSave.get_keybind("recipes")),
		"%s: Craftear (junto a la estación)" % OS.get_keycode_string(GameSave.get_keybind("craft")),
		"ESC: Menú de pausa",
	]
	controls_text_label.text = "\n".join(lines)
	_refresh_controls_hint()


func _refresh_controls_hint() -> void:
	if controls_hint_label == null:
		return
	controls_hint_label.text = "%s: Controles" % OS.get_keycode_string(GameSave.get_keybind("controls"))


## --- Menú de pausa (ESC) y Ajustes ---
##
## Distinto de las ventanas de _make_window: va en su propia CanvasLayer
## (por encima de todo lo demás, incluida cualquier ventana flotante
## abierta) y se centra en pantalla en vez de anclarse a una esquina.
## No entra en "floating_windows": su apertura/cierre lo gestiona
## _input() de forma explícita (ver el bloque de KEY_ESCAPE).

func _build_pause_menu_ui() -> void:
	var canvas := CanvasLayer.new()
	canvas.layer = 5
	add_child(canvas)

	var root := Control.new()
	root.set_anchors_preset(Control.PRESET_FULL_RECT)
	root.mouse_filter = Control.MOUSE_FILTER_IGNORE
	canvas.add_child(root)

	pause_dim = ColorRect.new()
	pause_dim.color = Color(0, 0, 0, 0.55)
	pause_dim.set_anchors_preset(Control.PRESET_FULL_RECT)
	pause_dim.mouse_filter = Control.MOUSE_FILTER_STOP
	pause_dim.visible = false
	root.add_child(pause_dim)

	var menu := _make_centered_panel(root, "Pausa")
	pause_menu_panel = menu["panel"]
	var menu_box: VBoxContainer = menu["box"]
	menu_box.custom_minimum_size = Vector2(240, 0)

	var resume_button := _make_slot_button("Reanudar")
	resume_button.custom_minimum_size = Vector2(220, 40)
	resume_button.pressed.connect(_close_pause_menu)
	menu_box.add_child(resume_button)

	var settings_button := _make_slot_button("Ajustes")
	settings_button.custom_minimum_size = Vector2(220, 40)
	settings_button.pressed.connect(_open_settings_from_pause)
	menu_box.add_child(settings_button)

	var exit_menu_button := _make_slot_button("Salir al Menú")
	exit_menu_button.custom_minimum_size = Vector2(220, 40)
	exit_menu_button.pressed.connect(_on_exit_to_menu_pressed)
	menu_box.add_child(exit_menu_button)

	var quit_button := _make_slot_button("Salir del Juego")
	quit_button.custom_minimum_size = Vector2(220, 40)
	quit_button.pressed.connect(_on_quit_game_pressed)
	menu_box.add_child(quit_button)

	_build_settings_ui(root)

	get_viewport().size_changed.connect(_center_pause_ui)
	call_deferred("_center_pause_ui")


## Crea un panel centrado (sin barra de arrastre ni X, a diferencia de
## _make_window): quien lo abra/cierre lo hace desde su propio botón
## ("Reanudar", "Volver"...) o desde ESC en _input().
func _make_centered_panel(parent: Control, title_text: String) -> Dictionary:
	var panel := PanelContainer.new()
	panel.visible = false

	var style := StyleBoxFlat.new()
	style.bg_color = Color(0.11, 0.09, 0.14, 0.98)
	style.border_color = Color(0.039, 0.031, 0.063)
	style.set_border_width_all(3)
	style.set_content_margin_all(18)
	panel.add_theme_stylebox_override("panel", style)
	parent.add_child(panel)

	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 14)
	panel.add_child(box)

	if title_text != "":
		var title := Label.new()
		title.text = title_text
		title.add_theme_color_override("font_color", Color(0.478, 0.125, 0.188))
		title.add_theme_font_size_override("font_size", 22)
		title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		box.add_child(title)

	return {"panel": panel, "box": box}


func _center_pause_ui() -> void:
	var vp_size := get_viewport().get_visible_rect().size
	if pause_menu_panel != null and pause_menu_panel.visible:
		pause_menu_panel.position = ((vp_size - pause_menu_panel.size) / 2.0).round()
	if settings_panel != null and settings_panel.visible:
		settings_panel.position = ((vp_size - settings_panel.size) / 2.0).round()


func _open_pause_menu() -> void:
	pause_dim.visible = true
	pause_menu_panel.visible = true
	settings_panel.visible = false
	player.input_locked = true
	call_deferred("_center_pause_ui")


func _close_pause_menu() -> void:
	pause_dim.visible = false
	pause_menu_panel.visible = false
	settings_panel.visible = false
	rebinding_action = ""
	player.input_locked = false


func _open_settings_from_pause() -> void:
	pause_menu_panel.visible = false
	settings_panel.visible = true
	_refresh_settings_ui()
	call_deferred("_center_pause_ui")


func _close_settings() -> void:
	settings_panel.visible = false
	pause_menu_panel.visible = true
	rebinding_action = ""
	call_deferred("_center_pause_ui")


func _on_exit_to_menu_pressed() -> void:
	player.input_locked = false
	get_tree().change_scene_to_file("res://scenes/MainMenu.tscn")


func _on_quit_game_pressed() -> void:
	get_tree().quit()


## --- Ajustes: pestaña "General" (pantalla completa, volumen, silencio) ---
##
## Misma lógica que ya usaba scripts/main_menu.gd (AudioServer para el
## volumen del bus "Master", DisplayServer para pantalla completa), para
## no duplicarla con otro enfoque: solo se añade el silencio (que el
## menú principal no tenía) y todo queda persistido en GameSave.

func _build_settings_ui(root: Control) -> void:
	var win := _make_centered_panel(root, "Ajustes")
	settings_panel = win["panel"]
	var box: VBoxContainer = win["box"]
	box.custom_minimum_size = Vector2(340, 0)

	settings_tabs = TabContainer.new()
	settings_tabs.custom_minimum_size = Vector2(340, 260)

	var tabs_panel_style := StyleBoxFlat.new()
	tabs_panel_style.bg_color = Color(0.11, 0.09, 0.14, 0.98)
	tabs_panel_style.border_color = Color(0.039, 0.031, 0.063)
	tabs_panel_style.set_border_width_all(2)
	settings_tabs.add_theme_stylebox_override("panel", tabs_panel_style)
	var tab_selected_style := StyleBoxFlat.new()
	tab_selected_style.bg_color = Color(0.169, 0.125, 0.220)
	tab_selected_style.set_content_margin_all(8)
	settings_tabs.add_theme_stylebox_override("tab_selected", tab_selected_style)
	var tab_unselected_style := StyleBoxFlat.new()
	tab_unselected_style.bg_color = Color(0.11, 0.09, 0.14)
	tab_unselected_style.set_content_margin_all(8)
	settings_tabs.add_theme_stylebox_override("tab_unselected", tab_unselected_style)
	settings_tabs.add_theme_color_override("font_selected_color", Color(0.95, 0.65, 0.15))
	settings_tabs.add_theme_color_override("font_unselected_color", Color(0.6, 0.58, 0.62))
	box.add_child(settings_tabs)

	_build_settings_general_tab(settings_tabs)
	_build_settings_controls_tab(settings_tabs)

	var back_button := _make_slot_button("Volver")
	back_button.custom_minimum_size = Vector2(220, 40)
	back_button.pressed.connect(_close_settings)
	box.add_child(back_button)


func _build_settings_general_tab(tabs: TabContainer) -> void:
	var tab := VBoxContainer.new()
	tab.name = "General"
	tab.add_theme_constant_override("separation", 14)
	tabs.add_child(tab)

	fullscreen_check = CheckButton.new()
	fullscreen_check.text = "Pantalla completa"
	fullscreen_check.add_theme_color_override("font_color", Color(0.88, 0.85, 0.90))
	fullscreen_check.toggled.connect(_on_fullscreen_toggled)
	tab.add_child(fullscreen_check)

	var volume_label := Label.new()
	volume_label.text = "Volumen general"
	volume_label.add_theme_color_override("font_color", Color(0.88, 0.85, 0.90))
	tab.add_child(volume_label)

	var volume_row := HBoxContainer.new()
	volume_row.add_theme_constant_override("separation", 10)
	tab.add_child(volume_row)

	volume_slider = HSlider.new()
	volume_slider.min_value = 0.0
	volume_slider.max_value = 1.0
	volume_slider.step = 0.01
	volume_slider.custom_minimum_size = Vector2(190, 0)
	volume_slider.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	volume_slider.value_changed.connect(_on_volume_changed)
	volume_row.add_child(volume_slider)

	# Casilla al lado del control de volumen para silenciar/activar sin
	# perder el valor del slider (independiente de él, como se pidió).
	mute_check = CheckButton.new()
	mute_check.text = "Silenciar"
	mute_check.add_theme_color_override("font_color", Color(0.88, 0.85, 0.90))
	mute_check.toggled.connect(_on_mute_toggled)
	volume_row.add_child(mute_check)


func _on_fullscreen_toggled(pressed: bool) -> void:
	if pressed:
		DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_FULLSCREEN)
	else:
		DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_WINDOWED)
	GameSave.set_fullscreen(pressed)


func _on_volume_changed(value: float) -> void:
	AudioServer.set_bus_volume_db(master_bus_index, linear_to_db(value))
	GameSave.set_master_volume(value)


func _on_mute_toggled(pressed: bool) -> void:
	AudioServer.set_bus_mute(master_bus_index, pressed)
	GameSave.set_master_muted(pressed)


func _apply_saved_display_and_audio_settings() -> void:
	master_bus_index = AudioServer.get_bus_index("Master")
	AudioServer.set_bus_volume_db(master_bus_index, linear_to_db(GameSave.get_master_volume()))
	AudioServer.set_bus_mute(master_bus_index, GameSave.get_master_muted())
	if GameSave.get_fullscreen():
		DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_FULLSCREEN)


func _refresh_settings_ui() -> void:
	if fullscreen_check != null:
		fullscreen_check.button_pressed = DisplayServer.window_get_mode() == DisplayServer.WINDOW_MODE_FULLSCREEN
	if volume_slider != null:
		volume_slider.value = GameSave.get_master_volume()
	if mute_check != null:
		mute_check.button_pressed = GameSave.get_master_muted()
	for action in rebind_buttons.keys():
		var button: Button = rebind_buttons[action]
		button.text = OS.get_keycode_string(GameSave.get_keybind(action))


## --- Ajustes: pestaña "Controles" (reasignar teclas) ---
##
## Por ahora solo las teclas que abren ventanas (ver GameSave.
## DEFAULT_KEYBINDS): clic en la tecla actual, se pone en modo "esperando
## tecla" (rebinding_action) y la siguiente tecla que se pulse en
## _input() la reemplaza.

func _build_settings_controls_tab(tabs: TabContainer) -> void:
	var tab := VBoxContainer.new()
	tab.name = "Controles"
	tab.add_theme_constant_override("separation", 8)
	tabs.add_child(tab)

	var hint := Label.new()
	hint.text = "Clic en una tecla y pulsa la nueva para cambiarla. ESC cancela."
	hint.add_theme_font_size_override("font_size", 11)
	hint.add_theme_color_override("font_color", Color(0.6, 0.58, 0.62))
	hint.autowrap_mode = TextServer.AUTOWRAP_WORD
	hint.custom_minimum_size = Vector2(300, 0)
	tab.add_child(hint)

	rebind_buttons.clear()
	for action in KEYBIND_ORDER:
		var row := HBoxContainer.new()
		row.add_theme_constant_override("separation", 10)
		tab.add_child(row)

		var label := Label.new()
		label.text = KEYBIND_LABELS.get(action, action)
		label.custom_minimum_size = Vector2(190, 0)
		label.add_theme_color_override("font_color", Color(0.88, 0.85, 0.90))
		row.add_child(label)

		var key_button := _make_slot_button(OS.get_keycode_string(GameSave.get_keybind(action)))
		key_button.custom_minimum_size = Vector2(110, 32)
		key_button.pressed.connect(_on_rebind_button_pressed.bind(action))
		row.add_child(key_button)
		rebind_buttons[action] = key_button


func _on_rebind_button_pressed(action: String) -> void:
	rebinding_action = action
	var button: Button = rebind_buttons.get(action)
	if button != null:
		button.text = "Pulsa una tecla..."


func _finish_rebind(keycode: int) -> void:
	var action := rebinding_action
	rebinding_action = ""
	if action == "":
		return
	GameSave.set_keybind(action, keycode)
	var button: Button = rebind_buttons.get(action)
	if button != null:
		button.text = OS.get_keycode_string(keycode)
	_refresh_controls_hint()


func _cancel_rebind() -> void:
	var action := rebinding_action
	rebinding_action = ""
	var button: Button = rebind_buttons.get(action)
	if button != null:
		button.text = OS.get_keycode_string(GameSave.get_keybind(action))
