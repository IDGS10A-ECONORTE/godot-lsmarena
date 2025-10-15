extends VideoStreamPlayer

# Compatibilidad: si se define, se usará como primer video cuando no haya lista.
@export var intro_video_path: String = "res://assets/cinematicas/intro1.ogv"
# Lista de videos a reproducir en secuencia (2 intros por defecto)
@export var video_paths: Array[String] = [
	"res://assets/cinematicas/godot.ogv",
	"res://assets/cinematicas/intro1.ogv"
]
@export var allow_skip: bool = true
@export var next_scene_path: String = "res://scenes/StartScreen.tscn"

var current_index: int = 0

func _ready() -> void:
	if video_paths.is_empty() and intro_video_path != "":
		video_paths = [intro_video_path]
	set_process_input(true)
	if has_signal("finished"):
		finished.connect(_on_finished)
	_play_current()

func _play_current() -> void:
	if current_index >= video_paths.size():
		_go_to_next_scene()
		return
	var path := video_paths[current_index]
	var next_stream := load(path) if path != "" else null
	stream = next_stream
	if autoplay and stream:
		play()

func _on_finished() -> void:
	current_index += 1
	_play_current()

func _go_to_next_scene() -> void:
	if next_scene_path == "":
		return
	# Asegura que el cambio ocurra cuando el nodo ya esté dentro del árbol
	call_deferred("_do_change_scene")

func _do_change_scene() -> void:
	var ml := Engine.get_main_loop()
	if ml and ml is SceneTree:
		(ml as SceneTree).change_scene_to_file(next_scene_path)

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
