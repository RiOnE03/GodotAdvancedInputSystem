extends "res://addons/GodotAdvancedInputSystem/InputProvider/Base Classes/InputProvider.gd"

const InputMetadataKeyboard := preload("res://addons/GodotAdvancedInputSystem/InputProvider/Keyboard/KeyboardMetadata.gd")


var _dummy_stealer: Key

var dict: Dictionary[int, String] = {}

var exclude : Array[Key] = [KEY_NONE, KEY_SPECIAL]


func _init()->void:
	var hint_string = ""
	
	# 1. Ask ourselves for our own properties
	for prop in self.get_property_list():
		if prop["name"] == "_dummy_stealer":
			hint_string = prop["hint_string"]
			break
			
	for item in hint_string.split(","):
		if item.is_empty(): continue
		
		var parts = item.split(":")
		if parts.size() < 2: continue
		
		var input_id: int = parts[1].to_int()
		
		if exclude.has(input_id): continue
		
		dict[input_id] = parts[0].trim_prefix("Key ")



func get_category_name() -> String:
	return "Keyboard"



func get_input_list() -> Array[String]:
	return dict.values()



func get_input_name(Event:InputEvent, variant_type: variant = variant.DEFAULT)->String:
	if not (Event is InputEventKey):
		return ""
	
	match variant_type:
		variant.FLOAT, variant.VECTOR:
			return ""

	var input : InputEventKey = Event
	if dict.has(input.physical_keycode):
		return dict[input.physical_keycode]
	return ""


func generate_metadata_from_input(Event: InputEvent, variant_type: variant = variant.DEFAULT) -> InputMetadata:
	if not (Event is InputEventKey):
		return null
	
	match variant_type:
		variant.FLOAT, variant.VECTOR:
			print("Error 1")
			return null

	var input: InputEventKey = Event
	if not dict.has(input.keycode):
		return null
	
	var Name: String = dict[input.keycode]
	return InputMetadataKeyboard.new(Name,get_category_name(), input.physical_keycode)


func generate_metadata_from_name(Name: String) -> InputMetadata:
	var key: Variant = dict.find_key(Name)
	if key!=null:
		var button_index: Key = key
		return InputMetadataKeyboard.new(Name,get_category_name(), button_index)
	return null
