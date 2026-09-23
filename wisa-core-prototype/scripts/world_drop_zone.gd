extends Control
class_name WorldDropZone

## =========================================================
## WisaCore - Zona de "soltar en el mundo"
##
## Cubre toda la pantalla y vive DEBAJO de las ventanas flotantes (se
## añade antes que "windows_layer" en main.gd, así que las ventanas y
## sus botones siempre tienen prioridad para recibir el drag&drop). Si
## el jugador arrastra un objeto de la mochila (drag&drop nativo de
## ItemSlotButton, ver item_slot_button.gd) y lo suelta en cualquier
## punto que no sea una ranura o una ventana, esta zona lo recibe y
## avisa a main.gd para soltarlo en el suelo del mundo de juego.
##
## mouse_filter = PASS: participa en el drag&drop, pero no bloquea el
## resto de eventos de ratón normales (Node._input() de player.gd, que
## gestiona el clic izquierdo de ataque, siempre recibe el evento antes
## que el sistema de GUI, así que esto no interfiere con el combate).
## =========================================================

var on_item_dropped: Callable


func _can_drop_data(_at_position: Vector2, data: Variant) -> bool:
	return data is Dictionary and data.get("kind") == "backpack"


func _drop_data(at_position: Vector2, data: Variant) -> void:
	if on_item_dropped.is_valid():
		on_item_dropped.call(data, at_position)
