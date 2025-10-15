extends VideoStreamPlayer

@export var intro_video_path: String = "res://assets/cinematicas/intro1.ogv"
@export var allow_skip: bool = true
@export var next_scene_path: String = "res://scenes/StartScreen.tscn"

func _ready() -> void:
	if intro_video_path != "":
		stream = load(intro_video_path)
	if autoplay and stream:
		play()
	set_process_input(true)
	if has_signal("finished"):
		finished.connect(_on_finished)

func _on_finished() -> void:
	if next_scene_path == "":
		return
	# Asegura que el cambio ocurra cuando el nodo ya esté dentro del árbol
	call_deferred("_do_change_scene")

func _do_change_scene() -> void:
	var tree := get_tree()
	if tree:
		tree.change_scene_to_file(next_scene_path)

func _input(event: InputEvent) -> void:
	if not allow_skip:
		return
	if event is InputEventKey and event.pressed:
		_on_finished()
	elif event is InputEventMouseButton and event.pressed:
		_on_finished()

func _process(_delta: float) -> void:
	if stream and not is_playing():
		_on_finished()
