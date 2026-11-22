extends Node3D
class_name ViewmodelReactor

@export var body: PlayerBody
@export var machine: StateMachine
@export var glow: Light3D
@export var pose_positions: Dictionary[StringName, Vector3]
@export var pose_rotations_degrees: Dictionary[StringName, Vector3]
@export var glow_colors: Dictionary[StringName, Color]
@export var default_glow_color := Color.WHITE
@export var landing_dip_per_speed := 0.01
@export var maximum_landing_dip := 0.25
@export var pose_smoothing := 12.0
@export var dip_recovery := 8.0

var rest_position := Vector3.ZERO
var rest_rotation_degrees := Vector3.ZERO
var target_position := Vector3.ZERO
var target_rotation_degrees := Vector3.ZERO
var dip := 0.0

#region Lifecycle
# Remembers the rest pose and listens for state changes and landings.
func _ready() -> void:
	rest_position = position
	rest_rotation_degrees = rotation_degrees
	machine.state_changed.connect(apply_state)
	body.landed.connect(func(impact_speed: float) -> void: dip = minf(impact_speed * landing_dip_per_speed, maximum_landing_dip))

# Smoothly moves the viewmodel to the pose of the current state plus any landing dip.
func _process(delta: float) -> void:
	dip = lerpf(dip, 0.0, 1.0 - exp(-dip_recovery * delta))
	var weight := 1.0 - exp(-pose_smoothing * delta)
	position = position.lerp(rest_position + target_position + Vector3.DOWN * dip, weight)
	rotation_degrees = rotation_degrees.lerp(rest_rotation_degrees + target_rotation_degrees, weight)
#endregion

#region Reactions
# Picks the pose and glow colour for the new state.
func apply_state(_previous: StringName, current: StringName) -> void:
	target_position = pose_positions.get(current, Vector3.ZERO)
	target_rotation_degrees = pose_rotations_degrees.get(current, Vector3.ZERO)
	glow.light_color = glow_colors.get(current, default_glow_color)
#endregion