extends SingleActionProcessingProxy

# ----------- Can override them ---------------

## Called when the state needs to be reset either by an interruption or when switching from
## ENDED/CANCELLED state to NONE state. Add extra variables that also need to be reset.
func _reset_context(interrupted: bool = false) -> void:
	super(interrupted)

## Called when the action signal of "proxy_of" fires.
## Interruptions, state reset to NONE, value, cached_actions and cached_inputs are handled automatically
## and don't need to be accounted for.[br]
## Properties that needs to be accounted for: elapse_duration, processing_duration and execution_state.
func _input_action_fired(InContext: InputContext)->void:
	pass

## Called to build initial connections. Override to remove or add anything. Called at the end of frame
## if resource is created via preload to make sure the InputManager is properly set before connecting.
func _initial_connection(manager: Node)->void:
	super(manager)

## Called when the Proxy is linked to the InputManager.
## Also acts as _ready function of nodes but for InputActionProxy class.
func _ready()->void:
	pass

## Virtual function for child classes to override. Called when InputManager Completed processing all the inputs that frame.
## Also acts as _process for InputActionProxy class.
func _evaluate_proxy(delta: float) -> void:
	pass
