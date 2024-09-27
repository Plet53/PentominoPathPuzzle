class_name Main

extends Control

var cell_texture := TextureName.BLANK
var menu_pentominos = {}
var buttons_disabled := false
var button_inputevent := InputEventAction.new()
var game_mode: GameMode = GameMode.CLASSIC
var selected_pentomino: StringName
var puzzle_board
@export
var toolbox: Control
@export
var startpoint_button: Control
@export
var puzzle_container: Control
@export
var score_label: Label
@export
var new_menu: Control
@export
var hold_timer: Timer


enum GameMode {CLASSIC = 0, SINGLE = 1, FREESTYLE = 2}
enum TextureName {BLANK = 0, BEVEL = 1, BUBBLES = 2, CHECK = 3}
var TEXTURE_SET = {
	TextureName.BLANK: preload("res://assets/cells/Blank.png"),
	TextureName.BEVEL: preload("res://assets/cells/Bevel.png"),
	TextureName.BUBBLES: preload("res://assets/cells/Bubbles.png"),
	TextureName.CHECK: preload("res://assets/cells/Check.png")
}
var pentomino_set = {}

func initialize_game_board(grid_size: Vector2i):
	if puzzle_board != null:
		puzzle_board.free()
	for pentomino in menu_pentominos:
		menu_pentominos[pentomino].disabled = false
	puzzle_board = PuzzleBoard.new()
	puzzle_board.container_position = puzzle_container.global_position
	puzzle_board.container_size = puzzle_container.size
	puzzle_board.init(grid_size)
	puzzle_container.add_child(puzzle_board)
	new_menu.visible = false
	puzzle_board.select_board.connect(_on_board_selected)
	puzzle_board.piece_release.connect(_on_button_release)
	puzzle_board.piece_removed.connect(_on_pentomino_removed)
	puzzle_board.startpoint_selected.connect(_on_start_point_picked)
	match game_mode:
		GameMode.SINGLE:
			puzzle_board.piece_placed.connect(_on_pentomino_placed)
			puzzle_board.board_clear.connect(_on_board_clear)
		GameMode.CLASSIC:
			puzzle_board.piece_placed.connect(_on_pentomino_placed)

func set_texture(texture: int):
	cell_texture = texture as TextureName
	for pentomino in menu_pentominos:
		menu_pentominos[pentomino].pentomino.set_texture(TEXTURE_SET[texture])
	if puzzle_board != null:
		puzzle_board.update_texture(TEXTURE_SET[texture])

func set_gamemode(mode: int):
	game_mode = mode as GameMode

func _on_pentomino_selected(pentomino: StringName):
	hold_timer.start()
	selected_pentomino = pentomino
	puzzle_board.select(menu_pentominos[pentomino].pentomino.copy())
	puzzle_board.selected_button = menu_pentominos[pentomino]

func _on_start_point_selected():
	hold_timer.start()
	puzzle_board.selected_button = startpoint_button
	puzzle_board.select(puzzle_board.startpoint_graphic)

func _on_board_selected():
	hold_timer.start()

func _on_start_point_picked():
	puzzle_board.selected_button = startpoint_button
	puzzle_board.select(puzzle_board.startpoint_graphic)
	startpoint_button.grab_focus()

func _on_object_held():
	puzzle_board.dragging = true
	puzzle_board.mouse_down = false

func _on_button_release():
	hold_timer.stop()

func _on_board_clear():
	for pentomino in menu_pentominos:
		menu_pentominos[pentomino].disabled = false
	buttons_disabled = false

func _on_pentomino_removed(pentomino_name: StringName):
	menu_pentominos[pentomino_name].disabled = false
	menu_pentominos[pentomino_name].grab_focus()
	puzzle_board.selected_button = menu_pentominos[pentomino_name]

func _on_pentomino_placed(pentomino: StringName):
	match game_mode:
		GameMode.SINGLE when !buttons_disabled:
			for other_pentomino in menu_pentominos:
				if other_pentomino != pentomino:
					menu_pentominos[other_pentomino].disabled = true
			buttons_disabled = true
		GameMode.CLASSIC:
			menu_pentominos[pentomino].disabled = true

func _on_rotate_piece_left_pressed():
	button_inputevent.action = &"game_rotate_left"
	Input.parse_input_event(button_inputevent)

func _on_rotate_piece_right_pressed():
	button_inputevent.action = &"game_rotate_right"
	Input.parse_input_event(button_inputevent)

func _on_flip_piece_hori_pressed():
	button_inputevent.action = &"game_flip_hori"
	Input.parse_input_event(button_inputevent)

func _on_flip_piece_vert_pressed():
	button_inputevent.action = &"game_flip_vert"
	Input.parse_input_event(button_inputevent)

func _on_drop_piece_pressed():
	puzzle_board.deselect_selected()

func _on_score_pressed():
	var score = puzzle_board.score_board()
	score_label.text = " Current Score: %d" % score

func _on_menu_pressed():
	new_menu.show_menu()

# Called when the node enters the scene tree for the first time.
func _ready():
	var pentominos_file := FileAccess.open(&"res://assets/pentominos.json", FileAccess.READ)
	var pentominos_string := pentominos_file.get_as_text()
	
	var json := JSON.new()
	var error = json.parse(pentominos_string)
	
	if error == OK:
		var data = json.data
		
		for obj in data:
			var pentomino = Pentomino.new()
			pentomino.name = obj["name"]
			pentomino.pentomino_name = obj["name"]
			pentomino.modulate = Color(obj["color"])
			for cell in obj["cells"]:
				pentomino.cells.push_back(Vector2i(int(cell.x), int(cell.y)))
			pentomino.setup_cells()
			pentomino.set_texture(TEXTURE_SET[cell_texture])
			pentomino_set[pentomino.name] = pentomino
			var pentomino_button = PentominoButton.new()
			pentomino_button.name = obj["name"] + " Button"
			pentomino_button.pentomino = pentomino
			var position_child = Node2D.new()
			position_child.position = Vector2i.ONE * 80
			position_child.add_child(pentomino)
			pentomino_button.add_child(position_child)
			pentomino_button.select.connect(_on_pentomino_selected)
			pentomino_button.release.connect(_on_button_release)
			toolbox.add_child(pentomino_button)
			menu_pentominos[pentomino.name] = pentomino_button
		
		# Place startpoint button at the end of the button menu
		toolbox.remove_child(startpoint_button)
		toolbox.add_child(startpoint_button)
		# Set up necessary factor of button input event
		button_inputevent.pressed = true
	else:
		printerr("JSON Loading Error: ", json.get_error_message(), ", please reload.")
