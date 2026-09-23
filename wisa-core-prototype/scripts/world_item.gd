extends Node2D
class_name WorldItem

## =========================================================
## WisaCore - Objeto físico tirado en el suelo
##
## Se crea por código (igual que el resto del arte "gray-box" del
## prototipo: Polygon2D + Line2D con el color del objeto) tanto cuando
## el jugador suelta algo de la mochila como cuando un enemigo suelta
## botín al morir. El jugador lo detecta por proximidad (mismo patrón
## de "escanear por distancia" que ya usa Player._cycle_target con los
## enemigos) y lo recoge con la tecla F.
## =========================================================

@export var item_data: ItemData
@export var quantity: int = 1

var _visual: Polygon2D
var _label: Label


func _ready() -> void:
	add_to_group("world_items")
	_build_visual()


func _build_visual() -> void:
	var display_color: Color = item_data.color if item_data != null else Color(0.6, 0.6, 0.6)

	_visual = Polygon2D.new()
	_visual.polygon = PackedVector2Array([Vector2(0, -10), Vector2(10, 0), Vector2(0, 10), Vector2(-10, 0)])
	_visual.color = display_color
	add_child(_visual)

	var outline := Line2D.new()
	outline.points = PackedVector2Array([Vector2(0, -10), Vector2(10, 0), Vector2(0, 10), Vector2(-10, 0), Vector2(0, -10)])
	outline.width = 2.0
	outline.default_color = Color(0.039, 0.031, 0.063, 1)
	add_child(outline)

	_label = Label.new()
	_label.text = ("x%d" % quantity) if quantity > 1 else ""
	_label.offset_left = -30.0
	_label.offset_right = 30.0
	_label.offset_top = -30.0
	_label.offset_bottom = -12.0
	_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_label.add_theme_font_size_override("font_size", 12)
	_label.add_theme_color_override("font_color", Color(0.9, 0.85, 0.6))
	add_child(_label)


## Nombre a mostrar en el aviso de "Pulsa F para recoger: ...".
func get_display_name() -> String:
	if item_data == null:
		return "Objeto"
	if quantity > 1:
		return "%s x%d" % [item_data.item_name, quantity]
	return item_data.item_name
