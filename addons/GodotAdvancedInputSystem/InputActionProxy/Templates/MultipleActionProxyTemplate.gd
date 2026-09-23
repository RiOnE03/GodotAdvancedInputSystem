extends MultiActionProxy


# ----------- Can override them ---------------

## Setter function for proxy_of_actions variable. Called whenever the array is updated.
func _set_proxy_of_actions(value: Variant)->void:
	proxy_of_actions = value

## Called to build initial connections. Override to remove or add anything. Called at the end of frame
## if resource is created via preload to make sure the InputManager is properly set before connecting.[br]
## It currently connects _ready and _evaluate_proxy function, override this if you don't want to connect either of these
## functions.
func _initial_connection(manager: Node)->void:
	super(manager)

## Called when the Proxy is linked to the InputManager.
## Also acts as _ready function of nodes but for MultiActionProxy class.
func _ready()->void:
	pass

## Virtual function for child classes to override. Called when InputManager Completed processing all the inputs that frame.
## Also acts as _process for InputActionProxy class.
func _evaluate_proxy(delta: float) -> void:
	pass

## Called when the state needs to be reset either by an interruption or when switching from
## ENDED/CANCELLED state to NONE state. Add extra variables that also need to be reset.
func _reset_context(interrupted:bool = false) -> void:
	super(interrupted)

## Called for every InputAction's action signal fire. Only the actions present in "proxy_of_actions" are called.
## Interruptions, cached_actions are handled automatically and don't need to be accounted for.
## But the state reset to NONE when the state reaches ENDED or CANCELLED state still needs to handled manually.
## context values that needs to be manually accounted for: elapsed_duration, processing_duration, execution_state.[br]
## Values that should be skipped altogther: value and cached_inputs[br]
## For example, check the code for other proxies that extends from MultiActionProxy class.
func _input_action_fired(InContext: InputContext)->void:
	pass
