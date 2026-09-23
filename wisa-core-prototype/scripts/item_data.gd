extends Resource
class_name ItemData

## =========================================================
## WisaCore - Definición de un objeto
## Sirve tanto para equipamiento como para materiales/consumibles.
## Los bonus de atributo son genéricos (Dictionary) para no tener
## que tocar este script cada vez que se añade un tipo de bonus.
## =========================================================

enum ItemType { EQUIPO, MATERIAL, CONSUMIBLE }
enum Rarity { COMUN, POCO_COMUN, RARO, EPICO, LEGENDARIO }

@export var item_name: String = "Objeto"
@export var item_type: ItemType = ItemType.MATERIAL
@export var rarity: Rarity = Rarity.COMUN

## Identificador estable (ej. "iron_ore") usado por el sistema de
## crafteo para saber qué material es, sin depender de comparar
## instancias de Resource. Vacío si el objeto no lo necesita
## (piezas de equipo únicas creadas a mano, por ejemplo).
@export var item_id: String = ""

## Ruta a un icono PNG propio de este objeto (ej. "res://assets/ui/icons/weapon_sword.png").
## Si está vacío, la ranura de equipo usa el icono genérico de su tipo de ranura.
@export var icon_path: String = ""

## Si es equipable, el valor de Equipment.Slot al que pertenece.
## -1 significa que no es equipable (material/consumible).
@export var equip_slot: int = -1

@export var stack_size: int = 1

## Si es true, este objeto es moneda (oro): al recogerlo del suelo no
## ocupa una ranura de la mochila, se suma directamente a Player.gold.
@export var is_currency: bool = false

## Color usado como "icono" provisional en la UI (sin arte todavía).
@export var color: Color = Color(0.4, 0.4, 0.4)

@export var description: String = ""

## Bonus de atributos que aporta al equiparlo. Claves válidas:
## estabilidad, agilidad, destreza, punteria, fuerza, voluntad,
## canalizacion, conexion_elemental, vida_base, aguante_base, mana_base.
@export var stat_bonuses: Dictionary = {}
