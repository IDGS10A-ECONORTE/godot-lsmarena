extends CanvasLayer

func set_camera_texture(tex: Texture2D) -> void:
	var rect := $Root/Panel/Texture as TextureRect
	rect.texture = tex

func set_viewport_texture(tex: Texture2D) -> void:
	var rect := $Root/Panel/Texture as TextureRect
	rect.texture = tex

func set_status(text: String) -> void:
	var lbl := $Root/Panel/Label as Label
	if lbl:
		lbl.text = text

