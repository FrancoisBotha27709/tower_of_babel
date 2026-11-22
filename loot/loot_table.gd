class_name LootTable
extends Resource

@export var entries: Array[LootEntry]
@export_range(0, 5) var minimum_drops := 0
@export_range(0, 5) var maximum_drops := 5

#region Rolling
# Rolls between the minimum and maximum number of weighted picks from the entries.
func roll() -> Array[LootDrop]:
	var drops: Array[LootDrop] = []
	if entries.is_empty():
		return drops
	for pick_index in randi_range(minimum_drops, maximum_drops):
		drops.append(pick_entry().roll())
	return drops

# Picks one entry with probability proportional to its weight.
func pick_entry() -> LootEntry:
	var total_weight := 0.0
	for entry in entries:
		total_weight += entry.weight
	var target := randf() * total_weight
	for entry in entries:
		target -= entry.weight
		if target <= 0.0:
			return entry
	return entries.back()
#endregion
