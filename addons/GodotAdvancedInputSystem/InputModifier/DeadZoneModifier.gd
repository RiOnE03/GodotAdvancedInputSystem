## Create a deadone for the vector but considers the [kbd]vector.length()[/kbd] for calculation.
class_name RadialDeadzoneModifier extends InputModifier

## Define the deadzone range. If the vector's length is smaller than this range then it'd become Vector2.ZERO
@export var Deadzone : float = 0.2:
	set(value):
		Deadzone = max(0.0, value)

func _evaluate(value : Vector2) ->Vector2:
	if value.length() < Deadzone:
		return Vector2.ZERO
	return value
