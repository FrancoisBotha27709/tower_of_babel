class_name ItemData
extends Resource

@export var display_name := ""
@export_multiline var description := ""
@export var icon: Texture2D
@export var value := 0
@export var modifiers: Array[StatModifier]
@export var abilities: Array[AbilityData]

#region Overridable
# Slot this item occupies; none means it is a passive upgrade.
func get_slot() -> SlotDefinition:
	return null

# How many copies the owner can hold at once.
func get_stack_limit() -> int:
	return 1
#endregion

#region Display
# One-line text for lists: the name, the slot it fills and how many are held.
func get_listing(count := 1) -> String:
	var slot := get_slot()
	var slot_text := " (%s)" % slot.display_name if slot else ""
	return "%s%s%s" % [display_name, slot_text, " x%d" % count if count > 1 else ""]
#endregion
