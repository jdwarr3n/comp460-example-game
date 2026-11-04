extends Camera3D
# A camera on a sphere around the cabinet. Arrow keys change longitude and latitude, and
# the mouse wheel changes the sphere's radius.

@export var target := Vector3(0, 1.0, 0) ## The point the camera looks at.
@export var longitude := 30.0 ## Degrees around the cabinet.
@export var latitude := 20.0 ## Degrees above the horizon.
@export var radius := 10.5 ## Distance from the target.
@export var turn_speed := 70.0 ## Degrees per second.
@export var zoom_step := 0.6 ## Radius change per wheel click.
@export var min_latitude := -8.0 ## Keeps the camera above the floor.
@export var max_latitude := 80.0 ## Keeps the camera from flipping over the top.
@export var min_radius := 7.0
@export var max_radius := 22.0


func _ready() -> void:
	_update_position()


func _process(delta: float) -> void:
	if Input.is_physical_key_pressed(KEY_LEFT):
		longitude -= turn_speed * delta
	if Input.is_physical_key_pressed(KEY_RIGHT):
		longitude += turn_speed * delta
	if Input.is_physical_key_pressed(KEY_UP):
		latitude += turn_speed * delta
	if Input.is_physical_key_pressed(KEY_DOWN):
		latitude -= turn_speed * delta
	latitude = clampf(latitude, min_latitude, max_latitude)
	_update_position()


func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.pressed:
		if event.button_index == MOUSE_BUTTON_WHEEL_UP:
			radius = maxf(radius - zoom_step, min_radius)
		elif event.button_index == MOUSE_BUTTON_WHEEL_DOWN:
			radius = minf(radius + zoom_step, max_radius)


func _update_position() -> void:
	var lon := deg_to_rad(longitude)
	var lat := deg_to_rad(latitude)
	position = target + radius * Vector3(cos(lat) * sin(lon), sin(lat), cos(lat) * cos(lon))
	look_at(target)
