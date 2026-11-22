class_name UIPanel
extends Control

signal opened(panel: UIPanel)
signal closed(panel: UIPanel)

@export var close_button: Button

var user: Node3D

#region Lifecycle
# Starts hidden and closes from its button.
func _ready() -> void:
	visible = false
	close_button.pressed.connect(close)
#endregion

#region Visibility
# Shows the panel for a user, fills it and announces it.
func open(opening_user: Node3D) -> void:
	user = opening_user
	visible = true
	refresh()
	opened.emit(self)

# Hides the panel and announces it.
func close() -> void:
	if not visible:
		return
	visible = false
	closed.emit(self)

# Rebuilds what the panel shows; panels override this.
func refresh() -> void:
	pass
#endregion
