class_name LootPickup
extends Area3D

signal collected(collector: Node3D)

@export var lifetime := 40.0

var drop: LootDrop

#region Lifecycle
# Waits for bodies to touch the pickup and removes it after its lifetime.
func _ready() -> void:
	body_entered.connect(on_body_entered)
	get_tree().create_timer(lifetime).timeout.connect(queue_free)

# Receives what this pickup holds, rolled by the dropper.
func configure(rolled_drop: LootDrop) -> void:
	drop = rolled_drop

# Hands the drop to whoever touched it and disappears once something was taken.
func on_body_entered(collector: Node3D) -> void:
	if not drop or not drop.grant(collector):
		return
	collected.emit(collector)
	queue_free()
#endregion
