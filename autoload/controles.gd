extends Node

const TECLAS := {
	"izquierda": [KEY_A, KEY_LEFT],
	"derecha": [KEY_D, KEY_RIGHT],
	"agacharse": [KEY_S, KEY_DOWN],
	"saltar": [KEY_SPACE, KEY_K],
	"correr": [KEY_SHIFT, KEY_J],
	"atacar": [KEY_Z],
	"reiniciar": [KEY_R],
	"salir": [KEY_ESCAPE],
}

const BOTONES_MANDO := {
	"izquierda": [JOY_BUTTON_DPAD_LEFT],
	"derecha": [JOY_BUTTON_DPAD_RIGHT],
	"agacharse": [JOY_BUTTON_DPAD_DOWN],
	"saltar": [JOY_BUTTON_A],
	"correr": [JOY_BUTTON_X],
	"atacar": [JOY_BUTTON_B],
	"reiniciar": [JOY_BUTTON_BACK],
}

const EJES_MANDO := {
	"izquierda": [JOY_AXIS_LEFT_X, -1.0],
	"derecha": [JOY_AXIS_LEFT_X, 1.0],
	"agacharse": [JOY_AXIS_LEFT_Y, 1.0],
}


func _ready() -> void:
	for accion in TECLAS:
		for tecla in TECLAS[accion]:
			var evento := InputEventKey.new()
			evento.physical_keycode = tecla
			_agregar(accion, evento)

	for accion in BOTONES_MANDO:
		for boton in BOTONES_MANDO[accion]:
			var evento := InputEventJoypadButton.new()
			evento.button_index = boton
			_agregar(accion, evento)

	for accion in EJES_MANDO:
		var evento := InputEventJoypadMotion.new()
		evento.axis = EJES_MANDO[accion][0]
		evento.axis_value = EJES_MANDO[accion][1]
		_agregar(accion, evento)


func _agregar(accion: String, evento: InputEvent) -> void:
	if not InputMap.has_action(accion):
		InputMap.add_action(accion, 0.3)
	InputMap.action_add_event(accion, evento)
