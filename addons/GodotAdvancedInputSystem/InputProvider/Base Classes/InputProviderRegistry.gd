## The Universal object that holds the list of all the InputProviders and provides functions to
## convert InputEvents to their equivalent InputMetadata which are used in [InputBindings].
class_name InputProvidersRegistry extends RefCounted

## A Dictionary that holds all the inputs providers with their Category names as the key. All
## the entered values are loaded RefCounted values and not resource. Created and destroyed 
## with each InputProvidersRegistry object.
var Providers: Dictionary[StringName, RefCounted]

enum variant {
	DEFAULT = 0,
	BOOLEAN = 1,
	FLOAT = 2,
	VECTOR = 3
}


## A list of the paths for each individual InputProvider Script.
var Provider_path_array: Array[String]= [
	"res://addons/GodotAdvancedInputSystem/InputProvider/Keyboard/ProviderKeyboard.gd",
	"res://addons/GodotAdvancedInputSystem/InputProvider/MouseAxis/ProviderMouseMotion.gd",
	"res://addons/GodotAdvancedInputSystem/InputProvider/MouseButton/ProviderMouseButton.gd",
	"res://addons/GodotAdvancedInputSystem/InputProvider/GamepadAxis/ProviderGamepadAxis.gd",
	"res://addons/GodotAdvancedInputSystem/InputProvider/GamepadButton/ProviderGamepadButton.gd",
	"res://addons/GodotAdvancedInputSystem/InputProvider/GamepadExtra/ProviderGamepadExtras.gd",
	"res://addons/GodotAdvancedInputSystem/InputProvider/ScreenGesture/ProviderScreenGestures.gd",
	"res://addons/GodotAdvancedInputSystem/InputProvider/ScreenTap/ProviderScreenTap.gd"
]

func _init() -> void:
	for entry in Provider_path_array:
		var ref : RefCounted = load(entry).new()
		Providers[ref.get_category_name()] = ref

## Converts an input's name into its equivalent InputMetada however the names need to be exact matchs.
## You can even provide Category's name to make the lookup faster. If left empty, it'd search all the
## providers for the correct metadata. If the Name or category(if provided) is incorrect, it'd return null. 
func get_metadata_from_name(Name: String, Category: String = "")->InputMetadata:
	if not Category.is_empty():
		if Providers.has(Category):
			var ref: RefCounted = Providers[Category]
			return ref.generate_metadata_from_name(Name)
		else:
			return null
	else:
		for item in Providers.values():
			var metadata: InputMetadata = item.generate_metadata_from_name(Name)
			if metadata:
				return metadata
	return null

## Converts an InputEvent directly to its Equivalent InputMetadata.[br]
## The variants here is for specifying the exact type that you want from the registry.
## For example even among Dpad inputs there are variants for horizontal, vertical and 2D but providing
## just a Dpad input event is not enough to tell which one you want, the variant here represents the
## exact variation you desire.
func get_metadata_from_event(event: InputEvent, variant_type: variant = variant.DEFAULT)->InputMetadata:
	for item in Providers.values():
		var metadata: InputMetadata = item.generate_metadata_from_input(event,variant_type)
		if metadata:
			return metadata
	return null
