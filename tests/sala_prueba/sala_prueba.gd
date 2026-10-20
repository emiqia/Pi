extends Node2D

const TILE := 32
const BLOQUE := Vector2i(0, 0)
const PLATAFORMA := Vector2i(1, 0)

const MAPA := [
	"#..............................................................#",
	"#..............................................................#",
	"#..............................................................#",
	"#..............................................................#",
	"#..............................................................#",
	"#................................................=====.#######.#",
	"#..............................................................#",
	"#..............................................................#",
	"#................................................=====.........#",
	"#.......................##.....................................#",
	"#..................##...##.....................................#",
	"#.............##...##...##.......................=====.........#",
	"#........##...##...##...##.....................................#",
	"#..P.....##...##...##...##.....................................#",
	"##############################....####.......###################",
	"##############################....####.......###################",
	"##############################....####.......###################",
]

@onready var _tiles: TileMapLayer = $Tiles
@onready var _pi: Pi = $Pi
@onready var _camara: Camera2D = $Pi/Camara
@onready var _luz: PointLight2D = $Luz
@onready var _ambiente: CanvasModulate = $Ambiente
@onready var _vitrina: Array[Sprite2D] = [$Vitrina/Original, $Vitrina/Sombreado]

var _tiempo := 0.0


func _ready() -> void:
	for y in MAPA.size():
		var fila: String = MAPA[y]
		for x in fila.length():
			var celda := Vector2i(x, y)
			match fila[x]:
				"#":
					_tiles.set_cell(celda, 0, BLOQUE)
				"=":
					_tiles.set_cell(celda, 0, PLATAFORMA)
				"P":
					_pi.position = _tiles.map_to_local(celda) + Vector2(0, TILE / 2.0)

	_camara.limit_left = 0
	_camara.limit_top = 0
	_camara.limit_right = MAPA[0].length() * TILE
	_camara.limit_bottom = MAPA.size() * TILE
	_camara.reset_smoothing()


func _process(delta: float) -> void:
	_tiempo += delta
	for sprite in _vitrina:
		sprite.frame = int(_tiempo * 12.0) % sprite.hframes
	_luz.global_position = get_global_mouse_position()


func _physics_process(_delta: float) -> void:
	if _pi.position.y > MAPA.size() * TILE + 64:
		get_tree().reload_current_scene()


func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and not event.echo and event.physical_keycode == KEY_L:
		_luz.visible = not _luz.visible
		_ambiente.visible = _luz.visible
	elif event.is_action_pressed("reiniciar"):
		get_tree().reload_current_scene()
	elif event.is_action_pressed("salir"):
		get_tree().quit()
