## The Object that is passed around by InputActions and InputActionProxy.
## Contains all the information related to the incoming action.
class_name InputContext extends RefCounted

#  doesn't show up in docs and too long to write if given a name.
#enum {
	### The idle or reset state. Required in a bitmask so '0' represents no active flags.
	#NONE = 0,
	#
	### Called once when the input is detected for the first time but there is a condition/threshold
	### before it can be considered as "STARTED". This execution is only used if there is a threshold that 
	### needs to be met. Thresholds are created by ActionProxy.
	#DETECTED = 1 << 0,
	#
	### Called every frame before threshold is met and the exection can be considered officially started.
	### Only created by ActionProxy objects.
	#PENDING = 1 << 1,
	#
	### Called once when the execution is officially considered to have started. The default initial state for all InputActions.
	#STARTED = 1 << 2,
	#
	### Starts firing after "Started" state and is called every frame till "ENDED" state.
	#PROCESSING = 1 << 3,
	#
	### Called once when the input has stopped firing.
	#ENDED = 1 << 4,
	#
	### Called if the inputs stops before the threshold is met. Only called by ActionProxy
	#CANCELLED = 1 << 5,
	#
	### Called when an interruption happens in the input manager which triggers state reset for all the InputActions that
	### haven't Ended yet. Interruptions are commonly called while pushing or popping new profiles onto the stack or 
	### disabling the processing state of profiles in the player controller.[br]
	### Interrupted stated is a one shot call and don't persist for the whole frame. The state is reverted to NONE
	### after the signal fires.
	### Interrupted state is always an exclusive state and won't overlap with others.
	#INTERRUPTED = 1 << 6
#}


## The idle or reset state. Required in a bitmask so '0' represents no active flags.
const NONE: int = 0

## Called once when the input is detected for the first time but there is a condition/threshold
## before it can be considered as "STARTED". This execution is only used if there is a threshold that 
## needs to be met. Thresholds are created by ActionProxy.
const DETECTED: int = 1 << 0

## Called every frame before threshold is met or the exection can be considered officially started.
## Only created by ActionProxy objects.
const PENDING: int = 1 << 1

## Called once when the execution is officially considered to have started. The default initial state for all InputActions.
const STARTED: int = 1 << 2

## Starts firing after "Started" state and is called every frame till "ENDED" state.
const PROCESSING: int = 1 << 3

## Called once when the input has stopped firing.
const ENDED: int = 1 << 4

## Called if the inputs stops before the threshold is met. Only called by ActionProxy
const CANCELLED: int = 1 << 5

## Called when an interruption happens in the input manager which triggers state reset for all the InputActions that
## haven't Ended yet. Interruptions are commonly called while pushing or popping profiles onto the stack or 
## disabling the processing state of profiles in the player controller.[br]
## Interrupted stated is a one shot call and don't persist for the whole frame. The state is reverted to NONE
## after the signal fires. [br]
## Interrupted state is always an exclusive state and won't overlap with others.
const INTERRUPTED: int = 1 << 6

## The actual value evaluated by the InputAction. For MultiActionProxy, the value
## is always true for all states except false when [code]ENDED[/code].
var value : Variant

## The cached InputEvents for the events which holds more data then just a value.
## Like MouseMotion holds additional information like pressure, velocity etc.
## Not used by MultiActionProxy. Instead they need to be routed through the cached_actions
## for InputAction's corresponding cached_inputs.
var cached_inputs : Array[InputEvent]

## Only used by InputActionProxy. Stores the InputActions responsible
## for triggering this InputActionProxy's Execution. Can also be used to fetch cached_inputs
## for specific InputActions. Since InputContext is used by pooling ,the InputContext for
## InputActions persist for the whole frame.
var cached_actions : Array[InputAction]

## The time passed since [code]DETECTED[/code] state. If the action starts from  [code]STARTED[/code]
## state (not coming from a proxy). It'll hold the same value as processing_duration.
var elapsed_duration: float = 0

## The time passed since [code]STARTED[/code] state.
var processing_duration: float = 0

## The current State of the execution. i.e [code]DETECTED[/code], [code]STARTED[/code] etc[br]
## The states uses bitmasking so a single execution may contain multiple states and a direct
## comparison of execution_state == InputContext.STATE may not work. For safety either
## use bitmask safe operations or use [method has_state] function.
var execution_state: int = NONE

## The InputAction or InputActionProxy that fired this. This value is never left empty.
var action: Variant = null:
	set(value):
		if action == null:
			action = value
		else:
			print("action property inside InputContext are read only.")

func _init(InAction: Variant)->void:
	action = InAction

## execution_state uses bitmasking which means it can hold multiple states with a single value.
## Use this method to check if the state you care about is present or not. To check for multiple states
## together use bitwise OR operator i.e. [code]|[/code]. For Example: [code]has_state(InputContext.STARTED|InputContext.ENDED)[/code]
func has_state(state : int)->bool:
	return (execution_state & state)
