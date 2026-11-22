class_name SlamState
extends PlayerState

signal slammed(impact_speed: float)

@export var slam_speed := 48.0
@export var horizontal_damping := 10.0
@export var impact_hitbox: HitboxComponent

#region Lifecycle
# Drops like a stone.
func enter() -> void:
	body.velocity.y = -slam_speed

# Holds the dive speed while keeping most sideways momentum.
func physics_update(delta: float) -> void:
	body.velocity.y = -slam_speed
	body.accelerate_horizontal(Vector3.ZERO, horizontal_damping, delta)

# Strikes everything around the landing, then lets the base class pick jump, slide or run.
func handle_landing() -> void:
	impact_hitbox.pulse()
	slammed.emit(-body.previous_velocity.y)
	super.handle_landing()
#endregion
