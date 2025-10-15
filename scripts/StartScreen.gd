extends Control

@export var background_png_path: String = "res://assets/escenas/1.png"

func _ready() -> void:
	var background := $Background as TextureRect
	if background_png_path != "":
		var tex := load(background_png_path)
		if tex:
			background.texture = tex
