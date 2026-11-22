class_name Interactable
extends Area3D

signal interacted(user: Node3D)

@export var prompt: Node3D
@export var action := &"interact"

var user: Node3D

#region Lifecycle
# Watches for inventory carriers entering and leaving reach.
func _ready() -> void:
	body_entered.connect(on_body_entered)
	body_exited.connect(on_body_exited)
	refresh_prompt()

# Announces the interaction when the action is pressed while a user is in reach.
func _unhandled_input(event: InputEvent) -> void:
	if user and event.is_action_pressed(action):
		interacted.emit(user)
		get_viewport().set_input_as_handled()
#endregion

#region Reach
# Remembers who is in reach; only bodies with an inventory can interact.
func on_body_entered(candidate: Node3D) -> void:
	if candidate.has_meta(InventoryComponent.META_KEY):
		user = candidate
		refresh_prompt()

# Forgets the user once they leave.
func on_body_exited(candidate: Node3D) -> void:
	if candidate == user:
		user = null
		refresh_prompt()

# Shows the prompt only while someone can interact.
func refresh_prompt() -> void:
	if prompt:
		prompt.visible = user != null
#endregion
