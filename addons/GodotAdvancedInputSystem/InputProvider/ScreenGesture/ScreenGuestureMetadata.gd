extends InputMetadata

@export_storage var input_id : int

func _init(InName: String = "",InCategory:String = "", InValue:int = 0)->void:
	InputName = InName
	CategoryName = InCategory
	input_id = InValue

func is_same_metadata(metadata: InputMetadata)->bool:
	if  metadata and metadata.CategoryName == CategoryName:
		return metadata.input_id == input_id
	return false

func is_input_relevant(Event : InputEvent)->bool:
	if Event is InputEventPanGesture:
		return input_id == 0
	elif Event is InputEventMagnifyGesture:
		return input_id == 1
	elif Event is InputEventScreenDrag:
		return input_id == 2
	return false

func extract_raw_value(Event : InputEvent)->Vector2:
	if Event is InputEventPanGesture:
		return Event.delta
	elif Event is InputEventMagnifyGesture:
		return Vector2(Event.factor,0)
	elif Event is InputEventScreenDrag:
		return Event.relative
	return Vector2.ZERO

func capture_with_context(Event : InputEvent)->bool:
	return Event is InputEventScreenDrag
