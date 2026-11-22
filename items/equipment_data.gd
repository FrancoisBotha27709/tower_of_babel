class_name EquipmentData
extends ItemData

@export var slot: SlotDefinition

#region Overrides
# Equipment fills one slot and replaces whatever was there.
func get_slot() -> SlotDefinition:
	return slot
#endregion
