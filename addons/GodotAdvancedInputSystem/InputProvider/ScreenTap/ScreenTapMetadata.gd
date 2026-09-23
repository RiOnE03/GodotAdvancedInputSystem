extends InputMetadata


@export_storage var index: int

func _init(InName: String = "", InCategory: String = "", InIndex: int = 0)->void:
	InputName = InName
	CategoryName = InCategory
	index = InIndex

func is_input_relevant(Event : InputEvent)->bool:
	if Event is InputEventScreenTouch:
		if index <= 1:
			return index == Event.index
		return true
	return false

func is_same_metadata(metadata: InputMetadata)->bool:
	if  metadata and metadata.CategoryName == CategoryName:
		return metadata.index == index
	return false

func extract_raw_value(Event : InputEvent)->Vector2:
	var input: InputEventScreenTouch = Event
	return Vector2(input.is_pressed() and not input.is_canceled() , 0)

func capture_with_context(Event : InputEvent)->bool:
	return true
