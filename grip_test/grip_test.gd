extends Node3D
# Grip test. Hold Space to lower the claw, and release to close and lift. Press R to restart.
#
# The claw (Hub and fingers) is a physics body hanging from the Carriage. The cable only
# pulls: this script stops the Hub from moving farther from the Carriage than the cable's
# length. If the claw lands on something, the Hub stops and the cable goes slack.
#
# Each finger hangs on a hinge with a motor. The motor's force limit is the grip strength.

enum State { READY, LOWERING, CLOSING, LIFTING, DONE }

@export_group("Claw")
@export var grip_strength := 1.0 ## How hard the fingers squeeze.
@export var close_speed := 1.5 ## How fast the fingers close.
@export var close_time := 0.7 ## How long the claw waits for the fingers to close.

@export_group("Cable")
@export var pay_out_speed := 0.6 ## How fast the claw lowers, in meters per second.
@export var lift_speed := 0.4 ## How fast the claw lifts, in meters per second.
@export var max_cable_length := 2.5 ## The cable stops paying out at this length.
@export_range(0.05, 1.0) var cable_stiffness := 0.2 ## How firmly the cable corrects stretch.

const OPEN_STRENGTH := 5.0

var state := State.READY
var cable_length := 0.0

@onready var carriage: Node3D = $Carriage
@onready var hub: RigidBody3D = $Hub
@onready var cable: MeshInstance3D = $Cable
@onready var hinges: Array[HingeJoint3D] = [$HingeA, $HingeB, $HingeC]

var _cable_mesh := ImmediateMesh.new()
var _start_length := 0.0
var _close_timer := 0.0


func _ready() -> void:
	if not InputMap.has_action("drop"):
		InputMap.add_action("drop")
		var key := InputEventKey.new()
		key.physical_keycode = KEY_SPACE
		InputMap.action_add_event("drop", key)
	cable.mesh = _cable_mesh
	cable_length = _hub_distance()
	_start_length = cable_length
	_set_fingers(-close_speed, OPEN_STRENGTH)


func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and event.keycode == KEY_R:
		get_tree().reload_current_scene()


func _physics_process(delta: float) -> void:
	var cable_rate := 0.0 # Positive pays out, negative pulls in.
	match state:
		State.READY:
			if Input.is_action_pressed("drop"):
				state = State.LOWERING
		State.LOWERING:
			if Input.is_action_pressed("drop"):
				cable_rate = pay_out_speed
			else:
				state = State.CLOSING
				_close_timer = close_time
				_set_fingers(close_speed, grip_strength)
		State.CLOSING:
			_close_timer -= delta
			if _close_timer <= 0.0:
				state = State.LIFTING
		State.LIFTING:
			cable_rate = -lift_speed
			if cable_length <= _start_length:
				state = State.DONE

	cable_length = clampf(cable_length + cable_rate * delta, _start_length, max_cable_length)
	if is_equal_approx(cable_length, max_cable_length) and cable_rate > 0.0:
		cable_rate = 0.0
	if is_equal_approx(cable_length, _start_length) and cable_rate < 0.0:
		cable_rate = 0.0

	var stretch := _hub_distance() - cable_length
	if stretch > 0.0:
		# The cable pulls the Hub up just enough to stay within its length.
		var lowest_speed := -cable_rate + cable_stiffness * stretch / delta
		var velocity := hub.linear_velocity
		if velocity.y < lowest_speed:
			velocity.y = lowest_speed
			hub.linear_velocity = velocity


func _process(_delta: float) -> void:
	_draw_cable()


func slack() -> float:
	return maxf(cable_length - _hub_distance(), 0.0)


func _set_fingers(speed: float, strength: float) -> void:
	for hinge in hinges:
		hinge.set_flag(HingeJoint3D.FLAG_ENABLE_MOTOR, true)
		hinge.set_param(HingeJoint3D.PARAM_MOTOR_TARGET_VELOCITY, speed)
		hinge.set_param(HingeJoint3D.PARAM_MOTOR_MAX_IMPULSE, strength)


func _hub_distance() -> float:
	return carriage.global_position.y - hub.global_position.y


func _draw_cable() -> void:
	# A slack cable is drawn bowed out to the side. It's only a drawing: it has no physics.
	var top := carriage.global_position
	var bottom := hub.global_position
	var sag := slack() * 0.35
	_cable_mesh.clear_surfaces()
	_cable_mesh.surface_begin(Mesh.PRIMITIVE_LINE_STRIP)
	for i in 25:
		var t := i / 24.0
		var point := top.lerp(bottom, t)
		point.x += sag * sin(PI * t)
		_cable_mesh.surface_add_vertex(point)
	_cable_mesh.surface_end()
