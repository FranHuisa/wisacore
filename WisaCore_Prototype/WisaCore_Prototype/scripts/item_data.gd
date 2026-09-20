extends Resource
class_name ItemData

## =========================================================
## WisaCore - Definición de un objeto
## Sirve tanto para equipamiento como para materiales/consumibles.
## Los bonus de atributo son genéricos (Dictionary) para no tener
## que tocar este script cada vez que se añade un tipo de bonus.
## =========================================================

enum ItemType { EQUIPO, MATERIAL, CONSUMIBLE }

@export var item_name: String = "Objeto"
@export var item_type: ItemType = ItemType.MATERIAL

## Si es equipable, el valor de Equipment.Slot al que pertenece.
## -1 significa que no es equipable (material/consumible).
@export var equip_slot: int = -1

@export var stack_size: int = 1

## Color usado como "icono" provisional en la UI (sin arte todavía).
@export var color: Color = Color(0.4, 0.4, 0.4)

@export var description: String = ""

## Bonus de atributos que aporta al equiparlo. Claves válidas:
## estabilidad, agilidad, destreza, punteria, fuerza, voluntad,
## canalizacion, conexion_elemental, vida_base, aguante_base, mana_base.
@export var stat_bonuses: Dictionary = {}
