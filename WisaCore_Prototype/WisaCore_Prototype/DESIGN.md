# WisaCore — Documento de Diseño

> Documento vivo. Se actualiza a medida que avanzamos en el roadmap.
> Estado actual del prototipo: Guerrero jugable, combate híbrido
> tiempo real / tab-target, cámara isométrica, sprint conectado a
> Aguante (Paso 1 del roadmap ya implementado).

## Roadmap de desarrollo

1. **Sistema de atributos y stats** ✅ *(implementado)*
2. Sistema de equipamiento (ranuras + inventario + modificadores)
3. Armas modulares y crafteo (piezas ensamblables)
4. Framework de clases y subclases (data-driven, validado con 2-3 primero)
5. Habilidades de combate por rol (DPS / Tanque / Healer / Support)
6. Competencias (Artesanía, Ingeniería, Percepción, Liderazgo, etc.)
7. Progresión: niveles + árbol de talentos + crafteo
8. Contenido de mundo (mazmorras, jefes, PvP) y evaluación de multijugador

---

## Estructura de clases

| Clase | Subclase | Rol | Identidad |
|---|---|---|---|
| ⚔️ Guerrero | Paladín | DPS | Combate ofensivo, armadura pesada y daño |
| ⚔️ Guerrero | Centinela | Tanque | Escudo, defensa, protección y control |
| 🗡️ Pícaro | Arquero | DPS | Daño físico a distancia, movilidad y precisión |
| 🗡️ Pícaro | Asesino | Burst melee | Sigilo, críticos y daño explosivo |
| ✨ Clérigo | Sanador | Healer | Curación y mantenimiento del grupo |
| ✨ Clérigo | Invocador | Support | Invocaciones, protección, buffs y utilidad |
| 🔮 Mago | Arcano | Burst | Magia ofensiva y grandes hechizos |
| 🔮 Mago | Alquimista | DPS/Utility | Piedras arcanas, efectos, debuffs y daño progresivo |
| ⚙️ Ingeniero | Mecánico | Melee MOD | Maquinaria, exoesqueletos y armas mecánicas |
| ⚙️ Ingeniero | Tirador | Ranged DPS | Armas de fuego, torretas y maquinaria a distancia |

## Atributos

| Atributo | Función |
|---|---|
| Estabilidad | Aumenta la Tenacidad cada X puntos y reduce la penalización de movilidad del equipo pesado |
| Agilidad | Aumenta la velocidad de movimiento y afecta al consumo de Aguante al esprintar |
| Destreza | Principalmente para Pícaro y Arquero |
| Puntería | Principalmente para Arquero y Artillero |
| Fuerza | Aumenta el daño de ataques cuerpo a cuerpo, excepto máquinas |
| Voluntad | Potencia hechizos y efectos relacionados con la magia divina |
| Canalización | Potencia los hechizos de los Magos |
| Conexión Elemental | Aumenta la resistencia a elementos y potencia habilidades/equipo/armas de naturaleza elemental |
| Vida | HP máximo |
| Aguante | STA máxima |
| Maná | MAN máximo |

**Implementado en `scripts/stat_block.gd`** (Resource `StatBlock`) con las
siguientes fórmulas iniciales (ajustables sin tocar el resto del código):

- `max_health = vida_base + (fuerza * 2) + (estabilidad * 1.5)`
- `max_stamina = aguante_base + (agilidad * 2)`
- `max_mana = mana_base + (voluntad * 1.5) + (canalizacion * 1.5)`
- `move_speed_bonus = max(0, agilidad - 10) * 2`
- `sprint_stamina_cost_per_second = max(4, 12 - agilidad * 0.05)`
- `melee_damage_multiplier = 1 + (fuerza * 0.02)`
- `heavy_armor_mobility_penalty_reduction = min(0.8, estabilidad * 0.01)` *(placeholder hasta el paso 2)*

## Competencias

| Competencia | Función |
|---|---|
| Artesanía | Desbloquea recetas de fabricación general |
| Ingeniería | Permite crear y desbloquear mejores módulos y componentes |
| Artesanía Arcana | Fabricación de objetos mágicos |
| Abrir Cerraduras | Permite abrir cerraduras según su dificultad |
| Percepción | Permite descubrir cosas, secretos y obtener pistas según el nivel |
| Liderazgo | Desbloquea habilidades de líder que afectan al grupo |

## Ranuras de equipamiento

Cabeza · Pecho · Manos · Piernas · Pies · Accesorio 1 · Accesorio 2 · Arma · Arma secundaria

### Tipos de equipamiento por clase

| Clase | Tipos de equipamiento |
|---|---|
| Guerrero | Ligera / Media / Pesada |
| Pícaro | Movilidad / Cazador / Duelista |
| Clérigo | Sanador / Sagrada / Guardián |
| Mago | Arcana / Combate / Ritual |
| Ingeniero | Exotraje / Reforzada / Ligera |

### Escudos

Pavés · Escudo pequeño · Escudo mediano — tratado como equipamiento
secundario, no como familia de armas de clase.

## Armas

### Armas por clase

| Clase | Armas |
|---|---|
| Guerrero | Espada · Hacha · Lanza · Maza |
| Mago | Bastón · Orbe · Cetro |
| Clérigo | Bastón · Talismán · Grimorio |
| Pícaro | Dagas · Arco corto · Arco largo · Garras |
| Ingeniero | Revólver · Rifle · Cuchillas mecánicas · Guanteletes mecánicos · Martillo mecánico |

### Armas modulares (3 piezas ensamblables)

| Arma | Pieza 1 | Pieza 2 | Pieza 3 |
|---|---|---|---|
| 🔫 Revólver | Cañón | Mecanismo | Empuñadura |
| 🔫 Rifle | Cañón | Mecanismo | Culata |
| 🗡️ Cuchillas mecánicas | Hoja | Mecanismo | Empuñadura |
| 🥊 Guanteletes mecánicos | Placa | Mecanismo | Empuñadura |
| 🔨 Martillo mecánico | Placa | Mecanismo | Mango |

---

## Notas de implementación (prototipo actual)

- El Guerrero usa un `StatBlock` con valores base (Fuerza 14, Estabilidad
  12, Agilidad 10). Si no se asigna ningún `StatBlock` en el Inspector,
  `player.gd` crea uno con esos valores por defecto.
- El **sprint** (Shift) consume Aguante en tiempo real según
  `get_sprint_stamina_cost_per_second()`, y el **esquivar** (Espacio)
  cuesta una cantidad fija de Aguante (20 por defecto). Si no hay
  Aguante suficiente, ninguna de las dos acciones funciona.
- El **daño cuerpo a cuerpo** (ataque básico y Golpe de Poder) ahora se
  multiplica por `get_melee_damage_multiplier()`, ligado a Fuerza.
- Los enemigos todavía no usan `StatBlock` — eso llegará junto con el
  sistema de equipamiento/itemización (pasos 2-3), cuando tenga sentido
  variar sus stats por tipo/dificultad.
