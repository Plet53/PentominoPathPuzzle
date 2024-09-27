class_name Pentomino

extends Node2D

var cells: Array[Vector2i] = [Vector2i(0,0)]
var center_pos: Vector2i
var pentomino_name: String
const backing_texture := preload("res://assets/cell_bg.png")

func _ready() -> void:
	texture_filter = TextureFilter.TEXTURE_FILTER_NEAREST

func copy() -> Pentomino:
	var dupe = self.duplicate()
	dupe.cells = cells.duplicate()
	dupe.pentomino_name = pentomino_name
	return dupe

func setup_cells():
	for pos in cells:
		var backing = Sprite2D.new()
		backing.texture = backing_texture
		backing.position = pos * 32
		var texture_sprite = Sprite2D.new()
		texture_sprite.scale *= 2
		backing.add_child(texture_sprite)
		add_child(backing)

func move_cells():
	for i in cells.size():
		var cell = get_child(i)
		cell.position = cells[i] * 32

func set_texture(texture: Texture2D):
	for cell in get_children():
		var cell_sprite = cell.get_child(0)
		cell_sprite.texture = texture

func rotate_piece(left = true):
	var new_cells
	if left:
		new_cells = cells.map(
			func(cell):
				return Vector2i(cell.y, cell.x * -1)
		)
	else:
		new_cells = cells.map(
			func(cell):
				return Vector2i(cell.y * -1, cell.x)
		)
	cells.clear()
	cells.append_array(new_cells)
	move_cells()

func flip_piece(y_axis = true):
	var new_cells
	if y_axis:
		new_cells = cells.map(
			func(cell):
				return cell * Vector2i(-1, 1)
		)
	else:
		new_cells = cells.map(
			func(cell):
				return cell * Vector2i(1, -1)
		)
	cells.clear()
	cells.append_array(new_cells)
	move_cells()
