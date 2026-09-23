## One to one proxies also copies the value and cached inputs of the input action.
@abstract
class_name SingleActionProxy extends InputActionProxy

## The InputAction that this proxy is supposed to manipulate.
@export var proxy_of: InputAction:
	set(value):
		if proxy_of == value:
			return
		
		if proxy_of and not Engine.is_editor_hint():
			if proxy_of.action.is_connected(_handle_interruption_reroute):
				_context.cached_actions.clear()
				proxy_of.action.disconnect(_handle_interruption_reroute)
				proxy_of.state_reset.disconnect(_reset_context)
		
		_set_proxy_of(value)
		
		if proxy_of and not Engine.is_editor_hint():
			if not proxy_of.action.is_connected(_handle_interruption_reroute):
				_context.cached_actions.append(proxy_of)
				proxy_of.action.connect(_handle_interruption_reroute)
				proxy_of.state_reset.connect(_reset_context)

## intermediate function call that handles the default tasks like handling interruptions,
## copying cached_inputs and value before calling _input_action_fired()
func _handle_interruption_reroute(InContext: InputContext)->void:
	if InContext.execution_state == InputContext.INTERRUPTED:
		if _context.elapsed_duration != InputContext.NONE:
			_fire_interrupt()
		return
	_context.cached_inputs.clear()
	_context.cached_inputs.append_array(InContext.cached_inputs)
	_context.value = InContext.value
	_input_action_fired(InContext)

# ----------- Can override this ---------------

## Setter function for proxy_of variable. Called whenever the action is updated.
func _set_proxy_of(value: Variant)->void:
	proxy_of = value

## Called when the state needs to be reset either by an interruption or when switching from
## ENDED/CANCELLED state to NONE state. Add extra variables that also need to be reset.
func _reset_context(interrupted: bool = false) -> void:
	super(interrupted)
	_context.value = proxy_of._set_value_type(Vector2.ZERO) if proxy_of else null
	_context.cached_inputs.clear()

## Called when the action signal of "proxy_of" fires.
## Interruptions, state reset to NONE, value, cached_actions and cached_inputs are handled automatically
## and don't need to be accounted for.[br]
## Properties that needs to be accounted for: elapse_duration, processing_duration and execution_state.
func _input_action_fired(InContext: InputContext)->void:
	pass
