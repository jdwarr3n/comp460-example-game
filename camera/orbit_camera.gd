extends Camera3D
# A camera on a sphere around the cabinet. Arrow keys or WASD change longitude and latitude.
# The scroll wheel zooms in on the point under the mouse, and never out past the starting view.
# Zooming narrows the lens instead of moving closer, so the camera stays outside the glass.

@export var target := Vector3(0, 1.0, 0) ## The point the camera looks at.
@export var longitude := 30.0 ## Degrees around the cabinet.
@export var latitude := 20.0 ## Degrees above the horizon.
@export var radius := 7.0 ## Distance from the target.
@export var turn_speed := 70.0 ## Degrees per second.
@export var min_latitude := -8.0 ## Keeps the camera above the floor.
@export var max_latitude := 80.0 ## Keeps the camera from flipping over the top.
@export var max_zoom := 6.0 ## How far the scroll wheel zooms in.
@export var zoom_step := 1.2 ## How much one click of the wheel zooms.
@export var zoom_smoothing := 10.0 ## How quickly the view catches up with the wheel.

var _zoom := 1.0
var _shown_zoom := 1.0
var _full_fov := 38.0
var _home := Vector3.ZERO
var _focus := Vector3.ZERO


func _ready() -> void:
	_full_fov = fov
	_home = target
	_focus = target
	_update_position()


func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.pressed:
		if event.button_index == MOUSE_BUTTON_WHEEL_UP:
			_focus = _point_under_mouse()
			_zoom = minf(_zoom * zoom_step, max_zoom)
		elif event.button_index == MOUSE_BUTTON_WHEEL_DOWN:
			_zoom = maxf(_zoom / zoom_step, 1.0)


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
	_update_zoom(delta)
	_update_position()


func _update_zoom(delta: float) -> void:
	var ease_amount := 1.0 - exp(-zoom_smoothing * delta)
	_shown_zoom = lerpf(_shown_zoom, _zoom, ease_amount)
	fov = _full_fov / _shown_zoom
	# Moving the target by this much keeps the focus at the same spot on screen.
	target = _home.lerp(_focus, 1.0 - 1.0 / _shown_zoom)


# The first thing the mouse points at, looking through the glass.
func _point_under_mouse() -> Vector3:
	var mouse := get_viewport().get_mouse_position()
	var origin := project_ray_origin(mouse)
	var end := origin + project_ray_normal(mouse) * 100.0
	var query := PhysicsRayQueryParameters3D.create(origin, end)
	var skipped: Array[RID] = []
	while true:
		query.exclude = skipped
		var hit := get_world_3d().direct_space_state.intersect_ray(query)
		if hit.is_empty():
			return target
		if not hit.collider.name.begins_with("Glass"):
			return hit.position
		skipped.append(hit.rid)
	return target


func _update_position() -> void:
	var lon := deg_to_rad(longitude)
	var lat := deg_to_rad(latitude)
	position = target + radius * Vector3(cos(lat) * sin(lon), sin(lat), cos(lat) * cos(lon))
	look_at(target)
