# WisaCore (Prototipo) — Guerrero vs. Aberración

Prototipo inicial hecho en **Godot 4.x** (GDScript). Es la base de la mecánica
de combate híbrido (tiempo real + tab-target) que luego se expandirá a más
clases, mazmorras, PvP y, eventualmente, a un MMO real.

## Cómo abrirlo

1. Abre Godot 4 (recomendado 4.3 o superior; si tienes una versión distinta,
   Godot te pedirá "convertir" el proyecto — acepta, no perderás nada).
2. En el gestor de proyectos, pulsa **Importar** y selecciona la carpeta
   `WisaCore_Prototype` (el archivo `project.godot`).
3. Pulsa **Reproducir** (F5). La escena principal (`Main.tscn`) ya está
   configurada como escena de inicio.

## Controles

| Tecla          | Acción                                                    |
|----------------|------------------------------------------------------------|
| WASD / Flechas | Moverse (tiempo real)                                       |
| Tab            | Seleccionar / rotar objetivo cercano (estilo tab-target)     |
| Clic izq. / 1  | Ataque básico (golpea a quien esté delante, sin necesitar objetivo) |
| 2              | Golpe de Poder (requiere objetivo bloqueado + rango, con cooldown) |
| Espacio        | Esquivar (dash corto con cooldown)                          |

## Estilo visual: "Gótico oscuro" (Estilo A)

Se aplicó la paleta y el lenguaje visual del Estilo A que elegiste:
negros casi puros, morados oscuros y un acento rojo sangre, con contornos
oscuros marcados (`Line2D`) alrededor de cada forma.

- El **suelo** ahora es un diamante isométrico (`Polygon2D`), no un
  rectángulo.
- El **jugador** y el **enemigo** son diamantes (fichas isométricas)
  en vez de cuadrados: morado oscuro para el jugador, rojo sangre para
  el enemigo — mismos colores que viste en la maqueta.
- El **movimiento (WASD)** es en cruz: cada tecla sola mueve arriba,
  abajo, izquierda o derecha en pantalla. Al combinar dos teclas
  adyacentes (W+D, S+D, A+W, A+S) se obtiene la diagonal de forma
  natural, como en la mayoría de juegos de acción — no hace falta
  nada especial en el código para eso, es simplemente sumar los
  vectores de cada tecla.
- El color de fondo del motor (clear color) se ajustó a un negro-violeta
  oscuro para que combine con la paleta en vez del azul grisáceo por
  defecto de Godot.

Sigue siendo arte "gray-box" (formas planas, sin sprites reales) — el
objetivo de este paso era validar que el *gameplay* se siente bien en
una proyección isométrica antes de invertir en arte final. El resto de
la arena (paredes) sigue siendo rectangular por ahora; se puede refinar
más adelante para que las paredes también sigan los bordes del diamante.

## Sensación isométrica de cámara y Sprint (esta versión)

- **Y-Sort**: activado en la escena `Main`, así el jugador y el enemigo se
  dibujan en el orden correcto según su posición vertical (quien está "más
  abajo" en pantalla se dibuja delante). El suelo y las paredes están
  fijados detrás con `z_index` negativo para que nunca tapen a los personajes.
- **Cámara con zoom no uniforme**: el `Camera2D` del jugador usa
  `zoom = Vector2(1.7, 1.25)` en vez de un zoom parejo. Esto comprime
  visualmente el eje vertical en pantalla, dando sensación de mirar el
  mundo en ángulo (como una cámara isométrica) sin tocar para nada el
  movimiento ni las colisiones — es puramente un truco de cámara/render.
  Las etiquetas de nombre (`NameLabel`) tienen un `scale.y` que compensa
  ese estiramiento para que el texto no se vea aplastado.
- **Sprint (Shift)**: mantener Shift multiplica la velocidad de movimiento
  por `sprint_multiplier` (1.6x por defecto, ajustable en el Inspector).
  No se combina con el esquivar (el dash tiene prioridad mientras dura).
  De momento no consume ningún recurso (estamina); si más adelante quieres
  que gaste algo, es un buen candidato para cuando definamos el sistema
  de recursos por clase.

## Controles (actualizado)

| Tecla          | Acción                                                    |
|----------------|------------------------------------------------------------|
| WASD / Flechas | Moverse en cruz (diagonal al combinar dos teclas)            |
| Shift (mantener)| Sprint                                                      |
| Tab            | Seleccionar / rotar objetivo cercano (estilo tab-target)     |
| Clic izq. / 1  | Ataque básico                                                |
| 2              | Golpe de Poder (requiere objetivo bloqueado + rango)          |
| Espacio        | Esquivar (dash corto con cooldown)                            |


- El **ataque básico** es 100% posicional/tiempo real: no importa si tienes
  objetivo o no, golpea todo lo que esté en el área frontal del personaje.
  Esto le da peso al movimiento y al posicionamiento, como pediste para que
  el PvP se sienta interesante.
- El **Golpe de Poder** usa el objetivo bloqueado (Tab), como en Dreadmyst/WoW:
  no necesitas apuntar con precisión, pero sí estar en rango y tener el
  objetivo seleccionado. Esto da la sensación "tab-target" en las habilidades
  fuertes/de recurso, mientras el movimiento y el golpe básico se sienten
  a la Dreamcore/acción.
- El enemigo (Aberración) tiene una máquina de estados simple: Deambular →
  Perseguir → Atacar → Morir, para que sea un buen "dummy" de pruebas de daño
  y de la IA que luego se puede complicar (patrones de ataque, resistencias,
  etc.).

## Guía para tu tileset

Antes de dibujar nada, lee **`TILESET_GUIDE.md`** — explica por qué el
tamaño de tile importa (el juego usa un truco de cámara para simular
isometría, no arte pre-inclinado) y te da las medidas exactas
recomendadas (tiles de 64×64, tamaños de personaje, paleta en hex).

## Ajustes a la ventana de inventario (esta versión)

- El inventario ahora es una **ventana real** (con barra de título y
  botón **X** para cerrar), no un overlay que tapa toda la pantalla.
  Su tamaño depende de su contenido, no de la resolución de pantalla.
- **Esc** ahora cierra primero el inventario si está abierto; solo te
  manda al menú principal si el inventario ya estaba cerrado.
- Las opciones del menú principal (Jugar/Ajustes/Salir) ahora se
  centran de forma explícita, independientemente del ancho del título.

## Inventario y equipamiento (Paso 2 del roadmap, versión inicial)

- **9 ranuras de equipamiento** (`scripts/equipment.gd`): Cabeza, Pecho,
  Manos, Piernas, Pies, Accesorio 1, Accesorio 2, Arma, Arma secundaria.
- **Mochila 5x5** (`scripts/inventory.gd`, 25 ranuras), con apilado
  automático para materiales.
- **Tecla `I`** abre/cierra el inventario durante la partida.
- El Guerrero arranca con algunos objetos de prueba en la mochila (yelmo,
  peto, espada, anillo, botas y mineral apilable). Haz clic en un objeto
  equipable de la mochila para equiparlo; haz clic en una ranura de
  equipamiento puesta para volver a guardarlo en la mochila.
- Cada objeto (`scripts/item_data.gd`) puede dar bonus a cualquier
  atributo (`stat_bonuses`, ej. `{"fuerza": 4.0}`). Al equipar/desequipar,
  `Player.recalculate_stats()` se ejecuta automáticamente y recalcula
  vida, aguante, maná, velocidad, coste de sprint y daño — verás las
  barras de vida/aguante cambiar en vivo.
- Todavía no hay tipos de armadura por clase (Ligera/Media/Pesada, etc.)
  ni penalización de movilidad — eso llega cuando definamos qué clase
  puede llevar qué (parte del Paso 4, framework de clases).

## Ventanas arrastrables (esta versión)

- **Todas las ventanas** (Inventario, Personaje, Habilidades) ahora se
  pueden **arrastrar desde su barra de título** con el cursor, gracias a
  `scripts/drag_handle.gd` (un script reutilizable para cualquier
  ventana futura).
- **`C`** abre/cierra **Mi personaje**: los 8 atributos combinados
  (base + equipo) y los valores derivados (vida, aguante, maná,
  velocidad, multiplicador de daño), en vivo.
- **`H`** abre/cierra **Mis habilidades**: las 3 habilidades actuales
  con su tecla, descripción y cooldown en vivo.
- **Esc** ahora cierra cualquier ventana que esté abierta (la que sea);
  solo te manda al menú si no había ninguna ventana abierta.

## Ajustes de esta versión

- **Resolución**: el juego arranca en **pantalla completa a la resolución
  máxima del monitor** (`window/size/mode = 3`, fullscreen). La resolución
  de referencia interna subió a 1920×1080 con `stretch/aspect = expand`,
  así que la UI ya no se ve diminuta en una pantalla grande.
- **Menú principal**: el centrado ahora se calcula a mano con el tamaño
  real de la caja de botones (`_center_boxes()` en `main_menu.gd`), en
  vez de depender de anclas anidadas — más a prueba de fallos. También
  se recentra solo si cambias el tamaño de la ventana.
- **Inventario**: ahora aparece **anclado al lateral derecho** de la
  pantalla (no centrado en medio), con recuadros más pequeños. El
  equipamiento ya no es una lista amontonada: está distribuido como un
  **muñeco** — Cabeza arriba, Pecho en el centro con los Accesorios a
  los lados, Manos con las Armas a los lados, Piernas y Pies debajo —
  imitando dónde iría cada pieza puesta sobre el cuerpo.

## Documento de diseño

Todo el diseño completo del juego (clases, subclases, atributos,
competencias, equipamiento y armas) está en **`DESIGN.md`**, junto con
el roadmap de desarrollo completo. Este README se centra en explicar
el prototipo técnico; `DESIGN.md` es la referencia de contenido/diseño.

## Sistema de atributos (Paso 1 del roadmap)

- `scripts/stat_block.gd` define el recurso `StatBlock` con los
  atributos primarios (Estabilidad, Agilidad, Destreza, Puntería,
  Fuerza, Voluntad, Canalización, Conexión Elemental) y los recursos
  base (Vida, Aguante, Maná), más las fórmulas derivadas.
- El Guerrero (`player.gd`) ahora calcula su vida máxima, aguante
  máximo, maná máximo, velocidad de movimiento y multiplicador de daño
  cuerpo a cuerpo a partir de su `StatBlock`, en vez de tener esos
  números "quemados" en el script.
- El **sprint (Shift)** ahora consume Aguante de verdad (barra nueva
  bajo la de vida) según el atributo Agilidad, y el **esquivar**
  cuesta una porción fija de Aguante. Si te quedas sin Aguante, no
  puedes esprintar ni esquivar hasta que regenere.
- Puedes asignar un `StatBlock` distinto al Guerrero desde el
  Inspector de Godot (nodo `Player` → propiedad `Stats`) para probar
  builds distintas sin tocar código.

## Menú principal y nivel de práctica

- El juego ahora **arranca en `MainMenu.tscn`** (menú Jugar / Ajustes / Salir),
  no directamente en la partida.
- **Jugar** carga `Main.tscn`. **Ajustes** abre un panel con volumen general
  (controla el bus de audio "Master") y pantalla completa. **Salir** cierra
  el juego. Todo construido por código (`scripts/main_menu.gd`), con la
  misma paleta del Estilo A.
- Desde la partida, **Esc** vuelve al menú principal en cualquier momento.
- Se añadieron **3 obstáculos estáticos** (pilares en forma de diamante,
  `Obstacle1/2/3` dentro de `Main.tscn`) repartidos por la arena para poder
  probar la colisión del jugador y del enemigo contra algo más que las
  paredes del borde. No bloquean el paso por completo: puedes rodearlos.

## Estructura de archivos

```
WisaCore_Prototype/
├── project.godot
├── DESIGN.md          # Documento de diseño + roadmap
├── scenes/
│   ├── MainMenu.tscn   # Menú (Jugar / Ajustes / Salir)
│   ├── Main.tscn        # Nivel de práctica (suelo, paredes, obstáculos)
│   ├── Player.tscn       # Guerrero
│   └── Enemy.tscn        # Aberración
└── scripts/
	├── main_menu.gd     # UI del menú principal, construida por código
	├── main.gd           # UI de partida + Esc para volver al menú
	├── player.gd          # Movimiento, ataques, esquivar, objetivo, inventario
	├── enemy.gd            # IA del enemigo
	├── stat_block.gd        # Recurso de atributos (Paso 1 del roadmap)
	├── item_data.gd          # Definición de un objeto (equipable o no)
	├── equipment.gd           # Las 9 ranuras de equipamiento
	└── inventory.gd            # Mochila 5x5
```

Todo el arte es "gray-box" (rectángulos de color) a propósito: es lo más
rápido de iterar mientras se define el gameplay. El azul es el jugador,
el rojo es el enemigo.

## Notas técnicas

- No se usó el `InputMap` de `project.godot`: las teclas están mapeadas
  directamente en `player.gd` (WASD/flechas por polling, y Tab/1/2/Espacio/clic
  por eventos). Esto es más fácil de tocar sin abrir el editor de proyecto,
  pero si prefieres, luego migramos esto al Input Map de Godot para poder
  remapear teclas desde un menú de opciones.
- Las capas de colisión usadas: `1` = mundo/paredes, `2` = jugador,
  `4` = enemigos (el área de ataque del jugador solo detecta la capa `4`).
- La cámara sigue al jugador con suavizado (`Camera2D` dentro de `Player.tscn`).

## Próximos pasos sugeridos

1. Reemplazar los rectángulos por sprites/animaciones (o modelos si decides
   pasar a 3D más adelante).
2. Añadir una segunda clase (ej. Mago) para probar el sistema con recursos
   distintos (maná vs. resistencia/energía).
3. Sistema de niveles + árbol de talentos básico (lo definimos en un
   documento de diseño aparte cuando quieras).
4. Primer mini-dungeon con 2-3 salas y un jefe simple.
5. Cuando el prototipo local esté sólido, evaluamos capa de red (Godot trae
   High-Level Multiplayer / ENet integrado, que es un buen punto de partida
   antes de pensar en un backend de MMO completo).
