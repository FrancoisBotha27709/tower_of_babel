extends Control

@export_group("Scene Paths", "scene_")
@export var scene_main_game : PackedScene
@export var scene_course_game : PackedScene
@export var scene_option_menu : PackedScene
@export_group("Nodes", "node_")
@export var node_play_button : AnimateButton
@export var node_option_button : AnimateButton
@export var node_quit_button : AnimateButton
@export var node_course_button : AnimateButton

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	node_play_button.pressed.connect(_on_play_button)
	node_option_button.pressed.connect(_on_option_button)
	node_quit_button.pressed.connect(_on_quit_button)
	node_course_button.pressed.connect(_on_course_button)

func _on_course_button() -> void:
	get_tree().change_scene_to_packed(scene_course_game)

func _on_play_button() -> void:
	get_tree().change_scene_to_packed(scene_main_game)

func _on_option_button() -> void:
	get_tree().change_scene_to_packed(scene_option_menu)

func _on_quit_button() -> void:
	get_tree().quit()
