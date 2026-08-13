extends Button

@export var asset_type: String = ""


func _get_drag_data(_at_position: Vector2) -> Variant:
	if asset_type.is_empty():
		return null

	var preview := Label.new()
	preview.text = text
	preview.modulate.a = 0.8

	set_drag_preview(preview)

	return {
		"asset_type": asset_type
	}
