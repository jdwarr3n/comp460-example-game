extends Camera3D
# A camera on a sphere around the cabinet. Arrow keys or WASD change longitude and latitude.

@export var target := Vector3(0, 1.0, 0) ## The point the camera looks at.
@export var longitude := 30.0 ## Degrees around the cabinet.
@export var latitude := 20.0 ## Degrees above the horizon.
@export var radius := 7.0 ## Distance from the target.
@export var turn_speed := 70.0 ## Degrees per second.
@export var min_latitude := -8.0 ## Keeps the camera above the floor.
@export var max_latitude := 80.0 ## Keeps the camera from flipping over the top.


func _ready() -> void:
	_update_position()


func _process(delta: float) -> void:
	if Input.is_physical_key_pressed(KEY_LEFT) or Input.is_physical_key_pressed(KEY_A):
		longitude -= turn_speed * delta
	if Input.is_physical_key_pressed(KEY_RIGHT) or Input.is_physical_key_pressed(KEY_D):
		longitude += turn_speed * delta
	if Input.is_physical_key_pressed(KEY_UP) or Input.is_physical_key_pressed(KEY_W):
		latitude += turn_speed * delta
	if Input.is_physical_key_pressed(KEY_DOWN) or Input.is_physical_key_pressed(KEY_S):
		latitude -= turn_speed * delta
	latitude = clampf(latitude, min_latitude, max_latitude)
	_update_position()


func _update_position() -> void:
	var lon := deg_to_rad(longitude)
	var lat := deg_to_rad(latitude)
	position = target + radius * Vector3(cos(lat) * sin(lon), sin(lat), cos(lat) * cos(lon))
	look_at(target)
