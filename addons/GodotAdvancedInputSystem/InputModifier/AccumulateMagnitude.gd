## Since normally the Boolean and Float value type only checks
## x-axis value for evaluation. Use this modifier if you need to
## look at the magnitude/length of the vector for evaluation.
## It'll converts the x axis value of the vector to vector_length 
## and leave y axis as 0.[br]
## vector -> Vector2(vector.length(),0)
class_name AccumulateMagnitudeModifier extends InputModifier


func _evaluate(value : Vector2) ->Vector2:
	return Vector2(value.length(),0)
