extends HBoxContainer

## =========================================================
## WisaCore - Barra de título arrastrable
## Se asigna como script a un HBoxContainer que actúe de barra
## de título; asigna "target" (el panel de la ventana) y listo.
## =========================================================

var target: Control
var dragging: bool = false
var drag_offset: Vector2 = Vector2.ZERO


func _gui_input(event: InputEvent) -> void:
	if target == null:
		return

	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT:
		if event.pressed:
			dragging = true
			drag_offset = get_global_mouse_position() - target.global_position
			var parent := target.get_parent()
			if parent != null:
				parent.move_child(target, parent.get_child_count() - 1)
		else:
			dragging = false
	elif event is InputEventMouseMotion and dragging:
		target.global_position = get_global_mouse_position() - drag_offset
