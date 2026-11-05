extends RigidBody3D
# A prize. Harder shapes are worth more.

@export var prize_name := "Ball"
@export var value := 1
@export var metal := false ## Clinks when it hits something.

var _speed := 0.0
var _sounds: Node = null


func _ready() -> void:
	_sounds = get_tree().current_scene.get_node_or_null("HitSounds")
	contact_monitor = true
	max_contacts_reported = 4
	body_entered.connect(_on_body_entered)


# Speed from the last tick, because a hit has already slowed the prize by the time it's reported.
func _physics_process(_delta: float) -> void:
	_speed = linear_velocity.length()


func _on_body_entered(body: Node) -> void:
	if _sounds == null:
		return
	if metal or not (body is StaticBody3D or "prize_name" in body):
		_sounds.hit("metal", _speed)
	elif body is StaticBody3D:
		_sounds.hit("soft", _speed)
	else:
		_sounds.hit("plastic", _speed)
