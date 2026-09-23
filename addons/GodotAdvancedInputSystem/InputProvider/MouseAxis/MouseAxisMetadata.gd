extends InputMetadata



func _init(InName: String = "",InCategory:String = "") -> void:
	InputName = InName
	CategoryName = InCategory


func is_same_metadata(metadata: InputMetadata)->bool:
	return metadata and metadata.CategoryName == CategoryName

func is_input_relevant(Event: InputEvent) -> bool:
	return Event is InputEventMouseMotion

func extract_raw_value(Event: InputEvent) -> Vector2:
	return Event.relative


func capture_with_context(Event: InputEvent) -> bool:
	return true
