## Intercepts and only starts the action if the base action was released before the threshold.
##
## [b]STATE MODIFICATION CHART[/b][br]
## How the raw continuous input is translated by the proxy based on hold duration:[br]
## [kbd] +-----------------------------+----------------+----------------------+ [/kbd][br]
## [kbd] | Input Phase                 | Base Action    | Proxy Output         | [/kbd][br]
## [kbd] +-----------------------------+----------------+----------------------+ [/kbd][br]
## [kbd] | On Initial Press            | STARTED        | DETECTED             | [/kbd][br]
## [kbd] | Holding (Under Threshold)   | PROCESSING     | PENDING              | [/kbd][br]
## [kbd] | Released (Under Threshold)  | ENDED          | [STARTED|ENDED]      | [/kbd][br]
## [kbd] | Holding (Past Threshold)    | PROCESSING     | CANCELLED            | [/kbd][br]
## [kbd] | Released (Past Threshold)   | ENDED          | ignored              | [/kbd][br]
## [kbd] +-----------------------------+----------------+----------------------+ [/kbd]
class_name TapProxy extends SingleActionProxy

## The action is considered successful if ended before this threshold.
@export var allowed_delay: float = 0.2:
	set(value):
		allowed_delay = maxf(0, value)

func _input_action_fired(InContext: InputContext)->void:
	if _context.execution_state == InputContext.CANCELLED:
		return
	_context.value = InContext.value
	_context.elapsed_duration = InContext.elapsed_duration
	match InContext.execution_state:
		InputContext.STARTED:
			_context.execution_state = InputContext.DETECTED
		InputContext.PROCESSING:
			if InContext.elapsed_duration < allowed_delay:
				_context.execution_state = InputContext.PENDING
			else:
				_context.execution_state = InputContext.CANCELLED
		InputContext.ENDED:
			if InContext.elapsed_duration < allowed_delay:
				_context.execution_state = InputContext.STARTED | InputContext.ENDED
			else:
				_context.execution_state = InputContext.CANCELLED
	proxy_action.emit(_context)
