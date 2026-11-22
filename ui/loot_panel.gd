class_name LootPanel
extends UIPanel

signal drop_taken(drop: LootDrop)

@export var loot_list: EntryList
@export var take_button: Button
@export var take_all_button: Button
@export var message_label: Label
@export var group_name := &"loot_panel"

var drops: Array[LootDrop] = []

#region Lifecycle
# Registers by group so chests can find the panel, and wires the buttons.
func _ready() -> void:
	super()
	add_to_group(group_name)
	take_button.pressed.connect(take_selected)
	take_all_button.pressed.connect(take_all)
#endregion

#region Display
# Opens a container's drops; taken drops are removed from the same array.
func open_loot(new_drops: Array[LootDrop], opening_user: Node3D) -> void:
	drops = new_drops
	message_label.text = ""
	open(opening_user)

# Lists what is left to take.
func refresh() -> void:
	var labels: PackedStringArray = []
	for drop in drops:
		labels.append(drop.get_label())
	loot_list.show_entries(drops, labels)
	message_label.text = message_label.text if not drops.is_empty() else "Empty."
#endregion

#region Taking
# Takes the selected drop if the user can use it.
func take_selected() -> void:
	var drop: LootDrop = loot_list.get_selected_entry()
	if drop:
		try_take(drop)
	refresh()

# Takes everything the user can use.
func take_all() -> void:
	for drop in drops.duplicate():
		try_take(drop)
	refresh()

# Grants one drop and removes it from the container, or explains why it stays.
func try_take(drop: LootDrop) -> void:
	if not drop.grant(user):
		message_label.text = "Cannot take %s." % drop.get_label()
		return
	drops.erase(drop)
	drop_taken.emit(drop)
#endregion
