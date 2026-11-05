extends Node3D
# The claw in the cabinet. The mouse points at the cabinet floor, and the carriage and
# gantry chase that point at a limited speed. The claw hangs from the carriage on a cable,
# so it sways when the carriage moves.
#
# Hold the left mouse button to pay out the cable, and release to close and lift. The claw
# then carries its load to the chute by itself, opens, and returns to its start position.
#
# The cable only pulls: this script stops the Hub from moving farther from the carriage than
# the cable's length, in any direction. If the claw lands on something, it stops there and
# the cable goes slack.
#
# Each finger hangs on a hinge with a motor. The motor's force limit is the grip strength.

signal drop_started ## Sent once at the start of each drop.

enum State { READY, LOWERING, CLOSING, LIFTING, TO_CHUTE, SETTLING, OPENING, RETURNING }

@export_group("Carriage")
@export var carriage_speed := 1.2 ## Top speed of the carriage, in meters per second.
@export var travel_limit := 1.08 ## How far the carriage can go from the center.
@export var chute_stop := 0.82 ## Where the carriage stops over the chute, on both axes.
@export var carry_speed := 0.45 ## Speed on the automatic trips to the chute and back.

@export_group("Cable")
@export var rest_length := 1.0 ## Cable length when the claw is at the top.
@export var max_length := 1.99 ## The cable stops paying out at this length.
@export var pay_out_speed := 0.6 ## How fast the claw lowers, in meters per second.
@export var lift_speed := 0.4 ## How fast the claw lifts, in meters per second.
@export_range(0.05, 1.0) var cable_stiffness := 0.2 ## How firmly the cable corrects stretch.
@export var cable_width := 0.01 ## How thick the cable is drawn. It has no effect on physics.

@export_group("Claw")
@export var grip_strength := 1.0 ## How hard the fingers squeeze.
@export var close_speed := 1.5 ## How fast the fingers close.
@export var close_time := 0.7 ## How long the claw waits for the fingers to close.
@export var settle_time := 3.0 ## The longest the claw waits over the chute before opening.
@export var settled_swing := 0.04 ## The claw opens once its swing is smaller than this.
@export var open_time := 0.8 ## How long the claw stays open over the chute.

@export_group("Sway")
@export var tilt_follow := 6.0 ## How quickly the claw tilts to line up with the cable.
@export var sway_damping := 3.0 ## How quickly the swing dies down. Higher settles faster.

@export_group("Sound")
@export var motor_volume_db := -42.0 ## How loud the motors are while running. Very faint.
@export var motor_fade := 10.0 ## How quickly a motor sound starts and stops, per second.

const OPEN_STRENGTH := 5.0

var state := State.READY
var cable_length := 0.0
var target := Vector3.ZERO ## Where the carriage is heading.
var mouse_aim := true
var drop_held := false ## Lets a test hold the drop button.
var motors_on := true ## The game turns the motor sounds off between rounds.
var drops_enabled := true ## The game turns this off when the round is over.
var auto_aim_target: Node3D = null ## While set, the claw follows this and ignores the mouse.

@onready var carriage: Node3D = get_node("../Cabinet/Carriage")
@onready var gantry: Node3D = get_node("../Cabinet/Gantry")
@onready var camera: Camera3D = get_node("../Camera")
@onready var hub: RigidBody3D = $Hub
@onready var cable: MeshInstance3D = $Cable
@onready var marker: MeshInstance3D = $Marker
@onready var hinges: Array[HingeJoint3D] = [$HingeA, $HingeB, $HingeC]
@onready var carriage_sound: AudioStreamPlayer = $CarriageSound
@onready var cable_sound: AudioStreamPlayer = $CableSound

var _cable_mesh := ImmediateMesh.new()
var _floor := Plane(Vector3.UP, 0.0)
var _timer := 0.0
var _home := Vector3.ZERO
var _last_cable_length := 0.0
var _hit_sounds: Node = null
var _part_speeds := {}


func _ready() -> void:
	cable.mesh = _cable_mesh
	cable_length = rest_length
	target = carriage.global_position
	_home = carriage.global_position
	hub.linear_damp = sway_damping
	_set_fingers(-close_speed, OPEN_STRENGTH)
	_hit_sounds = get_tree().current_scene.get_node_or_null("HitSounds")
	for part: RigidBody3D in [hub, $FingerA, $FingerB, $FingerC]:
		part.contact_monitor = true
		part.max_contacts_reported = 4
		part.body_entered.connect(_on_claw_hit.bind(part))


func _unhandled_input(event: InputEvent) -> void:
	# Aim changes only when the mouse moves, so orbiting the camera leaves the claw alone.
	if mouse_aim and auto_aim_target == null and state == State.READY and event is InputEventMouseMotion:
		_aim_at(event.position)


func _physics_process(delta: float) -> void:
	var cable_rate := _update_state(delta)
	if state == State.READY and is_instance_valid(auto_aim_target):
		target = auto_aim_target.global_position
	var before := carriage.global_position
	if state in [State.READY, State.TO_CHUTE, State.RETURNING]:
		_move_carriage(delta)
	var carriage_velocity := (carriage.global_position - before) / delta
	_apply_cable(cable_rate, carriage_velocity, delta)
	_tilt_claw()
	_set_motor(carriage_sound, motors_on and carriage_velocity.length() > 0.02, delta)
	_set_motor(cable_sound, motors_on and cable_length != _last_cable_length, delta)
	_last_cable_length = cable_length
	for part in [hub, $FingerA, $FingerB, $FingerC]:
		_part_speeds[part] = part.linear_velocity.length()


func _process(_delta: float) -> void:
	_draw_cable()
	var landing := carriage.global_position
	marker.global_position = Vector3(landing.x, 0.012, landing.z)
	marker.visible = state in [State.READY, State.LOWERING]


func slack() -> float:
	return maxf(cable_length - hub.global_position.distance_to(carriage.global_position), 0.0)


# Runs the drop sequence. Returns how fast the cable is changing: positive pays out.
func _update_state(delta: float) -> float:
	var held := drop_held or Input.is_mouse_button_pressed(MOUSE_BUTTON_LEFT)
	var rate := 0.0
	match state:
		State.READY:
			if held and drops_enabled:
				state = State.LOWERING
				drop_started.emit()
		State.LOWERING:
			if held:
				if cable_length < max_length:
					rate = pay_out_speed
			else:
				state = State.CLOSING
				_timer = close_time
				_set_fingers(close_speed, grip_strength)
		State.CLOSING:
			_timer -= delta
			if _timer <= 0.0:
				state = State.LIFTING
		State.LIFTING:
			rate = -lift_speed
			if cable_length <= rest_length:
				rate = 0.0
				state = State.TO_CHUTE
				target = Vector3(chute_stop, 0.0, chute_stop)
		State.TO_CHUTE:
			if _carriage_arrived():
				state = State.SETTLING
				_timer = settle_time
		State.SETTLING:
			_timer -= delta
			if _timer <= 0.0 or _swing() < settled_swing:
				state = State.OPENING
				_timer = open_time
				_set_fingers(-close_speed, OPEN_STRENGTH)
		State.OPENING:
			_timer -= delta
			if _timer <= 0.0:
				state = State.RETURNING
				target = _home
		State.RETURNING:
			if _carriage_arrived():
				state = State.READY
				auto_aim_target = null
	cable_length = clampf(cable_length + rate * delta, rest_length, max_length)
	return rate


func _swing() -> float:
	var offset := hub.global_position - carriage.global_position
	return Vector2(offset.x, offset.z).length()


func _carriage_arrived() -> bool:
	var here := carriage.global_position
	var there := Vector2(target.x, target.z)
	return Vector2(here.x, here.z).distance_to(there) < 0.005


func _aim_at(screen_point: Vector2) -> void:
	var origin := camera.project_ray_origin(screen_point)
	var direction := camera.project_ray_normal(screen_point)
	var hit: Variant = _floor.intersects_ray(origin, direction)
	if hit != null:
		target = hit


func _move_carriage(delta: float) -> void:
	var goal := Vector3(
		clampf(target.x, -travel_limit, travel_limit),
		carriage.global_position.y,
		clampf(target.z, -travel_limit, travel_limit)
	)
	var position_now := carriage.global_position
	var speed := carriage_speed if state == State.READY else carry_speed
	carriage.global_position = position_now.move_toward(goal, speed * delta)
	gantry.global_position.z = carriage.global_position.z


func _apply_cable(cable_rate: float, carriage_velocity: Vector3, delta: float) -> void:
	var offset := hub.global_position - carriage.global_position
	var distance := offset.length()
	if distance <= cable_length:
		return
	var along_cable := offset / distance
	var stretch := distance - cable_length
	var speed_away := (hub.linear_velocity - carriage_velocity).dot(along_cable)
	var allowed := cable_rate - cable_stiffness * stretch / delta
	if speed_away > allowed:
		hub.linear_velocity -= along_cable * (speed_away - allowed)


func _tilt_claw() -> void:
	# Turns the claw so its top points back up the cable.
	var up_cable := (carriage.global_position - hub.global_position).normalized()
	var turn := hub.global_basis.y.cross(up_cable)
	hub.angular_velocity = turn * tilt_follow


func _set_fingers(speed: float, strength: float) -> void:
	for hinge in hinges:
		hinge.set_flag(HingeJoint3D.FLAG_ENABLE_MOTOR, true)
		hinge.set_param(HingeJoint3D.PARAM_MOTOR_TARGET_VELOCITY, speed)
		hinge.set_param(HingeJoint3D.PARAM_MOTOR_MAX_IMPULSE, strength)


# Prizes make their own sound when the claw hits them, so this is for the cabinet.
func _on_claw_hit(body: Node, part: RigidBody3D) -> void:
	if _hit_sounds != null and body is StaticBody3D:
		_hit_sounds.hit("metal", _part_speeds.get(part, 0.0))


func _set_motor(player: AudioStreamPlayer, running: bool, delta: float) -> void:
	var full := db_to_linear(motor_volume_db)
	var level := full if running else 0.0
	player.volume_linear = move_toward(player.volume_linear, level, motor_fade * full * delta)


func _draw_cable() -> void:
	# A slack cable is drawn bowed out to the side. It's only a drawing: it has no physics.
	# It's a narrow ribbon facing the camera, because a line is always one pixel wide.
	var top := carriage.global_position
	var bottom := hub.global_position
	var sag := slack() * 0.35
	var camera := get_viewport().get_camera_3d()
	var to_camera := camera.global_position - top if camera else Vector3.BACK
	var side := (bottom - top).cross(to_camera).normalized() * cable_width * 0.5
	_cable_mesh.clear_surfaces()
	_cable_mesh.surface_begin(Mesh.PRIMITIVE_TRIANGLE_STRIP)
	for i in 25:
		var t := i / 24.0
		var point := top.lerp(bottom, t)
		point.x += sag * sin(PI * t)
		_cable_mesh.surface_add_vertex(point - side)
		_cable_mesh.surface_add_vertex(point + side)
	_cable_mesh.surface_end()
