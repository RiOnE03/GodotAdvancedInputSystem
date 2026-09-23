## Intercepts all the actions and only fires if all the actions are in a started or processing
## state before the allowed_delay is met.
## The execution will be cancelled if the delay was exceeded and all the actions are not active.
##
## [b]STATE MODIFICATION CHART[/b][br]
## How the raw continuous input is translated by the proxy based on elapsed duration:[br]
## [kbd] +----------------------------------------------------+---------------------+ [/kbd][br]
## [kbd] | Input Phase                                        | Proxy Output        | [/kbd][br]
## [kbd] +----------------------------------------------------+---------------------+ [/kbd][br]
## [kbd] | Any Action Started                                 | DETECTED            | [/kbd][br]
## [kbd] | Some Actions Started/Processing (Under Threshold)  | PENDING             | [/kbd][br]
## [kbd] | Partial actions Ended (Under Threshold)            | CANCELLED (fails)   | [/kbd][br]
## [kbd] | Past Threshold                                     | CANCELLED (fails)   | [/kbd][br]
## [kbd] | All Actions Started/Processing (Under Threshold)   | STARTED             | [/kbd][br]
## [kbd] | All Actions are held/Processing                    | PROCESSING          | [/kbd][br]
## [kbd] | Any or all actions Ended                           | ENDED               | [/kbd][br]
## [kbd] +----------------------------------------------------+---------------------+ [/kbd][br]
## "Partial actions Ended" defines a state where all the required actions weren't active
## but the ones that were also ended. 
class_name ConcurrentProxy extends MultiActionProxy


## The duration for which the proxy will wait for the arrival of all the actions.
## Exceeding this time limit will consider the action as cancelled.
@export var allowed_delay : float = 0.2:
	set(value):
		allowed_delay = max(0.0, value)


func _input_action_fired(InContext: InputContext)->void:
	if InContext.execution_state == InputContext.STARTED:
		_context.cached_actions.push_back(InContext.action)
	elif InContext.execution_state == InputContext.ENDED:
		_context.cached_actions.erase(InContext.action)




const _TERMINAL_STATES: int = InputContext.ENDED | InputContext.CANCELLED

var _preserve: Array[InputAction] = []


func _evaluate_proxy(delta: float) -> void:
	if _context.has_state(_TERMINAL_STATES):
		# Duplicate the data to protect against input right after the cancelled or ended state.
		_preserve.append_array(_context.cached_actions)
		_reset_context()
		_context.cached_actions.append_array(_preserve)
		_preserve.clear()
	
	if _context.cached_actions.is_empty() and _context.execution_state == InputContext.NONE:
		return
	
	_context.elapsed_duration +=delta
	
	if _context.cached_actions.size() == proxy_of_actions.size():
		_context.execution_state = InputContext.STARTED\
		if not _context.has_state(InputContext.STARTED|InputContext.PROCESSING)\
		else InputContext.PROCESSING
	
	elif _context.has_state(InputContext.STARTED|InputContext.PROCESSING):
		_context.execution_state = InputContext.ENDED
		_context.cached_actions.clear()
	
	elif _context.elapsed_duration > allowed_delay or _context.cached_actions.is_empty():
		_context.execution_state = InputContext.CANCELLED
		_context.cached_actions.clear()
	else:
		_context.execution_state = InputContext.DETECTED\
		if _context.execution_state == InputContext.NONE\
		else InputContext.PENDING
	
	proxy_action.emit(_context)
