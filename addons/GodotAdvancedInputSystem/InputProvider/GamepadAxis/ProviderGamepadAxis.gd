extends "res://addons/GodotAdvancedInputSystem/InputProvider/Base Classes/InputProvider.gd"


var dict: Dictionary[String, int] = {
	"Left Stick Up"             : -2,
	"Left Stick Down"           : -3,
	"Left Stick Left"           : -4,
	"Left Stick Right"          : -5,
	"Left Stick Horizontal"     : JOY_AXIS_LEFT_X,
	"Left Stick Vertical"       : JOY_AXIS_LEFT_Y,
	"Left Stick XY"             : -6,
	
	"Right Stick Up"             : -7,
	"Right Stick Down"           : -8,
	"Right Stick Left"           : -9,
	"Right Stick Right"          : -10,
	"Right Stick Horizontal"     : JOY_AXIS_RIGHT_X,
	"Right Stick Vertical"       : JOY_AXIS_RIGHT_Y,
	"Right Stick XY"             : -11,
	
	"Left Trigger (LT / L2)"     : JOY_AXIS_TRIGGER_LEFT,
	"Right Trigger (RT / R2)"    : JOY_AXIS_TRIGGER_RIGHT
}

const InputMetadataGamepadAxis:= preload("res://addons/GodotAdvancedInputSystem/InputProvider/GamepadAxis/GamepadAxisMetadata.gd") 




func get_category_name() -> String:
	return "Gamepad Axis"


func get_input_list() -> Array[String]:
	return dict.keys()


func get_input_name(Event:InputEvent, variant_type: variant = variant.DEFAULT)->String:
	if not (Event is InputEventJoypadMotion):
		return ""
	var input : InputEventJoypadMotion = Event
	
	match variant_type:
		variant.DEFAULT, variant.BOOLEAN:
			match input.axis:
				JOY_AXIS_TRIGGER_LEFT:
					return dict.find_key(JOY_AXIS_TRIGGER_LEFT)
				JOY_AXIS_TRIGGER_RIGHT:
					return dict.find_key(JOY_AXIS_TRIGGER_RIGHT)
		variant.VECTOR, variant.FLOAT:
			match input.axis:
				JOY_AXIS_TRIGGER_LEFT, JOY_AXIS_TRIGGER_RIGHT:
					return ""
	
	match variant_type:
		variant.BOOLEAN:
			match input.axis:
				JOY_AXIS_LEFT_X:
					return dict.find_key(-5 if input.axis_value>0 else -4)
				JOY_AXIS_LEFT_Y:
					return dict.find_key(-3 if input.axis_value>0 else -2)
				JOY_AXIS_RIGHT_X:
					return dict.find_key(-10 if input.axis_value>0 else -9)
				JOY_AXIS_RIGHT_Y:
					return dict.find_key(-8 if input.axis_value>0 else -7)
		variant.FLOAT:
			return dict.find_key(input.axis)
		variant.VECTOR, variant.DEFAULT: # this defines that the default input in the input selector UI would give whole stick(XY 2D)
			match input.axis:
				JOY_AXIS_LEFT_X,JOY_AXIS_LEFT_Y:
					return dict.find_key(-6)
				JOY_AXIS_RIGHT_X, JOY_AXIS_RIGHT_Y:
					return dict.find_key(-11)
	
	return ""


func generate_metadata_from_input(Event: InputEvent, variant_type: variant = variant.DEFAULT) -> InputMetadata:
	
	if not (Event is InputEventJoypadMotion):
		return null
	
	var input : InputEventJoypadMotion = Event
	
	var index: int = -1
	
	match variant_type:
		variant.DEFAULT, variant.BOOLEAN:
			match input.axis:
				JOY_AXIS_TRIGGER_LEFT:
					index = JOY_AXIS_TRIGGER_LEFT
				JOY_AXIS_TRIGGER_RIGHT:
					index = JOY_AXIS_TRIGGER_RIGHT
		variant.FLOAT, variant.VECTOR:
			match input.axis:
				JOY_AXIS_TRIGGER_LEFT, JOY_AXIS_TRIGGER_RIGHT:
					return null
	
	if index != -1:
		return InputMetadataGamepadAxis.new(dict.find_key(index),get_category_name(), index)
	
	match variant_type:
		variant.BOOLEAN:
			match input.axis:
				JOY_AXIS_LEFT_X:
					index = -5 if input.axis_value>0 else -4
				JOY_AXIS_LEFT_Y:
					index = -3 if input.axis_value>0 else -2
				JOY_AXIS_RIGHT_X:
					index = -10 if input.axis_value>0 else -9
				JOY_AXIS_RIGHT_Y:
					index = -8 if input.axis_value>0 else -7
		variant.FLOAT:
			index = input.axis
		variant.VECTOR, variant.DEFAULT: # this defines that the default input in the input selector UI would give whole stick(XY 2D)
			match input.axis:
				JOY_AXIS_LEFT_X,JOY_AXIS_LEFT_Y:
					index = -6
				JOY_AXIS_RIGHT_X, JOY_AXIS_RIGHT_Y:
					index = -11
	
	return InputMetadataGamepadAxis.new(dict.find_key(index),get_category_name(), index)



func generate_metadata_from_name(Name: String) -> InputMetadata:
	if dict.has(Name):
		var axis: int = dict[Name]
		return InputMetadataGamepadAxis.new(Name,get_category_name(), axis)
	return null
