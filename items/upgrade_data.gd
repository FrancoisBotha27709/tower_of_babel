class_name UpgradeData
extends ItemData

@export var max_stacks := 5

#region Overrides
# Upgrades stack up to their limit.
func get_stack_limit() -> int:
	return max_stacks
#endregion
