## Negates the input vector i.e vector -> -vector
class_name NegateModifier extends InputModifier

func _evaluate(value : Vector2) ->Vector2:
	return -value
