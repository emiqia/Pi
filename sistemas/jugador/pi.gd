class_name Pi
extends CharacterBody2D

enum Estado { QUIETO, CAMINANDO, CORRIENDO, AGACHADO, EN_AIRE, DOBLE_SALTO, BACKFLIP, ATACANDO }

@export_group("Movimiento horizontal")
@export var velocidad_caminar := 150.0
@export var velocidad_correr := 270.0
@export var aceleracion := 420.0
@export var friccion := 900.0
@export var freno_giro := 1600.0
@export var aceleracion_aire := 380.0
@export var velocidad_dash := 330.0
@export var duracion_dash := 0.2

@export_group("Salto")
@export var altura_salto := 112.0
@export var tiempo_a_cima := 0.38
@export var altura_doble_salto := 80.0
@export var altura_backflip := 192.0
@export var empuje_backflip := 140.0
@export var bonus_salto_corriendo := 0.12
@export var multiplicador_caida := 1.4
@export var corte_salto := 0.45
@export var velocidad_caida_max := 560.0
@export var tiempo_coyote := 0.1
@export var tiempo_buffer := 0.12

@export_group("Ataque")
@export var suspension_ataque_aire := 0.2

const DURACION_GIRO_BACKFLIP := 0.55
const ULTIMO_CUADRO_AGACHARSE := 5

var estado := Estado.QUIETO
var mirando := 1

var _gravedad: float
var _puede_doble_salto := false
var _coyote := 0.0
var _buffer := 0.0
var _maxima_aire := 0.0
var _queria_correr := false
var _dash := 0.0
var _suspension := 0.0
var _puede_suspenderse := true

@onready var _visual: Node2D = $Visual
@onready var _sprite: AnimatedSprite2D = $Visual/Sprite
@onready var _etiqueta: Label = $Etiqueta


func _ready() -> void:
	_gravedad = 2.0 * altura_salto / (tiempo_a_cima * tiempo_a_cima)
	_sprite.animation_finished.connect(_al_terminar_animacion)


func _physics_process(delta: float) -> void:
	var direccion := Input.get_axis("izquierda", "derecha")
	var en_suelo := is_on_floor()

	_actualizar_temporizadores(delta, en_suelo)
	_atacar()
	_dash_carrera(direccion, en_suelo)
	_mover_horizontal(direccion, en_suelo, delta)
	_saltar(en_suelo)
	_aplicar_gravedad(delta)
	move_and_slide()
	_actualizar_estado()
	_actualizar_visual(delta)


func _actualizar_temporizadores(delta: float, en_suelo: bool) -> void:
	if en_suelo:
		_coyote = tiempo_coyote
		_puede_doble_salto = true
		_maxima_aire = clampf(absf(velocity.x), velocidad_caminar, velocidad_correr)
		_puede_suspenderse = true
	else:
		_coyote -= delta

	_suspension -= delta
	_dash = _dash - delta if en_suelo else 0.0

	if Input.is_action_just_pressed("saltar"):
		_buffer = tiempo_buffer
	else:
		_buffer -= delta


func _atacar() -> void:
	if not Input.is_action_just_pressed("atacar") or estado == Estado.ATACANDO:
		return
	estado = Estado.ATACANDO
	if not is_on_floor() and _puede_suspenderse:
		_puede_suspenderse = false
		_suspension = suspension_ataque_aire
	_sprite.speed_scale = 1.0
	_sprite.play("atacar_burbujas")


func _al_terminar_animacion() -> void:
	if estado == Estado.ATACANDO and _sprite.animation == &"atacar_burbujas":
		estado = Estado.QUIETO if is_on_floor() else Estado.EN_AIRE


func _dash_carrera(direccion: float, en_suelo: bool) -> void:
	var quiere := en_suelo and _quiere_correr() and not Input.is_action_pressed("agacharse") and estado != Estado.ATACANDO
	if quiere and not _queria_correr and absf(velocity.x) <= velocidad_caminar + 1.0:
		velocity.x = signf(direccion) * velocidad_dash
		_dash = duracion_dash
		mirando = 1 if direccion > 0.0 else -1
	_queria_correr = quiere


func _mover_horizontal(direccion: float, en_suelo: bool, delta: float) -> void:
	var agachado := en_suelo and Input.is_action_pressed("agacharse")
	var atacando_en_suelo := en_suelo and estado == Estado.ATACANDO

	if _dash > 0.0:
		direccion = float(mirando)

	var objetivo := 0.0
	if direccion != 0.0 and not agachado and not atacando_en_suelo:
		var maxima := velocidad_correr if Input.is_action_pressed("correr") else velocidad_caminar
		if not en_suelo:
			maxima = _maxima_aire
		objetivo = direccion * maxima

	var tasa: float
	if _suspension > 0.0:
		objetivo = 0.0
		tasa = friccion
	elif estado == Estado.BACKFLIP:
		tasa = aceleracion_aire * 0.3
	elif not en_suelo:
		tasa = aceleracion_aire
	elif objetivo == 0.0:
		tasa = friccion
	elif velocity.x != 0.0 and signf(objetivo) != signf(velocity.x):
		tasa = freno_giro
	else:
		tasa = aceleracion

	velocity.x = move_toward(velocity.x, objetivo, tasa * delta)

	if direccion != 0.0 and estado != Estado.BACKFLIP and estado != Estado.ATACANDO and _dash <= 0.0:
		mirando = 1 if direccion > 0.0 else -1


func _saltar(en_suelo: bool) -> void:
	if estado == Estado.ATACANDO:
		return

	if _buffer > 0.0:
		if en_suelo and Input.is_action_pressed("agacharse") and not _totalmente_agachado():
			pass
		elif en_suelo or _coyote > 0.0:
			_buffer = 0.0
			_coyote = 0.0
			if en_suelo and Input.is_action_pressed("agacharse"):
				velocity.y = -_velocidad_para(altura_backflip)
				velocity.x = -mirando * empuje_backflip
				estado = Estado.BACKFLIP
				_puede_doble_salto = false
			else:
				var rapidez := clampf(absf(velocity.x) / velocidad_correr, 0.0, 1.0)
				velocity.y = -_velocidad_para(altura_salto) * (1.0 + bonus_salto_corriendo * rapidez)
				estado = Estado.EN_AIRE
		elif _puede_doble_salto:
			_buffer = 0.0
			_puede_doble_salto = false
			velocity.y = -_velocidad_para(altura_doble_salto)
			estado = Estado.DOBLE_SALTO
			_sprite.play("saltar")
			_sprite.frame = 0

	if Input.is_action_just_released("saltar") and velocity.y < 0.0 and estado != Estado.BACKFLIP:
		velocity.y *= corte_salto


func _totalmente_agachado() -> bool:
	return _sprite.animation == &"agacharse" and _sprite.frame >= ULTIMO_CUADRO_AGACHARSE


func _aplicar_gravedad(delta: float) -> void:
	if _suspension > 0.0:
		velocity.y = 0.0
		return
	var gravedad := _gravedad * multiplicador_caida if velocity.y > 0.0 else _gravedad
	velocity.y = minf(velocity.y + gravedad * delta, velocidad_caida_max)


func _actualizar_estado() -> void:
	if estado == Estado.ATACANDO:
		return

	var rapidez := absf(get_real_velocity().x)
	if is_on_floor():
		if Input.is_action_pressed("agacharse"):
			estado = Estado.AGACHADO
		elif rapidez > velocidad_caminar + 1.0 or (rapidez > 5.0 and _quiere_correr()):
			estado = Estado.CORRIENDO
		elif rapidez > 5.0:
			estado = Estado.CAMINANDO
		else:
			estado = Estado.QUIETO
	elif estado in [Estado.QUIETO, Estado.CAMINANDO, Estado.CORRIENDO, Estado.AGACHADO]:
		estado = Estado.EN_AIRE


func _velocidad_para(altura: float) -> float:
	return sqrt(2.0 * _gravedad * altura)


func _actualizar_visual(delta: float) -> void:
	_visual.scale.x = mirando

	if estado == Estado.BACKFLIP:
		_sprite.rotation = maxf(_sprite.rotation - TAU / DURACION_GIRO_BACKFLIP * delta, -TAU)
	else:
		_sprite.rotation = 0.0

	match estado:
		Estado.ATACANDO:
			pass
		Estado.CAMINANDO:
			_sprite.play("caminar")
			_sprite.speed_scale = absf(velocity.x) / velocidad_caminar
		Estado.CORRIENDO:
			_animar_carrera()
		Estado.QUIETO:
			_sprite.speed_scale = 1.0
			if _sprite.animation == &"agacharse":
				_cambiar_postura("levantarse")
			elif _sprite.animation != &"levantarse" or not _sprite.is_playing():
				_sprite.play("quieto")
		Estado.AGACHADO:
			if _sprite.animation != &"agacharse":
				_sprite.speed_scale = 1.0
				_cambiar_postura("agacharse")
		_:
			_animar_aire()

	_etiqueta.text = "%s  %d" % [Estado.keys()[estado], absf(velocity.x)]


func _cambiar_postura(animacion: StringName) -> void:
	var cuadro := 0
	if _sprite.animation == &"agacharse" and animacion == &"levantarse":
		cuadro = ULTIMO_CUADRO_AGACHARSE - mini(_sprite.frame, ULTIMO_CUADRO_AGACHARSE)
	elif _sprite.animation == &"levantarse" and animacion == &"agacharse" and _sprite.is_playing():
		cuadro = ULTIMO_CUADRO_AGACHARSE - _sprite.frame
	_sprite.play(animacion)
	_sprite.frame = cuadro


func _quiere_correr() -> bool:
	return Input.is_action_pressed("correr") and Input.get_axis("izquierda", "derecha") != 0.0


func _animar_carrera() -> void:
	if _sprite.animation == &"correr_inicio":
		if not _sprite.is_playing():
			_sprite.play("correr")
	elif _sprite.animation != &"correr":
		_sprite.speed_scale = 1.0
		_sprite.play("correr_inicio" if _sprite.animation == &"quieto" else "correr")

	if _sprite.animation == &"correr":
		_sprite.speed_scale = clampf(absf(velocity.x) / velocidad_correr, 0.6, 1.2)


func _animar_aire() -> void:
	_sprite.speed_scale = 1.0
	if velocity.y < 0.0:
		if _sprite.animation != &"saltar":
			_sprite.play("saltar")
	elif _sprite.animation == &"caer_inicio":
		if not _sprite.is_playing():
			_sprite.play("caer")
	elif _sprite.animation != &"caer":
		_sprite.play("caer_inicio")
