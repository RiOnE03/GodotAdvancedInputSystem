## Intercepts and delays an action's start until the threshold is reached.
## Use this for mechanics like hold to open chest, reviving a downed teammate, or hold to skip.
##
## [b]STATE MODIFICATION CHART[/b][br]
## How the raw continuous input is translated by the proxy based on hold duration:[br]
## [kbd] +-----------------------------+----------------+----------------------+ [/kbd][br]
## [kbd] | Input Phase                 | Base Action    | Proxy Output         | [/kbd][br]
## [kbd] +-----------------------------+----------------+----------------------+ [/kbd][br]
## [kbd] | On Initial Press            | STARTED        | DETECTED             | [/kbd][br]
## [kbd] | Holding (Under Threshold)   | PROCESSING     | PENDING              | [/kbd][br]
## [kbd] | Released (Under Threshold)  | ENDED          | CANCELLED (Fails)    | [/kbd][br]
## [kbd] | Holding (At Threshold)      | PROCESSING     | [STARTED|PROCESSING] | [/kbd][br]
## [kbd] | Holding (Past Threshold)    | PROCESSING     | PROCESSING           | [/kbd][br]
## [kbd] | Released (Past Threshold)   | ENDED          | ENDED                | [/kbd][br]
## [kbd] +-----------------------------+----------------+----------------------+ [/kbd]
class_name HoldProxy extends SingleActionProxy

## The duration for which the execution will be held before releasing the [code]STARTED[/code] state
@export var hold_duration: float = 1.0:
	set(value):
		hold_duration = max(0.0, value)


func _input_action_fired(InContext: InputContext)->void:
	_context.value = InContext.value
	
	var delta: float = InContext.elapsed_duration - _context.elapsed_duration
	_context.elapsed_duration = InContext.elapsed_duration
	
	match InContext.execution_state:
		InputContext.STARTED:
			_context.execution_state = InputContext.DETECTED
		
		InputContext.PROCESSING:
			if _context.elapsed_duration < hold_duration:
				_context.execution_state = InputContext.PENDING
			
			else:
				if _context.execution_state == InputContext.PENDING:
					_context.execution_state = InputContext.STARTED | InputContext.PROCESSING
				
				else:
					_context.processing_duration += delta
					_context.execution_state = InputContext.PROCESSING
			
		InputContext.ENDED:
			if _context.elapsed_duration < hold_duration:
				_context.execution_state = InputContext.CANCELLED
			else:
				_context.processing_duration += delta
				_context.execution_state = InputContext.ENDED
		
	proxy_action.emit(_context)
