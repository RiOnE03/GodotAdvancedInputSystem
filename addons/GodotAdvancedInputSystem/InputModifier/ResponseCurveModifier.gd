## Switchs the length of the length of the vector to the y_axis equivalent from the curve. 
class_name ResponseCurveModifer extends InputModifier

## The curve whose baked values will be used for mapping.
@export var curve : Curve


func _evaluate(value : Vector2) ->Vector2:
	if curve:
		var strength : float = curve.sample_baked(value.length())
		return value.normalized() * strength
	return Vector2.ZERO
