extends Button
class_name AnimateButton

@export_group("Nodes", "node_")
@export var node_label : RichTextLabel

@export_group("Juice", "juice_")
@export var juice_strength : float = 3.0

func _ready() -> void:
	if self.text:
		node_label.text = self.text
		self.text = ""
