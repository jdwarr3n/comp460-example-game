extends Node
# Plays collision sounds. Harder hits are louder, tiny bumps are ignored, and only a few sounds
# play at once, so a pile of prizes doesn't turn into noise. The game turns this on during a round.

const SOUNDS := {
	"soft": preload("res://audio/hit_soft.wav"),
	"plastic": preload("res://audio/hit_plastic.wav"),
	"metal": preload("res://audio/hit_metal.wav"),
}

@export var voices := 6 ## How many sounds can play at once.
@export var min_speed := 0.4 ## Hits slower than this make no sound.
@export var full_speed := 3.0 ## Hits this fast are at full volume.
@export var quiet_db := -34.0 ## Volume of the softest hit.
@export var loud_db := -16.0 ## Volume of the hardest hit.
@export var min_gap := 0.03 ## Seconds between sounds.

var enabled := false
var played := 0

var _players: Array[AudioStreamPlayer] = []
var _last_time := -1.0


func _ready() -> void:
	for i in voices:
		var player := AudioStreamPlayer.new()
		add_child(player)
		_players.append(player)


func hit(kind: String, speed: float) -> void:
	var now := Time.get_ticks_msec() / 1000.0
	if not enabled or speed < min_speed or now - _last_time < min_gap:
		return
	for player in _players:
		if not player.playing:
			var strength := clampf((speed - min_speed) / (full_speed - min_speed), 0.0, 1.0)
			player.stream = SOUNDS[kind]
			player.volume_db = lerpf(quiet_db, loud_db, strength)
			player.pitch_scale = randf_range(0.92, 1.08)
			player.play()
			_last_time = now
			played += 1
			return
