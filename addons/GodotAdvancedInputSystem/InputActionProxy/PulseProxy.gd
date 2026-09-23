## Intercepts and fires STARTED/ENDED at the same time but the PROCESSING state is fired at
## pulse_delay intervals instead of every frame.
##
## [b]STATE MODIFICATION CHART[/b][br]
## How the raw continuous input is translated by the proxy based on charge duration:[br]
## [kbd] +-----------------------------+----------------+---------------------------+ [/kbd][br]
## [kbd] | Input Phase                 | Base Action    | Proxy Output              | [/kbd][br]
## [kbd] +-----------------------------+----------------+---------------------------+ [/kbd][br]
## [kbd] | On Initial Press            | STARTED        | STARTED                   | [/kbd][br]
## [kbd] | Holding (Under pulse 1)     | PROCESSING     | PENDING                   | [/kbd][br]
## [kbd] | Holding (pulse exceeded)    | PROCESSING     | PROCESSING                | [/kbd][br]
## [kbd] | Holding (Under pulse 2)     | PROCESSING     | PENDING                   | [/kbd][br]
## [kbd] | Holding (pulse exceeded)    | PROCESSING     | PROCESSING                | [/kbd][br]
## [kbd] | Released                    | ENDED          | ENDED                     | [/kbd][br]
## [kbd] +-----------------------------+----------------+---------------------------+ [/kbd]
class_name PulseProxy extends SingleActionProxy

## The action is considered successful if ended before this threshold.
@export var pulse_delay: float = 0.5:
	set(value):
		pulse_delay = maxf(0, value)

var last_counter: float = 0

func _reset_context(interrupted: bool = false) -> void:
	last_counter = 0
	super()

func _input_action_fired(InContext: InputContext)->void:
	_context.value = InContext.value
	
	var new_counter: int = int(InContext.elapsed_duration/pulse_delay)
	var pulse_fire: bool = new_counter > last_counter
	last_counter = new_counter
	
	_context.elapsed_duration = InContext.elapsed_duration
	_context.processing_duration = InContext.processing_duration
	
	match InContext.execution_state:
		InputContext.STARTED:
			_context.execution_state = InputContext.STARTED
			proxy_action.emit(_context)
		InputContext.PROCESSING:
			if pulse_fire:
				_context.execution_state = InputContext.PROCESSING
				proxy_action.emit(_context)
			else:
				_context.execution_state = InputContext.PENDING
				proxy_action.emit(_context)
		InputContext.ENDED:
			_context.execution_state = InputContext.ENDED
			proxy_action.emit(_context)
