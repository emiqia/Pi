# Pi

Pi, un pequeño mago sin elemento propio, recorre los reinos
copiando y mezclando elementos para derrotar al ente que posee a Euler, el dios elemental.

Diseño completo en `docs/` (GDD, PDF de la idea y carta Gantt del MVP).

## Idea de la estructura

El **motor** (`sistemas/`, `autoload/`, `ui/`) está separado del **contenido** (`reinos/`, `datos/`).
Cada reino es una carpeta autocontenida con el mismo molde, así que sumar un reino nuevo es copiar
`reinos/_plantilla/` y rellenarla.

```
Pi/
├── project.godot          Configuración de Godot (pixel art 480x270 escalado ×4 a 1080p)
├── autoload/              Singletons globales: estado del juego, ruta pacifista/genocida,
│                          gestor de reinos, guardado, audio, transiciones de escena
├── sistemas/              Código reutilizable, no depende de ningún reino
│   ├── jugador/           Pi: movimiento con aceleración progresiva, doble salto, backflip
│   │   ├── estados/       Máquina de estados (idle, correr, saltar, backflip, atacar…)
│   │   └── camara/
│   ├── baculo/            Enganchar enemigo, ataques aéreos, absorber, arrojar enemigo u orbe
│   ├── elementos/         Lógica de elementos y fusiones (agua, fuego, planta, roca, metal, electricidad)
│   ├── enemigos/          Enemigo base (elemento que se puede absorber)
│   ├── jefes/             Jefe base + decisión perdonar / eliminar
│   ├── niveles/componentes/  Checkpoints, zonas secretas, plataformas, puertas, trampas
│   ├── clima/             Día, atardecer, lluvia y tormenta (p. ej. electricidad solo con lluvia)
│   ├── dialogos/          Sistema de diálogos e interacción
│   └── utilidades/
├── datos/                 Recursos de datos (.tres / JSON), se editan sin tocar código
│   ├── elementos/         Un recurso por elemento
│   ├── fusiones/          Tabla de combinaciones (y versiones potenciadas de los reyes)
│   ├── dificultades/      Normal, Veterano, Pesadilla, REAL
│   └── reinos/            Orden, desbloqueo y elementos disponibles por reino
├── reinos/
│   ├── _plantilla/        Molde de un reino
│   ├── 01_plantas/        Capítulo 1 (MVP): Reina de las plantas
│   │   ├── niveles/       Prados, bosque, día lluvioso con truenos, climas, estaciones, etccc
│   │   ├── enemigos/  jefe/  npcs/
│   │   ├── tilesets/  fondos/  musica/
│   │   └── dialogos/
│   ├── 02_desierto_montanas/
│   ├── 03_agua/
│   ├── 04_fuego/
│   ├── 05_industrial/
│   ├── 06_elemental/      Castillo de Euler, finales bueno y malo
│   └── 07_limbo/          Solo con la ruta genocida completa
├── compartido/            Arte y sonido usados en varios reinos
│   ├── personajes/        pi (con animaciones/ del cuerpo de Pi), euler, ente_maligno
│   ├── vfx/
│   │   ├── elementos/     agua, fuego, planta, roca, metal, electricidad (orbe, impacto, aura)
│   │   ├── fusiones/      efectos de las combinaciones (p. ej. agua_electricidad)
│   │   └── ataques/       enganchar, aereo_vertical, aereo_horizontal, absorber,
│   │                      arrojar_enemigo, arrojar_orbe
│   └── sfx/  fuentes/  ui/
├── ui/                    menus/ (principal, pausa, game over, selector de reino, dificultad),
│                          hud/ (vida, orbe y elemento activo), dialogo/
├── addons/                Plugins de Godot
├── tests/
├── docs/                  GDD, Gantt, PDF
└── builds/                Exportaciones (ignorado por Git)
```

## Convenciones

- Carpetas y archivos en `snake_case`, sin tildes ni ñ (`desierto_montanas`).
- Cada escena (`.tscn`) va junto a su script (`.gd`).
- Los reinos se numeran para mantener el orden de la historia.
- Animaciones como *sprite sheets* PNG nombradas
  `<cosa>_<accion>.png`, p. ej. `fuego_impacto.png`, `enganchar_golpe.png`.
