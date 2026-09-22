extends Area2D
class_name CraftingStation

## =========================================================
## WisaCore - Estación de crafteo interactuable en el mapa
## Emite señales cuando el jugador entra/sale de su radio; main.gd
## las escucha para mostrar el aviso de "Pulsa E" y permitir abrir
## la ventana de crafteo solo estando cerca.
## =========================================================

signal player_entered_range
signal player_exited_range


func _ready() -> void:
	body_entered.connect(_on_body_entered)
	body_exited.connect(_on_body_exited)


func _on_body_entered(body: Node) -> void:
	if body.is_in_group("player"):
		player_entered_range.emit()


func _on_body_exited(body: Node) -> void:
	if body.is_in_group("player"):
		player_exited_range.emit()
