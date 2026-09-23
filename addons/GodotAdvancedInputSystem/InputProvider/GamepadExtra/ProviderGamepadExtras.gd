extends "res://addons/GodotAdvancedInputSystem/InputProvider/Base Classes/InputProvider.gd"


const InputMetadataGamepadButtonExtras:=preload("res://addons/GodotAdvancedInputSystem/InputProvider/GamepadExtra/GamepadExtraMetadata.gd") 



var dict: Dictionary[int, String] = {
	JOY_BUTTON_PADDLE1 : "Paddle 1",
	JOY_BUTTON_PADDLE2 : "Paddle 2",
	JOY_BUTTON_PADDLE3 : "Paddle 3",
	JOY_BUTTON_PADDLE4 : "Paddle 4",
	JOY_BUTTON_TOUCHPAD : "TouchPad",
	JOY_BUTTON_MISC1 : "Misc 1",
	JOY_BUTTON_MISC2 : "Misc 2",
	JOY_BUTTON_MISC3 : "Misc 3",
	JOY_BUTTON_MISC4 : "Misc 4",
	JOY_BUTTON_MISC5 : "Misc 5",
	JOY_BUTTON_MISC6 : "Misc 6"
}

func get_category_name() -> String:
	return "Gamepad Extra"


func get_input_list() -> Array[String]:
	return dict.values()

func get_input_name(Event:InputEvent, variant_type: variant = variant.DEFAULT)->String:
	
	if not (Event is InputEventJoypadButton):
		return ""
	
	match variant_type:
		variant.FLOAT, variant.VECTOR:
			return ""
	
	var input : InputEventJoypadButton = Event
	if dict.has(input.axis):
		return dict[input.axis]
	return ""


func generate_metadata_from_input(Event: InputEvent, variant_type: variant = variant.DEFAULT) -> InputMetadata:
	if not (Event is InputEventJoypadButton):
		return null
	
	match variant_type:
		variant.FLOAT, variant.VECTOR:
			return null
	
	var input: InputEventJoypadButton = Event
	if not dict.has(input.button_index):
		return null
	
	var Name: String = dict[input.button_index]
	return InputMetadataGamepadButtonExtras.new(Name,get_category_name(), input.button_index)



func generate_metadata_from_name(Name: String) -> InputMetadata:
	var key: Variant = dict.find_key(Name)
	if key!=null:
		var button_index: JoyButton = key
		return InputMetadataGamepadButtonExtras.new(Name,get_category_name(), button_index)
	return null
