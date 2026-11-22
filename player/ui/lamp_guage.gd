extends Node
class_name LampGauge

@export var lamps_root: Node3D
@export var source: Node
@export var source_signal := &"charges_changed"

#region Lifecycle
# Listens to any float signal on any node.
func _ready() -> void:
	source.connect(source_signal, set_value)

# Lights each lamp child by how much of the value covers it; partial values glow dimmer.
func set_value(value: float) -> void:
	for index in lamps_root.get_child_count():
		(lamps_root.get_child(index) as GeometryInstance3D).transparency = 1.0 - clampf(value - index, 0.0, 1.0)
#endregion
