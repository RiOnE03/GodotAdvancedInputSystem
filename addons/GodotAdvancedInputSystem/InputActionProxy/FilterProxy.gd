## A proxy that takes a list of InputActions and filters them to only let one InputAction pass.
## The InputAction that will be allowed to pass depends on the filter_index which represents the
## index of the InputAction in the proxy_of_actions variable.[br][br]
## Usefull for switching InputActions at runtime.[br][br]
##
## [b]STATE MODIFICATION CHART[/b][br]
## How the raw continuous input is translated by the proxy based on charge duration:[br]
## [kbd] +--------------+-------------+-------------+----------------------+ [/kbd][br]
## [kbd] | OUTPUT       | Action (0)  | Action (1)  | Current filter Index | [/kbd][br]
## [kbd] +--------------+-------------+-------------+----------------------+ [/kbd][br]
## [kbd] |  Nil         | Nil         | -Any-       | 0                    | [/kbd][br]
## [kbd] |  STARTED     | STARTED     | -Any-       | 0                    | [/kbd][br]
## [kbd] |  PROCESSING  | PROCESSING  | -Any-       | 0                    | [/kbd][br]
## [kbd] |  ENDED       | ENDED       | -Any        | 0                    | [/kbd][br]
## [kbd] |  ENDED       | -Any-       | -Any-       | 1 (Just switched)    | [/kbd][br]
## [kbd] |  STARTED     | -Any-       | STARTED     | 1                    | [/kbd][br]
## [kbd] |  PROCESSING  | -Any-       | PROCESSING  | 1                    | [/kbd][br]
## [kbd] |  ENDED       | -Any-       | ENDED       | 1                    | [/kbd][br]
## [kbd] |  Nil         | -Any-       | Nil         | 1                    | [/kbd][br]
## [kbd] +--------------+-------------+-------------+----------------------+ [/kbd][br]
## -Any-: It represents any state where an input signal is coming from InputAction. 
@tool
class_name FilterProxy extends MultiActionProxy

## Defines the index of the InputAction's context that this filter should allow to pass, while blocking
## all others.
@export var filter_index: int = -1:
	set(value):
		if filter_index == value:
			return
		filter_index = value
		if not proxy_of_actions.is_empty():
			filter_index = clampi(value , 0 , proxy_of_actions.size() - 1)


var _following_index: int = -1:
	set(value):
		_following_index = value
		if value == -1:
			return
		if _context.cached_actions.is_empty():
			_context.cached_actions.append(proxy_of_actions[_following_index])
		else:
			_context.cached_actions[0] = proxy_of_actions[_following_index]


func _set_proxy_of_actions(value: Variant)->void:
	super(value)
	notify_property_list_changed()


# Overrided to exclude useless process calls
func _initial_connection(manager: Node)->void:
	_following_index = filter_index


func _input_action_fired(InContext: InputContext)->void:
	# Straight forwarding
	if _following_index == filter_index and InContext.action == proxy_of_actions[filter_index]:
		_context.elapsed_duration = InContext.elapsed_duration
		_context.processing_duration = InContext.processing_duration
		_context.value = InContext.value
		_context.execution_state = InContext.execution_state
	
	# if the filter was changed, end the propagation. Ignore if already ended once
	elif _following_index != -1 and InContext.action == proxy_of_actions[_following_index]:
		_context.elapsed_duration = InContext.elapsed_duration
		_context.processing_duration = InContext.processing_duration
		_context.value = InContext.value
		_context.execution_state = InputContext.ENDED
		_following_index = -1 # makes sure it only happens once and ignored every other time
	
	# if the filter was changed and the new action started
	elif InContext.action == proxy_of_actions[filter_index] and InContext.execution_state == InputContext.STARTED:
		_following_index = filter_index
		_context.elapsed_duration = 0
		_context.processing_duration = 0
		_context.execution_state = InputContext.STARTED
	
	# Just ignore it otherwise. It's an action that we don't care about.
	else:
		return
	proxy_action.emit(_context)
