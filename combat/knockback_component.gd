class_name KnockbackComponent
extends Node

@export var body: CharacterBody3D
@export var health: HealthComponent
@export var force_multiplier := 1.0

#region Lifecycle
# Listens for damage on the shared health.
func _ready() -> void:
	health.damaged.connect(apply_knockback)

# Adds the hit's knockback to the body's velocity.
func apply_knockback(hit: HitData) -> void:
	body.velocity += hit.knockback * force_multiplier
#endregion
