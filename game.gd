extends Node3D
# Runs the game: a timed round of grabbing prizes from a pile. A click leaves the start screen,
# and the clock starts on the first drop. When time runs out, a drop in progress finishes, and
# then the round is over. A click plays again. A prize counts when it falls through the chute.
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

## One is picked at random for each round.
const GAME_TRACKS := [preload("res://audio/music_game_a.wav"), preload("res://audio/music_game_b.wav")]

@export var prize_level := -0.1 ## A prize below this height has gone through the chute.
@export var round_seconds := 60.0 ## Length of a round.
@export var auto_aims := 1 ## How many times Q works per round.
@export var value_lighten := 0.3 ## Lightens the prize colors in the value list.
@export var final_score_size := 0.09 ## Height of the final score, as a share of the window.
@export var music_volume_db := -24.0
@export var music_fade_seconds := 1.0 ## Length of every music fade.
@export var replay_fade_speed := 3.0 ## Speeds up the fade after a click to play again.
@export var countdown_seconds := 10 ## A soft tick each second for this long at the end of a round.
@export var countdown_volume_db := -22.0
@export var replay_delay := 1.5 ## Seconds before a click can restart, so the score gets read.

@export_group("Easy")
@export var easy_sway := 3.0 ## Claw sway damping.
@export var easy_roll := 5.0 ## How quickly prizes stop rolling.

@export_group("Hard")
@export var hard_sway := 0.8
@export var hard_roll := 1.5

enum Phase { WAITING, PLAYING, OVER }

# These survive the scene reload between rounds.
static var hard := false
static var play_again := false

var phase := Phase.WAITING
var score := 0
var attempts := 0
var time_left := 60.0
var clock_running := false
var over_seconds := 0.0
var waiting_for_release := false
var last_tick_second := 0
var start_mix := 0.0
var game_mix := 0.0
var leaving := false
var auto_aims_left := 1
var pile: Array[RigidBody3D] = []

@onready var label: Label = $UI/Status
@onready var values: RichTextLabel = $UI/Values
@onready var final: Label = $UI/Final
@onready var start_overlay: TextureRect = $UI/StartOverlay
@onready var end_overlay: TextureRect = $UI/EndOverlay
@onready var camera: Camera3D = $Camera
@onready var start_music: AudioStreamPlayer = $StartMusic
@onready var game_music: AudioStreamPlayer = $GameMusic
@onready var countdown_tick: AudioStreamPlayer = $CountdownTick
@onready var marquee := $Cabinet/Marquee/Logo


func _ready() -> void:
	time_left = round_seconds
	auto_aims_left = auto_aims
	_show_values()
	$Claw.drop_started.connect(_on_drop_started)
	$Claw.drops_enabled = false
	countdown_tick.volume_db = countdown_volume_db
	game_music.stream = GAME_TRACKS.pick_random()
	_spawn_pile()
	if play_again:
		play_again = false
		_start_playing()


func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		if phase == Phase.WAITING:
			_start_playing()
		elif phase == Phase.OVER and over_seconds >= replay_delay:
			leaving = true
	if event is InputEventKey and event.pressed and not event.echo:
		if event.keycode == KEY_TAB:
			hard = not hard
			_apply_difficulty()
			_show_score()
		elif event.keycode == KEY_Q and auto_aims_left > 0 and phase == Phase.PLAYING:
			auto_aims_left -= 1
			$Claw.auto_aim_target = _prize_near_mouse()
			_show_score()


func _physics_process(delta: float) -> void:
	marquee.dimmed = clock_running
	_update_music(delta)
	# The click that starts the game mustn't also drop the claw.
	if waiting_for_release and not Input.is_mouse_button_pressed(MOUSE_BUTTON_LEFT):
		waiting_for_release = false
		$Claw.drops_enabled = true
	if phase == Phase.OVER:
		over_seconds += delta
	if clock_running:
		time_left = maxf(time_left - delta, 0.0)
		_tick_countdown()
		if time_left <= 0.0:
			clock_running = false
			$Claw.drops_enabled = false
		_show_score()
	if not clock_running and time_left <= 0.0 and phase == Phase.PLAYING and $Claw.state == 0:
		phase = Phase.OVER
		_show_score()
	for prize in pile.duplicate():
		if prize.global_position.y < prize_level:
			score += prize.value
			pile.erase(prize) # It's won: it slides out of the slot and stays there.
			_show_score()
	if pile.is_empty():
		_spawn_pile()


func _start_playing() -> void:
	phase = Phase.PLAYING
	waiting_for_release = true
	_show_score()


func _tick_countdown() -> void:
	var second := ceili(time_left)
	if second <= countdown_seconds and second > 0 and second != last_tick_second:
		last_tick_second = second
		countdown_tick.play()


func _update_music(delta: float) -> void:
	var in_round := phase == Phase.PLAYING
	var step := delta * (replay_fade_speed if leaving else 1.0)
	start_mix = _mix_track(start_music, start_mix, not in_round and not leaving, step)
	game_mix = _mix_track(game_music, game_mix, in_round and not leaving, step)
	if leaving and start_mix <= 0.0 and game_mix <= 0.0:
		play_again = true
		get_tree().reload_current_scene.call_deferred()


# Fades a track in and out when it's wanted or not, and at both ends of its loop.
func _mix_track(player: AudioStreamPlayer, mix: float, wanted: bool, delta: float) -> float:
	mix = move_toward(mix, 1.0 if wanted else 0.0, delta / music_fade_seconds)
	if wanted and not player.playing:
		player.play()
	elif mix <= 0.0 and player.playing:
		player.stop()
	var position := player.get_playback_position()
	var edge := minf(position, player.stream.get_length() - position) / music_fade_seconds
	player.volume_linear = db_to_linear(music_volume_db) * mix * clampf(edge, 0.0, 1.0)
	return mix


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
	var lines := [
		"Time: %d" % ceili(time_left),
		"Score: %d" % score,
		"Attempts: %d" % attempts,
		"Auto-aim (Q): %d" % auto_aims_left,
		"Level: %s" % ("Hard" if hard else "Easy"),
	]
	label.text = "\n".join(lines)
	start_overlay.visible = phase == Phase.WAITING
	end_overlay.visible = phase == Phase.OVER
	final.visible = phase == Phase.OVER
	final.text = "Final score\n%d" % score
	# The overlay image scales with the window, so the score has to as well.
	final.add_theme_font_size_override("font_size", int(get_viewport().get_visible_rect().size.y * final_score_size))


# Builds the table of prize values from the prizes themselves, so it can't go out of date.
func _show_values() -> void:
	var rows: Array[String] = []
	for entry in PILE:
		var prize: RigidBody3D = entry[0].instantiate()
		var mesh: Mesh = prize.get_node("Mesh").mesh
		var color: Color = mesh.material.albedo_color.lightened(value_lighten)
		rows.append("[right][color=#%s]%s: %d[/color][/right]" % [color.to_html(false), prize.prize_name, prize.value])
		prize.free()
	values.text = "\n".join(rows)
