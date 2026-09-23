extends InputMetadata

@export_storage var physical_keycode : Key

func _init(InName: String = "",InCategory:String = "", InKey : Key = 0)->void:
	InputName = InName
	CategoryName = InCategory
	physical_keycode = InKey

func is_same_metadata(metadata: InputMetadata)->bool:
	if  metadata and metadata.CategoryName == CategoryName:
		return metadata.physical_keycode == physical_keycode
	return false

func is_input_relevant(Event : InputEvent)->bool:
	if Event is InputEventKey:
		var input: InputEventKey = Event
		return input.physical_keycode == physical_keycode
	return false

func extract_raw_value(Event : InputEvent)->Vector2:
	return Vector2(Event.is_pressed() and not Event.is_canceled(),0)

func capture_with_context(Event : InputEvent)->bool:
	return true
