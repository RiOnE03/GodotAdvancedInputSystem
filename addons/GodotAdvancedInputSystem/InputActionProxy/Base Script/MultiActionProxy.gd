## Many to one proxies do not hold values or inputs. Access these values from the cached actions directly.
@abstract
class_name MultiActionProxy extends InputActionProxy


@export var proxy_of_actions: Array[InputAction]: set = _set_proxy_of_actions

func _init() -> void:
	if not Engine.is_editor_hint():
		_setup_connection.call_deferred()


## Binds the resource to the inputManager so this can work properly. If this failed,
## the _evaluate_proxy won't work and any delta related calculation can't be performed.
func _setup_connection() -> void:
	var tree: SceneTree = Engine.get_main_loop() as SceneTree
	if not tree:
		print("Scene tree is not created yet. _setup_connection\
		 failed in MultiActionProxy. Call manually. File: %s", resource_path)
		return 
	
	var manager: Node = tree.root.get_node_or_null("InputManager")
	
	if manager and manager.has_signal("inputs_processed"):
		if not manager.is_connected("inputs_processed", _evaluate_proxy):
			for action in proxy_of_actions:
				if not action.action.is_connected(_input_action_fired):
					action.action.connect(_input_action_fired)
			_initial_connection(manager)
	
	elif not tree.process_frame.is_connected(_setup_connection):
		tree.process_frame.connect(_setup_connection, CONNECT_ONE_SHOT)

## Called to add an action to the proxy through code. Action
## should never be added directly as this function also handles
## establishing connections.
func add_action(action: InputAction)->void:
	if not proxy_of_actions.has(action):
		proxy_of_actions.push_back(action)
		action.action.connect(_handle_interruption_reroute)

## Call this to remove an action from the list. Actions should never
## be removed directly from the list.
func remove_action(action: InputAction)->void:
	if proxy_of_actions.has(action):
		proxy_of_actions.erase(action)
		_context.cached_actions.erase(action)
		action.action.disconnect(_handle_interruption_reroute)


# ----------- Can override them ---------------

## Setter function for proxy_of_actions variable. Called whenever the array is updated.
func _set_proxy_of_actions(value: Variant)->void:
	proxy_of_actions = value

## Called to build initial connections. Override to remove or add anything. Called at the end of frame
## if resource is created via preload to make sure the InputManager is properly set before connecting.
func _initial_connection(manager: Node)->void:
	_ready()
	manager.connect("inputs_processed", _evaluate_proxy)

## Called when the Proxy is linked to the InputManager.
## Also acts as _ready function of nodes but for InputActionProxy class.
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
	_context.value = false

## Called for every InputAction's action signal fire. Only the actions present in "proxy_of_actions" are conencted.
## Interruptions, cached_actions are handled automatically and don't need to be accounted for.
## But the state reset to NONE is still needed to called manually.
## context values that needs to be manually accounted for: elapsed_duration, processing_duration, execution_state
## value and cached_inputs should be skipped altogether
func _input_action_fired(InContext: InputContext)->void:
	pass
