class_name PuzzleBoard

extends Node2D
var grid_size := Vector2i(5, 5)
var map: Array[int] = []
var board_pentominos: Array[Pentomino]
var start_point := Vector2i(-1, -1)
var lock := false
var dragging := false
var mouse_down := false
var startpoint_graphic
var piece_position = null
var selected = null
var selected_button
var entrace_map = {}
var text_child = null
var container_position
var container_size

signal select_board
signal piece_release
signal board_clear
signal piece_removed(pentomino_name: StringName)
signal piece_placed(pentomino_name: StringName)
signal startpoint_selected

const backing = preload("res://assets/cell_bg.png")
const cell_fill = preload("res://assets/cells/Blank.png")
const text_theme = preload("res://assets/board_text.tres")
const cardinals = [
	Vector2i.LEFT,
	Vector2i.RIGHT,
	Vector2i.UP,
	Vector2i.DOWN
]

func _ready() -> void:
	startpoint_graphic = Sprite2D.new()
	startpoint_graphic.texture = backing
	startpoint_graphic.name = &"StartPoint"
	var startpoint_sprite = Sprite2D.new()
	startpoint_sprite.texture = preload("res://assets/start_point.png")
	startpoint_graphic.add_child(startpoint_sprite)

func init(input_size: Vector2i) -> void:
	grid_size = input_size
	map.resize(input_size.x * input_size.y)
	map.fill(0)
	for i in input_size.x * input_size.y:
		var backing_sprite = Sprite2D.new()
		backing_sprite.texture = backing
		var cell_sprite = Sprite2D.new()
		cell_sprite.texture = cell_fill
		cell_sprite.scale *= 2
		backing_sprite.add_child(cell_sprite)
		backing_sprite.position = map_index_to_coord(i) * 32
		add_child(backing_sprite)
	entrace_map[Vector2i.LEFT] = Vector2i(grid_size.x, grid_size.y / 2)
	entrace_map[Vector2i.RIGHT] = Vector2i(0, grid_size.y / 2)
	entrace_map[Vector2i.UP] = Vector2i(grid_size.x / 2, grid_size.y)
	entrace_map[Vector2i.DOWN] = Vector2i(grid_size.x / 2, 0)
	position = (container_size / 2) - (Vector2(grid_size.x - 1, grid_size.y - 1) * 16)

# Input Handling Tree
func _input(event: InputEvent) -> void:
	if event.is_action_type() && event.is_pressed(): # Key Event Block
		match event:
			var ievent when selected is Pentomino && ievent.is_action(&"game_rotate_left"):
				selected.rotate_piece(true)
				selected_button.pentomino.rotate_piece(true)
			var ievent when selected is Pentomino && ievent.is_action(&"game_rotate_right"):
				selected.rotate_piece(false)
				selected_button.pentomino.rotate_piece(false)
			var ievent when selected is Pentomino && ievent.is_action(&"game_flip_hori"):
				selected.flip_piece(true)
				selected_button.pentomino.flip_piece(true)
			var ievent when selected is Pentomino && ievent.is_action(&"game_flip_vert"):
				selected.flip_piece(false)
				selected_button.pentomino.flip_piece(false)
			var ievent when ievent.is_action(&"move_piece_left"):
				move_selected(Vector2i.LEFT)
			var ievent when ievent.is_action(&"move_piece_right"):
				move_selected(Vector2i.RIGHT)
			var ievent when ievent.is_action(&"move_piece_up"):
				move_selected(Vector2i.UP)
			var ievent when ievent.is_action(&"move_piece_down"):
				move_selected(Vector2i.DOWN)
			var ievent when ievent.is_action(&"game_place"):
				if selected is Pentomino:
					place_pentomino(selected, selected.position)
				elif selected == startpoint_graphic:
					place_startpoint(selected.position)
			var ievent when ievent.is_action(&"game_drop"):
				deselect_selected()
			var ievent when ievent.is_action(&"left_mouse_click") && selected == null: # mouse down
				var mouse_position = get_viewport().get_mouse_position()
				var board_pos = local_to_grid(world_to_local(mouse_position))
				if board_pos == start_point:
					mouse_down = true
					select(startpoint_graphic)
					startpoint_selected.emit()
					select_board.emit()
				elif pos_in_bounds(board_pos) && map[coord_to_map_index(board_pos)] != 0:
					var target_pentomino = scan_board(board_pos)
					if target_pentomino != null:
						mouse_down = true
						select(target_pentomino)
						piece_position = target_pentomino.center_pos
						select_board.emit()
						remove(target_pentomino)
	
	elif event is InputEventMouseMotion: # Mouse Movement Block
		if selected != null: # Actions when you have something in hand
			if dragging: # Drag Object
				selected.position = world_to_local(event.position)
			else: # Ghost on Grid
				var board_pos = local_to_grid(world_to_local(event.position))
				if pos_in_bounds(board_pos):
					piece_position = board_pos
					update_held_position()
	
	elif event is InputEventMouseButton: # Mouse Button Release Block
		match event.button_index:
			MOUSE_BUTTON_LEFT: # Left click for Selection
				piece_release.emit() # Godot is only emitting IEMB on mouse release
				if mouse_down: # Catching board selection
					mouse_down = false
				else:
					if selected != null: # Actions when you have something in hand
						if dragging: # Drop Selected
							selected.position = event.position
							dragging = false
							if selected is Pentomino:
								place_pentomino(selected, world_to_local(selected.position))
							elif selected == startpoint_graphic:
								place_startpoint(world_to_local(event.position))
						else: # Click and Place
							if selected is Pentomino:
								place_pentomino(selected, world_to_local(event.position))
							elif selected == startpoint_graphic:
								place_startpoint(world_to_local(event.position))
			MOUSE_BUTTON_RIGHT: # Right click just drops
				deselect_selected()

func try_place(pentomino: Pentomino, pos: Vector2i) -> bool:
	for piece_cell in pentomino.cells:
		if !pos_in_bounds(piece_cell + pos) || start_point == piece_cell + pos:
			return false
		var test_index = coord_to_map_index(piece_cell + pos)
		if map[test_index] != 0:
			return false
	place(pentomino, pos)
	return true

func place(pentomino: Pentomino, pos: Vector2i):
	pentomino.center_pos = pos
	board_pentominos.append(pentomino)
	for piece_cell in pentomino.cells:
		map[coord_to_map_index(piece_cell + pos)] = -1
	piece_placed.emit(pentomino.pentomino_name)

func place_pentomino(pentomino: Pentomino, pos: Vector2):
	var board_pos = local_to_grid(pos)
	if pos_in_bounds(board_pos):
		piece_position = board_pos
		update_held_position()
		if try_place(pentomino, board_pos):
			place_selected(board_pos * 32)
			deselect()

func place_startpoint(pos: Vector2):
	var board_pos = local_to_grid(pos)
	if pos_in_bounds(board_pos):
		piece_position = board_pos
		update_held_position()
		if map[coord_to_map_index(board_pos)] == 0:
			start_point = board_pos
			place_selected(board_pos * 32)
			deselect()

func remove(pentomino: Pentomino):
	board_pentominos.erase(pentomino)
	for piece_cell in pentomino.cells:
		map[coord_to_map_index(piece_cell + pentomino.center_pos)] = 0
	piece_removed.emit(pentomino.pentomino_name)
	if board_pentominos.is_empty():
		board_clear.emit()

func score_board() -> int:
	if start_point < Vector2i.ZERO:
		return 0
	lock = true
	if text_child != null:
		clear_score()
	text_child = Control.new()
	text_child.theme = text_theme
	text_child.position = Vector2(-14, -12)
	add_child(text_child)
	map[coord_to_map_index(start_point)] = 1000
	var score = 1
	var current_cells = [start_point]
	var next_cells = []
	while (!current_cells.is_empty()):
		for cell in current_cells:
			for dir in cardinals:
				if pos_in_bounds(cell + dir):
					if map[coord_to_map_index(cell + dir)] == 0:
						var score_display = Label.new()
						score_display.text = "%d" % score
						score_display.position = (cell + dir) * 32
						score_display.size = Vector2(30, 30)
						score_display.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
						score_display.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
						text_child.add_child(score_display)
						map[coord_to_map_index(cell + dir)] = score
						next_cells.append(cell + dir)
		current_cells.clear()
		current_cells.append_array(next_cells)
		if !next_cells.is_empty():
			score += 1
			next_cells.clear()
	lock = false
	return score - 1

func clear_score():
	text_child.free()
	for i in range(grid_size.x * grid_size.y):
		if map[i] > 0:
			map[i] = 0

func move_selected(dir: Vector2i):
	if !dragging && selected != null:
		if piece_position == null:
			piece_position = entrace_map[dir]
		else:
			piece_position = (piece_position + dir).clamp(Vector2i.ZERO, grid_size)
		update_held_position()

func update_held_position():
	if selected != null:
		selected.position = piece_position * 32

func place_selected(pos: Vector2i):
	selected.position = pos
	selected.modulate.a = 1.0

func select(object: Node2D):
	if text_child != null:
		clear_score()
	if selected is Pentomino:
		selected.free()
	if selected == startpoint_graphic:
		remove_child(startpoint_graphic)
		start_point = Vector2i(-1, -1)
	object.modulate.a = .50
	selected = object
	if !object.is_inside_tree():
		add_child(object)

func deselect():
	selected = null
	piece_position = null
	dragging = false

func deselect_selected():
	if selected is Pentomino:
		selected.free()
	if selected == startpoint_graphic:
		remove_child(startpoint_graphic)
		start_point = Vector2i(-1, -1)
	deselect()

func scan_board(pos: Vector2i):
	for pentomino in board_pentominos:
		for cell in pentomino.cells:
			if pos == cell + pentomino.center_pos:
				return pentomino
	return null

func update_texture(texture: Texture2D):
	for pentomino in board_pentominos:
		pentomino.set_texture(texture)

func coord_to_map_index(coord: Vector2i) -> int:
	return (coord.y * grid_size.x) + coord.x

func map_index_to_coord(index: int) -> Vector2i:
	return Vector2i(index % grid_size.x, index / grid_size.x)

func pos_in_bounds(coord: Vector2i) -> bool:
	return coord.clamp(Vector2i.ZERO, grid_size - Vector2i.ONE) == coord

static func local_to_grid(local: Vector2) -> Vector2i:
	return Vector2i(
		(round(local.x) + 16) / 32,
		(round(local.y) + 16) / 32
	)

func world_to_local(world: Vector2) -> Vector2:
	return world - position - container_position
