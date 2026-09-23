extends InputMetadata

@export_storage var button_index: JoyButton

func _init( InName: String = "",InCategory: String = "", InIndex: JoyButton = 0)->void:
	InputName = InName
	CategoryName = InCategory
	button_index = InIndex

func is_same_metadata(metadata: InputMetadata)->bool:
	if  metadata and metadata.CategoryName == CategoryName:
		return metadata.button_index == button_index
	return false

func is_input_relevant(Event : InputEvent)->bool:
	if Event is InputEventJoypadButton:
		var input: InputEventJoypadButton = Event
		return input.button_index == button_index
	return false

func extract_raw_value(Event : InputEvent)->Vector2:
	return Vector2(Event.is_pressed() and not Event.is_canceled(),0)
