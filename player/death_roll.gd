class_name DeathRoll
extends Node

@export var death: DeathComponent
@export var rig: Node3D
@export_range(0.0, 180.0) var roll_degrees := 70.0
@export var duration := 0.8

#region Lifecycle
# Waits for the death to begin.
func _ready() -> void:
	death.dying.connect(roll)

# Tips the camera over so the player visibly collapses.
func roll() -> void:
	create_tween().set_trans(Tween.TRANS_SINE).tween_property(rig, "rotation:z", deg_to_rad(roll_degrees), duration)
#endregion
