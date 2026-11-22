class_name CameraRig
extends Node3D

@export var body: PlayerBody
@export var machine: StateMachine
@export var camera: Camera3D
@export var wall_run_state := &"WallRun"
@export var toggle_mouse_action := &"ui_cancel"
@export_group("Look")
@export var mouse_sensitivity := 0.002
@export_range(0.0, 90.0) var pitch_limit_degrees := 89.0
@export_group("Feel")
@export var base_fov := 90.0
@export var fov_per_speed := 0.8
@export var maximum_fov_bonus := 25.0
@export var strafe_roll_degrees_per_speed := 0.1
@export var wall_run_roll_degrees := 12.0
@export var smoothing := 10.0

var wall_running := false

#region Lifecycle
# Captures the mouse and tracks when wall running starts and stops.
func _ready() -> void:
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
	machine.state_changed.connect(func(_previous: StringName, current: StringName) -> void: 
		wall_running = current == wall_run_state)

# Turns the body for yaw, this node for pitch, and toggles mouse capture.
func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventMouseMotion:
		body.rotate_y(-event.relative.x * mouse_sensitivity)
		rotation.x = clampf(rotation.x - event.relative.y * mouse_sensitivity,\
		-deg_to_rad(pitch_limit_degrees), deg_to_rad(pitch_limit_degrees))
	elif event.is_action_pressed(toggle_mouse_action):
		Input.mouse_mode = Input.MOUSE_MODE_VISIBLE \
		if Input.mouse_mode == Input.MOUSE_MODE_CAPTURED else Input.MOUSE_MODE_CAPTURED

# Smooths speed-based FOV and strafe or wall-run roll.
func _process(delta: float) -> void:
	var local_velocity := body.global_basis.inverse() * body.velocity
	var roll := -local_velocity.x * strafe_roll_degrees_per_speed
	if wall_running:
		roll += wall_run_roll_degrees * body.get_wall_side()
	var weight := 1.0 - exp(-smoothing * delta)
	var target_fov := base_fov + minf(body.get_horizontal_velocity().length() \
	* fov_per_speed, maximum_fov_bonus)
	camera.fov = lerpf(camera.fov, target_fov, weight)
	camera.rotation.z = lerp_angle(camera.rotation.z, deg_to_rad(roll), weight)
#endregion
