class_name DeathComponent
extends Node

signal dying
signal death_finished

@export var health: HealthComponent
@export var death_delay := 1.0

#region Lifecycle
# Waits for the shared health to run out.
func _ready() -> void:
	health.died.connect(die)

# Announces the death right away and again once the delay has passed.
func die() -> void:
	dying.emit()
	get_tree().create_timer(death_delay).timeout.connect(death_finished.emit)
#endregion
