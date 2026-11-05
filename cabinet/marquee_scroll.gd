extends MeshInstance3D
# Scrolls the marquee text from right to left. It wraps, because the texture repeats.
# All four panels share this material, so text leaving one side enters the next, and this
# script belongs on one panel only.
# The game sets dimmed during a round, so the sign doesn't pull the player's eye.

@export var scroll_speed := 0.15 ## Panel widths per second.
@export var glow := 4.0 ## How bright the letters are.

@export_group("During a round")
@export var dimmed_scroll_speed := 0.05
@export var dimmed_glow := 1.3
@export var fade_speed := 6.0 ## How quickly the glow changes, per second.

var dimmed := false


func _process(delta: float) -> void:
	var material: StandardMaterial3D = mesh.material
	var speed := dimmed_scroll_speed if dimmed else scroll_speed
	var target := dimmed_glow if dimmed else glow
	material.uv1_offset.x = fmod(material.uv1_offset.x + speed * delta, 1.0)
	material.emission_energy_multiplier = move_toward(material.emission_energy_multiplier, target, fade_speed * delta)
