extends Control

@export var background_png_path: String = ""
@export var allow_back_to_start: bool = true
@export var start_scene_path: String = "res://scenes/StartScreen.tscn"

func _ready() -> void:
	# Crear TextureRect a pantalla completa para mostrar la imagen del minijuego
	if not has_node("Background"):
		var bg := TextureRect.new()
		bg.name = "Background"
		bg.anchors_preset = Control.PRESET_FULL_RECT
		bg.grow_horizontal = Control.GROW_DIRECTION_BOTH
		bg.grow_vertical = Control.GROW_DIRECTION_BOTH
		bg.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
		add_child(bg)
	_load_background()
	set_process_input(true)

func _load_background() -> void:
	var bg := $Background as TextureRect
	if background_png_path == "":
		return
	var tex := load(background_png_path)
	if tex:
		bg.texture = tex

func _input(event: InputEvent) -> void:
	if not allow_back_to_start:
		return
	if event is InputEventKey and event.pressed:
		if event.keycode == KEY_ESCAPE or event.keycode == KEY_BACKSPACE:
			var ml := Engine.get_main_loop()
			if ml and ml is SceneTree:
				(ml as SceneTree).change_scene_to_file(start_scene_path)

