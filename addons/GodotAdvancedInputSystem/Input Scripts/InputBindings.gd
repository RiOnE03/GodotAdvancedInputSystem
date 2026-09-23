## A collection of hardware input sources along with their respective list of modifiers that are
## used by the [InputProfile] to define the hardware inputs end of the logical input
## [InputAction].[br][br]
## Creating or editing this resource as an individual .tres file is not supported at the moment.
## If you want to keep reserve Input_bindings for swapping or any other unique task. Create a
## profile with no InputActions and use it as a container for your custom Input_bindings for later use.
class_name InputBindings extends Resource

## just a resource holding InputMetadata and an array of InputModifiers
const InputMetadataAndModifiers:= preload("res://addons/GodotAdvancedInputSystem/Input Scripts/InputMetadataAndModifiers.gd")

## The list of hardware inputs and their corresponding modifers.
@export_storage var _bindings: Array[InputMetadataAndModifiers]

## returns the hardware input metadata at the provided index. Return null if the index is not applicable.
func get_binded_input_metadata(index: int)->InputMetadata:
	if index<_bindings.size():
		return _bindings[index].binded_input
	return null

## The changes made to this array of modifiers will immediately reflect on the original modifiers
## this is not a duplicate but the original array.
func get_modifiers_list_at(index: int)->Array[InputModifier]:
	if index<_bindings.size():
		return _bindings[index].modifiers
	return []


## The changes made to this array of modifiers will immediately reflect on the original modifiers
## this is not a duplicate but the original array.
func get_modifiers_for_metadata(metadata: InputMetadata)->Array[InputModifier]:
	var custom_finder: Callable = func(original, compare)->bool: return original == compare
	var index:= _bindings.find_custom(custom_finder.bind(metadata))
	if index != -1 :
		return _bindings[index].modifiers
	return []

## Replaces any instance of metadata that holds the same input configuration.
func replace_all_metadata(From: InputMetadata, To: InputMetadata)->void:
	for metadata in _bindings:
		if metadata.binded_input.is_same_metadata(From):
			metadata.binded_input = To


## Adds a new entry in the _bindings list for a new hardware input. To get InputMetadata for
## an InputEvent create an InputProvidersRegistry object which provides a function
## [method InputProvidersRegistry.get_metadata_from_event] to convert InputEvent to its equivalent metadata. 
func add_new_entry(hardware_input: InputMetadata, modifiers: Array[InputModifier])->void:
	var new_entry: InputMetadataAndModifiers = InputMetadataAndModifiers.new()
	new_entry.binded_input = hardware_input
	new_entry.modifiers = modifiers
	_bindings.append(new_entry)

## General purpose remove_swap function can be used for any array.[br]
## Caution: It is faster than remove_at however it'll affect the order
## of entries
static func remove_swap(arr: Array, index: int)->void:
	if index >= arr.size():
		return
	
	var value := arr.pop_back()
	
	if index == arr.size():
		return
	
	arr[index] = value

# extracts a value for all the inputs in the binding list, feeds them incoming_inputs, stores the relevant inputs_events
# in the cached list and also remove the cached inputs from the incoming_inputs list if the consume is set to true.
# The individual input values are only accumulated after feeding them through the list of modifiers.
func _evaluate_inputs(incoming_inputs: Array[InputEvent],cached_inputs: Array[InputEvent], consume: bool)->Vector2:
	var result: Vector2 = Vector2.ZERO
	
	for i in _bindings.size():
		
		var raw_value: Vector2 = Vector2.ZERO
		
		for j in range(incoming_inputs.size() - 1, -1, -1):
			
			var metadata : InputMetadata =  _bindings[i].binded_input
			
			var input: InputEvent = incoming_inputs[j]
			
			if metadata and metadata.is_input_relevant(input):
				
				raw_value += metadata.extract_raw_value(input)
				#print(raw_value)
				if metadata.capture_with_context(input):
					cached_inputs.push_back(input)
				if consume:
					remove_swap(incoming_inputs,j)
		var modifiers: Array[InputModifier] = _bindings[i].modifiers
		#if raw_value != Vector2.ZERO: in case a new modifier is needed that works on ZERO vector. This safety check is removed
		for modifier in modifiers:
			raw_value = modifier._evaluate(raw_value)
		
		result += raw_value
	return result
