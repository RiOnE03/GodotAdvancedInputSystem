## Creates clamping results for individual axis of the vector
@tool
class_name ClampModifier extends InputModifier

@export_category("x-axis clamp range")
## Defines whether the x axis should be clamped or not.
@export var clamp_x: bool = false:
	set(value):
		clamp_x = value
		notify_property_list_changed()

## min value for clampf(axis,min, max)
@export var x_min: float = -1.0
## max value for clampf(axis,min, max)
@export var x_max: float = 1.0

@export_category("y-axis clamp range")
## Defines whether the y axis should be clamped or not.
@export var clamp_y: bool = false:
	set(value):
		clamp_y = value
		notify_property_list_changed()
## min value for clampf(axis,min, max)
@export var y_min: float = -1.0
## max value for clampf(axis,min, max)
@export var y_max: float = 1.0


func _validate_property(property: Dictionary) -> void:
	if property.name in ["x_min", "x_max"] and not clamp_x:
		property.usage &= ~PROPERTY_USAGE_EDITOR
	elif property.name in ["y_min", "y_max"] and not clamp_y:
		property.usage &= ~PROPERTY_USAGE_EDITOR

func _evaluate(value : Vector2) ->Vector2:
	if clamp_x:
		value.x = clampf(value.x, x_min, x_max)
	if clamp_y:
		value.y = clampf(value.y, y_min, y_max)
	return value
