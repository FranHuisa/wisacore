# WisaCore — Guía de dimensiones para el tileset

## Primero, lo importante: cómo funciona "lo isométrico" ahora mismo

El prototipo **no usa arte pre-dibujado en perspectiva isométrica**. Usa
un truco de cámara: `Camera2D.zoom = Vector2(1.7, 1.25)` (un zoom distinto
en X que en Y) que comprime visualmente el eje vertical en pantalla. Todo
lo demás — suelo, jugador, enemigo, obstáculos — está dibujado en un
espacio 2D **completamente plano/top-down** (nada de mallas o sprites
inclinados).

Esto te da **dos caminos** para el tileset. Tienes que elegir uno; si
mezclas los dos, la perspectiva se distorsiona (se "aplasta" dos veces).

### Camino A — Tiles normales (top-down), la cámara sigue haciendo el truco ✅ Recomendado por ahora
Dibujas los tiles como si fuera un juego top-down normal (cuadrados,
vistos desde arriba, SIN perspectiva dibujada a mano). La cámara ya se
encarga de dar la sensación isométrica. Es mucho más simple de dibujar
y no requiere rehacer nada de lo que ya construimos.

### Camino B — Tiles isométricos "de verdad" (dibujados en diamante)
Dibujas cada tile ya en perspectiva isométrica (forma de rombo/diamante
2:1). Se ve más "isométrico clásico" (como juegos tipo Diablo/Fallout
clásico), pero para que funcione bien **hay que quitar el truco de la
cámara** (volver a un zoom uniforme) y pasar el suelo a un `TileMap` de
Godot en modo "Isometric". Es más trabajo de re-estructuración.

**Mi recomendación**: sigue con el Camino A por ahora (tiles top-down
normales) mientras terminamos "lo básico". Si más adelante el estilo
Camino B te convence más al verlo, lo cambiamos — pero es una decisión
de una sola vez, mejor no ir a medias.

---

## Medidas — Camino A (recomendado)

| Elemento | Medida | Notas |
|---|---|---|
| **Tamaño de tile (suelo)** | **64 × 64 px** | Cuadrado normal, visto desde arriba. Nada de diamante dibujado a mano. |
| **Grid de nivel de referencia** | ~16 × 11 tiles | El área de juego actual mide 1000×700 unidades de mundo (1 unidad ≈ 1 px), así que a 64px/tile cubre aprox. ese tamaño. |
| **Personaje (Guerrero/Aberración)** | **64 px de ancho × 96–128 px de alto** por frame | Más alto que ancho porque un personaje de pie ocupa más de un tile en altura. El "punto de apoyo" (los pies) debe estar en la parte inferior-centro del lienzo, para que al colocarlo parezca que pisa el tile. |
| **Objetos/obstáculos pequeños** (rocas, pilares) | 64×64 a 64×96 px | Igual que el personaje: ancla en la base. |
| **Objetos grandes** (paredes, estructuras) | Múltiplos de 64 px | Para que encajen limpio en el grid. |
| **Iconos de inventario** | 32×32 px | Para cuando reemplacemos los botones de color plano por iconos reales. |

### Notas técnicas para cuando lo importes a Godot
- Si el estilo final es pixel art de baja resolución, activa **Nearest**
  (no Linear) como filtro de textura en el import, para que no se vea
  borroso.
- Usa un `TileSet` normal (no "Isometric") con `TileMap` en modo
  cuadrado de 64×64 — mismo grid que cualquier juego top-down.
- Cuando tengamos el tileset, sustituimos el `Floor` (el `Polygon2D`
  gigante de `Main.tscn`) por un `TileMap` de verdad — ese es un cambio
  aislado, no afecta a jugador/enemigo/combate.

## Medidas — Camino B (si en algún momento cambiamos a esto)

| Elemento | Medida |
|---|---|
| Tile de suelo (diamante 2:1) | 128×64 px |
| Personaje | 128 px ancho × 192–256 px alto, ancla en la base del diamante |
| Cámara | Zoom uniforme (sin el truco 1.7/1.25) |

## Paleta (Estilo A — Gótico oscuro)

Para que el tileset combine con lo que ya está en el juego:

| Uso | Color | Hex |
|---|---|---|
| Fondo / vacío | `Color(0.082, 0.067, 0.102)` | `#15111A` |
| Suelo / superficies | `Color(0.169, 0.125, 0.220)` | `#2B2038` |
| Estructuras / rocas | `Color(0.227, 0.169, 0.290)` | `#3A2B4A` |
| Contornos / sombras duras | `Color(0.039, 0.031, 0.063)` | `#0A0810` |
| Acento (peligro/sangre) | `Color(0.478, 0.125, 0.188)` | `#7A2030` |
