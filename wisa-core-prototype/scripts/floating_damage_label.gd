extends Label
class_name FloatingDamageLabel

## =========================================================
## WisaCore - Número de daño flotante
##
## Se instancia por código y se añade como hijo directo de quien
## recibe el golpe (mismo patrón que "NameLabel" en Player.tscn /
## Enemy.tscn: un Label hijo de un CharacterBody2D, posicionado con un
## offset local; al ser CanvasItem, hereda la transformada de su padre
## igual que cualquier Node2D). Sube y se desvanece con un Tween y se
## destruye sola al terminar: no hace falta que quien la crea gestione
## su ciclo de vida.
##
## Puramente visual: no participa en absoluto en el cálculo de daño,
## que sigue intacto en player.gd/enemy.gd. Solo se le pasa el número
## ya calculado para mostrarlo.
## =========================================================

@export var rise_distance: float = 42.0
@export var duration: float = 0.8


func setup(amount: float) -> void:
	text = str(int(round(amount)))
	add_theme_font_size_override("font_size", 18)
	add_theme_color_override("font_color", Color(0.95, 0.25, 0.25))
	add_theme_color_override("font_outline_color", Color(0.039, 0.031, 0.063))
	add_theme_constant_override("outline_size", 3)
	horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	z_index = 50


func _ready() -> void:
	var start_position := position
	var end_position := start_position + Vector2(randf_range(-10.0, 10.0), -rise_distance)

	var tween := create_tween()
	tween.tween_property(self, "position", end_position, duration).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	tween.parallel().tween_property(self, "modulate:a", 0.0, duration * 0.6).set_delay(duration * 0.4)
	tween.tween_callback(queue_free)
