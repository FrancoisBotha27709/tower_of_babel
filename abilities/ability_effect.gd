class_name AbilityEffect
extends Resource

#region Overridable
# Whether this effect has anything to do right now; override to add conditions.
func can_apply(_context: AbilityComponent) -> bool:
	return true

# Does the effect's work; override in subclasses.
func apply(_context: AbilityComponent) -> void:
	pass
#endregion
