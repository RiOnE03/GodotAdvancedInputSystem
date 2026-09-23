class_name InputMetadata extends Resource

## Name of the Input
@export_storage var InputName: String:
	set(value):
		if InputName.is_empty():
			InputName = value
		else:
			push_error("InputName variable is read-only after initialization.")

## Name of the Category.
@export_storage var CategoryName: StringName:
	set(value):
		if CategoryName.is_empty():
			CategoryName = value
		else:
			push_error("CategoryName variable is read-only after initialization.")


func _init(InName: String = "", InCategory: String = "")->void:
	InputName = InName
	CategoryName = InCategory

## Does a comparison between the current and the passed metadata and retuns true if both metadata have 
## same properties (It does not check if the references themselves are same or not)
func is_same_metadata(metadata: InputMetadata)->bool:
	return false

## Checks if this metadata accepts/operators on this InputEvent or not.
func is_input_relevant(Event : InputEvent)->bool:
	return false

## Provides a raw Vector2 value equivalent to the passed InputEvent's own value. This value may not make
## direct sense but are internally used by the [InputProfile] to generate desirable outcomes.
func extract_raw_value(Event : InputEvent)->Vector2:
	return Vector2.ZERO

## defines whether the InputEvent for a particular Input should also be passed along with the [InputContext] or not.
func capture_with_context(Event : InputEvent)->bool:
	return false
