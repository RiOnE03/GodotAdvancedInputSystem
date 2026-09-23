extends InputMetadata

@export_storage var axis : int

func _init(InName: String = "",InCategory:String = "", InAxis: int = 0)->void:
	InputName = InName
	CategoryName = InCategory
	axis = InAxis

func is_input_relevant(Event : InputEvent)->bool:
	if Event is InputEventJoypadMotion:
		if Event.axis == axis:
			return true
		if Event.axis == JOY_AXIS_LEFT_X or Event.axis == JOY_AXIS_LEFT_Y:
			return axis<=-2 and axis >= -6
		if Event.axis == JOY_AXIS_RIGHT_X or Event.axis == JOY_AXIS_RIGHT_Y:
			return axis<=-7 and axis>=-11
	return false

func is_same_metadata(metadata: InputMetadata)->bool:
	if metadata and metadata.CategoryName == CategoryName:
		return metadata.axis == axis
	return false

func extract_raw_value(Event : InputEvent)->Vector2:
	var input : InputEventJoypadMotion = Event
	if input.axis == JOY_AXIS_LEFT_X:
		match axis:
			-4: # Left stick left
				return Vector2(-clampf(input.axis_value,-1,0) , 0 )
			-5: # Left stick right
				return Vector2(clampf(input.axis_value,0,1) , 0 )
			JOY_AXIS_LEFT_X, -6: # left X axis and left stick XY 2D
				return Vector2( input.axis_value , 0 )
	elif input.axis == JOY_AXIS_LEFT_Y:
		match axis:
			-2: # Left stick Up
				return Vector2(-clampf(input.axis_value,-1,0) ,  0)
			-3: # Left stick Down
				return Vector2(clampf(input.axis_value,0,1) , 0 )
			JOY_AXIS_LEFT_Y: # left Y axis
				return Vector2(input.axis_value, 0)
			-6: # left stick XY 2D
				return Vector2(0 , input.axis_value)
	elif input.axis == JOY_AXIS_RIGHT_X:
		match axis:
			-9: # Right Stick Left
				return Vector2(-clampf(input.axis_value,-1,0) , 0 )
			-10: # Right stick right
				return Vector2(clampf(input.axis_value,0,1) , 0 )
			JOY_AXIS_RIGHT_X, -11: # Right X axis and Right stick XY 2D
				return Vector2( input.axis_value , 0 )
	elif input.axis == JOY_AXIS_RIGHT_Y:
		match axis:
			-7: # Right stick Up
				return Vector2(-clampf(input.axis_value,-1,0) , 0 )
			-8: # Right stick Down
				return Vector2(clampf(input.axis_value,0,1) , 0 )
			JOY_AXIS_RIGHT_Y: # Right Y axis
				return Vector2(input.axis_value, 0)
			-11: # Right stick XY 2D
				return Vector2(0 , input.axis_value)
	elif input.axis == axis: # Shoulder Triggers
		return Vector2( input.axis_value , 0 )
	return Vector2.ZERO
