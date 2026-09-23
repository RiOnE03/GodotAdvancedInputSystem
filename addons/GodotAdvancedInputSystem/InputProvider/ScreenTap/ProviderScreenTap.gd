extends "res://addons/GodotAdvancedInputSystem/InputProvider/Base Classes/InputProvider.gd"

const InputMetadataScreenTap:= preload("res://addons/GodotAdvancedInputSystem/InputProvider/ScreenTap/ScreenTapMetadata.gd") 


var list: Array[String] = [
	"Single Touch",
	"Double Touch",
	"Any Touch"
]

func get_category_name() -> String:
	return "Screen Touch"


func get_input_list() -> Array[String]:
	return list


func get_input_name(Event:InputEvent, variant_type: variant = variant.DEFAULT)->String:
	match variant_type:
		variant.FLOAT, variant.VECTOR:
			return ""
	
	if Event is InputEventScreenTouch:
		var touch:int = clampi(Event.index-1,0,2)
		return list[touch]
	return ""



func generate_metadata_from_input(Event: InputEvent, variant_type: variant = variant.DEFAULT) -> InputMetadata:
	match variant_type:
		variant.FLOAT, variant.VECTOR:
			return null
	
	if Event is InputEventScreenTouch:
		var touch:int = clampi(Event.index-1,0,2)
		return InputMetadataScreenTap.new(list[touch],get_category_name(), touch)
	return null


func generate_metadata_from_name(Name: String) -> InputMetadata:
	var index:= list.find(Name)
	if index>-1:
		return InputMetadataScreenTap.new(Name, get_category_name(), index)
	return null
