extends GPUParticles3D
class_name SpeedWind

@export var body: PlayerBody
@export var minimum_speed := 14.0
@export var maximum_speed := 40.0
@export var maximum_speed_scale := 2.0

#region Update
# Streams wind lines along the travel direction, denser and faster with speed.
func _process(_delta: float) -> void:
	var intensity := clampf(inverse_lerp(minimum_speed, maximum_speed, body.velocity.length()), 0.0, 1.0)
	emitting = intensity > 0.0
	if not emitting:
		return
	var direction := body.velocity.normalized()
	look_at(global_position + direction, Vector3.RIGHT if direction.cross(Vector3.UP).is_zero_approx() else Vector3.UP)
	amount_ratio = intensity
	speed_scale = lerpf(1.0, maximum_speed_scale, intensity)
#endregion