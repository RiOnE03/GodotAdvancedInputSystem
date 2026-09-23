extends InputMetadata

@export_storage var button_index : MouseButton

func _init(InName: String = "",InCategory:String = "", InButton: MouseButton = 0)->void:
	InputName = InName
	CategoryName = InCategory
	button_index = InButton

func is_same_metadata(metadata: InputMetadata)->bool:
	if  metadata and metadata.CategoryName == CategoryName:
		return metadata.button_index == button_index
	return false

func is_input_relevant(Event : InputEvent)->bool:
	if Event is InputEventMouseButton:
		var input: InputEventMouseButton = Event
		if input.button_index == button_index:
			return true
		var is_wheel: bool = input.button_index >= 4 and input.button_index <=7
		match button_index:
			-1:
				if is_wheel:
					return input.button_index == MOUSE_BUTTON_WHEEL_LEFT or input.button_index == MOUSE_BUTTON_WHEEL_RIGHT
			-2:
				if is_wheel:
					return input.button_index == MOUSE_BUTTON_WHEEL_UP or input.button_index == MOUSE_BUTTON_WHEEL_DOWN
			-4:
				return is_wheel
	return false

func extract_raw_value(Event : InputEvent)->Vector2:
	var output: int = Event.is_pressed() and not Event.is_canceled()
	
	if not output:
		return Vector2.ZERO
	
	if Event.button_index == button_index:
		return Vector2(output, 0)
	
	var result: Vector2 = Vector2.ZERO
	
	match Event.button_index:
		MOUSE_BUTTON_WHEEL_RIGHT:
			result.x += 1
		MOUSE_BUTTON_WHEEL_LEFT:
			result.x -= 1
		MOUSE_BUTTON_WHEEL_DOWN:
			result.y +=1
		MOUSE_BUTTON_WHEEL_UP:
			result.y -=1
	
	match button_index:
		-2:
			return Vector2(result.x, 0)
		-3:
			return Vector2(result.y, 0)
		-4:
			return result
	
	return result

func capture_with_context(Event : InputEvent)->bool:
	return true
