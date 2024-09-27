class_name NewMenu

extends Control

@export
var main_node: Main
@export
var width_edit: LineEdit
@export
var height_edit: LineEdit
@export
var credits_panel: Control


const MIN_GRID_SIZE := 5
const MAX_GRID_SIZE := 20

func grid_input():
	for edit in [width_edit, height_edit]:
		var input: String = edit.text
		var value: int = clampi(round(float(input)), MIN_GRID_SIZE, MAX_GRID_SIZE)
		edit.text = "%d" % value

func set_texture(texture: int):
	main_node.set_texture(texture)

func set_gamemode(mode: int):
	main_node.set_gamemode(mode)

func start_game():
	get_tree().paused = false
	grid_input() # Just in case anyone tries anything cheeky
	main_node.initialize_game_board(Vector2i(
		int(width_edit.text),
		int(height_edit.text)
	))

func toggle_credits():
	credits_panel.visible = !credits_panel.visible

func show_menu():
	get_tree().paused = true
	visible = true
	find_child(&"CloseButton").visible = true

func hide_menu():
	get_tree().paused = false
	visible = false

func _on_credits_display_link_clicked(meta: Variant):
	OS.shell_open(str(meta))

func _ready():
	var credits_display := credits_panel.find_child(&"CreditsDisplay")
	credits_display.text = credits_display.text + Engine.get_license_text()
