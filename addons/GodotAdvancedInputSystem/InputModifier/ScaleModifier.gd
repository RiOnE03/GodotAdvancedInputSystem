## Changes the vector's length to the scale property
class_name ScaleModifier extends InputModifier

## The new length of the vector
@export var scale: float:
	set(value):
		scale = clampf(value, 0 ,INF)

func _evaluate(value : Vector2) ->Vector2:
	return value.normalized() * scale
