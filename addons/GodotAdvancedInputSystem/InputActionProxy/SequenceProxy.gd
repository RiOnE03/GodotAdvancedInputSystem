## Intercepts and delays an action's execution/started state until all the actions are fired in the
## same sequence as provided in the "proxy_of_actions" list. Overlapping actions will be considered
## as cancelled. All actions much follow the order of [STARTED]->[ENDED]->[STARTED]->[ENDED]...
##
## [b]STATE MODIFICATION CHART[/b][br]
## How the raw continuous input is translated by the proxy based on charge duration:[br]
## [kbd] +--------------------------------+----------------+---------------------------+ [/kbd][br]
## [kbd] | Input Phase                    | Base Action    | Proxy Output              | [/kbd][br]
## [kbd] +--------------------------------+----------------+---------------------------+ [/kbd][br]
## [kbd] | First action Started           | STARTED        | DETECTED                  | [/kbd][br]
## [kbd] | First action Ended             | ENDED          | PENDING                   | [/kbd][br]
## [kbd] | Second action Started          | STARTED        | PENDING                   | [/kbd][br]
## [kbd] | Second action ENDED            | ENDED          | PENDING                   | [/kbd][br]
## [kbd] | Wrong action Started           | STARTED        | CANCELLED                 | [/kbd][br]
## [kbd] | Last action STARTED            | ENDED          | PENDING                   | [/kbd][br]
## [kbd] | Last action ENDED              | STARTED        | [STARTED | ENDED]         | [/kbd][br]
## [kbd] +--------------------------------+----------------+---------------------------+ [/kbd][br]
## Wrong actions does not include actions that are not provided in the proxy_of_actions list. Use force_cancel
## for such cases.
class_name SequenceProxy extends MultiActionProxy

## defines how long the sequence will wait for the next action before firing cancelled 
@export var wait_time: float = 1.0:
	set(value):
		wait_time = maxf(0, value)

var _time_checker: float = 0
var _current_action: float = 0

## If the action is mid sequence. Call this to stop the sequence from proceeding further and instead revert to default state
func force_cancel()->void:
	_context.execution_state = InputContext.CANCELLED if _context.execution_state!= InputContext.NONE else InputContext.NONE

## Returns the index of the action that is currently active in the sequence order.
## Will return -1 if the sequence hasn't started.
func get_current_action_index()->int:
	if _current_action<=0:
		return -1
	return int(_current_action)


## Returns the action that is currently active in the sequence order.
## Will return null if the sequence hasn't started.
func get_current_action()->InputAction:
	if _current_action<=0:
		return null
	return proxy_of_actions[int(_current_action)]

func _reset_context(interrupted:bool = false) -> void:
	_time_checker = 0
	_current_action = 0
	super(interrupted)


func _input_action_fired(InContext: InputContext)->void:
	if _current_action == -1:
		return
	if InContext.action != proxy_of_actions[ int(_current_action) ]:
		_current_action = -1
	elif InContext.execution_state == InputContext.STARTED:
		if _current_action == int(_current_action): #  accept values like 0.0, 1.0, 2.0...
			_current_action += 0.5                 # creates values like 0.5, 1.5, 2.5...
			wait_time = 0
	elif InContext.execution_state == InputContext.ENDED:
		if _current_action != int(_current_action): #  accept values like 0.5, 1.5, 2.5...
			_current_action += 0.5                 # creates values like 1.0, 2.0, 3.0...


const _TERMINAL_STATES: int = InputContext.ENDED | InputContext.CANCELLED



func _evaluate_proxy(delta: float) -> void:
	if _context.has_state(_TERMINAL_STATES):
		# Duplicate the data to protect against input right after the cancelled or ended state.
		var preserve: float = _current_action
		_reset_context()
		_current_action = preserve
	
	if _current_action == 0:
		return
	_context.elapsed_duration +=delta
	_time_checker += delta
	if _current_action == -1 or _time_checker > wait_time:
		_context.execution_state = InputContext.CANCELLED
		_current_action = 0
	elif _current_action == proxy_of_actions.size():
		_context.execution_state = InputContext.STARTED | InputContext.ENDED
		_current_action = 0
	elif _current_action:
		_context.execution_state = InputContext.DETECTED\
		if _context.execution_state == InputContext.NONE\
		else InputContext.PENDING
	proxy_action.emit(_context)
