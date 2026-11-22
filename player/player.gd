extends CharacterBody3D
class_name PlayerBody

signal landed(impact_speed: float)
signal left_floor
@warning_ignore("unused_signal")
signal jumped

#region Configuration
@export_group("Nodes")
@export var collision_shape: CollisionShape3D
@export var head: Node3D
@export var ceiling_check: RayCast3D
@export_group("Input Actions")
@export var move_left := &"move_left"
@export var move_right := &"move_right"
@export var move_forward := &"move_forward"
@export var move_backward := &"move_backward"
@export var jump_action := &"jump"
@export_group("Tuning")
@export var gravity := 32.0
@export var coyote_time := 0.12
@export var jump_buffer_time := 0.12
@export var stance_transition_time := 0.12
@export_range(0.0, 1.0) var eye_height_ratio := 0.9
#endregion

#region Runtime
var wall_normal := Vector3.ZERO
var previous_velocity := Vector3.ZERO
var coyote_remaining := 0.0
var jump_buffer_remaining := 0.0
var standing_height := 0.0
var capsule: CapsuleShape3D
var stance_tween: Tween
var was_on_floor := false
#endregion

#region Lifecycle
# Caches the capsule and its standing height.
func _ready() -> void:
	capsule = collision_shape.shape as CapsuleShape3D
	standing_height = capsule.height

# Records jump presses so they can be buffered.
func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed(jump_action):
		jump_buffer_remaining = jump_buffer_time

# Moves the body, ticks timers and emits floor signals. Called by the state machine.
func move(delta: float) -> void:
	previous_velocity = velocity
	move_and_slide()
	var on_floor := is_on_floor()
	var floor_changed := on_floor != was_on_floor
	was_on_floor = on_floor
	coyote_remaining = coyote_time if on_floor else maxf(coyote_remaining - delta, 0.0)
	jump_buffer_remaining = maxf(jump_buffer_remaining - delta, 0.0)
	if floor_changed:
		if on_floor:
			landed.emit(-previous_velocity.y)
		else:
			left_floor.emit()
#endregion

#region Movement Helpers
# World-space movement direction from input, relative to body yaw.
func get_move_direction() -> Vector3:
	var input := Input.get_vector(move_left, move_right, move_forward, move_backward)
	return global_basis * Vector3(input.x, 0.0, input.y)

# Velocity with the vertical component removed.
func get_horizontal_velocity() -> Vector3:
	return Vector3(velocity.x, 0.0, velocity.z)

# Overwrites horizontal velocity and keeps vertical untouched.
func set_horizontal_velocity(value: Vector3) -> void:
	velocity.x = value.x
	velocity.z = value.z

# Moves horizontal velocity toward a target at a fixed rate.
func accelerate_horizontal(target: Vector3, rate: float, delta: float) -> void:
	set_horizontal_velocity(get_horizontal_velocity().move_toward(target, rate * delta))

# Pulls the body down, optionally scaled.
func apply_gravity(delta: float, gravity_scale := 1.0) -> void:
	velocity.y -= gravity * gravity_scale * delta

# Which side the wall is on relative to the body: 1 right, -1 left.
func get_wall_side() -> float:
	return signf(-wall_normal.dot(global_basis.x))

# True when there is room above to stand up.
func can_stand() -> bool:
	return not ceiling_check.is_colliding()

# Smoothly resizes the capsule and eye height to a fraction of standing height.
func set_stance(height_scale: float) -> void:
	var height := standing_height * height_scale
	if stance_tween:
		stance_tween.kill()
	stance_tween = create_tween().set_parallel().set_trans(Tween.TRANS_SINE)
	stance_tween.tween_property(capsule, "height", height, stance_transition_time)
	stance_tween.tween_property(collision_shape, "position:y", height / 2.0, stance_transition_time)
	stance_tween.tween_property(head, "position:y", height\
	* eye_height_ratio, stance_transition_time)
#endregion
