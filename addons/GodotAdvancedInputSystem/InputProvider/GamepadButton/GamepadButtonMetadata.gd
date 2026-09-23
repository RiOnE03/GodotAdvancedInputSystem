extends InputMetadata

@export_storage var button_index: JoyButton

func _init( InName: String = "",InCategory:String = "", InIndex: JoyButton = 0)->void:
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
		if input.button_index == button_index:
			return true
		var is_dpad: bool = input.button_index >= 11 and input.button_index <=14
		match button_index:
			-2:
				if is_dpad:
					return input.button_index == JOY_BUTTON_DPAD_LEFT or input.button_index == JOY_BUTTON_DPAD_RIGHT
			-3:
				if is_dpad:
					return input.button_index == JOY_BUTTON_DPAD_UP or input.button_index == JOY_BUTTON_DPAD_DOWN
			-4:
				return is_dpad
	return false

func extract_raw_value(Event : InputEvent)->Vector2:
	var output: int = Event.is_pressed() and not Event.is_canceled()
	
	if not output:
		return Vector2.ZERO
	
	if Event.button_index == button_index:
		return Vector2(output, 0)
	
	var result: Vector2 = Vector2.ZERO
	
	match Event.button_index:
		JOY_BUTTON_DPAD_RIGHT:
			result.x = 1
		JOY_BUTTON_DPAD_LEFT:
			result.x = -1
		JOY_BUTTON_DPAD_DOWN:
			result.y = 1
		JOY_BUTTON_DPAD_UP:
			result.y = -1
	
	match button_index:
		-2:
			return Vector2(result.x, 0)
		-3:
			return Vector2(result.y, 0)
		-4:
			return result
	
	return result
