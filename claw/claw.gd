extends Node3D
# The claw in the cabinet. The mouse points at the cabinet floor, and the carriage and
# gantry chase that point at a limited speed. The claw hangs from the carriage on a cable,
# so it sways when the carriage moves.
#
# The cable only pulls: this script stops the Hub from moving farther from the carriage than
# the cable's length, in any direction.

@export_group("Carriage")
@export var carriage_speed := 1.2 ## Top speed of the carriage, in meters per second.
@export var travel_limit := 0.42 ## How far the carriage can go from the center.

@export_group("Cable")
@export var cable_length := 1.0 ## Distance from the carriage to the claw.
@export_range(0.05, 1.0) var cable_stiffness := 0.2 ## How firmly the cable corrects stretch.

@export_group("Sway")
@export var tilt_follow := 6.0 ## How quickly the claw tilts to line up with the cable.

const OPEN_STRENGTH := 5.0
const OPEN_SPEED := 1.5

var target := Vector3.ZERO ## Where the carriage is heading.
var mouse_aim := true

@onready var carriage: Node3D = get_node("../Cabinet/Carriage")
@onready var gantry: Node3D = get_node("../Cabinet/Gantry")
@onready var camera: Camera3D = get_node("../Camera")
@onready var hub: RigidBody3D = $Hub
@onready var cable: MeshInstance3D = $Cable
@onready var marker: MeshInstance3D = $Marker
@onready var hinges: Array[HingeJoint3D] = [$HingeA, $HingeB, $HingeC]

var _cable_mesh := ImmediateMesh.new()
var _floor := Plane(Vector3.UP, 0.0)


func _ready() -> void:
	cable.mesh = _cable_mesh
	target = carriage.global_position
	for hinge in hinges:
		hinge.set_flag(HingeJoint3D.FLAG_ENABLE_MOTOR, true)
		hinge.set_param(HingeJoint3D.PARAM_MOTOR_TARGET_VELOCITY, -OPEN_SPEED)
		hinge.set_param(HingeJoint3D.PARAM_MOTOR_MAX_IMPULSE, OPEN_STRENGTH)


func _unhandled_input(event: InputEvent) -> void:
	# Aim changes only when the mouse moves, so orbiting the camera leaves the claw alone.
	if mouse_aim and event is InputEventMouseMotion:
		_aim_at(event.position)


func _physics_process(delta: float) -> void:
	var before := carriage.global_position
	_move_carriage(delta)
	var carriage_velocity := (carriage.global_position - before) / delta
	_apply_cable(carriage_velocity, delta)
	_tilt_claw()


func _process(_delta: float) -> void:
	_draw_cable()
	var landing := carriage.global_position
	marker.global_position = Vector3(landing.x, 0.012, landing.z)


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
	carriage.global_position = position_now.move_toward(goal, carriage_speed * delta)
	gantry.global_position.z = carriage.global_position.z


func _apply_cable(carriage_velocity: Vector3, delta: float) -> void:
	var offset := hub.global_position - carriage.global_position
	var distance := offset.length()
	if distance <= cable_length:
		return
	var along_cable := offset / distance
	var stretch := distance - cable_length
	var speed_away := (hub.linear_velocity - carriage_velocity).dot(along_cable)
	var allowed := -cable_stiffness * stretch / delta
	if speed_away > allowed:
		hub.linear_velocity -= along_cable * (speed_away - allowed)


func _tilt_claw() -> void:
	# Turns the claw so its top points back up the cable.
	var up_cable := (carriage.global_position - hub.global_position).normalized()
	var turn := hub.global_basis.y.cross(up_cable)
	hub.angular_velocity = turn * tilt_follow


func _draw_cable() -> void:
	_cable_mesh.clear_surfaces()
	_cable_mesh.surface_begin(Mesh.PRIMITIVE_LINES)
	_cable_mesh.surface_add_vertex(carriage.global_position)
	_cable_mesh.surface_add_vertex(hub.global_position)
	_cable_mesh.surface_end()
