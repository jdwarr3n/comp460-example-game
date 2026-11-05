extends Node3D
# Runs the game: a timed round of grabbing prizes from a pile. The clock starts on the first
# drop. When time runs out, a drop in progress finishes, and then the round is over. R plays
# again. A prize counts when it falls through the chute.
#
# Q locks the claw onto the prize nearest the mouse, until the attempt is over. You get one
# per round.
# Difficulty is how much the physics is damped. Tab switches between Easy and Hard.

## How many of each prize are in a pile: about 1 / value.
const PILE := [
	[preload("res://prizes/ball.tscn"), 17],
	[preload("res://prizes/cylinder.tscn"), 9],
	[preload("res://prizes/capsule.tscn"), 8],
	[preload("res://prizes/cube.tscn"), 4],
	[preload("res://prizes/disc.tscn"), 2],
]

@export var prize_level := -0.1 ## A prize below this height has gone through the chute.
@export var round_seconds := 60.0 ## Length of a round.
@export var auto_aims := 1 ## How many times Q works per round.

@export_group("Easy")
@export var easy_sway := 3.0 ## Claw sway damping.
@export var easy_roll := 5.0 ## How quickly prizes stop rolling.

@export_group("Hard")
@export var hard_sway := 0.8
@export var hard_roll := 1.5

var hard := false
var score := 0
var attempts := 0
var time_left := 60.0
var clock_running := false
var round_over := false
var auto_aims_left := 1
var pile: Array[RigidBody3D] = []

@onready var label: Label = $UI/Status
@onready var values: RichTextLabel = $UI/ValuePanel/Values
@onready var final: Label = $UI/Final
@onready var camera: Camera3D = $Camera


func _ready() -> void:
	time_left = round_seconds
	auto_aims_left = auto_aims
	_show_values()
	$Claw.drop_started.connect(_on_drop_started)
	_spawn_pile()


func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and not event.echo:
		if event.keycode == KEY_R:
			get_tree().reload_current_scene()
		elif event.keycode == KEY_TAB:
			hard = not hard
			_apply_difficulty()
			_show_score()
		elif event.keycode == KEY_Q and auto_aims_left > 0 and not round_over:
			auto_aims_left -= 1
			$Claw.auto_aim_target = _prize_near_mouse()
			_show_score()


func _physics_process(delta: float) -> void:
	if clock_running:
		time_left = maxf(time_left - delta, 0.0)
		if time_left <= 0.0:
			clock_running = false
			$Claw.drops_enabled = false
		_show_score()
	if not clock_running and time_left <= 0.0 and not round_over and $Claw.state == 0:
		round_over = true
		_show_score()
	for prize in pile.duplicate():
		if prize.global_position.y < prize_level:
			score += prize.value
			pile.erase(prize) # It's won: it slides out of the slot and stays there.
			_show_score()
	if pile.is_empty():
		_spawn_pile()


func _spawn_pile() -> void:
	var scenes: Array[PackedScene] = []
	for entry in PILE:
		for i in entry[1]:
			scenes.append(entry[0])
	scenes.shuffle()
	# Prizes start in layers above the floor, away from the chute, and fall into a pile.
	for i in scenes.size():
		var prize: RigidBody3D = scenes[i].instantiate()
		var x := -0.95 + 0.27 * (i % 6)
		@warning_ignore("integer_division")
		var z := -1.0 + 0.33 * ((i / 6) % 7)
		prize.position = Vector3(x + randf_range(-0.03, 0.03), 0.35 + 0.1 * (i % 3), z + randf_range(-0.03, 0.03))
		prize.rotation = Vector3(randf_range(0.0, TAU), randf_range(0.0, TAU), randf_range(0.0, TAU))
		add_child(prize)
		pile.append(prize)
	_apply_difficulty()
	_show_score()


func _prize_near_mouse() -> RigidBody3D:
	var mouse := get_viewport().get_mouse_position()
	var origin := camera.project_ray_origin(mouse)
	var direction := camera.project_ray_normal(mouse)
	var best: RigidBody3D = null
	var best_distance := INF
	for prize in pile:
		var to_prize := prize.global_position - origin
		var distance := to_prize.cross(direction).length()
		if distance < best_distance:
			best_distance = distance
			best = prize
	return best


func _on_drop_started() -> void:
	attempts += 1
	clock_running = true
	_show_score()


func _apply_difficulty() -> void:
	$Claw.hub.linear_damp = hard_sway if hard else easy_sway
	for prize in pile:
		prize.angular_damp = hard_roll if hard else easy_roll


func _show_score() -> void:
	var level := "Hard" if hard else "Easy"
	var lines := [
		"Time: %d" % ceili(time_left),
		"Score: %d" % score,
		"Attempts: %d" % attempts,
		"Auto-aim (Q): %d" % auto_aims_left,
		"%s (Tab to change)" % level,
	]
	label.text = "\n".join(lines)
	final.visible = round_over
	final.text = "Final score %d - Hit 'r' to restart" % score


# Builds the table of prize values from the prizes themselves, so it can't go out of date.
func _show_values() -> void:
	var rows: Array[String] = []
	for entry in PILE:
		var prize: RigidBody3D = entry[0].instantiate()
		var mesh: Mesh = prize.get_node("Mesh").mesh
		var color: Color = mesh.material.albedo_color
		rows.append("[color=#%s]%s: %d[/color]" % [color.darkened(0.25).to_html(false), prize.prize_name, prize.value])
		prize.free()
	values.text = "\n".join(rows)
