extends RefCounted


const variant:= InputProvidersRegistry.variant

func get_category_name() -> String:
	return ""

func get_input_list() -> Array[String]:
	return []

func get_input_name(Event:InputEvent, variant_type: variant = variant.DEFAULT)->String:
	return ""


func generate_metadata_from_input(Event: InputEvent, variant_type: variant = variant.DEFAULT) -> InputMetadata:
	return null


func generate_metadata_from_name(Name: String) -> InputMetadata:
	return null
