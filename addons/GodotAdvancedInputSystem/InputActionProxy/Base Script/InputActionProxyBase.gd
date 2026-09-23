@abstract
class_name InputActionProxy extends Resource


signal proxy_action(context: InputContext)

var _context: InputContext = InputContext.new(self)

## intermediate function call that handles the default tasks like handling interruptions before calling 
## _input_action_fired()
func _handle_interruption_reroute(InContext: InputContext)->void:
	if InContext.execution_state == InputContext.INTERRUPTED:
		if _context.elapsed_duration != InputContext.NONE:
			_fire_interrupt()
		return
	_input_action_fired(InContext)

## Virtual function purely for overriding.
func _input_action_fired(InContext: InputContext)->void:
	pass

## resets the context to NONE state along with all its values to default
func _reset_context(interrupted: bool = false) -> void:
	_context.elapsed_duration = 0
	_context.processing_duration = 0
	_context.execution_state = InputContext.NONE
	_context.cached_actions.clear()


## creates and fire the interrupt signal. Afterwords immediately revert to NONE within the same frame.
func _fire_interrupt()->void:
	_reset_context(true)
	_context.execution_state = InputContext.INTERRUPTED
	proxy_action.emit(_context)
	_context.execution_state = InputContext.NONE
