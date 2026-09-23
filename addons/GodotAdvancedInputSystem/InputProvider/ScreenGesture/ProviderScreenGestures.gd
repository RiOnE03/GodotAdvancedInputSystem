extends "res://addons/GodotAdvancedInputSystem/InputProvider/Base Classes/InputProvider.gd"

const InputMetadataScreenGesture:= preload("res://addons/GodotAdvancedInputSystem/InputProvider/ScreenGesture/ScreenGuestureMetadata.gd")

var dict: Dictionary[int, String] = {
	0 : "Pan Gesture",
	1 : "Pinch / Zoom Gesture",
	2 : "Screen Swipe Gesture"
}

func get_category_name() -> String:
	return "Screen Gesture"


func get_input_list() -> Array[String]:
	return dict.values()

func get_input_name(Event:InputEvent, variant_type: variant = variant.DEFAULT)->String:
	if Event is InputEventPanGesture:
		match variant_type:
			variant.BOOLEAN, variant.FLOAT:
				return ""
		return dict[0]
	if Event is InputEventMagnifyGesture:
		if variant_type == variant.VECTOR:
			return ""
		return dict[1]
	if Event is InputEventScreenDrag:
		match variant_type:
			variant.BOOLEAN, variant.FLOAT:
				return ""
		return dict[2]
	return ""


func generate_metadata_from_input(Event: InputEvent, variant_type: variant = variant.DEFAULT) -> InputMetadata:
	if Event is InputEventPanGesture:
		match variant_type:
			variant.BOOLEAN, variant.FLOAT:
				return null
		return InputMetadataScreenGesture.new(dict[0],get_category_name(),0)
	if Event is InputEventMagnifyGesture:
		if variant_type == variant.VECTOR:
			return null
		return InputMetadataScreenGesture.new(dict[1],get_category_name(),1)
	if Event is InputEventScreenDrag:
		match variant_type:
			variant.BOOLEAN, variant.FLOAT:
				return null
		return InputMetadataScreenGesture.new(dict[2],get_category_name(),2)
	return null


func generate_metadata_from_name(Name: String) -> InputMetadata:
	var key: Variant = dict.find_key(Name)
	if key!=null:
		var id: int = key
		return InputMetadataScreenGesture.new(Name,get_category_name(), id)
	return null
