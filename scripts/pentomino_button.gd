class_name PentominoButton

extends Button

signal select(pentomino_name)
signal release

var pentomino: Pentomino

func _ready() -> void:
	custom_minimum_size = Vector2i.ONE * 160
	button_down.connect(on_down)
	button_up.connect(on_up)

func on_down():
	select.emit(pentomino.name)

func on_up():
	release.emit()
