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


func _ready() -> void:
	_build_ui()
	player.health_changed.connect(_on_player_health_changed)
	player.stamina_changed.connect(_on_player_stamina_changed)
	player.target_changed.connect(_on_target_changed)
	player.ability_cooldown_changed.connect(_on_ability_cooldown_changed)
	player.inventory_changed.connect(_refresh_inventory_ui)
	_on_player_health_changed(player.current_health, player.max_health)
	_on_player_stamina_changed(player.current_stamina, player.max_stamina)
	_build_inventory_ui()


func _input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and not event.echo:
		if event.physical_keycode == KEY_ESCAPE:
			if inventory_panel != null and inventory_panel.visible:
				inventory_panel.visible = false
			else:
				get_tree().change_scene_to_file("res://scenes/MainMenu.tscn")
		elif event.physical_keycode == KEY_I:
			if inventory_panel == null:
				return
			inventory_panel.visible = not inventory_panel.visible
			if inventory_panel.visible:
				_refresh_inventory_ui()


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

	# --- Instrucciones, ancladas arriba a la derecha ---
	var instructions := Label.new()
	instructions.position = Vector2(vp_size.x - 320.0, 20)
	instructions.text = "WASD: Moverse\nTab: Seleccionar objetivo\nClic izq / 1: Ataque básico\n2: Golpe de poder\nEspacio: Esquivar\nI: Inventario"
	ui.add_child(instructions)


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


func _build_inventory_ui() -> void:
	if ui_canvas == null:
		push_warning("No se pudo construir el inventario: falta el CanvasLayer.")
		return
	var canvas := ui_canvas

	inventory_panel = Control.new()
	inventory_panel.set_anchors_preset(Control.PRESET_FULL_RECT)
	inventory_panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	inventory_panel.visible = false
	canvas.add_child(inventory_panel)

	# --- Franja lateral derecha: aquí vive la ventana, centrada solo
	# verticalmente dentro de la franja (su tamaño depende del contenido). ---
	var side_strip := Control.new()
	side_strip.anchor_left = 1.0
	side_strip.anchor_right = 1.0
	side_strip.anchor_top = 0.0
	side_strip.anchor_bottom = 1.0
	side_strip.offset_left = -340.0
	side_strip.offset_right = -20.0
	side_strip.offset_top = 0.0
	side_strip.offset_bottom = 0.0
	side_strip.mouse_filter = Control.MOUSE_FILTER_IGNORE
	inventory_panel.add_child(side_strip)

	var vcenter := CenterContainer.new()
	vcenter.set_anchors_preset(Control.PRESET_FULL_RECT)
	vcenter.mouse_filter = Control.MOUSE_FILTER_IGNORE
	side_strip.add_child(vcenter)

	# --- "Ventana" del inventario: tamaño según su contenido ---
	var window_panel := PanelContainer.new()
	var window_style := StyleBoxFlat.new()
	window_style.bg_color = Color(0.11, 0.09, 0.14, 0.98)
	window_style.border_color = Color(0.039, 0.031, 0.063)
	window_style.set_border_width_all(3)
	window_style.set_content_margin_all(14)
	window_panel.add_theme_stylebox_override("panel", window_style)
	vcenter.add_child(window_panel)

	var window_box := VBoxContainer.new()
	window_box.add_theme_constant_override("separation", 10)
	window_panel.add_child(window_box)

	# --- Barra de título con botón de cerrar (X) ---
	var title_bar := HBoxContainer.new()
	window_box.add_child(title_bar)

	var window_title := Label.new()
	window_title.text = "Inventario"
	window_title.add_theme_color_override("font_color", Color(0.478, 0.125, 0.188))
	window_title.add_theme_font_size_override("font_size", 20)
	window_title.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	title_bar.add_child(window_title)

	var close_button := _make_slot_button("X")
	close_button.custom_minimum_size = Vector2(26, 26)
	close_button.pressed.connect(_on_inventory_close_pressed)
	title_bar.add_child(close_button)

	# --- Equipamiento como un "muñeco": cada ranura donde iría en el cuerpo ---
	var equip_title := Label.new()
	equip_title.text = "Equipo"
	equip_title.add_theme_color_override("font_color", Color(0.478, 0.125, 0.188))
	equip_title.add_theme_font_size_override("font_size", 16)
	window_box.add_child(equip_title)

	var equip_grid := GridContainer.new()
	equip_grid.columns = 3
	equip_grid.add_theme_constant_override("h_separation", 4)
	equip_grid.add_theme_constant_override("v_separation", 4)
	window_box.add_child(equip_grid)

	const EMPTY := -1
	var paperdoll_layout: Array = [
		[EMPTY, Equipment.Slot.CABEZA, EMPTY],
		[Equipment.Slot.ACCESORIO_1, Equipment.Slot.PECHO, Equipment.Slot.ACCESORIO_2],
		[Equipment.Slot.ARMA_SECUNDARIA, Equipment.Slot.MANOS, Equipment.Slot.ARMA],
		[EMPTY, Equipment.Slot.PIERNAS, EMPTY],
		[EMPTY, Equipment.Slot.PIES, EMPTY],
	]

	for row in paperdoll_layout:
		for slot in row:
			if slot == EMPTY:
				var spacer := Control.new()
				spacer.custom_minimum_size = Vector2(86, 34)
				equip_grid.add_child(spacer)
			else:
				var button := _make_slot_button(Equipment.SLOT_NAMES[slot])
				button.custom_minimum_size = Vector2(86, 34)
				button.pressed.connect(_on_equipment_slot_pressed.bind(slot))
				equip_grid.add_child(button)
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
		grid.add_child(button)
		backpack_buttons.append(button)


func _on_inventory_close_pressed() -> void:
	inventory_panel.visible = false


func _make_slot_button(text: String) -> Button:
	var button := Button.new()
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
	for slot in equipment_buttons.keys():
		var button: Button = equipment_buttons[slot]
		var item: ItemData = player.equipment.slots[slot]
		var slot_name: String = Equipment.SLOT_NAMES[slot]
		if item == null:
			button.text = slot_name
			button.tooltip_text = "%s (vacío)" % slot_name
		else:
			button.text = item.item_name
			button.tooltip_text = "%s: %s" % [slot_name, item.item_name]

	for i in range(Inventory.SIZE):
		var entry = player.inventory.get_at(i)
		var button: Button = backpack_buttons[i]
		if entry == null:
			button.text = ""
			button.tooltip_text = ""
		else:
			var item: ItemData = entry["item"]
			var quantity: int = entry["quantity"]
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


func _on_ability_cooldown_changed(ability_name: String, time_left: float, max_time: float) -> void:
	var label: Label = null
	if ability_name == "power_strike":
		label = power_cd_label
	elif ability_name == "dodge":
		label = dodge_cd_label

	if label == null:
		return

	label.text = "%.1f" % time_left if time_left > 0.0 else ""
