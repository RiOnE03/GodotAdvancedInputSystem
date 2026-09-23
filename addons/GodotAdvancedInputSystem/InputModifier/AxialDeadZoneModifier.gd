## Creates deadzone for individual axis of the vector
class_name AxialDeadzoneModifier extends InputModifier

## Defines the deadzone for x-axis. To caculate the deadzone, absolute value of x axis
## will be taken.[br]
## Example for deadzone of 0.2:[br][br]
## [kbd](0.5, 0.0)->(0.5, 0.0)
##
## (0.1, 0.0)->(0.0, 0.0)
##
## (-0.3, 0.0)->(-0.3, 0.0)
##
## (-0.1, 0.0)->(0.0, 0.0)[/kbd]
@export var Deadzone_X : float = 0.2:
	set(value):
		Deadzone_X = max(0.0, value)

## Defines the deadzone for y-axis. To caculate the deadzone, absolute value of y axis
## will be taken.[br]
## Example for deadzone of 0.2:[br][br]
## [kbd](0.5, 0.0)->(0.5, 0.0)
##
## (0.1, 0.0)->(0.0, 0.0)
##
## (-0.3, 0.0)->(-0.3, 0.0)
##
## (-0.1, 0.0)->(0.0, 0.0)[/kbd]
@export var Deadzone_Y : float = 0.2:
	set(value):
		Deadzone_Y = max(0.0, value)

func _evaluate(value : Vector2) ->Vector2:
	if abs(value.x)<Deadzone_X:
		value.x = 0
	if abs(value.y)<Deadzone_Y:
		value.y = 0
	return value
