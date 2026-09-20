extends Resource
class_name StatBlock

## =========================================================
## WisaCore - Bloque de atributos
## Contiene los atributos primarios y las fórmulas derivadas
## que afectan al gameplay. Un mismo StatBlock se puede asignar
## a cualquier clase/subclase futura; solo cambian los valores.
## =========================================================

@export_group("Atributos primarios")
@export var estabilidad: float = 10.0
@export var agilidad: float = 10.0
@export var destreza: float = 10.0
@export var punteria: float = 10.0
@export var fuerza: float = 10.0
@export var voluntad: float = 10.0
@export var canalizacion: float = 10.0
@export var conexion_elemental: float = 10.0

@export_group("Recursos base (antes de bonos de atributo)")
@export var vida_base: float = 100.0
@export var aguante_base: float = 100.0
@export var mana_base: float = 50.0


## --- Fórmulas derivadas ---
## Estas son un punto de partida razonable; se pueden re-balancear
## sin tocar ningún otro sistema, porque todo pasa por aquí.

func get_max_health() -> float:
	return vida_base + (fuerza * 2.0) + (estabilidad * 1.5)


func get_max_stamina() -> float:
	return aguante_base + (agilidad * 2.0)


func get_max_mana() -> float:
	return mana_base + (voluntad * 1.5) + (canalizacion * 1.5)


func get_move_speed_bonus() -> float:
	# Cada punto de Agilidad por encima de 10 añade velocidad de movimiento.
	return max(0.0, agilidad - 10.0) * 2.0


func get_sprint_stamina_cost_per_second() -> float:
	# Más Agilidad = esprintar cuesta menos Aguante por segundo (mínimo 4).
	return max(4.0, 12.0 - (agilidad * 0.05))


func get_melee_damage_multiplier() -> float:
	return 1.0 + (fuerza * 0.02)


func get_heavy_armor_mobility_penalty_reduction() -> float:
	# Placeholder hasta el sistema de equipamiento (paso 2 del roadmap):
	# cada punto de Estabilidad reducirá la penalización de movilidad
	# del equipo pesado, hasta un tope del 80%.
	return min(0.8, estabilidad * 0.01)
