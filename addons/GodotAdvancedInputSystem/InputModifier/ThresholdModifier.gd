## A threshold that defines an upper limit for an input. The same as deadzone from instead of flooring the value, it ceils it.
class_name RadialThresholdModifer extends InputModifier

## Considers the magnitude/length of the vector for caluclation. If the magintude/length of the
## vector is greater than this. Then the length will be clamped to the [member Threshold_Upper_Limit].
@export var Threshold : float = 0.5
## Defines the ceiling magnitude/length.
@export var Thresdhold_Upper_Limit : float = 1


func _evaluate(value : Vector2) ->Vector2:
	if value.length()<Threshold:
		return Vector2.ZERO
	return value.normalized()*Thresdhold_Upper_Limit
