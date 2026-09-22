extends Button
class_name ItemSlotButton

## =========================================================
## WisaCore - Botón de ranura (mochila o equipo) con tooltip
## enriquecido: nombre, rareza, tipo, bonus de stats y descripción.
##
## Usa el sistema de tooltip nativo de Godot (_make_custom_tooltip),
## que ya reposiciona el tooltip solo para que nunca quede cortado
## por los bordes de la pantalla, aunque el botón esté pegado al
## borde de la ventana de inventario.
## =========================================================

var tooltip_item: ItemData = null
var tooltip_quantity: int = 1
var tooltip_empty_text: String = "Vacío"

## Si se rellena (desde main.gd), el tooltip muestra una comparación
## "objeto nuevo -> objeto equipado" con la diferencia de estadísticas.
var compare_item: ItemData = null

## Icono que se muestra cuando la ranura está vacía, o cuando el objeto
## equipado no tiene su propio icon_path (ranuras de equipo únicamente).
var default_icon_path: String = ""

## =========================================================
## Arrastrar y soltar
## =========================================================

## "backpack" o "equip". Lo asigna main.gd al crear el botón.
var slot_kind: String = "backpack"
var backpack_index: int = -1          # Válido si slot_kind == "backpack"
var equip_slot_id: int = -1           # Válido si slot_kind == "equip" (Equipment.Slot)

## Callable(data: Dictionary, target: ItemSlotButton) asignado por main.gd,
## que decide qué hacer cuando se suelta algo sobre este botón.
var on_drop: Callable

const RARITY_NAMES := {
	ItemData.Rarity.COMUN: "Común",
	ItemData.Rarity.POCO_COMUN: "Poco común",
	ItemData.Rarity.RARO: "Raro",
	ItemData.Rarity.EPICO: "Épico",
	ItemData.Rarity.LEGENDARIO: "Legendario",
}

const RARITY_COLORS := {
	ItemData.Rarity.COMUN: Color(0.75, 0.75, 0.78),
	ItemData.Rarity.POCO_COMUN: Color(0.35, 0.80, 0.40),
	ItemData.Rarity.RARO: Color(0.35, 0.60, 0.95),
	ItemData.Rarity.EPICO: Color(0.68, 0.40, 0.90),
	ItemData.Rarity.LEGENDARIO: Color(0.95, 0.65, 0.15),
}

const STAT_NAMES := {
	"estabilidad": "Estabilidad", "agilidad": "Agilidad",
	"destreza": "Destreza", "punteria": "Puntería",
	"fuerza": "Fuerza", "voluntad": "Voluntad",
	"canalizacion": "Canalización", "conexion_elemental": "Conexión elemental",
	"vida_base": "Vida base", "aguante_base": "Aguante base", "mana_base": "Maná base",
}


func _make_custom_tooltip(for_text: String) -> Object:
	var panel := PanelContainer.new()
	var style := StyleBoxFlat.new()
	style.bg_color = Color(0.11, 0.09, 0.14, 0.98)
	style.border_color = Color(0.039, 0.031, 0.063)
	style.set_border_width_all(2)
	style.set_content_margin_all(10)
	panel.add_theme_stylebox_override("panel", style)
	panel.custom_minimum_size = Vector2(250, 0)

	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 4)
	panel.add_child(box)

	if tooltip_item == null:
		var empty_label := Label.new()
		empty_label.text = tooltip_empty_text
		empty_label.add_theme_color_override("font_color", Color(0.6, 0.58, 0.62))
		box.add_child(empty_label)
		return panel

	var item := tooltip_item

	var name_label := Label.new()
	name_label.text = item.item_name
	name_label.add_theme_font_size_override("font_size", 16)
	name_label.add_theme_color_override("font_color", RARITY_COLORS.get(item.rarity, Color.WHITE))
	box.add_child(name_label)

	var rarity_label := Label.new()
	rarity_label.text = RARITY_NAMES.get(item.rarity, "Común")
	rarity_label.add_theme_font_size_override("font_size", 12)
	rarity_label.add_theme_color_override("font_color", RARITY_COLORS.get(item.rarity, Color.WHITE))
	box.add_child(rarity_label)

	var type_text: String
	if item.equip_slot != -1:
		type_text = Equipment.SLOT_NAMES.get(item.equip_slot, "Equipo")
	elif item.item_type == ItemData.ItemType.CONSUMIBLE:
		type_text = "Consumible"
	else:
		type_text = "Material"
	var type_label := Label.new()
	type_label.text = type_text
	type_label.add_theme_font_size_override("font_size", 12)
	type_label.add_theme_color_override("font_color", Color(0.6, 0.58, 0.62))
	box.add_child(type_label)

	if tooltip_quantity > 1:
		var qty_label := Label.new()
		qty_label.text = "Cantidad: %d" % tooltip_quantity
		qty_label.add_theme_font_size_override("font_size", 12)
		qty_label.add_theme_color_override("font_color", Color(0.6, 0.58, 0.62))
		box.add_child(qty_label)

	if compare_item != null and compare_item != item:
		_add_comparison_section(box, item, compare_item)
	else:
		var has_bonus := false
		for key in item.stat_bonuses.keys():
			var value: float = item.stat_bonuses[key]
			if value == 0.0:
				continue
			if not has_bonus:
				box.add_child(HSeparator.new())
				has_bonus = true
			var bonus_label := Label.new()
			var sign_text := "+" if value > 0 else ""
			bonus_label.text = "%s%s %s" % [sign_text, _format_number(value), STAT_NAMES.get(key, key)]
			bonus_label.add_theme_font_size_override("font_size", 13)
			bonus_label.add_theme_color_override("font_color", Color(0.45, 0.80, 0.50))
			box.add_child(bonus_label)

	if item.description != "":
		box.add_child(HSeparator.new())
		var desc_label := Label.new()
		desc_label.text = item.description
		desc_label.autowrap_mode = TextServer.AUTOWRAP_WORD
		desc_label.custom_minimum_size = Vector2(210, 0)
		desc_label.add_theme_font_size_override("font_size", 12)
		desc_label.add_theme_color_override("font_color", Color(0.82, 0.80, 0.85))
		box.add_child(desc_label)

	return panel


func _add_comparison_section(box: VBoxContainer, new_item: ItemData, equipped_item: ItemData) -> void:
	box.add_child(HSeparator.new())

	var vs_label := Label.new()
	vs_label.text = "Comparado con equipado: %s" % equipped_item.item_name
	vs_label.autowrap_mode = TextServer.AUTOWRAP_WORD
	vs_label.custom_minimum_size = Vector2(210, 0)
	vs_label.add_theme_font_size_override("font_size", 11)
	vs_label.add_theme_color_override("font_color", RARITY_COLORS.get(equipped_item.rarity, Color(0.6, 0.58, 0.62)))
	box.add_child(vs_label)

	var grid := GridContainer.new()
	grid.columns = 3
	grid.add_theme_constant_override("h_separation", 12)
	grid.add_theme_constant_override("v_separation", 2)
	box.add_child(grid)

	var header_new := Label.new()
	header_new.text = "Nuevo"
	header_new.add_theme_font_size_override("font_size", 11)
	header_new.add_theme_color_override("font_color", Color(0.6, 0.58, 0.62))
	grid.add_child(Label.new())
	grid.add_child(header_new)
	var header_diff := Label.new()
	header_diff.text = "Dif."
	header_diff.add_theme_font_size_override("font_size", 11)
	header_diff.add_theme_color_override("font_color", Color(0.6, 0.58, 0.62))
	grid.add_child(header_diff)

	var keys := {}
	for k in new_item.stat_bonuses.keys():
		keys[k] = true
	for k in equipped_item.stat_bonuses.keys():
		keys[k] = true

	var any_row := false
	for key in keys.keys():
		var new_val: float = new_item.stat_bonuses.get(key, 0.0)
		var old_val: float = equipped_item.stat_bonuses.get(key, 0.0)
		if new_val == 0.0 and old_val == 0.0:
			continue
		any_row = true
		var diff := new_val - old_val

		var stat_label := Label.new()
		stat_label.text = STAT_NAMES.get(key, key)
		stat_label.add_theme_font_size_override("font_size", 12)
		stat_label.add_theme_color_override("font_color", Color(0.82, 0.80, 0.85))
		grid.add_child(stat_label)

		var new_label := Label.new()
		new_label.text = _format_number(new_val)
		new_label.add_theme_font_size_override("font_size", 12)
		new_label.add_theme_color_override("font_color", Color(0.82, 0.80, 0.85))
		grid.add_child(new_label)

		var diff_label := Label.new()
		diff_label.add_theme_font_size_override("font_size", 12)
		if diff > 0.0:
			diff_label.text = "+%s" % _format_number(diff)
			diff_label.add_theme_color_override("font_color", Color(0.35, 0.85, 0.40))
		elif diff < 0.0:
			diff_label.text = _format_number(diff)
			diff_label.add_theme_color_override("font_color", Color(0.90, 0.30, 0.30))
		else:
			diff_label.text = "="
			diff_label.add_theme_color_override("font_color", Color(0.6, 0.58, 0.62))
		grid.add_child(diff_label)

	if not any_row:
		var none_label := Label.new()
		none_label.text = "(sin diferencias de estadísticas)"
		none_label.add_theme_font_size_override("font_size", 11)
		none_label.add_theme_color_override("font_color", Color(0.6, 0.58, 0.62))
		box.add_child(none_label)


func _format_number(value: float) -> String:
	if value == int(value):
		return str(int(value))
	return "%.1f" % value


## --- Arrastrar y soltar (API nativa de Godot Control) ---

func _get_drag_data(_at_position: Vector2) -> Variant:
	if tooltip_item == null:
		return null

	var preview: Control
	if icon != null:
		var tex := TextureRect.new()
		tex.texture = icon
		tex.custom_minimum_size = Vector2(40, 40)
		tex.size = Vector2(40, 40)
		tex.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		tex.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		preview = tex
	else:
		var label := Label.new()
		label.text = tooltip_item.item_name
		label.add_theme_color_override("font_color", Color(0.9, 0.88, 0.92))
		preview = label
	preview.modulate = Color(1, 1, 1, 0.85)
	set_drag_preview(preview)

	return {
		"kind": slot_kind,
		"backpack_index": backpack_index,
		"equip_slot": equip_slot_id,
		"item": tooltip_item,
	}


func _can_drop_data(_at_position: Vector2, data: Variant) -> bool:
	if not (data is Dictionary and data.has("kind")):
		return false
	if slot_kind != "equip":
		return true  # La mochila acepta cualquier objeto en cualquier hueco.
	var item: ItemData = data.get("item")
	if item == null:
		return false
	return _is_slot_compatible(item.equip_slot, equip_slot_id)


func _drop_data(_at_position: Vector2, data: Variant) -> void:
	if on_drop.is_valid():
		on_drop.call(data, self)


## Los dos huecos de anillo se consideran intercambiables entre sí.
func _is_slot_compatible(item_slot: int, target_slot: int) -> bool:
	if item_slot == target_slot:
		return true
	var rings := [Equipment.Slot.ACCESORIO_1, Equipment.Slot.ACCESORIO_2]
	return item_slot in rings and target_slot in rings
