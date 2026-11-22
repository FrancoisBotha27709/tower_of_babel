class_name EntryList
extends ItemList

signal entry_chosen(entry: Variant)

var entries: Array = []

#region Lifecycle
# Turns a click into the entry behind the row.
func _ready() -> void:
	item_selected.connect(func(row: int) -> void: entry_chosen.emit(entries[row]))
#endregion

#region Rows
# Replaces every row; entries and labels line up by index.
func show_entries(new_entries: Array, labels: PackedStringArray) -> void:
	clear()
	entries = new_entries
	for label in labels:
		add_item(label)

# The entry behind the selected row, or null when nothing is selected.
func get_selected_entry() -> Variant:
	var selection := get_selected_items()
	return null if selection.is_empty() else entries[selection[0]]
#endregion
