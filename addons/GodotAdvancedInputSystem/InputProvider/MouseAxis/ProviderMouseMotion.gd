extends "res://addons/GodotAdvancedInputSystem/InputProvider/Base Classes/InputProvider.gd"


const InputMetadataMouseAxis:= preload("res://addons/GodotAdvancedInputSystem/InputProvider/MouseAxis/MouseAxisMetadata.gd")


func get_category_name() -> String:
	return "Mouse Axis"


func get_input_list() -> Array[String]:
	return ["Mouse Motion"]


func get_input_name(Event:InputEvent, variant_type: variant = variant.DEFAULT)->String:
	match variant_type:
		variant.BOOLEAN, variant.FLOAT:
			return ""
	if Event is InputEventMouseMotion:
		return "Mouse Motion"
	return ""


func generate_metadata_from_input(Event: InputEvent, variant_type: variant = variant.DEFAULT) -> InputMetadata:
	match variant_type:
		variant.BOOLEAN, variant.FLOAT:
			return null
	if Event is InputEventMouseMotion:
		return InputMetadataMouseAxis.new("Mouse Motion",get_category_name())
	return null


func generate_metadata_from_name(Name: String) -> InputMetadata:
	if Name == "Mouse Motion":
		return InputMetadataMouseAxis.new(Name,get_category_name())
	return null
