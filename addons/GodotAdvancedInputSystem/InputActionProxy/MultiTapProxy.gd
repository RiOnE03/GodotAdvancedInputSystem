## Intercepts and delays an action's execution/started state until the input is fired
## the same no. of times as detection_count under the allowed_delay.
##
## [b]STATE MODIFICATION CHART[/b][br]
## How the raw continuous input is translated by the proxy based on charge duration:[br]
## [kbd] +--------------------------------------------+----------------+---------------------------+ [/kbd][br]
## [kbd] | Input Phase                                | Base Action    | Proxy Output              | [/kbd][br]
## [kbd] +--------------------------------------------+----------------+---------------------------+ [/kbd][br]
## [kbd] | On Initial Press                           | STARTED        | DETECTED                  | [/kbd][br]
## [kbd] | Released (Under Threshold)                 | PROCESSING     | PENDING                   | [/kbd][br]
## [kbd] | Pressed Again (Under Threshold)            | ENDED          | PENDING                   | [/kbd][br]
## [kbd] | Release (count reached)(Under Threshold)   | PROCESSING     | [STARTED | ENDED]         | [/kbd][br]
## [kbd] | Count not reached before threshold         | ENDED          | CANCELLED                 | [/kbd][br]
## [kbd] +--------------------------------------------+----------------+---------------------------+ [/kbd]
class_name MultiTapProxy extends SingleActionProcessingProxy

## The number the times the action needs to be performed before its considered as successful.
## For simple simple multiple tap case, it just define the number of taps to be performed for the
## action to be considered as [code]STARTED[/code]
@export var detection_count: int = 2:
	set(value):
		detection_count = maxi(0, value)

## The duration for which the proxy will wait for the detection_count to be met. Exceeding the
## limit would yield [code]CANCELLED[/code], if the action was successful before this.
@export var allowed_delay: float = 0.2:
	set(value):
		allowed_delay = maxf(0, value)

var current_taps: float = 0


func _input_action_fired(InContext: InputContext)->void:
	if InContext.execution_state == InputContext.STARTED:
		if current_taps == int(current_taps): #  accept values like 0.0, 1.0, 2.0...
			current_taps += 0.5               # creates values like 0.5, 1.5, 2.5...
	elif InContext.execution_state == InputContext.ENDED:
		if current_taps != int(current_taps): #  accept values like 0.5, 1.5, 2.5...
			current_taps += 0.5               # creates values like 1.0, 2.0, 3.0...

func _reset_context(interrupted: bool = false) -> void:
	if interrupted or current_taps == detection_count:
		current_taps = 0
		super(interrupted)

const _TERMINAL_STATES: int = InputContext.ENDED | InputContext.CANCELLED

func _evaluate_proxy(delta: float) -> void:
	if _context.has_state(_TERMINAL_STATES):
		# Duplicate the data to protect against input right after the cancelled or ended state.
		var preserve: float = current_taps
		_reset_context(true)
		current_taps = preserve
	
	if current_taps == 0:
		return
	
	_context.elapsed_duration += delta
	
	if _context.elapsed_duration > allowed_delay:
		_context.execution_state = InputContext.CANCELLED
		current_taps = 0
	elif current_taps == detection_count:
		_context.execution_state = InputContext.STARTED | InputContext.ENDED
		current_taps = 0
	else:
		_context.execution_state = InputContext.DETECTED if\
		_context.execution_state == InputContext.NONE else InputContext.PENDING
	proxy_action.emit(_context)
