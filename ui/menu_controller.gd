class_name MenuController
extends CanvasLayer

@export var panels: Array[UIPanel]
@export var inventory_panel: UIPanel
@export var player: Node3D
@export var inventory_action := &"inventory"
@export var cancel_action := &"ui_cancel"

#region Lifecycle
# Listens to every panel so it can pause and free the mouse.
func _ready() -> void:
	for panel in panels:
		panel.opened.connect(on_panel_opened)
		panel.closed.connect(on_panel_closed)

# Toggles the inventory and lets cancel close whatever is open.
func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed(inventory_action):
		toggle_inventory()
	elif event.is_action_pressed(cancel_action) and is_any_open():
		close_all()
	else:
		return
	get_viewport().set_input_as_handled()
#endregion

#region Panels
# Only one panel shows at a time; the game pauses and the mouse is freed.
func on_panel_opened(opened_panel: UIPanel) -> void:
	for panel in panels:
		if panel != opened_panel:
			panel.close()
	get_tree().paused = true
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE

# Resumes the game and recaptures the mouse once nothing is open.
func on_panel_closed(_closed_panel: UIPanel) -> void:
	if is_any_open():
		return
	get_tree().paused = false
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED

# Opens the inventory, or closes it when it is already showing.
func toggle_inventory() -> void:
	if inventory_panel.visible:
		inventory_panel.close()
	else:
		inventory_panel.open(player)

# True while any panel is showing.
func is_any_open() -> bool:
	return panels.any(func(panel: UIPanel) -> bool: return panel.visible)

# Closes every panel.
func close_all() -> void:
	for panel in panels:
		panel.close()
#endregion
