extends Node

@export var ws_url: String = "ws://127.0.0.1:7777"
@export var send_interval_seconds: float = 0.1
@export var viewport_size: Vector2i = Vector2i(320, 240)
@export var show_overlay: bool = true
@export var camera_index_primary: int = 0
@export var camera_index_secondary: int = 1
@export var enable_secondary: bool = false

var websocket := WebSocketPeer.new()
var send_timer := Timer.new()

var camera_texture_primary: CameraTexture
var camera_feed_primary: CameraFeed

var capture_viewport: SubViewport
var capture_rect: TextureRect

func _ready() -> void:
	_add_timer()
	_init_websocket()
	_init_camera()
	_init_capture_pipeline()
	if show_overlay:
		_show_overlay_node()
	send_timer.start()

func _add_timer() -> void:
	send_timer.one_shot = false
	send_timer.wait_time = max(0.033, send_interval_seconds)
	add_child(send_timer)
	send_timer.timeout.connect(_on_send_timer_timeout)

func _init_websocket() -> void:
	var err := websocket.connect_to_url(ws_url)
	if err != OK:
		push_warning("WS: fallo connect_to_url -> " + str(err))
	else:
		print("WS: conectando a ", ws_url)
	set_process(true)

func _init_camera() -> void:
	# Asegura que CameraServer está monitoreando
	if not CameraServer.is_monitoring_feeds():
		CameraServer.set_monitoring_feeds(true)
	# Si aún no hay feeds, salir silenciosamente
	if CameraServer.get_feed_count() == 0:
		print("Cam: no hay feeds disponibles")
		return
	camera_feed_primary = CameraServer.get_feed(camera_index_primary)
	if camera_feed_primary:
		camera_feed_primary.set_active(true)
		camera_texture_primary = CameraTexture.new()
		camera_texture_primary.camera_feed_id = camera_feed_primary.get_id()
		print("Cam: feed primario activo id=", camera_feed_primary.get_id())

func _init_capture_pipeline() -> void:
	capture_viewport = SubViewport.new()
	capture_viewport.size = viewport_size
	capture_viewport.disable_3d = true
	capture_viewport.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	add_child(capture_viewport)

	capture_rect = TextureRect.new()
	capture_rect.stretch_mode = TextureRect.STRETCH_SCALE
	capture_rect.anchors_preset = Control.PRESET_FULL_RECT
	if camera_texture_primary:
		capture_rect.texture = camera_texture_primary
	capture_viewport.add_child(capture_rect)

func _show_overlay_node() -> void:
	var overlay_scene := load("res://scenes/ui/WebcamOverlay.tscn")
	if overlay_scene:
		var overlay = overlay_scene.instantiate()
		get_tree().root.call_deferred("add_child", overlay)
		# Preferimos mostrar lo que el SubViewport está renderizando (con escalado aplicado)
		var vp_tex := capture_viewport.get_texture()
		if vp_tex:
			overlay.set_viewport_texture(vp_tex)
			overlay.set_status("Cámara: renderizando SubViewport")
		elif camera_texture_primary:
			overlay.set_camera_texture(camera_texture_primary)
			overlay.set_status("Cámara: textura directa del feed")
		else:
			overlay.set_status("Cámara: sin textura")

func _process(_delta: float) -> void:
	var state := websocket.get_ready_state()
	if state == WebSocketPeer.STATE_CONNECTING or state == WebSocketPeer.STATE_OPEN:
		websocket.poll()
		while websocket.get_available_packet_count() > 0:
			var msg: String = websocket.get_packet_string()
			if msg != "":
				_parse_message(msg)
	elif state == WebSocketPeer.STATE_CLOSING or state == WebSocketPeer.STATE_CLOSED:
		# Opción: reintentar conexión simple
		# print_once para no spamear
		pass

func _on_send_timer_timeout() -> void:
	if websocket.get_ready_state() != WebSocketPeer.STATE_OPEN:
		return
	if not capture_viewport:
		return
	var img := capture_viewport.get_texture().get_image()
	if img.is_empty():
		return
	img.convert(Image.FORMAT_RGB8)
	var bytes := img.save_jpg_to_buffer(0.6)
	if bytes.size() == 0:
		return
	websocket.send(bytes)

func _parse_message(msg: String) -> void:
	var data := {}
	if msg.begins_with("{"):
		data = JSON.parse_string(msg)
	if typeof(data) == TYPE_DICTIONARY and data.has("command"):
		var command: String = data.get("command", "")
		var payload: Dictionary = data.get("payload", {})
		if Engine.has_singleton("GameInput"):
			var gi := Engine.get_singleton("GameInput")
			if gi:
				gi.set_command(command, payload)
