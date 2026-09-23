## Normalize the vector
class_name NormalizeModifier extends InputModifier


func _evaluate(value : Vector2) ->Vector2:
	return value.normalized()
