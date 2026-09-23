extends "res://addons/GodotAdvancedInputSystem/InputProvider/Base Classes/InputProvider.gd"



const InputMetadataGamepadButton := preload("res://addons/GodotAdvancedInputSystem/InputProvider/GamepadButton/GamepadButtonMetadata.gd") 



var _dummy_stealer: JoyButton


var dict : Dictionary[int, String] = {
	JOY_BUTTON_DPAD_UP : "D-pad Up",
	JOY_BUTTON_DPAD_DOWN : "D-pad Down",
	JOY_BUTTON_DPAD_LEFT : "D-pad Left",
	JOY_BUTTON_DPAD_RIGHT : "D-pad Right",
	-2 : "D-pad Horizontal",
	-3 : "D-pad Vertical",
	-4 : "D-pad XY",
	JOY_BUTTON_A : "Button Bottom",
	JOY_BUTTON_B : "Button Right",
	JOY_BUTTON_X : "Button Left",
	JOY_BUTTON_Y : "Button Top",
	JOY_BUTTON_BACK : "Back / Select / -",
	JOY_BUTTON_START : "Start / Menu / +",
	JOY_BUTTON_GUIDE : "Guide / PS / Home",
	JOY_BUTTON_LEFT_STICK : "Left Stick Click (L3)",
	JOY_BUTTON_RIGHT_STICK : "Right Stick Click (R3)",
	JOY_BUTTON_LEFT_SHOULDER : "Left Bumper (LB / L1)",
	JOY_BUTTON_RIGHT_SHOULDER : "Right Bumper (RB / R1)"
}


func get_category_name() -> String:
	return "Gamepad Button"


func get_input_list() -> Array[String]:
	return dict.values()



func get_input_name(Event:InputEvent, variant_type: variant = variant.DEFAULT)->String:
	
	if not (Event is InputEventJoypadButton):
		return ""
	
	var input : InputEventJoypadButton = Event
	
	var is_dpad: bool = input.button_index >= 11 and input.button_index <=14
	
	match variant_type:
		variant.FLOAT:
			if is_dpad:
				var x_axis: bool = input.button_index == JOY_BUTTON_DPAD_LEFT or input.button_index == JOY_BUTTON_DPAD_RIGHT
				return dict[-2 if x_axis else -3]
				pass
			return ""
		variant.VECTOR:
			if is_dpad:
				return dict[-4]
			return ""
	
	if dict.has(input.button_index):
		return dict[input.button_index]
	return ""


func generate_metadata_from_input(Event: InputEvent, variant_type: variant = variant.DEFAULT) -> InputMetadata:
	
	if not (Event is InputEventJoypadButton):
		return null
	
	var input: InputEventJoypadButton = Event
	
	var is_dpad: bool = input.button_index >= 11 and input.button_index <=14
	
	match variant_type:
		variant.FLOAT:
			if is_dpad:
				var x_axis: bool = input.button_index == JOY_BUTTON_DPAD_LEFT or input.button_index == JOY_BUTTON_DPAD_RIGHT
				var index: int =  -2 if x_axis else -3
				return InputMetadataGamepadButton.new(dict[index],get_category_name(), index)
			return null
		variant.VECTOR:
			if is_dpad:
				return InputMetadataGamepadButton.new(dict[-4],get_category_name(), -4)
			return null
	
	if not dict.has(input.button_index):
		return null
	
	var Name: String = dict[input.button_index]
	return InputMetadataGamepadButton.new(Name,get_category_name(), input.button_index)



func generate_metadata_from_name(Name: String) -> InputMetadata:
	var key: Variant = dict.find_key(Name)
	if key!=null:
		var button_index: JoyButton = key
		return InputMetadataGamepadButton.new(Name,get_category_name(), button_index)
	return null
