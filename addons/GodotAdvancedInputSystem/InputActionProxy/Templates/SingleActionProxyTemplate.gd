extends SingleActionProxy


# ----------- Can override this ---------------

## Setter function for proxy_of variable. Called whenever the action is updated.
func _set_proxy_of(value: Variant)->void:
	proxy_of = value

## Called when the state needs to be reset either by an interruption or when switching from
## ENDED/CANCELLED state to NONE state. Add extra variables that also need to be reset.
func _reset_context(interrupted: bool = false) -> void:
	super(interrupted)

## Called when the action signal of "proxy_of" fires.
## Interruptions, state reset to NONE, value, cached_actions and cached_inputs are handled automatically
## and don't need to be accounted for.[br]
## Properties that needs to be accounted for: elapsed_duration, processing_duration and execution_state.
func _input_action_fired(InContext: InputContext)->void:
	pass
