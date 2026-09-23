## A modifier to remove an axis of the vector.
class_name RemoveAxisModifier extends InputModifier

## Sets the x axis of this vector to 0.
@export var remove_x: bool = false
## Sets the y axis of this vector to 0.
@export var remove_y: bool = false

func _evaluate(value : Vector2) ->Vector2:
	if remove_x:
		value.x = 0
	if remove_y:
		value.y = 0
	return value
