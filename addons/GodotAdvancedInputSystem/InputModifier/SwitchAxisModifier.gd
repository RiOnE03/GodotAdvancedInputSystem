## Switchs the x axis of Vector2 with its y axis
class_name SwitchAxisModifier extends InputModifier


func _evaluate(value : Vector2) ->Vector2:
	return Vector2(value.y , value.x)
